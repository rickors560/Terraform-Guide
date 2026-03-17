# Backend -- Spring Boot REST API

A Spring Boot 3.3 REST API that serves as the backend for the MyApp application. Provides user and product management endpoints, secured with JWT authentication, backed by PostgreSQL with Flyway migrations, and instrumented with Prometheus metrics.

## Technology Stack

| Technology | Version | Purpose |
|---|---|---|
| Java | 21 | Language runtime |
| Spring Boot | 3.3.5 | Application framework |
| Spring Data JPA | (managed) | Database access via Hibernate |
| Spring Security | (managed) | Authentication and authorization |
| Spring Actuator | (managed) | Health checks, metrics, info endpoints |
| Spring Validation | (managed) | Request validation |
| PostgreSQL | (runtime) | Production database |
| H2 | (runtime) | In-memory database for dev/test |
| Flyway | (managed) | Database schema migrations |
| Caffeine | 3.1.8 | Local caching |
| JJWT | 0.12.6 | JWT token creation and validation |
| SpringDoc OpenAPI | 2.6.0 | Swagger UI and API docs |
| MapStruct | 1.5.5 | DTO-entity mapping (compile-time) |
| Lombok | (managed) | Boilerplate reduction |
| Micrometer Prometheus | (managed) | Prometheus metrics exporter |
| Logstash Logback Encoder | 8.0 | Structured JSON logging |
| AWS SDK v2 (S3, Secrets Manager) | 2.29.1 | AWS service integration |
| Testcontainers | 1.20.3 | Integration testing with real PostgreSQL |

## Directory Structure

```
backend/
├── Dockerfile                          # Multi-stage production build (JDK build + JRE runtime)
├── Dockerfile.dev                      # Development Dockerfile with hot-reload and debug port
├── .dockerignore                       # Docker build exclusions
├── pom.xml                             # Maven project definition with all dependencies
└── src/
    ├── main/
    │   ├── java/com/myapp/api/
    │   │   ├── Application.java                        # Main entry point (@SpringBootApplication, @EnableCaching)
    │   │   ├── config/
    │   │   │   ├── AwsConfig.java                      # AWS SDK client configuration (region, credentials)
    │   │   │   ├── CacheConfig.java                    # Caffeine cache manager setup
    │   │   │   ├── CorsConfig.java                     # CORS filter (allowed origins from config)
    │   │   │   ├── ObservabilityConfig.java             # Micrometer metrics customization
    │   │   │   └── OpenApiConfig.java                  # SpringDoc/Swagger configuration
    │   │   ├── controller/
    │   │   │   ├── HealthController.java               # GET /api/health -- app health, version, timestamp
    │   │   │   ├── ProductController.java              # CRUD endpoints for products
    │   │   │   └── UserController.java                 # CRUD endpoints for users
    │   │   ├── dto/
    │   │   │   ├── ApiResponse.java                    # Standard API response wrapper
    │   │   │   ├── PagedResponse.java                  # Paginated response wrapper
    │   │   │   ├── ProductDTO.java                     # Product DTOs (CreateRequest, UpdateRequest, Response)
    │   │   │   └── UserDTO.java                        # User DTOs (CreateRequest, UpdateRequest, Response)
    │   │   ├── entity/
    │   │   │   ├── Product.java                        # Product JPA entity
    │   │   │   └── User.java                           # User JPA entity
    │   │   ├── exception/
    │   │   │   ├── BadRequestException.java            # 400 error
    │   │   │   ├── GlobalExceptionHandler.java         # @ControllerAdvice for centralized error handling
    │   │   │   └── ResourceNotFoundException.java      # 404 error
    │   │   ├── mapper/
    │   │   │   ├── ProductMapper.java                  # MapStruct mapper (Product <-> ProductDTO)
    │   │   │   └── UserMapper.java                     # MapStruct mapper (User <-> UserDTO)
    │   │   ├── repository/
    │   │   │   ├── ProductRepository.java              # Spring Data JPA repository for products
    │   │   │   └── UserRepository.java                 # Spring Data JPA repository for users
    │   │   ├── security/
    │   │   │   ├── JwtAuthenticationFilter.java        # OncePerRequestFilter for JWT validation
    │   │   │   ├── JwtTokenProvider.java               # JWT token generation and parsing
    │   │   │   └── SecurityConfig.java                 # Security filter chain configuration
    │   │   └── service/
    │   │       ├── ProductService.java                 # Business logic for products
    │   │       └── UserService.java                    # Business logic for users
    │   └── resources/
    │       ├── application.yml                         # Default configuration (H2, dev profile)
    │       ├── application-dev.yml                     # Dev profile (H2, DEBUG logging, Swagger enabled)
    │       ├── application-staging.yml                 # Staging profile (PostgreSQL, INFO logging)
    │       ├── application-prod.yml                    # Prod profile (PostgreSQL, WARN logging, Swagger disabled)
    │       ├── logback-spring.xml                      # Structured logging configuration
    │       └── db/migration/
    │           ├── V1__create_users_table.sql           # Creates users table
    │           ├── V2__create_products_table.sql        # Creates products table
    │           └── V3__add_sample_data.sql              # Inserts sample data
    └── test/java/com/myapp/api/
        ├── ApplicationTests.java                       # Spring Boot context load test
        ├── controller/
        │   ├── ProductControllerTest.java              # Product endpoint tests
        │   └── UserControllerTest.java                 # User endpoint tests
        ├── repository/
        │   └── UserRepositoryTest.java                 # Repository integration test
        └── service/
            └── UserServiceTest.java                    # Service layer unit test
```

