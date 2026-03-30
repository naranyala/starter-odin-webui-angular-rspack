/**
 * Validation Service
 * 
 * Provides input validation, sanitization, and security checks
 */

import { Injectable } from '@angular/core';

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
}

export interface ValidationError {
  field: string;
  code: string;
  message: string;
}

export interface RateLimiter {
  recordAttempt: (key: string) => void;
  isLimited: (key: string) => boolean;
  reset: (key: string) => void;
}

@Injectable({
  providedIn: 'root'
})
export class ValidationService {

  // ============================================================================
  // String Validators
  // ============================================================================

  isEmpty(value: string): boolean {
    return !value || value.trim().length === 0;
  }

  hasMinLength(value: string, min: number): boolean {
    return value ? value.length >= min : false;
  }

  hasMaxLength(value: string, max: number): boolean {
    return value ? value.length <= max : false;
  }

  isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  isValidUsername(username: string): boolean {
    const usernameRegex = /^[a-zA-Z0-9_]{3,30}$/;
    return usernameRegex.test(username);
  }

  isValidPassword(password: string): boolean {
    if (!password || password.length < 8) {
      return false;
    }
    
    const hasUpper = /[A-Z]/.test(password);
    const hasLower = /[a-z]/.test(password);
    const hasDigit = /[0-9]/.test(password);
    
    return hasUpper && hasLower && hasDigit;
  }

  // ============================================================================
  // XSS Prevention
  // ============================================================================

