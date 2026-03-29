import { Component, signal, inject, Input, Output, EventEmitter, OnInit, OnChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../core/api.service';
import { LoggerService } from '../../core/logger.service';
import { DataTableColumn, FormField, DataTableConfig, User, Product, Order, StatsUpdateEvent } from '../../models';

@Component({
  selector: 'app-data-table',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './data-table.component.html',
  styleUrls: ['./data-table.component.css']
})
export class DataTableComponent implements OnInit, OnChanges {
  private api = inject(ApiService);
  private logger = inject(LoggerService);

  @Input() config: DataTableConfig | null = null;
  @Input() items: (User | Product | Order)[] = [];
  @Output() itemsChange = new EventEmitter<(User | Product | Order)[]>();
  @Output() statsChange = new EventEmitter<StatsUpdateEvent>();

  filteredItems = signal<(User | Product | Order)[]>([]);
  searchQuery = signal('');
  showModal = signal(false);
  editingItem = signal<User | Product | Order | null>(null);
  formData = signal<Record<string, unknown>>({});
  isLoading = signal(false);

  ngOnInit(): void {
    this.filterItems();
  }

  ngOnChanges(): void {
    this.filterItems();
  }

  filterItems(): void {
    const query = this.searchQuery().toLowerCase();
    if (!query) {
      this.filteredItems.set([...this.items]);
      return;
    }
    this.filteredItems.set(
      this.items.filter(item =>
        Object.values(item).some(val =>
          val !== null && val !== undefined &&
          String(val).toLowerCase().includes(query)
        )
      )
    );
  }

  formatDate(dateStr: string): string {
    if (!dateStr) return '';
    return new Date(dateStr).toLocaleDateString();
  }

  /**
   * Get value from item by key - helper for template
   */
  getItemValue(item: User | Product | Order, key: string): string | number {
    const value = (item as unknown as Record<string, unknown>)[key];
    return value as string | number;
  }

  /**
   * Format date value - helper for template
   */
  formatDateValue(item: User | Product | Order, key: string): string {
    const value = this.getItemValue(item, key);
    if (typeof value !== 'string') return '';
    return this.formatDate(value);
  }

  /**
   * Update form data - helper for template
   */
  updateFormData(key: string, value: unknown): void {
    this.formData.update(data => ({ ...data, [key]: value }));
  }

  showCreateModal(): void {
    this.editingItem.set(null);
    const initialData: Record<string, unknown> = {};
    if (this.config?.formFields) {
      for (const field of this.config.formFields) {
        initialData[field.key] = field.type === 'number' ? 0 : '';
      }
    }
    this.formData.set(initialData);
    this.showModal.set(true);
  }

  editItem(item: User | Product | Order): void {
    this.editingItem.set({ ...item });
    this.formData.set({ ...item });
    this.showModal.set(true);
  }

  closeModal(): void {
    this.showModal.set(false);
    this.editingItem.set(null);
  }

  async saveItem(): Promise<void> {
    if (!this.config) return;
    this.isLoading.set(true);
    try {
      const data = this.formData();
      if (this.editingItem()) {
        await this.api.callOrThrow(`update${this.config.entityName}`, [
          (this.editingItem() as any).id,
          ...this.config.formFields.map(f => data[f.key])
        ]);
      } else {
        await this.api.callOrThrow(`create${this.config.entityName}`,
          this.config.formFields.map(f => data[f.key])
        );
      }
      this.closeModal();
      this.statsChange.emit({ type: `total${this.config.entityNamePlural}` as any, count: this.items.length });
    } catch (error) {
      this.logger.error(`Failed to save ${this.config.entityName}`, error);
    } finally {
      this.isLoading.set(false);
    }
  }

  async deleteItem(item: User | Product | Order): Promise<void> {
    if (!this.config) return;
    const itemName = (item as any).name || (item as any).customer_name || 'item';
    if (!confirm(`Delete ${itemName}?`)) return;
    this.isLoading.set(true);
    try {
      await this.api.callOrThrow(`delete${this.config.entityName}`, [(item as any).id]);
      this.statsChange.emit({ type: `total${this.config.entityNamePlural}` as any, count: this.items.length - 1 });
    } catch (error) {
      this.logger.error(`Failed to delete ${this.config.entityName}`, error);
    } finally {
      this.isLoading.set(false);
    }
  }
}
