---
name: audiobookshelf-api
description: Reference skill for interacting with the Audiobookshelf REST API. Covers authentication, all endpoint groups, filtering, pagination, and Socket.io events. Use when writing code or scripts that talk to an Audiobookshelf server.
---

# Audiobookshelf API Skill

> **Note:** The official docs at https://api.audiobookshelf.org are self-described as out-of-date and no longer maintained. OpenAPI docs are planned. Treat this reference as a best-effort guide; verify against a live server when in doubt.

## Quick Reference

| Topic | Summary |
|---|---|
| Auth | Bearer token in `Authorization` header; GET requests can use `?token=` |
| Base URL | Non-API: `https://abs.example.com/`; API: `https://abs.example.com/api/` |
| Timestamps | All timestamps are milliseconds since Unix epoch |
| Media types | `book` or `podcast` - libraries and items are strictly one type |
| User types | `guest`, `user`, `admin`, `root` |
| Pagination | `limit` + `page` (0-indexed); `page` has no effect unless `limit > 0` |

---

## Authentication

### Obtaining a Token

**Admin UI:** Log in as admin, go to Config -> Users, click your account - the token is displayed.

**Programmatic login:**
```sh
curl -X POST "https://abs.example.com/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "root", "password": "secret"}'
# Token is at response.user.token
```

**If token is already persisted:**
```sh
curl -X POST "https://abs.example.com/api/authorize" \
  -H "Authorization: Bearer <token>"
# Returns current user + server settings
```

### Using a Token

All `/api/` endpoints require the token as a Bearer header:
```
Authorization: Bearer <token>
```

GET requests may optionally pass it as a query string instead:
```
GET /api/items/<ID>?token=<token>
```

### OAuth2 / SSO (PKCE flow)
1. `GET /auth/openid` with `code_challenge`, `code_challenge_method=S256`, `redirect_uri`, `client_id`, `state`
2. Follow the 302 redirect to the SSO provider in a browser
3. SSO redirects back to `redirect_uri?code=<code>&state=<state>`
4. `GET /auth/openid/callback?state=<state>&code=<code>&code_verifier=<verifier>` (send cookies from step 1)
5. Token is returned at `user.token`

**Rate limit on login:** Default 10 requests per 10 minutes (configurable in server settings).

---

## Endpoint Reference

### Server (no `/api` prefix)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/login` | Login with username + password |
| POST | `/logout` | Logout (optional `socketId` body param) |
| GET | `/status` | Server init status and language |
| GET | `/ping` | Health check returning `{"success": true}` |
| GET | `/healthcheck` | Minimal liveness check |
| POST | `/init` | Initialize a new server with a root user |
| GET | `/auth/openid` | Start OAuth2 PKCE flow |
| GET | `/auth/openid/callback` | Complete OAuth2 flow |
| GET | `/auth/openid/mobile-redirect` | Internal SSO redirect (do not call directly) |

