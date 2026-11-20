# v4 research: profile, women's exemptions, access control, languages

## Fiqh used (Shafi'i first, Hanafi where it differs)

| Topic | Rule | What the app does |
|---|---|---|
| Haid length | Shafi'i: at least a day and night, usually 6 to 7 days, at most 15. Hanafi: 3 to 10. | Server stops counting a period after 15 days (Hanafi 10). After that, salah is due again (istihada). |
| Purity between periods | At least 15 days. | A new haid within 15 days of the last one is refused (`purity_gap`) and the app explains it is istihada. |
| Nifas | Shafi'i at most 60 days, usually 40. Hanafi at most 40. | Server cap 60 (Hanafi 40). |
| Prayers during haid / nifas | Not owed, and no qada. | Marked *excused*: never missed, no Pray Now, no Qada, streak paused not broken. |
| Bleeding starts after the time began | Shafi'i: owed if there was time to pray it. | The prayer stays owed unless bleeding began within 5 minutes of the time starting. |
| Bleeding stops | The prayer of that time is due (ghusl first). Shafi'i: stopping in Asr time makes Dhuhr due too; in Isha time, Maghrib too. Hanafi: only the current prayer. | Applied on the server and in the demo; the app says which prayers are due. |
| Istihada | Pray, with wudu for each prayer. | Shown in the rules and the `purity_gap` message. |
| Illness | Never removes salah; pray sitting or lying. Unconscious for a whole prayer time: no qada (Shafi'i). | No illness switch on purpose. |
| Travel (qasr, jam') | Shafi'i about 81 km, under 4 days' stay, jam' allowed. Hanafi about 77 km, under 15 days, qasr required, no jam'. Fajr and Maghrib are never shortened. | **Not built yet** (next item). |
| Age | Duty at puberty, at the latest 15 lunar years. Children taught at 7, firmer at 10. | Profile age notes; under 18 asked to involve a parent. |
| Privacy | Her choice who knows; the family should not be able to tell (including pregnancy). | Circles see "Not shared", the same as anyone who hides their status. History is readable only by her (RLS). |

These are general rules; the app says to ask a trusted scholar for one's own case. No Samastha-specific source was found online; the Shafi'i rules above are the standard ones taught in Kerala.

## Access control (early phase)

Invite-only with a super admin, pending approval, revocable invite codes with limited uses and expiry, and circle owners approving joins. Enforced in Postgres (schema section 17) and tested in `supabase/tests/07_access_checks.sql`.

## Languages

English, Malayalam and Arabic (right to left), chosen on the first screen. Large text by default. Malayalam and Arabic need native review (`docs/translation_review.md`).

## Still pending (in order)

1. **Travel prayers:** a "travelling" switch showing qasr (Dhuhr, Asr, Isha as 2 rak'ah) and jam' per madhab, with the distance and day limits.
2. **Child / training mode:** for ages 7 to 14, gentle reminders, no streak pressure, parent can see progress.
3. **Native review** of Malayalam and Arabic.
4. **Ramadan mode:** suhoor and iftar times, taraweeh tracking.
5. **Voice adhan** choice and a "silent at work" schedule.
6. **Backup sign-in** by phone number (many older users have WhatsApp but rarely check email).
