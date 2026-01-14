import { LightningElement, api, track } from 'lwc';
import getSystemPermissions from '@salesforce/apex/PermissionsManagerController.getSystemPermissions';
import getSystemPermissionAccessWithUserFields from '@salesforce/apex/PermissionsManagerController.getSystemPermissionAccessWithUserFields';
import getSystemPermissionAccessOptimized from '@salesforce/apex/PermissionsManagerController.getSystemPermissionAccessOptimized';
import getSystemPermissionAccessUltraOptimized from '@salesforce/apex/PermissionsManagerController.getSystemPermissionAccessUltraOptimized';
import getMultipleSystemPermissionsAccess from '@salesforce/apex/PermissionsManagerController.getMultipleSystemPermissionsAccess';
import exportSingleSystemPermissionAnalysis from '@salesforce/apex/PermissionsManagerController.exportSingleSystemPermissionAnalysis';
import exportMultipleSystemPermissionsAnalysis from '@salesforce/apex/PermissionsManagerController.exportMultipleSystemPermissionsAnalysis';
import exportSystemPermissionsWithUserFields from '@salesforce/apex/PermissionsManagerController.exportSystemPermissionsWithUserFields';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import XLSX from '@salesforce/resourceUrl/xlsx';
import getProfiles from '@salesforce/apex/PermissionsManagerController.getProfiles';
import getPermissionSets from '@salesforce/apex/PermissionsManagerController.getPermissionSets';
import getUsers from '@salesforce/apex/PermissionsManagerController.getUsers';
import getUsersPaginated from '@salesforce/apex/PermissionsManagerController.getUsersPaginated';
import getUserFields from '@salesforce/apex/PermissionsManagerController.getUserFields';
import saveTemplate from '@salesforce/apex/PermissionsManagerController.saveTemplate';
import getTemplates from '@salesforce/apex/PermissionsManagerController.getTemplates';
import checkPermissionsTemplateExists from '@salesforce/apex/PermissionsManagerController.checkPermissionsTemplateExists';
import createPermissionsTemplateObject from '@salesforce/apex/PermissionsManagerController.createPermissionsTemplateObject';
import initializeAutomaticTemplates from '@salesforce/apex/PermissionsManagerController.initializeAutomaticTemplates';
import exportTemplateWithSplitting from '@salesforce/apex/PermissionsManagerController.exportTemplateWithSplitting';
import getTemplateDataForSplit from '@salesforce/apex/PermissionsManagerController.getTemplateDataForSplit';
import getPermissionSetsWithAssignments from '@salesforce/apex/PermissionsManagerController.getPermissionSetsWithAssignments';
import getActiveUsersPaginated from '@salesforce/apex/PermissionsManagerController.getActiveUsersPaginated';
import getUserFieldsForDisplay from '@salesforce/apex/PermissionsManagerController.getUserFieldsForDisplay';
import getSystemPermissionAccessWithDynamicFields from '@salesforce/apex/PermissionsManagerController.getSystemPermissionAccessWithDynamicFields';
import getAvailableLicenseTypes from '@salesforce/apex/UserPermController.getAvailableLicenseTypes';
import getActiveUsersPaginatedByLicense from '@salesforce/apex/PermissionsManagerController.getActiveUsersPaginatedByLicense';
import isCurrentUserSystemAdmin from '@salesforce/apex/PermissionsManagerController.isCurrentUserSystemAdmin';
import getPermissionSetGroupsPaginated from '@salesforce/apex/PermissionsManagerController.getPermissionSetGroupsPaginated';
// Removed unused import: getPermissionSetGroupSystemPermissions
/**
 * @description Component for displaying and analyzing system permissions
 */
export default class SystemPermissionsPanel extends LightningElement {
    @api title = 'System Permissions';
    @track systemPermissions = [];
    @track filteredPermissions = [];
    @track displayedPermissions = [];
    @track searchTerm = '';
    @track selectedPermission = null;
    @track isLoading = false;
    @track analysisResult = null;
    @track showAnalysisPanel = false;
    @track isAnalyzeDisabled = true;
    @track customPermissionInput = '';
    @track showCustomPermissionForm = false;
    @track showMissingObjectWarning = false;
    @track templateManagerAnimating = false; // Track animation state

    // Pagination properties
    @track pageSize = 20;
    @track currentPage = 1;
    @track totalPages = 1;
    @track hasMorePermissions = false;

    // Analysis UI properties
    @track profilesData = [];
    @track permSetsData = [];
    @track permSetGroupsData = [];
    @track usersData = [];
    @track totalCount = 0;
    @track activeTab = 'profiles';

    // Bulk export properties
    @track isBulkExporting = false;
    @track bulkExportProgress = 0;
    @track bulkExportTotal = 0;
    @track bulkExportProcessed = 0;
    @track showBulkExportModal = false;
    @track isBulkExportMinimized = false;
    @track isMinimizedExpanded = false;
    @track bulkExportStatus = '';
    @track bulkExportResults = [];
    isXLSXInitialized = false;

    @track selectedProfileIds = [];
    @track selectedPermSetIds = [];
    @track selectedPermSetGroupIds = [];
    @track selectedSystemPermissions = [];
    @track selectedUserIds = [];
    @track selectedUserFields = [];
    @track templates = [];
    @track selectedTemplate = null;
    @track selectedTemplateId = '';
    @track isExportButtonDisabled = true;
    @track showTemplateManager = false;
    
    // Automatic template properties
    @track automaticTemplatesInitialized = false;
    @track automaticTemplatesExist = false;
    @track automaticTemplateMessage = '';

    // Template data arrays
    @track profiles = [];
    @track permissionSets = [];
    @track permissionSetGroups = [];
    @track users = [];
    @track userFields = [];

    // Add a new track property to control visibility of the main panel
    @track showMainPanel = true;

    // Add new tracked properties for section expansion
    @track isCreateSectionExpanded = true;
    @track isExportSectionExpanded = false;

    // Multiple selection and export properties
    @track selectedPermissions = []; // Array to store multiple selected permissions
    @track showExportOptions = false; // Show export options panel
    @track isExporting = false; // Track export status
    @track exportProgress = 0; // Export progress percentage
    @track multipleAnalysisResults = null; // Store multiple permissions analysis results
    @track showMultipleAnalysisPanel = false; // Show multiple analysis panel
    @track expandedPermissions = []; // Track which permissions are expanded
    @track includeAllUsers = false; // new flag for including all active users

    // Dynamic User Fields properties
    @track availableUserFields = []; // All available user fields
    @track filteredUserFields = []; // Filtered user fields for search
    @track selectedUserFieldsForAnalysis = []; // Selected fields for analysis display
    @track showFieldSelector = false; // Show field selection modal
    @track dynamicUserFields = []; // Metadata for current dynamic fields
    @track useDynamicFields = false; // Toggle for using dynamic fields
    @track fieldSearchTerm = ''; // Search term for field filtering
    @track isCurrentUserAdmin = false; // Track if current user is System Administrator

    // Template manager button properties
    get templateButtonLabel() {
        return this.showTemplateManager ? 'Hide Templates' : 'Show/Save Templates';
    }

    get templateButtonIcon() {
        return this.showTemplateManager ? 'utility:chevronup' : 'utility:chevrondown';
    }

    @track analysisUserPage = 1;
    @track analysisUserPageSize = 200;
    @track analysisHasMoreUsers = false;
    @track isLoadingMoreUsers = false;
    @track analysisTotalUsers = 0;
    @track analysisTotalPages = 0;
    @track analysisCurrentPageUsers = [];
    @track showUserPagination = false;

    // User pagination properties for template creation
    @track userPageSize = 100;
    @track userCurrentPage = 1;
    @track userTotalPages = 0;
    @track userTotalCount = 0;
    @track userHasNext = false;
    @track userHasPrevious = false;
    @track userLastUserId = null;
    @track userSearchTerm = '';
    @track isLoadingUsers = false;

    // License type filtering properties
    @track availableLicenseTypes = [];
    @track selectedUserLicenseType = '';

    MAX_DYNAMIC_FIELDS = 20; // Maximum number of user fields that can be selected

    /**
     * @description Load system permissions when component is connected
     */
    connectedCallback() {
        this.loadSystemPermissions();
        this.initializeXLSX();
        this.initializeProgressBar();
        this.loadAvailableUserFields();
        this.loadAvailableLicenseTypes();
        this.checkCurrentUserAdminStatus();
        
        // Initialize paginated users for template creation
        this.initializeUsersForTemplate();
        
        // Also load other template data
        this.getProfiles();
        // Note: getPermissionSets() moved to lazy loading to avoid governor limits
        this.getPermissionSetGroups();
        this.getUserFields();
        this.getSystemPermissions();
        
        // Initialize system permissions for template manager (others are now tracked properties)
        // Note: profiles, permissionSets, users, userFields are now declared as @track properties
        
        // Set create section expanded by default
        this.isCreateSectionExpanded = true;
        
        // Setup background export support
        this.setupBackgroundExportSupport();
        
        // Check if the custom object exists
        checkPermissionsTemplateExists()
            .then(exists => {
                this.showMissingObjectWarning = !exists;
                if (!exists) {
                    // console.warn('PermissionsTemplate__c custom object does not exist');
                } else {
                    // Load templates if the object exists
                    this.loadTemplates();
                    // Initialize automatic templates
                    this.initializeAutomaticTemplatesOnLoad();
                }
            })
            .catch(() => {
                // console.error('Error checking if PermissionsTemplate__c exists:', error);
            });
    }

    /**
     * @description Cleanup when component is disconnected
     */
    disconnectedCallback() {
        this.cleanupBackgroundExportSupport();
    }

    /**
     * @description Setup background export support with visibility change detection
     */
    setupBackgroundExportSupport() {
        // Create bound functions and store them in private variables
        this._boundVisibilityHandler = this.handleVisibilityChange.bind(this);
        this._boundBeforeUnloadHandler = this.handleBeforeUnload.bind(this);
        
        // Listen for visibility changes to maintain export in background
        document.addEventListener('visibilitychange', this._boundVisibilityHandler);
        
        // Listen for beforeunload to warn user about ongoing export
        window.addEventListener('beforeunload', this._boundBeforeUnloadHandler);
    }

    /**
     * @description Cleanup background export support
     */
    cleanupBackgroundExportSupport() {
        if (this._boundVisibilityHandler) {
            document.removeEventListener('visibilitychange', this._boundVisibilityHandler);
            this._boundVisibilityHandler = null;
        }
        if (this._boundBeforeUnloadHandler) {
            window.removeEventListener('beforeunload', this._boundBeforeUnloadHandler);
            this._boundBeforeUnloadHandler = null;
        }
    }

    /**
     * @description Handle visibility change to maintain background export
     */
    handleVisibilityChange() {
        if (document.hidden && this.isBulkExporting) {
            // Page is hidden but export is running - ensure it continues
            console.log('Page hidden - export continues in background');
            
            // Show notification that export continues in background
            if (this.isBulkExportMinimized) {
                // Update widget to show it's running in background
                this.updateBackgroundExportStatus();
            }
        } else if (!document.hidden && this.isBulkExporting) {
            // Page is visible again - refresh UI state
            console.log('Page visible - refreshing export UI state');
            this.refreshExportProgress();
        }
    }

    /**
     * @description Handle before unload to warn about ongoing export
     */
    handleBeforeUnload(event) {
        if (this.isBulkExporting) {
            const message = 'Export is still in progress. Are you sure you want to leave?';
            event.preventDefault();
            event.returnValue = message;
            return message;
        }
        return null;
    }

    /**
     * @description Update background export status
     */
    updateBackgroundExportStatus() {
        if (this.isBulkExporting && document.hidden) {
            // Add visual indicator that export is running in background
            const widget = this.template.querySelector('.minimized-export-widget');
            if (widget) {
                widget.classList.add('background-running');
            }
        }
    }

    /**
     * @description Refresh export progress when page becomes visible
     */
    refreshExportProgress() {
        if (this.isBulkExporting) {
            // Update progress bar and status
            this.updateProgressBar();
            
            // Remove background indicator
            const widget = this.template.querySelector('.minimized-export-widget');
            if (widget) {
                widget.classList.remove('background-running');
            }
        }
    }

    /**
     * @description Check if current user is System Administrator
     */
    checkCurrentUserAdminStatus() {
        isCurrentUserSystemAdmin()
            .then(result => {
                this.isCurrentUserAdmin = result;
            })
            .catch(error => {
                console.error('Error checking admin status:', error);
                this.isCurrentUserAdmin = false;
            });
    }

