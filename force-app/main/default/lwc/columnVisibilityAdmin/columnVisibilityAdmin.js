import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProfiles from '@salesforce/apex/ColumnVisibilityController.getProfiles';
import getUsers from '@salesforce/apex/ColumnVisibilityController.getUsers';
import getPermissionSets from '@salesforce/apex/ColumnVisibilityController.getPermissionSets';
import saveColumnConfiguration from '@salesforce/apex/ColumnVisibilityController.saveColumnConfiguration';
import getExistingConfiguration from '@salesforce/apex/ColumnVisibilityController.getExistingConfiguration';

export default class ColumnVisibilityAdmin extends LightningElement {
    @track selectedConfigurationType = 'Profile';
    @track selectedTargetId = '';
    @track selectedTargetName = '';
    @track availableTargets = [];
    @track isLoading = false;
    @track isSaving = false;

    // Column visibility flags
    @track showFieldName = true;
    @track showFieldType = true;
    @track showDescription = true;
    @track showHelpText = true;
    @track showSensitivity = true;
    @track showFieldUsage = true;
    @track showDataOwner = true;
    @track showComplianceCategorizaton = true;

    // Configuration type options
    get configurationTypeOptions() {
        return [
            { label: 'By Profile', value: 'Profile' },
            { label: 'By User', value: 'User' },
            { label: 'By Permission Set', value: 'PermissionSet' }
        ];
    }

    // Available columns for configuration
    get availableColumns() {
        return [
            { label: 'Field Name', value: 'fieldName', checked: this.showFieldName },
            { label: 'Field Type', value: 'fieldType', checked: this.showFieldType },
            { label: 'Description', value: 'description', checked: this.showDescription },
            { label: 'Help Text', value: 'helpText', checked: this.showHelpText },
            { label: 'Sensitivity', value: 'sensitivity', checked: this.showSensitivity },
            { label: 'Field Usage', value: 'fieldUsage', checked: this.showFieldUsage },
            { label: 'Data Owner', value: 'dataOwner', checked: this.showDataOwner },
            { label: 'Compliance Categorization', value: 'complianceCategorizaton', checked: this.showComplianceCategorizaton }
        ];
    }

    // Handle configuration type change
    async handleConfigurationTypeChange(event) {
        this.selectedConfigurationType = event.detail.value;
        this.selectedTargetId = '';
        this.selectedTargetName = '';
        this.resetColumnVisibility();
        await this.loadTargets();
    }

    // Handle target selection change
    async handleTargetChange(event) {
        this.selectedTargetId = event.detail.value;
        this.selectedTargetName = event.target.options.find(opt => opt.value === this.selectedTargetId)?.label || '';
        
        if (this.selectedTargetId) {
            await this.loadExistingConfiguration();
        }
    }

    // Handle column visibility change
    handleColumnVisibilityChange(event) {
        const columnName = event.target.dataset.column;
        const isChecked = event.target.checked;
        
        switch (columnName) {
            case 'fieldName':
                this.showFieldName = isChecked;
                break;
            case 'fieldType':
                this.showFieldType = isChecked;
                break;
            case 'description':
                this.showDescription = isChecked;
                break;
            case 'helpText':
                this.showHelpText = isChecked;
                break;
            case 'sensitivity':
                this.showSensitivity = isChecked;
                break;
            case 'fieldUsage':
                this.showFieldUsage = isChecked;
                break;
            case 'dataOwner':
                this.showDataOwner = isChecked;
                break;
            case 'complianceCategorizaton':
                this.showComplianceCategorizaton = isChecked;
                break;
        }
    }

    // Load targets based on configuration type
    async loadTargets() {
        this.isLoading = true;
        try {
            let targets = [];
            
            if (this.selectedConfigurationType === 'Profile') {
                targets = await getProfiles();
            } else if (this.selectedConfigurationType === 'User') {
                targets = await getUsers();
            } else if (this.selectedConfigurationType === 'PermissionSet') {
                targets = await getPermissionSets();
            }
            
            this.availableTargets = targets.map(target => ({
                label: target.Name,
                value: target.Id
            }));
            
        } catch (error) {
            this.showErrorToast('Error Loading Targets', error.body.message);
        } finally {
            this.isLoading = false;
        }
    }

    // Load existing configuration for selected target
    async loadExistingConfiguration() {
        try {
            const config = await getExistingConfiguration({
                targetType: this.selectedConfigurationType,
                targetId: this.selectedTargetId
            });
            
            if (config) {
                this.showFieldName = config.showFieldName;
                this.showFieldType = config.showFieldType;
                this.showDescription = config.showDescription;
                this.showHelpText = config.showHelpText;
                this.showSensitivity = config.showSensitivity;
                this.showFieldUsage = config.showFieldUsage;
                this.showDataOwner = config.showDataOwner;
                this.showComplianceCategorizaton = config.showComplianceCategorizaton;
            } else {
                this.resetColumnVisibility();
            }
            
        } catch (error) {
            this.showErrorToast('Error Loading Configuration', error.body.message);
        }
    }

    // Reset column visibility to default (all visible)
    resetColumnVisibility() {
        this.showFieldName = true;
        this.showFieldType = true;
        this.showDescription = true;
        this.showHelpText = true;
        this.showSensitivity = true;
        this.showFieldUsage = true;
        this.showDataOwner = true;
        this.showComplianceCategorizaton = true;
    }

    // Save configuration
    async handleSaveConfiguration() {
        if (!this.selectedTargetId) {
            this.showErrorToast('Error', 'Please select a target first.');
            return;
        }

        this.isSaving = true;
        try {
            const result = await saveColumnConfiguration({
                targetType: this.selectedConfigurationType,
                targetId: this.selectedTargetId,
                targetName: this.selectedTargetName,
                showFieldName: this.showFieldName,
                showFieldType: this.showFieldType,
                showDescription: this.showDescription,
                showHelpText: this.showHelpText,
                showSensitivity: this.showSensitivity,
                showFieldUsage: this.showFieldUsage,
                showDataOwner: this.showDataOwner,
                showComplianceCategorizaton: this.showComplianceCategorizaton
            });
            this.showSuccessToast('Success', 'Column configuration saved successfully!');
            
        } catch (error) {
            this.showErrorToast('Error Saving Configuration', error.body.message);
        } finally {
            this.isSaving = false;
        }
    }

    // Cancel configuration
    handleCancel() {
        this.resetColumnVisibility();
        this.selectedTargetId = '';
        this.selectedTargetName = '';
    }

    // Initialize component
    connectedCallback() {
        this.loadTargets();
    }

    // Check if save button should be enabled
    get isSaveDisabled() {
        return !this.selectedTargetId || this.isSaving;
    }

    // Check if any configuration is selected
    get hasSelectedTarget() {
        return !!this.selectedTargetId;
    }

    // Show success toast
    showSuccessToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }

    // Show error toast
    showErrorToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error'
        });
        this.dispatchEvent(evt);
    }
}