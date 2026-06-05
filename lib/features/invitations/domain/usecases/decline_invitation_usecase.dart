import '../entities/invitation.dart';
import '../../data/repositories/invitation_repository.dart';

class DeclineInvitationUseCase {
  final InvitationRepository _repository;

  DeclineInvitationUseCase(this._repository);

  Future<Invitation> call({required String token}) async {
    if (token.isEmpty) {
      throw Exception('invalid_invitation_code');
    }

    return _repository.declineInvitation(token: token);
  }
}
