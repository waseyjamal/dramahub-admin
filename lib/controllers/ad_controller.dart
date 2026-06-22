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

  // ─── Ad Networks ──────────────────────────────────────────────────
  final RxBool levelplayEnabled = true.obs;
  final RxBool casEnabled = false.obs;

  // ─── App Open Provider ────────────────────────────────────────────
  final RxString appOpenProvider = 'liftoff'.obs;

  // ─── Interstitial Priority ────────────────────────────────────────
  final RxString interstitialPriority1 = 'levelplay'.obs;
  final RxBool interstitialPriority1Enabled = true.obs;
  final RxString interstitialPriority2 = 'cas'.obs;
  final RxBool interstitialPriority2Enabled = false.obs;

  // ─── Rewarded Priority ────────────────────────────────────────────
  final RxString rewardedPriority1 = 'levelplay'.obs;
  final RxBool rewardedPriority1Enabled = true.obs;
  final RxString rewardedPriority2 = 'cas'.obs;
  final RxBool rewardedPriority2Enabled = false.obs;

  // ─── Interstitial ─────────────────────────────────────────────────
  final RxBool interstitialEnabled = true.obs;
  final RxInt interstitialCooldownSeconds = 30.obs;
  final RxInt interstitialMaxPerSession = 8.obs;
  final interstitialAdUnitId = TextEditingController();
  final RxMap<String, bool> interstitialScreens = <String, bool>{
    'home_screen': false,
    'continue_watching': false,
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
  final RxInt rewardedCooldownSeconds = 30.obs;
  final RxInt rewardedMaxPerSession = 5.obs;
  final rewardedAdUnitId = TextEditingController();
  final RxMap<String, bool> rewardedScreens = <String, bool>{
    'home_screen': false,
    'continue_watching': false,
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

  // ─── Download ─────────────────────────────────────────────────────
  final RxBool downloadEnabled = true.obs;
  final RxInt downloadCooldownSeconds = 120.obs;
  final RxInt downloadMaxPerSession = 3.obs;
  final RxString downloadPriority1 = 'levelplay'.obs;
  final RxBool downloadPriority1Enabled = true.obs;
  final RxString downloadPriority2 = 'cas'.obs;
  final RxBool downloadPriority2Enabled = false.obs;

  // ─── Offline Ads ──────────────────────────────────────────────────
  final RxBool offlineAdsEnabled = false.obs;
  final RxString offlineAdType = 'interstitial'.obs;
  final RxInt offlineMaturityMinutes = 5.obs;
  final RxInt offlineSessionCoolMinutes = 5.obs;
  final RxInt offlineMaxPerSession = 3.obs;
  final RxString offlinePriority1 = 'levelplay'.obs;
  final RxBool offlinePriority1Enabled = true.obs;
  final RxString offlinePriority2 = 'cas'.obs;
  final RxBool offlinePriority2Enabled = false.obs;

  // ─── VAST ─────────────────────────────────────────────────────────
  final RxBool vastEnabled = false.obs;
  final RxInt vastSkipAfterSeconds = 5.obs;
  final RxInt vastMaxPerSession = 3.obs;
  final RxInt vastGapBetweenAdsMinutes = 10.obs;
  final RxList<Map<String, dynamic>> vastWaterfall = <Map<String, dynamic>>[].obs;

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

      // Ad Networks
      final adNetworks = json['ad_networks'] as Map<String, dynamic>? ?? {};
      levelplayEnabled.value = adNetworks['levelplay_enabled'] ?? true;
      casEnabled.value = adNetworks['cas_enabled'] ?? false;

      // App Open
      final appOpen = json['app_open'] as Map<String, dynamic>? ?? {};
      appOpenEnabled.value = appOpen['enabled'] ?? true;
      appOpenCooldownHours.value = appOpen['cooldown_hours'] ?? 4;
      appOpenAdUnitId.text = appOpen['ad_unit_id'] ?? '';
      appOpenProvider.value = appOpen['provider'] ?? 'cas';

      // Interstitial
      final inter = json['interstitial'] as Map<String, dynamic>? ?? {};
      interstitialEnabled.value = inter['enabled'] ?? true;
      interstitialCooldownSeconds.value = inter['cooldown_seconds'] ?? 30;
      interstitialMaxPerSession.value = inter['max_per_session'] ?? 3;
      interstitialAdUnitId.text = inter['ad_unit_id'] ?? '';
      interstitialPriority1.value = inter['priority_1'] ?? 'levelplay';
      interstitialPriority1Enabled.value = inter['priority_1_enabled'] ?? true;
      interstitialPriority2.value = inter['priority_2'] ?? 'cas';
      interstitialPriority2Enabled.value = inter['priority_2_enabled'] ?? false;
      final interScreens = inter['screens'] as Map<String, dynamic>? ?? {};
      interScreens.forEach((k, v) {
        interstitialScreens[k] = v as bool? ?? false;
      });

      // Rewarded
      final rew = json['rewarded'] as Map<String, dynamic>? ?? {};
      rewardedEnabled.value = rew['enabled'] ?? true;
      rewardedCooldownSeconds.value = rew['cooldown_seconds'] ?? 30;
      rewardedMaxPerSession.value = rew['max_per_session'] ?? 5;
      rewardedAdUnitId.text = rew['ad_unit_id'] ?? '';
      rewardedPriority1.value = rew['priority_1'] ?? 'levelplay';
      rewardedPriority1Enabled.value = rew['priority_1_enabled'] ?? true;
      rewardedPriority2.value = rew['priority_2'] ?? 'cas';
      rewardedPriority2Enabled.value = rew['priority_2_enabled'] ?? false;
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

      // Download
      final dl = json['download'] as Map<String, dynamic>? ?? {};
      downloadEnabled.value = dl['enabled'] ?? true;
      downloadCooldownSeconds.value = dl['cooldown_seconds'] ?? 120;
      downloadMaxPerSession.value = dl['max_per_session'] ?? 3;
      downloadPriority1.value = dl['priority_1'] ?? 'levelplay';
      downloadPriority1Enabled.value = dl['priority_1_enabled'] ?? true;
      downloadPriority2.value = dl['priority_2'] ?? 'cas';
      downloadPriority2Enabled.value = dl['priority_2_enabled'] ?? false;

      // Offline Ads
      final offline = json['offline_ads'] as Map<String, dynamic>? ?? {};
      offlineAdsEnabled.value = offline['enabled'] ?? false;
      offlineAdType.value = offline['ad_type'] ?? 'interstitial';
      offlineMaturityMinutes.value = offline['maturity_minutes'] ?? 5;
      offlineSessionCoolMinutes.value = offline['session_cool_minutes'] ?? 5;
      offlineMaxPerSession.value = offline['max_per_session'] ?? 3;
      offlinePriority1.value = offline['priority_1'] ?? 'levelplay';
      offlinePriority1Enabled.value = offline['priority_1_enabled'] ?? true;
      offlinePriority2.value = offline['priority_2'] ?? 'cas';
      offlinePriority2Enabled.value = offline['priority_2_enabled'] ?? false;

      // VAST
      final vast = json['vast'] as Map<String, dynamic>? ?? {};
      vastEnabled.value = vast['enabled'] ?? false;
      vastSkipAfterSeconds.value = vast['skip_after_seconds'] ?? 5;
      vastMaxPerSession.value = vast['max_per_session'] ?? 3;
      vastGapBetweenAdsMinutes.value = vast['gap_between_ads_minutes'] ?? 10;
      final waterfallJson = vast['waterfall'] as List<dynamic>? ?? [];
      vastWaterfall.assignAll(
        waterfallJson.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );

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
        'ad_networks': {
          'levelplay_enabled': levelplayEnabled.value,
          'cas_enabled': casEnabled.value,
        },
        'app_open': {
          'enabled': appOpenEnabled.value,
          'provider': appOpenProvider.value,
          'cooldown_hours': appOpenCooldownHours.value,
          'ad_unit_id': appOpenAdUnitId.text.trim(),
        },
        'interstitial': {
          'enabled': interstitialEnabled.value,
          'cooldown_seconds': interstitialCooldownSeconds.value,
          'max_per_session': interstitialMaxPerSession.value,
          'ad_unit_id': interstitialAdUnitId.text.trim(),
          'priority_1': interstitialPriority1.value,
          'priority_1_enabled': interstitialPriority1Enabled.value,
          'priority_2': interstitialPriority2.value,
          'priority_2_enabled': interstitialPriority2Enabled.value,
          'screens': Map<String, bool>.from(interstitialScreens),
        },
        'rewarded': {
          'enabled': rewardedEnabled.value,
          'cooldown_seconds': rewardedCooldownSeconds.value,
          'max_per_session': rewardedMaxPerSession.value,
          'ad_unit_id': rewardedAdUnitId.text.trim(),
          'priority_1': rewardedPriority1.value,
          'priority_1_enabled': rewardedPriority1Enabled.value,
          'priority_2': rewardedPriority2.value,
          'priority_2_enabled': rewardedPriority2Enabled.value,
          'screens': Map<String, bool>.from(rewardedScreens),
        },
        'native': {
          'enabled': nativeEnabled.value,
          'every_nth_card': nativeEveryNthCard.value,
          'ad_unit_id': nativeAdUnitId.text.trim(),
          'screens': Map<String, bool>.from(nativeScreens),
        },
        'download': {
          'enabled': downloadEnabled.value,
          'cooldown_seconds': downloadCooldownSeconds.value,
          'max_per_session': downloadMaxPerSession.value,
          'priority_1': downloadPriority1.value,
          'priority_1_enabled': downloadPriority1Enabled.value,
          'priority_2': downloadPriority2.value,
          'priority_2_enabled': downloadPriority2Enabled.value,
        },
        'offline_ads': {
          'enabled': offlineAdsEnabled.value,
          'ad_type': offlineAdType.value,
          'maturity_minutes': offlineMaturityMinutes.value,
          'session_cool_minutes': offlineSessionCoolMinutes.value,
          'max_per_session': offlineMaxPerSession.value,
          'priority_1': offlinePriority1.value,
          'priority_1_enabled': offlinePriority1Enabled.value,
          'priority_2': offlinePriority2.value,
          'priority_2_enabled': offlinePriority2Enabled.value,
        },
        'vast': {
          'enabled': vastEnabled.value,
          'skip_after_seconds': vastSkipAfterSeconds.value,
          'max_per_session': vastMaxPerSession.value,
          'gap_between_ads_minutes': vastGapBetweenAdsMinutes.value,
          'waterfall': vastWaterfall.toList(),
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
