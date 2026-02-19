class JsonMigrationEngine {
  static const int currentSchemaVersion = 2;

  static bool needsMigration(int version) {
    return version < currentSchemaVersion;
  }

  static Map<String, dynamic> migrateConfig(
    Map<String, dynamic> config,
  ) {
    int version = config['schema_version'] ?? 1;

    Map<String, dynamic> updated = Map<String, dynamic>.from(config);

    if (version < 2) {
      updated = _migrateV1ToV2(updated);
      updated['schema_version'] = 2;
    }

    return updated;
  }

  static Map<String, dynamic> _migrateV1ToV2(
    Map<String, dynamic> config,
  ) {
    if (!config.containsKey('feature_flags')) {
      config['feature_flags'] = {
        'bulk_upload': false,
        'episode_scheduler': false,
      };
    }

    if (!config.containsKey('beta_features')) {
      config['beta_features'] = {
        'dark_mode': true,
      };
    }

    return config;
  }
}
