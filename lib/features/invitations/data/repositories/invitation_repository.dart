import '../models/invitation_model.dart';

abstract class InvitationRepository {
  Future<InvitationModel> sendInvitation({
    required String homeId,
    required String email,
    required String role,
  });

  Future<InvitationModel> acceptInvitation({required String token});

  Future<InvitationModel> declineInvitation({required String token});

  Future<InvitationModel> cancelInvitation({required String invitationId});

  Future<List<InvitationModel>> getHomeInvitations({required String homeId});

  Future<List<InvitationModel>> getUserInvitations();

  Future<InvitationModel?> getInvitationByToken({required String token});

  Stream<List<InvitationModel>> watchHomeInvitations({required String homeId});

  Stream<List<InvitationModel>> watchUserInvitations();
}
