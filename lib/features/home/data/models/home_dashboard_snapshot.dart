class HomeDashboardSnapshot {
  final String homeId;
  final String homeName;
  final String? activeListId;
  final String? activeListName;
  final int remainingShoppingItemsCount;
  final int totalShoppingItemsCount;
  final int totalActiveListsCount;
  final String? lastActivityText;
  final DateTime updatedAt;

  HomeDashboardSnapshot({
    required this.homeId,
    required this.homeName,
    this.activeListId,
    this.activeListName,
    this.remainingShoppingItemsCount = 0,
    this.totalShoppingItemsCount = 0,
    this.totalActiveListsCount = 0,
    this.lastActivityText,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'homeId': homeId,
    'homeName': homeName,
    'activeListId': activeListId,
    'activeListName': activeListName,
    'remainingShoppingItemsCount': remainingShoppingItemsCount,
    'totalShoppingItemsCount': totalShoppingItemsCount,
    'totalActiveListsCount': totalActiveListsCount,
    'lastActivityText': lastActivityText,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory HomeDashboardSnapshot.fromJson(Map<String, dynamic> json) {
    return HomeDashboardSnapshot(
      homeId: json['homeId'] as String,
      homeName: json['homeName'] as String,
      activeListId: json['activeListId'] as String?,
      activeListName: json['activeListName'] as String?,
      remainingShoppingItemsCount:
          json['remainingShoppingItemsCount'] as int? ?? 0,
      totalShoppingItemsCount: json['totalShoppingItemsCount'] as int? ?? 0,
      totalActiveListsCount: json['totalActiveListsCount'] as int? ?? 0,
      lastActivityText: json['lastActivityText'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
