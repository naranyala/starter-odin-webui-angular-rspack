/**
 * Security Tests
 * 
 * Comprehensive security testing for:
 * - Input validation
 * - XSS prevention
 * - SQL injection prevention
 * - Authentication
 * - Authorization
 */

import { TestBed } from '@angular/core/testing';
import { ValidationService } from './validation.service';

describe('Security Tests', () => {
  let validationService: ValidationService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    validationService = TestBed.inject(ValidationService);
  });

  // ============================================================================
  // Input Validation Tests
  // ============================================================================

  describe('Input Validation', () => {
    it('should reject empty input', () => {
      expect(validationService.isEmpty('')).toBe(true);
      expect(validationService.isEmpty('   ')).toBe(true);
      expect(validationService.isEmpty('valid')).toBe(false);
    });

    it('should validate email format', () => {
      expect(validationService.isValidEmail('test@example.com')).toBe(true);
      expect(validationService.isValidEmail('user.name@domain.co.uk')).toBe(true);
      
      expect(validationService.isValidEmail('invalid')).toBe(false);
      expect(validationService.isValidEmail('no@domain')).toBe(false);
      expect(validationService.isValidEmail('@example.com')).toBe(false);
      expect(validationService.isValidEmail('user@')).toBe(false);
    });

    it('should validate username format', () => {
      expect(validationService.isValidUsername('john_doe')).toBe(true);
      expect(validationService.isValidUsername('user123')).toBe(true);
      expect(validationService.isValidUsername('abc')).toBe(true);
      
      expect(validationService.isValidUsername('ab')).toBe(false);  // Too short
      expect(validationService.isValidUsername('user-name')).toBe(false);  // Special chars
      expect(validationService.isValidUsername('user name')).toBe(false);  // Space
    });

    it('should validate password strength', () => {
      expect(validationService.isValidPassword('Password1')).toBe(true);
      expect(validationService.isValidPassword('Secure123')).toBe(true);
      
      expect(validationService.isValidPassword('short')).toBe(false);  // Too short
      expect(validationService.isValidPassword('nouppercase1')).toBe(false);  // No uppercase
      expect(validationService.isValidPassword('NOLOWERCASE1')).toBe(false);  // No lowercase
      expect(validationService.isValidPassword('NoNumbers')).toBe(false);  // No numbers
    });

    it('should validate string length', () => {
      expect(validationService.hasMinLength('abc', 3)).toBe(true);
      expect(validationService.hasMinLength('abc', 2)).toBe(true);
      expect(validationService.hasMinLength('abc', 4)).toBe(false);
      
      expect(validationService.hasMaxLength('abc', 3)).toBe(true);
      expect(validationService.hasMaxLength('abc', 4)).toBe(true);
      expect(validationService.hasMaxLength('abc', 2)).toBe(false);
    });
  });

  // ============================================================================
  // XSS Prevention Tests
  // ============================================================================

  describe('XSS Prevention', () => {
    it('should detect XSS patterns', () => {
      const xssPatterns = [
        '<script>alert("xss")</script>',
        'javascript:alert(1)',
        'onerror="alert(1)"',
        'onload="alert(1)"',
        '<img src=x onerror=alert(1)>',
        'document.cookie',
        'eval("malicious")',
      ];

      xssPatterns.forEach(pattern => {
        expect(validationService.hasXSSPattern(pattern)).toBe(true, 
          `Should detect XSS: ${pattern}`);
      });
    });

    it('should sanitize HTML input', () => {
      const malicious = '<script>alert("xss")</script>Hello';
      const sanitized = validationService.sanitizeHTML(malicious);
      
      expect(sanitized).not.toContain('<script>');
      expect(sanitized).not.toContain('</script>');
      expect(sanitized).toContain('Hello');
    });

    it('should encode HTML special characters', () => {
      const input = '<script>&"\'</script>';
      const encoded = validationService.encodeHTML(input);
      
      expect(encoded).toContain('&lt;');
      expect(encoded).toContain('&gt;');
      expect(encoded).toContain('&amp;');
      expect(encoded).toContain('&quot;');
      expect(encoded).toContain('&#x27;');
    });

    it('should validate user input for XSS', () => {
      expect(validationService.validateUserInput('<script>alert(1)</script>')).toBe(false);
      expect(validationService.validateUserInput('javascript:alert(1)')).toBe(false);
      expect(validationService.validateUserInput('Normal text')).toBe(true);
    });
  });

  // ============================================================================
  // SQL Injection Prevention Tests
  // ============================================================================

  describe('SQL Injection Prevention', () => {
    it('should detect SQL injection patterns', () => {
      const injectionPatterns = [
        "'; DROP TABLE users; --",
        "1 OR 1=1",
        "1' OR '1'='1",
        "admin'--",
        "1; DELETE FROM users",
        "UNION SELECT * FROM users",
        "EXEC xp_cmdshell",
        "WAITFOR DELAY '00:00:10'",
        "BENCHMARK(1000000, SHA1('test'))",
      ];

      injectionPatterns.forEach(pattern => {
        expect(validationService.isSafeSQL(pattern)).toBe(false,
          `Should detect SQL injection: ${pattern}`);
      });
    });

    it('should allow safe SQL queries', () => {
      const safeQueries = [
        "SELECT * FROM users WHERE id = 1",
        "INSERT INTO users (name, email) VALUES (?, ?)",
        "UPDATE users SET name = ? WHERE id = ?",
        "DELETE FROM users WHERE id = ?",
      ];

      safeQueries.forEach(query => {
        expect(validationService.isSafeSQL(query)).toBe(true,
          `Should allow safe query: ${query}`);
      });
    });

    it('should sanitize SQL input', () => {
      const malicious = "test'; DROP TABLE users; --";
      const sanitized = validationService.sanitizeSQLInput(malicious);
      
      expect(sanitized).not.toContain("'");
      expect(sanitized).not.toContain(';');
      expect(sanitized).not.toContain('--');
    });

    it('should validate user input for SQL injection', () => {
      expect(validationService.validateUserInput("'; DROP TABLE users; --")).toBe(false);
      expect(validationService.validateUserInput("1 OR 1=1")).toBe(false);
      expect(validationService.validateUserInput("Normal name")).toBe(true);
    });
  });

  // ============================================================================
  // Authentication Tests
  // ============================================================================

  describe('Authentication', () => {
    it('should require credentials', () => {
      expect(validationService.validateLogin('', '')).toBe(false);
      expect(validationService.validateLogin('test@example.com', '')).toBe(false);
      expect(validationService.validateLogin('', 'password')).toBe(false);
      expect(validationService.validateLogin('test@example.com', 'password')).toBe(true);
    });

    it('should validate session token format', () => {
      expect(validationService.isValidSessionToken('sess_1234567890_abc123')).toBe(true);
      expect(validationService.isValidSessionToken('invalid')).toBe(false);
      expect(validationService.isValidSessionToken('')).toBe(false);
    });

    it('should detect expired sessions', () => {
      const now = Date.now();
      const expired = now - (25 * 60 * 60 * 1000);  // 25 hours ago
      const valid = now - (1 * 60 * 60 * 1000);  // 1 hour ago
      
      expect(validationService.isSessionExpired(expired, 24 * 60 * 60 * 1000)).toBe(true);
      expect(validationService.isSessionExpired(valid, 24 * 60 * 60 * 1000)).toBe(false);
    });
  });

  // ============================================================================
  // Authorization Tests
  // ============================================================================

  describe('Authorization', () => {
    it('should enforce role hierarchy', () => {
      expect(validationService.hasRole('admin', 'user')).toBe(true);
      expect(validationService.hasRole('admin', 'manager')).toBe(true);
      expect(validationService.hasRole('manager', 'user')).toBe(true);
      expect(validationService.hasRole('user', 'admin')).toBe(false);
      expect(validationService.hasRole('guest', 'user')).toBe(false);
    });

    it('should check permissions', () => {
      const adminPermissions = ['read', 'write', 'delete', 'admin'];
      const userPermissions = ['read', 'write'];
      
      adminPermissions.forEach(perm => {
        expect(validationService.hasPermission('admin', perm)).toBe(true);
      });
      
      expect(validationService.hasPermission('user', 'read')).toBe(true);
      expect(validationService.hasPermission('user', 'admin')).toBe(false);
    });
  });

  // ============================================================================
  // Rate Limiting Tests
  // ============================================================================

  describe('Rate Limiting', () => {
    it('should track failed attempts', () => {
      const tracker = validationService.createRateLimiter(5, 15 * 60 * 1000);
      
      for (let i = 0; i < 5; i++) {
        tracker.recordAttempt('192.168.1.1');
      }
      
      expect(tracker.isLimited('192.168.1.1')).toBe(true);
      expect(tracker.isLimited('192.168.1.2')).toBe(false);
    });

    it('should reset after timeout', () => {
      const tracker = validationService.createRateLimiter(5, 100);  // 100ms timeout
      
      for (let i = 0; i < 5; i++) {
        tracker.recordAttempt('192.168.1.1');
      }
      
      expect(tracker.isLimited('192.168.1.1')).toBe(true);
      
      // Wait for timeout
      setTimeout(() => {
        expect(tracker.isLimited('192.168.1.1')).toBe(false);
      }, 150);
    });
  });

  // ============================================================================
  // Data Protection Tests
  // ============================================================================

  describe('Data Protection', () => {
    it('should mask sensitive data', () => {
      expect(validationService.maskEmail('test@example.com')).toBe('t***@example.com');
      expect(validationService.maskPhone('1234567890')).toBe('123456***0');
      expect(validationService.maskSSN('123-45-6789')).toBe('***-**-6789');
    });

    it('should not expose sensitive data in logs', () => {
      const sensitiveData = {
        password: 'secret123',
        creditCard: '1234567890123456',
        ssn: '123-45-6789',
      };
      
      const sanitized = validationService.sanitizeForLogging(sensitiveData);
      
      expect(sanitized.password).toBe('[REDACTED]');
      expect(sanitized.creditCard).toBe('[REDACTED]');
      expect(sanitized.ssn).toBe('[REDACTED]');
    });
  });

  // ============================================================================
  // Input Sanitization Tests
  // ============================================================================

  describe('Input Sanitization', () => {
    it('should trim whitespace', () => {
      expect(validationService.trim('  hello  ')).toBe('hello');
    });

    it('should remove dangerous characters', () => {
      const dangerous = '<script>alert("xss")</script>';
      const sanitized = validationService.removeDangerousChars(dangerous);
      
      expect(sanitized).not.toContain('<');
      expect(sanitized).not.toContain('>');
    });

    it('should normalize input', () => {
      expect(validationService.normalizeInput('  Hello  World  ')).toBe('Hello World');
    });
  });
});
