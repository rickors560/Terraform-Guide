import { useState, useEffect, type FormEvent } from 'react';
import type { User, UserCreateRequest, UserUpdateRequest } from '@/types/user';
import { validateEmail, validatePassword, validateRequired } from '@/utils/validators';
import { USER_ROLES } from '@/utils/constants';
import { capitalize } from '@/utils/formatters';

interface UserFormProps {
  user?: User | null;
  onSubmit: (data: UserCreateRequest | UserUpdateRequest) => void;
  onCancel: () => void;
  loading?: boolean;
}

interface FormErrors {
  name?: string;
  email?: string;
  password?: string;
  role?: string;
}

export default function UserForm({ user, onSubmit, onCancel, loading = false }: UserFormProps) {
  const isEditing = !!user;
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<'admin' | 'user' | 'moderator'>('user');
  const [errors, setErrors] = useState<FormErrors>({});

  useEffect(() => {
    if (user) {
      setName(user.name);
      setEmail(user.email);
      setRole(user.role);
      setPassword('');
    }
  }, [user]);

  const validate = (): boolean => {
    const newErrors: FormErrors = {};

    const nameResult = validateRequired(name, 'Name');
    if (!nameResult.valid) newErrors.name = nameResult.message;

    const emailResult = validateEmail(email);
    if (!emailResult.valid) newErrors.email = emailResult.message;

    if (!isEditing || password.length > 0) {
      const passwordResult = validatePassword(password);
      if (!passwordResult.valid) newErrors.password = passwordResult.message;
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    if (isEditing) {
      const data: UserUpdateRequest = { name, email, role };
      if (password) data.password = password;
      onSubmit(data);
    } else {
      onSubmit({ name, email, password, role });
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label htmlFor="user-name" className="label">
          Name
        </label>
        <input
          id="user-name"
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          className={`input ${errors.name ? 'border-red-500 focus:border-red-500 focus:ring-red-500' : ''}`}
          placeholder="John Doe"
        />
        {errors.name && <p className="mt-1 text-xs text-red-600">{errors.name}</p>}
      </div>

      <div>
        <label htmlFor="user-email" className="label">
          Email
        </label>
        <input
          id="user-email"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className={`input ${errors.email ? 'border-red-500 focus:border-red-500 focus:ring-red-500' : ''}`}
          placeholder="john@example.com"
        />
        {errors.email && <p className="mt-1 text-xs text-red-600">{errors.email}</p>}
      </div>

      <div>
        <label htmlFor="user-password" className="label">
          Password {isEditing && <span className="text-gray-400">(leave blank to keep current)</span>}
        </label>
        <input
          id="user-password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className={`input ${errors.password ? 'border-red-500 focus:border-red-500 focus:ring-red-500' : ''}`}
          placeholder={isEditing ? 'Leave blank to keep current' : 'Min 8 characters'}
        />
        {errors.password && <p className="mt-1 text-xs text-red-600">{errors.password}</p>}
      </div>

      <div>
        <label htmlFor="user-role" className="label">
          Role
        </label>
        <select
          id="user-role"
          value={role}
          onChange={(e) => setRole(e.target.value as 'admin' | 'user' | 'moderator')}
          className="input"
        >
          {USER_ROLES.map((r) => (
            <option key={r} value={r}>
              {capitalize(r)}
            </option>
          ))}
        </select>
      </div>

      <div className="flex justify-end gap-3 pt-4 border-t border-gray-200">
        <button type="button" onClick={onCancel} className="btn-secondary" disabled={loading}>
          Cancel
        </button>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Saving...' : isEditing ? 'Update User' : 'Create User'}
        </button>
      </div>
    </form>
  );
}
