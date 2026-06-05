import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/homes/data/models/home_model.dart';
import 'package:sawa/features/homes/data/repositories/home_repository.dart';
import 'package:sawa/features/homes/domain/usecases/create_home_usecase.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late MockHomeRepository mockRepository;
  late CreateHomeUseCase useCase;

  setUp(() {
    mockRepository = MockHomeRepository();
    useCase = CreateHomeUseCase(mockRepository);
  });

  group('CreateHomeUseCase', () {
    const tName = 'Sweet Home';
    const tType = 'family';
    const tCurrency = 'SAR';

    final tHome = HomeModel(
      id: 'home-123',
      name: tName,
      type: tType,
      defaultCurrency: tCurrency,
      ownerId: 'user-123',
      createdAt: DateTime.parse('2026-05-28T00:00:00Z'),
    );

    test('should create home through repository', () async {
      when(() => mockRepository.createHome(
            name: any(named: 'name'),
            type: any(named: 'type'),
            defaultCurrency: any(named: 'defaultCurrency'),
          )).thenAnswer((_) async => tHome);

      final result = await useCase(name: tName, type: tType, defaultCurrency: tCurrency);

      expect(result, tHome);
      verify(() => mockRepository.createHome(
            name: tName,
            type: tType,
            defaultCurrency: tCurrency,
          )).called(1);
    });
  });
}
