# Run Niskaricho? on your computer (Chrome)

With no Supabase keys, the app runs in **demo mode**. It has a sample **Family** circle spread across places: Ameen in **Dubai**, Fathima in **Kochi**, Rashid in **Thiruvananthapuram**, Shabna in **Kannur**. Your own times come from your browser's location (or Kozhikode if you don't share it). The focus timer is shortened to 20 seconds. Nothing is saved: refreshing the page resets the demo.

## Option A: open the ready-made build (about 2 minutes, no Flutter needed)

1. Download and unzip **`niskaricho-web-demo.zip`**.
2. Start the little local server inside the unzipped folder:
   - **Windows:** double-click `start.bat`
   - **Mac or Linux:** open Terminal in the folder and run `sh start.sh`

   Both need Python. If it isn't installed, get it from python.org; on Windows, tick "Add Python to PATH" during setup.
3. Open **http://localhost:8080** in Chrome.
4. Optional: press F12, click the phone icon (device toolbar) and pick a phone size so it looks like the mobile app.

Double-clicking `index.html` won't work. Flutter web apps have to be served over http, which is why you need the start script.

## Option B: run from source with Flutter (for development)

1. Install Flutter 3.50 or newer by following https://docs.flutter.dev/get-started/install. Choose the "Web" target; Android Studio and Xcode aren't needed for this.
2. Check the install: `flutter doctor` should show Chrome as available.
3. Unzip **`niskaricho.zip`**, then in a terminal:
   ```bash
   cd niskaricho
   flutter pub get
   flutter run -d chrome
   ```
   This opens Chrome with demo mode. Press `r` in the terminal to hot-reload after you edit code.

## Things to try in the demo

| Where | What to check |
|---|---|
| **Today** tab | The countdown for the current prayer. Future prayers show a lock, because you can't log in advance. A finished prayer you skipped shows **Log Qada**. |
| **Pray Now** | A black focus screen with Malayalam and English reflections. **Done** stays locked until the timer ends (20 s in the demo, 5 min in the real app). Back is blocked; Cancel asks first. |
| **Photo proof** | Shows after praying, because "Hostel Room 4" has photo mode on. On a laptop with no camera, tap the camera button to use a sample photo. Check the timestamp watermark. |
| **Circles** tab | Create a circle, or join with code **123456** (any other code is rejected). The ⋮ menu has copy invite, photo mode and new code. |
| **Family** / **Hostel Room 4** | The live matrix. Under each name is that person's own clock and city. Tap 👋 **Nudge** on a friend who hasn't prayed. Wait about 25 s and Fathima's "praying" turns 🟢 live. Tap a 📸 to see a photo. |
| **Celebrations** | Finish a prayer and you get confetti with "+XP". A level-up or a perfect 5/5 day gets a bigger moment. |
| **Weekly league** | In a circle, switch to **Weekly league**: XP rankings that reset every Monday. |
| **Circle Quest** | The purple card at the top of a circle: a shared weekly goal. |
| **Reactions** | Tap a friend's completed (🟢/🟡) prayer to see their photo and send 🤲 ❤️ 🔥 🌟. |
| **Journey** tab | Level orb, streaks, 5-week heatmap, on-time strength per prayer, badge cabinet (hold a badge to see how to earn it), and the Qibla compass. |
| **Tasbih** | From the Today tab: tap the orb for 33/33/34 adhkar after salah. |

## Test checklist: is the time right for everyone?

Each person's prayer windows are calculated from **their own** location, time zone and method, on the server, using the server's clock. Changing the phone's clock does nothing.

1. **Your own times.** Open the **Today** tab. Under *TODAY'S PRAYERS* you'll see where the times are for, e.g. `📍 Kozhikode · UTC+5:30 · Karachi`. Compare with the table below (a 1-minute difference is rounding).
2. **Only the current prayer is open.** The current prayer has **Pray Now**; later ones show a 🔒; an earlier one you skipped shows **Log Qada**.
3. **Family in other places.** Circles → **Family**. Each row shows that person's local time, e.g. `🕐 5:50 PM in Dubai (UTC+4)` while Kerala rows show 7:20 PM. Ameen in Dubai is on a different prayer than the Kerala members at the same moment. Tap any circle in his row to see his window in Dubai time *and* in your time.
4. **Pretend you are somewhere else.** Journey tab → *Prayer time settings* → **Demo: pretend I am in…** → Dubai. The Today tab switches to Dubai times and the UAE method.
5. **Or fake it in Chrome (closest to real life).** Press F12 → ⋮ (top right of DevTools) → *More tools* → **Sensors**. Set *Location* to *Other…* with latitude `25.2048`, longitude `55.2708`, and *Timezone ID* `Asia/Dubai`. Keep DevTools open, reload the page and click **Allow** for location. The app now behaves like a phone in Dubai. For Kochi use `9.9312`, `76.2673`, `Asia/Kolkata`.
6. **Method.** Kerala uses **Karachi + Shafi'i**; UAE uses **UAE (Dubai)**. If your local mosque's timetable is a few minutes different, change the method in *Prayer time settings*.

