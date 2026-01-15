import { LightningElement, wire,track  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import { reduceErrors } from 'c/ldsUtils';
//import fetchProfileOptions from '@salesforce/apex/ProfileToPermissionSetCloner.fetchProfileOptions';
import fetchLicenseOptions from '@salesforce/apex/ProfileToPermissionSetCloner.fetchLicenseOptions';
import fetchProfileOptionsByLicense from '@salesforce/apex/ProfileToPermissionSetCloner.fetchProfileOptionsByLicense'; 
import cloneProfileToPermissionSet from '@salesforce/apex/ProfileToPermissionSetCloner.cloneProfileToPermissionSet';
import getCloningHistory from '@salesforce/apex/ProfileToPermissionSetCloner.getCloningHistory';
//import cloneRecordTypes from '@salesforce/apex/ProfileToPermissionSetCloner.cloneRecordTypes';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import getPageUrlInfo from '@salesforce/apex/ProfileToPermissionSetCloner.getPageUrlInfo'; 


//import logoApplicationPerfection from '@salesforce/resourceUrl/SA_Audit__logoApplicationPerfection';
//import logo from '@salesforce/resourceUrl/SA_Audit__logo';
//import{loadStyles} from 'lightning/platFormResourseloader';
 




export default class ProfileToPset_LWC_App extends  NavigationMixin(LightningElement)  {
    permissionSetId; 
    //resourceLogoApplicationPerfection = logoApplicationPerfection;
    //resourceLogo = logo;
     @track isLoaded = false;
     @track pageUrl;
     @track isInCommunity;
    //@track permissionName = [];
    @track profileOptions = [];
    @track licenseOptions = [];
     @track selectedProfiles = []; 
     @track selectedLicense;
    @track columns = [
        { label: 'Profile Name', fieldName: 'ProfileName', type: 'text' },
        { label: 'Permission Set Name', fieldName: 'PermissionSetName', type: 'text' },
        { label: 'Cloned Date', fieldName: 'ClonedDate', type: 'date' },
    ];
    @track data;
    @track permissionName;
    @track wiredHistoryResult;
    @track isShowModal = false;
    @track isHistory = false; 
    
     
    @track processedObjects = [];
    @track processedObjectsColumns = [
        { label: 'Object Name', fieldName: 'objectName', type: 'text' },
        { label: 'Fields', fieldName: 'fields', type: 'text' }
    ];

    renderedCallback(){
        let style = document.createElement('style');        
        style.innerText = '.custom-table #brandBand_2 > div > div > div > div > app_flexipage-lwc-app-flexipage > app_flexipage-lwc-app-flexipage-decorator > slot > app_flexipage-lwc-app-flexipage-internal > forcegenerated-adg-rollup_component___force-generated__flexipage_-app-page___-s-a_-audit__-c-l-o-n-e-r > forcegenerated-flexipage_cloner__js > flexipage-lwc-app-home-template-two-columns-stacked > div > div > div.grouping.grouping1 > div > slot > flexipage-component2 > slot > sa_audit-profile-to-pset_-l-w-c_-app > article > div:nth-child(3) > lightning-datatable > div.dt-outer-container > div > div > table > thead > tr > th:nth-child(4) > lightning-primitive-header-factory > div > span{color: #FFFFFF;  background: #4682B4;}';
    }
    

    /*openContactUSLink(event) {
        const buttonLabel = event.target.label;
        let url = '';
        if (buttonLabel === 'Request a feature/support') {
            url = 'https://applicationperfection.com/contact/';
        } else if (buttonLabel === 'Help/Training') {
            url = 'https://applicationperfection.com/security-access-manager-help-training/';
        } else if (buttonLabel === "FAQ's") {
            url = 'https://applicationperfection.com/security-access-manager-faqs/';
        } else if (buttonLabel === 'Release Notes') {
            url = 'https://applicationperfection.com/security-access-manager-release-notes/';
        }
        window.open(url, '_blank');
    }*/
    errors; 
    @wire(getPageUrlInfo)
    wiredPageUrlInfo({ error, data }) {
        if (data) {
            this.pageUrl = data.pageUrl;
            this.isInCommunity = data.isInCommunity;
        } else if (error) {
            // Handle error
        }
    }
    /*@wire(cloneRecordTypes)wiredecordtypeOptions ({data,error}) {
        if (data) {
            this.profileOptions = data.map(option => ({
                label: option.label,
                value: option.value
            }));
            


        } else if (error) {
            this.errors = reduceErrors(error);

            this.showToast('Error', 'Failed to fetch profiles', 'error');
        }
    }
     */
    @wire(fetchLicenseOptions)
    wiredLicenseOptions({ error, data }) {
        if (data) {
            this.licenseOptions = data.map(option => ({
                label: option.label,
                value: option.value
            }));
        } else if (error) {
            // Handle error
        }
    }

    // This function fetches profile options based on the selected license
    @wire(fetchProfileOptionsByLicense, { licenseName: '$selectedLicense' })
    wiredProfileOptions({ error, data }) {
        if (data) {
            // First, map the data to the desired format
            let mappedData = data.map(option => ({
                label: option.label,
                value: option.value
            }));
            
            // Then, sort the mapped data alphabetically by label
            this.profileOptions = mappedData.sort((a, b) => {
                return a.label.localeCompare(b.label);
            });
        }  else if (error) {
            // Handle error
        }
    }

    // Handler for license change
    handleLicenseChange(event) {
        this.selectedLicense = event.detail.value;
        // Optionally reset profiles selection upon changing license
        this.selectedProfiles = [];
        this.permissionName = '';
    }

    // Handler for profile selection change
    handleProfileChange(event) {
        this.selectedProfiles = event.detail.value; // Assuming this is for single selection, adjust if it's multi-select
        this.permissionName = '';
    }

    @wire(getCloningHistory)
    wiredHistory(result) {
        if (result.data) {
            this.data = result.data;
            this.wiredHistoryResult = result;
        } else if (result.error) {
            // Handle error appropriately
        }
    }/*
    @wire(getCloningHistory)
    wiredHistory(result) {
        if (result.data) {
            console.log('Data from Apex:', result.data);
            this.data = result.data.map(record => ({
                ...record,
                ClonedDate: new Date(record.ClonedDate).toLocaleDateString('en-GB', { day: '2-digit', month: '2-digit', year: '4-digit' })
            }));
            console.log('Modified Data:', this.data);
            this.wiredHistoryResult = result;
        } else if (result.error) {
            // Handle error appropriately
        }
    }
    */ 

    refreshData() {

        return refreshApex(this.wiredHistoryResult);
    }

    handleHistory() {
        this.isHistory = !this.isHistory; 
    }


    //modal box
    hideModalBox() {  
        this.isShowModal = false;
    }

     handlePermissionSetChange(event) {
        this.permissionName = event.target.value;

    } 
 
    handleCloneProfilesToPermissionSets() {
        this.isLoaded = true;
        if (this.selectedProfiles.length === 0) {
            this.showToast('Error', 'select atleast one profile');
            this.isLoaded = false;
            return;
        }  
        // Call the Apex method to clone profiles to permission sets
        cloneProfileToPermissionSet({ profileNames: this.selectedProfiles, permissionName: this.permissionName })
            .then( newPermissionSetId => {
                // Show a success message or toast
                this.permissionSetId = newPermissionSetId;
                this.isShowModal = true;
                this.showToast('Success', 'Profiles Cloned Successfully');
                this.isHistory = true;
                //this.refreshHistory();
                 
            })
            .catch((error) => {
                // Handle errors

                 
               // let errorString = error.message; // Assuming message holds the error string
                 //   console.log('An errorString',errorString);
                   // if (errorString.includes('The label you entered is in use')) {

                        this.showToast('Error', error, 'error');
                    //} 
            })
            .finally(() => {
                this.isLoaded = false;
            });
    }/*
    handleCloneProfilesToPermissionSets() {
        this.isLoaded = true;
        // Call the Apex method to clone profiles to permission sets
        cloneProfileToPermissionSet({
            profileNames: this.selectedProfiles,
            permissionName: this.permissionName
        })
        .then((result) => {
            // Show a success message or toast
            this.permissionSetId = result.PermissionSetId;
            this.isShowModal = true;
            this.showToast("Success", "Profiles Cloned Successfully");
            this.isHistory = true;
            this.refreshHistory();

            // Construct processedObjects
            this.processedObjects = [];
                for (const [objectName, fields] of Object.entries(result.ProcessedObjects)) {
                    this.processedObjects.push({
                        objectName,
                        fields: Array.from(fields).join(', ')
                    });
                }
            })
        .catch((error) => {
            // Handle errors
            console.error("Error cloning profiles to permission sets:", error);
            this.showToast("Error", "An error occurred while cloning profiles", "error");
        })
        .finally(() => {
            this.isLoaded = false;
        });
    }
  */ 
    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    linkToPermissionSet() {
       

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId:  this.permissionSetId,
                actionName: 'view'
            }
            
        }).then(url => {
            window.open(url, '_blank');
        }).catch( error => {

        });
    }
    linkToObjectAccess() {
        
        /*if (this.pageUrl) {
            
            const urlWithParameters = this.pageUrl +
                '?' + this.selectedProfiles;

    
            if (this._isCommunity) {
                // Navigation to PageReference type standard__webPage not supported in communities.
                window.open(urlWithParameters);
            } else {
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__webPage',
                    attributes: {
                        url: urlWithParameters
                    }
                }).then(generatedUrl => {
                    window.open(generatedUrl);
                });
            }
        }*/
        const urlToObjectAccess = '/lightning/n/SA_Audit__Object_Access';
        if (this._isCommunity) {
            // Handle navigation in community
            // You may need to handle community navigation differently
            // For example, using Community NavigationMixin
            // window.open(urlToObjectAccess); // Example, replace this with community navigation
        } else {
            window.open(urlToObjectAccess, '_blank'); // Open in a new tab
        }
    }
    navigateToUserClonerPage() {
        // Get the base URL of the org
        const baseUrl = window.location.origin;
        
        // Construct the URL to the User Cloner page
        // Replace 'User_Cloner' with the actual API name of your Lightning page
        const url = `${baseUrl}/lightning/n/SA_Audit__usereverything`;
        
        // Open in a new window/tab
        window.open(url, '_blank', 'noopener,noreferrer');
    }
    linkToObjectnFieldsAccess() {
       
        /* 
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'SA_Audit__Objects_Fields'
            },
            state: {
                Profiles: this.selectedProfiles,
                permissionId: this.permissionSetId
            }
        }).then(url => {
            window.open(url, '_blank');
        }).catch( error => {

        });*/
        const urlToObjectFieldsAccess = '/lightning/n/SA_Audit__Objects_Fields';
        if (this._isCommunity) {
            // Handle navigation in community
            // You may need to handle community navigation differently
            // For example, using Community NavigationMixin
            // window.open(urlToObjectAccess); // Example, replace this with community navigation
        } else {
            window.open(urlToObjectFieldsAccess, '_blank'); // Open in a new tab
        }
    }
   
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}