### Libraries

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/libraries` | Get all libraries accessible to the user |
| POST | `/api/libraries` | Create a library |
| GET | `/api/libraries/<ID>` | Get a library; add `?include=filterdata` for filter metadata |
| PATCH | `/api/libraries/<ID>` | Update a library |
| DELETE | `/api/libraries/<ID>` | Delete a library (also deletes all items and user progress) |
| GET | `/api/libraries/<ID>/items` | Browse items with sort/filter/pagination |
| DELETE | `/api/libraries/<ID>/issues` | Remove all items with issues |
| GET | `/api/libraries/<ID>/episode-downloads` | Podcast episode download queue |
| GET | `/api/libraries/<ID>/series` | Paginated series list |
| GET | `/api/libraries/<ID>/collections` | Paginated collections list |
| GET | `/api/libraries/<ID>/playlists` | User playlists in this library |
| GET | `/api/libraries/<ID>/personalized` | Personalized shelves view |
| GET | `/api/libraries/<ID>/filterdata` | Authors, genres, tags, series, narrators |
| GET | `/api/libraries/<ID>/search` | Full-text search (`?q=`) |
| GET | `/api/libraries/<ID>/stats` | Library statistics |
| GET | `/api/libraries/<ID>/authors` | Paginated authors list |
| POST | `/api/libraries/<ID>/scan` | Trigger a folder scan |
| GET | `/api/libraries/<ID>/recent-episodes` | Recent podcast episodes |
| POST | `/api/libraries/order` | Reorder libraries |

**Library creation params:** `name` (required), `folders` (required, array with `fullPath`), `icon`, `mediaType` (`book`/`podcast`), `provider`, `settings`

**Library icons:** `database`, `audiobook`, `podcast`, `comic`, `magazine`

**Metadata providers (books):** `google`, `openlibrary`, `itunes`, `audible`, `audible.ca`, `audible.uk`, `audible.au`, `audible.fr`, `audible.de`, `audible.jp`, `audible.it`, `audible.in`, `audible.es`, `fantlab`

**Metadata providers (podcasts):** `itunes`

**Updating folders:** You must pass the full folder array - any folder omitted will be removed.

### Library Items

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/items/<ID>` | Get a library item |
| DELETE | `/api/items/<ID>` | Delete a library item |
| PATCH | `/api/items/<ID>/media` | Update media metadata |
| GET | `/api/items/<ID>/cover` | Get cover image |
| POST | `/api/items/<ID>/cover` | Upload a cover image |
| PATCH | `/api/items/<ID>/cover` | Update cover (URL or file) |
| DELETE | `/api/items/<ID>/cover` | Remove cover |
| POST | `/api/items/<ID>/match` | Match item against metadata provider |
| POST | `/api/items/<ID>/play` | Start a playback session |
| POST | `/api/items/<ID>/play/<EpisodeID>` | Start a podcast episode playback session |
| PATCH | `/api/items/<ID>/tracks` | Update audio tracks |
| POST | `/api/items/<ID>/scan` | Scan a single item |
| GET | `/api/items/<ID>/tone-object` | Get Tone metadata object |
| POST | `/api/items/<ID>/chapters` | Update chapters |
| POST | `/api/items/<ID>/tone-scan` | Tone-scan a single item |
| POST | `/api/items/batch/delete` | Batch delete items |
| POST | `/api/items/batch/update` | Batch update items |
| POST | `/api/items/batch/get` | Batch get items |
| POST | `/api/items/batch/quickmatch` | Batch quick-match items |
| DELETE | `/api/items/all` | Remove all items from DB (does NOT delete files; admin only) |

### Users

Admin required for most operations.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/users` | Get all users |
| POST | `/api/users` | Create a user |
| GET | `/api/users/online` | Get online users |
| GET | `/api/users/<ID>` | Get a user |
| PATCH | `/api/users/<ID>` | Update a user |
| DELETE | `/api/users/<ID>` | Delete a user |
| GET | `/api/users/<ID>/listening-sessions` | User's listening history |
| GET | `/api/users/<ID>/listening-stats` | User's aggregated stats |
| POST | `/api/users/<ID>/purge-media-progress` | Purge all media progress for a user |

### Collections

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/collections` | Get all collections |
| POST | `/api/collections` | Create a collection |
| GET | `/api/collections/<ID>` | Get a collection |
| PATCH | `/api/collections/<ID>` | Update a collection |
| DELETE | `/api/collections/<ID>` | Delete a collection |
| POST | `/api/collections/<ID>/book` | Add a book to a collection |
| DELETE | `/api/collections/<ID>/book/<BookID>` | Remove a book |
| POST | `/api/collections/<ID>/batch/add` | Batch add books |
| POST | `/api/collections/<ID>/batch/remove` | Batch remove books |

