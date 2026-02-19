class MigrationPlan {
  final int fromVersion;
  final int toVersion;
  final String description;

  MigrationPlan({
    required this.fromVersion,
    required this.toVersion,
    required this.description,
  });
}
