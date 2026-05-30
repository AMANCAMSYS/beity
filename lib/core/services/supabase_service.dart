import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/config/env_config.dart';

class SupabaseService {
  static SupabaseClient? _client;
  
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
      anonKey: EnvConfig.supabaseAnonKey,
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
    return client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }
  
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  // Realtime helpers
  static RealtimeChannel subscribeToChannel(String channel) {
    return client.channel(channel);
  }
}
