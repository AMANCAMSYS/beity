import '../../../../core/errors/app_exception.dart';
import '../entities/invitation.dart';
import '../../data/repositories/invitation_repository.dart';

class SendInvitationUseCase {
  final InvitationRepository _repository;

  SendInvitationUseCase(this._repository);

  Future<Invitation> call({
    required String homeId,
    required String email,
    required String role,
  }) async {
    // Validate email
    if (email.isEmpty) {
      throw const ValidationException(message: 'please_enter_email_validation');
    }

    if (!_isValidEmail(email)) {
      throw const ValidationException(message: 'invalid_email_format');
    }

    // Validate role
    if (!_isValidRole(role)) {
      throw const ValidationException(message: 'invalid_role_selected');
    }

    return _repository.sendInvitation(
      homeId: homeId,
      email: email,
      role: role,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidRole(String role) {
    return ['admin', 'member', 'viewer'].contains(role);
  }
}
