import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkPaidFeatureAccess from '@salesforce/apex/PermissionsManagerController.PaidFeatureAccess';
import getProfilesPaginated from '@salesforce/apex/PermissionsManagerController.getProfilesPaginated';
import getPermissionSetsPaginated from '@salesforce/apex/PermissionsManagerController.getPermissionSetsPaginated';
import getObjectsPaginated from '@salesforce/apex/PermissionsManagerController.getObjectsPaginated';
import getObjectPermissionsOptimized from '@salesforce/apex/PermissionsManagerController.getObjectPermissionsOptimized';
import getSystemPermissionAccessOptimized from '@salesforce/apex/PermissionsManagerController.getSystemPermissionAccessOptimized';
import getObjectPermissions from '@salesforce/apex/PermissionsManagerController.getObjectPermissions';
import getTabVisibility from '@salesforce/apex/PermissionsManagerController.getTabVisibility';
import getFieldPermissions from '@salesforce/apex/PermissionsManagerController.getFieldPermissions';

/**
 * @description Main component for exporting permissions - OPTIMIZED VERSION
 */
export default class PermissionsManager extends LightningElement {
    // Feature Access Control
    @track hasAccess = true;
    @track isCheckingAccess = true;
    
    @track profiles = [];
    @track permissionSets = [];
    @track objects = [];
    @track selectedProfiles = [];
    @track selectedPermSets = [];
    @track selectedObjects = [];
    @track isLoading = true;
    @track loadingStatusText = '';
    
    // Pagination properties - Optimized page sizes for filtered object loading
    @track profilePagination = { pageSize: 100, pageNumber: 1, totalPages: 1, hasNext: false, hasPrevious: false };
    @track permSetPagination = { pageSize: 100, pageNumber: 1, totalPages: 1, hasNext: false, hasPrevious: false };
    @track objectPagination = { pageSize: 100, pageNumber: 1, totalPages: 1, hasNext: false, hasPrevious: false }; // Increased from 50 to 100
    
    // Search terms
    @track profileSearchTerm = '';
    @track permSetSearchTerm = '';
    @track objectSearchTerm = '';
    
    // Loading states for individual components
    @track isProfilesLoading = false;
    @track isPermSetsLoading = false;
    @track isObjectsLoading = false;
    
    // Export Modal Properties
    @track showExportModal = false;
    @track exportStatusText = '';
    @track exportDetailsText = '';
    @track exportProgressValue = 0;
    @track isExportCancelDisabled = false;
    @track exportCancelled = false;
    
    // New property for the active panel
    @track activePanel = 'systemPermissions'; // Can be 'objects' or 'systemPermissions' - default to systemPermissions to prevent auto-loading objects
    
    // Performance optimization flags
    @track enableVirtualization = true;
    @track chunkSize = 10; // Process objects in chunks of 10
    
    // Caching properties for performance optimization
    @track objectsCache = null;
    @track objectsCacheExpiry = null;
    @track cacheExpiryTime = 5 * 60 * 1000; // 5 minutes
    @track objectsLoaded = false; // Track if objects have been loaded
    
    // DOM elements
    progressBarElement;
    
    /**
     * @description Lifecycle hook when component is connected
     */
    connectedCallback() {
        console.log('PermissionsManager: Component connected - objects will NOT load automatically');
        // Check feature access first
        this.checkFeatureAccess();
        // Clear any cached objects to ensure clean state
        this.clearObjectsCache();
        this.objects = []; // Ensure objects array is empty on load
        this.objectsLoaded = false; // Ensure objects loaded flag is false
        this.loadInitialData();
    }
    
    /**
     * @description Lifecycle hook when component is rendered
     */
    renderedCallback() {
        // Initialize progress bar if modal is showing
        if (this.showExportModal && !this.progressBarElement) {
            this.initializeProgressBar();
        }
    }
    
    /**
     * @description Check if user has access to paid features
     */
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
    
    /**
     * @description Initialize the progress bar DOM element
     */
    initializeProgressBar() {
        const progressBar = this.template.querySelector('.slds-progress-bar__value');
        if (progressBar) {
            this.progressBarElement = progressBar;
            this.updateProgressBar(this.exportProgressValue);
        }
    }
    
    /**
     * @description Update the progress bar value
     * @param {Number} value - Progress percentage (0-100)
     */
    updateProgressBar(value) {
        if (this.progressBarElement) {
            const percentage = Math.min(Math.max(value, 0), 100);
            this.exportProgressValue = percentage;
            this.progressBarElement.style.width = `${percentage}%`;
            
            // Update color based on progress
            if (percentage < 30) {
                this.progressBarElement.style.backgroundColor = '#ffb75d'; // Orange for early stages
            } else if (percentage < 70) {
                this.progressBarElement.style.backgroundColor = '#1589ee'; // Blue for middle progress
            } else {
                this.progressBarElement.style.backgroundColor = '#04844b'; // Green for nearly complete
            }
        }
    }
    
    /**
     * @description Load initial data with pagination - lazy load objects for performance
     */
    async loadInitialData() {
        try {
            this.isLoading = true;
            this.loadingStatusText = 'Loading profiles and permission sets...';
            
            // Load only profiles and permission sets initially (objects loaded on demand for performance)
            const promises = [
                this.loadAllProfiles(),
                this.loadAllPermissionSets()
            ];
            
            await Promise.all(promises);
            
            // Don't load objects from cache on initial load - wait for user to click Objects tab
            // this.loadObjectsFromCache(); // Removed to prevent loading objects on screen load
            
            this.isLoading = false;
            this.loadingStatusText = '';
        } catch (error) {
            this.showErrorToast('Error loading data', error.message || error.body?.message || 'Unknown error occurred');
            this.isLoading = false;
            this.loadingStatusText = '';
        }
    }
    
    /**
     * @description Load all profiles by fetching multiple pages if needed
     */
    async loadAllProfiles(searchTerm = '') {
        try {
            this.isProfilesLoading = true;
            this.profiles = [];
            let currentPage = 1;
            let hasMore = true;
            
            while (hasMore) {
                const result = await getProfilesPaginated({
                    pageSize: this.profilePagination.pageSize,
                    pageNumber: currentPage,
                    searchTerm: searchTerm
                });
                
                // Append profiles to the array
                this.profiles = [...this.profiles, ...(result.profiles || [])];
                
                // Update pagination info
                this.profilePagination = {
                    pageSize: result.pageSize || 200,
                    pageNumber: result.pageNumber || 1,
                    totalPages: result.totalPages || 1,
                    totalCount: result.totalCount || 0,
                    hasNext: result.hasNext || false,
                    hasPrevious: result.hasPrevious || false
                };
                
                hasMore = result.hasNext;
                currentPage++;
                
                // Safety check to prevent infinite loops
                if (currentPage > 20) {
                    console.warn('Stopped loading profiles after 20 pages for safety');
                    break;
                }
            }
            
            this.isProfilesLoading = false;
        } catch (error) {
            this.isProfilesLoading = false;
            throw error;
        }
    }

