import 'home_model.dart';

List<HomeModel> sortAvailableHomesByNewest(Iterable<HomeModel> homes) {
  final availableHomes = homes.where((home) => home.deletedAt == null).toList()
    ..sort((a, b) {
      final createdComparison = b.createdAt.compareTo(a.createdAt);
      if (createdComparison != 0) return createdComparison;

      return b.id.compareTo(a.id);
    });

  return availableHomes;
}

HomeModel? newestAvailableHome(Iterable<HomeModel> homes) {
  final sortedHomes = sortAvailableHomesByNewest(homes);
  if (sortedHomes.isEmpty) return null;
  return sortedHomes.first;
}

HomeModel? findAvailableHomeById(Iterable<HomeModel> homes, String? homeId) {
  if (homeId == null || homeId.isEmpty) return null;

  for (final home in homes) {
    if (home.id == homeId && home.deletedAt == null) return home;
  }

  return null;
}
