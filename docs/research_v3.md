# Research, round 3: what an app like this still needs

Sources were checked online on 20 Nov 2026. **Added** means it is in this version. **Next** means it is recommended but not built yet.

## Added in this version
- **Location and time anywhere.** GPS location with travel detection, the server clock as the authority, and a warning when the phone's time zone looks wrong.
- **Local calculation method picked automatically by region**, plus mosque minute offsets. No official Samastha formula is published, so offsets are the safe way to match a local timetable. IslamicFinder defaults Kerala to Karachi 18°/18°. (islamicfinder.org, praytimes.org/docs/methods)
- **High-latitude rule** for places where twilight never ends.
- **Hijri date with a ±2 day adjustment.** Kerala often follows the Gulf moon announcement while other places may be a day later. (siasat.com, khaleejtimes.com)
- **Jumu'ah** label on Fridays.
- **Niyyah reminder in focus mode.** On riya: SeekersGuidance (citing al-Ghazali) notes that telling others about *obligatory* prayer is not showing off, because everyone must do it. The concern is with voluntary deeds, so Tasbih stays private and earns no XP.
- **Delete my account.** Mandatory on Google Play (in-app plus a web link) and the App Store. (support.google.com/googleplay/android-developer/answer/13327111, developer.apple.com/support/offering-account-deletion-in-your-app)
- **Lite mode and reduced motion.** BackdropFilter blur and looping animations are the main jank sources on older GPUs. (docs.flutter.dev/perf/best-practices)
- **Respectful iconography:** a prayer mat (musalla) instead of the meditation icon, and a crescent instead of the candle.

## Next (recommended, in order)
1. **Private "excused" pause** for menstruation, illness or travel. Streaks freeze, and the circle sees only a neutral "excused", never the reason. Users of other apps have asked for this. (apps.apple.com Pillars; feedback.gtaf.org)
2. **Qada make-up log:** a private balance of missed prayers that you tick off when made up.
3. **Ramadan mode:** suhoor (imsak) and iftar countdowns, a Taraweeh check-in and a fasting log.
4. **Travel (qasr/jam')**: combined Dhuhr+Asr or Maghrib+Isha counted correctly while travelling.
5. **"Share less" privacy option**: circle sees only done / not done (no times, photos or XP), and you can leave the league without leaving the circle.
6. **Photo retention**: auto-delete proof photos after 72 hours, strip EXIF/GPS data, never require faces.
7. **Children's data (India DPDP Rules 2025):** under 18 needs verifiable parental consent. Add an age gate and a family-admin flow before inviting teens.
8. **Accessibility pass:** screen-reader labels on matrix cells ("Fathima, Asr, on time"), 48dp touch targets, and a 200% font-scale check (Android 14 non-linear scaling).
9. **Home-screen widget, Adhan sound choice, live compass Qibla.**

## Old phones
- **Minimum versions:** Flutter 3.50 supports Android 7.0 (API 24) and newer, and iOS 15 and newer. (docs.flutter.dev/reference/supported-platforms)
- **Rendering:** Impeller runs on Android 10+ with Vulkan, and older phones fall back to OpenGL automatically. Test on one cheap Android 8–9 phone before release. (docs.flutter.dev/perf/impeller)
- **Size:** ship an app bundle, or split APKs per CPU (`--split-per-abi`).
