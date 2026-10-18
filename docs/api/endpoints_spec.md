# Vilo API Specifications & Contracts

## Base Configuration
- Development URL: `http://localhost:3000/api/v1`
- Protocol: REST / JSON & WebSocket (Chats/Notifications)
- Authentication: Bearer JWT in Authorization Header

---

## Key Feature Endpoints

### 1. Feed Service
- `GET /feed/for-you`: Paginated shortform video stream with preloading tokens.
- `GET /feed/following`: Videos published by followed creators.
- `POST /feed/videos/{id}/like`: Toggle video like state.
- `POST /feed/videos/{id}/bookmark`: Save video to collection.
- `GET /feed/videos/{id}/comments`: Fetch comment thread with nested replies.

### 2. Shop Service
- `GET /shop/products`: Paginated product catalog with category & price filters.
- `GET /shop/products/{id}`: Full product specifications, variants, media, and seller data.
- `POST /shop/cart/items`: Add or update item quantity in cart.
- `POST /shop/checkout`: Initiate order checkout and payment intent.

### 3. Search & Discover Service
- `GET /search/trending`: Top trending video grid, featured accounts, and trending sounds.
- `GET /search/query?q={query}`: Universal query matching across Videos, Accounts, Sounds, and Products.

### 4. Profile & Friends
- `GET /friends/suggestions`: Recommended creators and contacts based on social graph.
- `POST /friends/{id}/follow`: Follow/unfollow creator.
- `DELETE /friends/suggestions/{id}`: Dismiss suggestion.