    /**
     * @description Initialize XLSX library for Excel export
     */
    initializeXLSX() {
        if (this.isXLSXInitialized) return Promise.resolve();

        // console.log('Initializing XLSX library');
        
        return loadScript(this, XLSX)
            .then(() => {
                this.isXLSXInitialized = true;
                // console.log('XLSX library loaded successfully');
                // console.log('window.XLSX available:', !!window.XLSX);
                
                return Promise.resolve();
            })
            .catch(error => {
                // console.error('Error loading XLSX library:', error);
                this.isXLSXInitialized = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading export library',
                        message: 'The export library could not be loaded. Excel export might not work.',
                        variant: 'error'
                    })
                );
                return Promise.reject(error);
            });
    }

    /**
     * @description Load available license types for user filtering
     */
    async loadAvailableLicenseTypes() {
        try {
            const licenseTypes = await getAvailableLicenseTypes();
            this.availableLicenseTypes = licenseTypes || [];
            // console.log('Loaded license types:', this.availableLicenseTypes);
        } catch (licenseError) {
            console.error('Error loading license types:', licenseError);
            this.availableLicenseTypes = [];
        }
    }

    /**
     * @description Handle user license filter change
     */
    handleUserLicenseFilterChange(event) {
        this.selectedUserLicenseType = event.detail.selectedLicenseType;
        // console.log('License filter changed to:', this.selectedUserLicenseType);
        this.loadUsersPaginated(1, this.userSearchTerm, null, true); // Reset pagination and reload
    }

    /**
     * @description Load available user fields for dynamic display
     */
    loadAvailableUserFields() {
        getUserFieldsForDisplay()
            .then(result => {
                // Initialize fields with isSelected set to false by default
                this.availableUserFields = (result.fields || []).map(field => ({
                    ...field,
                    isSelected: false // Start with no fields selected
                }));
                
                // Initialize filtered fields
                this.filteredUserFields = [...this.availableUserFields];
                
                // console.log('Loaded user fields for display:', this.availableUserFields.length);
                
                // Initialize with empty selection - fields will be selected when dynamic mode is enabled
                this.selectedUserFieldsForAnalysis = [];
                
                // console.log('User fields loaded, ready for selection');
            })
            .catch(fieldsError => {
                // console.error('Error loading user fields:', fieldsError);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Loading User Fields',
                        message: 'Could not load user field options: ' + fieldsError.body?.message,
                        variant: 'error'
                    })
                );
            });
    }

    /**
     * @description Load available system permissions from the server
     */
    loadSystemPermissions() {
        this.isLoading = true;

        getSystemPermissions()
            .then(result => {
                // Enhance each permission with UI properties
                this.systemPermissions = result.map(perm => {
                    return {
                        ...perm,
                        iconName: perm.isPrivileged ? 'utility:shield' : 'utility:lock',
                        iconClass: perm.isPrivileged ? 'slds-icon-text-error' : 'slds-icon-text-default',
                        displayDescription: perm.privilegedDescription || perm.description || ''
                    };
                });

                // Initialize filtered permissions and display first page
                this.filteredPermissions = [...this.systemPermissions];
                this.totalPages = Math.ceil(this.filteredPermissions.length / this.pageSize);
                this.hasMorePermissions = this.totalPages > 1;
                this.updateDisplayedPermissions();

                this.isLoading = false;
            })
            .catch(permError => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading system permissions',
                        message: permError.message || permError.body.message,
                        variant: 'error'
                    })
                );
                this.isLoading = false;
            });
    }

    /**
     * @description Update displayed permissions based on current page and filters
     */
    updateDisplayedPermissions() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = Math.min(startIndex + this.pageSize, this.filteredPermissions.length);

        this.displayedPermissions = this.filteredPermissions.slice(startIndex, endIndex);
        this.hasMorePermissions = endIndex < this.filteredPermissions.length;
    }

    /**
     * @description Handle search input changes
     * @param {Event} event - Input change event
     */
    handleSearchChange(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.filterPermissions();
    }

    /**
     * @description Filter permissions based on search term
     */
    filterPermissions() {
        if (!this.searchTerm) {
            this.filteredPermissions = [...this.systemPermissions];
        } else {
            this.filteredPermissions = this.systemPermissions.filter(permission =>
                (permission.label && permission.label.toLowerCase().includes(this.searchTerm)) ||
                (permission.name && permission.name.toLowerCase().includes(this.searchTerm))
            );
        }

        // Reset pagination when filters change
        this.currentPage = 1;
        this.totalPages = Math.ceil(this.filteredPermissions.length / this.pageSize);
        this.updateDisplayedPermissions();
    }

    /**
     * @description Load next page of permissions
     */
    handleLoadMore() {
        if (this.hasMorePermissions) {
            this.currentPage++;
            this.updateDisplayedPermissions();
        }
    }

    /**
     * @description Toggle the custom permission form
     */
    handleAddCustomPermission() {
        this.showCustomPermissionForm = !this.showCustomPermissionForm;
        this.customPermissionInput = '';
    }

    /**
     * @description Handle custom permission input change
     * @param {Event} event - Input change event
     */
    handleCustomPermissionChange(event) {
        this.customPermissionInput = event.target.value;
    }

    /**
     * @description Submit custom permission to add to the list
     */
    handleCustomPermissionSubmit() {
        if (!this.customPermissionInput) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Input Required',
                    message: 'Please enter a system permission API name.',
                    variant: 'warning'
                })
            );
            return;
        }

        // Format the custom permission name
        const permName = this.customPermissionInput.trim();

        // Check if it exists already
        if (this.systemPermissions.some(p => p.name && p.name.toLowerCase() === permName.toLowerCase())) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Duplicate Permission',
                    message: `The permission "${permName}" is already in the list.`,
                    variant: 'info'
                })
            );

            // Highlight existing permission
            this.searchTerm = permName;
            this.filterPermissions();
            return;
        }

        // Add the custom permission to the list
        const formattedLabel = permName.replace(/([A-Z])/g, ' $1').trim();
        const newPermission = {
            id: permName,
            name: permName,
            label: formattedLabel,
            isSelected: false,
            iconName: 'utility:lock',
            iconClass: 'slds-icon-text-default',
            isCustomAdded: true
        };

        this.systemPermissions = [...this.systemPermissions, newPermission];

        // Refresh displayed permissions
        this.searchTerm = permName;
        this.filterPermissions();

        // Close the form
        this.showCustomPermissionForm = false;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Permission Added',
                message: `The permission "${permName}" has been added to the list.`,
                variant: 'success'
            })
        );
    }

    /**
     * @description Handle permission selection (supports both single and multiple selection)
     * @param {Event} event - Click event on permission item
     */
    handlePermissionSelect(event) {
        const permissionId = event.currentTarget.dataset.id;
        const permission = this.systemPermissions.find(p => p.id === permissionId);
        
        if (!permission) return;

        // Check if multiple permissions are already selected or if Ctrl/Cmd key is pressed
        const isMultipleSelection = this.selectedPermissions.length > 0 || event.ctrlKey || event.metaKey;

        if (isMultipleSelection) {
            // Multiple selection mode
            const existingIndex = this.selectedPermissions.findIndex(p => p.id === permissionId);
            
            if (existingIndex >= 0) {
                // Remove if already selected
                this.selectedPermissions.splice(existingIndex, 1);
            } else {
                // Add to selection
                this.selectedPermissions.push({...permission});
            }
            
            // Clear single selection when going to multiple
            this.selectedPermission = null;
            
            // Update selection state
            this.selectedPermissions = [...this.selectedPermissions];
            this.isAnalyzeDisabled = this.selectedPermissions.length === 0;
            
            // Clear analysis data when changing multiple selection
            this.clearAllAnalysisData();
            
            // console.log('Multiple selection updated:', this.selectedPermissions.length, 'permissions selected');
            
            // Update UI to reflect selection
            this.updateMultipleSelectionUI();
        } else {
            // Single selection mode
            if (this.selectedPermission && this.selectedPermission.id === permissionId) {
                // Deselect if clicking the same permission
                this.selectedPermission = null;
                this.isAnalyzeDisabled = true;
                // Clear analysis data when deselecting
                this.clearAllAnalysisData();
            } else {
                // Select new permission and clear multiple selections
                this.selectedPermission = {...permission};
                this.selectedPermissions = [];
                this.isAnalyzeDisabled = false;
                // Clear previous analysis data when selecting a different permission
                this.clearAllAnalysisData();
            }
            
            // console.log('Single selection updated:', this.selectedPermission?.label || 'None');
            
            // Update UI to reflect selection
            this.updateSelectionUI();
        }
    }

    /**
     * @description Get formatted data for multiple analysis results table
     */
    get formattedMultipleResults() {
        if (!this.multipleAnalysisResults || !this.multipleAnalysisResults.permissionResults) {
            return [];
        }

        const results = [];
        const permissionResults = this.multipleAnalysisResults.permissionResults;
        
        Object.keys(permissionResults).forEach(permissionName => {
            const result = permissionResults[permissionName];
            const isExpanded = this.expandedPermissions && this.expandedPermissions.includes(permissionName);
            
            results.push({
                id: permissionName,
                permissionName: permissionName,
                totalUsers: result.totalUsers || 0,
                profilesCount: (result.profilesWithAccess || []).length,
                permissionSetsCount: (result.permissionSetsWithAccess || []).length,
                permissionSetGroupsCount: (result.permissionSetGroupsWithAccess || []).length,
                isExpanded: isExpanded,
                expandIcon: isExpanded ? 'utility:chevrondown' : 'utility:chevronright',
                profilesData: result.profilesWithAccess || [],
                permissionSetsData: result.permissionSetsWithAccess || [],
                permissionSetGroupsData: result.permissionSetGroupsWithAccess || [],
                usersData: this.processUserData(result.usersWithAccess || [])
            });
        });
        
        return results;
    }

    /**
     * @description Clear all analysis data to prevent showing cached results
     */
    clearAllAnalysisData() {
        this.analysisResult = null;
        this.profilesData = [];
        this.permSetsData = [];
        this.permSetGroupsData = [];
        this.usersData = [];
        this.totalCount = 0;
        
        // Reset pagination data
        this.analysisUserPage = 1;
        this.analysisHasMoreUsers = false;
        this.isLoadingMoreUsers = false;
        this.analysisTotalUsers = 0;
        this.analysisTotalPages = 0;
        this.analysisCurrentPageUsers = [];
        this.showUserPagination = false;
        
        this.multipleAnalysisResults = null;
        this.showAnalysisPanel = false;
        this.showMultipleAnalysisPanel = false;
        this.expandedPermissions = [];
    }

    /**
     * @description Update UI to reflect single selection
     */
    updateSelectionUI() {
        const items = this.template.querySelectorAll('.selectable-item');
        items.forEach(item => {
            const itemId = item.dataset.id;
            if (this.selectedPermission && itemId === this.selectedPermission.id) {
                item.classList.add('selected');
                item.classList.remove('multiple-selected');
            } else {
                item.classList.remove('selected', 'multiple-selected');
            }
        });
    }

    /**
     * @description Update UI to reflect multiple selections
     */
    updateMultipleSelectionUI() {
        const items = this.template.querySelectorAll('.selectable-item');
        items.forEach(item => {
            const itemId = item.dataset.id;
            const isSelected = this.selectedPermissions.some(p => p.id === itemId);
            
            if (isSelected) {
                item.classList.add('selected', 'multiple-selected');
            } else {
                item.classList.remove('selected', 'multiple-selected');
            }
        });
        
        // Force reactivity update
        this.selectedPermissions = [...this.selectedPermissions];
    }

    /**
     * @description Handle analyze button click (automatically detects single vs multiple)
     */
    handleAnalyze() {
        if (this.selectedPermissions.length > 0) {
            this.handleAnalyzeMultiple();
        } else if (this.selectedPermission) {
            this.handleAnalyzeSingle();
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No Permission Selected',
                    message: 'Please select one or more system permissions to analyze.',
                    variant: 'warning'
                })
            );
        }
    }

    /**
     * @description Analyze single permission using paginated server calls so **all** active users are eventually retrievable.
     */
    handleAnalyzeSingle() {
        if (!this.selectedPermission) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'No Permission Selected',
                message: 'Please select a system permission to analyze.',
                variant: 'warning'
            }));
            return;
        }

        this.isLoading = true;
        // Reset ALL analysis state to prevent showing cached data from previous permission
        this.clearAllAnalysisData();
        
        // Clear any multiple analysis results
        this.multipleAnalysisResults = null;
        this.showMultipleAnalysisPanel = false;

        // Use dynamic fields method if enabled, otherwise use optimized method
        let analysisMethod;
        if (this.useDynamicFields) {
            const fieldsForAnalysis = this.getUniqueFieldsForAnalysis();
            // console.log('Using dynamic fields for analysis:', fieldsForAnalysis);
            
            analysisMethod = getSystemPermissionAccessWithDynamicFields({
                systemPermissionName: this.selectedPermission.name,
                userPageSize: this.analysisUserPageSize,
                userPageNumber: this.analysisUserPage,
                selectedUserFields: fieldsForAnalysis
            });
        } else {
            // console.log('Using optimized method (static fields)');
            analysisMethod = getSystemPermissionAccessOptimized({
                systemPermissionName: this.selectedPermission.name,
                userPageSize: this.analysisUserPageSize,
                userPageNumber: this.analysisUserPage
            });
        }

        analysisMethod
            .then(result => {
                this.populateSingleAnalysisResult(result, /*append*/ false);
                this.isLoading = false;
                Promise.resolve().then(() => {
                    this.scrollToAnalysisPanel();
                });
            })
            .catch(error => {
                // console.error('Error in permission analysis:', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error analyzing permission',
                    message: error.message || (error.body && error.body.message) || 'Analysis failed',
                    variant: 'error'
                }));
                this.isLoading = false;
            });
    }

    /**
     * Helper to merge/assign analysis results.
     * @param {Object} result  Apex result payload
     * @param {Boolean} append Whether to append users to existing list (not used in pagination mode)
     */
    populateSingleAnalysisResult(result, append = false) {
        this.analysisResult = result;
        this.profilesData = result.profiles || result.profilesWithAccess || [];
        this.permSetsData = result.permissionSets || result.permissionSetsWithAccess || [];
        this.permSetGroupsData = result.permissionSetGroups || result.permissionSetGroupsWithAccess || [];
        
        // Handle dynamic user fields metadata
        if (result.userFields) {
            this.dynamicUserFields = result.userFields;
            // console.log('Set dynamic fields from Apex result:', this.dynamicUserFields);
        } else if (this.useDynamicFields) {
            // Create field metadata from all fields used in analysis (core + selected)
            const fieldsUsedInAnalysis = this.getUniqueFieldsForAnalysis();
            
            this.dynamicUserFields = fieldsUsedInAnalysis.map(fieldName => {
                // Skip Profile.Name as it's a relationship field handled separately
                if (fieldName === 'Profile.Name') return null;
                
                const fieldInfo = this.availableUserFields.find(field => 
                    field.name === fieldName || (field.name && field.name.toLowerCase() === fieldName.toLowerCase())
                );
                
                if (fieldInfo) {
                    return fieldInfo;
                }
                // Create basic field info for core fields or custom fields not found
                const isCore = ['Id', 'Name', 'Username', 'Email', 'IsActive'].includes(fieldName);
                return {
                    name: fieldName,
                    label: fieldName.replace(/([A-Z_])/g, ' $1').trim().replace(/^./, str => str.toUpperCase()), // Convert to readable
                    type: fieldName === 'IsActive' ? 'BOOLEAN' : 'STRING',
                    isCustom: fieldName.includes('__c'),
                    isCore: isCore,
                    apiName: fieldName
                };
            }).filter(field => field !== null); // Remove null entries
            
            // console.log('Created dynamic fields metadata for analysis:', this.dynamicUserFields);
        }

        const newUsersRaw = result.users || result.usersWithAccess || [];
        const processed = this.processUserData(newUsersRaw);

        // For pagination, we always replace the current page data
        this.usersData = processed;
        this.analysisCurrentPageUsers = processed;

        // Update pagination information
        const pag = result.userPagination || result.pagination || {};
        this.analysisUserPage = pag.pageNumber || this.analysisUserPage;
        this.analysisHasMoreUsers = pag.hasNext || false;
        this.analysisTotalUsers = result.totalUsers || (pag.totalCount ?? 0);
        this.analysisTotalPages = Math.ceil(this.analysisTotalUsers / this.analysisUserPageSize);
        this.showUserPagination = this.analysisTotalUsers > this.analysisUserPageSize;

        this.totalCount = (result.totalProfiles || 0) + (result.totalPermissionSets || 0) + 
                         (result.totalPermissionSetGroups || 0) + this.analysisTotalUsers;
        
        this.showAnalysisPanel = true;
        this.showMultipleAnalysisPanel = false;

        if (!append) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Analysis Complete',
                message: `Found ${this.analysisTotalUsers} active users with "${this.selectedPermission ? this.selectedPermission.label : 'Selected'}" permission.`,
                variant: 'success'
            }));
        }

        /* console.log('Analysis result populated with pagination:', {
            currentPage: this.analysisUserPage,
            totalPages: this.analysisTotalPages,
            totalUsers: this.analysisTotalUsers,
            currentPageUsers: this.usersData.length,
            showPagination: this.showUserPagination,
            hasMoreUsers: this.analysisHasMoreUsers
        });*/
    }

    /**
     * Navigate to a specific page of users
     */
    navigateToUserPage(pageNumber) {
        if (pageNumber < 1 || pageNumber > this.analysisTotalPages || this.isLoadingMoreUsers) {
            return;
        }
        
        this.isLoadingMoreUsers = true;
        
        // Use dynamic fields method if enabled, otherwise use optimized method
        let analysisMethod;
        if (this.useDynamicFields) {
            const fieldsForAnalysis = this.getUniqueFieldsForAnalysis();
            // console.log('Navigating to page', pageNumber, 'with dynamic fields:', fieldsForAnalysis);
            
            analysisMethod = getSystemPermissionAccessWithDynamicFields({
                systemPermissionName: this.selectedPermission.name,
                userPageSize: this.analysisUserPageSize,
                userPageNumber: pageNumber,
                selectedUserFields: fieldsForAnalysis
            });
        } else {
            // console.log('Navigating to page', pageNumber, 'with static fields');
            analysisMethod = getSystemPermissionAccessOptimized({
                systemPermissionName: this.selectedPermission.name,
                userPageSize: this.analysisUserPageSize,
                userPageNumber: pageNumber
            });
        }

        analysisMethod
            .then(result => {
                this.populateSingleAnalysisResult(result, false);
                this.isLoadingMoreUsers = false;
            })
            .catch(error => {
                // console.error('Error loading user page:', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Loading Users',
                    message: error.message || (error.body && error.body.message) || 'Failed to load user page',
                    variant: 'error'
                }));
                this.isLoadingMoreUsers = false;
            });
    }

    /**
     * Navigate to the first page of users
     */
    handleFirstUserPage() {
        this.navigateToUserPage(1);
    }

    /**
     * Navigate to the previous page of users
     */
    handlePreviousUserPage() {
        if (this.analysisUserPage > 1) {
            this.navigateToUserPage(this.analysisUserPage - 1);
        }
    }

    /**
     * Navigate to the next page of users
     */
    handleNextUserPage() {
        if (this.analysisUserPage < this.analysisTotalPages) {
            this.navigateToUserPage(this.analysisUserPage + 1);
        }
    }

    /**
     * Navigate to the last page of users
     */
    handleLastUserPage() {
        this.navigateToUserPage(this.analysisTotalPages);
    }

    /**
     * Handle page number input change
     */
    handleUserPageInputChange(event) {
        const pageNumber = parseInt(event.target.value, 10);
        if (!isNaN(pageNumber) && pageNumber >= 1 && pageNumber <= this.analysisTotalPages) {
            this.navigateToUserPage(pageNumber);
        }
    }

    /**
     * @description Analyze multiple permissions
     */
    handleAnalyzeMultiple() {
        if (!this.selectedPermissions || this.selectedPermissions.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No Permissions Selected',
                    message: 'Please select one or more system permissions to analyze.',
                    variant: 'warning'
                })
            );
            return;
        }

        this.isLoading = true;
        
        // Clear single analysis results to prevent showing cached data from previous single permission
        this.analysisResult = null;
        this.profilesData = [];
        this.permSetsData = [];
        this.permSetGroupsData = [];
        this.usersData = [];
        this.totalCount = 0;
        this.showAnalysisPanel = false;
        
        const permissionNames = this.selectedPermissions.map(p => p.name);

        // Use the imported Apex method

        getMultipleSystemPermissionsAccess({ systemPermissionNames: permissionNames })
            .then(result => {
                this.multipleAnalysisResults = result;
                this.showMultipleAnalysisPanel = true;
                this.showAnalysisPanel = false;
                this.isLoading = false;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Analysis Complete',
                        message: `Successfully analyzed ${result.totalPermissions} permissions.`,
                        variant: 'success'
                    })
                );

                Promise.resolve().then(() => {
                    this.scrollToAnalysisPanel();
                });
            })
            .catch(error => {
                // console.error('Error in multiple permissions analysis:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error analyzing permissions',
                        message: error.message || (error.body && error.body.message) || 'Unknown error occurred',
                        variant: 'error'
                    })
                );
                this.isLoading = false;
            });
    }

    /**
     * @description Handle export single permission analysis
     */
    handleExportSingle() {
        if (!this.selectedPermission || !this.analysisResult) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No Analysis to Export',
                    message: 'Please analyze a permission first before exporting.',
                    variant: 'warning'
                })
            );
            return;
        }

        this.isExporting = true;
        this.exportProgress = 0;

        // Use the imported export method

        // Ensure XLSX is initialized first
        this.initializeXLSX()
            .then(() => {
                if (this.useDynamicFields) {
                    const fieldsForExport = this.getUniqueFieldsForAnalysis();
                    return exportSystemPermissionsWithUserFields({
                        systemPermissionNames: [this.selectedPermission.name],
                        selectedUserFields: fieldsForExport,
                        maxUsersPerPermission: 40000
                    });
                }
                return exportSingleSystemPermissionAnalysis({ systemPermissionName: this.selectedPermission.name });
            })
            .then(result => {
                this.exportProgress = 50;
                // Generate Excel file
                this.generateSinglePermissionExcel(result);
            })
            .catch(error => {
                // console.error('Error exporting single permission:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Export Error',
                        message: error.message || (error.body && error.body.message) || 'Failed to export permission analysis',
                        variant: 'error'
                    })
                );
                this.isExporting = false;
                this.exportProgress = 0;
            });
    }

    /**
     * @description Handle export multiple permissions analysis
     */
    handleExportMultiple() {
        if (!this.selectedPermissions || this.selectedPermissions.length === 0 || !this.multipleAnalysisResults) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No Analysis to Export',
                    message: 'Please analyze multiple permissions first before exporting.',
                    variant: 'warning'
                })
            );
            return;
        }

        this.isExporting = true;
        this.exportProgress = 0;

        const permissionNames = this.selectedPermissions.map(p => p.name);

        // Ensure XLSX is initialized first
        this.initializeXLSX()
            .then(() => {
                if (this.useDynamicFields) {
                    const fieldsForExport = this.getUniqueFieldsForAnalysis();
                    return exportSystemPermissionsWithUserFields({
                        systemPermissionNames: permissionNames,
                        selectedUserFields: fieldsForExport,
                        maxUsersPerPermission: 40000
                    });
                }
                return exportMultipleSystemPermissionsAnalysis({ systemPermissionNames: permissionNames });
            })
            .then(result => {
                this.exportProgress = 50;
                // Generate Excel file
                this.generateMultiplePermissionsExcel(result);
            })
            .catch(error => {
                // console.error('Error exporting multiple permissions:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Export Error',
                        message: error.message || (error.body && error.body.message) || 'Failed to export permissions analysis',
                        variant: 'error'
                    })
                );
                this.isExporting = false;
                this.exportProgress = 0;
            });
    }

    /**
     * @description Generate Excel file for single permission analysis
     */
    generateSinglePermissionExcel(exportData) {
        try {
            // console.log('Starting Excel generation for single permission');
        // console.log('Export data:', exportData);
            
            if (!window.XLSX) {
                throw new Error('XLSX library is not properly loaded. Please refresh the page and try again.');
            }

            const workbook = window.XLSX.utils.book_new();
            let analysisData = exportData.exportData;
            let permissionName = exportData.permissionName;

            // Handle dynamic-fields export structure
            if (!analysisData && exportData.permissionResults) {
                const permKeys = Object.keys(exportData.permissionResults);
                if (permKeys.length) {
                    permissionName = permKeys[0];
                    const permBlock = exportData.permissionResults[permissionName];
                    analysisData = permBlock.exportData ? permBlock.exportData : permBlock;
                }
            }

            // Handle case where Apex returned the analysis map directly
            if (!analysisData && exportData.totalUsers !== undefined) {
                permissionName = exportData.systemPermissionName || permissionName;
                analysisData = exportData;
            }

            if (!analysisData) {
                throw new Error('Unexpected export payload – analysis data not found');
            }

            // console.log('Analysis data:', analysisData);
        // console.log('Permission name:', permissionName);

            // Summary sheet
            const summaryData = [
                ['System Permission Analysis Report'],
                ['Permission Name', permissionName || 'Unknown'],
                ['Analysis Date', exportData.timestamp || new Date().toISOString()],
                ['Total Users with Access', analysisData.totalUsers || 0],
                ['Profiles with Access', (analysisData.profilesWithAccess || []).length],
                ['Permission Sets with Access', (analysisData.permissionSetsWithAccess || []).length],
                ['Permission Set Groups with Access', (analysisData.permissionSetGroupsWithAccess || []).length],
                []
            ];

            // console.log('Creating summary sheet...');
            const summarySheet = window.XLSX.utils.aoa_to_sheet(summaryData);
            this.applyCellStyling(summarySheet, summaryData);
            window.XLSX.utils.book_append_sheet(workbook, summarySheet, 'Summary');

            // Profiles sheet
            if (analysisData.profilesWithAccess && analysisData.profilesWithAccess.length > 0) {
                // console.log('Creating profiles sheet...');
                const profilesData = [
                    ['Profile Name', 'Description', 'Profile ID', 'License Type', 'Type']
                ];
                for (const profile of analysisData.profilesWithAccess) {
                    profilesData.push([
                        profile.name || '',
                        profile.description || '',
                        profile.id || '',
                        profile.userLicense || '',
                        'Profile'
                    ]);
                }
                const profilesSheet = window.XLSX.utils.aoa_to_sheet(profilesData);
                this.applyCellStyling(profilesSheet, profilesData);
                window.XLSX.utils.book_append_sheet(workbook, profilesSheet, 'Profiles');
            }

            // Permission Sets sheet
            if (analysisData.permissionSetsWithAccess && analysisData.permissionSetsWithAccess.length > 0) {
                // console.log('Creating permission sets sheet...');
                const permSetsData = [
                    ['Permission Set Label', 'Description', 'API Name', 'Permission Set ID', 'Assignment Count', 'Type']
                ];
                for (const permSet of analysisData.permissionSetsWithAccess) {
                    permSetsData.push([
                        permSet.label || '',
                        permSet.description || '',
                        permSet.name || '',
                        permSet.id || '',
                        permSet.assignmentCount || 0,
                        'Permission Set'
                    ]);
                }
                const permSetsSheet = window.XLSX.utils.aoa_to_sheet(permSetsData);
                this.applyCellStyling(permSetsSheet, permSetsData);
                window.XLSX.utils.book_append_sheet(workbook, permSetsSheet, 'Permission Sets');
            }

            // Users sheet
            if (analysisData.usersWithAccess && analysisData.usersWithAccess.length > 0) {
                // console.log('Creating users sheet...');
                
                // Build headers based on dynamic fields or default structure
                let headers = [];
                let dynamicFieldsForExport = [];
                
                if (this.useDynamicFields && this.dynamicUserFields.length > 0) {
                    // Use all dynamic fields (including core fields)
                    headers = this.dynamicUserFields.map(f => f.label || f.name);
                    dynamicFieldsForExport = this.dynamicUserFields;
                } else {
                    // Default headers for static export
                    headers = ['Name', 'User ID', 'Username', 'Email', 'Profile'];
                }
                
                // Add single permission source column and status
                headers.push('Permission Source', 'Status');
                
                const usersData = [headers];
                
                analysisData.usersWithAccess.forEach(user => {
                    const sources = user.permissionSources || [];
                    const status = user.isActive || user.IsActive ? 'Active' : 'Inactive';
                    
                    // If user has no permission sources, create one row with empty permission source
                    if (sources.length === 0) {
                        let rowData = [];
                        
                        if (this.useDynamicFields && dynamicFieldsForExport.length > 0) {
                            // Extract values for each dynamic field
                            dynamicFieldsForExport.forEach(field => {
                                let value = user[field.name] || user[field.name?.toLowerCase()] || '';
                                
                                // Handle special field types
                                if (field.type === 'BOOLEAN') {
                                    value = value ? 'True' : 'False';
                                } else if (typeof value === 'object' && value !== null) {
                                    if (value.Name) value = value.Name;
                                    else if (value.Label) value = value.Label;
                                    else value = JSON.stringify(value);
                                }
                                
                                rowData.push(value);
                            });
                        } else {
                            // Default static structure
                            rowData = [
                                user.name || user.Name || '',
                                user.id || user.Id || '',
                                user.username || user.Username || '',
                                user.email || user.Email || '',
                                user.profileName || user.Profile?.Name || ''
                            ];
                        }
                        
                        rowData.push('', status); // Empty permission source, status
                        usersData.push(rowData);
                    } else {
                        // Create one row for each permission source
                        sources.forEach(source => {
                            let rowData = [];
                            
                            if (this.useDynamicFields && dynamicFieldsForExport.length > 0) {
                                // Extract values for each dynamic field
                                dynamicFieldsForExport.forEach(field => {
                                    let value = user[field.name] || user[field.name?.toLowerCase()] || '';
                                    
                                    // Handle special field types
                                    if (field.type === 'BOOLEAN') {
                                        value = value ? 'True' : 'False';
                                    } else if (typeof value === 'object' && value !== null) {
                                        if (value.Name) value = value.Name;
                                        else if (value.Label) value = value.Label;
                                        else value = JSON.stringify(value);
                                    }
                                    
                                    rowData.push(value);
                                });
                            } else {
                                // Default static structure
                                rowData = [
                                    user.name || user.Name || '',
                                    user.id || user.Id || '',
                                    user.username || user.Username || '',
                                    user.email || user.Email || '',
                                    user.profileName || user.Profile?.Name || ''
                                ];
                            }
                            
                            rowData.push(`${source.type}: ${source.name}`, status);
                            usersData.push(rowData);
                        });
                    }
                });
                
                // console.log('Users data for export:', usersData);
                const usersSheet = window.XLSX.utils.aoa_to_sheet(usersData);
                this.applyCellStyling(usersSheet, usersData);
                window.XLSX.utils.book_append_sheet(workbook, usersSheet, 'Users');
            }

            // Permission Set Groups sheet
            if (analysisData.permissionSetGroupsWithAccess && analysisData.permissionSetGroupsWithAccess.length > 0) {
                // console.log('Creating permission set groups sheet...');
                const psgData = [
                    ['Permission Set Group Label', 'Description', 'API Name', 'Permission Set Group ID', 'Assignment Count', 'Component Permission Sets', 'Type']
                ];
                for (const psg of analysisData.permissionSetGroupsWithAccess) {
                    const componentPSNames = psg.componentPermissionSets ? 
                        psg.componentPermissionSets.map(ps => ps.label).join('; ') : '';
                    
                    psgData.push([
                        psg.label || '',
                        psg.description || '',
                        psg.name || '',
                        psg.id || '',
                        psg.assignmentCount || 0,
                        componentPSNames,
                        'Permission Set Group'
                    ]);
                }
                const psgSheet = window.XLSX.utils.aoa_to_sheet(psgData);
                this.applyCellStyling(psgSheet, psgData);
                window.XLSX.utils.book_append_sheet(workbook, psgSheet, 'Permission Set Groups');
            }

            // Generate and download file
            // console.log('Generating Excel file...');
            this.exportProgress = 90;
            
            const cleanPermissionName = (permissionName || 'Unknown_Permission').replace(/[^a-zA-Z0-9_]/g, '_');
            const fileName = `${cleanPermissionName}_Analysis_${new Date().toISOString().split('T')[0]}.xlsx`;
            
            // console.log('Writing workbook...');
            // Generate Excel file using XLSX
            const wopts = { bookType: 'xlsx', type: 'array' };
            const wbout = window.XLSX.write(workbook, wopts);
            const blob = new Blob([wbout], { type: 'application/octet-stream' });

            // console.log('Creating download link...');
            // Create download link
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = fileName;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            window.URL.revokeObjectURL(url);

            this.exportProgress = 100;
            
            // console.log('Export completed successfully!');
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Export Successful',
                    message: `Permission analysis exported to ${fileName}`,
                    variant: 'success'
                })
            );

        } catch (error) {
            // console.error('Error generating Excel file:', error);
            // console.error('Error stack:', error.stack);
            // console.error('Export data that caused error:', exportData);
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Export Error',
                    message: 'Failed to generate Excel file: ' + (error.message || 'Unknown error'),
                    variant: 'error'
                })
            );
        } finally {
            this.isExporting = false;
            this.exportProgress = 0;
        }
    }

    /**
     * @description Generate Excel file for multiple permissions analysis
     */
    generateMultiplePermissionsExcel(exportData) {
        try {
            if (!window.XLSX || !window.XLSX.utils || typeof window.XLSX.utils.book_new !== 'function') {
                /*console.error('XLSX library state:', {
                    hasXLSX: !!window.XLSX,
                    hasUtils: !!(window.XLSX && window.XLSX.utils),
                    hasBookNew: !!(window.XLSX && window.XLSX.utils && typeof window.XLSX.utils.book_new === 'function')
                });*/
                throw new Error('XLSX library is not properly loaded. Please refresh the page and try again.');
            }

            const workbook = window.XLSX.utils.book_new();
            const analysisData = exportData.exportData;
            const permissionNames = exportData.permissionNames;

            // Summary sheet
            const summaryData = [
                ['Multiple System Permissions Analysis Report'],
                ['Analysis Date', exportData.timestamp],
                ['Total Permissions Analyzed', permissionNames.length],
                ['Permissions Analyzed', permissionNames.join(', ')],
                []
            ];

            // Add summary for each permission
            if (analysisData.permissionResults) {
                summaryData.push(['Permission', 'Total Users', 'Profiles', 'Permission Sets', 'Permission Set Groups']);
                Object.keys(analysisData.permissionResults).forEach(permName => {
                    const result = analysisData.permissionResults[permName];
                    summaryData.push([
                        permName,
                        result.totalUsers || 0,
                        (result.profilesWithAccess || []).length,
                        (result.permissionSetsWithAccess || []).length,
                        (result.permissionSetGroupsWithAccess || []).length
                    ]);
                });
            }

            const summarySheet = window.XLSX.utils.aoa_to_sheet(summaryData);
            this.formatMultipleSummarySheet(summarySheet, summaryData);
            window.XLSX.utils.book_append_sheet(workbook, summarySheet, 'Summary');

            // Create individual sheets for each permission
            if (analysisData.permissionResults) {
                Object.keys(analysisData.permissionResults).forEach(permName => {
                    const result = analysisData.permissionResults[permName];
                    
                    // Create combined sheet for this permission
                    const permData = [
                        [`${permName} - Analysis Results`],
                        ['Total Users with Access', result.totalUsers || 0],
                        [],
                        ['Profiles with Access']
                    ];

                    if (result.profilesWithAccess && result.profilesWithAccess.length > 0) {
                        permData.push(['Profile Name', 'License Type']);
                        result.profilesWithAccess.forEach(profile => {
                            permData.push([profile.name, profile.userLicense || '']);
                        });
                    } else {
                        permData.push(['No profiles have this permission']);
                    }

                    permData.push([]);
                    permData.push(['Permission Sets with Access']);

                    if (result.permissionSetsWithAccess && result.permissionSetsWithAccess.length > 0) {
                        permData.push(['Label', 'API Name', 'Assignment Count']);
                        result.permissionSetsWithAccess.forEach(permSet => {
                            permData.push([permSet.label, permSet.name, permSet.assignmentCount || 0]);
                        });
                    } else {
                        permData.push(['No permission sets have this permission']);
                    }

                    permData.push([]);
                    permData.push(['Users with Access']);

                    if (result.usersWithAccess && result.usersWithAccess.length > 0) {
                        permData.push(['Name', 'Username', 'Email', 'Profile', 'Permission Source', 'Status']);
                        result.usersWithAccess.forEach(user => {
                            const sources = user.permissionSources || [];
                            const status = user.isActive ? 'Active' : 'Inactive';
                            
                            // If user has no permission sources, create one row with empty permission source
                            if (sources.length === 0) {
                                const userRow = [
                                    user.name, 
                                    user.username, 
                                    user.email, 
                                    user.profileName,
                                    '', // Empty permission source
                                    status
                                ];
                                permData.push(userRow);
                            } else {
                                // Create one row for each permission source
                                sources.forEach(source => {
                                    const userRow = [
                                        user.name, 
                                        user.username, 
                                        user.email, 
                                        user.profileName,
                                        `${source.type}: ${source.name}`,
                                        status
                                    ];
                                    permData.push(userRow);
                                });
                            }
                        });
                    } else {
                        permData.push(['No users have this permission']);
                    }

                    const permSheet = window.XLSX.utils.aoa_to_sheet(permData);
                    this.formatPermissionSheet(permSheet, permData, permName);
                    // Truncate sheet name if too long
                    const sheetName = permName.length > 31 ? permName.substring(0, 28) + '...' : permName;
                    window.XLSX.utils.book_append_sheet(workbook, permSheet, sheetName);
                });
            }

            // Generate and download file
            this.exportProgress = 90;
            const fileName = `Multiple_Permissions_Analysis_${new Date().toISOString().split('T')[0]}.xlsx`;
            
            // Apply basic styling to workbook
            this.applyBasicWorkbookStyling(workbook);
            
            const wbout = window.XLSX.write(workbook, { 
                bookType: 'xlsx', 
                type: 'array'
            });
            const blob = new Blob([wbout], { type: 'application/octet-stream' });

            // Create download link
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = fileName;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            window.URL.revokeObjectURL(url);

            this.exportProgress = 100;
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Export Successful',
                    message: `Multiple permissions analysis exported to ${fileName}`,
                    variant: 'success'
                })
            );

        } catch (error) {
            // console.error('Error generating Excel file:', error);
            // console.error('Error stack:', error.stack);
            // console.error('Export data that caused error:', exportData);
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Export Error',
                    message: 'Failed to generate Excel file: ' + (error.message || 'Unknown error'),
                    variant: 'error'
                })
            );
        } finally {
            this.isExporting = false;
            this.exportProgress = 0;
        }
    }

    /**
     * @description Close multiple analysis panel
     */
    handleCloseMultipleAnalysis() {
        this.showMultipleAnalysisPanel = false;
        this.expandedPermissions = []; // Reset expanded state when closing
    }

    /**
     * @description Handle expanding/collapsing permission details
     */
    handleExpandPermission(event) {
        event.stopPropagation();
        const permissionName = event.currentTarget.dataset.permission;
        
        if (!permissionName) return;
        
        const expandedIndex = this.expandedPermissions.indexOf(permissionName);
        
        if (expandedIndex >= 0) {
            // Collapse - remove from expanded list
            this.expandedPermissions.splice(expandedIndex, 1);
        } else {
            // Expand - add to expanded list
            this.expandedPermissions.push(permissionName);
        }
        
        // Force reactivity update
        this.expandedPermissions = [...this.expandedPermissions];
        
        // console.log('Expanded permissions:', this.expandedPermissions);
    }

    /**
     * @description Handle expanding/collapsing permission set assignment details
     */
    handleExpandPermissionSet(event) {
        event.preventDefault();
        event.stopPropagation();
        
        const permSetId = event.currentTarget.dataset.permsetId;
        if (!permSetId) return;
        
        // Update the permission sets data to toggle the showAssignments flag
        this.permissionAnalysisResults = this.permissionAnalysisResults.map(result => {
            if (result.permissionSetsData && result.permissionSetsData.length > 0) {
                result.permissionSetsData = result.permissionSetsData.map(permSet => {
                    if (permSet.id === permSetId) {
                        return {
                            ...permSet,
                            showAssignments: !permSet.showAssignments
                        };
                    }
                    return permSet;
                });
            }
            return result;
        });
        
        // Update the expand button icon
        Promise.resolve().then(() => {
            const buttonIcon = this.template.querySelector(`[data-permset-id="${permSetId}"] .expand-button`);
            if (buttonIcon) {
                const isExpanded = this.permissionAnalysisResults
                    .flatMap(result => result.permissionSetsData || [])
                    .find(permSet => permSet.id === permSetId)?.showAssignments;
                
                buttonIcon.iconName = isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
            }
        });
    }

    /**
     * @description Get selection mode button label
     */
    get selectionModeButtonLabel() {
        return this.isMultipleSelectionMode ? 'Switch to Single Selection' : 'Switch to Multiple Selection';
    }

    /**
     * @description Get selection mode button icon
     */
    get selectionModeButtonIcon() {
        return this.isMultipleSelectionMode ? 'utility:single_column' : 'utility:multi_select_checkbox';
    }

    /**
     * @description Get analyze button label based on selection
     */
    get analyzeButtonLabel() {
        if (this.selectedPermissions && this.selectedPermissions.length > 1) {
            return `Analyze ${this.selectedPermissions.length} Permissions`;
        } else if (this.selectedPermissions && this.selectedPermissions.length === 1) {
            return `Analyze ${this.selectedPermissions.length} Permission`;
        }
        return this.selectedPermission ? `Analyze "${this.selectedPermission.label}"` : 'Select Permission to Analyze';
    }

    /**
     * @description Get selected permissions count label
     */
    get selectedPermissionsLabel() {
        if (this.selectedPermissions.length > 0) {
            return `${this.selectedPermissions.length} permission${this.selectedPermissions.length !== 1 ? 's' : ''} selected`;
        }
        return this.selectedPermission ? `"${this.selectedPermission.label}" selected` : 'No permission selected';
    }

    /**
     * @description Check if export is available for single analysis
     */
    get canExportSingle() {
        return this.showAnalysisPanel && this.analysisResult && this.selectedPermissions.length === 0;
    }

    /**
     * @description Check if export is available for multiple analysis
     */
    get canExportMultiple() {
        return this.showMultipleAnalysisPanel && this.multipleAnalysisResults && this.selectedPermissions.length > 0;
    }

    /**
     * @description Debug getter to check current selection state
     */
    get debugSelectionInfo() {
        return {
            selectedPermissionsCount: this.selectedPermissions.length,
            selectedPermission: this.selectedPermission?.label || 'None',
            analyzeButtonLabel: this.analyzeButtonLabel
        };
    }

    /**
     * @description Scroll to the analysis panel
     */
    scrollToAnalysisPanel() {
        const analysisPanel = this.template.querySelector('.analysis-panel');
        if (analysisPanel) {
            analysisPanel.scrollIntoView({ 
                behavior: 'smooth', 
                block: 'start'
            });
        }
    }

    /**
     * @description Get the icon name for a permission source type
     * @param {String} sourceType - The type of permission source (Profile, Permission Set, Permission Set Group)
     * @return {String} The SLDS icon name for the source type
     */
    getSourceIconName(sourceType) {
        switch (sourceType) {
            case 'Profile':
                return 'standard:user_role';
            case 'Permission Set':
                return 'standard:permission_set';
            case 'Permission Set Group':
                return 'standard:permission_set_group';
            default:
                return 'standard:app';
        }
    }

    /**
     * @description Process user data to add icon names for permission sources and prepare dynamic fields
     */
    processUserData(userData) {
        if (!userData || !Array.isArray(userData)) return userData;
        
        return userData.map(user => {
            if (user.permissionSources && Array.isArray(user.permissionSources)) {
                user.permissionSources = user.permissionSources.map(source => ({
                    ...source,
                    iconName: this.getSourceIconName(source.type)
                }));
            }
            
            // Process dynamic fields for display
            if (this.useDynamicFields && this.dynamicUserFields && this.dynamicUserFields.length > 0) {
                // console.log('Processing dynamic fields for user:', user.id || user.Id);
            // console.log('Available dynamic fields:', this.dynamicUserFields);
            // console.log('User data keys:', Object.keys(user));
                
                user.processedFields = this.dynamicUserFields.map(fieldInfo => {
                    // Try different field name variations to find the value
                    let fieldValue = user[fieldInfo.name];
                    
                    // If not found, try alternative field name formats
                    if (fieldValue === undefined || fieldValue === null) {
                        // Try with different casing
                        const alternativeNames = [
                            fieldInfo.name,
                            fieldInfo.name.toLowerCase(),
                            fieldInfo.name.charAt(0).toUpperCase() + fieldInfo.name.slice(1),
                            fieldInfo.apiName || fieldInfo.name
                        ];
                        
                        for (const altName of alternativeNames) {
                            if (user[altName] !== undefined && user[altName] !== null) {
                                fieldValue = user[altName];
                                break;
                            }
                        }
                    }
                    
                    const processedField = {
                        ...fieldInfo,
                        fieldValue: fieldValue,
                        isBooleanType: fieldInfo.type && fieldInfo.type.toUpperCase().includes('BOOLEAN'),
                        // Add display value for better rendering
                        displayValue: this.getFieldDisplayValue(fieldValue, fieldInfo.type)
                    };
                    
                    // console.log('Processed field:', fieldInfo.name, 'Value:', fieldValue, 'Display:', processedField.displayValue);
                    return processedField;
                });
                
                // console.log('Final processed fields for user:', user.processedFields);
            } else {
                // Ensure processedFields is always an array, even if empty
                user.processedFields = [];
            }
            
            return user;
        });
    }

    /**
     * @description Get display value for a field based on its type
     * @param {*} value - The field value
     * @param {String} fieldType - The field type
     * @return {String} The display value
     */
    getFieldDisplayValue(value, fieldType) {
        if (value === null || value === undefined) {
            return '';
        }
        
        // Handle object values (like relationship fields)
        if (typeof value === 'object' && value !== null) {
            // If it's a relationship field with Name property
            if (value.Name) {
                return value.Name;
            }
            // If it's a relationship field with other common properties
            if (value.MasterLabel) {
                return value.MasterLabel;
            }
            if (value.Label) {
                return value.Label;
            }
            if (value.DeveloperName) {
                return value.DeveloperName;
            }
            // If it's an array, join the elements
            if (Array.isArray(value)) {
                return value.join(', ');
            }
            // Try to stringify the object, but avoid [object Object]
            try {
                const stringified = JSON.stringify(value);
                if (stringified && stringified !== '{}' && stringified !== 'null') {
                    return stringified;
                }
            } catch (e) {
                // console.log('Error stringifying object value:', e);
            }
            return 'N/A';
        }
        
        if (fieldType && fieldType.toUpperCase().includes('BOOLEAN')) {
            return value ? 'True' : 'False';
        }
        
        if (fieldType && fieldType.toUpperCase().includes('DATE')) {
            return value ? new Date(value).toLocaleDateString() : '';
        }
        
        if (fieldType && fieldType.toUpperCase().includes('DATETIME')) {
            return value ? new Date(value).toLocaleString() : '';
        }
        
        if (fieldType && fieldType.toUpperCase().includes('CURRENCY')) {
            return value ? `$${Number(value).toLocaleString()}` : '';
        }
        
        if (fieldType && fieldType.toUpperCase().includes('PERCENT')) {
            return value ? `${Number(value)}%` : '';
        }
        
        return String(value);
    }

    /**
     * @description Get unique field list for dynamic analysis, ensuring no duplicates
     * @return {Array} Array of unique field names
     */
    getUniqueFieldsForAnalysis() {
        // Always include core fields for data integrity
        const coreFields = ['Id', 'Name', 'Username', 'Email', 'IsActive', 'Profile.Name'];
        
        if (this.selectedUserFieldsForAnalysis && this.selectedUserFieldsForAnalysis.length > 0) {
            // Clean the array first to remove any potential duplicates and null/undefined values
            let cleanedFields = [...new Set(this.selectedUserFieldsForAnalysis.filter(field => field && field.trim && field.trim().length > 0))];
            
            // Combine core fields with selected fields, using Set to prevent duplicates
            const allFieldsSet = new Set([...coreFields, ...cleanedFields]);
            
            // Convert back to array
            const finalFields = Array.from(allFieldsSet);
            
            // console.log('Dynamic fields for analysis (with core fields):', finalFields);
            return finalFields;
        }
        
        // Fallback to core fields only when no additional fields are selected
        // console.log('Using core fields for analysis:', coreFields);
        return coreFields;
    }

    /**
     * @description Clean and validate selected fields to prevent duplicates
     */
    cleanSelectedFields() {
        if (this.selectedUserFieldsForAnalysis && this.selectedUserFieldsForAnalysis.length > 0) {
            // Remove duplicates, null/undefined values, and empty strings using Set for guaranteed uniqueness
            const fieldsSet = new Set(
                this.selectedUserFieldsForAnalysis
                    .filter(field => field && field.trim && field.trim().length > 0)
            );
            
            // Convert back to array
            this.selectedUserFieldsForAnalysis = Array.from(fieldsSet);
            
            // console.log('Cleaned selected fields:', this.selectedUserFieldsForAnalysis);
            
            // Update the isSelected state in availableUserFields to match
            this.availableUserFields = this.availableUserFields.map(field => ({
                ...field,
                isSelected: this.selectedUserFieldsForAnalysis.includes(field.name)
            }));
            
            // Also update filteredUserFields if it exists
            if (this.filteredUserFields && this.filteredUserFields.length > 0) {
                this.filteredUserFields = this.filteredUserFields.map(field => ({
                    ...field,
                    isSelected: this.selectedUserFieldsForAnalysis.includes(field.name)
                }));
            }
        } else {
            // If no fields selected, ensure all fields are marked as unselected
            this.selectedUserFieldsForAnalysis = [];
            this.availableUserFields = this.availableUserFields.map(field => ({
                ...field,
                isSelected: false
            }));
            
            if (this.filteredUserFields && this.filteredUserFields.length > 0) {
                this.filteredUserFields = this.filteredUserFields.map(field => ({
                    ...field,
                    isSelected: false
                }));
            }
        }
    }

    /**
     * @description Handle tab change in the analysis panel
     * @param {Event} event - Tab change event
     */
    handleTabChange(event) {
        this.activeTab = event.target.value;
    }

    /**
     * @description Close analysis panel
     */
    handleCloseAnalysis() {
        this.showAnalysisPanel = false;
    }

    /**
     * @description Cancel adding custom permission
     */
    handleCancelCustomPermission() {
        this.showCustomPermissionForm = false;
        this.customPermissionInput = '';
    }

    /**
     * @description Get placeholder text for search input
     */
    get searchPlaceholder() {
        return `Search ${this.title}`;
    }

    /**
     * @description Get text showing how many items are selected
     */
    get countLabel() {
        return `${this.filteredPermissions.length} permissions found`;
    }

    /**
     * @description Get CSS class for the analyze button
     */
    get analyzeButtonClass() {
        return this.isAnalyzeDisabled 
            ? 'analyze-button-disabled slds-m-right_small' 
            : 'analyze-button slds-m-right_small';
    }



    /**
     * @description Get unique ID for the select all checkbox
     */
    get selectAllId() {
        return `select-all-${this.title.replace(/\s+/g, '-').toLowerCase()}`;
    }

    /**
     * @description Get label for the profiles tab with count
     */
    get profilesTabLabel() {
        return `Profiles (${this.profilesData.length})`;
    }

    /**
     * @description Get label for the permission sets tab with count
     */
    get permSetsTabLabel() {
        return `Permission Sets (${this.permSetsData.length})`;
    }

    /**
     * @description Get label for the permission set groups tab with count
     */
    get permSetGroupsTabLabel() {
        return `Permission Set Groups (${this.permSetGroupsData.length})`;
    }

    /**
     * @description Get label for the users tab with count
     */
    get usersTabLabel() {
        return `Users (${this.usersData.length})`;
    }

    /**
     * @description Handle bulk export of all system permissions
     */
    handleBulkExport() {
        if (!this.isXLSXInitialized) {
            this.initializeXLSX();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Export Library Loading',
                    message: 'The export library is loading. Please try again in a moment.',
                    variant: 'info'
                })
            );
            return;
        }

        if (this.systemPermissions.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No Permissions Available',
                    message: 'There are no system permissions to export.',
                    variant: 'warning'
                })
            );
            return;
        }

        // Show performance improvement notification
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Export Starting',
                message: ' Expected time: 5-15 minutes ',
                variant: 'info',
                mode: 'sticky'
            })
        );

        // Initialize export state
        this.initializeExport(this.systemPermissions.length);
        
        // Start batch processing
        this.processBulkExportBatch();
    }
    
    /**
     * @description Handle export of only privileged permissions
     */
    handleExportPrivileged() {
        if (!this.isXLSXInitialized) {
            this.initializeXLSX();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Export Library Loading',
                    message: 'The export library is loading. Please try again in a moment.',
                    variant: 'info'
                })
            );
            return;
        }

        // Filter only privileged permissions
        const privilegedPermissions = this.systemPermissions.filter(p => p.isPrivileged);
        
        if (privilegedPermissions.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No Privileged Permissions',
                    message: 'There are no privileged permissions to export.',
                    variant: 'warning'
                })
            );
            return;
        }

        // Show notification
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Privileged Export Starting',
                message: `Exporting ${privilegedPermissions.length} privileged permissions...`,
                variant: 'info',
                mode: 'sticky'
            })
        );

        // Initialize export state with only privileged permissions
        this.isBulkExporting = true;
        this.showBulkExportModal = true;
        this.isBulkExportMinimized = false;
        this.bulkExportProgress = 0;
        this.bulkExportTotal = privilegedPermissions.length;
        this.bulkExportProcessed = 0;
        this.bulkExportResults = [];
        this.bulkExportStatus = 'Preparing privileged permissions export...';
        this.batchSize = 0;
        this.batchProcessed = 0;
        this.updateProgressBar(0);
        
        // Start batch processing with privileged permissions only
        this.processPrivilegedExportBatch(privilegedPermissions);
    }

    /**
     * @description Initialize the export process with proper state
     * @param {Number} totalItems - Total number of items to process
     */
    initializeExport(totalItems) {
        // Reset all export tracking variables
        this.isBulkExporting = true;
        this.showBulkExportModal = true;
        this.isBulkExportMinimized = false;
        this.bulkExportProgress = 0;
        this.bulkExportTotal = totalItems;
        this.bulkExportProcessed = 0;
        this.bulkExportResults = [];
        this.bulkExportStatus = 'Preparing export...';
        
        // Reset batch tracking properties
        this.batchSize = 0;
        this.batchProcessed = 0;
        
        // Initialize progress bar to 0%
        this.updateProgressBar(0);
        
        // console.log(`Export initialized with ${totalItems} items to process`);
    }
    
    /**
     * @description Process a batch of permissions for bulk export - ULTRA OPTIMIZED FOR SPEED
     */
    processBulkExportBatch() {
        // LARGER BATCH SIZE for ultra-optimized methods - much faster processing
        const batchSize = 15; // Increased from 5 to 15 for faster bulk processing

        // Calculate the start and end indices for this batch
        const startIdx = this.bulkExportProcessed;
        const endIdx = Math.min(startIdx + batchSize, this.bulkExportTotal);

        // Extract the batch of permissions to process
        const batch = this.systemPermissions.slice(startIdx, endIdx);

        // Update status with speed optimization info
        this.bulkExportStatus = `🚀 Fast processing permissions ${startIdx + 1}-${endIdx} of ${this.bulkExportTotal}...`;

        // Setup tracking for batch progress
        this.batchSize = batch.length;
        this.batchProcessed = 0;

        // Process each permission in the batch sequentially
        this.processPermissionBatchSequentially(batch, 0)
            .then(() => {
                // Update progress
                this.bulkExportProcessed = endIdx;
                const newProgress = Math.round((endIdx / this.bulkExportTotal) * 90); // Use 90% for processing, reserve 10% for Excel generation
                
                // Make sure progress never decreases
                this.bulkExportProgress = Math.max(this.bulkExportProgress, newProgress);

                // Update the progress bar
                this.updateProgressBar(this.bulkExportProgress);

                // Check if we're done
                if (endIdx < this.bulkExportTotal) {
                    // Process next batch with minimal delay for speed
                    Promise.resolve().then(() => this.processBulkExportBatch());
                } else {
                    // All batches are processed, generate Excel file
                    this.bulkExportStatus = '📊 Generating Excel file...';
                    this.bulkExportProgress = 95; // Set to 95% for Excel generation
                    this.updateProgressBar(this.bulkExportProgress);
                    Promise.resolve().then(() => this.generateBulkExportExcel());
                }
            })
            .catch(error => {
                // console.error('Error processing bulk export batch:', error);
                this.bulkExportStatus = '❌ Error during export. See console for details.';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Export Error',
                        message: error.message || 'An error occurred during the export process.',
                        variant: 'error'
                    })
                );
            });
    }
    
    /**
     * @description Process a batch of PRIVILEGED permissions for export
     * @param {Array} privilegedPermissions - Array of only privileged permissions to export
     */
    processPrivilegedExportBatch(privilegedPermissions) {
        const batchSize = 15;

        const startIdx = this.bulkExportProcessed;
        const endIdx = Math.min(startIdx + batchSize, this.bulkExportTotal);
        const batch = privilegedPermissions.slice(startIdx, endIdx);

        this.bulkExportStatus = `🛡️ Processing privileged permissions ${startIdx + 1}-${endIdx} of ${this.bulkExportTotal}...`;
        this.batchSize = batch.length;
        this.batchProcessed = 0;

        // Process batch sequentially
        this.processPermissionBatchSequentially(batch, 0)
            .then(() => {
                this.bulkExportProcessed = endIdx;
                const newProgress = Math.round((endIdx / this.bulkExportTotal) * 90);
                this.bulkExportProgress = Math.max(this.bulkExportProgress, newProgress);
                this.updateProgressBar(this.bulkExportProgress);

                if (endIdx < this.bulkExportTotal) {
                    Promise.resolve().then(() => this.processPrivilegedExportBatch(privilegedPermissions));
                } else {
                    // Generate Excel with privileged-specific formatting
                    this.bulkExportStatus = '🛡️ Generating privileged permissions Excel file...';
                    this.bulkExportProgress = 95;
                    this.updateProgressBar(this.bulkExportProgress);
                    Promise.resolve().then(() => this.generatePrivilegedExportExcel());
                }
            })
            .catch(error => {
                this.bulkExportStatus = '❌ Error during privileged export.';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Privileged Export Error',
                        message: error.message || 'An error occurred during the privileged export process.',
                        variant: 'error'
                    })
                );
            });
    }

    /**
     * @description Process permissions in a batch sequentially - ULTRA OPTIMIZED FOR LARGE ORGS
     * @param {Array} batch - Batch of permissions to process
     * @param {Number} index - Current index in the batch
     * @returns {Promise} Promise that resolves when the batch is processed
     */
    processPermissionBatchSequentially(batch, index) {
        return new Promise((resolve, reject) => {
            if (index >= batch.length) {
                resolve();
                return;
            }

            const permission = batch[index];

            // Update detailed status
            this.bulkExportStatus = `Analyzing "${permission.label}"...`;

            // USE ULTRA-OPTIMIZED METHOD WITH AGGRESSIVE FALLBACK STRATEGY
            this.processPermissionWithUltraOptimizedFallback(permission.name)
                .then(result => {
                    // Store the result for this permission
                    this.bulkExportResults.push({
                        permission: permission,
                        result: result
                    });
                    
                    // Update intermediate progress bar within batch
                    this.batchProcessed++;
                    // Avoid decreasing progress with Math.max
                    this.bulkExportProgress = Math.max(
                        this.bulkExportProgress,
                        Math.round(((this.bulkExportProcessed + (this.batchProcessed / this.batchSize)) / this.bulkExportTotal) * 90)
                    );
                    this.updateProgressBar(this.bulkExportProgress);

                    // Process next permission in the batch
                    this.processPermissionBatchSequentially(batch, index + 1)
                        .then(resolve)
                        .catch(reject);
                })
                .catch(() => {
                    // // console.warn(`Error processing permission ${permission.name}:`, error);
                    
                    // Create fallback result to continue processing
                    this.bulkExportResults.push({
                        permission: permission,
                        result: {
                            systemPermissionName: permission.name,
                            profilesWithAccess: [],
                            permissionSetsWithAccess: [],
                            permissionSetGroupsWithAccess: [],
                            usersWithAccess: [],
                            totalUsers: 0,
                            error: 'Analysis failed - data incomplete',
                            isFallback: true
                        }
                    });
                    
                    // Update intermediate progress bar within batch
                    this.batchProcessed++;
                    // Avoid decreasing progress with Math.max
                    this.bulkExportProgress = Math.max(
                        this.bulkExportProgress,
                        Math.round(((this.bulkExportProcessed + (this.batchProcessed / this.batchSize)) / this.bulkExportTotal) * 90)
                    );
                    this.updateProgressBar(this.bulkExportProgress);
                    
                    // Still continue with next permission
                    this.processPermissionBatchSequentially(batch, index + 1)
                        .then(resolve)
                        .catch(reject);
                });
        });
    }

    /**
     * @description Process permission with ultra-optimized fallback strategy for bulk export
     * @param {String} permissionName - The name of the system permission to analyze
     * @returns {Promise} Promise that resolves to permission data
     */
    async processPermissionWithUltraOptimizedFallback(permissionName) {
        try {
            // ULTRA-AGGRESSIVE STRATEGY: Start with the fastest method for large orgs
            try {
                // console.log(`🚀 Bulk Export: Ultra-optimized analysis for permission: ${permissionName}`);
                return await getSystemPermissionAccessUltraOptimized({ 
                    systemPermissionName: permissionName,
                    maxUsers: 5000 // Increased limit to show more users in privileged export
                });
            } catch (ultraError) {
                // console.warn(`⚠️ Ultra-optimized failed for ${permissionName}, trying optimized:`, ultraError);
                
                // Second attempt: Try optimized method with very small limits
return await getSystemPermissionAccessOptimized({ 
    systemPermissionName: permissionName,
    userPageSize: 25, // Very small page size
    userPageNumber: 1
});
            }
        } catch (error) {
            // console.error(`❌ All methods failed for permission ${permissionName}:`, error);
            
            // Final fallback: return minimal data structure to prevent complete failure
            return {
                systemPermissionName: permissionName,
                profilesWithAccess: [],
                permissionSetsWithAccess: [],
                permissionSetGroupsWithAccess: [],
                usersWithAccess: [],
                totalUsers: 0,
                error: 'Analysis failed due to org size limitations - data incomplete',
                errorDetails: error.body ? error.body.message : error.message,
                isFallback: true,
                isUltraOptimized: true
            };
        }
    }

    /**
     * @description Generate Excel file for bulk export with HTML tables for styling
     */
    generateBulkExportExcel() {
        try {
            // console.log('Starting Excel generation with batched processing approach');
            
            // Create a workbook
            const workbook = window.XLSX.utils.book_new();
            workbook.Props = {
                Title: "System Permissions Export",
                Subject: "Salesforce System Permissions",
                Author: "Permissions Manager",
                CreatedDate: new Date()
            };
            
            // Define worksheets to generate
            const worksheets = [
               /* { name: 'Summary', generator: () => this.generateSummaryWorksheet() },*/
                { name: 'Permissions By Profile', generator: () => this.generateProfilePermissionsWorksheet() },
                { name: 'Permissions By User', generator: () => this.generateUserPermissionsWorksheet() },
                { name: 'Permission Sets', generator: () => this.generatePermissionSetsWorksheet() },
                { name: 'Permission Set Groups', generator: () => this.generatePermissionSetGroupsWorksheet() }
            ];
            
            // Process each worksheet in batches
            worksheets.forEach(({ name, generator }, index) => {
                try {
                    // console.log(`Processing worksheet: ${name}`);
                    
                    // Update progress
                    const worksheetProgress = Math.floor((index / worksheets.length) * 25) + 75; // 75-100% range
                    this.bulkExportStatus = `Creating worksheet: ${name}`;
                    this.updateProgressBar(worksheetProgress);
                    
                    // Generate worksheet data
                    const rawData = generator();
                    
                    // Process data in batches to prevent string length errors
                    const worksheetData = this.createWorksheetDataBatched(rawData, name, 500);
                    
                    // Create worksheet using direct array-to-sheet conversion
                    const worksheet = window.XLSX.utils.aoa_to_sheet(worksheetData);
                    
                    // Apply styling
                    this.applyWorksheetStyling(worksheet, name, worksheetData);
                    
                    // Add to workbook
                    window.XLSX.utils.book_append_sheet(workbook, worksheet, name);
                    
                    // console.log(`Successfully added worksheet: ${name} (${worksheetData.length} rows)`);
                    
                } catch (worksheetError) {
                    // console.error(`Error creating worksheet ${name}:`, worksheetError);
                    
                    // Create a minimal worksheet with error message
                    const errorData = [
                        ['Error'],
                        [`Failed to generate ${name} worksheet`],
                        ['Error details:', worksheetError.message || 'Unknown error']
                    ];
                    const errorWorksheet = window.XLSX.utils.aoa_to_sheet(errorData);
                    window.XLSX.utils.book_append_sheet(workbook, errorWorksheet, name);
                }
            });

            // Generate filename
            const now = new Date();
            const timestamp = now.toISOString().replace(/[:\-T]/g, '_').split('.')[0];
            const filename = `System_Permissions_Export_${timestamp}.xlsx`;

            // Update status
            this.bulkExportStatus = 'Downloading Excel file...';
            this.bulkExportProgress = 100;
            this.updateProgressBar(100);

            // Write the file and trigger download
            window.XLSX.writeFile(workbook, filename);
            // console.log('Excel file downloaded successfully');

            // Hide modal and show success message
            Promise.resolve().then(() => {
                this.showBulkExportModal = false;
                this.isBulkExportMinimized = false;
                this.isBulkExporting = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'SystemPermissions BulkExport Complete',
                        message: `Successfully exported ${this.bulkExportResults.length} permissions, Export completed`,
                        variant: 'success',
                        mode: 'sticky'
                    })
                );
            });
        } catch (error) {
            // console.error('Error generating Excel file:', error);
            this.bulkExportStatus = 'Error generating Excel file.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Export Error',
                    message: 'An error occurred while generating the Excel file: ' + (error.message || error),
                    variant: 'error'
                })
            );
            Promise.resolve().then(() => {
                this.showBulkExportModal = false;
                this.isBulkExportMinimized = false;
                this.isBulkExporting = false;
            });
        }
    }
    
    /**
     * @description Generate Excel file for PRIVILEGED permissions export with detailed info
     */
    generatePrivilegedExportExcel() {
        try {
            // Create workbook
            const workbook = window.XLSX.utils.book_new();
            workbook.Props = {
                Title: "Privileged System Permissions Export",
                Subject: "Privileged Salesforce System Permissions",
                Author: "Permissions Manager",
                CreatedDate: new Date()
            };
            
            // Define privileged-specific worksheets
            const worksheets = [
                { name: 'Privileged by Profile', generator: () => this.generatePrivilegedProfilesWorksheet() },
                { name: 'Privileged by Perm Set', generator: () => this.generatePrivilegedPermSetsWorksheet() },
                { name: 'Privileged by Perm Group', generator: () => this.generatePrivilegedPermSetGroupsWorksheet() },
                { name: 'Privileged by User', generator: () => this.generatePrivilegedUsersWorksheet() }
            ];
            
            // Process each worksheet
            worksheets.forEach(({ name, generator }, index) => {
                try {
                    const worksheetProgress = Math.floor((index / worksheets.length) * 25) + 75;
                    this.bulkExportStatus = `Creating ${name} worksheet...`;
                    this.updateProgressBar(worksheetProgress);
                    
                    const rawData = generator();
                    const worksheetData = this.createWorksheetDataBatched(rawData, name, 500);
                    const worksheet = window.XLSX.utils.aoa_to_sheet(worksheetData);
                    
                    this.applyWorksheetStyling(worksheet, name, worksheetData);
                    window.XLSX.utils.book_append_sheet(workbook, worksheet, name);
                    
                } catch (worksheetError) {
                    const errorData = [['Error'], [`Failed to generate ${name}`], ['Details:', worksheetError.message]];
                    const errorWorksheet = window.XLSX.utils.aoa_to_sheet(errorData);
                    window.XLSX.utils.book_append_sheet(workbook, errorWorksheet, name);
                }
            });

            // Generate filename with timestamp
            const now = new Date();
            const timestamp = now.toISOString().replace(/[:\-T]/g, '_').split('.')[0];
            const filename = `Privileged_Permissions_Export_${timestamp}.xlsx`;

            // Update status and download
            this.bulkExportStatus = 'Downloading privileged permissions Excel...';
            this.bulkExportProgress = 100;
            this.updateProgressBar(100);

            window.XLSX.writeFile(workbook, filename);

            // Hide modal and show success
            Promise.resolve().then(() => {
                this.showBulkExportModal = false;
                this.isBulkExportMinimized = false;
                this.isBulkExporting = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: '🛡️ Privileged Permissions Export Complete',
                        message: `Successfully exported ${this.bulkExportResults.length} privileged permissions`,
                        variant: 'success',
                        mode: 'sticky'
                    })
                );
            });
        } catch (error) {
            this.bulkExportStatus = 'Error generating privileged Excel file.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Export Error',
                    message: 'Error generating privileged export: ' + (error.message || error),
                    variant: 'error'
                })
            );
            Promise.resolve().then(() => {
                this.showBulkExportModal = false;
                this.isBulkExportMinimized = false;
                this.isBulkExporting = false;
            });
        }
    }
    

    
    /**
     * @description Create a styled HTML table from data
     * @param {Array} data - Array of arrays containing the sheet data
     * @param {String} sheetType - Type of sheet for specific styling
     * @param {String} tableId - Unique ID for the table
     * @return {String} HTML string for the table
     */
    /**
     * @description Create worksheet data in batches to prevent string length errors
     * @param {Array} data - The data array to process
     * @param {string} sheetType - Type of sheet for styling
     * @param {number} batchSize - Number of rows to process at a time (default 500)
     * @returns {Array} Array of arrays suitable for XLSX
     */
    createWorksheetDataBatched(data, sheetType, batchSize = 500) {
        if (!data || !data.length) {
            return [['No data']];
        }
        
        // console.log(`Processing ${sheetType} with ${data.length} rows in batches of ${batchSize}`);
        
        // For very large datasets, we'll use direct array-to-sheet conversion
        // instead of HTML tables to avoid string length issues
        const worksheetData = [];
        
        // Process header row first
        if (data.length > 0) {
            worksheetData.push(data[0]);
        }
        
        // Process data rows in batches
        for (let i = 1; i < data.length; i += batchSize) {
            const endIndex = Math.min(i + batchSize, data.length);
            const batch = data.slice(i, endIndex);
            
            // console.log(`Processing batch ${Math.floor(i/batchSize) + 1}: rows ${i}-${endIndex-1}`);
            
            // Add batch data to worksheet
            batch.forEach(row => {
                worksheetData.push(row);
            });
            
            // Update progress
            const progress = Math.floor((endIndex / data.length) * 100);
            this.bulkExportStatus = `Processing ${sheetType}: ${progress}%`;
            this.updateProgressBar(75 + (progress * 0.2)); // 75-95% range for this phase
        }
        
        // console.log(`Completed processing ${sheetType}: ${worksheetData.length} total rows`);
        return worksheetData;
    }

    /**
     * @description Apply cell styling to worksheet using XLSX native methods
     * @param {Object} worksheet - The XLSX worksheet
     * @param {string} sheetType - Type of sheet for styling
     * @param {Array} data - The worksheet data for reference
     */
    applyWorksheetStyling(worksheet, sheetType, data) {
        if (!worksheet || !data || !data.length) return;
        
        try {
            // Set column widths
            const columnWidths = this.calculateColumnWidths(data);
            worksheet['!cols'] = columnWidths;
            
            // Set freeze panes
            const freezeOptions = this.getWorksheetFreezeOptions(sheetType);
            worksheet['!view'] = { panes: [freezeOptions] };
            
            // Apply basic formatting if XLSX supports it
            if (window.XLSX && window.XLSX.utils && window.XLSX.utils.encode_cell) {
                // Header row styling
                if (data.length > 0) {
                    const headerRow = data[0];
                    for (let col = 0; col < headerRow.length; col++) {
                        const cellAddress = window.XLSX.utils.encode_cell({ r: 0, c: col });
                        if (worksheet[cellAddress]) {
                            worksheet[cellAddress].s = {
                                fill: { fgColor: { rgb: "1F497D" } },
                                font: { color: { rgb: "FFFFFF" }, bold: true },
                                alignment: { horizontal: "center" }
                            };
                        }
                    }
                }
            }
            
        } catch (error) {
            // console.warn('Could not apply advanced styling:', error);
        }
    }

    /**
     * @description Close bulk export modal
     */
    handleCloseBulkExportModal() {
        if (!this.isBulkExporting) {
            this.showBulkExportModal = false;
        }
    }

    /**
     * @description Cancel ongoing bulk export
     */
    handleCancelBulkExport() {
        // eslint-disable-next-line no-alert
        if (window.confirm('Are you sure you want to cancel the export?')) {
            this.isBulkExporting = false;
            this.showBulkExportModal = false;
            this.isBulkExportMinimized = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Export Cancelled',
                    message: 'The bulk export operation was cancelled.',
                    variant: 'info'
                })
            );
        }
    }

    /**
     * @description Minimize the bulk export modal
     */
    handleMinimizeBulkExport() {
        this.isBulkExportMinimized = true;
        this.isMinimizedExpanded = false;
        // console.log('Bulk export modal minimized - export continues in background');
        
        // Show a toast to inform user
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Export Minimized',
                message: 'Export continues in background. Click the chat icon to view progress.',
                variant: 'info'
            })
        );
    }

    /**
     * @description Restore the bulk export modal from minimized state
     */
    handleRestoreBulkExport() {
        this.isBulkExportMinimized = false;
        this.isMinimizedExpanded = false;
        // console.log('Bulk export modal restored');
    }

    /**
     * @description Toggle the minimized widget between chat icon and expanded view
     */
    handleToggleMinimizedWidget() {
        this.isMinimizedExpanded = !this.isMinimizedExpanded;
    }

    /**
     * @description Collapse the minimized widget back to chat icon
     */
    handleCollapseMinimizedWidget() {
        this.isMinimizedExpanded = false;
    }

    /**
     * @description Get CSS class for minimized widget
     */
    get minimizedWidgetClass() {
        let baseClass = 'minimized-export-widget';
        if (this.isMinimizedExpanded) {
            baseClass += ' expanded';
        }
        if (this.isBulkExporting && !this.isMinimizedExpanded) {
            baseClass += ' pulse-animation';
        }
        return baseClass;
    }

    /**
     * @description Get tooltip text for minimized widget
     */
    get minimizedWidgetTooltip() {
        if (this.isMinimizedExpanded) {
            return 'Click to minimize to icon';
        }
        return `Export Progress: ${this.bulkExportProgress}% - Click to expand`;
    }

    /**
     * @description Update progress ring via DOM manipulation
     */
    updateProgressRing() {
        const progressRing = this.template.querySelector('.progress-ring');
        if (progressRing && this.bulkExportProgress !== undefined) {
            const progressAngle = (this.bulkExportProgress / 100) * 360;
            progressRing.style.setProperty('--progress-angle', `${progressAngle}deg`);
        }
    }

    /**
     * @description Update progress bar and ring when progress changes
     */
    updateProgressBar() {
        // Update the standard progress bar
        const progressBars = this.template.querySelectorAll('.slds-progress-bar__value');
        progressBars.forEach(bar => {
            if (bar) {
                bar.style.width = `${this.bulkExportProgress}%`;
            }
        });
        
        // Update the progress ring
        this.updateProgressRing();
    }

    /**
     * @description Check if bulk export is disabled
     */
    get isBulkExportDisabled() {
        return this.systemPermissions.length === 0 || this.isBulkExporting || !this.isXLSXInitialized;
    }
    
    /**
     * @description Check if export privileged is disabled
     */
    get isExportPrivilegedDisabled() {
        const privilegedCount = this.systemPermissions.filter(p => p.isPrivileged).length;
        return privilegedCount === 0 || this.isBulkExporting || !this.isXLSXInitialized;
    }

    /**
     * @description Get the analyze button variant
     */
    get analyzeButtonVariant() {
        return this.selectedPermission ? 'brand' : 'neutral';
    }

    /**
     * @description Add a new method to initialize the progress bar
     */
    initializeProgressBar() {
        // This will be called whenever the progress bar needs to be updated
        this.updateProgressBar(0);
    }



    handleProfileSelectionChange(event) {
        // Make sure we're storing a regular array, not a Proxy object
        const selectedItems = event.detail.selectedItems || [];
        this.selectedProfileIds = [...selectedItems.map(item => item.id)];
        // console.log('Profile selection changed:', JSON.stringify(this.selectedProfileIds));
    }

    handlePermSetSelectionChange(event) {
        // Make sure we're storing a regular array, not a Proxy object
        const selectedItems = event.detail.selectedItems || [];
        this.selectedPermSetIds = [...selectedItems.map(item => item.id)];
        // console.log('Permission Set selection changed:', JSON.stringify(this.selectedPermSetIds));
    }

    handlePermSetGroupSelectionChange(event) {
        // Make sure we're storing a regular array, not a Proxy object
        const selectedItems = event.detail.selectedItems || [];
        this.selectedPermSetGroupIds = [...selectedItems.map(item => item.id)];
        // console.log('Permission Set Group selection changed:', JSON.stringify(this.selectedPermSetGroupIds));
    }

    handleSystemPermissionSelectionChange(event) {
        // Make sure we're storing a regular array, not a Proxy object
        const selectedItems = event.detail.selectedItems || [];
        this.selectedSystemPermissions = [...selectedItems.map(item => item.id)];
        // console.log('System Permission selection changed:', JSON.stringify(this.selectedSystemPermissions));
    }
    
    /**
     * @description Handle select all privileged permissions
     */
    handleSelectAllPrivileged() {
        // Find all privileged permissions and select them
        const privilegedPermissions = this.systemPermissions.filter(perm => perm.isPrivileged);
        this.selectedSystemPermissions = privilegedPermissions.map(perm => perm.id);
        
        // Update system permissions to reflect selection
        this.systemPermissions = this.systemPermissions.map(perm => ({
            ...perm,
            isSelected: perm.isPrivileged
        }));
        
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Privileged Permissions Selected',
                message: `${privilegedPermissions.length} privileged permissions have been selected`,
                variant: 'success'
            })
        );
    }

    handleUserSelectionChange(event) {
        // Ignore explicit selections if include-all is active
        if (this.includeAllUsers) {
            return;
        }
        const selectedItems = event.detail.selectedItems || [];
        this.selectedUserIds = [...selectedItems.map(it => it.id)];
    }

    handleUserFieldSelectionChange(event) {
        // Make sure we're storing a regular array, not a Proxy object
        const selectedItems = event.detail.selectedItems || [];
        this.selectedUserFields = [...selectedItems.map(item => item.id)];
        // console.log('User Field selection changed:', JSON.stringify(this.selectedUserFields));
    }

    getProfiles() {
        return getProfiles()
            .then(profiles => {
                // Ensure profiles is an array
                if (!Array.isArray(profiles)) {
                    // console.warn('Profiles data is not an array:', profiles);
                    profiles = [];
                }
                
                // Format profiles for selection panel
                this.profiles = profiles.map(profile => ({
                    ...profile,
                    isSelected: this.selectedProfileIds.includes(profile.id)
                }));
                return this.profiles;
            })
            .catch(error => {
                // console.error('Error fetching profiles:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Loading Profiles',
                        message: error.message || 'An error occurred while loading profiles.',
                        variant: 'error'
                    })
                );
                this.profiles = [];
                return [];
            });
    }

    getPermissionSets() {
        return getPermissionSets()
            .then(permissionSets => {
                // Ensure permissionSets is an array
                if (!Array.isArray(permissionSets)) {
                    // console.warn('Permission sets data is not an array:', permissionSets);
                    permissionSets = [];
                }
                
                // Format permission sets for selection panel
                this.permissionSets = permissionSets.map(permSet => ({
                    ...permSet,
                    isSelected: this.selectedPermSetIds.includes(permSet.id)
                }));
                return this.permissionSets;
            })
            .catch(error => {
                // console.error('Error fetching permission sets:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Loading Permission Sets',
                        message: error.message || 'An error occurred while loading permission sets.',
                        variant: 'error'
                    })
                );
                this.permissionSets = [];
                return [];
            });
    }

    getSystemPermissions() {
        // Use the already loaded system permissions if available
        if (this.systemPermissions && Array.isArray(this.systemPermissions) && this.systemPermissions.length > 0) {
            // Update selected state based on selectedSystemPermissions
            this.systemPermissions = this.systemPermissions.map(perm => ({
                ...perm,
                isSelected: this.selectedSystemPermissions.includes(perm.id)
            }));
            return Promise.resolve(this.systemPermissions);
        }
        
        return getSystemPermissions()
            .then(systemPermissions => {
                // Ensure systemPermissions is an array
                if (!Array.isArray(systemPermissions)) {
                    // console.warn('System permissions data is not an array:', systemPermissions);
                    systemPermissions = [];
                }
                
                // Format system permissions for selection panel
                this.systemPermissions = systemPermissions.map(perm => ({
                    ...perm,
                    isSelected: this.selectedSystemPermissions.includes(perm.id)
                }));
                return this.systemPermissions;
            })
            .catch(error => {
                // console.error('Error fetching system permissions:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Loading System Permissions',
                        message: error.message || 'An error occurred while loading system permissions.',
                        variant: 'error'
                    })
                );
                this.systemPermissions = [];
                return [];
            });
    }

    getUsers() {
        // console.log('=== BEGIN getUsers ===');
        return getUsers()
            .then(users => {
                // console.log('Fetched users from server:', users ? users.length : 0, 'users');
            // console.log('Sample user data:', users && users.length > 0 ? users[0] : 'No users');
                
                // Ensure users is an array
                if (!Array.isArray(users)) {
                    // console.warn('Users data is not an array:', users);
                    users = [];
                }
                
                // Format users for selection panel
                this.users = users.map(user => ({
                    ...user,
                    isSelected: this.selectedUserIds.includes(user.id)
                }));
                
                // console.log('Formatted users for UI:', this.users.length, 'users');
                // console.log('Selected user IDs:', JSON.stringify(this.selectedUserIds));
                // console.log('=== END getUsers - Success ===');
                return this.users;
            })
            .catch(error => {
                // console.error('Error fetching users:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Loading Users',
                        message: error.message || 'An error occurred while loading users.',
                        variant: 'error'
                    })
                );
                // console.log('=== END getUsers - Error ===');
                this.users = [];
                return [];
            });
    }

    /**
     * @description Get users with pagination support for template creation
     * @param {Number} pageSize - Number of users per page (default: 100)
     * @param {Number} pageNumber - Page number (1-based, default: 1) 
     * @param {String} searchTerm - Optional search term to filter users
     * @param {String} lastUserId - Last user ID for cursor-based pagination
     * @returns {Promise} Promise that resolves to paginated user data
     */
    getUsersPaginated(pageSize = 100, pageNumber = 1, searchTerm = '', lastUserId = '') {
        // console.log('=== BEGIN getUsersPaginated ===', { pageSize, pageNumber, searchTerm, lastUserId });
        
        return getUsersPaginated({ 
            pageSize: pageSize, 
            pageNumber: pageNumber, 
            searchTerm: searchTerm,
            lastUserId: lastUserId
        })
            .then(result => {
                // console.log('Fetched paginated users from server:', result);
                
                if (!result || !Array.isArray(result.users)) {
                    // console.warn('Invalid paginated users data:', result);
                    return {
                        users: [],
                        totalCount: 0,
                        pageSize: pageSize,
                        pageNumber: pageNumber,
                        totalPages: 0,
                        hasNext: false,
                        hasPrevious: false,
                        lastUserId: null
                    };
                }
                
                // Format users for selection panel
                const formattedUsers = result.users.map(user => ({
                    ...user,
                    isSelected: this.selectedUserIds.includes(user.id),
                    type: user.profileName // Add type for display
                }));
                
                // console.log('Formatted paginated users for UI:', formattedUsers.length, 'users');
                // console.log('Pagination info:', {
                //     totalCount: result.totalCount,
                //     pageSize: result.pageSize,
                //     pageNumber: result.pageNumber,
                //     totalPages: result.totalPages,
                //     hasNext: result.hasNext,
                //     hasPrevious: result.hasPrevious
                // });
                
                const paginatedResult = {
                    ...result,
                    users: formattedUsers
                };
                
                // console.log('=== END getUsersPaginated - Success ===');
                return paginatedResult;
            })
            .catch(error => {
                // console.error('Error fetching paginated users:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Loading Users',
                        message: error.message || 'An error occurred while loading users.',
                        variant: 'error'
                    })
                );
                // console.log('=== END getUsersPaginated - Error ===');
                return {
                    users: [],
                    totalCount: 0,
                    pageSize: pageSize,
                    pageNumber: pageNumber,
                    totalPages: 0,
                    hasNext: false,
                    hasPrevious: false,
                    lastUserId: null
                };
            });
    }

    getUserFields() {
        // console.log('=== BEGIN getUserFields ===');
        return getUserFields()
            .then(userFields => {
                // console.log('Fetched user fields from server:', userFields ? userFields.length : 0, 'fields');
            // console.log('Sample user field data:', userFields && userFields.length > 0 ? userFields[0] : 'No fields');
                
                // Ensure userFields is an array
                if (!Array.isArray(userFields)) {
                    // console.warn('User fields data is not an array:', userFields);
                    userFields = [];
                }
                
                // Format user fields for selection panel
                this.userFields = userFields.map(field => ({
                    ...field,
                    isSelected: this.selectedUserFields.includes(field.id)
                }));
                
                // console.log('Formatted user fields for UI:', this.userFields.length, 'fields');
                // console.log('Selected user field IDs:', JSON.stringify(this.selectedUserFields));
                // console.log('=== END getUserFields - Success ===');
                return this.userFields;
            })
            .catch(error => {
                // console.error('Error fetching user fields:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Loading User Fields',
                        message: error.message || 'An error occurred while loading user fields.',
                        variant: 'error'
                    })
                );
                // console.log('=== END getUserFields - Error ===');
                this.userFields = [];
                return [];
            });
    }

    getPermissionSetGroups() {
        return getPermissionSetGroupsPaginated({ searchTerm: '', pageNumber: 1, pageSize: 1000 })
            .then(result => {
                // Ensure result and permissionSetGroups are valid
                if (!result || !Array.isArray(result.permissionSetGroups)) {
                    // console.warn('Permission Set Groups data is not valid:', result);
                    result = { permissionSetGroups: [] };
                }
                
                // Format permission set groups for selection panel
                this.permissionSetGroups = result.permissionSetGroups.map(group => ({
                    ...group,
                    name: group.masterLabel, // Map masterLabel to name for display
                    isSelected: this.selectedPermSetGroupIds.includes(group.id)
                }));
                
                return this.permissionSetGroups;
            })
            .catch(error => {
                // console.error('Error fetching permission set groups:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Loading Permission Set Groups',
                        message: error.message || 'An error occurred while loading permission set groups.',
                        variant: 'error'
                    })
                );
                this.permissionSetGroups = [];
                return [];
            });
    }

    handleShowSaveTemplates() {
         
        
        // If already animating, prevent multiple clicks
        if (this.templateManagerAnimating) {
            //console.log('⚠️ Animation in progress, returning early');
            return;
        }

        // If we're hiding the template manager, just toggle it
        if (this.showTemplateManager) {
            this.templateManagerAnimating = true;
            
            // Add animation class for hiding
            const templateContainer = this.template.querySelector('.template-manager-container');
            if (templateContainer) {
                templateContainer.classList.add('template-manager-hiding');
                
                // Wait for animation to complete before hiding
                Promise.resolve().then(() => {
                    this.showTemplateManager = false;
                    this.templateManagerAnimating = false;
                    // Show main panel when template manager is hidden
                    this.showMainPanel = true;
                });
            } else {
                // If element not found, just toggle immediately
                this.showTemplateManager = false;
                this.templateManagerAnimating = false;
                // Show main panel when template manager is hidden
                this.showMainPanel = true;
            }
            return;
        }

        // If showing the template manager
       // console.log('🔄 Showing template manager...');
        this.isLoading = true;
        this.templateManagerAnimating = true;
        
        // Check if the custom object exists first
       // console.log('🔍 Checking if PermissionsTemplate__c exists...');
        checkPermissionsTemplateExists()
            .then(exists => {
              //  console.log('✅ Custom object exists check result:', exists);
                if (!exists) {
                  //  console.log('⚠️ Custom object does not exist, showing warning');
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Custom Object Missing',
                            message: 'The PermissionsTemplate__c custom object does not exist in this org. Please deploy the metadata first.',
                            variant: 'warning'
                        })
                    );
                    this.showMissingObjectWarning = true;
                    this.isLoading = false;
                    this.templateManagerAnimating = false;
                    return Promise.reject('Custom object does not exist');
                }

                console.log('🔄 Loading all data for template manager...');
                // Load all data including templates
                return Promise.all([
                    this.loadTemplates(),
                    this.getProfiles(),
                    this.getPermissionSets(),
                    this.getSystemPermissions(),
                    this.getUsers(),
                    this.getUserFields()
                ]);
            })
            .then(() => {
                //console.log('📊 Data loading results:', results);
              //  console.log('✅ All data loaded successfully:', results.length, 'arrays loaded');
              //  console.log('🎯 Setting showTemplateManager = true');
                this.showTemplateManager = true;
                // Hide main panel when template manager is shown
                this.showMainPanel = false;
                //console.log('✅ Template manager should now be visible');
                this.isLoading = false;
                this.templateManagerAnimating = false;
            })
            .catch(err => {
                console.error('❌ Error initializing template manager:', err);
                if (err !== 'Custom object does not exist') {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error Loading Template Manager',
                            message: err.message || 'An error occurred while loading the template manager.',
                            variant: 'error'
                        })
                    );
                }
                this.isLoading = false;
                this.templateManagerAnimating = false;
            });
    }

    /**
     * @description Handle creating the custom object
     */
    handleCreateCustomObject() {
        this.isLoading = true;
        
        createPermissionsTemplateObject()
            .then(success => {
                if (success) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'The PermissionsTemplate__c custom object has been created successfully.',
                            variant: 'success'
                        })
                    );
                    this.showMissingObjectWarning = false;
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Deployment Required',
                            message: 'The custom object cannot be created dynamically. Please deploy the metadata using Salesforce CLI or another deployment tool.',
                            variant: 'warning'
                        })
                    );
                }
            })
            .catch(err => {
                // console.error('Error creating custom object:', err);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Creating Custom Object',
                        message: err.message || err.body?.message || 'An error occurred while creating the custom object.',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * @description Handle generating a template
     */
    get profileNames() {
        const profileIds = this.selectedTemplate?.profileId?.split(',') || [];
        // Filter out empty strings that might come from split
        return profileIds.filter(id => id.trim().length > 0).map(id => {
            // Find the profile in the profiles array to get the name
            const profile = this.profiles.find(p => p.id === id);
            return profile ? profile.name : id;
        });
    }
    
    /**
     * @description Get permission set names for display
     */
    get permSetNames() {
        const permSetIds = this.selectedTemplate?.permissionSetIds?.split(',') || [];
        // Filter out empty strings that might come from split
        return permSetIds.filter(id => id.trim().length > 0).map(id => {
            // Find the permission set in the permissionSets array to get the name
            const permSet = this.permissionSets.find(p => p.id === id);
            return permSet ? permSet.name : id;
        });
    }
    
    /**
     * @description Get profile count
     */
    get profileCount() {
        return this.profileNames.length;
    }
    
    /**
     * @description Get permission set count
     */
    get permSetCount() {
        return this.permSetNames.length;
    }
    
    /**
     * @description Get system permission count
     */
    get systemPermCount() {
        return this.systemPermNames.length;
    }
    
    /**
     * @description Get system permission names for display
     */
    get systemPermNames() {
        // Use selectedSystemPermissions if available, otherwise fall back to selectedTemplate data
        const systemPerms = this.selectedSystemPermissions && this.selectedSystemPermissions.length > 0 
            ? this.selectedSystemPermissions 
            : (this.selectedTemplate?.systemPermissionNames?.split(',').map(name => name.trim()).filter(name => name) || []);
        
        return systemPerms;
    }

    /**
     * @description Get user names for display
     */
    get userNames() {
        // Use selectedUserIds if available, otherwise fall back to selectedTemplate data
        const userIds = this.selectedUserIds && this.selectedUserIds.length > 0 
            ? this.selectedUserIds 
            : (this.selectedTemplate?.userIds?.split(',').map(id => id.trim()).filter(id => id) || []);
        
        // Map user IDs to names
        return userIds.map(id => {
            // Find the user in the users array to get the name
            const user = this.users.find(u => u.id === id);
            return user ? user.name : id;
        });
    }

    /**
     * @description Get user count
     */
    get userCount() {
        return this.userNames.length;
    }

    /**
     * @description Get user field names for display
     */
    get userFieldNames() {
        // Use selectedUserFields if available, otherwise fall back to selectedTemplate data
        const fieldIds = this.selectedUserFields && this.selectedUserFields.length > 0 
            ? this.selectedUserFields 
            : (this.selectedTemplate?.userFieldIds?.split(',').map(id => id.trim()).filter(id => id) || []);
        
        // Map field IDs to labels
        return fieldIds.map(id => {
            // Find the field in the userFields array to get the label
            const field = this.userFields.find(f => f.id === id);
            return field ? field.label : id;
        });
    }

    /**
     * @description Get user field count
     */
    get userFieldCount() {
        return this.userFieldNames.length;
    }

    /**
     * @description Get permission set group names
     */
    get permSetGroupNames() {
        // Get the permission set group IDs from either current selection or selected template
        const groupIds = this.selectedTemplate 
            ? (this.selectedTemplate.permissionSetGroupIds?.split(',').map(id => id.trim()).filter(id => id) || [])
            : (this.selectedPermSetGroupIds || []);
        
        // Map group IDs to names
        return groupIds.map(id => {
            const group = this.permissionSetGroups.find(g => g.id === id);
            return group ? group.name : id;
        });
    }

    /**
     * @description Get permission set group count
     */
    get permSetGroupCount() {
        return this.permSetGroupNames.length;
    }
    
    handleGenerateTemplate() {
        // console.log('=== BEGIN handleGenerateTemplate ===');
        this.isLoading = true;
        
        // Get template name from input field
        const templateNameInput = this.template.querySelector('[data-id="templateName"]');
        const templateName = templateNameInput ? templateNameInput.value : '';
        
        // Validate template name
        if (!templateName) {
            // console.error('Template name is required');
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter a template name.',
                    variant: 'error'
                })
            );
            this.isLoading = false;
            // // console.log('=== END handleGenerateTemplate ===');- Missing template name ===');
            return;
        }
        
        // Validate that at least one type of permission is selected
        if ((!this.selectedProfileIds || this.selectedProfileIds.length === 0) && 
            (!this.selectedPermSetIds || this.selectedPermSetIds.length === 0) &&
            (!this.selectedPermSetGroupIds || this.selectedPermSetGroupIds.length === 0) &&
            (!this.selectedSystemPermissions || this.selectedSystemPermissions.length === 0)) {
            // console.error('No permissions selected');
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select at least one profile, permission set, permission set group, or system permission.',
                    variant: 'error'
                })
            );
            this.isLoading = false;
            // console.log('=== END handleGenerateTemplate - No permissions selected ===');
            return;
        }
        
        try {
            // Convert Proxy arrays to regular arrays and ensure they are properly initialized
            const profileIds = this.selectedProfileIds ? [...this.selectedProfileIds] : [];
            const permSetIds = this.selectedPermSetIds ? [...this.selectedPermSetIds] : [];
            const permSetGroupIds = this.selectedPermSetGroupIds ? [...this.selectedPermSetGroupIds] : [];
            const systemPermissions = this.selectedSystemPermissions ? [...this.selectedSystemPermissions] : [];
            const userIds = this.selectedUserIds ? [...this.selectedUserIds] : [];
            const userFields = this.selectedUserFields ? [...this.selectedUserFields] : [];
            
            // Debug selected values
            // console.log('Template Name:', templateName);
            // console.log('Selected Profile IDs:', JSON.stringify(profileIds));
            // console.log('Selected Permission Set IDs:', JSON.stringify(permSetIds));
            // console.log('Selected Permission Set Group IDs:', JSON.stringify(permSetGroupIds));
            // console.log('Selected System Permissions:', JSON.stringify(systemPermissions));
            // console.log('Selected User IDs:', JSON.stringify(userIds));
            // console.log('Selected User Fields:', JSON.stringify(userFields));
            
            // First check if the custom object exists
            checkPermissionsTemplateExists()
                .then(exists => {
                    if (!exists) {
                        // console.error('PermissionsTemplate__c custom object does not exist');
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Custom Object Missing',
                                message: 'The PermissionsTemplate__c custom object does not exist in this org. Please deploy the metadata first.',
                                variant: 'error'
                            })
                        );
                        this.isLoading = false;
                        // console.log('=== END handleGenerateTemplate - Missing custom object ===');
                        return;
                    }
                    
                    // If the object exists, proceed with saving
                    // console.log('Calling saveTemplate with parameters:');
                    // console.log('- templateName:', templateName);
                    // console.log('- profileIds:', JSON.stringify(profileIds));
                    // console.log('- permSetIds:', JSON.stringify(permSetIds));
                    // console.log('- systemPermissions:', JSON.stringify(systemPermissions));
                    // console.log('- userIds:', JSON.stringify(userIds));
                    // console.log('- userFields:', JSON.stringify(userFields));
                    
                    // Convert arrays to JSON strings to avoid serialization issues
                    const profileIdsStr = JSON.stringify(profileIds);
                    const permSetIdsStr = JSON.stringify(permSetIds);
                    const permSetGroupIdsStr = JSON.stringify(permSetGroupIds);
                    const systemPermissionsStr = JSON.stringify(systemPermissions);
                    const userIdsStr = JSON.stringify(userIds);
                    const userFieldsStr = JSON.stringify(userFields);
                    
                    // console.log('Stringified parameters:');
                    // console.log('- profileIdsStr:', profileIdsStr);
                    // console.log('- permSetIdsStr:', permSetIdsStr);
                    // console.log('- systemPermissionsStr:', systemPermissionsStr);
                    // console.log('- userIdsStr:', userIdsStr);
                    // console.log('- userFieldsStr:', userFieldsStr);
                    
                    // Call the Apex method with stringified arrays
                    saveTemplate({
                        templateName: templateName,
                        selectedProfileIds: profileIdsStr,
                        selectedPermSetIds: permSetIdsStr,
                        selectedPermSetGroupIds: permSetGroupIdsStr,
                        selectedSystemPermissions: systemPermissionsStr,
                        selectedUserIds: userIdsStr,
                        selectedUserFields: userFieldsStr,
                        licenseType: '' // Let Apex determine license type
                    })
            .then(() => {
                        // console.log('Template saved successfully');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Template Saved',
                                message: `Template "${templateName}" has been saved successfully.`,
                        variant: 'success'
                    })
                );
                        
                        // Template saved successfully
                        
                        // Refresh the templates list after successful save with a small delay
                        // console.log('🔄 Starting template refresh process...');
                            // console.log('📊 Current templates count before refresh:', this.templates.length);
                            // console.log('📋 Current templates before refresh:', JSON.stringify(this.templates.map(t => ({id: t.id, name: t.name}))));
                        
                        Promise.resolve().then(() => {
                            // console.log('⏰ Template refresh timeout triggered after 500ms');
                            return this.loadTemplates()
                                .then(() => {
                                    // console.log('✅ Template refresh completed successfully');
                                    // console.log('📊 New templates count after refresh:', this.templates.length);
                                    // console.log('📋 New templates after refresh:', JSON.stringify(this.templates.map(t => ({id: t.id, name: t.name}))));
                                    
                                    // Force reactive update by creating a new array
                                    this.templates = [...this.templates];
                                    // console.log('🔄 Forced reactive update by creating new array reference');
                                    
                                                                         // Try to find the newly created template
                                     const newTemplate = this.templates.find(t => t.name === templateName);
                                     if (newTemplate) {
                                         // console.log('🎯 Found newly created template:', JSON.stringify(newTemplate));
                                         
                                         // Set the template ID to trigger combobox update
                                         this.selectedTemplateId = newTemplate.id;
                                         this.selectedTemplate = newTemplate;
                                         this.isExportButtonDisabled = false;
                                         // console.log('🎯 Set selectedTemplateId to:', this.selectedTemplateId);
                                         
                                         // Force reactive update
                                         Promise.resolve().then(() => {
                                             // console.log('🔄 Forcing combobox refresh...');
                                             const combobox = this.template.querySelector('lightning-combobox');
                                             if (combobox) {
                                                 // console.log('🎛️ Found combobox element, current value:', combobox.value);
                    // console.log('🎛️ Setting combobox value to:', newTemplate.id);
                    combobox.value = newTemplate.id;
                    // console.log('🎛️ Combobox value after setting:', combobox.value);
                                             } else {
                                                 // console.warn('⚠️ Combobox element not found in DOM');
                                             }
                                         });
                                     } else {
                                         // console.warn('⚠️ Could not find newly created template with name:', templateName);
                    // console.log('📋 Available template names:', this.templates.map(t => t.name));
                                     }
                                })
                                .catch(() => {
                                    // // console.error('❌ Template refresh failed');
                                });
                        });
                        
                        // Expand the export section to make it visible
                        this.isExportSectionExpanded = true;
                        
                        // Clear template name input
                        if (templateNameInput) {
                            templateNameInput.value = '';
                        }
                        
                        // console.log('=== END handleGenerateTemplate - Success ===');
            })
            .catch(error => {
                        // Enhanced error logging
                        // console.error('Error saving template:', error);
                        
                        if (error.body && typeof error.body === 'object') {
                            // console.error('Error body details:', JSON.stringify(error.body));
                        }
                        
                        if (error.message) {
                            // console.error('Error message:', error.message);
                        }
                        
                        if (error.stack) {
                            // console.error('Error stack:', error.stack);
                        }
                        
                        // More informative error message to the user
                        let errorMessage = 'An error occurred while saving the template.';
                        if (error.body && error.body.message) {
                            errorMessage = error.body.message;
                        } else if (error.message) {
                            errorMessage = error.message;
                        }
                        
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Saving Template',
                                message: errorMessage,
                        variant: 'error'
                    })
                );
                        // console.log('=== END handleGenerateTemplate - Error ===');
                    });
                })
                .catch(objError => {
                    // console.error('Error checking if PermissionsTemplate__c exists:', objError);
                    
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error Checking Custom Object',
                            message: 'Could not verify if the required custom object exists: ' + (objError.message || objError.body?.message || 'Unknown error'),
                            variant: 'error'
                        })
                    );
                    // console.log('=== END handleGenerateTemplate - Error checking object ===');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } catch (error) {
            // console.error('Exception in handleGenerateTemplate:', error);
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Processing Template',
                    message: 'An unexpected error occurred: ' + (error.message || 'Unknown error'),
                    variant: 'error'
                })
            );
            this.isLoading = false;
            // console.log('=== END handleGenerateTemplate - Exception ===');
        }
    }

    handleTemplateChange(event) {
        // console.log('🎯 === BEGIN handleTemplateChange ===');
        const selectedTemplateId = event.detail.value;
        // console.log('🎯 Selected Template ID:', selectedTemplateId);
        // console.log('🎯 Available templates:', JSON.stringify(this.templates.map(t => ({id: t.id, name: t.name}))));
        
        if (!selectedTemplateId) {
            // console.log('🎯 No template selected');
            this.selectedTemplate = null;
            this.selectedTemplateId = null;
            this.isExportButtonDisabled = true;
            // console.log('🎯 === END handleTemplateChange - No selection ===');
            return;
        }
        
        // Find the selected template
        const template = this.templates.find(t => t.id === selectedTemplateId);
        // console.log('🎯 Selected Template:', JSON.stringify(template));
        
        if (!template) {
            // console.error('🎯 Template not found');
            this.selectedTemplate = null;
            this.selectedTemplateId = null;
            this.isExportButtonDisabled = true;
            // console.log('🎯 === END handleTemplateChange - Template not found ===');
            return;
        }
        
        // Store the selected template for export
        this.selectedTemplate = template;
        this.selectedTemplateId = selectedTemplateId;
        this.isExportButtonDisabled = false;
        // console.log('🎯 Template successfully selected and stored');
        
        try {
            // Set template name
            const templateNameInput = this.template.querySelector('[data-id="templateName"]');
            if (templateNameInput) {
                templateNameInput.value = template.name;
            }
            
            // Set selected profile IDs
            this.selectedProfileIds = template.profileId ? template.profileId.split(',').map(id => id.trim()).filter(id => id) : [];
            // console.log('Set Profile IDs:', JSON.stringify(this.selectedProfileIds));
            
            // Set selected permission set IDs
            if (template.permissionSetIds) {
                this.selectedPermSetIds = template.permissionSetIds.split(',').map(id => id.trim()).filter(id => id);
            } else {
                this.selectedPermSetIds = [];
            }
            // console.log('Set Permission Set IDs:', JSON.stringify(this.selectedPermSetIds));
            
            // Set selected permission set group IDs
            if (template.permissionSetGroupIds) {
                this.selectedPermSetGroupIds = template.permissionSetGroupIds.split(',').map(id => id.trim()).filter(id => id);
            } else {
                this.selectedPermSetGroupIds = [];
            }
            // console.log('Set Permission Set Group IDs:', JSON.stringify(this.selectedPermSetGroupIds));
            
            // Set selected system permissions
            if (template.systemPermissionNames) {
                this.selectedSystemPermissions = template.systemPermissionNames.split(',').map(name => name.trim()).filter(name => name);
            } else {
                this.selectedSystemPermissions = [];
            }
            // console.log('Set System Permissions:', JSON.stringify(this.selectedSystemPermissions));
            
            // Set selected user IDs
            if (template.userIds) {
                this.selectedUserIds = template.userIds.split(',').map(id => id.trim()).filter(id => id);
            } else {
                this.selectedUserIds = [];
            }
            // console.log('Set User IDs:', JSON.stringify(this.selectedUserIds));
            
            // Set selected user field IDs
            if (template.userFieldIds) {
                this.selectedUserFields = template.userFieldIds.split(',').map(id => id.trim()).filter(id => id);
            } else {
                this.selectedUserFields = [];
            }
            // console.log('Set User Field IDs:', JSON.stringify(this.selectedUserFields));
            
            // Ensure user data is loaded for proper display
            if ((this.selectedUserIds.length > 0 || this.selectedUserFields.length > 0) && 
                (this.users.length === 0 || this.userFields.length === 0)) {
                // console.log('Loading user data for template display...');
                Promise.all([
                    this.users.length === 0 ? this.getUsers() : Promise.resolve(),
                    this.userFields.length === 0 ? this.getUserFields() : Promise.resolve()
                ]).catch(() => {
                    // console.error('Error loading user data for template display:', error);
                });
            }
            
            // Show success toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Template Loaded',
                    message: `Template "${template.name}" has been loaded successfully.`,
                    variant: 'success'
                })
            );
            // console.log('=== END handleTemplateChange - Success ===');
        } catch (error) {
            // console.error('Error loading template:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Loading Template',
                    message: 'An error occurred while loading the template: ' + (error.message || 'Unknown error'),
                    variant: 'error'
                })
            );
            // console.log('=== END handleTemplateChange - Error ===');
        }
    }

    /**
     * @description Check if template contains only permission sets (no profiles, users, or user fields)
     * @returns {Boolean} True if template has only permission sets, false otherwise
     */
    isTemplatePermissionSetsOnly() {
        if (!this.selectedTemplate) {
            return false;
        }
        
        // Check if template has profiles
        const hasProfiles = this.selectedTemplate.profileIds && 
                           this.selectedTemplate.profileIds.trim().length > 0;
        
        // Check if template has users
        const hasUsers = this.selectedTemplate.userIds && 
                        this.selectedTemplate.userIds.trim().length > 0;
        
        // Check if template has user fields
        const hasUserFields = this.selectedTemplate.userFieldIds && 
                             this.selectedTemplate.userFieldIds.trim().length > 0;
        
        // Check if template has permission sets
        const hasPermissionSets = this.selectedTemplate.permissionSetIds && 
                                 this.selectedTemplate.permissionSetIds.trim().length > 0;
        
        // Template should have only permission sets and no other types
        const onlyPermissionSets = hasPermissionSets && !hasProfiles && !hasUsers && !hasUserFields;
        
        console.log('📋 Template composition check:', {
            hasProfiles,
            hasUsers,
            hasUserFields,
            hasPermissionSets,
            onlyPermissionSets
        });
        
        return onlyPermissionSets;
    }
    
    /**
     * @description Export the selected template to Excel
     */
    async handleExportTemplate() {
        // console.log('=== BEGIN handleExportTemplate ===');
        
        if (!this.selectedTemplate) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No Template Selected',
                    message: 'Please select a template to export.',
                    variant: 'warning'
                })
            );
            // console.log('=== END handleExportTemplate - No template selected ===');
            return;
        }
        
        if (!this.isXLSXInitialized) {
            this.initializeXLSX();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Export Library Loading',
                    message: 'The export library is loading. Please try again in a moment.',
                    variant: 'info'
                })
            );
            // console.log('=== END handleExportTemplate - XLSX not initialized ===');
            return;
        }
        
        try {
            // Check if template contains only permission sets for split logic eligibility
            const templateHasOnlyPermissionSets = this.isTemplatePermissionSetsOnly();
            
            if (templateHasOnlyPermissionSets) {
                // Only apply split logic for permission sets templates
                console.log('🔍 Template contains only permission sets. Checking if splitting is required...');
                
                const splittingResult = await exportTemplateWithSplitting({ templateId: this.selectedTemplate.id, maxRowsPerFile: 50000 });
                
                if (!splittingResult.success) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Export Error',
                            message: splittingResult.message,
                            variant: 'error'
                        })
                    );
                    return;
                }
                
                if (splittingResult.splitRequired) {
                    // Large permission sets dataset detected - use split export
                    console.log('📊 Large permission sets dataset detected. Splitting into multiple files to prevent browser freezing.');
                    console.log('📈 Estimated rows:', splittingResult.totalRows);
                    console.log('📁 Files to generate:', splittingResult.filesGenerated.length);
                    
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Large Dataset: Excel Export Will Be Split Into partial Files',
                            message: `Processing Excel`,
                            variant: 'info'
                        })
                    );
                    
                    // Process split exports for permission sets
                    await this.processSplitExport(splittingResult.filesGenerated);
                    return;
                }
            } else {
                // Template contains profiles, users, or user fields - use old export functionality
                console.log('📊 Template contains profiles, users, or user fields. Using traditional export functionality.');
                
            }
            
            // Use regular export for small permission sets datasets or non-permission sets templates
            console.log('📊 Using regular export functionality.');
            await this.processRegularExport();
            
        } catch (error) {
            console.error('❌ Error in handleExportTemplate:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Export Error',
                    message: 'An error occurred during export: ' + (error.body?.message || error.message),
                    variant: 'error'
                })
            );
        }
    }
    
    /**
     * @description Process split export for large datasets
     * @param {Array} filesGenerated Array of file information from server
     */
    async processSplitExport(filesGenerated) {
        try {
            this.showBulkExportModal = true;
            this.isBulkExporting = true;
            this.bulkExportProgress = 0;
            this.bulkExportStatus = 'Preparing split export...';
            
            // First, run a bulk export to get all the permission set data
            this.bulkExportStatus = 'Fetching permission set data for split export...';
            this.bulkExportProgress = 10;
            this.updateProgressBar(10);
            
            // Get all system permissions from the template
            const allSystemPermissions = this.selectedTemplate.systemPermissionNames ? 
                this.selectedTemplate.systemPermissionNames.split(',').map(name => name.trim()).filter(name => name) : [];
            
            // Run bulk export to get real data
            await this.runBulkExportForSplitData(allSystemPermissions);
            
            this.bulkExportStatus = 'Processing split files with real data...';
            this.bulkExportProgress = 30;
            this.updateProgressBar(30);
            
            // Process files sequentially using recursive approach to avoid await in loop
            const processFileRecursively = async (fileIndex) => {
                if (fileIndex >= filesGenerated.length) {
                    return; // Base case: all files processed
                }
                
                const fileInfo = filesGenerated[fileIndex];
                const currentFileNumber = fileIndex + 1;
                
                this.bulkExportStatus = `Processing file ${currentFileNumber} of ${filesGenerated.length}...`;
                this.bulkExportProgress = Math.round(30 + (fileIndex / filesGenerated.length * 60)); // 30-90% for processing
                this.updateProgressBar(this.bulkExportProgress);
                
                // Get template data for this split
                const splitDataResult = await getTemplateDataForSplit({
                    templateId: this.selectedTemplate.id,
                    permSetIds: fileInfo.permissionSetIds,
                    systemPermissions: fileInfo.systemPermissions,
                    fileNumber: fileInfo.fileNumber
                });
                
                if (!splitDataResult.success) {
                    throw new Error(`Failed to get data for file ${currentFileNumber}: ${splitDataResult.message}`);
                }
                
                // Create a temporary template object for this split
                const splitTemplate = splitDataResult.templateData;
                
                this.bulkExportStatus = `Generating Excel file ${currentFileNumber}...`;
                this.bulkExportProgress = Math.round(30 + ((fileIndex + 0.5) / filesGenerated.length * 60));
                this.updateProgressBar(this.bulkExportProgress);
                
                // Process this split using existing export logic with real data
                await this.processSingleSplitFile(splitTemplate, splitDataResult.fileName);
                
                // Recursively process the next file
                await processFileRecursively(fileIndex + 1);
            };
            
            await processFileRecursively(0);
            
            this.bulkExportProgress = 100;
            this.updateProgressBar(100);
            this.bulkExportStatus = 'All files generated successfully!';
            
            // Hide modal after completion
            this.showBulkExportModal = false;
            this.isBulkExporting = false;
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Split Export Complete',
                    message: `Successfully generated ${filesGenerated.length} Excel files with complete permission set data.`,
                    variant: 'success'
                })
            );
            
        } catch (error) {
            console.error('❌ Error in processSplitExport:', error);
            this.showBulkExportModal = false;
            this.isBulkExporting = false;
            throw error;
        }
    }
    
    /**
     * @description Run bulk export to get real permission set data for split processing
     * @param {Array} systemPermissions Array of system permissions to analyze
     */
    async runBulkExportForSplitData(systemPermissions) {
        try {
            console.log('🔄 Running bulk export to get real permission set data for split');
            
            // Initialize export state for data collection
            this.bulkExportResults = [];
            
            // Process system permissions using recursive batch processing
            const batchSize = 10; // Smaller batch size for data collection
            
            const processBatchRecursively = async (startIndex) => {
                if (startIndex >= systemPermissions.length) {
                    return; // Base case: all batches processed
                }
                
                const endIndex = Math.min(startIndex + batchSize, systemPermissions.length);
                const batch = systemPermissions.slice(startIndex, endIndex);
                
                // Update progress
                const progress = Math.round(10 + ((startIndex / systemPermissions.length) * 20)); // 10-30% range
                this.bulkExportStatus = `Analyzing permissions ${startIndex + 1}-${endIndex} of ${systemPermissions.length}...`;
                this.bulkExportProgress = progress;
                this.updateProgressBar(progress);
                
                // Process each permission in the batch using Promise.all for parallel processing
                const batchPromises = batch.map(async (permission) => {
                    try {
                        const permissionObj = { name: permission, label: permission };
                        const result = await this.processPermissionWithUltraOptimizedFallback(permission);
                        
                        return {
                            permission: permissionObj,
                            result: result
                        };
                    } catch (permError) {
                        console.warn('⚠️ Error processing permission for split data:', permission, permError);
                        // Return fallback result
                        return {
                            permission: { name: permission, label: permission },
                            result: {
                                systemPermissionName: permission,
                                profilesWithAccess: [],
                                permissionSetsWithAccess: [],
                                permissionSetGroupsWithAccess: [],
                                usersWithAccess: [],
                                totalUsers: 0,
                                error: 'Analysis failed',
                                isFallback: true
                            }
                        };
                    }
                });
                
                // Wait for all permissions in the batch to complete
                const batchResults = await Promise.all(batchPromises);
                this.bulkExportResults.push(...batchResults);
                
                // Process next batch recursively
                await processBatchRecursively(startIndex + batchSize);
            };
            
            await processBatchRecursively(0);
            
            console.log('✅ Bulk export data collection completed. Results:', this.bulkExportResults.length);
            
        } catch (error) {
            console.error('❌ Error in runBulkExportForSplitData:', error);
            throw error;
        }
    }
    
    /**
     * @description Process a single split file
     * @param {Object} splitTemplate Template data for this split
     * @param {String} fileName File name for this split
     */
    processSingleSplitFile(splitTemplate, fileName) {
        return new Promise((resolve, reject) => {
            try {
                // Gather template data for this split
                const template = splitTemplate;
                const profileIds = template.profileId ? template.profileId.split(',').map(id => id.trim()).filter(id => id) : [];
                const permSetIds = template.permissionSetIds ? template.permissionSetIds.split(',').map(id => id.trim()).filter(id => id) : [];
                const permSetGroupIds = template.permissionSetGroupIds ? template.permissionSetGroupIds.split(',').map(id => id.trim()).filter(id => id) : [];
                const systemPermissions = template.systemPermissionNames ? template.systemPermissionNames.split(',').map(name => name.trim()).filter(name => name) : [];
                const userIds = template.userIds ? template.userIds.split(',').map(id => id.trim()).filter(id => id) : [];
                const userFieldIds = template.userFieldIds ? template.userFieldIds.split(',').map(id => id.trim()).filter(id => id) : [];
                
                // Process bulk export for this split using existing logic
                this.processBulkExportForSplit(template, profileIds, permSetIds, permSetGroupIds, systemPermissions, userIds, userFieldIds, fileName)
                    .then(() => resolve())
                    .catch(error => reject(error));
                
            } catch (error) {
                console.error('❌ Error in processSingleSplitFile:', error);
                reject(error);
            }
        });
    }
    
    /**
     * @description Process bulk export for a split portion of the template
     * @param {Object} template Template object
     * @param {Array} profileIds Profile IDs for this split
     * @param {Array} permSetIds Permission set IDs for this split
     * @param {Array} permSetGroupIds Permission set group IDs for this split
     * @param {Array} systemPermissions System permissions for this split
     * @param {Array} userIds User IDs for this split
     * @param {Array} userFieldIds User field IDs for this split
     * @param {String} fileName File name for this split
     */
    async processBulkExportForSplit(template, profileIds, permSetIds, permSetGroupIds, systemPermissions, userIds, userFieldIds, fileName) {
        try {
            // Initialize arrays for actual data
            const selectedProfiles = [];
            const selectedPermSets = [];
            const selectedPermSetGroups = [];
            const validSystemPerms = systemPermissions.map(name => ({ name, label: name }));
            const selectedUsers = [];
            const selectedUserFields = [];
            
            // Fetch actual permission sets data with assignments for this split
            if (permSetIds.length > 0) {
                console.log('🔄 Fetching permission sets data for split:', permSetIds.length, 'permission sets');
                
                try {
                    // Use the existing bulk export logic to get permission sets with assignments
                    const permSetResults = await this.fetchPermissionSetsForSplit(permSetIds, systemPermissions);
                    selectedPermSets.push(...permSetResults);
                    console.log('✅ Successfully fetched', selectedPermSets.length, 'permission sets with assignments');
                } catch (fetchError) {
                    console.error('❌ Error fetching permission sets for split:', fetchError);
                    // Create fallback data to prevent complete failure
                    permSetIds.forEach(id => {
                        selectedPermSets.push({
                            id: id,
                            name: `PermSet_${id}`,
                            label: `Permission Set ${id} (Data Unavailable)`,
                            assignments: [],
                            error: 'Failed to fetch data'
                        });
                    });
                }
            }
            
            // Process the split export using the same logic as regular template export
            await this.processSplitExportWithRealData(template, selectedProfiles, selectedPermSets, selectedPermSetGroups, validSystemPerms, selectedUsers, selectedUserFields, fileName);
            
        } catch (error) {
            console.error('❌ Error in processBulkExportForSplit:', error);
            throw error;
        }
    }
    
    /**
     * @description Fetch actual permission sets data for split export
     * @param {Array} permSetIds Permission set IDs to fetch
     * @param {Array} systemPermissions System permissions to analyze
     * @returns {Array} Array of permission sets with assignments and system permission data
     */
    async fetchPermissionSetsForSplit(permSetIds, systemPermissions) {
        try {
            console.log('📊 Fetching permission sets data for split with assignments');
            
            // Create a map to collect permission sets with all their data
            const permSetsMap = new Map();
            
            // First, collect permission sets from bulk export results if available
            if (this.bulkExportResults && this.bulkExportResults.length > 0) {
                console.log('📊 Using existing bulk export results for split');
                
                this.bulkExportResults.forEach(item => {
                    if (item.result && item.result.permissionSetsWithAccess) {
                        item.result.permissionSetsWithAccess.forEach(permSet => {
                            if (permSetIds.includes(permSet.id)) {
                                // Get existing or create new permission set entry
                                let existingPermSet = permSetsMap.get(permSet.id);
                                if (!existingPermSet) {
                                    existingPermSet = {
                                        ...permSet,
                                        systemPermissions: new Map(),
                                        assignments: permSet.assignments || [],
                                        // Ensure all required fields are present
                                        id: permSet.id,
                                        name: permSet.name || permSet.label,
                                        label: permSet.label || permSet.name,
                                        isCustom: permSet.isCustom || false,
                                        createdById: permSet.createdById || '',
                                        createdByName: permSet.createdByName || '',
                                        createdDate: permSet.createdDate || '',
                                        description: permSet.description || ''
                                    };
                                    permSetsMap.set(permSet.id, existingPermSet);
                                }
                                
                                // Mark which system permissions this permission set has
                                if (item.permission && systemPermissions.includes(item.permission.name)) {
                                    existingPermSet.systemPermissions.set(item.permission.label || item.permission.name, true);
                                }
                            }
                        });
                    }
                });
            }
            
            // For permission sets not found in bulk results, fetch them directly
            const missingPermSetIds = permSetIds.filter(id => !permSetsMap.has(id));
            
            if (missingPermSetIds.length > 0) {
                console.log('🔄 Fetching missing permission sets with assignments:', missingPermSetIds.length);
                
                try {
                    // Fetch permission sets with assignments using the same method as regular export
                    const permSetsWithAssignments = await this.fetchPermissionSetsWithAssignments(missingPermSetIds);
                    
                    permSetsWithAssignments.forEach(permSet => {
                        if (!permSetsMap.has(permSet.id)) {
                            const permSetWithSystemPerms = {
                                ...permSet,
                                systemPermissions: new Map()
                            };
                            
                            // Initialize system permissions mapping
                            systemPermissions.forEach(permName => {
                                permSetWithSystemPerms.systemPermissions.set(permName, false);
                            });
                            
                            permSetsMap.set(permSet.id, permSetWithSystemPerms);
                        }
                    });
                } catch (fetchError) {
                    console.warn('⚠️ Error fetching permission sets with assignments:', fetchError);
                    
                    // Create fallback data for missing permission sets
                    missingPermSetIds.forEach(permSetId => {
                        if (!permSetsMap.has(permSetId)) {
                            const fallbackPermSet = {
                                id: permSetId,
                                name: `PermissionSet_${permSetId}`,
                                label: `Permission Set ${permSetId} (Data Unavailable)`,
                                assignments: [],
                                systemPermissions: new Map(),
                                isCustom: false,
                                createdById: '',
                                createdByName: '',
                                createdDate: '',
                                description: 'Data could not be fetched'
                            };
                            
                            // Initialize system permissions mapping
                            systemPermissions.forEach(permName => {
                                fallbackPermSet.systemPermissions.set(permName, false);
                            });
                            
                            permSetsMap.set(permSetId, fallbackPermSet);
                        }
                    });
                }
            }
            
            const result = Array.from(permSetsMap.values());
            console.log('✅ Fetched permission sets for split:', result.length, 'permission sets with assignments');
            
            return result;
            
        } catch (error) {
            console.error('❌ Error in fetchPermissionSetsForSplit:', error);
            throw error;
        }
    }
    
    /**
     * @description Fetch permission sets with their assignments from the server
     * @param {Array} permSetIds Permission set IDs to fetch
     * @returns {Array} Array of permission sets with assignments
     */
    async fetchPermissionSetsWithAssignments(permSetIds) {
        try {
            console.log('🔄 Fetching permission sets with assignments from server');
            
            // Use the existing getPermissionSets method if available, or create a simplified version
            if (this.permissionSets && this.permissionSets.length > 0) {
                // Filter existing permission sets
                const filteredPermSets = this.permissionSets.filter(ps => permSetIds.includes(ps.id));
                if (filteredPermSets.length > 0) {
                    console.log('📊 Using cached permission sets data');
                    return filteredPermSets;
                }
            }
            
            // Fetch permission sets with assignments from the server
            const permSetIdsString = permSetIds.join(',');
            console.log('📡 Calling Apex to fetch permission sets with assignments:', permSetIdsString);
            
            const result = await getPermissionSetsWithAssignments({ permSetIds: permSetIdsString });
            
            if (result.success && result.permissionSets) {
                console.log('✅ Successfully fetched', result.permissionSets.length, 'permission sets with assignments');
                return result.permissionSets;
            }
            
            console.warn('⚠️ Failed to fetch permission sets:', result.message);
            
            // Create fallback data
            const fallbackData = permSetIds.map(permSetId => ({
                id: permSetId,
                name: `PermissionSet_${permSetId}`,
                label: `Permission Set ${permSetId} (Data Unavailable)`,
                assignments: [],
                isCustom: false,
                createdById: '',
                createdByName: '',
                createdDate: '',
                description: 'Could not fetch from server: ' + result.message
            }));
            
            return fallbackData;
            
        } catch (error) {
            console.error('❌ Error fetching permission sets with assignments:', error);
            
            // Create fallback data on error
            const fallbackData = permSetIds.map(permSetId => ({
                id: permSetId,
                name: `PermissionSet_${permSetId}`,
                label: `Permission Set ${permSetId} (Error)`,
                assignments: [],
                isCustom: false,
                createdById: '',
                createdByName: '',
                createdDate: '',
                description: 'Error fetching data: ' + error.message
            }));
            
            return fallbackData;
        }
    }
    
    /**
     * @description Process split export with real data using the same format as original export
     * @param {Object} template Template object
     * @param {Array} selectedProfiles Selected profiles
     * @param {Array} selectedPermSets Selected permission sets with real data
     * @param {Array} selectedPermSetGroups Selected permission set groups
     * @param {Array} validSystemPerms Valid system permissions
     * @param {Array} selectedUsers Selected users
     * @param {Array} selectedUserFields Selected user fields
     * @param {String} fileName File name for export
     */
    async processSplitExportWithRealData(template, selectedProfiles, selectedPermSets, selectedPermSetGroups, validSystemPerms, selectedUsers, selectedUserFields, fileName) {
        try {
            console.log('📊 Processing split export with real data format');
            
            // Create workbook using the same method as regular template export
            const workbook = window.XLSX.utils.book_new();
            workbook.Props = {
                Title: `Template Export - ${template.name}`,
                Subject: "Salesforce Permission Template Split",
                Author: "Permissions Manager",
                CreatedDate: new Date()
            };
            
            // Generate Summary sheet
            const summaryData = this.generateTemplateSummarySheet(template, selectedProfiles, selectedPermSets, validSystemPerms, selectedUsers, selectedUserFields, selectedPermSetGroups);
            if (summaryData && summaryData.length > 0) {
                const summarySheet = window.XLSX.utils.aoa_to_sheet(summaryData);
                window.XLSX.utils.book_append_sheet(workbook, summarySheet, 'Summary');
            }
            
            // Generate Permission Sets sheet with real data
            if (selectedPermSets && selectedPermSets.length > 0) {
                console.log('📋 Generating Permission Sets sheet with', selectedPermSets.length, 'permission sets');
                const permSetsData = this.generateTemplatePermSetsSheet(selectedPermSets, validSystemPerms, this.bulkExportResults || []);
                if (permSetsData && permSetsData.length > 0) {
                    const permSetsSheet = window.XLSX.utils.aoa_to_sheet(permSetsData);
                    
                    // Set column widths for better readability
                    if (permSetsData[0] && permSetsData[0].length > 0) {
                        const colWidths = [];
                        for (let i = 0; i < Math.min(permSetsData[0].length, 30); i++) {
                            colWidths.push({ wch: 15 });
                        }
                        permSetsSheet['!cols'] = colWidths;
                    }
                    
                    // Add freeze panes
                    permSetsSheet['!freeze'] = { xSplit: 0, ySplit: 1 };
                    
                    window.XLSX.utils.book_append_sheet(workbook, permSetsSheet, 'Permission Sets');
                    console.log('✅ Permission Sets sheet added successfully');
                }
            }
            
            // Generate and download the file
            const wopts = { 
                bookType: 'xlsx', 
                bookSST: false, 
                type: 'binary'
            };
            
            console.log('💾 Downloading split export file:', fileName + '.xlsx');
            window.XLSX.writeFile(workbook, fileName + '.xlsx', wopts);
            
            console.log('✅ Split export completed successfully');
            
        } catch (error) {
            console.error('❌ Error in processSplitExportWithRealData:', error);
            throw error;
        }
    }
    
    /**
     * @description Process regular export for manageable datasets
     */
    async processRegularExport() {
        try {
            // Gather template data
            const template = this.selectedTemplate;
            // Fix: Parse profileId as a comma-separated list instead of treating it as a single ID
            const profileIds = template.profileId ? template.profileId.split(',').map(id => id.trim()).filter(id => id) : [];
            const permSetIds = template.permissionSetIds ? template.permissionSetIds.split(',').map(id => id.trim()).filter(id => id) : [];
            // Ensure permission set group IDs are properly parsed
            const permSetGroupIds = template.permissionSetGroupIds ? template.permissionSetGroupIds.split(',').map(id => id.trim()).filter(id => id) : [];
            const systemPermissions = template.systemPermissionNames ? template.systemPermissionNames.split(',').map(name => name.trim()).filter(name => name) : [];
            const userIds = template.userIds ? template.userIds.split(',').map(id => id.trim()).filter(id => id) : [];
            const userFieldIds = template.userFieldIds ? template.userFieldIds.split(',').map(id => id.trim()).filter(id => id) : [];
            
            // Check if template has at least one component to export
            if (profileIds.length === 0 && permSetIds.length === 0 && permSetGroupIds.length === 0 && systemPermissions.length === 0) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'No Data to Export',
                        message: 'This template does not contain any profiles, permission sets, permission set groups, or system permissions to export.',
                        variant: 'warning'
                    })
                );
                return;
            }
            
            // Show performance improvement notification for template export
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Exporting Template',
                    message: 'Template can take upto 10-15 minutes depending upon size of the data.!',
                    variant: 'info',
                    mode: 'sticky'
                })
            );

            // Initialize export state
            this.initializeExport(systemPermissions.length);
            
            // Fetch all necessary data
            Promise.all([
                // Get profile details
                getProfiles(),
                // Get permission set details
                getPermissionSets(),
                // Get permission set group details
                this.getPermissionSetGroups(),
                // Get system permissions details
                getSystemPermissions(),
                // Get user details if user IDs are specified
                userIds.length > 0 ? getUsers() : Promise.resolve([]),
                // Get user field details if user field IDs are specified
                userFieldIds.length > 0 ? getUserFields() : Promise.resolve([])
            ])
            .then(([allProfiles, allPermSets, allPermSetGroups, allSystemPerms, allUsers, allUserFields]) => {
                // Filter to get only the selected items
                const selectedProfiles = allProfiles.filter(profile => profileIds.includes(profile.id));
                const selectedPermSets = allPermSets.filter(permSet => permSetIds.includes(permSet.id));
                
                // Ensure permission set groups are properly filtered
                const selectedPermSetGroups = allPermSetGroups.filter(permSetGroup => {
                    const isIncluded = permSetGroupIds.includes(permSetGroup.id);
                    // Debug log for permission set group filtering
                    // if (isIncluded) {
                    //     console.log('Including permission set group:', permSetGroup.name || permSetGroup.masterLabel, permSetGroup.id);
                    // }
                    return isIncluded;
                });
                
                // Log selected permission set groups for debugging
                // console.log('Selected Permission Set Groups:', selectedPermSetGroups.length);
                // console.log('Permission Set Group IDs from template:', permSetGroupIds);
                // console.log('All Permission Set Groups:', allPermSetGroups.map(g => g.id));
                
                const selectedUsers = allUsers.filter(user => userIds.includes(user.id));
                const selectedUserFields = allUserFields.filter(field => userFieldIds.includes(field.id));
                
                // Filter and validate system permissions
                const validSystemPerms = [];
                const invalidSystemPerms = [];
                
                systemPermissions.forEach(permName => {
                    // Add null/undefined checks for both permission name and template permission name
                    if (!permName || typeof permName !== 'string') {
                        invalidSystemPerms.push(permName || 'undefined permission');
                        return;
                    }
                    
                    const matchingPerm = allSystemPerms.find(p => {
                        // Ensure both p.name and permName exist and are strings before calling toLowerCase()
                        return p && p.name && typeof p.name === 'string' && 
                               p.name.toLowerCase() === permName.toLowerCase();
                    });
                    
                    if (matchingPerm) {
                        validSystemPerms.push(matchingPerm);
                    } else {
                        invalidSystemPerms.push(permName);
                    }
                });
                
                // Only validate system permissions if they were specified in the template
                if (systemPermissions.length > 0 && validSystemPerms.length === 0) {
                    throw new Error('Could not find any valid system permissions in the org.');
                }
                
                if (invalidSystemPerms.length > 0) {
                    // console.warn('Invalid system permissions found:', invalidSystemPerms);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'info: some permissions invalid',
                            message: `Some system permissions in the template are invalid and will be skipped: ${invalidSystemPerms.join(', ')}`,
                            variant: 'info'
                        })
                    );
                }
                
                        // console.log('Selected Profiles:', JSON.stringify(selectedProfiles.map(p => p.name)));
            // console.log('Selected Permission Sets:', JSON.stringify(selectedPermSets.map(p => p.name)));
            // console.log('Selected Permission Set Groups:', JSON.stringify(selectedPermSetGroups.map(p => p.name)));
            // console.log('Valid System Permissions:', JSON.stringify(validSystemPerms.map(p => p.name)));
            // console.log('Selected Users:', JSON.stringify(selectedUsers.map(u => u.name)));
            // console.log('Selected User Fields:', JSON.stringify(selectedUserFields.map(f => ({ 
            //     id: f.id, 
            //     name: f.name, 
            //     value: f.value, 
            //     label: f.label 
            // }))));
                
                // Process permissions in batches
                this.templateExportData = {
                    template,
                    selectedProfiles,
                    selectedPermSets,
                    selectedPermSetGroups,
                    validSystemPerms,
                    selectedUsers,
                    selectedUserFields
                };
                
                // Start batch processing
                this.processTemplatePermissionsBatch(validSystemPerms, 0);
            })
            .catch(error => {
                // console.error('Error preparing template export:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Export Error',
                        message: 'An error occurred while preparing the template export: ' + (error.message || 'Unknown error'),
                        variant: 'error'
                    })
                );
                this.isBulkExporting = false;
                this.showBulkExportModal = false;
                // console.log('=== END handleExportTemplate - Error ===');
            });
        } catch (error) {
            // console.error('Exception in handleExportTemplate:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Export Error',
                    message: 'An unexpected error occurred: ' + (error.message || 'Unknown error'),
                    variant: 'error'
                })
            );
            this.isBulkExporting = false;
            this.showBulkExportModal = false;
            // console.log('=== END handleExportTemplate - Exception ===');
        }
    }
    
    /**
     * @description Process a batch of template permissions
     * @param {Array} permissions - Array of system permissions to process
     * @param {Number} startIndex - Starting index for this batch
     */
    processTemplatePermissionsBatch(permissions, startIndex) {
        // ULTRA-OPTIMIZED: Increased batch size for faster processing
        const batchSize = 15; // 3x larger batch size for faster processing
        
        // Calculate the start and end indices for this batch
        const endIndex = Math.min(startIndex + batchSize, permissions.length);
        
        // Extract the batch of permissions to process
        const batch = permissions.slice(startIndex, endIndex);
        
        // Update status with enhanced information
        this.bulkExportStatus = `Template Processing: ${startIndex + 1}-${endIndex} of ${permissions.length} (${Math.round((endIndex/permissions.length)*100)}%)`;
        
        // Setup tracking for batch progress
        
        // Initialize batch progress tracking
        this.batchSize = batch.length;
        this.batchProcessed = 0;
        
        // Process each permission in the batch sequentially
        this.processTemplatePermissionSequentially(batch, 0)
            .then(() => {
                // Update progress
                this.bulkExportProcessed = endIndex;
                const newProgress = Math.round((endIndex / permissions.length) * 90); // Use 90% for processing, reserve 10% for Excel generation
                
                // Make sure progress never decreases
                this.bulkExportProgress = Math.max(this.bulkExportProgress, newProgress);
                
                // Update the progress bar
                this.updateProgressBar(this.bulkExportProgress);
                
                // Check if we're done
                if (endIndex < permissions.length) {
                    // Process next batch with reduced delay for faster processing
                    Promise.resolve().then(() => this.processTemplatePermissionsBatch(permissions, endIndex));
                } else {
                    // All batches are processed, generate Excel file
                    this.bulkExportStatus = '📊 Generating optimized template Excel file...';
                    this.bulkExportProgress = 95; // Set to 95% for Excel generation
                    this.updateProgressBar(this.bulkExportProgress);
                    Promise.resolve().then(() => this.generateTemplateExcelFile());
                }
            })
            .catch(error => {
                // console.error('Error processing template permissions batch:', error);
                this.bulkExportStatus = 'Error during template export. See console for details.';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Template Export Error',
                        message: error.message || 'An error occurred during the template export process.',
                        variant: 'error'
                    })
                );
                this.isBulkExporting = false;
                Promise.resolve().then(() => {
                    this.showBulkExportModal = false;
                });
            });
    }
    
    /**
     * @description Process permissions in a batch sequentially for template export
     * @param {Array} batch - Batch of permissions to process
     * @param {Number} index - Current index in the batch
     * @returns {Promise} Promise that resolves when the batch is processed
     */
    processTemplatePermissionSequentially(batch, index) {
        return new Promise((resolve, reject) => {
            if (index >= batch.length) {
                resolve();
                return;
            }
            
            const permission = batch[index];
            
            // Update detailed status
            this.bulkExportStatus = `Analyzing "${permission.label}"...`;
            
            // Get permission access data - use enhanced method if user fields are selected
            const { selectedUserFields } = this.templateExportData;
            let userFieldNames = null;
            
            if (selectedUserFields && selectedUserFields.length > 0) {
                // For template export, also include core fields if dynamic fields are being used
                const coreFields = ['Id', 'Name', 'Username', 'Email', 'IsActive', 'Profile.Name'];
                const selectedFieldNames = selectedUserFields.map(field => field.name || field.value || field.id || field.label);
                const allFieldsSet = new Set([...coreFields, ...selectedFieldNames]);
                userFieldNames = Array.from(allFieldsSet);
                
                // console.log('Template Export: User fields being passed to permission analysis:', userFieldNames);
            }
                
            // Use ultra-optimized method with fallback strategy for timeout-prone permissions
            this.processPermissionWithFallback(permission.name, userFieldNames)
                .then(result => {
                    // Store the result for this permission
                    this.bulkExportResults.push({
                        permission: permission,
                        result: result
                    });
                    
                    // Update intermediate progress bar within batch
                    this.batchProcessed++;
                    // Avoid decreasing progress with Math.max
                    this.bulkExportProgress = Math.max(
                        this.bulkExportProgress,
                        Math.round(((this.bulkExportProcessed + (this.batchProcessed / this.batchSize)) / this.bulkExportTotal) * 90)
                    );
                    this.updateProgressBar(this.bulkExportProgress);
                    
                    // Process next permission in the batch
                    this.processTemplatePermissionSequentially(batch, index + 1)
                        .then(resolve)
                        .catch(reject);
                })
                .catch(error => {
                    // console.warn(`Error processing permission ${permission.name}:`, error);
                    
                    // Add to results with empty data
                    this.bulkExportResults.push({
                        permission: permission,
                        result: {
                            profilesWithAccess: [],
                            permissionSetsWithAccess: [],
                            permissionSetGroupsWithAccess: [],
                            usersWithAccess: [],
                            totalUsers: 0
                        },
                        error: error
                    });
                    
                    // Update intermediate progress bar within batch
                    this.batchProcessed++;
                    // Avoid decreasing progress with Math.max
                    this.bulkExportProgress = Math.max(
                        this.bulkExportProgress,
                        Math.round(((this.bulkExportProcessed + (this.batchProcessed / this.batchSize)) / this.bulkExportTotal) * 90)
                    );
                    this.updateProgressBar(this.bulkExportProgress);
                    
                    // Still continue with next permission
                    this.processTemplatePermissionSequentially(batch, index + 1)
                        .then(resolve)
                        .catch(reject);
                });
        });
    }
    
    /**
     * @description Process a single permission with fallback strategy to avoid timeouts
     * @param {string} permissionName - The system permission name
     * @param {Array} userFieldNames - Array of user field names to include
     * @returns {Promise} Promise that resolves to permission data
     */
    async processPermissionWithFallback(permissionName, userFieldNames) {
        try {
            // TEMPLATE EXPORT STRATEGY: Always prioritize user fields if they are requested
            if (userFieldNames && userFieldNames.length > 0) {
                try {
                    // console.log(`🚀 Template Export: Using user field analysis for ${permissionName} with ${userFieldNames.length} fields`);
                    const maxUsers = this.includeAllUsers ? 50000 : 2000; // Adjust max users based on includeAllUsers flag
                    return await getSystemPermissionAccessWithUserFields({ 
                        systemPermissionName: permissionName,
                        selectedUserFields: userFieldNames,
                        maxUsers: maxUsers
                    });
                } catch (userFieldError) {
                    // console.warn(`User field analysis failed for ${permissionName}, trying without fields:`, userFieldError);
                    // Fall back to method without user fields
                }
            }
            
            // Check if "Include All Active Users" is enabled - use different strategy
            if (this.includeAllUsers) {
                // console.log(`🚀 Template Export: Include All Users enabled - using comprehensive method for permission: ${permissionName}`);
                // No user fields requested or user fields failed, use the fetchAllUsersForPermission method
                // console.log(`Using fetchAllUsersForPermission for ${permissionName} with ALL USERS`);
                return await this.fetchAllUsersForPermission(permissionName, 1000);
            }
            
            // STANDARD STRATEGY: Conservative limits for normal template exports
            try {
                // console.log(`🚀 Template Export: Attempting ultra-optimized analysis for permission: ${permissionName}`);
                return await getSystemPermissionAccessUltraOptimized({ 
                    systemPermissionName: permissionName,
                        maxUsers: 2000 // Increased from 100 to 2000 for better coverage
                });
            } catch (ultraError) {
                // console.warn(`Ultra-optimized failed for ${permissionName}, trying with user fields:`, ultraError);
                
                    // Second attempt: Try with user fields if requested (this is the backup for when user fields weren't prioritized above)
                if (userFieldNames && userFieldNames.length > 0) {
                    try {
                        // console.log(`Attempting user field analysis for ${permissionName} with ${userFieldNames.length} fields (fallback)`);
                        return await getSystemPermissionAccessWithUserFields({ 
                            systemPermissionName: permissionName,
                                selectedUserFields: userFieldNames.slice(0, 5), // Increased from 2 to 5 fields
                                maxUsers: 1500 // Increased from 75 to 1500 users
                        });
                    } catch (userFieldError) {
                        // console.warn(`User field analysis also failed for ${permissionName}:`, userFieldError);
                    }
                }
                
                    // Third attempt: Try optimized method with reasonable limits
                    // console.log(`Attempting optimized analysis with standard limits for permission: ${permissionName}`);
                    return await getSystemPermissionAccessOptimized({ 
                        systemPermissionName: permissionName,
                            userPageSize: 200, // Increased from 20 to 200
                        userPageNumber: 1
                    });
            }
        } catch (error) {
            // console.error(`All methods failed for permission ${permissionName}:`, error);
            
            // Final fallback: return minimal data structure to prevent complete failure
            return {
                systemPermissionName: permissionName,
                profilesWithAccess: [],
                permissionSetsWithAccess: [],
                permissionSetGroupsWithAccess: [],
                usersWithAccess: [],
                totalUsers: 0,
                error: 'Template analysis failed due to org size limitations - data incomplete for this permission',
                errorDetails: error.body ? error.body.message : error.message,
                isFallback: true,
                isTemplateExport: true // Flag to indicate this is from template export
            };
        }
    }

    /**
     * @description Generate Excel file for template export
     */
    generateTemplateExcelFile() {
        try {
            const { template, selectedProfiles, selectedPermSets, selectedPermSetGroups, validSystemPerms, selectedUsers, selectedUserFields } = this.templateExportData;
            
            // Update progress to 95%
            this.bulkExportProgress = 95;
            this.updateProgressBar(95);
            this.bulkExportStatus = '📊 Generating Excel file (95%)...';
            
            // Process Excel generation immediately to avoid setTimeout restrictions
            try {
                // Create workbook data with memory optimization
                const workbookData = this.createOptimizedWorkbookData(template, selectedProfiles, selectedPermSets, selectedPermSetGroups, validSystemPerms, selectedUsers, selectedUserFields);
                
                // Update progress to 97%
                this.bulkExportProgress = 97;
                this.updateProgressBar(97);
                this.bulkExportStatus = '📊 Creating Excel workbook (97%)...';
                
                // Create XLSX workbook with minimal options to reduce memory usage
                const workbook = window.XLSX.utils.book_new();
                workbook.Props = {
                    Title: `Template Export - ${template.name}`,
                    Subject: "Salesforce Permission Template",
                    Author: "Permissions Manager",
                    CreatedDate: new Date()
                };
                
                // Add worksheets with minimal styling to prevent memory issues
                Object.entries(workbookData).forEach(([sheetName, sheetData]) => {
                    if (sheetData.length > 0) {
                        const worksheet = window.XLSX.utils.aoa_to_sheet(sheetData);
                        
                        // Only set essential column widths to reduce memory usage
                        if (sheetData.length > 0 && sheetData[0].length > 0) {
                            const colWidths = [];
                            for (let i = 0; i < Math.min(sheetData[0].length, 20); i++) { // Limit to first 20 columns
                                colWidths.push({ wch: 15 }); // Standard width
                            }
                            worksheet['!cols'] = colWidths;
                        }
                        
                        // Add freeze panes only for header row
                        worksheet['!freeze'] = { xSplit: 0, ySplit: 1 };
                        
                        // Apply basic styling
                        this.applyCellStyling(worksheet, sheetData);
                        
                        window.XLSX.utils.book_append_sheet(workbook, worksheet, sheetName);
                    }
                });
                
                // Update progress to 99%
                this.bulkExportProgress = 99;
                this.updateProgressBar(99);
                this.bulkExportStatus = '📊 Finalizing download (99%)...';
                
                // Generate filename with template name and timestamp
                const now = new Date();
                const timestamp = now.toISOString().replace(/[:\-T]/g, '_').split('.')[0];
                const sanitizedTemplateName = template.name.replace(/[^a-zA-Z0-9]/g, '_');
                const filename = `Template_${sanitizedTemplateName}_${timestamp}.xlsx`;
                
                // Final update to 100%
                this.bulkExportStatus = 'Downloading Excel file...';
                this.bulkExportProgress = 100;
                this.updateProgressBar(100);
                
                // Use minimal write options to reduce memory usage (same as working backup)
                const wopts = { 
                    bookType: 'xlsx', 
                    bookSST: false, 
                    type: 'binary'
                };
                
                // Write the file with error handling (same approach as working backup)
                try {
                    window.XLSX.writeFile(workbook, filename, wopts);
                    // console.log('Template Excel file written successfully');
                } catch (writeError) {
                    console.error('Error writing Excel file:', writeError);
                    throw new Error('Failed to generate Excel file: ' + writeError.message);
                }
                
                // Success - hide modal after download
                this.showBulkExportModal = false;
                this.isBulkExporting = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Export Complete',
                        message: `Template "${template.name}" has been exported successfully.`,
                        variant: 'success'
                    })
                );
                
            } catch (innerError) {
                console.error('Error in Excel generation:', innerError);
                this.handleExportError(innerError, 'Template export failed');
            }
            
        } catch (error) {
            this.handleExportError(error, 'Template export failed');
        }
    }
    
    /**
     * @description Create optimized workbook data with memory management
     */
    createOptimizedWorkbookData(template, selectedProfiles, selectedPermSets, selectedPermSetGroups, validSystemPerms, selectedUsers, selectedUserFields) {
        const workbookData = {};
        
        try {
            // Generate sheets with size limits to prevent memory issues
            workbookData.Summary = this.generateTemplateSummarySheet(template, selectedProfiles, selectedPermSets, validSystemPerms, selectedUsers, selectedUserFields, selectedPermSetGroups);
            
            // Only include sheets with data to reduce memory usage
            if (selectedProfiles && selectedProfiles.length > 0) {
                workbookData['Permissions By Profile'] = this.generateTemplateProfilePermissionsSheet(selectedProfiles, validSystemPerms, this.bulkExportResults); // Export all selected permissions
            }
            
            if (selectedUsers && selectedUsers.length > 0) {
                workbookData['Permissions By User'] = this.generateTemplateUserPermissionsSheet(validSystemPerms, this.bulkExportResults, selectedUsers.slice(0, 1000), selectedUserFields); // Export all selected permissions, limit users to 1000
            }
            
            if (selectedPermSets && selectedPermSets.length > 0) {
                workbookData['Permission Sets'] = this.generateTemplatePermSetsSheet(selectedPermSets, validSystemPerms, this.bulkExportResults); // Export all selected permissions
            }
            
            // Ensure permission set groups are included in the export
            if (selectedPermSetGroups && selectedPermSetGroups.length > 0) {
                // Log for debugging
                // console.log('Adding Permission Set Groups sheet with', selectedPermSetGroups.length, 'groups');
                // console.log('Permission Set Group IDs:', selectedPermSetGroups.map(g => g.id).join(', '));
                workbookData['Permission Set Groups'] = this.generateTemplatePermSetGroupsSheet(selectedPermSetGroups, validSystemPerms, this.bulkExportResults); // Export all selected permissions
            }
            
        } catch (err) {
            // console.error('Error creating workbook data:', err);
            // Return minimal data structure if generation fails
            workbookData.Summary = [['Error'], ['Failed to generate complete export due to data size limitations']];
        }
        
        return workbookData;
    }
    
    /**
     * @description Handle export errors consistently
     */
    handleExportError(err, context) {
        this.bulkExportStatus = `Error: ${context}`;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Export Error',
                message: `${context}: ${err.message || 'Unknown error'}. Try reducing the number of profiles, permission sets, or system permissions in your template.`,
                variant: 'error'
            })
        );
        Promise.resolve().then(() => {
            this.showBulkExportModal = false;
            this.isBulkExporting = false;
        });
    }

    /**
     * @description Apply cell styling to match bulk export formatting
     * @param {Object} worksheet - The XLSX worksheet object
     * @param {Array} data - The worksheet data
     */
    /**
     * @description Apply minimal cell styling to worksheet - MEMORY OPTIMIZED
     * @param {Object} worksheet - The XLSX worksheet object
     * @param {Array} data - The sheet data array
     */
    applyCellStyling(worksheet, data) {
        if (!worksheet || !data || !data.length) return;
        
        try {
            // Skip styling for large datasets to prevent memory issues and browser crashes
            const totalCells = data.length * (data[0]?.length || 0);
            if (totalCells > 10000 || data.length > 500 || (data[0] && data[0].length > 50)) {
                // console.log(`Skipping complex styling for large dataset (${data.length} rows, ${data[0]?.length || 0} cols, ${totalCells} total cells) to prevent memory issues`);
                return;
            }
            
            // Check if the XLSX.utils has the required style methods
            const hasStyleSupport = window.XLSX && (window.XLSX.SSF || window.XLSX.utils.book_append_sheet);
            
            if (!hasStyleSupport) {
                // console.warn('XLSX style support may not be available. Colors may not appear in the exported file.');
                return;
            }
            
            // console.log(`Applying minimal styling to ${data.length} rows with ${data[0]?.length || 0} columns`);
            
            // Define minimal styles only - reduced complexity
            const headerStyle = {
                fill: { patternType: "solid", fgColor: { rgb: "1F497D" } },
                font: { color: { rgb: "FFFFFF" }, bold: true }
            };
            
            const yesValueStyle = {
                fill: { patternType: "solid", fgColor: { rgb: "C6EFCE" } }, // Light green background
                font: { bold: true } // Bold text for Yes values
            };
            
            const noValueStyle = {
                fill: { patternType: "solid", fgColor: { rgb: "FFC7CE" } } // Light red background
            };
            
            // Apply header style to first row only
            const headerRange = window.XLSX.utils.decode_range(worksheet['!ref']);
            const maxCols = Math.min(headerRange.e.c + 1, 30); // Limit to 30 columns max
            
            for (let C = headerRange.s.c; C < maxCols; ++C) {
                const headerCell = window.XLSX.utils.encode_cell({ r: 0, c: C });
                if (!worksheet[headerCell]) continue;
                
                if (!worksheet[headerCell].s) worksheet[headerCell].s = {};
                Object.assign(worksheet[headerCell].s, headerStyle);
            }
            
            // Apply minimal Yes/No styling for small datasets only
            const maxRows = Math.min(headerRange.e.r + 1, 200); // Limit to 200 rows max
            
            if (data.length <= 200) {
                for (let R = 1; R < maxRows; ++R) {
                    for (let C = headerRange.s.c; C < maxCols; ++C) {
                        const cell = window.XLSX.utils.encode_cell({ r: R, c: C });
                        if (!worksheet[cell]) continue;
                        
                        // Apply minimal Yes/No styling only
                        const cellValue = data[R] && data[R][C];
                        if (cellValue === 'Yes') {
                            if (!worksheet[cell].s) worksheet[cell].s = {};
                            Object.assign(worksheet[cell].s, yesValueStyle);
                        } else if (cellValue === 'No') {
                            if (!worksheet[cell].s) worksheet[cell].s = {};
                            Object.assign(worksheet[cell].s, noValueStyle);
                        }
                    }
                }
            }
            
            // console.log(`Applied minimal styling to ${Math.min(data.length, 200)} rows and ${Math.min(data[0]?.length || 0, 30)} columns`);
            
        } catch (error) {
            // console.warn('Error applying cell styling (styling skipped to prevent crash):', error);
            // Don't throw error - just skip styling to prevent export failure
        }
    }



    /**
     * @description Generate the Template Summary worksheet
     * @param {Object} template - The template object
     * @param {Array} profiles - Array of profile objects
     * @param {Array} permSets - Array of permission set objects
     * @param {Array} systemPerms - Array of system permission objects
     * @param {Array} users - Array of user objects
     * @param {Array} userFields - Array of user field objects
     * @returns {Array} Array of arrays representing the worksheet data
     */
    generateTemplateSummarySheet(template, profiles, permSets, systemPerms, users = [], userFields = [], permSetGroups = []) {
        // Create header row
        const headers = ['Template Information', 'Value'];
        
        // Add template information
        const templateInfo = [
            headers,
            ['Name', template.name],
            ['ID', template.id],
            ['Created Date', new Date().toLocaleString()],
            ['Export Date', new Date().toLocaleString()],
            [''],
            ['Statistics', ''],
            ['Total Profiles', profiles.length.toString()],
            ['Total Permission Sets', permSets.length.toString()],
            ['Total Permission Set Groups', permSetGroups.length.toString()],
            ['Total System Permissions', systemPerms.length.toString()],
            ['Total Users', users.length.toString()],
            ['Total User Fields', userFields.length.toString()],
            [''] 
        ];
        
        // Add profile names
        if (profiles.length > 0) {
            templateInfo.push(['Included Profiles', '']);
            profiles.forEach(profile => {
                templateInfo.push(['', profile.name]);
            });
            templateInfo.push(['']);
        }
        
        // Add permission set names
        if (permSets.length > 0) {
            templateInfo.push(['Included Permission Sets', '']);
            permSets.forEach(permSet => {
                templateInfo.push(['', permSet.name]);
            });
            templateInfo.push(['']);
        }

        // Add permission set group names
        if (permSetGroups.length > 0) {
            templateInfo.push(['Included Permission Set Groups', '']);
            permSetGroups.forEach(permSetGroup => {
                templateInfo.push(['', permSetGroup.label || permSetGroup.name]);
            });
            templateInfo.push(['']);
        }

        // Add user names
        if (users.length > 0) {
            templateInfo.push(['Included Users', '']);
            users.forEach(user => {
                templateInfo.push(['', `${user.name} (${user.username})`]);
            });
            templateInfo.push(['']);
        }

        // Add user field names
        if (userFields.length > 0) {
            templateInfo.push(['Included User Fields', '']);
            userFields.forEach(field => {
                templateInfo.push(['', `${field.label} (${field.name})`]);
            });
            templateInfo.push(['']);
        }
        
        // Add system permission names
        if (systemPerms.length > 0) {
            templateInfo.push(['Included System Permissions', '']);
            systemPerms.forEach(perm => {
                templateInfo.push(['', perm.label]);
            });
        }
        
        return templateInfo;
    }
    
    /**
     * @description Generate the Template Profile Permissions worksheet
     * @param {Array} profiles - Array of profile objects
     * @param {Array} systemPerms - Array of system permission objects
     * @param {Array} permissionResults - Array of permission access results
     * @returns {Array} Array of arrays representing the worksheet data
     */
    generateTemplateProfilePermissionsSheet(profiles, systemPerms, permissionResults) {
        // Create header row with permission names
        const permissionNames = systemPerms.map(perm => perm.label);
        const headers = ['Profile Name', 'Description', 'Profile ID', ...permissionNames];
        
        // Create a map of all profiles
        const profilesMap = new Map();
        
        // Initialize all profiles with their basic info
        profiles.forEach(profile => {
            profilesMap.set(profile.id, {
                id: profile.id,
                name: profile.name,
                description: profile.description || '',
                permissions: new Map()
            });
        });
        
        // Populate permission data from results
        permissionResults.forEach(item => {
            const permLabel = item.permission.label;
            const profilesWithAccess = item.result?.profilesWithAccess || [];
            
            // Mark permissions for profiles that have access
            profilesWithAccess.forEach(profile => {
                // If this is one of our selected profiles, mark the permission
                if (profilesMap.has(profile.id)) {
                    profilesMap.get(profile.id).permissions.set(permLabel, true);
                }
            });
        });
        
        // Create data rows for each profile
        const rows = Array.from(profilesMap.values()).map(profile => {
            const row = [profile.name, profile.description, profile.id];
            
            // Add a column for each permission
            permissionNames.forEach(permName => {
                // If the profile has this permission, mark it as Yes, otherwise No
                row.push(profile.permissions.get(permName) ? 'Yes' : 'No');
            });
            
            return row;
        });
        
        // Debug: Log the final rows to see what's being exported
        // console.log('generateTemplatePermSetsSheet - Generated rows count:', rows.length);
        /* console.log('generateTemplatePermSetsSheet - Sample rows:', rows.slice(0, 3).map(row => ({
            permSetName: row[0],
            permSetId: row[1],
            assigneeId: row[7],
            assigneeName: row[8],
            assignmentId: row[10],
            totalAssignments: row[row.length - 1]
        })));*/
        
        // Return combined header and data rows
        return [headers, ...rows];
        
        /* 
         * DATA STRUCTURE EXPLANATION:
         * 
         * This method now handles two types of permission sets:
         * 1. Permission sets with assignment data (from fetchPermissionSetsWithAssignments)
         *    - These appear first in the export
         *    - Have complete assignment information (assignee, dates, etc.)
         *    - Show actual assignment rows
         * 
         * 2. Permission sets without assignment data (from bulk export results only)
         *    - These appear after permission sets with assignment data
         *    - Have system permission mappings but no assignment details
         *    - Show "(No Assignment Data Available)" in the name
         *    - Have empty assignment columns
         * 
         * This fixes the issue where the first 150-200 rows had empty assignment data
         * because they were permission sets found in bulk results but not in the
         * selected permission sets list.
         */
    }

    /**
     * @description Generate the Template User Permissions worksheet
     * @param {Array} systemPerms - Array of system permission objects
     * @param {Array} permissionResults - Array of permission access results
     * @param {Array} selectedUsers - Array of selected user objects (optional)
     * @param {Array} selectedUserFields - Array of selected user field objects (optional)
     * @returns {Array} Array of arrays representing the worksheet data
     */
    generateTemplateUserPermissionsSheet(systemPerms, permissionResults, selectedUsers = [], selectedUserFields = []) {
        // Create header row with permission names
        const permissionNames = systemPerms.map(perm => perm.label);
        
        // Build dynamic headers based on selected user fields
        let userFieldHeaders = ['User Name', 'Username', 'User ID', 'Profile'];
        
        // console.log('generateTemplateUserPermissionsSheet - selectedUserFields:', JSON.stringify(selectedUserFields));
        
        // If specific user fields are selected, add only those
        if (selectedUserFields.length > 0) {
            const additionalFields = selectedUserFields
                .filter(field => {
                    const fieldName = field.name || field.value || field.id || '';
                    return !['name', 'username', 'id', 'profile'].includes(fieldName.toLowerCase());
                })
                .map(field => field.label || field.name || field.value || field.id);
            userFieldHeaders = userFieldHeaders.concat(additionalFields);
        }
        
        const headers = [...userFieldHeaders, ...permissionNames, 'Permission Source'];
        
        // Create a map of all users
        const usersMap = new Map();
        
        // Collect all users from all results
        permissionResults.forEach(item => {
            const users = item.result?.usersWithAccess || [];
            users.forEach(user => {
                // If specific users are selected, only include those users
                if (selectedUsers.length > 0 && !selectedUsers.some(selectedUser => selectedUser.id === user.id)) {
                    return;
                }
                
                if (!usersMap.has(user.id)) {
                    usersMap.set(user.id, {
                        id: user.id,
                        name: user.name,
                        username: user.username,
                        email: user.email,
                        profileName: user.profileName,
                        permissions: new Map(),
                        sources: new Map(),
                        // New map to track unique permission sources
                        uniqueSources: new Set(),
                        // Store additional user data for selected fields
                        userData: user,
                        // Also store the user data directly for easier access
                        ...user
                    });
                }
                
                // Mark this permission as granted for this user
                usersMap.get(user.id).permissions.set(item.permission.label, true);
                
                // Store permission sources for this permission
                if (user.permissionSources && user.permissionSources.length) {
                    // Process and deduplicate sources
                    const processedSources = [];
                    
                    user.permissionSources.forEach(source => {
                        const sourceKey = `${source.type}: ${source.name}`;
                        // Only add if this is a new unique source
                        if (!usersMap.get(user.id).uniqueSources.has(sourceKey)) {
                            usersMap.get(user.id).uniqueSources.add(sourceKey);
                            processedSources.push(sourceKey);
                        }
                    });
                    
                    if (processedSources.length > 0) {
                        usersMap.get(user.id).sources.set(item.permission.label, processedSources);
                    }
                }
            });
        });
        
        // === NEW LOGIC: Ensure ALL selected users are included, even if they have NO permissions ===
        if (selectedUsers.length > 0) {
            selectedUsers.forEach(selUser => {
                if (!usersMap.has(selUser.id)) {
                    usersMap.set(selUser.id, {
                        id: selUser.id,
                        name: selUser.name,
                        username: selUser.username,
                        email: selUser.email,
                        profileName: selUser.profileName,
                        permissions: new Map(), // No permissions granted
                        sources: new Map(),
                        uniqueSources: new Set(),
                        userData: selUser,
                        // Also store the user data directly for easier access
                        ...selUser
                    });
                }
            });
        }
        
        // Create data rows - separate row for each permission source
        const rows = [];
        Array.from(usersMap.values()).forEach(user => {
            const uniqueSourcesList = Array.from(user.uniqueSources);
            
            // If user has no permission sources, create one row with empty source
            if (uniqueSourcesList.length === 0) {
                const row = [user.name, user.username, user.id, user.profileName];
                
                // Add additional user fields if selected
                if (selectedUserFields.length > 0) {
                    selectedUserFields
                        .filter(field => {
                            const fieldName = field.name || field.value || field.id || '';
                            return !['name', 'username', 'id', 'profile'].includes(fieldName.toLowerCase());
                        })
                        .forEach(field => {
                            const fieldName = field.name || field.value || field.id || '';
                            const fieldValue = user[fieldName] || user.userData[fieldName] || '';
                            row.push(fieldValue);
                        });
                }
                
                // Add a column for each permission
                permissionNames.forEach(permName => {
                    row.push(user.permissions.get(permName) ? 'Yes' : 'No');
                });
                
                // Add empty permission source
                row.push('');
                rows.push(row);
            } else {
                // Create a separate row for each permission source
                uniqueSourcesList.forEach(source => {
                    const row = [user.name, user.username, user.id, user.profileName];
                    
                    // Add additional user fields if selected
                    if (selectedUserFields.length > 0) {
                        selectedUserFields
                            .filter(field => {
                                const fieldName = field.name || field.value || field.id || '';
                                return !['name', 'username', 'id', 'profile'].includes(fieldName.toLowerCase());
                            })
                            .forEach(field => {
                                const fieldName = field.name || field.value || field.id || '';
                                const fieldValue = user[fieldName] || user.userData[fieldName] || '';
                                row.push(fieldValue);
                            });
                    }
                    
                    // Add a column for each permission
                    permissionNames.forEach(permName => {
                        row.push(user.permissions.get(permName) ? 'Yes' : 'No');
                    });
                    
                    // Add the individual permission source
                    row.push(source);
                    rows.push(row);
                });
            }
        });
        
        // Log final statistics
        console.log(`✅ Generated ${rows.length} total rows for permission sets export`);
        
        // Return combined header and data rows
        return [headers, ...rows];
    }
    
    /**
     * @description Generate the Template Permission Sets worksheet
     * @param {Array} permSets - Array of permission set objects
     * @param {Array} systemPerms - Array of system permission objects
     * @param {Array} permissionResults - Array of permission access results
     * @returns {Array} Array of arrays representing the worksheet data
     */
    generateTemplatePermSetsSheet(permSets, systemPerms, permissionResults) {
        // Create a set of permission set IDs that are included in this split
        const splitPermSetIds = new Set(permSets.map(ps => ps.id));
        console.log(`📋 Split contains ${splitPermSetIds.size} specific permission sets`);
        if (splitPermSetIds.size <= 10) {
            console.log('📋 Split permission set IDs:', Array.from(splitPermSetIds));
        }
        // Debug: Log the permission sets data to see what we're working with
        // console.log('generateTemplatePermSetsSheet - permSets:', JSON.stringify(permSets.map(ps => ({
        //     id: ps.id,
        //     name: ps.name || ps.label,
        //     assignmentsCount: ps.assignments ? ps.assignments.length : 0,
        //     assignments: ps.assignments ? ps.assignments.map(a => ({
        //         assigneeId: a.assigneeId,
        //         assigneeName: a.assigneeName,
        //         assignmentId: a.assignmentId
        //     })) : []
        // })), null, 2));
        
        // Create header row with permission names
        const permissionNames = systemPerms.map(perm => perm.label);
        const headers = ['Permission Set Name', 'Permission Set ID', 'Is Custom', 'Created By ID', 'Created By Name', 'Created Date', 'Description', 
                        'Assignee ID', 'Assignee Name', 'Expiration Date', 'Assignment ID', 'Is Active', 'Is Revoked', 
                        'Last Created By Change ID', 'Last Deleted By Change ID', 'Permission Set Group ID', 
                        'Permission Set ID (Assignment)', 'System Modstamp', ...permissionNames, 'Total Assignments Count'];
        
        // Create a map of all permission sets with their assignments
        const permSetsMap = new Map();
        
        // Initialize all permission sets with their basic info and assignments
        console.log(`📋 Processing ${permSets.length} selected permission sets with assignment data`);
        permSets.forEach((permSet, index) => {
            const assignments = permSet.assignments || [];
            const totalAssignments = assignments.length;
            
            if (index < 5) {
                console.log(`   ${index + 1}. Adding selected permission set: ${permSet.id} - ${permSet.label || permSet.name} (${totalAssignments} assignments)`);
            }
            
            permSetsMap.set(permSet.id, {
                id: permSet.id,
                name: permSet.label || permSet.name,
                isCustom: permSet.isCustom || false,
                createdById: permSet.createdById || '',
                createdByName: permSet.createdByName || '',
                createdDate: permSet.createdDate ? new Date(permSet.createdDate).toLocaleDateString() : '',
                description: permSet.description || '',
                assignments: assignments,
                totalAssignments: totalAssignments,
                permissions: new Map(),
                hasAssignmentData: true // Mark that this permission set has assignment data
            });
        });
        
        if (permSets.length > 5) {
            console.log(`   ... and ${permSets.length - 5} more selected permission sets`);
        }
        
        // Populate permission data from results and add missing permission sets
        console.log(`📋 Processing bulk export results for ${permissionResults.length} permissions`);
        let bulkPermSetsProcessed = 0;
        let duplicatesFound = 0;
        let filteredOutBySplit = 0;
        
        permissionResults.forEach(item => {
            const permLabel = item.permission.label;
            const permSetsWithAccess = item.result?.permissionSetsWithAccess || [];
            
            // Mark permissions for permission sets that have access
            permSetsWithAccess.forEach(permSet => {
                bulkPermSetsProcessed++;
                
                // SPLIT FILTER: Only process permission sets that are part of this split
                // This prevents processing ALL permission sets from bulk results in split exports
                if (splitPermSetIds.size > 0 && !splitPermSetIds.has(permSet.id)) {
                    // Skip permission sets not in this split
                    filteredOutBySplit++;
                    return;
                }
                
                // Check if this permission set already exists (duplicate detection)
                if (permSetsMap.has(permSet.id)) {
                    duplicatesFound++;
                    if (duplicatesFound <= 5) {
                        console.log(`🔄 Permission set already exists in selected sets: ${permSet.id} - ${permSet.label || permSet.name}`);
                    }
                }
                // If this permission set is not in our map, add it with available metadata
                if (!permSetsMap.has(permSet.id)) {
                    console.log('📋 Adding permission set from bulk results (not in selected sets):', permSet.id, permSet.label || permSet.name);
                    
                    // Extract all available metadata from the bulk result
                    const permSetData = {
                        id: permSet.id,
                        name: permSet.label || permSet.name || permSet.developerName || `PermissionSet_${permSet.id}`,
                        isCustom: permSet.isCustom !== undefined ? permSet.isCustom : (permSet.namespacePrefix ? false : true),
                        createdById: permSet.createdById || permSet.CreatedById || '',
                        createdByName: permSet.createdByName || permSet.CreatedBy?.Name || '',
                        createdDate: permSet.createdDate || permSet.CreatedDate ? 
                            new Date(permSet.createdDate || permSet.CreatedDate).toLocaleDateString() : '',
                        description: permSet.description || permSet.Description || '',
                        assignments: [], // No assignment data available from bulk results
                        totalAssignments: 0,
                        permissions: new Map(),
                        hasAssignmentData: false // Mark that this permission set lacks assignment data
                    };
                    
                    // Log what metadata we found
                    console.log('📊 Permission set metadata extracted:', {
                        id: permSetData.id,
                        name: permSetData.name,
                        isCustom: permSetData.isCustom,
                        createdById: permSetData.createdById,
                        createdByName: permSetData.createdByName,
                        createdDate: permSetData.createdDate,
                        description: permSetData.description
                    });
                    
                    permSetsMap.set(permSet.id, permSetData);
                }
                
                // Mark the permission for this permission set
                permSetsMap.get(permSet.id).permissions.set(permLabel, true);
            });
        });
        
        // Log bulk processing statistics
        console.log(`📊 Bulk export processing complete:`);
        console.log(`   Total permission set references processed: ${bulkPermSetsProcessed}`);
        console.log(`   Filtered out by split logic: ${filteredOutBySplit}`);
        console.log(`   Duplicates found (already in selected sets): ${duplicatesFound}`);
        if (duplicatesFound > 5) {
            console.log(`   ... and ${duplicatesFound - 5} more duplicates not shown`);
        }
        
        // Log statistics for debugging
        const totalPermSets = permSetsMap.size;
        const permSetsWithAssignments = Array.from(permSetsMap.values()).filter(ps => ps.hasAssignmentData).length;
        const permSetsWithoutAssignments = totalPermSets - permSetsWithAssignments;
        
        console.log(`📊 Permission Sets Processing Summary:`);
        console.log(`   Total Permission Sets: ${totalPermSets}`);
        console.log(`   With Assignment Data: ${permSetsWithAssignments}`);
        console.log(`   Without Assignment Data: ${permSetsWithoutAssignments}`);
        
        if (permSetsWithoutAssignments > 0) {
            console.warn(`⚠️ ${permSetsWithoutAssignments} permission sets found in bulk results but not in selected permission sets. These will show empty assignment columns.`);
        }
        
        // Create data rows - one row for each assignment
        const rows = [];
        
        // Sort permission sets alphabetically by name for proper sequence
        const sortedPermSets = Array.from(permSetsMap.values()).sort((a, b) => {
            // Sort all permission sets alphabetically by name
            return (a.name || '').localeCompare(b.name || '');
        });
        
        console.log('📋 Permission sets will be displayed in alphabetical sequence:');
        sortedPermSets.slice(0, 10).forEach((permSet, index) => {
            console.log(`   ${index + 1}. ${permSet.name} (Has Assignments: ${permSet.hasAssignmentData})`);
        });
        if (sortedPermSets.length > 10) {
            console.log(`   ... and ${sortedPermSets.length - 10} more permission sets`);
        }
        
        console.log(`📋 Processing ${sortedPermSets.length} permission sets for Excel generation`);
        
        sortedPermSets.forEach((permSet) => {
            if (permSet.assignments.length === 0) {
                  // If no assignments, create one row with empty assignment data
                  const row = [
                      permSet.name,
                     permSet.id,
                     permSet.isCustom ? 'Yes' : 'No',
                     permSet.createdById,
                     permSet.createdByName,
                     permSet.createdDate,
                     permSet.description,
                     // Empty assignment fields
                     '', // Assignee ID
                     '', // Assignee Name
                     '', // Expiration Date
                     '', // Assignment ID
                     '', // Is Active
                     '', // Is Revoked
                     '', // Last Created By Change ID
                     '', // Last Deleted By Change ID
                     '', // Permission Set Group ID
                     '', // Permission Set ID (Assignment)
                     ''  // System Modstamp
                 ];
                
                // Add permission columns
                permissionNames.forEach(permName => {
                    row.push(permSet.permissions.get(permName) ? 'Yes' : 'No');
                });
                
                // Add total assignments count
                row.push(permSet.totalAssignments);
                
                rows.push(row);
            } else {
                // Create one row for each assignment
                permSet.assignments.forEach(assignment => {
                    const row = [
                        permSet.name,
                        permSet.id,
                        permSet.isCustom ? 'Yes' : 'No',
                        permSet.createdById,
                        permSet.createdByName,
                        permSet.createdDate,
                        permSet.description,
                        // Assignment fields
                        assignment.assigneeId || '',
                        assignment.assigneeName || '',
                        assignment.expirationDate ? new Date(assignment.expirationDate).toLocaleDateString() : '',
                        assignment.assignmentId || '',
                        assignment.isActive !== undefined ? (assignment.isActive ? 'Yes' : 'No') : '',
                        assignment.isRevoked !== undefined ? (assignment.isRevoked ? 'Yes' : 'No') : '',
                        assignment.lastCreatedByChangeId || '',
                        assignment.lastDeletedByChangeId || '',
                        assignment.permissionSetGroupId || '',
                        assignment.permissionSetId || '',
                        assignment.systemModstamp ? new Date(assignment.systemModstamp).toLocaleDateString() : ''
                    ];
                    
                    // Add permission columns
                    permissionNames.forEach(permName => {
                        row.push(permSet.permissions.get(permName) ? 'Yes' : 'No');
                    });
                    
                    // Add total assignments count
                    row.push(permSet.totalAssignments);
                    
                    rows.push(row);
                });
            }
        });
        
        // Return combined header and data rows
        return [headers, ...rows];
    }

    /**
     * @description Generate the Template Permission Set Groups worksheet
     * @param {Array} selectedPermSetGroups - Array of selected permission set group objects
     * @param {Array} systemPerms - Array of system permission objects
     * @param {Array} permissionResults - Array of permission access results
     * @returns {Array} Array of arrays representing the worksheet data
     */
    generateTemplatePermSetGroupsSheet(selectedPermSetGroups, systemPerms, permissionResults) {
        // Create header row with permission names
        const permissionNames = systemPerms.map(perm => perm.label);
        const headers = ['Permission Set Group Name', 'Permission Set Group ID', 'Permission Set Name', ...permissionNames, 'Assigned Users Count'];
        
        // Create maps for permission results lookup
        const permissionResultsMap = new Map();
        const permSetPermissionsMap = new Map();
        
        // Build map of permission results for permission set groups
        permissionResults.forEach(item => {
            const permSetGroups = item.result?.permissionSetGroupsWithAccess || [];
            permSetGroups.forEach(group => {
                if (!permissionResultsMap.has(group.id)) {
                    permissionResultsMap.set(group.id, new Map());
                }
                permissionResultsMap.get(group.id).set(item.permission.label, true);
            });
            
            // Also build map for individual permission sets
            const permSets = item.result?.permissionSetsWithAccess || [];
            permSets.forEach(permSet => {
                if (!permSetPermissionsMap.has(permSet.id)) {
                    permSetPermissionsMap.set(permSet.id, new Map());
                }
                permSetPermissionsMap.get(permSet.id).set(item.permission.label, true);
            });
        });
        
        const rows = [];
        
        // Process each selected permission set group
        selectedPermSetGroups.forEach(group => {
            // Get user count for this group
            let groupUserCount = 0;
            permissionResults.forEach(item => {
                const permSetGroups = item.result?.permissionSetGroupsWithAccess || [];
                const foundGroup = permSetGroups.find(g => g.id === group.id);
                if (foundGroup && foundGroup.assignedUsers) {
                    groupUserCount = Math.max(groupUserCount, foundGroup.assignedUsers.length);
                }
            });
            
            // Get component permission sets from the group data
            const componentPermissionSets = group.componentPermissionSets || [];
            
            if (componentPermissionSets.length === 0) {
                // If no permission sets in the group, create a single row for the group
                const row = [
                    group.label || group.name,
                    group.id,
                    'No Permission Sets'
                ];
                
                // Add permission columns based on group-level permissions
                permissionNames.forEach(permName => {
                    const hasPermission = permissionResultsMap.get(group.id)?.get(permName) || false;
                    row.push(hasPermission ? 'Yes' : 'No');
                });
                
                row.push(groupUserCount);
                rows.push(row);
            } else {
                // Create rows for each permission set in the group
                componentPermissionSets.forEach((permSet) => {
                    const row = [
                        group.label || group.name, // Show group name on every row
                        group.id, // Show group ID on every row
                        permSet.label || permSet.name
                    ];
                    
                    // Add permission columns based on individual permission set permissions
                    permissionNames.forEach(permName => {
                        const hasPermission = permSetPermissionsMap.get(permSet.id)?.get(permName) || false;
                        row.push(hasPermission ? 'Yes' : 'No');
                    });
                    
                    row.push(groupUserCount); // Show user count on every row
                    rows.push(row);
                });
            }
        });
        
        // If no permission set groups were selected, add a note
        if (rows.length === 0) {
            const emptyRow = ['No permission set groups selected', '', ''];
            permissionNames.forEach(() => emptyRow.push(''));
            emptyRow.push('0');
            rows.push(emptyRow);
        }
        
        // Return combined header and data rows
        return [headers, ...rows];
    }

    /**
     * @description Get appropriate freeze pane options for a worksheet
     * @param {String} sheetName - The name of the worksheet
     * @returns {Object} Freeze pane configuration object
     */
    getWorksheetFreezeOptions(sheetName) {
        let row = 1;
        let col = 0;

        switch (sheetName) {
            case 'Summary':
                // Freeze first row and column (Permission Name)
                row = 1;
                col = 1;
                break;

            case 'Permissions By Profile':
                // Freeze first row and first two columns (Profile Name and ID)
                row = 1;
                col = 2;
                break;

            case 'Permissions By User':
                // Freeze first row and first four columns (User Name, Username, ID, Profile)
                row = 1;
                col = 4;
                break;

            case 'Permission Sets':
                // Freeze first row and first three columns (Permission Set Name, ID, Is Custom)
                row = 1;
                col = 3;
                break;

            case 'Permission Set Groups':
                // Freeze first row and first two columns (PSG Name and ID)
                row = 1;
                col = 2;
                break;
                
            // Handle legacy template export sheet names
            case 'Template Info':
            case 'Profiles':
            case 'System Permissions':
                row = 1;
                col = 1;
                break;
                
            default:
                // Default freeze configuration for unknown sheet types
                row = 1;
                col = 1;
                break;
        }

        // Create appropriate pane configuration for SheetJS
        // This defines split panes and frozen panes in Excel
        return {
            xSplit: col,
            ySplit: row,
            topLeftCell: window.XLSX.utils.encode_cell({ r: row, c: col }),
            activePane: 'bottomRight',
            state: 'frozen'
        };
    }

    /**
     * @description Calculate optimal column widths based on content
     * @param {Array} data - Worksheet data
     * @returns {Array} Array of column width objects
     */
    calculateColumnWidths(data) {
        if (!data || data.length === 0) return [];

        const widths = [];
        const maxSampleSize = 100; // Limit sample size for performance
        const minWidth = 10;    // Minimum column width
        const maxWidth = 50;    // Maximum column width

        // Use first row (headers) and sample of data rows for width calculation
        const sampleRows = [data[0]].concat(
            data.slice(1, Math.min(data.length, maxSampleSize + 1))
        );

        // Get max number of columns
        const maxCols = Math.max(...sampleRows.map(row => row.length));

        // Initialize width array
        for (let c = 0; c < maxCols; c++) {
            // Start with column width based on first row (headers)
            const header = data[0][c] || '';
            let colWidth = Math.min(
                maxWidth,
                Math.max(minWidth, String(header).length * 1.2) // Use 1.2x multiplier for headers
            );

            // Sample data rows for width
            for (let r = 1; r < sampleRows.length; r++) {
                if (sampleRows[r][c] !== undefined) {
                    const cellValue = String(sampleRows[r][c]);
                    const cellWidth = Math.min(maxWidth, cellValue.length);
                    colWidth = Math.max(colWidth, cellWidth);
                }
            }

            // Special handling for first few columns which are typically identifiers
            if (c < 4) {
                colWidth = Math.max(colWidth, 15); // Ensure identifiers have sufficient width
            }

            widths.push({ wch: colWidth });
        }

        return widths;
    }

    /**
     * @description Generate summary worksheet data
     * @returns {Array} Array of arrays representing the worksheet data
     */
    generateSummaryWorksheet() {
        // Create header row
        const headers = ['Permission API Name', 'Permission Label', 'Profiles', 'Permission Sets', 'Permission Set Groups', 'Users'];

        // Create summary data rows
        const rows = this.bulkExportResults.map(item => {
            const result = item.result || {};
            return [
                item.permission.name,
                item.permission.label,
                (result.profilesWithAccess || []).length,
                (result.permissionSetsWithAccess || []).length,
                (result.permissionSetGroupsWithAccess || []).length,
                (result.usersWithAccess || []).length
            ];
        });

        // Return combined header and data rows
        return [headers, ...rows];
    }

    /**
     * @description Generate profile permissions worksheet data
     * @returns {Array} Array of arrays representing the worksheet data
     */
    generateProfilePermissionsWorksheet() {
        // Create header row with permission names
        const permissionNames = this.bulkExportResults.map(item => item.permission.label);
        const headers = ['Profile Name', 'Description', 'Profile ID', ...permissionNames];

        // Create a map of all profiles
        const profilesMap = new Map();

        // Collect all profiles from all results
        this.bulkExportResults.forEach(item => {
            const profiles = item.result?.profilesWithAccess || [];
            profiles.forEach(profile => {
                if (!profilesMap.has(profile.id)) {
                    profilesMap.set(profile.id, {
                        id: profile.id,
                        name: profile.name,
                        description: profile.description || '',
                        permissions: new Map()
                    });
                }

                // Mark this permission as granted for this profile
                profilesMap.get(profile.id).permissions.set(item.permission.label, true);
            });
        });

        // Create data rows
        const rows = Array.from(profilesMap.values()).map(profile => {
            const row = [profile.name, profile.description, profile.id];

            // Add a column for each permission
            permissionNames.forEach(permName => {
                row.push(profile.permissions.get(permName) ? 'Yes' : 'No');
            });

            return row;
        });

        // Return combined header and data rows
        return [headers, ...rows];
    }

    /**
     * @description Generate user permissions worksheet data
     * @returns {Array} Array of arrays representing the worksheet data
     */
    generateUserPermissionsWorksheet() {
        // Create header row with permission names
        const permissionNames = this.bulkExportResults.map(item => item.permission.label);
        const headers = ['User Name', 'Username', 'User ID', 'Profile', ...permissionNames, 'Permission Sources'];

        // Create a map of all users
        const usersMap = new Map();

        // Collect all users from all results
        this.bulkExportResults.forEach(item => {
            const users = item.result?.usersWithAccess || [];
            users.forEach(user => {
                if (!usersMap.has(user.id)) {
                    usersMap.set(user.id, {
                        id: user.id,
                        name: user.name,
                        username: user.username,
                        profileName: user.profileName,
                        permissions: new Map(),
                        sources: new Map(),
                        // New map to track unique permission sources
                        uniqueSources: new Set()
                    });
                }

                // Mark this permission as granted for this user
                usersMap.get(user.id).permissions.set(item.permission.label, true);

                // Store permission sources for this permission
                if (user.permissionSources && user.permissionSources.length) {
                    // Process and deduplicate sources
                    const processedSources = [];
                    
                    user.permissionSources.forEach(source => {
                        const sourceKey = `${source.type}: ${source.name}`;
                        // Only add if this is a new unique source
                        if (!usersMap.get(user.id).uniqueSources.has(sourceKey)) {
                            usersMap.get(user.id).uniqueSources.add(sourceKey);
                            processedSources.push(sourceKey);
                        }
                    });
                    
                    if (processedSources.length > 0) {
                        usersMap.get(user.id).sources.set(item.permission.label, processedSources);
                    }
                }
            });
        });

        // Create data rows
        const rows = Array.from(usersMap.values()).map(user => {
            const row = [user.name, user.username, user.id, user.profileName];

            // Add a column for each permission
            permissionNames.forEach(permName => {
                row.push(user.permissions.get(permName) ? 'Yes' : 'No');
            });

            // Add deduplicated sources
            const uniqueSourcesList = Array.from(user.uniqueSources);
            row.push(uniqueSourcesList.join('; '));

            return row;
        });

        // Return combined header and data rows
        return [headers, ...rows];
    }

    /**
     * @description Generate permission sets worksheet data
     * @returns {Array} Array of arrays representing the worksheet data
     */
    generatePermissionSetsWorksheet() {
        // Create header row with permission names
        const permissionNames = this.bulkExportResults.map(item => item.permission.label);
        const headers = ['Permission Set Name', 'Permission Set ID', 'Is Custom', ...permissionNames, 'Assigned Users Count'];

        // Create a map of all permission sets
        const permSetsMap = new Map();

        // Collect all permission sets from all results
        this.bulkExportResults.forEach(item => {
            const permSets = item.result?.permissionSetsWithAccess || [];
            permSets.forEach(permSet => {
                if (!permSetsMap.has(permSet.id)) {
                    permSetsMap.set(permSet.id, {
                        id: permSet.id,
                        name: permSet.label || permSet.name,
                        isCustom: permSet.isCustom || false,
                        userCount: (permSet.assignedUsers || []).length,
                        permissions: new Map()
                    });
                }

                // Mark this permission as granted for this permission set
                permSetsMap.get(permSet.id).permissions.set(item.permission.label, true);
            });
        });

        // Create data rows
        const rows = Array.from(permSetsMap.values()).map(permSet => {
            const row = [permSet.name, permSet.id, permSet.isCustom ? 'Yes' : 'No'];

            // Add a column for each permission
            permissionNames.forEach(permName => {
                row.push(permSet.permissions.get(permName) ? 'Yes' : 'No');
            });

            // Add user count
            row.push(permSet.userCount);

            return row;
        });

        // Return combined header and data rows
        return [headers, ...rows];
    }

    /**
     * @description Generate permission set groups worksheet data
     * @returns {Array} Array of arrays representing the worksheet data
     */
    generatePermissionSetGroupsWorksheet() {
        // Create header row with permission names
        const permissionNames = this.bulkExportResults.map(item => item.permission.label);
        const headers = ['Permission Set Group Name', 'Permission Set Group ID', ...permissionNames, 'Assigned Users Count'];

        // Create a map of all permission set groups
        const permSetGroupsMap = new Map();

        // Collect all permission set groups from all results
        this.bulkExportResults.forEach(item => {
            const permSetGroups = item.result?.permissionSetGroupsWithAccess || [];
            permSetGroups.forEach(group => {
                if (!permSetGroupsMap.has(group.id)) {
                    permSetGroupsMap.set(group.id, {
                        id: group.id,
                        name: group.label || group.name,
                        userCount: (group.assignedUsers || []).length,
                        permissions: new Map()
                    });
                }

                // Mark this permission as granted for this permission set group
                permSetGroupsMap.get(group.id).permissions.set(item.permission.label, true);
            });
        });

        // Create data rows
        const rows = Array.from(permSetGroupsMap.values()).map(group => {
            const row = [group.name, group.id];

            // Add a column for each permission
            permissionNames.forEach(permName => {
                row.push(group.permissions.get(permName) ? 'Yes' : 'No');
            });

            // Add user count
            row.push(group.userCount);

            return row;
        });

        // Return combined header and data rows
        return [headers, ...rows];
    }
    
    /**
     * @description Generate privileged permissions by PROFILE worksheet with detailed info
     */
    generatePrivilegedProfilesWorksheet() {
        const permissionNames = this.bulkExportResults.map(item => item.permission.label);
        const headers = ['Profile Name', 'Profile ID', 'Description', 'License Type', 'Created By ID', 'Created By Name', 'Created Date', ...permissionNames];
        
        const profilesMap = new Map();
        
        this.bulkExportResults.forEach(item => {
            const profiles = item.result?.profilesWithAccess || [];
            profiles.forEach(profile => {
                if (!profilesMap.has(profile.id)) {
                    // Format date safely
                    let formattedDate = '';
                    if (profile.createdDate) {
                        try {
                            formattedDate = new Date(profile.createdDate).toLocaleDateString();
                        } catch (e) {
                            formattedDate = profile.createdDate;
                        }
                    }
                    
                    profilesMap.set(profile.id, {
                        id: profile.id || '',
                        name: profile.name || '',
                        description: profile.description || '',
                        license: profile.userLicense || '',
                        createdById: profile.createdById || '',
                        createdByName: profile.createdByName || '',
                        createdDate: formattedDate,
                        permissions: new Map()
                    });
                }
                profilesMap.get(profile.id).permissions.set(item.permission.label, true);
            });
        });
        
        const rows = Array.from(profilesMap.values()).map(profile => {
            const row = [
                profile.name, 
                profile.id, 
                profile.description, 
                profile.license,
                profile.createdById,
                profile.createdByName,
                profile.createdDate
            ];
            permissionNames.forEach(permName => {
                row.push(profile.permissions.get(permName) ? 'Yes' : 'No');
            });
            return row;
        });
        
        return [headers, ...rows];
    }
    
    /**
     * @description Generate privileged permissions by PERMISSION SET worksheet with detailed info
     */
    generatePrivilegedPermSetsWorksheet() {
        const permissionNames = this.bulkExportResults.map(item => item.permission.label);
        const headers = ['Permission Set Name', 'Permission Set ID', 'Is Custom', 'Created By', 'Created Date', 'Description', ...permissionNames, 'Assigned Users Count'];
        
        const permSetsMap = new Map();
        
        this.bulkExportResults.forEach(item => {
            const permSets = item.result?.permissionSetsWithAccess || [];
            permSets.forEach(permSet => {
                if (!permSetsMap.has(permSet.id)) {
                    permSetsMap.set(permSet.id, {
                        id: permSet.id,
                        name: permSet.label || permSet.name,
                        isCustom: permSet.isCustom || false,
                        createdBy: permSet.createdByName || '',
                        createdDate: permSet.createdDate || '',
                        description: permSet.description || '',
                        userCount: (permSet.assignedUsers || []).length,
                        permissions: new Map()
                    });
                }
                permSetsMap.get(permSet.id).permissions.set(item.permission.label, true);
            });
        });
        
        const rows = Array.from(permSetsMap.values()).map(permSet => {
            const row = [
                permSet.name, 
                permSet.id, 
                permSet.isCustom ? 'Yes' : 'No',
                permSet.createdBy,
                permSet.createdDate,
                permSet.description
            ];
            permissionNames.forEach(permName => {
                row.push(permSet.permissions.get(permName) ? 'Yes' : 'No');
            });
            row.push(permSet.userCount);
            return row;
        });
        
        return [headers, ...rows];
    }
    
    /**
     * @description Generate privileged permissions by PERMISSION SET GROUP worksheet with detailed info
     */
    generatePrivilegedPermSetGroupsWorksheet() {
        const permissionNames = this.bulkExportResults.map(item => item.permission.label);
        const headers = ['Permission Set Group Name', 'Permission Set Group ID', 'Description', 'Created By ID', 'Created By Name', 'Created Date', ...permissionNames, 'Assigned Users Count'];
        
        const permSetGroupsMap = new Map();
        
        this.bulkExportResults.forEach(item => {
            const groups = item.result?.permissionSetGroupsWithAccess || [];
            groups.forEach(group => {
                if (!permSetGroupsMap.has(group.id)) {
                    permSetGroupsMap.set(group.id, {
                        id: group.id,
                        name: group.label || group.name || group.developerName || group.DeveloperName,
                        description: group.description || group.Description || '',
                        createdById: group.createdById || group.CreatedById || '',
                        createdByName: group.createdByName || group.CreatedBy?.Name || '',
                        createdDate: group.createdDate || group.CreatedDate ? 
                            new Date(group.createdDate || group.CreatedDate).toLocaleDateString() : '',
                        userCount: (group.assignedUsers || []).length,
                        permissions: new Map()
                    });
                }
                permSetGroupsMap.get(group.id).permissions.set(item.permission.label, true);
            });
        });
        
        const rows = Array.from(permSetGroupsMap.values()).map(group => {
            const row = [
                group.name, 
                group.id,
                group.description,
                group.createdById,
                group.createdByName,
                group.createdDate
            ];
            permissionNames.forEach(permName => {
                row.push(group.permissions.get(permName) ? 'Yes' : 'No');
            });
            row.push(group.userCount);
            return row;
        });
        
        return [headers, ...rows];
    }
    
    /**
     * @description Generate privileged permissions by USER worksheet with detailed info
     */
    generatePrivilegedUsersWorksheet() {
        const permissionNames = this.bulkExportResults.map(item => item.permission.label);
        const headers = ['User Name', 'Username', 'Email', 'User ID', 'Profile Name', 'Profile ID', 'User License', 'Is Active', 'Department', 'Title', 'Manager Name', 'Created Date', 'Last Login Date', ...permissionNames];
        
        const usersMap = new Map();
        
        this.bulkExportResults.forEach(item => {
            const users = item.result?.usersWithAccess || [];
            users.forEach(user => {
                const userId = user.userId || user.id || user.Id;
                if (!usersMap.has(userId)) {
                    // Format dates safely
                    let formattedCreatedDate = '';
                    if (user.createdDate) {
                        try {
                            formattedCreatedDate = new Date(user.createdDate).toLocaleDateString();
                        } catch (e) {
                            formattedCreatedDate = user.createdDate;
                        }
                    }
                    
                    let formattedLastLoginDate = '';
                    if (user.lastLoginDate) {
                        try {
                            formattedLastLoginDate = new Date(user.lastLoginDate).toLocaleDateString();
                        } catch (e) {
                            formattedLastLoginDate = user.lastLoginDate;
                        }
                    }
                    
                    usersMap.set(userId, {
                        id: userId || '',
                        name: user.userName || user.name || user.Name || '',
                        username: user.username || user.Username || '',
                        email: user.email || user.Email || '',
                        profileName: user.profileName || '',
                        profileId: user.profileId || '',
                        userLicense: user.userLicense || '',
                        isActive: user.isActive !== undefined ? (user.isActive ? 'Yes' : 'No') : '',
                        department: user.department || '',
                        title: user.title || '',
                        managerName: user.managerName || '',
                        createdDate: formattedCreatedDate,
                        lastLoginDate: formattedLastLoginDate,
                        permissions: new Map()
                    });
                }
                usersMap.get(userId).permissions.set(item.permission.label, true);
            });
        });
        
        const rows = Array.from(usersMap.values()).map(user => {
            const row = [
                user.name, 
                user.username, 
                user.email, 
                user.id, 
                user.profileName, 
                user.profileId,
                user.userLicense,
                user.isActive,
                user.department,
                user.title,
                user.managerName,
                user.createdDate,
                user.lastLoginDate
            ];
            permissionNames.forEach(permName => {
                row.push(user.permissions.get(permName) ? 'Yes' : 'No');
            });
            return row;
        });
        
        return [headers, ...rows];
    }

    /**
     * @description Load available templates from the server
     */
    loadTemplates() {
        // console.log('🔄 === BEGIN loadTemplates ===');
        // console.log('📊 Current templates array length before API call:', this.templates.length);
        
        return getTemplates()
            .then(templates => {
                // console.log('📡 Raw templates received from server:');
            // console.log('📊 Server returned', templates.length, 'templates');
            // console.log('📋 Server templates:', JSON.stringify(templates, null, 2));
                
                // Store old template names for comparison (used in console logs)
                // const oldTemplateNames = this.templates.map(t => t.name);
                
                // Format templates for lightning-combobox
                const formattedTemplates = templates.map(template => ({
                    id: template.id,
                    name: template.name,
                    label: template.name,
                    value: template.id,
                    profileId: template.profileId,
                    permissionSetIds: template.permissionSetIds,
                    permissionSetGroupIds: template.permissionSetGroupIds,
                    systemPermissionNames: template.systemPermissionNames,
                    userIds: template.userIds,
                    userFieldIds: template.userFieldIds
                }));
                
                // console.log('🔄 Formatted templates for UI:');
            // console.log('📊 Formatted templates count:', formattedTemplates.length);
            // console.log('📋 Formatted templates:', JSON.stringify(formattedTemplates.map(t => ({id: t.id, name: t.name})), null, 2));
                
                // Update the templates array
                this.templates = formattedTemplates;
                
                // Template comparison for debugging (used in console logs)
                // const newTemplateNames = this.templates.map(t => t.name);
                
                // console.log('📊 Template comparison:');
                // console.log('  - Old count:', oldTemplatesCount, 'New count:', this.templates.length);
                // console.log('  - Added templates:', addedTemplates);
                // console.log('  - Removed templates:', removedTemplates);
                
                // console.log('✅ === END loadTemplates - Success ===');
                return this.templates;
            })
            .catch(error => {
                // console.error('❌ Error loading templates:', error);
                // console.error('❌ Error details:', JSON.stringify(error, null, 2));
                // console.log('❌ === END loadTemplates - Error ===');
                throw error;
            });
    }

    /**
     * @description Initialize automatic permission set templates on page load
     * This method runs only once when the page loads and creates pset-a-auto and pset-b-auto templates
     */
    async initializeAutomaticTemplatesOnLoad() {
        try {
            console.log('🔄 Initializing automatic templates...');
            
            // Call the Apex method to initialize automatic templates
            const result = await initializeAutomaticTemplates();
            
            this.automaticTemplatesInitialized = true;
            this.automaticTemplatesExist = result.templatesExist || result.templatesCreated;
            this.automaticTemplateMessage = result.message;
            
            if (result.templatesCreated) {
                console.log('✅ Automatic templates created successfully:', result.message);
                
                // Show success toast
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Automatic Templates Created',
                        message: result.message,
                        variant: 'success'
                    })
                );
                
                // Refresh templates list to include the new automatic templates
                await this.loadTemplates();
            } else if (result.templatesExist) {
                console.log('ℹ️ Automatic templates already exist:', result.message);
            } else {
                console.warn('⚠️ Could not create automatic templates:', result.message);
            }
            
        } catch (error) {
            console.error('❌ Error initializing automatic templates:', error);
            this.automaticTemplateMessage = 'Error initializing automatic templates: ' + error.body?.message || error.message;
            
            // Show error toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Initializing Templates',
                    message: this.automaticTemplateMessage,
                    variant: 'error'
                })
            );
        }
    }

    /**
     * @description Toggle the Create Template section
     */
    handleToggleCreateSection() {
        this.isCreateSectionExpanded = !this.isCreateSectionExpanded;
        
        // Update icon class directly
        Promise.resolve().then(() => {
            const iconElement = this.template.querySelector('.expandable-card:first-child .expandable-icon');
            if (iconElement) {
                if (this.isCreateSectionExpanded) {
                    iconElement.classList.add('expanded');
                } else {
                    iconElement.classList.remove('expanded');
                }
            }
        });
    }

    /**
     * @description Toggle the Export Template section
     */
    handleToggleExportSection() {
        this.isExportSectionExpanded = !this.isExportSectionExpanded;
        
        // Update icon class directly
        Promise.resolve().then(() => {
            const iconElement = this.template.querySelector('.expandable-card:last-child .expandable-icon');
            if (iconElement) {
                if (this.isExportSectionExpanded) {
                    iconElement.classList.add('expanded');
                } else {
                    iconElement.classList.remove('expanded');
                }
            }
        });
    }

    // Add getters for section icons
    get createSectionIcon() {
        return this.isCreateSectionExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get exportSectionIcon() {
        return this.isExportSectionExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    // Add getters for section classes
    get createSectionClass() {
        return this.isCreateSectionExpanded 
            ? 'expandable-card__content expanded' 
            : 'expandable-card__content';
    }

    get exportSectionClass() {
        return this.isExportSectionExpanded 
            ? 'expandable-card__content expanded' 
            : 'expandable-card__content';
    }

    /**
     * Lifecycle hook when component is rendered
     * Used to apply custom styling to tab elements
     */
    renderedCallback() {
        // Apply direct styling to tab elements
        this.applyTabStyling();
    }

    /**
     * Applies CSS styling directly to tab elements
     * This bypasses shadow DOM restrictions by directly manipulating DOM elements
     */
    applyTabStyling() {
        // Get all tab elements
        const tabset = this.template.querySelector('.analysis-tabset');
        if (!tabset) return;
        
        try {
            // Get the internal tab nav elements
            const tabNav = tabset.shadowRoot?.querySelector('.slds-tabs_scoped__nav');
            if (tabNav) {
                tabNav.style.backgroundColor = '#f8fafd';
                tabNav.style.borderBottom = '0';
                tabNav.style.borderRadius = '8px 8px 0 0';
                tabNav.style.padding = '0.5rem 0.5rem 0 0.5rem';
                tabNav.style.border = '1px solid #eef1f6';
                tabNav.style.borderBottom = 'none';
            }
            
            // Style all tab items
            const tabItems = tabset.shadowRoot?.querySelectorAll('.slds-tabs_scoped__item');
            if (tabItems && tabItems.length) {
                tabItems.forEach(tab => {
                    tab.style.borderRadius = '0.5rem 0.5rem 0 0';
                    tab.style.margin = '0 0.25rem';
                    tab.style.border = 'none';
                    tab.style.padding = '0.75rem 1.25rem';
                    tab.style.fontWeight = '600';
                    tab.style.letterSpacing = '0.3px';
                    tab.style.backgroundColor = 'rgba(247, 249, 252, 0.6)';
                    
                    // Add hover effect using event listeners
                    tab.addEventListener('mouseenter', () => {
                        tab.style.backgroundColor = 'rgba(238, 244, 255, 0.6)';
                    });
                    tab.addEventListener('mouseleave', () => {
                        if (!tab.classList.contains('slds-is-active')) {
                            tab.style.backgroundColor = 'rgba(247, 249, 252, 0.6)';
                        }
                    });
                });
            }
            
            // Style active tab
            const activeTab = tabset.shadowRoot?.querySelector('.slds-tabs_scoped__item.slds-is-active');
            if (activeTab) {
                activeTab.style.backgroundColor = 'white';
                activeTab.style.color = '#0070d2';
                activeTab.style.boxShadow = '0 -2px 5px rgba(0, 0, 0, 0.03)';
                activeTab.style.zIndex = '1';
                
                // Create and append active indicator if it doesn't exist
                let indicator = activeTab.querySelector('.active-tab-indicator');
                if (!indicator) {
                    indicator = document.createElement('span');
                    indicator.classList.add('active-tab-indicator');
                    indicator.style.display = 'block';
                    indicator.style.position = 'absolute';
                    indicator.style.bottom = '0';
                    indicator.style.left = '0';
                    indicator.style.right = '0';
                    indicator.style.height = '3px';
                    indicator.style.background = 'linear-gradient(90deg, #0070d2, #1589ee)';
                    indicator.style.borderRadius = '3px 3px 0 0';
                    activeTab.appendChild(indicator);
                }
            }
            
            // Style tab content area
            const tabContent = tabset.shadowRoot?.querySelector('.slds-tabs_scoped__content');
            if (tabContent) {
                tabContent.style.backgroundColor = 'white';
                tabContent.style.border = '1px solid #eef1f6';
                tabContent.style.borderTop = 'none';
                tabContent.style.borderRadius = '0 0 8px 8px';
                tabContent.style.padding = '0';
                tabContent.style.boxShadow = '0 3px 6px rgba(0, 0, 0, 0.04)';
            }
        } catch (error) {
            // Silently fail if we can't access shadow DOM elements
            // console.error('Error applying tab styling:', error);
        }
    }

    /**
     * @description Check if current page is the first page
     */
    get isFirstPage() {
        return this.currentPage <= 1;
    }

    /**
     * @description Check if current page is the last page
     */
    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }

    /**
     * @description Handle navigation to first page
     */
    handleFirstPage() {
        if (!this.isFirstPage) {
            this.currentPage = 1;
            this.updateDisplayedPermissions();
            this.scrollToTop();
        }
    }

    /**
     * @description Handle navigation to previous page
     */
    handlePreviousPage() {
        if (!this.isFirstPage) {
            this.currentPage--;
            this.updateDisplayedPermissions();
            this.scrollToTop();
        }
    }

    /**
     * @description Handle navigation to next page
     */
    handleNextPage() {
        if (!this.isLastPage) {
            this.currentPage++;
            this.updateDisplayedPermissions();
            this.scrollToTop();
        }
    }

    /**
     * @description Handle navigation to last page
     */
    handleLastPage() {
        if (!this.isLastPage) {
            this.currentPage = this.totalPages;
            this.updateDisplayedPermissions();
            this.scrollToTop();
        }
    }

    /**
     * @description Scroll to the top of the item list container
     */
    scrollToTop() {
        const listContainer = this.template.querySelector('.item-list-container');
        if (listContainer) {
            listContainer.scrollTop = 0;
        }
    }

    /**
     * @description Format summary sheet with basic professional styling
     */
    formatSummarySheet(worksheet, data) {
        if (!worksheet || !data) return;

        try {
            // Set column widths
            worksheet['!cols'] = [
                { wch: 35 }, // Column A - Labels
                { wch: 25 }  // Column B - Values
            ];

            // Set row heights
            if (!worksheet['!rows']) worksheet['!rows'] = [];
            worksheet['!rows'][0] = { hpt: 25 }; // Title row height

            // Merge title cell across columns
            if (!worksheet['!merges']) worksheet['!merges'] = [];
            worksheet['!merges'].push({
                s: { c: 0, r: 0 },
                e: { c: 1, r: 0 }
            });
        
        } catch (error) {
            // console.error('Error formatting summary sheet:', error);
            // console.error('Data:', data);
        }
    }

    /**
     * @description Format data sheets with basic professional styling
     */
    formatDataSheet(worksheet, data, sheetType) {
        if (!worksheet || !data) return;

        try {
            // Set column widths based on sheet type
            const columnWidths = this.getColumnWidths(sheetType);
            worksheet['!cols'] = columnWidths;

            // Set row heights
            if (!worksheet['!rows']) worksheet['!rows'] = [];
            worksheet['!rows'][0] = { hpt: 25 }; // Header row height
        
        } catch (error) {
            // console.error('Error formatting data sheet:', error);
            // console.error('Sheet type:', sheetType);
            // console.error('Data:', data);
        }
    }

    /**
     * @description Get column widths for different sheet types
     */
    getColumnWidths(sheetType) {
        switch (sheetType) {
            case 'Profiles':
                return [
                    { wch: 30 }, // Profile Name
                    { wch: 40 }, // Description
                    { wch: 20 }, // Profile ID
                    { wch: 25 }, // License Type
                    { wch: 15 }  // Type
                ];
            case 'Permission Sets':
                return [
                    { wch: 35 }, // Label
                    { wch: 20 }, // Permission Set ID
                    { wch: 25 }, // API Name
                    { wch: 15 }, // Assignment Count
                    { wch: 18 }  // Type
                ];
            case 'Permission Set Groups':
                return [
                    { wch: 30 }, // Label
                    { wch: 20 }, // Permission Set Group ID
                    { wch: 25 }, // API Name
                    { wch: 15 }, // Assignment Count
                    { wch: 40 }, // Component Permission Sets
                    { wch: 20 }  // Type
                ];
            case 'Users':
                return [
                    { wch: 25 }, // Name
                    { wch: 20 }, // User ID
                    { wch: 25 }, // Username
                    { wch: 30 }, // Email
                    { wch: 25 }, // Profile
                    { wch: 40 }, // Permission Sources
                    { wch: 12 }  // Status
                ];
            default:
                return [{ wch: 20 }];
        }
    }

    /**
     * @description Get header color for different sheet types
     */
    getHeaderColor(sheetType) {
        switch (sheetType) {
            case 'Profiles':
                return "28A745"; // Green
            case 'Permission Sets':
                return "007BFF"; // Blue
            case 'Permission Set Groups':
                return "FFC107"; // Yellow/Orange
            case 'Users':
                return "6F42C1"; // Purple
            default:
                return "1F4E79"; // Default blue
        }
    }

    /**
     * @description Apply basic styling to workbook using Excel features
     */
    applyBasicWorkbookStyling(workbook) {
        if (!workbook || !workbook.SheetNames) return;
        
        try {
            workbook.SheetNames.forEach(sheetName => {
                const worksheet = workbook.Sheets[sheetName];
                if (!worksheet) return;
                
                // Apply auto-filter to make data more professional
                const range = worksheet['!ref'];
                if (range) {
                    worksheet['!autofilter'] = { ref: range };
                }
                
                // Freeze top row for better navigation
                worksheet['!freeze'] = { xSplit: 0, ySplit: 1 };
                
                // Add print settings for professional output
                worksheet['!margins'] = {
                    left: 0.7,
                    right: 0.7,
                    top: 0.75,
                    bottom: 0.75,
                    header: 0.3,
                    footer: 0.3
                };
                
                // Set print options
                worksheet['!printOptions'] = {
                    headings: true,
                    gridLines: true,
                    horizontalCentered: true
                };
                
                // Apply basic cell formatting where possible
                this.applyBasicCellFormatting(worksheet, sheetName);
            });
            
            // console.log('Applied basic workbook styling');
        } catch (error) {
            // console.error('Error applying basic workbook styling:', error);
        }
    }

    /**
     * @description Apply basic cell formatting that works with standard XLSX
     */
    applyBasicCellFormatting(worksheet, sheetName) {
        try {
            if (!worksheet['!ref']) return;
            
            const range = window.XLSX.utils.decode_range(worksheet['!ref']);
            
            // Format first row as header
            for (let C = range.s.c; C <= range.e.c; ++C) {
                const cell_address = window.XLSX.utils.encode_cell({ c: C, r: 0 });
                if (worksheet[cell_address]) {
                    const cell = worksheet[cell_address];
                    // Add basic styling that XLSX supports
                    if (!cell.s) cell.s = {};
                    cell.s.font = { bold: true };
                    cell.s.alignment = { horizontal: "center" };
                }
            }
            
            // Add conditional formatting for status columns if this is a Users sheet
            if (sheetName.includes('Users') || sheetName.toLowerCase().includes('user')) {
                this.addConditionalFormatting(worksheet, range);
            }
            
        } catch (error) {
            // console.error('Error applying basic cell formatting:', error);
        }
    }

    /**
     * @description Add conditional formatting for status indicators
     */
    addConditionalFormatting(worksheet, range) {
        try {
            // Find status column (usually the last column)
            for (let R = 1; R <= range.e.r; ++R) {
                for (let C = range.s.c; C <= range.e.c; ++C) {
                    const cell_address = window.XLSX.utils.encode_cell({ c: C, r: R });
                    const cell = worksheet[cell_address];
                    
                    if (cell && cell.v) {
                        const cellValue = cell.v.toString().toLowerCase();
                        
                        // Apply formatting based on content
                        if (cellValue === 'active') {
                            if (!cell.s) cell.s = {};
                            cell.s.font = { bold: true, color: { rgb: "155724" } };
                            cell.s.fill = { fgColor: { rgb: "D4EDDA" } };
                        } else if (cellValue === 'inactive') {
                            if (!cell.s) cell.s = {};
                            cell.s.font = { bold: true, color: { rgb: "721C24" } };
                            cell.s.fill = { fgColor: { rgb: "F8D7DA" } };
                        }
                    }
                }
            }
        } catch (error) {
            // console.error('Error adding conditional formatting:', error);
        }
    }

    /**
     * @description Format multiple permissions summary sheet
     */
    formatMultipleSummarySheet(worksheet, data) {
        if (!worksheet || !data) return;

        try {
            // Set column widths
            worksheet['!cols'] = [
                { wch: 40 }, // Column A - Permission/Labels
                { wch: 15 }, // Column B - Total Users
                { wch: 15 }, // Column C - Profiles
                { wch: 18 }, // Column D - Permission Sets
                { wch: 20 }  // Column E - Permission Set Groups
            ];

            // Set row heights
            if (!worksheet['!rows']) worksheet['!rows'] = [];
            worksheet['!rows'][0] = { hpt: 25 }; // Title row height

            // Merge title cell across all columns
            if (!worksheet['!merges']) worksheet['!merges'] = [];
            worksheet['!merges'].push({
                s: { c: 0, r: 0 },
                e: { c: 4, r: 0 }
            });
        
        } catch (error) {
            // console.error('Error formatting multiple summary sheet:', error);
            // console.error('Data:', data);
        }
    }

    /**
     * @description Format individual permission sheets
     */
    formatPermissionSheet(worksheet, data) {
        if (!worksheet || !data) return;

        try {
            // Set column widths
            worksheet['!cols'] = [
                { wch: 35 }, // Main column for labels and data
                { wch: 25 }, // Secondary data column
                { wch: 25 }, // Additional columns
                { wch: 25 },
                { wch: 30 },
                { wch: 15 }
            ];

            // Set row heights
            if (!worksheet['!rows']) worksheet['!rows'] = [];
            worksheet['!rows'][0] = { hpt: 25 }; // Title row height
        
        } catch (error) {
            // console.error('Error formatting permission sheet:', error);
            // console.error('Data:', data);
        }
    }

    handleIncludeAllUsersToggle(event) {
        this.includeAllUsers = event.detail.includeAll;

        if (this.includeAllUsers) {
            // Clear any individual selections
            this.selectedUserIds = ['__ALL_ACTIVE_USERS__'];
        } else {
            // Reset to none; user may select manually afterwards
            this.selectedUserIds = [];
        }
    }

    /**
     * Fetch ALL users for a permission (no artificial cap) using paginated Apex calls.
     * Warning: can be heavy in very large orgs. Should only be used when user explicitly
     * requests "Include All Active Users".
     * @param {String} permissionName
     * @param {Number} pageSize - page size per call (defaults 500, must be <= 1000 per Apex constant)
     * @returns {Promise<Object>} full permission analysis result with complete usersWithAccess
     */
    async fetchAllUsersForPermission(permissionName, pageSize = 500) {
        let pageNumber = 1;
        let aggregatedResult = null;
        let allUsers = [];

        let hasMorePages = true;
        while (hasMorePages) {
            // eslint-disable-next-line no-await-in-loop
            const result = await getSystemPermissionAccessOptimized({
                systemPermissionName: permissionName,
                userPageSize: pageSize,
                userPageNumber: pageNumber
            });

            if (!aggregatedResult) {
                aggregatedResult = { ...result };
            }

            const usersPage = result.users || result.usersWithAccess || [];
            allUsers = allUsers.concat(usersPage);

            const pag = result.userPagination || result.pagination || {};
            hasMorePages = pag.hasNext;
            if (hasMorePages) {
                pageNumber += 1;
            }
        }

        // Replace usersWithAccess and update totalUsers
        aggregatedResult.users = allUsers;
        aggregatedResult.usersWithAccess = allUsers;
        aggregatedResult.totalUsers = allUsers.length;

        // Now, if includeAllUsers flag, we need users WITHOUT the permission too.
        // Fetch every active user and merge missing ones.
        if(this.includeAllUsers){
            let page = 1;
            let lastUserId = null;
            const extraUsers = [];
            let hasMoreUsers = true;
            while(hasMoreUsers){
                // eslint-disable-next-line no-await-in-loop
                const pageRes = await getActiveUsersPaginated({pageSize: pageSize, pageNumber: page, lastUserId: lastUserId});
                const list = pageRes.users || [];
                extraUsers.push(...list);
                hasMoreUsers = pageRes.hasNext;
                if(hasMoreUsers) {
                    // Update lastUserId for cursor-based pagination
                    if(list.length > 0) {
                        lastUserId = list[list.length - 1].id;
                    }
                    page +=1;
                }
            }

            const existingIds = new Set(allUsers.map(u=>u.id));
            extraUsers.forEach(u=>{ if(!existingIds.has(u.id)){ allUsers.push(u);} });
            aggregatedResult.users = allUsers;
            aggregatedResult.usersWithAccess = allUsers;
            aggregatedResult.totalUsers = allUsers.length;
        }
        return aggregatedResult;
    }

    /*
     * Safely return the currently selected permission label (or blank) so template bindings never break
     */
    get currentPermissionLabel() {
        return this.selectedPermission && this.selectedPermission.label ? this.selectedPermission.label : '';
    }

    /**
     * @description Handle toggling dynamic fields usage
     */
    handleToggleDynamicFields(event) {
        this.useDynamicFields = event.target.checked;
        
        // console.log('Dynamic fields toggled:', this.useDynamicFields);
        
        if (this.useDynamicFields) {
            // If enabling dynamic fields and no fields are currently selected
            if (!this.selectedUserFieldsForAnalysis || this.selectedUserFieldsForAnalysis.length === 0) {
                // Use Set to prevent duplicates when setting default core fields
                const coreFieldsSet = new Set(
                    this.availableUserFields
                        .filter(field => field.isCore)
                        .map(field => field.name)
                );
                
                this.selectedUserFieldsForAnalysis = Array.from(coreFieldsSet);
                    
                // console.log('Initialized with core fields:', this.selectedUserFieldsForAnalysis);
            } else {
                // Clean existing selection to prevent duplicates
                const fieldsSet = new Set(this.selectedUserFieldsForAnalysis.filter(field => field && field.trim && field.trim().length > 0));
                this.selectedUserFieldsForAnalysis = Array.from(fieldsSet);
                // console.log('Cleaned existing selection:', this.selectedUserFieldsForAnalysis);
            }
            
            // Update the isSelected state in availableUserFields to match current selection
            this.availableUserFields = this.availableUserFields.map(field => ({
                ...field,
                isSelected: this.selectedUserFieldsForAnalysis.includes(field.name)
            }));
        } else {
            // When disabling dynamic fields, clear the dynamic fields metadata to show static table
            this.dynamicUserFields = [];
            // console.log('Dynamic fields disabled, keeping current selection for future use');
        }
        
        // Clean fields to prevent duplicates
        this.cleanSelectedFields();
        
        // Re-run analysis if we have a selected permission
        if (this.selectedPermission) {
            this.handleAnalyzeSingle();
        }
    }

    /**
     * @description Show field selector modal
     */
    handleShowFieldSelector() {
        this.showFieldSelector = true;
        this.fieldSearchTerm = '';
        this.filteredUserFields = [...this.availableUserFields];
    }

    /**
     * @description Hide field selector modal
     */
    handleCloseFieldSelector() {
        this.showFieldSelector = false;
        this.fieldSearchTerm = '';
    }

    /**
     * @description Handle search input change for field filtering
     */
    handleFieldSearch(event) {
        this.fieldSearchTerm = event.target.value.toLowerCase();
        this.filterUserFields();
    }

    /**
     * @description Filter user fields based on search term
     */
    filterUserFields() {
        if (!this.fieldSearchTerm) {
            this.filteredUserFields = [...this.availableUserFields];
        } else {
            const searchTerm = this.fieldSearchTerm.toLowerCase();
            this.filteredUserFields = this.availableUserFields.filter(field => 
                field.label.toLowerCase().includes(searchTerm) ||
                field.name.toLowerCase().includes(searchTerm) ||
                field.type.toLowerCase().includes(searchTerm) ||
                (field.description && field.description.toLowerCase().includes(searchTerm)) ||
                (field.helpText && field.helpText.toLowerCase().includes(searchTerm))
            );
        }
    }

    /**
     * @description Handle field selection change
     */
    handleUserFieldSelection(event) {
        const fieldName = event.target.dataset.field;
        const isChecked = event.target.checked;
        
        // console.log('Field selection changed:', { fieldName, isChecked });
        
        // Enforce maximum selection limit
        if (isChecked && this.selectedUserFieldsForAnalysis.length >= this.MAX_DYNAMIC_FIELDS) {
            // Revert toggle
            event.target.checked = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Field Limit Reached',
                    message: `You can select up to ${this.MAX_DYNAMIC_FIELDS} fields.`,
                    variant: 'warning'
                })
            );
            return;
        }
        
        // Update the field's isSelected state in both arrays
        this.availableUserFields = this.availableUserFields.map(field => {
            if (field.name === fieldName) {
                return { ...field, isSelected: isChecked };
            }
            return field;
        });
        
        this.filteredUserFields = this.filteredUserFields.map(field => {
            if (field.name === fieldName) {
                return { ...field, isSelected: isChecked };
            }
            return field;
        });
        
        // Use Set for guaranteed uniqueness
        const fieldsSet = new Set(this.selectedUserFieldsForAnalysis.filter(field => field));
        
        if (isChecked) {
            fieldsSet.add(fieldName); // Set automatically prevents duplicates
        } else {
            fieldsSet.delete(fieldName); // Remove from set
        }
        
        // Convert back to array
        this.selectedUserFieldsForAnalysis = Array.from(fieldsSet);
        
        // console.log('Updated selected fields:', this.selectedUserFieldsForAnalysis);
    }

    /**
     * @description Select all visible fields
     */
    handleSelectAllFields() {
        // Use Set to prevent duplicates
        const fieldsSet = new Set(this.selectedUserFieldsForAnalysis.filter(field => field));
        
        let remaining = this.MAX_DYNAMIC_FIELDS - fieldsSet.size;
        this.filteredUserFields.forEach(field => {
            if (remaining > 0 && !field.isSelected) {
                field.isSelected = true;
                fieldsSet.add(field.name);
                remaining--;
            }
        });
        if (remaining === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Field Limit Reached',
                    message: `Only the first ${this.MAX_DYNAMIC_FIELDS} fields were selected to respect the limit.`,
                    variant: 'info'
                })
            );
        }
        
        // Convert back to array with guaranteed uniqueness
        this.selectedUserFieldsForAnalysis = Array.from(fieldsSet);
        
        // Update the main array as well
        this.availableUserFields = this.availableUserFields.map(field => {
            const filteredField = this.filteredUserFields.find(f => f.name === field.name);
            if (filteredField) {
                return { ...field, isSelected: filteredField.isSelected };
            }
            return field;
        });
        
        // Force reactivity
        this.filteredUserFields = [...this.filteredUserFields];
        
        // console.log('Selected all fields, final selection:', this.selectedUserFieldsForAnalysis);
    }

    /**
     * @description Deselect all visible fields
     */
    handleDeselectAllFields() {
        // Use Set for consistent field management
        const fieldsSet = new Set(this.selectedUserFieldsForAnalysis.filter(field => field));
        
        this.filteredUserFields.forEach(field => {
            if (field.isSelected) {
                field.isSelected = false;
                fieldsSet.delete(field.name); // Remove from set
            }
        });
        
        // Convert back to array
        this.selectedUserFieldsForAnalysis = Array.from(fieldsSet);
        
        // Update the main array as well
        this.availableUserFields = this.availableUserFields.map(field => {
            const filteredField = this.filteredUserFields.find(f => f.name === field.name);
            if (filteredField) {
                return { ...field, isSelected: filteredField.isSelected };
            }
            return field;
        });
        
        // Force reactivity
        this.filteredUserFields = [...this.filteredUserFields];
        
        // console.log('Deselected all fields, final selection:', this.selectedUserFieldsForAnalysis);
    }

    /**
     * @description Apply field selection and close modal
     */
    handleApplyFieldSelection() {
        // Extra layer of protection: Use Set to ensure absolute uniqueness
        const fieldsSet = new Set(
            this.selectedUserFieldsForAnalysis
                .filter(field => field && field.trim && field.trim().length > 0)
        );
        
        this.selectedUserFieldsForAnalysis = Array.from(fieldsSet);
        
        // Clean selected fields to prevent duplicates before applying
        this.cleanSelectedFields();
        
        // Validate that at least some fields are selected
        if (this.selectedUserFieldsForAnalysis.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No Fields Selected',
                    message: 'Please select at least one field for analysis.',
                    variant: 'warning'
                })
            );
            return;
        }
        
        this.showFieldSelector = false;
        
        // console.log('Applied field selection (guaranteed unique):', this.selectedUserFieldsForAnalysis);
        
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Fields Updated',
                message: `${this.selectedUserFieldsForAnalysis.length} fields selected for analysis`,
                variant: 'success'
            })
        );

        // Re-run analysis with new field selection if we have a selected permission
        if (this.selectedPermission && this.useDynamicFields) {
            this.handleAnalyzeSingle();
        }

        if (this.selectedUserFieldsForAnalysis.length > this.MAX_DYNAMIC_FIELDS) {
            this.selectedUserFieldsForAnalysis = this.selectedUserFieldsForAnalysis.slice(0, this.MAX_DYNAMIC_FIELDS);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Field Limit Applied',
                    message: `Only the first ${this.MAX_DYNAMIC_FIELDS} selected fields will be used.`,
                    variant: 'info'
                })
            );
        }
    }

    /**
     * @description Get count of selected fields
     */
    get selectedFieldsCount() {
        return this.selectedUserFieldsForAnalysis.length;
    }

    /**
     * @description Check if a field is selected
     */
    isFieldSelected(fieldName) {
        return this.selectedUserFieldsForAnalysis.includes(fieldName);
    }

    /**
     * @description Get count of visible selected fields
     */
    get visibleSelectedCount() {
        return this.filteredUserFields.filter(field => field.isSelected).length;
    }

    /**
     * @description Get count of visible fields
     */
    get visibleFieldCount() {
        return this.filteredUserFields.length;
    }

    /**
     * @description Check if all visible fields are selected
     */
    get allVisibleSelected() {
        return this.filteredUserFields.length > 0 && 
               this.filteredUserFields.every(field => field.isSelected);
    }

    /**
     * @description Check if some visible fields are selected
     */
    get someVisibleSelected() {
        return this.filteredUserFields.some(field => field.isSelected);
    }

    /**
     * @description Check if no visible fields are selected
     */
    get noVisibleSelected() {
        return !this.filteredUserFields.some(field => field.isSelected);
    }

    // User pagination getters
    get isFirstUserPage() {
        return this.analysisUserPage <= 1;
    }

    get isLastUserPage() {
        return this.analysisUserPage >= this.analysisTotalPages;
    }

    get userPageInfo() {
        if (!this.showUserPagination) return '';
        
        const startRecord = ((this.analysisUserPage - 1) * this.analysisUserPageSize) + 1;
        const endRecord = Math.min(this.analysisUserPage * this.analysisUserPageSize, this.analysisTotalUsers);
        
        return `Showing ${startRecord}-${endRecord} of ${this.analysisTotalUsers} users`;
    }

    get userPaginationInfo() {
        if (!this.showUserPagination) return '';
        return `Page ${this.analysisUserPage} of ${this.analysisTotalPages}`;
    }

    get showUserPaginationControls() {
        return this.showUserPagination && this.analysisTotalPages > 1;
    }

    /**
     * @description Debug information for dynamic fields
     */
    get dynamicFieldsDebugInfo() {
        return {
            useDynamicFields: this.useDynamicFields,
            selectedUserFieldsForAnalysis: this.selectedUserFieldsForAnalysis,
            dynamicUserFields: this.dynamicUserFields,
            usersDataCount: this.usersData ? this.usersData.length : 0,
            firstUserProcessedFields: this.usersData && this.usersData.length > 0 ? this.usersData[0].processedFields : null
        };
    }

    /**
     * @description Getter to enable user pagination in template creation
     */
    get enableUserPagination() {
        return true;
    }

    /**
     * @description Handle load more users for pagination in template creation
     */
    handleLoadMoreUsers() {
        if (this.isLoadingUsers || !this.userHasNext) {
            return;
        }

        // console.log('Loading more users for template creation...');
        this.isLoadingUsers = true;
        
        // Load next page
        this.loadUsersPaginated(this.userCurrentPage + 1, this.userSearchTerm, this.userLastUserId);
    }

    /**
     * @description Load users with pagination for template creation
     * @param {Number} pageNumber - Page number to load
     * @param {String} searchTerm - Search term for filtering
     * @param {String} lastUserId - Last user ID for cursor-based pagination
     * @param {Boolean} reset - Whether to reset pagination
     */
    loadUsersPaginated(pageNumber = 1, searchTerm = '', lastUserId = '', reset = false) {
        // console.log('Loading users page:', pageNumber, 'searchTerm:', searchTerm, 'licenseType:', this.selectedUserLicenseType);
        
        if (reset) {
            this.userCurrentPage = 1;
            this.userLastUserId = null;
            this.users = [];
            pageNumber = 1;
            lastUserId = '';
        }
        
        this.isLoadingUsers = true;
        
        // Use license-filtered method if license type is selected
        const loadMethod = this.selectedUserLicenseType ? 
            getActiveUsersPaginatedByLicense({
                pageSize: this.userPageSize,
                pageNumber: pageNumber,
                lastUserId: lastUserId,
                licenseType: this.selectedUserLicenseType,
                searchTerm: searchTerm
            }) :
            this.getUsersPaginated(this.userPageSize, pageNumber, searchTerm, lastUserId);
        
        loadMethod
            .then(result => {
                // console.log('Loaded users page result:', result);
                
                if (pageNumber === 1 || reset) {
                    // First page - replace users and reset totalCount for selectionPanel
                    this.users = result.users.map(user => ({
                        ...user,
                        // Ensure proper format for selectionPanel
                        id: user.id,
                        name: user.name,
                        label: user.name, // Add label for selectionPanel compatibility
                        type: user.profileName || user.type,
                        isSelected: this.selectedUserIds.includes(user.id)
                    }));
                } else {
                    // Subsequent pages - append users
                    const newUsers = result.users.map(user => ({
                        ...user,
                        id: user.id,
                        name: user.name,
                        label: user.name,
                        type: user.profileName || user.type,
                        isSelected: this.selectedUserIds.includes(user.id)
                    }));
                    this.users = [...this.users, ...newUsers];
                }
                
                // Update pagination state
                this.userCurrentPage = result.pageNumber;
                this.userTotalPages = result.totalPages;
                this.userTotalCount = result.totalCount;
                this.userHasNext = result.hasNext;
                this.userHasPrevious = result.hasPrevious;
                this.userLastUserId = result.lastUserId;
                
                // console.log('Users loaded. Current page users:', result.users.length, 'Total loaded:', this.users.length, 'Total available:', this.userTotalCount);
                
                this.isLoadingUsers = false;
            })
            .catch(error => {
                // console.error('Error loading users page:', error);
                this.isLoadingUsers = false;
                
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Loading Users',
                        message: error.message || 'An error occurred while loading users.',
                        variant: 'error'
                    })
                );
            });
    }

    /**
     * @description Initialize users loading on component connection
     */
    initializeUsersForTemplate() {
        // console.log('Initializing users for template creation...');
        
        // Reset pagination state
        this.userCurrentPage = 1;
        this.userSearchTerm = '';
        this.userLastUserId = null;
        this.users = [];
        
        // Load first page of users
        this.loadUsersPaginated();
    }
}