import '../entities/invitation.dart';
import '../../data/repositories/invitation_repository.dart';

class DeclineInvitationUseCase {
  final InvitationRepository _repository;

  DeclineInvitationUseCase(this._repository);

  Future<Invitation> call({required String token}) async {
    if (token.isEmpty) {
      throw Exception('رمز الدعوة غير صالح');
    }

    return await _repository.declineInvitation(token: token);
  }
}