    /**
     * @description Load profiles page
     */
    async loadProfilesPage(pageNumber, searchTerm = '') {
        try {
            this.isProfilesLoading = true;
            
            const result = await getProfilesPaginated({
                pageSize: this.profilePagination.pageSize,
                pageNumber: pageNumber,
                searchTerm: searchTerm
            });
            
            // Update profiles array
            if (pageNumber === 1) {
                this.profiles = result.profiles || [];
            } else {
                // Append to existing profiles for infinite scroll
                this.profiles = [...this.profiles, ...(result.profiles || [])];
            }
            
            // Update pagination info
            this.profilePagination = {
                pageSize: result.pageSize || 50,
                pageNumber: result.pageNumber || 1,
                totalPages: result.totalPages || 1,
                totalCount: result.totalCount || 0,
                hasNext: result.hasNext || false,
                hasPrevious: result.hasPrevious || false
            };
            
            this.isProfilesLoading = false;
        } catch (error) {
            this.isProfilesLoading = false;
            throw error;
        }
    }
    
    /**
     * @description Load all permission sets by fetching multiple pages if needed
     */
    async loadAllPermissionSets(searchTerm = '') {
        try {
            this.isPermSetsLoading = true;
            this.permissionSets = [];
            let currentPage = 1;
            let hasMore = true;
            
            while (hasMore) {
                const result = await getPermissionSetsPaginated({
                    pageSize: this.permSetPagination.pageSize,
                    pageNumber: currentPage,
                    searchTerm: searchTerm
                });
                
                // Append permission sets to the array
                this.permissionSets = [...this.permissionSets, ...(result.permissionSets || [])];
                
                // Update pagination info
                this.permSetPagination = {
                    pageSize: result.pageSize || 200,
                    pageNumber: result.pageNumber || 1,
                    totalPages: result.totalPages || 1,
                    totalCount: result.totalCount || 0,
                    hasNext: result.hasNext || false,
                    hasPrevious: result.hasPrevious || false
                };
                
                hasMore = result.hasNext;
                currentPage++;
                
                // Safety check to prevent infinite loops
                if (currentPage > 20) {
                    console.warn('Stopped loading permission sets after 20 pages for safety');
                    break;
                }
            }
            
            this.isPermSetsLoading = false;
        } catch (error) {
            this.isPermSetsLoading = false;
            throw error;
        }
    }

    /**
     * @description Load permission sets page
     */
    async loadPermissionSetsPage(pageNumber, searchTerm = '') {
        try {
            this.isPermSetsLoading = true;
            
            const result = await getPermissionSetsPaginated({
                pageSize: this.permSetPagination.pageSize,
                pageNumber: pageNumber,
                searchTerm: searchTerm
            });
            
            // Update permission sets array
            if (pageNumber === 1) {
                this.permissionSets = result.permissionSets || [];
            } else {
                // Append to existing permission sets for infinite scroll
                this.permissionSets = [...this.permissionSets, ...(result.permissionSets || [])];
            }
            
            // Update pagination info
            this.permSetPagination = {
                pageSize: result.pageSize || 50,
                pageNumber: result.pageNumber || 1,
                totalPages: result.totalPages || 1,
                totalCount: result.totalCount || 0,
                hasNext: result.hasNext || false,
                hasPrevious: result.hasPrevious || false
            };
            
            this.isPermSetsLoading = false;
        } catch (error) {
            this.isPermSetsLoading = false;
            throw error;
        }
    }
    
    /**
     * @description Load objects from cache if available and valid
     */
    loadObjectsFromCache() {
        try {
            const cachedData = sessionStorage.getItem('permissionsManager_objects');
            const cacheExpiry = sessionStorage.getItem('permissionsManager_objects_expiry');
            
            if (cachedData && cacheExpiry) {
                const expiryTime = parseInt(cacheExpiry);
                const now = Date.now();
                
                if (now < expiryTime) {
                    // Cache is still valid
                    const parsedData = JSON.parse(cachedData);
                    this.objects = parsedData.objects || [];
                    this.objectPagination = parsedData.pagination || this.objectPagination;
                    this.objectsLoaded = true;
                    console.log('Loaded objects from cache:', this.objects.length);
                    return;
                }
            }
            
            // Cache is invalid or doesn't exist
            this.clearObjectsCache();
        } catch (error) {
            console.error('Error loading objects from cache:', error);
            this.clearObjectsCache();
        }
    }

    /**
     * @description Save objects to cache
     */
    saveObjectsToCache() {
        try {
            const cacheData = {
                objects: this.objects,
                pagination: this.objectPagination
            };
            
            const expiryTime = Date.now() + this.cacheExpiryTime;
            
            sessionStorage.setItem('permissionsManager_objects', JSON.stringify(cacheData));
            sessionStorage.setItem('permissionsManager_objects_expiry', expiryTime.toString());
            
            console.log('Saved objects to cache:', this.objects.length);
        } catch (error) {
            console.error('Error saving objects to cache:', error);
        }
    }

    /**
     * @description Clear objects cache
     */
    clearObjectsCache() {
        try {
            sessionStorage.removeItem('permissionsManager_objects');
            sessionStorage.removeItem('permissionsManager_objects_expiry');
            this.objectsCache = null;
            this.objectsCacheExpiry = null;
        } catch (error) {
            console.error('Error clearing objects cache:', error);
        }
    }

    /**
     * @description Load objects on demand (when user clicks on Objects tab)
     */
    async loadObjectsOnDemand() {
        if (this.objectsLoaded) {
            console.log('PermissionsManager: Objects already loaded, skipping');
            return; // Already loaded
        }

        try {
            console.log('PermissionsManager: Starting on-demand object loading');
            this.isObjectsLoading = true;
            
            // First try to load from cache ONLY when explicitly requested
            this.loadObjectsFromCache();
            
            // If cache didn't provide objects, load from server
            if (!this.objectsLoaded || this.objects.length === 0) {
                console.log('PermissionsManager: Cache miss - loading objects from server');
                await this.loadObjectsPage(1);
                this.objectsLoaded = true;
                this.saveObjectsToCache();
                console.log('PermissionsManager: Objects loaded from server:', this.objects.length);
            } else {
                console.log('PermissionsManager: Objects loaded from cache:', this.objects.length);
            }
            
            this.isObjectsLoading = false;
        } catch (error) {
            console.error('PermissionsManager: Error loading objects on demand:', error);
            this.isObjectsLoading = false;
            this.showErrorToast('Load Error', 'Failed to load objects: ' + error.message);
        }
    }

    /**
     * @description Load all objects by fetching multiple pages (optimized with limits)
     */
    async loadAllObjects(searchTerm = '') {
        try {
            this.isObjectsLoading = true;
            this.objects = [];
            let currentPage = 1;
            let hasMore = true;
            let totalLoaded = 0;
            const maxPages = 15; // Increased from 10 to 15 pages max for better coverage
            const maxObjects = 1000; // Increased from 500 to 1000 objects max since we're filtering more efficiently
            
            while (hasMore && currentPage <= maxPages && totalLoaded < maxObjects) {
                const result = await getObjectsPaginated({
                    pageSize: this.objectPagination.pageSize,
                    pageNumber: currentPage,
                    searchTerm: searchTerm
                });
                
                const newObjects = result.objects || [];
                
                // Check if adding these objects would exceed our limit
                if (totalLoaded + newObjects.length > maxObjects) {
                    // Add only the objects that fit within the limit
                    const remainingSlots = maxObjects - totalLoaded;
                    this.objects = [...this.objects, ...newObjects.slice(0, remainingSlots)];
                    totalLoaded = maxObjects;
                    break;
                }
                
                // Append objects to the array
                this.objects = [...this.objects, ...newObjects];
                totalLoaded += newObjects.length;
                
                // Update pagination info
                this.objectPagination = {
                    pageSize: result.pageSize || 50,
                    pageNumber: result.pageNumber || 1,
                    totalPages: result.totalPages || 1,
                    totalCount: result.totalCount || 0,
                    hasNext: result.hasNext || false,
                    hasPrevious: result.hasPrevious || false
                };
                
                hasMore = result.hasNext;
                currentPage++;
            }
            
            if (totalLoaded >= maxObjects) {
                console.warn(`Object loading limited to ${maxObjects} standard and custom objects for performance`);
                this.showWarningToast('Performance Limit', `Loading limited to ${maxObjects} standard and custom objects. Use search to find specific objects.`);
            }
            
            this.objectsLoaded = true;
            this.saveObjectsToCache();
            this.isObjectsLoading = false;
        } catch (error) {
            this.isObjectsLoading = false;
            throw error;
        }
    }

