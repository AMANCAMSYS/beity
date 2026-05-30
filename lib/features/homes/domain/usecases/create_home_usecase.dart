import '../../data/repositories/home_repository.dart';
import '../../data/models/home_model.dart';

class CreateHomeUseCase {
  final HomeRepository _repository;

  CreateHomeUseCase(this._repository);

  Future<HomeModel> call({
    required String name,
    required String type,
    String? defaultCurrency,
  }) async {
    return _repository.createHome(
      name: name,
      type: type,
      defaultCurrency: defaultCurrency,
    );
  }
}
