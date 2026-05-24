enum EntityType {
  shoppingItem,
  shoppingList;

  String get displayName {
    switch (this) {
      case EntityType.shoppingItem:
        return 'Shopping Item';
      case EntityType.shoppingList:
        return 'Shopping List';
    }
  }

  String get tableName {
    switch (this) {
      case EntityType.shoppingItem:
        return 'shopping_items';
      case EntityType.shoppingList:
        return 'shopping_lists';
    }
  }
}
