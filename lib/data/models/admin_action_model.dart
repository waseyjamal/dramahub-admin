class AdminActionModel {
  final String action;
  final DateTime timestamp;

  AdminActionModel({
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        'timestamp': timestamp.toIso8601String(),
      };
}
