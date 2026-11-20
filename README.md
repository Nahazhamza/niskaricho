# Niskaricho? (നിസ്കരിച്ചോ?)

*"Did you pray?"* An open-source, ad-free group prayer accountability app for friends, families, hostel roommates and study circles. Built with Flutter (iOS + Android) and Supabase.

<p align="center"><img src="assets/icon/niskaricho_icon.svg" width="140" alt="Niskaricho icon"></p>

## What's in this folder

```
supabase/schema.sql                    Postgres schema, RLS, anti-cheat RPCs, prayer-time engine, storage, cron
lib/
  main.dart                            Supabase init + auth gate
  models/prayer_model.dart             PrayerName, PrayerStatus, PrayerWindow, PrayerLog, Streak
  models/circle_model.dart             Circle, MatrixRow / MatrixCell (live squad grid)
  services/prayer_calculator_service.dart   Offline GPS prayer times (adhan_dart)
  services/supabase_service.dart       Typed RPC / storage / realtime wrapper + server clock
  services/notification_service.dart   Exact Adhan alerts, 20-min warnings, nudge popups
  l10n/tr.dart                         tr('English') lookup, app language, text size
  l10n/ml.dart, l10n/ar.dart           Malayalam and Arabic UI text (409 phrases each)
  l10n/copy.dart                       Notifications and Khushu' reflections in all three languages
  models/access_model.dart             Invite-only access: accounts, invite codes, join requests
  theme/app_theme.dart                 Emerald / gold night theme
  widgets/fx.dart                      Cosmic background, glass cards, rings, sky arc, confetti
  models/progress_model.dart           XP rules, levels, league, quest, badge catalogue
  services/demo_backend.dart           In-memory demo with sample circle (no Supabase needed)
  services/zones.dart                  Time zones, region → method, time-zone sanity check
  services/hijri.dart                  Hijri date with moon-sighting adjustment
  theme/look.dart                      Night sky / Masjid designs, Lite mode
  widgets/islamic_icons.dart           Prayer mat (musalla) and crescent icons
  widgets/prayer_settings_card.dart    Method, madhab, mosque offsets with live preview
  widgets/appearance_card.dart         Design switch, Lite mode, Hijri adjust, delete account
  widgets/profile_form.dart            Name, gender, birth year, madhab, language, mosque, privacy
  widgets/women_card.dart              Private haid / nifas pause and rules
  widgets/circle_members_sheet.dart    Owner: join requests, ask-before-join, remove members
  screens/
    language_screen.dart               First screen: English / മലയാളം / العربية and text size
    onboarding_screen.dart             Profile setup on first open
    pending_screen.dart                Waiting for approval, or enter an invite code
    admin_screen.dart                  Super admin: approve / reject / remove people, invite codes
    auth_screen.dart                   Email -> 6-digit code sign in (optional invite code)
    home_shell.dart                    Bootstrap (location, notifications, nudge listener) + tabs
    dashboard_screen.dart              (a) Countdown + prayer cards
    circle_matrix_screen.dart          (b) Real-time accountability table + nudge buttons
    focus_timer_screen.dart            (c) 5-minute Khushu' timer
    journey_screen.dart                Level, XP, heatmap, badges, Qibla
    tasbih_screen.dart                 33/33/34 adhkar counter
    photo_proof_screen.dart            (d) Camera + timestamp watermark
    circle_manager_screen.dart         (e) Create / join with 6-digit code
assets/icon/niskaricho_icon.svg        App icon / logo
docs/notification_copy_ml.md           All Malayalam notification copy with English glosses
test/prayer_calculator_test.dart       Client vs server prayer-time agreement test
android/, ios/                         Platform projects with permissions already configured
```

## Gamification and community (v2)

XP and levels (Fajr 2×, +25 for a perfect day), a weekly circle league, a co-op Circle Quest, encouragement reactions, a Journey screen (heatmap, per-prayer strength, badge cabinet, Qibla), a Tasbih for adhkar, and celebration effects. The UI is a night-sky theme with glass cards, glowing prayer rings, and the sun's arc through the five prayers.

All XP, levels, leagues and quests are calculated on the server from verified `prayer_logs` (`get_my_progress`, `get_circle_leaderboard`, `get_circle_quest`), so there is nothing to farm with taps. Tasbih earns no XP on purpose. See [docs/feature_research.md](docs/feature_research.md) for the research behind these choices.

## How the anti-cheat works

The guiding rule is **the server is the source of truth**. The app can read prayer logs, but it cannot write them. Row Level Security has no INSERT/UPDATE policy on `prayer_logs`, and table privileges are revoked. Every check-in goes through a `SECURITY DEFINER` function that uses the database clock.

