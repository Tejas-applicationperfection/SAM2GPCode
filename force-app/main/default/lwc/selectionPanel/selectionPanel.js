import { LightningElement, api, track } from 'lwc';

/**
 * @description Reusable component for showing a list of items with selection capability - OPTIMIZED VERSION
 */
export default class SelectionPanel extends LightningElement {
    @api title;
    @track _items = [];
    @track filteredItems = [];
    @track displayedItems = []; // Items currently displayed (for virtual scrolling)
    @track searchTerm = '';
    @track selectedCount = 0;
    @track totalCount = 0;
    @track isSelectAllChecked = false;
    
    // Virtual scrolling properties
    @track virtualScrollEnabled = true;
    @track itemHeight = 60; // Height of each item in pixels
    @track containerHeight = 300; // Height of the scrollable container
    @track visibleItemCount = 10; // Number of items to render at once
    @track scrollTop = 0;
    @track startIndex = 0;
    @track endIndex = 10;
    
    // Pagination properties
    @track _enablePagination = false;
    @track currentPage = 1;
    @track pageSize = 50;
    @track totalPages = 1;
    @track hasNextPage = false;
    @track hasPreviousPage = false;
    
    // Performance optimization
    @track debounceTimeout;
    @api isLoading = false;
    @track loadingMore = false;
    
    @api showIncludeAllToggle = false;
    @track includeAllChecked = false;




// Add these properties after the existing @track properties
@api showLicenseFilter = false;
@api showPrivilegedFilter = false;
@track selectedLicenseType = '';
@track licenseTypeOptions = [];

// Add this API property to receive license options from parent
@api
set licenseOptions(value) {
    if (value && Array.isArray(value)) {
        this.licenseTypeOptions = value;
    }
}

get licenseOptions() {
    return this.licenseTypeOptions;
}

// Add this method after handleSearchChange
handleLicenseTypeChange(event) {
    this.selectedLicenseType = event.detail.value;
    
    // Dispatch event to parent component
    const licenseChangeEvent = new CustomEvent('licensechange', {
        detail: {
            selectedLicenseType: this.selectedLicenseType
        }
    });
    this.dispatchEvent(licenseChangeEvent);
}

/**
 * @description Handle select all privileged permissions
 */
handleSelectAllPrivileged() {
    // Dispatch event to parent component to handle the selection
    const selectPrivilegedEvent = new CustomEvent('selectprivileged');
    this.dispatchEvent(selectPrivilegedEvent);
}
    
    /**
     * @description Getter and setter for the items array
     */
    @api
    get items() {
        return this._items;
    }
    
    set items(value) {
        if (value && Array.isArray(value)) {
            // Create new arrays to ensure proper reactivity and add unique keys
            this._items = value.map(item => this.addUniqueKeys(item));
            this.filteredItems = [...this._items];
            this.totalCount = value.length;
            this.selectedCount = value.filter(item => item && item.isSelected).length;
            this.updateSelectAllState();
            this.updateVirtualScroll();
            this.updatePagination();
        } else {
            // Initialize with empty arrays if no valid data provided
            this._items = [];
            this.filteredItems = [];
            this.totalCount = 0;
            this.selectedCount = 0;
        }
    }
    
    /**
     * @description Add unique keys to an item to prevent conflicts across different contexts
     * @param {Object} item - Item to add unique keys to
     * @returns {Object} Item with unique keys added
     */
    addUniqueKeys(item) {
        if (!item) return item;
        
        // Ensure we have a valid ID
        const itemId = item.id || item.name || item.label || Math.random().toString(36).substr(2, 9);
        
        // Create a context-specific prefix based on title
        const contextPrefix = this.title ? this.title.toLowerCase().replace(/\s+/g, '-') : 'default';
        
        return {
            ...item,
            id: itemId, // Ensure ID is set
            uniqueKey: `${contextPrefix}-${itemId}`,
            uniqueInputId: `${contextPrefix}-input-${itemId}`,
            privilegedClass: item.isPrivileged ? 'privileged-permission-text' : ''
        };
    }
    