    /**
     * @description Load objects page
     */
    async loadObjectsPage(pageNumber, searchTerm = '') {
        try {
            this.isObjectsLoading = true;
            
            const result = await getObjectsPaginated({
                pageSize: this.objectPagination.pageSize,
                pageNumber: pageNumber,
                searchTerm: searchTerm
            });
            
            // Update objects array
            if (pageNumber === 1) {
                this.objects = result.objects || [];
            } else {
                // Append to existing objects for infinite scroll
                this.objects = [...this.objects, ...(result.objects || [])];
            }
            
            // Update pagination info
            this.objectPagination = {
                pageSize: result.pageSize || 50,
                pageNumber: result.pageNumber || 1,
                totalPages: result.totalPages || 1,
                totalCount: result.totalCount || 0,
                hasNext: result.hasNext || false,
                hasPrevious: result.hasPrevious || false
            };
            
            this.isObjectsLoading = false;
        } catch (error) {
            this.isObjectsLoading = false;
            throw error;
        }
    }
    
    /**
     * @description Handle search for profiles
     */
    async handleProfileSearch(event) {
        const searchTerm = event.target.value;
        this.profileSearchTerm = searchTerm;
        
        // Debounce search
        clearTimeout(this.profileSearchTimeout);
        this.profileSearchTimeout = setTimeout(async () => {
            try {
                await this.loadAllProfiles(searchTerm);
            } catch (error) {
                this.showErrorToast('Search Error', 'Failed to search profiles');
            }
        }, 300);
    }
    
    /**
     * @description Handle search for permission sets
     */
    async handlePermSetSearch(event) {
        const searchTerm = event.target.value;
        this.permSetSearchTerm = searchTerm;
        
        // Debounce search
        clearTimeout(this.permSetSearchTimeout);
        this.permSetSearchTimeout = setTimeout(async () => {
            try {
                await this.loadAllPermissionSets(searchTerm);
            } catch (error) {
                this.showErrorToast('Search Error', 'Failed to search permission sets');
            }
        }, 300);
    }
    
    /**
     * @description Handle search for objects
     */
    async handleObjectSearch(event) {
        const searchTerm = event.target.value;
        this.objectSearchTerm = searchTerm;
        
        // Debounce search
        clearTimeout(this.objectSearchTimeout);
        this.objectSearchTimeout = setTimeout(async () => {
            try {
                // Clear cache when searching to get fresh results
                if (searchTerm) {
                    this.clearObjectsCache();
                    this.objectsLoaded = false;
                }
                
                await this.loadAllObjects(searchTerm);
            } catch (error) {
                this.showErrorToast('Search Error', 'Failed to search objects');
            }
        }, 300);
    }
    
    /**
     * @description Load more profiles (infinite scroll)
     */
    async loadMoreProfiles() {
        if (this.profilePagination.hasNext && !this.isProfilesLoading) {
            try {
                await this.loadProfilesPage(this.profilePagination.pageNumber + 1, this.profileSearchTerm);
            } catch (error) {
                this.showErrorToast('Load Error', 'Failed to load more profiles');
            }
        }
    }
    
    /**
     * @description Load more permission sets (infinite scroll)
     */
    async loadMorePermissionSets() {
        if (this.permSetPagination.hasNext && !this.isPermSetsLoading) {
            try {
                await this.loadPermissionSetsPage(this.permSetPagination.pageNumber + 1, this.permSetSearchTerm);
            } catch (error) {
                this.showErrorToast('Load Error', 'Failed to load more permission sets');
            }
        }
    }
    
    /**
     * @description Load more objects (infinite scroll)
     */
    async loadMoreObjects() {
        if (this.objectPagination.hasNext && !this.isObjectsLoading) {
            try {
                await this.loadObjectsPage(this.objectPagination.pageNumber + 1, this.objectSearchTerm);
            } catch (error) {
                this.showErrorToast('Load Error', 'Failed to load more objects');
            }
        }
    }
    
    /**
     * @description Reset all selections
     */
    handleResetSelections() {
        this.profiles = this.profiles.map(profile => {
            return { ...profile, isSelected: false };
        });
        
        this.permissionSets = this.permissionSets.map(permSet => {
            return { ...permSet, isSelected: false };
        });
        
        this.objects = this.objects.map(obj => {
            return { ...obj, isSelected: false };
        });
        
        this.selectedProfiles = [];
        this.selectedPermSets = [];
        this.selectedObjects = [];
        
        this.dispatchEvent(
            new CustomEvent('selectionsreset')
        );
    }
    
    /**
     * @description Handle profile selection change
     * @param {CustomEvent} event - Selection change event
     */
    handleProfileSelectionChange(event) {
        console.log('Profile selection change event:', event.detail);
        this.selectedProfiles = event.detail.selectedItems || [];
        console.log('Updated selectedProfiles:', this.selectedProfiles.length, this.selectedProfiles);
        this.dispatchEvent(
            new CustomEvent('profileselectionchange', {
                detail: {
                    selectedProfiles: this.selectedProfiles
                }
            })
        );
    }
    
    /**
     * @description Handle permission set selection change
     * @param {CustomEvent} event - Selection change event
     */
    handlePermSetSelectionChange(event) {
        console.log('Permission set selection change event:', event.detail);
        this.selectedPermSets = event.detail.selectedItems || [];
        console.log('Updated selectedPermSets:', this.selectedPermSets.length, this.selectedPermSets);
        this.dispatchEvent(
            new CustomEvent('permsetselectionchange', {
                detail: {
                    selectedPermSets: this.selectedPermSets
                }
            })
        );
    }
    
    /**
     * @description Handle object selection change
     * @param {CustomEvent} event - Selection change event
     */
    handleObjectSelectionChange(event) {
        try {
            console.log('Object selection change event:', event.detail);
            
            // Ensure event.detail exists and has the expected structure
            if (!event.detail) {
                console.warn('Object selection event has no detail');
                return;
            }
            
            // Safely extract selectedItems with fallback
            const selectedItems = event.detail.selectedItems || event.detail.selectedObjects || [];
            
            // Validate that selectedItems is an array
            if (!Array.isArray(selectedItems)) {
                console.warn('Selected items is not an array:', selectedItems);
                this.selectedObjects = [];
                return;
            }
            
            // Filter out any invalid items (missing required properties)
            this.selectedObjects = selectedItems.filter(item => {
                return item && (item.id || item.apiName || item.name);
            });
            
            console.log('Updated selectedObjects:', this.selectedObjects.length, this.selectedObjects);
            
            this.dispatchEvent(
                new CustomEvent('objectselectionchange', {
                    detail: {
                        selectedObjects: this.selectedObjects
                    }
                })
            );
        } catch (error) {
            console.error('Error in handleObjectSelectionChange:', error);
            this.selectedObjects = [];
            this.showErrorToast('Selection Error', 'An error occurred while updating object selection');
        }
    }
    
