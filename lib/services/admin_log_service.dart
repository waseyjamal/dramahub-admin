import 'package:get/get.dart';
import '../data/models/admin_action_model.dart';
import '../data/repositories/github_repository.dart';
import '../services/github_service.dart';

class AdminLogService extends GetxService {
  final RxList<AdminActionModel> logs = <AdminActionModel>[].obs;

  final GitHubRepository _repository =
      GitHubRepository(Get.find<GitHubService>());

  static const String _path = 'admin_logs.json';

  void record(String action) {
    final entry = AdminActionModel(
      action: action,
      timestamp: DateTime.now(),
    );
    logs.add(entry);
  }

  Future<void> persistLogs() async {
    await _repository.commitJsonList(
      path: _path,
      data: logs.map((e) => e.toJson()).toList(),
      message: 'Update admin logs',
    );
  }
}
