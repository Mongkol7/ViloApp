# Architectural Decision Records (ADR)

## ADR-001: Feature-Driven Clean Architecture

- **Status**: Accepted
- **Context**: Need a modular codebase supporting distinct features (Feed, Shop, Search, Creator, Profile) without coupling.
- **Decision**: Organize codebase by feature (`features/<name>/data|domain|presentation`), backed by shared `core/` tokens.

## ADR-002: Obsidian Pulse Design System

- **Status**: Accepted
- **Context**: Need high-density, futuristic dark-mode UI with technical precision for video and commerce.
- **Decision**: Standardize on Obsidian Pulse: monochromatic palette (`#080808` Void, `#141414` Surfaces), 1px hairline borders (`rgba(255,255,255,0.08)`), Inter font, and Glassmorphic refraction.

## ADR-003: 5-Phase Apple Liquid Glass & Instagram Dynamic Scroll Navigation Bar

- **Status**: Accepted
- **Context**: Need a world-class floating navigation dock that maximizes screen space on scroll while feeling fluid and tactile.
- **Decision**: Implemented dual-edge viscous stretching spring model with hysteresis-based scroll compression (compresses to 48pt & 70% opacity on downward scroll $>20\text{pt}$, restores on upward scroll $<-6\text{pt}$).

## ADR-004: Exclusion of Live Video Streaming

- **Status**: Accepted
- **Context**: Scope is strictly short-form pre-recorded video content and integrated commerce.
- **Decision**: Omit live streaming protocols (RTMP, WebRTC rooms) to optimize video buffer efficiency and app bundle size.

## ADR-005: Dual Upload Pipeline with Direct Disk Streaming

- **Status**: Accepted
- **Context**: Large video files (10MB–50MB) caused in-memory byte buffer exhaustion (OOM crashes) when passing `PlatformFile.bytes` through multipart HTTP requests. Android 13+ also introduced granular media permissions (`READ_MEDIA_IMAGES` and `READ_MEDIA_VIDEO`).
- **Decision**: Implemented `http.MultipartFile.fromPath` direct disk streaming in `FeedRemoteDataSource.uploadVideo()`. Supported dual `ImagePicker` + `FilePicker` fallback, allowing posting of both video media files (`mp4`, `mov`, `webm`) and photo/image posts (`jpg`, `png`, `webp`) without memory buffering.

## ADR-006: Event-Driven Zero-Latency Profile & Follow Synchronization

- **Status**: Accepted
- **Context**: `ProfileScreen` is kept alive in memory via `wantKeepAlive => true` in `MainNavigationShell`. When posting a video or toggling follow state from external screens, `initState()` does not re-execute, causing stale profile data and missing post items.
- **Decision**: Created `ProfileSyncService` singleton with reactive `ValueNotifier<VideoModel?>` and `ValueNotifier<FollowChangeEvent?>`. Components listen to these events and optimistically mutate their local state (`_myVideos`, `followingCount`) with $0\text{ms}$ latency without awaiting full screen reloads.

## ADR-007: Resilient Decoupled Profile Data Fetching

- **Status**: Accepted
- **Context**: Tying profile metadata (`GET /users/me`) and video list (`GET /videos/user/{id}`) inside a single `try` block caused network errors in auth/profile to swallow and cancel user video fetching, leaving the profile grid blank or stuck on mock fallbacks.
- **Decision**: Decouple `_loadProfile()` into distinct, independent execution blocks. User video posts are always loaded and cached regardless of token or `/users/me` status, backed by `RefreshIndicator` with `AlwaysScrollableScrollPhysics`.

## ADR-008: `ViloTabBarView` for NestedScrollView Initial Index Synchronization

- **Status**: Accepted
- **Context**: Flutter's native `TabBarView` inside `NestedScrollView` clamps its internal `PagePosition` offset to 0.0 when initial layout constraints evaluate to zero width during route push transitions (`Navigator.push`). When opening profiles with `initialIndex: 1` (Posted Videos), the `TabBar` indicator highlights Tab 1, but the body gets stuck displaying Tab 0 (Music) until switching back and forth.
- **Decision**: Built `ViloTabBarView` (`vilo_tab_bar_view.dart`) which directly wraps a controlled `PageView`, monitors `TabController`, and performs post-frame / scroll-end synchronization checks. If `pageController.page?.round() != controller.index`, it immediately jumps to the target page, guaranteeing 100% reliable tab initialization across all profile screens.

## ADR-009: Responsive Video Feed Overlays & Edge-Faded Top Navigation Bar

- **Status**: Accepted
- **Context**: Video player captions and action controls collided with the floating bottom navigation bar on news feeds, or sat too high when viewed in standalone profile views without a navigation dock. The top category tabs and search icon also overlapped the floating sound toggle button.
- **Decision**:
  1. Dynamically compute responsive offsets: in news feed with bottom dock, captions sit at `padding.bottom + 80pt`; in standalone views, they move down to `padding.bottom + 20pt`.
  2. Shift right-side action buttons (`Profile`, `Like`, `Comment`, `Save`, `Share`, `Music Disc`) and volume toggle to `right: 8` for an edge-aligned TikTok/Reels aesthetic.
  3. Relocate sound toggle to `padding.top + 64pt` in main feed (8pt below the category bar) avoiding collision with search.
  4. Top category navbar in `HomeFeedPage` wrapped with a horizontal `ShaderMask` linear alpha gradient (`[0.0, 0.08, 0.92, 1.0]`) and `BouncingScrollPhysics` for edge-fade and fluid horizontal dragging across all input devices.

## ADR-010: Database Video Title & Hashtag Search Engine

- **Status**: Accepted
- **Context**: Video search previously queried a static list of 8 mock videos, making real uploaded/posted videos completely unsearchable. Hashtags on posted videos were not synchronized with `HashtagRepository`, and search results in Flutter displayed as static cards that only showed a snackbar instead of playing the video.
- **Decision**:
  1. Implemented full-text keyword search in `VideoRepository.searchVideos` matching `title`, `caption`, `description`, `VideoTag.tagName`, and creator username/displayName.
  2. Implemented `searchTagNames` in `VideoTagRepository` and automatically registered newly uploaded tags/hashtags in `HashtagRepository` with incremented usage counts.
  3. Integrated `VideoRepository` into `SearchService.search()` with tokenized multi-word query fallback and DTO conversion containing all playback parameters.
  4. Extended Flutter `TrendingVideo` with `videoUrl`, `caption`, `toVideoModel()`, and wired search grid taps to open `VideoFeedPage` for immediate fullscreen playback.
  5. Updated `_fallbackLocalSearch` to search `FeedRemoteDataSource.instance.getAllCachedVideos()` for offline and optimistic local responsiveness.
