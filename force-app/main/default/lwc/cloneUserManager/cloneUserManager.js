import { LightningElement, track, wire } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import customRiskBadge from 'c/customRiskBadge';

import analyzeUserRisk from '@salesforce/apex/AccessRiskAnalyzer.analyzeUserRisk';
import checkPaidFeatureAccess from '@salesforce/apex/UserPermController.PaidFeatureAccess';
import getAllObjects from '@salesforce/apex/SchemaBuilderController.getAllObjects';
import getActiveUsers from '@salesforce/apex/UserPermController.getActiveUsers';
import getActiveUsersByLicense from '@salesforce/apex/UserPermController.getActiveUsersByLicense';
import getAvailableLicenseTypes from '@salesforce/apex/UserPermController.getAvailableLicenseTypes';
import getFieldPermissions from '@salesforce/apex/UserPermController.getFieldPermissions';
import getLoginHistory from '@salesforce/apex/UserPermController.getLoginHistory';
import getObjectPermissions from '@salesforce/apex/UserPermController.getObjectPermissions';
import getSetupAuditTrail from '@salesforce/apex/UserPermController.getSetupAuditTrail';
import getObjectPermissionSources from '@salesforce/apex/UserPermController.getObjectPermissionSources';
import getObjectPermissionsForUser from '@salesforce/apex/UserPermController.getObjectPermissionsForUser';
import getRecordTypeAssignments from '@salesforce/apex/UserPermController.getRecordTypeAssignments';
import getRoleHierarchy from '@salesforce/apex/UserPermController.getRoleHierarchy';
import getSchemaDataWithMultipleSecondaryObjects from '@salesforce/apex/SchemaBuilderController.getSchemaDataWithMultipleSecondaryObjects';
import getSchemaDataWithPermissions from '@salesforce/apex/SchemaBuilderController.getSchemaDataWithPermissions';
// Removed unused import getSharingRulesAccess
import getSystemLevelPermissions from '@salesforce/apex/UserPermController.getSystemLevelPermissions';
import getUserDetails from '@salesforce/apex/UserPermController.getUserDetails';
import resetSystemPermissions from '@salesforce/apex/RemediationService.resetSystemPermissions';
import revokeSelectedPermissionSets from '@salesforce/apex/RemediationService.revokeSelectedPermissionSets';
import undoResetSystemPermissions from '@salesforce/apex/RemediationService.undoResetSystemPermissions';
import undoRevokePermissionSets from '@salesforce/apex/RemediationService.undoRevokePermissionSets';
import updateObjectPermissions from '@salesforce/apex/UserPermController.updateObjectPermissions';
import getRiskyUsers from '@salesforce/apex/UserPermController.getRiskyUsers';

import ChartJS from '@salesforce/resourceUrl/ChartJS';
import CustomFont from '@salesforce/resourceUrl/CustomFont';
import getCytoscape from '@salesforce/resourceUrl/cytoscape';
import getSharingRulesData from '@salesforce/apex/UserPermController.getSharingRulesData';
import refreshOWDSharingData from '@salesforce/apex/UserPermController.refreshOWDSharingData';

// Add these cleaning functions at the top

const cleanFieldName = (field) => {
    ////console.log('Original field:', field);
    const parts = field.split('.');
    const cleaned = parts.length > 1 ? parts.pop() : field;
    ////console.log('Cleaned field:', cleaned);
    return cleaned;
};

const cleanObjectName = (object) => {
    return object.replace(/SA_Audit__/g, '').replace(/__c/g, '');
};

export default class CloneUserManager extends NavigationMixin(LightningElement) {
    // Feature Access Control
    @track hasAccess = true;
    @track isCheckingAccess = true;
    
    // User Details Section
    @track userDetails = {
        userName: '',
        userEmail: '',
        profileName: '',
        isActive: false,
        permissionSets: [],
        highRiskCount: 0,
        riskScore: 0,
        riskLevel: 'Low',
        criticalFindings: []
    };

    // Instructions Bar Properties
    @track isInstructionsExpanded = false;
    get instructionsIcon() {
        return this.isInstructionsExpanded ? 'utility:chevronup' : 'utility:chevrondown';
    }

    // User Selection
    @track userOptions = [];
    @track selectedUserId;
    
    // License Type Selection
    @track licenseOptions = [];
    @track selectedLicenseType = '';
    
    chartJsInitialized = false;
    riskChart;

    // Risky Users Properties
    @track showRiskyUsersView = false;
    @track selectedRiskyUser = null;
    @track isLoadingRiskyUsers = false;
    @track riskyUsersError = null;
    @track riskyUsersData = [];
    @track currentRiskyUsersPage = 1;
    @track totalRiskyUsers = 0;
    @track riskyUsersPageSize = 20;
    
    // Risk Level Counters
    @track criticalUsersCount = 0;
    @track highRiskUsersCount = 0;
    @track mediumRiskUsersCount = 0;
    @track lowRiskUsersCount = 0;
    
