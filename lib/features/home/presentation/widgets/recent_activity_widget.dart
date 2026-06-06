import 'package:flutter/material.dart';
import 'package:sawa/core/localization/app_localizations.dart';

class RecentActivityWidget extends StatelessWidget {
  final List<ActivityItem> activities;
  final VoidCallback onViewAll;

  const RecentActivityWidget({
    super.key,
    required this.activities,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.translate('recent_activity'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: onViewAll,
              child: Text(context.translate('view_all')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          _buildEmptyState(context)
        else
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: activities
                    .map((activity) => _buildActivityTile(context, activity))
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                context.translate('no_activities_yet'),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTile(BuildContext context, ActivityItem activity) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: activity.color.withValues(alpha: 0.1),
        child: Icon(activity.icon, color: activity.color, size: 20),
      ),
      title: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: activity.userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' ${activity.action} '),
            TextSpan(
              text: '"${activity.itemName}"',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ],
        ),
      ),
      subtitle: Text(
        activity.timeAgo,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
    );
  }
}

class ActivityItem {
  final String userName;
  final String action;
  final String itemName;
  final IconData icon;
  final Color color;
  final String timeAgo;

  const ActivityItem({
    required this.userName,
    required this.action,
    required this.itemName,
    required this.icon,
    required this.color,
    required this.timeAgo,
  });
}