    /**
     * @description Handle Export button click with optimized processing
     */
    async handleExport() {
        // Check if any selections have been made
        if (!this.hasAnySelections) {
            this.showErrorToast('Selection Required', 'Please select at least one Profile/Permission Set and Object to export.');
            return;
        }
        
        // Show export modal with progress bar
        this.showExportModal = true;
        this.exportStatusText = 'Preparing export...';
        this.exportDetailsText = 'Initializing export process';
        this.exportProgressValue = 0;
        this.isExportCancelDisabled = false;
        this.exportCancelled = false;
        
        try {
            const profileIds = this.selectedProfiles.map(profile => profile.id);
            const permSetIds = this.selectedPermSets.map(permSet => permSet.id);
            const objectNames = this.selectedObjects.map(obj => obj.apiName || obj.name);
            
            // Warn for large exports
            if (objectNames.length > 20) {
                this.exportDetailsText = `Processing ${objectNames.length} objects (this may take several minutes)`;
            }
            
            let exportCount = 0;
            
            // Use optimized export methods
            await this.exportWithOptimizedMethods(profileIds, permSetIds, objectNames);
            
            this.exportStatusText = 'Export Complete';
            this.updateProgressBar(100);
            
            // Hide modal after delay
            setTimeout(() => {
                this.showExportModal = false;
                this.showSuccessToast('Export Complete', 'All permissions have been exported successfully.');
            }, 2000);
            
        } catch (error) {
            this.exportStatusText = 'Export Failed';
            this.exportDetailsText = error.message || 'An error occurred during export';
            this.showErrorToast('Export Error', error.message || 'Export failed');
            
            setTimeout(() => {
                this.showExportModal = false;
            }, 3000);
        }
    }
    
    /**
     * @description Export using optimized methods with chunking
     */
    async exportWithOptimizedMethods(profileIds, permSetIds, objectNames) {
        try {
            // Export object permissions with chunking
            this.exportStatusText = 'Exporting object permissions...';
            this.exportDetailsText = `Processing ${objectNames.length} objects in chunks`;
            this.updateProgressBar(10);
            
            await this.exportObjectPermissionsOptimized(profileIds, permSetIds, objectNames);
            
            if (this.exportCancelled) return;
            
            // Export tab visibility
            this.exportStatusText = 'Exporting tab visibility...';
            this.exportDetailsText = 'Processing tab visibility settings';
            this.updateProgressBar(40);
            
            await this.exportTabVisibilityData(profileIds, permSetIds, objectNames);
            
            if (this.exportCancelled) return;
            
            // Export field permissions
            this.exportStatusText = 'Exporting field permissions...';
            this.exportDetailsText = 'Processing field permissions';
            this.updateProgressBar(70);
            
            await this.exportFieldPermissionsData(profileIds, permSetIds, objectNames);
            
        } catch (error) {
            throw error;
        }
    }
    
    /**
     * @description Export object permissions using optimized method
     */
    async exportObjectPermissionsOptimized(profileIds, permSetIds, objectNames) {
        try {
            const data = await getObjectPermissionsOptimized({
                profileIds: profileIds,
                permSetIds: permSetIds,
                objectNames: objectNames,
                chunkSize: this.chunkSize
            });
            
            if (data && Object.keys(data).length > 0) {
                const csvContent = this.convertObjectPermissionsToCSV(data, profileIds, permSetIds, objectNames);
                this.downloadCSV(csvContent, 'Object_Permissions_Export.csv');
                return true;
            } else {
                this.showWarningToast('No Data', 'No object permissions found for the selected criteria.');
                return false;
            }
        } catch (error) {
            throw new Error('Failed to export object permissions: ' + error.message);
        }
    }
    
    /**
     * @description Export tab visibility data directly using Apex
     * @param {String[]} profileIds - List of profile IDs
     * @param {String[]} permSetIds - List of permission set IDs
     * @param {String[]} objectNames - List of object names
     * @returns {Promise<Boolean>} - Whether export was successful
     */
    exportTabVisibilityData(profileIds, permSetIds, objectNames) {
        return new Promise((resolve) => {
            try {
                // If there are no selected profiles/permission sets, skip export
                if (profileIds.length === 0 && permSetIds.length === 0) {
                    console.log('No profiles/permission sets selected for tab visibility export');
                    resolve(false);
                    return;
                }
                
                this.updateProgressBar(45);
                this.exportDetailsText = `Retrieving tab visibility data...`;
                
                // Simulate tab names from object names
                // In a real implementation, this would come from a proper tab name query
                const tabNames = objectNames.map(objName => objName);
                
                // Call the Apex method to get tab visibility data
                getTabVisibility({ profileIds, permSetIds, tabNames })
                    .then(data => {
                        if (this.exportCancelled) {
                            resolve(false);
                            return;
                        }
                        
                        this.updateProgressBar(55);
                        this.exportDetailsText = `Generating tab visibility CSV...`;
                        
                        // Convert the Apex result to CSV format
                        const csvContent = this.convertTabVisibilityToCSV(data, profileIds, permSetIds, tabNames);
                        
                        this.updateProgressBar(65);
                        this.exportDetailsText = `Downloading tab visibility CSV...`;
                        
                        // Trigger CSV download
                        this.downloadCSV(csvContent, 'tab_visibility_export.csv');
                        resolve(true);
                    })
                    .catch(error => {
                        console.error('Error fetching tab visibility data:', error);
                        this.exportDetailsText = `Error fetching tab visibility: ${error.message || 'Unknown error'}`;
                        resolve(false);
                    });
            } catch (error) {
                console.error('Error in exportTabVisibilityData:', error);
                this.exportDetailsText = `Error processing tab visibility: ${error.message || 'Unknown error'}`;
                resolve(false);
            }
        });
    }
    
