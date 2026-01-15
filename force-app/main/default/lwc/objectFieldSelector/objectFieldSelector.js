import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getObjectTypes from '@salesforce/apex/ObjectFieldSelectorController.getObjectTypes';
import getObjectsByType from '@salesforce/apex/ObjectFieldSelectorController.getObjectsByType';
import getObjectFields from '@salesforce/apex/ObjectFieldSelectorController.getObjectFields';
import getPaidFeatureAccess from '@salesforce/apex/ObjectFieldSelectorController.getPaidFeatureAccess';
import getCurrentUserConfiguration from '@salesforce/apex/ColumnVisibilityController.getCurrentUserConfiguration';
import getProfiles from '@salesforce/apex/ColumnVisibilityController.getProfiles';
import getUsers from '@salesforce/apex/ColumnVisibilityController.getUsers';
import getPermissionSets from '@salesforce/apex/ColumnVisibilityController.getPermissionSets';
import saveColumnConfiguration from '@salesforce/apex/ColumnVisibilityController.saveColumnConfiguration';
import getExistingConfiguration from '@salesforce/apex/ColumnVisibilityController.getExistingConfiguration';
import isSystemAdministrator from '@salesforce/apex/ColumnVisibilityController.isSystemAdministrator';

export default class ObjectFieldSelector extends LightningElement {
    @track hasAccess = true; // default to true to preserve current behavior
    @track selectedObjectType = '';
    @track selectedObject = '';
    @track objectTypes = [];
    @track organizationObjects = [];
    @track managedObjects = [];
    @track availableObjects = [];
    @track objectFields = [];
    @track isLoading = false;
    @track isLoadingObjects = false;
    @track isLoadingFields = false;

    // Admin Panel Properties
    @track isSystemAdmin = false;
    @track selectedConfigurationType = 'Profile';
    @track selectedConfigetId = '';
    @track selectedTargetName = '';
    @track availableTargets = [];
    @track isLoadingTargets = false;
    @track isSaving = false;

    // Column visibility configuration for display
    @track columnConfig = {
        showFieldName: true,
        showFieldType: true,
        showDescription: true,
        showHelpText: true,
        showSensitivity: true,
        showFieldUsage: true,
        showDataOwner: true,
        showComplianceCategorizaton: true
    };

    // Admin configuration for editing
    @track adminConfig = {
        showFieldName: true,
        showFieldType: true,
        showDescription: true,
        showHelpText: true,
        showSensitivity: true,
        showFieldUsage: true,
        showDataOwner: true,
        showComplianceCategorizaton: true
    };

    // Wire the object types on component initialization
    @wire(getObjectTypes)
    wiredObjectTypes({ error, data }) {
        if (data) {
            this.objectTypes = data;
        } else if (error) {
            this.showErrorToast('Error Loading Object Types', error.body.message);
        }
    }

    // Wire feature flag access
    @wire(getPaidFeatureAccess)
    wiredPaidFeatureAccess({ error, data }) {
        if (data !== undefined) {
            this.hasAccess = data;
        } else if (error) {
            // Preserve current behavior if check fails
            this.hasAccess = true;
        }
    }

    // Wire the current user's column configuration
    @wire(getCurrentUserConfiguration)
    wiredUserConfiguration({ error, data }) {
        if (data) {
            this.columnConfig = {
                showFieldName: data.showFieldName,
                showFieldType: data.showFieldType,
                showDescription: data.showDescription,
                showHelpText: data.showHelpText,
                showSensitivity: data.showSensitivity,
                showFieldUsage: data.showFieldUsage,
                showDataOwner: data.showDataOwner,
                showComplianceCategorizaton: data.showComplianceCategorizaton
            };
        } else if (error) {
            console.error('Error loading column configuration:', error);
            // Use default configuration (all columns visible)
        }
    }

    // Wire if the current user is a system administrator
    @wire(isSystemAdministrator)
    wiredIsSystemAdmin({ error, data }) {
        if (data) {
            this.isSystemAdmin = data;
        } else if (error) {
            console.error('Error checking system admin status:', error);
        }
    }

    // Initialize admin targets when component loads
    connectedCallback() {
        this.loadAdminTargets();
    }

