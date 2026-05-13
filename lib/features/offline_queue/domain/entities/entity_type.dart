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
}
