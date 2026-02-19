class MigrationHelper {
  static const int currentSchemaVersion = 1;

  static bool needsMigration(int version) {
    return version < currentSchemaVersion;
  }
}
