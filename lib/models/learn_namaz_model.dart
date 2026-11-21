// Data models for Learn Namaz: Islamic prayer & Wudu educational module.

enum LearningMadhhab {
  shafi('Shafi\'i', 'ശാഫിഈ', 'شافعي'),
  hanafi('Hanafi', 'ഹനഫി', 'حنفي'),
  maliki('Maliki', 'മാലികി', 'مالكي'),
  hanbali('Hanbali', 'ഹൻബലി', 'حنبل');

  const LearningMadhhab(this.label, this.ml, this.ar);
  final String label;
  final String ml;
  final String ar;
}

enum RulingLevel {
  fard('Farḍ (Obligatory)', 'ഫർള് (നിർബന്ധം)', 'فرض'),
  wajib('Wajib (Necessary)', 'വാജിബ്', 'واجب'),
  sunnahMuakkadah('Emphasized Sunnah', 'സുന്നത്തുൽ മുഅക്കദ', 'سنة مؤكدة'),
  sunnah('Sunnah (Recommended)', 'സുന്നത്ത്', 'سنة'),
  mustahabb('Mustahabb (Desirable)', 'മുസ്തഹബ്ബ്', 'مستحب');

  const RulingLevel(this.label, this.ml, this.ar);
  final String label;
  final String ml;
  final String ar;
}

enum SalahPosition {
  niyyah('Niyyah & Standing', 'നിയ്യത്തും നിൽക്കലും', 'النية والقيام'),
  takbir('Takbiratul Ihram', 'തക്ബീറത്തുൽ ഇഹ്റാം', 'تكبيرة الإحرام'),
  qiyam('Qiyam (Standing & Recitation)', 'ഖിയാം (നിന്നുകൊണ്ടുള്ള പാരായണം)', 'القيام والقراءة'),
  ruku('Ruku (Bowing)', 'റുക്കൂഅ് (കുനിയൽ)', 'الركوع'),
  itidal('I\'tidal (Rising upright)', 'ഇഅ്തിദാൽ (നേരെ നിൽക്കൽ)', 'الاعتدال'),
  sujood1('First Sujood (Prostration)', 'ഒന്നാം സുജൂദ്', 'السجود الأول'),
  jalsah('Jalsah (Sitting between prostrations)', 'രണ്ട് സുജൂദുകൾക്കിടയിലെ ഇരുത്തം', 'الجلسة بين السجدتين'),
  sujood2('Second Sujood', 'രണ്ടാം സുജൂദ്', 'السجود الثاني'),
  tashahhudFirst('First Tashahhud', 'ആദ്യ അത്തഹിയ്യാത്ത്', 'التشهد الأول'),
  tashahhudFinal('Final Tashahhud', 'അവസാന അത്തഹിയ്യാത്ത്', 'التشهد الأخير'),
  salawat('Salawat upon the Prophet ﷺ', 'സ്വലാത്ത്', 'الصلاة على النبي ﷺ'),
  dua('Final Supplication', 'അവസാന ദുആ', 'الدعاء قبل السلام'),
  tasleem('Tasleem (Salutation of peace)', 'സലാം വീട്ടൽ', 'التسليم');

  const SalahPosition(this.label, this.ml, this.ar);
  final String label;
  final String ml;
  final String ar;
}

class SalahStep {
  const SalahStep({
    required this.id,
    required this.stepNumber,
    required this.title,
    required this.position,
    required this.ruling,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.explanation,
    required this.repetition,
    required this.sourceReference,
    this.madhhabNotes = const {},
    this.audioUrl,
  });

  final String id;
  final int stepNumber;
  final String title;
  final SalahPosition position;
  final RulingLevel ruling;
  final String arabicText;
  final String transliteration;
  final String translation;
  final String explanation;
  final int repetition;
  final String sourceReference;
  final Map<LearningMadhhab, String> madhhabNotes;
  final String? audioUrl;
}

class WuduStep {
  const WuduStep({
    required this.stepNumber,
    required this.title,
    required this.whatToDo,
    required this.howToDo,
    required this.isObligatory,
    this.arabicSupplication,
    this.transliteration,
    this.translation,
    this.sourceReference,
    this.commonMistakes = const [],
    this.shafiRuling = 'Farḍ',
    this.hanafiRuling = 'Farḍ',
  });

