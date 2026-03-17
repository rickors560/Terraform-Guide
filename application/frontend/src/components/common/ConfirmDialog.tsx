import { Fragment } from 'react';
import { Dialog, Transition } from '@headlessui/react';
import { AlertTriangle } from 'lucide-react';

interface ConfirmDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  variant?: 'danger' | 'warning' | 'info';
  loading?: boolean;
}

const variantStyles = {
  danger: {
    icon: 'text-red-600 bg-red-100',
    button: 'btn-danger',
  },
  warning: {
    icon: 'text-yellow-600 bg-yellow-100',
    button: 'btn bg-yellow-600 text-white hover:bg-yellow-700 focus:ring-yellow-500',
  },
  info: {
    icon: 'text-primary-600 bg-primary-100',
    button: 'btn-primary',
  },
};

export default function ConfirmDialog({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  variant = 'danger',
  loading = false,
}: ConfirmDialogProps) {
  const styles = variantStyles[variant];

  return (
    <Transition appear show={isOpen} as={Fragment}>
      <Dialog as="div" className="relative z-50" onClose={onClose}>
        <Transition.Child
          as={Fragment}
          enter="ease-out duration-300"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="ease-in duration-200"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-black/40 backdrop-blur-sm" />
        </Transition.Child>

        <div className="fixed inset-0 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <Transition.Child
              as={Fragment}
              enter="ease-out duration-300"
              enterFrom="opacity-0 scale-95"
              enterTo="opacity-100 scale-100"
              leave="ease-in duration-200"
              leaveFrom="opacity-100 scale-100"
              leaveTo="opacity-0 scale-95"
            >
              <Dialog.Panel className="w-full max-w-md transform rounded-xl bg-white p-6 shadow-2xl transition-all">
                <div className="flex items-start gap-4">
                  <div className={`rounded-full p-2 ${styles.icon}`}>
                    <AlertTriangle className="h-6 w-6" />
                  </div>
                  <div className="flex-1">
                    <Dialog.Title as="h3" className="text-lg font-semibold text-gray-900">
                      {title}
                    </Dialog.Title>
                    <p className="mt-2 text-sm text-gray-600">{message}</p>
                  </div>
                </div>

                <div className="mt-6 flex justify-end gap-3">
                  <button
                    type="button"
                    className="btn-secondary"
                    onClick={onClose}
                    disabled={loading}
                  >
                    {cancelLabel}
                  </button>
                  <button
                    type="button"
                    className={styles.button}
                    onClick={onConfirm}
                    disabled={loading}
                  >
                    {loading ? 'Processing...' : confirmLabel}
                  </button>
                </div>
              </Dialog.Panel>
            </Transition.Child>
          </div>
        </div>
      </Dialog>
    </Transition>
  );
}
