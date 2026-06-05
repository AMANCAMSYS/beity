import 'dart:async';

import 'package:sawa/core/services/notification_service.dart';
import 'package:sawa/core/local_database/daos/invitations_dao.dart';
import 'package:sawa/core/local_database/daos/users_dao.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import 'package:sawa/core/local_database/local_model_mappers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invitation_model.dart';
import 'invitation_repository.dart';
import 'package:sawa/features/offline_queue/data/datasources/queue_datasource.dart';
import 'package:sawa/features/offline_queue/domain/entities/action_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/entity_type.dart';
import 'package:sawa/features/offline_queue/domain/entities/queue_entry.dart';

class LocalFirstInvitationRepository implements InvitationRepository {
  final SupabaseClient _client;
  final InvitationsDao _invitationsDao;
  final UsersDao _usersDao;
  final QueueDataSource _queueDataSource;

  LocalFirstInvitationRepository({
    required SupabaseClient client,
    InvitationsDao? invitationsDao,
    UsersDao? usersDao,
    required QueueDataSource queueDataSource,
  }) : _client = client,
       _invitationsDao =
           invitationsDao ?? InvitationsDao(LocalDatabaseService.instance),
       _usersDao = usersDao ?? UsersDao(LocalDatabaseService.instance),
       _queueDataSource = queueDataSource;

  String? get _userId => _client.auth.currentUser?.id;

  Future<String?> _getUserEmail() async {
    final user = _client.auth.currentUser;
    if (user != null) return user.email;

    try {
      final userId = _userId;
      if (userId != null) {
        final localUser = await _usersDao.getUser(userId);
        if (localUser?.email.isNotEmpty == true) return localUser!.email;
      }
    } catch (_) {}
    return null;
  }

  // ---------------------------------------------------------------------------
  // Send invitation (online-only, via RPC)
  // ---------------------------------------------------------------------------

