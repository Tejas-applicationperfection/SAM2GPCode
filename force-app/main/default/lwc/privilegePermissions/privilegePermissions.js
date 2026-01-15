import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkPaidFeatureAccess from '@salesforce/apex/PrivilegedPermissionsController.PaidFeatureAccess';
import getSystemPermissions from '@salesforce/apex/PrivilegedPermissionsController.getSystemPermissions';
import updatePrivilegedStatus from '@salesforce/apex/PrivilegedPermissionsController.updatePrivilegedStatus';
import exportPrivilegedPermissions from '@salesforce/apex/PrivilegedPermissionsController.exportPrivilegedPermissions';
import getStatistics from '@salesforce/apex/PrivilegedPermissionsController.getStatistics';
import checkUserAccess from '@salesforce/apex/PrivilegedPermissionsController.checkUserAccess';

export default class PrivilegePermissions extends LightningElement {
    // Feature Access Control
    @track hasAccess = false;
    @track isCheckingAccess = true;
    
    @track permissions = [];
    @track displayedPermissions = [];
    @track statistics = {
        totalPermissions: 0,
        privilegedCount: 0
    };
    @track searchTerm = '';
    @track currentPage = 1;
    @track pageSize = 25;
    @track totalRecords = 0;
    @track isLoading = false;
    @track selectedFilters = [];
    @track showToast = false;
    @track toastMessage = '';
    @track toastVariant = 'success';
    
    // Filter options
    filterOptions = [
        { label: 'Show Only Privileged', value: 'privilegedOnly' },
        { label: 'Show Only Non-Privileged', value: 'nonPrivilegedOnly' }
    ];
    
    connectedCallback() {
        this.checkFeatureAccess();
        this.checkAccess();
        this.loadStatistics();
        this.loadPermissions();
    }
    
    // Check feature access
    async checkFeatureAccess() {
        try {
            this.isCheckingAccess = true;
            const result = await checkPaidFeatureAccess();
            this.hasAccess = result;
        } catch (error) {
            console.error('Error checking feature access:', error);
            this.hasAccess = false;
        } finally {
            this.isCheckingAccess = false;
        }
    }
    
    // Check user access
    async checkAccess() {
        try {
            this.hasAccess = await checkUserAccess();
        } catch (error) {
            console.error('Error checking access:', error);
            this.hasAccess = false;
        }
    }
    
    // Load statistics
    async loadStatistics() {
        try {
            const stats = await getStatistics();
            this.statistics = stats;
            this.hasAccess = stats.hasAccess;
        } catch (error) {
            console.error('Error loading statistics:', error);
            this.showToastMessage('Error loading statistics', 'error');
        }
    }
    
