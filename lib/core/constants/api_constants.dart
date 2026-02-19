class ApiConstants {
  static const String githubOwner = 'waseyjamal';
  static const String githubRepo = 'dramahub-data';
  static const String githubBranch = 'main';
  static const String githubApiBase = 'https://api.github.com';

  static String contentsUrl(String path) =>
      '$githubApiBase/repos/$githubOwner/$githubRepo/contents/$path';
}
