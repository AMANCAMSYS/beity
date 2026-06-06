import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawa/core/services/supabase_service.dart';

import '../../../homes/presentation/providers/homes_provider.dart';
import '../../data/models/invitation_model.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../data/repositories/local_first_invitation_repository.dart';
import '../../../offline_queue/presentation/providers/offline_queue_provider.dart';

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  final queueDataSource = ref.read(queueDataSourceProvider);
  return LocalFirstInvitationRepository(
    client: SupabaseService.client,
    queueDataSource: queueDataSource,
  );
});

final userInvitationsProvider = FutureProvider<List<InvitationModel>>((
  ref,
) async {
  final repo = ref.read(invitationRepositoryProvider);
  return repo.getUserInvitations();
});

final homeInvitationsProvider =
    FutureProvider.family<List<InvitationModel>, String>((ref, homeId) async {
      final repo = ref.read(invitationRepositoryProvider);
      return repo.getHomeInvitations(homeId: homeId);
    });

final userInvitationsStreamProvider = StreamProvider<List<InvitationModel>>((
  ref,
) {
  final repo = ref.read(invitationRepositoryProvider);
  return repo.watchUserInvitations();
});

final homeInvitationsStreamProvider = StreamProvider.autoDispose
    .family<List<InvitationModel>, String>((ref, homeId) {
      final repo = ref.read(invitationRepositoryProvider);
      return repo.watchHomeInvitations(homeId: homeId);
    });

class InvitationNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  void _invalidateRelatedProviders(String homeId) {
    ref.invalidate(homeInvitationsStreamProvider(homeId));
    ref.invalidate(homeInvitationsProvider(homeId));
    ref.invalidate(userInvitationsStreamProvider);
    ref.invalidate(userInvitationsProvider);
    ref.invalidate(homeMembersProvider(homeId));
    ref.invalidate(userHomesProvider);
    ref.invalidate(hasHomesProvider);
    ref.invalidate(activeHomeIdProvider);
  }

  Future<InvitationModel> sendInvitation({
    required String homeId,
    required String email,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    try {
      final invitation = await ref
          .read(invitationRepositoryProvider)
          .sendInvitation(homeId: homeId, email: email, role: role);
      _invalidateRelatedProviders(homeId);
      state = const AsyncValue.data(null);
      return invitation;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<InvitationModel> acceptInvitation({required String token}) async {
    state = const AsyncValue.loading();
    try {
      final invitation = await ref
          .read(invitationRepositoryProvider)
          .acceptInvitation(token: token);

      try {
        final homeRepo = ref.read(homeRepositoryProvider);
        await homeRepo.syncHomesWithServer();
        await homeRepo.syncMembersWithServer(invitation.homeId);
      } catch (_) {}

      _invalidateRelatedProviders(invitation.homeId);
      state = const AsyncValue.data(null);
      return invitation;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<InvitationModel> declineInvitation({required String token}) async {
    state = const AsyncValue.loading();
    try {
      final invitation = await ref
          .read(invitationRepositoryProvider)
          .declineInvitation(token: token);
      _invalidateRelatedProviders(invitation.homeId);
      state = const AsyncValue.data(null);
      return invitation;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<InvitationModel> cancelInvitation({
    required String invitationId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final invitation = await ref
          .read(invitationRepositoryProvider)
          .cancelInvitation(invitationId: invitationId);
      _invalidateRelatedProviders(invitation.homeId);
      state = const AsyncValue.data(null);
      return invitation;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final invitationNotifierProvider =
    AsyncNotifierProvider<InvitationNotifier, void>(() {
      return InvitationNotifier();
    });
