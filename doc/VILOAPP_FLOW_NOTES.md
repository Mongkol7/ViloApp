# ViloApp full-stack flow notes

Last reviewed: 2026-10-28

## 1. Project scope

ViloApp is a Flutter mobile-first social video application backed by a Spring Boot REST API and PostgreSQL. The app currently combines:

- authentication and profile identity;
- short-video feeds and video interactions;
- hashtags, search, sounds, comments, likes, saves, and view counts;
- direct messages and order-related chat messages;
- creator profiles and products;
- cart, checkout, order history, and cancellation.

The source tree currently contains unrelated working-tree changes from ongoing development. Do not use `git reset --hard`, `git checkout --`, or broad cleanup commands when continuing work. Preserve existing changes unless the task explicitly asks for a reset.

## 2. Startup and navigation flow

```text
main.dart
  -> ViloApp (app/app.dart)
      -> LoginScreen
          -> successful login/register
              -> MainNavigationShell
                  -> Home / Inbox / Create / Activity / Profile
```

### Flutter startup

1. `lib/main.dart` calls `WidgetsFlutterBinding.ensureInitialized()`.
2. It installs Flutter and platform error logging.
3. It locks the app to portrait orientations.
4. It starts `ViloApp`.
5. `lib/app/app.dart` installs the dark theme and `RouteObserver`, then opens `LoginScreen`.

### Main navigation

- Entry file: `lib/features/bottom_nav/presentation/pages/main_navigation_shell.dart`
- Bottom bar: `lib/features/bottom_nav/presentation/widgets/vilo_floating_bottom_bar.dart`
- Home is kept alive while navigating away so feed tab state is not unnecessarily recreated.
- The Home top tabs are `Community`, `Following`, `For You`, and `Shop`.
- Switching tabs preserves the tab's current state.
- Tapping the already-selected feed tab is the explicit refresh action.
- Refresh state is local to the selected tab; another category must not refresh.

## 3. Network and authentication flow

### API client

Primary file: `lib/core/network/api_client.dart`

Base URL selection:

- Android emulator: `http://10.0.2.2:3000/api/v1`
- Windows, iOS, and web: `http://localhost:3000/api/v1`

Every request uses JSON headers. Authenticated requests attach the access token from `TokenStorage`. A `401` response attempts one refresh-token request; if refresh fails, local tokens are cleared and the user must log in again.

### Login/register

Flutter:

- `lib/features/auth/presentation/pages/login_screen.dart`
- `lib/features/auth/presentation/pages/register_screen.dart`
- `lib/features/auth/data/datasources/auth_remote_data_source.dart`
- `lib/features/auth/data/datasources/token_storage.dart`
- `lib/features/auth/data/models/user_model.dart`

Backend:

- `backend/.../controller/AuthController.java`
- `backend/.../service/AuthService.java`
- `backend/.../service/JwtService.java`
- `backend/.../config/SecurityConfig.java`
- `backend/.../config/JwtAuthenticationFilter.java`

Successful login/register saves access and refresh tokens, saves the current user, updates profile caches, and calls `InboxMessageManager.loadForUser(user.id)`. This account switch is important: it prevents the previous account's conversations from appearing in the new session.

Logout clears tokens and profile/feed caches, then reloads the inbox in guest mode.

Do not put real passwords, JWT secrets, or production database credentials in this document or in source control. Local development values are currently read from `backend/src/main/resources/application.properties`.

## 4. Home and video feed flow

Important files:

- `lib/features/feed/presentation/pages/home_feed_page.dart`
- `lib/features/feed/presentation/pages/community_feed_page.dart`
- `lib/features/feed/presentation/pages/video_feed_page.dart`
- `lib/features/feed/presentation/controllers/video_feed_manager.dart`
- `lib/features/feed/data/datasources/feed_remote_data_source.dart`
- `lib/features/feed/data/models/video_model.dart`
- `lib/features/feed/data/models/video_feed_model.dart`
- `backend/.../controller/VideoController.java`
- `backend/.../service/VideoService.java`
- `backend/.../entity/Video.java`

Feed categories:

- `CommunityFeedPage` shows the community feed.
- `VideoFeedPage(feedType: 'FOLLOWING')` shows followed accounts.
- `VideoFeedPage(feedType: 'FOR_YOU')` shows the recommended feed.
- `ShopPage` is the fourth Home tab.

The For You feed is intended to keep playing when the available list is exhausted. The feed page owns the current list and playback controllers; do not create a second independent feed list in a child widget. When changing feed behavior, preserve the existing keep-alive and tab refresh-token logic.

Video upload goes through `upload_video_sheet.dart` and publishes the uploaded model through `VideoFeedManager`. The feed pages listen for that notifier and can prepend the new video without rebuilding the entire navigation shell.

