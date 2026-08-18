# Architecture & Project Structure Design for Vilo (Short-form Video & Shop)

## Overview

**Vilo** is a high-performance Flutter mobile application designed for short-form video content delivery (similar to TikTok / Instagram Reels) paired with an integrated e-commerce shopping experience (Shop showcase, product tagging in videos, cart, checkout), intentionally excluding live video streaming.

To ensure performance (60/120 FPS video scrolling, aggressive video caching, low latency), maintainability, and testability, we adopt a **Feature-Driven Layered Clean Architecture** combined with a robust state management strategy (e.g., Bloc or Riverpod) and caching/preloading infrastructure.

---

## Architectural Pattern: Feature-Driven Clean Architecture

```
lib/
├── app/                        # App-level configs, bootstrap, observer, environment
├── core/                       # Shared foundational layer (agnostic of specific features)
│   ├── constants/              # App constants, API endpoints, asset keys
│   ├── network/                # HTTP/Dio client, interceptors, error handling
│   ├── theme/                  # Colors, typography, component themes (Dark/Light)
│   ├── router/                 # GoRouter / routing config & transitions
│   ├── utils/                  # Formatters, debouncers, validators, screen utilities
│   ├── services/               # Video cache manager, storage service, analytics
│   └── widgets/                # Reusable design system widgets (buttons, badges, modals)
└── features/                   # Independent vertical feature slices
    ├── auth/                   # Authentication (Login, Register, OTP, Token Refresh)
    ├── feed/                   # Short-form video feed (For You, Following, Video Player)
    ├── shop/                   # E-commerce (Product Catalog, Cart, Order, Product Detail)
    ├── creator/                # Content Creation (Camera capture, trim/filters, upload)
    ├── profile/                # User & Creator Profiles, Saved/Liked videos, Orders
    ├── search_discover/        # Discover trends, hashtags, search videos/products/creators
    ├── inbox_activity/         # Notifications, Direct Messages, System Alerts
    └── bottom_nav/             # Root scaffold with persistent bottom navigation
```

---

## Detailed Directory Breakdown

### 1. `lib/app/`

- `app.dart`: Root `MaterialApp` widget initializing routers, themes, and global listeners.
- `app_bloc_observer.dart` / `app_provider_observer.dart`: Global telemetry and state logging.
- `app_constants.dart`: Global configurations and environment toggles.

### 2. `lib/core/`

- **`constants/`**:
  - `api_endpoints.dart`: REST/GraphQL backend URLs.
  - `app_colors.dart`: Dark-first modern palette (black/neon accent/gray tones tailored for video UX).
  - `app_dimensions.dart` / `app_strings.dart` / `app_assets.dart`.
- **`network/`**:
  - `api_client.dart` (Dio client wrapper with retry & auth interceptors).
  - `api_exceptions.dart` / `error_handler.dart`.
- **`services/`**:
  - `video_cache_service.dart`: Integrates video caching layer (e.g. `flutter_cache_manager` / video player pre-caching) so scrolling next videos is instantaneous.
  - `local_storage_service.dart`: Shared preferences / secure storage for session keys & tokens.
  - `media_service.dart`: Camera and gallery pickers, thumbnail generator.
- **`widgets/`**:
  - `vilo_avatar.dart`, `vilo_button.dart`, `vilo_icon_button.dart`, `vilo_badge.dart`, `vilo_loading.dart`, `vilo_bottom_sheet.dart`, `price_tag_pill.dart`.

---

### 3. `lib/features/` (Feature Slices)

Each feature folder follows a clean 3-layer structure (`data`, `domain`, `presentation`):

```
features/<feature_name>/
├── data/
│   ├── datasources/            # Remote API / Local DB data sources
│   ├── models/                 # JSON serializable data transfer objects (DTOs)
│   └── repositories/          # Concrete implementation of domain repositories
├── domain/
│   ├── entities/               # Pure business domain entities
│   ├── repositories/          # Abstract repository interfaces
│   └── usecases/               # Pure single-responsibility business logic use cases
└── presentation/
    ├── controllers/ or bloc/   # State management (Bloc/Cubit, Riverpod Notifiers, or Controllers)
    ├── pages/ or screens/      # Top-level screen widgets
    └── widgets/                # Feature-scoped UI subcomponents
```

#### Key Feature Modules & Scope

#### A. `features/feed/` (Core Shortform Video Feed)

- **Entities & Models**: `VideoItem`, `VideoAuthor`, `VideoStats` (likes, comments, shares, views), `TaggedProductPill`.
- **Presentation**:
  - `feed_screen.dart`: Vertical `PageView.builder` with prefetching logic.
  - `video_player_item.dart`: Single video playback container with gesture detection (tap to pause, double-tap to like with heart animation).
  - `video_overlay_actions.dart`: Right sidebar (author avatar with follow button, like button + count, comment button + count, bookmark, share, sound disc rotation).
  - `video_overlay_info.dart`: Bottom overlay (creator username, caption with hashtags, music title marquee, tagged shop product badge).
  - `comments_bottom_sheet.dart`: Interactive comment thread sheet with replies & keyboard input.
  - `share_bottom_sheet.dart`: Share to external apps, copy link, save video.

#### B. `features/shop/` (Integrated E-commerce)

