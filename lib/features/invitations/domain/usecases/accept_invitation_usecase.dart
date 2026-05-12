import '../entities/invitation.dart';
import '../../data/repositories/invitation_repository.dart';

class AcceptInvitationUseCase {
  final InvitationRepository _repository;

  AcceptInvitationUseCase(this._repository);

  Future<Invitation> call({required String token}) async {
    if (token.isEmpty) {
      throw Exception('رمز الدعوة غير صالح');
    }

    return await _repository.acceptInvitation(token: token);
  }
}
