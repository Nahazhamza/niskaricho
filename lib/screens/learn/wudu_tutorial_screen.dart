import 'package:material_ui/material_ui.dart';

import '../../l10n/tr.dart';
import '../../services/learn_namaz_content.dart';
import '../../services/learn_namaz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fx.dart';
import '../../widgets/learn_namaz_illustrations.dart';
import 'learn_settings_sheet.dart';

class WuduTutorialScreen extends StatefulWidget {
  const WuduTutorialScreen({super.key});

  @override
  State<WuduTutorialScreen> createState() => _WuduTutorialScreenState();
}

class _WuduTutorialScreenState extends State<WuduTutorialScreen> {
  final _service = LearnNamazService.instance;
  late final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _completed = false;

  final _steps = LearnNamazContent.wuduSteps;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() => _completed = true);
      _service.completeWudu();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _restartWudu() {
    setState(() {
      _completed = false;
      _currentStep = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Learn Wudu')),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: tr('Wudu Rules & Invalidators'),
            onPressed: () => _showWuduIntroDialog(context),
          ),
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

  Widget _buildTutorialBody(TextTheme t) => Column(
    children: [
      // Progress indicators
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('Step {n} of {total}', {'n': _currentStep + 1, 'total': _steps.length}),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.cyan),
                ),
                Text(
                  _steps[_currentStep].isObligatory ? tr('Farḍ (Obligatory)') : tr('Sunnah (Recommended)'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _steps[_currentStep].isObligatory ? AppColors.gold : AppColors.emerald,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _steps.length,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
              ),
            ),
          ],
        ),
      ),

      // Interactive Step Cards
      Expanded(
        child: PageView.builder(
          controller: _pageController,
          itemCount: _steps.length,
          onPageChanged: (i) => setState(() => _currentStep = i),
          itemBuilder: (context, index) {
            final step = _steps[index];
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children: [
                  // Vector Illustration
                  Center(
                    child: WuduStepIllustration(
                      stepNumber: step.stepNumber,
                      size: 170,
                      primaryColor: step.isObligatory ? AppColors.cyan : AppColors.emerald,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title Card
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    glow: step.isObligatory ? AppColors.cyan : AppColors.emerald,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (step.isObligatory ? AppColors.gold : AppColors.emerald).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (step.isObligatory ? AppColors.gold : AppColors.emerald).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  step.isObligatory ? tr('FARḌ') : tr('SUNNAH'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: step.isObligatory ? AppColors.gold : AppColors.emerald,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tr(step.title),
                                style: t.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.bold, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tr(step.whatToDo),
                          style: t.bodyMedium?.copyWith(color: AppColors.cream, height: 1.45, fontSize: 13.5),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text('💡', style: TextStyle(fontSize: 15)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tr(step.howToDo),
                                  style: t.bodySmall?.copyWith(height: 1.4, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Arabic supplication if available
                        if (step.arabicSupplication != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    step.arabicSupplication!,
                                    style: const TextStyle(
                                      fontFamily: 'NotoNaskhArabic',
                                      fontSize: 22,
                                      height: 1.6,
                                      color: AppColors.cream,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (step.transliteration != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    step.transliteration!,
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.gold,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                if (step.translation != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    tr(step.translation!),
                                    style: t.bodySmall?.copyWith(fontSize: 12, height: 1.4),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // Common mistakes
                        if (step.commonMistakes.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            tr('Common Mistakes to Avoid:'),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFFFB4A2)),
                          ),
                          const SizedBox(height: 6),
                          for (final mistake in step.commonMistakes)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Text('⚠️ ', style: TextStyle(fontSize: 11)),
                                  ),
                                  Expanded(
                                    child: Text(tr(mistake), style: t.bodySmall?.copyWith(fontSize: 12, height: 1.35)),
                                  ),
                                ],
                              ),
                            ),
                        ],

                        // Hadith reference
                        if (step.sourceReference != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            '📖 ${step.sourceReference!}',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),

      // Bottom Navigation Buttons
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF030D12),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: Row(
          children: [
            if (_currentStep > 0)
              OutlinedButton.icon(
                onPressed: _previousStep,
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
              onPressed: _nextStep,
              icon: Icon(_currentStep == _steps.length - 1 ? Icons.check_circle : Icons.arrow_forward),
              label: Text(_currentStep == _steps.length - 1 ? tr('Complete Wudu') : tr('Next Step')),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: const Color(0xFF041820),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildCompletionScreen(TextTheme t) {
    final dua = LearnNamazContent.postWuduDua;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.emerald.withValues(alpha: 0.2),
              border: Border.all(color: AppColors.emerald, width: 2),
            ),
            child: const Center(
              child: Text('💧', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr('Masha Allah! Wudu Completed'),
            style: t.headlineSmall?.copyWith(color: AppColors.cream, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            tr('You have learned all 12 steps of the Prophetic ablution. (+15 XP)'),
            style: t.bodyMedium?.copyWith(color: AppColors.emerald),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Post-Wudu Dua Card
          GlassCard(
            glow: AppColors.gold,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('🤲', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr(dua.title),
                        style: t.titleMedium?.copyWith(color: AppColors.gold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    dua.arabicText,
                    style: const TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 22,
                      height: 1.7,
                      color: AppColors.cream,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  dua.transliteration,
                  style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.gold, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  dua.translation,
                  style: t.bodySmall?.copyWith(height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '📖 ${dua.sourceReference}',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.45)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _restartWudu,
                  icon: const Icon(Icons.refresh),
                  label: Text(tr('Practice Wudu Again')),
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
  }

  void _showWuduIntroDialog(BuildContext context) {
    final t = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF071E22),
        title: Row(
          children: [
            const Text('💧', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(tr('What Invalidates Wudu?'), style: t.titleMedium),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr('Things that break Wudu (Hadath):'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.cyan),
              ),
              const SizedBox(height: 8),
              for (final inv in LearnNamazContent.wuduInvalidators)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(inv, style: const TextStyle(fontSize: 12, height: 1.35))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('Close')),
          ),
        ],
      ),
    );
  }
}
