import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShoppingModeState {
  final bool isActive;
  final String? sessionId;
  final String searchQuery;
  final Set<String> collapsedCategories;
  final Map<String, bool> categoryStates;

  const ShoppingModeState({
    this.isActive = false,
    this.sessionId,
    this.searchQuery = '',
    this.collapsedCategories = const {},
    this.categoryStates = const {},
  });

  ShoppingModeState copyWith({
    bool? isActive,
    String? sessionId,
    String? searchQuery,
    Set<String>? collapsedCategories,
    Map<String, bool>? categoryStates,
  }) {
    return ShoppingModeState(
      isActive: isActive ?? this.isActive,
      sessionId: sessionId ?? this.sessionId,
      searchQuery: searchQuery ?? this.searchQuery,
      collapsedCategories: collapsedCategories ?? this.collapsedCategories,
      categoryStates: categoryStates ?? this.categoryStates,
    );
  }
}

class ShoppingModeNotifier extends StateNotifier<ShoppingModeState> {
  ShoppingModeNotifier() : super(const ShoppingModeState());

  void activate(String sessionId) {
    state = state.copyWith(
      isActive: true,
      sessionId: sessionId,
    );
  }

  void deactivate() {
    state = const ShoppingModeState();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleCategory(String categoryId, [bool? isCurrentlyCollapsed]) {
    if (isCurrentlyCollapsed != null) {
      final states = Map<String, bool>.from(state.categoryStates);
      states[categoryId] = !isCurrentlyCollapsed;
      state = state.copyWith(categoryStates: states);
    } else {
      // Legacy behavior fallback
      final collapsed = Set<String>.from(state.collapsedCategories);
      if (collapsed.contains(categoryId)) {
        collapsed.remove(categoryId);
      } else {
        collapsed.add(categoryId);
      }
      state = state.copyWith(collapsedCategories: collapsed);
    }
  }

  void collapseCategory(String categoryId) {
    final collapsed = Set<String>.from(state.collapsedCategories);
    collapsed.add(categoryId);
    
    final states = Map<String, bool>.from(state.categoryStates);
    states[categoryId] = true;
    
    state = state.copyWith(
      collapsedCategories: collapsed,
      categoryStates: states,
    );
  }

  void expandCategory(String categoryId) {
    final collapsed = Set<String>.from(state.collapsedCategories);
    collapsed.remove(categoryId);
    
    final states = Map<String, bool>.from(state.categoryStates);
    states[categoryId] = false;
    
    state = state.copyWith(
      collapsedCategories: collapsed,
      categoryStates: states,
    );
  }
}

final shoppingModeProvider =
    StateNotifierProvider<ShoppingModeNotifier, ShoppingModeState>((ref) {
  return ShoppingModeNotifier();
});
