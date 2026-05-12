import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/ad_controller.dart';

class AdManagerPage extends StatelessWidget {
  const AdManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AdController>();

    return Obx(() {
      if (c.isLoading.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.deepPurple),
              SizedBox(height: 16),
              Text('Loading ad config...'),
            ],
          ),
        );
      }

      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ───────────────────────────────────────────
                const _SectionHeader(
                  icon: Icons.campaign_rounded,
                  title: 'Ad Manager',
                  subtitle: 'Control all ads remotely — no app update needed',
                ),
                const SizedBox(height: 16),

                // ─── Global Kill Switch ───────────────────────────────
                _GlobalKillSwitch(c: c),
                const SizedBox(height: 16),
                _WaterfallStatusCard(c: c),
                const SizedBox(height: 16),

                // ─── App Open ─────────────────────────────────────────
                _AdNetworksSection(c: c),
                const SizedBox(height: 12),
                _AppOpenSection(c: c),
                const SizedBox(height: 12),

                // ─── Interstitial ─────────────────────────────────────
                _InterstitialSection(c: c),
                const SizedBox(height: 12),

                // ─── Rewarded ─────────────────────────────────────────
                _RewardedSection(c: c),
                const SizedBox(height: 12),

                // ─── Native ───────────────────────────────────────────
                _NativeSection(c: c),
                const SizedBox(height: 12),

                // ─── VAST ─────────────────────────────────────────────
                _VastSection(c: c),
                const SizedBox(height: 24),

                // ─── Save Button ──────────────────────────────────────
                _SaveButton(c: c),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLOBAL KILL SWITCH
