public with sharing class PsetGroupDescription {
    public Boolean isEdit { get; set; }
    public String selectedPerm { get; set; }
    public Boolean OrgIsAccessible { get; set; }
    public String exportUser { get; set; }
    public String xmlheader { get; set; }
    public String endfile { get; set; }
    public String currentLanguage { get; set; }
    public Organization org { get; set; }
    public Boolean noEndpointMetadata { get; set; }
    
    
    
    public PageReference openContactUSLink(){
        PageReference pageRef;
        pageRef = new PageReference('https://applicationperfection.com/contact/');
        return pageRef;
    }
    public PageReference openHelpTraining(){
        PageReference pageRef;
        pageRef = new PageReference('https://applicationperfection.com/security-access-manager-help-training/');
        return pageRef;
    }
    public PageReference openFAQ(){
        PageReference pageRef;
        pageRef = new PageReference('https://applicationperfection.com/security-access-manager-faqs/');
        return pageRef;
    }
    public PageReference openReleaseNotes(){
        PageReference pageRef;
        pageRef = new PageReference('https://applicationperfection.com/security-access-manager-release-notes/');
        return pageRef;
    }
    
    
     public PsetGroupDescription() {
        xmlheader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        endfile = '</Workbook>';
        exportUser = UserInfo.getName();
        Id currentUserId = UserInfo.getUserId();
        system.debug(currentUserId);
        User currentUser = [SELECT Id, Name FROM User WHERE Id =: currentUserId];
        currentLanguage = 'US';
        
        if(!Schema.getGlobalDescribe().get('Organization').getDescribe().isAccessible()) {
            OrgIsAccessible = false;
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You don\'t have access on Organization object');
            ApexPages.addMessage(myMsg);
        } else {
            OrgIsAccessible = true;
            
            noEndpointMetadata = false;
            String orgId = UserInfo.getOrganizationId();
            org = [SELECT Id , Name, NamespacePrefix FROM Organization WHERE ID = :orgID];
            system.debug('org name'+''+org.Name +''+ 'org Id' +''+ org.Id );
            
        }
     }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

}