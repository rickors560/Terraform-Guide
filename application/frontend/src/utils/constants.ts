export const API_PATHS = {
  AUTH: {
    LOGIN: '/auth/login',
    LOGOUT: '/auth/logout',
    REFRESH: '/auth/refresh',
    ME: '/auth/me',
  },
  USERS: {
    BASE: '/users',
    BY_ID: (id: number) => `/users/${id}`,
  },
  PRODUCTS: {
    BASE: '/products',
    BY_ID: (id: number) => `/products/${id}`,
  },
  HEALTH: '/health',
} as const;

export const PAGINATION_DEFAULTS = {
  PAGE: 1,
  PAGE_SIZE: 10,
  PAGE_SIZE_OPTIONS: [5, 10, 25, 50],
} as const;

export const APP_CONFIG = {
  APP_NAME: 'MyApp',
  APP_VERSION: '1.0.0',
  DATE_FORMAT: 'MMM dd, yyyy',
  DATE_TIME_FORMAT: 'MMM dd, yyyy HH:mm',
  DEBOUNCE_MS: 300,
  MAX_FILE_SIZE: 5 * 1024 * 1024,
} as const;

export const USER_ROLES = ['admin', 'user', 'moderator'] as const;
export const USER_STATUSES = ['active', 'inactive', 'suspended'] as const;
export const PRODUCT_STATUSES = ['active', 'inactive', 'discontinued'] as const;

export const PRODUCT_CATEGORIES = [
  'Electronics',
  'Clothing',
  'Books',
  'Home & Garden',
  'Sports',
  'Toys',
  'Food & Beverage',
  'Health',
  'Automotive',
  'Other',
] as const;
