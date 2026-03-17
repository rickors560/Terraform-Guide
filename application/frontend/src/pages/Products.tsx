import { useEffect, useState, useCallback } from 'react';
import { Plus, Search, LayoutGrid, List, Filter } from 'lucide-react';
import { getProducts, createProduct, updateProduct, deleteProduct } from '@/services/productService';
import ProductList from '@/components/products/ProductList';
import ProductCard from '@/components/products/ProductCard';
import ProductForm from '@/components/products/ProductForm';
import Modal from '@/components/common/Modal';
import ConfirmDialog from '@/components/common/ConfirmDialog';
import Pagination from '@/components/common/Pagination';
import LoadingSpinner from '@/components/common/LoadingSpinner';
import ErrorMessage from '@/components/common/ErrorMessage';
import type { Product, ProductCreateRequest, ProductUpdateRequest } from '@/types/product';
import { PAGINATION_DEFAULTS, PRODUCT_CATEGORIES } from '@/utils/constants';
import toast from 'react-hot-toast';

type ViewMode = 'grid' | 'list';

export default function Products() {
  const [products, setProducts] = useState<Product[]>([]);
  const [totalItems, setTotalItems] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [currentPage, setCurrentPage] = useState(PAGINATION_DEFAULTS.PAGE);
  const [pageSize, setPageSize] = useState(PAGINATION_DEFAULTS.PAGE_SIZE);
  const [sortBy, setSortBy] = useState('createdAt');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');
  const [searchQuery, setSearchQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [viewMode, setViewMode] = useState<ViewMode>('grid');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [showCreateModal, setShowCreateModal] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [deletingProduct, setDeletingProduct] = useState<Product | null>(null);
  const [formLoading, setFormLoading] = useState(false);

  const fetchProducts = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await getProducts({
        page: currentPage,
        pageSize,
        sortBy,
        sortOrder,
        search: searchQuery || undefined,
      });
      let filtered = response.data;
      if (categoryFilter) {
        filtered = filtered.filter((p) => p.category === categoryFilter);
      }
      setProducts(filtered);
      setTotalItems(categoryFilter ? filtered.length : response.total);
      setTotalPages(categoryFilter ? Math.ceil(filtered.length / pageSize) : response.totalPages);
    } catch {
      setError('Failed to load products. Please try again.');
    } finally {
      setLoading(false);
    }
  }, [currentPage, pageSize, sortBy, sortOrder, searchQuery, categoryFilter]);

  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  const handleSort = (field: string) => {
    if (sortBy === field) {
      setSortOrder((prev) => (prev === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortBy(field);
      setSortOrder('asc');
    }
    setCurrentPage(1);
  };

  const handlePageChange = (page: number) => setCurrentPage(page);
  const handlePageSizeChange = (size: number) => {
    setPageSize(size);
    setCurrentPage(1);
  };

  const handleCreate = async (data: ProductCreateRequest | ProductUpdateRequest) => {
    setFormLoading(true);
    try {
      await createProduct(data as ProductCreateRequest);
      toast.success('Product created successfully');
      setShowCreateModal(false);
      fetchProducts();
    } catch {
      // Error handled by interceptor
    } finally {
      setFormLoading(false);
    }
  };

  const handleUpdate = async (data: ProductCreateRequest | ProductUpdateRequest) => {
    if (!editingProduct) return;
    setFormLoading(true);
    try {
      await updateProduct(editingProduct.id, data as ProductUpdateRequest);
      toast.success('Product updated successfully');
      setEditingProduct(null);
      fetchProducts();
    } catch {
      // Error handled by interceptor
    } finally {
      setFormLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!deletingProduct) return;
    setFormLoading(true);
    try {
      await deleteProduct(deletingProduct.id);
      toast.success('Product deleted successfully');
      setDeletingProduct(null);
      fetchProducts();
    } catch {
      // Error handled by interceptor
    } finally {
      setFormLoading(false);
    }
  };

  const handleSearch = (value: string) => {
    setSearchQuery(value);
    setCurrentPage(1);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Products</h1>
          <p className="text-sm text-gray-500 mt-1">Manage your product catalog</p>
        </div>
        <button onClick={() => setShowCreateModal(true)} className="btn-primary gap-2">
          <Plus className="h-4 w-4" />
          Add Product
        </button>
      </div>

      {/* Filters */}
      <div className="card p-4">
        <div className="flex flex-col sm:flex-row items-start sm:items-center gap-3">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => handleSearch(e.target.value)}
              placeholder="Search products..."
              className="input pl-10"
            />
          </div>

          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2">
              <Filter className="h-4 w-4 text-gray-400" />
              <select
                value={categoryFilter}
                onChange={(e) => {
                  setCategoryFilter(e.target.value);
                  setCurrentPage(1);
                }}
                className="input w-40 py-2"
              >
                <option value="">All Categories</option>
                {PRODUCT_CATEGORIES.map((cat) => (
                  <option key={cat} value={cat}>
                    {cat}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex items-center rounded-lg border border-gray-300 p-0.5">
              <button
                onClick={() => setViewMode('grid')}
                className={`rounded-md p-1.5 transition-colors ${
                  viewMode === 'grid'
                    ? 'bg-primary-100 text-primary-700'
                    : 'text-gray-400 hover:text-gray-600'
                }`}
                title="Grid view"
              >
                <LayoutGrid className="h-4 w-4" />
              </button>
              <button
                onClick={() => setViewMode('list')}
                className={`rounded-md p-1.5 transition-colors ${
                  viewMode === 'list'
                    ? 'bg-primary-100 text-primary-700'
                    : 'text-gray-400 hover:text-gray-600'
                }`}
                title="List view"
              >
                <List className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      {loading ? (
        <LoadingSpinner size="lg" message="Loading products..." fullPage />
      ) : error ? (
        <ErrorMessage message={error} onRetry={fetchProducts} />
      ) : viewMode === 'list' ? (
        <ProductList
          products={products}
          totalItems={totalItems}
          currentPage={currentPage}
          pageSize={pageSize}
          totalPages={totalPages}
          sortBy={sortBy}
          sortOrder={sortOrder}
          onPageChange={handlePageChange}
          onPageSizeChange={handlePageSizeChange}
          onSort={handleSort}
          onEdit={setEditingProduct}
          onDelete={setDeletingProduct}
        />
      ) : (
        <>
          {products.length === 0 ? (
            <div className="card p-12 text-center">
              <p className="text-sm text-gray-500">No products found.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              {products.map((product) => (
                <ProductCard
                  key={product.id}
                  product={product}
                  onEdit={setEditingProduct}
                  onDelete={setDeletingProduct}
                />
              ))}
            </div>
          )}
          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            pageSize={pageSize}
            totalItems={totalItems}
            onPageChange={handlePageChange}
            onPageSizeChange={handlePageSizeChange}
          />
        </>
      )}

      {/* Create Modal */}
      <Modal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        title="Create Product"
        size="lg"
      >
        <ProductForm
          onSubmit={handleCreate}
          onCancel={() => setShowCreateModal(false)}
          loading={formLoading}
        />
      </Modal>

      {/* Edit Modal */}
      <Modal
        isOpen={!!editingProduct}
        onClose={() => setEditingProduct(null)}
        title="Edit Product"
        size="lg"
      >
        <ProductForm
          product={editingProduct}
          onSubmit={handleUpdate}
          onCancel={() => setEditingProduct(null)}
          loading={formLoading}
        />
      </Modal>

      {/* Delete Confirmation */}
      <ConfirmDialog
        isOpen={!!deletingProduct}
        onClose={() => setDeletingProduct(null)}
        onConfirm={handleDelete}
        title="Delete Product"
        message={`Are you sure you want to delete "${deletingProduct?.name}"? This action cannot be undone.`}
        confirmLabel="Delete"
        variant="danger"
        loading={formLoading}
      />
    </div>
  );
}
