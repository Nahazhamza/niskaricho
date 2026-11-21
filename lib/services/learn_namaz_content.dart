// Verified Islamic learning content for Niskaricho's Learn Namaz module.
// Sources: Quran, Sahih al-Bukhari, Sahih Muslim, Sunan at-Tirmidhi, and standard
// jurisprudential references for Shafi'i and Hanafi schools.

import '../models/learn_namaz_model.dart';

class LearnNamazContent {
  // ---------------------------------------------------------------------------
  // WUDU (ABLUTION) CONTENT
  // ---------------------------------------------------------------------------
  static const wuduIntro = '''
Wudu (ablution) is the ritual purification performed by Muslims before Salah (prayer). 
Allah says in the Holy Quran:
"O you who have believed, when you rise to [perform] prayer, wash your faces and your forearms to the elbows and wipe over your heads and wash your feet to the ankles." (Surah Al-Ma'idah 5:6)

The Prophet Muhammad ﷺ said:
"Prayer is not accepted without purification." (Sahih Muslim 224)
''';

  static const wuduInvalidators = [
    'Discharge of urine, stool, or gas from the private parts (Bukhari 135).',
    'Deep sleep where awareness of one\'s surroundings is lost (Abu Dawud 203).',
    'Loss of consciousness through fainting, intoxication, or medication.',
    'Direct skin-to-skin touch with non-Mahram of opposite sex without a barrier (Shafi\'i: invalidates; Hanafi: does not invalidate unless accompanied by sexual arousal).',
    'Bleeding profusely or vomiting a mouthful (Hanafi: invalidates; Shafi\'i: does not invalidate wudu).',
    'Direct touching of the private parts with the palm/inner fingers without a barrier (Bukhari/Tirmidhi 82; Shafi\'i/Hanbali invalidate, Hanafi does not).',
  ];

  static const wuduConditions = [
    'Clean, pure water (Tahoor).',
    'Removing any waterproof barrier (nail polish, wax, oil paint) from the skin/nails.',
    'Making the intention (Niyyah) in the heart before washing.',
  ];

  static const List<WuduStep> wuduSteps = [
    WuduStep(
      stepNumber: 1,
      title: 'Make the Intention (Niyyah)',
      whatToDo: 'Form the sincere intention in your heart to perform Wudu for the sake of Allah.',
      howToDo:
          'Intention resides in the heart. You do not need to say it aloud, though some scholars recommend whispering it to assist focus. Intend: "I intend to perform Wudu for purification to establish prayer for Allah."',
      isObligatory: true,
      arabicSupplication: 'نَوَيْتُ الْوُضُوءَ لِرَفْعِ الْحَدَثِ لِلَّهِ تَعَالَى',
      transliteration: "Nawaytul-wudu'a li-raf'il-hadathi lillahi ta'ala",
      translation: 'I intend ablution to remove ritual impurity for the sake of Allah the Almighty.',
      sourceReference: 'Sahih al-Bukhari 1: "Actions are judged by intentions."',
      shafiRuling: 'Farḍ (Obligatory at the start of washing face)',
      hanafiRuling: 'Sunnah Muakkadah (Obligatory for reward)',
      commonMistakes: [
        'Believing intention must be spoken loudly.',
        'Doubting intention after starting.',
      ],
    ),
    WuduStep(
      stepNumber: 2,
      title: 'Say Bismillah',
      whatToDo: 'Begin in the Name of Allah.',
      howToDo:
          'Say "Bismillah" (In the Name of Allah) before water touches your limbs. If in a bathroom with a toilet, say it quietly in your mind or just before stepping inside.',
      isObligatory: false,
      arabicSupplication: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      transliteration: 'Bismillahir-Rahmanir-Raheem',
      translation: 'In the Name of Allah, the Entirely Merciful, the Especially Merciful.',
      sourceReference: 'Sunan Ibn Majah 397; Abu Dawud 101',
      shafiRuling: 'Sunnah',
      hanafiRuling: 'Sunnah',
      commonMistakes: [
        'Saying sacred supplications out loud inside the toilet area.',
      ],
    ),
    WuduStep(
      stepNumber: 3,
      title: 'Wash Both Hands Up to the Wrists',
      whatToDo: 'Wash both hands up to the wrists three times, rubbing between the fingers.',
      howToDo:
          'Start with the right hand, then the left hand. Interlace the fingers (Takhlil) to ensure water reaches between every finger and under rings.',
      isObligatory: false,
      sourceReference: 'Sahih al-Bukhari 159, Sahih Muslim 226',
      shafiRuling: 'Sunnah',
      hanafiRuling: 'Sunnah',
      commonMistakes: [
        'Only washing the palms and missing the wrists.',
        'Not moving loose rings to let water underneath.',
      ],
    ),
    WuduStep(
      stepNumber: 4,
      title: 'Rinse the Mouth (Madmadah)',
      whatToDo: 'Rinse your mouth with water three times.',
      howToDo:
          'Take a handful of water with the right hand, bring it into the mouth, swirl it around to cleanse teeth and gums, then spit it out. Repeat 3 times.',
      isObligatory: false,
      sourceReference: 'Sahih al-Bukhari 191, Sahih Muslim 226',
      shafiRuling: 'Sunnah',
      hanafiRuling: 'Sunnah (Farḍ in Ghusl)',
      commonMistakes: [
        'Swallowing the water or barely letting water touch the mouth.',
      ],
    ),
    WuduStep(
      stepNumber: 5,
      title: 'Clean the Nose (Istinshaq & Istinthar)',
      whatToDo: 'Sniff water into the nostrils and blow it out gently three times.',
      howToDo:
          'Cup water in the right hand and sniff gently into the nostrils, then blow it out using the left hand to clean the nose. Repeat 3 times.',
      isObligatory: false,
      sourceReference: 'Sahih al-Bukhari 161, Sahih Muslim 237',
      shafiRuling: 'Sunnah',
      hanafiRuling: 'Sunnah (Farḍ in Ghusl)',
      commonMistakes: [
        'Sniffing water too violently causing choking.',
        'Skipping this step when water feels cold.',
      ],
    ),
    WuduStep(
      stepNumber: 6,
      title: 'Wash the Entire Face',
      whatToDo: 'Wash the entire face three times, from hairline to chin and ear to ear.',
      howToDo:
          'Take water with both hands and wash from the normal hairline at the top of the forehead down to the bottom of the chin, and from tragus of the right ear to the tragus of the left ear. Run wet fingers through a thick beard.',
      isObligatory: true,
      sourceReference: 'Quran 5:6; Sahih al-Bukhari 140',
      shafiRuling: 'Farḍ (Obligatory)',
      hanafiRuling: 'Farḍ (Obligatory)',
      commonMistakes: [
        'Missing the area between the sideburns and ears.',
        'Not washing under the lower lip and chin.',
      ],
    ),
    WuduStep(
      stepNumber: 7,
      title: 'Wash Right Arm Up to & Including Elbow',
      whatToDo: 'Wash the right arm thoroughly from fingertips up to and including the elbow 3 times.',
      howToDo:
          'Pour water starting from the hand and wash up past the elbow joint. Rub the forearm to ensure every hair and pore is wet. The elbow MUST be completely covered.',
      isObligatory: true,
      sourceReference: 'Quran 5:6; Sahih Muslim 246',
      shafiRuling: 'Farḍ (Obligatory)',
      hanafiRuling: 'Farḍ (Obligatory)',
      commonMistakes: [
        'Forgetting to re-wash the hand (assuming hand washing at step 3 was enough).',
        'Missing the back tip of the elbow.',
      ],
    ),
    WuduStep(
      stepNumber: 8,
      title: 'Wash Left Arm Up to & Including Elbow',
      whatToDo: 'Wash the left arm thoroughly from fingertips up to and including the elbow 3 times.',
      howToDo:
          'Repeat the exact same procedure for the left arm. Wash up past the elbow and rub thoroughly.',
      isObligatory: true,
      sourceReference: 'Quran 5:6; Sahih Muslim 246',
      shafiRuling: 'Farḍ (Obligatory)',
      hanafiRuling: 'Farḍ (Obligatory)',
      commonMistakes: [
        'Rushing the left arm and leaving the elbow dry.',
      ],
    ),
    WuduStep(
      stepNumber: 9,
      title: 'Wipe the Head (Mash)',
      whatToDo: 'Wipe over the head with wet hands once.',
      howToDo:
          'Wet your hands and shake off excess drops. Pass both hands from the front hairline over the head to the nape of the neck, and optionally bring them back to the front. (Shafi\'i: wiping any portion of the head or hair within its boundary satisfies the Farḍ; Hanafi: at least 1/4th of the head).',
      isObligatory: true,
      sourceReference: 'Quran 5:6; Sahih al-Bukhari 185',
      shafiRuling: 'Farḍ (Any part of head/hair)',
      hanafiRuling: 'Farḍ (At least quarter of head)',
      commonMistakes: [
        'Pouring water over the head instead of wiping.',
        'Wiping hair that falls below the boundary of the head.',
      ],
    ),
    WuduStep(
      stepNumber: 10,
      title: 'Wipe Both Ears',
      whatToDo: 'Wipe the interior and exterior of both ears once.',
      howToDo:
          'Insert the index fingers into the ear canals and wipe the crevices of the ear, while using the thumbs to wipe the back of the ears, using the moisture from wiping the head or fresh water.',
      isObligatory: false,
      sourceReference: 'Sunan Abu Dawud 135; Tirmidhi 36 (Hasan Sahih)',
      shafiRuling: 'Sunnah (Recommended with fresh water)',
      hanafiRuling: 'Sunnah (Done with remaining moisture from head)',
      commonMistakes: [
        'Pushing fingers too deep into the ear canal.',
        'Skipping the backs of the ears.',
      ],
    ),
    WuduStep(
      stepNumber: 11,
      title: 'Wash Right Foot Including Ankle',
      whatToDo: 'Wash the right foot completely up to and including the ankle bone 3 times.',
      howToDo:
          'Wash with the left hand, beginning at the toes and washing between them (Takhlil) using the little finger of the left hand, completely surrounding the heel and both protruding ankle bones (Ka\'bayn).',
      isObligatory: true,
      sourceReference: 'Quran 5:6; Sahih al-Bukhari 163',
      shafiRuling: 'Farḍ (Obligatory)',
      hanafiRuling: 'Farḍ (Obligatory)',
      commonMistakes: [
        'Leaving the back of the heel dry (Prophet ﷺ warned: "Woe to the heels from the Fire!" - Bukhari 165).',
        'Not washing between tightly spaced toes.',
      ],
    ),
    WuduStep(
      stepNumber: 12,
      title: 'Wash Left Foot Including Ankle',
      whatToDo: 'Wash the left foot completely up to and including the ankle bone 3 times.',
      howToDo:
          'Wash thoroughly just like the right foot, making sure the entire heel, ankle bones, and crevices between toes are wet.',
      isObligatory: true,
      sourceReference: 'Quran 5:6; Sahih al-Bukhari 163',
      shafiRuling: 'Farḍ (Obligatory)',
      hanafiRuling: 'Farḍ (Obligatory)',
      commonMistakes: [
        'Missing the dry spots on the Achilles tendon or heel.',
      ],
    ),
  ];

