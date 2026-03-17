import api from './api';
import { API_PATHS } from '@/utils/constants';
import type { User, UserCreateRequest, UserUpdateRequest } from '@/types/user';
import type { ApiResponse, PagedResponse, PaginationParams } from '@/types/api';

export async function getUsers(params: PaginationParams): Promise<PagedResponse<User>> {
  const response = await api.get<PagedResponse<User>>(API_PATHS.USERS.BASE, { params });
  return response.data;
}

export async function getUserById(id: number): Promise<User> {
  const response = await api.get<ApiResponse<User>>(API_PATHS.USERS.BY_ID(id));
  return response.data.data;
}

export async function createUser(data: UserCreateRequest): Promise<User> {
  const response = await api.post<ApiResponse<User>>(API_PATHS.USERS.BASE, data);
  return response.data.data;
}

export async function updateUser(id: number, data: UserUpdateRequest): Promise<User> {
  const response = await api.put<ApiResponse<User>>(API_PATHS.USERS.BY_ID(id), data);
  return response.data.data;
}

export async function deleteUser(id: number): Promise<void> {
  await api.delete(API_PATHS.USERS.BY_ID(id));
}
