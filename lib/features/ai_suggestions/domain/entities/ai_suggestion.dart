class AiSuggestion {
  final String name;
  final double? quantity;
  final String? unit;
  final String? category;
  final String? reason;

  const AiSuggestion({
    required this.name,
    this.quantity = 1.0,
    this.unit,
    this.category,
    this.reason,
  })  : assert(name.length > 0, 'Name cannot be empty'),
        assert(name.length <= 100, 'Name must be 100 characters or less'),
        assert(quantity == null || (quantity > 0 && quantity <= 9999),
            'Quantity must be between 0 and 9999');

  AiSuggestion copyWith({
    String? name,
    double? quantity,
    String? unit,
    String? category,
    String? reason,
  }) {
    return AiSuggestion(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      reason: reason ?? this.reason,
    );
  }
}