## API Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/health` | Health check (status, version, timestamp) |
| `GET` | `/api/users` | List users (paginated, sortable) |
| `GET` | `/api/users/{id}` | Get user by ID |
| `POST` | `/api/users` | Create user |
| `PUT` | `/api/users/{id}` | Update user |
| `DELETE` | `/api/users/{id}` | Delete user |
| `GET` | `/api/products` | List products (paginated, sortable) |
| `GET` | `/api/products/{id}` | Get product by ID |
| `POST` | `/api/products` | Create product |
| `PUT` | `/api/products/{id}` | Update product |
| `DELETE` | `/api/products/{id}` | Delete product |
| `GET` | `/actuator/health` | Spring Actuator health (with liveness/readiness sub-paths) |
| `GET` | `/actuator/prometheus` | Prometheus metrics endpoint (management port 8081) |
| `GET` | `/swagger-ui.html` | Swagger UI (dev and staging only) |
| `GET` | `/v3/api-docs` | OpenAPI 3.0 specification |

All list endpoints support query parameters: `page` (0-based), `size` (default 20, max 100), `sortBy`, `sortDir` (asc/desc).

## Running Locally

### With Maven (H2 in-memory database)

```bash
cd application/backend
mvn spring-boot:run -Dspring-boot.run.profiles=dev
# API available at http://localhost:8080
# Swagger UI at http://localhost:8080/swagger-ui.html
# H2 console at http://localhost:8080/h2-console
```

### With Docker

```bash
cd application/backend
docker build -t myapp-backend:latest .
docker run -p 8080:8080 myapp-backend:latest
```

### With Docker Compose (full stack)

```bash
cd application
docker compose up          # Starts PostgreSQL, Redis, backend, and frontend
docker compose down -v     # Stop and remove volumes
```

## Configuration Profiles

| Profile | Database | Logging | Swagger | Actuator Details | Pool Size |
|---|---|---|---|---|---|
| `dev` | H2 in-memory | DEBUG (app, web, SQL) | Enabled + try-it-out | always | 10 |
| `staging` | PostgreSQL | INFO | Enabled | when_authorized | 15 |
| `prod` | PostgreSQL | WARN | Disabled | never | 20 |

Set the active profile via the `SPRING_PROFILES_ACTIVE` environment variable or `--spring.profiles.active` JVM arg.

## Database Migrations (Flyway)

Migrations are located in `src/main/resources/db/migration/` and follow the naming convention `V{version}__{description}.sql`:

- `V1__create_users_table.sql` -- Creates the `users` table
- `V2__create_products_table.sql` -- Creates the `products` table
- `V3__add_sample_data.sql` -- Inserts sample records

Flyway runs automatically on application startup with `baseline-on-migrate: true`. In all profiles, `ddl-auto` is set to `validate` so Hibernate validates the schema but never modifies it.

## Testing Strategy

- **Unit tests**: Service and controller tests using MockMvc and Mockito (`mvn test`)
- **Integration tests**: Repository tests with Testcontainers running a real PostgreSQL instance (`mvn verify`)
- **Context load test**: Verifies the Spring context starts without errors

```bash
mvn test                        # Unit tests only
mvn verify                      # Unit + integration tests
mvn verify -DskipUnitTests=true # Integration tests only
```

## Docker Build

The production `Dockerfile` uses a multi-stage build:

1. **Builder stage** (`eclipse-temurin:21-jdk-jammy`): Copies `pom.xml` first for dependency caching, builds the JAR with `mvn package`, extracts Spring Boot layered JAR
2. **Runtime stage** (`eclipse-temurin:21-jre-jammy`): Copies extracted layers in order of change frequency, creates a non-root `appuser`, configures JVM container support (`-XX:MaxRAMPercentage=75.0`), includes a Docker HEALTHCHECK

The development `Dockerfile.dev` uses a single stage with the full JDK, enables Spring DevTools hot-reload, and exposes a debug port on 5005.

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `SPRING_PROFILES_ACTIVE` | `dev` | Active Spring profile |
| `DB_URL` | `jdbc:h2:mem:myappdb` | JDBC connection URL |
| `DB_USERNAME` | `sa` | Database username |
| `DB_PASSWORD` | (empty) | Database password |
| `DB_DRIVER` | `org.h2.Driver` | JDBC driver class |
| `DB_POOL_SIZE` | `10` | HikariCP max pool size |
| `JWT_SECRET` | (dev default) | HMAC secret for JWT signing |
| `JWT_EXPIRATION` | `86400000` | JWT expiration in milliseconds |
| `CORS_ALLOWED_ORIGINS` | `http://localhost:3000,http://localhost:5173` | Comma-separated allowed origins |
| `AWS_REGION` | `us-east-1` | AWS region for SDK clients |
| `SERVER_PORT` | `8080` | Application server port |
