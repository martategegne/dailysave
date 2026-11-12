/**
 * Lightweight, zero-dependency input validation engine for DailySave APIs.
 */

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export class ValidationError extends Error {
  constructor(errors) {
    super('Validation failed');
    this.name = 'ValidationError';
    this.statusCode = 400;
    this.errors = errors;
  }
}

export const validator = {
  isEmail(value) {
    return typeof value === 'string' && EMAIL_REGEX.test(value.trim());
  },

  isStrongPassword(value) {
    if (typeof value !== 'string') return false;
    // Minimum 8 characters, at least 1 letter and 1 number
    return value.length >= 8 && /[A-Za-z]/.test(value) && /\d/.test(value);
  },

  isUuid(value) {
    return typeof value === 'string' && UUID_REGEX.test(value.trim());
  },

  isPositiveInteger(value) {
    return (
      Number.isInteger(value) &&
      value > 0 &&
      Number.isSafeInteger(value)
    );
  },

  isNonEmptyString(value) {
    return typeof value === 'string' && value.trim().length > 0;
  },

  isIn(value, allowedList) {
    return allowedList.includes(value);
  },

  isIsoDate(value) {
    if (typeof value !== 'string') return false;
    const d = new Date(value);
    return !isNaN(d.getTime());
  },
};

/**
 * Validates an object against a declarative field rule schema.
 * @param {Record<string, any>} data
 * @param {Record<string, { required?: boolean, validator?: (val: any) => boolean, message?: string }>} schema
 * @throws {ValidationError}
 */
export function validateSchema(data, schema) {
  const errors = {};

  for (const [field, rule] of Object.entries(schema)) {
    const value = data?.[field];

    if (rule.required && (value === undefined || value === null || value === '')) {
      errors[field] = rule.message || `${field} is required.`;
      continue;
    }

    if (value !== undefined && value !== null && rule.validator) {
      if (!rule.validator(value)) {
        errors[field] = rule.message || `${field} is invalid.`;
      }
    }
  }

  if (Object.keys(errors).length > 0) {
    throw new ValidationError(errors);
  }
}
