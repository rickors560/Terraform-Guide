import { useState } from 'react';
import { Edit2, Trash2, ArrowUpDown, MoreVertical } from 'lucide-react';
import { Menu, Transition } from '@headlessui/react';
import { Fragment } from 'react';
import type { User } from '@/types/user';
import Pagination from '@/components/common/Pagination';
import { formatDate } from '@/utils/formatters';
import { capitalize } from '@/utils/formatters';

interface UserListProps {
  users: User[];
  totalItems: number;
  currentPage: number;
  pageSize: number;
  totalPages: number;
  sortBy: string;
  sortOrder: 'asc' | 'desc';
  onPageChange: (page: number) => void;
  onPageSizeChange: (pageSize: number) => void;
  onSort: (field: string) => void;
  onEdit: (user: User) => void;
  onDelete: (user: User) => void;
}

const statusColors: Record<string, string> = {
  active: 'bg-green-100 text-green-800',
  inactive: 'bg-gray-100 text-gray-800',
  suspended: 'bg-red-100 text-red-800',
};

const roleColors: Record<string, string> = {
  admin: 'bg-purple-100 text-purple-800',
  user: 'bg-blue-100 text-blue-800',
  moderator: 'bg-yellow-100 text-yellow-800',
};

export default function UserList({
  users,
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
}: UserListProps) {
  const [selectedIds, setSelectedIds] = useState<Set<number>>(new Set());

  const toggleSelect = (id: number) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  const toggleAll = () => {
    if (selectedIds.size === users.length) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(users.map((u) => u.id)));
    }
  };

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
                <input
                  type="checkbox"
                  checked={selectedIds.size === users.length && users.length > 0}
                  onChange={toggleAll}
                  className="h-4 w-4 rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                />
              </th>
              <th className="px-4 py-3 text-left">
                <SortButton field="name" label="Name" />
              </th>
              <th className="px-4 py-3 text-left">
                <SortButton field="email" label="Email" />
              </th>
              <th className="px-4 py-3 text-left">
                <SortButton field="role" label="Role" />
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
            {users.map((user) => (
              <tr
                key={user.id}
                className={`transition-colors hover:bg-gray-50 ${
                  selectedIds.has(user.id) ? 'bg-primary-50/50' : ''
                }`}
              >
                <td className="px-4 py-3">
                  <input
                    type="checkbox"
                    checked={selectedIds.has(user.id)}
                    onChange={() => toggleSelect(user.id)}
                    className="h-4 w-4 rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                  />
                </td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary-100 text-primary-700 font-medium text-sm">
                      {user.name.charAt(0).toUpperCase()}
                    </div>
                    <span className="text-sm font-medium text-gray-900">{user.name}</span>
                  </div>
                </td>
                <td className="px-4 py-3 text-sm text-gray-600">{user.email}</td>
                <td className="px-4 py-3">
                  <span
                    className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${roleColors[user.role] || 'bg-gray-100 text-gray-800'}`}
                  >
                    {capitalize(user.role)}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <span
                    className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${statusColors[user.status] || 'bg-gray-100 text-gray-800'}`}
                  >
                    {capitalize(user.status)}
                  </span>
                </td>
                <td className="px-4 py-3 text-sm text-gray-500">
                  {formatDate(user.createdAt)}
                </td>
                <td className="px-4 py-3 text-right">
                  <Menu as="div" className="relative inline-block">
                    <Menu.Button className="rounded-lg p-1.5 text-gray-400 hover:bg-gray-100 hover:text-gray-600">
                      <MoreVertical className="h-4 w-4" />
                    </Menu.Button>
                    <Transition
                      as={Fragment}
                      enter="transition ease-out duration-100"
                      enterFrom="transform opacity-0 scale-95"
                      enterTo="transform opacity-100 scale-100"
                      leave="transition ease-in duration-75"
                      leaveFrom="transform opacity-100 scale-100"
                      leaveTo="transform opacity-0 scale-95"
                    >
                      <Menu.Items className="absolute right-0 z-10 mt-1 w-36 origin-top-right rounded-lg bg-white shadow-lg ring-1 ring-black/5 focus:outline-none">
                        <div className="p-1">
                          <Menu.Item>
                            {({ active }) => (
                              <button
                                onClick={() => onEdit(user)}
                                className={`${
                                  active ? 'bg-gray-50' : ''
                                } flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm text-gray-700`}
                              >
                                <Edit2 className="h-4 w-4" />
                                Edit
                              </button>
                            )}
                          </Menu.Item>
                          <Menu.Item>
                            {({ active }) => (
                              <button
                                onClick={() => onDelete(user)}
                                className={`${
                                  active ? 'bg-red-50' : ''
                                } flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm text-red-600`}
                              >
                                <Trash2 className="h-4 w-4" />
                                Delete
                              </button>
                            )}
                          </Menu.Item>
                        </div>
                      </Menu.Items>
                    </Transition>
                  </Menu>
                </td>
              </tr>
            ))}
            {users.length === 0 && (
              <tr>
                <td colSpan={7} className="px-4 py-12 text-center text-sm text-gray-500">
                  No users found.
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