### Playlists

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/playlists` | Get all user playlists |
| POST | `/api/playlists` | Create a playlist |
| GET | `/api/playlists/<ID>` | Get a playlist |
| PATCH | `/api/playlists/<ID>` | Update a playlist |
| DELETE | `/api/playlists/<ID>` | Delete a playlist |
| POST | `/api/playlists/<ID>/item` | Add an item |
| DELETE | `/api/playlists/<ID>/item/<ItemID>` | Remove an item |
| POST | `/api/playlists/<ID>/batch/add` | Batch add items |
| POST | `/api/playlists/<ID>/batch/remove` | Batch remove items |
| POST | `/api/playlists/collection/<CollectionID>` | Create playlist from collection |

### Me (Authenticated User - Progress and Bookmarks)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/me` | Get current user |
| GET | `/api/me/listening-sessions` | Listening history |
| GET | `/api/me/listening-stats` | Aggregated listening stats |
| GET | `/api/me/items-in-progress` | All in-progress library items |
| GET | `/api/me/progress/<LibraryItemID>` | Get progress for an item |
| GET | `/api/me/progress/<LibraryItemID>/<EpisodeID>` | Get progress for a podcast episode |
| PATCH | `/api/me/progress/<LibraryItemID>` | Create or update progress |
| PATCH | `/api/me/progress/<LibraryItemID>/<EpisodeID>` | Create or update podcast episode progress |
| PATCH | `/api/me/progress/batch/update` | Batch create/update progress |
| DELETE | `/api/me/progress/<ID>` | Remove a progress entry |
| GET | `/api/me/progress/<ID>/remove-from-continue-listening` | Hide from continue listening |
| GET | `/api/me/series/<ID>/remove-from-continue-listening` | Hide a series from continue listening |
| POST | `/api/me/item/<ID>/bookmark` | Create a bookmark |
| PATCH | `/api/me/item/<ID>/bookmark` | Update a bookmark |
| DELETE | `/api/me/item/<ID>/bookmark/<Time>` | Remove a bookmark (time in seconds) |
| PATCH | `/api/me/password` | Change password |
| POST | `/api/me/sync-local-progress` | Sync local progress from a client |

**Progress fields:** `currentTime` (seconds), `isFinished` (bool), `hideFromContinueListening` (bool), `progress` (0.0-1.0)

### Sessions

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/sessions` | Get all sessions (admin) |
| DELETE | `/api/sessions/<ID>` | Delete a session (admin) |
| POST | `/api/session/local` | Sync a local playback session |
| POST | `/api/session/local-all` | Sync multiple local sessions |
| GET | `/api/session/<ID>` | Get an open playback session |
| POST | `/api/session/<ID>/sync` | Sync progress for an open session |
| POST | `/api/session/<ID>/close` | Close an open playback session |

### Podcasts

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/podcasts` | Create a podcast library item |
| POST | `/api/podcasts/feed` | Get a podcast feed from URL |
| POST | `/api/podcasts/opml` | Get podcast feeds from OPML |
| GET | `/api/podcasts/<ID>/checknew` | Check for new episodes |
| GET | `/api/podcasts/<ID>/downloads` | Episode download queue |
| GET | `/api/podcasts/<ID>/clear-queue` | Clear episode download queue |
| GET | `/api/podcasts/<ID>/search-episode` | Search feed for episodes (`?title=`) |
| POST | `/api/podcasts/<ID>/download-episodes` | Queue episodes for download |
| POST | `/api/podcasts/<ID>/match-episodes` | Match episodes against feed |
| GET | `/api/podcasts/<ID>/episode/<EpisodeID>` | Get a specific episode |
| PATCH | `/api/podcasts/<ID>/episode/<EpisodeID>` | Update episode metadata |
| DELETE | `/api/podcasts/<ID>/episode/<EpisodeID>` | Delete an episode |

### Authors and Series

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/authors/<ID>` | Get an author |
| PATCH | `/api/authors/<ID>` | Update an author |
| POST | `/api/authors/<ID>/match` | Match against external provider |
| GET | `/api/authors/<ID>/image` | Get author image |
| GET | `/api/series/<ID>` | Get a series |
| PATCH | `/api/series/<ID>` | Update a series |

### Backups

Admin only.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/backups` | Get all backups |
| POST | `/api/backups` | Create a backup |
| DELETE | `/api/backups/<ID>` | Delete a backup |
| POST | `/api/backups/<ID>/apply` | Apply (restore) a backup |
| POST | `/api/backups/upload` | Upload a backup file |

### Search (External Metadata)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/search/covers` | Search for cover images (`?title=`, `?author=`) |
| GET | `/api/search/books` | Search for books (`?title=`, `?author=`, `?provider=`) |
| GET | `/api/search/podcast` | Search for podcasts (`?term=`) |
| GET | `/api/search/authors` | Search for an author (`?q=`) |
| GET | `/api/search/chapters` | Search for chapters (`?asin=`) |

