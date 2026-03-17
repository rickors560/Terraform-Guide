import { Edit2, Trash2, Package } from 'lucide-react';
import type { Product } from '@/types/product';
import { formatCurrency, capitalize } from '@/utils/formatters';

interface ProductCardProps {
  product: Product;
  onEdit: (product: Product) => void;
  onDelete: (product: Product) => void;
}

const statusColors: Record<string, string> = {
  active: 'bg-green-100 text-green-800',
  inactive: 'bg-gray-100 text-gray-800',
  discontinued: 'bg-red-100 text-red-800',
};

export default function ProductCard({ product, onEdit, onDelete }: ProductCardProps) {
  return (
    <div className="card overflow-hidden transition-shadow hover:shadow-md">
      <div className="relative h-48 bg-gray-100 flex items-center justify-center">
        {product.imageUrl ? (
          <img
            src={product.imageUrl}
            alt={product.name}
            className="h-full w-full object-cover"
          />
        ) : (
          <Package className="h-16 w-16 text-gray-300" />
        )}
        <span
          className={`absolute top-3 right-3 inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${statusColors[product.status]}`}
        >
          {capitalize(product.status)}
        </span>
      </div>

      <div className="p-4">
        <div className="mb-1 flex items-start justify-between">
          <h3 className="text-sm font-semibold text-gray-900 line-clamp-1">{product.name}</h3>
          <span className="text-sm font-bold text-primary-600 whitespace-nowrap ml-2">
            {formatCurrency(product.price)}
          </span>
        </div>

        <p className="text-xs text-gray-500 mb-2 line-clamp-2">{product.description}</p>

        <div className="flex items-center justify-between text-xs text-gray-500">
          <span className="rounded-full bg-gray-100 px-2 py-0.5">{product.category}</span>
          <span>Stock: {product.stock}</span>
        </div>

        <div className="mt-3 flex items-center justify-between border-t border-gray-100 pt-3">
          <span className="text-xs text-gray-400">SKU: {product.sku}</span>
          <div className="flex items-center gap-1">
            <button
              onClick={() => onEdit(product)}
              className="rounded-lg p-1.5 text-gray-400 hover:bg-gray-100 hover:text-gray-600"
              title="Edit product"
            >
              <Edit2 className="h-4 w-4" />
            </button>
            <button
              onClick={() => onDelete(product)}
              className="rounded-lg p-1.5 text-gray-400 hover:bg-red-50 hover:text-red-600"
              title="Delete product"
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
