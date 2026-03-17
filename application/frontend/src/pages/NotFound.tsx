import { Link } from 'react-router-dom';
import { Home, ArrowLeft } from 'lucide-react';

export default function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] text-center px-4">
      <div className="text-8xl font-bold text-gray-200 mb-4">404</div>
      <h1 className="text-2xl font-bold text-gray-900 mb-2">Page Not Found</h1>
      <p className="text-gray-500 mb-8 max-w-md">
        The page you are looking for does not exist or has been moved. Please check the URL or
        navigate back to a known page.
      </p>
      <div className="flex gap-3">
        <button
          onClick={() => window.history.back()}
          className="btn-secondary gap-2"
        >
          <ArrowLeft className="h-4 w-4" />
          Go Back
        </button>
        <Link to="/" className="btn-primary gap-2">
          <Home className="h-4 w-4" />
          Go Home
        </Link>
      </div>
    </div>
  );
}
