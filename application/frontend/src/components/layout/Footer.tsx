import { APP_CONFIG } from '@/utils/constants';

export default function Footer() {
  const year = new Date().getFullYear();

  return (
    <footer className="border-t border-gray-200 bg-white px-6 py-4">
      <div className="flex flex-col items-center justify-between gap-2 text-sm text-gray-500 sm:flex-row">
        <p>
          &copy; {year} {APP_CONFIG.APP_NAME}. All rights reserved.
        </p>
        <p>Version {APP_CONFIG.APP_VERSION}</p>
      </div>
    </footer>
  );
}
