import 'package:material_ui/material_ui.dart';

import '../../l10n/tr.dart';
import '../../models/learn_namaz_model.dart';
import '../../services/learn_namaz_content.dart';
import '../../services/learn_namaz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fx.dart';
import '../../widgets/learn_namaz_illustrations.dart';
import 'learn_settings_sheet.dart';

class SalahGuideScreen extends StatefulWidget {
  const SalahGuideScreen({super.key, this.prayer});

  final PrayerInfo? prayer;

  @override
  State<SalahGuideScreen> createState() => _SalahGuideScreenState();
}

class _SalahGuideScreenState extends State<SalahGuideScreen> {
  final _service = LearnNamazService.instance;
  late final PageController _pageController = PageController();
  int _currentStepIndex = 0;
  bool _completed = false;

  late final List<SalahStep> _guideSteps = _buildStepsForPrayer(widget.prayer);

  List<SalahStep> _buildStepsForPrayer(PrayerInfo? p) {
    if (p == null) {
      return LearnNamazContent.salahSteps;
    }

    final all = {for (final s in LearnNamazContent.salahSteps) s.position: s};
    final steps = <SalahStep>[];
    final totalRakats = p.fardRakats;

    // Step 1: Intention
    steps.add(all[SalahPosition.niyyah]!);

    // Step 2: Takbiratul Ihram
    steps.add(all[SalahPosition.takbir]!);

    for (var r = 1; r <= totalRakats; r++) {
      // Qiyam
      steps.add(
        SalahStep(
          id: '${p.id}_r${r}_qiyam',
          stepNumber: steps.length + 1,
          title: 'Rak\'ah $r: Qiyam & ${r <= 2 ? "Fatiha + Surah" : "Fatiha Only"}',
          position: SalahPosition.qiyam,
          ruling: RulingLevel.fard,
          arabicText: all[SalahPosition.qiyam]!.arabicText,
          transliteration: all[SalahPosition.qiyam]!.transliteration,
          translation: all[SalahPosition.qiyam]!.translation,
          explanation: r <= 2
              ? 'Recite Surah Al-Fatiha followed by a short Surah (such as Al-Ikhlas).'
              : 'In Rak\'ah $r, recite ONLY Surah Al-Fatiha silently. No additional Surah is recited.',
          repetition: 1,
          sourceReference: 'Sahih al-Bukhari 756',
        ),
      );

      // Ruku
      steps.add(all[SalahPosition.ruku]!);

      // I'tidal
      steps.add(all[SalahPosition.itidal]!);

      // Sujood 1
      steps.add(all[SalahPosition.sujood1]!);

      // Jalsah
      steps.add(all[SalahPosition.jalsah]!);

      // Sujood 2
      steps.add(all[SalahPosition.sujood2]!);

      // Sitting conditions
      if (r == 2 && totalRakats > 2) {
        // First Tashahhud
        steps.add(all[SalahPosition.tashahhudFirst]!);
      } else if (r == totalRakats) {
        // Final sitting
        steps.add(all[SalahPosition.tashahhudFinal]!);
        steps.add(all[SalahPosition.salawat]!);
        steps.add(all[SalahPosition.dua]!);
        steps.add(all[SalahPosition.tasleem]!);
      }
    }

    return steps;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _service.stopTrack();
    super.dispose();
  }

