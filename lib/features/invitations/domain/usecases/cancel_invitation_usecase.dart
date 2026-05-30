import '../entities/invitation.dart';
import '../../data/repositories/invitation_repository.dart';

class CancelInvitationUseCase {
  final InvitationRepository _repository;

  CancelInvitationUseCase(this._repository);

  Future<Invitation> call({required String invitationId}) async {
    if (invitationId.isEmpty) {
      throw Exception('معرف الدعوة غير صالح');
    }

    return _repository.cancelInvitation(invitationId: invitationId);
  }
}
