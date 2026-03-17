import { Menu, Search, Bell, User, LogOut, Settings, Menu as MenuIcon } from 'lucide-react';
import { Menu as HeadlessMenu, Transition } from '@headlessui/react';
import { Fragment } from 'react';
import { useAppStore } from '@/store/appStore';
import { useAuth } from '@/hooks/useAuth';
import { APP_CONFIG } from '@/utils/constants';

export default function Header() {
  const { toggleSidebar } = useAppStore();
  const { user, logout, isAuthenticated } = useAuth();

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center border-b border-gray-200 bg-white px-4 lg:px-6">
      <button
        onClick={toggleSidebar}
        className="rounded-lg p-2 text-gray-500 hover:bg-gray-100 lg:hidden"
      >
        <MenuIcon className="h-5 w-5" />
      </button>

      <div className="flex flex-1 items-center gap-4 px-2 lg:px-0">
        <div className="hidden lg:flex lg:flex-1">
          <div className="relative w-full max-w-md">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              placeholder="Search..."
              className="input pl-10"
            />
          </div>
        </div>

        <div className="flex flex-1 justify-end items-center gap-2">
          <button className="relative rounded-lg p-2 text-gray-500 hover:bg-gray-100">
            <Bell className="h-5 w-5" />
            <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-red-500" />
          </button>

          <HeadlessMenu as="div" className="relative">
            <HeadlessMenu.Button className="flex items-center gap-2 rounded-lg p-1.5 text-gray-700 hover:bg-gray-100">
              <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary-100 text-primary-700">
                <User className="h-4 w-4" />
              </div>
              <span className="hidden text-sm font-medium md:block">
                {isAuthenticated && user ? user.name : 'Guest'}
              </span>
              <Menu className="h-4 w-4 text-gray-400 hidden md:block" />
            </HeadlessMenu.Button>

            <Transition
              as={Fragment}
              enter="transition ease-out duration-100"
              enterFrom="transform opacity-0 scale-95"
              enterTo="transform opacity-100 scale-100"
              leave="transition ease-in duration-75"
              leaveFrom="transform opacity-100 scale-100"
              leaveTo="transform opacity-0 scale-95"
            >
              <HeadlessMenu.Items className="absolute right-0 mt-2 w-56 origin-top-right rounded-xl bg-white shadow-lg ring-1 ring-black/5 focus:outline-none">
                <div className="p-1">
                  <div className="px-3 py-2 border-b border-gray-100 mb-1">
                    <p className="text-sm font-medium text-gray-900">
                      {isAuthenticated && user ? user.name : 'Guest User'}
                    </p>
                    <p className="text-xs text-gray-500">
                      {isAuthenticated && user ? user.email : `${APP_CONFIG.APP_NAME} User`}
                    </p>
                  </div>

                  <HeadlessMenu.Item>
                    {({ active }) => (
                      <button
                        className={`${
                          active ? 'bg-gray-50' : ''
                        } flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm text-gray-700`}
                      >
                        <Settings className="h-4 w-4" />
                        Settings
                      </button>
                    )}
                  </HeadlessMenu.Item>

                  {isAuthenticated && (
                    <HeadlessMenu.Item>
                      {({ active }) => (
                        <button
                          onClick={logout}
                          className={`${
                            active ? 'bg-red-50' : ''
                          } flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm text-red-600`}
                        >
                          <LogOut className="h-4 w-4" />
                          Sign out
                        </button>
                      )}
                    </HeadlessMenu.Item>
                  )}
                </div>
              </HeadlessMenu.Items>
            </Transition>
          </HeadlessMenu>
        </div>
      </div>
    </header>
  );
}