| Rule | Client side | Server side (`schema.sql`) |
|---|---|---|
| **No logging in advance** | "Pray Now" only appears while the server window is open; future prayers show a lock. The UI uses a server-corrected clock, so changing the phone's time does nothing. | `start_prayer()` recomputes the window from the user's stored location with `compute_prayer_times()` (an astronomical engine written in SQL) and rejects `outside_window`. A Qada date must be in the past (`window_not_closed`, `invalid_qada_date`). |
| **On-Time vs Qada decided once, forever** | Shows "Qada (late)" in focus mode. | `complete_prayer()` sets `on_time` only if the server's `started_at` fell inside the window. Otherwise it is `qada`. A logged prayer can't be re-logged (`already_logged`). `finalize_missed_prayers()` (pg_cron, every 10 min) marks closed windows as `missed`. |
| **5-minute minimum** | Done unlocks only when *both* a foreground-only monotonic stopwatch and server time since `started_at` reach 5:00. Leaving the app pauses it. Back is blocked. Screen stays awake. | `complete_prayer()` raises `focus_too_short` if `now() - started_at < 300 s` (and `session_expired` after 90 min). |
| **Moving to "where Asr hasn't ended"** | — | `set_my_location()` allows a real move only once per 6 hours and never while a session is open. Coordinates are hidden from peers through column privileges. |
| **Photo proof** | Live camera only (no gallery). Watermark with prayer + server-corrected time. | Insert-only storage bucket (no update/delete). `attach_photo_proof()` accepts the photo only if the storage object's server `created_at` is after the session started and within 10 min of completion. |
| **Nudge spam** | Button only shows in the last 20 minutes for friends who haven't started. | `send_nudge()` checks circle membership, the receiver's window, the 20-minute rule, and allows one nudge per sender, friend and prayer. |
| **Invite-code guessing** | — | `join_circle()` allows 10 wrong codes per hour. |

All limits live in the `app_config` table (5 min, 20 min, 6 h, and so on), so you can tune them without shipping an app update.

No system is cheat-proof. Someone can still start the timer and not pray. The aim is to remove the *one-tap lie* and the clock tricks, and let sincere friends keep each other honest.

### Prayer windows

| Prayer | Window |
|---|---|
| Fajr | Fajr → Sunrise |
| Dhuhr | Dhuhr (+1 min) → Asr |
| Asr | Asr → Maghrib |
| Maghrib | Maghrib → Isha |
| Isha | Isha → next Fajr |

The default is the **Karachi** method (18°/18°) with **Shafi'i** Asr, which is common in Kerala. Other options: **UAE (Dubai)** (matches the official UAE timetable), Muslim World League, Egyptian, North America (ISNA), Kuwait, and Hanafi Asr. Each member has their own location, time zone and method, so a family split between Kerala and Dubai each get their own windows, and the circle matrix shows every member's times in their local clock (`member_timezone`). The client (`adhan_dart`) and the server (SQL) use the same parameters. `test/prayer_calculator_test.dart` checks that they agree within 1 minute for Kozhikode, Kochi, Thiruvananthapuram and Dubai. `supabase/tests/03_reference_times.sql` prints the server's times for these cities.

## Try it in Chrome first (demo mode)

Run without Supabase keys and the app starts in demo mode with a sample circle. See [RUN_LOCALLY.md](RUN_LOCALLY.md): either open the prebuilt `niskaricho-web-demo.zip`, or run `flutter run -d chrome`.

## Setup

### 1. Supabase

