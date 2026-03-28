import { Injectable, signal } from '@angular/core';

export interface Notification {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  message: string;
  duration?: number;
}

@Injectable({
  providedIn: 'root'
})
export class NotificationService {
  private notifications = signal<Notification[]>([]);

  readonly notifications$ = this.notifications.asReadonly();

  show(type: Notification['type'], message: string, duration = 3000): void {
    const id = crypto.randomUUID();
    const notification: Notification = { id, type, message, duration };
    this.notifications.update(list => [...list, notification]);

    if (duration > 0) {
      setTimeout(() => this.dismiss(id), duration);
    }
  }

  success(message: string, duration?: number): void {
    this.show('success', message, duration);
  }

  error(message: string, duration?: number): void {
    this.show('error', message, duration);
  }

  warning(message: string, duration?: number): void {
    this.show('warning', message, duration);
  }

  info(message: string, duration?: number): void {
    this.show('info', message, duration);
  }

  dismiss(id: string): void {
    this.notifications.update(list => list.filter(n => n.id !== id));
  }

  clear(): void {
    this.notifications.set([]);
  }

  get items(): Notification[] {
    return this.notifications();
  }

  getMetrics(): Record<string, number> {
    const counts = this.notifications().reduce((acc, n) => {
      acc[n.type] = (acc[n.type] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);
    return counts;
  }
}
