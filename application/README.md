# Application

Full-stack web application consisting of a Spring Boot REST API backend and a React SPA frontend, designed for deployment on Amazon EKS. Includes Docker Compose configurations for local development and production-like environments.

## Directory Structure

```
application/
├── docker-compose.yml              # Dev compose: PostgreSQL, Redis, backend, frontend
├── docker-compose.prod.yml         # Prod overrides: resource limits, logging, required secrets
├── backend/                        # Spring Boot 3.3 REST API
│   ├── Dockerfile                  # Multi-stage production build (JDK 21 + JRE 21)
│   ├── Dockerfile.dev              # Dev Dockerfile with hot-reload and debug port (5005)
│   ├── .dockerignore
│   ├── pom.xml                     # Maven project (Java 21, Spring Boot 3.3.5)
│   └── src/
│       ├── main/
│       │   ├── java/com/myapp/api/
│       │   │   ├── Application.java
│       │   │   ├── config/         # AWS, cache, CORS, observability, OpenAPI configs
│       │   │   ├── controller/     # Health, Product, User REST controllers
│       │   │   ├── dto/            # API response wrappers and DTOs
│       │   │   ├── entity/         # JPA entities (User, Product)
│       │   │   ├── exception/      # Global exception handler + custom exceptions
│       │   │   ├── mapper/         # MapStruct entity-DTO mappers
│       │   │   ├── repository/     # Spring Data JPA repositories
│       │   │   ├── security/       # JWT filter, token provider, security config
│       │   │   └── service/        # Business logic services
│       │   └── resources/
│       │       ├── application.yml           # Default config
│       │       ├── application-dev.yml       # Dev profile (H2, DEBUG)
│       │       ├── application-staging.yml   # Staging profile (PostgreSQL, INFO)
│       │       ├── application-prod.yml      # Prod profile (PostgreSQL, WARN)
│       │       ├── logback-spring.xml        # Structured logging
│       │       └── db/migration/             # Flyway migrations (V1-V3)
│       └── test/java/com/myapp/api/
│           ├── ApplicationTests.java
│           ├── controller/                   # Controller tests
│           ├── repository/                   # Repository integration tests
│           └── service/                      # Service unit tests
├── frontend/                       # React 18 SPA
│   ├── Dockerfile                  # Multi-stage build (Node 20 + nginx 1.27)
│   ├── .dockerignore
│   ├── .env.example                # Environment variable template
│   ├── .eslintrc.cjs               # ESLint configuration
│   ├── index.html                  # HTML entry point
│   ├── nginx.conf                  # Production nginx config (security headers, gzip, SPA routing)
│   ├── package.json                # Dependencies (React, TypeScript, Vite, TailwindCSS, Zustand, Axios)
│   ├── postcss.config.js
│   ├── tailwind.config.js
│   ├── tsconfig.json
│   ├── tsconfig.node.json
│   ├── vite.config.ts              # Vite config (proxy, aliases, code splitting)
│   └── src/
│       ├── main.tsx                # Entry point
│       ├── App.tsx                 # Route definitions (/, /users, /products, 404)
│       ├── index.css               # TailwindCSS imports
│       ├── vite-env.d.ts
│       ├── components/             # common/, layout/, products/, users/
│       ├── hooks/                  # useApi, useAuth
│       ├── pages/                  # Home, Users, Products, NotFound
│       ├── services/               # API client, product/user services
│       ├── store/                  # Zustand stores (app, auth)
│       ├── types/                  # TypeScript type definitions
│       └── utils/                  # Constants, formatters, validators
└── README.md                       # This file
```

## Architecture

```
                    +-------------------+
                    |    Browser        |
                    +--------+----------+
                             |
                    +--------v----------+
                    |  Frontend (nginx) |  Port 3000 (dev) / 8080 (container)
                    |  React SPA        |
                    +--------+----------+
                             |
                             | /api/* proxy
                             |
                    +--------v----------+
                    |  Backend          |  Port 8080 (app) / 8081 (metrics)
                    |  Spring Boot      |
                    +---+----------+----+
                        |          |
               +--------v--+  +---v--------+
               | PostgreSQL |  |   Redis    |
               | Port 5432  |  | Port 6379  |
               +------------+  +------------+
```

- **Frontend** serves the React SPA via nginx and proxies `/api/*` requests to the backend
- **Backend** handles REST API requests, authenticates with JWT, persists data to PostgreSQL, uses Redis for caching
- **PostgreSQL** stores users and products with Flyway-managed schema
- **Redis** provides caching with LRU eviction (256MB max memory)

## Quick Start with Docker Compose

```bash
cd application

# Start all services (dev mode)
docker compose up --build

# Access the application
#   Frontend: http://localhost:3000
#   Backend:  http://localhost:8080
#   Swagger:  http://localhost:8080/swagger-ui.html
#   H2 Console: http://localhost:8080/h2-console (dev profile only)

# View logs
docker compose logs -f backend
docker compose logs -f frontend

# Stop and clean up
docker compose down -v
```

## Docker Compose Files

### `docker-compose.yml` (Development)

The base Compose file for local development:

| Service | Image | Ports | Notes |
|---|---|---|---|
| `postgres` | `postgres:16-alpine` | 5432:5432 | Persistent volume, health check |
| `redis` | `redis:7-alpine` | 6379:6379 | Persistent volume, LRU eviction, append-only |
| `backend` | Built from `./backend/Dockerfile` | 8080:8080 | Depends on postgres + redis (healthy), health check on `/api/health` |
| `frontend` | Built from `./frontend/Dockerfile` | 3000:8080 | Depends on backend (healthy), health check |

All services are on a shared `myapp-network` bridge network with `restart: unless-stopped`.

### `docker-compose.prod.yml` (Production override)

Apply on top of the base file for production-like settings:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up
```

Changes from the base:
- Internal ports only (no host port bindings for postgres, redis, backend)
- Frontend exposed on ports 80 and 443
- Required environment variables: `POSTGRES_PASSWORD`, `JWT_SECRET`
- Resource limits/reservations for all services (CPU + memory)
- JSON file logging driver with size/rotation limits
- `restart: always`

## Further Reading

- [Backend README](backend/README.md) -- API endpoints, configuration profiles, testing, Flyway migrations
- [Frontend README](frontend/README.md) -- Pages, components, build process, nginx configuration
