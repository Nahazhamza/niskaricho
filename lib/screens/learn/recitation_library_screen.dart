import 'package:material_ui/material_ui.dart';

import '../../l10n/tr.dart';
import '../../models/learn_namaz_model.dart';
import '../../services/learn_namaz_content.dart';
import '../../services/learn_namaz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fx.dart';
import 'learn_settings_sheet.dart';

class RecitationLibraryScreen extends StatefulWidget {
  const RecitationLibraryScreen({super.key});

  @override
  State<RecitationLibraryScreen> createState() => _RecitationLibraryScreenState();
}

class _RecitationLibraryScreenState extends State<RecitationLibraryScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final _categories = ['All', 'Opening', 'Quranic Recitation', 'Bowing & Prostrating', 'Sitting & Concluding'];

  List<RecitationItem> get _filteredRecitations {
    return LearnNamazContent.recitations.where((r) {
      final matchesCategory = _selectedCategory == 'All' || r.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.translation.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.transliteration.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Recitations & Duas')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => LearnSettingsSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText: tr('Search recitations, translations...'),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                ),
                onChanged: (q) => setState(() => _searchQuery = q),
              ),
            ),

            // Category Filter Chips
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(tr(cat)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                    selectedColor: AppColors.cyan.withValues(alpha: 0.3),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    side: BorderSide(
                      color: isSelected ? AppColors.cyan : Colors.white.withValues(alpha: 0.15),
                    ),
                  );
                },
              ),
            ),

            // Recitations List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredRecitations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = _filteredRecitations[index];
                  return _RecitationCard(item: item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecitationCard extends StatefulWidget {
  const _RecitationCard({required this.item});

  final RecitationItem item;

  @override
  State<_RecitationCard> createState() => _RecitationCardState();
}

class _RecitationCardState extends State<_RecitationCard> {
  final _service = LearnNamazService.instance;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final item = widget.item;

    return ValueListenableBuilder<LearnProgress>(
      valueListenable: _service.progress,
      builder: (context, prog, _) {
        final isMastered = prog.masteredRecitations.contains(item.id);

        return GlassCard(
          glow: isMastered ? AppColors.emerald : AppColors.cyan,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      tr(item.category),
                      style: const TextStyle(fontSize: 10, color: AppColors.cyan, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  // Bookmark / Mastered Button
                  IconButton(
                    icon: Icon(
                      isMastered ? Icons.bookmark : Icons.bookmark_border,
                      color: isMastered ? AppColors.gold : AppColors.muted,
                      size: 22,
                    ),
                    tooltip: isMastered ? tr('Mastered') : tr('Mark as learned'),
                    onPressed: () => _service.toggleRecitationMastered(item.id),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title & Context
              Text(tr(item.title), style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(tr(item.context), style: t.bodySmall?.copyWith(fontSize: 12, height: 1.4)),
              const SizedBox(height: 12),

              // Arabic Script Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
                ),
                child: ValueListenableBuilder<double>(
                  valueListenable: _service.arabicFontScale,
                  builder: (context, scale, _) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      item.arabicText,
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
              ),

              // Transliteration
              ValueListenableBuilder<bool>(
                valueListenable: _service.showTransliteration,
                builder: (context, show, _) {
                  if (!show) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      item.transliteration,
                      style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.gold, fontSize: 13, height: 1.35),
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
                      tr(item.translation),
                      style: t.bodySmall?.copyWith(height: 1.45, fontSize: 12.5),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),

              // Audio Controls
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _service.isPlaying,
                  builder: (context, isPlaying, _) {
                    final isCurrentTrack = _service.currentTrackId.value == item.id;
                    final playing = isPlaying && isCurrentTrack;

                    return Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: AppColors.cyan,
                            size: 28,
                          ),
                          onPressed: () => _service.playTrack(item.id, url: item.audioUrl),
                        ),
                        Expanded(
                          child: Text(
                            playing ? tr('Playing...') : tr('Listen to recitation'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        if (item.lines.length > 1)
                          TextButton.icon(
                            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
                            label: Text(_expanded ? tr('Hide lines') : tr('Line by line ({n})', {'n': item.lines.length})),
                            onPressed: () => setState(() => _expanded = !_expanded),
                          ),
                      ],
                    );
                  },
                ),
              ),

              // Line-by-Line Breakdown Drawer
              if (_expanded && item.lines.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        tr('Line-by-Line Practice:'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.cyan),
                      ),
                      const SizedBox(height: 8),
                      for (var idx = 0; idx < item.lines.length; idx++) ...[
                        _buildLineItem(idx + 1, item.lines[idx]),
                        if (idx < item.lines.length - 1)
                          Divider(color: Colors.white.withValues(alpha: 0.08), height: 16),
                      ],
                    ],
                  ),
                ),
              ],

              // Hadith Source
              const SizedBox(height: 10),
              Text(
                '📖 ${item.sourceReference}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLineItem(int num, RecitationLine line) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyan.withValues(alpha: 0.15),
            ),
            child: Text(
              '$num',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.cyan),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                line.arabic,
                style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 18,
                  height: 1.5,
                  color: AppColors.cream,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.only(left: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              line.transliteration,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.gold),
            ),
            const SizedBox(height: 2),
            Text(
              tr(line.translation),
              style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.35),
            ),
          ],
        ),
      ),
    ],
  );
}
