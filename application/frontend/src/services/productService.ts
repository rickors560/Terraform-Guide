import api from './api';
import { API_PATHS } from '@/utils/constants';
import type { Product, ProductCreateRequest, ProductUpdateRequest } from '@/types/product';
import type { ApiResponse, PagedResponse, PaginationParams } from '@/types/api';

export async function getProducts(params: PaginationParams): Promise<PagedResponse<Product>> {
  const response = await api.get<PagedResponse<Product>>(API_PATHS.PRODUCTS.BASE, { params });
  return response.data;
}

export async function getProductById(id: number): Promise<Product> {
  const response = await api.get<ApiResponse<Product>>(API_PATHS.PRODUCTS.BY_ID(id));
  return response.data.data;
}

export async function createProduct(data: ProductCreateRequest): Promise<Product> {
  const response = await api.post<ApiResponse<Product>>(API_PATHS.PRODUCTS.BASE, data);
  return response.data.data;
}

export async function updateProduct(id: number, data: ProductUpdateRequest): Promise<Product> {
  const response = await api.put<ApiResponse<Product>>(API_PATHS.PRODUCTS.BY_ID(id), data);
  return response.data.data;
}

export async function deleteProduct(id: number): Promise<void> {
  await api.delete(API_PATHS.PRODUCTS.BY_ID(id));
}
