# Sudoku Pencil ✏️

An iPad Sudoku app designed for Apple Pencil input. Draw digits directly into cells with your Pencil — the app recognizes your handwriting using Apple's Vision framework.

## Features

- **Apple Pencil drawing** — select a cell, then draw a digit in the floating canvas. Vision OCR recognizes it and places it.
- **Finger fallback** — number pad at the bottom for quick taps.
- **3 difficulty levels** — Easy, Medium, Hard (controls how many cells are revealed).
- **Error highlighting** — wrong answers show in red.
- **Puzzle generation** — random valid Sudoku boards every game.

## Requirements

- iOS 17+ / iPadOS 17+
- Xcode 15+
- Apple Pencil recommended (canvas uses `.pencilOnly` drawing policy)

## Setup

1. Open in Xcode: create a new iOS App project, set target to iPad, then drag the `Sources/` files in.
2. Or use Swift Package Manager structure — open the folder in Xcode and add an iOS app target.
3. Build & run on iPad or iPad Simulator.

## Architecture

```
Sources/
  App/              → App entry point
  Models/           → SudokuBoard (puzzle generation, game state)
  Views/            → SwiftUI views (grid, cells, number pad, pencil overlay)
  Recognition/      → DigitRecognizer (PencilKit → Vision OCR)
```

## How It Works

1. Tap a cell to select it (highlights blue).
2. A 200×200 drawing canvas appears — draw a digit (1-9) with Apple Pencil.
3. After 0.6s pause, Vision recognizes the digit and places it in the cell.
4. Alternatively, tap a number on the pad below.
5. Wrong numbers show in red; complete the puzzle to win!
