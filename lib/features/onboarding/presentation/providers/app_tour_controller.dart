import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/onboarding_storage.dart';
import '../widgets/tour_tooltip_card.dart';
import 'app_tour_target_registry.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class AppTourState {
  final bool isActive;
  final int currentStep;
  final int totalSteps;

  const AppTourState({
    this.isActive = false,
    this.currentStep = 0,
    this.totalSteps = 0,
  });

  AppTourState copyWith({bool? isActive, int? currentStep, int? totalSteps}) {
    return AppTourState(
      isActive: isActive ?? this.isActive,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }
}

// ── _TourStep model (internal) ────────────────────────────────────────────────

class _TourStep {
  final GlobalKey targetKey;
  final String titleKey;
  final String descKey;

  const _TourStep({
    required this.targetKey,
    required this.titleKey,
    required this.descKey,
  });
}

// ── Controller ────────────────────────────────────────────────────────────────

class AppTourController extends StateNotifier<AppTourState> {
  AppTourController() : super(const AppTourState());

  OverlayEntry? _overlayEntry;
  List<_TourStep> _steps = [];

  /// Builds the filtered step list respecting feature flags and mounted state.
  List<_TourStep> _buildSteps() {
    final all = [
      _TourStep(
        targetKey: AppTourTargetRegistry.drawerMenuKey,
        titleKey: 'tour_drawer_menu_title',
        descKey: 'tour_drawer_menu_desc',
      ),
      _TourStep(
        targetKey: AppTourTargetRegistry.homeHeaderKey,
        titleKey: 'tour_home_dashboard_title',
        descKey: 'tour_home_dashboard_desc',
      ),
      _TourStep(
        targetKey: AppTourTargetRegistry.quickAddKey,
        titleKey: 'tour_quick_add_title',
        descKey: 'tour_quick_add_desc',
      ),
      _TourStep(
        targetKey: AppTourTargetRegistry.shoppingModeActionKey,
        titleKey: 'tour_shopping_mode_title',
        descKey: 'tour_shopping_mode_desc',
      ),
      if (FeatureFlags.enableAi)
        _TourStep(
          targetKey: AppTourTargetRegistry.aiSuggestionsKey,
          titleKey: 'tour_ai_suggestions_title',
          descKey: 'tour_ai_suggestions_desc',
        ),
      _TourStep(
        targetKey: AppTourTargetRegistry.listsTabKey,
        titleKey: 'tour_lists_tab_title',
        descKey: 'tour_lists_tab_desc',
      ),
      _TourStep(
        targetKey: AppTourTargetRegistry.shoppingTabKey,
        titleKey: 'tour_shopping_tab_title',
        descKey: 'tour_shopping_tab_desc',
      ),
      _TourStep(
        targetKey: AppTourTargetRegistry.activityTabKey,
        titleKey: 'tour_activity_tab_title',
        descKey: 'tour_activity_tab_desc',
      ),
    ];

    // Only keep steps whose target widget is actually mounted.
    return all.where((s) => AppTourTargetRegistry.isMounted(s.targetKey)).toList();
  }

  /// Builds steps for the Inventory tour.
  List<_TourStep> _buildInventorySteps() {
    final all = [
      _TourStep(
        targetKey: AppTourTargetRegistry.inventoryAddKey,
        titleKey: 'tour_inventory_add_title',
        descKey: 'tour_inventory_add_desc',
      ),
      _TourStep(
        targetKey: AppTourTargetRegistry.inventoryFilterKey,
        titleKey: 'tour_inventory_filter_title',
        descKey: 'tour_inventory_filter_desc',
      ),
    ];
    return all.where((s) => AppTourTargetRegistry.isMounted(s.targetKey)).toList();
  }

  /// Builds steps for the Expenses tour.
  List<_TourStep> _buildExpensesSteps() {
    final all = [
      _TourStep(
        targetKey: AppTourTargetRegistry.expensesSummaryKey,
        titleKey: 'tour_expenses_summary_title',
        descKey: 'tour_expenses_summary_desc',
      ),
      _TourStep(
        targetKey: AppTourTargetRegistry.expensesBalancesKey,
        titleKey: 'tour_expenses_balances_title',
        descKey: 'tour_expenses_balances_desc',
      ),
      _TourStep(
        targetKey: AppTourTargetRegistry.expensesFilterKey,
        titleKey: 'tour_expenses_filter_title',
        descKey: 'tour_expenses_filter_desc',
      ),
      _TourStep(
        targetKey: AppTourTargetRegistry.expensesAddKey,
        titleKey: 'tour_expenses_add_title',
        descKey: 'tour_expenses_add_desc',
      ),
    ];
    return all.where((s) => AppTourTargetRegistry.isMounted(s.targetKey)).toList();
  }

