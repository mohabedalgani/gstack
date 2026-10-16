# جُمْلَة — iOS MVP (`seebaios`)

SwiftUI path-connect Arabic sentence puzzle (iOS 17+).  
Drag adjacent Arabic words to form a sentence → explode → gravity → new tiles from the top + SFX.

## Clone & open in Xcode

```bash
git clone https://github.com/mohabedalgani/seebaios.git
cd seebaios
open Jumla.xcodeproj
```

In Xcode:

1. Select the **Jumla** scheme and an iPhone simulator (or your device).
2. Set your **Team** under Signing & Capabilities (for a physical device).
3. Press **Run** (⌘R).

Optional App Icon: drop a 1024×1024 image into `Jumla/Assets.xcassets/AppIcon.appiconset`.

## Play

- Drag across adjacent tiles to form a verbal sentence (فعل + فاعل + مفعول به).
- Release to check.
- Correct → merge fly + explosion + score + tiles fall + new words drop in.
- Toggle **٤ / ٨ اتجاهات** in the menu.
- Mute / reset in the header.

Example sentence: **قَرَأَ الطَّالِبُ الْكِتَابَ**

## Project layout

```
Jumla/
  JumlaApp.swift
  Game/          # SwiftUI board, feedback, view model
  Domain/        # recipes, board/path/refill logic
  Audio/         # synthesized AVAudioEngine SFX
  Theme/         # colors
  Assets.xcassets
```

## Notes

- Portrait only, RTL layout.
- No network / no accounts — content is local JSON-style Swift catalogs.
- Sounds are synthesized (no audio asset files).
- This cloud environment cannot compile for iOS; build with Xcode on macOS.

## Pair with the web MVP

Web prototype (for quick iteration): `~/jumla-mvp` → `python3 -m http.server 8765`
