import { LightningElement, track } from 'lwc';
// Use the dedicated Cloner Suite access check (Apex: paidfeatureaccess2)
import checkPaidFeatureAccess from '@salesforce/apex/SecurityAccessManagerController.paidfeatureaccess2';
 
export default class NavigationCloner extends LightningElement {
    // Feature Access Control
    @track hasAccess = true;
    @track isCheckingAccess = true;
    
    // Reactive properties to control visibility of child components
 
    showProfileComponent = false;
    showUserCloneComponent = false;
    showUserAnalyticsComponent = false;

    // Reactive properties for card titles
    currentPage = '';
    currentPage2 = '';
    
    connectedCallback() {
        console.log('showAds:', this.showAds); // Check the value in the browser console
        // Check feature access first
        this.checkFeatureAccess();
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
    get showProfileToPsetLwcApp() {
        return this.currentPage === 'permissionsCloner';
    }
    

    
    get showUserClone() {
        return this.currentPage === 'userClone';
    }

    

    // Handler for "Profile To Permission Set" button
    handleProfileClick() {
        this.showProfileComponent = true;
        this.showUserCloneComponent = false;
        this.showUserAnalyticsComponent = false;
        this.scrollToComponent();
    }

    // Handler for "User Clone" button
    handleUserCloneClick() {
        this.showProfileComponent = false;
        this.showUserCloneComponent = true;
        this.showUserAnalyticsComponent = false;
        this.scrollToComponent();
    }
    handleUserAnalyticsClick(){
        this.showProfileComponent = false;
        this.showUserCloneComponent = false;
        this.showUserAnalyticsComponent = true;
        this.scrollToComponent();
    }

    scrollToComponent() {
        // Wait for DOM update then scroll
        setTimeout(() => {
            const container = this.template.querySelector('.component-container');
            if (container) {
                container.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        }, 50); // Short delay to ensure component is rendered
    }

    handleImageError(event) {
        event.target.style.display = 'none';
    }

    get areTabsActive() {
        return this.showProfileComponent || this.showUserCloneComponent;
    }
}