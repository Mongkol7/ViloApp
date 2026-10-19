# Project AI Guidelines & Core Stack

## 1. Tech Stack

- **Client Framework**: Flutter / Dart SDK `^3.7.0` (Material 3 enabled).
- **Backend Framework**: Spring Boot 3.4.1 (Java 17+), Spring Security 6 (Stateless JWT), Spring Data JPA.
- **Database**: PostgreSQL 18 (`vilo_db` on port 5432, user: `postgres`, password: `123`).
- **Dev Server Port**: Always port `3000` (`server.port=3000`).
- **Media Storage**: Local multipart disk storage under `./uploads/` (`/uploads/videos`, `/uploads/photos`, `/uploads/thumbnails`), exposed via Spring WebMvc static resource handlers.
- **Architecture**: Feature-Driven Layered Clean Architecture (`app/`, `core/`, `features/<feature>/data|domain|presentation`).
- **Styling & UI**: **Obsidian Pulse** design system (Monochromatic pitch-black void `#080808`, `#141414` surfaces, 1px hairline strokes, Liquid Glass aesthetics, Inter typography).

---

## 2. Core Architecture Rules

- **Layer Separation**:
  - `data/`: DTOs, data sources, and concrete repository implementations.
  - `domain/`: Pure Dart entities and abstract repository contracts (zero UI/framework dependencies).
  - `presentation/`: State controllers, screen pages, and localized widgets.
- **Shared Tokens**: Colors, typography, spacing, and radii must ALWAYS reference `lib/core/constants/` and `lib/core/theme/` tokens. Ad-hoc hardcoded values are forbidden.
- **Real-Time Cross-Screen Sync**: Use `ProfileSyncService.instance` event notifiers (`videoUploadedEvents`, `followEvents`) and `VideoFeedManager` for zero-latency state synchronization across tabs.
- **Short-form Video Constraints**: No live streaming feature; video controller lifecycle management using `RouteAware` auto-pause/resume and tab keep-alive optimization.

---

## 3. Implementation Guardrails

- Maintain `flutter analyze` with 0 issues / 0 warnings at all times.
- Ensure all unit & widget tests pass (28/28 tests passing baseline).
- Ensure all interactive touch elements satisfy minimum $44 \times 44\text{pt}$ hit-test boundaries.
- All new files and structural updates must follow existing naming and directory conventions.
