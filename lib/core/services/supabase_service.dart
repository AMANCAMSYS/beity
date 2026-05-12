import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/config/env_config.dart';

class SupabaseService {
  static SupabaseClient? _client;
  
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }
  
  // Auth helpers
  static User? get currentUser => _client?.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;
  
  // Session helpers
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
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