  final int stepNumber;
  final String title;
  final String whatToDo;
  final String howToDo;
  final bool isObligatory;
  final String? arabicSupplication;
  final String? transliteration;
  final String? translation;
  final String? sourceReference;
  final List<String> commonMistakes;
  final String shafiRuling;
  final String hanafiRuling;
}

class PrayerInfo {
  const PrayerInfo({
    required this.id,
    required this.name,
    required this.fardRakats,
    required this.sunnahBefore,
    required this.sunnahAfter,
    this.witr = 0,
    required this.description,
    required this.structureSummary,
    required this.rakahSummary,
    this.madhhabNotes = const {},
  });

  final String id;
  final String name;
  final int fardRakats;
  final int sunnahBefore;
  final int sunnahAfter;
  final int witr;
  final String description;
  final String structureSummary;
  final List<String> rakahSummary;
  final Map<LearningMadhhab, String> madhhabNotes;

  int get totalWithSunnah => fardRakats + sunnahBefore + sunnahAfter + witr;
}

class RecitationLine {
  const RecitationLine({
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });

  final String arabic;
  final String transliteration;
  final String translation;
}

class RecitationItem {
  const RecitationItem({
    required this.id,
    required this.title,
    required this.category,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.context,
    required this.sourceReference,
    this.repetition = 1,
    this.lines = const [],
    this.audioUrl,
  });

  final String id;
  final String title;
  final String category;
  final String arabicText;
  final String transliteration;
  final String translation;
  final String context;
  final int repetition;
  final String sourceReference;
  final List<RecitationLine> lines;
  final String? audioUrl;
}

class BeginnerDay {
  const BeginnerDay({
    required this.day,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.overview,
    required this.keyTakeaways,
    required this.practicalStep,
  });

  final int day;
  final String title;
  final String subtitle;
  final String icon;
  final String overview;
  final List<String> keyTakeaways;
  final String practicalStep;
}

class LearnProgress {
  const LearnProgress({
    this.completedWudu = false,
    this.completedPrayers = const {},
    this.masteredRecitations = const {},
    this.beginnerDayCompleted = 0,
    this.xpEarned = 0,
    this.lastLearnedDate,
  });

  final bool completedWudu;
  final Set<String> completedPrayers;
  final Set<String> masteredRecitations;
  final int beginnerDayCompleted;
  final int xpEarned;
  final String? lastLearnedDate;

  LearnProgress copyWith({
    bool? completedWudu,
    Set<String>? completedPrayers,
    Set<String>? masteredRecitations,
    int? beginnerDayCompleted,
    int? xpEarned,
    String? lastLearnedDate,
  }) => LearnProgress(
    completedWudu: completedWudu ?? this.completedWudu,
    completedPrayers: completedPrayers ?? this.completedPrayers,
    masteredRecitations: masteredRecitations ?? this.masteredRecitations,
    beginnerDayCompleted: beginnerDayCompleted ?? this.beginnerDayCompleted,
    xpEarned: xpEarned ?? this.xpEarned,
    lastLearnedDate: lastLearnedDate ?? this.lastLearnedDate,
  );

  Map<String, dynamic> toJson() => {
    'completedWudu': completedWudu,
    'completedPrayers': completedPrayers.toList(),
    'masteredRecitations': masteredRecitations.toList(),
    'beginnerDayCompleted': beginnerDayCompleted,
    'xpEarned': xpEarned,
    'lastLearnedDate': lastLearnedDate,
  };

  factory LearnProgress.fromJson(Map<String, dynamic> j) => LearnProgress(
    completedWudu: j['completedWudu'] as bool? ?? false,
    completedPrayers: Set<String>.from((j['completedPrayers'] as List?) ?? const []),
    masteredRecitations: Set<String>.from((j['masteredRecitations'] as List?) ?? const []),
    beginnerDayCompleted: (j['beginnerDayCompleted'] as num?)?.toInt() ?? 0,
    xpEarned: (j['xpEarned'] as num?)?.toInt() ?? 0,
    lastLearnedDate: j['lastLearnedDate'] as String?,
  );
}
