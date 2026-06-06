import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/core/errors/app_exception.dart';
import 'package:sawa/features/auth/data/models/user_model.dart';
import 'package:sawa/features/auth/data/repositories/auth_repository.dart';
import 'package:sawa/features/auth/domain/usecases/update_profile_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late UpdateProfileUseCase useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = UpdateProfileUseCase(mockRepository);
  });

  final tUser = UserModel(
    id: 'user-123',
    fullName: 'Updated Name',
    email: 'test@example.com',
    phone: '+1234567890',
    createdAt: DateTime(2026, 1, 1),
  );

  group('UpdateProfileUseCase', () {
    test('should return updated user on success', () async {
      when(
        () => mockRepository.updateProfile(
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          avatarUrl: any(named: 'avatarUrl'),
        ),
      ).thenAnswer((_) async => tUser);

      final result = await useCase(
        fullName: 'Updated Name',
        phone: '+1234567890',
      );

      expect(result, tUser);
      verify(
        () => mockRepository.updateProfile(
          fullName: 'Updated Name',
          phone: '+1234567890',
        ),
      ).called(1);
    });

    test('should throw AuthException on network error', () async {
      when(
        () => mockRepository.updateProfile(
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          avatarUrl: any(named: 'avatarUrl'),
        ),
      ).thenThrow(const AuthException(message: 'profile_update_failed'));

      expect(
        () => useCase(fullName: 'Updated Name'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('profile_update_failed'),
          ),
        ),
      );
    });

    test('should throw ValidationException on validation error', () async {
      when(
        () => mockRepository.updateProfile(
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          avatarUrl: any(named: 'avatarUrl'),
        ),
      ).thenThrow(const ValidationException(message: 'Name cannot be empty'));

      expect(
        () => useCase(fullName: ''),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'Name cannot be empty',
          ),
        ),
      );
    });

    test('should pass null fields correctly', () async {
      when(
        () => mockRepository.updateProfile(
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          avatarUrl: any(named: 'avatarUrl'),
        ),
      ).thenAnswer((_) async => tUser);

      await useCase(avatarUrl: 'https://example.com/avatar.png');

      verify(
        () => mockRepository.updateProfile(
          avatarUrl: 'https://example.com/avatar.png',
        ),
      ).called(1);
    });
  });
}
