import { LightningElement, api } from 'lwc';
import getAvailablePermissionSets from '@salesforce/apex/UserPermController.getAvailablePermissionSets';
import grantAccess from '@salesforce/apex/UserPermController.grantAccess';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class GrantAccessModal extends LightningElement {
    @api userId;
    permissionSets = [];
    selectedIds = [];
    isLoading = false;
    error = false;
    errorMessage = '';
    existingAssignedIds = [];

    connectedCallback() {
        this.loadPermissionSets();
    }

    loadPermissionSets() {
        this.isLoading = true;
        
        getAvailablePermissionSets({ userId: this.userId })
            .then(result => {
                // Deep clone to ensure we're not modifying references
                const processedResult = JSON.parse(JSON.stringify(result));
                
                // Force isAssigned to be a boolean
                if (processedResult && processedResult.length > 0) {
                    processedResult.forEach(ps => {
                        if ('isAssigned' in ps && typeof ps.isAssigned === 'string') {
                            ps.isAssigned = ps.isAssigned.toLowerCase() === 'true';
                        }
                    });
                }
                
                // Set the permission sets data
                this.permissionSets = processedResult;
                
                // Track already assigned permission sets
                this.existingAssignedIds = processedResult
                    .filter(ps => ps.isAssigned === true)
                    .map(ps => ps.id);
                    
                this.error = null;
            })
            .catch(error => {
                this.error = error;
                this.errorMessage = error.body ? error.body.message : 'Unknown error occurred while loading permission sets.';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleSelection(event) {
        if (event.detail && Array.isArray(event.detail)) {
            // If we get an array directly
            this.selectedIds = event.detail.map(row => row.id);
        } else if (event.detail && event.detail.selectedRows) {
            // If we get a detail object with selectedRows
            this.selectedIds = event.detail.selectedRows.map(row => row.id);
        } else if (event.detail) {
            // If we get something else
            this.selectedIds = Array.isArray(event.detail) ? event.detail : [event.detail];
        } else {
            this.selectedIds = [];
        }
    }

    handleGrantAccess() {
        if(this.selectedIds.length === 0) {
            this.showError('Please select at least one permission set');
            return;
        }

        this.isLoading = true;
        
        // Count new assignments (not already assigned)
        const newAssignments = this.selectedIds.filter(id => !this.existingAssignedIds.includes(id));
        const keptAssignments = this.selectedIds.filter(id => this.existingAssignedIds.includes(id));
        
        // Separate PS and Group IDs
        const psIds = this.selectedIds.filter(id => id.startsWith('0PS'));
        const groupIds = this.selectedIds.filter(id => id.startsWith('0PG'));

        // Get the names of the selected permission sets to pass back to the parent
        let selectedPermSetNames = this.permissionSets
            .filter(ps => this.selectedIds.includes(ps.id))
            .map(ps => ps.name);
        
        // Filter out any empty permission set names
        selectedPermSetNames = selectedPermSetNames.filter(name => name && name.trim().length > 0);

        grantAccess({
            userId: this.userId,
            permissionSetIds: psIds,
            groupIds: groupIds
        })
        .then(() => {
            // Create a more informative success message
            let message = '';
            if (newAssignments.length > 0) {
                message = `${newAssignments.length} new permission set${newAssignments.length !== 1 ? 's' : ''} assigned`;
                if (keptAssignments.length > 0) {
                    message += ` and ${keptAssignments.length} existing permission set${keptAssignments.length !== 1 ? 's' : ''} preserved`;
                }
            } else {
                message = `${keptAssignments.length} existing permission set${keptAssignments.length !== 1 ? 's' : ''} preserved`;
            }
            
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: message,
                variant: 'success'
            }));
            
            // Dispatch success event with the names of the assigned permission sets
            this.dispatchEvent(new CustomEvent('success', {
                detail: {
                    permissionSets: selectedPermSetNames
                }
            }));
            
            this.closeModal();
        })
        .catch(error => {
            this.showError(error.body?.message || error.message);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    parseError(error) {
        const defaultMsg = 'Failed to assign permissions. Check console for details.';
        if (typeof error === 'string') return error;
        return error.body?.message || error.message || defaultMsg;
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    showError(message) {
        if(message.includes('Duplicate PermissionSetAssignment')){
            message = 'Selected permissionSet already assigned to user..'
        }
        this.error = true;
        this.errorMessage = message;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
            mode: 'sticky'
        }));
    }
}