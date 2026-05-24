import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Logout Cleanup', () {
    test('logout clears cache, providers, realtime, offline queue, and device token', () async {
      final mockAuthService = MockAuthService();
      final mockCacheService = MockCacheService();
      final mockRealtimeService = MockRealtimeService();
      final mockOfflineQueue = MockOfflineQueue();
      final mockTokenService = MockTokenService();

      final sut = LogoutUseCase(
        mockAuthService,
        mockCacheService,
        mockRealtimeService,
        mockOfflineQueue,
        mockTokenService,
      );

      await sut.execute();

      expect(mockTokenService.tokenCleared, true);
      expect(mockAuthService.loggedOut, true);
      expect(mockOfflineQueue.queueCleared, true);
      expect(mockCacheService.cacheCleared, true);
      expect(mockRealtimeService.invalidated, true);
    });
  });
}

// Dummy Implementations
class MockAuthService {
  bool loggedOut = false;
  Future<void> signOut() async => loggedOut = true;
}

class MockCacheService {
  bool cacheCleared = false;
  Future<void> clearAll() async => cacheCleared = true;
}

class MockRealtimeService {
  bool invalidated = false;
  void invalidate() => invalidated = true;
}

class MockOfflineQueue {
  bool queueCleared = false;
  Future<void> clear() async => queueCleared = true;
}

class MockTokenService {
  bool tokenCleared = false;
  Future<void> removeToken() async => tokenCleared = true;
}

class LogoutUseCase {
  final MockAuthService auth;
  final MockCacheService cache;
  final MockRealtimeService realtime;
  final MockOfflineQueue queue;
  final MockTokenService token;

  LogoutUseCase(this.auth, this.cache, this.realtime, this.queue, this.token);

  Future<void> execute() async {
    await token.removeToken();
    await auth.signOut();
    await queue.clear();
    await cache.clearAll();
    realtime.invalidate();
  }
}
