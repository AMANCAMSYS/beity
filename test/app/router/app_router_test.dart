import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sawa/app/router/app_router.dart';
import 'package:sawa/features/homes/presentation/providers/homes_provider.dart';
import 'package:sawa/features/homes/data/models/home_model.dart';

class MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  String resolveHomeId(
    GoRouterState state, {
    List<HomeModel> homes = const [],
    String? activeHomeId,
  }) {
    final container = ProviderContainer(
      overrides: [
        cachedUserHomesProvider.overrideWithValue(homes),
        cachedActiveHomeIdProvider.overrideWithValue(activeHomeId),
      ],
    );
    addTearDown(container.dispose);

    return container.read(Provider((ref) => getEffectiveHomeId(state, ref)));
  }

  group('getEffectiveHomeId Priority', () {
    final olderHome = HomeModel(
      id: 'older_home_111',
      name: 'Older Home',
      type: 'apartment',
      ownerId: 'u1',
      createdAt: DateTime(2026, 1, 1),
    );

    final newerHome = HomeModel(
      id: 'newer_home_222',
      name: 'Newer Home',
      type: 'house',
      ownerId: 'u1',
      createdAt: DateTime(2026, 2, 1),
    );

    test('1. Resolves from queryParameters first', () {
      final state = MockGoRouterState();

      when(() => state.uri).thenReturn(Uri.parse('/path?homeId=query_456'));
      when(() => state.extra).thenReturn('extra_789');

      final result = resolveHomeId(state);
      expect(result, 'query_456');
    });

    test('2. Resolves from extra String if no query param', () {
      final state = MockGoRouterState();

      when(() => state.uri).thenReturn(Uri.parse('/path'));
      when(() => state.extra).thenReturn('extra_789');

      final result = resolveHomeId(state);
      expect(result, 'extra_789');
    });

    test('3. Resolves from extra Map if no query param', () {
      final state = MockGoRouterState();

      when(() => state.uri).thenReturn(Uri.parse('/path'));
      when(() => state.extra).thenReturn({'homeId': 'extra_map_789'});

      final result = resolveHomeId(state);
      expect(result, 'extra_map_789');
    });

    test('4. Resolves from cached active home when it is still available', () {
      final state = MockGoRouterState();

      when(() => state.uri).thenReturn(Uri.parse('/path'));
      when(() => state.extra).thenReturn(null);

      final result = resolveHomeId(
        state,
        homes: [olderHome, newerHome],
        activeHomeId: 'older_home_111',
      );
      expect(result, 'older_home_111');
    });

    test('5. Resolves from newest home if no valid active home exists', () {
      final homes = [
        HomeModel(
          id: 'deleted_home_000',
          name: 'Deleted Home',
          type: 'apartment',
          ownerId: 'u1',
          createdAt: DateTime(2026, 3, 1),
          deletedAt: DateTime(2026, 3, 2),
        ),
        olderHome,
        newerHome,
      ];

      final state = MockGoRouterState();

      when(() => state.uri).thenReturn(Uri.parse('/path'));
      when(() => state.extra).thenReturn(null);

      final result = resolveHomeId(state, homes: homes);
      expect(result, 'newer_home_222');
    });

    test('6. Ignores stale active home and falls back to newest home', () {
      final state = MockGoRouterState();

      when(() => state.uri).thenReturn(Uri.parse('/path'));
      when(() => state.extra).thenReturn(null);

      final result = resolveHomeId(
        state,
        homes: [olderHome, newerHome],
        activeHomeId: 'deleted_or_removed_home',
      );
      expect(result, 'newer_home_222');
    });

    test('7. Returns empty string if nothing is available', () {
      final state = MockGoRouterState();

      when(() => state.uri).thenReturn(Uri.parse('/path'));
      when(() => state.extra).thenReturn(null);

      final result = resolveHomeId(state);
      expect(result, '');
    });
  });
}
