export interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  category: string;
  sku: string;
  stock: number;
  imageUrl?: string;
  status: 'active' | 'inactive' | 'discontinued';
  createdAt: string;
  updatedAt: string;
}

export interface ProductCreateRequest {
  name: string;
  description: string;
  price: number;
  category: string;
  sku: string;
  stock: number;
  imageUrl?: string;
}

export interface ProductUpdateRequest {
  name?: string;
  description?: string;
  price?: number;
  category?: string;
  sku?: string;
  stock?: number;
  imageUrl?: string;
  status?: 'active' | 'inactive' | 'discontinued';
}
