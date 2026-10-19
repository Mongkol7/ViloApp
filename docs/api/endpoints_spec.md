# Vilo API Specifications & Contracts

## Base Configuration
- Development URL: `http://localhost:3000/api/v1` (or `http://10.0.2.2:3000/api/v1` in Android Emulator)
- Protocol: REST / JSON
- Media Static Serving: `http://localhost:3000/uploads/**`
- Authentication: Bearer JWT in `Authorization: Bearer <token>` Header

---

## Live Endpoints

### 1. Authentication Service (`/api/v1/auth`)
- `POST /auth/register`: Create a new user account.
  - Body: `{ "username": "string", "email": "string", "password": "string", "displayName": "string" }`
- `POST /auth/login`: Authenticate and issue JWT access token.
  - Body: `{ "emailOrUsername": "string", "password": "string" }`
  - Response: `{ "success": true, "token": "...", "user": { ... } }`
- `POST /auth/refresh`: Renew expired access token using refresh token.
- `POST /auth/logout`: Invalidate current session token.

### 2. User & Profile Service (`/api/v1/users`)
- `GET /users/me`: Retrieve current authenticated user profile (`requireAuth: true`).
- `GET /users/{idOrUsername}`: Retrieve public creator profile by ID or `@username`.
- `PUT /users/me`: Update profile display name, bio, and avatar.
- `POST /users/{id}/follow`: Follow creator. Emits real-time count change.
- `DELETE /users/{id}/follow`: Unfollow creator.
- `GET /users/{id}/followers`: List of followers with follow status.
- `GET /users/{id}/following`: List of accounts followed by user.

### 3. Video & Media Feed Service (`/api/v1/videos`)
- `GET /videos/feed?page=0&size=10&type=foryou`: Paginated short-form video stream (`foryou` or `following`).
- `GET /videos/user/{idOrUsername}`: List all videos posted by a specific creator.
- `GET /videos/{id}`: Detailed metadata for a single video.
- `POST /videos/upload` (Multipart Form Data):
  - `videoFile` (binary multipart): Video media (`.mp4`, `.mov`, `.webm`) or image/photo post (`.jpg`, `.png`, `.webp`).
  - `thumbnailFile` (binary multipart, optional): Video poster/thumbnail image.
  - `caption` (text): Video caption.
  - `tags` (text): Comma-delimited list of hashtags.
  - Response: Returns created `VideoModel` JSON payload.
- `POST /videos/{id}/like` & `DELETE /videos/{id}/like`: Toggle like state.
- `POST /videos/{id}/save` & `DELETE /videos/{id}/save`: Toggle bookmark/collection save.
- `POST /videos/{id}/view`: Asynchronously increment video view counter.
- `GET /videos/{id}/comments`: Paginated comment list for video.
- `POST /videos/{id}/comments`: Submit new comment or reply.

### 4. Static Media Storage (`/uploads/**`)
- `GET /uploads/videos/{filename}`: Stream uploaded video file (`Content-Type: video/mp4`).
- `GET /uploads/photos/{filename}`: Stream uploaded photo post image.
- `GET /uploads/thumbnails/{filename}`: Serve video preview poster image.

### 5. Search & Discovery Service (`/api/v1/search`)
- `GET /search/trending`: Top trending video grid, featured accounts, and popular audio.
- `GET /search?q={query}`: Multi-entity search across Top, Accounts, Videos, Sounds, and Shop.
- `GET /search/history`: Retrieve recent search queries.
- `POST /search/history`: Record query to search history.
- `DELETE /search/history`: Clear search history.