Video actions are sent through the feed data source/API:

- fetch feed and user videos;
- record a view;
- like/unlike;
- save/unsave;
- load/create/delete comments;
- load videos by sound;
- upload/delete video.

Profile grids should display the video's view count in the bottom-left count position. That count must not be replaced with favourite or save count.

## 5. Hashtag, search, and sound flow

Important files:

- `lib/features/search_discover/presentation/pages/search_screen.dart`
- `lib/features/search_discover/data/datasources/search_remote_data_source.dart`
- `lib/features/search_discover/domain/entities/search_results.dart`
- `lib/features/search_discover/data/datasources/static_search_data.dart`
- `lib/features/feed/presentation/pages/sound_detail_page.dart`
- `backend/.../controller/SearchController.java`
- `backend/.../service/SearchService.java`
- `backend/.../controller/SoundController.java`
- `backend/.../service/SoundService.java`

Expected behavior:

1. Tapping a hashtag from the playing video opens search for that hashtag.
2. Searching for an account can show the account and its public videos underneath.
3. Trending video results are ordered by view count descending.
4. Tapping the sound under the share control opens the sound detail screen.
5. Sound detail uses real sound/video data when available, not only mock music rows.
6. The original video is included/available from the sound detail flow.

When adding a new search result type, keep account results and public-video results distinguishable so the account row does not replace the video list.

## 6. Profile flow

Important files:

- `lib/features/profile/presentation/screens/profile_screen.dart`
- `lib/features/profile/presentation/screens/public_profile_screen.dart`
- `lib/features/profile/presentation/widgets/profile_tab_content.dart`
- `lib/features/profile/presentation/widgets/video_grid_item.dart`
- `lib/features/profile/presentation/widgets/shop_product_card.dart`
- `lib/features/profile/data/datasources/profile_remote_data_source.dart`
- `lib/features/profile/data/datasources/profile_sync_service.dart`
- `backend/.../controller/UserController.java`
- `backend/.../service/UserService.java`

Own-profile and public-profile tabs may show posted videos, saved videos, liked/favourite videos, and products. The profile data source is responsible for selecting the current user's data versus another user's public data.

Profile identity must come from the current/canonical user profile. Avoid copying a stale username or avatar into a message, profile, product, or order card. Use `ProfileSyncService` and `ProfileRemoteDataSource` when resolving the active profile.

Product cards shown in a profile use `shop_product_card.dart`. Product loading for a seller goes through `/products/by-seller/{sellerId}` and should remain separate from a user's video tabs.

## 7. Inbox and direct-message flow

Important files:

- `lib/features/inbox_activity/data/datasources/inbox_message_manager.dart`
- `lib/features/inbox_activity/domain/entities/inbox_item.dart`
- `lib/features/inbox_activity/presentation/pages/inbox_screen.dart`
- `lib/features/inbox_activity/presentation/pages/chat_detail_screen.dart`
- `lib/features/inbox_activity/data/datasources/static_inbox_data.dart`
- `backend/.../controller/ChatController.java`
- `backend/.../service/ChatService.java`
- `backend/.../entity/ChatMessageEntity.java`
- `backend/.../repository/ChatMessageRepository.java`
- `backend/.../dto/ChatMessageRequest.java`
- `backend/.../dto/ChatMessageResponse.java`

### Canonical conversation identity

`InboxMessageManager.buildThreadId(handle1, handle2)` removes `@`, normalizes case, sorts the two handles, and creates a symmetric ID:

```text
dm_<alphabetically-first-handle>_<alphabetically-second-handle>
```

Therefore both participants must resolve to the same thread. Never use a one-sided `chat_<sender>_<recipient>` key for new messages.

### Message lifecycle

1. Login calls `loadForUser`.
2. The manager loads the current user's versioned SharedPreferences key.
3. Legacy static/mock threads are filtered out.
4. Remote conversations are loaded from `/api/v1/chats/conversations` and merged.
5. Messages are loaded from `/api/v1/chats/{threadId}/messages`.
6. The manager deduplicates by peer and message ID.
7. `resolveThreadForActiveUser` maps sender/recipient and avatar data from the active user's perspective.
8. `ChatDetailScreen` refreshes the current conversation while open so a status change made by the other participant appears without leaving and reopening the inbox.

The local manager is account-scoped and also writes to the remote database when authenticated. Clearing messages should use `clearAllMessages`; do not only clear the visible widget list.

### Order messages

Order/inquiry messages must carry the exact order reference when they are created. Cancellation must match that reference, not only a product title. Product-title matching is only a legacy fallback for old messages that have no `orderReference`.

