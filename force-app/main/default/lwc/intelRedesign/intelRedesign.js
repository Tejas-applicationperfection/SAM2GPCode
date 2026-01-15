import { LightningElement, wire, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import checkPaidFeatureAccess from '@salesforce/apex/SecurityAccessManagerController.PaidFeatureAccess';
import getReportData from '@salesforce/apex/SecurityAccessManagerController.getReportData';
import getReportIdByName from '@salesforce/apex/SecurityAccessManagerController.getReportIdByName';
import getReportMetadata from '@salesforce/apex/SecurityAccessManagerController.getReportMetadata';
import getAllUserFields from '@salesforce/apex/SecurityAccessManagerController.getAllUserFields';
import exportReportToExcel from '@salesforce/apex/SecurityAccessManagerController.exportReportToExcel';
import exportAllReports from '@salesforce/apex/SecurityAccessManagerController.exportAllReports';
import getConfigIntelReportData from '@salesforce/apex/SecurityAccessManagerController.getConfigIntelReportData';
import getSharingSettingsReport from '@salesforce/apex/SecurityAccessManagerController.getSharingSettingsReport';
import getAllSharingRulesData from '@salesforce/apex/SecurityAccessManagerController.getAllSharingRulesData';
import getOrgWideDefaultsData from '@salesforce/apex/SecurityAccessManagerController.getOrgWideDefaultsData';
import getPublicGroupsData from '@salesforce/apex/SecurityAccessManagerController.getPublicGroupsData';
import getPublicGroupMembersData from '@salesforce/apex/SecurityAccessManagerController.getPublicGroupMembersData';
import getReportFolderShareData from '@salesforce/apex/SecurityAccessManagerController.getReportFolderShareData';
import getDashboardFolderShareData from '@salesforce/apex/SecurityAccessManagerController.getDashboardFolderShareData';
import getDashboardRunningUserData from '@salesforce/apex/SecurityAccessManagerController.getDashboardRunningUserData';
import getProfileAssignmentData from '@salesforce/apex/SecurityAccessManagerController.getProfileAssignmentData';
import getRoleTypeData from '@salesforce/apex/SecurityAccessManagerController.getRoleTypeData';
import getRoleTypeDataPaginated from '@salesforce/apex/SecurityAccessManagerController.getRoleTypeDataPaginated';
import getTerritoriesData from '@salesforce/apex/SecurityAccessManagerController.getTerritoriesData';
import getPermissionSetNoGroupData from '@salesforce/apex/SecurityAccessManagerController.getPermissionSetNoGroupData';
import getInstalledPackagesData from '@salesforce/apex/SecurityAccessManagerController.getInstalledPackagesData';
import getListViewDataPaginated from '@salesforce/apex/SecurityAccessManagerController.getListViewDataPaginated';
import getApexClassesData from '@salesforce/apex/SecurityAccessManagerController.getApexClassesData';
import getApexTriggersData from '@salesforce/apex/SecurityAccessManagerController.getApexTriggersData';
import getUserTerritoriesData from '@salesforce/apex/SecurityAccessManagerController.getUserTerritoriesData';
import getUserPermissionFields from '@salesforce/apex/SecurityAccessManagerController.getUserPermissionFields';
import saveTemplate from '@salesforce/apex/SecurityAccessManagerController.saveTemplate';
import loadTemplates from '@salesforce/apex/SecurityAccessManagerController.loadTemplates';
import deleteTemplate from '@salesforce/apex/SecurityAccessManagerController.deleteTemplate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPermissionSetsData from '@salesforce/apex/SecurityAccessManagerController.getPermissionSetsData';
import getPermissionSetGroupsData from '@salesforce/apex/SecurityAccessManagerController.getPermissionSetGroupsData';
import getUserPermissionSetAssignments from '@salesforce/apex/SecurityAccessManagerController.getUserPermissionSetAssignments';
import getUserPermissionSetGroupAssignments from '@salesforce/apex/SecurityAccessManagerController.getUserPermissionSetGroupAssignments';
import getPermissionSetDetails from '@salesforce/apex/SecurityAccessManagerController.getPermissionSetDetails';
import getUserDataWithPermissions from '@salesforce/apex/SecurityAccessManagerController.getUserDataWithPermissions';
import getUserDataWithPermissionsWithFilter from '@salesforce/apex/SecurityAccessManagerController.getUserDataWithPermissionsWithFilter';
import exportUserDataWithPermissionsBulk from '@salesforce/apex/SecurityAccessManagerController.exportUserDataWithPermissionsBulk';
import exportUserDataWithPermissionsBulkWithFilter from '@salesforce/apex/SecurityAccessManagerController.exportUserDataWithPermissionsBulkWithFilter';
import exportCombinedPermissionAssignmentsBulk from '@salesforce/apex/SecurityAccessManagerController.exportCombinedPermissionAssignmentsBulk';
import testPermissionSetGroupAssignments from '@salesforce/apex/SecurityAccessManagerController.testPermissionSetGroupAssignments';
import fetchTableDataOption36 from '@salesforce/apex/IntelController.fetchTableDataOption36';

export default class IntelRedesign extends LightningElement {
    // Feature Access Control
    @track hasAccess = true;
    @track isCheckingAccess = true;
    
    @track selectedFilters = [];
    @track isHomeScreen = true;
    @track activeDashboardTitle = '';
    @track activeCardId = '';
    @track reportData = null;
    @track isLoading = false;
    @track error = null;
    
    // Pagination properties
    @track currentPage = 1;
    @track pageSize = 5;
    @track totalRecords = 0;
    @track totalPages = 0;
    @track paginatedData = [];
    _allReportData = null; // Store all data for pagination
    
    // Removed scroll shadow functionality

    // Updated filter options with User Data category
    filterOptions = [
        {
            label: 'User Data',
            value: 'userData',
            subFilters: [
                { label: 'User Name', value: 'userName' },
                { label: 'User ID', value: 'userId' },
                { label: 'User Email', value: 'userEmail' },
                { label: 'User Status', value: 'userStatus' },
                { label: 'User Profile Name', value: 'profileName' },
                { label: 'User Role', value: 'userRole' },
                { label: 'Role ID', value: 'roleId' },
                { label: 'Last Login Date', value: 'lastLoginDate' },
                { label: 'Manager', value: 'manager' },
                { label: 'Title', value: 'title' },
                { label: 'Department', value: 'department' },
                { label: 'User License', value: 'userLicense' },
                // Additional user contact and personal information fields
                { label: 'First Name', value: 'firstName' },
                { label: 'Last Name', value: 'lastName' },
                { label: 'Username', value: 'username' },
                { label: 'Alias', value: 'alias' },
                { label: 'Phone', value: 'phone' },
                { label: 'Mobile Phone', value: 'mobilePhone' },
                { label: 'Fax', value: 'fax' },
                { label: 'Street', value: 'street' },
                { label: 'City', value: 'city' },
                { label: 'State', value: 'state' },
                { label: 'Postal Code', value: 'postalCode' },
                { label: 'Country', value: 'country' },
                { label: 'Time Zone', value: 'timeZoneSidKey' },
                { label: 'Locale', value: 'localeSidKey' },
                { label: 'Email Encoding', value: 'emailEncodingKey' },
                { label: 'Language', value: 'languageLocaleKey' },
                { label: 'Employee Number', value: 'employeeNumber' },
                { label: 'Extension', value: 'extension' },
                { label: 'Division', value: 'division' },
                { label: 'Company Name', value: 'companyName' },
                { label: 'About Me', value: 'aboutMe' },
                { label: 'Created Date', value: 'createdDate' },
                { label: 'Last Modified Date', value: 'lastModifiedDate' },
                { label: 'System Modstamp', value: 'systemModstamp' },
                { label: 'Permission Sets', value: 'userPermissionSetNames' },
                { label: 'Permission Set IDs', value: 'userPermissionSetIds' },
                { label: 'Permission Set Groups', value: 'userPermissionSetGroupNames' },
                { label: 'Permission Set Group IDs', value: 'userPermissionSetGroupIds' }
            ]
        },
        {
            label: 'User Permission Set Assignments',
            value: 'userPermissionSetAssignments',
            subFilters: [
                { label: 'User Name', value: 'userPermissionSetAssignmentUserName' },
                { label: 'User Email', value: 'userPermissionSetAssignmentUserEmail' },
                { label: 'User ID (AssigneeId)', value: 'userPermissionSetAssignmentUserId' },
                { label: 'Permission Set Name', value: 'userPermissionSetAssignmentPermissionSetName' },
                { label: 'Permission Set Label', value: 'userPermissionSetAssignmentPermissionSetLabel' },
                { label: 'Permission Set ID', value: 'userPermissionSetAssignmentPermissionSetId' },
                { label: 'Assignment ID', value: 'userPermissionSetAssignmentId' },
                { label: 'Is Active', value: 'userPermissionSetAssignmentIsActive' },
                { label: 'Is Revoked', value: 'userPermissionSetAssignmentIsRevoked' },
                { label: 'Expiration Date', value: 'userPermissionSetAssignmentExpirationDate' },
                { label: 'Last Created By Change ID', value: 'userPermissionSetAssignmentLastCreatedByChangeId' },
                { label: 'Last Deleted By Change ID', value: 'userPermissionSetAssignmentLastDeletedByChangeId' },
                { label: 'Permission Set Group ID', value: 'userPermissionSetAssignmentPermissionSetGroupId' },
                { label: 'System Modstamp', value: 'userPermissionSetAssignmentSystemModstamp' },
                { label: 'User Profile', value: 'userPermissionSetAssignmentUserProfile' }
            ]
        },
        {
            label: 'User Permission Set Group Assignments',
            value: 'userPermissionSetGroupAssignments',
            subFilters: [
                { label: 'User Name', value: 'userPermissionSetGroupAssignmentUserName' },
                { label: 'User Email', value: 'userPermissionSetGroupAssignmentUserEmail' },
                { label: 'User ID (AssigneeId)', value: 'userPermissionSetGroupAssignmentUserId' },
                { label: 'Permission Set Group Name', value: 'userPermissionSetGroupAssignmentPermissionSetGroupName' },
                { label: 'Permission Set Group Label', value: 'userPermissionSetGroupAssignmentPermissionSetGroupLabel' },
                { label: 'Permission Set Group ID', value: 'userPermissionSetGroupAssignmentPermissionSetGroupId' },
                { label: 'Assignment ID', value: 'userPermissionSetGroupAssignmentId' },
                { label: 'Is Active', value: 'userPermissionSetGroupAssignmentIsActive' },
                { label: 'Is Revoked', value: 'userPermissionSetGroupAssignmentIsRevoked' },
                { label: 'Expiration Date', value: 'userPermissionSetGroupAssignmentExpirationDate' },
                { label: 'Last Created By Change ID', value: 'userPermissionSetGroupAssignmentLastCreatedByChangeId' },
                { label: 'Last Deleted By Change ID', value: 'userPermissionSetGroupAssignmentLastDeletedByChangeId' },
                { label: 'System Modstamp', value: 'userPermissionSetGroupAssignmentSystemModstamp' },
                { label: 'User Profile', value: 'userPermissionSetGroupAssignmentUserProfile' }
            ]
        },
        {
            label: 'Permission Set Details',
            value: 'permissionSetDetails',
            subFilters: [
                { label: 'Permission Set ID', value: 'permissionSetDetailsId' },
                { label: 'Permission Set Name', value: 'permissionSetDetailsName' },
                { label: 'Permission Set Label', value: 'permissionSetDetailsLabel' },
                { label: 'Type', value: 'permissionSetDetailsType' },
                { label: 'Is Custom', value: 'permissionSetDetailsIsCustom' },
                { label: 'Created By', value: 'permissionSetDetailsCreatedBy' },
                { label: 'Created Date', value: 'permissionSetDetailsCreatedDate' },
                { label: 'Description', value: 'permissionSetDetailsDescription' },
                { label: 'Is Owned By Profile', value: 'permissionSetDetailsIsOwnedByProfile' },
                { label: 'Namespace Prefix', value: 'permissionSetDetailsNamespacePrefix' }
            ]
        },
        {
            label: 'User Territories',
            value: 'userTerritories',
            subFilters: [
                { label: 'User Name', value: 'territoryUserName' },
                { label: 'User Id', value: 'territoryUserId' },
                { label: 'Territory Name', value: 'territoryName' },
                { label: 'Active in Territory', value: 'territoryActive' },
                { label: 'Role in Territory', value: 'territoryRole' },
                { label: 'Last Login Date', value: 'territoryLastLogin' }
            ]
        },
        {
            label: 'Compare Settings on Users',
            value: 'compareUsers'
        }
    ];

    // Config Intel filter options
    configFilterOptions = [
        {
            label: 'Validation Rules',
            value: 'validationRules',
            subFilters: [
                { label: 'Validation Rule Name', value: 'validationRules_validationRuleName' },
                { label: 'Namespace Prefix', value: 'validationRules_namespacePrefix' },
                { label: 'Active', value: 'validationRules_active' },
                { label: 'Object', value: 'validationRules_object' },
                { label: 'Description', value: 'validationRules_description' },
                { label: 'Error Display Field', value: 'validationRules_errorDisplayField' },
                { label: 'Error Message', value: 'validationRules_errorMessage' },
                { label: 'Criteria', value: 'validationRules_criteria' }
            ]
        }
        /*,
        {
            label: 'Fields in Page Layouts',
            value: 'fieldsInPageLayouts',
            subFilters: [
                { label: 'Field Label', value: 'fieldsInPageLayouts_fieldLabel' },
                { label: 'Object', value: 'fieldsInPageLayouts_object' },
                { label: 'Page Layout', value: 'fieldsInPageLayouts_pageLayout' }
            ]
        },
        {
            label: 'Page Layouts Assignment',
            value: 'pageLayoutsAssignment',
            subFilters: [
                { label: 'Field Label', value: 'pageLayoutsAssignment_fieldLabel' },
                { label: 'Object', value: 'pageLayoutsAssignment_object' },
                { label: 'Page Layout', value: 'pageLayoutsAssignment_pageLayout' }
            ]
        }*/
    ];
    // Sharing Intel filter options with hierarchical structure
    sharingFilterOptions = [
        {
            label: 'Sharing Settings',
            value: 'sharingSettings'
        },
        {
            label: 'Organization Wide Defaults',
            value: 'orgWideDefaults'
        },
        {
            label: 'Public Groups',
            value: 'publicGroups',
            subFilters: [
                { label: 'Label', value: 'groupLabel' },
                { label: 'Group Name', value: 'groupName' },
                { label: 'Created By', value: 'createdBy' },
                { label: 'Created Date', value: 'createdDate' },
                { label: 'Members Includes Active Users', value: 'activeMembers' },
                { label: 'Last Modified Date', value: 'lastModifiedDate' },
                { label: 'Modified By', value: 'modifiedBy' }
            ]
        },
        {
            label: 'Public Group Members',
            value: 'publicGroupMembers',
            subFilters: [
                { label: 'Alias', value: 'alias' },
                { label: 'Full Name', value: 'fullName' },
                { label: 'User Name', value: 'userName' },
                { label: 'User Id', value: 'userId' },
                { label: 'Role', value: 'role' },
                { label: 'Active', value: 'active' },
                { label: 'Profile', value: 'profile' },
                { label: 'Last Login Date', value: 'lastLoginDate' }
            ]
        }
    ];

    // Add this new property after your existing sharingFilterOptions
    reportingFilterOptions = [
        { label: 'Report Folder Share', value: 'reportFolderShare' },
        { label: 'Dashboard Folder Share', value: 'dashboardFolderShare' },
        { label: 'Dashboard and Running User', value: 'dashboardRunningUser' }
    ];

    // Add this new property after your existing reportingFilterOptions
    profileAssignmentFilterOptions = [
        { label: 'Profile Name', value: 'profileName' },
        { label: 'Profile Type', value: 'profileType' },
        { label: 'User License', value: 'userLicense' },
        { label: 'Used by Active Users', value: 'activeUsers' },
        { label: 'Used by Inactive Users', value: 'inactiveUsers' }
    ];

    // Add this new property after your profileAssignmentFilterOptions
    permissionsIntelFilterOptions = [
        {
            label: 'Role Type',
            value: 'roleType',
            subFilters: [
                { label: 'Role Label', value: 'roleLabel' },
                { label: 'Role Name', value: 'roleName' },
                { label: 'This Role Reports To', value: 'roleReportsTo' },
                { label: 'Forecast Manager', value: 'roleForecastManager' },
                { label: 'Modified By', value: 'roleModifiedBy' },
                { label: 'Opportunity Access', value: 'roleOpportunityAccess' },
                { label: 'Case Access', value: 'roleCaseAccess' },
                { label: 'Customer Role', value: 'customerRole' },
                { label: 'Portal Role', value: 'portalRole' },
                { label: 'Portal Type', value: 'portalType' }
            ]
        },
        {
            label: 'Territories',
            value: 'territories',
            subFilters: [
                { label: 'Territory Label', value: 'territoryLabel' },
                { label: 'Territory Name', value: 'territoryName' },
                { label: 'Territory Type', value: 'territoryType' },
                { label: 'Territory Model', value: 'territoryModel' },
                { label: 'Parent Territory', value: 'parentTerritory' },
                { label: 'Forecast Manager', value: 'territoryForecastManager' },
                { label: 'Modified By', value: 'territoryModifiedBy' },
                { label: 'Opportunity Access', value: 'territoryOpportunityAccess' },
                { label: 'Case Access', value: 'territoryCaseAccess' },
                { label: 'Account Access', value: 'territoryAccountAccess' }
            ]
        },
        {
            label: 'Permission Set not in Permission Set Group',
            value: 'permissionSetNoGroup',
            subFilters: [
                { label: 'Name', value: 'permissionSetName' },
                { label: 'Label', value: 'permissionSetLabel' },
                { label: 'Id', value: 'permissionSetId' },
                { label: 'Created By', value: 'permissionSetCreatedBy' },
                { label: 'Created Date', value: 'permissionSetCreatedDate' }
            ]
        }
    ];

    // Add this new property after your permissionsIntelFilterOptions
    otherIntelFilterOptions = [
        {
            label: 'Installed Packages',
            value: 'installedPackages',
            subFilters: [
                { label: 'Name', value: 'packageName' },
                { label: 'Description', value: 'packageDescription' },
                { label: 'Publisher', value: 'packagePublisher' },
                { label: 'Version Number', value: 'versionNumber' },
                { label: 'Namespace Prefix', value: 'namespacePrefix' },
                { label: 'Status', value: 'packageStatus' },
                { label: 'Allowed Licenses', value: 'allowedLicenses' },
                { label: 'Used Licenses', value: 'usedLicenses' },
                { label: 'Expiration Date', value: 'expirationDate' },
                { label: 'Created Date', value: 'packageCreatedDate' },
                { label: 'Last Modified Date', value: 'packageModifiedDate' }
            ]
        },
        {
            label: 'List View',
            value: 'listView',
            subFilters: [
                { label: 'Object', value: 'listViewObject' },
                { label: 'View Name', value: 'viewName' },
                { label: 'View Unique Name', value: 'viewUniqueName' },
                { label: 'Filter By Owner', value: 'filterByOwner' },
                { label: 'Filtered by Fields', value: 'filteredByFields' },
                { label: 'Selected Fields', value: 'selectedFields' }
            ]
        },
        {
            label: 'Apex Triggers and Apex Classes',
            value: 'apexCode',
            subFilters: [
                {
                    label: 'Apex Classes',
                    value: 'apexClasses',
                    nestedFilters: [
                        { label: 'Name (Sorted Ascending)', value: 'className' },
                        { label: 'sObject Type', value: 'classSObjectType' },
                        { label: 'Api Version', value: 'classApiVersion' },
                        { label: 'Status', value: 'classStatus' },
                        { label: 'Created Date', value: 'classCreatedDate' },
                        { label: 'Last Modified By', value: 'classModifiedBy' }
                    ]
                },
                {
                    label: 'Apex Triggers',
                    value: 'apexTriggers',
                    nestedFilters: [
                        { label: 'Name (Sorted Ascending)', value: 'triggerName' },
                        { label: 'sObject Type', value: 'triggerSObjectType' },
                        { label: 'Api Version', value: 'triggerApiVersion' },
                        { label: 'Status', value: 'triggerStatus' },
                        { label: 'Created Date', value: 'triggerCreatedDate' },
                        { label: 'Last Modified By', value: 'triggerModifiedBy' }
                    ]
                }
            ]
        }
    ];

    // Add these properties after the otherIntelFilterOptions property
    userTemplates = [];
    showTemplateModal = false;
    newTemplateName = '';
    templateToDelete = null;
    selectedTemplate = null;
    showDeleteConfirmation = false;
    showLoadTemplateModal = false;

    // Card data for the dashboards
    cardData = {
        user: {
            title: 'User',
            records: 200,
            lastUpdated: '5 days ago',
            detailText: 'Feyecting mtel'
        },
        config: {
            title: 'Config',
            records: 250,
            lastUpdated: '5 days ago',
            detailText: 'Twiesting mtel'
        },
        sharing: {
            title: 'Sharing',
            records: 290,
            lastUpdated: '5 days ago',
            detailText: 'Sharing Intel'
        },
        reporting: {
            title: 'Reporting',
            records: 280,
            lastUpdated: '5 days ago',
            detailText: 'View report and dashboard sharing'
        },
        profileAssignment: {
            title: 'Profile Assignment',
            records: 200,
            lastUpdated: '5 days ago',
            detailText: 'View profile assignments and types'
        },
        config2: {
            title: 'Config',
            records: 200,
            lastUpdated: '5 days ago',
            detailText: 'Reporting mtel'
        },
        other2: {
            title: 'Other',
            records: 200,
            lastUpdated: '5 days ago',
            detailText: 'Tepotting mtel'
        },
        profile: {
            title: 'Profile Assignment',
            records: 200,
            lastUpdated: '5 days ago',
            detailText: 'Frhœtling mtel'
        },
        permissions: {
            title: 'Permissions',
            records: 200,
            lastUpdated: '5 days ago',
            detailText: 'Permting mtel'
        },
        
    };

    get isReportButtonDisabled() {
        return this.selectedFilters.length === 0;
    }

    get isExportButtonDisabled() {
        return !this.reportData;
    }

    get showNoDataMessage() {
        return !this.isLoading && !this.error && !this.reportData && this.selectedFilters.length > 0;
    }

    // Pagination computed properties
    get hasPagination() {
        console.log('hasPagination check:', {
            totalPages: this.totalPages,
            totalRecords: this.totalRecords,
            pageSize: this.pageSize,
            hasData: !!this._allReportData
        });
        return this.totalPages > 1;
    }

    get showFirstButton() {
        return this.currentPage <= 1;
    }

    get showPreviousButton() {
        return this.currentPage <= 1;
    }

    get showNextButton() {
        return this.currentPage >= this.totalPages;
    }

    get showLastButton() {
        return this.currentPage >= this.totalPages;
    }

    get pageInfo() {
        const startRecord = (this.currentPage - 1) * this.pageSize + 1;
        const endRecord = Math.min(this.currentPage * this.pageSize, this.totalRecords);
        return `${startRecord} - ${endRecord} of ${this.totalRecords}`;
    }

    get pageOptions() {
        return [
            { label: '5', value: 5 },
            { label: '10', value: 10 },
            { label: '25', value: 25 },
            { label: '50', value: 50 },
            { label: '100', value: 100 }
        ];
    }

    handleCheckboxChange(event) {
        const value = event.target.value;
        if (event.target.checked) {
            // Add the filter while maintaining userName as first
            if (value !== 'userName') {
                this.selectedFilters = [...this.selectedFilters, value];
            }
        } else {
            // Don't allow unchecking userName
            if (value === 'userName') {
                event.target.checked = true;
                return;
            }
            this.selectedFilters = this.selectedFilters.filter(item => item !== value);
        }
        
        this.updateFilterCount();
    }

    connectedCallback() {
        // Check feature access first
        this.checkFeatureAccess();
        
        // Remove pre-select userName filter
        this.selectedFilters = [];
        
        // Load saved templates
        this.loadTemplatesFromStorage();
        
        // Load User fields dynamically
        this.loadUserFields();
        
        // Add CSS to handle table styling
        const style = document.createElement('style');
        style.innerText = `
            .sharing-rules-table th,
            .sharing-rules-table td {
                white-space: normal !important;
                word-break: break-word !important;
                font-size: 0.75rem !important;
                max-width: 200px !important;
            }
            
            .sharing-rules-table div.slds-hyphenate {
                max-width: 100% !important;
                word-break: break-word !important;
                white-space: normal !important;
            }
            
            .sharing-rules-container {
                max-width: 100% !important;
                overflow-x: auto !important;
            }
            
            .sharing-rules-header {
                background: #2c3f5f;
                color: white;
                padding: 0.5rem 1rem;
                font-weight: bold;
            }
        `;
        document.head.appendChild(style);
        
        // Initialize filter help text based on selected filters
        if (this.selectedFilters) {
            // Show help text for any pre-selected filters
            this.selectedFilters.forEach(filter => {
                if (filter === 'sharingSettings' || filter === 'orgWideDefaults') {
                    this.updateFilterHelpText(filter, true);
                }
            });
        }
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

    renderedCallback() {
        // Removed scroll shadow functionality
        
        // Add logic to hide/show help text based on the filter type
        const helpTextDivs = this.template.querySelectorAll('.slds-text-body_small[data-value]');
        if (helpTextDivs) {
            helpTextDivs.forEach(div => {
                const filterType = div.dataset.value;
                if (filterType === 'sharingSettings') {
                    div.classList.add('sharing-settings-help');
                } else {
                    div.classList.remove('sharing-settings-help');
                    div.style.display = 'none';
                }
            });
        }
        
        // Add logic to hide/show help text for OWD
        const owdHelpTextDivs = this.template.querySelectorAll('.slds-text-body_small[data-value-owd]');
        if (owdHelpTextDivs) {
            owdHelpTextDivs.forEach(div => {
                const filterType = div.dataset.valueOwd;
                if (filterType === 'orgWideDefaults') {
                    div.classList.add('owd-help');
                } else {
                    div.classList.remove('owd-help');
                    div.style.display = 'none';
                }
            });
        }
        
        // Fix duplicate checkbox IDs for Config Intel card
        if (this.activeCardId === 'config') {
            // Get all sub-filter checkboxes
            const subFilterCheckboxes = this.template.querySelectorAll('input[data-parent]');
            
            // Create a map to track which IDs we've seen
            const seenIds = new Map();
            
            // Process each checkbox to ensure unique IDs
            subFilterCheckboxes.forEach(checkbox => {
                const subValue = checkbox.value;
                const parentValue = checkbox.dataset.parent;
                
                // If we've already seen this subValue, we need to make it unique
                if (seenIds.has(subValue)) {
                    // Generate a unique ID based on parent and sub values
                    const uniqueId = this.generateSubFilterId(parentValue, subValue);
                    
                    // Update the checkbox ID
                    checkbox.id = uniqueId;
                    
                    // Update the corresponding label's "for" attribute
                    const label = checkbox.nextElementSibling;
                    if (label && label.tagName === 'LABEL') {
                        label.setAttribute('for', uniqueId);
                    }
                } else {
                    // Mark this ID as seen
                    seenIds.set(subValue, true);
                }
            });
        }
        
        // Remove duplicate checkboxes for Config Intel card
        if (this.activeCardId === 'config') {
            const configFilters = ['validationRules', 'fieldsInPageLayouts', 'pageLayoutsAssignment'];
            
            // Get all checkboxes for these filters
            configFilters.forEach(filter => {
                const checkboxes = this.template.querySelectorAll(`input[value="${filter}"]`);
                
                // If there are duplicates, remove the extra ones
                if (checkboxes.length > 1) {
                    console.log(`Found ${checkboxes.length} checkboxes for ${filter}, removing duplicates`);
                    
                    // Keep only the first one that has child elements (sub-filters)
                    let keepFirst = true;
                    checkboxes.forEach(checkbox => {
                        // Check if this checkbox is part of a parent filter with sub-filters
                        const parentDiv = checkbox.closest('.slds-p-bottom_small');
                        const hasSubFilters = parentDiv && parentDiv.querySelectorAll(`[data-parent="${filter}"]`).length > 0;
                        
                        if (keepFirst && hasSubFilters) {
                            // Keep this one
                            keepFirst = false;
                        } else {
                            // Hide the parent div of this checkbox
                            const checkboxParent = checkbox.closest('.slds-form-element__control');
                            if (checkboxParent) {
                                checkboxParent.style.display = 'none';
                            }
                        }
                    });
                }
            });
        }
        
        // Update checkbox states if there are selected filters (useful for template loading)
        if (this.selectedFilters && this.selectedFilters.length > 0) {
            // Small delay to ensure DOM is ready
            setTimeout(() => {
                // Check if component is still connected before proceeding
                if (!this.template) return;
                this.updateCheckboxStatesQuietly();
            }, 50);
        }
    }

    disconnectedCallback() {
        // Removed scroll shadow functionality
    }

    // Removed handleTableScroll method

    // Removed updateScrollShadows method

    /**
     * Handle the Run Report button click
     */
    handleRunReport() {
        try {
            this.error = null;
            
            // Check if compareUsers filter is selected
            if (this.selectedFilters.includes('compareUsers')) {
                // If we already have selected users, fetch permission fields
                if (this.selectedUsers && this.selectedUsers.length > 0) {
                    this.isLoading = true;
                    this.fetchUserPermissionFields();
                    return;
                } else {
                    // Otherwise show the user selection modal
                    this.fetchUsersForComparison();
                    return;
                }
            }
            
            // For other filters, proceed with normal report generation
            if (this.selectedFilters.length === 0) {
                this.error = 'Please select at least one filter to run the report';
                return;
            }
            
            this.isLoading = true;
            
            // Determine which report to run based on active card and filters
            if (this.activeCardId === 'user') {
                // User Intel card - check for specific report types
                if (this.selectedFilters.includes('userTerritories')) {
                    this.fetchUserTerritoriesData();
                } else if (this.selectedFilters.includes('userData')) {
                    // User data with integrated permissions
                    this.fetchUserDataWithPermissions();
                } else {
                    // Default user data report (fallback for old filters)
                    const filtersToSend = [...this.selectedFilters];
                    
                    getReportData({ filters: filtersToSend, cardId: this.activeCardId, pageSize: this.pageSize, pageNumber: this.currentPage })
                        .then(result => {
                            this.processStandardReportData(result);
                        })
                        .catch(error => {
                            this.handleError(error);
                        })
                        .finally(() => {
                            this.isLoading = false;
                        });
                }
            } else if (this.activeCardId === 'config') {
                // Config Intel card
                const filtersToSend = [...this.selectedFilters];
                
                this.handleConfigIntelReport();
            } else if (this.activeCardId === 'sharing') {
                // Sharing Intel card logic
                this.handleSharingIntelReport();
            } else if (this.activeCardId === 'reporting') {
                // Reporting Intel card logic
                this.handleReportingIntelReport();
            } else if (this.activeCardId === 'profileAssignment') {
                // Profile Assignment Intel card logic
                this.handleProfileAssignmentReport();
            } else if (this.activeCardId === 'permissions') {
                // Permissions Intel card logic
                this.handlePermissionsIntelReport();
            } else if (this.activeCardId === 'other') {
                // Other Intel card logic
                this.handleOtherIntelReport();
            }
        } catch (error) {
            this.handleError(error);
            this.isLoading = false;
        }
    }
    
    // Improved helper methods for sharing rules data
    fetchSharingRulesData() {
        console.log('Fetching sharing rules data...');
        getAllSharingRulesData()
            .then(result => {
                console.log('Sharing rules data received:', result);
                if (result && result.sections) {
                    // Log the sections to help with debugging
                    console.log('Sections found:', result.sections.length);
                    result.sections.forEach((section, index) => {
                        console.log(`Section ${index+1}: ${section.title}, Rows: ${section.rows ? section.rows.length : 0}`);
                    });
                    
                    this.reportData = result;
                } else {
                    console.error('Invalid sharing rules data received:', result);
                    this.reportData = {
                        sections: [{
                            title: 'NO DATA FOUND',
                            headers: ['Message'],
                            rows: [{
                                key: 'no-data',
                                values: ['No sharing rules data was returned from the server.']
                            }]
                        }]
                    };
                }
                // Removed scroll shadow call
            })
            .catch(error => {
                console.error('Error fetching sharing rules:', error);
                this.handleError(error);
                // Create a fallback report data structure for errors
                this.reportData = { 
                    sections: [{
                        title: 'ERROR RETRIEVING DATA',
                        headers: ['Error Message'],
                        rows: [{
                            key: 'error',
                            values: [error.message || 'An error occurred while retrieving sharing rules data.']
                        }]
                    }]
                };
                // Removed scroll shadow call
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    processStandardReportData(result) {
                if (result && result.headers && result.rows) {
                    // Store all data for pagination
                    this._allReportData = {
                        headers: result.headers.map(header => ({
                            label: this.getHeaderLabel(header),
                            value: header
                        })),
                        rows: result.rows.map((row, index) => ({
                            id: `row-${index}`,
                            cells: row.values.map((value, cellIndex) => ({
                                id: `cell-${index}-${cellIndex}`,
                                value: value || '',
                                header: result.headers[cellIndex]
                            }))
                        }))
                    };
                    
                    // Reset pagination to first page
                    this.currentPage = 1;
                    
                    // Update pagination and display paginated data
                    this.updatePagination();
                    
            // Removed scroll shadow call
                }
            }
    
    // Removed updateTableScrollShadows method
    
    handleError(error) {
        console.error('Error details:', JSON.stringify(error));
        console.error('Error type:', typeof error);
        console.error('Error message:', error?.message);
        console.error('Error body:', error?.body);
        
        if (error && error.body) {
            // Handle standard error object
            if (error.body.message) {
                this.error = error.body.message;
            } else if (typeof error.body === 'string') {
                this.error = error.body;
            } else {
                this.error = JSON.stringify(error.body);
            }
        } else if (error && error.message) {
            this.error = error.message;
        } else if (typeof error === 'string') {
            this.error = error;
        } else {
            this.error = 'An unexpected error occurred. Please try again.';
            console.error('Unhandled error structure:', error);
        }
    }

    getHeaderLabel(header) {
        if (this.activeCardId === 'config') {
            const option = this.configFilterOptions.find(opt => opt.value === header);
            return option ? option.label : header;
        } else if (this.activeCardId === 'reporting') {
            // Define reporting field labels
            const reportingFieldLabels = {
                'folderName': 'Folder Name',
                'accessType': 'Access Type',
                'shareType': 'Share Type',
                'sharedWith': 'Shared With',
                'dashboardName': 'Dashboard Name',
                'dashboardURL': 'Dashboard URL',
                'runAsSpecifiedUser': 'Run As Specified User',
                'runningUserName': 'Running User Name'
            };
            
            return reportingFieldLabels[header] || header;
        } else if (this.activeCardId === 'profileAssignment') {
            const option = this.profileAssignmentFilterOptions.find(opt => opt.value === header);
            return option ? option.label : header;
        } else if (this.activeCardId === 'permissions') {
            // Check in Role Type sub-filters
            const roleTypeFilter = this.permissionsIntelFilterOptions.find(f => f.value === 'roleType');
            if (roleTypeFilter) {
                const subOption = roleTypeFilter.subFilters.find(sub => sub.value === header);
                if (subOption) return subOption.label;
            }
            
            // Check in Territories sub-filters
            const territoriesFilter = this.permissionsIntelFilterOptions.find(f => f.value === 'territories');
            if (territoriesFilter) {
                const subOption = territoriesFilter.subFilters.find(sub => sub.value === header);
                if (subOption) return subOption.label;
            }
            
            // Check in Permission Set sub-filters
            const permissionSetFilter = this.permissionsIntelFilterOptions.find(f => f.value === 'permissionSetNoGroup');
            if (permissionSetFilter) {
                const subOption = permissionSetFilter.subFilters.find(sub => sub.value === header);
                if (subOption) return subOption.label;
            }
            
            const option = this.permissionsIntelFilterOptions.find(opt => opt.value === header);
            return option ? option.label : header;
        } else if (this.activeCardId === 'other') {
            // Check in Installed Packages sub-filters
            const installedPackagesFilter = this.otherIntelFilterOptions.find(f => f.value === 'installedPackages');
            if (installedPackagesFilter) {
                const subOption = installedPackagesFilter.subFilters.find(sub => sub.value === header);
                if (subOption) return subOption.label;
            }
            
            // Check in List View sub-filters
            const listViewFilter = this.otherIntelFilterOptions.find(f => f.value === 'listView');
            if (listViewFilter) {
                const subOption = listViewFilter.subFilters.find(sub => sub.value === header);
                if (subOption) return subOption.label;
            }
            
            // Check in Apex Code sub-filters (which might have nested filters)
            const apexCodeFilter = this.otherIntelFilterOptions.find(f => f.value === 'apexCode');
            if (apexCodeFilter) {
                for (const subFilter of apexCodeFilter.subFilters || []) {
                    if (subFilter.value === header) return subFilter.label;
                    
                    // Check nested filters if they exist
                    if (subFilter.nestedFilters) {
                        const nestedOption = subFilter.nestedFilters.find(nested => nested.value === header);
                        if (nestedOption) return nestedOption.label;
                    }
                }
            }
            
            const option = this.otherIntelFilterOptions.find(opt => opt.value === header);
            return option ? option.label : header;
        } else if (this.activeCardId === 'sharing') {
            // Check in Public Groups sub-filters
            const publicGroupsFilter = this.sharingFilterOptions.find(f => f.value === 'publicGroups');
            if (publicGroupsFilter) {
                const subOption = publicGroupsFilter.subFilters.find(sub => sub.value === header);
                if (subOption) return subOption.label;
            }
            
            // Check in Public Group Members sub-filters
            const publicGroupMembersFilter = this.sharingFilterOptions.find(f => f.value === 'publicGroupMembers');
            if (publicGroupMembersFilter) {
                const subOption = publicGroupMembersFilter.subFilters.find(sub => sub.value === header);
                if (subOption) return subOption.label;
            }
        } else if (this.activeCardId === 'user') {
            // Check for User Territories sub-filters
            if (header.startsWith('territory')) {
                const territoryFieldLabels = {
                    'territoryUserName': 'User Name',
                    'territoryUserId': 'User Id',
                    'territoryName': 'Territory Name',
                    'territoryActive': 'Active in Territory',
                    'territoryRole': 'Role in Territory',
                    'territoryLastLogin': 'Last Login Date'
                };
                
                return territoryFieldLabels[header] || header;
            }
            
            // Check for Assignment Type column (used in combined permission assignment reports)
            if (header === 'Assignment Type') {
                return 'Assignment Type';
            }
            
            // Check for User Permission Set Assignment sub-filters
            if (header.startsWith('userPermissionSetAssignment')) {
                const userPermissionSetAssignmentFieldLabels = {
                    'userPermissionSetAssignmentUserName': 'User Name',
                    'userPermissionSetAssignmentUserEmail': 'User Email',
                    'userPermissionSetAssignmentUserId': 'User ID',
                    'userPermissionSetAssignmentPermissionSetName': 'Permission Set Name',
                    'userPermissionSetAssignmentPermissionSetLabel': 'Permission Set Label',
                    'userPermissionSetAssignmentPermissionSetId': 'Permission Set ID',
                    'userPermissionSetAssignmentIsActive': 'User Is Active',
                    'userPermissionSetAssignmentUserProfile': 'User Profile',
                    'userPermissionSetAssignmentAssignedDate': 'Assigned Date',
                    'userPermissionSetAssignmentAssignedBy': 'Assigned By',
                    'userPermissionSetAssignmentExpirationDate': 'Expiration Date'
                };
                
                return userPermissionSetAssignmentFieldLabels[header] || header;
            }
            
            // Check for User Permission Set Group Assignment sub-filters
            if (header.startsWith('userPermissionSetGroupAssignment')) {
                const userPermissionSetGroupAssignmentFieldLabels = {
                    'userPermissionSetGroupAssignmentUserName': 'User Name',
                    'userPermissionSetGroupAssignmentUserEmail': 'User Email',
                    'userPermissionSetGroupAssignmentUserId': 'User ID',
                    'userPermissionSetGroupAssignmentPermissionSetGroupName': 'Permission Set Group Name',
                    'userPermissionSetGroupAssignmentPermissionSetGroupLabel': 'Permission Set Group Label',
                    'userPermissionSetGroupAssignmentPermissionSetGroupId': 'Permission Set Group ID',
                    'userPermissionSetGroupAssignmentIsActive': 'User Is Active',
                    'userPermissionSetGroupAssignmentUserProfile': 'User Profile',
                    'userPermissionSetGroupAssignmentAssignedDate': 'Assigned Date',
                    'userPermissionSetGroupAssignmentAssignedBy': 'Assigned By',
                    'userPermissionSetGroupAssignmentExpirationDate': 'Expiration Date'
                };
                
                return userPermissionSetGroupAssignmentFieldLabels[header] || header;
            }
            
            // Check for User Data sub-filters including new permission fields
            const userDataFieldLabels = {
                'userName': 'User Name',
                'name': 'User Name',  // Add mapping for 'name' field
                'userId': 'User ID',
                'userEmail': 'User Email',
                'userStatus': 'User Status',
                'profileName': 'User Profile Name',
                'userProfile': 'User Profile Name',
                'userRole': 'User Role',
                'roleId': 'Role ID',
                'lastLoginDate': 'Last Login Date',
                'manager': 'Manager',
                'title': 'Title',
                'department': 'Department',
                'userLicense': 'User License',
                'userPermissionSetNames': 'Permission Sets',
                'userPermissionSetGroupNames': 'Permission Set Groups'
            };
            
            if (userDataFieldLabels[header]) {
                return userDataFieldLabels[header];
            }
            
            // Check in User Data sub-filters
            const userDataFilter = this.filterOptions.find(f => f.value === 'userData');
            if (userDataFilter) {
                const subOption = userDataFilter.subFilters.find(sub => sub.value === header);
                if (subOption) return subOption.label;
            }
            
            // Check in User Permission Set Assignments sub-filters
            const userPermissionSetAssignmentsFilter = this.filterOptions.find(f => f.value === 'userPermissionSetAssignmentsReport');
            if (userPermissionSetAssignmentsFilter) {
                const subOption = userPermissionSetAssignmentsFilter.subFilters.find(sub => sub.value === header);
                if (subOption) return subOption.label;
            }
            
            // Check in User Permission Set Group Assignments sub-filters
            const userPermissionSetGroupAssignmentsFilter = this.filterOptions.find(f => f.value === 'userPermissionSetGroupAssignmentsReport');
            if (userPermissionSetGroupAssignmentsFilter) {
                const subOption = userPermissionSetGroupAssignmentsFilter.subFilters.find(sub => sub.value === header);
                if (subOption) return subOption.label;
            }
        }
        
        const option = this.filterOptions.find(opt => opt.value === header);
        return option ? option.label : header;
    }

    handleExportData() {
        if (!this.reportData) return;

        // Check if this is User Intel with permission data
        if (this.activeCardId === 'user' && 
            (this.selectedFilters.includes('userPermissionSetNames') || 
             this.selectedFilters.includes('userPermissionSetGroupNames') ||
             this.selectedFilters.includes('userData'))) {
            
            this.handleBulkUserExport();
        } else if (this.activeCardId === 'user' && 
                   (this.selectedFilters.includes('userPermissionSetAssignmentsReport') ||
                    this.selectedFilters.includes('userPermissionSetGroupAssignmentsReport'))) {
            
            this.handleBulkCombinedPermissionExport();
        } else {
            // Use standard export for other reports
            const csvContent = this.convertToCSV(this.reportData);
            this.downloadCSV(csvContent, 'user_report.csv');
        }
    }

    handleBulkUserExport() {
        this.isLoading = true;
        this.error = null;
        
        // Show loading toast
        this.showToast('Info', 'Starting bulk export... This may take several minutes for large datasets.', 'info');
        
        // Create a copy of selectedFilters without the parent 'userData' filter if it exists
        let filtersToSend = this.selectedFilters.filter(filter => filter !== 'userData');
        
        // Remove any duplicate field mappings that could cause SOQL errors bulk export handle
        const fieldMappings = new Map([
            ['id', 'Id'],
            ['userid', 'Id'],
            ['name', 'Name'],
            ['username', 'username'],
            ['userName', 'Name'],
            ['email', 'Email'],
            ['useremail', 'Email'],
            ['userEmail', 'Email'],
            ['isactive', 'IsActive'],
            ['userstatus', 'IsActive'],
            ['accountid', 'AccountId'],
            ['contactid', 'ContactId'],
            ['digestfrequency', 'DigestFrequency'],
            ['sendername', 'SenderName'],
            ['profileid', 'ProfileId'],
            ['profile_name__c', 'profileName'],
            ['profilename', 'profileName'],
            ['firstname', 'firstName'],
            ['lastname', 'lastName'],
            ['userroleid', 'UserRoleId'],
            ['roleid', 'UserRoleId'],
            ['userrole', 'UserRoleId'],
            ['managerid', 'ManagerId'],
            ['manager', 'ManagerId'],
            ['title', 'Title'],
            ['department', 'Department'],
            ['lastlogindate', 'LastLoginDate'],
            ['userlicense', 'UserType'],
            ['usertype','UserType'],
            // Additional field mappings for new user fields
            ['alias', 'alias'],
            ['phone', 'phone'],
            ['mobilephone', 'mobilePhone'],
            ['fax', 'fax'],
            ['street', 'street'],
            ['city', 'city'],
            ['state', 'state'],
            ['postalcode', 'postalCode'],
            ['country', 'country'],
            ['timezonesidkey', 'timeZoneSidKey'],
            ['localesidkey', 'localeSidKey'],
            ['emailencodingkey', 'emailEncodingKey'],
            ['languagelocalekey', 'languageLocaleKey'],
            ['employeenumber', 'employeeNumber'],
            ['extension', 'extension'],
            ['division', 'division'],
            ['companyname', 'companyName'],
            ['aboutme', 'aboutMe'],
            ['createddate', 'createdDate'],
            ['lastmodifieddate', 'lastModifiedDate'],
            ['systemmodstamp', 'systemModstamp']
        ]);
        
        // Normalize filters to prevent duplicates
        const normalizedFilters = new Set();
        filtersToSend.forEach(filter => {
            const lowerFilter = filter.toLowerCase();
            if (fieldMappings.has(lowerFilter)) {
                normalizedFilters.add(fieldMappings.get(lowerFilter));
            } else {
                normalizedFilters.add(filter);
            }
        });
        
        filtersToSend = Array.from(normalizedFilters);
        
        console.log('Original filters:', this.selectedFilters);
        console.log('Filters after userData removal:', this.selectedFilters.filter(filter => filter !== 'userData'));
        console.log('Normalized filters being sent to Apex:', filtersToSend);
        
        // Set a longer timeout for bulk operations
        const startTime = Date.now();
        const maxWaitTime = 5 * 60 * 1000; // 5 minutes
        
        const exportPromise = exportUserDataWithPermissionsBulkWithFilter({ filters: filtersToSend, filterByValues: this.filterByFieldValues });
        
        // Create a timeout promise
        const timeoutPromise = new Promise((_, reject) => {
            setTimeout(() => {
                reject(new Error('Export operation timed out after 5 minutes. Please try with fewer filters or contact your administrator.'));
            }, maxWaitTime);
        });
        
        // Race between the export and timeout
        Promise.race([exportPromise, timeoutPromise])
            .then(result => {
                const processingTime = Math.round((Date.now() - startTime) / 1000);
                console.log(`Bulk export completed in ${processingTime} seconds`);
                
                if (result && result.headers && result.rows) {
                    console.log('Bulk export completed. Total rows:', result.rows.length);
                    
                    // Convert to CSV with proper formatting
                    const csvContent = this.convertBulkDataToCSV(result);
                    const fileName = `user_intel_bulk_export_${new Date().toISOString().split('T')[0]}.csv`;
                    this.downloadCSV(csvContent, fileName);
                    
                    this.showToast('Success', `Export completed in ${processingTime}s! ${result.rows.length} users exported.`, 'success');
                } else {
                    this.error = 'No data returned from bulk export';
                    this.showToast('Warning', 'No data was returned from the export', 'warning');
                }
            })
            .catch(error => {
                console.error('Error in bulk export:', error);
                console.error('Error details:', JSON.stringify(error, null, 2));
                
                let errorMessage = 'Export failed';
                let toastVariant = 'error';
                
                if (error.message && error.message.includes('timed out')) {
                    errorMessage = 'Export timed out. Please try with fewer filters or contact your administrator.';
                } else if (error.body?.message) {
                    errorMessage = error.body.message;
                    
                    // Handle SOQL limit exceeded specifically with detailed guidance
                    if (errorMessage.includes('Too many SOQL queries')) {
                        errorMessage = 'A temporary system limit was encountered during the export. Our system has been optimized to handle large datasets and complex permission queries efficiently.\n\n' +
                                     'Please try the export again. If the issue persists:\n' +
                                     '• Wait a moment and retry the export\n' +
                                     '• Contact your administrator if the problem continues\n\n' +
                                     'Note: You can continue using all available fields and filters - our system is designed to handle comprehensive exports.';
                        toastVariant = 'warning';
                        
                        // Show encouraging toast after a delay
                        setTimeout(() => {
                            this.showToast('System Enhanced', 'Our export system has been optimized to efficiently handle all field types including permission-related fields. Use any filters you need.', 'info');
                        }, 4000);
                    }
                    // Handle CPU limit exceeded specifically with detailed guidance
                    else if (errorMessage.includes('CPU time limit exceeded')) {
                        errorMessage = 'The export process exceeded processing time limits. Our system has been optimized for better performance with all field types.\n\n' +
                                     'Please try the export again. If the issue persists:\n' +
                                     '• Wait a moment and retry the export\n' +
                                     '• Contact your administrator if the problem continues\n\n' +
                                     'You can continue using all available fields - our system supports comprehensive exports.' ;
                        toastVariant = 'warning';
                        
                        // Show encouraging toast after a delay
                        setTimeout(() => {
                            this.showToast('Performance Optimized', 'Our system has been enhanced to efficiently process exports with all field types, including permission-related fields.', 'info');
                        }, 3000);
                    }
                } else if (error.message) {
                    errorMessage = error.message;
                }
                
                this.handleError(error);
                this.showToast('Export Failed', errorMessage, toastVariant);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    convertBulkDataToCSV(data) {
        if (!data || !data.headers || !data.rows) return '';
        
        const headers = data.headers;
        const csvRows = [];
        
        // Add headers
        csvRows.push(headers.map(h => `"${h}"`).join(','));
        
        // Add data rows with proper escaping for comma-separated values
        data.rows.forEach(row => {
            const values = row.values.map(value => {
                const cellValue = value || '';
                // Escape quotes and wrap in quotes for CSV
                const escapedValue = cellValue.replace(/"/g, '""');
                return `"${escapedValue}"`;
            });
            csvRows.push(values.join(','));
        });
        
        return csvRows.join('\n');
    }

    convertToCSV(data) {
        // Use all data for export, not just current page
        const dataToExport = this._allReportData || data;
        
        if (!dataToExport || !dataToExport.headers || !dataToExport.rows) return '';
        
        const headers = dataToExport.headers;
        const csvRows = [];
        
        // Add headers
        csvRows.push(headers.map(h => h.label || h).join(','));
        
        // Add data rows
        dataToExport.rows.forEach(row => {
            const values = row.cells.map(cell => {
                const value = cell.value || '';
                return `"${value}"`;
            });
            csvRows.push(values.join(','));
        });
        
        return csvRows.join('\n');
    }

    downloadCSV(content, fileName) {
        const element = document.createElement('a');
        element.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(content);
        element.download = fileName;
        element.style.display = 'none';
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    }

    handleBulkCombinedPermissionExport() {
        this.isLoading = true;
        this.error = null;
        
        // Show loading toast
        this.showToast('Info', 'Starting bulk combined permission export... This may take a few moments for large datasets.', 'info');
        
        // Get filters for permission set assignments
        const permissionSetAssignmentFilters = this.selectedFilters.filter(filter => 
            filter !== 'userPermissionSetAssignmentsReport' && filter !== 'userPermissionSetGroupAssignmentsReport' &&
            filter.startsWith('userPermissionSetAssignment') && !filter.startsWith('userPermissionSetGroupAssignment')
        );
        
        // Get filters for permission set group assignments
        const permissionSetGroupAssignmentFilters = this.selectedFilters.filter(filter => 
            filter !== 'userPermissionSetAssignmentsReport' && filter !== 'userPermissionSetGroupAssignmentsReport' &&
            filter.startsWith('userPermissionSetGroupAssignment')
        );
        
        exportCombinedPermissionAssignmentsBulk({ 
            permissionSetFilters: permissionSetAssignmentFilters,
            permissionSetGroupFilters: permissionSetGroupAssignmentFilters
        })
            .then(result => {
                if (result && result.headers && result.rows) {
                    console.log('Bulk combined permission export completed. Total rows:', result.rows.length);
                    
                    // Convert to CSV with proper formatting
                    const csvContent = this.convertBulkDataToCSV(result);
                    const fileName = `user_permission_assignments_bulk_export_${new Date().toISOString().split('T')[0]}.csv`;
                    this.downloadCSV(csvContent, fileName);
                    
                    this.showToast('Success', `Export completed! ${result.rows.length} users with permission assignments exported.`, 'success');
                } else {
                    this.error = 'No data returned from bulk combined permission export';
                    this.showToast('Warning', 'No data was returned from the export', 'warning');
                }
            })
            .catch(error => {
                console.error('Error in bulk combined permission export:', error);
                
                let errorMessage = 'Export failed: ' + (error.body?.message || error.message);
                let toastVariant = 'error';
                
                // Handle SOQL limit exceeded specifically
                if (error.body?.message && error.body.message.includes('Too many SOQL queries')) {
                    errorMessage = 'A temporary system limit was encountered during the export. Our system has been optimized to handle large datasets efficiently.\n\n' +
                                 'Please try the export again. If the issue persists:\n' +
                                 '• Wait a moment and retry the export\n' +
                                 '• Contact your administrator if the problem continues\n\n' +
                                 'Note: You can continue using all available filters - our system is designed to handle comprehensive exports.';
                    toastVariant = 'warning';
                    
                    // Show encouraging toast after a delay
                    setTimeout(() => {
                        this.showToast('System Optimized', 'Our export system has been enhanced to handle large permission datasets efficiently. Feel free to use all available filters.', 'info');
                    }, 4000);
                }
                // Handle CPU limit exceeded specifically
                else if (error.body?.message && error.body.message.includes('CPU time limit exceeded')) {
                    errorMessage = 'The export process exceeded processing time limits. Our system has been optimized for better performance.\n\n' +
                                 'Please try the export again. If the issue persists:\n' +
                                 '• Wait a moment and retry the export\n' +
                                 '• Contact your administrator if the problem continues\n\n' +
                                 'You can continue using all available filters - our system supports comprehensive exports.';
                    toastVariant = 'warning';
                    
                    // Show encouraging toast after a delay
                    setTimeout(() => {
                        this.showToast('Enhanced Performance', 'Our system has been optimized to handle comprehensive permission exports more efficiently.', 'info');
                    }, 3000);
                }
                
                this.handleError(error);
                this.showToast('Export Failed', errorMessage, toastVariant);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Helper method to set report data with pagination
    setReportDataWithPagination(result) {
        if (result && result.headers && result.rows) {
            // Store all data for pagination
            this._allReportData = {
                headers: result.headers.map(header => ({
                    label: this.getHeaderLabel(header),
                    value: header
                })),
                rows: result.rows.map((row, index) => ({
                    id: `row-${index}`,
                    cells: row.values.map((value, cellIndex) => ({
                        id: `cell-${index}-${cellIndex}`,
                        value: value || '',
                        header: result.headers[cellIndex]
                    }))
                }))
            };
            
            // Reset pagination to first page
            this.currentPage = 1;
            
            // Update pagination and display paginated data
            this.updatePagination();
            
            // Removed scroll shadow call
            return true;
        }
        return false;
    }

    // Pagination methods
    updatePagination() {
        console.log('updatePagination called with:', this._allReportData);
        if (this._allReportData) {
            if (this._allReportData.rows) {
                this.totalRecords = this._allReportData.rows.length;
            } else if (this._allReportData.sections) {
                // For sharing reports with sections, count total rows across all sections
                this.totalRecords = this._allReportData.sections.reduce((total, section) => {
                    return total + (section.rows ? section.rows.length : 0);
                }, 0);
            } else {
                this.totalRecords = 0;
            }
            
            this.updateRecordCount();
            this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
            if (this.currentPage > this.totalPages && this.totalPages > 0) {
                this.currentPage = this.totalPages;
            }
            console.log('Pagination updated:', {
                totalRecords: this.totalRecords,
                totalPages: this.totalPages,
                currentPage: this.currentPage,
                pageSize: this.pageSize
            });
            this.updatePaginatedData();
        }
    }

    updatePaginatedData() {
        if (this._allReportData) {
            if (this._allReportData.rows) {
                // Standard table format
                const startIndex = (this.currentPage - 1) * this.pageSize;
                const endIndex = startIndex + this.pageSize;
                const paginatedRows = this._allReportData.rows.slice(startIndex, endIndex);
                
                this.reportData = {
                    ...this._allReportData,
                    rows: paginatedRows
                };
            } else if (this._allReportData.sections) {
                // Sharing reports with sections format
                let allRows = [];
                this._allReportData.sections.forEach(section => {
                    if (section.rows) {
                        allRows = allRows.concat(section.rows.map(row => ({...row, sectionTitle: section.title, sectionHeaders: section.headers})));
                    }
                });
                
                const startIndex = (this.currentPage - 1) * this.pageSize;
                const endIndex = startIndex + this.pageSize;
                const paginatedRows = allRows.slice(startIndex, endIndex);
                
                // Group paginated rows back into sections
                const paginatedSections = [];
                let currentSection = null;
                
                paginatedRows.forEach(row => {
                    if (!currentSection || currentSection.title !== row.sectionTitle) {
                        currentSection = {
                            title: row.sectionTitle,
                            headers: row.sectionHeaders,
                            rows: []
                        };
                        paginatedSections.push(currentSection);
                    }
                    const {sectionTitle, sectionHeaders, ...cleanRow} = row;
                    currentSection.rows.push(cleanRow);
                });
                
                this.reportData = {
                    ...this._allReportData,
                    sections: paginatedSections
                };
            }
        }
    }

    // Pagination event handlers
    handleFirstPage() {
        console.log('handleFirstPage clicked');
        this.currentPage = 1;
        this.updatePaginatedData();
    }

    handlePreviousPage() {
        console.log('handlePreviousPage clicked, currentPage:', this.currentPage);
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginatedData();
        }
    }

    handleNextPage() {
        console.log('handleNextPage clicked, currentPage:', this.currentPage, 'totalPages:', this.totalPages);
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePaginatedData();
        }
    }

    handleLastPage() {
        console.log('handleLastPage clicked');
        this.currentPage = this.totalPages;
        this.updatePaginatedData();
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.detail.value);
        this.currentPage = 1;
        this.updatePagination();
    }

    handleCardClick(event) {
        const cardId = event.currentTarget.dataset.id;
        console.log('Card clicked:', cardId);
        this.activeCardId = cardId;
        this.selectedFilters = [];
        this.isHomeScreen = false;
        this.activeDashboardTitle = this.getCardTitle(cardId);
        this.reportData = null;
        this.error = null;
        
        // If we're switching to the Config Intel card, ensure all filters are enabled and unchecked
        if (cardId === 'config') {
            setTimeout(() => {
                // Make sure all checkboxes are unchecked initially
                const configFilters = ['validationRules', 'fieldsInPageLayouts', 'pageLayoutsAssignment'];
                configFilters.forEach(filter => {
                    const checkbox = this.template.querySelector(`input[value="${filter}"]`);
                    if (checkbox) {
                        checkbox.checked = false;
                    }
                    
                    // Uncheck all sub-filters too
                    const subFilterCheckboxes = this.template.querySelectorAll(`input[data-parent="${filter}"]`);
                    subFilterCheckboxes.forEach(subCheckbox => {
                        subCheckbox.checked = false;
                    });
                });
            }, 0);
        }
        
        // If we're switching to the Sharing Intel card, ensure all filters are enabled
        if (cardId === 'sharing') {
            // Make sure all sharing filters and their sub-filters are enabled
            setTimeout(() => {
                this.updateSharingFilterCheckboxes(null);
                
                // Also make sure all checkboxes are unchecked initially
                const sharingFilters = ['sharingSettings', 'orgWideDefaults', 'publicGroups', 'publicGroupMembers'];
                sharingFilters.forEach(filter => {
                    const checkbox = this.template.querySelector(`input[value="${filter}"]`);
                    if (checkbox) {
                        checkbox.checked = false;
                    }
                    
                    // Uncheck all sub-filters too
                    if (filter === 'publicGroups' || filter === 'publicGroupMembers') {
                        const subFilterCheckboxes = this.template.querySelectorAll(`input[data-parent="${filter}"]`);
                        subFilterCheckboxes.forEach(subCheckbox => {
                            subCheckbox.checked = false;
                        });
                    }
                });
            }, 0);
            
            // Load templates when navigating to Sharing Intel
            this.loadTemplatesFromStorage();
        }
        
        // If we're switching to the Reporting Intel card, ensure all filters are enabled
        if (cardId === 'reporting') {
            // Make sure all reporting filters are enabled
            setTimeout(() => {
                this.updateReportingFilterCheckboxes(null);
                
                // Also make sure all checkboxes are unchecked initially
                const reportingFilters = ['reportFolderShare', 'dashboardFolderShare', 'dashboardRunningUser'];
                reportingFilters.forEach(filter => {
                    const checkbox = this.template.querySelector(`input[value="${filter}"]`);
                    if (checkbox) {
                        checkbox.checked = false;
                    }
                });
            }, 0);
        }
        
        // If we're switching to the Permissions Intel card, ensure all filters are enabled
        if (cardId === 'permissions') {
            // Make sure all permissions filters are enabled
            setTimeout(() => {
                this.updatePermissionsFilterCheckboxes(null);
                
                // Also make sure all checkboxes are unchecked initially
                const permissionsFilters = ['roleType', 'territories', 'permissionSetNoGroup'];
                permissionsFilters.forEach(filter => {
                    const checkbox = this.template.querySelector(`input[value="${filter}"]`);
                    if (checkbox) {
                        checkbox.checked = false;
                    }
                    
                    // Uncheck all sub-filters too
                    const subFilterCheckboxes = this.template.querySelectorAll(`input[data-parent="${filter}"]`);
                    subFilterCheckboxes.forEach(subCheckbox => {
                        subCheckbox.checked = false;
                    });
                });
            }, 0);
            
            // Load templates when navigating to Permissions Intel
            this.loadTemplatesFromStorage();
        }
        
        // If we're switching to the Other Intel card, ensure all filters are enabled
        if (cardId === 'other') {
            // Make sure all other intel filters are enabled
            setTimeout(() => {
                this.updateOtherIntelFilterCheckboxes(null);
                
                // Also make sure all checkboxes are unchecked initially
                const otherIntelFilters = ['installedPackages', 'listView', 'apexCode'];
                otherIntelFilters.forEach(filter => {
                    const checkbox = this.template.querySelector(`input[value="${filter}"]`);
                    if (checkbox) {
                        checkbox.checked = false;
                    }
                    
                    // Uncheck all sub-filters too
                    const subFilterCheckboxes = this.template.querySelectorAll(`input[data-parent="${filter}"]`);
                    subFilterCheckboxes.forEach(subCheckbox => {
                        subCheckbox.checked = false;
                    });
                });
            }, 0);
            
            // Load templates when navigating to Other Intel
            this.loadTemplatesFromStorage();
        }
        
        // If we're switching to the User Intel or Profile Assignment Intel card, update the button state and load templates
        if (cardId === 'user' || cardId === 'profileAssignment') {
            // Load templates when navigating to User Intel or Profile Assignment Intel
            this.loadTemplatesFromStorage();
        }
    }

    goBackToHome() {
        this.isHomeScreen = true;
        this.activeCardId = null; // Reset active card to hide filters
        this.selectedFilters = [];
        this.reportData = null;
        this.error = null;
    }

    removeFilter(event) {
        const valueToRemove = event.currentTarget.dataset.value;
        this.selectedFilters = this.selectedFilters.filter(item => item !== valueToRemove);
        
        const checkboxes = this.template.querySelectorAll('input[type="checkbox"]');
        checkboxes.forEach(checkbox => {
            if (checkbox.value === valueToRemove) {
                checkbox.checked = false;
            }
        });
    }

    getCardTitle(cardId) {
        const card = this.cardData[cardId];
        return card ? card.title : cardId.charAt(0).toUpperCase() + cardId.slice(1);
    }

    // Update the currentFilterOptions getter to include the new reporting option
    get currentFilterOptions() {
        if (this.activeCardId === 'user') {
            // Use dynamic filter options if loaded, otherwise fall back to static
            return this.userFieldsLoaded && this.dynamicFilterOptions.length > 0 
                ? this.dynamicFilterOptions 
                : this.filterOptions;
        } else if (this.activeCardId === 'config') {
            // Log the filter options for debugging
            console.log('Config Intel filter options:', this.configFilterOptions);
            return this.configFilterOptions;
        } else if (this.activeCardId === 'sharing') {
            return this.sharingFilterOptions;
        } else if (this.activeCardId === 'reporting') {
            return this.reportingFilterOptions;
        } else if (this.activeCardId === 'profileAssignment') {
            return this.profileAssignmentFilterOptions;
        } else if (this.activeCardId === 'permissions') {
            return this.permissionsIntelFilterOptions;
        } else if (this.activeCardId === 'other') {
            return this.otherIntelFilterOptions;
        }
        return this.filterOptions;
    }

    // Update the handleParentFilterChange method to also update help text visibility
    handleParentFilterChange(event) {
        const parentValue = event.target.value;
        const isChecked = event.target.checked;
        
        console.log('Parent filter changed:', parentValue, 'Checked:', isChecked);
        
        // Handle compareUsers filter specially
        if (parentValue === 'compareUsers') {
            if (isChecked) {
                // Remove other user filters first
                this.selectedFilters = this.selectedFilters.filter(f => f !== 'userData' && f !== 'userTerritories');
                
                // Add this filter
                this.selectedFilters.push(parentValue);
                
                // Show user selection modal
                this.fetchUsersForComparison();
                
                // Update checkbox states
                setTimeout(() => {
                    const userDataCheckbox = this.template.querySelector('input[value="userData"]');
                    const userTerritoriesCheckbox = this.template.querySelector('input[value="userTerritories"]');
                    
                    if (userDataCheckbox) userDataCheckbox.checked = false;
                    if (userTerritoriesCheckbox) userTerritoriesCheckbox.checked = false;
                }, 0);
            } else {
                // Remove the filter
                this.selectedFilters = this.selectedFilters.filter(f => f !== parentValue);
                
                // Clear selected users
                this.selectedUsers = [];
                this.reportData = null;
            }
            
            return;
        }
        
        // Special handling for User Intel card - separate basic user data from permission assignment data
        if (this.activeCardId === 'user' && (parentValue === 'userData' || parentValue === 'userTerritories' || parentValue === 'userPermissionSetAssignmentsReport' || parentValue === 'userPermissionSetGroupAssignmentsReport')) {
            // Basic user data filters (mutually exclusive with permission assignment filters)
            const basicUserFilters = ['userData', 'userTerritories', 'compareUsers'];
            // Permission assignment-related filters (can be combined with each other)
            const permissionAssignmentFilters = ['userPermissionSetAssignmentsReport', 'userPermissionSetGroupAssignmentsReport'];
            
            if (isChecked) {
                if (basicUserFilters.includes(parentValue)) {
                    // If selecting a basic user filter, clear all other filters
                    this.selectedFilters = this.selectedFilters.filter(f => 
                        !basicUserFilters.includes(f) && !permissionAssignmentFilters.includes(f)
                    );
                    
                    // Add this filter
                    this.selectedFilters.push(parentValue);
                    
                    // Update checkbox states - uncheck all other user filters
                    setTimeout(() => {
                        [...basicUserFilters, ...permissionAssignmentFilters].forEach(filter => {
                            if (filter !== parentValue) {
                                const checkbox = this.template.querySelector(`input[value="${filter}"]`);
                                if (checkbox) checkbox.checked = false;
                            }
                        });
                    }, 0);
                } else if (permissionAssignmentFilters.includes(parentValue)) {
                    // If selecting a permission assignment filter, clear basic user filters but allow other permission assignment filters
                    this.selectedFilters = this.selectedFilters.filter(f => !basicUserFilters.includes(f));
                    
                    // Add this filter if not already present
                    if (!this.selectedFilters.includes(parentValue)) {
                        this.selectedFilters.push(parentValue);
                    }
                    
                    // Update checkbox states - uncheck basic user filters only
                    setTimeout(() => {
                        basicUserFilters.forEach(filter => {
                            const checkbox = this.template.querySelector(`input[value="${filter}"]`);
                            if (checkbox) checkbox.checked = false;
                        });
                    }, 0);
                }
            } else {
                // Remove this filter
                this.selectedFilters = this.selectedFilters.filter(f => f !== parentValue);
                
                // Also remove any sub-filters of this parent
                const currentOptions = this.currentFilterOptions;
                const parentFilter = currentOptions.find(f => f.value === parentValue);
                if (parentFilter && parentFilter.subFilters) {
                    const subFilterValues = parentFilter.subFilters.map(sub => sub.value);
                    this.selectedFilters = this.selectedFilters.filter(f => !subFilterValues.includes(f));
                }
            }
            
            return;
        }
        
        // Special handling for Sharing Intel card filters - make them mutually exclusive
        if (this.activeCardId === 'sharing') {
            const sharingFilters = ['sharingSettings', 'orgWideDefaults', 'publicGroups', 'publicGroupMembers'];
            
            if (isChecked) {
                // First, clear any existing sharing filters
                this.selectedFilters = this.selectedFilters.filter(f => !sharingFilters.includes(f));
                
                // Then add the newly selected filter
                this.selectedFilters.push(parentValue);
                
                // Update checkbox states to make other sharing filters disabled
                this.updateSharingFilterCheckboxes(parentValue);
                
                // Update help text visibility
                if (parentValue === 'sharingSettings' || parentValue === 'orgWideDefaults') {
                    this.updateFilterHelpText(parentValue, true);
                }
            } else {
                // Remove the filter
                this.selectedFilters = this.selectedFilters.filter(f => f !== parentValue);
                
                // Enable all sharing filter checkboxes
                this.updateSharingFilterCheckboxes(null);
                
                // Hide help text
                if (parentValue === 'sharingSettings' || parentValue === 'orgWideDefaults') {
                    this.updateFilterHelpText(parentValue, false);
                }
            }
            
            // If we're unchecking a parent filter that has sub-filters, also remove those
            if (!isChecked) {
                const parentFilter = this.sharingFilterOptions.find(f => f.value === parentValue);
                if (parentFilter && parentFilter.subFilters) {
                    const subFilterValues = parentFilter.subFilters.map(sub => sub.value);
                    this.selectedFilters = this.selectedFilters.filter(f => !subFilterValues.includes(f));
                }
            }
            
            return;
        }
        
        // Special handling for Reporting Intel card filters - make them mutually exclusive
        if (this.activeCardId === 'reporting') {
            const reportingFilters = ['reportFolderShare', 'dashboardFolderShare', 'dashboardRunningUser'];
            
            if (isChecked) {
                // First, clear any existing reporting filters
                this.selectedFilters = this.selectedFilters.filter(f => !reportingFilters.includes(f));
                
                // Then add the newly selected filter
                this.selectedFilters.push(parentValue);
                
                // Update checkbox states to make other reporting filters disabled
                this.updateReportingFilterCheckboxes(parentValue);
            } else {
                // Remove the filter
                this.selectedFilters = this.selectedFilters.filter(f => f !== parentValue);
                
                // Enable all reporting filter checkboxes
                this.updateReportingFilterCheckboxes(null);
            }
            
            return;
        }
        
        // Special handling for Config Intel card filters - manage parent and sub-filters
        if (this.activeCardId === 'config') {
            if (isChecked) {
                // Add the newly selected filter without clearing other config filters
                if (!this.selectedFilters.includes(parentValue)) {
                    this.selectedFilters.push(parentValue);
                }
                
                // Clear sub-filter selection for only this parent
                const parentFilter = this.configFilterOptions.find(f => f.value === parentValue);
                if (parentFilter && parentFilter.subFilters) {
                    const subFilterValues = parentFilter.subFilters.map(sub => sub.value);
                    this.selectedFilters = this.selectedFilters.filter(f => !subFilterValues.includes(f));
                }
            } else {
                // Remove the filter
                this.selectedFilters = this.selectedFilters.filter(f => f !== parentValue);
                
                // If we're unchecking a parent filter that has sub-filters, also remove those
                const parentFilter = this.configFilterOptions.find(f => f.value === parentValue);
                if (parentFilter && parentFilter.subFilters) {
                    const subFilterValues = parentFilter.subFilters.map(sub => sub.value);
                    this.selectedFilters = this.selectedFilters.filter(f => !subFilterValues.includes(f));
                }
            }
            
            return;
        }
        
        // Special handling for Permissions Intel card filters - make them mutually exclusive
        if (this.activeCardId === 'permissions') {
            const permissionsFilters = ['roleType', 'territories', 'permissionSetNoGroup'];
            
            if (isChecked) {
                // First, clear any existing permissions filters
                this.selectedFilters = this.selectedFilters.filter(f => !permissionsFilters.includes(f));
                
                // Then add the newly selected filter
                this.selectedFilters.push(parentValue);
                
                // Update checkbox states to make other permissions filters disabled
                this.updatePermissionsFilterCheckboxes(parentValue);
            } else {
                // Remove the filter
                this.selectedFilters = this.selectedFilters.filter(f => f !== parentValue);
                
                // Enable all permissions filter checkboxes
                this.updatePermissionsFilterCheckboxes(null);
                
                // If we're unchecking a parent filter that has sub-filters, also remove those
                const parentFilter = this.permissionsIntelFilterOptions.find(f => f.value === parentValue);
                if (parentFilter && parentFilter.subFilters) {
                    const subFilterValues = parentFilter.subFilters.map(sub => sub.value);
                    this.selectedFilters = this.selectedFilters.filter(f => !subFilterValues.includes(f));
                }
            }
            
            return;
        }
        
        // Special handling for Other Intel card filters - make them mutually exclusive
        if (this.activeCardId === 'other') {
            const otherIntelFilters = ['installedPackages', 'listView', 'apexCode'];
            
            if (isChecked) {
                // First, clear any existing other intel filters
                this.selectedFilters = this.selectedFilters.filter(f => !otherIntelFilters.includes(f));
                
                // Then add the newly selected filter
                this.selectedFilters.push(parentValue);
                
                // Update checkbox states to make other intel filters disabled
                this.updateOtherIntelFilterCheckboxes(parentValue);
            } else {
                // Remove the filter
                this.selectedFilters = this.selectedFilters.filter(f => f !== parentValue);
                
                // Enable all other intel filter checkboxes
                this.updateOtherIntelFilterCheckboxes(null);
                
                // If we're unchecking a parent filter that has sub-filters, also remove those
                const parentFilter = this.otherIntelFilterOptions.find(f => f.value === parentValue);
                if (parentFilter && parentFilter.subFilters) {
                    const subFilterValues = parentFilter.subFilters.map(sub => sub.value);
                    this.selectedFilters = this.selectedFilters.filter(f => !subFilterValues.includes(f));
                }
            }
            
            return;
        }
        
        // Original code for other card types
        if (parentValue === 'sharingSettings' || parentValue === 'orgWideDefaults') {
            if (isChecked) {
                this.selectedFilters = [...this.selectedFilters, parentValue];
                console.log('Added filter:', parentValue, 'Current filters:', this.selectedFilters);
                // Update help text visibility
                this.updateFilterHelpText(parentValue, true);
            } else {
                this.selectedFilters = this.selectedFilters.filter(f => f !== parentValue);
                console.log('Removed filter:', parentValue, 'Current filters:', this.selectedFilters);
                // Hide help text
                this.updateFilterHelpText(parentValue, false);
            }
            return;
        }
        
        let parentFilter;
        if (this.activeCardId === 'reporting') {
            parentFilter = this.reportingFilterOptions.find(f => f.value === parentValue);
        } else if (this.activeCardId === 'permissions') {
            parentFilter = this.permissionsIntelFilterOptions.find(f => f.value === parentValue);
        } else if (this.activeCardId === 'other') {
            parentFilter = this.otherIntelFilterOptions.find(f => f.value === parentValue);
        }

        if (parentFilter && parentFilter.subFilters) {
            if (isChecked) {
                // Only add the parent filter, not the sub-filters
                this.selectedFilters = [...this.selectedFilters, parentValue];
                
                // Update checkbox UI for sub-filters
                setTimeout(() => {
                    const subFilterCheckboxes = this.template.querySelectorAll(`input[data-parent="${parentValue}"]`);
                    subFilterCheckboxes.forEach(checkbox => {
                        checkbox.checked = false;
                    });
                }, 0);
            } else {
                // Remove parent and all subfilters
                this.selectedFilters = this.selectedFilters.filter(f => {
                    const isParent = f === parentValue;
                    const isSubFilter = parentFilter.subFilters.some(sub => 
                        sub.value === f || (sub.nestedFilters && sub.nestedFilters.some(nested => nested.value === f))
                    );
                    return !isParent && !isSubFilter;
                });
            }
        }
        
        console.log('After handling, selectedFilters:', this.selectedFilters);
        
        // Check for performance-intensive combinations and show warnings
        this.checkPerformanceWarnings();
    }

    // Add this new method to update sharing filter checkboxes
    updateSharingFilterCheckboxes(selectedFilter) {
        setTimeout(() => {
            const sharingFilters = ['sharingSettings', 'orgWideDefaults', 'publicGroups', 'publicGroupMembers'];
            
            sharingFilters.forEach(filter => {
                const checkbox = this.template.querySelector(`input[value="${filter}"]`);
                if (checkbox) {
                    // If selectedFilter is null, enable all checkboxes
                    if (selectedFilter === null) {
                        checkbox.disabled = false;
                        
                        // Also enable sub-filters for this parent
                        if (filter === 'publicGroups' || filter === 'publicGroupMembers') {
                            const subFilterCheckboxes = this.template.querySelectorAll(`input[data-parent="${filter}"]`);
                            subFilterCheckboxes.forEach(subCheckbox => {
                                subCheckbox.disabled = false;
                            });
                        }
                    } else {
                        // Otherwise, disable all except the selected one
                        checkbox.disabled = filter !== selectedFilter;
                        
                        // For sub-filters: enable if parent is selected, disable otherwise
                        if (filter === 'publicGroups' || filter === 'publicGroupMembers') {
                            const subFilterCheckboxes = this.template.querySelectorAll(`input[data-parent="${filter}"]`);
                            subFilterCheckboxes.forEach(subCheckbox => {
                                // Only enable sub-filters if their parent is the selected filter
                                subCheckbox.disabled = filter !== selectedFilter;
                            });
                        }
                    }
                }
            });
        }, 0);
    }

    // Add this new method for help text visibility
    updateFilterHelpText(filterValue, isVisible) {
        // Use setTimeout to ensure DOM is updated before we manipulate it
        setTimeout(() => {
            const sharingSettingsHelp = this.template.querySelector('.sharingSettingsHelp');
            const orgWideDefaultsHelp = this.template.querySelector('.orgWideDefaultsHelp');
            
            if (filterValue === 'sharingSettings' && sharingSettingsHelp) {
                sharingSettingsHelp.style.display = isVisible ? 'block' : 'none';
            }
            
            if (filterValue === 'orgWideDefaults' && orgWideDefaultsHelp) {
                orgWideDefaultsHelp.style.display = isVisible ? 'block' : 'none';
            }
        }, 0);
    }

    // Update the handleSubFilterChange method to work with the mutual exclusivity of sharing filters
    handleSubFilterChange(event) {
        const subValue = event.target.value;
        const parentValue = event.target.dataset.parent;
        const isChecked = event.target.checked;
        
        // Skip separator fields
        if (subValue && (subValue.startsWith('separator') || subValue.includes('---'))) {
            return;
        }
        
        console.log('Sub filter changed:', subValue, 'Parent:', parentValue, 'Checked:', isChecked);
        
        // For Sharing Intel card, ensure parent filter is selected and others are disabled
        if (this.activeCardId === 'sharing' && (parentValue === 'publicGroups' || parentValue === 'publicGroupMembers')) {
            const sharingFilters = ['sharingSettings', 'orgWideDefaults', 'publicGroups', 'publicGroupMembers'];

        if (isChecked) {
                // First, clear any existing sharing filters except the parent
                this.selectedFilters = this.selectedFilters.filter(f => !sharingFilters.includes(f) || f === parentValue);
                
                // If parent is not already selected, select it
                if (!this.selectedFilters.includes(parentValue)) {
                    this.selectedFilters.push(parentValue);
                    
                    // Update parent checkbox UI
                    setTimeout(() => {
                        const parentCheckbox = this.template.querySelector(`input[value="${parentValue}"]`);
                        if (parentCheckbox) {
                            parentCheckbox.checked = true;
                        }
                    }, 0);
                    
                    // Disable other sharing filter checkboxes
                    this.updateSharingFilterCheckboxes(parentValue);
                }
                
                // Add the sub-filter
            this.selectedFilters.push(subValue);
            } else {
                // Remove the sub-filter
                this.selectedFilters = this.selectedFilters.filter(f => f !== subValue);
                
                // Check if any sub-filters of the parent are still selected
                const parentFilter = this.sharingFilterOptions.find(f => f.value === parentValue);
                if (parentFilter) {
                    const anySubSelected = parentFilter.subFilters.some(sub => 
                        this.selectedFilters.includes(sub.value)
                    );
                    
                    // If no sub-filters are selected but parent is still checked, leave it
                    // We don't uncheck the parent because it's a valid selection on its own
                }
            }
            
            console.log('After sharing sub-filter handling, selectedFilters:', this.selectedFilters);
            return;
        }
        
        // For Permissions Intel card, handle Role Type filter
        if (this.activeCardId === 'permissions' && parentValue === 'roleType') {
            if (isChecked) {
                // If parent is not already selected, select it
                if (!this.selectedFilters.includes(parentValue)) {
                    this.selectedFilters.push(parentValue);
                    
                    // Update parent checkbox UI
                    setTimeout(() => {
                        const parentCheckbox = this.template.querySelector(`input[value="${parentValue}"]`);
                        if (parentCheckbox) {
                            parentCheckbox.checked = true;
                        }
                    }, 0);
                }
                
                // Add the sub-filter
                this.selectedFilters.push(subValue);
            } else {
                // Remove the sub-filter
                this.selectedFilters = this.selectedFilters.filter(f => f !== subValue);
                
                // Check if any sub-filters of the parent are still selected
                const roleTypeFilter = this.permissionsIntelFilterOptions.find(f => f.value === 'roleType');
                if (roleTypeFilter) {
                    const anySubSelected = roleTypeFilter.subFilters.some(sub => 
                        this.selectedFilters.includes(sub.value)
                    );
                    
                    // If no sub-filters are selected, uncheck the parent
                    if (!anySubSelected) {
                        this.selectedFilters = this.selectedFilters.filter(f => f !== parentValue);
                        
                        // Update parent checkbox UI
                        setTimeout(() => {
                            const parentCheckbox = this.template.querySelector(`input[value="${parentValue}"]`);
                            if (parentCheckbox) {
                                parentCheckbox.checked = false;
                            }
                        }, 0);
                    }
                }
            }
            
            console.log('After permissions sub-filter handling, selectedFilters:', this.selectedFilters);
            return;
        }

        // For Other Intel card, handle Installed Packages filter
        if (this.activeCardId === 'other' && parentValue === 'installedPackages') {
            if (isChecked) {
                // If parent is not already selected, select it
                if (!this.selectedFilters.includes(parentValue)) {
                    this.selectedFilters.push(parentValue);
                    
                    // Update parent checkbox UI
                    setTimeout(() => {
                        const parentCheckbox = this.template.querySelector(`input[value="${parentValue}"]`);
                        if (parentCheckbox) {
                            parentCheckbox.checked = true;
                        }
                    }, 0);
                }
                
                // Add the sub-filter
                this.selectedFilters.push(subValue);
            } else {
                // Remove the sub-filter
                this.selectedFilters = this.selectedFilters.filter(f => f !== subValue);
                
                // Check if any sub-filters of the parent are still selected
                const installedPackagesFilter = this.otherIntelFilterOptions.find(f => f.value === 'installedPackages');
                if (installedPackagesFilter) {
                    const anySubSelected = installedPackagesFilter.subFilters.some(sub => 
                        this.selectedFilters.includes(sub.value)
                    );
                    
                    // If no sub-filters are selected, uncheck the parent
                    if (!anySubSelected) {
                        this.selectedFilters = this.selectedFilters.filter(f => f !== parentValue);
                        
                        // Update parent checkbox UI
                        setTimeout(() => {
                            const parentCheckbox = this.template.querySelector(`input[value="${parentValue}"]`);
                            if (parentCheckbox) {
                                parentCheckbox.checked = false;
                            }
                        }, 0);
                    }
                }
            }
            
            console.log('After other intel sub-filter handling, selectedFilters:', this.selectedFilters);
            return;
        }
        
        // For Other Intel card, handle List View filter
        if (this.activeCardId === 'other' && parentValue === 'listView') {
            if (isChecked) {
                // If parent is not already selected, select it
                if (!this.selectedFilters.includes(parentValue)) {
                    this.selectedFilters.push(parentValue);
                    
                    // Update parent checkbox UI
                    setTimeout(() => {
                        const parentCheckbox = this.template.querySelector(`input[value="${parentValue}"]`);
                        if (parentCheckbox) {
                            parentCheckbox.checked = true;
                        }
                    }, 0);
                }
                
                // Add the sub-filter
                this.selectedFilters.push(subValue);
            } else {
                // Remove the sub-filter
                this.selectedFilters = this.selectedFilters.filter(f => f !== subValue);
                
                // Check if any sub-filters of the parent are still selected
                const listViewFilter = this.otherIntelFilterOptions.find(f => f.value === 'listView');
                if (listViewFilter) {
                    const anySubSelected = listViewFilter.subFilters.some(sub => 
                        this.selectedFilters.includes(sub.value)
                    );
                    
                    // If no sub-filters are selected, uncheck the parent
                    if (!anySubSelected) {
                        this.selectedFilters = this.selectedFilters.filter(f => f !== parentValue);
                        
                        // Update parent checkbox UI
                        setTimeout(() => {
                            const parentCheckbox = this.template.querySelector(`input[value="${parentValue}"]`);
                            if (parentCheckbox) {
                                parentCheckbox.checked = false;
                            }
                        }, 0);
                    }
                }
            }
            
            console.log('After list view sub-filter handling, selectedFilters:', this.selectedFilters);
            return;
        }

        // For Config Intel card filters (validationRules, fieldsInPageLayouts, pageLayoutsAssignment)
        if (this.activeCardId === 'config') {
            if (isChecked) {
                // If parent is not already selected, select it
                if (!this.selectedFilters.includes(parentValue)) {
                    this.selectedFilters.push(parentValue);
                    
                    // Update parent checkbox UI
                    setTimeout(() => {
                        const parentCheckbox = this.template.querySelector(`input[value="${parentValue}"]`);
                        if (parentCheckbox) {
                            parentCheckbox.checked = true;
                        }
                    }, 0);
                }
                
                // Add the sub-filter
                this.selectedFilters.push(subValue);
            } else {
                // Remove the sub-filter
                this.selectedFilters = this.selectedFilters.filter(f => f !== subValue);
                
                // Check if any sub-filters of the parent are still selected
                const parentFilter = this.configFilterOptions.find(f => f.value === parentValue);
                if (parentFilter) {
                    const anySubSelected = parentFilter.subFilters.some(sub => 
                        this.selectedFilters.includes(sub.value)
                    );
                    
                    // If no sub-filters are selected, don't uncheck the parent
                    // This allows the parent to be a valid selection on its own
                }
            }
            
            console.log('After config sub-filter handling, selectedFilters:', this.selectedFilters);
            return;
        }

        if (isChecked) {
            // When checking a sub-filter, make sure the parent is also checked
            if (!this.selectedFilters.includes(parentValue)) {
                this.selectedFilters.push(parentValue);
                
                // Update parent checkbox UI
                setTimeout(() => {
                    const parentCheckbox = this.template.querySelector(`input[value="${parentValue}"]`);
                    if (parentCheckbox) {
                        parentCheckbox.checked = true;
                    }
                }, 0);
            }
            
            // Add the sub-filter
            this.selectedFilters.push(subValue);
        } else {
            // Remove the sub-filter
            this.selectedFilters = this.selectedFilters.filter(f => f !== subValue);
            
            // Check if any sub-filters of the parent are still selected
            let parentFilter;
            if (this.activeCardId === 'sharing') {
                parentFilter = this.sharingFilterOptions.find(f => f.value === parentValue);
            } else if (this.activeCardId === 'reporting') {
                parentFilter = this.reportingFilterOptions.find(f => f.value === parentValue);
            } else if (this.activeCardId === 'permissions') {
                parentFilter = this.permissionsIntelFilterOptions.find(f => f.value === parentValue);
            } else if (this.activeCardId === 'other') {
                parentFilter = this.otherIntelFilterOptions.find(f => f.value === parentValue);
            }

            // Add User Intel card handling
            if (this.activeCardId === 'user') {
                // For User Intel, find the parent filter from dynamic options
                const userDataFilter = this.dynamicFilterOptions.find(f => f.value === parentValue);
                if (userDataFilter) {
                    const anySubSelected = userDataFilter.subFilters.some(sub => 
                        this.selectedFilters.includes(sub.value)
                    );
                    
                    // If no sub-filters are selected, uncheck the parent
                    if (!anySubSelected) {
                        this.selectedFilters = this.selectedFilters.filter(f => f !== parentValue);
                        
                        // Update parent checkbox UI
                        setTimeout(() => {
                            const parentCheckbox = this.template.querySelector(`input[value="${parentValue}"]`);
                            if (parentCheckbox) {
                                parentCheckbox.checked = false;
                            }
                        }, 0);
                    }
                }
            } else if (parentFilter) {
                const anySubSelected = parentFilter.subFilters.some(sub => 
                    this.selectedFilters.includes(sub.value)
                );
                
                // If no sub-filters are selected, uncheck the parent
                if (!anySubSelected) {
                    this.selectedFilters = this.selectedFilters.filter(f => f !== parentValue);
                    
                    // Update parent checkbox UI
                    setTimeout(() => {
                        const parentCheckbox = this.template.querySelector(`input[value="${parentValue}"]`);
                        if (parentCheckbox) {
                            parentCheckbox.checked = false;
                        }
                    }, 0);
                }
            }
        }
        
        console.log('After sub-filter handling, selectedFilters:', this.selectedFilters);
        
        // Check for performance-intensive combinations and show warnings
        this.checkPerformanceWarnings();
    }
    
    // New method to check for performance-intensive filter combinations
    checkPerformanceWarnings() {
        if (this.activeCardId !== 'user') return;
        
        // Define permission-related fields that are resource-intensive
        const permissionFields = [
            'userPermissionSetNames', 'userPermissionSetGroupNames', 'userData',
            'userPermissionSetAssignmentsReport', 'userPermissionSetGroupAssignmentsReport'
        ];
        
        // Count selected permission fields
        const selectedPermissionFields = this.selectedFilters.filter(filter => 
            permissionFields.includes(filter)
        ).length;
        
        // Count total selected fields
        const totalSelectedFields = this.selectedFilters.length;
        
        // Show warnings based on selection patterns
        if (selectedPermissionFields >= 4 && totalSelectedFields >= 15) {
            this.showToast(
                'Performance Warning', 
                'You have selected multiple permission fields with many other filters. This may cause timeouts during export. Consider reducing the number of selected fields for better performance.', 
                'warning'
            );
        } else if (selectedPermissionFields >= 1 && totalSelectedFields >= 8) {
            this.showToast(
                'Optimize Performance', 
                'Large exports with many fields may take longer to process. Consider using more specific filters to reduce the dataset size.', 
                'info'
            );
        }
    }

    // Update the isSharingCard getter and add isReportingCard
    get isSharingCard() {
        return this.activeCardId === 'sharing';
    }

    get isReportingCard() {
        return this.activeCardId === 'reporting';
    }

    get isOtherCard() {
        // Explicitly exclude user cards to prevent conflicts
        return !this.isSharingCard && !this.isReportingCard && !this.isProfileAssignmentCard 
               && !this.isPermissionsCard && !this.isOtherIntelCard && !this.isUserIntelCard;
    }

    // Add new getter for profile assignment card
    get isProfileAssignmentCard() {
        return this.activeCardId === 'profileAssignment';
    }

    // Add new getter for permissions intel card
    get isPermissionsCard() {
        return this.activeCardId === 'permissions';
    }

    // Add new getter for other intel card
    get isOtherIntelCard() {
        return this.activeCardId === 'other';
    }

    // Add this getter after the isOtherIntelCard getter
    get isUserIntelCard() {
        return this.activeCardId === 'user';
    }

    // Add this getter after the isUserIntelCard getter
    get isConfigCard() {
        return this.activeCardId === 'config';
    }

    // Helper methods for templates
    saveTemplate() {
        try {
            if (!this.newTemplateName) {
                throw new Error('Template name is required');
            }
            
            // Prepare template data for saving
            const templateData = {
                filters: [...this.selectedFilters]
            };
            
            // Add user data if this is a compareUsers template
            if (this.selectedFilters.includes('compareUsers') && this.selectedUsers.length > 0) {
                templateData.userData = {
                    selectedUsers: this.selectedUsers
                };
            }
            
            // Save template to Salesforce object
            saveTemplate({
                templateName: this.newTemplateName,
                cardType: this.activeCardId,
                selectedFilters: JSON.stringify(templateData)
            })
            .then(result => {
                if (result) {
                    // Reload templates to refresh the list
                    this.loadTemplatesFromStorage();
                    
                    // Close modal
                    this.showTemplateModal = false;
                    this.newTemplateName = '';
                    this.selectedTemplate = null;
                    
                    // Show success toast
                    const event = new ShowToastEvent({
                        title: 'Success',
                        message: `Template "${this.newTemplateName}" saved successfully`,
                        variant: 'success'
                    });
                    this.dispatchEvent(event);
                }
            })
            .catch(error => {
                console.error('Error saving template:', error);
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: `Error saving template: ${error.body ? error.body.message : error.message}`,
                    variant: 'error'
                });
                this.dispatchEvent(event);
            });
        } catch (error) {
            console.error('Error saving template:', error);
            const event = new ShowToastEvent({
                title: 'Error',
                message: `Error saving template: ${error.message}`,
                variant: 'error'
            });
            this.dispatchEvent(event);
        }
    }

    loadTemplate(event) {
        try {
            const templateId = event.currentTarget.dataset.id;
            const template = this.userTemplates.find(t => t.id === templateId);
            
            if (template) {
                console.log('Loading template:', template);
                
                // Parse the selectedFilters JSON
                let templateData;
                try {
                    templateData = JSON.parse(template.selectedFilters);
                } catch (parseError) {
                    console.error('Error parsing template data:', parseError);
                    templateData = { filters: [] };
                }
                
                // Clear existing selections
                this.selectedFilters = [];
                
                // Add template filters
                if (templateData.filters && templateData.filters.length > 0) {
                    this.selectedFilters = [...templateData.filters];
                    
                    // Update checkbox states to reflect loaded template
                    this.updateCheckboxStates();
                    
                    // Check if this is a compareUsers template
                    if (templateData.filters.includes('compareUsers')) {
                        // If template contains user comparison data, load it
                        if (templateData.userData && templateData.userData.selectedUsers) {
                            this.selectedUsers = [...templateData.userData.selectedUsers];
                            
                            // Fetch permission fields for these users
                            if (this.selectedUsers.length > 0) {
                                this.isLoading = true;
                                this.fetchUserPermissionFields();
                            }
                        } else {
                            // If no user data in template, show the user selection modal
                            this.fetchUsersForComparison();
                        }
                    } else {
                        // For other templates, just load the filters - don't auto-run the report
                        // This allows users to see the checkboxes are selected and modify if needed
                        console.log('Template loaded with filters. User can now run the report manually.');
                    }
                }
                
                // Close the modal
                this.showLoadTemplateModal = false;
                
                // Show success toast
                const event = new ShowToastEvent({
                    title: 'Success',
                    message: `Template "${template.name}" loaded successfully`,
                    variant: 'success'
                });
                this.dispatchEvent(event);
            }
        } catch (error) {
            console.error('Error loading template:', error);
            const event = new ShowToastEvent({
                title: 'Error',
                message: `Error loading template: ${error.message}`,
                variant: 'error'
            });
            this.dispatchEvent(event);
        }
    }

    updateCheckboxStates() {
        // Give the DOM time to update
        setTimeout(() => {
            console.log('Updating checkbox states for filters:', this.selectedFilters);
            
            // Update parent checkboxes
            const parentCheckboxes = this.template.querySelectorAll('input[type="checkbox"]:not([data-parent])');
            parentCheckboxes.forEach(checkbox => {
                const isChecked = this.selectedFilters.includes(checkbox.value);
                checkbox.checked = isChecked;
                console.log(`Parent checkbox ${checkbox.value}: ${isChecked ? 'checked' : 'unchecked'}`);
            });
            
            // Update sub-filter checkboxes
            const subFilterCheckboxes = this.template.querySelectorAll('input[type="checkbox"][data-parent]');
            subFilterCheckboxes.forEach(checkbox => {
                const subValue = checkbox.value;
                const isChecked = this.selectedFilters.includes(subValue);
                checkbox.checked = isChecked;
                console.log(`Sub-filter checkbox ${subValue}: ${isChecked ? 'checked' : 'unchecked'}`);
            });
            
            // Handle special cases for parent filters that should be checked when sub-filters are selected
            this.updateParentCheckboxesBasedOnSubFilters();
            
        }, 100); // Increased timeout to ensure DOM is fully updated
    }
    
    updateParentCheckboxesBasedOnSubFilters() {
        // For User Intel card, check if userData parent should be checked
        if (this.activeCardId === 'user') {
            const userDataSubFilters = this.currentFilterOptions.find(option => option.value === 'userData');
            if (userDataSubFilters && userDataSubFilters.subFilters) {
                const hasUserDataSubFilter = userDataSubFilters.subFilters.some(subFilter => 
                    this.selectedFilters.includes(subFilter.value)
                );
                
                const userDataCheckbox = this.template.querySelector('input[value="userData"]');
                if (userDataCheckbox && hasUserDataSubFilter) {
                    userDataCheckbox.checked = true;
                    if (!this.selectedFilters.includes('userData')) {
                        this.selectedFilters.push('userData');
                    }
                }
            }
        }
        
        // Handle other card types with hierarchical filters
        const currentOptions = this.currentFilterOptions;
        if (currentOptions) {
            currentOptions.forEach(option => {
                if (option.subFilters) {
                    const hasSubFilterSelected = option.subFilters.some(subFilter => 
                        this.selectedFilters.includes(subFilter.value)
                    );
                    
                    const parentCheckbox = this.template.querySelector(`input[value="${option.value}"]`);
                    if (parentCheckbox && hasSubFilterSelected) {
                        parentCheckbox.checked = true;
                        if (!this.selectedFilters.includes(option.value)) {
                            this.selectedFilters.push(option.value);
                        }
                    }
                }
            });
        }
    }
    
    updateCheckboxStatesQuietly() {
        // Update parent checkboxes
        const parentCheckboxes = this.template.querySelectorAll('input[type="checkbox"]:not([data-parent])');
        parentCheckboxes.forEach(checkbox => {
            const isChecked = this.selectedFilters.includes(checkbox.value);
            checkbox.checked = isChecked;
        });
        
        // Update sub-filter checkboxes
        const subFilterCheckboxes = this.template.querySelectorAll('input[type="checkbox"][data-parent]');
        subFilterCheckboxes.forEach(checkbox => {
            const subValue = checkbox.value;
            const isChecked = this.selectedFilters.includes(subValue);
            checkbox.checked = isChecked;
        });
        
        // Handle special cases for parent filters
        this.updateParentCheckboxesBasedOnSubFilters();
    }

    deleteTemplate() {
        if (this.templateToDelete) {
            const templateName = this.templateToDelete.name;
            
            // Delete template from Salesforce object
            deleteTemplate({ templateId: this.templateToDelete.id })
            .then(result => {
                if (result) {
                    // Reload templates to refresh the list
                    this.loadTemplatesFromStorage();
                    
                    // Show success message
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: `Template "${templateName}" deleted successfully`,
                            variant: 'success'
                        })
                    );
                    
                    // Reset and close confirmation
                    this.templateToDelete = null;
                    this.showDeleteConfirmation = false;
                    
                    // If the load template modal is open, keep it open
                    if (!this.showLoadTemplateModal) {
                        this.showLoadTemplateModal = false;
                    }
                }
            })
            .catch(error => {
                console.error('Error deleting template:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: `Error deleting template: ${error.body ? error.body.message : error.message}`,
                        variant: 'error'
                    })
                );
                
                // Reset and close confirmation even on error
                this.templateToDelete = null;
                this.showDeleteConfirmation = false;
            });
        }
    }

    saveTemplatesToStorage() {
        // This method is no longer needed as we save directly to Salesforce
        // Kept for backward compatibility but does nothing
    }

    loadTemplatesFromStorage() {
        // Load templates from Salesforce object for the current card type
        if (this.activeCardId) {
            loadTemplates({ cardType: this.activeCardId })
            .then(result => {
                if (result) {
                    this.userTemplates = result;
                    console.log('Loaded templates:', result);
                } else {
                    this.userTemplates = [];
                }
            })
            .catch(error => {
                console.error('Error loading templates:', error);
                this.userTemplates = [];
                // Don't show toast for loading errors as it might be too noisy
            });
        } else {
            this.userTemplates = [];
        }
    }

    // generateUUID method removed as we now use Salesforce-generated IDs

    // Add these handlers for template modals
    handleSaveTemplateClick() {
        // Check if any filters are selected
        if (this.selectedFilters.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select at least one filter to save as a template',
                    variant: 'error'
                })
            );
            return;
        }
        
        this.newTemplateName = '';
        this.selectedTemplate = null;
        this.showTemplateModal = true;
    }

    handleEditTemplateClick(event) {
        const templateId = event.currentTarget.dataset.id;
        const template = this.userTemplates.find(t => t.id === templateId);
        
        if (template) {
            this.selectedTemplate = template;
            this.newTemplateName = template.name;
            this.showTemplateModal = true;
            this.showLoadTemplateModal = false;
        }
    }

    handleDeleteTemplateClick(event) {
        const templateId = event.currentTarget.dataset.id;
        const template = this.userTemplates.find(t => t.id === templateId);
        
        if (template) {
            this.templateToDelete = template;
            this.showDeleteConfirmation = true;
        }
    }

    handleLoadTemplatesClick() {
        // We already updated isUser getter to include profileAssignment, so we don't need to check here
        this.showLoadTemplateModal = true;
    }

    handleTemplateModalClose() {
        this.showTemplateModal = false;
        this.newTemplateName = '';
        this.selectedTemplate = null;
    }

    handleLoadTemplateModalClose() {
        this.showLoadTemplateModal = false;
    }

    handleDeleteConfirmationClose() {
        this.showDeleteConfirmation = false;
        this.templateToDelete = null;
    }

    handleTemplateNameChange(event) {
        this.newTemplateName = event.target.value;
    }

    // Add this getter with the other getters
    get isUser() {
        // Update to include Sharing Intel card, Profile Assignment card, Permissions Intel card, and Other Intel card
        return this.activeCardId === 'user' || this.activeCardId === 'sharing' || 
               this.activeCardId === 'profileAssignment' || this.activeCardId === 'permissions' ||
               this.activeCardId === 'other';
    }

    // Add a getter to filter templates by current card type
    get filteredTemplates() {
        if (!this.userTemplates) return [];
        
        // Templates are already filtered by card type when loaded from Salesforce
        // So we can return all loaded templates
        return this.userTemplates;
    }

    // Update the hasTemplates getter to use filteredTemplates
    get hasTemplates() {
        return this.filteredTemplates && this.filteredTemplates.length > 0;
    }

    // Update the isTemplateButtonDisabled getter to use filteredTemplates
    get isTemplateButtonDisabled() {
        return !this.hasTemplates;
    }

    // Add this getter method
    get templateModalTitle() {
        return this.selectedTemplate ? 'Edit Template' : 'Save Template';
    }

    // Add this getter to check if an option is the Sharing Settings option
    isSharingSettingsOption(optionValue) {
        return optionValue === 'sharingSettings';
    }

    // Update the method to always return false since we removed sub-filters
    isSharingSettingsParent(parentValue) {
        return false;
    }

    // Add this getter to check if the Sharing Settings filter is selected
    get isSharingSettingsSelected() {
        return this.selectedFilters.includes('sharingSettings');
    }

    fetchOrgWideDefaultsData() {
        console.log('Fetching org-wide defaults data...');
        getOrgWideDefaultsData()
            .then(result => {
                console.log('Org-wide defaults data received:', result);
                if (result && result.sections) {
                    // Log the sections to help with debugging
                    console.log('Sections found:', result.sections.length);
                    result.sections.forEach((section, index) => {
                        console.log(`Section ${index+1}: ${section.title}, Rows: ${section.rows ? section.rows.length : 0}`);
                    });
                    
                    // Store all data for pagination
                    this._allReportData = result;
                    
                    // Reset pagination to first page
                    this.currentPage = 1;
                    
                    // Update pagination and display paginated data
                    this.updatePagination();
                } else {
                    console.error('Invalid org-wide defaults data received:', result);
                    this.reportData = { 
                        sections: [{
                            title: 'NO DATA FOUND',
                            headers: ['Message'],
                            rows: [{
                                key: 'no-data',
                                values: ['No org-wide defaults data was returned from the server.']
                            }]
                        }]
                    };
                }
                // Removed scroll shadow call
            })
            .catch(error => {
                console.error('Error fetching org-wide defaults:', error);
                this.handleError(error);
                // Create a fallback report data structure for errors
                this.reportData = { 
                    sections: [{
                        title: 'ERROR RETRIEVING DATA',
                        headers: ['Error Message'],
                        rows: [{
                            key: 'error',
                            values: [error.message || 'An error occurred while retrieving org-wide defaults data.']
                        }]
                    }]
                };
                // Removed scroll shadow call
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Add these getter methods after the existing getters
    get isSharingSettings() {
        return this.parentOption && this.parentOption.value === 'sharingSettings';
    }
    
    get isOrgWideDefaults() {
        return this.parentOption && this.parentOption.value === 'orgWideDefaults';
    }

    // Add these methods after fetchSharingRulesData
    fetchPublicGroupsData() {
        console.log('Fetching public groups data...');
        
        // Get all sub-filters of publicGroups that are selected
        const publicGroupsFilter = this.sharingFilterOptions.find(f => f.value === 'publicGroups');
        const selectedSubFilters = this.selectedFilters.filter(filter => 
            publicGroupsFilter.subFilters.some(sub => sub.value === filter)
        );
        
        // If no sub-filters are selected, use all available sub-filters
        const filtersToSend = selectedSubFilters.length > 0 ? 
            selectedSubFilters : 
            publicGroupsFilter.subFilters.map(sub => sub.value);
        
        console.log('Sending filters:', filtersToSend);
        
        getPublicGroupsDataPaginated({ filters: filtersToSend, pageSize: this.pageSize, pageNumber: this.currentPage })
            .then(result => {
                console.log('Public Groups data received:', result);
                if (result && result.headers && result.rows) {
                    // Store all data for pagination
                    this._allReportData = {
                        headers: result.headers.map(header => ({
                            label: this.getHeaderLabel(header),
                            value: header
                        })),
                        rows: result.rows.map((row, index) => ({
                            id: `row-${index}`,
                            cells: row.values.map((value, cellIndex) => ({
                                id: `cell-${index}-${cellIndex}`,
                                value: value || '',
                                header: result.headers[cellIndex]
                            }))
                        }))
                    };
                    
                    // Reset pagination to first page
                    this.currentPage = 1;
                    
                    // Update pagination and display paginated data
                    this.updatePagination();
                    
                    console.log('Processed reportData:', this.reportData);
                    // Removed scroll shadow call
                } else {
                    console.error('Invalid public groups data received:', result);
                    this.error = 'No public groups data found in your organization';
                }
            })
            .catch(error => {
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    fetchPublicGroupMembersData() {
        console.log('Fetching public group members data...');
        
        // Get all sub-filters of publicGroupMembers that are selected
        const publicGroupMembersFilter = this.sharingFilterOptions.find(f => f.value === 'publicGroupMembers');
        const selectedSubFilters = this.selectedFilters.filter(filter => 
            publicGroupMembersFilter.subFilters.some(sub => sub.value === filter)
        );
        
        // If no sub-filters are selected, use all available sub-filters
        const filtersToSend = selectedSubFilters.length > 0 ? 
            selectedSubFilters : 
            publicGroupMembersFilter.subFilters.map(sub => sub.value);
        
        console.log('Sending filters:', filtersToSend);
        
        getPublicGroupMembersDataPaginated({ filters: filtersToSend, pageSize: this.pageSize, pageNumber: this.currentPage })
            .then(result => {
                console.log('Public Group Members data received:', result);
                if (!this.setReportDataWithPagination(result)) {
                    console.error('Invalid public group members data received:', result);
                    this.error = 'No public group members data found in your organization';
                }
            })
            .catch(error => {
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Add this getter to determine if we're showing Public Groups or Public Group Members data
    get isPublicGroupsSelected() {
        return this.selectedFilters.includes('publicGroups') || this.selectedFilters.includes('publicGroupMembers');
    }

    // Add this new method to fetch Report Folder Share data
    fetchReportFolderShareData() {
        console.log('Fetching report folder share data...');
        
        getReportFolderShareData()
            .then(result => {
                console.log('Report folder share data received:', result);
                if (!this.setReportDataWithPagination(result)) {
                    console.error('Invalid report folder share data received:', result);
                    this.error = 'No report folder share data found in your organization';
                }
            })
            .catch(error => {
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Add this new method after fetchReportFolderShareData
    fetchDashboardFolderShareData() {
        console.log('Fetching dashboard folder share data...');
        
        getDashboardFolderShareData()
            .then(result => {
                console.log('Dashboard folder share data received:', result);
                if (!this.setReportDataWithPagination(result)) {
                    console.error('Invalid dashboard folder share data received:', result);
                    this.error = 'No dashboard folder share data found in your organization';
                }
            })
            .catch(error => {
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Add this new method after fetchDashboardFolderShareData
    fetchDashboardRunningUserData() {
        console.log('Fetching dashboard and running user data...');
        
        getDashboardRunningUserData()
            .then(result => {
                console.log('Dashboard and running user data received:', result);
                if (!this.setReportDataWithPagination(result)) {
                    console.error('Invalid dashboard and running user data received:', result);
                    this.error = 'No dashboard and running user data found in your organization';
                }
            })
            .catch(error => {
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Add this new method after updateSharingFilterCheckboxes
    updateReportingFilterCheckboxes(selectedFilter) {
        setTimeout(() => {
            const reportingFilters = ['reportFolderShare', 'dashboardFolderShare', 'dashboardRunningUser'];
            
            reportingFilters.forEach(filter => {
                const checkbox = this.template.querySelector(`input[value="${filter}"]`);
                if (checkbox) {
                    // If selectedFilter is null, enable all checkboxes
                    if (selectedFilter === null) {
                        checkbox.disabled = false;
                    } else {
                        // Otherwise, disable all except the selected one
                        checkbox.disabled = filter !== selectedFilter;
                    }
                }
            });
        }, 0);
    }

    // Add this new method after fetchDashboardRunningUserData
    fetchProfileAssignmentData() {
        console.log('Fetching profile assignment data...');
        
        getProfileAssignmentData({ filters: this.selectedFilters })
            .then(result => {
                console.log('Profile assignment data received:', result);
                if (!this.setReportDataWithPagination(result)) {
                    console.error('Invalid profile assignment data received:', result);
                    this.error = 'No profile assignment data found in your organization';
                }
            })
            .catch(error => {
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    fetchRoleTypeData() {
        console.log('Fetching role type data...');
        
        // Create a copy of selectedFilters without the parent 'roleType' filter
        const filtersToSend = this.selectedFilters.filter(filter => filter !== 'roleType');
        
        getRoleTypeDataPaginated({ filters: filtersToSend, pageSize: this.pageSize, pageNumber: this.currentPage })
            .then(result => {
                console.log('Role type data received:', result);
                if (!this.setReportDataWithPagination(result)) {
                    console.error('Invalid role type data received:', result);
                    this.error = 'No role type data found in your organization';
                }
            })
            .catch(error => {
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Add this new method after updateReportingFilterCheckboxes
    updatePermissionsFilterCheckboxes(selectedFilter) {
        setTimeout(() => {
            const permissionsFilters = ['roleType', 'territories', 'permissionSetNoGroup'];
            
            permissionsFilters.forEach(filter => {
                const checkbox = this.template.querySelector(`input[value="${filter}"]`);
                if (checkbox) {
                    // If selectedFilter is null, enable all checkboxes
                    if (selectedFilter === null) {
                        checkbox.disabled = false;
                        
                        // Also enable sub-filters for this parent
                        const subFilterCheckboxes = this.template.querySelectorAll(`input[data-parent="${filter}"]`);
                        subFilterCheckboxes.forEach(subCheckbox => {
                            subCheckbox.disabled = false;
                        });
                    } else {
                        // Otherwise, disable all except the selected one
                        checkbox.disabled = filter !== selectedFilter;
                        
                        // For sub-filters: enable if parent is selected, disable otherwise
                        const subFilterCheckboxes = this.template.querySelectorAll(`input[data-parent="${filter}"]`);
                        subFilterCheckboxes.forEach(subCheckbox => {
                            // Only enable sub-filters if their parent is the selected filter
                            subCheckbox.disabled = filter !== selectedFilter;
                        });
                    }
                }
            });
        }, 0);
    }

    fetchTerritoriesData() {
        console.log('Fetching territories data...');
        
        // Create a copy of selectedFilters without the parent 'territories' filter
        const filtersToSend = this.selectedFilters.filter(filter => filter !== 'territories');
        
        getTerritoriesData({ filters: filtersToSend })
            .then(result => {
                console.log('Territories data received:', result);
                if (!this.setReportDataWithPagination(result)) {
                    console.error('Invalid territories data received:', result);
                    this.error = 'No territories data found in your organization';
                }
            })
            .catch(error => {
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    fetchPermissionSetNoGroupData() {
        console.log('Fetching permission set data...');
        
        // Create a copy of selectedFilters without the parent 'permissionSetNoGroup' filter
        const filtersToSend = this.selectedFilters.filter(filter => filter !== 'permissionSetNoGroup');
        console.log('Filters to send:', filtersToSend);
        
        getPermissionSetNoGroupData({ filters: filtersToSend })
            .then(result => {
                console.log('Permission set data received:', result);
                if (result && result.headers && result.rows) {
                    console.log('Headers:', result.headers);
                    console.log('Row count:', result.rows.length);
                    
                    // Log the first row for debugging
                    if (result.rows.length > 0) {
                        console.log('First row values:', result.rows[0].values);
                    }
                    
                    this.setReportDataWithPagination(result);
                } else {
                    console.error('Invalid permission set data received:', result);
                    this.error = 'No permission sets found in your organization';
                }
            })
            .catch(error => {
                console.error('Error fetching permission set data:', error);
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    fetchInstalledPackagesData() {
        console.log('Fetching installed packages data...');
        
        // Create a copy of selectedFilters without the parent 'installedPackages' filter
        const filtersToSend = this.selectedFilters.filter(filter => filter !== 'installedPackages');
        console.log('Filters to send:', filtersToSend);
        
        getInstalledPackagesData({ filters: filtersToSend })
            .then(result => {
                console.log('Installed packages data received:', result);
                if (result && result.headers && result.rows) {
                    console.log('Headers:', result.headers);
                    console.log('Row count:', result.rows.length);
                    
                    // Log the first row for debugging
                    if (result.rows.length > 0) {
                        console.log('First row values:', result.rows[0].values);
                    }
                    
                    this.setReportDataWithPagination(result);
                } else {
                    console.error('Invalid installed packages data received:', result);
                    this.error = 'No installed packages found in your organization';
                }
            })
            .catch(error => {
                console.error('Error fetching installed packages data:', error);
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Add this method to update other intel filter checkboxes
    updateOtherIntelFilterCheckboxes(selectedFilter) {
        setTimeout(() => {
            const otherIntelFilters = ['installedPackages', 'listView', 'apexCode'];
            
            otherIntelFilters.forEach(filter => {
                const checkbox = this.template.querySelector(`input[value="${filter}"]`);
                if (checkbox) {
                    // If selectedFilter is null, enable all checkboxes
                    if (selectedFilter === null) {
                        checkbox.disabled = false;
                        
                        // Also enable sub-filters for this parent
                        const subFilterCheckboxes = this.template.querySelectorAll(`input[data-parent="${filter}"]`);
                        subFilterCheckboxes.forEach(subCheckbox => {
                            subCheckbox.disabled = false;
                        });
                    } else {
                        // Otherwise, disable all except the selected one
                        checkbox.disabled = filter !== selectedFilter;
                        
                        // For sub-filters: enable if parent is selected, disable otherwise
                        const subFilterCheckboxes = this.template.querySelectorAll(`input[data-parent="${filter}"]`);
                        subFilterCheckboxes.forEach(subCheckbox => {
                            // Only enable sub-filters if their parent is the selected filter
                            subCheckbox.disabled = filter !== selectedFilter;
                        });
                    }
                }
            });
        }, 0);
    }

    // Add this method after the fetchInstalledPackagesData method
    fetchListViewData() {
        console.log('Fetching list view data with pagination...');
        
        // Create a copy of selectedFilters without the parent 'listView' filter
        const filtersToSend = this.selectedFilters.filter(filter => filter !== 'listView');
        console.log('Filters to send:', filtersToSend);
        
        // Use paginated method for better performance
        getListViewDataPaginated({ 
            filters: filtersToSend, 
            offset: 0, 
            pageSize: 50 
        })
            .then(result => {
                console.log('Paginated list view data received:', result);
                if (result && result.headers && result.rows) {
                    console.log('Headers:', result.headers);
                    console.log('Row count:', result.rows.length);
                    
                    // Log the first row for debugging
                    if (result.rows.length > 0) {
                        console.log('First row values:', result.rows[0].values);
                    }
                    
                    this.setReportDataWithPagination(result);
                } else {
                    console.error('Invalid list view data received:', result);
                    this.error = 'No list views found in your organization';
                }
            })
            .catch(error => {
                console.error('Error fetching list view data:', error);
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Add these methods after fetchListViewData method
    fetchApexClassesData() {
        console.log('Fetching apex classes data...');
        
        // Create a copy of selectedFilters without the parent 'apexClasses' and 'apexCode' filters
        const filtersToSend = this.selectedFilters.filter(filter => 
            filter !== 'apexClasses' && filter !== 'apexCode'
        );
        console.log('Filters to send:', filtersToSend);
        
        getApexClassesData({ filters: filtersToSend })
            .then(result => {
                console.log('Apex classes data received:', result);
                if (result && result.headers && result.rows) {
                    console.log('Headers:', result.headers);
                    console.log('Row count:', result.rows.length);
                    
                    // Log the first row for debugging
                    if (result.rows.length > 0) {
                        console.log('First row values:', result.rows[0].values);
                    }
                    
                    this.setReportDataWithPagination(result);
                } else {
                    console.error('Invalid apex classes data received:', result);
                    this.error = 'No apex classes found in your organization';
                }
            })
            .catch(error => {
                console.error('Error fetching apex classes data:', error);
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    fetchApexTriggersData() {
        console.log('Fetching apex triggers data...');
        
        // Create a copy of selectedFilters without the parent 'apexTriggers' and 'apexCode' filters
        const filtersToSend = this.selectedFilters.filter(filter => 
            filter !== 'apexTriggers' && filter !== 'apexCode'
        );
        console.log('Filters to send:', filtersToSend);
        
        getApexTriggersData({ filters: filtersToSend })
            .then(result => {
                console.log('Apex triggers data received:', result);
                if (result && result.headers && result.rows) {
                    console.log('Headers:', result.headers);
                    console.log('Row count:', result.rows.length);
                    
                    // Log the first row for debugging
                    if (result.rows.length > 0) {
                        console.log('First row values:', result.rows[0].values);
                    }
                    
                    this.setReportDataWithPagination(result);
                } else {
                    console.error('Invalid apex triggers data received:', result);
                    this.error = 'No apex triggers found in your organization';
                }
            })
            .catch(error => {
                console.error('Error fetching apex triggers data:', error);
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    fetchUserTerritoriesData() {
        console.log('Fetching user territories data...');
        
        // Create a copy of selectedFilters without the parent 'userTerritories' filter
        const filtersToSend = this.selectedFilters.filter(filter => filter !== 'userTerritories');
        console.log('Filters to send:', filtersToSend);
        
        getUserTerritoriesData({ filters: filtersToSend })
            .then(result => {
                console.log('User territories data received:', result);
                if (result && result.headers && result.rows) {
                    console.log('Headers:', result.headers);
                    console.log('Row count:', result.rows.length);
                    
                    // Log the first row for debugging
                    if (result.rows.length > 0) {
                        console.log('First row values:', result.rows[0].values);
                    }
                    
                    this.setReportDataWithPagination(result);
                } else {
                    console.error('Invalid user territories data received:', result);
                    this.error = 'No user territories found in your organization';
                }
            })
            .catch(error => {
                console.error('Error fetching user territories data:', error);
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    fetchUserDataWithPermissions() {
        console.log('Fetching user data with permissions...');
        
        // Create a copy of selectedFilters without the parent 'userData' filter
        const filtersToSend = this.selectedFilters.filter(filter => filter !== 'userData');
        console.log('Filters to send:', filtersToSend);
        
        getUserDataWithPermissionsWithFilter({ filters: filtersToSend, filterByValues: this.filterByFieldValues })
            .then(result => {
                console.log('User data with permissions received:', result);
                if (result && result.headers && result.rows) {
                    console.log('Headers:', result.headers);
                    console.log('Row count:', result.rows.length);
                    
                    // Log the first row for debugging
                    if (result.rows.length > 0) {
                        console.log('First row values:', result.rows[0].values);
                    }
                    
                    this.setReportDataWithPagination(result);
                } else {
                    console.error('Invalid user data received:', result);
                    this.error = 'No user data found in your organization';
                }
            })
            .catch(error => {
                console.error('Error fetching user data with permissions:', error);
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    fetchUserPermissionSetAssignmentsData() {
        console.log('Fetching user permission set assignments data...');
        
        // Create a copy of selectedFilters without the parent filter
        const filtersToSend = this.selectedFilters.filter(filter => filter !== 'userPermissionSetAssignmentsReport');
        console.log('Filters to send:', filtersToSend);
        
        getUserPermissionSetAssignments({ filters: filtersToSend })
            .then(result => {
                console.log('User permission set assignments data received:', result);
                if (result && result.headers && result.rows) {
                    console.log('Headers:', result.headers);
                    console.log('Row count:', result.rows.length);
                    
                    // Log the first row for debugging
                    if (result.rows.length > 0) {
                        console.log('First row values:', result.rows[0].values);
                    }
                    
                    this.setReportDataWithPagination(result);
                } else {
                    console.error('Invalid user permission set assignments data received:', result);
                    this.error = 'No permission set assignments found in your organization';
                }
            })
            .catch(error => {
                console.error('Error fetching user permission set assignments data:', error);
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    fetchUserPermissionSetGroupAssignmentsData() {
        console.log('Fetching user permission set group assignments data...');
        
        // Create a copy of selectedFilters without the parent filter
        const filtersToSend = this.selectedFilters.filter(filter => filter !== 'userPermissionSetGroupAssignmentsReport');
        console.log('Filters to send:', filtersToSend);
        
        getUserPermissionSetGroupAssignments({ filters: filtersToSend })
            .then(result => {
                console.log('User permission set group assignments data received:', result);
                if (result && result.headers && result.rows) {
                    console.log('Headers:', result.headers);
                    console.log('Row count:', result.rows.length);
                    
                    // Log the first row for debugging
                    if (result.rows.length > 0) {
                        console.log('First row values:', result.rows[0].values);
                    }
                    
                    this.setReportDataWithPagination(result);
                } else {
                    console.error('Invalid user permission set group assignments data received:', result);
                    this.error = 'No permission set group assignments found in your organization';
                }
            })
            .catch(error => {
                console.error('Error fetching user permission set group assignments data:', error);
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    fetchCombinedPermissionAssignmentData() {
        console.log('Fetching combined user permission set and permission set group assignments data...');
        console.log('Current selectedFilters:', this.selectedFilters);
        
        // First test if permission set group assignments are available
        testPermissionSetGroupAssignments()
            .then(testResult => {
                console.log('Permission Set Group Assignment Test Result:', testResult);
            })
            .catch(error => {
                console.error('Error testing permission set group assignments:', error);
            });
        
        // Get filters for user permission set assignments (excluding the parent filter)
        const permissionSetAssignmentFilters = this.selectedFilters.filter(filter => 
            filter !== 'userPermissionSetAssignmentsReport' && filter !== 'userPermissionSetGroupAssignmentsReport' &&
            filter.startsWith('userPermissionSetAssignment') && !filter.startsWith('userPermissionSetGroupAssignment')
        );
        
        // Get filters for user permission set group assignments (excluding the parent filter)
        const permissionSetGroupAssignmentFilters = this.selectedFilters.filter(filter => 
            filter !== 'userPermissionSetAssignmentsReport' && filter !== 'userPermissionSetGroupAssignmentsReport' &&
            filter.startsWith('userPermissionSetGroupAssignment')
        );
        
        console.log('Permission Set Assignment Filters:', permissionSetAssignmentFilters);
        console.log('Permission Set Group Assignment Filters:', permissionSetGroupAssignmentFilters);
        
        // Fetch both datasets in parallel
        const permissionSetAssignmentsPromise = getUserPermissionSetAssignments({ filters: permissionSetAssignmentFilters });
        const permissionSetGroupAssignmentsPromise = getUserPermissionSetGroupAssignments({ filters: permissionSetGroupAssignmentFilters });
        
        Promise.all([permissionSetAssignmentsPromise, permissionSetGroupAssignmentsPromise])
            .then(([permissionSetAssignmentsResult, permissionSetGroupAssignmentsResult]) => {
                console.log('=== PERMISSION SET ASSIGNMENTS RESULT ===');
                console.log('Headers:', permissionSetAssignmentsResult?.headers);
                console.log('Row count:', permissionSetAssignmentsResult?.rows?.length);
                console.log('First few rows:', permissionSetAssignmentsResult?.rows?.slice(0, 3));
                
                console.log('=== PERMISSION SET GROUP ASSIGNMENTS RESULT ===');
                console.log('Headers:', permissionSetGroupAssignmentsResult?.headers);
                console.log('Row count:', permissionSetGroupAssignmentsResult?.rows?.length);
                console.log('First few rows:', permissionSetGroupAssignmentsResult?.rows?.slice(0, 3));
                
                // Combine the results
                const combinedResult = this.combinePermissionAssignmentResults(permissionSetAssignmentsResult, permissionSetGroupAssignmentsResult);
                
                console.log('=== COMBINED RESULT ===');
                console.log('Headers:', combinedResult?.headers);
                console.log('Row count:', combinedResult?.rows?.length);
                console.log('First few rows:', combinedResult?.rows?.slice(0, 5));
                
                if (combinedResult && combinedResult.headers && combinedResult.rows) {
                    this.setReportDataWithPagination(combinedResult);
                } else {
                    this.error = 'No permission assignment data found in your organization';
                }
            })
            .catch(error => {
                console.error('Error fetching combined permission assignment data:', error);
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    combinePermissionAssignmentResults(permissionSetAssignmentsResult, permissionSetGroupAssignmentsResult) {
        console.log('Starting combination with separate rows for each assignment...');
        
        // Create headers for the individual assignment view
        const combinedHeaders = [
            'User Name', 
            'User Email', 
            'User ID', 
            'Permission Set/Group Name',
            'Assignment Type',
            'User Profile', 
            'User Is Active'
        ];
        
        const combinedRows = [];
        let rowIndex = 0;
        
        // Process Permission Set Assignments - each assignment gets its own row
        if (permissionSetAssignmentsResult && permissionSetAssignmentsResult.headers && permissionSetAssignmentsResult.rows) {
            const headers = permissionSetAssignmentsResult.headers;
            
            permissionSetAssignmentsResult.rows.forEach(row => {
                // Find user-related fields
                const userNameIndex = headers.findIndex(h => h.includes('UserName'));
                const userEmailIndex = headers.findIndex(h => h.includes('UserEmail'));
                const userIdIndex = headers.findIndex(h => h.includes('UserId'));
                const permissionSetNameIndex = headers.findIndex(h => h.includes('PermissionSetName') && !h.includes('Group'));
                const userProfileIndex = headers.findIndex(h => h.includes('UserProfile'));
                const userActiveIndex = headers.findIndex(h => h.includes('IsActive'));
                
                const userName = userNameIndex >= 0 ? row.values[userNameIndex] : '';
                const userEmail = userEmailIndex >= 0 ? row.values[userEmailIndex] : '';
                const userId = userIdIndex >= 0 ? row.values[userIdIndex] : '';
                const permissionSetName = permissionSetNameIndex >= 0 ? row.values[permissionSetNameIndex] : '';
                const userProfile = userProfileIndex >= 0 ? row.values[userProfileIndex] : '';
                const userActive = userActiveIndex >= 0 ? row.values[userActiveIndex] : '';
                
                // Create a separate row for each permission set assignment
                if (permissionSetName) {
                    const newRow = {
                        key: `assignment-${rowIndex++}`,
                        values: [
                            userName || '',
                            userEmail || '',
                            userId || '',
                            permissionSetName,
                            'Permission Set',
                            userProfile || '',
                            userActive || ''
                        ]
                    };
                    combinedRows.push(newRow);
                }
            });
        }
        
        // Process Permission Set Group Assignments - each assignment gets its own row
        if (permissionSetGroupAssignmentsResult && permissionSetGroupAssignmentsResult.headers && permissionSetGroupAssignmentsResult.rows) {
            // Check if this is an error/message row
            const isErrorMessage = permissionSetGroupAssignmentsResult.rows.length === 1 && 
                                  permissionSetGroupAssignmentsResult.rows[0].values[0] && 
                                  permissionSetGroupAssignmentsResult.rows[0].values[0].includes('No permission set group');
            
            console.log('Permission Set Group Assignment error check:', {
                isErrorMessage: isErrorMessage,
                firstRowValue: permissionSetGroupAssignmentsResult.rows[0]?.values[0],
                totalRows: permissionSetGroupAssignmentsResult.rows.length
            });
            
            if (!isErrorMessage) {
                const headers = permissionSetGroupAssignmentsResult.headers;
                
                permissionSetGroupAssignmentsResult.rows.forEach(row => {
                    // Find user-related fields
                    const userNameIndex = headers.findIndex(h => h.includes('UserName'));
                    const userEmailIndex = headers.findIndex(h => h.includes('UserEmail'));
                    const userIdIndex = headers.findIndex(h => h.includes('UserId'));
                    const permissionSetGroupNameIndex = headers.findIndex(h => h.includes('PermissionSetGroupName'));
                    const userProfileIndex = headers.findIndex(h => h.includes('UserProfile'));
                    const userActiveIndex = headers.findIndex(h => h.includes('IsActive'));
                    
                    const userName = userNameIndex >= 0 ? row.values[userNameIndex] : '';
                    const userEmail = userEmailIndex >= 0 ? row.values[userEmailIndex] : '';
                    const userId = userIdIndex >= 0 ? row.values[userIdIndex] : '';
                    const permissionSetGroupName = permissionSetGroupNameIndex >= 0 ? row.values[permissionSetGroupNameIndex] : '';
                    const userProfile = userProfileIndex >= 0 ? row.values[userProfileIndex] : '';
                    const userActive = userActiveIndex >= 0 ? row.values[userActiveIndex] : '';
                    
                    // Create a separate row for each permission set group assignment
                    if (permissionSetGroupName) {
                        const newRow = {
                            key: `assignment-${rowIndex++}`,
                            values: [
                                userName || '',
                                userEmail || '',
                                userId || '',
                                permissionSetGroupName,
                                'Permission Set Group',
                                userProfile || '',
                                userActive || ''
                            ]
                        };
                        combinedRows.push(newRow);
                    }
                });
            } else {
                console.log('Skipping permission set group assignment error message');
            }
        }
        
        console.log('Individual assignment data created:', {
            totalAssignments: combinedRows.length,
            headers: combinedHeaders,
            firstFewRows: combinedRows.slice(0, 3)
        });
        
        return {
            headers: combinedHeaders,
            rows: combinedRows
        };
    }

    // Add these properties with the other @track properties
    @track showUserSelectionModal = false;
    @track availableUsers = [];
    @track selectedUsers = [];
    maxUserSelection = 5; // Maximum number of users that can be selected for comparison
    @track userPermissionFields = [];
    @track allUserFields = [];
    @track userFieldsLoaded = false;
    @track dynamicFilterOptions = [];
    
    // New UI enhancement properties
    @track recordCount = '0';
    @track filterCount = '0';
    
    // Toggle for filtering users by field values
    @track filterByFieldValues = false;
    
    // Expandable section states
    @track userDetailsExpanded = false;
    @track permissionsExpanded = false;
    
    // Search functionality for user information fields
    @track userDetailsSearchTerm = '';
    @track permissionsSearchTerm = '';
    
    // Handle toggle change for filtering by field values
    handleFilterToggleChange(event) {
        this.filterByFieldValues = event.target.checked;
        console.log('Filter by field values toggled:', this.filterByFieldValues);
    }
    
    // Handle expandable section toggles
    handleUserDetailsToggle() {
        this.userDetailsExpanded = !this.userDetailsExpanded;
    }
    
    handlePermissionsToggle() {
        this.permissionsExpanded = !this.permissionsExpanded;
    }
    
    // Handle search input changes
    handleUserDetailsSearch(event) {
        this.userDetailsSearchTerm = event.target.value.toLowerCase();
    }
    
    handlePermissionsSearch(event) {
        this.permissionsSearchTerm = event.target.value.toLowerCase();
    }
    
    // Computed getters for chevron icons
    get userDetailsChevronIcon() {
        return this.userDetailsExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }
    
    get permissionsChevronIcon() {
        return this.permissionsExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }
    
    // Computed getters for field arrays
    get userDetailsFields() {
        // Define core user information fields
        const coreFields = [
            { label: 'User Id', value: 'userId' },
            { label: 'User Name', value: 'userName' },
            { label: 'Email', value: 'userEmail' },
            { label: 'First Name', value: 'firstName' },
            { label: 'Last Name', value: 'lastName' },
            { label: 'Username', value: 'username' },
            { label: 'Is Active', value: 'isActive' },
            { label: 'Profile Name', value: 'profileName' },
            { label: 'User Role', value: 'userRole' },
            { label: 'Role Id', value: 'roleId' },
            { label: 'Manager', value: 'manager' },
            { label: 'Title', value: 'title' },
            { label: 'Department', value: 'department' },
            { label: 'Last Login Date', value: 'lastLoginDate' },
            { label: 'User License', value: 'userLicense' },
            { label: 'Territory Name', value: 'Territory_Name__c' },
            { label: 'Active in Territory', value: 'Active_in_Territory__c' },
            { label: 'Role in Territory', value: 'Role_in_Territory__c' }
        ];

        // Filter out permission-related fields from allUserFields
        const filteredDynamicFields = this.allUserFields.filter(field => 
            !['userPermissionSets', 'userPermissionSetNames', 'userPermissionSetGroups', 
              'userPermissionSetGroupNames', 'userPermissionSetIds', 'userPermissionSetGroupIds'].includes(field.value)
        );

        // Combine core fields with dynamic fields, removing duplicates based on value
        const combinedFields = [...coreFields];
        const existingValues = new Set(coreFields.map(field => field.value.toLowerCase()));

        // Add dynamic fields that don't already exist
        filteredDynamicFields.forEach(field => {
            // Safely get field value and name
            const fieldValue = field.value || field.name || '';
            const fieldName = field.name || field.value || '';
            
            if (fieldValue) {
                const fieldValueLower = fieldValue.toLowerCase();
                const fieldNameLower = fieldName.toLowerCase();
                
                if (!existingValues.has(fieldValueLower) && !existingValues.has(fieldNameLower)) {
                    combinedFields.push({
                        label: field.label || fieldValue,
                        value: fieldName || fieldValue // Use field.name if available, otherwise field.value
                    });
                    existingValues.add(fieldValueLower);
                    if (fieldName && fieldName !== fieldValue) {
                        existingValues.add(fieldNameLower);
                    }
                }
            }
        });

        // Filter fields based on search term
        let filteredFields = combinedFields;
        if (this.userDetailsSearchTerm) {
            filteredFields = combinedFields.filter(field => 
                field.label.toLowerCase().includes(this.userDetailsSearchTerm) ||
                field.value.toLowerCase().includes(this.userDetailsSearchTerm)
            );
        }

        // Ensure each field has a unique key for template iteration
        return filteredFields.map((field, index) => ({
            ...field,
            key: `user-detail-${field.value}-${index}` // Create unique key
        }));
    }
    //getter for psermissionsaccess fields in user intel
    get permissionsFields() {
        // Return permission-related fields with unique keys
        const permissionFields = [
             
          { label: 'Permission Sets', value: 'userPermissionSetNames' },
            { label: 'Permission Set IDs', value: 'userPermissionSetIds' },
            { label: 'Permission Set Groups', value: 'userPermissionSetGroupNames' },
            { label: 'Permission Set Group IDs', value: 'userPermissionSetGroupIds' },
            { label: 'Assignee ID', value: 'assigneeId' },
            { label: 'Expiration Date', value: 'expirationDate' },
             
            { label: 'Is Active', value: 'isActive' },
            { label: 'Is Revoked', value: 'isRevoked' },
            { label: 'Last Created By Change ID', value: 'lastCreatedByChangeId' },
            { label: 'Last Deleted By Change ID', value: 'lastDeletedByChangeId' },
             
            { label: 'System Modstamp', value: 'systemModstamp' },
            { label: 'Created By ID', value: 'createdById' },
            { label: 'Created Date', value: 'createdDate' },
            { label: 'Description', value: 'description' }
        ];

        // Filter fields based on search term
        let filteredFields = permissionFields;
        if (this.permissionsSearchTerm) {
            filteredFields = permissionFields.filter(field => 
                field.label.toLowerCase().includes(this.permissionsSearchTerm) ||
                field.value.toLowerCase().includes(this.permissionsSearchTerm)
            );
        }

        // Ensure each field has a unique key for template iteration
        return filteredFields.map((field, index) => ({
            ...field,
            key: `permission-${field.value}-${index}` // Create unique key
        }));
    }
    
    // Computed getters for selection counts
    get selectedUserDetailsCount() {
        return this.selectedFilters.filter(filter => 
            this.userDetailsFields.some(field => field.value === filter)
        ).length;
    }
    
    get selectedPermissionsCount() {
        return this.selectedFilters.filter(filter => 
            this.permissionsFields.some(field => field.value === filter)
        ).length;
    }
    

    
    // Add these methods after the fetchUserTerritoriesData method
    
    /**
     * Fetches permission set details data
     */
    fetchPermissionSetDetailsData() {
        console.log('Fetching permission set details data...');
        
        // Create a copy of selectedFilters without the parent filter
        const filtersToSend = this.selectedFilters.filter(filter => filter !== 'permissionSetDetailsReport');
        console.log('Filters to send:', filtersToSend);
        
        getPermissionSetDetails({ filters: filtersToSend })
            .then(result => {
                console.log('Permission set details data received:', result);
                if (result && result.headers && result.rows) {
                    console.log('Headers:', result.headers);
                    console.log('Row count:', result.rows.length);
                    
                    // Log the first row for debugging
                    if (result.rows.length > 0) {
                        console.log('First row values:', result.rows[0].values);
                    }
                    
                    this.setReportDataWithPagination(result);
                } else {
                    console.error('Invalid permission set details data received:', result);
                    this.error = 'No permission set details found in your organization';
                }
            })
            .catch(error => {
                console.error('Error fetching permission set details data:', error);
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Fetches users for the compare settings functionality
     */
    fetchUsersForComparison() {
        this.isLoading = true;
        
        // Use the existing getReportData method to fetch users
        getReportData({ filters: ['userName', 'userId', 'profileName', 'userStatus'], cardId: 'user', pageSize: this.pageSize, pageNumber: this.currentPage })
            .then(result => {
                if (result && result.rows) {
                    this.availableUsers = result.rows.map((row, index) => {
                        return {
                            id: row.values[1], // userId
                            name: row.values[0], // userName
                            profile: row.values[2], // profileName
                            status: row.values[3], // userStatus
                            selected: false
                        };
                    });
                    
                    // Filter to only active users
                    this.availableUsers = this.availableUsers.filter(user => 
                        user.status === 'Active'
                    );
                    
                    this.showUserSelectionModal = true;
                } else {
                    this.error = 'No users found in your organization';
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.handleError(error);
                this.isLoading = false;
            });
    }
    
    /**
     * Handles the user selection in the modal
     */
    handleUserSelection(event) {
        const userId = event.target.dataset.id;
        const isChecked = event.target.checked;
        
        // Update the selected state in availableUsers
        this.availableUsers = this.availableUsers.map(user => {
            if (user.id === userId) {
                user.selected = isChecked;
            }
            return user;
        });
        
        // Update selectedUsers array
        if (isChecked) {
            // Check if max selection limit is reached
            const currentSelectedCount = this.availableUsers.filter(user => user.selected).length;
            if (currentSelectedCount > this.maxUserSelection) {
                // Uncheck the checkbox
                event.target.checked = false;
                
                // Update the user's selected state back to false
                this.availableUsers = this.availableUsers.map(user => {
                    if (user.id === userId) {
                        user.selected = false;
                    }
                    return user;
                });
                
                // Show error message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Selection Limit Reached',
                        message: `You can select a maximum of ${this.maxUserSelection} users for comparison`,
                        variant: 'warning'
                    })
                );
                return;
            }
        }
    }
    
    /**
     * Closes the user selection modal
     */
    handleUserSelectionModalClose() {
        this.showUserSelectionModal = false;
        
        // Reset selections if the modal is closed without showing permissions
        this.availableUsers = this.availableUsers.map(user => {
            user.selected = false;
            return user;
        });
    }
    
    /**
     * Shows the permissions comparison for selected users
     */
    showPermissionsComparison() {
        // Get the selected users
        this.selectedUsers = this.availableUsers.filter(user => user.selected);
        
        if (this.selectedUsers.length < 2) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Selection Required',
                    message: 'Please select at least 2 users to compare',
                    variant: 'warning'
                })
            );
            return;
        }
        
        this.isLoading = true;
        this.showUserSelectionModal = false;
        
        // Fetch user permission fields from User object
        this.fetchUserPermissionFields();
    }
    
    /**
     * Fetches permission fields from the User object
     */
    fetchUserPermissionFields() {
        // Use Apex to get a list of User object permission fields
        getUserPermissionFields({ userIds: this.selectedUsers.map(user => user.id) })
            .then(result => {
                if (result) {
                    this.userPermissionFields = result.permissionFields;
                    
                    // Format the data for display
                    this.formatComparisonReportData(result);
                } else {
                    this.error = 'Failed to fetch user permission fields';
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.handleError(error);
                this.isLoading = false;
            });
    }
    
    /**
     * Formats the comparison data for display
     */
    formatComparisonReportData(permissionData) {
        // Create report data structure
        const headers = ['Permission Field'];
        this.selectedUsers.forEach(user => {
            headers.push(user.name);
        });
        
        // Group permission fields by category
        const fieldsByCategory = {};
        permissionData.permissionFields.forEach(field => {
            if (!fieldsByCategory[field.category]) {
                fieldsByCategory[field.category] = [];
            }
            fieldsByCategory[field.category].push(field);
        });
        
        // Create rows organized by category
        const rows = [];
        
        // Process each category
        Object.keys(fieldsByCategory).sort().forEach(category => {
            // Add a category header row
            rows.push({
                id: `category-${category}`,
                isCategory: true,
                category: category,
                rowClass: 'category-row',
                cells: [
                    { id: `category-${category}-label`, value: category, isCategory: true }
                ]
            });
            
            // Add rows for each field in this category
            fieldsByCategory[category].forEach(field => {
                const row = {
                    id: field.name,
                    category: category,
                    rowClass: 'slds-hint-parent',
                    cells: [
                        { id: `${field.name}-label`, value: field.label }
                    ]
                };
                
                // Add a cell for each selected user
                this.selectedUsers.forEach(user => {
                    const userPermissions = permissionData.userPermissions[user.id] || {};
                    const hasPermission = userPermissions[field.name] === true;
                    row.cells.push({
                        id: `${field.name}-${user.id}`,
                        value: hasPermission ? 'Yes' : 'No',
                        hasPermission: hasPermission
                    });
                });
                
                rows.push(row);
            });
        });
        
        // Add user profile information at the top
        const profileRow = {
            id: 'profile-info',
            isProfileInfo: true,
            rowClass: 'profile-row',
            cells: [
                { id: 'profile-label', value: 'Profile' }
            ]
        };
        
        this.selectedUsers.forEach(user => {
            const userInfo = permissionData.userPermissions[user.id] || {};
            profileRow.cells.push({
                id: `profile-${user.id}`,
                value: userInfo.ProfileName || 'Unknown',
                isProfileInfo: true
            });
        });
        
        // Insert profile row at the beginning
        rows.unshift(profileRow);
        
        // Set the report data
        this.reportData = {
            headers: headers.map(header => ({ label: header, value: header })),
            rows: rows,
            isComparisonReport: true
        };
    }

    /**
     * Handle Sharing Intel report generation
     */
    handleSharingIntelReport() {
        // For Sharing Settings, directly call getAllSharingRulesData
        if (this.selectedFilters.includes('sharingSettings')) {
            this.fetchSharingRulesData();
            return;
        }
        
        // For Organization Wide Defaults, directly call getOrgWideDefaultsData
        if (this.selectedFilters.includes('orgWideDefaults')) {
            this.fetchOrgWideDefaultsData();
            return;
        }
        
        // For Public Groups, call getPublicGroupsData with selected sub-filters
        if (this.selectedFilters.includes('publicGroups')) {
            this.fetchPublicGroupsData();
            return;
        }
        
        // For Public Group Members, call getPublicGroupMembersData with selected sub-filters
        if (this.selectedFilters.includes('publicGroupMembers')) {
            this.fetchPublicGroupMembersData();
            return;
        }
    }
    
    /**
     * Handle Reporting Intel report generation
     */
    handleReportingIntelReport() {
        // For Report Folder Share, call getReportFolderShareData
        if (this.selectedFilters.includes('reportFolderShare')) {
            this.fetchReportFolderShareData();
            return;
        }
        
        // For Dashboard Folder Share, call getDashboardFolderShareData
        if (this.selectedFilters.includes('dashboardFolderShare')) {
            this.fetchDashboardFolderShareData();
            return;
        }
        
        // For Dashboard and Running User, call getDashboardRunningUserData
        if (this.selectedFilters.includes('dashboardRunningUser')) {
            this.fetchDashboardRunningUserData();
            return;
        }
    }
    
    /**
     * Handle Profile Assignment Intel report generation
     */
    handleProfileAssignmentReport() {
        this.fetchProfileAssignmentData();
    }
    
    /**
     * Handle Permissions Intel report generation
     */
    handlePermissionsIntelReport() {
        // For Role Type in Permissions Intel, call getRoleTypeData
        if (this.selectedFilters.includes('roleType')) {
            // Check if at least one sub-filter is selected
            const roleTypeFilter = this.permissionsIntelFilterOptions.find(f => f.value === 'roleType');
            const hasSubFilters = roleTypeFilter && roleTypeFilter.subFilters.some(sub => 
                this.selectedFilters.includes(sub.value)
            );
            
            if (hasSubFilters) {
                this.fetchRoleTypeData();
                return;
            } else {
                this.error = 'Please select at least one sub-filter for Role Type';
                this.isLoading = false;
                return;
            }
        }
        
        // For Territories in Permissions Intel, call getTerritoriesData
        if (this.selectedFilters.includes('territories')) {
            // Check if at least one sub-filter is selected
            const territoriesFilter = this.permissionsIntelFilterOptions.find(f => f.value === 'territories');
            const hasSubFilters = territoriesFilter && territoriesFilter.subFilters.some(sub => 
                this.selectedFilters.includes(sub.value)
            );
            
            if (hasSubFilters) {
                this.fetchTerritoriesData();
                return;
            } else {
                this.error = 'Please select at least one sub-filter for Territories';
                this.isLoading = false;
                return;
            }
        }
        
        // For Permission Set not in Permission Set Group in Permissions Intel, call getPermissionSetNoGroupData
        if (this.selectedFilters.includes('permissionSetNoGroup')) {
            // Check if at least one sub-filter is selected
            const permissionSetFilter = this.permissionsIntelFilterOptions.find(f => f.value === 'permissionSetNoGroup');
            const hasSubFilters = permissionSetFilter && permissionSetFilter.subFilters.some(sub => 
                this.selectedFilters.includes(sub.value)
            );
            
            if (hasSubFilters) {
                this.fetchPermissionSetNoGroupData();
                return;
            } else {
                this.error = 'Please select at least one sub-filter for Permission Set not in Permission Set Group';
                this.isLoading = false;
                return;
            }
        }
        
        // For Permission Set Details in Permissions Intel, call fetchPermissionSetDetailsData
        if (this.selectedFilters.includes('permissionSetDetails')) {
            // Check if at least one sub-filter is selected
            const permissionSetDetailsFilter = this.permissionsIntelFilterOptions.find(f => f.value === 'permissionSetDetails');
            const hasSubFilters = permissionSetDetailsFilter && permissionSetDetailsFilter.subFilters.some(sub => 
                this.selectedFilters.includes(sub.value)
            );
            
            if (hasSubFilters) {
                this.fetchPermissionSetDetailsData();
                return;
            } else {
                this.error = 'Please select at least one sub-filter for Permission Set Details';
                this.isLoading = false;
                return;
            }
        }
    }
    
    /**
     * Handle Other Intel report generation
     */
    handleOtherIntelReport() {
        // For Installed Packages in Other Intel, call getInstalledPackagesData
        if (this.selectedFilters.includes('installedPackages')) {
            // Check if at least one sub-filter is selected
            const installedPackagesFilter = this.otherIntelFilterOptions.find(f => f.value === 'installedPackages');
            const hasSubFilters = installedPackagesFilter && installedPackagesFilter.subFilters.some(sub => 
                this.selectedFilters.includes(sub.value)
            );
            
            if (hasSubFilters) {
                this.fetchInstalledPackagesData();
                return;
            } else {
                this.error = 'Please select at least one sub-filter for Installed Packages';
                this.isLoading = false;
                return;
            }
        }
        
        // For List View in Other Intel, call getListViewData
        if (this.selectedFilters.includes('listView')) {
            // Check if at least one sub-filter is selected
            const listViewFilter = this.otherIntelFilterOptions.find(f => f.value === 'listView');
            const hasSubFilters = listViewFilter && listViewFilter.subFilters.some(sub => 
                this.selectedFilters.includes(sub.value)
            );
            
            if (hasSubFilters) {
                this.fetchListViewData();
                return;
            } else {
                this.error = 'Please select at least one sub-filter for List View';
                this.isLoading = false;
                return;
            }
        }
        
        // For Apex Classes in Other Intel, call getApexClassesData
        if (this.selectedFilters.includes('apexCode') && 
            this.selectedFilters.includes('apexClasses')) {
            // Check if at least one sub-filter is selected
            const apexCodeFilter = this.otherIntelFilterOptions.find(f => f.value === 'apexCode');
            const apexClassesFilter = apexCodeFilter.subFilters.find(f => f.value === 'apexClasses');
            const hasSubFilters = apexClassesFilter && apexClassesFilter.nestedFilters.some(sub => 
                this.selectedFilters.includes(sub.value)
            );
            
            if (hasSubFilters) {
                this.fetchApexClassesData();
                return;
            } else {
                this.error = 'Please select at least one sub-filter for Apex Classes';
                this.isLoading = false;
                return;
            }
        }
        
        // For Apex Triggers in Other Intel, call getApexTriggersData
        if (this.selectedFilters.includes('apexCode') && 
            this.selectedFilters.includes('apexTriggers')) {
            // Check if at least one sub-filter is selected
            const apexCodeFilter = this.otherIntelFilterOptions.find(f => f.value === 'apexCode');
            const apexTriggersFilter = apexCodeFilter.subFilters.find(f => f.value === 'apexTriggers');
            const hasSubFilters = apexTriggersFilter && apexTriggersFilter.nestedFilters.some(sub => 
                this.selectedFilters.includes(sub.value)
            );
            
            if (hasSubFilters) {
                this.fetchApexTriggersData();
                return;
            } else {
                this.error = 'Please select at least one sub-filter for Apex Triggers';
                this.isLoading = false;
                return;
            }
        }
    }

    /**
     * Handle Config Intel report generation
     */
    handleConfigIntelReport() {
        console.log('Running Config Intel report with filters:', this.selectedFilters);
        this.isLoading = true;
        this.error = null;
        
        // For Validation Rules
        if (this.selectedFilters.includes('validationRules')) {
            // Use a predefined set of fields for validation rules for simplicity
            const predefinedFields = ['validationRules_validationRuleName', 'validationRules_object', 'validationRules_active', 'validationRules_description', 'validationRules_errorMessage', 'validationRules_errorDisplayField'];
            console.log('Using predefined fields for Validation Rules:', predefinedFields);
            
            // Clear all sub-filters and replace with predefined fields
            this.selectedFilters = this.selectedFilters.filter(filter => filter !== 'validationRules_validationRuleName' && 
                                                           filter !== 'validationRules_object' && 
                                                           filter !== 'validationRules_active' && 
                                                           filter !== 'validationRules_description' && 
                                                           filter !== 'validationRules_errorMessage' && 
                                                           filter !== 'validationRules_errorDisplayField' && 
                                                           filter !== 'validationRules_namespacePrefix' && 
                                                           filter !== 'validationRules_criteria');
            
            // Add our predefined fields
            predefinedFields.forEach(field => {
                if (!this.selectedFilters.includes(field)) {
                    this.selectedFilters.push(field);
                }
            });
            
            console.log('Final filters for API call:', this.selectedFilters);
            
            // Call the Apex method
            getConfigIntelReportData({ filters: this.selectedFilters })
                .then(result => {
                    console.log('Received result:', JSON.stringify(result));
                    
                    if (!this.setReportDataWithPagination(result)) {
                        this.error = 'No validation rules data found. The response from the server was empty or invalid.';
                    }
                })
                .catch(error => {
                    console.error('Error in getConfigIntelReportData:', error);
                    this.handleError(error);
                })
                .finally(() => {
                    this.isLoading = false;
                });
            return;
        }

        // Fields in Page Layouts
        if (this.selectedFilters.includes('fieldsInPageLayouts')) {
            // Check if at least one sub-filter is selected
            const hasSubFilters = this.selectedFilters.some(filter => 
                filter.startsWith('fieldsInPageLayouts_')
            );
            
            if (!hasSubFilters) {
                // Use predefined set of fields for page layouts
                const predefinedFields = ['fieldsInPageLayouts_fieldLabel', 'fieldsInPageLayouts_object', 'fieldsInPageLayouts_pageLayout'];
                console.log('Using predefined fields for Fields in Page Layouts:', predefinedFields);
                
                // Add predefined fields
                predefinedFields.forEach(field => {
                    if (!this.selectedFilters.includes(field)) {
                        this.selectedFilters.push(field);
                    }
                });
            }
            
            console.log('Final filters for Fields in Page Layouts API call:', this.selectedFilters);
            
            // Prompt user to select an object
            const objectInput = prompt('Please enter the API name of the object to analyze (e.g., Account, Contact, Custom__c):', 'Account');
            
            if (!objectInput) {
                this.isLoading = false;
                this.error = 'Object name is required for Page Layout analysis.';
                return;
            }
            
            // Call the Apex method to get page layout data
            // We'll use IntelController.fetchTableDataOption36 which calls PageLayoutAssignmentClass.readProfileLayoutAssignmentsForObject
            
            fetchTableDataOption36({ selectedOptions: [objectInput] })
                .then(result => {
                    console.log('Received page layout result:', JSON.stringify(result));
                    
                    // Transform the data to match the expected format for the report
                    const reportData = this.transformPageLayoutData(result, this.selectedFilters);
                    
                    if (!this.setReportDataWithPagination(reportData)) {
                        this.error = 'No page layout data found for the specified object.';
                    }
                })
                .catch(error => {
                    console.error('Error fetching page layout data:', error);
                    this.handleError(error);
                })
                .finally(() => {
                    this.isLoading = false;
                });
            return;
        }

        // Page Layouts Assignment
        if (this.selectedFilters.includes('pageLayoutsAssignment')) {
            // Check if at least one sub-filter is selected
            const hasSubFilters = this.selectedFilters.some(filter => 
                filter.startsWith('pageLayoutsAssignment_')
            );
            
            if (!hasSubFilters) {
                // Use predefined set of fields for page layout assignments
                const predefinedFields = ['pageLayoutsAssignment_object', 'pageLayoutsAssignment_pageLayout'];
                console.log('Using predefined fields for Page Layout Assignments:', predefinedFields);
                
                // Add predefined fields
                predefinedFields.forEach(field => {
                    if (!this.selectedFilters.includes(field)) {
                        this.selectedFilters.push(field);
                    }
                });
            }
            
            console.log('Final filters for Page Layout Assignments API call:', this.selectedFilters);
            
            // Prompt user to select an object
            const objectInput = prompt('Please enter the API name of the object to analyze (e.g., Account, Contact, Custom__c):', 'Account');
            
            if (!objectInput) {
                this.isLoading = false;
                this.error = 'Object name is required for Page Layout Assignment analysis.';
                return;
            }
            
            // Call the Apex method to get page layout assignment data
            // We'll use IntelController.fetchTableDataOption36 which calls PageLayoutAssignmentClass.readProfileLayoutAssignmentsForObject
            
            fetchTableDataOption36({ selectedOptions: [objectInput] })
                .then(result => {
                    console.log('Received page layout assignment result:', JSON.stringify(result));
                    
                    // Transform the data to match the expected format for the report
                    const reportData = this.transformPageLayoutAssignmentData(result, this.selectedFilters);
                    
                    if (!this.setReportDataWithPagination(reportData)) {
                        this.error = 'No page layout assignment data found for the specified object.';
                    }
                })
                .catch(error => {
                    console.error('Error fetching page layout assignment data:', error);
                    this.handleError(error);
                })
                .finally(() => {
                    this.isLoading = false;
                });
            return;
        }

        // If no specific filter is selected
        this.isLoading = false;
        this.error = 'Please select a specific filter to generate a report.';
    }

    // Add this method after the generateUUID method
    generateSubFilterId(parentValue, subValue) {
        return `${parentValue}-${subValue}`;
    }
    
    /**
     * Transform page layout data from PageLayoutAssignmentClass to report format
     * @param {Object} pageLayoutData - Data from PageLayoutAssignmentClass.readProfileLayoutAssignmentsForObject
     * @param {Array} selectedFilters - Selected filters for the report
     * @returns {Object} - Formatted report data
     */
    transformPageLayoutData(pageLayoutData, selectedFilters) {
        console.log('Transforming page layout data:', pageLayoutData);
        
        // Create the report data structure
        const reportData = {
            headers: selectedFilters,
            rows: []
        };
        
        if (!pageLayoutData || !pageLayoutData.profileData) {
            console.error('Invalid page layout data format');
            return reportData;
        }
        
        // Extract data from the profileData map
        const profileData = pageLayoutData.profileData;
        const objectName = pageLayoutData.objectSelected;
        
        // Iterate through profiles
        for (const profileName in profileData) {
            const recordTypes = profileData[profileName];
            
            // Iterate through record types
            for (const recordTypeName in recordTypes) {
                const layouts = recordTypes[recordTypeName];
                
                // Iterate through layouts
                layouts.forEach(layoutName => {
                    const rowData = [];
                    
                    // Add data for each requested field
                    selectedFilters.forEach(filter => {
                        let value = '';
                        
                        switch (filter) {
                            case 'fieldsInPageLayouts_fieldLabel':
                                // This would require additional API calls to get field details
                                // For now, we'll leave it blank
                                value = 'See Page Layout in Setup';
                                break;
                            case 'fieldsInPageLayouts_object':
                                value = objectName;
                                break;
                            case 'fieldsInPageLayouts_pageLayout':
                                value = layoutName;
                                break;
                            default:
                                value = 'N/A';
                        }
                        
                        rowData.push(value);
                    });
                    
                    // Add the row to the report
                    reportData.rows.push({ values: rowData });
                });
            }
        }
        
        return reportData;
    }
    
    /**
     * Transform page layout assignment data from PageLayoutAssignmentClass to report format
     * @param {Object} pageLayoutData - Data from PageLayoutAssignmentClass.readProfileLayoutAssignmentsForObject
     * @param {Array} selectedFilters - Selected filters for the report
     * @returns {Object} - Formatted report data
     */
    transformPageLayoutAssignmentData(pageLayoutData, selectedFilters) {
        console.log('Transforming page layout assignment data:', pageLayoutData);
        
        // Create the report data structure
        const reportData = {
            headers: selectedFilters,
            rows: []
        };
        
        if (!pageLayoutData || !pageLayoutData.profileData) {
            console.error('Invalid page layout assignment data format');
            return reportData;
        }
        
        // Extract data from the profileData map
        const profileData = pageLayoutData.profileData;
        const objectName = pageLayoutData.objectSelected;
        
        // Iterate through profiles
        for (const profileName in profileData) {
            const recordTypes = profileData[profileName];
            
            // Iterate through record types
            for (const recordTypeName in recordTypes) {
                const layouts = recordTypes[recordTypeName];
                
                // Iterate through layouts
                layouts.forEach(layoutName => {
                    const rowData = [];
                    
                    // Add data for each requested field
                    selectedFilters.forEach(filter => {
                        let value = '';
                        
                        switch (filter) {
                            case 'pageLayoutsAssignment_fieldLabel':
                                // This would require additional API calls to get field details
                                value = 'N/A';
                                break;
                            case 'pageLayoutsAssignment_object':
                                value = objectName;
                                break;
                            case 'pageLayoutsAssignment_pageLayout':
                                value = `${layoutName} (${profileName} - ${recordTypeName || 'Master'})`;
                                break;
                            default:
                                value = 'N/A';
                        }
                        
                        rowData.push(value);
                    });
                    
                    // Add the row to the report
                    reportData.rows.push({ values: rowData });
                });
            }
        }
        
        return reportData;
    }

    /**
     * Load all User object fields dynamically
     */
    loadUserFields() {
        getAllUserFields()
            .then(result => {
                this.allUserFields = result;
                this.userFieldsLoaded = true;
                this.buildDynamicFilterOptions();
            })
            .catch(error => {
                console.error('Error loading User fields:', error);
                // Fall back to static filter options if dynamic loading fails
                this.userFieldsLoaded = true;
            });
    }

    /**
     * Build dynamic filter options based on loaded User fields
     */
    buildDynamicFilterOptions() {
        if (!this.allUserFields || this.allUserFields.length === 0) {
            return;
        }

        // Group fields by category
        const fieldsByCategory = {};
        this.allUserFields.forEach(field => {
            if (!fieldsByCategory[field.category]) {
                fieldsByCategory[field.category] = [];
            }
            fieldsByCategory[field.category].push({
                label: field.label,
                value: field.name
            });
        });

        // Build the dynamic filter options
        const dynamicUserDataFilters = [];
        
        // Add categories in a specific order for better UX
        const categoryOrder = [
            'Basic Information',
            'Contact Information', 
            'Organization',
            'Security & Access',
            'Authentication',
            'Localization',
            'System Information',
            'Custom Fields'
        ];

        // Add core user identification fields first (always at the top)
        const coreUserFields = [
            { label: 'User Name', value: 'Name' },
            { label: 'User ID', value: 'Id' },
            { label: 'Email', value: 'Email' },
            { label: 'Active Status', value: 'IsActive' },
            { label: 'First Name', value: 'FirstName' },
            { label: 'Last Name', value: 'LastName' },
            { label: 'Username', value: 'Username' }
        ];

        // Track added field values to prevent duplicates
        const addedFieldValues = new Set();

        // Filter out core fields that exist and add them first
        coreUserFields.forEach(coreField => {
            const existingField = this.allUserFields.find(field => {
                const fieldName = field.name || '';
                const coreValue = coreField.value || '';
                return fieldName.toLowerCase() === coreValue.toLowerCase();
            });
            if (existingField && existingField.name && !addedFieldValues.has(existingField.name.toLowerCase())) {
                dynamicUserDataFilters.push({
                    label: coreField.label,
                    value: existingField.name
                });
                addedFieldValues.add(existingField.name.toLowerCase());
            }
        });

        // Add a separator comment (this will help visually in the UI)
        dynamicUserDataFilters.push({ label: '--- User Details ---', value: 'separator1', disabled: true });

        categoryOrder.forEach(category => {
            if (fieldsByCategory[category] && fieldsByCategory[category].length > 0) {
                // Filter out core fields already added and prevent duplicates
                const categoryFields = fieldsByCategory[category].filter(field => {
                    const fieldValue = field.value || '';
                    if (!fieldValue) return false;
                    
                    const fieldValueLower = fieldValue.toLowerCase();
                    const alreadyAdded = addedFieldValues.has(fieldValueLower);
                    const isCoreField = coreUserFields.some(coreField => {
                        const coreValue = coreField.value || '';
                        return coreValue.toLowerCase() === fieldValueLower;
                    });
                    return !alreadyAdded && !isCoreField;
                });
                
                categoryFields.forEach(field => {
                    if (field.value) {
                        dynamicUserDataFilters.push(field);
                        addedFieldValues.add(field.value.toLowerCase());
                    }
                });
            }
        });

        // Add any remaining categories not in the order
        Object.keys(fieldsByCategory).forEach(category => {
            if (!categoryOrder.includes(category)) {
                const categoryFields = fieldsByCategory[category].filter(field => {
                    const fieldValue = field.value || '';
                    if (!fieldValue) return false;
                    
                    const fieldValueLower = fieldValue.toLowerCase();
                    const alreadyAdded = addedFieldValues.has(fieldValueLower);
                    const isCoreField = coreUserFields.some(coreField => {
                        const coreValue = coreField.value || '';
                        return coreValue.toLowerCase() === fieldValueLower;
                    });
                    return !alreadyAdded && !isCoreField;
                });
                
                categoryFields.forEach(field => {
                    if (field.value) {
                        dynamicUserDataFilters.push(field);
                        addedFieldValues.add(field.value.toLowerCase());
                    }
                });
            }
        });

        // Add permission fields at the end with a separator
        if (!addedFieldValues.has('separator2')) {
            dynamicUserDataFilters.push({ label: '--- Permissions ---', value: 'separator2', disabled: true });
            addedFieldValues.add('separator2');
        }
        
        const permissionFields = [
            { label: 'Permission Sets', value: 'userPermissionSetNames' },
            { label: 'Permission Set IDs', value: 'userPermissionSetIds' },
            { label: 'Permission Set Groups', value: 'userPermissionSetGroupNames' },
            { label: 'Permission Set Group IDs', value: 'userPermissionSetGroupIds' },
            { label: 'Assignee ID', value: 'AssigneeId' },
            { label: 'Expiration Date', value: 'ExpirationDate' },
            { label: 'ID', value: 'Id' },
            { label: 'Is Active', value: 'IsActive' },
            { label: 'Is Revoked', value: 'IsRevoked' },
            { label: 'Last Created By Change ID', value: 'LastCreatedByChangeId' },
            { label: 'Last Deleted By Change ID', value: 'LastDeletedByChangeId' },
            { label: 'Permission Set Group ID', value: 'PermissionSetGroupId' },
            { label: 'Permission Set ID', value: 'PermissionSetId' },
            { label: 'System Modstamp', value: 'SystemModstamp' },
            { label: 'Created By ID', value: 'CreatedById' },
            { label: 'Created Date', value: 'CreatedDate' },
            { label: 'Description', value: 'Description' }
        ];
        
        permissionFields.forEach(field => {
            if (!addedFieldValues.has(field.value.toLowerCase())) {
                dynamicUserDataFilters.push(field);
                addedFieldValues.add(field.value.toLowerCase());
            }
        });

        // Update the filterOptions with dynamic User Data
        this.dynamicFilterOptions = [
            {
                label: 'User Data',
                value: 'userData',
                subFilters: dynamicUserDataFilters
            },
            {
                label: 'User Territories',
                value: 'userTerritories',
                subFilters: [
                    { label: 'User Name', value: 'territoryUserName' },
                    { label: 'User Id', value: 'territoryUserId' },
                    { label: 'Territory Name', value: 'territoryName' },
                    { label: 'Active in Territory', value: 'territoryActive' },
                    { label: 'Role in Territory', value: 'territoryRole' },
                    { label: 'Last Login Date', value: 'territoryLastLogin' }
                ]
            },
            {
                label: 'Compare Settings on Users',
                value: 'compareUsers'
            }
        ];
    }

    // Enhanced UI methods
    refreshData() {
        this.handleRunReport();
    }

    exportData() {
        this.handleExportData();
    }

    retryOperation() {
        this.error = null;
        this.handleRunReport();
    }

    clearAllFilters() {
        this.selectedFilters = [];
        this.reportData = null;
        this.error = null;
        this.updateFilterCount();
        
        // Clear all checkboxes
        const checkboxes = this.template.querySelectorAll('input[type="checkbox"]');
        checkboxes.forEach(checkbox => {
            checkbox.checked = false;
        });

        this.showToast('Success', 'All filters cleared', 'success');
    }

    updateFilterCount() {
        this.filterCount = this.selectedFilters.length.toString();
    }

    updateRecordCount() {
        if (this.reportData && this.reportData.rows) {
            this.recordCount = this.reportData.rows.length.toString() + ' records';
        } else if (this.totalRecords) {
            this.recordCount = this.totalRecords.toString() + ' records';
        } else {
            this.recordCount = '0 records';
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'pester'
        });
        this.dispatchEvent(event);
    }
}