1. Create a project at [supabase.com](https://supabase.com) (the free tier is enough).
2. **Database → Extensions:** enable `pg_cron`.
3. **SQL Editor:** paste the whole `supabase/schema.sql` and run it. It creates the tables, RLS, RPCs, the `prayer-proofs` storage bucket, realtime publication and the cron job.
4. **Authentication → Providers → Email:** keep it enabled. Under **Email Templates → Magic Link**, include `{{ .Token }}` so users receive a 6-digit code.
5. **Project Settings → API:** copy the Project URL and the publishable (anon) key.

### 2. Flutter app

Requires Flutter 3.50+ (Dart 3.14+).

```bash
flutter pub get
flutter test                    # prayer-time agreement tests
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Android permissions (location, camera, notifications, exact alarms, boot receiver) and core-library desugaring are already set up in `android/app`. iOS usage strings for location and camera are already in `ios/Runner/Info.plist`. For iOS, run `cd ios && pod install` once.

### 3. Launcher icons

`assets/icon/niskaricho_icon.svg` is the master logo. Export a 1024×1024 PNG from it (Figma, Inkscape, or `rsvg-convert -w 1024`) and generate the platform icons with [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons).

## Works anywhere (v3)

- **Location:** GPS, re-checked every 15 minutes and whenever the app comes back to the foreground. A move goes to `set_my_location`, which allows one real move every 6 hours (anti-cheat) and never during an open prayer.
- **Time:** the server's clock decides everything. The phone's clock is ignored, and the phone's time zone only affects dates and how times are displayed. If it doesn't match the GPS location, the app shows a warning.
- **Method:** `method_auto` picks the local method from the time zone (`_method_for_timezone` in SQL, `methodForTimezone` in Dart). It covers Karachi (India/Kerala), UAE, Umm al-Qura (Saudi), Qatar, Kuwait, Singapore/Malaysia, Indonesia, Turkey, Egypt, Morocco, Jordan, ISNA (Americas) and MWL (elsewhere). Users can fix a method instead.
- **High latitudes:** where twilight never ends (UK, Scandinavia in summer), Fajr/Isha use the "middle of the night" rule, same as adhan.
- **Mosque offsets:** `minute_offsets` moves each prayer by up to ±10 minutes. `set_prayer_settings` rate-limits changes to method, madhab and offsets to once per 6 hours. The app previews new times locally before saving, so people can try values freely.
- **Account deletion:** `delete_my_account()` removes the user and their data, and hands their circles to another member. This is required by Google Play and the App Store.

## Profile, women's exemptions, invite-only access, three languages (v4)

**Profile on first open.** Name, gender, year of birth (private), madhab, app language, home mosque, and "keep my prayers private in circles". All editable later in Journey → *My profile*. Age notes: under 7 not asked to pray; 7 to 14 practice years (duty at puberty, at the latest 15 lunar years); under 18 asked to involve a parent.

**Haid and nifas (women only, private).** Journey → *Haid and Nifas*. Prayers in that time are *excused*: never missed, no qada, and the streak is paused, not broken. The server enforces the limits (haid at most 15 days, Hanafi 10; nifas at most 60, Hanafi 40; 15 days of purity between periods, otherwise istihada and salah is due). When bleeding stops, the prayer of that time is due; Shafi'i: stopping in Asr time also makes Dhuhr due, in Isha time Maghrib. Circles only ever see **Not shared**, the same as anyone who hides their status, so nothing reveals a period or a pregnancy. Illness never excuses salah (pray sitting or lying), so it has no switch. Travel shortening (qasr and jam') is shown as the next item to build.

**Invite-only access.** The first account on a fresh database becomes the super admin. Everyone else starts as *pending* and can only set up their profile until an admin approves them, or until they use an invite code (8 characters, 1, 5 or 20 uses, 1, 7 or 30 days, can be stopped any time). Admins approve, reject, remove (takes the person out of every circle) and make other admins in Journey → *Admin*. Circle owners approve join requests (on by default) and remove members from the circle screen. All of it is checked again on the server (schema section 17): a pending account cannot log prayers, create or join circles, nudge or react.

To make an existing account the super admin, run once in the Supabase SQL editor:
```sql
update public.profiles set is_admin = true, access_status = 'approved'
 where id = (select id from auth.users where email = 'YOUR EMAIL');
```

**Three languages.** English, Malayalam and Arabic, chosen on the first screen and changeable in Journey → *Language*. Arabic is fully right to left. Every screen, error, notification and onboarding step goes through `tr()`, and `test/l10n_test.dart` fails if any phrase is missing in Malayalam or Arabic. Text size is Large by default (Normal / Large / Extra large), and main buttons are at least 56 px tall. The Malayalam and Arabic need a native speaker's check: see `docs/translation_review.md`.

## Performance and old phones

- **Minimum versions:** Android 7.0 (API 24) and iOS 15, the Flutter 3.50 defaults.
- **Lite mode** (Journey → Appearance) and the phone's reduce-motion setting both turn off blur, the animated sky and entrance animations. These are the main costs on low-end GPUs. The **Masjid** design is always still.
- **Release builds:** publish an app bundle (`flutter build appbundle`), or `flutter build apk --split-per-abi` for direct APKs, so each phone downloads only its own CPU build.
- **Photo retention (next step):** proof photos are insert-only for anti-cheat. Add a scheduled Edge Function with the service role that deletes photos after 72 hours and those of deleted accounts.

## Notifications

- **Adhan** and **"20 minutes left"** alerts are scheduled locally for today and tomorrow with exact alarms, calculated offline from GPS. They work with no internet.
- **Friend nudges** arrive over Supabase Realtime and show instantly while the app is running or in recent background.
- **Next step for background nudges:** to deliver nudges when the app is fully closed, add Firebase Cloud Messaging plus a small Supabase Edge Function triggered on `INSERT` into `nudges`. The schema already provides everything the function needs.

All Malayalam copy is in [`docs/notification_copy_ml.md`](docs/notification_copy_ml.md).

## What was verified

- `schema.sql` was run against PostgreSQL 16 with a mock of Supabase's `auth` and `storage` schemas. Tests covered: Pray Now inside and outside the window, early completion rejected, direct table writes denied, On-Time vs Qada, location cooldown, invite join with a wrong code, peers can't read coordinates, outsiders can't see the circle, photo attach, nudge rules and duplicate nudges, and missed-prayer finalization.
- The SQL prayer engine matches `adhan_dart` to within a few seconds (Raleigh, 12 Jul 2015, ISNA; Kozhikode, 20 Nov 2026, Karachi).
- `flutter analyze` reports no issues and `flutter test` passes (Flutter 3.50.1).
- **Not yet done:** a build or run on a real Android or iOS device, or against a live Supabase project.

## License

MIT, see [LICENSE](LICENSE). Circles everywhere are welcome to fork it.