    /**
     * @description Convert object permissions data to CSV format
     * @param {Object} data - Object permissions data from Apex
     * @param {String[]} profileIds - List of profile IDs
     * @param {String[]} permSetIds - List of permission set IDs
     * @param {String[]} objectNames - List of object names
     * @returns {String} - CSV content
     */
    convertObjectPermissionsToCSV(data, profileIds, permSetIds, objectNames) {
        try {
            // Create an HTML table that Excel can interpret when opening the CSV
            let csv = '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">';
            csv += '<head><!--[if gte mso 9]><xml><x:ExcelWorkbook><x:ExcelWorksheets><x:ExcelWorksheet><x:Name>Object Permissions</x:Name><x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions></x:ExcelWorksheet></x:ExcelWorksheets></x:ExcelWorkbook></xml><![endif]--></head>';
            csv += '<body><table border="1">';
            
            // Get all parents (profiles and permission sets)
            const parentIds = [...profileIds, ...permSetIds];
            const permissionTypes = ['Read', 'Create', 'Edit', 'Delete', 'View All', 'Modify All'];
            
            // Create header row with colored background
            csv += '<tr><th style="background-color:#4A90E2; color:white; font-weight:bold; text-align:center; padding:10px;">Object</th>';
            
            // Add parent columns for each permission type
            parentIds.forEach((parentId, parentIndex) => {
                const parentName = this.getParentName(parentId);
                permissionTypes.forEach((permType, typeIndex) => {
                    // Different colors for different permission types
                    let headerColor = '#5C6BC0'; // Default purple-blue
                    if (permType === 'Read') headerColor = '#42A5F5'; // Light blue
                    else if (permType === 'Create') headerColor = '#66BB6A'; // Green
                    else if (permType === 'Edit') headerColor = '#FFA726'; // Orange
                    else if (permType === 'Delete') headerColor = '#EF5350'; // Red
                    else if (permType === 'View All') headerColor = '#AB47BC'; // Purple
                    else if (permType === 'Modify All') headerColor = '#EC407A'; // Pink
                    
                    // Add right border after "Modify All" column for each profile/permission set
                    if (typeIndex === permissionTypes.length - 1) {
                        csv += `<th style="background-color:${headerColor}; color:white; font-weight:bold; text-align:center; padding:10px; border-right: 2px solid #000000;">${parentName} ${permType}</th>`;
                    } else {
                        csv += `<th style="background-color:${headerColor}; color:white; font-weight:bold; text-align:center; padding:10px;">${parentName} ${permType}</th>`;
                    }
                });
            });
            csv += '</tr>';
            
            // Add data rows for each object
            objectNames.forEach(objectName => {
                if (!data[objectName]) return;
                
                const objData = data[objectName];
                const objLabel = this.getObjectLabel(objectName);
                
                // Start row
                csv += '<tr>';
                
                // Add object name with light blue background
                csv += `<td style="background-color:#b9cefc;">${objLabel}</td>`;
                
                // Add permissions for each parent
                parentIds.forEach((parentId, parentIndex) => {
                    const permissions = objData.permissions?.[parentId];
                    
                    if (permissions) {
                        // Add each permission type for this parent with color coding
                        csv += `<td style="background-color:${permissions.canRead ? '#C8E6C9' : '#FFCDD2'};">${permissions.canRead ? 'TRUE' : 'FALSE'}</td>`;
                        csv += `<td style="background-color:${permissions.canCreate ? '#C8E6C9' : '#FFCDD2'};">${permissions.canCreate ? 'TRUE' : 'FALSE'}</td>`;
                        csv += `<td style="background-color:${permissions.canEdit ? '#C8E6C9' : '#FFCDD2'};">${permissions.canEdit ? 'TRUE' : 'FALSE'}</td>`;
                        csv += `<td style="background-color:${permissions.canDelete ? '#C8E6C9' : '#FFCDD2'};">${permissions.canDelete ? 'TRUE' : 'FALSE'}</td>`;
                        csv += `<td style="background-color:${permissions.canViewAll ? '#C8E6C9' : '#FFCDD2'};">${permissions.canViewAll ? 'TRUE' : 'FALSE'}</td>`;
                        
                        // Add right border after "Modify All" column
                        csv += `<td style="background-color:${permissions.canModifyAll ? '#C8E6C9' : '#FFCDD2'}; border-right: 2px solid #000000;">${permissions.canModifyAll ? 'TRUE' : 'FALSE'}</td>`;
                    } else {
                        // No permission data - all FALSE with light red background
                        csv += '<td style="background-color:#FFCDD2;">FALSE</td>';
                        csv += '<td style="background-color:#FFCDD2;">FALSE</td>';
                        csv += '<td style="background-color:#FFCDD2;">FALSE</td>';
                        csv += '<td style="background-color:#FFCDD2;">FALSE</td>';
                        csv += '<td style="background-color:#FFCDD2;">FALSE</td>';
                        csv += '<td style="background-color:#FFCDD2; border-right: 2px solid #000000;">FALSE</td>';
                    }
                });
                
                csv += '</tr>';
            });
            
            csv += '</table></body></html>';
            return csv;
        } catch (error) {
            console.error('Error converting object permissions to CSV:', error);
            return 'Error generating CSV data';
        }
    }
    
    /**
     * @description Convert tab visibility data to CSV format
     * @param {Object} data - Tab visibility data from Apex
     * @param {String[]} profileIds - List of profile IDs
     * @param {String[]} permSetIds - List of permission set IDs
     * @param {String[]} tabNames - List of tab names
     * @returns {String} - CSV content
     */
    convertTabVisibilityToCSV(data, profileIds, permSetIds, tabNames) {
        try {
            // Create an HTML table that Excel can interpret (same approach as other exports)
            let csv = '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">';
            csv += '<head><!--[if gte mso 9]><xml><x:ExcelWorkbook><x:ExcelWorksheets><x:ExcelWorksheet><x:Name>Tab Visibility</x:Name><x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions></x:ExcelWorksheet></x:ExcelWorksheets></x:ExcelWorkbook></xml><![endif]--></head>';
            csv += '<body><table border="1">';
            
            // Get all parents (profiles and permission sets)
            const parentIds = [...profileIds, ...permSetIds];
            
            // Create header row with colored background
            csv += '<tr><th style="background-color:#4A90E2; color:white; font-weight:bold; text-align:center; padding:10px;">Tab Name</th>';
            
            // Add parent columns with right borders and colored headers
            parentIds.forEach((parentId, parentIndex) => {
                const parentName = this.getParentName(parentId);
                csv += `<th style="background-color:#26A69A; color:white; font-weight:bold; text-align:center; padding:10px; border-right: 2px solid #000000;">${parentName}</th>`;
            });
            csv += '</tr>';
            
            // Add data rows for each tab
            tabNames.forEach(tabName => {
                if (!data[tabName]) return;
                
                const tabData = data[tabName];
                const tabLabel = this.getTabLabel(tabName);
                
                // Start new row
                csv += '<tr>';
                
                // Add tab name
                csv += `<td>${tabLabel}</td>`;
                
                // Add visibility for each parent
                parentIds.forEach((parentId, parentIndex) => {
                    const visibility = tabData.visibility?.[parentId];
                    
                    let visibilityValue = 'Available'; // Default
                    let cellStyle = 'background-color: #FFCC80; border-right: 2px solid #000000;'; // Light orange for Available (default)
                    
                    if (visibility) {
                        if (visibility.isVisible) {
                            visibilityValue = 'DefaultOn';
                            cellStyle = 'background-color: #C8E6C9; border-right: 2px solid #000000;'; // Light green for DefaultOn
                        } else if (visibility.isAvailable) {
                            visibilityValue = 'Available';
                            cellStyle = 'background-color: #FFCC80; border-right: 2px solid #000000;'; // Light orange for Available
                        } else {
                            visibilityValue = 'Hidden';
                            cellStyle = 'background-color: #FFCDD2; border-right: 2px solid #000000;'; // Light red for Hidden
                        }
                    }
                    
                    // Add right border and color-coding to each column
                    csv += `<td style="${cellStyle}">${visibilityValue}</td>`;
                });
                
                csv += '</tr>';
            });
            
            csv += '</table></body></html>';
            return csv;
        } catch (error) {
            console.error('Error converting tab visibility to CSV:', error);
            return 'Error generating CSV data';
        }
    }
    
