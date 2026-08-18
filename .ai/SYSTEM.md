# Project AI Guidelines & Core Stack

## 1. Tech Stack

- **Framework**: Flutter / Dart SDK `^3.12.2` (Material 3 enabled).
- **Architecture**: Feature-Driven Layered Clean Architecture (`app/`, `core/`, `features/<feature>/data|domain|presentation`).
- **Styling & UI**: **Obsidian Pulse** design system (Monochromatic pitch-black void `#080808`, `#141414` surfaces, 1px hairline strokes, Liquid Glass aesthetics, Inter typography).
- **Backend Protocol**: REST / WebSocket (Port 3000 in dev environment).

---

## 2. Core Architecture Rules

- **Layer Separation**:
  - `data/`: DTOs, data sources, and concrete repository implementations.
  - `domain/`: Pure Dart entities and abstract repository contracts (zero UI/framework dependencies).
  - `presentation/`: State controllers, screen pages, and localized widgets.
- **Shared Tokens**: Colors, typography, spacing, and radii must ALWAYS reference `lib/core/constants/` and `lib/core/theme/` tokens. Ad-hoc hardcoded values are forbidden.
- **Short-form Video Constraints**: No live streaming feature; feed player recycling max 3 active controllers to avoid memory leaks.

---

## 3. Implementation Guardrails

- Maintain `flutter analyze` with 0 issues / 0 warnings at all times.
- Ensure all interactive touch elements satisfy minimum $44 \times 44\text{pt}$ hit-test boundaries.
- All new files and structural updates must follow existing naming and directory conventions.
