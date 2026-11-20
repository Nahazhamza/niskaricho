// Notification text and Focus Mode reflections in English, Malayalam and
// Arabic. Plain words, short sentences. The Malayalam variety is kept from v1
// (several messages, one picked at random so reminders do not feel robotic).
// Malayalam and Arabic need a native speaker's review: docs/translation_review.md.

import 'dart:math';

import '../models/prayer_model.dart';
import 'tr.dart';

class AppCopy {
  AppCopy._();
  static final _rng = Random();
  static T _pick<T>(List<T> l) => l[_rng.nextInt(l.length)];
  static AppLang get _l => L10n.lang.value;

  // Adhan time (window opens) -------------------------------------------------
  static ({String title, String body}) adhan(PrayerName p) {
    final n = p.label;
    return switch (_l) {
      AppLang.en => (
        title: '🕌 $n time',
        body: _pick([
          'It is time for $n. Pray now while the time is good.',
          p == PrayerName.fajr
              ? 'Prayer is better than sleep. Time for Fajr 🌅'
              : 'Take a short break for Allah. $n time has started.',
        ]),
      ),
      AppLang.ar => (
        title: '🕌 حان وقت $n',
        body: _pick([
          'حان الآن وقت صلاة $n. صلِّ في أول الوقت.',
          p == PrayerName.fajr ? 'الصلاة خير من النوم. حان وقت الفجر 🌅' : 'خذ استراحة قصيرة لله. دخل وقت $n.',
        ]),
      ),
      AppLang.ml => (
        title: '$n ബാങ്ക് 🕌',
        body: _pick(switch (p) {
          PrayerName.fajr => [
            'സുബ്ഹ് ബാങ്ക് കൊടുത്തു. ഉറക്കത്തേക്കാൾ ഉത്തമം നിസ്കാരമാണ് 🌅',
            'അസ്സലാത്തു ഖൈറും മിനന്നൗം. എഴുന്നേൽക്കൂ, സുബ്ഹിന്റെ സമയമായി.',
            'പുലരിയുടെ ബറകത്ത് നിസ്കാരത്തോടെ തുടങ്ങാം 🤲',
          ],
          PrayerName.dhuhr => [
            'ളുഹർ സമയമായി. ജോലിക്കിടയിൽ അല്ലാഹുവിനായി ഒരു ചെറിയ ഇടവേള ☀️',
            'ക്ലാസും ഓഫീസും ഒന്ന് നിർത്താം, ളുഹർ നിസ്കരിക്കാം.',
          ],
          PrayerName.asr => [
            'അസർ സമയമായി. വൈകുന്നേരത്തെ തിരക്കിൽ മറക്കല്ലേ 🌤️',
            'അസർ നിസ്കാരം കാത്തിരിക്കുന്നു. ഇപ്പോൾ തന്നെ ആവാം.',
          ],
          PrayerName.maghrib => [
            'മഗ്‌രിബ് ബാങ്ക് കൊടുത്തു. സമയം കുറവാണ്, വേഗം നിസ്കരിക്കാം 🌇',
            'സൂര്യൻ അസ്തമിച്ചു. മഗ്‌രിബിന്റെ സമയമായി.',
          ],
          PrayerName.isha => [
            'ഇശാ സമയമായി. ദിവസം നിസ്കാരത്തോടെ അവസാനിപ്പിക്കാം 🌙',
            'ഉറങ്ങുന്നതിന് മുൻപ് ഇശാ നിസ്കരിച്ചോ?',
          ],
        }),
      ),
    };
  }

  // 20 minutes before the time ends ------------------------------------------
  static ({String title, String body}) expiryWarning(PrayerName p) {
    final n = p.label;
    return switch (_l) {
      AppLang.en => (title: '⏰ 20 minutes left for $n', body: 'Have you prayed $n? Pray now, before the time ends.'),
      AppLang.ar => (title: '⏰ بقي ٢٠ دقيقة على نهاية وقت $n', body: 'هل صليت $n؟ صلِّ الآن قبل أن ينتهي الوقت.'),
      AppLang.ml => (
        title: '⏰ $n സമയം തീരാൻ 20 മിനിറ്റ്',
        body: _pick([
          '$n ഇനിയും നിസ്കരിച്ചില്ലേ? ഖളാ ആകുന്നതിന് മുൻപ് വേഗം!',
          'സമയം കഴിയാറായി. ഇപ്പോൾ നിസ്കരിച്ചാൽ സമയത്ത് തന്നെ ആകും 🟢',
          'ഒരു 5 മിനിറ്റ് മതി. $n നിസ്കരിക്കാം, ഇൻ ഷാ അല്ലാഹ്.',
        ]),
      ),
    };
  }

