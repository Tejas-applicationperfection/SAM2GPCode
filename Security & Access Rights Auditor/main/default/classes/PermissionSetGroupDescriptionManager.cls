public with sharing class PermissionSetGroupDescriptionManager {
    // Properties
    public List<SelectOption> allPSetGroups { get; set; }
     public List<SelectOption> allPSetGrpDecriptionCount { get; set; }
    public List<SelectOption> selectedPSetGroups { get; set; }
    public List<PermissionSetGroupWrapper> pSetGroupDescriptions { get; set; }
    public Boolean isEdit { get; set; }
    public Boolean OrgIsAccessible { get; set; }
    public String exportUser { get; set; }
    public String xmlheader { get; set; }
    public String endfile { get; set; }
    public String currentLanguage { get; set; }
    public Organization org { get; set; }
    public Boolean noEndpointMetadata { get; set; }

    public Integer TotalPsetGrpCount { get; set; }
    public Integer descriptionCount { get; set; }
    public Decimal percentageDescriptionsPopulated { get; set; }
    
    
    
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
    
    
    
    // Constructor
    public PermissionSetGroupDescriptionManager() {
        allPSetGroups = new List<SelectOption>();
        allPSetGrpDecriptionCount = new List<SelectOption>();
        selectedPSetGroups = new List<SelectOption>();
        pSetGroupDescriptions = new List<PermissionSetGroupWrapper>();
        isEdit = false;
        TotalPsetGrpCount = 0;  // Initialize to 0
        descriptionCount = 0;
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

        // Populate available permission set groups
        for (PermissionSetGroup pSetGroup : [SELECT Id, DeveloperName,Description FROM PermissionSetGroup ORDER BY DeveloperName LIMIT 30000]) {
            allPSetGroups.add(new SelectOption(pSetGroup.Id, pSetGroup.DeveloperName));
            //allPSetGrpDecriptionCount.add(new SelectOption(pSetGroup.Id, pSetGroup.Description));
        }
         for (PermissionSetGroup pSetGroup : [SELECT Id, DeveloperName,Description FROM PermissionSetGroup ORDER BY DeveloperName LIMIT 30000]) {
             if(pSetGroup.Description != null && pSetGroup.Description != ''){
                  allPSetGrpDecriptionCount.add(new SelectOption(pSetGroup.Id, pSetGroup.Description));
             }
           
        }
       

        // Update total permission set groups count
        TotalPsetGrpCount = allPSetGroups.size();
        descriptionCount = allPSetGrpDecriptionCount.size();
        calculatePercentageDescriptionsPopulated();
    }

    public void fetchPSetGroupDescriptions() { 
    pSetGroupDescriptions.clear();
        
        
        // Check if the selected list exceeds 100
    if (selectedPSetGroups.size() > 100) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You can not select more than 100 permission set groups.'));
        return;
    }

    // Debugging: Check if any groups are selected
    System.debug('Selected Permission Set Groups: ' + selectedPSetGroups);

    // Check if any groups are selected
    if (!selectedPSetGroups.isEmpty()) {
        // Extract the Ids from selectedPSetGroups
        List<String> selectedIds = new List<String>();
        for (SelectOption option : selectedPSetGroups) {
            selectedIds.add(option.getValue()); // Extract the Id from SelectOption
        }

        // Debugging: Check the list of Ids to be used in the query
        System.debug('Selected Ids for SOQL Query: ' + selectedIds);

        // Fetch the selected PermissionSetGroups
        List<PermissionSetGroup> selectedGroups = [
            SELECT Id, DeveloperName, MasterLabel, Description, NamespacePrefix 
            FROM PermissionSetGroup 
            WHERE Id IN :selectedIds
        ];

        // Debugging: Check if the SOQL query returns any results
        System.debug('Fetched Permission Set Groups: ' + selectedGroups);

        // Map the result to display descriptions in the wrapper class
        Integer counter = 1;
        for (PermissionSetGroup pSetGroup : selectedGroups) {
            // Update constructor call to include masterLabel and description
            pSetGroupDescriptions.add(new PermissionSetGroupWrapper(
                counter, 
                pSetGroup, 
                pSetGroup.MasterLabel, 
                pSetGroup.Description // Include description here
            ));
            counter++;
        }

        // Reset the description count
        descriptionCount = 0;

        // Calculate the count of descriptions (non-null descriptions)
        for (PermissionSetGroupWrapper wrapper : pSetGroupDescriptions) {
            if (wrapper.description != null ) {//&& !wrapper.description.isEmpty()
                descriptionCount++;
            }
        }

        // Update the total count of permission set groups with descriptions
        TotalPsetGrpCount = selectedGroups.size();

        // Debugging: Check the populated descriptions list and count
        System.debug('Populated Permission Set Group Descriptions: ' + pSetGroupDescriptions);
        System.debug('Total Descriptions Populated: ' + descriptionCount);
    }
}

    
    public void calculatePercentageDescriptionsPopulated() {
        if (TotalPsetGrpCount > 0) {
            Decimal rawPercentage = (Decimal.valueOf(descriptionCount) / Decimal.valueOf(TotalPsetGrpCount)) * 100;
            percentageDescriptionsPopulated = rawPercentage.setScale(2); // Set the scale to 2 decimal places for clarity
        } else {
            percentageDescriptionsPopulated = 0; // Handle division by zero scenario
        }
        system.debug('Percentage of descriptions populated: ' + percentageDescriptionsPopulated);
    }
    

    // Toggle Edit Mode
    public void toggleEdit() {
        isEdit = !isEdit;
    }

    // Save Updated Descriptions
    public void saveDescriptions() {
        List<PermissionSetGroup> toUpdate = new List<PermissionSetGroup>();

        // Prepare updated Permission Set Groups
        for (PermissionSetGroupWrapper wrapper : pSetGroupDescriptions) {
            PermissionSetGroup updatedGroup = new PermissionSetGroup(
                Id = wrapper.pSetGroup.Id,
                Description = wrapper.description
            );
            toUpdate.add(updatedGroup);
        }

        // Update the Permission Set Groups
        if (!toUpdate.isEmpty()) {
            try {
                update toUpdate;

                // Show success message after update
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Permission Set Group descriptions updated successfully.'));
            } catch (DmlException e) {
                // Handle any errors during the update
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occurred while updating descriptions: ' + e.getMessage()));
            }
        }

        isEdit = false;
    }

    public PageReference ExportToExcel(){
        return Page.PermissionSetGroupExport;
    }

    // Wrapper Class for Permission Set Groups
    public class PermissionSetGroupWrapper {
        public Integer serialNumber { get; set; }
        public PermissionSetGroup pSetGroup { get; set; }
        public String masterLabel { get; set; }
        public String description { get; set; }

        public PermissionSetGroupWrapper(Integer serialNumber, PermissionSetGroup pSetGroup, String masterLabel, String description ) {
            this.serialNumber = serialNumber;
            this.pSetGroup = pSetGroup;
            this.masterLabel = pSetGroup.MasterLabel;
            this.description = pSetGroup.Description; // Initialize description
        }
    }

    public static MetadataService.MetadataPort createService() { 
        system.debug('TestingProfiles');  
        system.debug('debugg createService');
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        // service.endpoint_x = 'callout:SA_Audit__Tooling_API_Creds';
        service.timeout_x = 60000;
        return service;
    }
}