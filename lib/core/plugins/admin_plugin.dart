abstract class AdminPlugin {
  String get name;
  String get version;
  List<PluginRoute> get routes;
  void initialize();
}

class PluginRoute {
  final String path;
  final String label;

  PluginRoute({
    required this.path,
    required this.label,
  });
}
