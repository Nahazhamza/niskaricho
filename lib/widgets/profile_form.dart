import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// Name, gender, birth year, language, Asr madhab, home mosque and circle
/// privacy. Used on first open and in Journey → Profile.
class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key, required this.onSaved, this.saveLabel});
  final VoidCallback onSaved;
  final String? saveLabel;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _db = SupabaseService.instance;
  late final _name = TextEditingController(text: _db.myName == 'You' || _db.myName == 'Friend' ? '' : _db.myName);
  late final _mosque = TextEditingController(text: _db.myMosque ?? '');
  late String? _gender = _db.myGender;
  late int? _birthYear = _db.myBirthYear;
  // The app language is chosen on the first screen; this keeps it in sync.
  late String _language = L10n.lang.value.name;
  late String _madhab = _db.myMadhab;
  late bool _hide = _db.myHideStatus;
  bool _saving = false;
  String? _error;

  int? get _age => _birthYear == null ? null : DateTime.now().year - _birthYear!;

  String? get _ageNote {
    final a = _age;
    if (a == null) return null;
    if (a < 7) return tr('Children under 7 are not asked to pray yet. You can still use the app together as a family.');
    if (a < 15) {
      return tr(
        'Practice years: children are taught to pray from 7. Prayer becomes a duty at puberty (at the latest 15 lunar years). A parent should set this up with you.',
      );
    }
    if (a < 18) return tr('Under 18: please ask a parent before joining circles.');
    return null;
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      setState(() => _error = tr('Please enter your name (at least 2 letters).'));
      return;
    }
    if (_gender == null) {
      setState(() => _error = tr('Please choose Male or Female.'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _db.updateProfile(
        name: _name.text.trim(),
        gender: _gender,
        birthYear: _birthYear,
        mosque: _mosque.text.trim(),
        language: _language,
        hideStatus: _hide,
      );
      if (_madhab != _db.myMadhab) {
        await _db.savePrayerSettings(
          auto: _db.myMethodAuto,
          method: _db.myMethod,
          madhab: _madhab,
          offsets: _db.myOffsets,
        );
      }
      if (_language != L10n.lang.value.name) {
        await L10n.set(AppLang.values.byName(_language)); // rebuilds the app in the new language
      }
      widget.onSaved();
    } on ServerRuleException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _mosque.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final thisYear = DateTime.now().year;
    InputDecoration deco(String label, [String? hint]) =>
        InputDecoration(labelText: label, hintText: hint, isDense: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('profile-name'),
          controller: _name,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          decoration: deco(tr('Your name'), tr('Shown to your circles')),
        ),
        const SizedBox(height: 4),
        Text(tr('Gender'), style: t.titleSmall),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'male', label: Text(tr('Male'))),
            ButtonSegment(value: 'female', label: Text(tr('Female'))),
          ],
          emptySelectionAllowed: true,
          selected: {?_gender},
          onSelectionChanged: (s) => setState(() => _gender = s.firstOrNull),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            tr(
              'Private: only you see it. Women get a private haid and nifas pause, so excused prayers are never counted as missed.',
            ),
            style: t.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _birthYear,
          decoration: deco(tr('Year of birth (private)')),
          menuMaxHeight: 320,
          items: [for (var y = thisYear - 5; y >= thisYear - 95; y--) DropdownMenuItem(value: y, child: Text('$y'))],
          onChanged: (y) => setState(() => _birthYear = y),
        ),
        if (_ageNote != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_ageNote!, style: t.bodySmall?.copyWith(color: AppColors.gold)),
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _madhab,
          decoration: deco(tr('Madhab (for Asr time and period rules)')),
          items: [
            DropdownMenuItem(value: 'shafi', child: Text(tr("Shafi'i (most of Kerala)"))),
            DropdownMenuItem(value: 'hanafi', child: Text(tr('Hanafi'))),
          ],
          onChanged: (m) => setState(() => _madhab = m ?? _madhab),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _language,
          decoration: deco(tr('App language')),
          items: [for (final l in AppLang.values) DropdownMenuItem(value: l.name, child: Text(l.native))],
          onChanged: (l) => setState(() => _language = l ?? _language),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('profile-mosque'),
          controller: _mosque,
          maxLength: 60,
          decoration: deco(tr('Home mosque (optional)'), tr('for example: Kallai Juma Masjid')),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tr('Keep my prayers private in circles')),
          subtitle: Text(tr('Circles see "Not shared" instead of your status. You can change this any time.')),
          value: _hide,
          onChanged: (v) => setState(() => _hide = v),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: const TextStyle(color: AppColors.missed)),
          ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? tr('Saving…') : widget.saveLabel ?? tr('Save profile')),
        ),
      ],
    );
  }
}
