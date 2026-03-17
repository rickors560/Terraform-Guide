import { Edit2, Trash2, ArrowUpDown } from 'lucide-react';
import type { Product } from '@/types/product';
import Pagination from '@/components/common/Pagination';
import { formatCurrency, formatDate, capitalize } from '@/utils/formatters';

interface ProductListProps {
  products: Product[];
  totalItems: number;
  currentPage: number;
  pageSize: number;
  totalPages: number;
  sortBy: string;
  sortOrder: 'asc' | 'desc';
  onPageChange: (page: number) => void;
  onPageSizeChange: (pageSize: number) => void;
  onSort: (field: string) => void;
  onEdit: (product: Product) => void;
  onDelete: (product: Product) => void;
}

const statusColors: Record<string, string> = {
  active: 'bg-green-100 text-green-800',
  inactive: 'bg-gray-100 text-gray-800',
  discontinued: 'bg-red-100 text-red-800',
};

export default function ProductList({
  products,
  totalItems,
  currentPage,
  pageSize,
  totalPages,
  sortBy,
  sortOrder,
  onPageChange,
  onPageSizeChange,
  onSort,
  onEdit,
  onDelete,
}: ProductListProps) {
  const SortButton = ({ field, label }: { field: string; label: string }) => (
    <button
      onClick={() => onSort(field)}
      className="flex items-center gap-1 text-xs font-medium uppercase tracking-wide text-gray-500 hover:text-gray-700"
    >
      {label}
      <ArrowUpDown
        className={`h-3 w-3 ${sortBy === field ? 'text-primary-600' : 'text-gray-400'} ${
          sortBy === field && sortOrder === 'desc' ? 'rotate-180' : ''
        }`}
      />
    </button>
  );

  return (
    <div className="card overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-200 bg-gray-50">
              <th className="px-4 py-3 text-left">
                <SortButton field="name" label="Product" />
              </th>
              <th className="px-4 py-3 text-left">
                <SortButton field="category" label="Category" />
              </th>
              <th className="px-4 py-3 text-left">
                <SortButton field="price" label="Price" />
              </th>
              <th className="px-4 py-3 text-left">
                <SortButton field="stock" label="Stock" />
              </th>
              <th className="px-4 py-3 text-left">
                <SortButton field="status" label="Status" />
              </th>
              <th className="px-4 py-3 text-left">
                <SortButton field="createdAt" label="Created" />
              </th>
              <th className="px-4 py-3 text-right">
                <span className="text-xs font-medium uppercase tracking-wide text-gray-500">
                  Actions
                </span>
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {products.map((product) => (
              <tr key={product.id} className="transition-colors hover:bg-gray-50">
                <td className="px-4 py-3">
                  <div>
                    <p className="text-sm font-medium text-gray-900">{product.name}</p>
                    <p className="text-xs text-gray-500">SKU: {product.sku}</p>
                  </div>
                </td>
                <td className="px-4 py-3">
                  <span className="rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-700">
                    {product.category}
                  </span>
                </td>
                <td className="px-4 py-3 text-sm font-medium text-gray-900">
                  {formatCurrency(product.price)}
                </td>
                <td className="px-4 py-3">
                  <span
                    className={`text-sm ${product.stock <= 10 ? 'font-medium text-red-600' : 'text-gray-600'}`}
                  >
                    {product.stock}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <span
                    className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${statusColors[product.status]}`}
                  >
                    {capitalize(product.status)}
                  </span>
                </td>
                <td className="px-4 py-3 text-sm text-gray-500">
                  {formatDate(product.createdAt)}
                </td>
                <td className="px-4 py-3 text-right">
                  <div className="flex items-center justify-end gap-1">
                    <button
                      onClick={() => onEdit(product)}
                      className="rounded-lg p-1.5 text-gray-400 hover:bg-gray-100 hover:text-gray-600"
                      title="Edit"
                    >
                      <Edit2 className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => onDelete(product)}
                      className="rounded-lg p-1.5 text-gray-400 hover:bg-red-50 hover:text-red-600"
                      title="Delete"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {products.length === 0 && (
              <tr>
                <td colSpan={7} className="px-4 py-12 text-center text-sm text-gray-500">
                  No products found.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <div className="border-t border-gray-200">
        <Pagination
          currentPage={currentPage}
          totalPages={totalPages}
          pageSize={pageSize}
          totalItems={totalItems}
          onPageChange={onPageChange}
          onPageSizeChange={onPageSizeChange}
        />
      </div>
    </div>
  );
}
