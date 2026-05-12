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
      throw Exception('يرجى إدخال اسم الوحدة');
    }

    if (name.length > 50) {
      throw Exception('اسم الوحدة طويل جداً');
    }

    // Validate symbol
    if (symbol.isEmpty) {
      throw Exception('يرجى إدخال رمز الوحدة');
    }

    if (symbol.length > 10) {
      throw Exception('رمز الوحدة طويل جداً');
    }

    // Validate type
    if (!_isValidType(type)) {
      throw Exception('نوع الوحدة غير صالح');
    }

    return await _repository.createUnit(
      name: name,
      symbol: symbol,
      type: type,
    );
  }

  bool _isValidType(String type) {
    return ['weight', 'volume', 'count', 'length'].contains(type);
  }
}
