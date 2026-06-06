import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/core/errors/app_exception.dart';
import 'package:sawa/features/auth/data/models/user_model.dart';
import 'package:sawa/features/auth/data/repositories/auth_repository.dart';
import 'package:sawa/features/auth/domain/usecases/sign_up_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late SignUpUseCase useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignUpUseCase(mockRepository);
  });

  final tUser = UserModel(
    id: 'user-123',
    fullName: 'Test User',
    email: 'test@example.com',
    createdAt: DateTime(2026, 1, 1),
  );

  group('SignUpUseCase', () {
    test('should return user on successful sign up', () async {
      when(
        () => mockRepository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fullName: any(named: 'fullName'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => tUser);

      final result = await useCase(
        email: 'test@example.com',
        password: 'Password123!',
        fullName: 'Test User',
      );

      expect(result, tUser);
      verify(
        () => mockRepository.signUp(
          email: 'test@example.com',
          password: 'Password123!',
          fullName: 'Test User',
        ),
      ).called(1);
    });

    test('should throw AuthException on duplicate email', () async {
      when(
        () => mockRepository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fullName: any(named: 'fullName'),
          language: any(named: 'language'),
        ),
      ).thenThrow(const AuthException(message: 'email_already_registered'));

      expect(
        () => useCase(
          email: 'existing@example.com',
          password: 'Password123!',
          fullName: 'Test User',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'email_already_registered',
          ),
        ),
      );
    });

    test('should throw AuthException on weak password', () async {
      when(
        () => mockRepository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fullName: any(named: 'fullName'),
          language: any(named: 'language'),
        ),
      ).thenThrow(const AuthException(message: 'weak_password'));

      expect(
        () => useCase(
          email: 'test@example.com',
          password: '123',
          fullName: 'Test User',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'weak_password',
          ),
        ),
      );
    });

    test(
      'should throw EmailConfirmationRequiredException when email confirmation is required',
      () async {
        when(
          () => mockRepository.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
            language: any(named: 'language'),
          ),
        ).thenThrow(
          const EmailConfirmationRequiredException(email: 'test@example.com'),
        );

        expect(
          () => useCase(
            email: 'test@example.com',
            password: 'Password123!',
            fullName: 'Test User',
          ),
          throwsA(
            isA<EmailConfirmationRequiredException>()
                .having((e) => e.email, 'email', 'test@example.com')
                .having((e) => e.code, 'code', 'email_confirmation_required'),
          ),
        );
      },
    );

    test('should pass language parameter correctly', () async {
      when(
        () => mockRepository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fullName: any(named: 'fullName'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => tUser);

      await useCase(
        email: 'test@example.com',
        password: 'Password123!',
        fullName: 'Test User',
        language: 'ar',
      );

      verify(
        () => mockRepository.signUp(
          email: 'test@example.com',
          password: 'Password123!',
          fullName: 'Test User',
          language: 'ar',
        ),
      ).called(1);
    });
  });
}
