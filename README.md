# La Marelle des Mots (Flutter)

Flash-card reading game with a mascot. Port of the HTML V1, plus:

- **Cumulative lessons**: pick "Lecture 7" in the settings and lessons 3 to 7 are all in the deck
  (switch "Cumulatif" off to tick lessons one by one).
- **Swipe**: right (or tap) = "je le sais", left = "encore" (the word comes back a few cards later).
- **Mascot**: hides behind the card, peeks out, reacts to every swipe, can be poked.

## First run on your Mac

```bash
# 1. create the native iOS project once
flutter create --platforms=ios --org com.biobrix --project-name marelle_des_mots marelle_des_mots
cd marelle_des_mots

# 2. unzip this archive over it (overwrites lib/, pubspec.yaml, test/, assets/ ...)
unzip -o ../marelle_des_mots.zip -d .

# 3. go
flutter pub get
flutter test            # 12 small logic tests
flutter run             # pick your iPhone (or a simulator)
```

Fonts (Baloo 2 and Nunito) are downloaded by the `google_fonts` package the first time the app
runs online and cached after that. Bundle the font files in `assets/fonts/` before sharing with
friends so it also works the very first time offline.

## Adding word lists

Everything lives in `assets/data/lessons.json`. Add one entry to `"lessons"`:

```json
{ "id": "lecture11", "number": 11, "title": "Lecture 11", "words": ["mot", "autre", "..."] }
```

The settings sheet shows a chip for every lesson in that file; no code to change.
(`python3 tool/extract_lists.py your.html` rebuilds the file from the old HTML if you prefer to
keep editing the lists there.)

Cumulative decks: a word that an earlier selected lesson already contains is not added again, so
"le", "il", "a" do not take over. Repeats *inside* a lesson are kept, as in V1.

## The mascot

Strips live in `assets/sprites/` and are named `clipname_framecount.png`
(frames side by side, bottom-aligned, transparent). The app reads the folder: drop a file in and it is used.

| Name starts with | Played when |
| --- | --- |
| `idle` / `idle_blink` | resting loop / random blink |
| `know_` | swipe right or tap (a random one, never the same twice in a row) |
| `again_` | swipe left |
| `poke_` | tap on the mascot |
| `streak_cheer` | every 5 known words in a row (if the file exists) |

The strips in there now were cut from your otter sheet by `tool/slice_otter_sheet.py` as stand-ins.
Delete them when your own art is ready.

`tool/make_sounds.py` regenerates the five sounds in `assets/audio/`; replace any file by a recording.
