import 'package:flutter/material.dart';
import '../../../../core/services/realtime_service.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final ConnectionStateModel connectionState;

  const ConnectionStatusWidget({
    super.key,
    required this.connectionState,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    if (connectionState.isConnected) {
      return const SizedBox.shrink();
    }

    if (connectionState.isDisconnected) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        color: theme.colorScheme.error,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: theme.colorScheme.onError, size: 16),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'غير متصل' : 'Offline',
              style: TextStyle(color: theme.colorScheme.onError, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (connectionState.isReconnecting) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        color: theme.colorScheme.tertiary,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onTertiary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'جارٍ المزامنة...' : 'Syncing...',
              style: TextStyle(color: theme.colorScheme.onTertiary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
