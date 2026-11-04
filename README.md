# Synapse

Synapse is a Flutter direct-messaging application with a Node.js/Express
backend, PostgreSQL persistence, and Socket.IO real-time events. The web client
is served by nginx and the complete local stack can be run with Docker Compose.

## Current status

The core direct-message experience is implemented, including:

- Registration, login, short-lived access tokens, and rotating refresh tokens.
- Per-device sessions, session revocation, logout-all-devices, and password changes.
- Password-confirmed permanent account deletion, including related data and avatars.
- User profiles with usernames, display names, bios, and WebP avatars.
- Searchable users, friend requests, friendships, muting, and blocking.
- Direct conversations with persisted message history.
- Real-time messaging over Socket.IO with HTTP history and recovery.
- `pending`, `sent`, `delivered`, and `read` message lifecycle states.
- Client-message idempotency to prevent duplicate submissions.
- Pagination, reconnect synchronization, delivery acknowledgements, and read cursors.
- Persisted notifications, unread indicators, and notification center support.
- Light/dark presets and customizable theme colors.
- Configurable request, upload, authentication, message, WebSocket, and duplicate
  request limits.
- Automated backend and Flutter test coverage for authentication and messaging
  synchronization behavior.

Group conversations, attachments beyond profile pictures, push notifications,
message editing/deletion, and voice/video features are not implemented yet.
See [TO-DO-LIST.md](./TO-DO-LIST.md) for the roadmap.

## Architecture

```text
Flutter web client
        │ HTTP / Socket.IO
        ▼
Node.js + Express + Socket.IO
        │
        ▼
PostgreSQL
```

The backend runs migrations from
`backend/src/db/migrations/` automatically on startup. PostgreSQL is the
authoritative source for users, relationships, conversations, messages,
notifications, sessions, delivery acknowledgements, and read cursors.

## Getting started with Docker

### Prerequisites

- Docker
- Docker Compose

Create a local environment file:

```bash
cp .env.example .env
```

Change `JWT_SECRET` to a long, random value before using the application outside
local development. Start the stack:

```bash
docker compose up --build
```

Open the web client at <http://localhost:8080>. The backend health endpoint is
available at <http://localhost:3000/health>.

Stop the stack:

```bash
docker compose down
```

To remove the PostgreSQL data volume as well:

```bash
docker compose down -v
```

## Configuration

The backend reads environment variables through `backend/src/config/env.js`.
The complete example is in [.env.example](./.env.example).

| Variable                                                                    | Purpose                              |                   Default |
| --------------------------------------------------------------------------- | ------------------------------------ | ------------------------: |
| `POSTGRES_USER`                                                             | PostgreSQL user                      |                    `chat` |
| `POSTGRES_PASSWORD`                                                         | PostgreSQL password                  |           `chat_password` |
| `POSTGRES_DB`                                                               | PostgreSQL database name             |                    `chat` |
| `DATABASE_URL`                                                              | Backend PostgreSQL connection string |           Compose-derived |
| `PORT`                                                                      | Backend HTTP port                    |                    `3000` |
| `JWT_SECRET`                                                                | JWT signing secret                   | Development fallback only |
| `JWT_MAX_LIFETIME_DAYS`                                                     | Maximum refresh/session lifetime     |                       `7` |
| `JWT_ACCESS_LIFETIME_MINUTES`                                               | Access-token lifetime                |                      `15` |
| `JSON_BODY_LIMIT_BYTES`                                                     | JSON request body limit              |                 `1048576` |
| `AVATAR_MAX_BYTES`                                                          | Profile image upload limit           |                 `5242880` |
| `MULTIPART_MAX_FIELDS` / `MULTIPART_MAX_PARTS`                              | Multipart request limits             |                `8` / `10` |
| `HTTP_RATE_LIMIT_WINDOW_SECONDS` / `HTTP_RATE_LIMIT_MAX_REQUESTS`           | General HTTP throttling              |              `60` / `120` |
| `AUTH_RATE_LIMIT_WINDOW_SECONDS` / `AUTH_RATE_LIMIT_MAX_REQUESTS`           | Authentication throttling            |              `900` / `10` |
| `MESSAGE_RATE_LIMIT_WINDOW_SECONDS` / `MESSAGE_RATE_LIMIT_MAX_MESSAGES`     | Message sending limits               |               `60` / `30` |
| `MESSAGE_MAX_LENGTH`                                                        | Maximum message length               |                    `4000` |
| `MESSAGE_HISTORY_PAGE_SIZE`                                                 | Maximum history page size            |                      `50` |
| `WEBSOCKET_RATE_LIMIT_WINDOW_SECONDS` / `WEBSOCKET_RATE_LIMIT_MAX_EVENTS`   | WebSocket event throttling           |               `10` / `40` |
| `WEBSOCKET_CONNECTION_WINDOW_SECONDS` / `WEBSOCKET_CONNECTION_MAX_ATTEMPTS` | WebSocket connection throttling      |               `60` / `20` |
| `DUPLICATE_REQUEST_WINDOW_SECONDS`                                          | Duplicate request suppression window |                      `10` |

When using Compose, the database and JWT settings are passed by
[compose.yml](./compose.yml). Pass any additional limit overrides in the
backend service's `environment` section when deploying them through Compose.

## Local development

### Backend

```bash
cd backend
npm install
npm run dev
```

The backend expects PostgreSQL and a `DATABASE_URL`. It exposes `/health`,
REST APIs under `/api`, static avatars under `/uploads`, and Socket.IO at
`/socket.io`.

### Flutter client

```bash
cd flutter_app
flutter pub get
flutter run -d chrome
```

For a non-web target, override the backend URL:

```bash
flutter run --dart-define=API_URL=http://10.0.2.2:3000
```

The web client uses the current browser origin by default, which allows nginx
to proxy `/api`, `/uploads`, and `/socket.io`.

## Testing and validation

Run backend tests:

```bash
cd backend
npm test
```

Run Flutter analysis and tests:

```bash
cd flutter_app
flutter analyze
flutter test
```

Build the Flutter web client:

```bash
cd flutter_app
flutter build web
```

The test suites cover authentication input validation, message idempotency,
cursor pagination, delivery/read persistence, model parsing, optimistic
messages, persisted-message reconciliation, and reconnect synchronization.

## Project structure

```text
chat-app/
├── backend/
│   ├── src/
│   │   ├── config/                 # Environment and PostgreSQL configuration
│   │   ├── db/migrations/          # Ordered schema migrations
│   │   ├── middleware/             # Validation, throttling, deduplication
│   │   ├── modules/
│   │   │   ├── auth/               # Auth, profiles, sessions, avatars
│   │   │   ├── conversations/      # DMs, users, friendships, relationships
│   │   │   ├── messages/           # History, lifecycle, idempotency
│   │   │   └── notifications/      # Notification center APIs
│   │   └── sockets/                # Socket.IO authentication and events
│   └── test/                       # Node.js backend tests
├── flutter_app/
│   ├── lib/
│   │   ├── core/                   # API client, configuration, themes
│   │   └── features/               # Auth, chat, settings, profiles
│   └── test/                       # Flutter tests
├── compose.yml                     # PostgreSQL, backend, and web services
├── .env.example                    # Configuration template
├── TO-DO-LIST.md                   # Product roadmap
└── README.md
```

## Contributing

1. Create a focused branch.
2. Keep changes scoped and preserve existing behavior.
3. Add or update automated tests and documentation.
4. Run backend tests, `flutter analyze`, Flutter tests, and relevant builds.
5. Do not commit credentials, private keys, user data, or generated build output.

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE).
