import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Users, Package, TrendingUp, Activity, ArrowRight, Plus } from 'lucide-react';
import { getUsers } from '@/services/userService';
import { getProducts } from '@/services/productService';
import LoadingSpinner from '@/components/common/LoadingSpinner';
import ErrorMessage from '@/components/common/ErrorMessage';
import { formatRelativeTime, formatCurrency, formatCompactNumber } from '@/utils/formatters';
import type { User } from '@/types/user';
import type { Product } from '@/types/product';

interface DashboardStats {
  totalUsers: number;
  totalProducts: number;
  recentUsers: User[];
  recentProducts: Product[];
}

export default function Home() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchDashboardData = async () => {
    setLoading(true);
    setError(null);
    try {
      const [usersResponse, productsResponse] = await Promise.all([
        getUsers({ page: 1, pageSize: 5, sortBy: 'createdAt', sortOrder: 'desc' }),
        getProducts({ page: 1, pageSize: 5, sortBy: 'createdAt', sortOrder: 'desc' }),
      ]);

      setStats({
        totalUsers: usersResponse.total,
        totalProducts: productsResponse.total,
        recentUsers: usersResponse.data,
        recentProducts: productsResponse.data,
      });
    } catch {
      setError('Failed to load dashboard data. The API server may not be running.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  if (loading) {
    return <LoadingSpinner size="lg" message="Loading dashboard..." fullPage />;
  }

  if (error) {
    return <ErrorMessage message={error} onRetry={fetchDashboardData} />;
  }

  const statCards = [
    {
      label: 'Total Users',
      value: formatCompactNumber(stats?.totalUsers ?? 0),
      icon: Users,
      color: 'bg-blue-500',
      bgColor: 'bg-blue-50',
      textColor: 'text-blue-700',
      link: '/users',
    },
    {
      label: 'Total Products',
      value: formatCompactNumber(stats?.totalProducts ?? 0),
      icon: Package,
      color: 'bg-green-500',
      bgColor: 'bg-green-50',
      textColor: 'text-green-700',
      link: '/products',
    },
    {
      label: 'Revenue',
      value: formatCurrency(
        stats?.recentProducts.reduce((sum, p) => sum + p.price * p.stock, 0) ?? 0,
      ),
      icon: TrendingUp,
      color: 'bg-purple-500',
      bgColor: 'bg-purple-50',
      textColor: 'text-purple-700',
      link: '/products',
    },
    {
      label: 'Active Items',
      value: formatCompactNumber(
        (stats?.recentUsers.filter((u) => u.status === 'active').length ?? 0) +
          (stats?.recentProducts.filter((p) => p.status === 'active').length ?? 0),
      ),
      icon: Activity,
      color: 'bg-orange-500',
      bgColor: 'bg-orange-50',
      textColor: 'text-orange-700',
      link: '/',
    },
  ];

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-sm text-gray-500 mt-1">
            Welcome back! Here is an overview of your application.
          </p>
        </div>
        <div className="flex gap-2">
          <Link to="/users" className="btn-secondary gap-2">
            <Plus className="h-4 w-4" />
            Add User
          </Link>
          <Link to="/products" className="btn-primary gap-2">
            <Plus className="h-4 w-4" />
            Add Product
          </Link>
        </div>
      </div>

      {/* Stats cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {statCards.map((card) => (
          <Link
            key={card.label}
            to={card.link}
            className="card p-5 transition-shadow hover:shadow-md"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">{card.label}</p>
                <p className={`text-2xl font-bold ${card.textColor} mt-1`}>{card.value}</p>
              </div>
              <div className={`rounded-xl ${card.bgColor} p-3`}>
                <card.icon className={`h-6 w-6 ${card.textColor}`} />
              </div>
            </div>
          </Link>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Recent Users */}
        <div className="card">
          <div className="flex items-center justify-between border-b border-gray-200 px-5 py-4">
            <h2 className="font-semibold text-gray-900">Recent Users</h2>
            <Link
              to="/users"
              className="flex items-center gap-1 text-sm text-primary-600 hover:text-primary-700"
            >
              View all <ArrowRight className="h-4 w-4" />
            </Link>
          </div>
          <div className="divide-y divide-gray-100">
            {stats?.recentUsers.length === 0 && (
              <p className="px-5 py-8 text-center text-sm text-gray-500">No users yet.</p>
            )}
            {stats?.recentUsers.map((user) => (
              <div key={user.id} className="flex items-center justify-between px-5 py-3">
                <div className="flex items-center gap-3">
                  <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary-100 text-primary-700 font-medium text-sm">
                    {user.name.charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <p className="text-sm font-medium text-gray-900">{user.name}</p>
                    <p className="text-xs text-gray-500">{user.email}</p>
                  </div>
                </div>
                <span className="text-xs text-gray-400">
                  {formatRelativeTime(user.createdAt)}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Products */}
        <div className="card">
          <div className="flex items-center justify-between border-b border-gray-200 px-5 py-4">
            <h2 className="font-semibold text-gray-900">Recent Products</h2>
            <Link
              to="/products"
              className="flex items-center gap-1 text-sm text-primary-600 hover:text-primary-700"
            >
              View all <ArrowRight className="h-4 w-4" />
            </Link>
          </div>
          <div className="divide-y divide-gray-100">
            {stats?.recentProducts.length === 0 && (
              <p className="px-5 py-8 text-center text-sm text-gray-500">No products yet.</p>
            )}
            {stats?.recentProducts.map((product) => (
              <div key={product.id} className="flex items-center justify-between px-5 py-3">
                <div className="flex items-center gap-3">
                  <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-gray-100">
                    <Package className="h-5 w-5 text-gray-400" />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-gray-900">{product.name}</p>
                    <p className="text-xs text-gray-500">{product.category}</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-sm font-medium text-gray-900">
                    {formatCurrency(product.price)}
                  </p>
                  <p className="text-xs text-gray-400">
                    {formatRelativeTime(product.createdAt)}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Quick Links */}
      <div className="card p-5">
        <h2 className="font-semibold text-gray-900 mb-4">Quick Links</h2>
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
          <Link
            to="/users"
            className="flex items-center gap-3 rounded-lg border border-gray-200 p-4 transition-colors hover:border-primary-300 hover:bg-primary-50/50"
          >
            <Users className="h-5 w-5 text-primary-600" />
            <div>
              <p className="text-sm font-medium text-gray-900">Manage Users</p>
              <p className="text-xs text-gray-500">Create, edit, and manage users</p>
            </div>
          </Link>
          <Link
            to="/products"
            className="flex items-center gap-3 rounded-lg border border-gray-200 p-4 transition-colors hover:border-green-300 hover:bg-green-50/50"
          >
            <Package className="h-5 w-5 text-green-600" />
            <div>
              <p className="text-sm font-medium text-gray-900">Manage Products</p>
              <p className="text-xs text-gray-500">Add and update your catalog</p>
            </div>
          </Link>
          <div className="flex items-center gap-3 rounded-lg border border-gray-200 p-4">
            <Activity className="h-5 w-5 text-orange-600" />
            <div>
              <p className="text-sm font-medium text-gray-900">System Health</p>
              <p className="text-xs text-gray-500">All systems operational</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
