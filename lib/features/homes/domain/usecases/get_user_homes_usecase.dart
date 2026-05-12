import '../../data/repositories/home_repository.dart';
import '../../data/models/home_model.dart';

class GetUserHomesUseCase {
  final HomeRepository _repository;

  GetUserHomesUseCase(this._repository);

  Future<List<HomeModel>> call() async {
    return await _repository.getUserHomes();
  }
}
