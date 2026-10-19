# Architecture & Project Structure Design for Vilo (Short-form Video & Shop)

## Overview

**Vilo** is a high-performance full-stack application designed for short-form video delivery (similar to TikTok / Instagram Reels) paired with an integrated e-commerce shopping experience (Shop showcase, product tagging in videos, cart, checkout), intentionally excluding live video streaming.

To ensure performance (60/120 FPS video scrolling, aggressive video lifecycle control, low latency), maintainability, and testability, we adopt a **Feature-Driven Layered Clean Architecture** on the Flutter client, backed by a **Modular Spring Boot 3.4.1 REST Service** with **PostgreSQL 18** and **local disk multipart streaming storage**.

---

## High-Level System Architecture

```
viloapp/
├── backend/                    # Spring Boot 3.4.1 (Java 17+) REST Backend
│   ├── src/main/java/com/vilo/backend/
│   │   ├── config/             # SecurityConfig (JWT), WebMvcConfig (Static /uploads/**), DataInitializer
│   │   ├── controller/         # Auth, User, Video, Search REST Controllers
│   │   ├── entity/             # JPA Entities (User, Video, VideoLike, VideoSave, Comment, SearchHistory)
│   │   ├── repository/         # Spring Data JPA Repositories
│   │   ├── security/           # JwtTokenProvider, JwtAuthenticationFilter, CustomUserDetailsService
│   │   └── service/            # AuthService, UserService, VideoService, SearchService, LocalFileStorageService
│   └── src/main/resources/     # application.properties (PostgreSQL, Port 3000, Upload dir)
├── uploads/                    # Local media storage directory
│   ├── photos/                 # Uploaded photo posts (.jpg, .png, .webp)
│   ├── thumbnails/             # Video thumbnails & posters
│   └── videos/                 # Uploaded vertical video files (.mp4, .mov, .webm)
└── lib/                        # Flutter Client (Clean Architecture)
    ├── app/                    # App-level configs, bootstrap, route observers, theme
    ├── core/                   # Shared foundational layer (network, tokens, constants)
    │   ├── constants/          # Colors, dimensions, spacing, strings
    │   ├── network/            # ApiClient (HTTP client, base URL auto-detection, JWT injection)
    │   ├── theme/              # Dark Obsidian Pulse theme & typography
    │   └── utils/              # Formatters, screen utilities
    └── features/               # Independent vertical feature slices
        ├── auth/               # Authentication (Login, Register, Forgot Password, TokenStorage)
        ├── bottom_nav/         # Floating Liquid Glass bottom nav & MainNavigationShell
        ├── feed/               # Short-form video feed, video lifecycle, and UploadVideoSheet
        ├── inbox_activity/     # Thought Stories, Music Picker & Trimmer, Notifications, Chat Detail
        ├── profile/            # ProfileScreen, PublicProfileScreen, Followers/Following, ProfileSyncService
        ├── search_discover/    # Discover trends, universal search, category filters, search history
        └── shop/               # Shop showcase, product details, cart modal
```

---

## Detailed Directory Breakdown

### 1. `lib/core/`

- **`network/api_client.dart`**:
  - Automatically selects `http://10.0.2.2:3000/api/v1` for Android Emulator, and `http://localhost:3000/api/v1` for Web/Windows/iOS.
  - Automatically injects JWT Bearer tokens from `TokenStorage`.
  - Global error translation (`ApiResponseException`).
- **`constants/` & `theme/`**:
  - `PulseColors`, `PulseTypography`, `PulseSpacing`, `PulseRadius`: Design tokens strictly enforced across all screens.

---

### 2. `lib/features/` (Feature Slices)

#### A. `features/auth/`
- **Data**: `auth_remote_data_source.dart`, `token_storage.dart` (secure token caching).
- **Pages**: `login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart`, `link_sent_screen.dart`.

