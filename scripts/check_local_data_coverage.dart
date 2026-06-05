import 'dart:io';

const auditPath = 'docs/local-first-storage/data-coverage-audit.md';
const scannedRoots = ['lib/core', 'lib/features'];

final fromPattern = RegExp(r"""\.from\(\s*['"]([^'"]+)['"]\s*\)""");
final markdownTablePattern = RegExp(r'`([a-z][a-z0-9_]+)`');

void main() {
  final auditFile = File(auditPath);
  if (!auditFile.existsSync()) {
    stderr.writeln('Missing coverage audit: $auditPath');
    exit(2);
  }

  final documentedTables = markdownTablePattern
      .allMatches(auditFile.readAsStringSync())
      .map((match) => match.group(1)!)
      .toSet();

  final tableReferences = <String, Set<String>>{};

  for (final root in scannedRoots) {
    final directory = Directory(root);
    if (!directory.existsSync()) continue;

    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      for (final match in fromPattern.allMatches(content)) {
        final table = match.group(1)!;
        tableReferences.putIfAbsent(table, () => <String>{}).add(entity.path);
      }
    }
  }

  final missing =
      tableReferences.keys
          .where((table) => !documentedTables.contains(table))
          .toList()
        ..sort();

  if (missing.isEmpty) {
    stdout.writeln(
      'OK: all direct Supabase .from(...) tables are documented in $auditPath.',
    );
    stdout.writeln('Documented direct tables found: ${tableReferences.length}');
    return;
  }

  stderr.writeln(
    'Found Supabase tables used in Dart code but missing from $auditPath:',
  );
  for (final table in missing) {
    stderr.writeln('- $table');
    final files = tableReferences[table]!.toList()..sort();
    for (final file in files.take(5)) {
      stderr.writeln('  - $file');
    }
    if (files.length > 5) {
      stderr.writeln('  - ... ${files.length - 5} more files');
    }
  }
  stderr.writeln('');
  stderr.writeln('Update $auditPath before adding new remote data paths.');
  exit(1);
}