  @override
  Future<InvitationModel> sendInvitation({
    required String homeId,
    required String email,
    required String role,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('must_login_first');

    try {
      final response = await _client.rpc(
        'create_invitation',
        params: {'p_home_id': homeId, 'p_email': email, 'p_role': role},
      );

      final model = InvitationModel.fromJson(response as Map<String, dynamic>);

      // Save to local
      await _invitationsDao.upsertInvitations([model.toLocalRow()]);

      return model;
    } on PostgrestException catch (e) {
      if (e.message.contains('already an active member')) {
        throw Exception('already_a_member');
      }
      if (e.message.contains('pending invitation already exists')) {
        throw Exception('pending_invitation_exists');
      }
      if (e.message.contains('Only owners and admins')) {
        throw Exception('no_permission_to_invite');
      }
      if (e.message.contains('gen_random_bytes')) {
        throw Exception('invitation_code_generation_failed');
      }
      throw Exception('send_invitation_failed: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // Accept invitation (requires RPC - online-only)
  // ---------------------------------------------------------------------------

  @override
  Future<InvitationModel> acceptInvitation({required String token}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('must_login_first');

    try {
      final response = await _client.rpc(
        'accept_invitation',
        params: {'invitation_token': token},
      );

      final model = InvitationModel.fromJson(response as Map<String, dynamic>);
      await _invitationsDao.upsertInvitations([model.toLocalRow()]);
      unawaited(
        NotificationService.sendInvitationNotification(
          eventType: 'invitation_accepted',
          homeId: model.homeId,
          actorId: user.id,
          invitationId: model.id,
          targetUserIds: [model.invitedBy],
          context: {
            'home_name': 'home',
            if (model.email != null) 'email': model.email!,
          },
        ),
      );
      return model;
    } catch (e) {
      if (e.toString().contains('Not authenticated')) {
        throw Exception('must_login_first');
      } else if (e.toString().contains('Invitation not found')) {
        throw Exception('invitation_not_found_or_handled');
      } else if (e.toString().contains('Invitation expired')) {
        throw Exception('invitation_expired');
      } else if (e.toString().contains('Unauthorized')) {
        throw Exception('not_authorized_accept_invitation');
      }
      throw Exception('accept_invitation_failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Decline invitation (local-first + outbox)
  // ---------------------------------------------------------------------------

  @override
  Future<InvitationModel> declineInvitation({required String token}) async {
    // Look up the invitation locally first
    final localInvitation = await _invitationsDao.getInvitationByToken(token);

    // Update local status immediately
    if (localInvitation != null) {
      await _invitationsDao.updateStatus(
        invitationId: localInvitation.id,
        status: 'cancelled',
      );
    }

    // Try Supabase
    try {
      final invitation = await _client
          .from('invitations')
          .select()
          .eq('token', token)
          .eq('status', 'pending')
          .maybeSingle();

      if (invitation == null) {
        if (localInvitation != null) {
          return localInvitation.toInvitationModel();
        }
        throw Exception('invitation_not_found');
      }

      final response = await _client
          .from('invitations')
          .update({'status': 'cancelled'})
          .eq('id', invitation['id'])
          .select()
          .maybeSingle();

      if (response != null) {
        final model = InvitationModel.fromJson(response);
        await _invitationsDao.upsertInvitations([model.toLocalRow()]);
        final actorId = _userId;
        if (actorId != null) {
          unawaited(
            NotificationService.sendInvitationNotification(
              eventType: 'invitation_declined',
              homeId: model.homeId,
              actorId: actorId,
              invitationId: model.id,
              targetUserIds: [model.invitedBy],
              context: {
                'home_name': 'home',
                if (model.email != null) 'email': model.email!,
              },
            ),
          );
        }
        return model;
      }
    } catch (_) {
      // Enqueue to outbox on failure
      await _queueDataSource.enqueueAction(
        actionType: ActionType.declineInvitation,
        entityType: EntityType.invitation,
        entityId: localInvitation?.id ?? token,
        homeId: localInvitation?.homeId,
        scope: MutationScope.user,
        payload: {'token': token},
      );
    }

    if (localInvitation != null) {
      return localInvitation.toInvitationModel();
    }
    throw Exception('invitation_not_found');
  }

  // ---------------------------------------------------------------------------
  // Cancel invitation (local-first + outbox)
  // ---------------------------------------------------------------------------

  @override
  Future<InvitationModel> cancelInvitation({
    required String invitationId,
  }) async {
    // Update local status immediately
    await _invitationsDao.updateStatus(
      invitationId: invitationId,
      status: 'cancelled',
    );

    // Try Supabase
    try {
      final response = await _client
          .from('invitations')
          .update({'status': 'cancelled'})
          .eq('id', invitationId)
          .select()
          .maybeSingle();

      if (response != null) {
        final model = InvitationModel.fromJson(response);
        await _invitationsDao.upsertInvitations([model.toLocalRow()]);
        return model;
      }
    } catch (_) {
      // Enqueue to outbox on failure
      await _queueDataSource.enqueueAction(
        actionType: ActionType.cancelInvitation,
        entityType: EntityType.invitation,
        entityId: invitationId,
        scope: MutationScope.user,
        payload: {'invitation_id': invitationId},
      );
    }

    // Return local state
    final local = await _invitationsDao.getInvitationById(invitationId);
    if (local != null) return local.toInvitationModel();

    throw Exception('no_permission_to_cancel');
  }

  // ---------------------------------------------------------------------------
  // Get home invitations (Drift-first)
  // ---------------------------------------------------------------------------

  @override
  Future<List<InvitationModel>> getHomeInvitations({
    required String homeId,
  }) async {
    // 1. Read from Drift first
    final localRows = await _invitationsDao.getHomeInvitations(homeId);

    // 2. Refresh from remote in background
    _refreshHomeInvitationsFromRemote(homeId);

    if (localRows.isNotEmpty) {
      return localRows.map((r) => r.toInvitationModel()).toList();
    }

    return [];
  }

  Future<void> _refreshHomeInvitationsFromRemote(String homeId) async {
    try {
      final response = await _client
          .from('invitations')
          .select()
          .eq('home_id', homeId)
          .order('created_at', ascending: false);

      final models = (response as List)
          .map((json) => InvitationModel.fromJson(json))
          .toList();

      await _invitationsDao.upsertInvitations(
        models.map((m) => m.toLocalRow()).toList(),
      );
    } catch (_) {
      // Silent fail
    }
  }

  // ---------------------------------------------------------------------------
  // Get user invitations (Drift-first)
  // ---------------------------------------------------------------------------

  @override
  Future<List<InvitationModel>> getUserInvitations() async {
    final userEmail = await _getUserEmail();
    if (userEmail == null) return [];

    // 1. Read from Drift first
    final localRows = await _invitationsDao.getUserInvitations(userEmail);

    // 2. Refresh from remote in background
    _refreshUserInvitationsFromRemote(userEmail);

    if (localRows.isNotEmpty) {
      return localRows.map((r) => r.toInvitationModel()).toList();
    }

    return [];
  }

  Future<void> _refreshUserInvitationsFromRemote(String email) async {
    try {
      final response = await _client
          .from('invitations')
          .select()
          .eq('email', email)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final models = (response as List)
          .map((json) => InvitationModel.fromJson(json))
          .toList();

      final currentUserId = _userId;
      await _invitationsDao.upsertInvitations(
        models.map((m) => m.toLocalRow(userId: currentUserId)).toList(),
      );
    } catch (_) {
      // Silent fail
    }
  }

  // ---------------------------------------------------------------------------
  // Get invitation by token
  // ---------------------------------------------------------------------------

  @override
  Future<InvitationModel?> getInvitationByToken({required String token}) async {
    // 1. Try local first
    final localRow = await _invitationsDao.getInvitationByToken(token);
    if (localRow != null) {
      // Refresh in background
      _refreshInvitationByTokenFromRemote(token);
      return localRow.toInvitationModel();
    }

    // 2. Fallback to remote
    try {
      final response = await _client
          .from('invitations')
          .select()
          .eq('token', token)
          .maybeSingle();

      if (response == null) return null;
      final model = InvitationModel.fromJson(response);
      await _invitationsDao.upsertInvitations([model.toLocalRow()]);
      return model;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshInvitationByTokenFromRemote(String token) async {
    try {
      final response = await _client
          .from('invitations')
          .select()
          .eq('token', token)
          .maybeSingle();

      if (response != null) {
        final model = InvitationModel.fromJson(response);
        await _invitationsDao.upsertInvitations([model.toLocalRow()]);
      }
    } catch (_) {
      // Silent fail
    }
  }

  // ---------------------------------------------------------------------------
  // Watch home invitations (Drift stream + remote refresh)
  // ---------------------------------------------------------------------------

  @override
  Stream<List<InvitationModel>> watchHomeInvitations({
    required String homeId,
  }) async* {
    // 1. Refresh from remote first
    await _refreshHomeInvitationsFromRemote(homeId);

    // 2. Emit from Drift stream
    yield* _invitationsDao
        .watchHomeInvitations(homeId)
        .map(
          (rows) => rows
              .map((r) => r.toInvitationModel())
              .where((inv) => inv.isPending)
              .toList(),
        );
  }

  // ---------------------------------------------------------------------------
  // Watch user invitations (Drift stream + remote refresh)
  // ---------------------------------------------------------------------------

  @override
  Stream<List<InvitationModel>> watchUserInvitations() async* {
    final userEmail = await _getUserEmail();
    if (userEmail == null) {
      yield [];
      return;
    }

    // 1. Refresh from remote first
    await _refreshUserInvitationsFromRemote(userEmail);

    // 2. Emit from Drift stream
    yield* _invitationsDao
        .watchUserInvitations(userEmail)
        .map(
          (rows) => rows
              .map((r) => r.toInvitationModel())
              .where((inv) => inv.isPending)
              .toList(),
        );
  }
}
