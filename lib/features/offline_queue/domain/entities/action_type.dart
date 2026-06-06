enum ActionType {
  addItem,
  updateItem,
  deleteItem,
  restoreItem,
  markPurchased,
  updateQuantity,
  createList,
  updateList,
  deleteList,
  createCategory,
  updateCategory,
  deleteCategory,
  createUnit,
  updateUnit,
  deleteUnit,
  startShoppingModeSession,
  endShoppingModeSession,
  markNotificationRead,
  markAllNotificationsRead,
  updateNotificationPreference,
  acceptInvitation,
  declineInvitation,
  cancelInvitation;

  String get displayName {
    switch (this) {
      case ActionType.addItem:
        return 'Add Item';
      case ActionType.updateItem:
        return 'Update Item';
      case ActionType.deleteItem:
        return 'Delete Item';
      case ActionType.restoreItem:
        return 'Restore Item';
      case ActionType.markPurchased:
        return 'Mark Purchased';
      case ActionType.updateQuantity:
        return 'Update Quantity';
      case ActionType.createList:
        return 'Create List';
      case ActionType.updateList:
        return 'Update List';
      case ActionType.deleteList:
        return 'Delete List';
      case ActionType.createCategory:
        return 'Create Category';
      case ActionType.updateCategory:
        return 'Update Category';
      case ActionType.deleteCategory:
        return 'Delete Category';
      case ActionType.createUnit:
        return 'Create Unit';
      case ActionType.updateUnit:
        return 'Update Unit';
      case ActionType.deleteUnit:
        return 'Delete Unit';
      case ActionType.startShoppingModeSession:
        return 'Start Shopping Session';
      case ActionType.endShoppingModeSession:
        return 'End Shopping Session';
      case ActionType.markNotificationRead:
        return 'Mark Notification Read';
      case ActionType.markAllNotificationsRead:
        return 'Mark All Notifications Read';
      case ActionType.updateNotificationPreference:
        return 'Update Notification Preference';
      case ActionType.acceptInvitation:
        return 'Accept Invitation';
      case ActionType.declineInvitation:
        return 'Decline Invitation';
      case ActionType.cancelInvitation:
        return 'Cancel Invitation';
    }
  }

  String get translationKey {
    final snackCase = name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
    return 'action_$snackCase';
  }
}