  static const postWuduDua = RecitationItem(
    id: 'post_wudu_dua',
    title: 'Supplication After Completing Wudu',
    category: 'Wudu',
    arabicText:
        'أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ. اللَّهُمَّ اجْعَلْنِي مِنَ التَّوَّابِينَ وَاجْعَلْنِي مِنَ الْمُتَطَهِّرِينَ.',
    transliteration:
        "Ash-hadu alla ilaha illallahu wahdahu la sharika lahu, wa ash-hadu anna Muhammadan 'abduhu wa rasuluh. Allahumma-j'alni minat-tawwabina waj'alni minal-mutatahhirin.",
    translation:
        'I bear witness that there is no deity worthy of worship except Allah alone, without partner, and I bear witness that Muhammad is His servant and His Messenger. O Allah, make me among those who repent constantly and make me among those who purify themselves.',
    context:
        'Recited immediately upon completing Wudu while facing the Qibla. The Prophet ﷺ said: "Whoever performs Wudu thoroughly then recites this, all eight gates of Paradise are opened for him to enter from whichever he wishes." (Sahih Muslim 234; At-Tirmidhi 55)',
    sourceReference: 'Sahih Muslim 234 & Jami` at-Tirmidhi 55',
  );

  // ---------------------------------------------------------------------------
  // FIVE DAILY SALAH RAK'AH BREAKDOWN
  // ---------------------------------------------------------------------------
  static const List<PrayerInfo> prayers = [
    PrayerInfo(
      id: 'fajr',
      name: 'Fajr',
      fardRakats: 2,
      sunnahBefore: 2,
      sunnahAfter: 0,
      witr: 0,
      description: 'The Dawn Prayer performed between the break of true dawn and sunrise.',
      structureSummary: '2 Sunnah (Emphasized) → 2 Farḍ (Recited aloud by Imam/alone)',
      rakahSummary: [
        'Rak\'ah 1: Takbir, Fatiha + Surah aloud, Ruku, Sujood x2',
        'Rak\'ah 2: Fatiha + Surah aloud, Ruku, Sujood x2, Tashahhud & Durood, Tasleem',
      ],
      madhhabNotes: {
        LearningMadhhab.shafi:
            'Qunut supplication is an emphasized Sunnah (Ab\'ad) recited standing after rising from Ruku in the 2nd Rak\'ah.',
        LearningMadhhab.hanafi:
            'Qunut is not recited in Fajr (reserved for Witr in Hanafi). The 2 Sunnah before Fajr are the most emphasized of all Sunnahs.',
      },
    ),
    PrayerInfo(
      id: 'dhuhr',
      name: 'Dhuhr',
      fardRakats: 4,
      sunnahBefore: 4,
      sunnahAfter: 2,
      description: 'The Noon Prayer performed after the sun passes its zenith (Zawal).',
      structureSummary: '4 (or 2) Sunnah Before → 4 Farḍ (Recited silently) → 2 Sunnah After',
      rakahSummary: [
        'Rak\'ah 1: Fatiha + Surah (silent), Ruku, Sujood x2',
        'Rak\'ah 2: Fatiha + Surah (silent), Ruku, Sujood x2, First Tashahhud (sitting)',
        'Rak\'ah 3: Stand up, Fatiha only (silent), Ruku, Sujood x2',
        'Rak\'ah 4: Fatiha only (silent), Ruku, Sujood x2, Final Tashahhud, Durood & Tasleem',
      ],
      madhhabNotes: {
        LearningMadhhab.shafi: 'Sunnah before Dhuhr can be prayed as 2 or 4 rak\'ahs.',
        LearningMadhhab.hanafi: '4 rak\'ahs before Dhuhr are Sunnah Muakkadah prayed with one Tasleem.',
      },
    ),
    PrayerInfo(
      id: 'asr',
      name: 'Asr',
      fardRakats: 4,
      sunnahBefore: 4,
      sunnahAfter: 0,
      witr: 0,
      description: 'The Afternoon Prayer performed when shadow length reaches its specific madhhab measure.',
      structureSummary: '4 (or 2) Optional Sunnah Before → 4 Farḍ (Recited silently) → No prayer after',
      rakahSummary: [
        'Rak\'ah 1: Fatiha + Surah (silent), Ruku, Sujood x2',
        'Rak\'ah 2: Fatiha + Surah (silent), Ruku, Sujood x2, First Tashahhud (sitting)',
        'Rak\'ah 3: Stand up, Fatiha only (silent), Ruku, Sujood x2',
        'Rak\'ah 4: Fatiha only (silent), Ruku, Sujood x2, Final Tashahhud, Durood & Tasleem',
      ],
      madhhabNotes: {
        LearningMadhhab.shafi: 'Asr start time is when shadow equals object length + noon shadow.',
        LearningMadhhab.hanafi: 'Majority Hanafi time is when shadow equals twice the object length.',
      },
    ),
    PrayerInfo(
      id: 'maghrib',
      name: 'Maghrib',
      fardRakats: 3,
      sunnahBefore: 0,
      sunnahAfter: 2,
      witr: 0,
      description: 'The Sunset Prayer performed immediately after the sun has completely set.',
      structureSummary: '3 Farḍ (First 2 aloud, 3rd silent) → 2 Sunnah After',
      rakahSummary: [
        'Rak\'ah 1: Fatiha + Surah aloud, Ruku, Sujood x2',
        'Rak\'ah 2: Fatiha + Surah aloud, Ruku, Sujood x2, First Tashahhud (sitting)',
        'Rak\'ah 3: Stand up, Fatiha only (silent), Ruku, Sujood x2, Final Tashahhud, Durood & Tasleem',
      ],
      madhhabNotes: {
        LearningMadhhab.shafi: '2 light Sunnah before Maghrib are recommended if time permits.',
        LearningMadhhab.hanafi: 'Directly begin Farḍ after Adhan, then pray 2 Sunnah Muakkadah after.',
      },
    ),
    PrayerInfo(
      id: 'isha',
      name: 'Isha',
      fardRakats: 4,
      sunnahBefore: 0,
      sunnahAfter: 2,
      witr: 3,
      description: 'The Night Prayer performed after the red twilight has vanished from the western sky.',
      structureSummary: '4 Farḍ (First 2 aloud, last 2 silent) → 2 Sunnah After → 1 to 3 Witr',
      rakahSummary: [
        'Rak\'ah 1: Fatiha + Surah aloud, Ruku, Sujood x2',
        'Rak\'ah 2: Fatiha + Surah aloud, Ruku, Sujood x2, First Tashahhud (sitting)',
        'Rak\'ah 3: Stand up, Fatiha only (silent), Ruku, Sujood x2',
        'Rak\'ah 4: Fatiha only (silent), Ruku, Sujood x2, Final Tashahhud, Durood & Tasleem',
        'Followed by: 2 Sunnah Muakkadah + Witr prayer',
      ],
      madhhabNotes: {
        LearningMadhhab.shafi: 'Witr can be 1, 3, or up to 11 rak\'ahs. 3 rak\'ahs prayed as 2 + 1 with separate Tasleem.',
        LearningMadhhab.hanafi: 'Witr is Wajib (strongly obligatory), prayed as 3 continuous rak\'ahs with Qunut before Ruku in 3rd.',
      },
    ),
  ];

