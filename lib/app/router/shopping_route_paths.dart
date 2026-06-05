class ShoppingRoutePaths {
  static const lists = '/shopping-lists';
  static const mode = '/shopping-mode';
  static const create = '/shopping-lists/create';
  static const detailPrefix = '/shopping-list';
  static const detailPattern = '/shopping-list/:id';
  static const addItemPattern = '/shopping-list/:id/add-item';
  static const editItemPattern = '/shopping-list/:id/edit-item/:itemId';
  static const summaryPattern = '/shopping-list/:id/summary';
  static const aiSuggestionsPattern = '/shopping-list/:id/ai-suggestions';
  static const quickAddPattern = '/shopping-list/:id/quick-add';
  static const shoppingModePattern = '/shopping-list/:id/shopping-mode';
  static const activityPattern = '/shopping-list/:id/activity';

  static String detail(String listId) => '/shopping-list/$listId';
  static String _withHomeId(String path, String? homeId) {
    if (homeId == null || homeId.isEmpty) return path;
    return '$path?homeId=${Uri.encodeQueryComponent(homeId)}';
  }

  static String addItem(String listId, {String? homeId}) =>
      _withHomeId('/shopping-list/$listId/add-item', homeId);
  static String editItem(String listId, String itemId, {String? homeId}) =>
      _withHomeId('/shopping-list/$listId/edit-item/$itemId', homeId);
  static String summary(String listId) => '/shopping-list/$listId/summary';
  static String aiSuggestions(String listId) =>
      '/shopping-list/$listId/ai-suggestions';
  static String quickAdd(String listId) => '/shopping-list/$listId/quick-add';
  static String shoppingMode(String listId) =>
      '/shopping-list/$listId/shopping-mode';
  static String activity(String listId) => '/shopping-list/$listId/activity';
}
