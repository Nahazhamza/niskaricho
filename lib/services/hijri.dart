import '../l10n/tr.dart';

/// Hijri (Islamic) date using the standard tabular calculation, plus a
/// per-device adjustment of -2..+2 days. Moon sighting differs by place
/// (Kerala often follows the Gulf announcement, other places may be a day
/// later), so people set the adjustment to match their own community.
class HijriDate {
  const HijriDate(this.year, this.month, this.day);
  final int year;
  final int month; // 1..12
  final int day;

  static const monthsEn = [
    'Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Akhir", 'Jumada al-Ula', 'Jumada al-Akhirah', //
    'Rajab', "Sha'ban", 'Ramadan', 'Shawwal', "Dhu al-Qa'dah", 'Dhu al-Hijjah',
  ];
  static const monthsMl = [
    'മുഹർറം', 'സഫർ', 'റബീഉൽ അവ്വൽ', 'റബീഉൽ ആഖിർ', 'ജമാദുൽ അവ്വൽ', 'ജമാദുൽ ആഖിർ', //
    'റജബ്', 'ശഅബാൻ', 'റമദാൻ', 'ശവ്വാൽ', 'ദുൽഖഅദ്', 'ദുൽഹിജ്ജ',
  ];

  static const monthsAr = [
    'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', //
    'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
  ];

  String get en => '$day ${monthsEn[month - 1]} $year AH';
  String get ar => '$day ${monthsAr[month - 1]} $year هـ';

  /// In the app's language.
  String get label => switch (L10n.lang.value) {
    AppLang.en => en,
    AppLang.ml => ml,
    AppLang.ar => ar,
  };
  String get ml => '$day ${monthsMl[month - 1]} $year';
  bool get isRamadan => month == 9;

  /// [date] is a local calendar day; [adjust] shifts by whole days.
  factory HijriDate.fromDate(DateTime date, {int adjust = 0}) {
    final d = DateTime.utc(date.year, date.month, date.day).add(Duration(days: adjust));
    final jd = d.millisecondsSinceEpoch ~/ 86400000 + 2440588;
    var z = jd - 1948440 + 10632;
    final n = (z - 1) ~/ 10631;
    z = z - 10631 * n + 354;
    final j = ((10985 - z) ~/ 5316) * ((50 * z) ~/ 17719) + (z ~/ 5670) * ((43 * z) ~/ 15238);
    z = z - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) - (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
    final m = (24 * z) ~/ 709;
    final day = z - (709 * m) ~/ 24;
    return HijriDate(30 * n + j - 30, m, day);
  }
}