  /// Builds steps for the Tasks tour.
  List<_TourStep> _buildTasksSteps() {
    final all = [
      _TourStep(
        targetKey: AppTourTargetRegistry.tasksQuickAddKey,
        titleKey: 'tour_tasks_quick_add_title',
        descKey: 'tour_tasks_quick_add_desc',
      ),
      _TourStep(
        targetKey: AppTourTargetRegistry.tasksFilterKey,
        titleKey: 'tour_tasks_filter_title',
        descKey: 'tour_tasks_filter_desc',
      ),
      _TourStep(
        targetKey: AppTourTargetRegistry.tasksAddKey,
        titleKey: 'tour_tasks_add_title',
        descKey: 'tour_tasks_add_desc',
      ),
    ];
    return all.where((s) => AppTourTargetRegistry.isMounted(s.targetKey)).toList();
  }

  /// Builds steps for the Categories tour.
  List<_TourStep> _buildCategoriesSteps() {
    final all = [
      _TourStep(
        targetKey: AppTourTargetRegistry.categoriesFilterKey,
        titleKey: 'tour_categories_filter_title',
        descKey: 'tour_categories_filter_desc',
      ),
      _TourStep(
        targetKey: AppTourTargetRegistry.categoriesAddKey,
        titleKey: 'tour_categories_add_title',
        descKey: 'tour_categories_add_desc',
      ),
    ];
    return all.where((s) => AppTourTargetRegistry.isMounted(s.targetKey)).toList();
  }

  /// Builds steps for the Units tour.
  List<_TourStep> _buildUnitsSteps() {
    final all = [
      _TourStep(
        targetKey: AppTourTargetRegistry.unitsFilterKey,
        titleKey: 'tour_units_filter_title',
        descKey: 'tour_units_filter_desc',
      ),
      _TourStep(
        targetKey: AppTourTargetRegistry.unitsAddKey,
        titleKey: 'tour_units_add_title',
        descKey: 'tour_units_add_desc',
      ),
    ];
    return all.where((s) => AppTourTargetRegistry.isMounted(s.targetKey)).toList();
  }