#### B. `features/feed/`
- **Data & Controllers**:
  - `feed_remote_data_source.dart`: Unified `getFeed`, `getUserVideos`, `uploadVideo`, in-memory feed & user cache, and optimistic mutation methods (`prependUserVideo`, `invalidateUserVideos`).
  - `video_feed_manager.dart`: Real-time active feed controller broadcasting newly uploaded videos.
  - `video_model.dart`: Complete media model with relative URL resolution (`resolveMediaUrl`) and photo post detection (`isImagePost`).
- **Pages & Widgets**:
  - `home_feed_page.dart`: Top navigation tabs (`Community`, `Following`, `For You`, `Shop`) with `PageStorageKeys` preserving scroll position.
  - `video_feed_page.dart`: Vertical video `PageView.builder` featuring RouteAware auto-pause/resume, tab keep-alive optimization, center pause indicators, like/save toggling, comments sheet, and full-screen view mode (`initialVideos`, `initialIndex`).
  - `upload_video_sheet.dart`: Resilient upload studio supporting both videos and photo posts with dual `ImagePicker` + `FilePicker` fallback, direct disk streaming multipart upload, caption, hashtags, and thumbnail picker.
  - `comment_bottom_sheet.dart`, `share_bottom_sheet.dart`, `sound_detail_page.dart`.

#### C. `features/profile/`
- **Data & Sync**:
  - `profile_sync_service.dart`: Global real-time event bus broadcasting `videoUploadedEvents` and `followEvents`. Pre-warms follower and following lists for zero-latency screen transitions.
  - `profile_remote_data_source.dart`: In-memory user caching, `getMyProfile`, `getUser`, `getFollowers`, `getFollowing`.
- **Presentation**:
  - `profile_screen.dart`: Own profile screen with Share Mind thought balloon, real-time `videoUploadedEvents` listener, independent video loading, pull-to-refresh (`RefreshIndicator`), and 5 content tabs (`Music`, `Grid`, `Shop`, `Saved`, `Liked`).
  - `public_profile_screen.dart`: View other creators' profiles with live follow toggle and video grid.
  - `followers_following_screen.dart`: Followers and Following tabbed lists with search and instant follow toggles.
  - `video_grid_item.dart`: Video thumbnail card with relative URL resolution, play icon views badge, and tap callback to open full-screen `VideoFeedPage`.
  - `profile_tab_content.dart`: Slivers builder generating tab views with dynamic poster generation for videos without thumbnails.

#### D. `features/inbox_activity/`
- **Data & State**: `thought_story_manager.dart` (ValueNotifier state syncing story between Inbox and Profile).
- **Presentation**: `inbox_screen.dart`, `share_thought_screen.dart` (6 atmospheric palettes), `music_picker_bottom_sheet.dart`, `music_trimmer_bottom_sheet.dart` (clip duration wheel, waveform progress, instant replay), `story_viewer_screen.dart`, `chat_detail_screen.dart`.

#### E. `features/search_discover/`
- **Data**: `search_remote_data_source.dart` (trending, live search query, and search history sync).
- **Presentation**: `search_screen.dart` (search header, category chips, trending grid, accounts, sounds, and history pills).

#### F. `features/bottom_nav/`
- `main_navigation_shell.dart`: Persistent shell managing active tabs (`Home`, `Friends`, `Upload Modal`, `Inbox`, `Profile`) and scroll hysteresis compaction.

---

## Testing & Quality Assurance
The codebase is validated by 28 automated tests across 3 comprehensive test suites:
1. `test/widget_test.dart` (24 tests):
   - Bottom navigation bar, People screen, Inbox direct message, Full Story lifecycle, Profile Share Mind sync, Settings & Privacy, Edit Profile, Public Profile follow toggle, Followers/Following screen, Search screen & category filtering, Sound detail page, Video feed creator rendering, and tab scroll retention.
2. `test/upload_video_sheet_test.dart`:
   - Modal opening from navigation shell, media preview tile rendering, and required input validation.
3. `test/profile_video_post_test.dart`:
   - Real-time video upload sync to profile grid, `FeedRemoteDataSource.prependUserVideo` cache retention, `VideoGridItem` tap interaction, and `VideoFeedPage` direct rendering with initial video lists.