### Notifications

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/notifications` | Get notification settings |
| PATCH | `/api/notifications` | Update notification settings |
| GET | `/api/notifications/data` | Get notification event data |
| GET | `/api/notifications/test` | Fire a test notification event |
| POST | `/api/notifications` | Create a notification |
| DELETE | `/api/notifications/<ID>` | Delete a notification |
| PATCH | `/api/notifications/<ID>` | Update a notification |
| GET | `/api/notifications/<ID>/test` | Send a notification test |

### RSS Feeds

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/feeds/item/<LibraryItemID>/open` | Open an RSS feed for a library item |
| POST | `/api/feeds/collection/<CollectionID>/open` | Open an RSS feed for a collection |
| POST | `/api/feeds/series/<SeriesID>/open` | Open an RSS feed for a series |
| POST | `/api/feeds/<ID>/close` | Close an RSS feed |

### Misc

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/upload` | Upload files to a library folder |
| PATCH | `/api/settings` | Update server settings (admin) |
| POST | `/api/authorize` | Get authorized user + server info from persisted token |
| GET | `/api/tags` | Get all tags |
| POST | `/api/tags/rename` | Rename a tag across all items |
| DELETE | `/api/tags/<Tag>` | Delete a tag |
| GET | `/api/genres` | Get all genres |
| POST | `/api/genres/rename` | Rename a genre across all items |
| DELETE | `/api/genres/<Genre>` | Delete a genre |
| POST | `/api/validate-cron` | Validate a cron expression |
| POST | `/api/cache/purge` | Purge all cache (admin) |
| POST | `/api/cache/items/purge` | Purge items cache (admin) |
| POST | `/api/tools/item/<ID>/encode-m4b` | Encode a book as M4B |
| DELETE | `/api/tools/item/<ID>/encode-m4b` | Cancel an M4B encode task |
| POST | `/api/tools/item/<ID>/embed-metadata` | Embed metadata into audio files |

---

## Filtering

Pass filters via the `filter` query parameter on library item listing endpoints.

### Format

```
filter=<group>.<BASE64_URL_ENCODED_value>
```

### Encoding a Filter Value

```sh
# Example: filter by progress "in-progress"
echo -n "in-progress" | base64        # aW4tcHJvZ3Jlc3M=
# URL-encode the base64 output, then combine:
filter=progress.aW4tcHJvZ3Jlc3M%3D
```

### Available Filter Groups

| Group | Target | Example Values |
|-------|--------|----------------|
| `genres` | books + podcasts | Genre string |
| `tags` | books + podcasts | Tag string |
| `series` | books | Series ID or `no-series` |
| `authors` | books | Author ID |
| `narrators` | books | Narrator name |
| `languages` | books + podcasts | Language string |
| `progress` | books + podcasts | `finished`, `not-started`, `not-finished`, `in-progress` |
| `missing` | books | `asin`, `isbn`, `subtitle`, `authors`, `publishedYear`, `series`, `description`, `genres`, `tags`, `narrators`, `publisher`, `language` |
| `tracks` | books | `single`, `multi` |

### Special Standalone Filters (no value, no encoding)

```
filter=issues        # Items with issues
filter=feed-open     # Items with an open RSS feed
```

### Sorting

The `sort` query parameter uses JavaScript dot-notation attribute paths:

```
sort=media.metadata.title
sort=media.metadata.authorName
sort=media.duration
sort=addedAt
sort=sequence      # Series sort when filtering by a series
```

---

## Pagination

```sh
# Page 2 of results, 25 per page, sorted by title
GET /api/libraries/<ID>/items?limit=25&page=1&sort=media.metadata.title
```

- `page` is 0-indexed
- `page` has no effect unless `limit > 0`
- `limit=0` returns all results with no pagination

---

## Socket.io Real-Time Events

Connect with Socket.io, then immediately emit `auth` with the API token. Re-authenticate after every reconnect.

```js
const socket = io("https://abs.example.com")
socket.emit("auth", token)
socket.on("connect", () => socket.emit("auth", token))
```

### Client-Emitted Events

| Event | Payload | Description |
|-------|---------|-------------|
| `auth` | API token string | Authenticate the socket connection |
| `ping` | - | Connectivity check (server responds with `pong`) |
| `cancel_scan` | library ID | Cancel a running scan |
| `set_log_listener` | log level | Subscribe to server log events |
| `remove_log_listener` | - | Unsubscribe from logs |
| `fetch_daily_logs` | - | Request today's log events |
| `message_all_users` | message string | Broadcast to all users (admin) |

### Server-Emitted Events (Selected)

| Category | Key Events |
|----------|------------|
| Auth | `invalid_token`, `init` |
| Users (admin only) | `user_online`, `user_offline`, `user_added`, `user_updated`, `user_removed` |
| Progress | `user_item_progress_updated` |
| Streams | `stream_open`, `stream_closed`, `stream_progress`, `stream_ready`, `stream_error` |
| Libraries | `library_added`, `library_updated`, `library_removed` |
| Scans | `scan_start`, `scan_complete` |
| Items | `item_added`, `item_updated`, `item_removed`, `items_added`, `items_updated` |
| Authors | `author_added`, `author_updated`, `author_removed` |
| Series | `series_added`, `series_updated` |
| Collections | `collection_added`, `collection_updated`, `collection_removed` |
| Playlists | `playlist_added`, `playlist_updated`, `playlist_removed` |
| RSS | `rss_feed_open`, `rss_feed_closed` |
| Podcasts | `episode_download_queued`, `episode_download_started`, `episode_download_finished` |
| Audio | `audio_metadata_started`, `audio_metadata_finished` |
| Misc | `log`, `daily_logs`, `admin_message`, `pong`, `batch_quickmatch_complete` |

---

## Common Workflows

### Get all audiobooks in a library and list titles

```sh
TOKEN="your_token"
LIB_ID="lib_xxx"
curl "https://abs.example.com/api/libraries/${LIB_ID}/items?limit=0&sort=media.metadata.title" \
  -H "Authorization: Bearer ${TOKEN}" \
  | jq '.results[].media.metadata.title'
