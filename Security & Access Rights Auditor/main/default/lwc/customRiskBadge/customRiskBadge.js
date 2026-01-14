import { LightningElement, api } from 'lwc';

export default class CustomRiskBadge extends LightningElement {
    @api riskLevel;
    @api riskBadgeClass;

    get badgeClass() {
        return `risk-level-badge ${this.riskBadgeClass || ''}`;
    }

    get themeClass() {
        // Extract theme class from riskBadgeClass
        if (this.riskBadgeClass && this.riskBadgeClass.includes('slds-theme_')) {
            const themeMatch = this.riskBadgeClass.match(/slds-theme_\w+/);
            return themeMatch ? themeMatch[0] : 'slds-theme_default';
        }
        return 'slds-theme_default';
    }
}