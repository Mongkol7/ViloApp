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
