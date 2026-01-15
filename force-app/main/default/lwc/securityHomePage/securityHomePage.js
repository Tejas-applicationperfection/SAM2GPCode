import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import HideLightningHeader from '@salesforce/resourceUrl/HideLightningHeader';
import { loadStyle } from 'lightning/platformResourceLoader';
import userLogoManager from '@salesforce/resourceUrl/UserLogoManager';
import permissionManagerLogo from '@salesforce/resourceUrl/PermissionManagerlogo';
import dictionaryBuilderLogo from '@salesforce/resourceUrl/dictionaryBuilderLogo';
import permissionAuditLogo from '@salesforce/resourceUrl/permissionAuditLogo';
import samBgcRemoved from '@salesforce/resourceUrl/samBgcRemoved';
import InstantPermissionlogo from '@salesforce/resourceUrl/InstantPermissionlogo';
import userDictionaryLogo from '@salesforce/resourceUrl/userDictionaryLogo';
import reportMangerLogo from '@salesforce/resourceUrl/reportMangerLogo';
import getFeatureLicenseStatus from '@salesforce/apex/SecurityHomePageController.getFeatureLicenseStatus';

export default class SecurityHomePage extends NavigationMixin(LightningElement) {
    @api hideStandardHeader = false;
    @track featureLicenseMap = {};
    @track isLoadingLicenses = true;
    
    lastScrollTop = 0;
    scrollThreshold = 50;
    
    // Getter for the UserLogoManager URL
    get userLogoManagerUrl() {
        return userLogoManager;
    }
    get intelTabLogoManagerUrl() {
        return userLogoManager;
    }
    get systemPermissionsLogoManagerUrl() {
        return userLogoManager;
    }
    get permissionsManagerLogoManagerUrl() {
        return permissionManagerLogo;
    }
    get instantClonerLogoManagerUrl() {
        return InstantPermissionlogo;
    }
    get auditPlannerLogoManagerUrl() {
        return permissionAuditLogo;
    }
    get reportManagerLogoManagerUrl() {
        return reportMangerLogo;
    }
    get dataDictionaryLogoManagerUrl() {    
        return dictionaryBuilderLogo;
    }
    get dataDictionaryUserLogoManagerUrl() {
        return userDictionaryLogo;
    }
    get samBgcRemovedUrl() {
        return samBgcRemoved;
    }
    
    connectedCallback() {
        // Load CSS to hide standard header
        loadStyle(this, HideLightningHeader);
        
        // Load feature license status
        this.loadFeatureLicenses();
        
        // Bind scroll handler once and save reference
        this._boundScrollHandler = this.handleScroll.bind(this);
        
        // Add scroll event listener
        if (typeof window !== 'undefined') {
            window.addEventListener('scroll', this._boundScrollHandler);
        }
        
        // Set flag to initialize DOM elements in renderedCallback
        this._needsInitialization = true;
    }
    
    /**
     * Load feature license status from Apex
     */
    async loadFeatureLicenses() {
        try {
            this.isLoadingLicenses = true;
            const result = await getFeatureLicenseStatus();
            this.featureLicenseMap = result;
        } catch (error) {
            console.error('Error loading feature licenses:', error);
            // Default to false if error
            this.featureLicenseMap = {};
        } finally {
            this.isLoadingLicenses = false;
        }
    }
    
    /**
     * Get license status for a specific feature
     * @param {String} featureName - The feature identifier
     * @returns {Boolean} - License status
     */
    getFeatureLicenseStatus(featureName) {
        return this.featureLicenseMap[featureName] === true;
    }
    
    /**
     * Get license badge class for a feature
     * @param {String} featureName - The feature identifier
     * @returns {String} - CSS class for badge
     */
    getFeatureBadgeClass(featureName) {
        const isLicensed = this.getFeatureLicenseStatus(featureName);
        return isLicensed ? 'license-badge licensed' : 'license-badge unlicensed';
    }
    
    disconnectedCallback() {
        // Remove scroll event listener using saved reference
        if (this._boundScrollHandler && typeof window !== 'undefined') {
            window.removeEventListener('scroll', this._boundScrollHandler);
        }
    }
    
