// Gamification models. All numbers come from the server (`get_my_progress`,
// `get_circle_leaderboard`, `get_circle_quest`), which derives them from
// prayer_logs. The client only displays them.

import 'dart:math' as math;

import 'prayer_model.dart';

/// Mirrors `_xp_for_log` in schema.sql. Used to show "+XP" right after a
/// prayer and by the demo backend; totals always come from the server.
int xpForLog(PrayerLog l) => switch (l.status) {
  PrayerStatus.onTime => (l.prayer == PrayerName.fajr ? 20 : 10) + (l.focusVerified ? 5 : 0) + (l.hasPhoto ? 5 : 0),
  PrayerStatus.qada => 4 + (l.hasPhoto ? 2 : 0),
  _ => 0,
};

const perfectDayBonus = 25;

int levelForXp(int xp) => math.sqrt(math.max(xp, 0) / 50).floor() + 1;
int xpForLevel(int level) => 50 * (level - 1) * (level - 1);

/// Level badges: clear progression tiers (inspired by Google Local Guides & milestone badges).
({String en, String ml, String emoji}) levelTitle(int level) => switch (level) {
  <= 1 => (en: 'Starter Tier', ml: 'സ്റ്റാർട്ടർ ടയർ', emoji: '🌱'),
  2 => (en: 'Bronze Badge', ml: 'ബ്രോൺസ് ബാഡ്ജ്', emoji: '🥉'),
  3 => (en: 'Silver Badge', ml: 'സിൽവർ ബാഡ്ജ്', emoji: '🥈'),
  4 => (en: 'Gold Badge', ml: 'ഗോൾഡ് ബാഡ്ജ്', emoji: '🥇'),
  5 => (en: 'Platinum Badge', ml: 'പ്ലാറ്റിനം ബാഡ്ജ്', emoji: '🛡️'),
  6 => (en: 'Sapphire Badge', ml: 'സഫയർ ബാഡ്ജ്', emoji: '🔷'),
  7 => (en: 'Emerald Badge', ml: 'എമറാൾഡ് ബാഡ്ജ്', emoji: '❇️'),
  8 => (en: 'Diamond Badge', ml: 'ഡയമണ്ട് ബാഡ്ജ്', emoji: '💎'),
  9 => (en: 'Master Tier', ml: 'മാസ്റ്റർ ടയർ', emoji: '👑'),
  _ => (en: 'Legend Tier', ml: 'ലെജൻഡ് ടയർ', emoji: '🌟'),
};

class DayHistory {
  const DayHistory({required this.date, required this.onTime, required this.qada, required this.missed});
  final DateTime date;
  final int onTime;
  final int qada;
  final int missed;

  factory DayHistory.fromJson(Map<String, dynamic> j) => DayHistory(
    date: DateTime.parse(j['date'] as String),
    onTime: (j['on_time'] as num).toInt(),
    qada: (j['qada'] as num).toInt(),
    missed: (j['missed'] as num).toInt(),
  );
}

class Progress {
  const Progress({
    required this.xp,
    required this.level,
    required this.weekXp,
    required this.streak,
    required this.badges,
    required this.history,
    required this.perPrayer,
  });

  final int xp;
  final int level;
  final int weekXp;
  final Streak streak;
  final Set<String> badges;
  final List<DayHistory> history; // oldest first, 35 days
  final Map<PrayerName, int> perPrayer; // on-time % over 30 days

  int get levelStartXp => xpForLevel(level);
  int get nextLevelXp => xpForLevel(level + 1);
  double get levelProgress => (xp - levelStartXp) / (nextLevelXp - levelStartXp);

  factory Progress.fromJson(Map<String, dynamic> j) => Progress(
    xp: (j['xp'] as num).toInt(),
    level: (j['level'] as num).toInt(),
    weekXp: (j['week_xp'] as num).toInt(),
    streak: j['streak'] == null ? const Streak() : Streak.fromJson(j['streak'] as Map<String, dynamic>),
    badges: {for (final b in (j['badges'] as List)) (b as Map)['code'] as String},
    history: [for (final h in (j['history'] as List)) DayHistory.fromJson(h as Map<String, dynamic>)],
    perPrayer: {
      for (final e in (j['per_prayer'] as Map<String, dynamic>).entries)
        PrayerName.fromDb(e.key): (e.value as num).toInt(),
    },
  );
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.weekXp,
    required this.level,
    required this.streakDays,
  });
  final String userId;
  final String displayName;
  final int weekXp;
  final int level;
  final int streakDays;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
    userId: j['user_id'] as String,
    displayName: j['display_name'] as String,
    weekXp: (j['week_xp'] as num).toInt(),
    level: (j['level'] as num).toInt(),
    streakDays: (j['streak_days'] as num).toInt(),
  );
}

class CircleQuest {
  const CircleQuest({required this.title, required this.goal, required this.progress, required this.endsAt});
  final String title;
  final int goal;
  final int progress;
  final DateTime endsAt;
  double get fraction => goal == 0 ? 0 : (progress / goal).clamp(0, 1).toDouble();

  factory CircleQuest.fromJson(Map<String, dynamic> j) => CircleQuest(
    title: j['title'] as String,
    goal: (j['goal'] as num).toInt(),
    progress: (j['progress'] as num).toInt(),
    endsAt: DateTime.parse(j['ends_at'] as String),
  );
}

/// Reactions allowed by the `reactions.emoji` check constraint.
const reactionEmojis = ['🤲', '❤️', '🔥', '🌟'];

/// Badge catalogue. Codes match what the server awards (`_award`).
class BadgeInfo {
  const BadgeInfo(this.code, this.emoji, this.name, this.ml, this.how);
  final String code;
  final String emoji;
  final String name;
  final String ml;
  final String how;
}

const badgeCatalogue = <BadgeInfo>[
  BadgeInfo('streak_3', '✨', 'First Spark', 'ആദ്യ തീപ്പൊരി', '3 days of 5/5 on time'),
  BadgeInfo('streak_7', '🔥', 'Week of Light', 'പ്രകാശവാരം', '7 days of 5/5 on time'),
  BadgeInfo('streak_30', '🌙', 'Moon Cycle', 'ഒരു ചന്ദ്രമാസം', '30 days of 5/5 on time'),
  BadgeInfo('streak_40', '🕋', 'Forty Days', 'നാൽപത് ദിവസം', '40 days of 5/5 on time'),
  BadgeInfo('streak_100', '💯', 'Hundred', 'നൂറ്', '100 days of 5/5 on time'),
  BadgeInfo('fajr_7', '🌅', 'Dawn Week', 'സുബ്ഹ് വാരം', 'Fajr on time 7 days in a row'),
  BadgeInfo('fajr_30', '☀️', 'Dawn Keeper', 'സുബ്ഹിന്റെ കാവൽ', 'Fajr on time 30 days in a row'),
  BadgeInfo('fajr_40', '🛡️', 'Fajr Guardian', 'ഫജ്ർ രക്ഷകൻ', 'Fajr on time 40 days in a row'),
  BadgeInfo('circle_fajr_7', '🤝', 'Full Circle Fajr', 'സർക്കിൾ സുബ്ഹ്', 'Whole circle prays Fajr on time for 7 days'),
  BadgeInfo(
    'circle_fajr_30',
    '🌍',
    'Unbreakable Circle',
    'തകരാത്ത സർക്കിൾ',
    'Whole circle prays Fajr on time for 30 days',
  ),
];
