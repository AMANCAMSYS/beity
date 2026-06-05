import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void d(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      _write('DEBUG', message, data: data);
    }
  }

  static void i(String message, {Map<String, dynamic>? data}) {
    _write('INFO', message, data: data);
  }

  static void w(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _write('WARN', message, data: data, error: error, stackTrace: stackTrace);
  }

  static void e(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _write('ERROR', message, data: data, error: error, stackTrace: stackTrace);
    // Note: Integrations like Firebase Crashlytics should be plugged in here
  }

  static void _write(
    String level,
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final dataSuffix = data == null ? '' : ' - $data';
    developer.log(
      '[$level] $message$dataSuffix',
      name: 'SAWA',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
