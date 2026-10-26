# Vilo Development Notes & Engineering Guide

Welcome to the engineering notes repository for the **Vilo App**. This document provides quick reference notes, feature overviews, architectural rules, and operational guidelines for developers and AI agents working on the codebase.

---

## 1. Quick Architecture Overview

Vilo is architected as a full-stack, production-grade short-form video and e-commerce platform:

- **Client**: Flutter 3.27+ with Material 3, adhering to Feature-Driven Layered Clean Architecture (`lib/features/<feature>/data|domain|presentation`).
- **Backend**: Spring Boot 3.4.1 (Java 17+), Spring Security 6 (Stateless JWT authentication), Spring Data JPA.
- **Database**: PostgreSQL 18 on port `5432` (`vilo_db`).
- **Dev Port**: Always port `3000` (`server.port=3000`).
- **Local Media Storage**: Multipart uploads streamed directly to disk under `./uploads/` (`videos`, `photos`, `thumbnails`), served via static Spring WebMvc resource handlers (`/uploads/**`).

---

## 2. Core Notes & Best Practices

### A. Video Player & Overlays
- **Responsive Layout**: Overlays adapt based on whether the view is inside the main feed (with bottom navigation dock) or standalone (fullscreen viewer opened from profile or sound page).
  - Main Feed: Bottom caption offset is `mediaPadding.bottom + 80.0`, floating safely above the dock.
  - Standalone: Bottom caption offset is `mediaPadding.bottom + 20.0`, sitting snug against the lower safe area.
  - Right Action Controls: Aligned at `right: 8` for a clean, edge-hugging TikTok/Reels aesthetic.
- **Top Navigation Edge Fading**: The category bar in `HomeFeedPage` (`Community`, `Following`, `For You`, `Shop`) uses a horizontal `ShaderMask` gradient (`stops: [0.0, 0.08, 0.92, 1.0]`) to smoothly fade items at the left and right edges, paired with `BouncingScrollPhysics` and `TabAlignment.center` for fluid horizontal scrolling.
- **Sound / Volume Toggle**: Positioned at `padding.top + 64.0` in the main feed to sit with an 8px margin directly below the category bar and search icon, avoiding click interception.

### B. Profile & Tab Synchronization
- **Tab Order**:
  - `Tab 0`: Music / Sounds (`Icons.music_note_rounded`)
  - `Tab 1`: Posted Videos / Grid (`Icons.grid_view_rounded`)
  - `Tab 2`: Shop (`Icons.shopping_bag_outlined`)
  - `Tab 3`: Saved (`Icons.bookmark_border_rounded`)
  - `Tab 4`: Liked (`Icons.favorite_border_rounded`)
- **`ViloTabBarView` Solution**: Standard Flutter `TabBarView` inside `NestedScrollView` clamps `PagePosition` to `0.0` when initial layout width evaluates to zero. `ViloTabBarView` wraps a controlled `PageView` and runs post-frame synchronization checks to guarantee that `initialIndex: 1` loads the Posted Videos tab immediately without desynchronization.
- **Video Deletion Policy**: The delete button is strictly restricted to user-owned videos opened from the user's own profile (`canDelete: true` passed only on Tab 1 in `ProfileScreen`).

### C. Animated Follow Button
- Self-contained stateful component (`_AnimatedFollowButton`) featuring:
  - Medium impact haptic feedback on touch.
  - Expanding radial ripple shockwave.
  - Spring scale bounce (`1.0` $\rightarrow$ `1.42` $\rightarrow$ `1.15`).
  - 180° rotation and icon morph from `+` (`Icons.add`) to `✓` (`Icons.check_rounded`).
  - Color interpolation from TikTok crimson (`#FE2C55`) to emerald green (`#10B981`).
  - Celebratory hold followed by an `easeInBack` scale-down and fade-out into the creator avatar.

### D. Team Accounts & Video Asset Distribution
- **Active Team Roster (7 Accounts)**:
  1. **Thoeung Sereymongkol** (`@mongkol`) — *Lead*: Auth, Security & Profile Management
  2. **Lim Bunheng** (`@bunheng`) — Video Engine, Feed Streaming & Interactions
  3. **Sok Rithysak** (`@rithysak`, renamed from *Chhuon Rithysak*) — E-Commerce, Shop & Orders
  4. **Set Kimliza** (`@setkimliza`, renamed from *Kim Liza*) — Chat, Stories & Notifications
  5. **Tren Mono** (`@trenmono`, renamed from *Mono T*) — Search, Sounds, OpenAPI & DevOps
  6. **Try Phien** (`@tryphien`, *new creator*) — Creative Media, Camera Studio & Audio Sync
  7. **Nen Seanghai** (`@nenseanghai`, *new creator*) — Mobile UI/UX & Responsive Layouts
- **Zero-Duplication Asset Allocation**:
  - 14 distinct videos selected from `assets/videos/vid1.mp4` – `assets/videos/vid20.mp4`.
  - Exactly 2 distinct videos per creator account:
    - `@mongkol`: `assets/videos/vid1.mp4`, `assets/videos/vid2.mp4`
    - `@rithysak`: `assets/videos/vid3.mp4`, `assets/videos/vid4.mp4`
    - `@setkimliza`: `assets/videos/vid5.mp4`, `assets/videos/vid6.mp4`
    - `@trenmono`: `assets/videos/vid7.mp4`, `assets/videos/vid8.mp4`
    - `@bunheng`: `assets/videos/vid9.mp4`, `assets/videos/vid10.mp4`
    - `@tryphien`: `assets/videos/vid11.mp4`, `assets/videos/vid12.mp4`
    - `@nenseanghai`: `assets/videos/vid13.mp4`, `assets/videos/vid14.mp4`
  - All accounts start with baseline authentic counts (`0` likes, `0` comments, `0` saves, `0` views).
  - Mutual team follow graph established across all 7 members in `followers_following`.

---

## 3. Reference Links

- [Release Notes](RELEASE_NOTES.md) — Detailed changelog of recent updates and bug fixes.
- [Team Task Division](../../TEAM_TASK_DIVISION.md) — Full team architecture and domain ownership.
- [Active Tasks & Roadmap](../../.ai/ACTIVE_TASKS.md) — Current task board and milestones.
- [Architectural Decision Records](../../.ai/DECISIONS.md) — Formal records of key system decisions.
- [Learned Quirks & Gotchas](../../.ai/MEMORY.md) — Repository of edge cases, fixes, and troubleshooting steps.
- [API Specifications](../../docs/api/endpoints_spec.md) — REST endpoints specification.
