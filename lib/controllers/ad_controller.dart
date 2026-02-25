import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/github_service.dart';
import '../data/repositories/github_repository.dart';

class AdController extends GetxController {
  final GitHubRepository _repository =
      GitHubRepository(Get.find<GitHubService>());

  static const String _adConfigPath = 'ad_config.json';

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString statusMessage = ''.obs;
  final RxBool hasError = false.obs;

  // ─── Global ───────────────────────────────────────────────────────
  final RxBool adsEnabled = true.obs;

  // ─── App Open ─────────────────────────────────────────────────────
  final RxBool appOpenEnabled = true.obs;
  final RxInt appOpenCooldownHours = 4.obs;
  final appOpenAdUnitId = TextEditingController();

  // ─── Interstitial ─────────────────────────────────────────────────
  final RxBool interstitialEnabled = true.obs;
  final RxInt interstitialCooldownSeconds = 30.obs;
  final RxInt interstitialMaxPerSession = 3.obs;
  final interstitialAdUnitId = TextEditingController();
  final RxMap<String, bool> interstitialScreens = <String, bool>{
    'home_screen': false,
    'episodes_screen': true,
    'video_screen': true,
    'upcoming_screen': false,
    'watchlist_screen': false,
    'history_screen': false,
    'download_screen': false,
    'profile_screen': false,
    'premium_screen': false,
    'suggest_drama_screen': false,
    'rate_app_screen': false,
    'report_problem_screen': false,
  }.obs;

  // ─── Rewarded ─────────────────────────────────────────────────────
  final RxBool rewardedEnabled = true.obs;
  final rewardedAdUnitId = TextEditingController();
  final RxMap<String, bool> rewardedScreens = <String, bool>{
    'home_screen': false,
    'episodes_screen': false,
    'video_screen': false,
    'upcoming_screen': true,
    'watchlist_screen': false,
    'history_screen': false,
    'download_screen': false,
    'profile_screen': false,
    'premium_screen': false,
    'suggest_drama_screen': false,
    'rate_app_screen': false,
    'report_problem_screen': false,
  }.obs;

  // ─── Native ───────────────────────────────────────────────────────
  final RxBool nativeEnabled = false.obs;
  final RxInt nativeEveryNthCard = 5.obs;
  final nativeAdUnitId = TextEditingController();
  final RxMap<String, bool> nativeScreens = <String, bool>{
    'home_screen': false,
    'episodes_screen': false,
    'watchlist_screen': false,
    'history_screen': false,
    'download_screen': false,
  }.obs;

  @override
  void onInit() {
    super.onInit();
    loadAdConfig();
  }

  @override
  void onClose() {
    appOpenAdUnitId.dispose();
    interstitialAdUnitId.dispose();
    rewardedAdUnitId.dispose();
    nativeAdUnitId.dispose();
    super.onClose();
  }

  Future<void> loadAdConfig() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      statusMessage.value = '';

      final data = await _repository.fetchJsonList(_adConfigPath);
      final json = data as Map<String, dynamic>;

      adsEnabled.value = json['ads_enabled'] ?? true;

      // App Open
      final appOpen = json['app_open'] as Map<String, dynamic>? ?? {};
      appOpenEnabled.value = appOpen['enabled'] ?? true;
      appOpenCooldownHours.value = appOpen['cooldown_hours'] ?? 4;
      appOpenAdUnitId.text = appOpen['ad_unit_id'] ?? '';

      // Interstitial
      final inter = json['interstitial'] as Map<String, dynamic>? ?? {};
      interstitialEnabled.value = inter['enabled'] ?? true;
      interstitialCooldownSeconds.value = inter['cooldown_seconds'] ?? 30;
      interstitialMaxPerSession.value = inter['max_per_session'] ?? 3;
      interstitialAdUnitId.text = inter['ad_unit_id'] ?? '';
      final interScreens = inter['screens'] as Map<String, dynamic>? ?? {};
      interScreens.forEach((k, v) {
        interstitialScreens[k] = v as bool? ?? false;
      });

      // Rewarded
      final rew = json['rewarded'] as Map<String, dynamic>? ?? {};
      rewardedEnabled.value = rew['enabled'] ?? true;
      rewardedAdUnitId.text = rew['ad_unit_id'] ?? '';
      final rewScreens = rew['screens'] as Map<String, dynamic>? ?? {};
      rewScreens.forEach((k, v) {
        rewardedScreens[k] = v as bool? ?? false;
      });

      // Native
      final nat = json['native'] as Map<String, dynamic>? ?? {};
      nativeEnabled.value = nat['enabled'] ?? false;
      nativeEveryNthCard.value = nat['every_nth_card'] ?? 5;
      nativeAdUnitId.text = nat['ad_unit_id'] ?? '';
      final natScreens = nat['screens'] as Map<String, dynamic>? ?? {};
      natScreens.forEach((k, v) {
        nativeScreens[k] = v as bool? ?? false;
      });

      statusMessage.value = '✅ Config loaded';
    } catch (e) {
      hasError.value = true;
      statusMessage.value = '❌ Failed to load: $e';
      debugPrint('AdController load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveAdConfig() async {
    try {
      isSaving.value = true;
      hasError.value = false;
      statusMessage.value = '';

      final data = {
        'ads_enabled': adsEnabled.value,
        'app_open': {
          'enabled': appOpenEnabled.value,
          'cooldown_hours': appOpenCooldownHours.value,
          'ad_unit_id': appOpenAdUnitId.text.trim(),
        },
        'interstitial': {
          'enabled': interstitialEnabled.value,
          'cooldown_seconds': interstitialCooldownSeconds.value,
          'max_per_session': interstitialMaxPerSession.value,
          'ad_unit_id': interstitialAdUnitId.text.trim(),
          'screens': Map<String, bool>.from(interstitialScreens),
        },
        'rewarded': {
          'enabled': rewardedEnabled.value,
          'ad_unit_id': rewardedAdUnitId.text.trim(),
          'screens': Map<String, bool>.from(rewardedScreens),
        },
        'native': {
          'enabled': nativeEnabled.value,
          'every_nth_card': nativeEveryNthCard.value,
          'ad_unit_id': nativeAdUnitId.text.trim(),
          'screens': Map<String, bool>.from(nativeScreens),
        },
      };

      await _repository.commitJsonList(
        path: _adConfigPath,
        data: data,
        message: 'Update ad config from admin panel',
      );

      statusMessage.value = '✅ Ad config saved successfully!';
      Get.snackbar(
        'Saved',
        'Ad configuration updated successfully',
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      hasError.value = true;
      statusMessage.value = '❌ Save failed: $e';
      Get.snackbar(
        'Error',
        'Failed to save: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      debugPrint('AdController save error: $e');
    } finally {
      isSaving.value = false;
    }
  }
}
