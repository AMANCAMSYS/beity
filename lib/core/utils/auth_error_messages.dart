class AuthErrorMessages {
  static String mapError(String code) {
    switch (code) {
      case 'invalid_credentials':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'user_already_registered':
      case 'email_address_invalid':
        return 'هذا البريد الإلكتروني مسجل بالفعل';
      case 'weak_password':
        return 'كلمة المرور ضعيفة، يجب أن تكون 8 أحرف على الأقل';
      case 'invalid_email':
        return 'البريد الإلكتروني غير صالح';
      case 'network_error':
        return 'لا يوجد اتصال بالإنترنت، يرجى المحاولة مرة أخرى';
      case 'session_expired':
        return 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى';
      default:
        return 'حدث خطأ، يرجى المحاولة مرة أخرى';
    }
  }

  static String validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'البريد الإلكتروني غير صالح';
    }
    return '';
  }

  static String validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    if (value.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    return '';
  }

  static String validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال الاسم';
    }
    if (value.length > 100) {
      return 'الاسم طويل جداً';
    }
    return '';
  }
}
