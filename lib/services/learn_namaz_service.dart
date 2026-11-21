import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/learn_namaz_model.dart';
import 'supabase_service.dart';

class LearnNamazService {
  LearnNamazService._();
  static final LearnNamazService instance = LearnNamazService._();

  static const _prefKey = 'learn_namaz_progress_v1';
  static const _madhhabKey = 'learn_namaz_madhhab';
  static const _fontScaleKey = 'learn_namaz_font_scale';
  static const _audioSpeedKey = 'learn_namaz_audio_speed';
  static const _repeatAudioKey = 'learn_namaz_repeat_audio';
  static const _showTransliterationKey = 'learn_namaz_show_translit';
  static const _showTranslationKey = 'learn_namaz_show_trans';

  final progress = ValueNotifier<LearnProgress>(const LearnProgress());
  final madhhab = ValueNotifier<LearningMadhhab>(LearningMadhhab.shafi);
  final arabicFontScale = ValueNotifier<double>(1.15);
  final audioSpeed = ValueNotifier<double>(1.0);
  final repeatAudio = ValueNotifier<bool>(false);
  final showTransliteration = ValueNotifier<bool>(true);
  final showTranslation = ValueNotifier<bool>(true);

  // Audio player state
  AudioPlayer? _player;
  final isPlaying = ValueNotifier<bool>(false);
  final currentTrackId = ValueNotifier<String?>(null);
  final trackPosition = ValueNotifier<Duration>(Duration.zero);
  final trackDuration = ValueNotifier<Duration>(const Duration(seconds: 10));

  Timer? _mockAudioTimer;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final p = await SharedPreferences.getInstance();
      final savedProgress = p.getString(_prefKey);
      if (savedProgress != null) {
        progress.value = LearnProgress.fromJson(jsonDecode(savedProgress) as Map<String, dynamic>);
      }

      // Sync Madhhab with user's Asr madhab if not set
      final savedMadhhab = p.getString(_madhhabKey);
      if (savedMadhhab != null) {
        madhhab.value = LearningMadhhab.values.firstWhere(
          (m) => m.name == savedMadhhab,
          orElse: () => LearningMadhhab.shafi,
        );
      } else {
        final userMadhab = SupabaseService.instance.myMadhab;
        madhhab.value = userMadhab == 'hanafi' ? LearningMadhhab.hanafi : LearningMadhhab.shafi;
      }

      arabicFontScale.value = p.getDouble(_fontScaleKey) ?? 1.15;
      audioSpeed.value = p.getDouble(_audioSpeedKey) ?? 1.0;
      repeatAudio.value = p.getBool(_repeatAudioKey) ?? false;
      showTransliteration.value = p.getBool(_showTransliterationKey) ?? true;
      showTranslation.value = p.getBool(_showTranslationKey) ?? true;

