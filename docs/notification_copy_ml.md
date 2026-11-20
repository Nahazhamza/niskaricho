# Niskaricho? — Malayalam notification copy

Warm, everyday Kerala Malayalam, the way a friend or a family elder would say it. Each line has an English gloss. The app picks one message at random each time so reminders don't feel robotic. The source of truth in code is `lib/l10n/ml_strings.dart`.

Prayer names follow common Kerala usage: സുബ്ഹ് (Fajr), ളുഹർ (Dhuhr), അസർ (Asr), മഗ്‌രിബ് (Maghrib), ഇശാ (Isha).

## 1. Adhan (window opens)

**Title pattern:** `<prayer> ബാങ്ക് 🕌 · <English> time`

| Prayer | Malayalam | English |
|---|---|---|
| Fajr | സുബ്ഹ് ബാങ്ക് കൊടുത്തു. ഉറക്കത്തേക്കാൾ ഉത്തമം നിസ്കാരമാണ് 🌅 | The Subh adhan has been called. Prayer is better than sleep. |
| Fajr | അസ്സലാത്തു ഖൈറും മിനന്നൗം. എഴുന്നേൽക്കൂ, സുബ്ഹിന്റെ സമയമായി. | "Prayer is better than sleep." Wake up, it's time for Subh. |
| Fajr | പുലരിയുടെ ബറകത്ത് നിസ്കാരത്തോടെ തുടങ്ങാം 🤲 | Let's begin the blessing of dawn with prayer. |
| Dhuhr | ളുഹർ സമയമായി. ജോലിക്കിടയിൽ അല്ലാഹുവിനായി ഒരു ചെറിയ ഇടവേള ☀️ | It's Dhuhr time. A short break for Allah in the middle of work. |
| Dhuhr | ക്ലാസും ഓഫീസും ഒന്ന് നിർത്താം, ളുഹർ നിസ്കരിക്കാം. | Pause class or the office for a moment and pray Dhuhr. |
| Asr | അസർ സമയമായി. വൈകുന്നേരത്തെ തിരക്കിൽ മറക്കല്ലേ 🌤️ | It's Asr time. Don't forget it in the evening rush. |
| Asr | അസർ നിസ്കാരം കാത്തിരിക്കുന്നു. ഇപ്പോൾ തന്നെ ആവാം. | Asr is waiting. Let's do it right now. |
| Maghrib | മഗ്‌രിബ് ബാങ്ക് കൊടുത്തു. സമയം കുറവാണ്, വേഗം നിസ്കരിക്കാം 🌇 | Maghrib adhan has been called. The window is short, pray soon. |
| Maghrib | സൂര്യൻ അസ്തമിച്ചു. മഗ്‌രിബിന്റെ സമയമായി. | The sun has set. It's Maghrib time. |
| Isha | ഇശാ സമയമായി. ദിവസം നിസ്കാരത്തോടെ അവസാനിപ്പിക്കാം 🌙 | It's Isha time. Let's end the day with prayer. |
| Isha | ഉറങ്ങുന്നതിന് മുൻപ് ഇശാ നിസ്കരിച്ചോ? | Did you pray Isha before sleeping? |

## 2. Urgent: 20 minutes before the window closes

**Title:** `⏰ <prayer> സമയം തീരാൻ 20 മിനിറ്റ്` (20 minutes left for <prayer>)

| Malayalam | English |
|---|---|
| `<prayer>` ഇനിയും നിസ്കരിച്ചില്ലേ? ഖളാ ആകുന്നതിന് മുൻപ് വേഗം! | Still haven't prayed `<prayer>`? Hurry before it becomes Qada! |
| സമയം കഴിയാറായി. ഇപ്പോൾ നിസ്കരിച്ചാൽ "On-Time" ആയി കിട്ടും 🟢 | Time is almost up. Pray now and it still counts as On-Time. |
| ഒരു 5 മിനിറ്റ് മതി. `<prayer>` നിസ്കരിക്കാം, ഇൻ ഷാ അല്ലാഹ്. | Just 5 minutes. Let's pray `<prayer>`, in sha Allah. |

