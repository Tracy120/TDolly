# TeacherDolly (Offline Pre-K & K) — Flutter Demo

Date: March 03, 2026

This project is a **fully offline** learning app structure for **Pre‑K (Age 3–4)** and **Kindergarten (Age 5–6)**.

## What is included (offline)

- **Path mode** (Worlds → Units → Lessons) with unlock progression
- **English & French** curriculum (switch anytime)
- **Voice guidance** toggle (Text‑to‑Speech) with kid‑friendly pacing
- **Subjects** (Pre‑K & K):
  - Early Literacy / Phonics
  - Math
  - Science
  - Social‑Emotional Learning
  - Art & Creativity
  - Music & Rhythm
- **Worksheets** (offline templates) with a **Worksheet Builder**
  - Generates a simple PDF worksheet (letters, counting, matching)
- **Games** (offline data + playable logic)
  - Matching
  - Sorting
  - Simple Quiz
- **Reading Month** (monthly themes + book list + reading goals)

> Note on voice: A “Rachel” voice depends on the voices installed on the device (Android/iOS).  
> The app **tries to pick a female English voice when available**, and you can still use TTS with a natural pace.  
> If “Rachel” exists on the device, it will be selectable automatically.

---

## How to run

1. Install Flutter and set up an emulator/device.
2. From this folder:
   ```bash
   flutter pub get
   flutter run
   ```

---

## Project structure (open paths)

You can inspect everything. Main parts:

```
lib/
  main.dart
  models/
    content_models.dart
  services/
    lesson_repository.dart
    progress_store.dart
    tts_service.dart
    worksheet_pdf.dart
  screens/
    splash_screen.dart
    language_screen.dart
    home_screen.dart
    world_screen.dart
    unit_screen.dart
    lesson_screen.dart
    worksheet_builder_screen.dart
    reading_month_screen.dart
    settings_screen.dart
  widgets/
    lesson_step_widgets.dart
    ui.dart

assets/
  lessons/
    en/  (Pre-K + K worlds/units/lessons)
    fr/
  worksheets/
    en/  (templates)
    fr/
  games/
    en/ (game packs)
    fr/
  reading_month/
    en/
    fr/
```

---

## Where to edit curriculum

- `assets/lessons/en/worlds_manifest.json`
- `assets/lessons/fr/worlds_manifest.json`

Each world points to units and lessons stored as JSON.

---

## Add more content

- Add new JSON files under `assets/lessons/<lang>/`
- Register them inside `worlds_manifest.json`
- The UI auto‑loads and displays them in path mode.

All lesson content (worlds, units, individual lessons) is packaged inside
the application under `assets/lessons` and is available offline. Tap **Path →
World → Unit → Lesson** to run through an interactive lesson; this is the same
JSON format that can also be imported at runtime. There is no network fetch—
everything the student sees is stored locally in the app, just like the
worksheet templates.

### Importing at runtime

You can now import lesson JSON files while the app is running. Open
**Settings → Import JSON file** and select a `.json` file from your device. The
file is copied into the app's local storage (`/lessons/<lang>/` under the
application documents directory) and will take precedence over bundled assets.

Imported manifests and world/unit files will be visible immediately (the
`Worlds` screen refreshes automatically). There's no need to rebuild the
app. This lets you download external curricula and drop them into the app
without touching the source assets.

---

## Worksheet Builder

Open **Worksheets → Build Worksheet** and choose:

- Letters practice
- Counting practice
- Matching practice

Then export as a **PDF** (saved locally).  
On Android/iOS this uses `path_provider` + `printing`.

---

## If you want it to look exactly like Education.com

Education.com is a huge web platform with many categories/resources.  
This app is structured similarly in **libraries** (subjects/resources) and **guided paths**, but stays 100% offline.