  hasXSSPattern(input: string): boolean {
    const xssPatterns = [
      /<script/i,
      /javascript:/i,
      /onerror\s*=/i,
      /onload\s*=/i,
      /onclick\s*=/i,
      /onmouse/i,
      /alert\s*\(/i,
      /confirm\s*\(/i,
      /prompt\s*\(/i,
      /document\.cookie/i,
      /document\.write/i,
      /eval\s*\(/i,
    ];

    return xssPatterns.some(pattern => pattern.test(input));
  }

  sanitizeHTML(input: string): string {
    return input
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#x27;')
      .replace(/&/g, '&amp;');
  }

  encodeHTML(input: string): string {
    const htmlEntities: Record<string, string> = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#x27;',
    };

    return input.replace(/[&<>"']/g, char => htmlEntities[char]);
  }

  validateUserInput(input: string): boolean {
    return !this.hasXSSPattern(input) && this.isSafeSQL(input);
  }

  // ============================================================================
  // SQL Injection Prevention
  // ============================================================================

  isSafeSQL(input: string): boolean {
    const dangerousPatterns = [
      /--/i,
      /;/i,
      /\/\*/i,
      /\*\//i,
      /xp_/i,
      /exec\s/i,
      /execute\s/i,
      /drop\s/i,
      /delete\s+from/i,
      /truncate\s/i,
      /alter\s/i,
      /union\s/i,
      /or\s+1\s*=\s*1/i,
      /or\s+'1'\s*=\s*'1'/i,
      /and\s+1\s*=\s*1/i,
      /waitfor\s/i,
      /benchmark\s*\(/i,
      /sleep\s*\(/i,
    ];

    return !dangerousPatterns.some(pattern => pattern.test(input));
  }

  sanitizeSQLInput(input: string): string {
    return input
      .replace(/'/g, '')
      .replace(/"/g, '')
      .replace(/;/g, '')
      .replace(/--/g, '')
      .replace(/\/\*/g, '')
      .replace(/\*\//g, '');
  }

  // ============================================================================
  // Authentication Validation
  // ============================================================================

  validateLogin(email: string, password: string): boolean {
    return !this.isEmpty(email) && !this.isEmpty(password);
  }

  isValidSessionToken(token: string): boolean {
    const tokenRegex = /^sess_\d+_\w+$/;
    return tokenRegex.test(token);
  }

  isSessionExpired(timestamp: number, ttl: number): boolean {
    return Date.now() > timestamp + ttl;
  }

  // ============================================================================
  // Authorization
  // ============================================================================

  hasRole(userRole: string, requiredRole: string): boolean {
    const roleHierarchy: Record<string, number> = {
      guest: 0,
      user: 1,
      manager: 2,
      admin: 3,
    };

    const userLevel = roleHierarchy[userRole.toLowerCase()] ?? 0;
    const requiredLevel = roleHierarchy[requiredRole.toLowerCase()] ?? 0;

    return userLevel >= requiredLevel;
  }

  hasPermission(role: string, permission: string): boolean {
    const permissions: Record<string, string[]> = {
      admin: ['read', 'write', 'delete', 'admin'],
      manager: ['read', 'write', 'delete'],
      user: ['read', 'write'],
      guest: ['read'],
    };

    return permissions[role.toLowerCase()]?.includes(permission) ?? false;
  }

  // ============================================================================
  // Rate Limiting
  // ============================================================================

  createRateLimiter(maxAttempts: number, windowMs: number): RateLimiter {
    const attempts = new Map<string, { count: number; resetTime: number }>();

    return {
      recordAttempt: (key: string) => {
        const now = Date.now();
        const record = attempts.get(key) || { count: 0, resetTime: now + windowMs };

        if (now > record.resetTime) {
          record.count = 0;
          record.resetTime = now + windowMs;
        }

        record.count++;
        attempts.set(key, record);
      },

      isLimited: (key: string): boolean => {
        const record = attempts.get(key);
        if (!record) {
          return false;
        }

        const now = Date.now();
        if (now > record.resetTime) {
          return false;
        }

        return record.count >= maxAttempts;
      },

      reset: (key: string) => {
        attempts.delete(key);
      },
    };
  }

  // ============================================================================
  // Data Protection
  // ============================================================================

  maskEmail(email: string): string {
    if (!email || !email.includes('@')) {
      return email;
    }

    const [local, domain] = email.split('@');
    const maskedLocal = local.charAt(0) + '***';
    
    return `${maskedLocal}@${domain}`;
  }

  maskPhone(phone: string): string {
    if (!phone || phone.length < 4) {
      return phone;
    }

    return phone.substring(0, phone.length - 1).replace(/\d/g, '*') + 
           phone.charAt(phone.length - 1);
  }

  maskSSN(ssn: string): string {
    if (!ssn || ssn.length < 4) {
      return ssn;
    }

    return '***-**-' + ssn.substring(ssn.length - 4);
  }

  sanitizeForLogging(data: Record<string, any>): Record<string, any> {
    const sensitiveFields = ['password', 'creditCard', 'ssn', 'token', 'secret', 'apiKey'];
    const sanitized = { ...data };

    for (const field of sensitiveFields) {
      if (sanitized[field]) {
        sanitized[field] = '[REDACTED]';
      }
    }

    return sanitized;
  }

  // ============================================================================
  // Input Sanitization
  // ============================================================================

  trim(value: string): string {
    return value?.trim() ?? '';
  }

  removeDangerousChars(input: string): string {
    return input
      .replace(/[<>]/g, '')
      .replace(/javascript:/gi, '')
      .replace(/on\w+\s*=/gi, '');
  }

  normalizeInput(input: string): string {
    return input
      .trim()
      .replace(/\s+/g, ' ');
  }

  // ============================================================================
  // User Validation
  // ============================================================================

  validateUser(name: string, email: string, age: number): ValidationResult {
    const errors: ValidationError[] = [];

    // Validate name
    if (this.isEmpty(name)) {
      errors.push({
        field: 'name',
        code: 'required',
        message: 'Name is required',
      });
    } else if (!this.hasMaxLength(name, 100)) {
      errors.push({
        field: 'name',
        code: 'max_length',
        message: 'Name cannot exceed 100 characters',
      });
    }

    // Validate email
    if (!this.isValidEmail(email)) {
      errors.push({
        field: 'email',
        code: 'invalid',
        message: 'Invalid email format',
      });
    }

    // Validate age
    if (age < 1 || age > 150) {
      errors.push({
        field: 'age',
        code: 'invalid',
        message: 'Age must be between 1 and 150',
      });
    }

    return {
      valid: errors.length === 0,
      errors,
    };
  }

  validateProduct(name: string, price: number, stock: number): ValidationResult {
    const errors: ValidationError[] = [];

    // Validate name
    if (this.isEmpty(name)) {
      errors.push({
        field: 'name',
        code: 'required',
        message: 'Product name is required',
      });
    } else if (!this.hasMaxLength(name, 200)) {
      errors.push({
        field: 'name',
        code: 'max_length',
        message: 'Product name cannot exceed 200 characters',
      });
    }

    // Validate price
    if (price < 0) {
      errors.push({
        field: 'price',
        code: 'invalid',
        message: 'Price cannot be negative',
      });
    }

    // Validate stock
    if (stock < 0) {
      errors.push({
        field: 'stock',
        code: 'invalid',
        message: 'Stock cannot be negative',
      });
    }

    return {
      valid: errors.length === 0,
      errors,
    };
  }
}