  // Reminder from someone in your circle -------------------------------------
  static ({String title, String body}) nudge(PrayerName p, String fromName) {
    final n = p.label;
    return switch (_l) {
      AppLang.en => (title: '$fromName reminded you 👋', body: 'It is $n time. Did you pray?'),
      AppLang.ar => (title: '$fromName يذكّرك 👋', body: 'حان وقت $n. هل صليت؟'),
      AppLang.ml => (
        title: '$fromName നിങ്ങളെ ഓർമ്മിപ്പിച്ചു 👋',
        body: _pick([
          '$n സമയമായി, നിസ്കരിച്ചോ?',
          '$n കഴിഞ്ഞോ? സമയം തീരാറായി 😊',
          'നമ്മുടെ സർക്കിൾ മുഴുവൻ $n പൂർത്തിയാക്കാം. നിങ്ങളും വരൂ! 🤝',
          'ദുആയിൽ ഓർക്കണേ, $n നിസ്കരിക്കാൻ മറക്കല്ലേ 🤲',
        ]),
      ),
    };
  }

  // Focus Mode reflections ----------------------------------------------------
  // en is shown in English, ml (with the English below it) in Malayalam,
  // ar in Arabic (Quran and hadith in their original words).
  static const reflections = <({String ml, String en, String ar})>[
    (
      ml: 'നിസ്കാരത്തിൽ ഭക്തിയുള്ളവർ വിജയിച്ചിരിക്കുന്നു.',
      en: 'Successful indeed are the believers, those who humble themselves in prayer. (23:1-2)',
      ar: 'قَدْ أَفْلَحَ الْمُؤْمِنُونَ ۝ الَّذِينَ هُمْ فِي صَلَاتِهِمْ خَاشِعُونَ (المؤمنون ١-٢)',
    ),
    (
      ml: 'നീ അല്ലാഹുവിനെ കാണുന്നത് പോലെ ആരാധിക്കുക. നീ അവനെ കാണുന്നില്ലെങ്കിലും അവൻ നിന്നെ കാണുന്നു.',
      en: 'Worship Allah as if you see Him; and if you do not see Him, He surely sees you. (Hadith Jibril)',
      ar: 'أَنْ تَعْبُدَ اللَّهَ كَأَنَّكَ تَرَاهُ، فَإِنْ لَمْ تَكُنْ تَرَاهُ فَإِنَّهُ يَرَاكَ (حديث جبريل)',
    ),
    (
      ml: 'ഇതാണ് നിന്റെ അവസാന നിസ്കാരം എന്ന പോലെ നിസ്കരിക്കുക.',
      en: 'Pray as though it is your farewell prayer. (Ibn Majah)',
      ar: 'إِذَا قُمْتَ فِي صَلَاتِكَ فَصَلِّ صَلَاةَ مُوَدِّعٍ (ابن ماجه)',
    ),
    (
      ml: 'ക്ഷമയും നിസ്കാരവും കൊണ്ട് സഹായം തേടുക.',
      en: 'Seek help through patience and prayer. (2:45)',
      ar: 'وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ (البقرة ٤٥)',
    ),
    (
      ml: 'അറിയുക, അല്ലാഹുവിനെ കുറിച്ചുള്ള സ്മരണ കൊണ്ടാണ് ഹൃദയങ്ങൾ ശാന്തമാകുന്നത്.',
      en: 'Verily, in the remembrance of Allah do hearts find rest. (13:28)',
      ar: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ (الرعد ٢٨)',
    ),
    (
      ml: 'ഫോൺ മാറ്റിവെക്കൂ. ഇപ്പോൾ നീയും നിന്റെ റബ്ബും മാത്രം.',
      en: 'Put the phone down. Right now it is only you and your Lord.',
      ar: 'ضع الهاتف جانبًا. الآن أنت وربك فقط.',
    ),
  ];
}
