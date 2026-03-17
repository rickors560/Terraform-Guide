export interface ValidationResult {
  valid: boolean;
  message: string;
}

export function validateRequired(value: string, fieldName: string): ValidationResult {
  if (!value || value.trim().length === 0) {
    return { valid: false, message: `${fieldName} is required` };
  }
  return { valid: true, message: '' };
}

export function validateEmail(email: string): ValidationResult {
  if (!email || email.trim().length === 0) {
    return { valid: false, message: 'Email is required' };
  }
  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  if (!emailRegex.test(email)) {
    return { valid: false, message: 'Please enter a valid email address' };
  }
  return { valid: true, message: '' };
}

export function validatePassword(password: string): ValidationResult {
  if (!password || password.length === 0) {
    return { valid: false, message: 'Password is required' };
  }
  if (password.length < 8) {
    return { valid: false, message: 'Password must be at least 8 characters' };
  }
  if (!/[A-Z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one uppercase letter' };
  }
  if (!/[a-z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one lowercase letter' };
  }
  if (!/[0-9]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one number' };
  }
  return { valid: true, message: '' };
}

export function validateMinLength(
  value: string,
  minLength: number,
  fieldName: string,
): ValidationResult {
  if (value.length < minLength) {
    return { valid: false, message: `${fieldName} must be at least ${minLength} characters` };
  }
  return { valid: true, message: '' };
}

export function validateMaxLength(
  value: string,
  maxLength: number,
  fieldName: string,
): ValidationResult {
  if (value.length > maxLength) {
    return { valid: false, message: `${fieldName} must be at most ${maxLength} characters` };
  }
  return { valid: true, message: '' };
}

export function validatePositiveNumber(value: number, fieldName: string): ValidationResult {
  if (isNaN(value) || value < 0) {
    return { valid: false, message: `${fieldName} must be a positive number` };
  }
  return { valid: true, message: '' };
}

export function validatePrice(value: number): ValidationResult {
  if (isNaN(value) || value < 0) {
    return { valid: false, message: 'Price must be a positive number' };
  }
  if (value > 999999.99) {
    return { valid: false, message: 'Price cannot exceed $999,999.99' };
  }
  return { valid: true, message: '' };
}

export function validateUrl(url: string): ValidationResult {
  if (!url || url.trim().length === 0) {
    return { valid: true, message: '' };
  }
  try {
    new URL(url);
    return { valid: true, message: '' };
  } catch {
    return { valid: false, message: 'Please enter a valid URL' };
  }
}
