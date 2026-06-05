class AutocompleteSuggestion {
  final String name;
  final double quantity;
  final String? unitName;
  final String? sourceId;
  final bool isTemplate;

  const AutocompleteSuggestion({
    required this.name,
    required this.quantity,
    this.unitName,
    this.sourceId,
    this.isTemplate = false,
  });
}
