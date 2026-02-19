import 'dart:convert';

class GitHubFileModel {
  final String name;
  final String path;
  final String sha;
  final String content;
  final String encoding;

  GitHubFileModel({
    required this.name,
    required this.path,
    required this.sha,
    required this.content,
    required this.encoding,
  });

  factory GitHubFileModel.fromJson(Map<String, dynamic> json) {
    return GitHubFileModel(
      name: json['name'],
      path: json['path'],
      sha: json['sha'],
      content: json['content'],
      encoding: json['encoding'],
    );
  }

  String get decodedContent {
    if (encoding == 'base64') {
      return utf8.decode(base64Decode(content.replaceAll('\n', '')));
    }
    return content;
  }
}