    /**
     * @description API method to enable/disable virtual scrolling
     */
    @api
    set enableVirtualScrolling(value) {
        this.virtualScrollEnabled = value;
        if (value) {
            this.updateVirtualScroll();
        } else {
            this.displayedItems = this.filteredItems;
        }
    }
    
    get enableVirtualScrolling() {
        return this.virtualScrollEnabled;
    }
    
    /**
     * @description API method to set page size for pagination
     */
    @api
    set itemsPerPage(value) {
        this.pageSize = value || 50;
        this.updatePagination();
    }
    
    get itemsPerPage() {
        return this.pageSize;
    }

    /**
     * @description API method to enable/disable pagination
     */
    @api
    set enablePagination(value) {
        this._enablePagination = Boolean(value);
        this.virtualScrollEnabled = !this._enablePagination; // Disable virtual scroll when pagination is enabled
        this.updatePagination();
    }

    get enablePagination() {
        return this._enablePagination;
    }
    
    /**
     * @description Lifecycle hook after component is rendered
     */
    renderedCallback() {
        if (this.virtualScrollEnabled) {
            this.setupVirtualScrolling();
        }
    }
    
    /**
     * @description Setup virtual scrolling event listeners
     */
    setupVirtualScrolling() {
        const scrollContainer = this.template.querySelector('.virtual-scroll-container');
        if (scrollContainer && !scrollContainer.hasScrollListener) {
            scrollContainer.addEventListener('scroll', this.handleScroll.bind(this));
            scrollContainer.hasScrollListener = true;
        }
    }
    
    /**
     * @description Handle scroll events for virtual scrolling
     */
    handleScroll(event) {
        if (!this.virtualScrollEnabled) return;
        
        const scrollTop = event.target.scrollTop;
        this.scrollTop = scrollTop;
        
        // Throttle scroll events
        clearTimeout(this.scrollTimeout);
        this.scrollTimeout = setTimeout(() => {
            this.updateVirtualScroll();
        }, 16); // ~60fps
    }
    
    /**
     * @description Update virtual scroll display
     */
    updateVirtualScroll() {
        if (!this.virtualScrollEnabled || this.filteredItems.length === 0) {
            this.displayedItems = this.filteredItems;
            return;
        }
        
        // Calculate visible range
        const startIndex = Math.floor(this.scrollTop / this.itemHeight);
        const visibleCount = Math.ceil(this.containerHeight / this.itemHeight);
        const bufferSize = Math.ceil(visibleCount / 2); // Buffer for smooth scrolling
        
        this.startIndex = Math.max(0, startIndex - bufferSize);
        this.endIndex = Math.min(this.filteredItems.length, startIndex + visibleCount + bufferSize);
        
        // Update displayed items
        this.displayedItems = this.filteredItems.slice(this.startIndex, this.endIndex);
        
        // Update scroll container styles
        this.updateScrollContainerStyles();
    }
    
    /**
     * @description Update scroll container styles for virtual scrolling
     */
    updateScrollContainerStyles() {
        const scrollContainer = this.template.querySelector('.virtual-scroll-container');
        const itemList = this.template.querySelector('.virtual-item-list');
        
        if (scrollContainer && itemList) {
            const totalHeight = this.filteredItems.length * this.itemHeight;
            const offsetTop = this.startIndex * this.itemHeight;
            
            scrollContainer.style.height = `${this.containerHeight}px`;
            itemList.style.height = `${totalHeight}px`;
            itemList.style.paddingTop = `${offsetTop}px`;
        }
    }
    
    /**
     * @description Update pagination info
     */
    updatePagination() {
        if (!this._enablePagination) return;
        
        this.totalPages = Math.ceil(this.filteredItems.length / this.pageSize);
        this.hasNextPage = this.currentPage < this.totalPages;
        this.hasPreviousPage = this.currentPage > 1;
        
        // Update displayed items for pagination
        if (!this.virtualScrollEnabled) {
            const startIndex = (this.currentPage - 1) * this.pageSize;
            const endIndex = Math.min(startIndex + this.pageSize, this.filteredItems.length);
            this.displayedItems = this.filteredItems.slice(startIndex, endIndex);
        }
    }
    