  void _next() {
    if (_currentStepIndex < _guideSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() => _completed = true);
      if (widget.prayer != null) {
        _service.completePrayer(widget.prayer!.id);
      }
    }
  }

  void _previous() {
    if (_currentStepIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _restart() {
    setState(() {
      _completed = false;
      _currentStepIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final title = widget.prayer != null ? '${tr(widget.prayer!.name)} (${widget.prayer!.fardRakats} Farḍ)' : tr('Step-by-Step Salah Guide');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => LearnSettingsSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _completed ? _buildCompletionScreen(t) : _buildTutorialBody(t),
      ),
    );
  }

  Widget _buildTutorialBody(TextTheme t) {
    final current = _guideSteps[_currentStepIndex];

    return Column(
      children: [
        // Top Step Progress Indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('Step {n} of {total}', {'n': _currentStepIndex + 1, 'total': _guideSteps.length}),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.cyan, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      tr(current.ruling.label),
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.gold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStepIndex + 1) / _guideSteps.length,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                ),
              ),
            ],
          ),
        ),

        // Interactive Page View
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _guideSteps.length,
            onPageChanged: (i) {
              _service.stopTrack();
              setState(() => _currentStepIndex = i);
            },
            itemBuilder: (context, index) {
              final step = _guideSteps[index];

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                child: Column(
                  children: [
                    // Visual Posture Diagram
                    Center(
                      child: SalahPostureIllustration(
                        position: step.position,
                        size: 175,
                        primaryColor: AppColors.emerald,
                        accentColor: AppColors.cyan,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Main Step Card
                    GlassCard(
                      padding: const EdgeInsets.all(18),
                      glow: AppColors.emerald,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            tr(step.title),
                            style: t.titleLarge?.copyWith(fontSize: 19, color: AppColors.cream, height: 1.35),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr(step.explanation),
                            style: t.bodySmall?.copyWith(height: 1.45, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // Arabic Recitation Box
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.emerald.withValues(alpha: 0.35)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ValueListenableBuilder<double>(
                                  valueListenable: _service.arabicFontScale,
                                  builder: (context, scale, _) => Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      step.arabicText,
                                      style: TextStyle(
                                        fontFamily: 'NotoNaskhArabic',
                                        fontSize: 22 * scale,
                                        height: 1.6,
                                        color: AppColors.cream,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                if (step.repetition > 1) ...[
                                  const SizedBox(height: 6),
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.gold.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '🔁 ${tr('Recite at least {n} times', {'n': step.repetition})}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Transliteration
                          ValueListenableBuilder<bool>(
                            valueListenable: _service.showTransliteration,
                            builder: (context, show, _) {
                              if (!show) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  step.transliteration,
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.gold,
                                    fontSize: 13.5,
                                    height: 1.35,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),

                          // English Translation
                          ValueListenableBuilder<bool>(
                            valueListenable: _service.showTranslation,
                            builder: (context, show, _) {
                              if (!show) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  tr(step.translation),
                                  style: t.bodySmall?.copyWith(fontSize: 12.5, height: 1.45),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),

                          // Audio Playback Bar
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _service.isPlaying,
                              builder: (context, isPlaying, _) {
                                final isCurrentTrack = _service.currentTrackId.value == step.id;
                                final playing = isPlaying && isCurrentTrack;

                                return Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                        color: AppColors.cyan,
                                        size: 32,
                                      ),
                                      onPressed: () => _service.playTrack(step.id, url: step.audioUrl),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        playing ? tr('Listening to recitation...') : tr('Listen to pronunciation'),
                                        style: const TextStyle(fontSize: 12, color: AppColors.cream),
                                      ),
                                    ),
                                    ValueListenableBuilder<bool>(
                                      valueListenable: _service.repeatAudio,
                                      builder: (context, rep, _) => IconButton(
                                        icon: Icon(
                                          Icons.repeat,
                                          color: rep ? AppColors.gold : AppColors.muted,
                                          size: 20,
                                        ),
                                        tooltip: tr('Repeat audio'),
                                        onPressed: () => _service.toggleRepeatAudio(),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          // Madhhab Specific Note
                          ValueListenableBuilder<LearningMadhhab>(
                            valueListenable: _service.madhhab,
                            builder: (context, m, _) {
                              final note = step.madhhabNotes[m];
                              if (note == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('📌 ', style: TextStyle(fontSize: 12)),
                                      Expanded(
                                        child: Text(
                                          '${m.label}: $note',
                                          style: const TextStyle(fontSize: 11, color: AppColors.gold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Hadith reference
                          const SizedBox(height: 12),
                          Text(
                            '📖 ${step.sourceReference}',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Navigation Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF030D12),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: Row(
            children: [
              if (_currentStepIndex > 0)
                OutlinedButton.icon(
                  onPressed: _previous,
                  icon: const Icon(Icons.arrow_back),
                  label: Text(tr('Previous')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cream,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                )
              else
                const Spacer(),
              const Spacer(),
              FilledButton.icon(
                onPressed: _next,
                icon: Icon(_currentStepIndex == _guideSteps.length - 1 ? Icons.check_circle : Icons.arrow_forward),
                label: Text(_currentStepIndex == _guideSteps.length - 1 ? tr('Complete Salah') : tr('Next Movement')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionScreen(TextTheme t) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.emerald.withValues(alpha: 0.2),
            border: Border.all(color: AppColors.emerald, width: 2),
          ),
          child: const Center(
            child: Text('🕌', style: TextStyle(fontSize: 44)),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          tr('Alhamdulillah! Salah Guide Completed'),
          style: t.headlineSmall?.copyWith(color: AppColors.cream, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.prayer != null
              ? tr('You have walked through the complete {p} prayer. (+20 XP)', {'p': tr(widget.prayer!.name)})
              : tr('You have walked through all 13 positions of Salah. (+20 XP)'),
          style: t.bodyMedium?.copyWith(color: AppColors.emerald),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GlassCard(
          padding: const EdgeInsets.all(18),
          glow: AppColors.gold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('What to Remember When Praying:'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              _tipItem('🤲', tr('Khushu (Devotion): Stand with humility knowing you are directly before Allah.')),
              _tipItem('⏱️', tr('Tranquility (Tuma\'ninah): Pause in every position until your bones settle.')),
              _tipItem('📖', tr('Pronunciation: Pronounce each letter clearly and do not rush verses.')),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.refresh),
                label: Text(tr('Practice Again')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cream,
                  side: const BorderSide(color: AppColors.cyan),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: Text(tr('Done')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _tipItem(String emoji, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, height: 1.35))),
      ],
    ),
  );
}
