import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum IconStyle { rounded, outlined, plain }

class ShoppingUiUtils {
  ShoppingUiUtils._();

  static IconData getIconData(
    String iconName, {
    IconStyle style = IconStyle.rounded,
  }) {
    switch (style) {
      case IconStyle.rounded:
        return _roundedIcons[iconName] ?? Icons.shopping_cart_rounded;
      case IconStyle.outlined:
        return _outlinedIcons[iconName] ?? Icons.shopping_cart_outlined;
      case IconStyle.plain:
        return _plainIcons[iconName] ?? Icons.shopping_cart;
    }
  }

  static Color getProgressColor(double progress) {
    if (progress >= 0.8) return AppColors.success;
    if (progress >= 0.5) return AppColors.info;
    if (progress >= 0.3) return AppColors.warning;
    return AppColors.error;
  }

  static const Map<String, IconData> _roundedIcons = {
    'shopping_cart': Icons.shopping_cart_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'local_grocery_store': Icons.local_grocery_store_rounded,
    'local_pharmacy': Icons.local_pharmacy_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'restaurant': Icons.restaurant_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'home': Icons.home_rounded,
    'hardware': Icons.hardware_rounded,
    'build': Icons.build_rounded,
    'child_care': Icons.child_care_rounded,
    'pets': Icons.pets_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'celebration': Icons.celebration_rounded,
    'school': Icons.school_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'cleaning_services': Icons.cleaning_services_rounded,
    'local_florist': Icons.local_florist_rounded,
  };

  static const Map<String, IconData> _outlinedIcons = {
    'shopping_cart': Icons.shopping_cart_outlined,
    'shopping_bag': Icons.shopping_bag_outlined,
    'local_grocery_store': Icons.local_grocery_store_outlined,
    'local_pharmacy': Icons.local_pharmacy_outlined,
    'local_hospital': Icons.local_hospital_outlined,
    'restaurant': Icons.restaurant_outlined,
    'local_cafe': Icons.local_cafe_outlined,
    'home': Icons.home_outlined,
    'hardware': Icons.hardware_outlined,
    'build': Icons.build_outlined,
    'child_care': Icons.child_care_outlined,
    'pets': Icons.pets_outlined,
    'card_giftcard': Icons.card_giftcard_outlined,
    'celebration': Icons.celebration_outlined,
    'school': Icons.school_outlined,
    'fitness_center': Icons.fitness_center_outlined,
    'cleaning_services': Icons.cleaning_services_outlined,
    'local_florist': Icons.local_florist_outlined,
  };

  static const Map<String, IconData> _plainIcons = {
    'shopping_cart': Icons.shopping_cart,
    'shopping_bag': Icons.shopping_bag,
    'local_grocery_store': Icons.local_grocery_store,
    'local_pharmacy': Icons.local_pharmacy,
    'local_hospital': Icons.local_hospital,
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'home': Icons.home,
    'hardware': Icons.hardware,
    'build': Icons.build,
    'child_care': Icons.child_care,
    'pets': Icons.pets,
    'card_giftcard': Icons.card_giftcard,
    'celebration': Icons.celebration,
    'school': Icons.school,
    'fitness_center': Icons.fitness_center,
    'cleaning_services': Icons.cleaning_services,
    'local_florist': Icons.local_florist,
  };
}
