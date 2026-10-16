# جُمْلَة — iOS MVP (`seebaios`)

SwiftUI path-connect Arabic sentence puzzle (iOS 17+).

## Open in Xcode (recommended)

This branch on `gstack` holds the full Xcode project. On your Mac:

```bash
git clone -b seebaios-ios --single-branch https://github.com/mohabedalgani/gstack.git seebaios
cd seebaios
open Jumla.xcodeproj
```

Then: pick an iPhone simulator → ⌘R.

## Optional: copy into mohabedalgani/seebaios

If you want the code on https://github.com/mohabedalgani/seebaios (empty repo):

```bash
git clone https://github.com/mohabedalgani/seebaios.git
cd seebaios
git pull https://github.com/mohabedalgani/gstack.git seebaios-ios
git push -u origin main
open Jumla.xcodeproj
```

## Play

- Drag adjacent tiles to form a verbal sentence (e.g. قَرَأَ الطَّالِبُ الْكِتَابَ)
- Release → explode + gravity refill + SFX
- Mute / reset in the header; 4- or 8-way adjacency in the menu

## Layout

```
Jumla.xcodeproj
Jumla/
  JumlaApp.swift
  Game/     Board, feedback, view model
  Domain/   Recipes, path/refill logic
  Audio/    Synthesized SFX
  Theme/
```
