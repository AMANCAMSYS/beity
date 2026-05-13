import 'package:flutter/material.dart';

import 'error_screen.dart';
import '../monitoring/monitoring_service.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorScreen(
        message: 'An unexpected error occurred. Please try again.',
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
        onReport: () {
          MonitoringService().logError(
            _error,
            _stackTrace,
            reason: 'User reported error from ErrorBoundary',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error report sent. Thank you!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      );
    }

    return widget.child;
  }
}
