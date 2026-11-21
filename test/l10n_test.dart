import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niskaricho/l10n/ar.dart';
import 'package:niskaricho/l10n/ml.dart';
import 'package:niskaricho/l10n/tr.dart';
import 'package:niskaricho/models/prayer_model.dart';
import 'package:niskaricho/models/progress_model.dart';
import 'package:niskaricho/services/demo_backend.dart';
import 'package:niskaricho/services/learn_namaz_content.dart';
import 'package:niskaricho/services/zones.dart';
import 'package:niskaricho/theme/look.dart';

/// Every tr('...') key used in lib/, plus the names passed to tr() at run time.
Set<String> usedKeys() {
  final keys = <String>{};
  // tr('..') / tr("..") including Dart's implicit concatenation over lines.
  final call = RegExp(r'''\btr\(\s*((?:(?:'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*")\s*)+)''');
  final lit = RegExp(r'''(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")''');
  final trn = RegExp(r"""\btrn\(\s*'((?:[^'\\]|\\.)*)',\s*'((?:[^'\\]|\\.)*)'""");
  String unescape(String s) =>
      s.replaceAll(r"\'", "'").replaceAll(r'\"', '"').replaceAll(r'\n', '\n').replaceAll(r'\$', r'$');
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart') || f.path.contains('l10n${Platform.pathSeparator}')) continue;
    final src = f.readAsStringSync();
    for (final m in call.allMatches(src)) {
      keys.add(lit.allMatches(m.group(1)!).map((l) => unescape(l.group(1) ?? l.group(2)!)).join());
    }
    for (final m in trn.allMatches(src)) {
      keys
        ..add(unescape(m.group(1)!))
        ..add(unescape(m.group(2)!));
    }
  }
  keys
    ..addAll(calcMethodNames.values)
    ..addAll([for (var l = 1; l <= 10; l++) levelTitle(l).en])
    ..addAll([
      for (final b in badgeCatalogue) ...[b.name, b.how],
    ])
    ..addAll([
      for (final s in AppStyle.values) ...[s.label, s.blurb],
    ])
    ..addAll([for (final s in PrayerStatus.values) (L10n.lang.value = AppLang.en, s.label).$2])
    ..add('Circle Quest: 80% on time this week')
    ..addAll(demoCities.keys)
    ..add('Your location')
    ..addAll([
      for (final s in LearnNamazContent.wuduSteps) ...[
        s.title,
        s.whatToDo,
        s.howToDo,
        if (s.translation != null) s.translation!,
        ...s.commonMistakes,
      ],
    ])
    ..addAll([
      for (final s in LearnNamazContent.salahSteps) ...[
        s.title,
        s.explanation,
        s.translation,
      ],
    ])
    ..addAll([
      for (final p in LearnNamazContent.prayers) ...[
        p.description,
        p.structureSummary,
        ...p.rakahSummary,
      ],
    ])
    ..addAll([
      for (final d in LearnNamazContent.beginnerDays) ...[
        d.title,
        d.subtitle,
        d.overview,
        ...d.keyTakeaways,
        d.practicalStep,
      ],
    ])
    ..addAll([
      for (final r in LearnNamazContent.recitations) ...[
        r.title,
        r.context,
        r.translation,
        for (final l in r.lines) l.translation,
      ],
    ]);
  return keys;
}

void main() {
  final keys = usedKeys();

  test('found the UI text', () {
    expect(keys.length, greaterThan(300));
    // DUMP_L10N_KEYS=path writes the keys as JSON (for translators).
    final out = Platform.environment['DUMP_L10N_KEYS'];
    if (out != null) File(out).writeAsStringSync(jsonEncode(keys.toList()..sort()));
  });

  for (final (name, table) in [('Malayalam', mlStrings), ('Arabic', arStrings)]) {
    test('$name has every key', () {
      final missing = keys.where((k) => !table.containsKey(k)).toList()..sort();
      expect(missing, isEmpty, reason: '$name is missing ${missing.length}:\n${missing.join('\n')}');
    });
    test('$name keeps every {placeholder}', () {
      final ph = RegExp(r'\{(\w+)\}');
      for (final e in table.entries) {
        final want = ph.allMatches(e.key).map((m) => m.group(1)).toSet();
        final got = ph.allMatches(e.value).map((m) => m.group(1)).toSet();
        expect(got, want, reason: '$name: "${e.key}"');
      }
    });
  }
}
