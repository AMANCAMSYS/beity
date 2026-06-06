enum EntityType {
  shoppingItem,
  shoppingList,
  category,
  unit,
  shoppingModeSession,
  notification,
  notificationPreference,
  invitation;

  @Deprecated('Use translationKey with context.translate() instead')
  String get displayName => translationKey;

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
