# Frontend -- React SPA

A React 18 single-page application built with TypeScript and Vite, serving as the user interface for the MyApp application. Provides user management and product management pages with a responsive layout built on TailwindCSS.

## Technology Stack

| Technology | Version | Purpose |
|---|---|---|
| React | 18.2 | UI framework |
| TypeScript | 5.3 | Type-safe JavaScript |
| Vite | 5.1 | Build tool and dev server |
| TailwindCSS | 3.4 | Utility-first CSS framework |
| React Router DOM | 6.22 | Client-side routing |
| Zustand | 4.5 | Lightweight state management |
| Axios | 1.6 | HTTP client for API calls |
| Headless UI | 1.7 | Unstyled accessible UI primitives |
| Lucide React | 0.344 | Icon library |
| React Hot Toast | 2.4 | Toast notifications |
| ESLint | 8.56 | Code linting |
| Prettier | 3.2 | Code formatting |
| PostCSS | 8.4 | CSS processing (with Autoprefixer) |

## Directory Structure

```
frontend/
├── Dockerfile                          # Multi-stage production build (Node build + nginx serve)
├── .dockerignore                       # Docker build exclusions
├── .env.example                        # Example environment variables (VITE_API_URL)
├── .eslintrc.cjs                       # ESLint configuration
├── index.html                          # HTML entry point (Vite injects script tags)
├── nginx.conf                          # Nginx configuration for production container
├── package.json                        # Dependencies and scripts
├── postcss.config.js                   # PostCSS plugins (TailwindCSS, Autoprefixer)
├── tailwind.config.js                  # TailwindCSS configuration
├── tsconfig.json                       # TypeScript configuration
├── tsconfig.node.json                  # TypeScript config for Vite/Node files
├── vite.config.ts                      # Vite configuration (proxy, aliases, build options)
└── src/
    ├── main.tsx                        # Application entry point (React root, BrowserRouter)
    ├── App.tsx                         # Root component with route definitions
    ├── index.css                       # Global styles (TailwindCSS directives)
    ├── vite-env.d.ts                   # Vite environment type declarations
    ├── components/
    │   ├── common/
    │   │   ├── ConfirmDialog.tsx        # Reusable confirmation dialog
    │   │   ├── ErrorMessage.tsx         # Error display component
    │   │   ├── LoadingSpinner.tsx       # Loading indicator
    │   │   ├── Modal.tsx               # Generic modal wrapper
    │   │   └── Pagination.tsx          # Pagination controls
    │   ├── layout/
    │   │   ├── Footer.tsx              # Page footer
    │   │   ├── Header.tsx              # Top navigation bar
    │   │   ├── Layout.tsx              # Page layout wrapper (header + sidebar + outlet + footer)
    │   │   └── Sidebar.tsx             # Side navigation menu
    │   ├── products/
    │   │   ├── ProductCard.tsx         # Product display card
    │   │   ├── ProductForm.tsx         # Create/edit product form
    │   │   └── ProductList.tsx         # Product list with CRUD actions
    │   └── users/
    │       ├── UserForm.tsx            # Create/edit user form
    │       └── UserList.tsx            # User list with CRUD actions
    ├── hooks/
    │   ├── useApi.ts                   # Generic API call hook with loading/error state
    │   └── useAuth.ts                  # Authentication hook (JWT token management)
    ├── pages/
    │   ├── Home.tsx                    # Dashboard / landing page
    │   ├── NotFound.tsx                # 404 page
    │   ├── Products.tsx                # Products management page
    │   └── Users.tsx                   # Users management page
    ├── services/
    │   ├── api.ts                      # Axios instance configuration (base URL, interceptors)
    │   ├── productService.ts           # Product API service (CRUD operations)
    │   └── userService.ts              # User API service (CRUD operations)
    ├── store/
    │   ├── appStore.ts                 # Global app state (Zustand)
    │   └── authStore.ts                # Authentication state (Zustand)
    ├── types/
    │   ├── api.ts                      # API response type definitions
    │   ├── product.ts                  # Product type definitions
    │   └── user.ts                     # User type definitions
    └── utils/
        ├── constants.ts                # Application constants
        ├── formatters.ts               # Data formatting utilities
        └── validators.ts               # Form validation utilities
```

## Pages and Components

| Route | Page | Description |
|---|---|---|
| `/` | Home | Dashboard / landing page |
| `/users` | Users | User management with list, create, edit, delete |
| `/products` | Products | Product management with list, create, edit, delete |
| `*` | NotFound | 404 fallback page |

All pages are rendered inside the `Layout` component which provides a consistent header, sidebar navigation, content area, and footer.

## Running Locally

### Development server (with API proxy)

```bash
cd application/frontend
npm install
npm run dev
# Available at http://localhost:3000
# API requests to /api/* are proxied to http://localhost:8080
```

### With Docker

```bash
cd application/frontend
docker build -t myapp-frontend:latest .
docker run -p 3000:8080 myapp-frontend:latest
```

### With Docker Compose (full stack)

```bash
cd application
docker compose up
# Frontend at http://localhost:3000
# Backend at http://localhost:8080
```

## Build Process

```bash
npm run build     # TypeScript compilation + Vite production build
npm run lint      # ESLint check
npm run format    # Prettier formatting
npm run preview   # Preview production build locally
```

The Vite build configuration includes:

- **Output**: `dist/` directory
- **Minification**: Terser with `drop_console` and `drop_debugger` in production
- **Code splitting**: Manual chunks for `vendor` (react, react-dom, react-router-dom) and `ui` (headless-ui, lucide-react)
- **Source maps**: Disabled in production builds
- **Path aliases**: `@` maps to `./src/`

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `VITE_API_URL` | `/api` | Backend API base URL (compile-time, baked into the build) |

Environment variables prefixed with `VITE_` are embedded at build time by Vite. To change the API URL for a production build, pass it as a Docker build arg:

```bash
docker build --build-arg VITE_API_URL=https://api.example.com -t myapp-frontend .
```

## Docker Build

The `Dockerfile` uses a multi-stage build:

1. **Builder stage** (`node:20-alpine`): Installs dependencies with `npm ci`, builds the production bundle with `npm run build`
2. **Runtime stage** (`nginx:1.27-alpine`): Copies the custom `nginx.conf` and built assets, creates a non-root user (UID 1001), exposes port 8080, includes a Docker HEALTHCHECK

## Nginx Configuration

The `nginx.conf` provides:

- Listening on port **8080** (non-privileged, for non-root container)
- **Security headers**: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection, Referrer-Policy, Content-Security-Policy, HSTS, Permissions-Policy
- **Gzip compression**: Enabled for text, CSS, JS, JSON, XML, SVG
- **Static asset caching**: 1-year expiry with `immutable` Cache-Control for JS, CSS, images, fonts
- **API proxy**: `/api/` requests are forwarded to `http://backend:8080/api/` (for docker-compose usage)
- **SPA routing**: All non-file paths return `index.html` (supports client-side routing)
- **Hidden files**: Access to dotfiles is denied
