import '../entities/invitation.dart';
import '../../data/repositories/invitation_repository.dart';

class AcceptInvitationUseCase {
  final InvitationRepository _repository;

  AcceptInvitationUseCase(this._repository);

  Future<Invitation> call({required String token}) async {
    if (token.isEmpty) {
      throw Exception('invalid_invitation_code');
    }

    return _repository.acceptInvitation(token: token);
  }
}