  // ---------------------------------------------------------------------------
  // STEP-BY-STEP SALAH MOVEMENTS & RECITATIONS (13 STEPS)
  // ---------------------------------------------------------------------------
  static const List<SalahStep> salahSteps = [
    SalahStep(
      id: 'salah_1_niyyah',
      stepNumber: 1,
      title: 'Niyyah & Standing (Qiyam)',
      position: SalahPosition.niyyah,
      ruling: RulingLevel.fard,
      arabicText: 'نَوَيْتُ أَنْ أُصَلِّيَ فَرْضَ الصُّبْحِ رَكْعَتَيْنِ لِلَّهِ تَعَالَى',
      transliteration: "Nawaytu an usalliya fardas-subhi rak'atayni lillahi ta'ala",
      translation: 'I intend to pray the two Farḍ rak\'ahs of Fajr for Allah the Almighty.',
      explanation:
          'Stand upright facing the Qibla (Kaaba). Keep your feet straight and shoulder-width apart without crossing or spreading excessively. Sincere intention is made in your heart at the exact moment you begin the prayer.',
      repetition: 1,
      sourceReference: 'Sahih al-Bukhari 1; Sahih Muslim 1907',
      madhhabNotes: {
        LearningMadhhab.shafi: 'Intention must coincide with the Takbiratul Ihram.',
        LearningMadhhab.hanafi: 'Intention just before the Takbir is valid.',
      },
    ),
    SalahStep(
      id: 'salah_2_takbir',
      stepNumber: 2,
      title: 'Takbiratul Ihram',
      position: SalahPosition.takbir,
      ruling: RulingLevel.fard,
      arabicText: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allahu Akbar',
      translation: 'Allah is the Greatest.',
      explanation:
          'Raise both hands with palms facing forward towards the Qibla and fingers naturally open. Say "Allahu Akbar". This marks the formal entry into the sacred state of Salah, during which worldly talk and actions become forbidden (Haram).',
      repetition: 1,
      sourceReference: 'Sahih al-Bukhari 735, Sahih Muslim 390',
      madhhabNotes: {
        LearningMadhhab.shafi: 'Raise hands so thumbs level with earlobes, fingertips level with upper ear.',
        LearningMadhhab.hanafi: 'Men touch earlobes with thumbs; women raise hands to shoulder height.',
      },
    ),
    SalahStep(
      id: 'salah_3_qiyam',
      stepNumber: 3,
      title: 'Qiyam: Hand Placement & Surah Al-Fatiha',
      position: SalahPosition.qiyam,
      ruling: RulingLevel.fard,
      arabicText:
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۝ الرَّحْمَٰنِ الرَّحِيمِ ۝ مَالِكِ يَوْمِ الدِّينِ ۝ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۝ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ ۝ صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ ۝',
      transliteration:
          "Bismillahir-Rahmanir-Raheem. Al-hamdu lillahi Rabbil-'alamin. Ar-Rahmanir-Raheem. Maliki Yawmid-Deen. Iyyaka na'budu wa iyyaka nasta'een. Ihdinas-siratal-mustaqeem. Siratalladhina an'amta 'alayhim, ghayril-maghdubi 'alayhim wa lad-dallin.",
      translation:
          'In the Name of Allah, the Entirely Merciful, the Especially Merciful. All praise is due to Allah, Lord of the worlds. The Entirely Merciful, the Especially Merciful. Sovereign of the Day of Recompense. It is You we worship and You we ask for help. Guide us to the straight path. The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray.',
      explanation:
          'Fold your hands over the chest/torso (right hand over left wrist). Look towards the spot of prostration. First recite the opening supplication (Dua al-Istiftah), then seek refuge in Allah (Ta\'awwudh), then recite Surah Al-Fatiha carefully. In the first two rak\'ahs, also recite another Surah (e.g. Surah Al-Ikhlas).',
      repetition: 1,
      sourceReference: 'Sahih al-Bukhari 756: "There is no prayer for whoever does not recite the Opening of the Book."',
      madhhabNotes: {
        LearningMadhhab.shafi: 'Place hands between navel and chest, slightly to the left. Basmalah is an obligatory verse of Fatiha.',
        LearningMadhhab.hanafi: 'Men clasp right hand over left wrist below the navel; women place hands on chest.',
      },
    ),
    SalahStep(
      id: 'salah_4_ruku',
      stepNumber: 4,
      title: 'Ruku (Bowing)',
      position: SalahPosition.ruku,
      ruling: RulingLevel.fard,
      arabicText: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
      transliteration: "Subhana Rabbiyal-'Adheem",
      translation: 'Glory be to my Lord, the Magnificent.',
      explanation:
          'Say "Allahu Akbar" while bowing down into Ruku. Grasp your knees firmly with fingers spread wide. Keep your back straight and horizontal like a table, head in line with the back (not hanging or raised high). Repeat the glorification at least 3 times calmly.',
      repetition: 3,
      sourceReference: 'Sahih Muslim 772, Sunan Abi Dawud 869',
      madhhabNotes: {
        LearningMadhhab.shafi: 'Say "Subhana Rabbiyal Adheemi wa bihamdih" 3 times.',
        LearningMadhhab.hanafi: 'Say "Subhana Rabbiyal Adheem" at least 3 times.',
      },
    ),
    SalahStep(
      id: 'salah_5_itidal',
      stepNumber: 5,
      title: 'I\'tidal (Rising from Ruku)',
      position: SalahPosition.itidal,
      ruling: RulingLevel.fard,
      arabicText: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ ۝ رَبَّنَا وَلَكَ الْحَمْدُ',
      transliteration: "Sami' Allahu liman hamidah. Rabbana wa lakal-hamd.",
      translation: 'Allah listens to whoever praises Him. Our Lord, and to You belongs all praise.',
      explanation:
          'Rise upright until your back is completely straight. While rising, say "Sami\' Allahu liman hamidah". Once standing erect and still (Tuma\'ninah), say "Rabbana wa lakal-hamd" (or "Rabbana lakal-hamd"). Standing calmly is an obligatory pillar.',
      repetition: 1,
      sourceReference: 'Sahih al-Bukhari 789, Sahih Muslim 404',
      madhhabNotes: {
        LearningMadhhab.shafi: 'Raise hands to shoulder/ear level when rising. In Fajr 2nd rak\'ah, recite Qunut here.',
        LearningMadhhab.hanafi: 'Imam says "Sami Allahu...", follower says "Rabbana lakal hamd", individual says both.',
      },
    ),
    SalahStep(
      id: 'salah_6_sujood1',
      stepNumber: 6,
      title: 'First Sujood (Prostration)',
      position: SalahPosition.sujood1,
      ruling: RulingLevel.fard,
      arabicText: 'سُبْحَانَ رَبِّيَ الْأَعْلَىٰ',
      transliteration: "Subhana Rabbiyal-A'la",
      translation: 'Glory be to my Lord, the Most High.',
      explanation:
          'Say "Allahu Akbar" and descend into prostration. Seven body parts MUST firmly touch the floor: (1) forehead and nose together, (2 & 3) both palms flat on the ground beside the shoulders/ears, (4 & 5) both knees, and (6 & 7) the tips of the toes of both feet bent pointing towards the Qibla. Keep elbows elevated away from the ground.',
      repetition: 3,
      sourceReference: 'Sahih al-Bukhari 812: "I have been commanded to prostrate on seven bones."',
      madhhabNotes: {
        LearningMadhhab.shafi: 'Forehead must touch uncovered without barrier. Add "wa bihamdih".',
        LearningMadhhab.hanafi: 'Both knees descend first, then hands, then face.',
      },
    ),
    SalahStep(
      id: 'salah_7_jalsah',
      stepNumber: 7,
      title: 'Jalsah (Sitting Between Sujoods)',
      position: SalahPosition.jalsah,
      ruling: RulingLevel.fard,
      arabicText: 'رَبِّ اغْفِرْ لِي، رَبِّ اغْفِرْ لِي',
      transliteration: 'Rabbighfir li, Rabbighfir li',
      translation: 'O my Lord, forgive me. O my Lord, forgive me.',
      explanation:
          'Say "Allahu Akbar" and rise from prostration into an upright sitting position. Sit on your left foot laid flat, with your right foot upright and toes pointing towards the Qibla (Iftirash posture). Rest both hands flat on your thighs near the knees. Wait until every bone settles peacefully before moving.',
      repetition: 2,
      sourceReference: 'Sunan Abi Dawud 874, Sunan Ibn Majah 897',
      madhhabNotes: {
        LearningMadhhab.shafi:
            'Recite the full Sunnah dua: "Rabbighfir li warhamni wajburni warfa\'ni warzuqni wahdini wa\'afini".',
        LearningMadhhab.hanafi: 'Say "Rabbighfir li" or sit silently with calm tranquility (Tuma\'ninah).',
      },
    ),
    SalahStep(
      id: 'salah_8_sujood2',
      stepNumber: 8,
      title: 'Second Sujood (Second Prostration)',
      position: SalahPosition.sujood2,
      ruling: RulingLevel.fard,
      arabicText: 'سُبْحَانَ رَبِّيَ الْأَعْلَىٰ',
      transliteration: "Subhana Rabbiyal-A'la",
      translation: 'Glory be to my Lord, the Most High.',
      explanation:
          'Say "Allahu Akbar" and go down for the second prostration exactly like the first. Ensure all seven limbs firmly contact the ground. Recite the glorification at least 3 times. This completes one full Rak\'ah!',
      repetition: 3,
      sourceReference: 'Sahih al-Bukhari 812, Sahih Muslim 493',
      madhhabNotes: {
        LearningMadhhab.shafi: 'After the 2nd prostration, briefly sit in Jalsat al-Istirahah before rising.',
        LearningMadhhab.hanafi: 'Rise directly from prostration to standing without sitting.',
      },
    ),
    SalahStep(
      id: 'salah_9_tashahhud_first',
      stepNumber: 9,
      title: 'First Tashahhud (In 3 & 4 Rak\'ah Prayers)',
      position: SalahPosition.tashahhudFirst,
      ruling: RulingLevel.wajib,
      arabicText:
          'التَّحِيَّاتُ الْمُبَارَكَاتُ الصَّلَوَاتُ الطَّيِّبَاتُ لِلَّهِ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَىٰ عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ.',
      transliteration:
          "At-tahiyyatu al-mubarakatus-salawatu at-tayyibatu lillah. As-salamu 'alayka ayyuhan-Nabiyyu wa rahmatullahi wa barakatuh. As-salamu 'alayna wa 'ala 'ibadillahis-salihin. Ash-hadu alla ilaha illallahu wa ash-hadu anna Muhammadan rasulullah.",
      translation:
          'All blessed greetings, prayers and good deeds belong to Allah. Peace be upon you, O Prophet, and the mercy of Allah and His blessings. Peace be upon us and upon the righteous servants of Allah. I bear witness that there is no deity worthy of worship except Allah, and I bear witness that Muhammad is the Messenger of Allah.',
      explanation:
          'At the end of the 2nd Rak\'ah in Dhuhr, Asr, Maghrib, and Isha, sit in the Iftirash position. Place your left hand open on your left knee and make a light fist with the right hand. When you say "Illallahu", raise the right index finger pointing forward as a testimony of Tawhid (Divine Oneness).',
      repetition: 1,
      sourceReference: 'Sahih Muslim 403 (Ibn Abbas narration), Sahih al-Bukhari 831 (Ibn Mas\'ud narration)',
      madhhabNotes: {
        LearningMadhhab.shafi: 'Recites the Ibn Abbas wording (above). Finger raised at "illallah" and kept steady.',
        LearningMadhhab.hanafi: 'Recites Ibn Mas\'ud wording: "At-tahiyyatu lillahi was-salawatu wat-tayyibat..." Raised at "La ilaha", lowered at "illallah".',
      },
    ),
    SalahStep(
      id: 'salah_10_tashahhud_final',
      stepNumber: 10,
      title: 'Final Tashahhud',
      position: SalahPosition.tashahhudFinal,
      ruling: RulingLevel.fard,
      arabicText:
          'التَّحِيَّاتُ الْمُبَارَكَاتُ الصَّلَوَاتُ الطَّيِّبَاتُ لِلَّهِ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَىٰ عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ.',
      transliteration:
          "At-tahiyyatu al-mubarakatus-salawatu at-tayyibatu lillah. As-salamu 'alayka ayyuhan-Nabiyyu wa rahmatullahi wa barakatuh. As-salamu 'alayna wa 'ala 'ibadillahis-salihin. Ash-hadu alla ilaha illallahu wa ash-hadu anna Muhammadan rasulullah.",
      translation:
          'All blessed greetings, prayers and good deeds belong to Allah. Peace be upon you, O Prophet, and the mercy of Allah and His blessings. Peace be upon us and upon the righteous servants of Allah. I bear witness that there is no deity worthy of worship except Allah, and I bear witness that Muhammad is the Messenger of Allah.',
      explanation:
          'Recited in the final sitting of every prayer (Rak\'ah 2 in Fajr, Rak\'ah 3 in Maghrib, Rak\'ah 4 in Dhuhr/Asr/Isha). In Shafi\'i, sit in Tawarruk posture (left foot passes under the right leg, resting bottom on the floor).',
      repetition: 1,
      sourceReference: 'Sahih al-Bukhari 828, Sahih Muslim 403',
      madhhabNotes: {
        LearningMadhhab.shafi: 'Sit in Tawarruk posture in the final sitting.',
        LearningMadhhab.hanafi: 'Men remain in Iftirash posture (sitting on left foot); women sit in Tawarruk.',
      },
    ),
    SalahStep(
      id: 'salah_11_salawat',
      stepNumber: 11,
      title: 'Salawat / Durood Ibrahim',
      position: SalahPosition.salawat,
      ruling: RulingLevel.fard,
      arabicText:
          'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ. اللَّهُمَّ بَارِكْ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ.',
      transliteration:
          "Allahumma salli 'ala Muhammadin wa 'ala ali Muhammad, kama sallayta 'ala Ibrahima wa 'ala ali Ibrahim, innaka Hamidun Majid. Allahumma barik 'ala Muhammadin wa 'ala ali Muhammad, kama barakta 'ala Ibrahima wa 'ala ali Ibrahim, innaka Hamidun Majid.",
      translation:
          'O Allah, send blessings upon Muhammad and upon the family of Muhammad, as You sent blessings upon Ibrahim and upon the family of Ibrahim; indeed, You are Praiseworthy, Majestic. O Allah, bless Muhammad and the family of Muhammad, as You blessed Ibrahim and the family of Ibrahim; indeed, You are Praiseworthy, Majestic.',
      explanation:
          'Sending peace and blessings upon the Prophet Muhammad ﷺ and his noble household immediately following Tashahhud. It is an obligatory pillar in the final sitting of Salah according to the Shafi\'i and Hanbali schools.',
      repetition: 1,
      sourceReference: 'Sahih al-Bukhari 3370, Sahih Muslim 406',
      madhhabNotes: {
        LearningMadhhab.shafi: 'Reciting at least "Allahumma salli \'ala Muhammad" is an obligatory pillar (Farḍ).',
        LearningMadhhab.hanafi: 'Durood Ibrahim is an emphasized Sunnah (Sunnah Muakkadah) in the final sitting.',
      },
    ),
    SalahStep(
      id: 'salah_12_final_dua',
      stepNumber: 12,
      title: 'Final Supplication (Dua Before Salam)',
      position: SalahPosition.dua,
      ruling: RulingLevel.sunnah,
      arabicText:
          'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، وَمِنْ عَذَابِ جَهَنَّمَ، وَمِنْ فِتْنَةِ الْمَحْيَا وَالْمَمَاتِ، وَمِنْ شَرِّ فِتْنَةِ الْمَسِيحِ الدَّجَّالِ.',
      transliteration:
          "Allahumma inni a'udhu bika min 'adhabil-qabr, wa min 'adhabi jahannam, wa min fitnatil-mahya wal-mamat, wa min sharri fitnatil-masihid-dajjal.",
      translation:
          'O Allah, I seek refuge in You from the punishment of the grave, from the punishment of Hellfire, from the trials of life and death, and from the evil trial of the False Messiah (Dajjal).',
      explanation:
          'A deeply recommended Sunnah supplication taught directly by the Prophet ﷺ before concluding the prayer. You may also recite any Quranic supplication here such as: "Rabbana atina fid-dunya hasanah wa fil-akhirati hasanah wa qina \'adhaban-nar."',
      repetition: 1,
      sourceReference: 'Sahih al-Bukhari 1377, Sahih Muslim 588',
      madhhabNotes: {
        LearningMadhhab.shafi: 'Sunnah to seek refuge from the four trials.',
        LearningMadhhab.hanafi: 'Only supplications from the Quran or authentic Sunnah are permissible here.',
      },
    ),
    SalahStep(
      id: 'salah_13_tasleem',
      stepNumber: 13,
      title: 'Tasleem (Salutation of Peace)',
      position: SalahPosition.tasleem,
      ruling: RulingLevel.fard,
      arabicText: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
      transliteration: "As-salamu 'alaykum wa rahmatullah",
      translation: 'May the peace and mercy of Allah be upon you.',
      explanation:
          'Turn your head to the right until the cheek is visible from behind, and say: "As-salamu \'alaykum wa rahmatullah". Then turn your head to the left and repeat the salutation. The first Salam to the right is the obligatory pillar that concludes the Salah.',
      repetition: 2,
      sourceReference: 'Sahih Muslim 582, Sunan Abi Dawud 996',
      madhhabNotes: {
        LearningMadhhab.shafi: 'The first Salam to the right is the Farḍ pillar; the second to the left is Sunnah.',
        LearningMadhhab.hanafi: 'Both Salams are Wajib; turning completes the prayer.',
      },
    ),
  ];

