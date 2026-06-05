import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/config/env_config.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static Future<void>? _googleSignInInitializeFuture;

  static SupabaseClient get client {
    if (_client != null) return _client!;
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
  }

  static set client(SupabaseClient value) => _client = value;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      publishableKey: EnvConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  // Auth helpers
  static User? get currentUser {
    try {
      return client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static bool get isAuthenticated => currentUser != null;

  // Session helpers
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return client.auth.signUp(email: email, password: password, data: data);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<AuthResponse> signInWithGoogle() async {
    final webClientId = EnvConfig.googleWebClientId;
    final iosClientId = EnvConfig.googleIosClientId;
    final isApplePlatform =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    final scopes = <String>['email', 'profile'];
    final googleSignIn = GoogleSignIn.instance;

    _googleSignInInitializeFuture ??= googleSignIn.initialize(
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
      clientId: isApplePlatform && iosClientId.isNotEmpty ? iosClientId : null,
    );
    await _googleSignInInitializeFuture;

    GoogleSignInAccount? googleUser;
    try {
      googleUser = await googleSignIn.attemptLightweightAuthentication();
    } catch (_) {
      await googleSignIn.signOut();
    }

    if (googleUser == null) {
      if (!googleSignIn.supportsAuthenticate()) {
        throw const AuthException('google_sign_in_not_supported');
      }
      googleUser = await googleSignIn.authenticate(scopeHint: scopes);
    }

    final authentication = googleUser.authentication;
    final idToken = authentication.idToken;
    if (idToken == null) {
      throw const AuthException('google_verification_token_failed');
    }

    final authorization =
        await googleUser.authorizationClient.authorizationForScopes(scopes) ??
        await googleUser.authorizationClient.authorizeScopes(scopes);

    return client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );
  }

  // Realtime helpers
  static RealtimeChannel subscribeToChannel(String channel) {
    return client.channel(channel);
  }
}
