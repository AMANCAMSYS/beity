import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/features/homes/data/repositories/home_local_data_source.dart';
import 'package:sawa/features/homes/domain/usecases/switch_home_usecase.dart';

class MockHomeLocalDataSource extends Mock implements HomeLocalDataSource {}

void main() {
  late MockHomeLocalDataSource mockLocalDataSource;
  late SwitchHomeUseCase useCase;

  setUp(() {
    mockLocalDataSource = MockHomeLocalDataSource();
    useCase = SwitchHomeUseCase(mockLocalDataSource);
  });

  group('SwitchHomeUseCase', () {
    const tHomeId = 'home-123';
    const tHomeName = 'Sweet Home';

    test('should set active home in local data source', () async {
      when(() => mockLocalDataSource.setActiveHome(any(), any()))
          .thenAnswer((_) async => {});

      await useCase(tHomeId, tHomeName);

      verify(() => mockLocalDataSource.setActiveHome(tHomeId, tHomeName)).called(1);
    });
  });
}