    /**
     * @description Get the search placeholder text
     * @returns {String} Search placeholder text
     */
    get searchPlaceholder() {
        return `Filter ${this.title}`;
    }
    
    /**
     * @description Get the ID for the select all checkbox
     * @returns {String} Select all checkbox ID
     */
    get selectAllId() {
        return `select-all-${this.title.toLowerCase().replace(/\s+/g, '-')}`;
    }
    
    /**
     * @description Get the display name for an item (name or label)
     * @param {Object} item - Item to get display name for
     * @returns {String} Display name
     */
    getItemDisplayName(item) {
        return item.name || item.label;
    }
    
    /**
     * @description Handle search input change with debouncing
     * @param {Event} event - Input change event
     */
    handleSearchChange(event) {
        const searchTerm = event.target.value.toLowerCase();
        this.searchTerm = searchTerm;
        
        // Debounce search to improve performance
        clearTimeout(this.debounceTimeout);
        this.debounceTimeout = setTimeout(() => {
            this.filterItems();
        }, 300);
    }
    
    /**
     * @description Filter items based on search term
     */
    filterItems() {
        this.isLoading = true;
        
        // Use requestAnimationFrame to avoid blocking the UI
        requestAnimationFrame(() => {
            try {
                if (!Array.isArray(this._items)) {
                    console.error('SelectionPanel: _items is not an array in filterItems:', this._items);
                    this.filteredItems = [];
                } else if (!this.searchTerm) {
                    this.filteredItems = [...this._items];
                } else {
                    this.filteredItems = this._items.filter(item => 
                        item && (
                            (item.name && item.name.toLowerCase().includes(this.searchTerm)) ||
                            (item.label && item.label.toLowerCase().includes(this.searchTerm))
                        )
                    );
                }
                
                // Ensure filtered items also have unique keys
                this.filteredItems = this.filteredItems.map(item => this.addUniqueKeys(item));
                
                // Reset pagination and virtual scroll
                this.currentPage = 1;
                this.scrollTop = 0;
                this.updatePagination();
                this.updateVirtualScroll();
            } catch (error) {
                console.error('SelectionPanel: Error in filterItems:', error);
                this.filteredItems = [];
            } finally {
                this.isLoading = false;
            }
        });
    }
    
    /**
     * @description Handle selection of an individual item
     * @param {Event} event - Checkbox change event
     */
    handleItemSelection(event) {
        const itemId = event.target.dataset.id || event.target.id;
        const isChecked = event.target.checked;
        
        // Use batch update for better performance
        this.updateItemSelection(itemId, isChecked);
    }
    
    /**
     * @description Update item selection state
     */
    updateItemSelection(itemId, isChecked) {
        try {
            // Ensure we have valid data
            if (!Array.isArray(this._items)) {
                console.error('SelectionPanel: _items is not an array:', this._items);
                return;
            }
            
            if (!itemId) {
                console.error('SelectionPanel: itemId is required for updateItemSelection');
                return;
            }
            
            // Create new arrays instead of modifying existing ones (LWC reactive pattern)
            // Update the main items array
            this._items = this._items.map(item => {
                if (item && item.id === itemId) {
                    return this.addUniqueKeys({ ...item, isSelected: isChecked });
                }
                return item;
            });
            
            // Update filtered items
            if (Array.isArray(this.filteredItems)) {
                this.filteredItems = this.filteredItems.map(item => {
                    if (item && item.id === itemId) {
                        return this.addUniqueKeys({ ...item, isSelected: isChecked });
                    }
                    return item;
                });
            }
            
            // Update displayed items
            if (Array.isArray(this.displayedItems)) {
                this.displayedItems = this.displayedItems.map(item => {
                    if (item && item.id === itemId) {
                        return this.addUniqueKeys({ ...item, isSelected: isChecked });
                    }
                    return item;
                });
            }
            
            this.selectedCount = this._items.filter(item => item && item.isSelected).length;
            this.updateSelectAllState();
            this.dispatchSelectionChangeEvent();
        } catch (error) {
            console.error('SelectionPanel: Error in updateItemSelection:', error);
        }
    }
    
