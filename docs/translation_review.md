# Malayalam and Arabic: please review

The app is fully translated into Malayalam and Arabic (409 phrases each, plus the
notification messages and Focus Mode reflections). The text was written in plain,
short sentences for older users, but it was **not** written by a native speaker.
Before sharing widely, please ask one Malayalam reader and one Arabic reader to
go through it.

## Where the text lives

| File | What |
|---|---|
| `lib/l10n/ml.dart` | Malayalam for every screen, button and error. English on the left, Malayalam on the right. |
| `lib/l10n/ar.dart` | Arabic (simple Modern Standard Arabic), same layout. |
| `lib/l10n/copy.dart` | Notifications (adhan, 20 minutes left, reminders from the circle) and Focus Mode reflections in all three languages. Quran and hadith are in their original Arabic. |

## How to review

1. Open the demo, choose the language on the first screen, and use every tab.
2. Note anything that sounds odd, too formal, or hard for an elderly person.
3. Change the text on the right-hand side in `ml.dart` or `ar.dart`. Keep anything in `{curly brackets}` exactly as it is: the app fills those in (names, times, numbers).
4. Run `flutter test`. It fails if a phrase is missing or a `{placeholder}` was changed by mistake.

## Things worth a careful look

* **Fiqh terms** (haid, nifas, istihada, ghusl, qada, qasr): Malayalam uses the words common in Kerala madrasas (ഹൈള്, നിഫാസ്, ഇസ്തിഹാള, കുളി / ഗുസ്ൽ, ഖളാ). Please check they match what your family says.
* **Women's rules** (Journey → Haid and Nifas → *How the app applies the rules*): the wording must stay accurate. Shafi'i and Hanafi versions are separate.
* **Arabic for women:** messages addressed to a woman use the feminine form (for example صلّي، توضئي).
* **The app name in Arabic** is shown as «هل صلّيت؟» ("Did you pray?") rather than a transliteration.
* **Polite form in Malayalam:** the app uses നിങ്ങൾ throughout, never നീ, except inside the Quran and hadith reflections where the original addresses "you" directly.