    // Risky Users Table Columns
    riskyUsersColumns = [
        {
            label: 'User Name',
            fieldName: 'userName',
            type: 'text',
            sortable: true,
            cellAttributes: { class: 'slds-text-title_bold' }
        },
        {
            label: 'Email',
            fieldName: 'userEmail',
            type: 'email',
            sortable: true
        },
        {
            label: 'Profile',
            fieldName: 'profileName',
            type: 'text',
            sortable: true
        },
        {
            label: 'Risk Score',
            fieldName: 'riskScore',
            type: 'number',
            sortable: true,
            cellAttributes: {
                alignment: 'center',
                class: 'risk-score-cell'
            }
        },
        {
            label: 'Risk Level',
            fieldName: 'riskLevel',
            type: 'customRiskBadge',
            sortable: true,
            typeAttributes: {
                riskLevel: { fieldName: 'riskLevel' },
                riskBadgeClass: { fieldName: 'riskBadgeClass' }
            }
        },
        {
            label: 'Critical Findings',
            fieldName: 'highRiskCount',
            type: 'number',
            sortable: true,
            cellAttributes: { alignment: 'center' }
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Analyze Risk', name: 'analyze_risk' }
                ]
            }
        }
    ];

    // Component Initialization
    connectedCallback() {
        // Check feature access first
        this.checkFeatureAccess();
        
        // Register custom data types for lightning-datatable
        this.customTypes = {
            customRiskBadge: {
                template: customRiskBadge,
                standardCellLayout: true,
                typeAttributes: ['riskLevel', 'riskBadgeClass']
            }
        };
        
        // Check if the instructions should be expanded based on localStorage
        const savedInstructionsState = localStorage.getItem('uam_instructions_expanded');
        this.isInstructionsExpanded = savedInstructionsState === 'true';
        
        loadStyle(this, CustomFont)
        .then(() => {
           // //console.log('Custom font loaded successfully');
        })
        .catch(() => {
           // //console.error('Error loading custom font');
        });
        
        this.loadLicenseTypes();
        this.loadActiveUsers();
        
        try {
            // Load both libraries in parallel
            Promise.all([
                this.loadCytoscapeLibrary(),
                this.loadChartJsLibrary()
            ]).then(() => {
                this.populateSchemaObjectOptions();
            }).catch(() => {
               // //console.error('Error loading libraries');
            });
        } catch (e) {
           // //console.error('Error in connectedCallback:', e);
        }
    }
    disconnectedCallback() {
        try {
            // Clean up event listeners
            if (this.handleKeyDown) {
                window.removeEventListener('keydown', this.handleKeyDown);
            }
            
            // Clean up Cytoscape instance
            if (this.cyInstance) {
                try {
                    // Remove all event handlers
                    this.cyInstance.removeAllListeners();
                    // Destroy the instance
                    this.cyInstance.destroy();
                    this.cyInstance = null;
                } catch (e) {
                   // //console.error('Error cleaning up Cytoscape instance:', e);
                }
            }
            
            // Clean up ResizeObserver polyfill if we created it
            if (window.ResizeObserver && window.ResizeObserver.prototype.disconnect) {
                try {
                    // Clean up any ResizeObserver instances
                    if (this.resizeObserver) {
                        this.resizeObserver.disconnect();
                        this.resizeObserver = null;
                    }
                } catch (e) {
                   // //console.error('Error cleaning up ResizeObserver:', e);
                }
            }
            
            // Clear any references to DOM elements
            this.cytoscapeLib = null;
            
            // Clear any timeouts
            if (this.objectSearchTimeout) {
                clearTimeout(this.objectSearchTimeout);
            }
            if (this.schemaChangeTimeout) {
                clearTimeout(this.schemaChangeTimeout);
            }
            if (this.nodeClickTimeout) {
                clearTimeout(this.nodeClickTimeout);
            }
        } catch (error) {
           // //console.error('Error in disconnectedCallback:', error);
        }
    }

    // Feature Access Check
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

    resetAllData() {
        this.userDetails = {
            userName: '',
            userEmail: '',
            profileName: '',
            isActive: false,
            permissionSets: [],
            highRiskCount: 0,
            riskScore: 0,
            riskLevel: 'Low',
            criticalFindings: []
        };
        
        // Clear permission set tracking when switching users
        this.revokedPermissionSets = new Set();
        this.grantedPermissionSets = new Set();
        ////console.log('Cleared permission sets tracking (both revoked and granted)');
        
        this.objectPermissions = [];
        this.fieldPermissions = [];
        this.systemPermissions = [];
        this.recordTypePermissions = [];
        this.sharingRules = [];
        this.roleHierarchy = [];
        
        // Reset pagination
        this.currentObjectPage = 1;
        this.currentFieldPage = 1;
        
        // Clear any error states
        this.error = undefined;
    }


    // Load license types for combobox
    async loadLicenseTypes() {
        try {
            const licenses = await getAvailableLicenseTypes();
            this.licenseOptions = licenses.map(license => ({
                label: license.label,
                value: license.value
            }));
        } catch(error) {
            this.showErrorToast('License Load Error', error.body?.message || error.message);
        }
    }

    // Load active users for combobox (filtered by license type)
    async loadActiveUsers() {
        try {
            const users = await getActiveUsersByLicense({ licenseType: this.selectedLicenseType });
            this.userOptions = users.map(user => ({
                label: user.Name,
                value: user.Id
            }));
            
            // Clear selected user if it's no longer in the filtered list
            if (this.selectedUserId && !this.userOptions.find(user => user.value === this.selectedUserId)) {
                this.selectedUserId = '';
                this.resetAllData();
            }
        } catch(error) {
            this.showErrorToast('User Load Error', error.body?.message || error.message);
        }
    }

    // Handle license type change
    async handleLicenseTypeChange(event) {
        try {
            this.selectedLicenseType = event.detail.value;
            this.selectedUserId = ''; // Clear selected user when license type changes
            this.resetAllData(); // Clear all data when license type changes
            await this.loadActiveUsers(); // Reload users based on new license type
        } catch(error) {
            this.showErrorToast('License Filter Error', error.body?.message || error.message);
        }
    }

    // Main user change handler
    async handleUserChange(event) {
        this.currentObjectPage = 1;
        this.currentFieldPage = 1;
        try {
            this.selectedUserId = event.detail.value;
            this.isInitialLoading = true;
            
            // Clear previous data immediately
            this.resetAllData();
            
            // Sequential loading for dependent data
            await this.loadUserDetails();
            
            // Parallel loading for independent data
            await Promise.all([
                this.loadRiskAnalysis(),
                this.loadObjectPermissions(),
                this.loadFieldPermissions(),
                this.loadSystemPermissions(),
                this.loadUserPermissions()
            ]);
            
        } catch(error) {
            this.showErrorToast('Load Failed', 
                error.body?.message ||  // Use optional chaining
                error.message || 
                'Failed to load user data'
            );
            this.resetAllData();
        } finally {
            this.isInitialLoading = false;
        }
    }

    // User Details Implementation
    async loadUserDetails() {
        try {
           // //console.log('Loading user details for:', this.selectedUserId);
            const data = await getUserDetails({ userId: this.selectedUserId });
           // //console.log('Raw user details response:', JSON.stringify(data));
            
            // Get permission sets from server response and filter out any empty or undefined values
            let permissionSets = [...(data.permissionSets || [])].filter(ps => ps && ps.trim().length > 0);
           // //console.log('Permission sets after filtering empty values:', permissionSets);
            
            // Filter out any permission sets that we've tracked as revoked
            if (this.revokedPermissionSets && this.revokedPermissionSets.size > 0) {
               // //console.log('Filtering out revoked permission sets:', Array.from(this.revokedPermissionSets));
                permissionSets = permissionSets.filter(ps => !this.revokedPermissionSets.has(ps));
               // //console.log('Permission sets after filtering revoked ones:', permissionSets);
            }
            
            // Add any tracked newly granted permission sets that aren't already in the list
            if (this.grantedPermissionSets && this.grantedPermissionSets.size > 0) {
               // //console.log('Adding tracked granted permission sets:', Array.from(this.grantedPermissionSets));
                
                // Use a Set to ensure no duplicates
                const permSetSet = new Set(permissionSets);
                this.grantedPermissionSets.forEach(ps => {
                    // Make sure we don't add empty permission sets
                    if (ps && ps.trim().length > 0 && !permSetSet.has(ps)) {
                        permSetSet.add(ps);
                        permissionSets.push(ps);
                    }
                });
                
               // //console.log('Permission sets after adding granted ones:', permissionSets);
            }
            
            this.userDetails = Object.assign(
                {}, 
                this.userDetails, 
                {
                    userName: data.userName,
                    userEmail: data.userEmail,
                    profileName: data.profileName,
                    isActive: data.isActive,
                    permissionSets: permissionSets
                }
            );
            
           // //console.log('Processed userDetails:', JSON.stringify({
           //     ...this.userDetails,
           //     permissionSets: this.userDetails.permissionSets.length
           // }));
        } catch(error) {
           // //console.error('User details error:', JSON.stringify(error));
            this.showErrorToast('User Details Error', 
                error.body?.message || error.message
            );
        }
    }

    // Risk Analysis Implementation
    async loadRiskAnalysis() {
        try {
            const riskResult = await analyzeUserRisk({ userId: this.selectedUserId });
            
            // Ensure risk score is a number between 0-100
            const riskScore = Math.min(100, Math.max(0, Number(riskResult.riskScore) || 0));
            
            this.userDetails = Object.assign(
                {},
                this.userDetails,
                {
                    highRiskCount: riskResult.highRiskCount,
                    riskScore: riskScore,
                    riskLevel: riskResult.riskLevel,
                    criticalFindings: riskResult.criticalFindings,
                    criticalFindingsDetailed: riskResult.criticalFindingsDetailed || []
                }
            );
            
            // Render the risk chart after data is loaded
            if (this.chartJsInitialized) {
                // Use Promise to ensure the DOM is updated before rendering the chart
                Promise.resolve().then(() => {
                    this.renderRiskChart();
                });
            }
            
        } catch(error) {
           //    //console.error('Risk analysis error:', error);
            this.showErrorToast('Risk Analysis Error','Error analyzing risk');
        }
    }

    // Method to force refresh risk analysis after permission changes
    async refreshRiskAnalysis() {
        try {
            // Force a fresh call to the risk analysis method
            await this.loadRiskAnalysis();
        } catch(error) {
            //console.error('Error refreshing risk analysis:', error);
            this.showErrorToast('Risk Refresh Error', 'Failed to refresh risk analysis');
        }
    }

    renderRiskChart() {
        const canvas = this.template.querySelector('.risk-chart');
        if (!canvas) return;
        
        // Check if Chart.js is loaded
        if (!window.Chart || !this.chartJsInitialized) {
            // Chart.js is not loaded yet, skip rendering for now
            // The chart will be rendered when loadRiskAnalysis is called after Chart.js loads
            return;
        }
        
        // Get the risk score
        const riskScore = this.userDetails.riskScore || 0;
        
        // Determine color based on risk level
        let chartColor;
        if (riskScore <= 50) {
            chartColor = '#00CED1'; // Aqua/Turquoise for scores 50 or below
        } else {
            chartColor = '#FF6B6B'; // Subtle coral red for scores above 50
        }
        
        // If a chart already exists, destroy it
        if (this.riskChart) {
            this.riskChart.destroy();
        }
        
        // Create new chart with solid colors for better compatibility
        this.riskChart = new window.Chart(canvas, {
            type: 'doughnut',
            data: {
                datasets: [{
                    data: [riskScore, 100 - riskScore],
                    backgroundColor: [
                        chartColor, // Use solid color instead of gradient
                        '#EEEEEE' // Light gray for the remaining portion
                    ],
                    borderWidth: 0,
                    hoverBackgroundColor: [
                        this.adjustColor(chartColor, -20), // Slightly darker on hover
                        '#DDDDDD'
                    ]
                }]
            },
            options: {
                circumference: 180, // Semi-circle
                rotation: -90, // Rotate to make the semi-circle face up
                cutout: '75%', // Size of the hole in the middle
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    },
                    tooltip: {
                        enabled: false
                    }
                }
            }
        });
    }

    // Helper function to adjust color brightness
    adjustColor(color, amount) {
        return '#' + color.replace(/^#/, '').replace(/../g, hex => 
            ('0' + Math.min(255, Math.max(0, parseInt(hex, 16) + amount)).toString(16)).substr(-2)
        );
    }

    // Getters for derived properties
    get userIsActive() {
        return this.userDetails.isActive ? 'Active' : 'Inactive';
    }

    get userStatusVariant() {
        return this.userDetails.isActive ? 'success' : 'error';
    }

    get totalPermissions() {
        return (this.userDetails.permissionSets?.length || 0) + 
               (this.systemPermissions?.length || 0);
    }

    // Toast utility
    showErrorToast(title, message) {
        const safeMessage = this.sanitizeHtml(message);
        if (!import.meta.env.SSR) {
        this.dispatchEvent(new ShowToastEvent({
            title: title || 'Error',
            message: safeMessage,
                variant: 'error'
        }));
        }
    }
    

   @track showSystemPermissions = false;
    systemPermissions = [];
    objectPermissions = [];
    fieldPermissions;
    itemsPerPageObjects = 100;
    itemsPerPageFields = 100;
  currentObjectPage = 1;
    currentFieldPage = 1;
    totalObjectRecords = 0;
    totalFieldRecords = 0;
    @track totalFieldsCount; 
  showObjects = false;
    showFields = false;
   showRecordTypes = false;
    @track recordTypePermissions = [];
    recordTypeColumns = [
        {
            label: 'Object',
            fieldName: 'objectName',
            type: 'text',
            sortable: true
        },
        {
            label: 'Record Types',
            fieldName: 'formattedRecordTypes',  // Changed from recordTypeNames
            type: 'text',
            sortable: true,
            wrapText: true
        },
        {
            label: 'Profile',
            fieldName: 'profileName',
            type: 'text',
            sortable: true
        },
        {
            label: 'Assigned Via',
            fieldName: 'assignedVia',
            type: 'text',
            sortable: true
        }
    ];
    systemPermissionColumns = [
        { label: 'Permission', fieldName: 'permission', type: 'text',cellAttributes: { class: 'slds-cell-wrap slds-text-title_bold' } },
    { label: 'Status', fieldName: 'status', type: 'text' ,cellAttributes: { class: 'slds-cell-wrap slds-text-title_bold' }},
    { 
        label: 'Sources', 
        fieldName: 'sources', 
        type: 'text',
        cellAttributes: { class: 'slds-cell-wrap slds-text-title_bold' },
        initialWidth: 300 
        
    }
    ];

    // Define table columns
    objectColumns = [
        { 
            label: 'Object', 
            fieldName: 'objectName',
            type: 'text',
            cellAttributes: { class: 'slds-text-title_bold' } 
        },
        { 
            label: 'Read', 
            fieldName: 'readText', 
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'readText' },
                title: 'Click to toggle permission',
                name: 'toggle_read',
                variant: 'base',
                iconName: { fieldName: 'readIcon' },
                iconPosition: 'right'
            },
            cellAttributes: { 
                class: 'permission-cell',
                alignment: 'center'
            }
        },
        { 
            label: 'Create', 
            fieldName: 'createText', 
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'createText' },
                title: 'Click to toggle permission',
                name: 'toggle_create',
                variant: 'base',
                iconName: { fieldName: 'createIcon' },
                iconPosition: 'right'
            },
            cellAttributes: { 
                class: 'permission-cell',
                alignment: 'center'
            }
        },
        { 
            label: 'Edit', 
            fieldName: 'editText', 
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'editText' },
                title: 'Click to toggle permission',
                name: 'toggle_edit',
                variant: 'base',
                iconName: { fieldName: 'editIcon' },
                iconPosition: 'right'
            },
            cellAttributes: { 
                class: 'permission-cell',
                alignment: 'center'
            }
        },
        { 
            label: 'Delete', 
            fieldName: 'deleteText', 
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'deleteText' },
                title: 'Click to toggle permission',
                name: 'toggle_delete',
                variant: 'base',
                iconName: { fieldName: 'deleteIcon' },
                iconPosition: 'right'
            },
            cellAttributes: { 
                class: 'permission-cell',
                alignment: 'center'
            }
        },
        { 
            label: 'View All Records', 
            fieldName: 'viewAllText', 
            type: 'text',
            cellAttributes: { 
                class: 'granular-permission-cell',
                alignment: 'center'
            }
        },
        { 
            label: 'Modify All Records', 
            fieldName: 'modifyAllText', 
            type: 'text',
            cellAttributes: { 
                class: 'granular-permission-cell',
                alignment: 'center'
            }
        },
        { 
            label: 'View All Fields', 
            fieldName: 'viewAllFieldsText', 
            type: 'text',
            cellAttributes: { 
                class: 'granular-permission-cell',
                alignment: 'center'
            }
        },
        { 
            label: 'AssignedBy', 
            fieldName: 'assignedBy', 
            type: 'text',
             
            sortable: true
        },
        { 
            label: 'AssignmentMethod', 
            fieldName: 'assignmentMethod', 
            type: 'text',
             
            sortable: true
        },
         
        { 
            label: 'Source Type', 
            fieldName: 'sourceType', 
            type: 'text',
            cellAttributes: {
                class: 'source-type-badge {sourceBadgeClass}'
            },
            sortable: true
        },
        { 
            label: 'Source Name', 
            fieldName: 'sourceName', 
            type: 'text',
            sortable: true
        },
        {
            type: 'action',
            typeAttributes: { 
                rowActions: [
                    { label: 'View Source Details', name: 'view_details', iconName: 'utility:source' }
                ],
                menuAlignment: 'right'
            },
            cellAttributes: {
                class: { fieldName: 'actionClass' }
            }
        }
    ];

    // Modified field columns definition
    fieldColumns = [
        { 
            label: 'Object', 
            fieldName: 'object',
            type: 'text', // Changed from text to button type
             
            cellAttributes: { 
                class: 'slds-text-title_bold ',
                style: 'background-color: #e3e0ff; color: #181818;'
            },
            iconName: 'utility:standard_objects', // Add object type icon
            iconPosition: 'left',
            sortable: true,
            initialWidth: 250
        },
        { 
            label: 'Field', 
            fieldName: 'field',   // Matches cleaned data
            type: 'text',
            cellAttributes: { class: 'slds-truncate ' } 
        },
        { 
            label: 'Read', 
            fieldName: 'readText', 
            type: 'text',
            typeAttributes: {
                iconName: { fieldName: 'readIcon' },
                iconPosition: 'right'
            },
            cellAttributes: { 
                class: 'permission-cell',
                alignment: 'center'
            }
        },
        { 
            label: 'Edit', 
            fieldName: 'editText', 
            type: 'text',
            typeAttributes: {
                iconName: { fieldName: 'editIcon' },
                iconPosition: 'right'
            },
            cellAttributes: { 
                class: 'permission-cell',
                alignment: 'center'
            }
        }
    ];

    // Add to class properties
    searchTerm = '';
    fieldSearchTerm = '';

    // Modified field permissions handling
    fieldLastRecordId = null;
    fieldPageData = [];

    // Add search mode tracking
    searchMode = false;

    // Component properties - removed duplicates to fix diagnostic errors
    itemsPerObjectPage = 50;
    objectSearchTimeout;
    _showSystemPermissions = false;
    allMergedObjects = new Map();

    // Add to component properties
   @track showSharingRules = false;
    @track showRoleHierarchy = false;
    @track showLoginHistory = false;
    @track showAuditTrail = false;
    @track sharingRules = [];
    @track roleHierarchy = [];
    @track loginhistory = [];
    @track auditTrailData = [];
    
    // Audit Trail Properties
    @track auditStartDate = '';
    @track auditEndDate = '';
    @track selectedMetadataType = '';
    @track isLoadingAuditData = false;
    @track auditTrailCount = 0;
    @track auditSortedBy = 'CreatedDate';
    @track auditSortedDirection = 'desc';
    
    // Metadata Type Options
    @track metadataTypeOptions = [
        { label: 'All Types', value: '' },
        { label: 'User', value: 'User' },
        { label: 'Profile', value: 'Profile' },
        { label: 'Permission Set', value: 'Permission Set' },
        { label: 'Role', value: 'Role' },
        { label: 'Custom Object', value: 'Custom Object' },
        { label: 'Custom Field', value: 'Custom Field' },
        { label: 'Workflow Rule', value: 'Workflow Rule' },
        { label: 'Flow', value: 'Flow' },
        { label: 'Apex Class', value: 'Apex Class' },
        { label: 'Apex Trigger', value: 'Apex Trigger' },
        { label: 'Lightning Component', value: 'Lightning Components' },
        { label: 'Report', value: 'Report' },
        { label: 'Dashboard', value: 'Dashboard' },
        { label: 'Custom Apps', value: 'Custom Apps' },
        { label: 'Application', value: 'Application' }
    ];

    // Add column definitions
    sharingRuleColumns = [
        { label: 'Object Name', fieldName: 'objectApiName', type: 'text' },
        { label: 'Criteria', fieldName: 'ruleName', type: 'text' },
        { label: 'Shared With', fieldName: 'ruleType', type: 'text' },
        { label: 'Rule Type', fieldName: 'sharedWith', type: 'text' }
    ];

    roleHierarchyColumns = [
        { label: 'Role Name', fieldName: 'roleName', type: 'text' },
        { label: 'Parent Role', fieldName: 'parentRole', type: 'text' },
        { label: 'Access Level', fieldName: 'accessLevel', type: 'text' }
    ];

    loginhistoryColumn = [
        { label: 'Login Time', fieldName: 'LoginTime', type: 'date', 
          typeAttributes: { 
              timeZone: 'UTC', 
              year: 'numeric', 
              month: '2-digit', 
              day: '2-digit', 
              hour: '2-digit', 
              minute: '2-digit', 
              second: '2-digit' 
          } },
        { label: 'Status', fieldName: 'Status', type: 'text' },
        { label: 'Source IP', fieldName: 'SourceIp', type: 'text' },
        { label: 'Login Type', fieldName: 'LoginType', type: 'text' },
        { label: 'Application', fieldName: 'Application', type: 'text' },
        { label: 'Browser', fieldName: 'Browser', type: 'text' },
        { label: 'Platform', fieldName: 'Platform', type: 'text' }
    ];

    auditTrailColumns = [
        { label: 'Date', fieldName: 'CreatedDate', type: 'date', sortable: true,
          typeAttributes: { 
              timeZone: 'UTC', 
              year: 'numeric', 
              month: '2-digit', 
              day: '2-digit', 
              hour: '2-digit', 
              minute: '2-digit' 
          } },
        { label: 'User', fieldName: 'CreatedByName', type: 'text', sortable: true },
        { label: 'Action', fieldName: 'Action', type: 'text', sortable: true },
        { label: 'Section', fieldName: 'Section', type: 'text', sortable: true },
        { label: 'Delegate User', fieldName: 'DelegateUser', type: 'text', sortable: true },
        { label: 'Display', fieldName: 'Display', type: 'text', sortable: true }
    ];

    // Load users on component load
    @wire(getActiveUsers)
    wiredUsers({ data, error }) {
        if (data) {
            this.userOptions = data.map(user => ({
                label: user.Name,
                value: user.Id
            }));
        }
    }
    handleClearSearch() {
        this.searchTerm = '';
        this.currentObjectPage = 1;
        this.loadObjectPermissions();
    }
    

    

    /**
     * Identifies objects that have duplicate access permissions from multiple sources
     * @param {Array} permissionsData - The raw permissions data from the server
     * @returns {Set} - A Set of object names that have duplicate access
     */
    identifyDuplicateAccess(permissionsData) {
        // Group objects by their name
        const objectPermMap = {};
        
        permissionsData.forEach(perm => {
            const objectName = perm.objectName;
            if (!objectPermMap[objectName]) {
                objectPermMap[objectName] = [];
            }
            objectPermMap[objectName].push(perm);
        });
        
        // Identify objects with multiple sources
        const duplicateObjects = new Set();
        const objectSourceMap = new Map(); // Map to track object → sources
        
        Object.keys(objectPermMap).forEach(objectName => {
            const permissions = objectPermMap[objectName];
            
            // Only include if there are multiple sources for the same object
            if (permissions.length > 1) {
                duplicateObjects.add(objectName);
                
                // Store sources for later use in processing
                if (!objectSourceMap.has(objectName)) {
                    objectSourceMap.set(objectName, new Set());
                }
                
                permissions.forEach(perm => {
                    objectSourceMap.get(objectName).add(perm.sourceName);
                });
            }
        });
        
        this.duplicateObjectSourceMap = objectSourceMap;
        return duplicateObjects;
    }

    async loadObjectPermissions() {
        try {
            const { data, total } = await getObjectPermissions({
                userId: this.selectedUserId,
                page: this.currentObjectPage,
                pageSize: this.itemsPerPageObjects,
                searchTerm: this.searchTerm,
            });

           // console.log('DEBUG: Raw data from Apex:', data);
           // console.log('DEBUG: First record structure:', data[0]);
            /*console.log('DEBUG: Granular permissions check:', {
                canViewAll: data[0]?.canViewAll,
                canModifyAll: data[0]?.canModifyAll,
                canViewAllFields: data[0]?.canViewAllFields
            });*/

            // REPLACE existing records instead of merging
            if(this.currentObjectPage === 1) {
                this.allMergedObjects.clear();
            }

            // Store unique records but don't slice for pagination
            data.forEach(op => {
                const key = op.objectName;
                this.allMergedObjects.set(key, op);
            });

            // Identify objects with duplicate access
            const duplicateObjects = this.identifyDuplicateAccess(data);
            this.duplicateAccessCount = duplicateObjects.size;

            // Group objects and merge their permissions
            const mergedObjectPermMap = new Map();
            
            // First pass - create merged objects
            data.forEach(perm => {
                const objectName = perm.objectName;
                if (!mergedObjectPermMap.has(objectName)) {
                    // Create a new merged permission with the highest values
                    mergedObjectPermMap.set(objectName, {
                        objectName: objectName,
            PermissionsRead: perm.canRead,
            PermissionsCreate: perm.canCreate,
            PermissionsEdit: perm.canEdit,
            PermissionsDelete: perm.canDelete,
                        // Enhanced granular permissions
                        canViewAll: perm.canViewAll || false,
                        canModifyAll: perm.canModifyAll || false,
                        canViewAllFields: perm.canViewAllFields || false,
                        sources: new Map(), // Store sources by name
                        isDuplicateAccess: duplicateObjects.has(objectName)
                    });
                } else {
                    // Update with OR operations to get the highest permission level
                    const mergedPerm = mergedObjectPermMap.get(objectName);
                    mergedPerm.PermissionsRead = mergedPerm.PermissionsRead || perm.canRead;
                    mergedPerm.PermissionsCreate = mergedPerm.PermissionsCreate || perm.canCreate;
                    mergedPerm.PermissionsEdit = mergedPerm.PermissionsEdit || perm.canEdit;
                    mergedPerm.PermissionsDelete = mergedPerm.PermissionsDelete || perm.canDelete;
                    // Enhanced granular permissions - use OR to get highest level
                    mergedPerm.canViewAll = mergedPerm.canViewAll || perm.canViewAll || false;
                    mergedPerm.canModifyAll = mergedPerm.canModifyAll || perm.canModifyAll || false;
                    mergedPerm.canViewAllFields = mergedPerm.canViewAllFields || perm.canViewAllFields || false;
                }
                
                // Add this source
                const sourceMap = mergedObjectPermMap.get(objectName).sources;
                sourceMap.set(perm.sourceName, {
                    type: perm.sourceType,
                    name: perm.sourceName,
            assignedBy: perm.assignedBy,
                    assignmentMethod: perm.assignmentMethod,
                    canRead: perm.canRead,
                    canCreate: perm.canCreate,
                    canEdit: perm.canEdit,
                    canDelete: perm.canDelete,
                    // Enhanced granular permissions
                    canViewAll: perm.canViewAll || false,
                    canModifyAll: perm.canModifyAll || false,
                    canViewAllFields: perm.canViewAllFields || false,
            sourceBadgeClass: this.getSourceBadgeClass(perm.sourceType)
                });
            });
            
            // Convert to array and add flat source information for the datatable
            let processedData = Array.from(mergedObjectPermMap.values()).map(mergedPerm => {
                const sources = Array.from(mergedPerm.sources.values());
                const firstSource = sources[0]; // Get first source for default display
                
                return {
                    ...mergedPerm,
                    sourceType: firstSource.type,
                    assignedBy: firstSource.assignedBy,
                    assignmentMethod: firstSource.assignmentMethod,
                    sourceName: sources.length > 1 ? 
                        `Multiple Sources (${sources.length})` : 
                        firstSource.name,
                    sourceBadgeClass: sources.length > 1 ? 
                        'slds-theme_info' : 
                        firstSource.sourceBadgeClass,
                    readIcon: mergedPerm.PermissionsRead ? 'utility:check' : 'utility:close',
                    readLabel: mergedPerm.PermissionsRead ? 'Allowed' : 'Denied',
                    readText: mergedPerm.PermissionsRead ? 'Allowed' : 'Denied',
                    createIcon: mergedPerm.PermissionsCreate ? 'utility:check' : 'utility:close',
                    createLabel: mergedPerm.PermissionsCreate ? 'Allowed' : 'Denied',
                    createText: mergedPerm.PermissionsCreate ? 'Allowed' : 'Denied',
                    // Enhanced granular permissions text
                    viewAllText: mergedPerm.canViewAll ? 'Allowed' : 'Denied',
                    modifyAllText: mergedPerm.canModifyAll ? 'Allowed' : 'Denied',
                    viewAllFieldsText: mergedPerm.canViewAllFields ? 'Allowed' : 'Denied',
                    editIcon: mergedPerm.PermissionsEdit ? 'utility:check' : 'utility:close',
                    editLabel: mergedPerm.PermissionsEdit ? 'Allowed' : 'Denied',
                    editText: mergedPerm.PermissionsEdit ? 'Allowed' : 'Denied',
                    deleteIcon: mergedPerm.PermissionsDelete ? 'utility:check' : 'utility:close',
                    deleteLabel: mergedPerm.PermissionsDelete ? 'Allowed' : 'Denied',
                    deleteText: mergedPerm.PermissionsDelete ? 'Allowed' : 'Denied',
                    rowClass: mergedPerm.isDuplicateAccess ? 'duplicate-access-highlight' : '',
                    actionClass: mergedPerm.isDuplicateAccess ? 'show-actions' : 'hide-actions'
                };
            });
            
            // If showing only duplicate access, filter for objects with duplicate access
            if (this.showDuplicateAccessOnly) {
                processedData = processedData.filter(perm => perm.isDuplicateAccess);
            }
            
            this.objectPermissions = processedData;
            this.totalObjectRecords = this.showDuplicateAccessOnly ? processedData.length : total;
        this.error = undefined;
            
    } catch(error) {
        this.objectPermissions = [];
        this.totalObjectRecords = 0;
            this.duplicateAccessCount = 0;
        this.showErrorToast('Load Error', error.body?.message || error.message);
    } finally {
        this.isLoading = false;
    }
    }

    getSourceBadgeClass(sourceType) {
        const styleMap = {
            'Profile': 'slds-theme_success',
            'Permission Set': 'slds-theme_warning',
            'Package': 'slds-theme_alt-inverse'
        };
        return `slds-badge badge-small ${styleMap[sourceType] || ''}`;
    }


    /**
     * @description loads the data for fields.
     * @Date 3 March 2025
     * @return async
     */
    async loadFieldPermissions() {
        const userId = this.selectedUserId;
        if (!userId) return;

        try {
            this.isLoadingFields = true;
            // Show a loading spinner while we retrieve data
            //console.log('Loading field permissions with search term: ', this.fieldSearchTerm);

            // Get the field permissions grouped by object first
            const result = await getFieldPermissions({
                userId: userId,
                lastRecordId: null,
                searchTerm: this.fieldSearchTerm ? this.fieldSearchTerm.trim() : '',
                groupByObject: true,
                objectName: ''
            });

            if (result && result.success) {
                // Process the objects list
                this.objectsWithPermissions = result.objects || [];
                this.totalFieldsCount = result.totalCount || 0;
                
                // Store field counts returned from the server for each object
                if (result.fieldCountsByObject) {
                    this.fieldCountsByObject = result.fieldCountsByObject;
                }
                
                // Log how many objects were found
                if (this.fieldSearchTerm) {
                    //console.log(`Found ${this.objectsWithPermissions.length} objects matching search: "${this.fieldSearchTerm}"`);
                } else {
                    //console.log(`Loaded ${this.objectsWithPermissions.length} objects with field permissions`);
                }
            }
        } catch (e) {
            //console.error('Error loading field permissions:', e);
            this.showErrorToast('Error Loading Field Permissions', this.getErrorMessage(e));
        } finally {
            this.isLoadingFields = false;
        }
    }
    
    // Add a new method to load fields for a specific object when expanded
    async loadFieldsForObject(objectName) {
        if (!this.selectedUserId || !objectName) return;
        
        try {
            // Only load fields if we haven't already loaded them for this object
            if (this.fieldPermissionsByObject[objectName] && 
                this.fieldPermissionsByObject[objectName].length > 0) {
                //console.log(`Using cached fields for ${objectName}`);
                return;
            }
            
            this.isLoadingFields = true;
            //console.log(`Loading fields for object: ${objectName}`);
            
            // Check if we're filtering with a search term
            if (this.fieldSearchTerm) {
                //console.log(`Using search term for field loading: "${this.fieldSearchTerm}"`);
            }
            
            const result = await getFieldPermissions({
                userId: this.selectedUserId,
                lastRecordId: null,
                searchTerm: this.fieldSearchTerm ? this.fieldSearchTerm.trim() : '',
                groupByObject: false,
                objectName: objectName
            });
            
            if (result && result.success) {
                // Process the field data
                const fields = result.data || [];
                
                // Format fields for display
                const formattedFields = fields.map((field, index) => {
                    // Extract field name from the full path (Object.Field)
                    const fieldParts = field.Field ? field.Field.split('.') : [];
                    const fieldName = fieldParts.length > 1 ? fieldParts[1] : field.Field;
                    
                    return {
                        key: `${objectName}-field-${index}`,
                        field: fieldName,
                        PermissionsRead: field.PermissionsRead,
                        PermissionsEdit: field.PermissionsEdit,
                        readIconName: field.PermissionsRead ? 'utility:check' : 'utility:close',
                        readAccessText: field.PermissionsRead ? 'Read Access Allowed' : 'Read Access Denied',
                        readIconClass: field.PermissionsRead ? 'slds-icon-text-success' : 'slds-icon-text-error',
                        editIconName: field.PermissionsEdit ? 'utility:check' : 'utility:close',
                        editAccessText: field.PermissionsEdit ? 'Edit Access Allowed' : 'Edit Access Denied',
                        editIconClass: field.PermissionsEdit ? 'slds-icon-text-success' : 'slds-icon-text-error',
                        rowClass: index % 2 === 0 ? 'field-row even-row' : 'field-row odd-row'
                    };
                });
                
                // Store the fields for this object
                this.fieldPermissionsByObject[objectName] = formattedFields;
                
                // Update the field count in the fieldCountsByObject map
                if (!this.fieldCountsByObject) {
                    this.fieldCountsByObject = {};
                }
                this.fieldCountsByObject[objectName] = formattedFields.length;
                
                //console.log(`Loaded ${formattedFields.length} fields for ${objectName}`);
            } else {
                //console.error(`Error loading fields for ${objectName}:`, result);
                this.fieldPermissionsByObject[objectName] = [];
            }
        } catch (error) {
            //console.error(`Error loading fields for ${objectName}:`, error);
            this.showErrorToast(`Error loading fields for ${objectName}`, this.getErrorMessage(error));
            this.fieldPermissionsByObject[objectName] = [];
        } finally {
            this.isLoadingFields = false;
        }
    }

    // Add this method to handle expansion/collapse of objects
    handleObjectExpand(event) {
        const objectName = event.currentTarget.dataset.objectName;
        
        if (this.expandedObjects.has(objectName)) {
            // Collapse this object
            this.expandedObjects.delete(objectName);
        } else {
            // Expand this object
            this.expandedObjects.add(objectName);
            // Load fields if not already loaded
            this.loadFieldsForObject(objectName);
        }
        
        // Update UI state
        this.objectsWithPermissions = this.objectsWithPermissions.map(obj => {
            if (obj.objectName === objectName) {
                return {
                    ...obj,
                    isExpanded: this.expandedObjects.has(objectName)
                };
            }
            return obj;
        });
    }

    // Fix toggleObjects to include scrolling
    toggleObjects() {
        this.showObjects = !this.showObjects;
        if (this.showObjects) {
            this.currentObjectPage = 1;
            this.loadObjectPermissions();
            // Add scrolling when showing objects
            this.scrollToSection('objects-section');
        }
    }

    // Fix toggleFields to include scrolling
    toggleFields() {
        this.showFields = !this.showFields;
        if (this.showFields) {
            this.currentFieldPage = 1;
            this.loadFieldPermissions();
            // Add scrolling when showing fields
            this.scrollToSection('fields-section');
        }
    }
    get hasData() {
        return this.paginatedFieldPermissions?.length > 0;
    }

    // Fix toggleRecordTypes to include scrolling
    toggleRecordTypes() {
        this.showRecordTypes = !this.showRecordTypes;
        if(this.showRecordTypes) {
           this.loadUserPermissions();
           // Add scrolling when showing record types
           this.scrollToSection('record-types-section');
        }
    }

    // Fix toggleSystemPermissions to include scrolling
    toggleSystemPermissions() {
        this.showSystemPermissions = !this.showSystemPermissions;
        if (this.showSystemPermissions) {
            this.loadSystemPermissions();
            // Add scrolling when showing system permissions
            this.scrollToSection('system-permissions-section');
        }
    }

    // Fix handleSharingRulesToggle to include scrolling
    handleSharingRulesToggle() {
        this.showSharingRules = !this.showSharingRules;
        if (this.showSharingRules) {
            this.loadSharingRules();
            // Add scrolling when showing sharing rules
            this.scrollToSection('sharing-rules-section');
        }
    }

    // Fix handleRoleHierarchyToggle to include scrolling
    handleRoleHierarchyToggle() {
        this.showRoleHierarchy = !this.showRoleHierarchy;
        if (this.showRoleHierarchy) {
            this.loadRoleHierarchy();
            // Add scrolling when showing role hierarchy
            this.scrollToSection('role-hierarchy-section');
        }
    }

    // Fix handleLoginHistoryToggle to include scrolling
    handleLoginHistoryToggle() {
        this.showLoginHistory = !this.showLoginHistory;
        if (this.showLoginHistory) {
            this.loadLoginHistory();
            // Add scrolling when showing login history
            this.scrollToSection('login-history-section');
        }
    }

    // Audit Trail Toggle Handler
    handleAuditTrailToggle() {
        this.showAuditTrail = !this.showAuditTrail;
        if (this.showAuditTrail) {
            // Set default date range (last 30 days)
            const today = new Date();
            const thirtyDaysAgo = new Date(today.getTime() - (30 * 24 * 60 * 60 * 1000));
            this.auditEndDate = today.toISOString().split('T')[0];
            this.auditStartDate = thirtyDaysAgo.toISOString().split('T')[0];
            
            // Add scrolling when showing audit trail
            this.scrollToSection('audit-trail-section');
        }
    }

    handleObjectPrevious() {
        if(this.currentObjectPage > 1) {
            this.currentObjectPage--;
            this.loadObjectPermissions();
        }
    }

    handleObjectNext() {
        if(!this.disableObjectNextButton) {
            this.currentObjectPage++;
            this.loadObjectPermissions();
        }
    }

    handleFieldPrevious() {
        if(this.currentFieldPage > 1) {
            this.currentFieldPage--;
        }
    }

    async handleFieldNext() {
        if(this.hasMoreFields) {
            this.currentFieldPage++;
            // Only load more if we don't have enough client-side data
            if(this.currentFieldPage * this.itemsPerPageFields > this.fieldPageData.length) {
                await this.loadFieldPermissions();
            }
        }
    }

    get objectPageInfo() {
        return this.getPageInfo(this.currentObjectPage, this.totalObjectRecords);
    }

    get fieldPageInfo() {
        return this.PageInfo(this.currentFieldPage, this.totalFieldRecords);
    }
    get pageInfo() {
        const total = this.fieldPageData.length;
        const start = Math.min((this.currentFieldPage - 1) * this.itemsPerPageFields + 1, total);
        const end = Math.min(start + this.itemsPerPageFields - 1, total);
        return total > 0 ? `Showing ${start}-${end} of ${total}` : 'No results';
    }

    getPageInfo(currentPage, totalRecords) {
        const validTotal = totalRecords || 0;
        const start = ((currentPage - 1) * this.itemsPerPageObjects) + 1;
        const end = Math.min(currentPage * this.itemsPerPageObjects, validTotal);
        return validTotal > 0 ? `Showing ${start}-${end} of ${validTotal} records` : 'No records found';
    }

    get objectIcon() {
        return this.showObjects ? 'utility:chevronup' : 'utility:chevrondown';
    }

    get fieldIcon() {
        return this.showFields ? 'utility:chevronup' : 'utility:chevrondown';
    }

    get isFirstObjectPage() {
        return this.currentObjectPage === 1;
    }

    get isLastObjectPage() {
        return this.currentObjectPage * this.itemsPerPageObjects >= this.totalObjectRecords;
    }

    get isFirstFieldPage() {
        return this.currentFieldPage === 1;
    }

    get isLastFieldPage() {
        // Check both client-side data and server-side availability
        return !this.hasMoreFields && 
               this.currentFieldPage * this.itemsPerPageFields >= this.fieldPageData.length;
    }

    

    get recordTypeIcon() {
        return this.showRecordTypes ? 'utility:chevronup' : 'utility:chevrondown';
    }

     async loadUserPermissions() {
        try {
            const result = await getRecordTypeAssignments({ 
                userId: this.selectedUserId 
            }) || [];
            
            this.recordTypePermissions = result.map(rt => ({
                id: rt.objectName + '-' + rt.profileName,  // Add a unique key
                objectName: rt.objectName || '',
                formattedRecordTypes: rt.formattedRecordTypes || '',
                profileName: rt.profileName || '',
                assignedVia: rt.assignedVia || ''
            }));
            
        } catch(error) {
            this.recordTypePermissions = [];
            //this.showErrorToast('Error', error.body?.message || 'Error loading record types');
        }
    } 

    // Replace the toggle methods with these
    handleRecordTypeToggle(event) {
        this.showRecordTypes = event.detail.checked;
        if (this.showRecordTypes && (!this.recordTypePermissions || this.recordTypePermissions.length === 0)) {
            this.loadUserPermissions();
        }
    }

    handleObjectToggle(event) {
        this.showObjects = event.detail.checked;
        if(this.showObjects && this.objectPermissions.length === 0) {
            this.loadObjectPermissions();
        }
    }

    handleFieldToggle(event) {
        this.showFields = event.detail.checked;
    }

    handleSystemPermissionsToggle(event) {
        this.showSystemPermissions = event.detail.checked;
        if(this.showSystemPermissions && !this.systemPermissions.length) {
            this.loadSystemPermissions();
        }
    }

    // Corrected handler method
    /*async handleObjectSearch(event) {
        this.searchTerm = event.detail.value;
        this.currentObjectPage = 1;
        await this.loadObjectPermissions();
    }*/
        async handleObjectSearch(event) {
            // Get search term from event properly
            const searchTerm = event.detail.value; // For lightning-input use event.detail.value
            // const searchTerm = event.target.value; // For standard HTML input
            
            // Add null check and proper reference
            if (searchTerm && searchTerm.length < 3) {
                this.showToast('Info', 'Please enter at least 3 characters to search', 'info');
                return;
            }
            
            // Assign to class property
            this.searchTerm = searchTerm;
            this.currentObjectPage = 1;
            await this.loadObjectPermissions();
        }


    // Modified filtered getter with proper reactivity
    /*get filteredObjectPermissions() {
        return this.objectPermissions;
    }*/
        get filteredObjectPermissions() {
            return this.objectPermissions.filter(perm => 
                perm.objectName.toLowerCase().includes(this.searchTerm?.toLowerCase() || '')
            );
        }
    // Modified search handler
    async handleFieldSearch(event) {
        try {
            // Check the value from the event
            const searchValue = event.target.value;
            //console.log('Field search term (raw):', searchValue);
            
            // Assign to the component property
            this.fieldSearchTerm = searchValue;
            
            // Only perform search if we have a user selected
            if (!this.selectedUserId) {
                //console.log('No user selected, cannot search field permissions');
                return;
            }
            
            this.isLoadingFields = true;
            
            // Reset our data structures before loading with new search
            this.expandedObjects = new Set();
            this.fieldPermissionsByObject = {};
            this.objectsWithPermissions = [];
            
            // Reload field permissions with the search term
        await this.loadFieldPermissions();
            
            //console.log(`After search, found ${this.objectsWithPermissions.length} objects matching '${this.fieldSearchTerm}'`);
        } catch (error) {
            //console.error('Error in field search:', error);
            //console.error('Stack:', error.stack);
            if (error.body) {
                //console.error('Error body:', JSON.stringify(error.body));
            }
            this.showErrorToast('Search Error', error.message || 'Error performing search');
        } finally {
            this.isLoadingFields = false;
        }
    }

    // Update filtered field permissions getter
    get filteredFieldPermissions() {
        if (!this.fieldPageData) return [];
        if (!this.fieldSearchTerm) return this.fieldPageData;
        
        const searchTerm = this.fieldSearchTerm.toLowerCase();
        return this.fieldPageData.filter(fp => {
            const objectMatch = fp.object?.toLowerCase().includes(searchTerm);
            const fieldMatch = fp.field?.toLowerCase().includes(searchTerm);
            return objectMatch || fieldMatch;
        });
    }

    // Update paginated getter to use filtered results
    get paginatedFieldPermissions() {
        const start = (this.currentFieldPage - 1) * this.itemsPerPageFields;
        return this.fieldPageData.slice(start, start + this.itemsPerPageFields);
    }

    // Update total records getter
    get totalFieldRecords() {
        return this.fieldPageData.length;
    }

    get hasMoreFields() {
        // Only consider server-side more records when we have a last ID
        return this.fieldLastRecordId !== null;
    }

    get disableNextButton() {
        // Enable if we have more fields OR client-side data allows next page
        return !this.hasMoreFields && 
               this.currentFieldPage * this.itemsPerPageFields >= this.fieldPageData.length;
    }

    get disablePreviousButton() {
        return this.isFirstFieldPage;
    }

   

    get filteredCount() {
        return this.filteredFieldPermissions.length;
    }

    // Client-side deduplication
    mergeFieldPermissions(data) {
        const merged = new Map();
        
        data.forEach(fp => {
            const key = `${fp.SobjectType}_${fp.Field}`;
            if(!merged.has(key)) {
                merged.set(key, {
                    ...fp,
                    object: cleanObjectName(fp.SobjectType),
                    field: cleanFieldName(fp.Field),
                    key: key,
                    PermissionsRead: false,
                    PermissionsEdit: false
                });
            }
            
            const existing = merged.get(key);
            merged.set(key, {
                ...existing,
                PermissionsRead: existing.PermissionsRead || fp.PermissionsRead,
                PermissionsEdit: existing.PermissionsEdit || fp.PermissionsEdit
            });
        });
        
        // Add permission formatting properties
        const mergedData = Array.from(merged.values()).map(item => {
            return {
                ...item,
                readIcon: item.PermissionsRead ? 'utility:check' : 'utility:close',
                readLabel: item.PermissionsRead ? 'Allowed' : 'Denied',
                readText: item.PermissionsRead ? 'Allowed' : 'Denied',
                editIcon: item.PermissionsEdit ? 'utility:check' : 'utility:close',
                editLabel: item.PermissionsEdit ? 'Allowed' : 'Denied',
                editText: item.PermissionsEdit ? 'Allowed' : 'Denied'
            };
        });
        
        return mergedData;
    }

    async loadSystemPermissions() {
        try {
            if(!this.selectedUserId) return;
            
            const permMap = await getSystemLevelPermissions({ 
                userId: this.selectedUserId 
            });
            
            this.systemPermissions = Object.keys(permMap).map(permKey => ({
                permission: permKey.replace(/_/g, ' '),
                status: permMap[permKey].Value ? 'Enabled' : 'Disabled',
                sources: permMap[permKey].Sources.join(', ')
            })).sort((a, b) => a.permission.localeCompare(b.permission));
            
        } catch(error) {
           // //console.error('Permission Error:', error);
            this.showErrorToast('System Permissions Error', error.body?.message || error.message);
        }
    }

    get systemPermissionsCount() {
        return this.systemPermissions?.length || 0;
    }

    async loadChartJsLibrary() {
        try {
            await loadScript(this, ChartJS);
            this.chartJsInitialized = true;
           // //console.log('Chart.js loaded successfully');
           
            // If we have risk data already loaded, render the chart now
            if (this.userDetails && this.userDetails.riskScore !== undefined) {
                this.renderRiskChart();
            }
        } catch (error) {
           // //console.error('Error loading Chart.js', error);
            this.showErrorToast('Error', 'Failed to load Chart.js library');
        }
    }

    activeSection = {
        fields: true,
        system: false
    };

    handleSectionToggle(event) {
        const section = event.currentTarget.dataset.section;
        this.activeSection = {
            ...this.activeSection,
            [section]: !this.activeSection[section]
        };
        
        // Lazy load data when section activated
        if(this.activeSection[section] && !this[`${section}DataLoaded`]) {
            this[`load${section.charAt(0).toUpperCase() + section.slice(1)}Permissions`]();
            this[`${section}DataLoaded`] = true;
        }
    }

    get disableObjectNextButton() {
        return this.currentObjectPage * this.itemsPerPageObjects >= this.totalObjectRecords;
    }

    // Update getter
    get showSystemPermissions() {
        return this._showSystemPermissions;
    }

    // Object Permissions Table
    get objectTableClasses() {
        return `slds-table slds-table_cell-buffer slds-table_bordered ${this.showObjects ? '' : 'slds-hidden'}`;
    }

    // Field Permissions Table (existing)
    get fieldTableClasses() {
        return `slds-table slds-table_cell-buffer slds-table_bordered ${this.showFields ? '' : 'slds-hidden'}`;
    }

    // Add this method to handle object permission merging
    mergeObjectPermissions(newData) {
        const merged = new Map();
        
        console.log('DEBUG: mergeObjectPermissions input:', newData);
        console.log('DEBUG: First item granular permissions:', {
            canViewAll: newData[0]?.canViewAll,
            canModifyAll: newData[0]?.canModifyAll,
            canViewAllFields: newData[0]?.canViewAllFields
        });
        
        newData.forEach(op => {
            const objectName = op.objectName || 'Unknown Object';
            const key = objectName;
            
            if(merged.has(key)) {
                const existing = merged.get(key);
                existing.PermissionsRead = existing.PermissionsRead || op.canRead;
                existing.PermissionsCreate = existing.PermissionsCreate || op.canCreate;
                existing.PermissionsEdit = existing.PermissionsEdit || op.canEdit;
                existing.PermissionsDelete = existing.PermissionsDelete || op.canDelete;
                // Enhanced granular permissions - merge with OR
                existing.canViewAll = existing.canViewAll || op.canViewAll;
                existing.canModifyAll = existing.canModifyAll || op.canModifyAll;
                existing.canViewAllFields = existing.canViewAllFields || op.canViewAllFields;
            } else {
                merged.set(key, {
                    ...op,
                    SobjectType: objectName,
                    PermissionsRead: Boolean(op.canRead),
                    readIcon: op.canRead ? 'utility:check' : 'utility:close',
                    readLabel: op.canRead ? 'Allowed' : 'Denied',
                    readText: op.canRead ? 'Allowed' : 'Denied',
                    PermissionsCreate: Boolean(op.canCreate),
                    createIcon: op.canCreate ? 'utility:check' : 'utility:close',
                    createLabel: op.canCreate ? 'Allowed' : 'Denied',
                    createText: op.canCreate ? 'Allowed' : 'Denied',
                    PermissionsEdit: Boolean(op.canEdit),
                    editIcon: op.canEdit ? 'utility:check' : 'utility:close',
                    editLabel: op.canEdit ? 'Allowed' : 'Denied',
                    editText: op.canEdit ? 'Allowed' : 'Denied',
                    PermissionsDelete: Boolean(op.canDelete),
                    deleteIcon: op.canDelete ? 'utility:check' : 'utility:close',
                    deleteLabel: op.canDelete ? 'Allowed' : 'Denied',
                    deleteText: op.canDelete ? 'Allowed' : 'Denied',
                    // Enhanced granular permissions
                    canViewAll: Boolean(op.canViewAll),
                    viewAllText: op.canViewAll ? 'Allowed' : 'Denied',
                    canModifyAll: Boolean(op.canModifyAll),
                    modifyAllText: op.canModifyAll ? 'Allowed' : 'Denied',
                    canViewAllFields: Boolean(op.canViewAllFields),
                    viewAllFieldsText: op.canViewAllFields ? 'Allowed' : 'Denied'
                });
            }
             
        });
        
        return Array.from(merged.values());
    }

    // Add toggle handlers
   

    // Add data loading methods
    async loadSharingRules() {
        try {
            this.isLoadingSharingRules = true;
            
            const result = await getSharingRulesData({ searchTerm: '', objectName: '' });
            //console.log('Sharing rules data:', result);
            
            if (!result || !result.sharingRules || result.sharingRules.length === 0) {
            this.sharingRules = [];
                this.showToast('No Data', 'No sharing rules found', 'info');
                return;
            }
            
            this.sharingRules = result.sharingRules;
            this.isRefreshingSharingRules = false;
            
            if (this.sharingRules.length === 0) {
                this.showToast('No Rules', 'No sharing rules found for any objects', 'info');
            } else {
                //console.log(`Loaded ${this.sharingRules.length} sharing rules`);
            }
        } catch (error) {
            //console.error('Error loading sharing rules:', error);
            this.showErrorToast('Error Loading Sharing Rules', this.getErrorMessage(error));
            this.sharingRules = [];
        } finally {
            this.isLoadingSharingRules = false;
        }
    }

    /**
     * Refreshes the sharing rules data by calling the @future method
     */
    async refreshSharingRules() {
        try {
            this.isRefreshingSharingRules = true;
            this.showToast('Processing', 'Refreshing sharing rules data. This may take a moment...', 'info');
            
            const result = await refreshOWDSharingData();
            
            if (result === true) {
                this.showToast('Success', 'Sharing rules refresh has been initiated. Please check back in a few minutes.', 'success');
                
                // Wait a moment for the background job to process, then try to load the data
                setTimeout(() => {
                    this.loadSharingRules();
                }, 5000); // Wait 5 seconds before attempting to load the refreshed data
            } else {
                this.showToast('Error', 'Failed to refresh sharing rules', 'error');
            }
        } catch (error) {
            //console.error('Error refreshing sharing rules:', error);
            this.showErrorToast('Refresh Error', this.getErrorMessage(error));
        } finally {
            this.isRefreshingSharingRules = false;
        }
    }

    async loadRoleHierarchy() {
        try {
            this.roleHierarchy = await getRoleHierarchy({ userId: this.selectedUserId });
        } catch(error) {
            this.roleHierarchy = [];
            this.showToast('Error', error.body.message, 'error');
        }
    }

    async loadLoginHistory(){
        if (!this.selectedUserId) return;
        try {
            this.loginhistory = await getLoginHistory({ userId: this.selectedUserId });
            ////console.log('logindata--',this.loginhistory );
        } catch(error) {
            this.loginhistory = [];
            this.showToast('Error', error.body?.message || error.message, 'error');  // Added safe error handling
        }
    }
    


    // Add getters for counts
    get sharingRulesCount() {
        return this.sharingRules?.length || 0;
    }

    get roleHierarchyCount() {
        return this.roleHierarchy?.length || 0;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    @track toggleStates = {
        recordtypes: false,
        objects: false,
        fields: false,
        systempermissions: false,
        sharingrules: false,
        rolehierarchy: false,
        loginhistory:false
    };

    handleToggleChange(event) {
        const toggleId = event.target.id;
        const isChecked = event.target.checked;
        
        // Update the corresponding property based on toggle ID
        switch(toggleId) {
            case 'recordTypesToggle':
                this.toggleStates.recordtypes = isChecked;
                if (isChecked && (!this.recordTypePermissions || this.recordTypePermissions.length === 0)) {
                    this.loadUserPermissions();
                }
                // Scroll to record types section if toggled on
                if (isChecked) {
                    this.scrollToSection('record-types-section');
                }
                break;
            case 'objectsToggle':
                this.toggleStates.objects = isChecked;
                if (isChecked && this.objectPermissions.length === 0) {
                    this.loadObjectPermissions();
                }
                // Scroll to objects section if toggled on
                if (isChecked) {
                    this.scrollToSection('objects-section');
                }
                break;
            case 'fieldsToggle':
                this.toggleStates.fields = isChecked;
                // Scroll to fields section if toggled on
                if (isChecked) {
                    this.scrollToSection('fields-section');
                }
                break;
            case 'systemPermissionsToggle':
                this.toggleStates.systempermissions = isChecked;
                if (isChecked && !this.systemPermissions.length) {
                    this.loadSystemPermissions();
                }
                // Scroll to system permissions section if toggled on
                if (isChecked) {
                    this.scrollToSection('system-permissions-section');
                }
                break;
            case 'sharingRulesToggle':
                this.toggleStates.sharingrules = isChecked;
                if (isChecked && (!this.sharingRules || this.sharingRules.length === 0)) {
                    this.loadSharingRules();
                }
                // Scroll to sharing rules section if toggled on
                if (isChecked) {
                    this.scrollToSection('sharing-rules-section');
                }
                break;
            case 'roleHierarchyToggle':
                this.toggleStates.rolehierarchy = isChecked;
                if (isChecked && (!this.roleHierarchy || this.roleHierarchy.length === 0)) {
                    this.loadRoleHierarchy();
                }
                // Scroll to role hierarchy section if toggled on
                if (isChecked) {
                    this.scrollToSection('role-hierarchy-section');
                }
                break;
            case 'loginHistoryToggle':
                this.toggleStates.loginhistory = isChecked;
                if (isChecked && (!this.loginhistory || this.loginhistory.length === 0)) {
                    this.loadLoginHistory();
                }
                // Scroll to login history section if toggled on
                if (isChecked) {
                    this.scrollToSection('login-history-section');
                }
                break;
        }
        
       // //console.log('Toggle state changed:', toggleId, isChecked);
    }

    // Helper method to scroll to a section
    scrollToSection(sectionId) {
        // Allow time for section to render if needed
        setTimeout(() => {
            const section = this.template.querySelector(`[data-id="${sectionId}"]`);
            if (section) {
                section.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        }, 100);
    }

    get showRecordTypes() { return this.toggleStates.recordtypes; }
    get showObjects() { return this.toggleStates.objects; }
    get showFields() { return this.toggleStates.fields; }
    get showSystemPermissions() { return this.toggleStates.systempermissions; }
    get showSharingRules() { return this.toggleStates.sharingrules; }
    get showRoleHierarchy() { return this.toggleStates.rolehierarchy; }
    get showLoginHistory() { return this.toggleStates.loginhistory; }

    showInfoMessage() {
        const infoMessage = 'Select the toggles below to view and manage different permission types';
        this.dispatchEvent(new ShowToastEvent({
            title: 'Information',
            message: infoMessage,
            variant: 'info'
        }));
    }

 

    get riskLevelVariant() {
        return (this.userDetails.riskLevel || '').toLowerCase();
    }

    // Add these getters
    get statusIcon() {
        return this.userDetails.isActive ? 'utility:success' : 'utility:error';
    }

    get statusLabel() {
        return this.userDetails.isActive ? 'Active' : 'Inactive';
    }

    get statusVariant() {
        return this.statusLabel === 'Active' ? 'success' : 'error';
    }

    // Add to class properties
    remediationActions = [
        { label: 'Revoke Permission Sets', value: 'revokePermissionSets' }
        /*,
        { label: 'Reset System Permissions', value: 'resetSystemPermissions' }*/
    ];
    selectedAction = 'revokePermissionSets';

    // Add after existing methods
    handleActionChange(event) {
        this.selectedAction = event.detail.value;
    }

    // Add to class properties
    showUndoButton = false;
    lastActionType = null;

    // Modify executeRemediation
    async executeRemediation() {
        this.isLoading = true;
        this.isInitialLoading = false;
        try {
            // Add null checks for critical parameters
            if(!this.selectedUserId || !this.selectedAction) {
                throw new Error('Missing required parameters for remediation');
            }

            // Explicit method calls instead of dynamic dispatch
            if(this.selectedAction === 'revokePermissionSets') {
                // We now use the modal for permission set selection
                // This method should not be called directly anymore for permission sets
                this.openRevokePermissionModal();
                this.isLoading = false;
                return;
            } else if(this.selectedAction === 'resetSystemPermissions') {
                await resetSystemPermissions({ userId: this.selectedUserId });
            } else {
                throw new Error('Invalid remediation action selected');
            }
            this.isLoading = false;
            this.showUndoButton = true;
            this.lastActionType = this.selectedAction;
            // Refresh data with error handling
           /* await Promise.allSettled([
                this.loadUserDetails(),
                this.loadSystemPermissions()
            ]);*/
            await this.refreshData();
            this.showToast('Success', 'Remediation completed successfully', 'success');
            this.isInitialLoading = false;
        } catch(error) {
            this.isLoading = false;
           // //console.error('Remediation error:', error);
            
            // Check if this is the specific undo permission error - we can still continue
            if (error.body && error.body.message && 
                (error.body.message.includes('Insufficient permissions for undo operation') ||
                 error.body.message.includes('PermissionSetUndoo__c'))) {
                
                // Show a more user-friendly message
                this.showToast(
                    'Warning', 
                    'Action completed successfully, but undo functionality is not available due to permission limitations.', 
                    'warning'
                );
                
                await this.refreshData();
            } else {
                // For other errors, show the error message
                this.showErrorToast('Failed', error.body?.message || error.message);
            }
        } finally {
            this.isLoading = false;
            this.isInitialLoading = false;
        }
    }

    // Add undo handler
    async handleUndo() {
        try {
            this.isLoading = true;
            
            if(this.lastActionType === 'revokePermissionSets') {
                await undoRevokePermissionSets({ userId: this.selectedUserId });
            } else if(this.lastActionType === 'resetSystemPermissions') {
                await undoResetSystemPermissions({ userId: this.selectedUserId });
            }
            
            this.showToast('Undo Successful', 'Previous action has been reverted', 'success');
            this.showUndoButton = false;
            await this.refreshData();
            
        } catch(error) {
          //  //console.error('Undo error:', error);
            
            // Check if this is the specific undo permission error
            if (error.body && error.body.message && 
                (error.body.message.includes('No undo records found') ||
                 error.body.message.includes('PermissionSetUndoo__c'))) {
                
                this.showToast(
                    'Warning', 
                    'Cannot undo previous action. Undo records not found or permission limitations exist.', 
                    'warning'
                );
                
                // Hide the undo button since undo is not possible
                this.showUndoButton = false;
            } else {
                this.showErrorToast('Undo Failed', error.body?.message || error.message);
            }
        } finally {
            this.isLoading = false;
        }
    }

    // Add new property for initial load
    @track isInitialLoading = false;

    get isInitialLoadingOrIsLoading() {
        return this.isInitialLoading || this.isLoading;
    }
    get showSearchWarning() {
        return this.searchTerm && this.totalObjectRecords >= 2000;
    }

    // Add data reset method
    async refreshData(clearPermissionTracking = true) {
        try {
            this.isLoading = true;
            ////console.log('Starting refreshData() to reload user data...');
            
            // Always clear the permission sets tracking during refresh to get fresh server data
            if (clearPermissionTracking) {
                this.revokedPermissionSets = new Set();
                this.grantedPermissionSets = new Set();
              //  //console.log('Cleared all permission sets tracking during refresh');
            }
            
            // Clear permission sets data before reloading it
            if (this.userDetails) {
               // //console.log('Clearing existing permission sets before refresh');
                this.userDetails.permissionSets = [];
            }
            
            // First load the user details to get fresh permission sets
            await this.loadUserDetails();
           // //console.log('After refresh loadUserDetails, permissionSets count:',  this.userDetails.permissionSets ? this.userDetails.permissionSets.length : 0);
            
            // Then load the rest of the data
            await Promise.all([
                this.loadRiskAnalysis(),
                this.loadObjectPermissions(),
                this.loadFieldPermissions(),
                this.loadSystemPermissions()
            ]);
            
            // Force UI update for permission sets
            this.userDetails = {...this.userDetails};
           //    //console.log('Refresh complete, permission sets updated');
        } catch(error) {
           // //console.error('Error in refreshData():', error);
            this.showErrorToast('Refresh Failed', error.body?.message || error.message);
        } finally {
            this.isLoading = false;
        }
    }

    // Improved error message handler
    getErrorMessage(error) {
        return error.body?.message || 
               error.message || 
               'Unknown error occurred while loading user data';
    }
     handleCopyCurrentPageToExcel() {
        try {
            // Get visible columns and their field names
            const columns = this.objectColumns.map(col => col.label);
            const fields = this.objectColumns.map(col => col.fieldName);

            // Create CSV/TSV content
            const csvContent = [
                columns.join('\t'), // Use tab separator for Excel
                ...this.filteredObjectPermissions.map(row => 
                    fields.map(field => {
                        // Handle nested objects (like links) and formatted values
                        const value = row[field];
                        return typeof value === 'object' ? 
                            (value.value || value.label || '') : 
                            (value || '');
                    }).join('\t')
                )
            ].join('\n');

            // Create temporary element for clipboard copy
            const textArea = document.createElement('textarea');
            textArea.value = csvContent;
            document.body.appendChild(textArea);
            textArea.select();
            
            // Execute copy command
            if (document.execCommand('copy')) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Current Page Data copied to clipboard - paste into Excel',
                    variant: 'success'
                }));
            } else {
                throw new Error('Clipboard copy failed');
            }
            
            document.body.removeChild(textArea);
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Copying Data',
                message: error.message,
                variant: 'error'
            }));
        }
    } 

        
    //copies all the data for objects permisions
    async handleCopyToExcel() {
        try {
            this.isLoading = true;
    
            // Fetch data
            const data = await getObjectPermissionsForUser({ 
                userId: this.selectedUserId 
            });
    
            // Update headers and data mapping to match ObjectPermissionWrapper
            const headers = [
                'Object', 'Read', 'Create', 'Edit', 'Delete',
                'Source Type', 'Source Name', 'Assigned By', 'Assignment Method'
            ];

            const csvContent = [
                headers.join(','),
                ...data.map(p => 
                    `"${p.objectName}",${p.canRead},${p.canCreate},${p.canEdit},${p.canDelete},` +
                    `"${p.sourceType}","${p.sourceName}","${p.assignedBy}","${p.assignmentMethod}"`
                )
            ].join('\r\n');
    
            // Create Blob with a generic MIME type
            const blob = new Blob([`\ufeff${csvContent}`], { type: 'application/octet-stream' });
    
            // Create download link
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = 'UserPermissions.csv';
            link.style.display = 'none';
    
            // Append link to the DOM in a Lightning-safe way
            const container = this.template.querySelector('.download-container') || document.body;
            container.appendChild(link);
    
            // Trigger the download
            link.click();
    
            // Clean up
            container.removeChild(link);
            URL.revokeObjectURL(link.href); // Release the object URL to free memory
    
            this.showToast('Success', 'CSV download started', 'success');
        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    

    get totalObjectPages() {
        return Math.ceil(this.allMergedObjects.size / this.itemsPerPageObjects);
    }

    get totalFieldPages() {
        return Math.ceil(this.fieldPageData.length / this.itemsPerPageFields);
    }

    // Add this property
    showGrantAccessModal = false;

    // Add this method
    async handleSuccess(event) {
        // Get the newly assigned permission sets from the event if available
        let newlyAssignedPermSets = event?.detail?.permissionSets || [];
        
        // Filter out any empty permission sets
        newlyAssignedPermSets = newlyAssignedPermSets.filter(ps => ps && ps.trim().length > 0);
        ////console.log('Newly assigned permission sets after filtering empty values:', newlyAssignedPermSets);
        
        // Close the modal first
        this.showGrantAccessModal = false;
        
        try {
            this.isLoading = true;
            
            // If we have newly assigned permission sets, add them to the UI immediately
            if (newlyAssignedPermSets.length > 0 && this.userDetails) {
               // //console.log('Adding newly assigned permission sets to UI:', newlyAssignedPermSets);
                
                // Add new permission sets to tracking and remove from revoked if present
                newlyAssignedPermSets.forEach(pset => {
                    this.grantedPermissionSets.add(pset);
                    this.revokedPermissionSets.delete(pset); // Remove from revoked if present
                });
                ////console.log('Updated grantedPermissionSets:', Array.from(this.grantedPermissionSets));
                
                // Add new permission sets to the existing ones if not already present
                const currentPermSets = new Set(this.userDetails.permissionSets || []);
                const newPermSets = [];
                
                newlyAssignedPermSets.forEach(pset => {
                    if (!currentPermSets.has(pset)) {
                        newPermSets.push(pset);
                    }
                });
                
                if (newPermSets.length > 0) {
                    this.userDetails.permissionSets = [
                        ...this.userDetails.permissionSets || [], 
                        ...newPermSets
                    ];
                    
                    // Force UI update
                    this.userDetails = {...this.userDetails};
                    ////console.log('Updated UI with new permission sets');
                }
            }
            
            // Refresh user data to ensure everything is up to date
            await this.refreshData();
            
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Permission assignments updated',
                variant: 'success'
            }));
        } catch (error) {
           // //console.error('Error refreshing data after granting access:', error);
            this.showErrorToast('Refresh Error', 'Failed to refresh data after updating permissions');
        } finally {
            this.isLoading = false;
        }
    }
    handleGrantAccess() {
        if(!this.selectedUserId) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please select a user first',
                variant: 'error'
            }));
            return;
        }
        this.showGrantAccessModal = true;
        
        // After showing the modal, scroll to it
        // Use setTimeout to ensure the modal is rendered before scrolling
        setTimeout(() => {
            this.scrollToSection('grant-access-modal-section');
        }, 100);
    }

    // Add modal handlers
    handleModalClose() {
        this.showGrantAccessModal = false;
    }

    handleModalError(event) {
        this.showToast('Error', event.detail.message, 'error');
    }


    
    @track showSchemaViewer = false;
    @track selectedSchemaObject = null;
    @track selectedSecondaryObjects = [];
    @track objectSchemaOptions = [];
    @track isSchemaFullScreen = false;
    @track isSchemaLoading = false;
    cytoscapeLib;
    cyInstance;
    toggleSchemaViewer() {
       // //console.log('Toggle Schema Viewer clicked');
        this.showSchemaViewer = !this.showSchemaViewer;
        
        if (this.showSchemaViewer) {
            // Clear any existing data
            this.schemaNodes = [];
            this.schemaEdges = [];
            this.selectedSecondaryObjects = [];
            
            // Show loading indicator
            this.isSchemaLoading = true;
            
            // Load Cytoscape library if not already loaded
            if (!this.cytoscapeLib) {
                this.loadCytoscapeLibrary();
            }
            
            // Populate object options if empty
            if (this.objectSchemaOptions.length === 0) {
                this.populateSchemaObjectOptions();
            } else {
                // If we already have options, just load the schema data
                if (this.selectedSchemaObject && this.cytoscapeLib) {
                    // Load data for the selected object
                    this.loadSchemaData();
                } else {
                    // No object selected or Cytoscape not loaded
                    this.isSchemaLoading = false;
                }
            }
        }
    }
    
    //second instance of the schema viewer

    @track showSchemaViewer = false;
    @track selectedSchemaObject = null;
    @track selectedSecondaryObjects = [];
    @track objectSchemaOptions = [];
    @track isSchemaFullScreen = false;
    @track isSchemaLoading = false;
    cytoscapeLib;
    cyInstance;
 

    loadCytoscapeLibrary() {
       // //console.log('Loading Cytoscape library...');
        
        // Add ResizeObserver polyfill for Lightning Web Components
        if (!window.ResizeObserver) {
            window.ResizeObserver = class ResizeObserver {
                constructor(callback) {
                    this.callback = callback;
                    this.observedElements = new Set();
                }
                
                observe(element) {
                    this.observedElements.add(element);
                    // Use a simple fallback with window resize
                    if (!this.windowResizeHandler) {
                        this.windowResizeHandler = () => {
                            this.observedElements.forEach(el => {
                                if (el && el.getBoundingClientRect) {
                                    const rect = el.getBoundingClientRect();
                                    this.callback([{
                                        target: el,
                                        contentRect: {
                                            width: rect.width,
                                            height: rect.height
                                        }
                                    }]);
                                }
                            });
                        };
                        window.addEventListener('resize', this.windowResizeHandler);
                    }
                }
                
                unobserve(element) {
                    this.observedElements.delete(element);
                }
                
                disconnect() {
                    this.observedElements.clear();
                    if (this.windowResizeHandler) {
                        window.removeEventListener('resize', this.windowResizeHandler);
                        this.windowResizeHandler = null;
                    }
                }
            };
        }
        
        loadScript(this, getCytoscape)
            .then(() => {
                // Try multiple ways to access cytoscape
                this.cytoscapeLib = window.cytoscape || globalThis?.cytoscape;
                
                if (!this.cytoscapeLib) {
                    throw new Error('Cytoscape library not found after loading');
                }
                
               // //console.log('✓ Cytoscape library loaded successfully');
                
                // If we have schema data, render the graph
                if (this.schemaNodes && this.schemaNodes.length > 0 && this.showSchemaViewer) {
                    this.renderSchemaGraph();
                } else if (this.selectedSchemaObject && this.showSchemaViewer) {
                    // If we have a selected object but no data, load the data
                    this.loadSchemaData();
                } else {
                    // No data to render
                    this.isSchemaLoading = false;
                }
            })
            .catch(error => {
               // //console.error('✗ Error loading Cytoscape library:', error);
                this.showToast('Error', 'Failed to load visualization library', 'error');
                this.isSchemaLoading = false;
            });
    }

    populateSchemaObjectOptions() {
       // //console.log('Populating schema object options...');
        this.isSchemaLoading = true;
        
        // Get all objects dynamically
        getAllObjects()
            .then(result => {
                if (result && result.length > 0) {
                   // //console.log(`Found ${result.length} objects from server`);
                    
                    // Map the results to the format expected by the combobox
                    this.objectSchemaOptions = result.map(obj => ({
                        label: obj.label,
                        value: obj.name
                    }));
                    
                   // //console.log(`✓ Populated ${this.objectSchemaOptions.length} schema object options`);
                   // //console.log('First 5 objects:', JSON.stringify(this.objectSchemaOptions.slice(0, 5)));
                    
                    // Set default selected object if not already set
                    if (this.objectSchemaOptions.length > 0 && !this.selectedSchemaObject) {
                        this.selectedSchemaObject = this.objectSchemaOptions[0].value;
                       // //console.log(`Default selected object: ${this.selectedSchemaObject}`);
                    }
                } else {
                   // //console.error('No objects returned from server');
                    this.showToast('Error', 'Failed to load object options', 'error');
                }
            })
            .catch(error => {
               // //console.error('Error loading schema objects:', error);
                this.showToast('Error', 'Failed to load schema objects', 'error');
            })
            .finally(() => {
                this.isSchemaLoading = false;
            });
    }

    // Add debouncing properties
    schemaChangeTimeout;
    nodeClickTimeout;

    handleSchemaObjectChange(event) {
        // Clear any existing timeout to debounce rapid changes
        if (this.schemaChangeTimeout) {
            clearTimeout(this.schemaChangeTimeout);
        }

        // Set loading state immediately for better UX
        this.isSchemaLoading = true;
        
        // Debounce the actual processing to prevent rapid successive calls
        this.schemaChangeTimeout = setTimeout(() => {
            try {
                this.selectedSchemaObject = event.detail.value;
                
                // Reset hide/show state
                this.hideUnrelatedNodes = false;
                this.selectedNodeForFiltering = null;
                
                // Load schema data for the selected object
                if (this.selectedSchemaObject) {
                    this.loadSchemaData();
                } else {
                    this.schemaNodes = [];
                    this.schemaEdges = [];
                    this.isSchemaLoading = false;
                }
            } catch (error) {
                console.error('Error in handleSchemaObjectChange:', error);
                this.isSchemaLoading = false;
                this.showToast('Error', 'Failed to process schema object selection', 'error');
            }
        }, 300); // 300ms debounce delay
    }

    // Add sanitization utility method to prevent XSS
    sanitizeHtml(text) {
        if (text === null || text === undefined) return '';
        return String(text)
            .replace(/&/gu, '&amp;')
            .replace(/</gu, '&lt;')
            .replace(/>/gu, '&gt;')
            .replace(/"/gu, '&quot;')
            .replace(/'/gu, '&#039;');
    }

    // Validate node data to prevent security issues
    validateNodeData(node) {
        if (!node || typeof node !== 'object') return false;
        if (!node.name || typeof node.name !== 'string') return false;
        return true;
    }

    // Validate edge data to prevent security issues
    validateEdgeData(edge) {
        if (!edge || typeof edge !== 'object') return false;
        if (!edge.source || !edge.target) return false;
        return true;
    }

    // Process nodes asynchronously to prevent UI blocking
    async processNodesAsync(validNodes) {
        return new Promise((resolve) => {
            const result = [];
            let currentIndex = 0;
            const chunkSize = 10;
            
            const processChunk = () => {
                const endIndex = Math.min(currentIndex + chunkSize, validNodes.length);
                
                for (let i = currentIndex; i < endIndex; i++) {
                    const node = validNodes[i];
                    result.push({
                        data: {
                            id: this.sanitizeHtml(node.name),
                            label: this.sanitizeHtml(node.label || node.name),
                            isPrimary: node.name === this.selectedSchemaObject,
                            isSecondary: this.selectedSecondaryObjects.includes(node.name),
                            isStandard: !node.name.endsWith('__c'),
                            isCustom: node.name.endsWith('__c'),
                            // Simplified permissions - only basic CRUD to reduce processing overhead
                            permissions: {
                                read: !!(node.permissions?.read),
                                create: !!(node.permissions?.create),
                                edit: !!(node.permissions?.edit),
                                delete: !!(node.permissions?.delete)
                            },
                            accessLevel: this.getAccessLevel(node.permissions),
                            apiName: this.sanitizeHtml(node.name)  
                        }
                    });
                }
                
                currentIndex = endIndex;
                
                if (currentIndex < validNodes.length) {
                    // Process next chunk in next frame
                    requestAnimationFrame(processChunk);
                } else {
                    resolve(result);
                }
            };
            
            processChunk();
        });
    }

    // Process edges asynchronously to prevent UI blocking
    async processEdgesAsync(validEdges) {
        return new Promise((resolve) => {
            const result = [];
            let currentIndex = 0;
            const chunkSize = 10;
            
            const processChunk = () => {
                const endIndex = Math.min(currentIndex + chunkSize, validEdges.length);
                
                for (let i = currentIndex; i < endIndex; i++) {
                    const edge = validEdges[i];
                    // Sanitize relationship fields
                    const relationshipFields = Array.isArray(edge.fields) 
                        ? edge.fields.map(field => this.sanitizeHtml(field))
                        : [];
                    
                    result.push({
                        data: {
                            id: `${this.sanitizeHtml(edge.source)}_${this.sanitizeHtml(edge.target)}_${this.sanitizeHtml(edge.relationshipName || 'relationship')}`,
                            source: this.sanitizeHtml(edge.source),
                            target: this.sanitizeHtml(edge.target),
                            relationshipName: this.sanitizeHtml(edge.relationshipName || 'Relationship'),
                            relationshipType: this.sanitizeHtml(edge.relationshipType || 'Lookup'),
                            relationshipFields: relationshipFields,
                            label: this.sanitizeHtml(edge.relationshipName || 'relates to'),
                            isPrimaryRelationship: (
                                (edge.source === this.selectedSchemaObject || this.selectedSecondaryObjects.includes(edge.source)) &&
                                (edge.target === this.selectedSchemaObject || this.selectedSecondaryObjects.includes(edge.target))
                            )
                        }
                    });
                }
                
                currentIndex = endIndex;
                
                if (currentIndex < validEdges.length) {
                    // Process next chunk in next frame
                    requestAnimationFrame(processChunk);
                } else {
                    resolve(result);
                }
            };
            
            processChunk();
        });
    }

    //render graph code 
    async renderSchemaGraph() {
        try {
           // //console.log('Rendering schema graph with nodes:', this.schemaNodes?.length, 'and edges:', this.schemaEdges?.length);
            
            // Clean up previous instance
            if (this.cyInstance) {
                try {
                    this.cyInstance.destroy();
                    this.cyInstance = null;
                } catch (e) {
                   // //console.error('Error cleaning up Cytoscape instance');
                }
            }
            
            const container = this.template.querySelector('.cy-container');
            if (!container) {
               // //console.error('Cytoscape container not found');
                this.isSchemaLoading = false;
                return;
            }
            
            // Early return if no data to prevent unnecessary processing
            if (!this.schemaNodes || this.schemaNodes.length === 0) {
                this.isSchemaLoading = false;
                return;
            }
            
            // Validate nodes and filter out invalid ones
            const validNodes = Array.isArray(this.schemaNodes) 
                ? this.schemaNodes.filter(node => this.validateNodeData(node))
                : [];
                
            if (validNodes.length !== (this.schemaNodes?.length || 0)) {
               // console.warn(`Filtered out ${(this.schemaNodes?.length || 0) - validNodes.length} invalid nodes`);
            }
            
            // Validate edges and filter out invalid ones
            const validEdges = Array.isArray(this.schemaEdges)
                ? this.schemaEdges.filter(edge => this.validateEdgeData(edge))
                : [];
                
            if (validEdges.length !== (this.schemaEdges?.length || 0)) {
               // console.warn(`Filtered out ${(this.schemaEdges?.length || 0) - validEdges.length} invalid edges`);
            }
            
            // Use requestAnimationFrame to break up heavy processing and prevent UI blocking
            const nodeElements = await this.processNodesAsync(validNodes);
            const edgeElements = await this.processEdgesAsync(validEdges);
            
            
            if (this.selectedSecondaryObjects && this.selectedSecondaryObjects.length > 0) {
                if (this.selectedSecondaryObjects.length > 3) {
                  
                    this.selectedLayout = 'concentric';
                } else if (this.selectedSecondaryObjects.length > 1) {
                  
                    this.selectedLayout = 'cose';
                } else {
                   
                    this.selectedLayout = 'grid';
                }
               // //console.log(`Selected layout: ${this.selectedLayout} based on ${this.selectedSecondaryObjects.length} secondary objects`);
            }
            
           
            const layoutConfig = {
                name: this.selectedLayout || 'concentric',
                fit: true,
                padding: 50,
                animate: true,
                animationDuration: 500,
                spacingFactor: 1.5,
                nodeDimensionsIncludeLabels: true
            };
            
           
            if (layoutConfig.name === 'concentric') {
                layoutConfig.minNodeSpacing = 50;
                layoutConfig.concentric = (node) => {
                    if (node.data('isPrimary')) return 3;
                    if (node.data('isSecondary')) return 2;
                    return 1;
                };
                layoutConfig.levelWidth = () => 1;
            } else if (layoutConfig.name === 'breadthfirst') {
                layoutConfig.directed = true;
                layoutConfig.roots = [`#${this.selectedSchemaObject}`];
            } else if (layoutConfig.name === 'grid') {
                layoutConfig.rows = Math.ceil(Math.sqrt(nodeElements.length));
            }
            
            
            // Check if cytoscapeLib is available
            if (!this.cytoscapeLib) {
                throw new Error('Cytoscape library not loaded');
            }
            
            this.cyInstance = this.cytoscapeLib({
                container: container,
                elements: {
                    nodes: nodeElements,
                    edges: edgeElements
                },
                style: [
                    {
                        selector: 'node',
                        style: {
                            
                            'label': 'data(label)',
                            'text-valign': 'center',
                            'text-halign': 'center',
                            'background-color': (ele) => {
                                if (ele.data('isPrimary')) return '#EA4335';
                                if (ele.data('isSecondary')) return '#673AB7';
                                return '#032D60';
                            },
                            'text-wrap': 'ellipsis',
                            'text-max-width': '80px',
                            'font-size': '10px',
                            'color': '#FFFFFF',
                            'text-outline-width': 1,
                            'text-outline-color': '#000000',
                            'text-outline-opacity': 0.5,
                            'border-width': 2,
                            'border-color': '#FFFFFF',
                            'width': 80,
                            'height': 80,
                            'text-margin-y': 0,
                            'text-overflow-wrap': 'anywhere',
                            'cursor': 'pointer'
                        }
                    },
                    {
                        selector: 'edge',
                        style: {
                            'width': 2,
                            'line-color': (ele) => {
                                if (ele.data('relationshipType') === 'Master-Detail') return '#E53935';
                                return '#4285F4';
                            },
                            'target-arrow-color': (ele) => {
                                if (ele.data('relationshipType') === 'Master-Detail') return '#E53935';
                                return '#4285F4';
                            },
                            'target-arrow-shape': 'triangle',
                            'curve-style': 'bezier',
                            'line-style': (ele) => {
                                if (ele.data('relationshipType') === 'Master-Detail') return 'solid';
                                return 'dashed';
                            },
                            'label': 'data(label)',
                            'font-size': '10px',
                            'text-rotation': 'autorotate',
                            'text-background-color': '#FFFFFF',
                            'text-background-opacity': 0.9,
                            'text-background-padding': '3px',
                            'text-background-shape': 'roundrectangle',
                            'cursor': 'pointer'
                        }
                    },
                    {
                        selector: 'edge[isPrimaryRelationship]',
                        style: {
                            'width': 3,
                            'line-color': '#FF5722',
                            'target-arrow-color': '#FF5722',
                            'z-index': 999
                        }
                    },
                    {
                        selector: 'node:selected',
                        style: {
                            'border-width': 3,
                            'border-color': '#FFEB3B',
                            'border-opacity': 1,
                            'background-opacity': 1,
                            'text-outline-width': 2,
                            'z-index': 9999
                        }
                    },
                    {
                        selector: 'edge:selected',
                        style: {
                            'width': 4,
                            'line-color': '#FFEB3B',
                            'target-arrow-color': '#FFEB3B',
                            'z-index': 9999
                        }
                    },
                    {
                        selector: '.hidden',
                        style: {
                            'opacity': 0.2,
                            'z-index': 1
                        }
                    }
                ],
                layout: layoutConfig,
                wheelSensitivity: 0.2,
                minZoom: 0.5,
                maxZoom: 2.0,
                boxSelectionEnabled: false
            });
            
            // Simplified node tap event - minimal processing only
            this.cyInstance.on('tap', 'node', (event) => {
                try {
                    const node = event.target;
                    if (!node) return;
                    
                    // Only do basic highlighting - no heavy processing
                    this.highlightConnectedElements(node);
                    
                    // Show node info with basic permission data
                    const nodeData = node.data();
                    if (nodeData && nodeData.id) {
                        this.selectedNodeData = {
                            id: nodeData.id,
                            label: nodeData.label || nodeData.id,
                            apiName: nodeData.apiName || nodeData.id,
                            isPrimary: nodeData.isPrimary || false,
                            isSecondary: nodeData.isSecondary || false,
                            permissions: {
                                read: !!(nodeData.permissions?.read),
                                create: !!(nodeData.permissions?.create),
                                edit: !!(nodeData.permissions?.edit),
                                delete: !!(nodeData.permissions?.delete),
                                sources: []
                            }
                        };
                        this.isPermissionModalOpen = true;
                        
                        // Load detailed permission sources asynchronously after modal opens
                        if (this.selectedUserId && nodeData.apiName) {
                            this.loadPermissionSourcesOnDemand();
                        }
                    }
                } catch (error) {
                    console.error('Error handling node tap:', error);
                }
            });
            
            // Add edge tap event with async processing
            this.cyInstance.on('tap', 'edge', (event) => {
                try {
                    const edge = event.target;
                    if (!edge) return;
                    
                    // Process edge details asynchronously to prevent UI blocking
                    requestAnimationFrame(() => {
                        const edgeData = edge.data();
                        if (edgeData && typeof edgeData === 'object') {
                            this.showRelationshipDetails(edgeData);
                        }
                    });
                } catch (error) {
                    //console.error('Error handling edge tap event:', error);
                }
            });
            
            // Add background tap event to reset highlighting with async processing
            this.cyInstance.on('tap', (event) => {
                try {
                    if (event.target === this.cyInstance) {
                        // Use requestAnimationFrame to prevent UI blocking
                        requestAnimationFrame(() => {
                            this.resetHighlighting();
                        });
                    }
                } catch (error) {
                    //console.error('Error handling background tap event:', error);
                }
            });
            
           // //console.log('Using layout:', layoutConfig.name);
            
            // Set loading to false after successful rendering
            this.isSchemaLoading = false;
            
        } catch (error) {
            // Generic error message to avoid exposing sensitive information
           // //console.error('Error rendering schema graph');
            this.showToast('Error', 'Failed to render schema graph', 'error');
            this.isSchemaLoading = false;
        }
    }

    highlightConnectedElements(node) {
        try {
            if (!this.cyInstance || !node) return;
            
            // Minimal highlighting - just the selected node
            this.cyInstance.batch(() => {
                // Reset all highlighting first
                this.cyInstance.elements().removeClass('highlighted faded');
                
                // Only highlight the selected node
                node.addClass('highlighted');
            });
        } catch (error) {
            console.error('Error highlighting node:', error);
        }
    }

    resetHighlighting() {
        try {
            if (!this.cyInstance) return;
            
            // If hide unrelated nodes is active, don't reset highlighting
            if (this.hideUnrelatedNodes) return;
            
            // Batch remove all visual classes for better performance
            this.cyInstance.batch(() => {
                this.cyInstance.elements().removeClass('highlighted faded');
            });
        } catch (error) {
           // //console.error('Error resetting highlighting:', error);
        }
    }

    // Helper methods for permissions
    getAccessLevel(permissions) {
        try {
            if (!permissions || typeof permissions !== 'object') return 'none';
            
            if (permissions.delete === true) return 'full';
            if (permissions.edit === true) return 'edit';
            if (permissions.read === true) return 'read';
            return 'none';
        } catch (error) {
           // //console.error('Error getting access level:', error);
            return 'none';
        }
    }

    getPermissionSources(permissions) {
        try {
            if (!permissions || !permissions.sources) return '';
            
            // Ensure sources is an array
            const sources = Array.isArray(permissions.sources) ? permissions.sources : [];
            
            if (sources.length === 0) return 'No access';
            
            return sources.map(source => {
                // Handle case where source might not be an object
                if (typeof source !== 'object' || source === null) {
                    return 'Unknown source';
                }
                return `${source.type || 'Unknown'}: ${source.name || 'Unknown'}`;
            }).join(', ');
        } catch (error) {
           // //console.error('Error getting permission sources:', error);
            return 'Error retrieving sources';
        }
    }

    // Show permission details in a modal - simplified approach for better performance
    showPermissionDetails(nodeData) {
        try {
            // Validate nodeData before processing
            if (!nodeData || typeof nodeData !== 'object') {
                return;
            }
            
            // Simplified data structure - minimal processing
            const sanitizedNodeData = {
                id: nodeData.id || '',
                label: nodeData.label || nodeData.id || '',
                apiName: nodeData.apiName || nodeData.id || '',
                isPrimary: !!nodeData.isPrimary,
                isSecondary: !!nodeData.isSecondary,
                isStandard: !!nodeData.isStandard,
                isCustom: !!nodeData.isCustom,
                permissions: {
                    read: !!(nodeData.permissions?.read),
                    create: !!(nodeData.permissions?.create),
                    edit: !!(nodeData.permissions?.edit),
                    delete: !!(nodeData.permissions?.delete),
                    // Lazy load sources only when modal is opened
                    sources: []
                }
            };
            
            // Only sanitize sources if they exist and will be displayed
            if (nodeData.permissions?.sources && nodeData.permissions.sources.length > 0) {
                sanitizedNodeData.permissions.sources = nodeData.permissions.sources.map(source => {
                    // Handle case where source might not be an object
                    if (typeof source !== 'object' || source === null) {
                        return { type: '', name: '' };
                    }
                    return {
                        type: source.type || '',
                        name: source.name || ''
                    };
                });
            }
            
            this.selectedNodeData = sanitizedNodeData;
            this.isPermissionModalOpen = true;
        } catch (error) {
            this.showToast('Error', 'Failed to show object details. Please try again.', 'error');
        }
    }

    closePermissionModal() {
        this.isPermissionModalOpen = false;
    }

    get hasPermissionSources() {
        return this.selectedNodeData && this.selectedNodeData.permissions && this.selectedNodeData.permissions.sources && this.selectedNodeData.permissions.sources.length > 0;
    }

    get permissionSources() {
        // Return the actual permission sources from selectedNodeData
        if (this.selectedNodeData && this.selectedNodeData.permissions && this.selectedNodeData.permissions.sources) {
            return this.selectedNodeData.permissions.sources.map((source, index) => {
                return {
                    key: `source-${index}`,
                    type: source.sourceType || 'Unknown',
                    name: source.sourceName || 'Unknown Source',
                    typeIcon: this.getSourceTypeIcon(source.sourceType),
                    assignedBy: source.assignedBy || 'Unknown',
                    assignmentMethod: source.assignmentMethod || 'Unknown',
                    canRead: source.canRead,
                    canCreate: source.canCreate,
                    canEdit: source.canEdit,
                    canDelete: source.canDelete,
                    readIcon: source.canRead ? 'utility:check' : 'utility:close',
                    readVariant: source.canRead ? 'success' : 'error',
                    createIcon: source.canCreate ? 'utility:check' : 'utility:close',
                    createVariant: source.canCreate ? 'success' : 'error',
                    editIcon: source.canEdit ? 'utility:check' : 'utility:close',
                    editVariant: source.canEdit ? 'success' : 'error',
                    deleteIcon: source.canDelete ? 'utility:check' : 'utility:close',
                    deleteVariant: source.canDelete ? 'success' : 'error'
                };
            });
        }
        return [];
    }
    
    getSourceTypeIcon(sourceType) {
        switch(sourceType) {
            case 'Profile':
                return 'standard:user';
            case 'Permission Set':
                return 'utility:key';
            case 'Package':
                return 'utility:package';
            default:
                return 'utility:lock';
        }
    }
    
    // Alternative method to load permission sources on demand
    async loadPermissionSourcesOnDemand() {
        if (!this.selectedNodeData?.apiName || !this.selectedUserId) {
            console.log('Missing data for permission sources:', {
                apiName: this.selectedNodeData?.apiName,
                userId: this.selectedUserId
            });
            return;
        }
        
        try {
            console.log('Loading permission sources for:', {
                userId: this.selectedUserId,
                objectName: this.selectedNodeData.apiName
            });
            
            // Only load detailed permission sources when explicitly requested
            const sources = await getObjectPermissionSources({
                userId: this.selectedUserId,
                objectName: this.selectedNodeData.apiName
            });
            
            console.log('Received permission sources:', sources);
            
            // Update the selected node data with loaded sources
            if (this.selectedNodeData && this.selectedNodeData.permissions) {
                // Force reactivity by creating a new object reference
                this.selectedNodeData = {
                    ...this.selectedNodeData,
                    permissions: {
                        ...this.selectedNodeData.permissions,
                        sources: sources || []
                    }
                };
                console.log('Updated selectedNodeData with sources:', this.selectedNodeData.permissions.sources);
            }
        } catch (error) {
            console.error('Error loading permission sources:', error);
        }
    }

    // Add zoom controls to the graph
    addZoomControls() {
        // Add buttons to the DOM
        const container = this.template.querySelector('.schema-controls');
        if (!container) return;
        
        // Clear existing controls
        while (container.firstChild) {
            container.removeChild(container.firstChild);
        }
        
        // Create zoom in button
        const zoomInBtn = document.createElement('button');
        zoomInBtn.className = 'slds-button slds-button_icon';
        zoomInBtn.innerHTML = '<svg class="slds-button__icon" aria-hidden="true"><use xlink:href="/assets/icons/utility-sprite/svg/symbols.svg#add"></use></svg>';
        zoomInBtn.title = 'Zoom In';
        zoomInBtn.onclick = () => this.cyInstance.zoom({ level: this.cyInstance.zoom() * 1.2 });
        
        // Create zoom out button
        const zoomOutBtn = document.createElement('button');
        zoomOutBtn.className = 'slds-button slds-button_icon';
        zoomOutBtn.innerHTML = '<svg class="slds-button__icon" aria-hidden="true"><use xlink:href="/assets/icons/utility-sprite/svg/symbols.svg#dash"></use></svg>';
        zoomOutBtn.title = 'Zoom Out';
        zoomOutBtn.onclick = () => this.cyInstance.zoom({ level: this.cyInstance.zoom() * 0.8 });
        
        // Create fit button
        const fitBtn = document.createElement('button');
        fitBtn.className = 'slds-button slds-button_icon';
        fitBtn.innerHTML = '<svg class="slds-button__icon" aria-hidden="true"><use xlink:href="/assets/icons/utility-sprite/svg/symbols.svg#fit_to_width"></use></svg>';
        fitBtn.title = 'Fit to View';
        fitBtn.onclick = () => this.cyInstance.fit();
        
        // Add buttons to container
        container.appendChild(zoomInBtn);
        container.appendChild(zoomOutBtn);
        container.appendChild(fitBtn);
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        if (action.name === 'view_schema') {
            this.selectedSchemaObject = row.SobjectType;
            this.showSchemaViewer = true;
            this.loadSchemaData();
        }
    }

    // Add these properties
    @track selectedLayout = 'breadthfirst';
    get layoutOptions() {
        return [
            { label: 'Force-Directed', value: 'cose' },
            { label: 'Grid', value: 'grid' },
            { label: 'Circle', value: 'circle' },
            { label: 'Concentric', value: 'concentric' },
            { label: 'Breadth-First', value: 'breadthfirst' }
        ];
    }

    // Update the layout change handler
    handleLayoutChange(event) {
        this.selectedLayout = event.detail.value;
        
        // Reset hide/show state
        this.hideUnrelatedNodes = false;
        this.selectedNodeForFiltering = null;
        
        // Re-render the graph with the new layout
        if (this.schemaNodes && this.schemaNodes.length > 0) {
            this.renderSchemaGraph();
        }
    }

    // Add these properties
    @track showAccessibleObjectsOnly = false;

    // Add these methods
    showAllObjects() {
        this.showAccessibleObjectsOnly = false;
        this.loadSchemaData();
    }

    showAccessibleOnly() {
        this.showAccessibleObjectsOnly = true;
        this.loadSchemaData();
    }

    get allObjectsVariant() {
        return this.showAccessibleObjectsOnly ? 'neutral' : 'brand';
    }

    get accessibleObjectsVariant() {
        return this.showAccessibleObjectsOnly ? 'brand' : 'neutral';
    }

    get fullScreenIcon() {
        return this.isSchemaFullScreen ? 'utility:contract_alt' : 'utility:expand_alt';
    }

    get fullScreenButtonLabel() {
        return this.isSchemaFullScreen ? 'Exit Fullscreen' : 'Fullscreen';
    }

    @track isPermissionModalOpen = false;
    @track selectedNodeData = {
        label: '',
        permissions: {
            read: false,
            create: false,
            edit: false,
            delete: false,
            sources: []
        }
    };

    @wire(getSchemaDataWithPermissions, { 
        objectName: '$selectedSchemaObject',
        userId: '$selectedUserId',
        loadRelatedObjects: true
    })
    async wiredSchemaData({ error, data }) {
        if (data) {
           // //console.log('Wired schema data received');
            this.schemaNodes = data.nodes || [];
            this.schemaEdges = data.edges || [];
            
            // Render the graph if Cytoscape is loaded and we're viewing the schema
            if (this.cytoscapeLib && this.showSchemaViewer) {
                await this.renderSchemaGraph();
            } else {
                this.isSchemaLoading = false;
            }
        } else if (error) {
           // //console.error('Error loading schema data:', error);
            this.isSchemaLoading = false;
            this.showToast('Error', 'Failed to load schema data', 'error');
        }
    }

    async loadSchemaData() {
        if (!this.selectedSchemaObject || !this.cytoscapeLib || !this.selectedUserId) {
            this.isSchemaLoading = false;
            return;
        }
        
        this.isSchemaLoading = true;
        
        // no secondary objects are selected, load the primary object
        if (!this.selectedSecondaryObjects || this.selectedSecondaryObjects.length === 0) {
            // Load data for the selected object
            getSchemaDataWithPermissions({ 
                objectName: this.selectedSchemaObject,
                userId: this.selectedUserId,
                loadRelatedObjects: true
            })
            .then(async result => {
                if (result) {
                    this.schemaNodes = result.nodes || [];
                    this.schemaEdges = result.edges || [];
                    
                    if (this.cytoscapeLib && this.showSchemaViewer) {
                        await this.renderSchemaGraph();
                    } else {
                        this.isSchemaLoading = false;
                    }
                }
            })
            .catch(error => {
               // //console.error('Error loading schema data:', error);
                let errorMessage = 'Failed to load schema data';
                
                // Check for specific error types
                if (error.body && error.body.message) {
                    if (error.body.message.includes('CPU time limit exceeded')) {
                        errorMessage = 'The server took too long to process this request. Try selecting fewer objects.';
                    } else {
                        errorMessage = error.body.message;
                    }
                }
                
                this.showToast('Error', errorMessage, 'error');
                this.isSchemaLoading = false;
            });
        } else {
            // Check count of objects are selected
            if (this.selectedSecondaryObjects.length > 10) {
                this.showToast(
                    'Too Many Objects', 
                    'You have selected more than 10 objects, which may cause performance issues. Try selecting fewer objects.',
                    'warning'
                );
            }
            
            // Load data for primary and all selected secondary objects
            getSchemaDataWithMultipleSecondaryObjects({
                primaryObjectName: this.selectedSchemaObject,
                secondaryObjectNames: this.selectedSecondaryObjects,
                userId: this.selectedUserId
            })
            .then(async result => {
                if (result) {
                   // //console.log('Schema data received for multiple objects');
                    this.schemaNodes = result.nodes || [];
                    this.schemaEdges = result.edges || [];
                    
                    if (this.cytoscapeLib && this.showSchemaViewer) {
                        await this.renderSchemaGraph();
                    } else {
                        this.isSchemaLoading = false;
                    }
                }
            })
            .catch(error => {
               // //console.error('Error loading schema data for multiple objects:', error);
                let errorMessage = 'Failed to load schema data for multiple objects';
                
                // Check for specific error types
                if (error.body && error.body.message) {
                    if (error.body.message.includes('CPU time limit exceeded')) {
                        errorMessage = 'The server took too long to process this request. Try selecting fewer objects or use the "Custom" option instead.';
                    } else {
                        errorMessage = error.body.message;
                    }
                }
                
                this.showToast('Error', errorMessage, 'error');
                this.isSchemaLoading = false;
                
                // Clear the secondary object selection if we hit a CPU timeout
                if (error.body && error.body.message && error.body.message.includes('CPU time limit exceeded')) {
                    this.unselectAllOptions();
                }
            });
        }
    }
     // Add these getters for the permission icons and statuses
    get objectLabel() {
        return this.selectedNodeData?.label || 'Object';
    }

    // Read permission getters
    get readIconName() {
        return this.selectedNodeData?.permissions?.read ? 'utility:check' : 'utility:close';
    }

    get readVariant() {
        return this.selectedNodeData?.permissions?.read ? 'success' : 'error';
    }

    get readStatus() {
        return this.selectedNodeData?.permissions?.read ? 'Allowed' : 'Not Allowed';
    }

    // Create permission getters
    get createIconName() {
        return this.selectedNodeData?.permissions?.create ? 'utility:check' : 'utility:close';
    }

    get createVariant() {
        return this.selectedNodeData?.permissions?.create ? 'success' : 'error';
    }

    get createStatus() {
        return this.selectedNodeData?.permissions?.create ? 'Allowed' : 'Not Allowed';
    }

    // Edit permission getters
    get editIconName() {
        return this.selectedNodeData?.permissions?.edit ? 'utility:check' : 'utility:close';
    }

    get editVariant() {
        return this.selectedNodeData?.permissions?.edit ? 'success' : 'error';
    }

    get editStatus() {
        return this.selectedNodeData?.permissions?.edit ? 'Allowed' : 'Not Allowed';
    }

    // Delete permission getters
    get deleteIconName() {
        return this.selectedNodeData?.permissions?.delete ? 'utility:check' : 'utility:close';
    }

    get deleteVariant() {
        return this.selectedNodeData?.permissions?.delete ? 'success' : 'error';
    }

    get deleteStatus() {
        return this.selectedNodeData?.permissions?.delete ? 'Allowed' : 'Not Allowed';
    }

    

    // Add these properties
    @track secondarySchemaObject;
    @track filterActive = {
        selected: false,
        full: false,
        edit: false,
        read: false,
        none: false
    };

    // Add these methods for filtering
    filterByAccessLevel(event) {
        const accessLevel = event.currentTarget.dataset.filter;
        this.filterActive = {
            selected: false,
            full: false,
            edit: false,
            read: false,
            none: false
        };
        this.filterActive[accessLevel] = true;
        
        if (this.cyInstance) {
            // Show all nodes and edges first
            this.cyInstance.elements().style('display', 'element');
            
            // Hide nodes that don't match the filter
            this.cyInstance.nodes().filter(node => 
                node.data('accessLevel') !== accessLevel
            ).style('display', 'none');
            
            // Hide edges connected to hidden nodes
            this.cyInstance.edges().filter(edge => 
                this.cyInstance.getElementById(edge.data('source')).style('display') === 'none' || 
                this.cyInstance.getElementById(edge.data('target')).style('display') === 'none'
            ).style('display', 'none');
            
            // Fit the visible elements
            this.cyInstance.fit();
        }
    }

    filterBySelectedObject(event) {
        this.filterActive = {
            selected: true,
            full: false,
            edit: false,
            read: false,
            none: false
        };
        
        if (this.cyInstance) {
            // Show all nodes and edges first
            this.cyInstance.elements().style('display', 'element');
            
            // Get the selected node
            const selectedNode = this.cyInstance.nodes().filter(node => node.data('isPrimary'));
            
            // Hide nodes that aren't the selected node or its neighbors
            this.cyInstance.nodes().filter(node => 
                !node.data('isPrimary') && !selectedNode.neighborhood().contains(node)
            ).style('display', 'none');
            
            // Hide edges not connected to the selected node
            this.cyInstance.edges().filter(edge => 
                !selectedNode.connectedEdges().contains(edge)
            ).style('display', 'none');
            
            // Fit the visible elements
            this.cyInstance.fit();
        }
    }

    clearFilters() {
        this.filterActive = {
            selected: false,
            full: false,
            edit: false,
            read: false,
            none: false
        };
        
        if (this.cyInstance) {
            // Show all nodes and edges
            this.cyInstance.elements().style('display', 'element');
            
            // Fit the visible elements
            this.cyInstance.fit();
        }
    }

    // Handle multi-select for secondary objects using the custom multi-select picklist
    handleSecondaryObjectsMultiChange(event) {
        try {
           // //console.log('Secondary objects selection changed');
            const selectElement = event.target;
            const selectedOptions = [];
            
            // Get all selected options from the multi-select
            for (let i = 0; i < selectElement.options.length; i++) {
                if (selectElement.options[i].selected) {
                    selectedOptions.push(selectElement.options[i].value);
                }
            }
            
            this.selectedSecondaryObjects = selectedOptions;
           // //console.log('Selected secondary objects:', JSON.stringify(this.selectedSecondaryObjects));
            
            // ONLY proceed if primary object is selected
            if (!this.selectedSchemaObject) {
               // //console.log('Not processing - missing primary object');
                return; // Exit early if primary object is not selected
            }
            
            // Use the loadSchemaData method to refresh the schema
            this.loadSchemaData();
        } catch (error) {
           // //console.error('Error in handleSecondaryObjectsMultiChange:', error);
            this.showToast('Error', 'An error occurred processing the selection', 'error');
            this.isSchemaLoading = false;
        }
    }
    
    // Select all options in the multi-select
    selectAllOptions() {
        try {
           // //console.log('Selecting all options');
            const selectElement = this.template.querySelector('.secondary-object-list');
            if (selectElement) {
                for (let i = 0; i < selectElement.options.length; i++) {
                    selectElement.options[i].selected = true;
                }
                
                // Update the selectedSecondaryObjects array
                this.selectedSecondaryObjects = Array.from(selectElement.options)
                    .filter(option => option.selected)
                    .map(option => option.value);
                
                // Refresh the schema
                if (this.selectedSchemaObject) {
                    this.loadSchemaData();
                }
            }
        } catch (error) {
           // //console.error('Error in selectAllOptions:', error);
        }
    }
    
    // Unselect all options in the multi-select
    unselectAllOptions() {
        try {
           // //console.log('Unselecting all options');
            const selectElement = this.template.querySelector('.secondary-object-list');
            if (selectElement) {
                for (let i = 0; i < selectElement.options.length; i++) {
                    selectElement.options[i].selected = false;
                }
                
                // Clear the selectedSecondaryObjects array
                this.selectedSecondaryObjects = [];
                
                // Refresh the schema
                if (this.selectedSchemaObject) {
                    this.loadSchemaData();
                }
            }
        } catch (error) {
           // //console.error('Error in unselectAllOptions:', error);
        }
    }
    
    // Select all standard objects
    selectStandardObjects() {
        try {
           // //console.log('Selecting standard objects');
            const selectElement = this.template.querySelector('.secondary-object-list');
            if (selectElement && this.objectSchemaOptions) {
                // First unselect all
                for (let i = 0; i < selectElement.options.length; i++) {
                    selectElement.options[i].selected = false;
                }
                
                // Then select only standard objects (with a limit to prevent CPU timeout)
                const standardObjects = [];
                const MAX_STANDARD_OBJECTS = 5; // Limit to prevent CPU timeout
                let count = 0;
                
                for (let i = 0; i < selectElement.options.length; i++) {
                    const optionValue = selectElement.options[i].value;
                    // Standard objects don't end with __c
                    if (!optionValue.endsWith('__c')) {
                        // Only select up to the maximum limit
                        if (count < MAX_STANDARD_OBJECTS) {
                            selectElement.options[i].selected = true;
                            standardObjects.push(optionValue);
                            count++;
                        }
                    }
                }
                
                // Update the selectedSecondaryObjects array
                this.selectedSecondaryObjects = standardObjects;
                
                // Show a toast message if we limited the selection
                if (count === MAX_STANDARD_OBJECTS) {
                    this.showToast(
                        'Selection Limited', 
                        `Selected ${MAX_STANDARD_OBJECTS} standard objects. Selecting too many objects at once can cause performance issues.`, 
                        'info'
                    );
                }
                
                // Refresh the schema
                if (this.selectedSchemaObject) {
                    this.loadSchemaData();
                }
            }
        } catch (error) {
           // //console.error('Error in selectStandardObjects:', error);
            this.showToast('Error', 'An error occurred while selecting standard objects', 'error');
        }
    }
    
    // Select all custom objects
    selectCustomObjects() {
        try {
           // //console.log('Selecting custom objects');
            const selectElement = this.template.querySelector('.secondary-object-list');
            if (selectElement && this.objectSchemaOptions) {
                // First unselect all
                for (let i = 0; i < selectElement.options.length; i++) {
                    selectElement.options[i].selected = false;
                }
                
                // Then select only custom objects (with a limit to prevent CPU timeout)
                const customObjects = [];
                const MAX_CUSTOM_OBJECTS = 10; // Limit to prevent CPU timeout
                let count = 0;
                
                for (let i = 0; i < selectElement.options.length; i++) {
                    const optionValue = selectElement.options[i].value;
                    // Custom objects end with __c
                    if (optionValue.endsWith('__c')) {
                        // Only select up to the maximum limit
                        if (count < MAX_CUSTOM_OBJECTS) {
                            selectElement.options[i].selected = true;
                            customObjects.push(optionValue);
                            count++;
                        }
                    }
                }
                
                // Update the selectedSecondaryObjects array
                this.selectedSecondaryObjects = customObjects;
                
                // Show a toast message if we limited the selection
                if (count === MAX_CUSTOM_OBJECTS) {
                    this.showToast(
                        'Selection Limited', 
                        `Selected ${MAX_CUSTOM_OBJECTS} custom objects. Selecting too many objects at once can cause performance issues.`, 
                        'info'
                    );
                }
                
                // Refresh the schema
                if (this.selectedSchemaObject) {
                    this.loadSchemaData();
                }
            }
        } catch (error) {
           // //console.error('Error in selectCustomObjects:', error);
            this.showToast('Error', 'An error occurred while selecting custom objects', 'error');
        }
    }
    
    // Select all objects (both standard and custom)
    selectAllObjects() {
        try {
           // //console.log('Selecting all objects (standard and custom)');
            this.selectAllOptions();
        } catch (error) {
           // //console.error('Error in selectAllObjects:', error);
        }
    }

    zoomIn() {
        try {
           // //console.log('Zooming in');
            if (this.cyInstance) {
                const currentZoom = this.cyInstance.zoom();
                this.cyInstance.zoom({
                    level: currentZoom * 1.2,
                    renderedPosition: { x: this.cyInstance.width() / 2, y: this.cyInstance.height() / 2 }
                });
            }
        } catch (error) {
           // //console.error('Error in zoomIn:', error);
        }
    }
    
    zoomOut() {
        try {
           // //console.log('Zooming out');
            if (this.cyInstance) {
                const currentZoom = this.cyInstance.zoom();
                this.cyInstance.zoom({
                    level: currentZoom * 0.8,
                    renderedPosition: { x: this.cyInstance.width() / 2, y: this.cyInstance.height() / 2 }
                });
            }
        } catch (error) {
           // //console.error('Error in zoomOut:', error);
        }
    }
    
    fitGraph() {
        if (this.cyInstance) {
            this.cyInstance.fit();
            this.cyInstance.center();
        }
    }

    toggleFullScreen() {
        const schemaContainer = this.template.querySelector('.schema-container');
        this.isSchemaFullScreen = !this.isSchemaFullScreen;
        
        if (this.isSchemaFullScreen) {
            // Enter full screen mode
            schemaContainer.classList.add('schema-fullscreen');
            
            // Add full screen header
            const headerDiv = document.createElement('div');
            headerDiv.className = 'fullscreen-header';
            headerDiv.innerHTML = `
                <div class="fullscreen-title">
                    Schema Viewer - ${this.selectedSchemaObject ? this.getObjectLabel(this.selectedSchemaObject) : 'Full View'}
                </div>
            `;
            
            // Insert header at the beginning of the container
            schemaContainer.insertBefore(headerDiv, schemaContainer.firstChild);
            
            // Add keyboard event listener for Escape key
            this.handleKeyDown = this.handleKeyDown.bind(this);
            window.addEventListener('keydown', this.handleKeyDown);
            
            // Resize the graph to fit the new container size
            if (this.cyInstance) {
                // Force immediate resize and repositioning
                this.cyInstance.resize();
                this.cyInstance.fit();
                this.cyInstance.center();
                
                // Force canvas redraw by triggering a layout update
                this.cyInstance.layout({ name: 'preset' }).run();
                
                // Additional resize using Promise for better timing
                Promise.resolve().then(() => {
                    this.cyInstance.resize();
                    this.cyInstance.fit();
                    this.cyInstance.center();
                });
            }
        } else {
            // Exit full screen mode
            schemaContainer.classList.remove('schema-fullscreen');
            
            // Remove the header
            const header = schemaContainer.querySelector('.fullscreen-header');
            if (header) {
                schemaContainer.removeChild(header);
            }
            
            // Remove keyboard event listener
            window.removeEventListener('keydown', this.handleKeyDown);
            
            // Resize the graph to fit the original container size
            if (this.cyInstance) {
                // Give the DOM time to update before resizing
                setTimeout(() => {
                    this.cyInstance.resize();
                    this.cyInstance.fit();
                    this.cyInstance.center();
                }, 100);
            }
        }
    }

    getObjectLabel(objectName) {
        const option = this.objectSchemaOptions.find(opt => opt.value === objectName);
        return option ? option.label : objectName;
    }

    handleKeyDown(event) {
        // Exit full screen mode when Escape key is pressed
        if (event.key === 'Escape' && this.isSchemaFullScreen) {
            this.toggleFullScreen();
        }
    }

    filterByConnectionType(event) {
        try {
            const filterType = event.currentTarget.dataset.filter;
           // //console.log('Filtering by connection type:', filterType);
            
            if (!this.cyInstance) return;
            
            // Reset all filters first
            this.clearFilters();
            
            // Update filter state
            this.filterActive = {
                ...this.filterActive,
                connection: filterType === 'connection'
            };
            
            if (filterType === 'connection') {
                // Show only highlighted connections between selected objects
                this.cyInstance.elements().style('opacity', 0.2);
                
                // Get all selected objects (primary + secondary)
                const selectedObjects = [this.selectedSchemaObject, ...this.selectedSecondaryObjects];
                
                // Highlight the selected objects and their direct connections
                selectedObjects.forEach(objName => {
                    const node = this.cyInstance.getElementById(objName);
                    if (node.length) {
                        node.style('opacity', 1);
                        
                        // Find connections between selected objects
                        node.connectedEdges().forEach(edge => {
                            const source = edge.source().id();
                            const target = edge.target().id();
                            
                            if (selectedObjects.includes(source) && selectedObjects.includes(target)) {
                                edge.style('opacity', 1);
                                edge.style('line-color', '#FF5722');
                                edge.style('target-arrow-color', '#FF5722');
                                edge.style('width', 3);
                            }
                        });
                    }
                });
            }
        } catch (error) {
           // //console.error('Error in filterByConnectionType:', error);
        }
    }

    // Add this new method to handle showing relationship details
    showRelationshipDetails(edgeData) {
        try {
            // Validate edgeData before processing
            if (!edgeData || typeof edgeData !== 'object') {
               // //console.error('Invalid edge data received');
                return;
            }
            
            // Validate required properties
            if (!edgeData.source || !edgeData.target) {
               // //console.error('Edge data missing required properties');
                return;
            }
            
            // Create a sanitized copy of the edge data
            const sanitizedEdgeData = {
                sourceObject: this.sanitizeHtml(this.getObjectLabel(edgeData.source)),
                targetObject: this.sanitizeHtml(this.getObjectLabel(edgeData.target)),
                relationshipName: this.sanitizeHtml(edgeData.relationshipName || ''),
                relationshipType: this.sanitizeHtml(edgeData.relationshipType || ''),
                source: this.sanitizeHtml(edgeData.source || ''),
                target: this.sanitizeHtml(edgeData.target || '')
            };
            
            // Safely handle relationship fields
            if (Array.isArray(edgeData.relationshipFields)) {
                sanitizedEdgeData.relationshipFields = edgeData.relationshipFields.map(
                    field => this.sanitizeHtml(field)
                );
            } else {
                sanitizedEdgeData.relationshipFields = [];
            }
            
            // Set up data for the modal
            this.selectedEdgeData = sanitizedEdgeData;
            
            // Open the relationship modal
            this.isRelationshipModalOpen = true;
        } catch (error) {
           // //console.error('Error showing relationship details');
            this.showToast('Error', 'Failed to show relationship details', 'error');
        }
    }

    // Add a method to close the relationship modal
    closeRelationshipModal() {
        this.isRelationshipModalOpen = false;
    }

    // Add these properties to track the relationship modal state
    @track isRelationshipModalOpen = false;
    @track selectedEdgeData = {
        sourceObject: '',
        targetObject: '',
        relationshipName: '',
        relationshipType: '',
        relationshipFields: []
    };

    // Add these getter methods for the relationship modal
    get relationshipTypeIcon() {
        if (this.selectedEdgeData.relationshipType === 'Master-Detail') {
            return 'utility:link';
        } else if (this.selectedEdgeData.relationshipType === 'Lookup') {
            return 'utility:connected_apps';
        }
        return 'utility:relationship';
    }

    get hasRelationshipFields() {
        return this.selectedEdgeData.relationshipFields && 
               this.selectedEdgeData.relationshipFields.length > 0;
    }

    // Add these getter methods for the relationship modal
    get isMasterDetail() {
        return this.selectedEdgeData.relationshipType === 'Master-Detail';
    }

    get isLookup() {
        return this.selectedEdgeData.relationshipType === 'Lookup';
    }

    get relationshipFieldsCount() {
        return this.selectedEdgeData.relationshipFields ? this.selectedEdgeData.relationshipFields.length : 0;
    }

    get relationshipTypeIndicatorClass() {
        const baseClass = 'relationship-type-indicator';
        if (this.selectedEdgeData.relationshipType === 'Master-Detail') {
            return `${baseClass} master-detail`;
        } else {
            return `${baseClass} lookup`;
        }
    }

    // Add these properties to track the hide/show nodes state
    @track hideUnrelatedNodes = false;
    @track selectedNodeForFiltering = null;

    // Add getter methods for button variants
    get hideUnrelatedNodesButtonVariant() {
        return this.hideUnrelatedNodes ? 'brand' : 'neutral';
    }

    get showAllNodesButtonVariant() {
        return this.hideUnrelatedNodes ? 'neutral' : 'brand';
    }

    // Toggle hide unrelated nodes
    toggleHideUnrelatedNodes() {
        this.hideUnrelatedNodes = !this.hideUnrelatedNodes;
        
        if (this.cyInstance) {
            if (this.hideUnrelatedNodes) {
                // Apply fading effect to unrelated nodes
                if (this.selectedNodeForFiltering) {
                    // If a node is already selected, use it for filtering
                    this.fadeUnrelatedNodes(this.selectedNodeForFiltering);
                } else if (this.selectedSchemaObject) {
                    // Otherwise use the primary object
                    const primaryNode = this.cyInstance.getElementById(this.selectedSchemaObject);
                    if (primaryNode.length > 0) {
                        this.selectedNodeForFiltering = primaryNode;
                        this.fadeUnrelatedNodes(primaryNode);
                    }
                }
            } else {
                // Reset all nodes to full opacity
                this.cyInstance.elements().style({
                    'opacity': 1
                });
            }
        }
    }
    fadeUnrelatedNodes(selectedNode) {
        if (!selectedNode) return;
        
        // Get the selected node and its connected nodes
        const connectedNodes = selectedNode.neighborhood().nodes();
        const allNodes = this.cyInstance.nodes();
        
        // Add the selected node to the connected nodes
        connectedNodes.push(selectedNode);
        
        // Fade unrelated nodes (nodes not in the connected set)
        allNodes.forEach(node => {
            if (!connectedNodes.contains(node)) {
                node.style({
                    'opacity': 0.2  // You can adjust this value (0.0 to 1.0) for desired fading effect
                });
            } else {
                node.style({
                    'opacity': 1
                });
            }
        });
        
        // Keep edges connected to the selected node visible, fade others
        const allEdges = this.cyInstance.edges();
        allEdges.forEach(edge => {
            if (edge.source().id() === selectedNode.id() || edge.target().id() === selectedNode.id()) {
                edge.style({
                    'opacity': 1
                });
            } else {
                edge.style({
                    'opacity': 0.2  // Match the node opacity for consistency
                });
            }
        });
    }

    // Show all nodes
    showAllNodes() {
        this.hideUnrelatedNodes = false;
        
        if (this.cyInstance) {
            // Show all nodes and edges
            this.cyInstance.elements().removeClass('hidden');
            this.cyInstance.elements().style('opacity', 1);
            
            // Reset the selected node for filtering
            this.selectedNodeForFiltering = null;
            
            // Fit the graph to view all nodes
            this.fitGraph();
        }
    }

    // Filter graph to show only nodes connected to the selected node - optimized
    filterGraphByNode(node) {
        try {
            if (!this.cyInstance || !node) return;
            
            // Get the selected node and its connected nodes and edges
            const selectedNodeId = node.id();
            if (!selectedNodeId) {
               // //console.error('Node ID is undefined');
                return;
            }
            
            // Batch all operations for better performance
            this.cyInstance.batch(() => {
                const connectedNodes = node.neighborhood('node');
                const connectedEdges = node.connectedEdges();
                
                // Create a collection of elements to show (selected node, connected nodes, and edges)
                const elementsToShow = this.cyInstance.collection().add(node);
                
                // Safely add connected nodes and edges if they exist
                if (connectedNodes && connectedNodes.length > 0) {
                    elementsToShow.add(connectedNodes);
                }
                
                if (connectedEdges && connectedEdges.length > 0) {
                    elementsToShow.add(connectedEdges);
                }
                
                // Hide all elements first
                this.cyInstance.elements().addClass('hidden').style('opacity', 0.2);
                
                // Show the elements connected to the selected node
                elementsToShow.removeClass('hidden').style('opacity', 1);
            });
            
            // Fit the graph to show the visible elements (outside batch for better performance)
            requestAnimationFrame(() => {
                const elementsToShow = node.union(node.neighborhood());
                this.cyInstance.fit(elementsToShow, 50);
            });
        } catch (error) {
           // //console.error('Error filtering graph by node:', error);
        }
    }

    // Add this method to handle node selection from the legend
    handleNodeSelection(objectName) {
        if (!this.cyInstance || !objectName) return;
        
        const node = this.cyInstance.getElementById(objectName);
        if (node.length > 0) {
            // Set this as the selected node for filtering
            this.selectedNodeForFiltering = node;
            
            // Highlight the node and its connections
            this.highlightConnectedElements(node);
            
            // If hide unrelated nodes is active, filter the graph
            if (this.hideUnrelatedNodes) {
                this.filterGraphByNode(node);
            }
        }
    }

    // Add these computed properties
    get hasSelectedSecondaryObjects() {
        return this.selectedSecondaryObjects && this.selectedSecondaryObjects.length > 0;
    }

    get selectedSecondaryObjectsInfo() {
        if (!this.selectedSecondaryObjects || !this.objectSchemaOptions) {
            return [];
        }
        
        // Map selected values to their full info (value and label)
        return this.selectedSecondaryObjects.map(objName => {
            const option = this.objectSchemaOptions.find(opt => opt.value === objName);
            return {
                value: objName,
                label: option ? option.label : objName
            };
        });
    }

    // Add this method to handle removing a selected object
    handleRemoveSelectedObject(event) {
        const valueToRemove = event.currentTarget.dataset.value;
        
        if (valueToRemove && this.selectedSecondaryObjects) {
            // Remove the object from the selected list
            this.selectedSecondaryObjects = this.selectedSecondaryObjects.filter(
                objName => objName !== valueToRemove
            );
            
            // Update the multi-select to reflect the change
            const selectElement = this.template.querySelector('.secondary-object-list');
            if (selectElement) {
                // Deselect the option in the multi-select
                Array.from(selectElement.options).forEach(option => {
                    if (option.value === valueToRemove) {
                        option.selected = false;
                    }
                });
            }
            
            // Always refresh the schema with the updated selection
            if (this.selectedSchemaObject) {
                this.loadSchemaData();
            }
        }
    }

    // We don't need the loadAllObjects method if loadSchemaData already handles this case correctly
    // If loadSchemaData doesn't handle empty selectedSecondaryObjects correctly, we need to modify it

    // Check if loadSchemaData needs modification to handle empty selectedSecondaryObjects
    // This is a placeholder - you'll need to check your actual implementation
    /*
    loadSchemaData() {
        // Get the selected objects
        const primaryObject = this.selectedSchemaObject;
        const secondaryObjects = this.selectedSecondaryObjects || [];
        
        // Call the Apex method with the selected objects
        getSchemaDataWithRelatedObjects({ 
            primaryObjectName: primaryObject,
            secondaryObjectNames: secondaryObjects 
        })
        .then(result => {
            // Process the result
            // ...
        })
        .catch(error => {
            // Handle errors
            // ...
        });
    }
    */

    @track objectFilterTerm = '';
    
    handleObjectFilter(event) {
        this.objectFilterTerm = event.target.value.toLowerCase();
    }
    
    get filteredObjectSchemaOptions() {
        if (!this.objectSchemaOptions) {
            return [];
        }
        
        if (!this.objectFilterTerm) {
            return this.objectSchemaOptions;
        }
        
        return this.objectSchemaOptions.filter(option => 
            option.label.toLowerCase().includes(this.objectFilterTerm) || 
            option.value.toLowerCase().includes(this.objectFilterTerm)
        );
    }

    // Select common standard objects that are frequently used
    selectCommonObjects() {
        try {
           // //console.log('Selecting common objects');
            const selectElement = this.template.querySelector('.secondary-object-list');
            if (selectElement && this.objectSchemaOptions) {
                // First unselect all
                for (let i = 0; i < selectElement.options.length; i++) {
                    selectElement.options[i].selected = false;
                }
                
                // List of common objects to select
                const commonObjectNames = [
                    'Account', 'Contact', 'User', 'Profile', 'PermissionSet', 
                    'Group', 'UserRole', 'Case', 'Opportunity'
                ];
                
                // Select only common objects
                const selectedObjects = [];
                
                for (let i = 0; i < selectElement.options.length; i++) {
                    const optionValue = selectElement.options[i].value;
                    if (commonObjectNames.includes(optionValue)) {
                        selectElement.options[i].selected = true;
                        selectedObjects.push(optionValue);
                    }
                }
                
                // Update the selectedSecondaryObjects array
                this.selectedSecondaryObjects = selectedObjects;
                
                // Refresh the schema
                if (this.selectedSchemaObject) {
                    this.loadSchemaData();
                }
            }
        } catch (error) {
           // //console.error('Error in selectCommonObjects:', error);
            this.showToast('Error', 'An error occurred while selecting common objects', 'error');
        }
    }

    get readStatusClass() {
        return this.selectedNodeData?.permissions?.read ? 'access-allowed' : 'access-denied';
    }

    get createStatusClass() {
        return this.selectedNodeData?.permissions?.create ? 'access-allowed' : 'access-denied';
    }

    get editStatusClass() {
        return this.selectedNodeData?.permissions?.edit ? 'access-allowed' : 'access-denied';
    }

    get deleteStatusClass() {
        return this.selectedNodeData?.permissions?.delete ? 'access-allowed' : 'access-denied';
    }

    // Tour functionality
    showTour = false;
    currentTourStep = 1;
    totalTourSteps = 7;
    tourSteps = [
        {
            title: 'Welcome to User Access Manager',
            description: 'Now you can easily view and manage user access to your Salesforce org. This tour will guide you through the main features of the User Access Manager, Click Next to continue.',
            element: '.app-title',
            position: 'bottom'
        },
        {
            title: 'Select a User',
            description: 'Start by selecting a user from this dropdown to view and manage their permissions.',
            element: '.user-selector',
            position: 'bottom-left'
        },
        {
            title: 'Access Configuration',
            description: 'Use these toggles to show or hide different types of permissions and access information.',
            element: '.toggle-group',
            position: 'right'
        },
        
        {
            title: 'Risk Score',
            description: 'The risk score indicates the security risk level associated with this user\'s permissions. Higher scores indicate higher risk.',
            element: '.risk-meter-card',
            position: 'left'
        },
        {
            title: 'Remediation Actions',
            description: 'If needed, you can take remediation actions to adjust user permissions and reduce security risks.',
            element: '.remediation-section',
            position: 'left'
        },
        {
            title: 'Permission Sets',
            description: 'View the permission sets assigned to this user. You can also grant additional access by clicking the "Grant Access" button to assign new permission sets.',
            element: '.permission-sets-section',
            position: 'right'
        },
        {
            title: 'Thank You!',
            description: 'You\'ve completed the tour of User Access Manager. Feel free to explore the application further. If you need to take the tour again, click the "Take a Tour" button at any time.',
            element: '.app-header',
            position: 'bottom'
        }
    ];

    get currentTourTitle() {
        return this.tourSteps[this.currentTourStep - 1]?.title || '';
    }

    get currentTourDescription() {
        return this.tourSteps[this.currentTourStep - 1]?.description || '';
    }

    get showPreviousButton() {
        return this.currentTourStep > 1;
    }

    get nextButtonLabel() {
        return this.currentTourStep === this.totalTourSteps ? 'Finish' : 'Next';
    }

    startTour() {
        this.showTour = true;
        this.currentTourStep = 1;
        
        // Wait for the DOM to update
        setTimeout(() => {
            this.positionTourTooltip();
            this.highlightElement();
        }, 100);
    }

    endTour() {
        this.showTour = false;
        this.removeHighlight();
    }

    nextTourStep() {
        this.removeHighlight();
        
        if (this.currentTourStep < this.totalTourSteps) {
            this.currentTourStep++;
            
            // Wait for the DOM to update
            setTimeout(() => {
                this.positionTourTooltip();
                this.highlightElement();
            }, 100);
        } else {
            this.endTour();
        }
    }

    previousTourStep() {
        this.removeHighlight();
        
        if (this.currentTourStep > 1) {
            this.currentTourStep--;
            
            // Wait for the DOM to update
            setTimeout(() => {
                this.positionTourTooltip();
                this.highlightElement();
            }, 100);
        }
    }

    positionTourTooltip() {
        const step = this.tourSteps[this.currentTourStep - 1];
        if (!step) return;
        
        const targetElement = this.template.querySelector(step.element);
        if (!targetElement) return;
        
        const tooltip = this.template.querySelector('.tour-tooltip');
        if (!tooltip) return;
        
        const targetRect = targetElement.getBoundingClientRect();
        const tooltipRect = tooltip.getBoundingClientRect();
        
        // Calculate position based on the specified position
        let top, left;
        
        switch (step.position) {
            case 'top':
                top = targetRect.top - tooltipRect.height - 16;
                left = targetRect.left + (targetRect.width / 2) - (tooltipRect.width / 2);
                break;
            case 'bottom':
                top = targetRect.bottom + 16;
                left = targetRect.left + (targetRect.width / 2) - (tooltipRect.width / 2);
                break;
            case 'left':
                top = targetRect.top + (targetRect.height / 2) - (tooltipRect.height / 2);
                left = targetRect.left - tooltipRect.width - 16;
                break;
            case 'right':
                top = targetRect.top + (targetRect.height / 2) - (tooltipRect.height / 2);
                left = targetRect.right + 16;
                break;
            case 'bottom-left':
                top = targetRect.bottom + 16;
                left = targetRect.left;
                break;
            default:
                top = targetRect.bottom + 16;
                left = targetRect.left + (targetRect.width / 2) - (tooltipRect.width / 2);
        }
        
        // Ensure the tooltip stays within the viewport
        const viewportWidth = window.innerWidth;
        const viewportHeight = window.innerHeight;
        
        if (left < 16) {
            left = 16;
        } else if (left + tooltipRect.width > viewportWidth - 16) {
            left = viewportWidth - tooltipRect.width - 16;
        }
        
        if (top < 16) {
            top = 16;
        } else if (top + tooltipRect.height > viewportHeight - 16) {
            top = viewportHeight - tooltipRect.height - 16;
        }
        
        // Set the position
        tooltip.style.top = `${top}px`;
        tooltip.style.left = `${left}px`;
        
        // Create the tooltip content
        this.createTooltipContent(tooltip);
    }

    createTooltipContent(tooltip) {
        // Clear existing content
        tooltip.innerHTML = '';
        
        // Create the tooltip content
        const header = document.createElement('div');
        header.className = 'tour-header';
        
        const stepIndicator = document.createElement('div');
        stepIndicator.className = 'tour-step-indicator';
        stepIndicator.innerHTML = `<span class="tour-step-count">${this.currentTourStep}</span> of <span class="tour-total-steps">${this.totalTourSteps}</span>`;
        
        const closeButton = document.createElement('button');
        closeButton.className = 'tour-close-button';
        closeButton.innerHTML = '<lightning-icon icon-name="utility:close" size="small"></lightning-icon>';
        closeButton.addEventListener('click', () => this.endTour());
        
        header.appendChild(stepIndicator);
        header.appendChild(closeButton);
        
        const content = document.createElement('div');
        content.className = 'tour-content';
        
        const title = document.createElement('h2');
        title.className = 'tour-title';
        title.textContent = this.currentTourTitle;
        
        const description = document.createElement('p');
        description.className = 'tour-description';
        description.textContent = this.currentTourDescription;
        
        content.appendChild(title);
        content.appendChild(description);
        
        const footer = document.createElement('div');
        footer.className = 'tour-footer';
        
        if (this.showPreviousButton) {
            const previousButton = document.createElement('button');
            previousButton.className = 'slds-button slds-button_neutral tour-previous-button';
            previousButton.textContent = 'Previous';
            previousButton.addEventListener('click', () => this.previousTourStep());
            footer.appendChild(previousButton);
        }
        
        const nextButton = document.createElement('button');
        nextButton.className = 'slds-button slds-button_brand tour-next-button';
        nextButton.textContent = this.nextButtonLabel;
        nextButton.addEventListener('click', () => this.nextTourStep());
        footer.appendChild(nextButton);
        
        tooltip.appendChild(header);
        tooltip.appendChild(content);
        tooltip.appendChild(footer);
    }

    highlightElement() {
        const step = this.tourSteps[this.currentTourStep - 1];
        if (!step) return;
        
        const targetElement = this.template.querySelector(step.element);
        if (!targetElement) return;
        
        // Add highlight class
        targetElement.classList.add('tour-highlight');
    }

    removeHighlight() {
        // Remove highlight from all elements
        const highlightedElements = this.template.querySelectorAll('.tour-highlight');
        highlightedElements.forEach(element => {
            element.classList.remove('tour-highlight');
        });
    }

    // Permission Set Revocation Modal
    showRevokePermissionModal = false;
    isLoadingPermSets = false;
    permissionSetsToRevoke = [];
    
    get selectedPermSetsCount() {
        return this.permissionSetsToRevoke.filter(pset => pset.selected).length;
    }
    
    get totalPermSetsCount() {
        return this.permissionSetsToRevoke.length;
    }
    
    get isRevokeButtonDisabled() {
        return this.selectedPermSetsCount === 0 || this.isLoadingPermSets;
    }
    
    openRevokePermissionModal() {
        this.showRevokePermissionModal = true;
        this.loadPermissionSetsForRevocation();
    }
    
    closeRevokePermissionModal() {
        this.showRevokePermissionModal = false;
    }
    
    async loadPermissionSetsForRevocation() {
        this.isLoadingPermSets = true;
        
        try {
            // In a real implementation, you would call an Apex method to get detailed permission set data
            // For now, we'll use the existing permission sets data and add risk analysis
            
            if (this.userDetails && this.userDetails.permissionSets) {
                // Create a detailed analysis of each permission set
                this.permissionSetsToRevoke = this.userDetails.permissionSets.map((psetName, index) => {
                    // Simulate risk analysis - in a real implementation, this would come from the server
                    const riskLevel = this.analyzePermissionSetRisk(psetName);
                    const criticalPermissions = this.identifyCriticalPermissions(psetName);
                    
                    return {
                        id: 'pset-' + index,
                        name: psetName,
                        label: psetName,
                        description: 'Permission set granting specific access to Salesforce features',
                        selected: false,
                        riskLevel: riskLevel.level,
                        riskScore: riskLevel.score,
                        riskIcon: this.getRiskIcon(riskLevel.level),
                        riskClass: 'risk-level-' + riskLevel.level.toLowerCase(),
                        rowClass: riskLevel.level.toLowerCase() + '-risk',
                        recommendation: this.getRecommendation(riskLevel.level, psetName),
                        criticalPermissions: criticalPermissions
                    };
                });
                
                // Sort by risk level (high to low)
                this.permissionSetsToRevoke.sort((a, b) => b.riskScore - a.riskScore);
            }
        } catch (error) {
            // //console.error('Error loading permission sets for revocation:', error);
            this.showErrorToast('Error', 'Failed to load permission sets for analysis');
        } finally {
            this.isLoadingPermSets = false;
        }
    }
    
    analyzePermissionSetRisk(permissionSetName) {
        // This is a simplified risk analysis - in a real implementation, 
        // you would analyze the actual permissions in each permission set
        
        // Simulate high risk for permission sets with certain keywords
        const highRiskKeywords = ['admin', 'modify all', 'system', 'apex', 'customize'];
        const mediumRiskKeywords = ['create', 'edit', 'delete', 'manage'];
        
        const name = permissionSetName.toLowerCase();
        
        if (highRiskKeywords.some(keyword => name.includes(keyword))) {
            return { level: 'High', score: 80 + Math.floor(Math.random() * 20) };
        } else if (mediumRiskKeywords.some(keyword => name.includes(keyword))) {
            return { level: 'Medium', score: 40 + Math.floor(Math.random() * 40) };
        } else {
            return { level: 'Low', score: Math.floor(Math.random() * 40) };
        }
    }
    
    identifyCriticalPermissions(permissionSetName) {
        // This is a simplified analysis - in a real implementation, 
        // you would identify actual critical permissions in each permission set
        
        const name = permissionSetName.toLowerCase();
        const criticalPermissions = [];
        
        if (name.includes('admin')) {
            criticalPermissions.push('Modify All Data');
            criticalPermissions.push('View All Data');
            criticalPermissions.push('Assign Permission Sets');
        }
        
        if (name.includes('system')) {
            criticalPermissions.push('Customize Application');
            criticalPermissions.push('Manage Users');
        }
        
        if (name.includes('apex')) {
            criticalPermissions.push('Author Apex');
            criticalPermissions.push('Run Flows');
        }
        
        // Add some random critical permissions for demonstration
        const possiblePermissions = [
            'Manage Public Reports',
            'Manage Dashboards',
            'Manage Roles',
            'Manage Sharing',
            'Manage Profiles and Permission Sets',
            'View Setup and Configuration',
            'Manage Authentication',
            'Manage IP Addresses'
        ];
        
        // Add 1-3 random permissions
        const numToAdd = Math.floor(Math.random() * 3) + 1;
        for (let i = 0; i < numToAdd; i++) {
            const randomPerm = possiblePermissions[Math.floor(Math.random() * possiblePermissions.length)];
            if (!criticalPermissions.includes(randomPerm)) {
                criticalPermissions.push(randomPerm);
            }
        }
        
        return criticalPermissions;
    }
    
    getRecommendation(riskLevel, permissionSetName) {
        switch (riskLevel) {
            case 'High':
                return `Consider revoking this permission set as it grants highly privileged access that may pose security risks. ${permissionSetName} contains permissions that could be exploited if compromised.`;
            case 'Medium':
                return `Review if this permission set is necessary for the user's job functions. It grants significant access that should be limited to appropriate users.`;
            case 'Low':
                return `This permission set grants minimal risk permissions and is likely appropriate for most users.`;
            default:
                return 'Review this permission set to determine if it is necessary for the user.';
        }
    }
    
    getRiskIcon(riskLevel) {
        switch (riskLevel) {
            case 'High':
                return 'utility:warning';
            case 'Medium':
                return 'utility:error';
            case 'Low':
                return 'utility:check';
            default:
                return 'utility:info';
        }
    }
    
    handlePermSetSelection(event) {
        const permSetId = event.target.name;
        const isChecked = event.target.checked;
        
        this.permissionSetsToRevoke = this.permissionSetsToRevoke.map(pset => {
            if (pset.id === permSetId) {
                return { ...pset, selected: isChecked };
            }
            return pset;
        });
    }
    
    selectAllPermSets() {
        this.permissionSetsToRevoke = this.permissionSetsToRevoke.map(pset => {
            return { ...pset, selected: true };
        });
    }
    
    selectRiskyPermSets() {
        this.permissionSetsToRevoke = this.permissionSetsToRevoke.map(pset => {
            return { ...pset, selected: pset.riskLevel === 'High' };
        });
    }
    
    clearPermSetSelection() {
        this.permissionSetsToRevoke = this.permissionSetsToRevoke.map(pset => {
            return { ...pset, selected: false };
        });
    }
    
    // Track revoked permission sets to handle caching issues
    revokedPermissionSets = new Set();
    grantedPermissionSets = new Set();
    
    async executeSelectedRevocation() {
        let selectedPermSets = this.permissionSetsToRevoke
            .filter(pset => pset.selected)
            .map(pset => pset.name);
        
        // Filter out any empty permission sets
        selectedPermSets = selectedPermSets.filter(ps => ps && ps.trim().length > 0);
           // //console.log('Selected permission sets to revoke after filtering empty values:', selectedPermSets);
        
        if (selectedPermSets.length === 0) {
            this.showToast('No Permission Sets Selected', 'Please select at least one permission set to revoke.', 'warning');
            return;
        }
        
        try {
            this.isLoadingPermSets = true;
            
            // Call the existing revocation method with the selected permission sets
            await this.revokeSelectedPermSetsJS(selectedPermSets);
            
            // First close the modal to prevent stale data display
            this.closeRevokePermissionModal();
            
            // Add the revoked permission sets to our tracking set and remove from granted set if present
            selectedPermSets.forEach(pset => {
                this.revokedPermissionSets.add(pset);
                this.grantedPermissionSets.delete(pset);
            });
            ////console.log('Added to revokedPermissionSets tracking:', selectedPermSets);
            ////console.log('Total tracked revoked permission sets:', Array.from(this.revokedPermissionSets));
            
            // Immediately update local permission sets array by removing the revoked ones
            if (this.userDetails && this.userDetails.permissionSets) {
               // //console.log('Before removal, permission sets:', JSON.stringify(this.userDetails.permissionSets));
                this.userDetails.permissionSets = this.userDetails.permissionSets.filter(
                    ps => !selectedPermSets.includes(ps)
                );
               // //console.log('After removal, permission sets:', JSON.stringify(this.userDetails.permissionSets));
                
                // Force immediate UI update with the filtered permission sets
                this.userDetails = {...this.userDetails};
                
                // Force template re-render to ensure UI reflects changes
                this.template.querySelectorAll('.permission-sets-container').forEach(container => {
                    if (container) {
                        container.style.display = 'none';
                        // Use Promise to ensure DOM update
                        Promise.resolve().then(() => {
                            container.style.display = '';
                        });
                    }
                });
            }
            
            // Show success message
            this.showToast('Success', `Successfully revoked ${selectedPermSets.length} permission set(s) from the user.`, 'success');
            
            // Immediately refresh risk analysis to update risk score
            await this.refreshRiskAnalysis();
            
            // Then do a full refresh to ensure data consistency
            await this.refreshData();
            
        } catch (error) {
           // //console.error('Error revoking permission sets:', error);
            this.showErrorToast('Error', 'Failed to revoke permission sets: ' + (error.body?.message || error.message || 'Unknown error'));
        } finally {
            this.isLoadingPermSets = false;
        }
    }
    
    async revokeSelectedPermSetsJS(permissionSetsToRevoke) {
        // Call the Apex method to revoke the selected permission sets
        try {
            await revokeSelectedPermissionSets({
                userId: this.selectedUserId,
                permissionSetNames: permissionSetsToRevoke
            });
            
            this.lastActionType = 'revokePermissionSets';
            this.showUndoButton = true;
            
        } catch (error) {
           // //console.error('Error revoking permission sets:', error);
            
            // Check if this is the specific undo permission error - we can still continue
            if (error.body && error.body.message && 
                (error.body.message.includes('Insufficient permissions for undo operation') ||
                 error.body.message.includes('PermissionSetUndoo__c'))) {
                
                // Show a more user-friendly message
                this.showToast(
                    'Warning', 
                    'Permission sets were revoked successfully, but undo functionality is not available due to permission limitations.', 
                    'warning'
                );
                
                // Return without throwing, since the operation actually succeeded
                return;
            }
            
            // For other errors, rethrow to be handled by the caller
            throw error;
        }
    }

    // Add URL validation method to prevent open redirects
    isValidUrl(url) {
        if (!url) return false;
        
        // Check if URL is internal or on an approved domain list
        const allowedDomains = ['salesforce.com', 'force.com', 'lightning.force.com'];
        
        try {
            // For relative URLs, consider them valid
            if (url.startsWith('/')) return true;
            
            // For absolute URLs, validate the domain
            const urlObj = new URL(url);
            return urlObj.hostname.endsWith('salesforce.com') || 
                   allowedDomains.some(domain => urlObj.hostname.endsWith(domain));
        } catch (e) {
            // If URL parsing fails, consider it invalid
           // //console.error('Invalid URL format:', url);
            return false;
        }
    }
    
    // Helper method to safely navigate to a URL
    navigateToUrl(url) {
        if (!this.isValidUrl(url)) {
           // //console.error('Attempted navigation to invalid URL:', url);
            this.showToast('Security Warning', 'Navigation to external URL blocked', 'error');
            return;
        }
        
        // Safe navigation using LWC navigation service or window.open for internal URLs
        if (url.startsWith('/')) {
            // Use LWC navigation for relative URLs
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: url
                }
            });
        } else {
            // For absolute URLs that passed validation, open in a new tab
            window.open(url, '_blank');
        }
    }

    // Add this near other @track properties
    @track showDuplicateAccessOnly = false;
    @track duplicateAccessCount = 0;
    @track isObjectSourcesModalOpen = false;
    @track selectedObjectForSources = null;
    @track objectSourcesList = [];
    @track draftValues = [];
    
    // Add this method after handleCopyToExcel or handleCopyCurrentPageToExcel
    handleShowDuplicateAccess() {
        // Toggle the flag
        this.showDuplicateAccessOnly = !this.showDuplicateAccessOnly;
        
        // Reset to first page when toggling
        this.currentObjectPage = 1;
        
        // If toggling on, show a toast message explaining what's happening
        if (this.showDuplicateAccessOnly) {
            this.showToast(
                'Showing Duplicate Access', 
                'Filtering to only show objects with permissions granted from multiple sources', 
                'info'
            );
        } else {
            this.showToast(
                'Showing All Permissions', 
                'Displaying all object permissions', 
                'info'
            );
        }
        
        // Refresh the table to apply the filter
        this.loadObjectPermissions();
    }
    
    get duplicateAccessButtonVariant() {
        return this.showDuplicateAccessOnly ? 'brand' : 'neutral';
    }
    
    get objectRowClass() {
        return function(row) {
            return row.isDuplicateAccess ? 'duplicate-access-highlight' : '';
        };
    }
    
    get duplicateAccessButtonLabel() {
        return this.showDuplicateAccessOnly 
            ? 'Show All Permissions' 
            : `Show Duplicate Access (${this.duplicateAccessCount})`;
    }
    
    // Add this with the other column definitions
    sourceDetailColumns = [
        { 
            label: 'Source Name', 
            fieldName: 'sourceName',
            type: 'text',
            cellAttributes: { class: 'slds-text-title_bold' },
            initialWidth: 250
        },
        { 
            label: 'Source Type', 
            fieldName: 'sourceTypeFormatted',
            type: 'text',
            cellAttributes: { 
                class: { fieldName: 'sourceTypeClass' }
            },
            initialWidth: 150
        },
        { 
            label: 'Read', 
            fieldName: 'readPermission', 
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'readPermission' },
                title: 'Click to toggle permission',
                name: 'toggle_source_read',
                variant: 'base',
                iconName: { fieldName: 'readIcon' },
                iconPosition: 'right'
            },
            cellAttributes: { 
                class: { fieldName: 'readPermission', formatter: value => `permission-cell ${value === 'Allowed' ? 'allowed' : 'denied'}` },
                alignment: 'center'
            },
            initialWidth: 100,
            hideDefaultActions: true
        },
        { 
            label: 'Create', 
            fieldName: 'createPermission', 
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'createPermission' },
                title: 'Click to toggle permission',
                name: 'toggle_source_create',
                variant: 'base',
                iconName: { fieldName: 'createIcon' },
                iconPosition: 'right'
            },
            cellAttributes: { 
                class: { fieldName: 'createPermission', formatter: value => `permission-cell ${value === 'Allowed' ? 'allowed' : 'denied'}` },
                alignment: 'center'
            },
            initialWidth: 100,
            hideDefaultActions: true
        },
        { 
            label: 'Edit', 
            fieldName: 'editPermission', 
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'editPermission' },
                title: 'Click to toggle permission',
                name: 'toggle_source_edit',
                variant: 'base',
                iconName: { fieldName: 'editIcon' },
                iconPosition: 'right'
            },
            cellAttributes: { 
                class: { fieldName: 'editPermission', formatter: value => `permission-cell ${value === 'Allowed' ? 'allowed' : 'denied'}` },
                alignment: 'center'
            },
            initialWidth: 100,
            hideDefaultActions: true
        },
        { 
            label: 'Delete', 
            fieldName: 'deletePermission', 
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'deletePermission' },
                title: 'Click to toggle permission',
                name: 'toggle_source_delete',
                variant: 'base',
                iconName: { fieldName: 'deleteIcon' },
                iconPosition: 'right'
            },
            cellAttributes: { 
                class: { fieldName: 'deletePermission', formatter: value => `permission-cell ${value === 'Allowed' ? 'allowed' : 'denied'}` },
                alignment: 'center'
            },
            initialWidth: 100,
            hideDefaultActions: true
        },
        { 
            label: 'View All Records', 
            fieldName: 'viewAllText', 
            type: 'text',
            cellAttributes: { 
                class: 'granular-permission-cell',
                alignment: 'center'
            },
            initialWidth: 120,
            hideDefaultActions: true
        },
        { 
            label: 'Modify All Records', 
            fieldName: 'modifyAllText', 
            type: 'text',
            cellAttributes: { 
                class: 'granular-permission-cell',
                alignment: 'center'
            },
            initialWidth: 130,
            hideDefaultActions: true
        },
        { 
            label: 'View All Fields', 
            fieldName: 'viewAllFieldsText', 
            type: 'text',
            cellAttributes: { 
                class: 'granular-permission-cell',
                alignment: 'center'
            },
            initialWidth: 120,
            hideDefaultActions: true
        }
    ];
    
    // Method to handle actions from the datatable
    handleObjectRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        if (action.name === 'view_schema') {
            this.selectedSchemaObject = row.SobjectType;
            this.showSchemaViewer = true;
            this.loadSchemaData();
        }
    }
    
    // Method to close the modal
    closeObjectSourcesModal() {
        this.isObjectSourcesModalOpen = false;
        this.selectedObjectForSources = null;
        this.objectSourcesList = [];
    }

    // Method to show sources for an object
    showSourcesForObject(objectName) {
        this.selectedObjectForSources = objectName;
        this.isObjectSourcesModalOpen = true;
        this.objectSourcesList = [];
        
        // Get the actual permission sources from the server
        this.getObjectPermissionSources(objectName);
    }
    
    // Method to get permission sources from the server
    async getObjectPermissionSources(objectName) {
        try {
            // Show loading state
            this.isLoading = true;
            
            // Get object permissions for this user and object
            const result = await getObjectPermissionSources({
                userId: this.selectedUserId,
                objectName: objectName
            });
            
            if (result && Array.isArray(result)) {
                // Format the data for the datatable
                this.objectSourcesList = result.map(source => {
                    return {
                        sourceName: source.sourceName || 'Unknown',
                        sourceType: source.sourceType || 'Unknown',
                        sourceTypeFormatted: source.sourceType || 'Unknown',
                        sourceTypeClass: `source-type-${source.sourceType?.toLowerCase() || 'unknown'}`,
                        sourceId: source.sourceId || source.permissionSetId || null, // Include sourceId for permission updates
                        PermissionsRead: source.canRead || false,
                        PermissionsCreate: source.canCreate || false,
                        PermissionsEdit: source.canEdit || false,
                        PermissionsDelete: source.canDelete || false,
                        readIcon: source.canRead ? 'utility:check' : 'utility:close',
                        createIcon: source.canCreate ? 'utility:check' : 'utility:close',
                        editIcon: source.canEdit ? 'utility:check' : 'utility:close',
                        deleteIcon: source.canDelete ? 'utility:check' : 'utility:close',
                        readPermission: source.canRead ? 'Allowed' : 'Denied',
                        createPermission: source.canCreate ? 'Allowed' : 'Denied',
                        editPermission: source.canEdit ? 'Allowed' : 'Denied',
                        deletePermission: source.canDelete ? 'Allowed' : 'Denied',
                        // Enhanced granular permissions
                        viewAllText: source.canViewAll ? 'Allowed' : 'Denied',
                        modifyAllText: source.canModifyAll ? 'Allowed' : 'Denied',
                        viewAllFieldsText: source.canViewAllFields ? 'Allowed' : 'Denied'
                    };
                });
            } else {
                // Handle empty or invalid response
                this.objectSourcesList = [];
                this.showToast('Error', 'No permission sources found for this object', 'error');
            }
        } catch (error) {
            this.objectSourcesList = [];
            this.showToast('Error', `Failed to load permission sources: ${error.message || 'Unknown error'}`, 'error');
            //console.error('Error loading permission sources:', error);
        } finally {
            this.isLoading = false;
        }
    }

    // After the objectColumns definition, add this method to handle cell edits
    handlePermissionCellEdit(event) {
        // Get the draft values from the event
        const draftValues = event.detail.draftValues;

        if (draftValues && draftValues.length > 0) {
            // Get the edited record and field
            const editedItem = draftValues[0];
            const objectName = editedItem.objectName;
            
            // Determine which permission was edited
            const fieldName = Object.keys(editedItem).find(key => 
                key !== 'objectName' && key !== 'id'
            );
            
            if (!fieldName) return;
            
            // Convert fieldName to permission type
            let permissionType = '';
            if (fieldName === 'readText') permissionType = 'read';
            if (fieldName === 'createText') permissionType = 'create';
            if (fieldName === 'editText') permissionType = 'edit';
            if (fieldName === 'deleteText') permissionType = 'delete';
            
            if (!permissionType) return;
            
            // Toggle the permission value
            const newValue = editedItem[fieldName] === 'Allowed' ? false : true;
            
            // Prepare the permission update
            const permUpdate = {
                objectName: objectName,
                permissions: {
                    [permissionType]: newValue
                }
            };
            
            // Show loading spinner
            this.isLoading = true;
            
            // Call the server to update permissions
            updateObjectPermissions({
                userId: this.selectedUserId,
                permissionUpdates: [permUpdate]
            })
            .then(result => {
                if (result) {
                    // Success - refresh the data
                    this.showToast('Success', 'Permission updated successfully', 'success');
                    
                    // Update the local data to reflect the change
                    this.updateLocalPermissionData(objectName, permissionType, newValue);
                    
                    // Clear draft values
                    this.draftValues = [];
                } else {
                    this.showToast('Error', 'Failed to update permission', 'error');
                }
            })
            .catch(error => {
                this.showToast('Error', 'Error updating permission: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
        }
    }

    // Helper to update local permission data
    updateLocalPermissionData(objectName, permissionType, newValue) {
        // Find the object in our local data
        const objIndex = this.objectPermissions.findIndex(obj => obj.objectName === objectName);
        
        if (objIndex !== -1) {
            // Make a deep copy of the object
            const updatedObj = JSON.parse(JSON.stringify(this.objectPermissions[objIndex]));
            
            // Update the appropriate permission
            if (permissionType === 'read') {
                updatedObj.PermissionsRead = newValue;
                updatedObj.readIcon = newValue ? 'utility:check' : 'utility:close';
                updatedObj.readText = newValue ? 'Allowed' : 'Denied';
            } else if (permissionType === 'create') {
                updatedObj.PermissionsCreate = newValue;
                updatedObj.createIcon = newValue ? 'utility:check' : 'utility:close';
                updatedObj.createText = newValue ? 'Allowed' : 'Denied';
            } else if (permissionType === 'edit') {
                updatedObj.PermissionsEdit = newValue;
                updatedObj.editIcon = newValue ? 'utility:check' : 'utility:close';
                updatedObj.editText = newValue ? 'Allowed' : 'Denied';
            } else if (permissionType === 'delete') {
                updatedObj.PermissionsDelete = newValue;
                updatedObj.deleteIcon = newValue ? 'utility:check' : 'utility:close';
                updatedObj.deleteText = newValue ? 'Allowed' : 'Denied';
            }
            
            // Update the array
            this.objectPermissions = [
                ...this.objectPermissions.slice(0, objIndex),
                updatedObj,
                ...this.objectPermissions.slice(objIndex + 1)
            ];
        }
    }

    // Helper to show toast messages
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    // Handle row actions for permission buttons and object details
    handlePermissionAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
     //   //console.log('Action clicked:', actionName);
       // //console.log('Row data:', JSON.stringify(row));
        
        // If this is a toggle permission action
        if (actionName.startsWith('toggle_')) {
            try {
                // Get the permission type from the action name
                const permissionType = actionName.split('_')[1];
                
                // Current value (Allowed or Denied)
                const currentValue = row[permissionType + 'Text'];
                
                // Make sure we have a valid objectName
                if (!row.objectName) {
                    this.showToast('Error', 'Object name not found in the row data', 'error');
                    return;
                }
                
                // Get the exact permission type expected by the server
                let serverPermissionType;
                if (permissionType === 'read') serverPermissionType = 'read';
                if (permissionType === 'create') serverPermissionType = 'create';
                if (permissionType === 'edit') serverPermissionType = 'edit';
                if (permissionType === 'delete') serverPermissionType = 'delete';
                
                // Check for dependency issues in the client side first
                if (currentValue === 'Denied' && serverPermissionType !== 'read') {
                    // Trying to enable a dependent permission (create/edit/delete)
                    if (row['readText'] === 'Denied') {
                        this.showToast(
                            'Dependency Required',
                            `Cannot enable ${serverPermissionType} permission without enabling Read permission first`,
                            'warning'
                        );
                        return;
                    }
                }
                
                // New value will be the opposite
                const newValue = currentValue === 'Allowed' ? false : true;
                const newTextValue = currentValue === 'Allowed' ? 'Denied' : 'Allowed';
                const newIconValue = currentValue === 'Allowed' ? 'utility:close' : 'utility:check';
                
                // Show special warning if disabling Read permission
                if (serverPermissionType === 'read' && !newValue) {
                    // Check if other permissions are enabled
                    const otherPermsEnabled = 
                        row['createText'] === 'Allowed' || 
                        row['editText'] === 'Allowed' || 
                        row['deleteText'] === 'Allowed';
                    
                    if (otherPermsEnabled) {
                        this.showToast(
                            'Related Permissions Will Be Updated',
                            'Disabling Read permission will also disable Create, Edit, and Delete permissions',
                            'warning'
                        );
                    }
                }
                
                // Immediately update the UI to show the change while waiting for server response
                // Update the row in the data table to show the changed values
                const updatedRow = {...row};
                updatedRow[permissionType + 'Text'] = newTextValue;
                updatedRow[permissionType + 'Icon'] = newIconValue;
                
                // If disabling Read, also visually update dependent permissions
                if (permissionType === 'read' && !newValue) {
                    updatedRow['createText'] = 'Denied';
                    updatedRow['createIcon'] = 'utility:close';
                    updatedRow['editText'] = 'Denied';
                    updatedRow['editIcon'] = 'utility:close';
                    updatedRow['deleteText'] = 'Denied';
                    updatedRow['deleteIcon'] = 'utility:close';
                }
                
                // Find and update the row in the data collection
                if (this.objectPermissions) {
                    const index = this.objectPermissions.findIndex(obj => obj.objectName === row.objectName);
                    if (index !== -1) {
                        // Create a new array with the updated row
                        this.objectPermissions = [
                            ...this.objectPermissions.slice(0, index),
                            updatedRow,
                            ...this.objectPermissions.slice(index + 1)
                        ];
                    }
                }
                
                // Prepare the permission update - ensure it's properly formatted
                const permUpdate = {
                    objectName: row.objectName,
                    permissions: {}
                };
                permUpdate.permissions[serverPermissionType] = newValue;
                
                //console.log('Updating permission:', JSON.stringify(permUpdate));
                
                // Show a toast that we're processing the update
                this.showToast('Processing', 'Updating permission...', 'info');
                
                // Call the server to update permissions
                this.updatePermission(permUpdate, permissionType, newValue);
                    
            } catch (error) {
                //console.error('Unexpected error in handlePermissionAction:', error);
                this.showToast('Error', 'An unexpected error occurred: ' + error.message, 'error');
            }
        } 
        // If this is the view details action
        else if (actionName === 'view_details') {
            this.showSourcesForObject(row.objectName);
        }
    }

    // Helper method to handle the permission update process
    async updatePermission(permUpdate, permissionType, newValue) {
        try {
            // Check if this is a source-specific update (from the modal)
            const isSourceUpdate = permUpdate.sourceId !== undefined && permUpdate.sourceId !== null;
            
            // Log what type of update we're doing
           // //console.log(isSourceUpdate ? 'Updating source-specific permission:' : 'Updating general permission:', JSON.stringify(permUpdate));
            
            // Call the server to update permissions
            const result = await updateObjectPermissions({
                userId: this.selectedUserId,
                permissionUpdates: JSON.stringify([permUpdate])
            });
            
           // //console.log('Permission update result:', result);
            
            if (result && result.success) {
                // Success - show success message
                this.showToast('Success', 'Permission updated successfully', 'success');
                
                // If dependencies were updated, show a message about it
                if (result.dependenciesUpdated) {
                    this.showToast(
                        'Related Permissions Updated', 
                        'When Read permission is disabled, Create, Edit, and Delete permissions are also disabled automatically', 
                        'info'
                    );
                }
                
                // If there are other important messages, display them
                if (result.messages && result.messages.length > 0) {
                    // Skip showing the first success message which is redundant
                    const importantMessages = result.messages.filter(msg => 
                        !msg.includes('Successfully updated') && 
                        !msg.includes('No permissions needed updating')
                    );
                    
                    if (importantMessages.length > 0) {
                        this.showToast('Update Information', importantMessages[0], 'info');
                    }
                }
                
                // For source updates, the UI is already updated in the handleSourcePermissionAction
                // For general updates, the UI is already updated in the handlePermissionAction
                
                // Refresh object permissions list if this was a general update (not from sources modal)
                if (!isSourceUpdate) {
                    // Refresh the object permissions data to ensure up-to-date info
                    this.refreshObjectPermissions();
                }
            } else {
                // Show error message
                let errorMessage = 'Failed to update permission.';
                
                // Add any server messages
                if (result && result.messages && result.messages.length > 0) {
                    errorMessage = result.messages[0] || errorMessage;
                }
                
                this.showToast('Error', errorMessage, 'error');
                
                // Always refresh data to ensure it's in sync with the server
                if (isSourceUpdate) {
                    // If it was a source update that failed, refresh the sources display
                    this.getObjectPermissionSources(this.selectedObjectForSources);
                } else {
                    // Otherwise refresh the main object permissions
                    this.refreshObjectPermissions();
                }
            }
        } catch (error) {
            //console.error('Error updating permissions:', error);
            
            // Provide detailed error message
            let errorMessage = 'Error updating permission: ';
            if (error.body && error.body.message) {
                errorMessage += error.body.message;
            } else if (error.message) {
                errorMessage += error.message;
            } else {
                errorMessage += 'Unknown error';
            }
            
            this.showToast('Error', errorMessage, 'error');
            
            // Determine what data to refresh based on where the update came from
            const isSourceUpdate = permUpdate.sourceId !== undefined && permUpdate.sourceId !== null;
            
            if (isSourceUpdate) {
                // If it was a source update that failed, refresh the sources display
                this.getObjectPermissionSources(this.selectedObjectForSources);
            } else {
                // Otherwise refresh the main object permissions
                this.refreshObjectPermissions();
            }
        }
    }

    // Refresh object permissions after changes
    refreshObjectPermissions() {
        // Short timeout to avoid UI locks
        setTimeout(() => {
            try {
                this.loadObjectPermissions();
            } catch (error) {
                //console.error('Error refreshing object permissions:', error);
            }
        }, 500);
    }

    // Keep the original row action handler to maintain backward compatibility with any existing code
    handleObjectRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        if (action.name === 'view_details') {
            this.showSourcesForObject(row.objectName);
        }
    }

    // Method to handle permission actions from the sources modal
    handleSourcePermissionAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
        ////console.log('Source permission action clicked:', actionName);
        ////console.log('Source row data:', JSON.stringify(row));
        
        // If this is a toggle source permission action
        if (actionName.startsWith('toggle_source_')) {
            try {
                // Get the permission type from the action name (remove 'toggle_source_' prefix)
                const permissionType = actionName.split('toggle_source_')[1];
                
                // Current value (Allowed or Denied)
                const currentValue = row[permissionType + 'Permission'];
                
                // Make sure we have a valid sourceName
                if (!row.sourceName || !this.selectedObjectForSources) {
                    this.showToast('Error', 'Source name or object name not found', 'error');
                    return;
                }
                
                // Check if this is a profile permission - those generally can't be modified directly
                if (row.sourceType === 'Profile') {
                    this.showToast('Warning', 'Profile permissions cannot be directly modified from this interface. Please use the Salesforce Setup menu.', 'warning');
                    return;
                }
                
                // Get the exact permission type expected by the server
                let serverPermissionType;
                if (permissionType === 'read') serverPermissionType = 'read';
                if (permissionType === 'create') serverPermissionType = 'create';
                if (permissionType === 'edit') serverPermissionType = 'edit';
                if (permissionType === 'delete') serverPermissionType = 'delete';
                
                // Check for dependency issues in the client side first
                if (currentValue === 'Denied' && serverPermissionType !== 'read') {
                    // Trying to enable a dependent permission (create/edit/delete)
                    if (row['readPermission'] === 'Denied') {
                        this.showToast(
                            'Dependency Required',
                            `Cannot enable ${serverPermissionType} permission without enabling Read permission first`,
                            'warning'
                        );
                        return;
                    }
                }
                
                // New value will be the opposite
                const newValue = currentValue === 'Allowed' ? false : true;
                const newTextValue = currentValue === 'Allowed' ? 'Denied' : 'Allowed';
                const newIconValue = currentValue === 'Allowed' ? 'utility:close' : 'utility:check';
                
                // Show special warning if disabling Read permission
                if (serverPermissionType === 'read' && !newValue) {
                    // Check if other permissions are enabled
                    const otherPermsEnabled = 
                        row['createPermission'] === 'Allowed' || 
                        row['editPermission'] === 'Allowed' || 
                        row['deletePermission'] === 'Allowed';
                    
                    if (otherPermsEnabled) {
                        this.showToast(
                            'Related Permissions Will Be Updated',
                            'Disabling Read permission will also disable Create, Edit, and Delete permissions',
                            'warning'
                        );
                    }
                }
                
                // Immediately update the UI to show the change while waiting for server response
                // Update the row in the data table to show the changed values
                const updatedRow = {...row};
                updatedRow[permissionType + 'Permission'] = newTextValue;
                updatedRow[permissionType + 'Icon'] = newIconValue;
                
                // If disabling Read, also visually update dependent permissions
                if (permissionType === 'read' && !newValue) {
                    updatedRow['createPermission'] = 'Denied';
                    updatedRow['createIcon'] = 'utility:close';
                    updatedRow['editPermission'] = 'Denied';
                    updatedRow['editIcon'] = 'utility:close';
                    updatedRow['deletePermission'] = 'Denied';
                    updatedRow['deleteIcon'] = 'utility:close';
                }
                
                // Find and update the row in the data collection
                if (this.objectSourcesList) {
                    const index = this.objectSourcesList.findIndex(source => source.sourceName === row.sourceName);
                    if (index !== -1) {
                        // Create a new array with the updated row
                        this.objectSourcesList = [
                            ...this.objectSourcesList.slice(0, index),
                            updatedRow,
                            ...this.objectSourcesList.slice(index + 1)
                        ];
                    }
                }
                
                // Prepare the permission update - ensure it's properly formatted
                const permUpdate = {
                    objectName: this.selectedObjectForSources,
                    sourceId: row.sourceId || null, // This would need to be included in the data from the server
                    permissions: {}
                };
                permUpdate.permissions[serverPermissionType] = newValue;
                
                ////console.log('Updating source permission:', JSON.stringify(permUpdate));
                
                // Show a toast that we're processing the update
                this.showToast('Processing', 'Updating permission...', 'info');
                
                // Call the server to update permissions
                this.updatePermission(permUpdate, permissionType, newValue);
            } catch (error) {
                //console.error('Unexpected error in handleSourcePermissionAction:', error);
                this.showToast('Error', 'An unexpected error occurred: ' + error.message, 'error');
            }
        }
    }

    // Toggle instructions visibility
    toggleInstructions(event) {
        // Prevent toggling if clicking on the Tour button or its children
        const path = event?.composedPath();
        if (path && path.some(element => element.classList && 
            (element.classList.contains('tour-button') || 
             element.closest('.tour-button')))) {
            return;
        }
        
        this.isInstructionsExpanded = !this.isInstructionsExpanded;
        // Save preference to localStorage
        localStorage.setItem('uam_instructions_expanded', this.isInstructionsExpanded);
    }

    // Handle Tour button click - prevent propagation to parent
    handleTourButton(event) {
        // Stop the event from bubbling up to the instructions-header div
        event.stopPropagation();
        this.startTour();
    }

    // Add these properties to the component class
    @track fieldPermissionsByObject = {};
    @track expandedObjects = new Set();
    @track isLoadingFields = false;
    @track objectsWithPermissions = [];
    @track fieldCountsByObject = {}; // Added to store field counts by object
    @track fieldFiltersByObject = {}; // Track field filters per object

    // Get appropriate icon for Salesforce objects
    getObjectIcon(objectName) {
        // Handle null or undefined object names
        if (!objectName) {
            ////console.log('Received null or undefined object name');
            return 'standard:entity';
        }
        
       // //console.log(`Getting icon for object: ${objectName}`);
        
        const standardObjects = {
            'Account': 'standard:account',
            'Contact': 'standard:contact',
            'Lead': 'standard:lead',
            'Opportunity': 'standard:opportunity',
            'Case': 'standard:case',
            'Task': 'standard:task',
            'User': 'standard:user',
            'Campaign': 'standard:campaign',
            'Contract': 'standard:contract',
            'Event': 'standard:event',
            'Order': 'standard:orders',
            'Product2': 'standard:product',
            'Asset': 'standard:asset',
            'Solution': 'standard:solution',
            'Pricebook2': 'standard:pricebook',
            'Report': 'standard:report',
            'Dashboard': 'standard:dashboard',
            'Profile': 'standard:profile',
            'Group': 'standard:groups',
            'Knowledge__kav': 'standard:knowledge',
            'ContentDocument': 'standard:document',
            'ContentVersion': 'standard:file',
            'PermissionSet': 'standard:permission_set',
            'ApprovalSubmission': 'standard:approval',
            'ApprovalSubmissionDetail': 'standard:approval',
            'ApprovalWorkItem': 'standard:approval',
            'ApptBundleConfig': 'standard:service_appointment',
            'ApptBundlePolicy': 'standard:service_appointment',
            'Asset': 'standard:asset',
            'AssetRelationship': 'standard:asset_relationship',
            'AssignedResource': 'standard:resource',
            'AttributeDefinition': 'standard:custom_field',
            'AuthorizationForm': 'standard:form',
            'AuthorizationFormConsent': 'standard:form',
            'AuthorizationFormText': 'standard:form',
            'BusinessBrand': 'standard:brand',
            'Campaign': 'standard:campaign',
            'Case': 'standard:case',
            'ConsumptionRate': 'standard:metrics'
        };
        
        // Check if it's a known standard object
        if (standardObjects[objectName]) {
          //  //console.log(`Found standard object icon for ${objectName}: ${standardObjects[objectName]}`);
            return standardObjects[objectName];
        }
        
        // Check for custom objects (ends with __c)
        if (objectName.endsWith('__c')) {
           // //console.log(`Identified ${objectName} as a custom object`);
            return 'standard:custom_object';
        }
        
        // Check for custom metadata types (ends with __mdt)
        if (objectName.endsWith('__mdt')) {
          //  //console.log(`Identified ${objectName} as a custom metadata type`);
            return 'standard:custom_metadata_type';
        }
        
        // Check for platform events (ends with __e)
        if (objectName.endsWith('__e')) {
           // //console.log(`Identified ${objectName} as a platform event`);
            return 'standard:event';
        }
        
        // Handle namespace objects (containing periods)
        if (objectName.includes('.')) {
           // //console.log(`Identified ${objectName} as an object with namespace`);
            // If it contains a period and ends with __c, it's a custom object in a namespace
            if (objectName.endsWith('__c')) {
                return 'standard:custom_object';
            }
            return 'standard:entity';
        }
        
        // Default to standard entity for other standard objects
        ////console.log(`Using default icon for ${objectName}`);
        return 'standard:entity';
    }
    
    // Add a getter that processes the list of objects to include icon information
    get objectsWithIcons() {
        if (!this.objectsWithPermissions) return [];
        
        return this.objectsWithPermissions.map(objectName => {
            const isExpanded = this.expandedObjects.has(objectName);
            const fieldsAll = this.fieldPermissionsByObject[objectName] || [];
            const key = `obj-${objectName}`;
            const fieldsRowKey = `fields-${objectName}`;
            const headerKey = `header-${objectName}`;
            const noFieldsKey = `no-fields-${objectName}`;
            const headerClass = "field-header";
            
            // Filter fields based on search term if there is one for this object
            const filterTerm = this.fieldFiltersByObject[objectName] || '';
            const fields = filterTerm 
                ? fieldsAll.filter(field => 
                    field.field && field.field.toLowerCase().includes(filterTerm))
                : fieldsAll;
            
            // Use the preloaded field count from server if available, otherwise show the count of loaded fields
            // or 0 if no fields are loaded yet
            const fieldCount = (this.fieldCountsByObject && this.fieldCountsByObject[objectName]) || 
                              (fieldsAll.length > 0 ? fieldsAll.length : '0');
            
            // Add filter info to the object data
            const filterInfo = filterTerm 
                ? `Showing ${fields.length} of ${fieldsAll.length} fields` 
                : '';
            
            return {
                objectName,
                iconName: this.getObjectIcon(objectName),
                isExpanded,
                fields,
                fieldCount,
                fieldsAll,
                filterTerm,
                filterInfo,
                key,
                fieldsRowKey,
                headerKey,
                noFieldsKey,
                headerClass,
                chevronIcon: isExpanded ? 'utility:chevrondown' : 'utility:chevronright',
                expandButtonLabel: isExpanded ? 'Collapse' : 'Expand',
                expandButtonIcon: isExpanded ? 'utility:chevronup' : 'utility:chevrondown'
            };
        });
    }

    // Handle clicking on the entire object row to expand/collapse
    handleObjectRowClick(event) {
        // Prevent if clicking on the button or button icon which is handled separately
        if (event.target.tagName === 'BUTTON' || 
            event.target.closest('lightning-button') || 
            event.target.closest('lightning-button-icon')) {
            return;
        }
        
        // Get the object name from the row's data attribute
        const objectName = event.currentTarget.dataset.objectName;
        if (objectName) {
            this.handleObjectExpand({ currentTarget: { dataset: { objectName } } });
        }
    }

    /**
     * Handles exporting field permissions to CSV
     * Exports all field permissions from all objects
     */
    async handleFieldPermissionsToExcel() {
        try {
            if (!this.objectsWithPermissions || this.objectsWithPermissions.length === 0) {
                this.showToast('No Data', 'There are no field permissions to export.', 'info');
                return;
            }
            
            // Show loading toast
            this.showToast('Loading Data', 'Preparing field permissions for export...', 'info');
            
            const rows = [];
            // Add headers
            rows.push(['Object Name', 'Field Name', 'Read Access', 'Edit Access']);
            
            // Track which objects need their fields loaded
            const objectsToLoad = [];
            for (const objectName of this.objectsWithPermissions) {
                if (!this.fieldPermissionsByObject[objectName] || this.fieldPermissionsByObject[objectName].length === 0) {
                    objectsToLoad.push(objectName);
                }
            }
            
            // If we need to load fields for objects, show a confirmation if there are many objects
            if (objectsToLoad.length > 5) {
                // Use confirm dialog to verify before loading many objects
                if (!confirm(`This will load field permissions for ${objectsToLoad.length} objects. This may take some time. Continue?`)) {
                    this.showToast('Export Cancelled', 'CSV export was cancelled', 'info');
                    return;
                }
            }
            
            // Load fields for objects that haven't been loaded yet (up to 5 at a time)
            if (objectsToLoad.length > 0) {
                const batchSize = 5;
                for (let i = 0; i < objectsToLoad.length; i += batchSize) {
                    const batch = objectsToLoad.slice(i, i + batchSize);
                    // Use Promise.all to load multiple objects in parallel
                    await Promise.all(batch.map(objectName => this.loadFieldsForObject(objectName)));
                }
            }
            
            // Now add all fields for all objects to the CSV
            for (const objectName of this.objectsWithPermissions) {
                const fields = this.fieldPermissionsByObject[objectName] || [];
                if (fields.length === 0) {
                    // If we still don't have fields after trying to load them, add a placeholder row
                    rows.push([objectName, '(No fields available)', 'N/A', 'N/A']);
                    continue;
                }
                
                // Add all fields for this object
                for (const field of fields) {
                    rows.push([
                        objectName,
                        field.field,
                        field.PermissionsRead ? 'Yes' : 'No',
                        field.PermissionsEdit ? 'Yes' : 'No'
                    ]);
                }
            }
            
            // Add fields count information
            rows.push([]);
            rows.push(['Summary Information']);
            rows.push(['Total Objects', this.objectsWithPermissions.length.toString()]);
            rows.push(['Total Fields', rows.length - 5]);  // Subtract headers and summary rows
            
            // Convert the rows to CSV format
            let csvContent = '';
            rows.forEach(row => {
                // Properly handle commas and quotes in CSV values
                const formattedRow = row.map(cell => {
                    if (cell === undefined || cell === null) return '';
                    // Convert to string and handle special characters
                    const cellStr = String(cell);
                    // If the cell contains commas, quotes, or newlines, enclose it in quotes
                    if (cellStr.includes(',') || cellStr.includes('"') || cellStr.includes('\n')) {
                        // Double up any quotes
                        return `"${cellStr.replace(/"/g, '""')}"`;
                    }
                    return cellStr;
                });
                csvContent += formattedRow.join(',') + '\n';
            });
            
            // Create a download link
            const encodedUri = encodeURI('data:text/csv;charset=utf-8,' + csvContent);
            const link = document.createElement('a');
            link.setAttribute('href', encodedUri);
            
            // Get user name for filename
            const userName = this.userDetails?.userName || 'user';
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            link.setAttribute('download', `${userName}_field_permissions_${timestamp}.csv`);
            document.body.appendChild(link);
            
            // Trigger the download
            link.click();
            document.body.removeChild(link);
            
            this.showToast('Success', 'Field permissions exported successfully', 'success');
        } catch (error) {
            //console.error('Error exporting field permissions:', error);
            this.showToast('Error', 'Failed to export field permissions: ' + this.getErrorMessage(error), 'error');
        }
    }

    /**
     * Handles field filtering within an expanded object
     * @param {Event} event - The keyup event from the search input
     */
    handleFieldFilter(event) {
        const searchTerm = event.target.value.toLowerCase();
        const objectName = event.target.dataset.objectName;
        
        // Store the filter term for this object
        this.fieldFiltersByObject[objectName] = searchTerm;
        
        // Force a refresh of the UI to show filtered fields
        this.objectsWithPermissions = [...this.objectsWithPermissions];
    }

    /**
     * Clears the field filter for a specific object
     * @param {Event} event - The click event from the clear filter link
     */
    clearFieldFilter(event) {
        const objectName = event.currentTarget.dataset.objectName;
        
        if (objectName) {
            // Clear the filter for this object
            delete this.fieldFiltersByObject[objectName];
            
            // Find the search input and clear its value
            const searchInput = this.template.querySelector(`lightning-input[data-object-name="${objectName}"]`);
            if (searchInput) {
                searchInput.value = '';
            }
            
            // Force a refresh of the UI
            this.objectsWithPermissions = [...this.objectsWithPermissions];
        }
    }

    // Add class variables to track sharing rules loading state
    @track isLoadingSharingRules = false;
    @track isRefreshingSharingRules = false;

    /**
     * Handles exporting sharing rules to CSV
     */
    handleSharingRulesToExcel() {
        try {
            if (!this.sharingRules || this.sharingRules.length === 0) {
                this.showToast('No Data', 'There are no sharing rules to export.', 'info');
                return;
            }
            
            const rows = [];
            // Add headers
            rows.push(['Object Name', 'Rule Name', 'Rule Type', 'Shared With']);
            
            // Add data rows
            this.sharingRules.forEach(rule => {
                rows.push([
                    rule.objectApiName || '',
                    rule.ruleName || '',
                    rule.ruleType || '',
                    rule.sharedWith || ''
                ]);
            });
            
            // Convert the rows to CSV format
            let csvContent = '';
            rows.forEach(row => {
                // Properly handle commas and quotes in CSV values
                const formattedRow = row.map(cell => {
                    if (cell === undefined || cell === null) return '';
                    // Convert to string and handle special characters
                    const cellStr = String(cell);
                    // If the cell contains commas, quotes, or newlines, enclose it in quotes
                    if (cellStr.includes(',') || cellStr.includes('"') || cellStr.includes('\n')) {
                        // Double up any quotes
                        return `"${cellStr.replace(/"/g, '""')}"`;
                    }
                    return cellStr;
                });
                csvContent += formattedRow.join(',') + '\n';
            });
            
            // Create a download link
            const encodedUri = encodeURI('data:text/csv;charset=utf-8,' + csvContent);
            const link = document.createElement('a');
            link.setAttribute('href', encodedUri);
            
            // Get user name for filename
            const userName = this.userDetails?.userName || 'user';
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            link.setAttribute('download', `${userName}_sharing_rules_${timestamp}.csv`);
            document.body.appendChild(link);
            
            // Trigger the download
            link.click();
            document.body.removeChild(link);
            
            this.showToast('Success', 'Sharing rules exported successfully', 'success');
        } catch (error) {
            //console.error('Error exporting sharing rules:', error);
            this.showToast('Error', 'Failed to export sharing rules: ' + this.getErrorMessage(error), 'error');
        }
    }

    // Audit Trail Event Handlers
    handleAuditStartDateChange(event) {
        this.auditStartDate = event.target.value;
    }

    handleAuditEndDateChange(event) {
        this.auditEndDate = event.target.value;
    }

    handleMetadataTypeChange(event) {
        this.selectedMetadataType = event.target.value;
    }

    async loadAuditTrailData() {
        if (!this.selectedUserId) {
            this.showToast('Error', 'Please select a user first.', 'error');
            return;
        }

        if (!this.auditStartDate || !this.auditEndDate) {
            this.showToast('Error', 'Please select both start and end dates.', 'error');
            return;
        }

        this.isLoadingAuditData = true;
        try {
            const result = await getSetupAuditTrail({
                userId: this.selectedUserId,
                startDate: this.auditStartDate,
                endDate: this.auditEndDate,
                metadataType: this.selectedMetadataType
            });
            
            // Transform the data to match our column structure
            this.auditTrailData = result.map(record => ({
                id: record.Id,
                CreatedDate: record.CreatedDate,
                CreatedByName: record.CreatedBy?.Name || 'Unknown',
                Action: record.Action,
                Section: record.Section,
                DelegateUser: record.DelegateUser || '',
                Display: record.Display || ''
            }));
            
            this.auditTrailCount = this.auditTrailData.length;
            this.showToast('Success', `Loaded ${this.auditTrailCount} audit trail records.`, 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to load audit trail data: ' + error.body?.message || error.message, 'error');
        } finally {
            this.isLoadingAuditData = false;
        }
    }

    generateMockAuditData() {
        // Generate mock audit trail data for demonstration
        const mockData = [];
        const actions = ['Created', 'Updated', 'Deleted', 'Activated', 'Deactivated'];
        const sections = ['User', 'Profile', 'Permission Set', 'Role', 'Custom Object'];
        
        for (let i = 0; i < 20; i++) {
            const createdDate = new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000);
            mockData.push({
                id: `audit_${i}`,
                CreatedDate: createdDate.toISOString(),
                CreatedByName: `User ${Math.floor(Math.random() * 10) + 1}`,
                Action: actions[Math.floor(Math.random() * actions.length)],
                Section: sections[Math.floor(Math.random() * sections.length)],
                DelegateUser: Math.random() > 0.5 ? `Delegate ${Math.floor(Math.random() * 5) + 1}` : '',
                Display: `Sample audit entry ${i + 1}`
            });
        }
        
        return mockData.sort((a, b) => new Date(b.CreatedDate) - new Date(a.CreatedDate));
    }

    clearAuditFilters() {
        this.auditStartDate = '';
        this.auditEndDate = '';
        this.selectedMetadataType = '';
        this.auditTrailData = [];
        this.auditTrailCount = 0;
    }

    handleAuditSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.auditSortedBy = fieldName;
        this.auditSortedDirection = sortDirection;
        
        // Sort the audit trail data
        this.auditTrailData = [...this.auditTrailData].sort((a, b) => {
            let aVal = a[fieldName] || '';
            let bVal = b[fieldName] || '';
            
            if (fieldName === 'CreatedDate') {
                aVal = new Date(aVal);
                bVal = new Date(bVal);
            }
            
            if (sortDirection === 'asc') {
                return aVal > bVal ? 1 : -1;
            }
            return aVal < bVal ? 1 : -1;
        });
    }

    // Risky Users Methods
    
    /**
     * Handle click on Risky Users button - Switch to full-screen view
     */
    handleRiskyUsersClick() {
        this.showRiskyUsersView = true;
        this.selectedRiskyUser = null;
        this.currentRiskyUsersPage = 1;
        this.loadRiskyUsers();
    }
    
    /**
     * Handle back to User Access Manager
     */
    handleBackToUAM() {
        this.showRiskyUsersView = false;
        this.selectedRiskyUser = null;
        this.riskyUsersError = null;
        this.riskyUsersData = [];
    }
    
    /**
     * Handle back to risky users list from user detail
     */
    handleBackToRiskyUsersList() {
        this.selectedRiskyUser = null;
    }
    
    /**
     * Handle row action in risky users table
     */
    handleRiskyUsersRowAction(event) {
        try {
            const action = event.detail.action;
            const row = event.detail.row;
            
            if (action.name === 'analyze_risk') {
                // Handle analyze risk action
                this.analyzeUserRisk(row);
            }
        } catch (error) {
            console.error('Error handling row action:', error);
            this.showToast('Error', 'Failed to process action', 'error');
        }
    }
    
    /**
     * Analyze user risk
     */
    analyzeUserRisk(user) {
        try {
            // Set the selected user for analysis
            this.selectedUserId = user.userId;
            
            // Switch back to main view to show user analysis
            this.showRiskyUsersView = false;
            
            // Trigger user change to load data for the selected user
            const userChangeEvent = {
                detail: {
                    value: user.userId
                }
            };
            this.handleUserChange(userChangeEvent);
            
            this.showToast('Success', `Analyzing risk for ${user.userName}`, 'success');
        } catch (error) {
            console.error('Error analyzing user risk:', error);
            this.showToast('Error', 'Failed to analyze user risk', 'error');
        }
    }
    
    /**
     * Load risky users data from server
     */
    async loadRiskyUsers() {
        try {
            this.isLoadingRiskyUsers = true;
            this.riskyUsersError = null;
            
            const response = await getRiskyUsers({
                pageNumber: 1,
                pageSize: 1000 // Load all users for client-side sorting and pagination
            });
            
            if (response) {
                this.riskyUsersData = response.users || [];
                this.totalRiskyUsers = response.totalCount || 0;
                
                // Process the data to ensure proper formatting
                this.riskyUsersData = this.riskyUsersData.map(user => ({
                    ...user,
                    riskBadgeClass: this.getRiskBadgeClass(user.riskLevel)
                }));
                
                // Calculate risk level counts
                this.calculateRiskLevelCounts();
            }
        } catch (error) {
            this.riskyUsersError = error.body?.message || error.message || 'Error loading risky users';
            this.showErrorToast('Error Loading Risky Users', this.riskyUsersError);
        } finally {
            this.isLoadingRiskyUsers = false;
        }
    }
    
    /**
     * Handle previous page for risky users
     */
    handleRiskyUsersPrevious() {
        if (this.currentRiskyUsersPage > 1) {
            this.currentRiskyUsersPage--;
            // No need to reload data, just update the page view
        }
    }
    
    /**
     * Handle next page for risky users
     */
    handleRiskyUsersNext() {
        if (!this.isLastRiskyUsersPage) {
            this.currentRiskyUsersPage++;
            // No need to reload data, just update the page view
        }
    }
    
    /**
     * Get CSS class for risk level badge
     */
    getRiskBadgeClass(riskLevel) {
        switch (riskLevel) {
            case 'Critical':
                return 'slds-badge slds-theme_error';
            case 'High':
                return 'slds-badge slds-theme_warning';
            case 'Medium':
                return 'slds-badge slds-theme_info';
            case 'Low':
                return 'slds-badge slds-theme_success';
            default:
                return 'slds-badge slds-theme_default';
        }
    }
    
    /**
     * Calculate risk level counts for summary stats
     */
    calculateRiskLevelCounts() {
        this.criticalUsersCount = 0;
        this.highRiskUsersCount = 0;
        this.mediumRiskUsersCount = 0;
        this.lowRiskUsersCount = 0;
        
        this.riskyUsersData.forEach(user => {
            switch (user.riskLevel) {
                case 'Critical':
                    this.criticalUsersCount++;
                    break;
                case 'High':
                    this.highRiskUsersCount++;
                    break;
                case 'Medium':
                    this.mediumRiskUsersCount++;
                    break;
                case 'Low':
                    this.lowRiskUsersCount++;
                    break;
            }
        });
    }
    
    // Risky Users Getters
    
    /**
     * Get sorted risky users by priority (Critical > High > Medium > Low)
     */
    get sortedRiskyUsers() {
        if (!this.riskyUsersData || this.riskyUsersData.length === 0) {
            return [];
        }
        
        const riskPriority = {
            'Critical': 4,
            'High': 3,
            'Medium': 2,
            'Low': 1
        };
        
        return [...this.riskyUsersData].sort((a, b) => {
            // First sort by risk priority (highest first)
            const priorityDiff = (riskPriority[b.riskLevel] || 0) - (riskPriority[a.riskLevel] || 0);
            if (priorityDiff !== 0) {
                return priorityDiff;
            }
            
            // Then by risk score (highest first)
            const scoreDiff = (b.riskScore || 0) - (a.riskScore || 0);
            if (scoreDiff !== 0) {
                return scoreDiff;
            }
            
            // Finally by name (alphabetical)
            return (a.userName || '').localeCompare(b.userName || '');
        });
    }
    
    /**
     * Get paginated risky users for current page with priority-based flow
     * Critical users appear first across all pages, followed by high, medium, then low
     */
    get paginatedRiskyUsers() {
        const sortedUsers = this.sortedRiskyUsers || [];
        
        if (sortedUsers.length === 0) {
            return [];
        }
        
        // Calculate pagination slice for current page
        const startIndex = (this.currentRiskyUsersPage - 1) * this.riskyUsersPageSize;
        const endIndex = startIndex + this.riskyUsersPageSize;
        
        return sortedUsers.slice(startIndex, endIndex);
    }
    
    /**
     * Get page info string for risky users with priority flow indication
     */
    get riskyUsersPageInfo() {
        const sortedUsers = this.sortedRiskyUsers || [];
        
        if (sortedUsers.length === 0) {
            return 'No users found';
        }
        
        const startIndex = (this.currentRiskyUsersPage - 1) * this.riskyUsersPageSize;
        const endIndex = Math.min(startIndex + this.riskyUsersPageSize, sortedUsers.length);
        const start = startIndex + 1;
        const end = endIndex;
        
        // Get risk level distribution for current page
        const currentPageUsers = sortedUsers.slice(startIndex, endIndex);
        const riskCounts = {
            'Critical': 0,
            'High': 0,
            'Medium': 0,
            'Low': 0
        };
        
        currentPageUsers.forEach(user => {
            if (Object.prototype.hasOwnProperty.call(riskCounts, user.riskLevel)) {
                riskCounts[user.riskLevel]++;
            }
        });
        
        const riskSummary = Object.entries(riskCounts)
            .filter(([, count]) => count > 0)
            .map(([riskLevel, count]) => `${count} ${riskLevel}`)
            .join(', ');
        
        return `${start}-${end} of ${sortedUsers.length} users (${riskSummary})`;
    }
    
    /**
     * Check if this is the first page of risky users
     */
    get isFirstRiskyUsersPage() {
        return this.currentRiskyUsersPage <= 1;
    }
    
    /**
     * Check if this is the last page of risky users
     */
    get isLastRiskyUsersPage() {
        const sortedUsers = this.sortedRiskyUsers || [];
        return (this.currentRiskyUsersPage * this.riskyUsersPageSize) >= sortedUsers.length;
    }
}