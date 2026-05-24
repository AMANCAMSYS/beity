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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final others = presences.values
        .where((p) => p.userId != currentUserId)
        .toList();

    if (others.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            isArabic ? 'المتواجدون:' : 'Active now:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          ...others.take(5).map((presence) => Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Tooltip(
                  message: presence.displayName,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      presence.initials,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              )),
          if (others.length > 5)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Text(
                  '+${others.length - 5}',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