- **Entities & Models**: `Product`, `ProductCategory`, `CartItem`, `Order`, `ProductReview`, `Promotion`.
- **Presentation**:
  - `shop_home_screen.dart`: Shop tab with categories, flash sales, search bar, recommended products grid.
  - `product_detail_screen.dart`: Image carousel, variant selector (size/color), product specifications, video reviews, "Buy Now" & "Add to Cart".
  - `cart_screen.dart` / `cart_modal.dart`: Cart management with total price calculation and coupon input.
  - `checkout_screen.dart`: Shipping address, payment method selector, order confirmation.
  - `order_history_screen.dart`: Order tracking and purchase records.
  - `product_tag_card.dart`: Compact product card embedded inside video overlays.

#### C. `features/creator/` (Video Creation & Upload - No Live Video)

- **Entities & Models**: `DraftVideo`, `MusicTrack`, `VideoFilter`, `UploadPayload`.
- **Presentation**:
  - `camera_screen.dart`: Full-screen camera preview with record button, flip camera, timer, speed control, flash toggle.
  - `video_editor_screen.dart`: Trimming, sound selection/sync, overlay text/stickers, filter previews.
  - `video_publish_screen.dart`: Caption editor, hashtag suggestions, privacy settings (public, friends, private), cover thumbnail picker, **"Tag Shop Product"** selector.
  - `upload_progress_overlay.dart`: Background upload manager with progress indicator.

#### D. `features/search_discover/` (Search & Discover)

- **Presentation**:
  - `discover_screen.dart`: Trending banners, popular hashtags with horizontal video previews, top trending products.
  - `search_results_screen.dart`: Tabbed search results (`Top`, `Videos`, `Shop / Products`, `Users`, `Sounds`, `Hashtags`).

#### E. `features/inbox_activity/` (Notifications & Chat)

- **Presentation**:
  - `inbox_screen.dart`: Activity notifications (likes, comments, mentions, shop order updates) and direct message chats.
  - `chat_screen.dart`: 1-on-1 messaging between users or user-to-seller inquiry.

#### F. `features/profile/` (User & Shop Profile)

- **Presentation**:
  - `profile_screen.dart`: User details, stats (Following, Followers, Likes), Bio, Edit Profile button.
  - `profile_tabs_view.dart`:
    - Tab 1: Uploaded Videos grid.
    - Tab 2: Liked Videos (privacy-restricted).
    - Tab 3: Saved / Bookmarked Videos & Products.
    - Tab 4: Showcase Shop (if creator has an affiliated shop or selling items).
  - `settings_screen.dart`: Account settings, notifications, orders & payment methods, dark mode.

#### G. `features/bottom_nav/` (Navigation Shell)

- `main_navigation_shell.dart`: 5-tab persistent bottom bar:
  1. **Home / Feed** (Videos)
  2. **Shop** (E-commerce)
  3. **(+) Create** (Center create button)
  4. **Inbox** (Activity & Chat)
  5. **Profile** (My Profile)

---

## Recommended Key Packages & Dependencies

| Category | Recommended Package | Purpose |
| --- | --- | --- |
| **State Management** | `flutter_bloc` or `flutter_riverpod` | Predictable state flow for video feeds, carts, and user sessions |
| **Routing** | `go_router` | Declarative deep-linking & bottom nav shell routing |
| **Video Playback** | `video_player` + `chewie` / `better_player` | Video rendering with buffer control |
| **Video Caching** | `flutter_cache_manager` / native cache proxy | Pre-buffering next 2-3 videos in the feed |
| **Camera & Media** | `camera`, `image_picker`, `video_thumbnail` | Video recording, photo selection, thumbnail generation |
| **Networking** | `dio`, `retrofit` / `http` | API requests, token interceptors, file upload progress |
| **Local Storage** | `flutter_secure_storage`, `shared_preferences` | Tokens, cart persistence, local caches |
| **UI & Animations** | `cached_network_image`, `lottie`, `shimmer` | Smooth image loading, double-tap heart animations, skeletons |

---

## Performance & UX Optimization Strategy for Short-Form Video

1. **Feed Video Pre-caching & Recycling**:
   - Limit active video controllers to 3 (Previous, Current, Next) to prevent memory overhead and out-of-memory crashes on low-end devices.
   - Automatically pause off-screen video controllers as soon as page swipe threshold exceeds 50%.
2. **Shop Integration in Videos**:
   - Lightweight floating product widget over video without interrupting video buffer.
   - Quick "Add to Cart" bottom sheet that keeps video playing in background or paused seamlessly.
3. **Dark Theme Native Feel**:
   - Feed operates in pure dark canvas (`#000000`) for edge-to-edge immersive playback.

---

## User Review Required

> [!NOTE]
> **State Management Preference**: Do you prefer **BLoC (`flutter_bloc`)**, **Riverpod (`flutter_riverpod`)**, or **Provider / GetX** for your state management solution? (We recommend `flutter_bloc` or `flutter_riverpod` for high scalability).

> [!NOTE]
> **Video Player & Preloading Approach**: For short-form video feeds, we will structure video pre-caching and feed controllers to keep memory consumption low.

---

## Verification Plan

### Automated Checks

- Run `flutter analyze` to ensure strict linting compliance across all folders and architectural layers.
- Unit tests for `feed` state controllers, `shop` cart calculations, and repository data mappings.

### Manual Verification

- Verify clean structure directory tree under `lib/`.
- Verify dummy feed and shop tab switching with responsive UI and edge-to-edge layout.
