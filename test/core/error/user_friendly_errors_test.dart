import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User Friendly Errors', () {
    test('Format exception is converted to friendly message', () {
      final rawError = FormatException('Unexpected character');
      final friendlyError = ErrorHandler.getFriendlyMessage(rawError);
      
      expect(friendlyError.contains('FormatException'), false);
      expect(friendlyError, 'حدث خطأ في تنسيق البيانات. يرجى المحاولة مرة أخرى.');
    });

    test('TypeError is converted to friendly message', () {
      try {
        dynamic a = 1;
        a.substring(1); // throws TypeError or NoSuchMethodError
      } catch (e) {
        final friendlyError = ErrorHandler.getFriendlyMessage(e);
        expect(friendlyError.contains('TypeError'), false);
        expect(friendlyError.contains('NoSuchMethodError'), false);
        expect(friendlyError, 'حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.');
      }
    });

    test('Database Exceptions are converted to friendly messages', () {
      final rawError = Exception('PostgresError: null value in column "name"');
      final friendlyError = ErrorHandler.getFriendlyMessage(rawError);
      
      expect(friendlyError.contains('PostgresError'), false);
      expect(friendlyError, 'حدث خطأ في الاتصال بقاعدة البيانات.');
    });
    
    test('Network exceptions are converted to friendly messages', () {
      final rawError = Exception('SocketException: Failed host lookup');
      final friendlyError = ErrorHandler.getFriendlyMessage(rawError);
      
      expect(friendlyError, 'تأكد من اتصالك بالإنترنت وحاول مرة أخرى.');
    });
  });
}

class ErrorHandler {
  static String getFriendlyMessage(dynamic error) {
    final errorString = error.toString();
    
    if (error is FormatException || errorString.contains('FormatException')) {
      return 'حدث خطأ في تنسيق البيانات. يرجى المحاولة مرة أخرى.';
    }
    if (errorString.contains('SocketException') || errorString.contains('Network')) {
      return 'تأكد من اتصالك بالإنترنت وحاول مرة أخرى.';
    }
    if (errorString.contains('PostgresError') || errorString.contains('Database')) {
      return 'حدث خطأ في الاتصال بقاعدة البيانات.';
    }
    
    // Default fallback
    return 'حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.';
  }
}
