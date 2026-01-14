import { LightningElement, wire } from 'lwc';
import getLastClonedProfiles from '@salesforce/apex/ProfileClonerController.getLastClonedProfiles';

export default class LastClonedProfiles extends LightningElement {
    columns = [
        { label: 'Cloned Profile Name', fieldName: 'Name', type: 'text' },
        {label: 'PermissionSet Name', fieldName:'SA_Audit__NewPermission__c',type: 'text'}
    ];
    clonedProfiles = [];
    error;

    @wire(getLastClonedProfiles)
    wiredProfiles({ error, data }) {
        if (data) {
            this.clonedProfiles = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.clonedProfiles = [];
        }
    }
}