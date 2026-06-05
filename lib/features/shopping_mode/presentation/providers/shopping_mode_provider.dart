import 'package:flutter_riverpod/legacy.dart';

class ShoppingModeState {
  final bool isActive;
  final String? sessionId;
  final Map<String, bool> categoryStates;

  const ShoppingModeState({
    this.isActive = false,
    this.sessionId,
    this.categoryStates = const {},
  });

  ShoppingModeState copyWith({
    bool? isActive,
    String? sessionId,
    Map<String, bool>? categoryStates,
  }) {
    return ShoppingModeState(
      isActive: isActive ?? this.isActive,
      sessionId: sessionId ?? this.sessionId,
      categoryStates: categoryStates ?? this.categoryStates,
    );
  }

  bool isCategoryCollapsed(String categoryId, {bool fallback = false}) {
    return categoryStates[categoryId] ?? fallback;
  }
}

class ShoppingModeNotifier extends StateNotifier<ShoppingModeState> {
  ShoppingModeNotifier() : super(const ShoppingModeState());

  void activate(String sessionId) {
    state = state.copyWith(isActive: true, sessionId: sessionId);
  }

  void deactivate() {
    state = const ShoppingModeState();
  }

  void toggleCategory(String categoryId) {
    final states = Map<String, bool>.from(state.categoryStates);
    final isCollapsed = states[categoryId] ?? false;
    states[categoryId] = !isCollapsed;
    state = state.copyWith(categoryStates: states);
  }

  void collapseCategory(String categoryId) {
    final states = Map<String, bool>.from(state.categoryStates);
    states[categoryId] = true;
    state = state.copyWith(categoryStates: states);
  }

  void expandCategory(String categoryId) {
    final states = Map<String, bool>.from(state.categoryStates);
    states[categoryId] = false;
    state = state.copyWith(categoryStates: states);
  }
}

final shoppingModeProvider =
    StateNotifierProvider<ShoppingModeNotifier, ShoppingModeState>((ref) {
      return ShoppingModeNotifier();
    });
