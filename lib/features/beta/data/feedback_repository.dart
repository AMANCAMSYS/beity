import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sawa/core/services/supabase_service.dart';

import '../../../core/monitoring/device_info_service.dart';
import '../../../core/monitoring/app_log_buffer.dart';

class FeedbackRepository {
  final SupabaseClient _supabase;
  final DeviceInfoService _deviceInfoService;
  final AppLogBuffer _logBuffer;

  FeedbackRepository({
    SupabaseClient? supabase,
    DeviceInfoService? deviceInfoService,
    AppLogBuffer? logBuffer,
  }) : _supabase = supabase ?? SupabaseService.client,
       _deviceInfoService = deviceInfoService ?? DeviceInfoService(),
       _logBuffer = logBuffer ?? AppLogBuffer();

  Future<String> submitFeedback({
    required String feedbackType,
    required String description,
    int? starRating,
    String? screenRoute,
  }) async {
    final deviceInfo = await _deviceInfoService.getDeviceInfo();
    final recentLogs = _logBuffer.getRecent();

    final response = await _supabase.functions.invoke(
      'submit-feedback',
      body: {
        'feedback_type': feedbackType,
        'description': description,
        'star_rating': starRating,
        'device_info': deviceInfo,
        'screen_route': screenRoute,
        'app_logs': recentLogs,
      },
    );

    final data = response.data as Map<String, dynamic>?;

    if (response.status != 201) {
      final error = data?['error'] ?? 'Unknown error';
      throw Exception('Failed to submit feedback: $error');
    }

    return data?['id'] as String? ?? '';
  }
}
