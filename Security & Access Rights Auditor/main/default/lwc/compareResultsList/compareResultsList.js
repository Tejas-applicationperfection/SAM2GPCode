import { LightningElement, api, track } from 'lwc';

export default class CompareResultsList extends LightningElement {
    @api items = [];
    @api itemType = '';
    @api searchTerm = '';
    @api showDifferencesOnly = false;
    @api expanded = false;
    
    @track expandedItems = new Set();
    @track selectedItems = new Set();
    
    get filteredItems() {
        console.log('CompareResultsList - filteredItems called');
        console.log('CompareResultsList - items:', this.items);
        console.log('CompareResultsList - items length:', this.items ? this.items.length : 'null/undefined');
        
        if (!this.items || this.items.length === 0) {
            console.log('CompareResultsList - No items available');
            return [];
        }
        
        let filtered = [...this.items];
        console.log('CompareResultsList - Initial filtered items:', filtered);
        
        // Apply search filter
        if (this.searchTerm) {
            const searchLower = this.searchTerm.toLowerCase();
            filtered = filtered.filter(item => 
                item.name?.toLowerCase().includes(searchLower) ||
                item.label?.toLowerCase().includes(searchLower) ||
                item.description?.toLowerCase().includes(searchLower)
            );
            console.log('CompareResultsList - After search filter:', filtered);
        }
        
        // Apply differences only filter - show only items with actual differences
        if (this.showDifferencesOnly) {
            filtered = filtered.filter(item => 
                item.status === 'added' || 
                item.status === 'removed' || 
                item.status === 'changed'
            );
            console.log('CompareResultsList - After differences filter:', filtered);
        }
        
        // Process items for comparison display
        const processedItems = filtered.map(item => {
            const processedItem = { ...item };
            
            // Add required properties for display
            processedItem.id = processedItem.id || processedItem.name || Math.random().toString();
            processedItem.statusClass = this.getItemStatusClass(processedItem.status);
            processedItem.statusIcon = this.getItemStatusIcon(processedItem.status);
            processedItem.statusIconClass = processedItem.statusClass;
            processedItem.statusLabel = this.getItemStatusLabel(processedItem.status);
            processedItem.statusBadgeClass = `status-badge ${processedItem.statusClass}`;
            
            // Determine if we should show comparison details
            processedItem.showComparison = this.shouldShowComparison(item);
            
            // Determine if this item has value changes (for changed items)
            processedItem.hasValueChange = item.status === 'changed' && 
                (item.fromValue !== undefined && item.toValue !== undefined);
            
            // Show basic details for added/removed items
            processedItem.showDetails = (item.status === 'added' || item.status === 'removed') && 
                item.details && (item.details.apiName || item.details.type);
            
            return processedItem;
        });
        
        console.log('CompareResultsList - Final processed items:', processedItems);
        return processedItems;
    }
    
    get hasItems() {
        const filtered = this.filteredItems;
        const hasItemsResult = filtered && filtered.length > 0;
        console.log('CompareResultsList - hasItems called');
        console.log('CompareResultsList - filteredItems:', filtered);
        console.log('CompareResultsList - filteredItems length:', filtered ? filtered.length : 'null/undefined');
        console.log('CompareResultsList - hasItems result:', hasItemsResult);
        return hasItemsResult;
    }
    
    connectedCallback() {
        // Component initialization - no expansion needed for simplified view
    }
    
    renderedCallback() {
        // Component rendered - no special handling needed
    }
    
    /**
     * Determines if comparison details should be shown for an item
     */
    shouldShowComparison(item) {
        // Show comparison details for changed items with value changes
        // or for added/removed items with additional details
        return (item.status === 'changed' && (item.fromValue || item.toValue)) ||
               ((item.status === 'added' || item.status === 'removed') && 
                item.details && (item.details.apiName || item.details.type));
    }
    
    getItemStatusClass(status) {
        switch (status) {
            case 'added':
                return 'status-added';
            case 'removed':
                return 'status-removed';
            case 'changed':
                return 'status-changed';
            case 'unchanged':
                return 'status-unchanged';
            default:
                return 'status-unknown';
        }
    }
    
    getItemStatusIcon(status) {
        switch (status) {
            case 'added':
                return 'utility:add';
            case 'removed':
                return 'utility:dash';
            case 'changed':
                return 'utility:swap';
            case 'unchanged':
                return 'utility:check';
            default:
                return 'utility:info';
        }
    }
    
    getItemStatusLabel(status) {
        switch (status) {
            case 'added':
                return 'Added';
            case 'removed':
                return 'Removed';
            case 'changed':
                return 'Changed';
            case 'unchanged':
                return 'Unchanged';
            default:
                return 'Unknown';
        }
    }
    
    /**
     * Gets a clean display message for empty states
     */
    get noItemsMessage() {
        console.log('CompareResultsList - noItemsMessage called');
        console.log('CompareResultsList - searchTerm:', this.searchTerm);
        console.log('CompareResultsList - showDifferencesOnly:', this.showDifferencesOnly);
        console.log('CompareResultsList - itemType:', this.itemType);
        
        if (this.showDifferencesOnly) {
            return `No ${this.itemType.toLowerCase()} differences found between the selected users.`;
        }
        return this.searchTerm ? 
            `No ${this.itemType.toLowerCase()}s match your search criteria.` : 
            `No ${this.itemType.toLowerCase()}s to compare.`;
    }
}