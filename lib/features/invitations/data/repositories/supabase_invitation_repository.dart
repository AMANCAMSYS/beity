import 'dart:convert';
import 'package:sawa/core/local_database/daos/users_dao.dart';
import 'package:sawa/core/local_database/local_database_service.dart';
import 'package:sawa/core/services/shared_prefs_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invitation_model.dart';
import 'invitation_repository.dart';

class SupabaseInvitationRepository implements InvitationRepository {
  final SupabaseClient _client;
  final UsersDao _usersDao;

  SupabaseInvitationRepository(this._client, {UsersDao? usersDao})
    : _usersDao = usersDao ?? UsersDao(LocalDatabaseService.instance);

  @override
  Future<InvitationModel> sendInvitation({
    required String homeId,
    required String email,
    required String role,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    try {
      // Use server-side RPC for secure token generation and validation
      final response = await _client.rpc(
        'create_invitation',
        params: {'p_home_id': homeId, 'p_email': email, 'p_role': role},
      );

      return InvitationModel.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      // Map server errors to user-friendly messages
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

  @override
  Future<InvitationModel> acceptInvitation({required String token}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    try {
      final response = await _client.rpc(
        'accept_invitation',
        params: {'invitation_token': token},
      );
      return InvitationModel.fromJson(response as Map<String, dynamic>);
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

  @override
  Future<InvitationModel> declineInvitation({required String token}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final invitation = await _client
        .from('invitations')
        .select()
        .eq('token', token)
        .eq('status', 'pending')
        .maybeSingle();

    if (invitation == null) {
      throw Exception('invitation_not_found');
    }

    final response = await _client
        .from('invitations')
        .update({'status': 'cancelled'})
        .eq('id', invitation['id'])
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('no_permission_to_decline');
    }

    return InvitationModel.fromJson(response);
  }

  @override
  Future<InvitationModel> cancelInvitation({
    required String invitationId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('must_login_first');
    }

    final invitation = await _client
        .from('invitations')
        .select()
        .eq('id', invitationId)
        .maybeSingle();

    if (invitation == null) {
      throw Exception('invitation_not_found');
    }

    final response = await _client
        .from('invitations')
        .update({'status': 'cancelled'})
        .eq('id', invitationId)
        .select()
        .maybeSingle();

    if (response == null) {
      throw Exception('no_permission_to_cancel');
    }

    return InvitationModel.fromJson(response);
  }

  @override
  Future<List<InvitationModel>> getHomeInvitations({
    required String homeId,
  }) async {
    final cacheKey = 'cached_home_invitations_$homeId';
    try {
      final response = await _client
          .from('invitations')
          .select()
          .eq('home_id', homeId)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((json) => InvitationModel.fromJson(json))
          .toList();

      // Cache
      try {
        final prefs = AppPreferences.instance;
        final rawJson = jsonEncode(list.map((i) => i.toJson()).toList());
        await prefs.setString(cacheKey, rawJson);
      } catch (_) {}

      return list;
    } catch (e) {
      // Fallback
      try {
        final prefs = AppPreferences.instance;
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          final List<dynamic> list = jsonDecode(cached);
          return list
              .map(
                (item) =>
                    InvitationModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
      } catch (_) {}
      rethrow;
    }
  }

  Future<String?> _getUserId() async {
    final user = _client.auth.currentUser;
    if (user != null) return user.id;

    try {
      final prefs = AppPreferences.instance;
      return prefs.getString('last_logged_in_user_id');
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getUserEmail() async {
    final user = _client.auth.currentUser;
    if (user != null) return user.email;

    try {
      final userId = await _getUserId();
      if (userId != null) {
        final localUser = await _usersDao.getUser(userId);
        if (localUser?.email.isNotEmpty == true) return localUser!.email;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<InvitationModel>> getUserInvitations() async {
    final userId = await _getUserId();
    final userEmail = await _getUserEmail();
    if (userId == null || userEmail == null) return [];
    final cacheKey = 'cached_user_invitations_$userId';

    try {
      final response = await _client
          .from('invitations')
          .select()
          .eq('email', userEmail)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((json) => InvitationModel.fromJson(json))
          .toList();

      // Cache
      try {
        final prefs = AppPreferences.instance;
        final rawJson = jsonEncode(list.map((i) => i.toJson()).toList());
        await prefs.setString(cacheKey, rawJson);
      } catch (_) {}

      return list;
    } catch (e) {
      // Fallback
      try {
        final prefs = AppPreferences.instance;
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          final List<dynamic> list = jsonDecode(cached);
          return list
              .map(
                (item) =>
                    InvitationModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<InvitationModel?> getInvitationByToken({required String token}) async {
    final response = await _client
        .from('invitations')
        .select()
        .eq('token', token)
        .maybeSingle();

    if (response == null) return null;
    return InvitationModel.fromJson(response);
  }

  @override
  Stream<List<InvitationModel>> watchHomeInvitations({
    required String homeId,
  }) async* {
    final cacheKey = 'cached_home_invitations_$homeId';

    // 1. Emit cached invitations immediately
    try {
      final prefs = AppPreferences.instance;
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final List<dynamic> list = jsonDecode(cached);
        yield list
            .map(
              (item) => InvitationModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (_) {}

    // 2. Subscribe to remote stream
    try {
      await for (final response
          in _client
              .from('invitations')
              .stream(primaryKey: ['id'])
              .eq('home_id', homeId)
              .order('created_at', ascending: false)) {
        final list = response
            .map((json) => InvitationModel.fromJson(json))
            .where((inv) => inv.isPending)
            .toList();

        try {
          final prefs = AppPreferences.instance;
          final rawJson = jsonEncode(list.map((i) => i.toJson()).toList());
          await prefs.setString(cacheKey, rawJson);
        } catch (_) {}

        yield list;
      }
    } catch (_) {
      // Absorb stream errors when offline
    }
  }

  @override
  Stream<List<InvitationModel>> watchUserInvitations() async* {
    final userId = await _getUserId();
    final userEmail = await _getUserEmail();
    if (userId == null || userEmail == null) {
      yield [];
      return;
    }
    final cacheKey = 'cached_user_invitations_$userId';

    // 1. Emit cached invitations immediately
    try {
      final prefs = AppPreferences.instance;
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final List<dynamic> list = jsonDecode(cached);
        yield list
            .map(
              (item) => InvitationModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (_) {}

    // 2. Subscribe to remote stream
    try {
      await for (final response
          in _client
              .from('invitations')
              .stream(primaryKey: ['id'])
              .eq('email', userEmail)
              .order('created_at', ascending: false)) {
        final list = response
            .map((json) => InvitationModel.fromJson(json))
            .where((inv) => inv.isPending)
            .toList();

        try {
          final prefs = AppPreferences.instance;
          final rawJson = jsonEncode(list.map((i) => i.toJson()).toList());
          await prefs.setString(cacheKey, rawJson);
        } catch (_) {}

        yield list;
      }
    } catch (_) {
      // Absorb stream errors when offline
    }
  }
}
