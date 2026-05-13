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
    if (connectionState.isConnected) {
      return const SizedBox.shrink();
    }

    if (connectionState.isDisconnected) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        color: Colors.red[600],
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'غير متصل',
              style: TextStyle(color: Colors.white, fontSize: 13),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      );
    }

    if (connectionState.isReconnecting) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        color: Colors.blue[600],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'جارٍ المزامنة...',
              style: TextStyle(color: Colors.white, fontSize: 13),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
