import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/shopping_mode/data/models/shopping_mode_session_model.dart';
import 'package:sawa/features/shopping_mode/data/repositories/shopping_mode_repository.dart';
import 'package:sawa/features/shopping_mode/domain/usecases/end_shopping_session_usecase.dart';
import 'package:sawa/features/shopping_mode/domain/usecases/start_shopping_session_usecase.dart';

class FakeShoppingModeRepository implements ShoppingModeRepository {
  ShoppingModeSessionModel? activeSession;
  int getActiveSessionCalls = 0;
  int startSessionCalls = 0;
  int endSessionCalls = 0;
  String? requestedUserId;
  String? requestedListId;
  String? endedSessionId;
  int? endedPurchasedCount;

  @override
  Future<ShoppingModeSessionModel?> getActiveSession({
    required String userId,
    required String listId,
  }) async {
    getActiveSessionCalls++;
    requestedUserId = userId;
    requestedListId = listId;
    return activeSession;
  }

  @override
  Future<ShoppingModeSessionModel> startSession({
    required String listId,
    required String userId,
    required String homeId,
    required int itemsTotalCount,
  }) async {
    startSessionCalls++;
    activeSession = ShoppingModeSessionModel(
      id: 'session-new',
      shoppingListId: listId,
      userId: userId,
      homeId: homeId,
      startedAt: DateTime(2026),
      itemsTotalCount: itemsTotalCount,
    );
    return activeSession!;
  }

  @override
  Future<ShoppingModeSessionModel> endSession({
    required String sessionId,
    required int itemsPurchasedCount,
  }) async {
    endSessionCalls++;
    endedSessionId = sessionId;
    endedPurchasedCount = itemsPurchasedCount;
    final ended =
        (activeSession ??
                ShoppingModeSessionModel(
                  id: sessionId,
                  shoppingListId: 'list-1',
                  userId: 'user-1',
                  homeId: 'home-1',
                  startedAt: DateTime(2026),
                  itemsTotalCount: 4,
                ))
            .copyWith(
              endedAt: DateTime(2026, 1, 1, 12),
              itemsPurchasedCount: itemsPurchasedCount,
            );
    activeSession = null;
    return ShoppingModeSessionModel(
      id: ended.id,
      shoppingListId: ended.shoppingListId,
      userId: ended.userId,
      homeId: ended.homeId,
      startedAt: ended.startedAt,
      endedAt: ended.endedAt,
      itemsPurchasedCount: ended.itemsPurchasedCount,
      itemsTotalCount: ended.itemsTotalCount,
      createdAt: ended.createdAt,
      updatedAt: ended.updatedAt,
    );
  }
}

void main() {
  test(
    'start returns an existing active session without creating another one',
    () async {
      final repository = FakeShoppingModeRepository()
        ..activeSession = ShoppingModeSessionModel(
          id: 'session-existing',
          shoppingListId: 'list-1',
          userId: 'user-1',
          homeId: 'home-1',
          startedAt: DateTime(2026),
          itemsTotalCount: 5,
        );
      final useCase = StartShoppingSessionUseCase(repository);

      final session = await useCase(
        listId: 'list-1',
        userId: 'user-1',
        homeId: 'home-1',
        itemsTotalCount: 5,
      );

      expect(session.id, 'session-existing');
      expect(repository.getActiveSessionCalls, 1);
      expect(repository.startSessionCalls, 0);
      expect(repository.requestedUserId, 'user-1');
      expect(repository.requestedListId, 'list-1');
    },
  );

  test('start creates a session when no active session exists', () async {
    final repository = FakeShoppingModeRepository();
    final useCase = StartShoppingSessionUseCase(repository);

    final session = await useCase(
      listId: 'list-1',
      userId: 'user-1',
      homeId: 'home-1',
      itemsTotalCount: 4,
    );

    expect(session.id, 'session-new');
    expect(session.isActive, isTrue);
    expect(session.itemsTotalCount, 4);
    expect(repository.startSessionCalls, 1);
  });

  test('end closes the session with the final purchased count', () async {
    final repository = FakeShoppingModeRepository()
      ..activeSession = ShoppingModeSessionModel(
        id: 'session-1',
        shoppingListId: 'list-1',
        userId: 'user-1',
        homeId: 'home-1',
        startedAt: DateTime(2026),
        itemsTotalCount: 4,
      );
    final useCase = EndShoppingSessionUseCase(repository);

    final session = await useCase(
      sessionId: 'session-1',
      itemsPurchasedCount: 3,
    );

    expect(session.isActive, isFalse);
    expect(session.itemsPurchasedCount, 3);
    expect(session.progress, 0.75);
    expect(repository.endSessionCalls, 1);
    expect(repository.endedSessionId, 'session-1');
    expect(repository.endedPurchasedCount, 3);
  });
}