    // Admin Panel Configuration Type Options
    get configurationTypeOptions() {
        return [
            { label: 'By Profile', value: 'Profile' },
            { label: 'By User', value: 'User' },
            { label: 'By Permission Set', value: 'PermissionSet' }
        ];
    }

    // Handle admin configuration type change
    async handleConfigurationTypeChange(event) {
        this.selectedConfigurationType = event.detail.value;
        this.selectedConfigetId = '';
        this.selectedTargetName = '';
        this.resetAdminConfiguration();
        await this.loadAdminTargets();
    }

    // Handle admin target selection change
    async handleTargetChange(event) {
        this.selectedConfigetId = event.detail.value;
        this.selectedTargetName = event.target.options.find(opt => opt.value === this.selectedConfigetId)?.label || '';
        
        if (this.selectedConfigetId) {
            await this.loadExistingAdminConfiguration();
        }
    }

    // Handle admin column visibility change
    handleAdminColumnChange(event) {
        const columnName = event.target.name;
        const isChecked = event.target.checked;
        
        this.adminConfig = {
            ...this.adminConfig,
            [columnName]: isChecked
        };
    }

    // Load admin targets based on configuration type
    async loadAdminTargets() {
        this.isLoadingTargets = true;
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
                label: target.Name || target.Label,
                value: target.Id
            }));
            
        } catch (error) {
            this.showErrorToast('Error Loading Targets', error.body.message);
        } finally {
            this.isLoadingTargets = false;
        }
    }

    // Load existing admin configuration for selected target
    async loadExistingAdminConfiguration() {
        try {
            const config = await getExistingConfiguration({
                targetType: this.selectedConfigurationType,
                targetId: this.selectedConfigetId
            });
            
            if (config) {
                this.adminConfig = {
                    showFieldName: config.showFieldName,
                    showFieldType: config.showFieldType,
                    showDescription: config.showDescription,
                    showHelpText: config.showHelpText,
                    showSensitivity: config.showSensitivity,
                    showFieldUsage: config.showFieldUsage,
                    showDataOwner: config.showDataOwner,
                    showComplianceCategorizaton: config.showComplianceCategorizaton
                };
            } else {
                this.resetAdminConfiguration();
            }
            
        } catch (error) {
            this.showErrorToast('Error Loading Configuration', error.body.message);
        }
    }

    // Reset admin configuration to default (all visible)
    resetAdminConfiguration() {
        this.adminConfig = {
            showFieldName: true,
            showFieldType: true,
            showDescription: true,
            showHelpText: true,
            showSensitivity: true,
            showFieldUsage: true,
            showDataOwner: true,
            showComplianceCategorizaton: true
        };
    }

    // Handle save configuration
    async handleSaveConfiguration() {
        if (!this.selectedConfigetId) {
            this.showErrorToast('Error', 'Please select a target first.');
            return;
        }

        this.isSaving = true;
        try {
            await saveColumnConfiguration({
                targetType: this.selectedConfigurationType,
                targetId: this.selectedConfigetId,
                targetName: this.selectedTargetName,
                showFieldName: this.adminConfig.showFieldName,
                showFieldType: this.adminConfig.showFieldType,
                showDescription: this.adminConfig.showDescription,
                showHelpText: this.adminConfig.showHelpText,
                showSensitivity: this.adminConfig.showSensitivity,
                showFieldUsage: this.adminConfig.showFieldUsage,
                showDataOwner: this.adminConfig.showDataOwner,
                showComplianceCategorizaton: this.adminConfig.showComplianceCategorizaton
            });
            this.showSuccessToast('Success', 'Column configuration saved successfully!');
            
        } catch (error) {
            this.showErrorToast('Error Saving Configuration', error.body.message);
        } finally {
            this.isSaving = false;
        }
    }

    // Handle reset configuration
    handleResetConfiguration() {
        this.resetAdminConfiguration();
        this.showSuccessToast('Reset', 'Configuration reset to default (all columns visible).');
    }

    // Check if admin target is selected
    get hasSelectedTarget() {
        return !!this.selectedConfigetId;
    }

    // Handle object type selection change
    handleObjectTypeChange(event) {
        this.selectedObjectType = event.detail.value;
        this.selectedObject = '';
        this.objectFields = [];
        this.loadObjectsByType();
    }

    // Handle object selection change
    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.loadObjectFields();
    }

    // Load objects based on selected object type
    async loadObjectsByType() {
        if (!this.selectedObjectType) {
            this.availableObjects = [];
            return;
        }

        this.isLoadingObjects = true;
        try {
            const objects = await getObjectsByType({ objectType: this.selectedObjectType });
            
            if (this.selectedObjectType === 'Organization') {
                this.organizationObjects = objects;
                this.availableObjects = objects;
            } else if (this.selectedObjectType === 'Managed') {
                this.managedObjects = objects;
                this.availableObjects = objects;
            }
        } catch (error) {
            this.showErrorToast('Error Loading Objects', error.body.message);
        } finally {
            this.isLoadingObjects = false;
        }
    }

    // Load fields for the selected object
    async loadObjectFields() {
        if (!this.selectedObject) {
            this.objectFields = [];
            return;
        }

        this.isLoadingFields = true;
        try {
            const fields = await getObjectFields({ objectName: this.selectedObject });
            this.objectFields = fields.map(field => ({
                name: field.name,
                label: field.label,
                type: field.type,
                inlineHelpText: field.inlineHelpText || '',
                description: field.description || '',
                // Show actual values or "None" if empty/null
                dataOwner: field.dataOwner || 'None',
                // Show actual BusinessStatus value or "None" if empty
                dataSensitivityLevel: field.dataSensitivityLevel || '',
                dataSensitivityLevelDisplay: field.dataSensitivityLevel && field.dataSensitivityLevel.trim() !== '' ? field.dataSensitivityLevel : 'None',
                // Show actual BusinessStatus value (like "DeprecateCandidate") or "None" if empty
                fieldUsage: field.isActive || '',
                fieldUsageDisplay: field.isActive && field.isActive.trim() !== '' ? field.isActive : 'None',
                complianceCategorization: field.complianceCategorization || [],
                sensitivityClass: this.getSensitivityClass(field.dataSensitivityLevel),
                usageClass: this.getUsageClass(field.isActive),
                complianceDisplay: this.formatComplianceCategorization(field.complianceCategorization)
            }));
        } catch (error) {
            this.showErrorToast('Error Loading Fields', error.body.message);
        } finally {
            this.isLoadingFields = false;
        }
    }

    // Get CSS class for sensitivity level
    getSensitivityClass(sensitivityLevel) {
        if (!sensitivityLevel || sensitivityLevel === 'None') {
            return 'slds-text-color_weak';
        }
        
        switch (sensitivityLevel) {
            case 'Confidential':
                return 'slds-text-color_error';
            case 'Restricted':
                return 'slds-text-color_warning';
            case 'Internal':
                return 'slds-text-color_success';
            case 'Public':
                return 'slds-text-color_weak';
            default:
                return 'slds-text-color_default';
        }
    }

    // Get CSS class for field usage
    getUsageClass(fieldUsage) {
        if (!fieldUsage || fieldUsage === 'None') {
            return 'slds-text-color_weak';
        }
        
        switch (fieldUsage) {
            case 'Active':
                return 'slds-text-color_success';
            case 'DeprecateCandidate':
                return 'slds-text-color_warning';
            case 'Deprecated':
                return 'slds-text-color_error';
            default:
                return 'slds-text-color_default';
        }
    }

    // Format compliance categorization for display
    formatComplianceCategorization(complianceGroups) {
        if (!complianceGroups || complianceGroups.length === 0) {
            return 'None';
        }
        return complianceGroups.join('; ');
    }

    // Get object type options for the combobox
    get objectTypeOptions() {
        return [
            { label: 'Organization Objects', value: 'Organization' },
            { label: 'Managed Package Objects', value: 'Managed' }
        ];
    }

    // Get object options for the combobox
    get objectOptions() {
        return this.availableObjects.map(obj => ({
            label: obj.label || obj.name,
            value: obj.name
        }));
    }

    // Check if object type is selected
    get hasSelectedObjectType() {
        return !!this.selectedObjectType;
    }

    // Check if object is selected
    get hasSelectedObject() {
        return !!this.selectedObject;
    }

    // Check if fields are loaded
    get hasFields() {
        return this.objectFields.length > 0;
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

    // Show success toast
    showSuccessToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }
}