    /**
     * @description Export field permissions data with optimized server calls
     * @param {String[]} profileIds - List of profile IDs
     * @param {String[]} permSetIds - List of permission set IDs
     * @param {String[]} objectNames - List of object names
     * @returns {Promise<Boolean>} - Whether export was successful
     */
    exportFieldPermissionsData(profileIds, permSetIds, objectNames) {
        return new Promise((resolve) => {
            try {
                // If there are no selected profiles/permission sets or objects, skip export
                if ((profileIds.length === 0 && permSetIds.length === 0) || objectNames.length === 0) {
                    console.log('No profiles/permission sets or objects selected for field permissions export');
                    resolve(false);
                    return;
                }
                
                // List of objects known to cause issues with field permissions retrieval
                // These typically cause "Attempt to de-reference a null object" errors
                const problematicObjects = [
                    // Objects reported in error logs
                    'WorkOrder', 'Asset', 'ApptBundleConfig', 
                    
                    // Other known problematic objects
                    'AIApplication', 'AIApplicationConfig', 'AIInsight', 'AIInsightAction',
                    'AIInsightFeedback', 'AIInsightReason', 'AIInsightValue', 'AIRecordInsight',
                    'ApptBundleAggrPolicy', 'ApptBundleConfig', 'ApptBundlePolicy', 'ApptBundlePolicySvcTerr',
                    'ApptBundlePropagatePolicy', 'ApptBundleSortPolicy', 'ActionableListMember',
                    'AppointmentInvitation', 'AppointmentTopicTimeSlot', 'AppointmentTopicTimeSlotFeed',
                    'ChannelProgramLevelShare', 'ContentDocumentLink', 'ContentVersion', 'ContentDocument',
                    'ContentDocumentSubscription', 'KnowledgeArticleVersion', 'LocationShare', 'MessagingSession',
                    'OmniSupervisorConfigUser', 'PermissionSetTabSetting', 'ProfileTabVisibility', 'TimeSheetEntryShare',
                    'AgentWork', 'AuthorizationFormConsent', 'LoginEventStream', 'LoginGeo', 'PermissionSetAssignment',
                    'GrantedByLicense', 'PendingServiceRouting', 'RelationshipInfo', 'ServiceResource', 'UserServicePresence',
                    'ServiceAppointment', 'ResourceAbsence', 'ResourcePreference', 'ServiceResourceCapacity', 'ServiceTerritoryShare',
                    'ShiftShare', 'SkillRequirement', 'TimeSlot'
                ];
                
                // Check whether any objects might cause issues
                const problematicSelectedObjects = objectNames.filter(obj => problematicObjects.includes(obj));
                const filteredObjects = objectNames.filter(obj => !problematicObjects.includes(obj));
                
                // Warn user about problematic objects that are being excluded
                if (problematicSelectedObjects.length > 0) {
                    console.log(`Excluding ${problematicSelectedObjects.length} problematic objects: ${problematicSelectedObjects.join(', ')}`);
                    this.exportDetailsText = `Excluded ${problematicSelectedObjects.length} objects that commonly cause errors`;
                    this.showWarningToast('Some Objects Excluded', 
                        `${problematicSelectedObjects.length} objects that commonly cause errors have been excluded from field permissions export: ${problematicSelectedObjects.join(', ')}`);
                }
                
                if (filteredObjects.length === 0) {
                    this.showWarningToast('No Valid Objects', 'All selected objects are known to cause errors and have been excluded from the export.');
                    resolve(false);
                    return;
                }
                
                // Instead of making multiple Apex calls for each chunk, we'll process the data client-side
                // to minimize server load while still providing progress feedback
                
                let successCount = 0;
                let failureCount = 0;
                let allResults = [];
                
                // Process objects in the UI in chunks after data retrieval
                const processObjectsLocally = (objectsData) => {
                    // objectsData is a map where keys are object names and values are field permissions
                    const objectNames = Object.keys(objectsData);
                    const totalObjects = objectNames.length;
                    
                    if (totalObjects === 0) {
                        this.exportStatusText = 'Error: No Field Data';
                        this.exportDetailsText = 'No valid field permissions data could be retrieved';
                        this.showErrorToast('Export Failed', 'No valid field permissions data could be retrieved.');
                        resolve(false);
                        return;
                    }
                    
                    // Process objects in chunks to keep UI responsive
                    const chunkSize = 20;
                    let processedCount = 0;
                    let currentProgress = 75; // Start at 75% since we've already made it through object and tab exports
                    
                    const processNextChunk = () => {
                        if (this.exportCancelled) {
                            resolve(false);
                            return;
                        }
                        
                        // Get next chunk of objects
                        const endIdx = Math.min(processedCount + chunkSize, totalObjects);
                        const currentChunk = objectNames.slice(processedCount, endIdx);
                        
                        // Update progress indicator
                        this.exportDetailsText = `Processing field permissions data (${processedCount + 1}-${endIdx}/${totalObjects})...`;
                        
                        // Calculate progress based on how many objects we've processed
                        currentProgress = 75 + ((processedCount / totalObjects) * 25);
                        this.updateProgressBar(currentProgress);
                        
                        // Process current chunk
                        currentChunk.forEach(objectName => {
                            try {
                                const data = objectsData[objectName];
                                if (data && Object.keys(data).length > 0) {
                                    allResults.push({ objectName, data });
                                    successCount++;
                                } else {
                                    console.log(`No field permissions found for ${objectName}`);
                                    failureCount++;
                                }
                            } catch (error) {
                                console.error(`Error processing ${objectName}: ${error.message}`);
                                failureCount++;
                            }
                        });
                        
                        processedCount = endIdx;
                        
                        // Check if we're done
                        if (processedCount < totalObjects) {
                            // Schedule next chunk with a small delay to keep UI responsive
                            setTimeout(processNextChunk, 10);
                        } else {
                            // All chunks processed, generate CSV
                            this.exportStatusText = 'Generating CSV';
                            this.exportDetailsText = `Generating field permissions CSV file for ${allResults.length} objects...`;
                            this.updateProgressBar(95);
                            
                            try {
                                // Convert the combined data to CSV format
                                const csvContent = this.convertFieldPermissionsToCSV(allResults, profileIds, permSetIds);
                                
                                // Trigger CSV download
                                this.downloadCSV(csvContent, 'field_permissions_export.csv');
                                
                                // Show summary toast
                                if (failureCount > 0) {
                                    this.showWarningToast('Partial Export Complete', 
                                        `Successfully exported field permissions for ${successCount} objects. ${failureCount} objects failed.`);
                                } else {
                                    this.showSuccessToast('Export Complete', 
                                        `Successfully exported field permissions for all ${successCount} objects.`);
                                }
                                
                                // Resolve with success as long as we got some data
                                resolve(successCount > 0);
                                
                            } catch (error) {
                                console.error('Error generating CSV:', error);
                                this.exportStatusText = 'Export Error';
                                this.exportDetailsText = 'An error occurred while generating the CSV file';
                                this.showErrorToast('Export Error', 'An error occurred while generating the CSV file.');
                                resolve(false);
                            }
                        }
                    };
                    
                    // Start processing the first chunk
                    processNextChunk();
                };
                
                // Make a single server call to get all field permissions data
                this.exportStatusText = 'Retrieving Field Data';
                this.exportDetailsText = `Fetching field permissions for ${filteredObjects.length} objects...`;
                this.updateProgressBar(70);
                
                // Use a more efficient method to retrieve data when available
                // For now, we'll use what we have but make a note this should be optimized
                const batchSize = 10; // Larger batch size to reduce calls
                const objectBatches = this.chunkArray(filteredObjects, batchSize);
                
                let batchPromises = objectBatches.map((batch, batchIndex) => {
                    return new Promise(batchResolve => {
                        // Add a small delay between batches to avoid overwhelming the server
                        setTimeout(() => {
                            if (this.exportCancelled) {
                                batchResolve([]);
                                return;
                            }
                            
                            this.exportDetailsText = `Retrieving field permissions (batch ${batchIndex + 1}/${objectBatches.length})...`;
                            const progressIncrement = 10 / objectBatches.length;
                            this.updateProgressBar(70 + (batchIndex * progressIncrement));
                            
                            // Process each object in the batch
                            const batchPromises = batch.map(objectName => {
                                return getFieldPermissions({ profileIds, permSetIds, objectName })
                                    .then(data => ({ objectName, data }))
                                    .catch(error => {
                                        console.error(`Error fetching field permissions for ${objectName}:`, error);
                                        return null; // Return null for failed objects
                                    });
                            });
                            
                            Promise.all(batchPromises)
                                .then(results => {
                                    // Filter out null results
                                    const validResults = results.filter(result => result !== null);
                                    batchResolve(validResults);
                                })
                                .catch(error => {
                                    console.error('Error processing batch:', error);
                                    batchResolve([]); // Return empty array for failed batch
                                });
                        }, batchIndex * 500); // Stagger batches by 500ms
                    });
                });
                
                // Process all batches and combine results
                Promise.all(batchPromises)
                    .then(batchResults => {
                        if (this.exportCancelled) {
                            resolve(false);
                            return;
                        }
                        
                        // Flatten batch results
                        const flatResults = batchResults.flat();
                        
                        // Convert to object map for efficient processing
                        const objectsData = {};
                        flatResults.forEach(result => {
                            if (result && result.objectName && result.data) {
                                objectsData[result.objectName] = result.data;
                            }
                        });
                        
                        // Process objects locally
                        processObjectsLocally(objectsData);
                    })
                    .catch(error => {
                        console.error('Error processing batches:', error);
                        this.exportStatusText = 'Export Error';
                        this.exportDetailsText = 'Error retrieving field permissions data';
                        this.showErrorToast('Export Error', 'An error occurred while retrieving field permissions data.');
                        resolve(false);
                    });
                
            } catch (error) {
                console.error('Error in exportFieldPermissionsData:', error);
                this.exportStatusText = 'Export Error';
                this.exportDetailsText = 'Error setting up field permissions export';
                this.showErrorToast('Export Error', 'An error occurred while setting up the field permissions export.');
                resolve(false);
            }
        });
    }
    
