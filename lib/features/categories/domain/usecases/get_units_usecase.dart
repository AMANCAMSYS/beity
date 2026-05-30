import '../entities/unit.dart';
import '../../data/repositories/unit_repository.dart';

class GetUnitsUseCase {
  final UnitRepository _repository;

  GetUnitsUseCase(this._repository);

  Future<List<Unit>> call({
    String? type,
  }) async {
    return _repository.getUnits(
      type: type,
    );
  }
}
