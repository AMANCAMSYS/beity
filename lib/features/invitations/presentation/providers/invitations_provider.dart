import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/invitation_model.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../data/repositories/supabase_invitation_repository.dart';

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  return SupabaseInvitationRepository(Supabase.instance.client);
});

final userInvitationsProvider = FutureProvider<List<InvitationModel>>((ref) async {
  final repo = ref.read(invitationRepositoryProvider);
  return repo.getUserInvitations();
});

final homeInvitationsProvider = FutureProvider.family<List<InvitationModel>, String>((ref, homeId) async {
  final repo = ref.read(invitationRepositoryProvider);
  return repo.getHomeInvitations(homeId: homeId);
});

final userInvitationsStreamProvider = StreamProvider<List<InvitationModel>>((ref) {
  final repo = ref.read(invitationRepositoryProvider);
  return repo.watchUserInvitations();
});

final homeInvitationsStreamProvider = StreamProvider.family<List<InvitationModel>, String>((ref, homeId) {
  final repo = ref.read(invitationRepositoryProvider);
  return repo.watchHomeInvitations(homeId: homeId);
});

class InvitationNotifier extends StateNotifier<AsyncValue<void>> {
  final InvitationRepository _repo;

  InvitationNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<InvitationModel> sendInvitation({
    required String homeId,
    required String email,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    try {
      final invitation = await _repo.sendInvitation(
        homeId: homeId,
        email: email,
        role: role,
      );
      state = const AsyncValue.data(null);
      return invitation;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<InvitationModel> acceptInvitation({
    required String token,
  }) async {
    state = const AsyncValue.loading();
    try {
      final invitation = await _repo.acceptInvitation(
        token: token,
      );
      state = const AsyncValue.data(null);
      return invitation;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<InvitationModel> declineInvitation({
    required String token,
  }) async {
    state = const AsyncValue.loading();
    try {
      final invitation = await _repo.declineInvitation(
        token: token,
      );
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
      final invitation = await _repo.cancelInvitation(
        invitationId: invitationId,
      );
      state = const AsyncValue.data(null);
      return invitation;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

final invitationNotifierProvider =
    StateNotifierProvider<InvitationNotifier, AsyncValue<void>>((ref) {
  final repo = ref.read(invitationRepositoryProvider);
  return InvitationNotifier(repo);
});