Free-form messages sent from a seller profile must remain normal chat messages. They must not be interpreted as a new order or cancel/modify an existing order.

## 8. Shop, product, checkout, and order flow

Important Flutter files:

- `lib/features/shop/views/shop_feed_screen.dart`
- `lib/features/shop/views/shop_search_results_screen.dart`
- `lib/features/shop/views/product_detail_screen.dart`
- `lib/features/shop/presentation/pages/product_detail_page.dart`
- `lib/features/shop/presentation/pages/add_product_screen.dart`
- `lib/features/shop/presentation/pages/cart_page.dart`
- `lib/features/shop/presentation/pages/checkout_page.dart`
- `lib/features/shop/presentation/pages/order_history_page.dart`
- `lib/features/shop/presentation/controllers/cart_controller.dart`
- `lib/features/shop/data/datasources/shop_remote_data_source.dart`
- `lib/features/shop/services/shop_service.dart`
- `lib/features/shop/data/models/product_model.dart`
- `lib/features/shop/data/models/cart_item_model.dart`
- `lib/features/shop/data/models/order_model.dart`
- `lib/features/shop/models/product.dart`

Important backend files:

- `backend/.../controller/ProductController.java`
- `backend/.../service/ProductService.java`
- `backend/.../entity/Product.java`
- `backend/.../controller/CartController.java`
- `backend/.../service/CartService.java`
- `backend/.../entity/CartItem.java`
- `backend/.../controller/OrderController.java`
- `backend/.../service/OrderService.java`
- `backend/.../entity/Order.java`
- `backend/.../entity/OrderItem.java`
- `backend/.../entity/OrderStatus.java`
- `backend/.../dto/CheckoutRequest.java`
- `backend/.../dto/OrderResponse.java`

### Product flow

1. A seller opens `AddProductScreen`.
2. Product details, seller identity, price, stock, images, and optional video/category links are submitted.
3. Backend persists the product and returns a product response.
4. Profile and shop pages load products from the backend; seller profile products use the seller endpoint.
5. Product thumbnails must use the product's own image list/primary image, not a random unrelated thumbnail.

### Cart and checkout flow

1. A product is added from shop/product detail/profile UI.
2. `CartController` keeps the active cart and uses `ShopRemoteDataSource` for authenticated server calls.
3. `CheckoutPage` validates the address and sends `shippingAddress`, `paymentMethod`, and optional `notes` to `/orders/checkout`.
4. The backend validates stock, reserves stock, increments sales count, creates order items, and persists the order.
5. The Flutter client clears the cart after success and records the returned order.
6. If the request fails, the data source creates a local fallback order so the UI remains usable offline.

The checkout note is stored in `OrderModel.notes` and is returned by the backend. If a new UI needs to display it, use the order model value; do not recreate it from the payment method or chat text.

### Order status and cancellation flow

- `OrderHistoryPage` displays the current order status and allows cancellation for pending orders.
- `OrderModel.dynamicStatus` preserves explicit cancellation and maps older paid/delivered orders to the displayed success state after the configured elapsed period.
- Cancellation restores stock and sold counts locally, updates the local order status, sends cancellation updates through `InboxMessageManager.cancelOrderInChats`, and calls the remote order-status update when available.
- Cancellation must affect only the selected order. Matching by a reused short order suffix or only by product title can cancel unrelated newer orders.
- The buyer and seller must read the same canonical chat message/order reference so both sides show the same cancellation state.

The current My Orders layout uses flexible/ellipsized rows for long order references, status badges, item subtotals, payment text, and totals. Preserve those constraints when adding fields to the card.

## 9. Backend endpoint map

All routes below are prefixed by `/api/v1` unless noted otherwise.

### Auth and users

```text
POST   /auth/register
POST   /auth/login
POST   /auth/refresh
POST   /auth/logout
GET    /users/me
PUT    /users/me
GET    /users/suggestions
GET    /users/{identifier}
GET    /users/{identifier}/followers
GET    /users/{identifier}/following
POST   /users/{identifier}/follow
DELETE /users/{identifier}/follow
GET    /users/{identifier}/sounds
GET    /users/{identifier}/videos
GET    /users/{identifier}/saved
GET    /users/{identifier}/liked
```

### Videos and sounds

```text
GET    /videos/feed
GET    /videos/user/{identifier}
GET    /videos/saved
GET    /videos/liked
GET    /videos/user/{identifier}/liked
GET    /videos/my-videos
GET    /videos/my-sounds
GET    /videos/by-sound
GET    /videos/{id}
POST   /videos/upload
DELETE /videos/{id}
POST   /videos/{id}/like
DELETE /videos/{id}/like
POST   /videos/{id}/save
DELETE /videos/{id}/save
GET    /videos/{id}/comments
POST   /videos/{id}/comments
DELETE /videos/{videoId}/comments/{commentId}
POST   /videos/{id}/view
GET    /sounds
GET    /sounds/trending
GET    /sounds/{id}
GET    /sounds/{id}/videos
POST   /sounds/upload
DELETE /sounds/{id}
PATCH  /sounds/{id}
```