    handleScroll() {
        if (typeof window === 'undefined' || typeof document === 'undefined') {
            return;
        }
        
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        const header = this.template.querySelector('.header-container');
        
        // Only proceed if header element exists and has classList
        if (header && header.classList) {
            // If we've scrolled past the threshold
            if (scrollTop > this.scrollThreshold) {
                // Scrolling down
                if (scrollTop > this.lastScrollTop) {
                    header.classList.add('hidden');
                } 
                // Scrolling up
                else {
                    header.classList.remove('hidden');
                }
            } else {
                // At the top of the page, show header
                header.classList.remove('hidden');
            }
            
            this.lastScrollTop = scrollTop;
        }
    }
    
    // License status getters for each feature
    get objectSecurityLicensed() {
        return this.getFeatureLicenseStatus('objectSecurity');
    }
    
    get fieldSecurityLicensed() {
        return this.getFeatureLicenseStatus('fieldSecurity');
    }
    
    get recordAccessLicensed() {
        return this.getFeatureLicenseStatus('recordAccess');
    }
    
    get intelTabLicensed() {
        return this.getFeatureLicenseStatus('intelTab');
    }
    
    get dataDescriptionEditorLicensed() {
        return this.getFeatureLicenseStatus('dataDescriptionEditor');
    }
    
    get systemPermissionsLicensed() {
        return this.getFeatureLicenseStatus('System_Permissions');
    }
    
    get permissionAuditLicensed() {
        return this.getFeatureLicenseStatus('permissionAudit');
    }
    
    get reportManagerLicensed() {
        return this.getFeatureLicenseStatus('reportManager');
    }
    
    get bulkExporterLicensed() {
        return this.getFeatureLicenseStatus('bulkExporter');
    }
    
    get lightningIntelLicensed() {
        return this.getFeatureLicenseStatus('lightningIntel');
    }
    
    get userAccessManagerLicensed() {
        return this.getFeatureLicenseStatus('userAccessManager');
    }
    
    get clonerAppLicensed() {
        return this.getFeatureLicenseStatus('clonerApp');
    }

    get privilegedPermissionsLicensed() {
        return this.getFeatureLicenseStatus('privilegedPermissions');
    }
    
