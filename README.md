# Chat App

A modern chat application for real-time conversations, built to provide a simple and dependable messaging experience.

## Contents

- [Overview](#overview)
- [Features](#features)
- [Getting started](#getting-started)
- [Configuration](#configuration)
- [Development](#development)
- [Testing](#testing)
- [Project structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

## Overview

This project is a foundation for a chat experience with a clean interface and room to grow. Use it to exchange messages, organize conversations, and extend the application with the features your users need.

## Features

- Real-time conversation experience
- Clear, responsive chat interface
- Conversation and message history
- Extensible authentication and user-management integration
- Configuration through environment variables
- A structure designed for local development and production deployment

## Getting started

### Prerequisites

Install Docker and Docker Compose, then clone the repository:

```bash
git clone https://github.com/RUN1-CS/Synapse.git
cd chat-app
```

Build and start the application and its services with Docker Compose:

```bash
docker compose up --build
```

If the project provides an example environment file, create a local copy before starting:

```bash
cp .env.example .env
```

Stop the containers with:

```bash
docker compose down
```

Open the application at the local URL exposed by Docker.

## Configuration

Keep secrets out of source control. Typical configuration values may include:

| Variable            | Description                                     | Required |
| ------------------- | ----------------------------------------------- | -------- |
| `POSTGRES_USER`     | PostgreSQL database user                        | Yes      |
| `POSTGRES_PASSWORD` | PostgreSQL database password                    | Yes      |
| `POSTGRES_DB`       | PostgreSQL database name                        | Yes      |
| `JWT_SECRET`        | Secret used to sign and verify JWTs             | Yes      |
| `PORT`              | Backend port; set to `3000` in Compose          | No       |
| `DATABASE_URL`      | Built from the PostgreSQL variables for backend | Derived  |

Use the project's actual environment variable names as the source of truth; remove unused entries from local configuration.

## Development

Use Docker Compose for development so the commands run in the project's containers:

```bash
docker compose up --build       # Build and start the development stack
docker compose logs -f          # Follow service logs
docker compose ps               # List running services
docker compose down             # Stop the stack
```

Run project-specific commands inside the appropriate service container, replacing `<service>` with its Compose service name:

```bash
docker compose run --rm <service> <command>
```

Before opening a pull request, run the relevant build, lint, formatting, and test commands in the containers.

## Testing

Run the project's test suite with:

```bash
<package-manager> test
```

Add tests for new behavior and regression tests for fixed bugs. Prefer testing user-visible behavior and important error paths.

## Project structure

The exact layout may vary, but a typical organization is:

```text
chat-app/
│
├── backend/                         # Node.js backend
│   └── src/
│       ├── config/                  # Environment and database configuration
│       ├── db/
│       │   └── migrations/          # SQL schema migrations
│       ├── modules/                 # Feature-oriented backend modules
│       │   ├── auth/                # Authentication, authorization and sessions
│       │   ├── messages/            # Message handling and persistence
│       │   └── rooms/               # Chat room management
│       ├── sockets/                 # Real-time communication (Socket.IO)
│       └── utils/                   # Shared utilities and error handling
│
├── flutter_app/                     # Cross-platform Flutter client
│   ├── lib/
│   │   ├── core/                    # Shared infrastructure (API, configuration)
│   │   └── features/                # Feature-oriented application code
│   │       ├── auth/                # Login, user state and authentication
│   │       └── chat/                # Chat UI, rooms, messages and sockets
│   │
│   ├── ios/                         # iOS native project (Xcode)
│   ├── linux/                       # Linux native project (GTK)
│   ├── macos/                       # macOS native project (Xcode)
│   ├── windows/                     # Windows native project
│   ├── web/                         # Web entry point, manifest and icons
│   └── test/                        # Flutter tests
│
├── compose.yml                      # Container orchestration
├── .gitignore                       # Git exclusions
└── README.md                        # Project documentation
```

Keep UI, domain logic, data access, and integration code separated where practical so each area remains easy to test and maintain.

## Contributing

1.  Create a focused branch from the default branch.
2.  Make the smallest change that solves the problem.
3.  Add or update tests and documentation as needed.
4.  Run formatting, linting, tests, and a production build.
5.  Open a pull request with a concise description of the change and its verification steps.

Do not commit credentials, private keys, generated artifacts, or user data.

## License

This project is licensed under the MIT License.
