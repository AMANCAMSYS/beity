import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/homes/data/models/home_member_model.dart';
import 'package:sawa/features/homes/data/repositories/home_repository.dart';
import 'package:sawa/features/homes/domain/usecases/get_home_members_usecase.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late MockHomeRepository mockRepository;
  late GetHomeMembersUseCase useCase;

  setUp(() {
    mockRepository = MockHomeRepository();
    useCase = GetHomeMembersUseCase(mockRepository);
  });

  group('GetHomeMembersUseCase', () {
    const tHomeId = 'home-123';

    final tMembers = [
      HomeMemberModel(
        id: 'member-1',
        homeId: tHomeId,
        userId: 'user-1',
        userName: 'Omar',
        userEmail: 'omar@sawa.com',
        role: 'owner',
        joinedAt: DateTime.parse('2026-05-28T00:00:00Z'),
      ),
      HomeMemberModel(
        id: 'member-2',
        homeId: tHomeId,
        userId: 'user-2',
        userName: 'Ahmad',
        userEmail: 'ahmad@sawa.com',
        role: 'member',
        joinedAt: DateTime.parse('2026-05-28T00:00:00Z'),
      ),
    ];

    test('should get list of home members from repository', () async {
      when(
        () => mockRepository.getHomeMembers(any()),
      ).thenAnswer((_) async => tMembers);

      final result = await useCase(tHomeId);

      expect(result, tMembers);
      verify(() => mockRepository.getHomeMembers(tHomeId)).called(1);
    });
  });
}