    get userDataDictionaryLicensed() {
        return this.getFeatureLicenseStatus('userDataDictionary');
    }
    navigateToFeature(event) {
        const featureType = event.currentTarget.dataset.feature;
        
        // Map feature types to their corresponding pages or components
        const featureMap = {
            objectSecurity: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__Object_Access'
                }
            },
            fieldSecurity: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__Objects_Fields'
                }
            },
            systemPermissions: {
                type: 'standard__component',
                attributes: {
                    componentName: 'c__systemPermissionsPanel'
                }
            },
            
            recordAccess: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__RecordAccessLightningtab'
                }
            },
            dataDescriptionEditor: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__Data_Description_Editor'
                }
            },
            permissionAudit: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__PermissionAudit'
                }
            },
            instantCloner: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__ClonerApp'
                }
            },
            intelTab: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__Intel'
                }
            },
            User_Dictionary: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__User_Dictionary'
                }
            },
            System_Permissions: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__System_Permission'
                }
            },
            reportManager: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__Report_Manager_Pro'
                }
            },
            bulkExporter: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__BulkExporter'
                }
            },
            lightningIntel: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__Lightning_Intel'
                }
            },
            userAccessManager: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__UserAccessManager'
                }
            },
            clonerApp: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__ClonerApp'
                }
            },
            privilegedPermissions: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__Privileged_Permissions'
                }
            },
            userDataDictionary: {
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/SA_Audit__User_Data_Dictionary1'
                }
            }
                
            // Add other feature mappings as needed
        };
        
        // Get the navigation configuration for this feature
        const navConfig = featureMap[featureType];
        
        if (navConfig) {
            // Navigate to the component
            this[NavigationMixin.Navigate](navConfig);
        } else {
            // For features without specific navigation, log message
            console.log('Navigation not yet implemented for feature:', featureType);
        }
    }
    
    // Handle navigation to app pages from footer
    handleAppNavigation(event) {
        const appElement = event.currentTarget;
        const appType = appElement.dataset.app;
        
        // Map app types to their corresponding pages or URLs
        const appMap = {
            permissionsManager: {
                type: 'standard__app',
                attributes: {
                    appTarget: 'c__PermissionsManager',
                    pageRef: {
                        type: 'standard__navItemPage',
                        attributes: {
                            apiName: 'Permissions_Manager'
                        }
                    }
                }
            },
            ultimateUser: {
                type: 'standard__app',
                attributes: {
                    appTarget: 'c__UltimateUserManager',
                    pageRef: {
                        type: 'standard__navItemPage',
                        attributes: {
                            apiName: 'User_Manager'
                        }
                    }
                }
            },
            instantCloner: {
                type: 'standard__app',
                attributes: {
                    appTarget: 'c__InstantPermissionsCloner',
                    pageRef: {
                        type: 'standard__navItemPage',
                        attributes: {
                            apiName: 'Permissions_Cloner'
                        }
                    }
                }
            },
            auditPlanner: {
                type: 'standard__app',
                attributes: {
                    appTarget: 'c__PermissionsAuditPlanner',
                    pageRef: {
                        type: 'standard__navItemPage',
                        attributes: {
                            apiName: 'Audit_Planner'
                        }
                    }
                }
            },
            reportManager: {
                type: 'standard__app',
                attributes: {
                    appTarget: 'c__ReportManager',
                    pageRef: {
                        type: 'standard__navItemPage',
                        attributes: {
                            apiName: 'Report_Manager'
                        }
                    }
                }
            },
            dataDictionary: {
                type: 'standard__app',
                attributes: {
                    appTarget: 'c__DataDictionary',
                    pageRef: {
                        type: 'standard__navItemPage',
                        attributes: {
                            apiName: 'Data_Dictionary'
                        }
                    }
                }
            },
            dataDictionaryUser: {
                type: 'standard__app',
                attributes: {
                    appTarget: 'c__DataDictionaryUser',
                    pageRef: {
                        type: 'standard__navItemPage',
                        attributes: {
                            apiName: 'Data_Dictionary_User'
                        }
                    }
                }
            }
        };
        
        // Get the navigation configuration for this app
        const navConfig = appMap[appType];
        
        if (navConfig) {
            // Navigate to the app
            this[NavigationMixin.Navigate](navConfig);
        } else {
            // For apps without specific navigation, navigate to a default page
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/page/home'
                }
            });
        }
    }
    
    handleNavLinkClick(event) {
        const section = event.target.textContent;
        console.log('Navigation to section:', section);
        
        // Implement smooth scrolling to sections if they exist on the same page
        // or navigation to different pages
    }
    
    handleSignIn() {
        // Navigate to sign in page
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/login'
            }
        });
    }
    
    handleGetStarted() {
        // Navigate to get started page or open a modal
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/setup/securityCenter/home'
            }
        });
    }
    
    handleExploreAll() {
        // Navigate to features overview page
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: 'https://applicationperfection.com/security-access-manager-help-training/'
            }
        });
    }
    
    handleFooterLinkClick(event) {
        const linkText = event.target.textContent;
        
        // Map link text to URLs
        const linkMap = {
            'About Us': '/about',
            'Contact': '/contact',
            'Privacy Policy': '/privacy',
            'Terms of Service': '/terms'
        };
        
        // Navigate to the appropriate page
        const url = linkMap[linkText] || '/';
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }
    
    renderedCallback() {
        // Initialize DOM elements only once after first render
        if (this._needsInitialization) {
            this._needsInitialization = false;
            
            // Apply custom styles for header spacing based on configuration
            if (this.hideStandardHeader) {
                const hostElement = this.template.host;
                if (hostElement && hostElement.classList) {
                    // Add a class to the host element to adjust styles when header is hidden
                    hostElement.classList.add('hide-standard-header');
                }
            }
            
            // Initialize header visibility
            const header = this.template.querySelector('.header-container');
            if (header && header.classList) {
                // Ensure header is visible initially
                header.classList.remove('hidden');
            }
        }
    }
}