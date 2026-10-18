# Architecture & Project Structure Design for Vilo (Short-form Video & Shop)

## Overview

**Vilo** is a high-performance Flutter mobile application designed for short-form video content delivery (similar to TikTok / Instagram Reels) paired with an integrated e-commerce shopping experience (Shop showcase, product tagging in videos, cart, checkout), intentionally excluding live video streaming.

To ensure performance (60/120 FPS video scrolling, aggressive video lifecycle control, low latency), maintainability, and testability, we adopt a **Feature-Driven Layered Clean Architecture** combined with reactive state managers, route observers, and responsive UI components.

---

## Architectural Pattern: Feature-Driven Clean Architecture

```
lib/
├── app/                        # App-level configs, bootstrap, route observers, theme
├── core/                       # Shared foundational layer (agnostic of specific features)
│   ├── constants/              # App colors, dimensions, spacing, strings
│   ├── theme/                  # Colors, typography, component themes (Dark Obsidian)
│   └── utils/                  # Formatters, screen utilities
└── features/                   # Independent vertical feature slices
    ├── auth/                   # Authentication (Login, Register, Forgot Password, Link Sent)
    ├── feed/                   # Short-form video feed (HomeFeedPage, VideoFeedPage, SoundDetail, Comments, Share)
    ├── inbox_activity/         # Thought Stories, Music Picker & Trimmer, Viewer Sheet, Notifications, Chat Detail
    ├── profile/                # User Profile, Share Mind Balloon, People/Friends, Tab Contents (Music, Grid, Shop, Saved, Liked)
    ├── search_discover/        # Discover trends, search videos, accounts, and sounds
    └── bottom_nav/             # Floating bottom navigation bar with scroll hysteresis & MainNavigationShell
```

---

## Detailed Directory Breakdown

### 1. `lib/app/`

- `app.dart`: Root `MaterialApp` widget initializing routers, themes, `LoginScreen` entry, and global `routeObserver` for video and story route tracking.

### 2. `lib/core/`

- **`constants/`**:
  - `app_colors.dart`: Dark-first Obsidian modern palette (`voidBackground`, `surfaceContainer`, `surfaceElevated`, neon and gradient accents).
  - `app_spacing.dart`: 8pt structural spacing grid.
- **`theme/`**:
  - `app_theme.dart`: Dark theme data definition.
  - `app_typography.dart`: Clean Inter typography hierarchy.

---

### 3. `lib/features/` (Feature Slices)

#### A. `features/auth/` (Authentication & Onboarding)
- **Pages**:
  - `login_screen.dart`: Login with username/email and password, redirecting to `MainNavigationShell(initialIndex: 0)`.
  - `register_screen.dart`: Account registration with validation and terms acceptance.
  - `forgot_password_screen.dart` & `link_sent_screen.dart`: Password recovery flow.
- **Widgets**: `vilo_input_field.dart`, `vilo_primary_button.dart`, `vilo_social_login_section.dart`, `vilo_logo_mark.dart`.

#### B. `features/feed/` (Short-Form Video Feed)
- **Pages**:
  - `home_feed_page.dart`: Top navigation bar with 4 tabs (`Community`, `Following`, `For You`, `Shop`) and direct `🔍` Search button redirection.
  - `video_feed_page.dart`: Vertical video `PageView.builder` featuring:
    - **Translucent Center Pause Overlay Icon** (`Icons.play_arrow_rounded`) when playback is paused.
    - **RouteAware Auto-Pause/Resume**: Automatically pauses video playback when opening Search, Comments, or external routes, and resumes upon returning.
    - **Tab Switching Pause Control**: Videos on inactive bottom tabs (Friends, Inbox, Profile) or inactive top feed tabs automatically pause without consuming background resources.
  - `sound_detail_page.dart`: Audio track info with featured video grid and bookmarking.
- **Widgets**: `comment_bottom_sheet.dart`, `share_bottom_sheet.dart`.

#### C. `features/inbox_activity/` (Thought Stories & Direct Messages)
- **Data & State**:
  - `thought_story_manager.dart`: Singleton manager with reactive `ValueNotifier<SharedThoughtStory?>` ensuring 100% two-way state synchronization between Inbox and Profile screens.
  - `static_inbox_data.dart` & `static_story_viewers_data.dart`: Static and mock data sources.
- **Domain**:
  - `shared_thought_story.dart`: Entity models for `SharedThoughtStory`, `StoryViewer`, and `TrimmedMusicTrack`.
- **Presentation**:
  - `inbox_screen.dart`: Horizontal stories row with active sunset story ring and dancing mini music equalizer, Notification Hub tiles, and direct message threads.
  - `share_thought_screen.dart`: Fullscreen thought composer with centered avatar layout, 6 atmosphere palette switcher themes, music attachment badge, and animated audio equalizer waveform.
  - `music_picker_bottom_sheet.dart`: Auto-scrolling carousel (3.2s interval) with indicator dots, search, and category tabs.
  - `music_trimmer_bottom_sheet.dart`: Interactive waveform trimmer with dynamic box squeeze, synchronized moving playhead progress, instant replay on reselection, and Instagram-style clip duration wheel modal.
  - `story_viewer_screen.dart`: Fullscreen story viewer with progress timer, views count button, waveform badge, and 3-dots popup to delete story.
  - `story_viewers_bottom_sheet.dart`: Modal sheet displaying viewer accounts with interactive follow/following toggles.
  - `chat_detail_screen.dart`: 1-on-1 direct messaging conversation view.
  - `animated_mini_music_wave.dart`: Reusable animated 3-bar equalizer widget.

#### D. `features/profile/` (User & Friends Profiles)
- **Pages**:
  - `profile_screen.dart`: User profile with interactive **Share Your Mind** thought balloon, animated equalizer waves, sunset story gradient ring, bio, stats, and 5 content tabs (`Music`, `Grid`, `Shop`, `Saved`, `Liked`).
  - `people_screen.dart`: "Friends" recommendation screen with search header and creator suggestion cards.
- **Widgets**:
  - `person_card.dart`: Interactive creator suggestion card with Follow/Following and Remove actions.
  - `profile_tab_content.dart`, `video_grid_item.dart`, `shop_product_card.dart`, `sound_list_item.dart`.

#### E. `features/search_discover/` (Search & Discovery)
- **Pages**:
  - `search_screen.dart`: Discover search bar with clear action, 3-column video grid, trending accounts with avatar badges, and popular audio tracks.

#### F. `features/bottom_nav/` (Floating Navigation Shell)
- **Pages**:
  - `main_navigation_shell.dart`: Controls persistent bottom bar, scroll hysteresis notifications, and connects:
    - Tab 0: `HomeFeedPage` (Videos & Shop)
    - Tab 1: `PeopleScreen` (Friends)
    - Tab 2: `InboxScreen` (Chat & Stories)
    - Tab 3: `ProfileScreen` (User Profile)
- **Widgets**:
  - `vilo_floating_bottom_bar.dart`: Floating dock with scroll-aware auto-collapse (`_isCompact`) and active indicator pills.

---

## Testing & Quality Assurance
- Automated Widget Tests in `test/widget_test.dart`:
  1. `ViloFloatingBottomBar` rendering and active state verification.
  2. `PeopleScreen` search bar navigation to `SearchScreen`.
  3. `InboxScreen` direct message navigation to `ChatDetailScreen`.
  4. Full Story lifecycle: Sharing thought with trimmed music, viewing story, inspecting viewers sheet, and deleting story.
  5. `ProfileScreen` Share Mind story creation and real-time state synchronization with `InboxScreen`.
