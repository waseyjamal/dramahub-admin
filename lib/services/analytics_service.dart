import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

/// Reads analytics data from Firestore
/// Data is written by DramaHub user app on every episode_watched event
class AnalyticsService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Top Dramas ───────────────────────────────────────────────────
  final RxList<Map<String, dynamic>> topDramas = <Map<String, dynamic>>[].obs;

  // ─── Top Episodes ─────────────────────────────────────────────────
  final RxList<Map<String, dynamic>> topEpisodes = <Map<String, dynamic>>[].obs;

  // ─── View Counts ──────────────────────────────────────────────────
  final RxInt totalViewsToday = 0.obs;
  final RxInt totalViewsWeek = 0.obs;
  final RxInt totalViewsMonth = 0.obs;
  final RxInt totalViewsAllTime = 0.obs;

  // ─── Daily Chart Data (last 7 days) ───────────────────────────────
  final RxList<Map<String, dynamic>> dailyViews = <Map<String, dynamic>>[].obs;

  final RxBool isLoading = false.obs;
  final RxString lastUpdated = ''.obs;

  Future<void> loadAnalytics() async {
    try {
      isLoading.value = true;

      await Future.wait([
        _loadViewCounts(),
        _loadTopDramas(),
        _loadTopEpisodes(),
        _loadDailyChart(),
      ]);

      final now = DateTime.now();
      lastUpdated.value =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('AnalyticsService error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadViewCounts() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(const Duration(days: 7));
      final monthStart = DateTime(now.year, now.month, 1);

      // Today
      final todaySnap = await _firestore
          .collection('analytics')
          .doc('views')
          .collection('events')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .count()
          .get();
      totalViewsToday.value = todaySnap.count ?? 0;

      // Week
      final weekSnap = await _firestore
          .collection('analytics')
          .doc('views')
          .collection('events')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .count()
          .get();
      totalViewsWeek.value = weekSnap.count ?? 0;

      // Month
      final monthSnap = await _firestore
          .collection('analytics')
          .doc('views')
          .collection('events')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .count()
          .get();
      totalViewsMonth.value = monthSnap.count ?? 0;

      // All time from summary doc
      final summaryDoc =
          await _firestore.collection('analytics').doc('summary').get();
      if (summaryDoc.exists) {
        totalViewsAllTime.value =
            (summaryDoc.data()?['total_views'] ?? 0) as int;
      }
    } catch (e) {
      debugPrint('_loadViewCounts error: $e');
    }
  }

  Future<void> _loadTopDramas() async {
    try {
      final snap = await _firestore
          .collection('analytics')
          .doc('dramas')
          .collection('counts')
          .orderBy('views', descending: true)
          .limit(5)
          .get();

      topDramas.assignAll(snap.docs.map((d) => {
            'drama_id': d.id,
            'title': d.data()['title'] ?? d.id,
            'views': d.data()['views'] ?? 0,
          }));
    } catch (e) {
      debugPrint('_loadTopDramas error: $e');
    }
  }

  Future<void> _loadTopEpisodes() async {
    try {
      final snap = await _firestore
          .collection('analytics')
          .doc('episodes')
          .collection('counts')
          .orderBy('views', descending: true)
          .limit(5)
          .get();

      topEpisodes.assignAll(snap.docs.map((d) => {
            'episode_id': d.id,
            'title': d.data()['title'] ?? d.id,
            'drama_title': d.data()['drama_title'] ?? '',
            'episode_number': d.data()['episode_number'] ?? 0,
            'views': d.data()['views'] ?? 0,
          }));
    } catch (e) {
      debugPrint('_loadTopEpisodes error: $e');
    }
  }

  Future<void> _loadDailyChart() async {
    try {
      final List<Map<String, dynamic>> result = [];
      final now = DateTime.now();

      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final snap = await _firestore
            .collection('analytics')
            .doc('views')
            .collection('events')
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
            .where('timestamp', isLessThan: Timestamp.fromDate(dayEnd))
            .count()
            .get();

        result.add({
          'day': _dayLabel(day.weekday),
          'count': snap.count ?? 0,
        });
      }

      dailyViews.assignAll(result);
    } catch (e) {
      debugPrint('_loadDailyChart error: $e');
    }
  }

  String _dayLabel(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