```

### Search a library

```sh
curl "https://abs.example.com/api/libraries/${LIB_ID}/search?q=foundation" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Filter by progress (in-progress items)

```sh
FILTER=$(printf 'in-progress' | base64 | python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))")
curl "https://abs.example.com/api/libraries/${LIB_ID}/items?filter=progress.${FILTER}" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Update reading progress

```sh
curl -X PATCH "https://abs.example.com/api/me/progress/${ITEM_ID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"currentTime": 3600, "isFinished": false}'
```

### Start a playback session

```sh
curl -X POST "https://abs.example.com/api/items/${ITEM_ID}/play" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"deviceInfo": {"clientName": "my-script"}, "supportedMimeTypes": ["audio/mpeg"]}'
```

### Open an RSS feed for a library item

```sh
curl -X POST "https://abs.example.com/api/feeds/item/${ITEM_ID}/open" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"serverAddress": "https://abs.example.com", "slug": "my-feed-slug"}'
```

---

## Key Data Schemas

### Library Item (book)

```json
{
  "id": "li_...",
  "libraryId": "lib_...",
  "folderId": "fol_...",
  "path": "/audiobooks/Author/Title",
  "mediaType": "book",
  "media": {
    "metadata": {
      "title": "...",
      "authorName": "...",
      "seriesName": "...",
      "narratorName": "...",
      "publishedYear": "...",
      "asin": "...",
      "isbn": "...",
      "genres": [],
      "description": "..."
    },
    "coverPath": "...",
    "tags": [],
    "duration": 12000.0,
    "numTracks": 1,
    "numAudioFiles": 1,
    "numChapters": 1
  },
  "addedAt": 1650621073750,
  "updatedAt": 1650621110769,
  "isMissing": false,
  "isInvalid": false
}
```

### Media Progress

```json
{
  "id": "...",
  "libraryItemId": "li_...",
  "episodeId": null,
  "duration": 12000.0,
  "progress": 0.5,
  "currentTime": 6000.0,
  "isFinished": false,
  "hideFromContinueListening": false,
  "lastUpdate": 1668586015691,
  "startedAt": 1668120083771,
  "finishedAt": null
}
```

---

## Never / Always

**Never:**
- Never call `DELETE /api/items/all` without confirmation - it removes all items from the database.
- Never call `DELETE /api/libraries/<ID>` without confirmation - it also deletes all items and all user progress.
- Never omit existing folders when PATCHing a library - missing folders are removed.
- Never assume `page` pagination works when `limit` is 0 or unset.

**Always:**
- Always re-authenticate the Socket.io connection after a reconnect.
- Always Base64 + URL encode filter values (except `issues` and `feed-open`).
- Always confirm the library's `mediaType` before crafting requests - some endpoints and fields only apply to `book` or `podcast`.
- Always use millisecond timestamps when constructing request bodies.