### Search

```text
GET    /search
GET    /explore/trending
GET    /search/history
POST   /search/history
DELETE /search/history
DELETE /search/history/{id}
```

### Chat, shop, and orders

```text
POST   /chats/messages
GET    /chats/conversations
GET    /chats/{threadId}/messages
GET    /categories
GET    /products
GET    /products/{id}
GET    /products/by-video/{videoId}
GET    /products/by-seller/{sellerId}
POST   /products
POST   /products/{id}/deduct-stock
GET    /cart
POST   /cart/items
PUT    /cart/items/{itemId}
DELETE /cart/items/{itemId}
DELETE /cart
POST   /orders/checkout
GET    /orders/history
GET    /orders/{id}
```

`ProductController` also exposes `/api/products` aliases for product routes. Check the controller before adding another route so duplicate API paths are not introduced.

## 10. Persistence and identity rules

### Remote persistence

- PostgreSQL stores users, videos, sounds, products, carts, orders, comments, follows, likes/saves, and chat messages.
- JPA schema behavior is configured in `backend/src/main/resources/application.properties`.
- Backend local server port is `3000`.

### Flutter local persistence

- Tokens/user identity: `TokenStorage`.
- Chat threads/drafts: versioned SharedPreferences keys managed by `InboxMessageManager`.
- Local/offline orders: `ShopRemoteDataSource` user-scoped order maps.
- Profile identity cache: `ProfileSyncService` and `ProfileRemoteDataSource`.
- Feed runtime updates: `VideoFeedManager` notifiers.

When switching accounts, clear or reload every account-scoped manager. A user ID or username must be part of any local storage key that can contain private data.

## 11. Local development commands

Run backend from the project root:

```powershell
Set-Location backend
& 'C:\Users\thoeu\.m2\wrapper\dists\apache-maven-3.9.11\d6d3cbd4012d4c1d840e93277aca316c\bin\mvn.cmd' '-Dmaven.test.skip=true' 'package'
```

Run the generated jar:

```powershell
& java -jar 'backend\target\backend-0.0.1-SNAPSHOT.jar'
```

Find and stop the process using port 3000:

```powershell
Get-NetTCPConnection -LocalPort 3000 -State Listen | Select-Object OwningProcess
Stop-Process -Id <PID> -Force
```

Run Flutter:

```powershell
flutter pub get
flutter run
```

Useful checks:

```powershell
flutter analyze
flutter test --no-pub --concurrency=1
git diff --check
```

On this machine, Dart analysis has reported `No issues found!` but may still exit non-zero when Dart telemetry cannot update `C:\Users\thoeu\AppData\Roaming\.dart-tool\dart-flutter-telemetry-session.json`. Treat that specific telemetry permission error separately from analyzer findings.

## 12. Testing map

Relevant tests currently include:

- `test/widget_test.dart`
- `test/upload_sound_sheet_test.dart`
- `test/features/inbox_activity/inbox_message_manager_test.dart`
- `test/features/shop/product_test.dart`
- `test/features/shop/shop_service_test.dart`
- `test/features/shop/product_enhancements_and_cancellation_test.dart`
- `test/profile_post_product_flow_test.dart`

For chat/order changes, test both accounts in the same canonical thread:

1. Log in as buyer and seller separately.
2. Send a normal message and confirm both sides see it with correct sender alignment and current profile data.
3. Create separate orders for the same product.
4. Cancel only one order.
5. Confirm only its exact order message changes to cancelled on both accounts.
6. Create/send another normal message and confirm it does not cancel an order.
7. Leave and re-enter the conversation to verify remote reload and local merge remain identical.

For feed changes, verify category switching, same-tab refresh, leaving Home and returning, For You loop behavior, hashtag search, sound detail/original video, and profile view counts.

## 13. Change checklist

Before considering a feature complete:

- Trace the Flutter page -> data source/service -> API controller -> service -> repository/entity path.
- Preserve account scoping and canonical IDs.
- Keep existing Home tab state and refresh behavior.
- Keep long text inside `Expanded`, `Flexible`, or ellipsized text constraints.
- Add or update a focused test when the change is deterministic.
- Run analyzer/tests as far as the local environment allows.
- Run `git diff --check` and review only files belonging to the task.
- Do not commit credentials, tokens, database passwords, or generated build output.