## 3. Friend nudges

**Title:** `<friend> നിങ്ങളെ ഓർമ്മിപ്പിച്ചു 👋` (<friend> reminded you)

| Malayalam | English |
|---|---|
| **അസർ സമയമായി, നിസ്കരിച്ചോ?** (`<prayer>` സമയമായി, നിസ്കരിച്ചോ?) | It's Asr time, did you pray? |
| ഡാ, `<prayer>` കഴിഞ്ഞോ? സമയം തീരാറായി 😊 | Hey, done with `<prayer>`? Time's nearly up. |
| നമ്മുടെ സർക്കിൾ മുഴുവൻ `<prayer>` പൂർത്തിയാക്കാം. നീ കൂടി വാ! 🤝 | Let's get the whole circle through `<prayer>`. Come on, join us! |
| ദുആയിൽ ഓർക്കണേ, `<prayer>` നിസ്കരിക്കാൻ മറക്കല്ലേ 🤲 | Remember me in your dua, and don't forget to pray `<prayer>`. |

"ഡാ" is casual and friendly among peers. For a family circle, swap it for "മോനേ / മോളേ" or drop it.

## 4. Positive reinforcement

| When | Malayalam | English |
|---|---|---|
| After a prayer is logged | അൽഹംദുലില്ലാഹ്! അല്ലാഹു സ്വീകരിക്കട്ടെ 🤲 | Alhamdulillah! May Allah accept it. |
| Streak 1–6 days | 🔥 N ദിവസം. നല്ല തുടക്കം! | N days. A great start! |
| Streak 7+ days | 🔥 N ദിവസം തുടർച്ചയായി 5/5. അൽഹംദുലില്ലാഹ്! | N days of 5/5 in a row. Alhamdulillah! |
| Streak 40+ days | 🔥 N ദിവസം! 40 ദിവസം തുടർച്ചയായി. മാഷാ അല്ലാഹ്! | N days! Forty days straight. Masha Allah! |
| Full Circle Fajr | മാഷാ അല്ലാഹ്! സർക്കിളിലെ എല്ലാവരും സുബ്ഹ് സമയത്ത് നിസ്കരിച്ചു 🌅🤝 | Masha Allah! Everyone in the circle prayed Subh on time. |

## 5. Khushu' reflections (Focus Mode)

| Malayalam | English |
|---|---|
| നിസ്കാരത്തിൽ ഭക്തിയുള്ളവർ വിജയിച്ചിരിക്കുന്നു. | Successful indeed are the believers, those who humble themselves in prayer. (23:1-2) |
| നീ അല്ലാഹുവിനെ കാണുന്നത് പോലെ ആരാധിക്കുക. നീ അവനെ കാണുന്നില്ലെങ്കിലും അവൻ നിന്നെ കാണുന്നു. | Worship Allah as if you see Him; and if you do not see Him, He surely sees you. |
| ഇതാണ് നിന്റെ അവസാന നിസ്കാരം എന്ന പോലെ നിസ്കരിക്കുക. | Pray as though it is your farewell prayer. |
| ക്ഷമയും നിസ്കാരവും കൊണ്ട് സഹായം തേടുക. | Seek help through patience and prayer. (2:45) |
| അറിയുക, അല്ലാഹുവിനെ കുറിച്ചുള്ള സ്മരണ കൊണ്ടാണ് ഹൃദയങ്ങൾ ശാന്തമാകുന്നത്. | Verily, in the remembrance of Allah do hearts find rest. (13:28) |
| ഫോൺ മാറ്റിവെക്കൂ. ഇപ്പോൾ നീയും നിന്റെ റബ്ബും മാത്രം. | Put the phone down. Right now it is only you and your Lord. |

> Please have a native speaker from your community review the wording and the Qur'an/hadith translations before release; regional phrasing varies across Kerala.
