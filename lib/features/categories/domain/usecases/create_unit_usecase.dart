import '../../../../core/errors/app_exception.dart';
import '../entities/unit.dart';
import '../../data/repositories/unit_repository.dart';

class CreateUnitUseCase {
  final UnitRepository _repository;

  CreateUnitUseCase(this._repository);

  Future<Unit> call({
    required String name,
    required String symbol,
    required String type,
  }) async {
    // Validate name
    if (name.isEmpty) {
      throw const ValidationException(message: 'please_enter_unit_name_validation');
    }

    if (name.length > 50) {
      throw const ValidationException(message: 'unit_name_too_long');
    }

    // Validate symbol
    if (symbol.isEmpty) {
      throw const ValidationException(message: 'please_enter_unit_symbol_validation');
    }

    if (symbol.length > 10) {
      throw const ValidationException(message: 'unit_symbol_too_long');
    }

    // Validate type
    if (!_isValidType(type)) {
      throw const ValidationException(message: 'invalid_unit_type');
    }

    return _repository.createUnit(
      name: name,
      symbol: symbol,
      type: type,
    );
  }

  bool _isValidType(String type) {
    return ['weight', 'volume', 'count', 'length'].contains(type);
  }
}
