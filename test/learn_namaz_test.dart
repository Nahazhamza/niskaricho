import 'package:flutter_test/flutter_test.dart';
import 'package:niskaricho/models/learn_namaz_model.dart';
import 'package:niskaricho/services/learn_namaz_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Learn Namaz - Fard Rak\'ah Counts & Structure', () {
    test('Obligatory Farḍ rak\'ahs strictly match Islamic law', () {
      final prayers = {for (final p in LearnNamazContent.prayers) p.id: p};

      expect(prayers['fajr']!.fardRakats, 2);
      expect(prayers['dhuhr']!.fardRakats, 4);
      expect(prayers['asr']!.fardRakats, 4);
      expect(prayers['maghrib']!.fardRakats, 3);
      expect(prayers['isha']!.fardRakats, 4);

      // Total daily Farḍ rak'ahs MUST be 17
      final totalDailyFard = prayers.values.map((p) => p.fardRakats).reduce((a, b) => a + b);
      expect(totalDailyFard, 17);
    });

    test('Farḍ and Sunnah are strictly separated in each prayer', () {
      for (final p in LearnNamazContent.prayers) {
        expect(p.fardRakats, greaterThan(0));
        // Sunnah is not mixed into fardRakats
        expect(p.fardRakats, isNot(p.totalWithSunnah));
        expect(p.structureSummary, contains('Farḍ'));
      }
    });

    test('Witr is clearly annotated for Isha', () {
      final isha = LearnNamazContent.prayers.firstWhere((p) => p.id == 'isha');
      expect(isha.witr, greaterThan(0));
      expect(isha.structureSummary, contains('Witr'));
    });

    test('Madhhab notes exist and distinguish Shafi\'i and Hanafi rulings', () {
      final fajr = LearnNamazContent.prayers.firstWhere((p) => p.id == 'fajr');
      expect(fajr.madhhabNotes[LearningMadhhab.shafi], contains('Qunut'));
      expect(fajr.madhhabNotes[LearningMadhhab.hanafi], contains('Qunut'));
    });
  });

  group('Learn Namaz - Wudu Guide Accuracy', () {
    test('Contains exactly 12 steps in correct sequence', () {
      final steps = LearnNamazContent.wuduSteps;
      expect(steps.length, 12);

      for (var i = 0; i < steps.length; i++) {
        expect(steps[i].stepNumber, i + 1);
      }

      // Step 1: Intention, Step 6: Face, Step 9: Head, Step 11/12: Feet
      expect(steps[0].title, contains('Intention'));
      expect(steps[5].title, contains('Face'));
      expect(steps[8].title, contains('Head'));
      expect(steps[10].title, contains('Right Foot'));
      expect(steps[11].title, contains('Left Foot'));
    });

    test('Distinguishes Quranic Farḍ actions from Sunnah actions', () {
      final steps = LearnNamazContent.wuduSteps;

      // Niyyah, Face, Right arm, Left arm, Head, Right foot, Left foot are Farḍ
      final fardSteps = steps.where((s) => s.isObligatory).toList();
      expect(fardSteps.length, 7);

      // Mouth & nose rinsing and ear wiping are Sunnah
      final mouth = steps.firstWhere((s) => s.stepNumber == 4);
      final nose = steps.firstWhere((s) => s.stepNumber == 5);
      final ears = steps.firstWhere((s) => s.stepNumber == 10);

      expect(mouth.isObligatory, isFalse);
      expect(nose.isObligatory, isFalse);
      expect(ears.isObligatory, isFalse);
    });

    test('Post-Wudu Dua cites authentic Hadith reference', () {
      final dua = LearnNamazContent.postWuduDua;
      expect(dua.arabicText, contains('أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ'));
      expect(dua.sourceReference, contains('Sahih Muslim'));
    });
  });

  group('Learn Namaz - Step-by-Step Salah Postures & Recitations', () {
    test('Covers all 13 core prayer positions', () {
      final steps = LearnNamazContent.salahSteps;
      expect(steps.length, 13);

      final positions = steps.map((s) => s.position).toSet();
      expect(positions, contains(SalahPosition.niyyah));
      expect(positions, contains(SalahPosition.takbir));
      expect(positions, contains(SalahPosition.qiyam));
      expect(positions, contains(SalahPosition.ruku));
      expect(positions, contains(SalahPosition.itidal));
      expect(positions, contains(SalahPosition.sujood1));
      expect(positions, contains(SalahPosition.jalsah));
      expect(positions, contains(SalahPosition.sujood2));
      expect(positions, contains(SalahPosition.tashahhudFinal));
      expect(positions, contains(SalahPosition.salawat));
      expect(positions, contains(SalahPosition.tasleem));
    });

    test('Recitations have non-empty Arabic, transliteration, and translation', () {
      for (final s in LearnNamazContent.salahSteps) {
        expect(s.arabicText.trim().isNotEmpty, isTrue);
        expect(s.transliteration.trim().isNotEmpty, isTrue);
        expect(s.translation.trim().isNotEmpty, isTrue);
        expect(s.sourceReference.trim().isNotEmpty, isTrue);
      }
    });
  });

  group('Learn Namaz - Recitation Library', () {
    test('Contains Surah Al-Fatiha, short Surahs, Tashahhud, and Durood', () {
      final ids = LearnNamazContent.recitations.map((r) => r.id).toSet();
      expect(ids, contains('rec_fatiha'));
      expect(ids, contains('rec_ikhlas'));
      expect(ids, contains('rec_falaq'));
      expect(ids, contains('rec_nas'));
      expect(ids, contains('rec_kawthar'));
      expect(ids, contains('rec_tashahhud'));
      expect(ids, contains('rec_durood'));
      expect(ids, contains('rec_qunut'));
      expect(ids, contains('rec_tasleem'));
    });

    test('Surah Al-Fatiha has all 7 verified verses in line-by-line breakdown', () {
      final fatiha = LearnNamazContent.recitations.firstWhere((r) => r.id == 'rec_fatiha');
      expect(fatiha.lines.length, 7);
      expect(fatiha.lines.first.arabic, contains('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'));
      expect(fatiha.lines.last.arabic, contains('وَلَا الضَّالِّينَ'));
    });
  });

  group('Learn Namaz - Beginner 7-Day Path', () {
    test('Has exactly 7 structured days leading up to complete prayer', () {
      final days = LearnNamazContent.beginnerDays;
      expect(days.length, 7);
      for (var i = 0; i < 7; i++) {
        expect(days[i].day, i + 1);
        expect(days[i].keyTakeaways.isNotEmpty, isTrue);
      }
    });
  });

  group('Learn Namaz - Progress & State Persistence', () {
    test('Progress serialization and deserialization preserves all fields', () {
      final p1 = const LearnProgress(
        completedWudu: true,
        completedPrayers: {'fajr', 'dhuhr'},
        masteredRecitations: {'rec_fatiha', 'rec_ikhlas'},
        beginnerDayCompleted: 3,
        xpEarned: 65,
        lastLearnedDate: '2026-11-21T12:00:00Z',
      );

      final json = p1.toJson();
      final p2 = LearnProgress.fromJson(json);

      expect(p2.completedWudu, isTrue);
      expect(p2.completedPrayers, containsAll(['fajr', 'dhuhr']));
      expect(p2.masteredRecitations, containsAll(['rec_fatiha', 'rec_ikhlas']));
      expect(p2.beginnerDayCompleted, 3);
      expect(p2.xpEarned, 65);
      expect(p2.lastLearnedDate, '2026-11-21T12:00:00Z');
    });

    test('Awarding XP updates progress immutably', () {
      final p1 = const LearnProgress(xpEarned: 10);
      final p2 = p1.copyWith(xpEarned: p1.xpEarned + 15, completedWudu: true);

      expect(p1.xpEarned, 10);
      expect(p1.completedWudu, isFalse);
      expect(p2.xpEarned, 25);
      expect(p2.completedWudu, isTrue);
    });
  });
}
