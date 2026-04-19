class Window {
  final Map<String, String> sessionStorage = {};
}

class Html {
  final Window window = Window();
}

final html = Html();

class Storage {
  void operator []=(String key, String value) {}
  String? operator [](String key) => null;
  void remove(String key) {}
}

extension WindowExt on Window {
  Storage get sessionStorage => Storage();
}