  // ---------------------------------------------------------------------------
  // COMPLETE RECITATION & DUA LIBRARY
  // ---------------------------------------------------------------------------
  static const List<RecitationItem> recitations = [
    RecitationItem(
      id: 'rec_takbir',
      title: 'Takbir (Allahu Akbar)',
      category: 'Opening',
      arabicText: 'اللَّهُ أَكْبَرُ',
      transliteration: 'Allahu Akbar',
      translation: 'Allah is the Greatest.',
      context: 'Recited at the start of prayer and between movements (transitions).',
      sourceReference: 'Sahih al-Bukhari 789',
      lines: [
        RecitationLine(arabic: 'اللَّهُ أَكْبَرُ', transliteration: 'Allahu Akbar', translation: 'Allah is the Greatest.'),
      ],
    ),
    RecitationItem(
      id: 'rec_istiftah_shafi',
      title: 'Opening Dua (Wajjahtu - Shafi\'i)',
      category: 'Opening',
      arabicText:
          'وَجَّهْتُ وَجْهِيَ لِلَّذِي فَطَرَ السَّمَاوَاتِ وَالْأَرْضَ حَنِيفًا مُسْلِمًا وَمَا أَنَا مِنَ الْمُشْرِكِينَ، إِنَّ صَلَاتِي وَنُسُكِي وَمَحْيَايَ وَمَمَاتِي لِلَّهِ رَبِّ الْعَالَمِينَ، لَا شَرِيكَ لَهُ وَبِذَٰلِكَ أُمِرْتُ وَأَنَا مِنَ الْمُسْلِمِينَ.',
      transliteration:
          "Wajjahtu wajhiya lilladhi fataras-samawati wal-arda hanifan musliman wa ma ana minal-mushrikin. Inna salati wa nusuki wa mahyaya wa mamati lillahi Rabbil-'alamin, la sharika lahu wa bidhalika umirtu wa ana minal-muslimin.",
      translation:
          'I have turned my face sincerely towards Him Who originated the heavens and the earth, being upright and a Muslim, and I am not of the polytheists. Indeed, my prayer, my sacrifice, my living, and my dying are for Allah, Lord of all the worlds. No partner has He, and with this I have been commanded, and I am among the Muslims.',
      context: 'Recited silently after Takbiratul Ihram before Surah Al-Fatiha in the first Rak\'ah.',
      sourceReference: 'Sahih Muslim 771 (Ali ibn Abi Talib narration)',
      lines: [
        RecitationLine(
          arabic: 'وَجَّهْتُ وَجْهِيَ لِلَّذِي فَطَرَ السَّمَاوَاتِ وَالْأَرْضَ حَنِيفًا مُسْلِمًا وَمَا أَنَا مِنَ الْمُشْرِكِينَ',
          transliteration: "Wajjahtu wajhiya lilladhi fataras-samawati wal-arda hanifan musliman wa ma ana minal-mushrikin",
          translation: 'I have turned my face sincerely towards Him Who created the heavens and earth.',
        ),
        RecitationLine(
          arabic: 'إِنَّ صَلَاتِي وَنُسُكِي وَمَحْيَايَ وَمَمَاتِي لِلَّهِ رَبِّ الْعَالَمِينَ',
          transliteration: "Inna salati wa nusuki wa mahyaya wa mamati lillahi Rabbil-'alamin",
          translation: 'Indeed, my prayer, my sacrifice, my life, and my death are all for Allah.',
        ),
        RecitationLine(
          arabic: 'لَا شَرِيكَ لَهُ وَبِذَٰلِكَ أُمِرْتُ وَأَنَا مِنَ الْمُسْلِمِينَ',
          transliteration: 'La sharika lahu wa bidhalika umirtu wa ana minal-muslimin',
          translation: 'No partner has He, and with this I was commanded, and I am among the Muslims.',
        ),
      ],
    ),
    RecitationItem(
      id: 'rec_istiftah_hanafi',
      title: 'Opening Dua (Subhanaka - Hanafi / Hanbali)',
      category: 'Opening',
      arabicText:
          'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، وَتَبَارَكَ اسْمُكَ، وَتَعَالَىٰ جَدُّكَ، وَلَا إِلَٰهَ غَيْرُكَ.',
      transliteration:
          'Subhanakallahumma wa bihamdika, wa tabarakasmuka, wa ta\'ala jadduka, wa la ilaha ghayruk.',
      translation:
          'Glory be to You, O Allah, and all praise. Blessed is Your Name, exalted is Your Majesty, and there is no deity worthy of worship besides You.',
      context: 'Recited silently after Takbiratul Ihram before Surah Al-Fatiha in the first Rak\'ah.',
      sourceReference: 'Sunan Abi Dawud 775, Jami` at-Tirmidhi 242 (Sahih)',
      lines: [
        RecitationLine(
          arabic: 'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ',
          transliteration: 'Subhanakallahumma wa bihamdik',
          translation: 'Glory be to You, O Allah, and all praise is Yours.',
        ),
        RecitationLine(
          arabic: 'وَتَبَارَكَ اسْمُكَ، وَتَعَالَىٰ جَدُّكَ، وَلَا إِلَٰهَ غَيْرُكَ',
          transliteration: "Wa tabarakasmuka, wa ta'ala jadduka, wa la ilaha ghayruk",
          translation: 'Blessed is Your Name, exalted is Your Majesty, and there is no deity besides You.',
        ),
      ],
    ),
    RecitationItem(
      id: 'rec_fatiha',
      title: 'Surah Al-Fatiha (The Opening)',
      category: 'Quranic Recitation',
      arabicText:
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ۝ الرَّحْمَٰنِ الرَّحِيمِ ۝ مَالِكِ يَوْمِ الدِّينِ ۝ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ۝ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ ۝ صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ ۝',
      transliteration:
          "Bismillahir-Rahmanir-Raheem. Al-hamdu lillahi Rabbil-'alamin. Ar-Rahmanir-Raheem. Maliki Yawmid-Deen. Iyyaka na'budu wa iyyaka nasta'een. Ihdinas-siratal-mustaqeem. Siratalladhina an'amta 'alayhim, ghayril-maghdubi 'alayhim wa lad-dallin.",
      translation:
          'In the Name of Allah, the Entirely Merciful, the Especially Merciful. All praise is due to Allah, Lord of the worlds. The Entirely Merciful, the Especially Merciful. Sovereign of the Day of Recompense. It is You we worship and You we ask for help. Guide us to the straight path. The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray.',
      context: 'Recited in EVERY rak\'ah of every prayer. An obligatory pillar without which prayer is invalid.',
      sourceReference: 'Surah Al-Fatiha (1:1-7); Sahih al-Bukhari 756',
      lines: [
        RecitationLine(arabic: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', transliteration: 'Bismillahir-Rahmanir-Raheem', translation: 'In the Name of Allah, the Entirely Merciful, the Especially Merciful.'),
        RecitationLine(arabic: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', transliteration: "Al-hamdu lillahi Rabbil-'alamin", translation: 'All praise is due to Allah, Lord of all the worlds.'),
        RecitationLine(arabic: 'الرَّحْمَٰنِ الرَّحِيمِ', transliteration: 'Ar-Rahmanir-Raheem', translation: 'The Entirely Merciful, the Especially Merciful.'),
        RecitationLine(arabic: 'مَالِكِ يَوْمِ الدِّينِ', transliteration: 'Maliki Yawmid-Deen', translation: 'Sovereign of the Day of Recompense.'),
        RecitationLine(arabic: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ', transliteration: "Iyyaka na'budu wa iyyaka nasta'een", translation: 'It is You alone we worship, and You alone we ask for help.'),
        RecitationLine(arabic: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ', transliteration: 'Ihdinas-siratal-mustaqeem', translation: 'Guide us to the straight path.'),
        RecitationLine(arabic: 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ', transliteration: "Siratalladhina an'amta 'alayhim, ghayril-maghdubi 'alayhim wa lad-dallin", translation: 'The path of those You favored, not of those who incurred anger or went astray.'),
      ],
    ),
    RecitationItem(
      id: 'rec_ikhlas',
      title: 'Surah Al-Ikhlas (Purity of Faith)',
      category: 'Quranic Recitation',
      arabicText:
          'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ ۝',
      transliteration:
          'Qul Huwallahu Ahad. Allahus-Samad. Lam yalid wa lam yulad. Wa lam yakul-lahu kufuwan ahad.',
      translation:
          'Say: "He is Allah, [who is] One. Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent."',
      context: 'Commonly recited after Surah Al-Fatiha in the first or second Rak\'ah. Equals one-third of the Quran.',
      sourceReference: 'Surah Al-Ikhlas (112:1-4); Sahih al-Bukhari 5013',
      lines: [
        RecitationLine(arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ', transliteration: 'Qul Huwallahu Ahad', translation: 'Say: "He is Allah, the One."'),
        RecitationLine(arabic: 'اللَّهُ الصَّمَدُ', transliteration: 'Allahus-Samad', translation: 'Allah, the Eternal Refuge.'),
        RecitationLine(arabic: 'لَمْ يَلِدْ وَلَمْ يُولَدْ', transliteration: 'Lam yalid wa lam yulad', translation: 'He neither begets nor is born.'),
        RecitationLine(arabic: 'وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ', transliteration: 'Wa lam yakul-lahu kufuwan ahad', translation: 'Nor is there to Him any equivalent.'),
      ],
    ),
    RecitationItem(
      id: 'rec_falaq',
      title: 'Surah Al-Falaq (The Daybreak)',
      category: 'Quranic Recitation',
      arabicText:
          'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ ۝',
      transliteration:
          "Qul a'udhu bi-Rabbil-falaq. Min sharri ma khalaq. Wa min sharri ghasiqin idha waqab. Wa min sharrin-naffathati fil-'uqad. Wa min sharri hasidin idha hasad.",
      translation:
          'Say: "I seek refuge in the Lord of daybreak from the evil of that which He created, and from the evil of darkness when it settles, and from the evil of the blowers in knots, and from the evil of an envier when he envies."',
      context: 'Recited after Surah Al-Fatiha in Rak\'ah 1 or 2. One of the two protector Surahs (Al-Mu\'awwidhatayn).',
      sourceReference: 'Surah Al-Falaq (113:1-5); Sahih Muslim 814',
      lines: [
        RecitationLine(arabic: 'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ', transliteration: "Qul a'udhu bi-Rabbil-falaq", translation: 'Say: "I seek refuge in the Lord of daybreak."'),
        RecitationLine(arabic: 'مِن شَرِّ مَا خَلَقَ', transliteration: 'Min sharri ma khalaq', translation: 'From the evil of what He created.'),
        RecitationLine(arabic: 'وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ', transliteration: 'Wa min sharri ghasiqin idha waqab', translation: 'And from the evil of darkness when it settles.'),
        RecitationLine(arabic: 'وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ', transliteration: "Wa min sharrin-naffathati fil-'uqad", translation: 'And from the evil of those who blow on knots.'),
        RecitationLine(arabic: 'وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ', transliteration: 'Wa min sharri hasidin idha hasad', translation: 'And from the evil of an envier when he envies.'),
      ],
    ),
    RecitationItem(
      id: 'rec_nas',
      title: 'Surah An-Nas (Mankind)',
      category: 'Quranic Recitation',
      arabicText:
          'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ ۝',
      transliteration:
          "Qul a'udhu bi-Rabbin-nas. Malikin-nas. Ilahin-nas. Min sharril-waswasil-khannas. Alladhi yuwaswisu fee sudoorin-nas. Minal-jinnati wan-nas.",
      translation:
          'Say: "I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the retreating whisperer who whispers [evil] into the breasts of mankind, from among the jinn and mankind."',
      context: 'Recited after Surah Al-Fatiha in Rak\'ah 1 or 2.',
      sourceReference: 'Surah An-Nas (114:1-6); Sahih Muslim 814',
      lines: [
        RecitationLine(arabic: 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ', transliteration: "Qul a'udhu bi-Rabbin-nas", translation: 'Say: "I seek refuge in the Lord of mankind."'),
        RecitationLine(arabic: 'مَلِكِ النَّاسِ', transliteration: 'Malikin-nas', translation: 'The Sovereign of mankind.'),
        RecitationLine(arabic: 'إِلَٰهِ النَّاسِ', transliteration: 'Ilahin-nas', translation: 'The God of mankind.'),
        RecitationLine(arabic: 'مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ', transliteration: 'Min sharril-waswasil-khannas', translation: 'From the evil of the retreating whisperer.'),
        RecitationLine(arabic: 'الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ', transliteration: 'Alladhi yuwaswisu fee sudoorin-nas', translation: 'Who whispers into the breasts of mankind.'),
        RecitationLine(arabic: 'مِنَ الْجِنَّةِ وَالنَّاسِ', transliteration: 'Minal-jinnati wan-nas', translation: 'From among the jinn and mankind.'),
      ],
    ),
    RecitationItem(
      id: 'rec_kawthar',
      title: 'Surah Al-Kawthar (Abundance)',
      category: 'Quranic Recitation',
      arabicText:
          'إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ ۝ فَصَلِّ لِرَبِّكَ وَانْحَرْ ۝ إِنَّ شَانِئَكَ هُوَ الْأَبْتَرُ ۝',
      transliteration:
          "Inna a'taynkal-kawthar. Fa-salli li-Rabbika wan-har. Inna shani'aka huwal-abtar.",
      translation:
          'Indeed, We have granted you, [O Muhammad], abundance. So pray to your Lord and sacrifice. Indeed, your enemy is the one cut off.',
      context: 'The shortest Surah in the Holy Quran, very easy and common for beginners to recite in Salah.',
      sourceReference: 'Surah Al-Kawthar (108:1-3)',
      lines: [
        RecitationLine(arabic: 'إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ', transliteration: "Inna a'taynkal-kawthar", translation: 'Indeed, We have given you the Abundance.'),
        RecitationLine(arabic: 'فَصَلِّ لِرَبِّكَ وَانْحَرْ', transliteration: 'Fa-salli li-Rabbika wan-har', translation: 'So pray to your Lord and sacrifice.'),
        RecitationLine(arabic: 'إِنَّ شَانِئَكَ هُوَ الْأَبْتَرُ', transliteration: "Inna shani'aka huwal-abtar", translation: 'Indeed, your enemy is cut off from all good.'),
      ],
    ),
    RecitationItem(
      id: 'rec_ruku',
      title: 'Tasbeeh of Ruku (Bowing)',
      category: 'Bowing & Prostrating',
      arabicText: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ وَبِحَمْدِهِ',
      transliteration: "Subhana Rabbiyal-'Adheemi wa bihamdih",
      translation: 'Glory be to my Lord, the Magnificent, and with His praise.',
      context: 'Recited at least 3 times while bowed in Ruku.',
      repetition: 3,
      sourceReference: 'Sahih Muslim 772, Sunan Abi Dawud 869',
      lines: [
        RecitationLine(arabic: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ', transliteration: "Subhana Rabbiyal-'Adheem", translation: 'Glory be to my Lord, the Magnificent.'),
      ],
    ),
    RecitationItem(
      id: 'rec_itidal',
      title: 'Praise of I\'tidal (Rising upright)',
      category: 'Bowing & Prostrating',
      arabicText: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ ۝ رَبَّنَا وَلَكَ الْحَمْدُ',
      transliteration: "Sami' Allahu liman hamidah. Rabbana wa lakal-hamd.",
      translation: 'Allah listens to whoever praises Him. Our Lord, and to You belongs all praise.',
      context: 'First part recited while moving up, second part once fully upright and still.',
      sourceReference: 'Sahih al-Bukhari 789, Sahih Muslim 404',
      lines: [
        RecitationLine(arabic: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ', transliteration: "Sami' Allahu liman hamidah", translation: 'Allah listens to whoever praises Him.'),
        RecitationLine(arabic: 'رَبَّنَا وَلَكَ الْحَمْدُ', transliteration: 'Rabbana wa lakal-hamd', translation: 'Our Lord, and to You belongs all praise.'),
      ],
    ),
    RecitationItem(
      id: 'rec_sujood',
      title: 'Tasbeeh of Sujood (Prostration)',
      category: 'Bowing & Prostrating',
      arabicText: 'سُبْحَانَ رَبِّيَ الْأَعْلَىٰ وَبِحَمْدِهِ',
      transliteration: "Subhana Rabbiyal-A'la wa bihamdih",
      translation: 'Glory be to my Lord, the Most High, and with His praise.',
      context: 'Recited at least 3 times while in Sujood (prostration).',
      repetition: 3,
      sourceReference: 'Sahih Muslim 772',
      lines: [
        RecitationLine(arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَىٰ', transliteration: "Subhana Rabbiyal-A'la", translation: 'Glory be to my Lord, the Most High.'),
      ],
    ),
    RecitationItem(
      id: 'rec_jalsah',
      title: 'Dua Between Prostrations',
      category: 'Bowing & Prostrating',
      arabicText: 'رَبِّ اغْفِرْ لِي، وَارْحَمْنِي، وَاجْبُرْنِي، وَارْفَعْنِي، وَارْزُقْنِي، وَاهْدِنِي، وَعَافِنِي.',
      transliteration: "Rabbighfir li, warhamni, wajburni, warfa'ni, warzuqni, wahdini, wa'afini.",
      translation: 'O my Lord, forgive me, have mercy on me, mend my shortcomings, elevate my status, provide for me, guide me, and grant me well-being.',
      context: 'Recited while sitting calmly between the first and second Sujood.',
      sourceReference: 'Sunan Abi Dawud 850, Jami` at-Tirmidhi 284 (Sahih)',
      lines: [
        RecitationLine(arabic: 'رَبِّ اغْفِرْ لِي، وَارْحَمْنِي', transliteration: 'Rabbighfir li, warhamni', translation: 'O my Lord, forgive me and have mercy on me.'),
        RecitationLine(arabic: 'وَاجْبُرْنِي، وَارْفَعْنِي، وَارْزُقْنِي', transliteration: "Wajburni, warfa'ni, warzuqni", translation: 'Mend my shortcomings, elevate me, and provide for me.'),
        RecitationLine(arabic: 'وَاهْدِنِي، وَعَافِنِي', transliteration: "Wahdini, wa'afini", translation: 'Guide me and grant me pardoning well-being.'),
      ],
    ),
    RecitationItem(
      id: 'rec_tashahhud',
      title: 'Tashahhud (Attahiyyat)',
      category: 'Sitting & Concluding',
      arabicText:
          'التَّحِيَّاتُ الْمُبَارَكَاتُ الصَّلَوَاتُ الطَّيِّبَاتُ لِلَّهِ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَىٰ عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ وَأَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ.',
      transliteration:
          "At-tahiyyatu al-mubarakatus-salawatu at-tayyibatu lillah. As-salamu 'alayka ayyuhan-Nabiyyu wa rahmatullahi wa barakatuh. As-salamu 'alayna wa 'ala 'ibadillahis-salihin. Ash-hadu alla ilaha illallahu wa ash-hadu anna Muhammadan rasulullah.",
      translation:
          'All blessed greetings, prayers and good deeds belong to Allah. Peace be upon you, O Prophet, and the mercy of Allah and His blessings. Peace be upon us and upon the righteous servants of Allah. I bear witness that there is no deity worthy of worship except Allah, and I bear witness that Muhammad is the Messenger of Allah.',
      context: 'Recited in the sitting of the 2nd and final Rak\'ahs.',
      sourceReference: 'Sahih Muslim 403 (Ibn Abbas narration), Sahih al-Bukhari 831',
      lines: [
        RecitationLine(arabic: 'التَّحِيَّاتُ الْمُبَارَكَاتُ الصَّلَوَاتُ الطَّيِّبَاتُ لِلَّهِ', transliteration: 'At-tahiyyatu al-mubarakatus-salawatu at-tayyibatu lillah', translation: 'All blessed greetings, prayers and pure deeds belong to Allah.'),
        RecitationLine(arabic: 'السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ', transliteration: "As-salamu 'alayka ayyuhan-Nabiyyu wa rahmatullahi wa barakatuh", translation: 'Peace be upon you, O Prophet, and Allah\'s mercy and blessings.'),
        RecitationLine(arabic: 'السَّلَامُ عَلَيْنَا وَعَلَىٰ عِبَادِ اللَّهِ الصَّالِحِينَ', transliteration: "As-salamu 'alayna wa 'ala 'ibadillahis-salihin", translation: 'Peace be upon us and upon the righteous servants of Allah.'),
        RecitationLine(arabic: 'أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا اللَّهُ', transliteration: 'Ash-hadu alla ilaha illallah', translation: 'I bear witness that there is no god but Allah.'),
        RecitationLine(arabic: 'وَأَشْهَدُ أَنَّ مُحَمَّدًا رَسُولُ اللَّهِ', transliteration: 'Wa ash-hadu anna Muhammadan rasulullah', translation: 'And I bear witness that Muhammad is the Messenger of Allah.'),
      ],
    ),
    RecitationItem(
      id: 'rec_durood',
      title: 'Durood Ibrahim (Salawat)',
      category: 'Sitting & Concluding',
      arabicText:
          'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ. اللَّهُمَّ بَارِكْ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ.',
      transliteration:
          "Allahumma salli 'ala Muhammadin wa 'ala ali Muhammad, kama sallayta 'ala Ibrahima wa 'ala ali Ibrahim, innaka Hamidun Majid. Allahumma barik 'ala Muhammadin wa 'ala ali Muhammad, kama barakta 'ala Ibrahima wa 'ala ali Ibrahim, innaka Hamidun Majid.",
      translation:
          'O Allah, send blessings upon Muhammad and upon the family of Muhammad, as You sent blessings upon Ibrahim and upon the family of Ibrahim; indeed, You are Praiseworthy, Majestic. O Allah, bless Muhammad and the family of Muhammad, as You blessed Ibrahim and the family of Ibrahim; indeed, You are Praiseworthy, Majestic.',
      context: 'Recited immediately after Tashahhud in the final sitting before concluding the prayer.',
      sourceReference: 'Sahih al-Bukhari 3370, Sahih Muslim 406',
      lines: [
        RecitationLine(arabic: 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ', transliteration: "Allahumma salli 'ala Muhammadin wa 'ala ali Muhammad", translation: 'O Allah, send blessings upon Muhammad and the family of Muhammad,'),
        RecitationLine(arabic: 'كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ', transliteration: "kama sallayta 'ala Ibrahima wa 'ala ali Ibrahim, innaka Hamidun Majid.", translation: 'as You blessed Ibrahim and his family; You are Praiseworthy, Majestic.'),
        RecitationLine(arabic: 'اللَّهُمَّ بَارِكْ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ', transliteration: "Allahumma barik 'ala Muhammadin wa 'ala ali Muhammad", translation: 'O Allah, bless Muhammad and the family of Muhammad,'),
        RecitationLine(arabic: 'كَمَا بَارَكْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ', transliteration: "kama barakta 'ala Ibrahima wa 'ala ali Ibrahim, innaka Hamidun Majid.", translation: 'as You blessed Ibrahim and his family; You are Praiseworthy, Majestic.'),
      ],
    ),
    RecitationItem(
      id: 'rec_qunut',
      title: 'Du\'a al-Qunut',
      category: 'Sitting & Concluding',
      arabicText:
          'اللَّهُمَّ اهْدِنِي فِيمَنْ هَدَيْتَ، وَعَافِنِي فِيمَنْ عَافَيْتَ، وَتَوَلَّنِي فِيمَنْ تَوَلَّيْتَ، وَبَارِكْ لِي فِيمَا أَعْطَيْتَ، وَقِنِي شَرَّ مَا قَضَيْتَ، فَإِنَّكَ تَقْضِي وَلَا يُقْضَىٰ عَلَيْكَ، وَإِنَّهُ لَا يَذِلُّ مَنْ وَالَيْتَ، وَلَا يَعِزُّ مَنْ عَادَيْتَ، تَبَارَكْتَ رَبَّنَا وَتَعَالَيْتَ.',
      transliteration:
          "Allahumma-hdini fiman hadayt, wa 'afini fiman 'afayt, wa tawallani fiman tawallayt, wa barik li fima a'tayt, wa qini sharra ma qadayt, fa-innaka taqdi wa la yuqda 'alayk, wa innahu la yadhillu man walayt, wa la ya'izzu man 'adayt, tabarakta Rabbana wa ta'alayt.",
      translation:
          'O Allah, guide me among those You have guided, grant me well-being among those You have granted well-being, take me into Your care among those You have taken into Your care, bless me in what You have given, and save me from the evil of what You have decreed. For indeed You decree and none can decree over You. Indeed, he whom You take as an ally is never humiliated, and he whom You take as an enemy is never honored. Blessed are You, our Lord, and Exalted.',
      context: 'Recited in Fajr prayer after Ruku in Shafi\'i, and in Witr prayer in Hanafi.',
      sourceReference: 'Sunan Abi Dawud 1425, Jami` at-Tirmidhi 464 (Hasan Sahih)',
      lines: [
        RecitationLine(arabic: 'اللَّهُمَّ اهْدِنِي فِيمَنْ هَدَيْتَ', transliteration: 'Allahumma-hdini fiman hadayt', translation: 'O Allah, guide me among those You have guided.'),
        RecitationLine(arabic: 'وَعَافِنِي فِيمَنْ عَافَيْتَ', transliteration: "Wa 'afini fiman 'afayt", translation: 'Grant me health and well-being among those You have pardoned.'),
        RecitationLine(arabic: 'وَتَوَلَّنِي فِيمَنْ تَوَلَّيْتَ', transliteration: 'Wa tawallani fiman tawallayt', translation: 'Take me under Your loving guardianship.'),
        RecitationLine(arabic: 'وَبَارِكْ لِي فِيمَا أَعْطَيْتَ', transliteration: "Wa barik li fima a'tayt", translation: 'Bless me in all that You have granted.'),
        RecitationLine(arabic: 'وَقِنِي شَرَّ مَا قَضَيْتَ', transliteration: 'Wa qini sharra ma qadayt', translation: 'And protect me from the evil of what You decreed.'),
        RecitationLine(arabic: 'فَإِنَّكَ تَقْضِي وَلَا يُقْضَىٰ عَلَيْكَ', transliteration: "Fa-innaka taqdi wa la yuqda 'alayk", translation: 'For You decree, and none can decree against You.'),
        RecitationLine(arabic: 'تَبَارَكْتَ رَبَّنَا وَتَعَالَيْتَ', transliteration: "Tabarakta Rabbana wa ta'alayt", translation: 'Blessed are You, our Lord, and Most High.'),
      ],
    ),
    RecitationItem(
      id: 'rec_tasleem',
      title: 'Tasleem (Concluding Salam)',
      category: 'Sitting & Concluding',
      arabicText: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
      transliteration: "As-salamu 'alaykum wa rahmatullah",
      translation: 'May the peace and mercy of Allah be upon you.',
      context: 'Recited turning head right, then turning head left, to finish the prayer.',
      sourceReference: 'Sahih Muslim 582',
      lines: [
        RecitationLine(arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ', transliteration: "As-salamu 'alaykum wa rahmatullah", translation: 'Peace and Allah\'s mercy be upon you.'),
      ],
    ),
  ];

  // ---------------------------------------------------------------------------
  // 7-DAY BEGINNER LEARNING PATH
  // ---------------------------------------------------------------------------
  static const List<BeginnerDay> beginnerDays = [
    BeginnerDay(
      day: 1,
      title: 'Day 1: What is Salah & The 5 Prayers',
      subtitle: 'Understand why we pray and discover the five daily appointments with Allah.',
      icon: '🕋',
      overview:
          'Salah is the second pillar of Islam and the direct link between a servant and the Creator. Today, discover the names, times, and obligatory rak\'ah counts of the 5 prayers.',
      keyTakeaways: [
        'Salah was given directly to the Prophet ﷺ during the Miraj.',
        'The 5 daily prayers are: Fajr (2), Dhuhr (4), Asr (4), Maghrib (3), and Isha (4).',
        'Obligatory (Farḍ) rak\'ahs must never be skipped.',
      ],
      practicalStep: 'Review the Five Daily Prayers breakdown and memorize their names.',
    ),
    BeginnerDay(
      day: 2,
      title: 'Day 2: Mastering Wudu (Ablution)',
      subtitle: 'Learn the sacred method of purifying body and soul before standing before Allah.',
      icon: '💧',
      overview:
          'Purification is half of faith. Before we pray, we perform Wudu with clean water following the Sunnah of the Prophet ﷺ.',
      keyTakeaways: [
        'Wudu washes away physical impurities and minor sins.',
        'Four things are Farḍ in the Quran: washing face, arms to elbows, wiping head, washing feet to ankles.',
        'Washing 3 times and rinsing mouth/nose are beautiful Sunnahs.',
      ],
      practicalStep: 'Follow the 12-step Wudu tutorial and practice it at the sink.',
    ),
    BeginnerDay(
      day: 3,
      title: 'Day 3: Standing, Niyyah & Takbir',
      subtitle: 'How to enter Salah with intention and majesty.',
      icon: '🧍',
      overview:
          'Learn how to stand upright facing the Qibla, form the intention in your heart, raise your hands, and say the opening Allahu Akbar.',
      keyTakeaways: [
        'Face the Qibla and keep feet shoulder-width apart.',
        'Intention (Niyyah) is formed in the heart.',
        'Takbiratul Ihram marks the sacred beginning where worldly actions cease.',
      ],
      practicalStep: 'Practice raising your hands, saying Allahu Akbar, and folding hands on chest.',
    ),
    BeginnerDay(
      day: 4,
      title: 'Day 4: Surah Al-Fatiha',
      subtitle: 'The Mother of the Book — recited in every single rak\'ah.',
      icon: '📖',
      overview:
          'Surah Al-Fatiha is the core recitation of Salah. Without it, prayer is invalid. Learn its pronunciation, verse by verse, and its profound meaning.',
      keyTakeaways: [
        'Consists of 7 verses recited in every rak\'ah.',
        'In the first two rak\'ahs, follow it with a short Surah like Al-Ikhlas.',
        'Take your time and pause after each verse.',
      ],
      practicalStep: 'Listen line-by-line to Surah Al-Fatiha and recite along 3 times.',
    ),
    BeginnerDay(
      day: 5,
      title: 'Day 5: Ruku (Bowing) & Rising',
      subtitle: 'Physical humility before the Magnificence of the Creator.',
      icon: '🙇',
      overview:
          'Learn the correct posture of Ruku with a flat back and hands on knees, what to recite, and how to stand up straight with praise.',
      keyTakeaways: [
        'Keep back straight like a table, head neither raised nor dropped.',
        'Recite "Subhana Rabbiyal Adheem" at least 3 times.',
        'Rise saying "Sami Allahu liman hamidah" and settle completely before moving.',
      ],
      practicalStep: 'Practice bowing in front of a mirror or friend to verify a straight back.',
    ),
    BeginnerDay(
      day: 6,
      title: 'Day 6: Sujood (Prostration) & Sitting',
      subtitle: 'The closest a servant ever comes to Allah.',
      icon: '🤲',
      overview:
          'The Prophet ﷺ said: "The servant is closest to his Lord during prostration, so make much supplication." (Sahih Muslim 482). Master the 7 contact points.',
      keyTakeaways: [
        'Seven points MUST touch: forehead & nose, both palms, both knees, and both sets of toes.',
        'Recite "Subhana Rabbiyal A\'la" 3 times.',
        'Sit peacefully between the two Sujoods and say "Rabbighfir li".',
      ],
      practicalStep: 'Practice prostrating with elbows elevated off the ground.',
    ),
    BeginnerDay(
      day: 7,
      title: 'Day 7: Tashahhud, Durood & Tasleem',
      subtitle: 'Concluding your Salah with peace and testimony.',
      icon: '🌟',
      overview:
          'Learn the final sitting, the testimony of faith (Tashahhud), blessings on the Prophet ﷺ (Durood Ibrahim), and the concluding Salam.',
      keyTakeaways: [
        'Sit with hands on thighs and raise the index finger during testimony.',
        'Recite Durood Ibrahim sending peace upon the Prophet ﷺ.',
        'Conclude by turning right then left saying "As-salamu \'alaykum wa rahmatullah".',
      ],
      practicalStep: 'Perform your first complete guided 2-Rak\'ah Fajr prayer!',
    ),
  ];
}
