import 'package:flutter/material.dart';

class RecentListsWidget extends StatelessWidget {
  final List<RecentList> lists;
  final VoidCallback onViewAll;
  final Function(String listId) onTap;

  const RecentListsWidget({
    super.key,
    required this.lists,
    required this.onViewAll,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'القوائم الأخيرة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (lists.isEmpty)
          _buildEmptyState(context)
        else
          ...lists.map((list) => _buildListTile(context, list)),
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
              Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'لا توجد قوائم بعد',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, RecentList list) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => onTap(list.id),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(list.icon, style: const TextStyle(fontSize: 24))),
        ),
        title: Text(
          list.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${list.remainingItems} متبقية',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

class RecentList {
  final String id;
  final String name;
  final String icon;
  final int remainingItems;

  const RecentList({
    required this.id,
    required this.name,
    required this.icon,
    required this.remainingItems,
  });
}
