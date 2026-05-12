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
      throw Exception('يرجى إدخال البريد الإلكتروني');
    }

    if (!_isValidEmail(email)) {
      throw Exception('البريد الإلكتروني غير صالح');
    }

    // Validate role
    if (!_isValidRole(role)) {
      throw Exception('الدور غير صالح');
    }

    return await _repository.sendInvitation(
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
