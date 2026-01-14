import { LightningElement, api, track } from 'lwc';

export default class PermissionSetTable extends LightningElement {
    @api recordId;
    @track records = [];
    @track selectedRows = [];
    @track initialSelection = [];
    
    // This is the API for external components to access
    @api 
    get selectedIds() {
        return this.selectedRows;
    }

    @api
    get tableData() {
        return this.records;
    }
    
    set tableData(value) {
        if (value) {
            // Process data and identify assigned items
            this.processData(value);
        }
    }

    /**
     * Process the incoming data and identify pre-selected items
     */
    processData(value) {
        // Deep clone the data to avoid reference issues
        this.records = JSON.parse(JSON.stringify(value));
            
        // Extract ids of records with isAssigned=true
        const assignedRecords = this.records.filter(record => record.isAssigned === true);
        const preSelectedIds = assignedRecords.map(record => record.id);
        
        // Store the initial selection for later use
        this.initialSelection = [...preSelectedIds];
            
        // Set selected rows
        if (preSelectedIds.length > 0) {
            this.selectedRows = [...preSelectedIds];
        }
        
        // Apply selection to ensure component shows pre-selected items
        this.applySelection();
    }

    get columns() {
        return [
            { label: 'Name', fieldName: 'label', type: 'text' },
            { label: 'Description', fieldName: 'description', type: 'text', wrapText: true },
            { label: 'Type', fieldName: 'type', type: 'text' }
        ];
    }

    connectedCallback() {
        // Component initialization logic
    }

    renderedCallback() {
        // Apply selection after render
        this.applySelection();
    }
    
    /**
     * Apply selection to ensure pre-assigned permission sets are checked
     */
    applySelection() {
        if (this.selectedRows.length > 0) {
            // Use Promise.resolve to ensure DOM is updated before applying selection
            Promise.resolve().then(() => {
                const datatable = this.template.querySelector('lightning-datatable');
                
                if (datatable && datatable.data && datatable.data.length > 0) {
                    try {
                        // Apply selection directly to the datatable
                        datatable.selectedRows = [...this.selectedRows];
                    } catch (error) {
                        console.error('Error applying selection:', error);
                    }
                }
            });
        }
    }

    handleRowSelection(event) {
        if (!event.detail) {
            return;
        }
        
        const selectedRows = event.detail.selectedRows || [];
        const selectedIds = selectedRows.map(row => row.id);
        this.selectedRows = [...selectedIds];
        
        // Notify parent component
        this.dispatchEvent(new CustomEvent('selection', {
            detail: selectedRows
        }));
    }
}