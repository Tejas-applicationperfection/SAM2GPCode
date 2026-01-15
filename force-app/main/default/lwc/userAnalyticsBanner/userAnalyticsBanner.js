import { LightningElement, wire, track } from 'lwc';
import getCriticalAccessData from '@salesforce/apex/UserCloneController.getCriticalAccessData';

export default class UserAnalyticsBanner extends LightningElement {
    @track criticalUsers = [];
    @track selectedUserId = null;
    @track error;
    @track currentPage = 1;
    itemsPerPage = 10;
    columns = [
        { label: 'User Name', fieldName: 'userName', type: 'text' },
        { label: 'Access Level', fieldName: 'accessLevel', type: 'text' },
        { label: 'Last Accessed', fieldName: 'lastAccessed', type: 'date', typeAttributes: { year: "numeric", month: "short", day: "2-digit", hour: "2-digit", minute: "2-digit"}}
    ];

    @wire(getCriticalAccessData)
    wiredData({ error, data }) {
        if (data) {
            this.criticalUsers = data.map(user => ({
                ...user,
                isExpanded: false,
                buttonLabel: 'Show Details',
                chevronIcon: 'utility:chevronright',
                modifySources: user.modifyAllSources.join(', '),
                apexSources: user.authorApexSources.join(', '),
                apiSources: user.apiAccessSources.join(', ')
            }));
        } else if (error) {
            this.error = error;
        }
    }

    get hasData() {
        return this.criticalUsers.length > 0;
    }

    handleUserClick(event) {
        const userId = event.currentTarget.dataset.userid;
        this.criticalUsers = this.criticalUsers.map(user => {
            const isExpanded = user.userId === userId ? !user.isExpanded : false;
            return {
                ...user,
                isExpanded,
                buttonLabel: isExpanded ? 'Hide Details' : 'Show Details',
                chevronIcon: `utility:chevron${isExpanded ? 'down' : 'right'}`
            };
        });
        
        const listItem = event.currentTarget.closest('.user-item');
        listItem.classList.toggle('expanded');
    }

    get expandedDetails() {
        return this.criticalUsers.filter(user => user.isExpanded);
    }

    get paginatedUsers() {
        const start = (this.currentPage - 1) * this.itemsPerPage;
        const end = start + this.itemsPerPage;
        return this.criticalUsers.slice(start, end);
    }

    get totalPages() {
        return Math.ceil(this.criticalUsers.length / this.itemsPerPage);
    }

    handlePrevious() {
        if (this.currentPage > 1) this.currentPage--;
    }

    handleNext() {
        if (this.currentPage < this.totalPages) this.currentPage++;
    }

    get isPreviousDisabled() {
        return this.currentPage === 1;
    }

    get isNextDisabled() {
        return this.currentPage === this.totalPages;
    }
}