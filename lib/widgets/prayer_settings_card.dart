import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../models/prayer_model.dart';
import '../services/demo_backend.dart' show demoCities;
import '../services/supabase_service.dart';
import '../services/zones.dart';
import '../theme/app_theme.dart';
import 'fx.dart';

/// Prayer time settings: automatic method by region (or a fixed one), Asr
/// madhab, and per-prayer mosque offsets with a live preview. Nothing is
/// sent until Save, because the server only accepts one change every 6 hours.
class PrayerSettingsCard extends StatefulWidget {
  const PrayerSettingsCard({super.key});

  @override
  State<PrayerSettingsCard> createState() => _PrayerSettingsCardState();
}

class _PrayerSettingsCardState extends State<PrayerSettingsCard> {
  final _db = SupabaseService.instance;
  late bool _auto = _db.myMethodAuto;
  late String _method = _db.myMethod;
  late String _madhab = _db.myMadhab;
  late final List<int> _offsets = List.of(_db.myOffsets);
  bool _saving = false;

  String get _effectiveMethod => _auto ? methodForTimezone(_db.myTimezone) : _method;

  bool get _dirty =>
      _auto != _db.myMethodAuto ||
      (!_auto && _method != _db.myMethod) ||
      _madhab != _db.myMadhab ||
      !_listEq(_offsets, _db.myOffsets);

  static bool _listEq(List<int> a, List<int> b) =>
      a.length == b.length && [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _db.savePrayerSettings(auto: _auto, method: _effectiveMethod, madhab: _madhab, offsets: _offsets);
      _db.settingsChanged.value++;
      _toast(tr('Saved. Your Today tab and circles now use these times.'));
    } on ServerRuleException catch (e) {
      _toast(
        e.code == 'settings_cooldown'
            ? tr(
                'Prayer time settings can change once every 6 hours (so nobody can stretch a window). Try again later.',
              )
            : e.message,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickCity(String city) async {
    await _db.setMyLocation(demoCities[city]!.$1, place: city);
    _db.demo.myself.pinned = true;
    _db.settingsChanged.value++;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final loc = _db.myLocation;
    final preview = loc == null
        ? const <PrayerWindow>[]
        : _db.myCalculator(method: _effectiveMethod, madhab: _madhab, offsets: _offsets).windowsFor(loc, _db.myToday);
    InputDecoration deco(String label) => InputDecoration(labelText: label, isDense: true);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('🧭 Prayer time settings'), style: t.titleMedium),
          const SizedBox(height: 4),
          Text(
            '📍 ${_db.myPlaceLabel} · ${_db.myTimezone ?? ''} (${Zones.offsetLabel(_db.myTimezone)})',
            style: t.bodySmall,
          ),
          Text(
            tr(
              'Location comes from GPS and updates by itself when you travel. The clock is the server\'s, so changing the phone\'s time changes nothing.',
            ),
            style: t.bodySmall?.copyWith(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          if (_db.isDemo) ...[
            DropdownButtonFormField<String>(
              initialValue: demoCities.containsKey(_db.myPlaceLabel) ? _db.myPlaceLabel : null,
              decoration: deco(tr('Demo: pretend I am in…')),
              items: [for (final c in demoCities.keys) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (c) => c == null ? null : _pickCity(c),
            ),
            const SizedBox(height: 10),
          ],
          DropdownButtonFormField<String>(
            initialValue: _auto ? 'auto' : _method,
            isExpanded: true,
            decoration: deco(tr('Calculation method')),
            items: [
              DropdownMenuItem(
                value: 'auto',
                child: Text(
                  tr('Automatic: {method}', {'method': calcMethodLabels[methodForTimezone(_db.myTimezone)]}),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              for (final e in calcMethodLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (m) => setState(() {
              if (m == 'auto') {
                _auto = true;
              } else if (m != null) {
                _auto = false;
                _method = m;
              }
            }),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _madhab,
            decoration: deco(tr('Asr')),
            items: [
              DropdownMenuItem(value: 'shafi', child: Text(tr("Shafi'i (standard, Kerala)"))),
              DropdownMenuItem(value: 'hanafi', child: Text(tr('Hanafi (later Asr)'))),
            ],
            onChanged: (m) => setState(() => _madhab = m ?? _madhab),
          ),
          const SizedBox(height: 14),
          Text(tr('Match your mosque (minutes)'), style: t.titleSmall),
          const SizedBox(height: 4),
          for (final (i, p) in PrayerName.values.indexed)
            Row(
              children: [
                SizedBox(width: 92, child: Text(p.label, style: t.bodySmall)),
                IconButton(
                  tooltip: tr('Earlier'),
                  onPressed: _offsets[i] > -10 ? () => setState(() => _offsets[i]--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(
                  width: 34,
                  child: Text(
                    _offsets[i] == 0 ? '0' : '${_offsets[i] > 0 ? '+' : ''}${_offsets[i]}',
                    textAlign: TextAlign.center,
                    style: t.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: tr('Later'),
                  onPressed: _offsets[i] < 10 ? () => setState(() => _offsets[i]++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const Spacer(),
                if (preview.length == 5)
                  Text(
                    Zones.hm(preview[i].start, _db.myTimezone),
                    style: t.titleSmall?.copyWith(
                      color: AppColors.gold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _dirty && !_saving ? _save : null,
            child: Text(_saving ? 'Saving…' : tr('Save prayer time settings')),
          ),
          const SizedBox(height: 6),
          Text(
            tr(
              'Kerala: Karachi + Shafi\'i. UAE: UAE (Dubai). Times on the right are a preview for today. Settings can be saved once every 6 hours.',
            ),
            style: t.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
