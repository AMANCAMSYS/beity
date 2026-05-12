import '../../data/repositories/home_local_data_source.dart';

class SwitchHomeUseCase {
  final HomeLocalDataSource _localDataSource;

  SwitchHomeUseCase(this._localDataSource);

  Future<void> call(String homeId, String homeName) async {
    await _localDataSource.setActiveHome(homeId, homeName);
  }
}