    /**
     * @description Handle row click - toggles the checkbox
     * @param {Event} event - Row click event
     */
    handleRowClick(event) {
        try {
            if (!event || !event.currentTarget) {
                console.error('SelectionPanel: Invalid event in handleRowClick:', event);
                return;
            }
            
            const itemId = event.currentTarget.dataset.id;
            if (!itemId) {
                console.error('SelectionPanel: No itemId found in event target');
                return;
            }
            
            if (!Array.isArray(this._items)) {
                console.error('SelectionPanel: _items is not an array in handleRowClick:', this._items);
                return;
            }
            
            const item = this._items.find(i => i && i.id === itemId);
            if (item) {
                const newStatus = !item.isSelected;
                this.updateItemSelection(itemId, newStatus);
            } else {
                console.warn('SelectionPanel: Item not found for id:', itemId);
            }
        } catch (error) {
            console.error('SelectionPanel: Error in handleRowClick:', error);
        }
    }
    
    /**
     * @description Stop event propagation when clicking directly on the checkbox
     * @param {Event} event - Checkbox click event
     */
    handleCheckboxClick(event) {
        event.stopPropagation();
    }
    
    /**
     * @description Handle select all checkbox change
     * @param {Event} event - Checkbox change event
     */
    handleSelectAll(event) {
        const isChecked = event.target.checked;
        this.isSelectAllChecked = isChecked;
        
        // Use batch update for better performance
        this.batchUpdateAllItems(isChecked);
    }
    
    /**
     * @description Batch update all items selection state
     */
    batchUpdateAllItems(isChecked) {
        this.isLoading = true;
        
        // Use requestAnimationFrame to avoid blocking the UI
        requestAnimationFrame(() => {
            try {
                // Create new arrays with updated selection state (LWC reactive pattern)
                if (Array.isArray(this._items)) {
                    this._items = this._items.map(item => this.addUniqueKeys({
                        ...item,
                        isSelected: isChecked
                    }));
                }
                
                if (Array.isArray(this.filteredItems)) {
                    this.filteredItems = this.filteredItems.map(item => this.addUniqueKeys({
                        ...item,
                        isSelected: isChecked
                    }));
                }
                
                if (Array.isArray(this.displayedItems)) {
                    this.displayedItems = this.displayedItems.map(item => this.addUniqueKeys({
                        ...item,
                        isSelected: isChecked
                    }));
                }
                
                this.selectedCount = isChecked ? this._items.length : 0;
                this.dispatchSelectionChangeEvent();
            } catch (error) {
                console.error('SelectionPanel: Error in batchUpdateAllItems:', error);
            } finally {
                this.isLoading = false;
            }
        });
    }
    
    /**
     * @description Update the state of the select all checkbox
     */
    updateSelectAllState() {
        this.isSelectAllChecked = this._items.length > 0 && 
            this.selectedCount === this._items.length;
    }
    
    /**
     * @description Handle pagination - next page
     */
    handleNextPage() {
        if (this.hasNextPage) {
            this.currentPage++;
            this.updatePagination();
            this.dispatchEvent(new CustomEvent('loadmore'));
        }
    }
    
    /**
     * @description Handle pagination - previous page
     */
    handlePreviousPage() {
        if (this.hasPreviousPage) {
            this.currentPage--;
            this.updatePagination();
        }
    }
    
