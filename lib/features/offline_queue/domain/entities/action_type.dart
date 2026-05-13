enum ActionType {
  addItem,
  updateItem,
  deleteItem,
  markPurchased,
  updateQuantity;

  String get displayName {
    switch (this) {
      case ActionType.addItem:
        return 'Add Item';
      case ActionType.updateItem:
        return 'Update Item';
      case ActionType.deleteItem:
        return 'Delete Item';
      case ActionType.markPurchased:
        return 'Mark Purchased';
      case ActionType.updateQuantity:
        return 'Update Quantity';
    }
  }
}
