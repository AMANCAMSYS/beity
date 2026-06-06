mixin AccessibilityHelpers {
  static String shoppingItemLabel({
    required String name,
    required double? quantity,
    required String? unit,
    required bool isPurchased,
  }) {
    final buffer = StringBuffer(name);
    if (quantity != null && quantity > 0) {
      buffer.write(
        ', ${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 1)}',
      );
      if (unit != null && unit.isNotEmpty) {
        buffer.write(' $unit');
      }
    }
    buffer.write(isPurchased ? ', purchased' : ', not purchased');
    return buffer.toString();
  }

  static String shoppingListLabel({
    required String name,
    required int itemCount,
    required int purchasedCount,
  }) {
    return 'Shopping list: $name, $itemCount items, $purchasedCount purchased';
  }

  static String markAsPurchasedLabel({
    required String itemName,
    required bool currentlyPurchased,
  }) {
    if (currentlyPurchased) {
      return 'Mark $itemName as not purchased';
    }
    return 'Mark $itemName as purchased';
  }

  static String categoryHeaderLabel({
    required String category,
    required int itemCount,
  }) {
    return '$category category, $itemCount items';
  }

  static String progressLabel({required int purchased, required int total}) {
    return '$purchased of $total items purchased';
  }
}
