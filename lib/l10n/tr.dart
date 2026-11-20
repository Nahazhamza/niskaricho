// App language: English, Malayalam or Arabic (right to left).
//
// Every piece of UI text goes through tr('English text'). The English text is
// the key; ml.dart and ar.dart hold the translations. A test
// (test/l10n_test.dart) fails if any tr('...') used in lib/ is missing from
// either file, so no screen can ship half translated.
//
// Placeholders: tr('Joined {name}', {'name': c.name}).
//
// Malayalam and Arabic were written in plain, simple words for older users.
// They still need a native speaker's review: see docs/translation_review.md.

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ar.dart';
import 'ml.dart';

enum AppLang {
  en('English', 'English'),
  ml('മലയാളം', 'Malayalam'),
  ar('العربية', 'Arabic');

  const AppLang(this.native, this.english);
  final String native;
  final String english;

  Locale get locale => Locale(name);
  bool get rtl => this == AppLang.ar;
}

class L10n {
  L10n._();

  /// Current language. The whole app rebuilds when it changes.
  static final lang = ValueNotifier<AppLang>(AppLang.ml);

  /// False until the person has picked a language on the first screen.
  static bool chosen = false;

  /// Text size for older eyes: 1.0 normal, 1.15 large (default), 1.3 extra large.
  static final textScale = ValueNotifier<double>(1.15);

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final saved = p.getString('app.lang');
      chosen = saved != null;
      lang.value = AppLang.values.asNameMap()[saved] ?? AppLang.ml;
      textScale.value = p.getDouble('app.textScale') ?? 1.15;
    } catch (_) {}
  }

  static Future<void> set(AppLang l) async {
    lang.value = l;
    chosen = true;
    try {
      await (await SharedPreferences.getInstance()).setString('app.lang', l.name);
    } catch (_) {}
  }

  static Future<void> setTextScale(double s) async {
    textScale.value = s;
    try {
      await (await SharedPreferences.getInstance()).setDouble('app.textScale', s);
    } catch (_) {}
  }

  static Map<String, String>? get _table => switch (lang.value) {
    AppLang.en => null,
    AppLang.ml => mlStrings,
    AppLang.ar => arStrings,
  };
}

/// Translate [en] into the current language, filling {placeholders}.
String tr(String en, [Map<String, Object?> args = const {}]) {
  var s = L10n._table?[en] ?? en;
  args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

/// Translate a word that changes with a count: tr1('1 day', '{n} days', n).
String trn(String one, String many, int n) => n == 1 ? tr(one, {'n': n}) : tr(many, {'n': n});