### Expected times for Friday 20 November 2026

| Place | Method | Fajr | Sunrise | Dhuhr | Asr | Maghrib | Isha |
|---|---|---|---|---|---|---|---|
| Kozhikode | Karachi | 5:11 | 6:25 | 12:13 | 3:32 | 6:00 | 7:14 |
| Kochi | Karachi | 5:08 | 6:21 | 12:11 | 3:31 | 6:00 | 7:13 |
| Thiruvananthapuram | Karachi | 5:03 | 6:16 | 12:09 | 3:29 | 5:59 | 7:12 |
| Kannur | Karachi | 5:14 | 6:28 | 12:15 | 3:33 | 6:00 | 7:14 |
| Malappuram | Karachi | 5:10 | 6:24 | 12:12 | 3:31 | 5:59 | 7:13 |
| Dubai | UAE (Dubai) | 5:19 | 6:36 | 12:07 | 3:09 | 5:33 | 6:50 |

Checked against published timetables: Dubai matches the official UAE times (5:18, 6:35, 12:07, 3:09, 5:33, 6:50) within a minute, and Kozhikode matches timesprayer.com (Karachi, Shafi'i) within a minute for Fajr to Asr. For Maghrib and Isha the app is up to 2 minutes later than that site, which is the safe side, since Maghrib must not be prayed before sunset. Times change by about a minute a day, so on another day compare with your mosque or a site such as IslamicFinder using the same method.

## New in this version: works anywhere, two designs, old phones

| Try | What should happen |
|---|---|
| **Automatic local method** | With location shared, Journey → *Prayer time settings* shows **Automatic: …** for your region (Kerala → Karachi, UAE → UAE (Dubai), Saudi → Umm al-Qura, Qatar, Malaysia, Turkey, UK → MWL, USA → ISNA…). Try Sensors with Makkah `21.4225, 39.8262, Asia/Riyadh`. |
| **Travel** | Change the Sensors location while the app is open, then switch to another tab and back. A message says a new place was detected and the times follow it. (On the real server you can move once every 6 hours, so nobody can hop to a city where Asr hasn't ended.) |
| **Wrong phone time zone** | Set Sensors location to London but Timezone ID to `Asia/Kolkata`. A red bar explains the phone's time zone looks wrong. Prayer times stay correct, because they come from GPS and the server clock. |
| **Match your mosque** | In *Prayer time settings*, tap + / − next to a prayer. The time on the right updates live. Press **Save**. (Real app: once every 6 hours, ±10 minutes max.) |
| **Hijri date and Jumu'ah** | Under the title on Today. On Fridays Dhuhr shows as **Jumu'ah**. Adjust the Hijri date ±2 days in Journey → *Appearance* to match your local moon sighting. |
| **Second design** | Journey → *Appearance* → **Masjid** (geometric pattern, calm, no animation). Switch back to **Night sky** any time. |
| **Lite mode** | Journey → *Appearance* → *Lite mode*: no blur or moving background, for older phones. It also turns on by itself when the phone's "remove animations" accessibility setting is on. |

## New in v4: profile, haid and nifas, admin, three languages

| Try | What should happen |
|---|---|
| **Language first** | A fresh browser shows English / മലയാളം / العربية with big buttons and a text size choice (A, A+, A++). Pick العربية: every screen is in Arabic and right to left. Change it later in Journey → *Language*. To see the first screen again, open the page in a private window. |
| **Profile setup** | After the language, set your name, gender and so on, then *Continue*. It is remembered in this browser. Edit it in Journey → *My profile*. |
| **Haid / nifas** | Choose *Female* in the profile. Journey → *Haid and Nifas* → *Haid started*. Today shows a private note and prayers from then on are excused (🤍, no Pray Now, no Qada). *Bleeding has stopped* tells you which prayer is due. |
| **What the family sees** | Circles → *Family*: Shabna shows 🤍 **Not shared**, never the reason. |
| **Admin** | Journey → *Admin* (you are the super admin in the demo). Approve or reject Sameer, remove someone, make a new invite code (it is copied for WhatsApp), stop a code. The eye icon shows what a new person sees while waiting. |
| **Circle owner** | Circles → *Hostel Room 4* → the people icon at the top: accept Junaid's request, turn *Ask me before people join* off or on, remove a member. |
| **Join flow** | Circles → *Join with code*: `123456` sends a request (you wait for the owner), `654321` joins straight away. |

## Connecting the real backend later

Run `supabase/schema.sql` in your Supabase project (see README), then:
```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_KEY
```
On the web, Adhan and 20-minute alerts are mobile-only. Those need the Android or iOS app.