    /**
     * @description Convert field permissions data to CSV format
     * @param {Object[]} results - Array of field permissions data by object
     * @param {String[]} profileIds - List of profile IDs
     * @param {String[]} permSetIds - List of permission set IDs
     * @returns {String} - CSV content
     */
    convertFieldPermissionsToCSV(results, profileIds, permSetIds) {
        try {
            // Create an HTML table that Excel can interpret (same approach as object permissions)
            let csv = '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">';
            csv += '<head><!--[if gte mso 9]><xml><x:ExcelWorkbook><x:ExcelWorksheets><x:ExcelWorksheet><x:Name>Field Permissions</x:Name><x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions></x:ExcelWorksheet></x:ExcelWorksheets></x:ExcelWorkbook></xml><![endif]--></head>';
            csv += '<body><table border="1">';
            
            // Get all parents (profiles and permission sets)
            const parentIds = [...profileIds, ...permSetIds];
            
            // Create header row with colored backgrounds
            csv += '<tr><th style="background-color:#4A90E2; color:white; font-weight:bold; text-align:center; padding:10px;">Object</th><th style="background-color:#4A90E2; color:white; font-weight:bold; text-align:center; padding:10px;">Field Api Name</th><th style="background-color:#4A90E2; color:white; font-weight:bold; text-align:center; padding:10px;">Field Label</th>';
            
            // Add parent columns for read and edit permissions with different colors
            parentIds.forEach((parentId, parentIndex) => {
                const parentName = this.getParentName(parentId);
                csv += `<th style="background-color:#42A5F5; color:white; font-weight:bold; text-align:center; padding:10px;">${parentName} Read</th>`;
                // Add right border after "Edit" column for each profile/permission set
                csv += `<th style="background-color:#FFA726; color:white; font-weight:bold; text-align:center; padding:10px; border-right: 2px solid #000000;">${parentName} Edit</th>`;
            });
            csv += '</tr>';
            
            // Process each object's fields
            results.forEach(({ objectName, data }) => {
                if (!data) return;
                
                const objectLabel = this.getObjectLabel(objectName);
                
                // For each field in the object
                Object.keys(data).forEach(fieldKey => {
                    const fieldData = data[fieldKey];
                    const fieldApiName = fieldData.fieldName;
                    const fieldLabel = fieldData.fieldName; // Use field name as label if no label is provided
                    
                    // Start new row
                    csv += '<tr>';
                    
                    // Add object and field info
                    csv += `<td>${objectLabel}</td>`;
                    csv += `<td>${fieldApiName}</td>`;
                    csv += `<td>${fieldLabel}</td>`;
                    
                    // Add permissions for each parent
                    parentIds.forEach((parentId, parentIndex) => {
                        const permissions = fieldData.permissions?.[parentId];
                        
                        if (permissions) {
                            // Read permission
                            csv += `<td>${permissions.canRead ? 'TRUE' : 'FALSE'}</td>`;
                            // Edit permission with right border
                            csv += `<td style="border-right: 2px solid #000000;">${permissions.canEdit ? 'TRUE' : 'FALSE'}</td>`;
                        } else {
                            // No permission data
                            csv += '<td>FALSE</td>';
                            csv += '<td style="border-right: 2px solid #000000;">FALSE</td>';
                        }
                    });
                    
                    csv += '</tr>';
                });
            });
            
            csv += '</table></body></html>';
            return csv;
        } catch (error) {
            console.error('Error converting field permissions to CSV:', error);
            return 'Error generating CSV data';
        }
    }
    
    /**
     * @description Split an array into smaller chunks
     * @param {Array} array - The array to split
     * @param {Number} chunkSize - The maximum size of each chunk
     * @returns {Array} Array of chunks
     */
    chunkArray(array, chunkSize) {
        const chunks = [];
        for (let i = 0; i < array.length; i += chunkSize) {
            chunks.push(array.slice(i, i + chunkSize));
        }
        return chunks;
    }
    
