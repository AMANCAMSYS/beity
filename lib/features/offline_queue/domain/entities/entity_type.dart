enum EntityType {
  shoppingItem,
  shoppingList,
  category,
  unit,
  shoppingModeSession,
  notification,
  notificationPreference,
  invitation;

  String get displayName {
    switch (this) {
      case EntityType.shoppingItem:
        return 'Shopping Item';
      case EntityType.shoppingList:
        return 'Shopping List';
      case EntityType.category:
        return 'Category';
      case EntityType.unit:
        return 'Unit';
      case EntityType.shoppingModeSession:
        return 'Shopping Mode Session';
      case EntityType.notification:
        return 'Notification';
      case EntityType.notificationPreference:
        return 'Notification Preference';
      case EntityType.invitation:
        return 'Invitation';
    }
  }

  String get tableName {
    switch (this) {
      case EntityType.shoppingItem:
        return 'shopping_items';
      case EntityType.shoppingList:
        return 'shopping_lists';
      case EntityType.category:
        return 'categories';
      case EntityType.unit:
        return 'units';
      case EntityType.shoppingModeSession:
        return 'shopping_mode_sessions';
      case EntityType.notification:
        return 'notifications';
      case EntityType.notificationPreference:
        return 'notification_preferences';
      case EntityType.invitation:
        return 'invitations';
    }
  }

  String get translationKey {
    final snackCase = name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
    return 'entity_type_$snackCase';
  }
}
