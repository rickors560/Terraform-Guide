import { useState, useEffect, type FormEvent } from 'react';
import type { Product, ProductCreateRequest, ProductUpdateRequest } from '@/types/product';
import { validateRequired, validatePrice, validatePositiveNumber, validateUrl } from '@/utils/validators';
import { PRODUCT_CATEGORIES } from '@/utils/constants';

interface ProductFormProps {
  product?: Product | null;
  onSubmit: (data: ProductCreateRequest | ProductUpdateRequest) => void;
  onCancel: () => void;
  loading?: boolean;
}

interface FormErrors {
  name?: string;
  description?: string;
  price?: string;
  category?: string;
  sku?: string;
  stock?: string;
  imageUrl?: string;
}

export default function ProductForm({
  product,
  onSubmit,
  onCancel,
  loading = false,
}: ProductFormProps) {
  const isEditing = !!product;
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [price, setPrice] = useState('');
  const [category, setCategory] = useState(PRODUCT_CATEGORIES[0]);
  const [sku, setSku] = useState('');
  const [stock, setStock] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [errors, setErrors] = useState<FormErrors>({});

  useEffect(() => {
    if (product) {
      setName(product.name);
      setDescription(product.description);
      setPrice(product.price.toString());
      setCategory(product.category);
      setSku(product.sku);
      setStock(product.stock.toString());
      setImageUrl(product.imageUrl || '');
    }
  }, [product]);

  const validate = (): boolean => {
    const newErrors: FormErrors = {};

    const nameResult = validateRequired(name, 'Name');
    if (!nameResult.valid) newErrors.name = nameResult.message;

    const descResult = validateRequired(description, 'Description');
    if (!descResult.valid) newErrors.description = descResult.message;

    const priceResult = validatePrice(parseFloat(price));
    if (!priceResult.valid) newErrors.price = priceResult.message;

    const categoryResult = validateRequired(category, 'Category');
    if (!categoryResult.valid) newErrors.category = categoryResult.message;

    const skuResult = validateRequired(sku, 'SKU');
    if (!skuResult.valid) newErrors.sku = skuResult.message;

    const stockResult = validatePositiveNumber(parseInt(stock, 10), 'Stock');
    if (!stockResult.valid) newErrors.stock = stockResult.message;

    if (imageUrl) {
      const urlResult = validateUrl(imageUrl);
      if (!urlResult.valid) newErrors.imageUrl = urlResult.message;
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    const data = {
      name,
      description,
      price: parseFloat(price),
      category,
      sku,
      stock: parseInt(stock, 10),
      imageUrl: imageUrl || undefined,
    };

    onSubmit(data);
  };

  const inputClass = (fieldName: keyof FormErrors) =>
    `input ${errors[fieldName] ? 'border-red-500 focus:border-red-500 focus:ring-red-500' : ''}`;

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label htmlFor="product-name" className="label">
            Name
          </label>
          <input
            id="product-name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className={inputClass('name')}
            placeholder="Product name"
          />
          {errors.name && <p className="mt-1 text-xs text-red-600">{errors.name}</p>}
        </div>

        <div>
          <label htmlFor="product-sku" className="label">
            SKU
          </label>
          <input
            id="product-sku"
            type="text"
            value={sku}
            onChange={(e) => setSku(e.target.value)}
            className={inputClass('sku')}
            placeholder="PROD-001"
          />
          {errors.sku && <p className="mt-1 text-xs text-red-600">{errors.sku}</p>}
        </div>
      </div>

      <div>
        <label htmlFor="product-description" className="label">
          Description
        </label>
        <textarea
          id="product-description"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          className={inputClass('description')}
          rows={3}
          placeholder="Product description..."
        />
        {errors.description && (
          <p className="mt-1 text-xs text-red-600">{errors.description}</p>
        )}
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div>
          <label htmlFor="product-price" className="label">
            Price ($)
          </label>
          <input
            id="product-price"
            type="number"
            step="0.01"
            min="0"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            className={inputClass('price')}
            placeholder="0.00"
          />
          {errors.price && <p className="mt-1 text-xs text-red-600">{errors.price}</p>}
        </div>

        <div>
          <label htmlFor="product-stock" className="label">
            Stock
          </label>
          <input
            id="product-stock"
            type="number"
            min="0"
            value={stock}
            onChange={(e) => setStock(e.target.value)}
            className={inputClass('stock')}
            placeholder="0"
          />
          {errors.stock && <p className="mt-1 text-xs text-red-600">{errors.stock}</p>}
        </div>

        <div>
          <label htmlFor="product-category" className="label">
            Category
          </label>
          <select
            id="product-category"
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            className="input"
          >
            {PRODUCT_CATEGORIES.map((cat) => (
              <option key={cat} value={cat}>
                {cat}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div>
        <label htmlFor="product-image" className="label">
          Image URL <span className="text-gray-400">(optional)</span>
        </label>
        <input
          id="product-image"
          type="url"
          value={imageUrl}
          onChange={(e) => setImageUrl(e.target.value)}
          className={inputClass('imageUrl')}
          placeholder="https://example.com/image.jpg"
        />
        {errors.imageUrl && <p className="mt-1 text-xs text-red-600">{errors.imageUrl}</p>}
      </div>

      <div className="flex justify-end gap-3 pt-4 border-t border-gray-200">
        <button type="button" onClick={onCancel} className="btn-secondary" disabled={loading}>
          Cancel
        </button>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Saving...' : isEditing ? 'Update Product' : 'Create Product'}
        </button>
      </div>
    </form>
  );
}