    /**
     * @description Helper to escape CSV values
     * @param {String} value - Value to escape
     * @return {String} Escaped CSV value
     */
    escapeCsvValue(value) {
        if (value === null || value === undefined) return '';
        
        // Convert to string and escape quotes
        const stringValue = String(value);
        if (stringValue.includes(',') || stringValue.includes('"') || stringValue.includes('\n')) {
            return '"' + stringValue.replace(/"/g, '""') + '"';
        }
        return stringValue;
    }
    
    /**
     * @description Get parent name (profile or permission set) from ID
     * @param {String} parentId - Parent ID
     * @return {String} Parent name
     */
    getParentName(parentId) {
        // First check if it's a profile
        const profile = this.selectedProfiles.find(p => p.id === parentId);
        if (profile) {
            return profile.name;
        }
        
        // Then check if it's a permission set
        const permSet = this.selectedPermSets.find(ps => ps.id === parentId);
        if (permSet) {
            return permSet.label || permSet.name;
        }
        
        return 'Unknown';
    }
    
    /**
     * @description Get object label from API name
     * @param {String} objectName - Object API name
     * @return {String} Object label
     */
    getObjectLabel(objectName) {
        const obj = this.selectedObjects.find(o => (o.apiName || o.name) === objectName);
        return obj ? (obj.label || obj.name) : objectName;
    }
    
    /**
     * @description Get tab label from tab name
     * @param {String} tabName - Tab name
     * @return {String} Tab label
     */
    getTabLabel(tabName) {
        // In practice, you'd have a more sophisticated mapping from tab name to label
        // For now, just use the tab name with a cleaner format
        return tabName.replace('__c', '').replace(/([A-Z])/g, ' $1').trim();
    }
    
    /**
     * @description Download CSV content
     * @param {String} csvContent - CSV content
     * @param {String} filename - Filename for download
     */
    downloadCSV(csvContent, filename) {
        try {
            // Check if this is HTML content (for object permissions)
            const isHtml = csvContent.startsWith('<html');
            
            // Create and trigger download with appropriate MIME type
            const mimeType = isHtml ? 'application/vnd.ms-excel' : 'text/csv;charset=utf-8';
            const encodedUri = `data:${mimeType},` + encodeURIComponent(csvContent);
            const link = document.createElement('a');
            link.setAttribute('href', encodedUri);
            link.setAttribute('download', isHtml ? filename.replace('.csv', '.xls') : filename);
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        } catch (error) {
            console.error('Error downloading CSV:', error);
            this.showErrorToast('Download Error', 'Failed to download the CSV file');
        }
    }
    
    /**
     * @description Show error toast message
     * @param {String} title - Toast title
     * @param {String} message - Error message
     */
    showErrorToast(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'error'
            })
        );
    }
    
    /**
     * @description Show success toast message
     * @param {String} title - Toast title
     * @param {String} message - Success message
     */
    showSuccessToast(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'success'
            })
        );
    }
    
    /**
     * @description Show warning toast message
     * @param {String} title - Toast title
     * @param {String} message - Warning message
     */
    showWarningToast(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'warning'
            })
        );
    }
    
    /**
     * @description Get main container class
     * @return {String} Container class
     */
    get mainContainerClass() {
        return 'container';
    }
    
    /**
     * @description Check if any profile is selected
     * @return {Boolean} True if any profile is selected
     */
    get isAnyProfileSelected() {
        return this.selectedProfiles.length > 0;
    }
    
    /**
     * @description Check if any permission set is selected
     * @return {Boolean} True if any permission set is selected
     */
    get isAnyPermSetSelected() {
        return this.selectedPermSets.length > 0;
    }
    
    /**
     * @description Check if any object is selected
     * @return {Boolean} True if any object is selected
     */
    get isAnyObjectSelected() {
        return this.selectedObjects.length > 0;
    }
    
    /**
     * @description Check if any selections have been made
     * @return {Boolean} True if any selections have been made
     */
    get hasAnySelections() {
        const profilesSelected = this.isAnyProfileSelected;
        const permSetsSelected = this.isAnyPermSetSelected;
        const objectsSelected = this.isAnyObjectSelected;
        const hasSelections = (profilesSelected || permSetsSelected) && objectsSelected;
        
        console.log('Selection validation:', {
            profilesSelected,
            permSetsSelected,
            objectsSelected,
            hasSelections,
            selectedProfilesCount: this.selectedProfiles.length,
            selectedPermSetsCount: this.selectedPermSets.length,
            selectedObjectsCount: this.selectedObjects.length
        });
        
        return hasSelections;
    }
    
    /**
     * @description Get whether the export button should be disabled
     * @return {Boolean} Whether the export button should be disabled
     */
    get isExportDisabled() {
        return !this.hasAnySelections;
    }
    
    /**
     * @description Get a summary of the current selections for display
     * @return {String} Selection summary
     */
    get selectionSummary() {
        const profileCount = this.selectedProfiles.length;
        const permSetCount = this.selectedPermSets.length;
        const objectCount = this.selectedObjects.length;
        
        let summary = '';
        
        if (profileCount > 0) {
            summary += `${profileCount} Profile${profileCount > 1 ? 's' : ''}`;
        }
        
        if (permSetCount > 0) {
            if (summary) summary += ' and ';
            summary += `${permSetCount} Permission Set${permSetCount > 1 ? 's' : ''}`;
        }
        
        if (summary) summary += ' for ';
        
        if (objectCount === 1) {
            // For a single object, show its name
            summary += this.selectedObjects[0].label;
        } else {
            summary += `${objectCount} Object${objectCount > 1 ? 's' : ''}`;
        }
        
        return summary;
    }
    
    /**
     * @description Handle panel navigation (objects vs system permissions)
     * @param {Event} event - Click event
     */
    async handlePanelChange(event) {
        const panelName = event.currentTarget.dataset.panel;
        if (panelName && panelName !== this.activePanel) {
            this.activePanel = panelName;
            
            // Load objects on demand when Objects tab is selected
            if (panelName === 'objects' && !this.objectsLoaded) {
                console.log('PermissionsManager: Objects tab clicked - loading objects on demand');
                await this.loadObjectsOnDemand();
            } else if (panelName === 'objects' && this.objectsLoaded) {
                console.log('PermissionsManager: Objects tab clicked - objects already loaded from cache');
            }
        }
    }
    
    /**
     * @description Handle system permission selection
     * @param {CustomEvent} event - Selection event from system permissions panel
     */
    handleSystemPermissionSelect(event) {
        // This method receives the selected system permission
        // We don't need to do anything with it in the parent component
        // as the systemPermissionsPanel component handles the analysis
    }
    
    /**
     * @description Get the active tab class for the objects panel
     */
    get objectsPanelClass() {
        return this.activePanel === 'objects' ? 
            'slds-tabs_default__item slds-is-active' : 
            'slds-tabs_default__item';
    }
    
    /**
     * @description Get the active tab class for the system permissions panel
     */
    get systemPermissionsPanelClass() {
        return this.activePanel === 'systemPermissions' ? 
            'slds-tabs_default__item slds-is-active' : 
            'slds-tabs_default__item';
    }
    
    /**
     * @description Get aria selected for objects panel
     */
    get objectsPanelAriaSelected() {
        return this.activePanel === 'objects' ? 'true' : 'false';
    }
    
    /**
     * @description Get aria selected for system permissions panel
     */
    get systemPermissionsPanelAriaSelected() {
        return this.activePanel === 'systemPermissions' ? 'true' : 'false';
    }
    
    /**
     * @description Get the content class for the objects panel
     */
    get objectsPanelContentClass() {
        return this.activePanel === 'objects' ? 
            'slds-tabs_default__content slds-show' : 
            'slds-tabs_default__content slds-hide';
    }
    
    /**
     * @description Get the content class for the system permissions panel
     */
    get systemPermissionsPanelContentClass() {
        return this.activePanel === 'systemPermissions' ? 
            'slds-tabs_default__content slds-show' : 
            'slds-tabs_default__content slds-hide';
    }

    /**
     * @description Get whether objects have been loaded (for template access)
     */
    get areObjectsLoaded() {
        return this.objectsLoaded;
    }
}