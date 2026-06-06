import '../../domain/entities/ai_suggestion.dart';

class AiSuggestionModel {
  final String name;
  final double? quantity;
  final String? unit;
  final String? category;
  final String? reason;

  const AiSuggestionModel({
    required this.name,
    this.quantity,
    this.unit,
    this.category,
    this.reason,
  });

  factory AiSuggestionModel.fromJson(Map<String, dynamic> json) {
    // Graceful handling of name: default to empty string if missing, then trim and cap
    String parsedName =
        (json['name'] as String? ?? json['n'] as String?)?.trim() ?? '';
    if (parsedName.length > 100) {
      parsedName = parsedName.substring(0, 100);
    }

    // Graceful handling of quantity: default to 1.0 if null or invalid
    double? parsedQuantity = 1.0;
    final qtyVal = json['quantity'] ?? json['q'];
    if (qtyVal != null) {
      if (qtyVal is num) {
        parsedQuantity = qtyVal.toDouble();
      } else if (qtyVal is String) {
        parsedQuantity = double.tryParse(qtyVal) ?? 1.0;
      }
      if (parsedQuantity <= 0 || parsedQuantity > 9999) {
        parsedQuantity = 1.0;
      }
    }

    // Strip null or empty unit/category
    String? parsedUnit = (json['unit'] as String? ?? json['u'] as String?)
        ?.trim();
    if (parsedUnit != null && parsedUnit.isEmpty) parsedUnit = null;

    String? parsedCategory = (json['category'] as String?)?.trim();
    if (parsedCategory != null && parsedCategory.isEmpty) parsedCategory = null;

    String? parsedReason = (json['reason'] as String?)?.trim();
    if (parsedReason != null && parsedReason.isEmpty) parsedReason = null;

    return AiSuggestionModel(
      name: parsedName,
      quantity: parsedQuantity,
      unit: parsedUnit,
      category: parsedCategory,
      reason: parsedReason,
    );
  }

  AiSuggestion toEntity() {
    return AiSuggestion(
      name: name,
      quantity: quantity,
      unit: unit,
      category: category,
      reason: reason,
    );
  }
}
