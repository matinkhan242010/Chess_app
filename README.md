# Offline Chess — Stage 1

Board rendering + rules integration (via the `chess` package) + local 2-player mode.

## What's implemented in this stage

- `lib/engine/chess_engine.dart` — thin wrapper around the `chess` pub package
  (chess.js port). All rules (legality, check/mate/stalemate, castling, en
  passant, promotion, threefold repetition, 50-move rule, insufficient
  material) come from that package — nothing hand-rolled.
- `lib/models/game_state.dart` — `ChangeNotifier` holding the live game:
  selection, legal-move highlighting, last-move tracking, promotion flow,
  undo, board-flip logic, SAN move history.
- `lib/ui/widgets/chess_board_widget.dart` — 8x8 board with **both**
  drag-and-drop (`Draggable`/`DragTarget`) and tap-to-move, legal-move dots,
  last-move highlight, king-in-check highlight.
- `lib/ui/widgets/promotion_dialog.dart` — piece-picker shown on promotion.
- `lib/ui/widgets/move_history_panel.dart` — scrollable SAN list, numbered in
  move pairs.
- `lib/ui/screens/home_screen.dart` / `game_screen.dart` — menu → local
  2-player game, with a responsive board+side-panel layout on wide screens
  and a stacked layout on narrow ones.
- `pubspec.yaml` already lists every dependency the full build plan needs
  (provider, shared_preferences, sqflite, audioplayers, stockfish), so you
  only run `flutter pub get` once, now.

Not yet wired up (later stages): bot/Stockfish, clock, sounds, themes/settings
screen, resign/draw, captured-pieces tray. The "vs Bot" and "Settings" buttons
on the home screen are visibly present but disabled on purpose so the menu
shape doesn't need to change later.

## Setup

> This project was written and reviewed but **not compiled in this sandbox**
> — the container here doesn't have the Flutter SDK or network access to
> pub.dev, so I couldn't run `flutter pub get` / `flutter run` myself. Please
> run the commands below on your machine and tell me what you see; I'll fix
> anything that comes up.

```bash
# 1. Confirm Flutter is installed and healthy
flutter doctor

# 2. From the chess_app/ folder, fetch dependencies
cd chess_app
flutter pub get

# 3. Enable desktop targets if you haven't already (one-time, per machine)
flutter config --enable-macos-desktop   # macOS
flutter config --enable-windows-desktop # Windows
flutter config --enable-linux-desktop   # Linux
```

## Run / test this stage

```bash
# Mobile: launch an emulator/simulator or plug in a device first, then
flutter run

# Desktop (pick the one matching your OS)
flutter run -d macos
flutter run -d windows
flutter run -d linux

# Resize the desktop window and confirm the board+history layout switches
# between the wide (side-by-side) and narrow (stacked) layouts around 800px.
```

### Manual test checklist for Stage 1

- [ ] Tap a piece → its legal destination squares get a dot/ring highlight.
- [ ] Tap a legal destination → the move happens; tap the board again with
      nothing selected → nothing happens.
- [ ] Drag a piece to a legal square → move happens; drag to an illegal
      square → piece snaps back, no move.
- [ ] Push a pawn to the last rank → promotion dialog appears; picking a
      piece completes the move as that piece.
- [ ] Put a king in check → its square highlights.
- [ ] Play to checkmate/stalemate → status bar shows the correct reason.
- [ ] "Undo" button undoes one ply at a time.
- [ ] "Flip board" button flips orientation.
- [ ] Move history panel fills in as `1. e4 e5 2. Nf3 ...` in real time.
- [ ] Resize a desktop window across ~800px width → layout switches from
      stacked to side-by-side.

Once you've run through that list (or found issues), let me know and I'll
move on to Stage 2 (move-history jump-to-position / review mode is partially
stubbed already — `isReviewing` — plus polishing undo edge cases), then
Stage 3 (Stockfish + bot mode).
