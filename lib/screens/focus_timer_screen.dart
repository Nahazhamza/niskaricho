import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/tr.dart';
import '../l10n/copy.dart';
import '../models/prayer_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// Prayer Focus Mode — the anti-cheat Khushu' timer.
///
/// Client-side rules (the server enforces the same rule independently):
///  * "Done" stays disabled until 5 minutes have passed on BOTH clocks:
///    a monotonic Stopwatch that only runs while this screen is in the
///    foreground, and the server-corrected wall clock since the server's
///    `started_at`. Changing the phone's time does not help.
///  * Leaving the app pauses the foreground stopwatch.
///  * Back gesture is blocked; leaving requires an explicit Cancel.
///  * The screen stays awake and system bars are hidden.
class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key, required this.log});
  final PrayerLog log;

  /// 5 minutes (shortened to 20 s in demo mode).
  static Duration get minFocus => SupabaseService.instance.minFocus;

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> with WidgetsBindingObserver {
  final _db = SupabaseService.instance;
  final _foreground = Stopwatch();
  Timer? _tick;
  int _reflection = 0;
  int _leftApp = 0;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _foreground.start();
    _reflection = math.Random().nextInt(AppCopy.reflections.length);
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (t.tick % 30 == 0) _reflection = (_reflection + 1) % AppCopy.reflections.length;
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground.start();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (_foreground.isRunning) _leftApp++;
      _foreground.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Duration get _serverElapsed => _db.serverNow.difference(widget.log.startedAt ?? _db.serverNow);

  /// The smaller of the two clocks is what counts.
  Duration get _elapsed => _foreground.elapsed < _serverElapsed ? _foreground.elapsed : _serverElapsed;

  bool get _canFinish => _elapsed >= FocusTimerScreen.minFocus;

  Future<void> _finish() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final done = await _db.completePrayer(widget.log.id);
      if (mounted) Navigator.of(context).pop(done);
    } on ServerRuleException catch (e) {
      setState(() => _error = e.code == 'focus_too_short' ? '${e.message} (${e.hint ?? ''})' : e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('Stop focus mode?')),
        content: Text(tr('This prayer will not be logged. You can start again while the window is open.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Keep praying'))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Stop'))),
        ],
      ),
    );
    if (ok != true) return;
    await _db.cancelPrayer(widget.log.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = AppCopy.reflections[_reflection];
    final remaining = FocusTimerScreen.minFocus - _elapsed;
    final progress = (_elapsed.inMilliseconds / FocusTimerScreen.minFocus.inMilliseconds).clamp(0.0, 1.0);
    final mm = remaining.isNegative ? 0 : remaining.inMinutes;
    final ss = remaining.isNegative ? 0 : remaining.inSeconds % 60;
    final isQada =
        !(widget.log.startedAt != null &&
            !widget.log.startedAt!.isBefore(widget.log.windowStart) &&
            widget.log.startedAt!.isBefore(widget.log.windowEnd));

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _submitting ? null : _cancel,
                    child: Text(tr('Cancel'), style: TextStyle(color: Colors.white38)),
                  ),
                ),
                Text(widget.log.prayer.label, style: t.titleLarge?.copyWith(color: AppColors.gold)),
                if (isQada) Text(tr('Qada (late)'), style: t.bodySmall?.copyWith(color: AppColors.qada)),
                const SizedBox(height: 6),
                // Niyyah reminder: the app keeps count, but the prayer is for Allah alone.
                Text(
                  tr('For Allah alone, not for points or people.'),
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: Colors.white54, height: 1.4),
                ),
                const Spacer(),
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 5,
                          backgroundColor: Colors.white10,
                          color: _canFinish ? AppColors.onTime : AppColors.gold,
                        ),
                      ),
                      Text(
                        _canFinish ? '✓' : '$mm:${ss.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w200),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  child: Column(
                    key: ValueKey(_reflection),
                    children: [
                      Text(
                        switch (L10n.lang.value) {
                          AppLang.ml => r.ml,
                          AppLang.ar => r.ar,
                          AppLang.en => r.en,
                        },
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 20, height: 1.6),
                      ),
                      if (L10n.lang.value == AppLang.ml) ...[
                        const SizedBox(height: 10),
                        Text(
                          r.en,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white38, fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                if (_leftApp > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      tr('Timer paused while you were away ({n}×)', {'n': _leftApp}),
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!, style: const TextStyle(color: AppColors.missed)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canFinish && !_submitting ? _finish : null,
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: Colors.white10,
                      disabledForegroundColor: Colors.white24,
                    ),
                    child: Text(
                      _canFinish
                          ? tr('Done · Alhamdulillah')
                          : FocusTimerScreen.minFocus.inMinutes > 0
                          ? tr('Done opens after {n} minutes', {'n': FocusTimerScreen.minFocus.inMinutes})
                          : tr('Done opens after {n} seconds', {'n': FocusTimerScreen.minFocus.inSeconds}),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