    // Load permissions from Apex
    async loadPermissions() {
        if (!this.hasAccess) {
            return;
        }
        
        this.isLoading = true;
        try {
            const result = await getSystemPermissions({
                searchTerm: this.searchTerm,
                pageNumber: this.currentPage,
                pageSize: this.pageSize,
                filterOptions: this.selectedFilters
            });
            
            this.permissions = result.permissions || [];
            this.totalRecords = result.totalCount || 0;
            this.processPermissions();
        } catch (error) {
            console.error('Error loading permissions:', error);
            this.showToastMessage('Error loading permissions: ' + error.body?.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    // Process permissions for display
    processPermissions() {
        this.displayedPermissions = this.permissions.map(perm => {
            return {
                ...perm,
                badgeClass: perm.isPrivileged ? 'slds-theme_error' : 'slds-theme_success',
                isEditingDescription: false,
                originalDescription: perm.description
            };
        });
    }
    
    // Handle search
    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.currentPage = 1; // Reset to first page
        this.debounceLoadPermissions();
    }
    
    // Debounce for search
    debounceLoadPermissions() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        clearTimeout(this.searchTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.searchTimeout = setTimeout(() => {
            this.loadPermissions();
        }, 500);
    }
    
    // Handle filter change
    handleFilterChange(event) {
        this.selectedFilters = event.detail.value;
        this.currentPage = 1;
        this.loadPermissions();
    }
    
    // Handle toggle privileged status
    async handleTogglePrivileged(event) {
        const permissionApiName = event.target.dataset.permission;
        const isPrivileged = event.target.checked;
        const permissionLabel = event.target.dataset.label;
        const description = event.target.dataset.description;
        
        this.isLoading = true;
        try {
            const deploymentId = await updatePrivilegedStatus({
                permissionApiName: permissionApiName,
                isPrivileged: isPrivileged,
                permissionLabel: permissionLabel,
                description: description
            });
            
            // Update local data
            const permission = this.permissions.find(p => p.apiName === permissionApiName);
            if (permission) {
                permission.isPrivileged = isPrivileged;
            }
            
            this.processPermissions();
            this.loadStatistics();
            
            const message = isPrivileged 
                ? `${permissionLabel} marked as privileged` 
                : `${permissionLabel} unmarked as privileged`;
            this.showToastMessage(message, 'success');
            
            // Show deployment info
            if (deploymentId) {
                this.showToastMessage(`Metadata deployment initiated: ${deploymentId}`, 'info');
            }
            
        } catch (error) {
            console.error('Error updating permission:', error);
            this.showToastMessage('Error updating permission: ' + error.body?.message, 'error');
            // Revert checkbox
            event.target.checked = !isPrivileged;
        } finally {
            this.isLoading = false;
        }
    }
    
    // Handle refresh
    handleRefresh() {
        this.loadPermissions();
        this.loadStatistics();
        this.showToastMessage('Permissions refreshed', 'success');
    }
    
    // Handle export to CSV
    async handleExport() {
        this.isLoading = true;
        try {
            const csvData = await exportPrivilegedPermissions();
            
            // Check if we have data
            if (!csvData || csvData.trim().length === 0) {
                this.showToastMessage('No privileged permissions to export', 'warning');
                return;
            }
            
            // Create download link using data URL instead of Blob
            const link = document.createElement('a');
            link.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvData);
            link.target = '_blank';
            link.download = `privileged_permissions_${new Date().toISOString().split('T')[0]}.csv`;
            
            // Trigger download
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            this.showToastMessage('CSV exported successfully', 'success');
        } catch (error) {
            console.error('Error exporting CSV:', error);
            // Better error message handling
            let errorMessage = 'Unknown error occurred';
            if (error.body && error.body.message) {
                errorMessage = error.body.message;
            } else if (error.message) {
                errorMessage = error.message;
            } else if (typeof error === 'string') {
                errorMessage = error;
            }
            this.showToastMessage('Error exporting CSV: ' + errorMessage, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    // Handle edit description
    handleEditDescription(event) {
        const permissionApiName = event.target.dataset.permission;
        this.displayedPermissions = this.displayedPermissions.map(perm => {
            if (perm.apiName === permissionApiName) {
                return { ...perm, isEditingDescription: true, originalDescription: perm.description };
            }
            return perm;
        });
    }
    
    // Handle description change
    handleDescriptionChange(event) {
        const permissionApiName = event.target.dataset.permission;
        const newDescription = event.target.value;
        this.displayedPermissions = this.displayedPermissions.map(perm => {
            if (perm.apiName === permissionApiName) {
                return { ...perm, description: newDescription };
            }
            return perm;
        });
    }
    
    // Handle save description
    async handleSaveDescription(event) {
        const permissionApiName = event.target.dataset.permission;
        const permission = this.displayedPermissions.find(p => p.apiName === permissionApiName);
        
        if (!permission) return;
        
        this.isLoading = true;
        try {
            const deploymentId = await updatePrivilegedStatus({
                permissionApiName: permissionApiName,
                isPrivileged: permission.isPrivileged,
                permissionLabel: permission.label,
                description: permission.description
            });
            
            // Update local data
            this.displayedPermissions = this.displayedPermissions.map(perm => {
                if (perm.apiName === permissionApiName) {
                    return { 
                        ...perm, 
                        isEditingDescription: false,
                        originalDescription: perm.description
                    };
                }
                return perm;
            });
            
            // Update main permissions array
            const mainPerm = this.permissions.find(p => p.apiName === permissionApiName);
            if (mainPerm) {
                mainPerm.description = permission.description;
            }
            
            this.showToastMessage('Description saved successfully', 'success');
            
            if (deploymentId) {
                this.showToastMessage(`Metadata deployment initiated: ${deploymentId}`, 'info');
            }
            
        } catch (error) {
            console.error('Error saving description:', error);
            this.showToastMessage('Error saving description: ' + error.body?.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    // Handle cancel description edit
    handleCancelDescription(event) {
        const permissionApiName = event.target.dataset.permission;
        this.displayedPermissions = this.displayedPermissions.map(perm => {
            if (perm.apiName === permissionApiName) {
                return { 
                    ...perm, 
                    isEditingDescription: false,
                    description: perm.originalDescription
                };
            }
            return perm;
        });
    }
    
    // Handle refresh
    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.loadPermissions();
        }
    }
    
    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.loadPermissions();
        }
    }
    
    // Toast message helper
    showToastMessage(message, variant) {
        const event = new ShowToastEvent({
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
    
    // Computed properties
    get hasPermissions() {
        return this.displayedPermissions && this.displayedPermissions.length > 0;
    }
    
    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize);
    }
    
    get startRecord() {
        return this.totalRecords === 0 ? 0 : (this.currentPage - 1) * this.pageSize + 1;
    }
    
    get endRecord() {
        const end = this.currentPage * this.pageSize;
        return end > this.totalRecords ? this.totalRecords : end;
    }
    
    get isFirstPage() {
        return this.currentPage === 1;
    }
    
    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }
    
    get toastClass() {
        const baseClass = 'slds-notify slds-notify_toast';
        const variantClass = this.toastVariant === 'success' ? 'slds-theme_success' : 
                             this.toastVariant === 'error' ? 'slds-theme_error' : 
                             'slds-theme_info';
        return `${baseClass} ${variantClass}`;
    }
}