  /// Safely starts the tour after the dashboard is fully rendered.
  ///
  /// Retries up to [maxRetries] times with [retryDelay] if keys aren't
  /// mounted yet (e.g. the build is still in progress).
  Future<void> maybeStartTour(
    BuildContext context, {
    int maxRetries = 5,
    Duration retryDelay = const Duration(milliseconds: 300),
  }) async {
    if (!OnboardingStorage.shouldShowAppTour()) return;
    if (state.isActive) return;

    // Retry until at least one key is mounted.
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      await Future.delayed(retryDelay);
      if (!context.mounted) return;
      final steps = _buildSteps();
      if (steps.isNotEmpty) {
        _startTour(context, steps, onComplete: OnboardingStorage.markAppTourSeen);
        return;
      }
    }
  }

  /// Safely starts the Inventory tour after the screen is fully rendered.
  Future<void> maybeStartInventoryTour(
    BuildContext context, {
    int maxRetries = 5,
    Duration retryDelay = const Duration(milliseconds: 300),
  }) async {
    if (!OnboardingStorage.shouldShowInventoryTour()) return;
    if (state.isActive) return;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      await Future.delayed(retryDelay);
      if (!context.mounted) return;
      final steps = _buildInventorySteps();
      if (steps.isNotEmpty) {
        _startTour(context, steps, onComplete: OnboardingStorage.markInventoryTourSeen);
        return;
      }
    }
  }

  /// Safely starts the Expenses tour after the screen is fully rendered.
  Future<void> maybeStartExpensesTour(
    BuildContext context, {
    int maxRetries = 5,
    Duration retryDelay = const Duration(milliseconds: 300),
  }) async {
    if (!OnboardingStorage.shouldShowExpensesTour()) return;
    if (state.isActive) return;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      await Future.delayed(retryDelay);
      if (!context.mounted) return;
      final steps = _buildExpensesSteps();
      if (steps.isNotEmpty) {
        _startTour(context, steps, onComplete: OnboardingStorage.markExpensesTourSeen);
        return;
      }
    }
  }

  /// Safely starts the Tasks tour after the screen is fully rendered.
  Future<void> maybeStartTasksTour(
    BuildContext context, {
    int maxRetries = 5,
    Duration retryDelay = const Duration(milliseconds: 300),
  }) async {
    if (!OnboardingStorage.shouldShowTasksTour()) return;
    if (state.isActive) return;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      await Future.delayed(retryDelay);
      if (!context.mounted) return;
      final steps = _buildTasksSteps();
      if (steps.isNotEmpty) {
        _startTour(context, steps, onComplete: OnboardingStorage.markTasksTourSeen);
        return;
      }
    }
  }

  /// Safely starts the Categories tour after the screen is fully rendered.
  Future<void> maybeStartCategoriesTour(
    BuildContext context, {
    int maxRetries = 5,
    Duration retryDelay = const Duration(milliseconds: 300),
  }) async {
    if (!OnboardingStorage.shouldShowCategoriesTour()) return;
    if (state.isActive) return;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      await Future.delayed(retryDelay);
      if (!context.mounted) return;
      final steps = _buildCategoriesSteps();
      if (steps.isNotEmpty) {
        _startTour(context, steps, onComplete: OnboardingStorage.markCategoriesTourSeen);
        return;
      }
    }
  }

  /// Safely starts the Units tour after the screen is fully rendered.
  Future<void> maybeStartUnitsTour(
    BuildContext context, {
    int maxRetries = 5,
    Duration retryDelay = const Duration(milliseconds: 300),
  }) async {
    if (!OnboardingStorage.shouldShowUnitsTour()) return;
    if (state.isActive) return;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      await Future.delayed(retryDelay);
      if (!context.mounted) return;
      final steps = _buildUnitsSteps();
      if (steps.isNotEmpty) {
        _startTour(context, steps, onComplete: OnboardingStorage.markUnitsTourSeen);
        return;
      }
    }
  }

  VoidCallback? _onTourComplete;

  void _startTour(BuildContext context, List<_TourStep> steps, {VoidCallback? onComplete}) {
    _steps = steps;
    _onTourComplete = onComplete;
    state = AppTourState(
      isActive: true,
      currentStep: 0,
      totalSteps: steps.length,
    );
    _showStep(context, 0);
  }

  void _showStep(BuildContext context, int stepIndex) {
    _removeOverlay();
    if (!context.mounted) return;
    if (stepIndex >= _steps.length) {
      _completeTour();
      return;
    }

    final step = _steps[stepIndex];
    if (!AppTourTargetRegistry.isMounted(step.targetKey)) {
      // Skip unmounted target
      _showStep(context, stepIndex + 1);
      return;
    }

    state = state.copyWith(currentStep: stepIndex);

    final renderBox =
        step.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      _showStep(context, stepIndex + 1);
      return;
    }

    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;
    final isLast = stepIndex == _steps.length - 1;
    final t = context.translate;

    _overlayEntry = OverlayEntry(
      builder: (_) => _TourOverlay(
        targetRect: Rect.fromLTWH(
          position.dx,
          position.dy,
          size.width,
          size.height,
        ),
        screenSize: screenSize,
        tooltip: TourTooltipCard(
          title: t(step.titleKey),
          description: t(step.descKey),
          currentStep: stepIndex + 1,
          totalSteps: _steps.length,
          isLast: isLast,
          onNext: () => _showStep(context, stepIndex + 1),
          onSkip: _completeTour,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _completeTour() {
    _removeOverlay();
    state = const AppTourState(isActive: false);
    if (_onTourComplete != null) {
      _onTourComplete!();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Call this to replay the tour (e.g. from Settings).
  Future<void> replayTour(BuildContext context) async {
    await OnboardingStorage.resetAppTour();
    await OnboardingStorage.resetInventoryTour();
    await OnboardingStorage.resetExpensesTour();
    await OnboardingStorage.resetTasksTour();
    await OnboardingStorage.resetCategoriesTour();
    await OnboardingStorage.resetUnitsTour();
    if (!context.mounted) return;
    await maybeStartTour(context);
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }
}

final appTourControllerProvider =
    StateNotifierProvider<AppTourController, AppTourState>(
  (_) => AppTourController(),
);

// ── Tour Overlay widget ───────────────────────────────────────────────────────

class _TourOverlay extends StatefulWidget {
  final Rect targetRect;
  final Size screenSize;
  final Widget tooltip;

  const _TourOverlay({
    required this.targetRect,
    required this.screenSize,
    required this.tooltip,
  });

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.targetRect;
    final s = widget.screenSize;
    const padding = 8.0;

    // Decide tooltip position: prefer below target, fallback above.
    final spaceBelow = s.height - r.bottom;
    final tooltipAbove = spaceBelow < 220;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dimmed background with spotlight cutout
          CustomPaint(
            size: s,
            painter: _SpotlightPainter(
              targetRect: r.inflate(padding),
              radius: 12,
            ),
          ),

          // Pulsing spotlight ring
          Positioned(
            left: r.left - padding,
            top: r.top - padding,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: _pulseAnim.value,
                child: child,
              ),
              child: Container(
                width: r.width + padding * 2,
                height: r.height + padding * 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // Tooltip card — positioned below or above target
          Positioned(
            left: 16,
            right: 16,
            top: tooltipAbove ? null : r.bottom + 16,
            bottom: tooltipAbove ? (s.height - r.top + 16) : null,
            child: widget.tooltip,
          ),
        ],
      ),
    );
  }
}

/// Paints a semi-transparent overlay with a rounded rectangular cutout
/// at [targetRect].
class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double radius;

  _SpotlightPainter({required this.targetRect, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final cutout = RRect.fromRectAndRadius(
      targetRect,
      Radius.circular(radius),
    );
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(cutout)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.targetRect != targetRect;
}