// ─────────────────────────────────────────────────────────────────────────────
class _GlobalKillSwitch extends StatelessWidget {
  final AdController c;
  const _GlobalKillSwitch({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          decoration: BoxDecoration(
            color:
                c.adsEnabled.value ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: c.adsEnabled.value
                  ? Colors.green.shade300
                  : Colors.red.shade300,
              width: 1.5,
            ),
          ),
          child: ListTile(
            leading: Icon(
              c.adsEnabled.value
                  ? Icons.monetization_on_rounded
                  : Icons.money_off_rounded,
              color: c.adsEnabled.value
                  ? Colors.green.shade700
                  : Colors.red.shade700,
              size: 32,
            ),
            title: Text(
              c.adsEnabled.value ? 'All Ads ENABLED' : 'All Ads DISABLED',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: c.adsEnabled.value
                    ? Colors.green.shade800
                    : Colors.red.shade800,
              ),
            ),
            subtitle: Text(
              c.adsEnabled.value
                  ? 'Tap to disable all ads instantly'
                  : 'Tap to re-enable all ads',
              style: TextStyle(
                color: c.adsEnabled.value
                    ? Colors.green.shade600
                    : Colors.red.shade600,
              ),
            ),
            trailing: Switch(
              value: c.adsEnabled.value,
              onChanged: (v) => c.adsEnabled.value = v,
              activeThumbColor: Colors.green.shade700,
              inactiveThumbColor: Colors.red.shade700,
            ),
          ),
        ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP OPEN SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _AppOpenSection extends StatelessWidget {
  final AdController c;
  const _AppOpenSection({required this.c});

  @override
  Widget build(BuildContext context) {
    return _AdCard(
      title: 'App Open Ad',
      icon: Icons.open_in_new_rounded,
      color: Colors.indigo,
      isEnabled: c.appOpenEnabled,
      onToggle: (v) => c.appOpenEnabled.value = v,
      children: [
        _ProtectedAdUnitIdField(
          controller: c.appOpenAdUnitId,
          label: 'App Open Ad Unit ID',
        ),
        const SizedBox(height: 12),
        Obx(() => _DropdownTile(
          label: 'Provider',
          value: c.appOpenProvider.value,
          options: const ['cas', 'appodeal'],
          onChanged: (v) => c.appOpenProvider.value = v!,
        )),
        const SizedBox(height: 12),
        Obx(() => _SliderTile(
          label: 'Cooldown',
          value: c.appOpenCooldownHours.value.toDouble(),
          min: 1,
          max: 12,
          divisions: 11,
          displayText: '${c.appOpenCooldownHours.value} hours',
          onChanged: (v) => c.appOpenCooldownHours.value = v.round(),
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERSTITIAL SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _InterstitialSection extends StatelessWidget {
  final AdController c;
  const _InterstitialSection({required this.c});

  @override
  Widget build(BuildContext context) {
    return _AdCard(
      title: 'Interstitial Ads',
      icon: Icons.fullscreen_rounded,
      color: Colors.deepPurple,
      isEnabled: c.interstitialEnabled,
      onToggle: (v) => c.interstitialEnabled.value = v,
      children: [
        _ProtectedAdUnitIdField(
          controller: c.interstitialAdUnitId,
          label: 'Interstitial Ad Unit ID',
        ),
        const SizedBox(height: 12),
        Obx(() => _SliderTile(
          label: 'Cooldown between ads',
          value: c.interstitialCooldownSeconds.value.toDouble(),
          min: 10,
          max: 120,
          divisions: 11,
          displayText: '${c.interstitialCooldownSeconds.value}s',
          onChanged: (v) => c.interstitialCooldownSeconds.value = v.round(),
        )),
        const SizedBox(height: 8),
        Obx(() => _SliderTile(
          label: 'Max per session',
          value: c.interstitialMaxPerSession.value.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          displayText: '${c.interstitialMaxPerSession.value} ads',
          onChanged: (v) => c.interstitialMaxPerSession.value = v.round(),
        )),
        const SizedBox(height: 12),
        _PrioritySection(
          priority1: c.interstitialPriority1,
          priority1Enabled: c.interstitialPriority1Enabled,
          priority2: c.interstitialPriority2,
          priority2Enabled: c.interstitialPriority2Enabled,
        ),
        const SizedBox(height: 12),
        _ScreenToggles(
          title: 'Show on screens:',
          screens: c.interstitialScreens,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REWARDED SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _RewardedSection extends StatelessWidget {
  final AdController c;
  const _RewardedSection({required this.c});

  @override
  Widget build(BuildContext context) {
    return _AdCard(
      title: 'Rewarded Ads',
      icon: Icons.card_giftcard_rounded,
      color: Colors.orange,
      isEnabled: c.rewardedEnabled,
      onToggle: (v) => c.rewardedEnabled.value = v,
      children: [
        _ProtectedAdUnitIdField(
          controller: c.rewardedAdUnitId,
          label: 'Rewarded Ad Unit ID',
        ),
        const SizedBox(height: 12),
        Obx(() => _SliderTile(
          label: 'Cooldown between ads',
          value: c.rewardedCooldownSeconds.value.toDouble(),
          min: 10,
          max: 120,
          divisions: 11,
          displayText: '${c.rewardedCooldownSeconds.value}s',
          onChanged: (v) => c.rewardedCooldownSeconds.value = v.round(),
        )),
        const SizedBox(height: 8),
        Obx(() => _SliderTile(
          label: 'Max per session',
          value: c.rewardedMaxPerSession.value.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          displayText: '${c.rewardedMaxPerSession.value} ads',
          onChanged: (v) => c.rewardedMaxPerSession.value = v.round(),
        )),
        const SizedBox(height: 12),
        _PrioritySection(
          priority1: c.rewardedPriority1,
          priority1Enabled: c.rewardedPriority1Enabled,
          priority2: c.rewardedPriority2,
          priority2Enabled: c.rewardedPriority2Enabled,
        ),
        const SizedBox(height: 12),
        _ScreenToggles(
          title: 'Show on screens:',
          screens: c.rewardedScreens,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NATIVE SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _NativeSection extends StatelessWidget {
  final AdController c;
  const _NativeSection({required this.c});

  @override
  Widget build(BuildContext context) {
    return _AdCard(
      title: 'Native Ads',
      icon: Icons.view_stream_rounded,
      color: Colors.teal,
      isEnabled: c.nativeEnabled,
      onToggle: (v) => c.nativeEnabled.value = v,
      children: [
        _ProtectedAdUnitIdField(
          controller: c.nativeAdUnitId,
          label: 'Native Ad Unit ID',
        ),
        const SizedBox(height: 12),
        Obx(() => _SliderTile(
              label: 'Show every N cards',
              value: c.nativeEveryNthCard.value.toDouble(),
              min: 3,
              max: 10,
              divisions: 7,
              displayText: 'Every ${c.nativeEveryNthCard.value} cards',
              onChanged: (v) => c.nativeEveryNthCard.value = v.round(),
            )),
        const SizedBox(height: 12),
        _ScreenToggles(
          title: 'Show on screens:',
          screens: c.nativeScreens,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SAVE BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final AdController c;
  const _SaveButton({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: c.isSaving.value ? null : c.saveAdConfig,
            icon: c.isSaving.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cloud_upload_rounded),
            label: Text(
              c.isSaving.value ? 'Saving to GitHub...' : 'Save Ad Config',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROTECTED AD UNIT ID FIELD
// Read-only by default. Tap edit icon to unlock. Tap anywhere to close keyboard.
// ─────────────────────────────────────────────────────────────────────────────
class _ProtectedAdUnitIdField extends StatefulWidget {
  final TextEditingController controller;
  final String label;

  const _ProtectedAdUnitIdField({
    required this.controller,
    required this.label,
  });

  @override
  State<_ProtectedAdUnitIdField> createState() =>
      _ProtectedAdUnitIdFieldState();
}

class _ProtectedAdUnitIdFieldState extends State<_ProtectedAdUnitIdField> {
  bool _isEditing = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      // Auto-lock when focus lost (user tapped elsewhere)
      if (!_focusNode.hasFocus && _isEditing) {
        setState(() => _isEditing = false);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    HapticFeedback.lightImpact();
    setState(() => _isEditing = !_isEditing);
    if (_isEditing) {
      Future.delayed(const Duration(milliseconds: 50), () {
        _focusNode.requestFocus();
      });
    } else {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warning banner — only shown while editing
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isEditing
              ? Container(
                  key: const ValueKey('warning'),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Be careful — wrong ID will break ads!',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),

        // The field
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          readOnly: !_isEditing,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: _isEditing ? Colors.black87 : Colors.grey.shade600,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
            hintStyle: const TextStyle(fontSize: 11),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color:
                    _isEditing ? Colors.orange.shade400 : Colors.grey.shade300,
                width: _isEditing ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.orange.shade600,
                width: 1.5,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: Icon(
              Icons.key_rounded,
              size: 18,
              color: _isEditing ? Colors.orange : Colors.grey.shade400,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isEditing ? Icons.lock_open_rounded : Icons.edit_rounded,
                size: 18,
                color:
                    _isEditing ? Colors.orange.shade700 : Colors.grey.shade400,
              ),
              tooltip: _isEditing ? 'Lock field' : 'Edit ID',
              onPressed: _toggleEdit,
            ),
            filled: true,
            fillColor: _isEditing ? Colors.white : Colors.grey.shade50,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }
}

class _AdCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final RxBool isEnabled;
  final ValueChanged<bool> onToggle;
  final List<Widget> children;

  const _AdCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.isEnabled,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                const Spacer(),
                Obx(() => Switch(
                      value: isEnabled.value,
                      onChanged: onToggle,
                       activeThumbColor: color,
                    )),
              ],
            ),
          ),
          // Content
          Obx(() => AnimatedCrossFade(
                firstChild: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
                secondChild: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'This ad type is disabled. Toggle on to configure.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
                crossFadeState: isEnabled.value
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
              )),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayText;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                displayText,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: Colors.deepPurple,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ScreenToggles extends StatelessWidget {
  final String title;
  final RxMap<String, bool> screens;

  const _ScreenToggles({required this.title, required this.screens});

  String _formatScreenName(String key) {
    return key
        .replaceAll('_screen', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Obx(() => Column(
                children: screens.keys.map((screen) {
                  final isLast = screen == screens.keys.last;
                  return Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(
                            _screenIcon(screen),
                            size: 16,
                            color: screens[screen] == true
                                ? Colors.deepPurple
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatScreenName(screen),
                              style: TextStyle(
                                fontSize: 13,
                                color: screens[screen] == true
                                    ? Colors.black87
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                          Switch(
                            value: screens[screen] ?? false,
                            onChanged: (v) => screens[screen] = v,
                           activeThumbColor: Colors.deepPurple,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      if (!isLast)
                        Divider(
                            height: 1, color: Colors.grey.shade100, indent: 36),
                    ],
                  );
                }).toList(),
              )),
        ),
      ],
    );
  }

  IconData _screenIcon(String screen) {
    if (screen.contains('home')) return Icons.home_outlined;
    if (screen.contains('episode')) return Icons.play_circle_outline;
    if (screen.contains('video')) return Icons.videocam_outlined;
    if (screen.contains('upcoming')) return Icons.schedule_outlined;
    if (screen.contains('watchlist')) return Icons.bookmark_outline;
    if (screen.contains('history')) return Icons.history_outlined;
    if (screen.contains('download')) return Icons.download_outlined;
    if (screen.contains('profile')) return Icons.person_outline;
    if (screen.contains('premium')) return Icons.star_outline;
    if (screen.contains('suggest')) return Icons.lightbulb_outline;
    if (screen.contains('rate')) return Icons.star_rate_outlined;
    if (screen.contains('report')) return Icons.flag_outlined;
    return Icons.phone_android_outlined;
  }
}

class _VastSection extends StatelessWidget {
  final AdController c;
  const _VastSection({required this.c});

  @override
  Widget build(BuildContext context) {
    return _AdCard(
      title: 'VAST Video Ads (Preroll)',
      icon: Icons.smart_display_rounded,
      color: Colors.red,
      isEnabled: c.vastEnabled,
      onToggle: (v) => c.vastEnabled.value = v,
      children: [
        // Skip after seconds slider
        Obx(() => _SliderTile(
              label: 'Skip button after',
              value: c.vastSkipAfterSeconds.value.toDouble(),
              min: 3,
              max: 30,
              divisions: 27,
              displayText: '${c.vastSkipAfterSeconds.value}s',
              onChanged: (v) => c.vastSkipAfterSeconds.value = v.round(),
            )),
        const SizedBox(height: 8),

        // Max per session slider
        Obx(() => _SliderTile(
              label: 'Max ads per session',
              value: c.vastMaxPerSession.value.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              displayText: '${c.vastMaxPerSession.value} ads',
              onChanged: (v) => c.vastMaxPerSession.value = v.round(),
            )),
        const SizedBox(height: 8),

        // Gap between ads slider
        Obx(() => _SliderTile(
              label: 'Gap between ads',
              value: c.vastGapBetweenAdsMinutes.value.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              displayText: '${c.vastGapBetweenAdsMinutes.value} min',
              onChanged: (v) => c.vastGapBetweenAdsMinutes.value = v.round(),
            )),
        const SizedBox(height: 16),

        // Waterfall header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ad Networks (Waterfall)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: () {
                c.vastWaterfall.add({
                  'network': 'new_network',
                  'url': '',
                  'priority': c.vastWaterfall.length + 1,
                  'enabled': false,
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Waterfall list
        Obx(() => Column(
              children: c.vastWaterfall.asMap().entries.map((entry) {
                final i = entry.key;
                final network = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Network name + enabled toggle + delete
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Priority ${network['priority']}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: network['network'],
                              decoration: const InputDecoration(
                                labelText: 'Network name',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 13),
                              onChanged: (v) {
                                c.vastWaterfall[i] = {
                                  ...c.vastWaterfall[i],
                                  'network': v,
                                };
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: network['enabled'] ?? false,
                            onChanged: (v) {
                              c.vastWaterfall[i] = {
                                ...c.vastWaterfall[i],
                                'enabled': v,
                              };
                            },
                            activeThumbColor: Colors.red,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            onPressed: () => c.vastWaterfall.removeAt(i),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // VAST URL field
                      TextFormField(
                        initialValue: network['url'],
                        decoration: const InputDecoration(
                          labelText: 'VAST URL',
                          hintText: 'https://...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          prefixIcon: Icon(Icons.link, size: 18),
                        ),
                        style: const TextStyle(fontSize: 12),
                        onChanged: (v) {
                          c.vastWaterfall[i] = {
                            ...c.vastWaterfall[i],
                            'url': v,
                          };
                        },
                      ),
                      const SizedBox(height: 8),

                      // Priority field
                      TextFormField(
                        initialValue: network['priority'].toString(),
                        decoration: const InputDecoration(
                          labelText: 'Priority (1 = highest)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13),
                        onChanged: (v) {
                          c.vastWaterfall[i] = {
                            ...c.vastWaterfall[i],
                            'priority': int.tryParse(v) ?? (i + 1),
                          };
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WATERFALL STATUS CARD
// ─────────────────────────────────────────────────────────────────────────────
class _WaterfallStatusCard extends StatelessWidget {
  final AdController c;
  const _WaterfallStatusCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final String mode;
      final Color color;
      final IconData icon;

      if (!c.adsEnabled.value) {
        mode = 'All Ads Disabled';
        color = Colors.red;
        icon = Icons.block_rounded;
      } else if (!c.appodealEnabled.value && !c.casEnabled.value) {
        mode = 'All Networks Disabled';
        color = Colors.red;
        icon = Icons.block_rounded;
      } else if (c.interstitialPriority1Enabled.value && c.interstitialPriority2Enabled.value) {
        mode = 'Waterfall Active (${c.interstitialPriority1.value.toUpperCase()} → ${c.interstitialPriority2.value.toUpperCase()})';
        color = Colors.blue;
        icon = Icons.waterfall_chart_rounded;
      } else if (c.interstitialPriority1Enabled.value && !c.interstitialPriority2Enabled.value) {
        mode = '${c.interstitialPriority1.value.toUpperCase()} Only';
        color = Colors.green;
        icon = Icons.check_circle_rounded;
      } else if (!c.interstitialPriority1Enabled.value && c.interstitialPriority2Enabled.value) {
        mode = '${c.interstitialPriority2.value.toUpperCase()} Only';
        color = Colors.green;
        icon = Icons.check_circle_rounded;
      } else {
        mode = 'No Priority Enabled';
        color = Colors.orange;
        icon = Icons.warning_rounded;
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Live Mode',
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  mode,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AD NETWORKS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _AdNetworksSection extends StatelessWidget {
  final AdController c;
  const _AdNetworksSection({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.hub_rounded, color: Colors.blueGrey.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ad Networks',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Obx(() => _NetworkToggleTile(
                  name: 'Appodeal',
                  subtitle: 'Primary mediation network',
                  value: c.appodealEnabled.value,
                  color: Colors.deepPurple,
                  onChanged: (v) => c.appodealEnabled.value = v,
                )),
                const SizedBox(height: 8),
                Obx(() => _NetworkToggleTile(
                  name: 'CAS.AI',
                  subtitle: 'Secondary mediation network',
                  value: c.casEnabled.value,
                  color: Colors.teal,
                  onChanged: (v) => c.casEnabled.value = v,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkToggleTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _NetworkToggleTile({
    required this.name,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha: 0.06) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? Colors.green : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: value ? color : Colors.grey.shade600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIORITY SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _PrioritySection extends StatelessWidget {
  final RxString priority1;
  final RxBool priority1Enabled;
  final RxString priority2;
  final RxBool priority2Enabled;

  const _PrioritySection({
    required this.priority1,
    required this.priority1Enabled,
    required this.priority2,
    required this.priority2Enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Waterfall Priority',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Obx(() => _PriorityTile(
                label: 'Priority 1',
                value: priority1.value,
                enabled: priority1Enabled.value,
                onNetworkChanged: (v) => priority1.value = v!,
                onEnabledChanged: (v) => priority1Enabled.value = v,
              )),
              Divider(height: 1, color: Colors.grey.shade100),
              Obx(() => _PriorityTile(
                label: 'Priority 2',
                value: priority2.value,
                enabled: priority2Enabled.value,
                onNetworkChanged: (v) => priority2.value = v!,
                onEnabledChanged: (v) => priority2Enabled.value = v,
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriorityTile extends StatelessWidget {
  final String label;
  final String value;
  final bool enabled;
  final ValueChanged<String?> onNetworkChanged;
  final ValueChanged<bool> onEnabledChanged;

  const _PriorityTile({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onNetworkChanged,
    required this.onEnabledChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'appodeal', child: Text('Appodeal')),
                DropdownMenuItem(value: 'cas', child: Text('CAS.AI')),
              ],
              onChanged: onNetworkChanged,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: enabled,
            onChanged: onEnabledChanged,
            activeThumbColor: Colors.deepPurple,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DROPDOWN TILE
// ─────────────────────────────────────────────────────────────────────────────
class _DropdownTile extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _DropdownTile({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          items: options
              .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(o.toUpperCase()),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