    /**
     * @description Handle load more for infinite scroll
     */
    handleLoadMore() {
        if (!this.loadingMore) {
            this.loadingMore = true;
            this.dispatchEvent(new CustomEvent('loadmore'));
            
            // Reset loading state after a delay
            setTimeout(() => {
                this.loadingMore = false;
            }, 1000);
        }
    }
    
    /**
     * @description Dispatch a custom event when selections change
     */
    dispatchSelectionChangeEvent() {
        try {
            if (!Array.isArray(this._items)) {
                console.error('SelectionPanel: _items is not an array in dispatchSelectionChangeEvent:', this._items);
                return;
            }
            
            const selectedItems = this._items.filter(item => item && item.isSelected);
            
            console.log(`SelectionPanel (${this.title}): Dispatching selectionchange event with ${selectedItems.length} selected items:`, selectedItems);
            
            this.dispatchEvent(
                new CustomEvent('selectionchange', {
                    detail: {
                        selectedItems: selectedItems
                    }
                })
            );
        } catch (error) {
            console.error('SelectionPanel: Error in dispatchSelectionChangeEvent:', error);
        }
    }
    
    /**
     * @description Get a formatted count string
     * @returns {String} Count string (e.g., "Showing 5 of 10 items")
     */
    get countLabel() {
        if (this._enablePagination) {
            const startItem = (this.currentPage - 1) * this.pageSize + 1;
            const endItem = Math.min(this.currentPage * this.pageSize, this.filteredItems.length);
            return `Showing ${startItem}-${endItem} of ${this.totalCount} ${this.title.toLowerCase()}`;
        } else if (this.virtualScrollEnabled) {
            return `Showing ${this.displayedItems.length} of ${this.filteredItems.length} ${this.title.toLowerCase()}`;
        } else {
            return `Showing ${this.filteredItems.length} of ${this.totalCount} ${this.title.toLowerCase()}`;
        }
    }
    
    /**
     * @description Get a label for selected items
     * @returns {String} Selected items label (e.g., "1 item selected")
     */
    get selectedItemsLabel() {
        return `${this.selectedCount} ${this.selectedCount === 1 ? 'item' : 'items'} selected`;
    }
    
    /**
     * @description Check if any item is selected
     * @returns {Boolean} True if any item is selected
     */
    get hasSelectedItems() {
        return this.selectedCount > 0;
    }
    
    /**
     * @description Check if pagination controls should be shown
     */
    get showPaginationControls() {
        return this._enablePagination && this.totalPages > 1;
    }
    
    /**
     * @description Check if load more button should be shown
     */
    get showLoadMoreButton() {
        return !this._enablePagination && !this.virtualScrollEnabled && this.filteredItems.length < this.totalCount;
    }

    /**
     * @description Check if we're on the first page
     */
    get isFirstPage() {
        return this.currentPage <= 1;
    }

    /**
     * @description Check if we're on the last page
     */
    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }
    
    /**
     * @description Get CSS classes for the container
     */
    get containerClass() {
        let classes = 'item-list-container';
        if (this.virtualScrollEnabled) {
            classes += ' virtual-scroll-container';
        }
        if (this.isLoading) {
            classes += ' loading';
        }
        return classes;
    }
    
    /**
     * @description Get CSS classes for the item list
     */
    get itemListClass() {
        let classes = 'slds-has-dividers_bottom-space';
        if (this.virtualScrollEnabled) {
            classes += ' virtual-item-list';
        }
        return classes;
    }

    handleIncludeAllToggle(event) {
        this.includeAllChecked = event.target.checked;
        // Fire an event upward so parent component can react
        this.dispatchEvent(new CustomEvent('includeallchange', {
            detail: { includeAll: this.includeAllChecked }
        }));

        // When include-all is checked we clear any manual selections for clarity
        if (this.includeAllChecked) {
            // Deselect existing items
            this._items = this._items.map(itm => ({ ...itm, isSelected: false }));
            this.filteredItems = [...this._items];
            this.selectedCount = 0;
            this.isSelectAllChecked = false;
            this.dispatchSelectionChangeEvent();
        }
    }
}