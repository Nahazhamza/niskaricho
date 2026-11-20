# Feature research: what similar apps do, and what Niskaricho? took from them

I looked at three groups of apps: Muslim prayer apps (Pillars, Muslim Pro, Deen Tracker, Qaza/Qadha trackers, Sajdah, Tqwa), social prayer and habit apps (Prayway, Pray with Friends, PRAYR), and the best-known gamified habit app, Duolingo.

## What the market does

| Pattern | Seen in | Takeaway |
|---|---|---|
| Prayer times, Qibla, ad-free and privacy-first | Pillars, Muslim Pro | Qibla and clean, ad-free design are basic expectations. |
| Personal prayer log with stats and history | Deen Tracker, Sajdah, Tqwa, Pillars | A calendar heatmap and a per-prayer on-time rate are the most-used views. |
| Qada (missed prayer) tracking | Qaza Qada, Qadha Tracker | Qada should be logged without shame and still count for something. |
| Streaks | Prayway and most habit apps | Streaks drive return visits. |
| Praying with friends | Pray with Friends, PRAYR | A small, trusted group works better than a public feed. |
| XP, levels, weekly leagues, friend quests, celebrations | Duolingo | Leagues reset weekly so everyone can compete again. Co-op "friend quests" and celebration moments are what make it feel playable. |
| Tasbih counter after salah | Muslim Pro and many others | The natural next step right after prayer. |

## The gap Niskaricho? fills

Almost every tracker trusts a single tap. None of them verify the time window or the duration on a server. Niskaricho? keeps that integrity, and every game element is built on top of verified data. Nothing can be earned with a tap.

## What was added in this upgrade

| Feature | Inspired by | Anti-cheat |
|---|---|---|
| **XP and levels** (Seeker → Pillar of the Circle), Fajr 2× XP, +25 perfect-day bonus | Duolingo XP | XP is calculated on the server (`get_my_progress`) from `prayer_logs`, which only the verified RPCs can write. |
| **Weekly circle league** that resets every Monday | Duolingo leagues | Server-side `get_circle_leaderboard`. |
| **Circle Quest**: together, pray 80% on time this week | Duolingo friend quests | Server-side `get_circle_quest`. Cooperative rather than competitive. |
| **Encouragement reactions** (🤲 ❤️ 🔥 🌟) on friends' completed prayers | Social apps | `react_to_log` checks circle membership. You can't react to your own prayer, only to completed ones, and only from an allowed set of emoji. |
| **Journey screen**: level orb, streak stats, 5-week heatmap, on-time strength per prayer with a "focus area" tip, badge cabinet | Pillars and Deen Tracker stats | Read-only. |
| **Qibla direction** with an animated compass | Pillars, Muslim Pro | Calculated offline with `adhan_dart`. |
| **Tasbih** for the adhkar after salah (33/33/34) | Muslim Pro | Deliberately gives **no XP**: it can't be verified, and dhikr is personal. |
| **Celebrations**: confetti, "+XP", level-up and perfect-day moments | Duolingo | Display only. |
| **Futuristic UI**: animated night sky with aurora and stars, glass cards, glowing prayer rings, the sun travelling an arc through the five prayers, neon progress bars, haptic buttons, staggered entrance animations | — | — |

## Ideas for later

- **Background push for nudges** (FCM plus an Edge Function on `nudges` inserts).
- **Home-screen widgets** for the next prayer and today's rings. Pillars users love these.
- **Jumu'ah mode**: a Friday reminder and a Kahf checklist.
- **Ramadan mode**: Taraweeh and fasting tracker, with suhoor and iftar times.
- **Live compass** using the phone's magnetometer (sensors_plus).
- **Qada plan**: a calculator to make up past missed prayers, with a gentle daily target.
- **Streak shield**: a family-approved pause for illness or travel. Needs scholarly input before it's built.

## Sources

- [Pillars: Prayer Times & Qibla](https://chrome-stats.com/d/id1559086853) · [Pillars alternatives (fiveprayer.app)](https://www.fiveprayer.app/alternatives/pillars)
- [Muslim Pro / Muslim: Ramadan 2026, Azan](https://apps.apple.com/us/app/-/id1137963102) · [Deen Tracker](https://apps.apple.com/app/id6449619738) · [Sajdah: Muslim Prayer Tracker](https://apps.apple.com/app/id6748613025) · [Prayer Tracker, Journal: Tqwa](https://apps.apple.com/app/id6757415815)
- [Qaza Qada: Missed Salah](https://apps.apple.com/app/id6757791803) · [Qadha Tracker](https://apps.apple.com/us/app/-/id6760733053) · [Muslim Prayer Challenge](https://apps.apple.com/us/app/-/id6749324214)
- [Prayway: Prayer Streak App](https://apps.apple.com/app/id6759345089) · [Pray with Friends](https://apps.apple.com/us/app/-/id6744947460) · [PRAYR](https://apps.apple.com/us/app/-/id6754390428)
- [Duolingo: How the $15B app uses gaming principles (Deconstructor of Fun)](https://www.deconstructoroffun.com/blog/2025/4/14/duolingo-how-the-15b-app-uses-gaming-principles-to-supercharge-dau-growth) · [How the Duolingo streak builds habit](https://blog.duolingo.com/how-duolingo-streak-builds-habit) · [Duolingo gamification and loyalty (Open Loyalty)](https://openloyalty.io/insider/how-duolingos-gamification-mechanics-drive-customer-loyalty)
