export interface User {
  id: number;
  email: string;
  name: string;
  role: 'admin' | 'user' | 'moderator';
  status: 'active' | 'inactive' | 'suspended';
  avatarUrl?: string;
  createdAt: string;
  updatedAt: string;
}

export interface UserCreateRequest {
  email: string;
  name: string;
  password: string;
  role: 'admin' | 'user' | 'moderator';
}

export interface UserUpdateRequest {
  email?: string;
  name?: string;
  password?: string;
  role?: 'admin' | 'user' | 'moderator';
  status?: 'active' | 'inactive' | 'suspended';
}
