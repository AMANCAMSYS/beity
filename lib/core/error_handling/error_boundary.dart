import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
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
        message: 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
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
              content: Text('تم إرسال تقرير الخطأ. شكراً لك!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      );
    }

    return widget.child;
  }
}
