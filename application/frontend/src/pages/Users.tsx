import { useEffect, useState, useCallback } from 'react';
import { Plus, Search } from 'lucide-react';
import { getUsers, createUser, updateUser, deleteUser } from '@/services/userService';
import UserList from '@/components/users/UserList';
import UserForm from '@/components/users/UserForm';
import Modal from '@/components/common/Modal';
import ConfirmDialog from '@/components/common/ConfirmDialog';
import LoadingSpinner from '@/components/common/LoadingSpinner';
import ErrorMessage from '@/components/common/ErrorMessage';
import type { User, UserCreateRequest, UserUpdateRequest } from '@/types/user';
import { PAGINATION_DEFAULTS } from '@/utils/constants';
import toast from 'react-hot-toast';

export default function Users() {
  const [users, setUsers] = useState<User[]>([]);
  const [totalItems, setTotalItems] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [currentPage, setCurrentPage] = useState(PAGINATION_DEFAULTS.PAGE);
  const [pageSize, setPageSize] = useState(PAGINATION_DEFAULTS.PAGE_SIZE);
  const [sortBy, setSortBy] = useState('createdAt');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [showCreateModal, setShowCreateModal] = useState(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [deletingUser, setDeletingUser] = useState<User | null>(null);
  const [formLoading, setFormLoading] = useState(false);

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await getUsers({
        page: currentPage,
        pageSize,
        sortBy,
        sortOrder,
        search: searchQuery || undefined,
      });
      setUsers(response.data);
      setTotalItems(response.total);
      setTotalPages(response.totalPages);
    } catch {
      setError('Failed to load users. Please try again.');
    } finally {
      setLoading(false);
    }
  }, [currentPage, pageSize, sortBy, sortOrder, searchQuery]);

  useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  const handleSort = (field: string) => {
    if (sortBy === field) {
      setSortOrder((prev) => (prev === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortBy(field);
      setSortOrder('asc');
    }
    setCurrentPage(1);
  };

  const handlePageChange = (page: number) => {
    setCurrentPage(page);
  };

  const handlePageSizeChange = (size: number) => {
    setPageSize(size);
    setCurrentPage(1);
  };

  const handleCreate = async (data: UserCreateRequest | UserUpdateRequest) => {
    setFormLoading(true);
    try {
      await createUser(data as UserCreateRequest);
      toast.success('User created successfully');
      setShowCreateModal(false);
      fetchUsers();
    } catch {
      // Error handled by interceptor
    } finally {
      setFormLoading(false);
    }
  };

  const handleUpdate = async (data: UserCreateRequest | UserUpdateRequest) => {
    if (!editingUser) return;
    setFormLoading(true);
    try {
      await updateUser(editingUser.id, data as UserUpdateRequest);
      toast.success('User updated successfully');
      setEditingUser(null);
      fetchUsers();
    } catch {
      // Error handled by interceptor
    } finally {
      setFormLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!deletingUser) return;
    setFormLoading(true);
    try {
      await deleteUser(deletingUser.id);
      toast.success('User deleted successfully');
      setDeletingUser(null);
      fetchUsers();
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
          <h1 className="text-2xl font-bold text-gray-900">Users</h1>
          <p className="text-sm text-gray-500 mt-1">Manage your application users</p>
        </div>
        <button onClick={() => setShowCreateModal(true)} className="btn-primary gap-2">
          <Plus className="h-4 w-4" />
          Add User
        </button>
      </div>

      {/* Search */}
      <div className="card p-4">
        <div className="relative max-w-md">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => handleSearch(e.target.value)}
            placeholder="Search users by name or email..."
            className="input pl-10"
          />
        </div>
      </div>

      {/* Content */}
      {loading ? (
        <LoadingSpinner size="lg" message="Loading users..." fullPage />
      ) : error ? (
        <ErrorMessage message={error} onRetry={fetchUsers} />
      ) : (
        <UserList
          users={users}
          totalItems={totalItems}
          currentPage={currentPage}
          pageSize={pageSize}
          totalPages={totalPages}
          sortBy={sortBy}
          sortOrder={sortOrder}
          onPageChange={handlePageChange}
          onPageSizeChange={handlePageSizeChange}
          onSort={handleSort}
          onEdit={setEditingUser}
          onDelete={setDeletingUser}
        />
      )}

      {/* Create Modal */}
      <Modal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        title="Create User"
      >
        <UserForm
          onSubmit={handleCreate}
          onCancel={() => setShowCreateModal(false)}
          loading={formLoading}
        />
      </Modal>

      {/* Edit Modal */}
      <Modal
        isOpen={!!editingUser}
        onClose={() => setEditingUser(null)}
        title="Edit User"
      >
        <UserForm
          user={editingUser}
          onSubmit={handleUpdate}
          onCancel={() => setEditingUser(null)}
          loading={formLoading}
        />
      </Modal>

      {/* Delete Confirmation */}
      <ConfirmDialog
        isOpen={!!deletingUser}
        onClose={() => setDeletingUser(null)}
        onConfirm={handleDelete}
        title="Delete User"
        message={`Are you sure you want to delete "${deletingUser?.name}"? This action cannot be undone.`}
        confirmLabel="Delete"
        variant="danger"
        loading={formLoading}
      />
    </div>
  );
}