      _initPlayer();
    } catch (e) {
      debugPrint('LearnNamazService init error: $e');
    }
  }

  void _initPlayer() {
    try {
      _player = AudioPlayer();
      _player?.onPlayerStateChanged.listen((state) {
        isPlaying.value = state == PlayerState.playing;
        if (state == PlayerState.completed) {
          if (repeatAudio.value && currentTrackId.value != null) {
            _player?.seek(Duration.zero);
            _player?.resume();
          } else {
            isPlaying.value = false;
            currentTrackId.value = null;
          }
        }
      });
      _player?.onPositionChanged.listen((pos) => trackPosition.value = pos);
      _player?.onDurationChanged.listen((dur) => trackDuration.value = dur);
    } catch (e) {
      debugPrint('AudioPlayer init failed, will use simulated playback: $e');
    }
  }

  Future<void> setMadhhab(LearningMadhhab m) async {
    madhhab.value = m;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_madhhabKey, m.name);
    } catch (_) {}
  }

  Future<void> setArabicFontScale(double s) async {
    arabicFontScale.value = s.clamp(0.85, 1.6);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble(_fontScaleKey, arabicFontScale.value);
    } catch (_) {}
  }

  Future<void> setAudioSpeed(double speed) async {
    audioSpeed.value = speed;
    try {
      await _player?.setPlaybackRate(speed);
      final p = await SharedPreferences.getInstance();
      await p.setDouble(_audioSpeedKey, speed);
    } catch (_) {}
  }

  Future<void> toggleRepeatAudio() async {
    repeatAudio.value = !repeatAudio.value;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_repeatAudioKey, repeatAudio.value);
    } catch (_) {}
  }

  Future<void> toggleTransliteration() async {
    showTransliteration.value = !showTransliteration.value;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_showTransliterationKey, showTransliteration.value);
    } catch (_) {}
  }

  Future<void> toggleTranslation() async {
    showTranslation.value = !showTranslation.value;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_showTranslationKey, showTranslation.value);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // AUDIO CONTROLS (With live fallback)
  // ---------------------------------------------------------------------------
  Future<void> playTrack(String trackId, {String? url}) async {
    if (isPlaying.value && currentTrackId.value == trackId) {
      await pauseTrack();
      return;
    }

    _mockAudioTimer?.cancel();
    currentTrackId.value = trackId;
    isPlaying.value = true;
    trackPosition.value = Duration.zero;

    if (url != null && url.isNotEmpty && _player != null) {
      try {
        await _player?.stop();
        await _player?.setPlaybackRate(audioSpeed.value);
        if (url.startsWith('http')) {
          await _player?.play(UrlSource(url));
        } else {
          await _player?.play(AssetSource(url));
        }
        return;
      } catch (e) {
        debugPrint('Playing audio failed ($e), falling back to simulated playback');
      }
    }

    // Simulated playback for recitation learning when asset is offline/pending
    trackDuration.value = const Duration(seconds: 8);
    var elapsed = 0;
    _mockAudioTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      elapsed += 250;
      trackPosition.value = Duration(milliseconds: elapsed);
      if (elapsed >= 8000) {
        if (repeatAudio.value) {
          elapsed = 0;
        } else {
          timer.cancel();
          isPlaying.value = false;
          currentTrackId.value = null;
        }
      }
    });
  }

  Future<void> pauseTrack() async {
    _mockAudioTimer?.cancel();
    try {
      await _player?.pause();
    } catch (_) {}
    isPlaying.value = false;
  }

  Future<void> stopTrack() async {
    _mockAudioTimer?.cancel();
    try {
      await _player?.stop();
    } catch (_) {}
    isPlaying.value = false;
    currentTrackId.value = null;
  }

  // ---------------------------------------------------------------------------
  // PROGRESS TRACKING & REWARD
  // ---------------------------------------------------------------------------
  Future<void> completeWudu() async {
    if (progress.value.completedWudu) return;
    final updated = progress.value.copyWith(
      completedWudu: true,
      xpEarned: progress.value.xpEarned + 15,
      lastLearnedDate: DateTime.now().toIso8601String(),
    );
    await _saveProgress(updated);
  }

  Future<void> completePrayer(String prayerId) async {
    final prayers = Set<String>.from(progress.value.completedPrayers);
    final isNew = prayers.add(prayerId);
    final updated = progress.value.copyWith(
      completedPrayers: prayers,
      xpEarned: progress.value.xpEarned + (isNew ? 20 : 0),
      lastLearnedDate: DateTime.now().toIso8601String(),
    );
    await _saveProgress(updated);
  }

  Future<void> toggleRecitationMastered(String recitationId) async {
    final mastered = Set<String>.from(progress.value.masteredRecitations);
    final isNew = mastered.contains(recitationId) ? mastered.remove(recitationId) : mastered.add(recitationId);
    final updated = progress.value.copyWith(
      masteredRecitations: mastered,
      xpEarned: progress.value.xpEarned + (isNew ? 5 : 0),
      lastLearnedDate: DateTime.now().toIso8601String(),
    );
    await _saveProgress(updated);
  }

  Future<void> completeBeginnerDay(int day) async {
    if (day <= progress.value.beginnerDayCompleted) return;
    final updated = progress.value.copyWith(
      beginnerDayCompleted: day,
      xpEarned: progress.value.xpEarned + 10,
      lastLearnedDate: DateTime.now().toIso8601String(),
    );
    await _saveProgress(updated);
  }

  Future<void> _saveProgress(LearnProgress p) async {
    progress.value = p;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_prefKey, jsonEncode(p.toJson()));
    } catch (e) {
      debugPrint('Failed to save learn namaz progress: $e');
    }
  }

  void dispose() {
    _mockAudioTimer?.cancel();
    _player?.dispose();
  }
}
