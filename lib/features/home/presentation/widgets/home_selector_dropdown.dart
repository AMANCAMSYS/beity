import 'package:flutter/material.dart';
import 'package:sawa/core/localization/app_localizations.dart';

class HomeSelectorDropdown extends StatelessWidget {
  final String currentHomeName;
  final List<HomeOption> homes;
  final Function(String homeId) onHomeSelected;
  final VoidCallback onManageHomes;

  const HomeSelectorDropdown({
    super.key,
    required this.currentHomeName,
    required this.homes,
    required this.onHomeSelected,
    required this.onManageHomes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'manage') {
          onManageHomes();
        } else {
          onHomeSelected(value);
        }
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        ...homes.map(
          (home) => PopupMenuItem(
            value: home.id,
            child: Row(
              children: [
                Icon(
                  home.isActive ? Icons.check_circle : Icons.home_outlined,
                  color: home.isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        home.name,
                        style: TextStyle(
                          fontWeight: home.isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (home.memberCount > 0)
                        Text(
                          context.translate(
                            'members_count',
                            arguments: {'count': home.memberCount.toString()},
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'manage',
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, size: 20),
              const SizedBox(width: 12),
              Text(context.translate('manage_homes')),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                currentHomeName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeOption {
  final String id;
  final String name;
  final int memberCount;
  final bool isActive;

  const HomeOption({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.isActive,
  });
}
