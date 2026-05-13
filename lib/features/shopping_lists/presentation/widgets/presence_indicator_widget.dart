import 'package:flutter/material.dart';
import '../../../../core/services/realtime_service.dart';

class PresenceIndicatorWidget extends StatelessWidget {
  final Map<String, PresenceState> presences;
  final String currentUserId;

  const PresenceIndicatorWidget({
    super.key,
    required this.presences,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final others = presences.values
        .where((p) => p.userId != currentUserId)
        .toList();

    if (others.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            'المتواجدون:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 8),
          ...others.take(5).map((presence) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Tooltip(
                  message: presence.displayName,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      presence.initials,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ),
              )),
          if (others.length > 5)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey[200],
                child: Text(
                  '+${others.length - 5}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
