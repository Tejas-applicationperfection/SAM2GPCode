/*
Author     : Tejas Kshirsagar
Description: Controller for PermissionAudit App.      
*/
public with sharing class AuditObjectiveController {
    
    public AuditObjectiveController() { 
        //  boolean acc  = FeatureManagement.checkPackageBooleanValue('PaidFeatureAccess');
        //  system.debug('acc1--'+acc);
        integer managedObjectCount;       // To count managed objects
        integer descriptionCount ; 
        upsertAuditSteps();
    } 
    @AuraEnabled(cacheable=true)
    public static Boolean PaidFeatureAccess() {
        // Check if the feature is enabled for the user 
        // this line is not in used when creating specific packages
        // ye line ko uncomment mat kro agr specific package bna rhe ho.....
        //return FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess');
        
        
       //for show --- 
       return true; 
     
    
    }
    
    @AuraEnabled
    public static List<User> findUsers(String searchTerm) {
        String searchCriteria = '%' + searchTerm + '%';
        return [SELECT Id, Name FROM User WHERE Name LIKE :searchCriteria LIMIT 4000];
    }
    
    
    @AuraEnabled
    public static void updateStepOwner(SA_Audit__Audit_Step__c step, Id OwnerAs, String currentTemplateId) {
        System.debug('OwnerAs == ' + OwnerAs);
        System.debug('step == ' + step +'currentTemplateId'+currentTemplateId);
        
        try {
            // Retrieve the step record for the current template
            SA_Audit__Audit_Step__c updatedStep = [
                SELECT Name, Id, SA_Audit__Template__c , SA_Audit__OrderIndex__c, SA_Audit__OwnerAssined__c
                FROM SA_Audit__Audit_Step__c
                WHERE SA_Audit__Template__c = :currentTemplateId 
                AND Name = :step.Name
                LIMIT 1
            ];
            
            // Ensure step.Owner is not null and update the OwnerAssigned field
            if (OwnerAs != null) {
                if (Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OwnerAssined__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OwnerAssined__c.isUpdateable()) {
                        updatedStep.SA_Audit__OwnerAssined__c = OwnerAs;
                    }
            } else {
                System.debug('Error updating step: OwnerAssigned is null');
            }
            
            // Update the step
            update as User updatedStep;
        } catch (Exception e) {
            // Handle exception and throw a user-friendly error
            System.debug('Error updating step: ' + e.getMessage());
            throw new AuraHandledException('Failed to update Owner: ' + e.getMessage());
        }
    }
    
    /* @AuraEnabled
public static void upsertAuditSteps() {
List<SA_Audit__Audit_Step__c> defaultSteps = getAuditSteps();
system.debug('defaultSteps=' + defaultSteps);
List<String> stepNames = new List<String>();

// Extract Audit_Step__c names from the defaultSteps list
for (SA_Audit__Audit_Step__c defaultStep : defaultSteps) {
stepNames.add(defaultStep.Name);
}

// Old map saving the steps
Map<String, SA_Audit__Audit_Step__c> existingStepsMap = new Map<String, SA_Audit__Audit_Step__c>();

// Retrieve existing Audit_Step__c records by Name
List<SA_Audit__Audit_Step__c> dataa = [SELECT Id, Name FROM SA_Audit__Audit_Step__c WHERE Name IN :stepNames];
system.debug('dataa+' + dataa);

for (SA_Audit__Audit_Step__c existingStep : dataa) {
existingStepsMap.put(existingStep.Name, existingStep);
}

List<SA_Audit__Audit_Step__c> stepsToUpsert = new List<SA_Audit__Audit_Step__c>();
for (SA_Audit__Audit_Step__c defaultStep : defaultSteps) {
system.debug('defaultStep=' + defaultStep);

// Check Field-Level Security (FLS) for each field before updating or inserting
if (Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isAccessible() &&
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isAccessible() &&
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isAccessible() &&
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OwnerAssined__c.isAccessible() &&
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isUpdateable() &&
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isUpdateable() &&
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isUpdateable() &&
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OwnerAssined__c.isUpdateable()
&&
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isCreateable() &&
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isCreateable() &&
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isCreateable() &&
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OwnerAssined__c.isCreateable()) {

if (existingStepsMap.containsKey(defaultStep.Name) && dataa.size() == 0) {
// If the record with the same Name exists, update it
system.debug('helloo1');
SA_Audit__Audit_Step__c existingStep = existingStepsMap.get(defaultStep.Name); 
existingStep.SA_Audit__OrderIndex__c = defaultStep.SA_Audit__OrderIndex__c;
existingStep.SA_Audit__ReviewDatee__c = defaultStep.SA_Audit__ReviewDatee__c;
existingStep.SA_Audit__Comments__c = defaultStep.SA_Audit__Comments__c;
existingStep.SA_Audit__OwnerAssined__c = defaultStep.SA_Audit__OwnerAssined__c;
stepsToUpsert.add(existingStep);
} else {
// If the record with the same Name doesn't exist, insert it
system.debug('helloo2');
stepsToUpsert.add(defaultStep);
}
} else {
system.debug('User does not have FLS access or is not allowed to update one or more required fields.');
}
}

if (!stepsToUpsert.isEmpty()) {
system.debug('helloo3');
upsert stepsToUpsert SA_Audit__Audit_Step__c.Fields.Name;
}
}*/
    
    @AuraEnabled
    public static void upsertAuditSteps() {
        // Retrieve the default audit steps
        List<SA_Audit__Audit_Step__c> defaultSteps = getAuditSteps();
        System.debug('defaultSteps=' + defaultSteps);
        
        // Extract the names of the default steps
        List<String> stepNames = new List<String>();
        for (SA_Audit__Audit_Step__c defaultStep : defaultSteps) {
            stepNames.add(defaultStep.Name);
        }
        
        // Map to store existing audit steps by name
        Map<String, SA_Audit__Audit_Step__c> existingStepsMap = new Map<String, SA_Audit__Audit_Step__c>();
        
        // Retrieve existing audit steps with matching names
        List<SA_Audit__Audit_Step__c> existingSteps = [
            SELECT Id, Name, SA_Audit__OrderIndex__c, SA_Audit__ReviewDatee__c, SA_Audit__DueDate__c ,
            SA_Audit__Comments__c, SA_Audit__OwnerAssined__c 
            FROM SA_Audit__Audit_Step__c 
            WHERE Name IN :stepNames
        ];
        System.debug('existingSteps=' + existingSteps);
        
        // Populate the map with existing audit steps
        for (SA_Audit__Audit_Step__c step : existingSteps) {
            existingStepsMap.put(step.Name, step);
        }
        
        List<SA_Audit__Audit_Step__c> stepsToUpsert = new List<SA_Audit__Audit_Step__c>();
        
        // Check FLS once for the fields
        Boolean hasAccess = Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isAccessible() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isAccessible() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isAccessible() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OwnerAssined__c.isAccessible() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isUpdateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isUpdateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isUpdateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OwnerAssined__c.isUpdateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isCreateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isCreateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isCreateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OwnerAssined__c.isCreateable();
        
        if (!hasAccess) {
            System.debug('User does not have FLS access or cannot update one or more required fields.');
            return;
        }
        
        // Iterate through the default steps to prepare for upsert
        for (SA_Audit__Audit_Step__c defaultStep : defaultSteps) {
            System.debug('Processing defaultStep=' + defaultStep);
            
            if (existingStepsMap.containsKey(defaultStep.Name)) {
                // Update the existing record
                SA_Audit__Audit_Step__c existingStep = existingStepsMap.get(defaultStep.Name);
                existingStep.SA_Audit__OrderIndex__c = defaultStep.SA_Audit__OrderIndex__c;
                existingStep.SA_Audit__ReviewDatee__c = defaultStep.SA_Audit__ReviewDatee__c;
                existingStep.SA_Audit__Comments__c = defaultStep.SA_Audit__Comments__c;
                existingStep.SA_Audit__OwnerAssined__c = defaultStep.SA_Audit__OwnerAssined__c;
                existingStep.SA_Audit__DueDate__c = defaultStep.SA_Audit__DueDate__c;
                stepsToUpsert.add(existingStep);
            } else {
                // Insert the new record
                stepsToUpsert.add(defaultStep);
            }
        }
        
        // Perform the upsert operation if there are records to upsert
        if (!stepsToUpsert.isEmpty()) {
            System.debug('Upserting steps: ' + stepsToUpsert);
            upsert as User stepsToUpsert SA_Audit__Audit_Step__c.Fields.Name;
        }
    }
    
    
    @AuraEnabled
    public static List<SA_Audit__Audit_Step__c> getAuditSteps() {
        Id CurrentUserId = UserInfo.getUserId();
        List<SA_Audit__Audit_Step__c> defaultSteps = new List<SA_Audit__Audit_Step__c>();
        
        // Define the steps, checking FLS on each field
        if (Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Name.isCreateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Template__c.isCreateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isCreateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isCreateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isCreateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderVal__c.isCreateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OwnerAssined__c.isCreateable()&&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Name.isUpdateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Template__c.isUpdateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isUpdateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isUpdateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isUpdateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderVal__c.isUpdateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OwnerAssined__c.isUpdateable() 
           ) {
               
               // Default Template Steps
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Define Audit Team', SA_Audit__Template__c = 'Default', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = '', SA_Audit__OrderIndex__c = 1, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Define Objectives', SA_Audit__Template__c = 'Default', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = '', SA_Audit__OrderIndex__c = 2, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Review Current Setup', SA_Audit__Template__c = 'Default', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = '', SA_Audit__OrderIndex__c = 3, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Define Ownership and Sign Off', SA_Audit__Template__c = 'Default', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = '', SA_Audit__OrderIndex__c = 4, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Identify risk areas and sensitive data', SA_Audit__Template__c = 'Default', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = '', SA_Audit__OrderIndex__c = 5, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Document Model & Changes', SA_Audit__Template__c = 'Default', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = '', SA_Audit__OrderIndex__c = 6, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Implement New Model', SA_Audit__Template__c = 'Default', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = '', SA_Audit__OrderIndex__c = 7, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Test Deploy Test', SA_Audit__Template__c = 'Default', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = '', SA_Audit__OrderIndex__c = 8, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Communicate', SA_Audit__Template__c = 'Default', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = '', SA_Audit__OrderIndex__c = 9, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               
               // GDPR Template Steps - Based on "10 Key GDPR Audit Steps for Your App.md"
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Understand Data Processing Activities', SA_Audit__Template__c = 'GDPR', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = 'Identify and document all personal data your organization collects, processes, and stores, including data sources and purposes.', SA_Audit__OrderIndex__c = 1, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Establish Legal Grounds for Processing', SA_Audit__Template__c = 'GDPR', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = 'Verify that each data processing activity has a valid legal basis under GDPR (e.g., consent, contractual necessity, legal obligation).', SA_Audit__OrderIndex__c = 2, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Review Data Subject Rights Processes', SA_Audit__Template__c = 'GDPR', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = 'Develop and test procedures to handle requests for access, correction, deletion, portability, and objection.', SA_Audit__OrderIndex__c = 3, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Assess Third-Party Data Sharing', SA_Audit__Template__c = 'GDPR', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = 'Audit all third-party data processors to ensure they comply with GDPR and have adequate safeguards.', SA_Audit__OrderIndex__c = 4, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Implement Privacy by Design and Default', SA_Audit__Template__c = 'GDPR', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = 'Ensure that systems and processes include privacy measures by default, minimizing the collection and retention of personal data.', SA_Audit__OrderIndex__c = 5, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Create a Data Breach Response Plan', SA_Audit__Template__c = 'GDPR', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = 'Develop a clear process for detecting, reporting, and responding to data breaches within the GDPR-mandated 72 hours.', SA_Audit__OrderIndex__c = 6, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Perform Regular Data Protection Impact Assessments', SA_Audit__Template__c = 'GDPR', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = 'Identify high-risk data processing activities and document the risks, safeguards, and decisions (DPIAs).', SA_Audit__OrderIndex__c = 7, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Review Data Retention Policies', SA_Audit__Template__c = 'GDPR', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = 'Define clear rules for retaining personal data and establish deletion schedules for data no longer needed.', SA_Audit__OrderIndex__c = 8, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Train Employees on GDPR Compliance', SA_Audit__Template__c = 'GDPR', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = 'Provide training sessions to ensure staff understands GDPR principles, their responsibilities, and best practices.', SA_Audit__OrderIndex__c = 9, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
               defaultSteps.add(new SA_Audit__Audit_Step__c(Name = 'Maintain Detailed GDPR Audit Logs', SA_Audit__Template__c = 'GDPR', SA_Audit__ReviewDatee__c = '', SA_Audit__Comments__c = 'Regularly update and keep accessible records of processing activities, compliance efforts, and audit findings.', SA_Audit__OrderIndex__c = 10, SA_Audit__OrderVal__c = '1', SA_Audit__OwnerAssined__c = CurrentUserId, SA_Audit__DueDate__c = ''));
   
           }
        
        List<String> stepNames = new List<String>();
        for (SA_Audit__Audit_Step__c defaultStep : defaultSteps) {
            system.debug('defaultStep=' + defaultStep);
            stepNames.add(defaultStep.Name);
        }
        
        // Check for existing records by Name
        List<SA_Audit__Audit_Step__c> existingSteps = [SELECT Id, Name FROM SA_Audit__Audit_Step__c WHERE Name IN :stepNames];
        system.debug('existingSteps=' + existingSteps);
        
        List<SA_Audit__Audit_Step__c> AllSteps = [SELECT Id, Name FROM SA_Audit__Audit_Step__c WHERE Id != null];
        system.debug('existingSteps=' + existingSteps);
        
        Map<String, SA_Audit__Audit_Step__c> existingStepsMap = new Map<String, SA_Audit__Audit_Step__c>();
        for (SA_Audit__Audit_Step__c existingStep : existingSteps) {
            existingStepsMap.put(existingStep.Name, existingStep);
        }
        
        List<SA_Audit__Audit_Step__c> stepsToInsert = new List<SA_Audit__Audit_Step__c>();
        for (SA_Audit__Audit_Step__c defaultStep : defaultSteps) {
            // Check if this specific step (by Name and Template) doesn't already exist
            if (!existingStepsMap.containsKey(defaultStep.Name)) {
                // Also verify the step doesn't exist for this specific template
                List<SA_Audit__Audit_Step__c> templateSpecificSteps = [
                    SELECT Id FROM SA_Audit__Audit_Step__c 
                    WHERE Name = :defaultStep.Name 
                    AND SA_Audit__Template__c = :defaultStep.SA_Audit__Template__c 
                    LIMIT 1
                ];
                
                if (templateSpecificSteps.isEmpty()) {
                    // Perform FLS checks before insert
                    if (Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Name.isCreateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Template__c.isCreateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isCreateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isCreateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isCreateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderVal__c.isCreateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OwnerAssined__c.isCreateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Name.isUpdateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Template__c.isUpdateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isUpdateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isUpdateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isUpdateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderVal__c.isUpdateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OwnerAssined__c.isUpdateable()) {
                            system.debug('Inserting new step: ' + defaultStep);
                            stepsToInsert.add(defaultStep);
                        } else {
                            system.debug('User does not have permission to insert one or more fields.');
                        }
                }
            }
        }
        
        if (!stepsToInsert.isEmpty()) {
            system.debug('Inserting steps: ' + stepsToInsert);
            insert as User stepsToInsert;
        }
        
        system.debug('defaultSteps=' + defaultSteps);
        return defaultSteps;
    }
    public static String sanitizeInput(String input) {
        if (String.isBlank(input)) {
            return input;
        }
        
        // Escape special HTML characters
        String sanitized = input;
        sanitized = sanitized.replace('&', '&amp;');
        sanitized = sanitized.replace('<', '&lt;');
        sanitized = sanitized.replace('>', '&gt;');
        sanitized = sanitized.replace('"', '&quot;');
        
        
        // Remove potential script injections (e.g., <script> tags)
        sanitized = sanitized.replaceAll('(?i)<script.*?>.*?</script>', ''); // Case-insensitive regex
        sanitized = sanitized.replaceAll('(?i)<.*?javascript:.*?>', ''); // Remove inline JS
        sanitized = sanitized.replaceAll('(?i)<.*?on\\w+=.*?>', ''); // Remove event handler attributes (e.g., onclick)
        
        // Return sanitized string
        return sanitized;
    }
    
    
    @AuraEnabled
    public static List<Audit_Step__c> getExistingRecords(String templateValue) { 
        system.debug('templateValue=' + templateValue);
        
        // Query existing records
        List<Audit_Step__c> existingRecords = [
            SELECT Name, SA_Audit__OrderIndex__c, SA_Audit__Template__c,SA_Audit__DueDate__c , SA_Audit__ReviewDatee__c, SA_Audit__Comments__c,SA_Audit__OwnerAssined__c
            FROM SA_Audit__Audit_Step__c
            WHERE SA_Audit__Template__c = :templateValue
            ORDER BY SA_Audit__OrderIndex__c
        ];
        
        // Check if the result set is empty
        if (existingRecords.isEmpty()) {
            System.debug('No existing records found.');
        }
        
        return existingRecords;
    } 
    
    @AuraEnabled
    public static List<SA_Audit__AuditSelectionData__c> getReviewSelectionRecords() {
        List<SA_Audit__AuditSelectionData__c> picklistData = [SELECT Id, SA_Audit__PicklistSelection__c, SA_Audit__Selection_value__c FROM SA_Audit__AuditSelectionData__c  WHERE ID != NULL];
        system.debug('picklistData='+picklistData);
        return picklistData;
    } 
    //for dates
    @AuraEnabled
    public static Date getExistingDatesFromServer(String recordName) {
        system.debug('recordName=='+recordName);
        SA_Audit__AuditDateInfo__c dateData = [SELECT Id, SA_Audit__DateSelectionName__c, SA_Audit__Date_Selection_value__c FROM SA_Audit__AuditDateInfo__c WHERE SA_Audit__DateSelectionName__c = :recordName limit 1];
        
        return dateData != null ? dateData.SA_Audit__Date_Selection_value__c : null;
        //return dateData
    } 
    @AuraEnabled
    public static void saveAuditSteps(List<SA_Audit__Audit_Step__c> auditSteps) {
        system.debug('auditSteps='+auditSteps);
        try {
            
            List<SA_Audit__Audit_Step__c> newSteps = new List<SA_Audit__Audit_Step__c>();
            List<SA_Audit__Audit_Step__c> existingSteps = new List<SA_Audit__Audit_Step__c>();
            
            for (SA_Audit__Audit_Step__c step : auditSteps) {
                if (step.Id == null) {
                    newSteps.add(step);
                } else {
                    existingSteps.add(step);
                }
            } 
            insert as User newSteps;
            update as User existingSteps; 
        } catch (Exception e) {    
            System.debug('An error occurred while saving audit steps: ' + e.getMessage());
        }
    }
    
    /* @AuraEnabled
public static void renameRecords(List<Map<String, Object>> renameAuditItemsd) {
System.debug('renameAuditItemsd= ' + renameAuditItemsd);

Map<Id, SA_Audit__Audit_Step__c> recordsToUpdateMap = new Map<Id, SA_Audit__Audit_Step__c>();

for (Map<String, Object> renameAuditItem : renameAuditItemsd) {
String stepInputParam = (String) renameAuditItem.get('name');  
System.debug('renameAuditItem==' + renameAuditItem);
Decimal orderIndex = (decimal) renameAuditItem.get('orderIndex'); 
String Newtemplate = (String) renameAuditItem.get('Newtemplate'); 
System.debug('Newtemplate==' + Newtemplate);

if (stepInputParam != null) {
// Query records based on OrderIndex__c
List<SA_Audit__Audit_Step__c> existingNameRecords = [
SELECT Id, Name, SA_Audit__OrderVal__c, SA_Audit__ReviewDatee__c, SA_Audit__Comments__c
FROM SA_Audit__Audit_Step__c
WHERE SA_Audit__OrderIndex__c = :orderIndex AND SA_Audit__Template__c =: Newtemplate
LIMIT 1
];

if (!existingNameRecords.isEmpty()) {
if (Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Name.isCreateable() && 
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Name.isUpdateable()) {
SA_Audit__Audit_Step__c recordToUpdate = existingNameRecords[0];
recordToUpdate.Name = stepInputParam;

// Add to map using the record ID to avoid duplicates
recordsToUpdateMap.put(recordToUpdate.Id, recordToUpdate);
}
}
}
}

if (!recordsToUpdateMap.isEmpty()) {
System.debug('recordsToUpdate=' + recordsToUpdateMap.values());
update recordsToUpdateMap.values();
}
}*/
    @AuraEnabled
    public static void renameRecords(List<Map<String, Object>> renameAuditItemsd) {
        System.debug('renameAuditItemsd= ' + renameAuditItemsd);
        
        Map<Id, SA_Audit__Audit_Step__c> recordsToUpdateMap = new Map<Id, SA_Audit__Audit_Step__c>();
        if (Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Id.isAccessible()&&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Id.isCreateable() && 
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Id.isUpdateable() && 
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Name.isAccessible()&&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Name.isCreateable() && 
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Name.isUpdateable() &&  
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderVal__c.isUpdateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isUpdateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isUpdateable() &&
            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Template__c.isUpdateable()) {
                for (Map<String, Object> renameAuditItem : renameAuditItemsd) {
                    String stepInputParam = (String) renameAuditItem.get('name');  
                    System.debug('renameAuditItem==' + renameAuditItem);
                    Decimal orderIndex = (Decimal) renameAuditItem.get('orderIndex'); 
                    String Newtemplate = (String) renameAuditItem.get('Newtemplate'); 
                    System.debug('Newtemplate==' + Newtemplate);
                    
                    
                    // Query records based on OrderIndex__c
                    List<SA_Audit__Audit_Step__c> existingNameRecords = [
                        SELECT Id, Name, SA_Audit__OrderVal__c,SA_Audit__DueDate__c , SA_Audit__ReviewDatee__c, SA_Audit__Comments__c
                        FROM SA_Audit__Audit_Step__c
                        WHERE SA_Audit__OrderIndex__c = :orderIndex AND SA_Audit__Template__c = :Newtemplate
                        LIMIT 1
                    ];  
                    //}
                }}
        
        if (!recordsToUpdateMap.isEmpty()) {
            System.debug('recordsToUpdate=' + recordsToUpdateMap.values());
            //  update recordsToUpdateMap.values();
        }
    }
    
    
    
    
    public class renameAuditItems {
        @AuraEnabled
        public String name;
        
        @AuraEnabled
        public String Newtemplate;
        
        @AuraEnabled
        public Decimal orderIndex;
        
    }
    
    //og default methods to save
    @AuraEnabled
    public static void createAuditRecords(List<Map<String, Object>> auditItemsd) {
        System.debug('auditItemsd=' + auditItemsd);
        List<SA_Audit__Audit_Step__c> recordsToUpdate = new List<SA_Audit__Audit_Step__c>();
        List<SA_Audit__Audit_Step__c> recordsToInsert = new List<SA_Audit__Audit_Step__c>();
        
        for (Map<String, Object> auditItem : auditItemsd) {
            
            String name = (String) auditItem.get('name');
            System.debug('name1=' + name);
            
            System.debug('name=' + name);
            
            String templateParam = (String) auditItem.get('template');
            System.debug('templateParam=' + templateParam);
            
            // String OrderVal = (String) auditItem.get('orderIndex');
            // System.debug('name=' + name);
            
            String datee = (String) auditItem.get('datee');
            System.debug('datee=' + datee);
            String comment = (String) auditItem.get('comment');
            String duedate = (String) auditItem.get('duedate');
            
            if (datee != null || comment != null || duedate != NULL) {
                // Check if a record with the same name already exists
                List<SA_Audit__Audit_Step__c> existingRecords = [SELECT Id,Name,SA_Audit__OrderVal__c, SA_Audit__ReviewDatee__c,SA_Audit__DueDate__c , SA_Audit__Comments__c FROM SA_Audit__Audit_Step__c WHERE Name = :name LIMIT 20000];
                List<SA_Audit__Audit_Step__c> existingRecords2 = [SELECT Id, Name , SA_Audit__Template__c FROM SA_Audit__Audit_Step__c WHERE SA_Audit__Template__c = : templateParam  LIMIT 20000];
                
                Decimal nextOrderInd = 1;
                if (!existingRecords2.isEmpty()) {
                    nextOrderInd = existingRecords2.size() + 1;
                    System.debug('nextOrderInd' + nextOrderInd);
                } 
                
                if (!existingRecords.isEmpty()) {
                    // If an existing record is found, update the date and comment values
                    for (SA_Audit__Audit_Step__c record : existingRecords) {
                        if ( 
                            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isCreateable() &&
                            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isCreateable() &&   
                            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isUpdateable() &&
                            Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isUpdateable() 
                        ) {
                            //    string SanitizedDate = datee.escapeHtml4();
                            record.SA_Audit__ReviewDatee__c = datee;
                            record.SA_Audit__Comments__c = comment; 
                            record.SA_Audit__DueDate__c = duedate;
                            recordsToUpdate.add(record);
                        }
                    }
                } else {
                    // If no existing record is found, create a new record
                    if (
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Name.isCreateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isCreateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isCreateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isCreateable()
                    ) {
                        SA_Audit__Audit_Step__c newRecord = new SA_Audit__Audit_Step__c();
                        string SanitizedName = name.escapeHtml4();
                        newRecord.Name = SanitizedName;
                        //string SanitizedDatee = datee.escapeHtml4();
                        newRecord.SA_Audit__ReviewDatee__c = datee;
                        newRecord.SA_Audit__Comments__c = comment;
                        newRecord.SA_Audit__DueDate__c = duedate;
                        newRecord.SA_Audit__OrderIndex__c = nextOrderInd;
                        recordsToInsert.add(newRecord);
                    }
                }
            }
            
        }
        
        if (!recordsToUpdate.isEmpty()) {
            System.debug('recordsToUpdate=' + recordsToUpdate);
            update as User recordsToUpdate;
        }
        
        if (!recordsToInsert.isEmpty()) {
            System.debug('recordsToInsert=' + recordsToInsert);
            insert as User recordsToInsert;
        }
    }
    
    public class AuditItem {
        //@AuraEnabled
        //public String stepOrder;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public string datee;
        @AuraEnabled
        public String comment;
    } 
    
    
    @AuraEnabled
    public static void addNewProcess(String inputParam,String OrderIndParam, Date reviewDateParam, String commentsParam ,String templateParam) {
        System.debug('inputParam>>' + inputParam + '=review=' + reviewDateParam + '=comm=' + commentsParam + '==templateParam='+templateParam);
        
        if (inputParam != null ) {
            // Check if a record with the same name already exists
            List<SA_Audit__Audit_Step__c> existingRecords = [SELECT Id,SA_Audit__Template__c, Name,SA_Audit__OrderIndex__c, SA_Audit__ReviewDatee__c, SA_Audit__Comments__c FROM SA_Audit__Audit_Step__c WHERE Name = :inputParam];
            List<SA_Audit__Audit_Step__c> existingRecords2 = [SELECT Id, Name , SA_Audit__Template__c FROM SA_Audit__Audit_Step__c WHERE SA_Audit__Template__c = : templateParam];
            
            Decimal nextOrderInd = 1;
            if (!existingRecords2.isEmpty()) {
                nextOrderInd = existingRecords2.size() + 1;
                System.debug('existingRecords' + existingRecords2);
            }
            
            if (!existingRecords.isEmpty()) {
                system.debug('in if');
                // If an existing record is found, update the date and comment values
                for (SA_Audit__Audit_Step__c record : existingRecords) {
                    
                    if (Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isCreateable() && 
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isUpdateable() &&
                        
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isCreateable() && 
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isUpdateable() &&
                        
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isCreateable() && 
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isUpdateable() &&
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Template__c.isCreateable() && 
                        Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Template__c.isUpdateable() 
                       ) {
                           
                           record.SA_Audit__OrderIndex__c = nextOrderInd + 1 ;
                           record.SA_Audit__ReviewDatee__c = string.valueof(reviewDateParam);
                           record.SA_Audit__Comments__c = commentsParam;
                           record.SA_Audit__Template__c = templateParam;
                       }}
                update as User existingRecords;
            } else {
                system.debug('in else');
                // If no existing record is found, create a new record
                SA_Audit__Audit_Step__c newRecord = new SA_Audit__Audit_Step__c();
                //newRecord.OrderVal__c = string.valueof(integer.valueof(OrderIndParam));
                if (Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Name.isCreateable() && 
                    Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Name.isUpdateable() &&
                    Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isCreateable() && 
                    Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isUpdateable() &&
                    
                    Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isCreateable() && 
                    Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isUpdateable() &&
                    
                    Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isCreateable() && 
                    Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isUpdateable() &&
                    Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Template__c.isCreateable() && 
                    Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Template__c.isUpdateable() 
                   ) {
                       newRecord.SA_Audit__OrderIndex__c = nextOrderInd + 1;
                       newRecord.Name = inputParam;
                       newRecord.SA_Audit__ReviewDatee__c = string.valueof(reviewDateParam);
                       newRecord.SA_Audit__Comments__c = commentsParam;
                       newRecord.SA_Audit__Template__c = templateParam;
                       system.debug('newRecord'+newRecord);
                       
                       insert as User newRecord;
                   }
            }
        }
    }
    
    
    @AuraEnabled 
    public static List<String> getUniqueTemplateNames() {
        // Query unique template names from Audit_Step__c
        List<String> templateNames = new List<String>();
        
        for (AggregateResult result : [SELECT SA_Audit__Template__c FROM SA_Audit__Audit_Step__c GROUP BY SA_Audit__Template__c LIMIT 2000]) {
            String templateName = (String) result.get('SA_Audit__Template__c');
            
            if (templateName != null) {
                templateNames.add(templateName);
            }
        }
        
        System.debug('Template Names: ' + templateNames);
        return templateNames;
    }
    
     @AuraEnabled
public static void addNewProcesstemp(String inputParam, Date reviewDateParam, String commentsParam , String templateParam) {
System.debug('templateParam>>' + templateParam);

if (templateParam != null || (reviewDateParam != null || commentsParam != null)) {
List<SA_Audit__Audit_Step__c> existingRecords = [SELECT Id, Name, SA_Audit__Template__c,SA_Audit__OrderIndex__c, SA_Audit__ReviewDatee__c, SA_Audit__Comments__c FROM SA_Audit__Audit_Step__c WHERE Name = :inputParam];
List<SA_Audit__Audit_Step__c> existingRecords2 = [SELECT Id, Name, SA_Audit__Template__c, SA_Audit__OrderIndex__c, SA_Audit__ReviewDatee__c, SA_Audit__Comments__c FROM SA_Audit__Audit_Step__c Limit 45000 ];

Decimal nextOrderInd = 1;
if ( Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isCreateable() && 
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isUpdateable() &&

Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isCreateable() && 
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isUpdateable() && 
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isCreateable() && 
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isUpdateable()){
if (!existingRecords.isEmpty()) {
// If an existing record is found, update the date and comment values
System.debug('if');
for (SA_Audit__Audit_Step__c record : existingRecords) {
record.SA_Audit__OrderIndex__c = nextOrderInd;
record.SA_Audit__ReviewDatee__c = string.valueof(reviewDateParam);
record.SA_Audit__Comments__c = commentsParam;

}
update as User existingRecords;
} }else{
System.debug('else');

// Query existing records to determine the correct order index
List<SA_Audit__Audit_Step__c> existingRecords3 = [SELECT Id, Name, SA_Audit__OrderIndex__c, SA_Audit__ReviewDatee__c,SA_Audit__Comments__c FROM SA_Audit__Audit_Step__c  LIMIT 20000];

Decimal nextOrderIndex = 1;
if ( Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Name.isCreateable() && 
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.Name.isUpdateable() &&
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isCreateable() && 
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__OrderIndex__c.isUpdateable() &&

Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isCreateable() && 
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__ReviewDatee__c.isUpdateable() &&

Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isCreateable() && 
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Comments__c.isUpdateable() &&  
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Template__c.isCreateable() && 
Schema.sObjectType.SA_Audit__Audit_Step__c.fields.SA_Audit__Template__c.isUpdateable()){
// Create a new record
SA_Audit__Audit_Step__c newRecord = new SA_Audit__Audit_Step__c();
newRecord.SA_Audit__OrderIndex__c = nextOrderIndex; 
string sanitized = inputParam;
newRecord.Name = inputParam;
newRecord.SA_Audit__ReviewDatee__c = String.valueOf(reviewDateParam);
newRecord.SA_Audit__Comments__c = commentsParam;
newRecord.SA_Audit__Template__c = templateParam;

System.debug('newRecord' + newRecord);

insert as User  newRecord;
}
}
}
} 
 
    /*
     * deprecated
     * @AuraEnabled
    public static void addNewProcesstemp(String inputParam, Date reviewDateParam, String commentsParam , String templateParam) {
        System.debug('templateParam>>' + templateParam);
        
        if (templateParam != null || (reviewDateParam != null || commentsParam != null)) {
            List<SA_Audit__Audit_Step__c> existingRecords = [SELECT Id, Name, SA_Audit__Template__c,SA_Audit__OrderIndex__c, SA_Audit__ReviewDatee__c, SA_Audit__Comments__c FROM SA_Audit__Audit_Step__c WHERE Name = :inputParam];
            List<SA_Audit__Audit_Step__c> existingRecords2 = [SELECT Id, Name, SA_Audit__Template__c, SA_Audit__OrderIndex__c, SA_Audit__ReviewDatee__c, SA_Audit__Comments__c FROM SA_Audit__Audit_Step__c LIMIT 2000];
            
            Decimal nextOrderInd = 1;
            
            if (!existingRecords.isEmpty()) {
                // If an existing record is found, update the date and comment values
                System.debug('if');
                for (SA_Audit__Audit_Step__c record : existingRecords) {
                    record.SA_Audit__OrderIndex__c = nextOrderInd;
                    record.SA_Audit__ReviewDatee__c = string.valueof(reviewDateParam);
                    record.SA_Audit__Comments__c = commentsParam;
                }
                update as user existingRecords;
            } else{
                System.debug('else');
                
                // Query existing records to determine the correct order index
                List<SA_Audit__Audit_Step__c> existingRecords3 = [SELECT Id, Name, SA_Audit__OrderIndex__c, SA_Audit__ReviewDatee__c, SA_Audit__Comments__c FROM SA_Audit__Audit_Step__c LIMIT 2000];
                
                Decimal nextOrderIndex = 1;
                
                // Create a new record
                SA_Audit__Audit_Step__c newRecord = new SA_Audit__Audit_Step__c();
                newRecord.SA_Audit__OrderIndex__c = nextOrderIndex;
                System.debug('inn' + newRecord.SA_Audit__OrderIndex__c);
                newRecord.Name = inputParam;
                newRecord.SA_Audit__ReviewDatee__c = String.valueOf(reviewDateParam);
                newRecord.SA_Audit__Comments__c = commentsParam;
                newRecord.SA_Audit__Template__c = templateParam;
                System.debug('newRecord' + newRecord);
                
                insert as user newRecord;
            }
        }
    } */
    
    @AuraEnabled
    public static void deleteStepRecord(String stepToRemove) {
        system.debug('stepToRemove'+stepToRemove);
        try {
            // Query for the corresponding step record
            if (  Schema.sObjectType.SA_Audit__Audit_Step__c.isAccessible() && Schema.sObjectType.SA_Audit__Audit_Step__c.isDeletable()) {
                SA_Audit__Audit_Step__c stepToDelete = [SELECT Id FROM SA_Audit__Audit_Step__c WHERE Name = :stepToRemove LIMIT 1];
                
                // Delete the step record if found
                if (stepToDelete != null) {
                    if(Schema.sObjectType.SA_Audit__Audit_Step__c.isAccessible() &&  Schema.sObjectType.SA_Audit__Audit_Step__c.isDeletable() ){
                        if(SA_Audit__Audit_Step__c.sObjectType.getDescribe().isDeletable()){ delete stepToDelete; } 
                    }
                }
            }
        } catch (Exception e) {
            // Handle any exceptions
            System.debug('Error deleting step record: ' + e.getMessage());
        }
    }
    public static String escapeHtml(String input) {
        if (String.isEmpty(input)) {
            return input;
        }
        // Replace special characters with HTML-safe equivalents
        input = input.replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;');
        
        return input;
    }
    
    /*  @AuraEnabled
public static void DeleteTemplateApex(String templ) {
system.debug('templ-'+templ);
try {
// Query for the corresponding step records
List<SA_Audit__Audit_Step__c> stepsToDelete = [
SELECT Id, SA_Audit__Template__c
FROM SA_Audit__Audit_Step__c
WHERE SA_Audit__Template__c = :templ limit 999
];

// Check if there are any steps to delete
if (!stepsToDelete.isEmpty()) {
// Delete the step records if found
delete stepsToDelete;
}
} catch (Exception e) {
// Handle any exceptions
System.debug('Error deleting step record: ' + e.getMessage());
}
}*/
    @AuraEnabled 
    public static void DeleteTemplateApex(String templ) { 
        System.debug('templ-' + templ); 
        
        try { 
            // Check if the user has delete access on the SA_Audit__Audit_Step__c object 
            if (SA_Audit__Audit_Step__c.sObjectType.getDescribe().isDeletable() ) {  
                
                // Field-Level Security check for SA_Audit__Template__c field
                Schema.DescribeFieldResult templateFieldDescribe = SA_Audit__Audit_Step__c.SA_Audit__Template__c.getDescribe();
                if (!templateFieldDescribe.isAccessible()) {
                    System.debug('User does not have access to the field SA_Audit__Template__c.');
                    return;
                }
                
                // Query for the corresponding step records 
                List<SA_Audit__Audit_Step__c> stepsToDelete = [ 
                    SELECT Id, SA_Audit__Template__c 
                    FROM SA_Audit__Audit_Step__c 
                    WHERE SA_Audit__Template__c = :templ 
                    LIMIT 999  
                ]; 
                
                // Check if there are any steps to delete 
                if (!stepsToDelete.isEmpty()) { 
                    if(SA_Audit__Audit_Step__c.sObjectType.getDescribe().isDeletable()){
                        // Delete the step records if found 
                        delete stepsToDelete; 
                        System.debug('Steps deleted successfully.'); 
                    }} else { 
                        System.debug('No steps found to delete.'); 
                    } 
                
            } else { 
                System.debug('User does not have delete access for SA_Audit__Audit_Step__c object.'); 
            } 
        } catch (Exception e) { 
            // Handle any exceptions 
            System.debug('Error deleting step record: ' + e.getTypeName() + ' - ' + e.getMessage()); 
        } 
    } 
    
    
    
    // Its used to genarate the export to excel for step section(I)
    @AuraEnabled
    public static List<Map<String, Object>> getAuditReports() {
        List<Map<String, Object>> reportRecordsList = new List<Map<String, Object>>();
        List<SA_Audit__Audit_Step__c> dataList = [SELECT Id, Name, SA_Audit__Template__c,SA_Audit__ReviewDatee__c, SA_Audit__Comments__c, SA_Audit__OwnerAssined__c FROM SA_Audit__Audit_Step__c WHERE ID != NULL];
        
        for (SA_Audit__Audit_Step__c reportOnRecord : dataList) {
            try {
                Map<String, Object> reportOneRecord = new Map<String, Object>();
                reportOneRecord.put('Id', reportOnRecord.Id);
                reportOneRecord.put('Name', reportOnRecord.Name );
                reportOneRecord.put('Comments__c', reportOnRecord.SA_Audit__Comments__c);
                reportOneRecord.put('ReviewDatee__c', reportOnRecord.SA_Audit__ReviewDatee__c);
                reportOneRecord.put('SA_Audit__Template__c', reportOnRecord.SA_Audit__Template__c);
                reportOneRecord.put('OwnerAssined__c', reportOnRecord.SA_Audit__OwnerAssined__c);
                reportRecordsList.add(reportOneRecord);
                
            } catch (Exception ex) {
                System.debug('The following exception has occurred in auditapp: ' + ex.getMessage());
            }
        }
        system.debug('reportRecordsList+'+reportRecordsList);
        return reportRecordsList;
    } 
    
    @AuraEnabled
    public static void sendNotification(String userIndex, String retrievedRecordId) {
        // Step 1: Debugging - Check the input parameters
        System.debug('Sending notification to user with ID: ' + retrievedRecordId);
        System.debug('Step Index: ' + userIndex);
        
        // Step 2: Query the user details using the retrievedRecordId (User ID)
        User targetUser = [SELECT Id, Email, Name FROM User WHERE Id = :retrievedRecordId LIMIT 1];
        
        // Step 3: Check if the user has a valid email
        if (targetUser.Email != null) {
            // Step 4: Create an email to inform the user that the step is assigned
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            // Set email parameters
            email.setToAddresses(new String[] {targetUser.Email});
            email.setSubject('Step Assigned to You');
            //email.setPlainTextBody('Dear ' + targetUser.Name + ',\n\nA new step has been assigned to you. Please check your tasks and complete it accordingly.\n\nThank you.');
            email.setPlainTextBody('Dear ' + targetUser.Name + ',\n\n' +
                                   'We wanted to inform you that a new Step has been assigned to you as part of Audit App.\n\n' +
                                   'To review the details of this Step, Your attention to this step is crucial, Navigate to the Audit App.\n\n' +
                                   'Thank you for your effort.!\n\n' +
                                   'Best regards,\n' +
                                   'The Application perfection Team');
            // Step 5: Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            
            System.debug('Email sent successfully to ' + targetUser.Email);
        } else {
            System.debug('No valid email address found for the user with ID: ' + retrievedRecordId);
        }
    }
    
    
    //                                     method to handle section two
    //----------------------------------------------------------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------
    
    /*this method is to mail the reports on click*/
    @AuraEnabled
    public static void batchApexExecutionToSendAnEmail(List<String> listOfIDs, List<string> selectedOption){
        system.debug('selectedOption1 ='+selectedOption);
        Database.executeBatch(new GenerateAllReports(listOfIDs,selectedOption), 200);
        system.debug('selectedOption2='+selectedOption);
    }
    
    //getPermissionReviewData will return the count for the audit section2:column3
   /* @AuraEnabled
    public static List<PermissionReviewItem> getPermissionReviewData() { 
        
        SchedulebAuditBatchClass batch = new SchedulebAuditBatchClass();
        Database.executeBatch(batch); 
        List<PermissionReviewItem> permissionReviewData = new List<PermissionReviewItem>();
        //Integer totalProfiles = [SELECT COUNT() FROM Profile  WHERE ID != NULL];
        Integer totalProfiles = [SELECT COUNT() FROM PermissionSet Where Iscustom=true AND ProfileId != null ];
        Integer totalPermissionSets = [SELECT COUNT() FROM PermissionSet WHERE IsCustom = true AND ( NOT Name LIKE 'X00%' )];
        Integer totalPermissionSetGroups = [SELECT COUNT() FROM PermissionSetGroup  WHERE ID != NULL]; 
        Integer unusedPermissionSetsCanDelete = [SELECT COUNT() FROM PermissionSet WHERE  IsCustom = true AND Id NOT IN (SELECT PermissionSetId FROM PermissionSetAssignment) AND (NOT Name LIKE 'X00%')];
        Integer unusedPermissionSetGroupsCanDelete = [SELECT COUNT() FROM PermissionSetGroup WHERE Id NOT IN (SELECT PermissionSetGroupId FROM PermissionSetAssignment)];
        // Integer unusedProfilesCanDelete = [SELECT COUNT() from profile where id not in (select profileid from user)];
        Integer unusedProfilesCanDelete = [SELECT COUNT() FROM PermissionSet Where Iscustom=true AND ProfileId != null AND ProfileId not in (select profileid from user)];
        
        // Fetch all GroupMember records first to build the set of usedGroupIds
        Set<Id> usedGroupIds = new Set<Id>();
        //35200 data in dev1
        for (GroupMember groupMember : [SELECT GroupId FROM GroupMember WHERE GroupId != NULL Limit 37000]) {
            usedGroupIds.add(groupMember.GroupId);
        }
        
        // Query for the count of unused public groups in a single query
        Integer unusedPublicGroupCount = [SELECT COUNT() FROM Group WHERE Type = 'Regular' AND Id NOT IN :usedGroupIds];
        
        // Fetch all User and UserRole records to build sets of usedRoleIds and parentRoleIds
        Set<Id> usedRoleIds = new Set<Id>();
        Set<Id> parentRoleIds = new Set<Id>();
        for (User user : [SELECT UserRoleId FROM User WHERE UserRoleId != NULL Limit 10000]) {
            usedRoleIds.add(user.UserRoleId);
        }
        for (UserRole userRole : [SELECT ParentRoleId FROM UserRole WHERE ParentRoleId != NULL]) {
            parentRoleIds.add(userRole.ParentRoleId);
        }
        
        // Query for the count of unused roles
        Integer unusedRoleCount = [SELECT COUNT() FROM UserRole WHERE Id NOT IN :usedRoleIds];
        
        // Query for the total count of roles
        Integer totalRolesCount = [SELECT COUNT() FROM UserRole WHERE Id != NULL];
        
        // Query for the counts of unused internal and external roles
        Integer unusedInternalRoleCount = 0;
        Integer unusedExternalRoleCount = 0; 
        for (UserRole userRole : [SELECT Id, PortalType FROM UserRole WHERE Id != NULL]) {
            if (!usedRoleIds.contains(userRole.Id)) {
                if (userRole.PortalType == null || userRole.PortalType == 'None') {
                    unusedInternalRoleCount++;
                } else {
                    unusedExternalRoleCount++;
                }
            }
        }
        //till here
        // Integer totalTerritoriesCount = [SELECT COUNT() FROM Territory2];
        Integer totalpublicGroupCount = [SELECT COUNT() FROM Group WHERE Type = 'Regular' AND DeveloperName != 'AllInternalUsers'];
        Integer totalinternalRoleCount = [SELECT COUNT() FROM UserRole WHERE PortalType = 'None'];
        Integer totalexternalRoleCount = [SELECT COUNT() FROM UserRole WHERE PortalType != 'None']; 
        PermissionReviewItem profilesItem = new PermissionReviewItem(); 
        profilesItem.index = 1;
        profilesItem.type = 'Profile';
        profilesItem.Profilecount = totalProfiles;
        profilesItem.Permissioncount = totalPermissionSets;
        profilesItem.PermissionGroupcount = totalPermissionSetGroups;
        profilesItem.Rolescount = totalRolescount;
        // profilesItem.Territoriescount =  totalTerritoriesCount;
        profilesItem.PublicGroupcount =  totalpublicGroupCount;
        profilesItem.InternalRolescount =  totalinternalRoleCount;
        profilesItem.ExternalRolescount =  totalexternalRoleCount;
        profilesItem.unusedRolesCanDelete =  unusedRoleCount;
        system.debug('profilesItem.unusedRolesCanDelete'+profilesItem.unusedRolesCanDelete);
        //profilesItem.unusedTerritoriesCanDelete =  unusedTerritoryCount; 
        profilesItem.unusedPublicGroupCanDelete =  unusedPublicGroupCount;
        profilesItem.unusedInternalRolesCanDelete =  unusedInternalRoleCount;
        system.debug('profilesItem.unusedInternalRolesCanDelete'+profilesItem.unusedInternalRolesCanDelete);
        profilesItem.unusedExternalRolesCanDelete =  unusedExternalRoleCount;
        system.debug('profilesItem.unusedExternalRoleCount'+profilesItem.unusedExternalRolesCanDelete);
        profilesItem.unusedProfilesCount = unusedProfilesCanDelete;  
        profilesItem.unusedPermissionCount = unusedPermissionSetsCanDelete;
        profilesItem.unusedPermissionGroupCount = string.valueof(unusedPermissionSetGroupsCanDelete);
        //percentage counts 
        // Calculate and assign percentage counts
        Decimal ProfilePrValue = (totalProfiles != 0) ? Math.floor((Decimal.valueOf(unusedProfilesCanDelete) / Decimal.valueOf(totalProfiles) * 100)) : 0;
        profilesItem.percentageUnusedProfiles = ProfilePrValue + '%';
        
        Decimal PermissionPrValue = (totalPermissionSets != 0) ? Math.floor((Decimal.valueOf(unusedPermissionSetsCanDelete) / Decimal.valueOf(totalPermissionSets) * 100)) : 0;
        profilesItem.percentageUnusedPermissions = PermissionPrValue + '%';
        
        Decimal percentPsetGroupValue = (totalPermissionSetGroups != 0) ? Math.floor((Decimal.valueOf(unusedPermissionSetGroupsCanDelete) / Decimal.valueOf(totalPermissionSetGroups) * 100)) : 0;
        profilesItem.percentageUnusedPsetGroup = percentPsetGroupValue + '%';
        
        Decimal RolesPrValue = (totalRolescount != 0) ? Math.floor((Decimal.valueOf(unusedRoleCount) / Decimal.valueOf(totalRolescount) * 100)) : 0;
        profilesItem.percentageUnusedRoles = RolesPrValue + '%';
        
        Decimal PublicGroupPrValue = (totalpublicGroupCount != 0) ? Math.floor((Decimal.valueOf(unusedPublicGroupCount) / Decimal.valueOf(totalpublicGroupCount) * 100)) : 0;
        profilesItem.percentageUnusedPublicGroup = PublicGroupPrValue + '%';
        
        Decimal InternalRolesPrValue = (totalinternalRoleCount != 0) ? Math.floor((Decimal.valueOf(unusedInternalRoleCount) / Decimal.valueOf(totalinternalRoleCount) * 100)) : 0;
        profilesItem.percentageUnusedInternalRoles = InternalRolesPrValue + '%';
        
        Decimal ExternalRolesPrValue = (totalexternalRoleCount != 0) ? Math.floor((Decimal.valueOf(unusedExternalRoleCount) / Decimal.valueOf(totalexternalRoleCount) * 100)) : 0;
        profilesItem.percentageUnusedExternalRoles = ExternalRolesPrValue + '%';
        
        // Calculate and assign OrgHealthCount
        Decimal orghealth = (ProfilePrValue + PermissionPrValue + percentPsetGroupValue + RolesPrValue + PublicGroupPrValue + InternalRolesPrValue + ExternalRolesPrValue) / 7;
        profilesItem.OrgHealthCount = orghealth; 
        permissionReviewData.add(profilesItem);
        
        
        system.debug('proReviewData=='+permissionReviewData);  
        return permissionReviewData;
    }*/

    
     @AuraEnabled
    public static List<PermissionReviewItem> getPermissionReviewData() { 
               
       
        List<PermissionReviewItem> permissionReviewData = new List<PermissionReviewItem>();
        
        // Use direct COUNT queries for simple counts
        Integer totalProfiles = [SELECT COUNT() FROM PermissionSet WHERE Iscustom=true AND ProfileId != null];
        Integer totalPermissionSets = [SELECT COUNT() FROM PermissionSet WHERE IsCustom = true AND (NOT Name LIKE 'X00%')];
        Integer totalPermissionSetGroups = [SELECT COUNT() FROM PermissionSetGroup WHERE ID != NULL];
        
        // Use subqueries for unused counts
        Integer unusedPermissionSetsCanDelete = [SELECT COUNT() 
                                               FROM PermissionSet 
                                               WHERE IsCustom = true 
                                               AND Id NOT IN (SELECT PermissionSetId FROM PermissionSetAssignment) 
                                               AND (NOT Name LIKE 'X00%')];
        
        Integer unusedPermissionSetGroupsCanDelete = [SELECT COUNT() 
                                                    FROM PermissionSetGroup 
                                                    WHERE Id NOT IN (SELECT PermissionSetGroupId FROM PermissionSetAssignment)];
        
        Integer unusedProfilesCanDelete = [SELECT COUNT() 
                                         FROM PermissionSet 
                                         WHERE Iscustom=true 
                                         AND ProfileId != null 
                                         AND ProfileId NOT IN (SELECT ProfileId FROM User)];
        
        // Use direct COUNT queries instead of processing all records
        Integer totalGroupMembers = [SELECT COUNT() FROM GroupMember WHERE GroupId != NULL];
        Integer totalUsers = [SELECT COUNT() FROM User WHERE UserRoleId != NULL];
        Integer totalUserRoles = [SELECT COUNT() FROM UserRole WHERE ParentRoleId != NULL];
        
        // Use subqueries to get counts directly
        Integer unusedPublicGroupCount = [SELECT COUNT() 
                                        FROM Group 
                                        WHERE Type = 'Regular' 
                                        AND Id NOT IN (SELECT GroupId FROM GroupMember)];
        
        Integer unusedRoleCount = [SELECT COUNT() 
                                 FROM UserRole 
                                 WHERE Id NOT IN (SELECT UserRoleId FROM User)];
        
        Integer totalRolesCount = [SELECT COUNT() FROM UserRole WHERE Id != NULL];
        
        // Calculate internal and external role counts using direct queries
        Integer unusedInternalRoleCount = [SELECT COUNT() 
                                         FROM UserRole 
                                         WHERE Id NOT IN (SELECT UserRoleId FROM User)
                                         AND (PortalType = 'None' OR PortalType = null)];
        
        Integer unusedExternalRoleCount = [SELECT COUNT() 
                                         FROM UserRole 
                                         WHERE Id NOT IN (SELECT UserRoleId FROM User)
                                         AND PortalType != 'None'];
        
        Integer totalpublicGroupCount = [SELECT COUNT() 
                                       FROM Group 
                                       WHERE Type = 'Regular' 
                                       AND DeveloperName != 'AllInternalUsers'];
        Integer totalinternalRoleCount = [SELECT COUNT() 
                                        FROM UserRole 
                                        WHERE PortalType = 'None'];
        Integer totalexternalRoleCount = [SELECT COUNT() 
                                        FROM UserRole 
                                        WHERE PortalType != 'None'];
        
        // Create and populate the PermissionReviewItem
        PermissionReviewItem profilesItem = new PermissionReviewItem();
        profilesItem.index = 1;
        profilesItem.type = 'Profile';
        profilesItem.Profilecount = totalProfiles;
        profilesItem.Permissioncount = totalPermissionSets;
        profilesItem.PermissionGroupcount = totalPermissionSetGroups;
        profilesItem.Rolescount = totalRolesCount;
        profilesItem.PublicGroupcount = totalpublicGroupCount;
        profilesItem.InternalRolescount = totalinternalRoleCount;
        profilesItem.ExternalRolescount = totalexternalRoleCount;
        profilesItem.unusedRolesCanDelete = unusedRoleCount;
        profilesItem.unusedPublicGroupCanDelete = unusedPublicGroupCount;
        profilesItem.unusedInternalRolesCanDelete = unusedInternalRoleCount;
        profilesItem.unusedExternalRolesCanDelete = unusedExternalRoleCount;
        profilesItem.unusedProfilesCount = unusedProfilesCanDelete;
        profilesItem.unusedPermissionCount = unusedPermissionSetsCanDelete;
        profilesItem.unusedPermissionGroupCount = String.valueOf(unusedPermissionSetGroupsCanDelete);
        
        // Calculate percentages
        Decimal ProfilePrValue = (totalProfiles != 0) ? Math.floor((Decimal.valueOf(unusedProfilesCanDelete) / Decimal.valueOf(totalProfiles) * 100)) : 0;
        profilesItem.percentageUnusedProfiles = ProfilePrValue + '%';
        
        Decimal PermissionPrValue = (totalPermissionSets != 0) ? Math.floor((Decimal.valueOf(unusedPermissionSetsCanDelete) / Decimal.valueOf(totalPermissionSets) * 100)) : 0;
        profilesItem.percentageUnusedPermissions = PermissionPrValue + '%';
        
        Decimal percentPsetGroupValue = (totalPermissionSetGroups != 0) ? Math.floor((Decimal.valueOf(unusedPermissionSetGroupsCanDelete) / Decimal.valueOf(totalPermissionSetGroups) * 100)) : 0;
        profilesItem.percentageUnusedPsetGroup = percentPsetGroupValue + '%';
        
        Decimal RolesPrValue = (totalRolesCount != 0) ? Math.floor((Decimal.valueOf(unusedRoleCount) / Decimal.valueOf(totalRolesCount) * 100)) : 0;
        profilesItem.percentageUnusedRoles = RolesPrValue + '%';
        
        Decimal PublicGroupPrValue = (totalpublicGroupCount != 0) ? Math.floor((Decimal.valueOf(unusedPublicGroupCount) / Decimal.valueOf(totalpublicGroupCount) * 100)) : 0;
        profilesItem.percentageUnusedPublicGroup = PublicGroupPrValue + '%';
        
        Decimal InternalRolesPrValue = (totalinternalRoleCount != 0) ? Math.floor((Decimal.valueOf(unusedInternalRoleCount) / Decimal.valueOf(totalinternalRoleCount) * 100)) : 0;
        profilesItem.percentageUnusedInternalRoles = InternalRolesPrValue + '%';
        
        Decimal ExternalRolesPrValue = (totalexternalRoleCount != 0) ? Math.floor((Decimal.valueOf(unusedExternalRoleCount) / Decimal.valueOf(totalexternalRoleCount) * 100)) : 0;
        profilesItem.percentageUnusedExternalRoles = ExternalRolesPrValue + '%';
        
        // Calculate org health
        Decimal orghealth = (ProfilePrValue + PermissionPrValue + percentPsetGroupValue + RolesPrValue + PublicGroupPrValue + InternalRolesPrValue + ExternalRolesPrValue) / 7;
        profilesItem.OrgHealthCount = orghealth;
        
        permissionReviewData.add(profilesItem);
        system.debug('permissionReviewData--'+permissionReviewData);
        return permissionReviewData;
    }
    
    //Imp method load when we click on the objectPermission section two
    @AuraEnabled
    public static List<ObjPermissionItem> getObjPermReviewData() {
        // Strip to the essentials: compute the six counts exactly like ObjectDescriptions
        List<ObjPermissionItem> ObjPermissionData = new List<ObjPermissionItem>();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        List<String> customObjectNames = new List<String>();

        // 1) Build custom object list (exclude __mdt), same rule as ObjectDescriptions.getCustomObjects()
        for (String objectName : globalDescribe.keySet()) {
            Schema.DescribeSObjectResult d = globalDescribe.get(objectName).getDescribe();
            if (d.isCustom() && !objectName.endsWith('__mdt')) {
                customObjectNames.add(objectName);
            }
        }

        // Guard: if none, return zeros
        ObjPermissionItem ObjPermItem = new ObjPermissionItem();
        if (customObjectNames.isEmpty()) {
            ObjPermItem.TotalCustomObjects = 0;
            ObjPermItem.DescPopulatedObjects = 0;
            ObjPermItem.TotalManagedObjects = 0;
            ObjPermItem.ManagedObjDesc = 0;
            ObjPermItem.EditableObjectsCount = 0;
            ObjPermItem.BlankEditableDescCount = 0;
            ObjPermItem.UneditableBlankCount = 0;
            ObjPermissionData.add(ObjPermItem);
            return ObjPermissionData;
        }

        // 2) Count descriptions populated using EntityDefinition for ONLY custom objects
        // Use chunking to avoid URL length limits and aggregate results
        Set<String> describedCustomObjects = new Set<String>();
        List<String> literals = new List<String>();
        for (String n : customObjectNames) {
            literals.add('\'' + n + '\'');
        }
        Integer chunkSize = 100;
        for (Integer i = 0; i < literals.size(); i += chunkSize) {
            Integer endIdx = Math.min(i + chunkSize, literals.size());
            List<String> sub = new List<String>();
            for (Integer j = i; j < endIdx; j++) {
                sub.add(literals[j]);
            }
            String edQuery = 'SELECT QualifiedApiName, Description FROM EntityDefinition WHERE QualifiedApiName IN (' + String.join(sub, ',') + ')';
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v62.0/tooling/query/?q=' + EncodingUtil.urlEncode(edQuery, 'UTF-8'));
                req.setMethod('GET');
                req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
                req.setHeader('Content-Type', 'application/json');
                Http http = new Http();
                HttpResponse res = http.send(req);
                if (res.getStatusCode() == 200) {
                    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    List<Object> records = (List<Object>) result.get('records');
                    for (Object o : records) {
                        Map<String, Object> r = (Map<String, Object>) o;
                        String apiName = (String) r.get('QualifiedApiName');
                        String descr = (String) r.get('Description');
                        if (String.isNotBlank(descr)) {
                            describedCustomObjects.add(apiName);
                        }
                    }
                } else {
                    System.debug('EntityDefinition query HTTP error: ' + res.getStatusCode());
                }
            } catch (Exception e) {
                System.debug('EntityDefinition chunk query failed: ' + e.getMessage());
            }
        }

        // 3) Detect managed custom objects using EntityParticle (same approach as ObjectDescriptions.getManagedObjectCount)
        Set<String> managedCustomObjects = new Set<String>();
        try {
            List<EntityParticle> allFields = [
                SELECT FieldDefinition.NamespacePrefix, EntityDefinition.QualifiedApiName
                FROM EntityParticle
                WHERE EntityDefinition.QualifiedApiName IN :customObjectNames
            ];
            for (EntityParticle f : allFields) {
                if (String.isNotBlank(f.FieldDefinition.NamespacePrefix)) {
                    managedCustomObjects.add(f.EntityDefinition.QualifiedApiName);
                }
            }
        } catch (Exception e2) {
            System.debug('EntityParticle query failed: ' + e2.getMessage());
        }

        // 4) Compute final counts exactly like the dashboard
        Integer totalCustomObjects = customObjectNames.size();
        Integer descPopulatedObjects = describedCustomObjects.size();
        Integer totalManagedObjects = managedCustomObjects.size();
        Integer managedObjDesc = 0;
        for (String name : managedCustomObjects) {
            if (describedCustomObjects.contains(name)) managedObjDesc++;
        }
        Integer editableObjectsCount = Math.max(totalCustomObjects - totalManagedObjects, 0);
        Integer editableDescribed = Math.max(descPopulatedObjects - managedObjDesc, 0);
        Integer blankEditableDescCount = Math.max(editableObjectsCount - editableDescribed, 0);
        Integer uneditableBlankCount = Math.max(totalManagedObjects - managedObjDesc, 0);

        // 5) Assign to response DTO
        ObjPermItem.TotalCustomObjects = totalCustomObjects;
        ObjPermItem.DescPopulatedObjects = descPopulatedObjects;
        ObjPermItem.TotalManagedObjects = totalManagedObjects;
        ObjPermItem.ManagedObjDesc = managedObjDesc;
        ObjPermItem.EditableObjectsCount = editableObjectsCount;
        ObjPermItem.BlankEditableDescCount = blankEditableDescCount;
        ObjPermItem.UneditableBlankCount = uneditableBlankCount;

        ObjPermissionData.add(ObjPermItem);
        return ObjPermissionData;
    }
    
    @AuraEnabled
    public static List<ProPsetPermissionItem> getProPsetReviewData() {
        List<ProPsetPermissionItem> permissionData = new List<ProPsetPermissionItem>();
        
        // Variables to store counts
        Integer profileCount = 0;
        Integer profileDescriptionCount = 0;
        Integer permissionSetCount = 0;
        Integer permissionSetDescriptionCount = 0;
        Integer permissionSetGroupCount = 0;
        Integer permissionSetGroupDescriptionCount = 0;
        
        // Query Profiles
        List<Profile> profiles = [SELECT Id, Description FROM Profile LIMIT 30000];
        profileCount = profiles.size();
        for (Profile p : profiles) {
            if (String.isNotBlank(p.Description)) {
                profileDescriptionCount++;
            }
        }
        
        // Query only permission sets not owned by profiles
        List<PermissionSet> permissionSets = [SELECT Id, Description 
                                              FROM PermissionSet 
                                              WHERE IsOwnedByProfile = false];
        
        permissionSetCount = permissionSets.size(); // Update permission set count
        
        for (PermissionSet ps : permissionSets) {
            if (String.isNotBlank(ps.Description)) {
                permissionSetDescriptionCount++;
            }
        }
        
        
        // Query Permission Set Groups
        List<PermissionSetGroup> permissionSetGroups = [SELECT Id, Description FROM PermissionSetGroup LIMIT 30000];
        permissionSetGroupCount = permissionSetGroups.size();
        for (PermissionSetGroup psg : permissionSetGroups) {
            if (String.isNotBlank(psg.Description)) {
                permissionSetGroupDescriptionCount++;
            }
        }
        // Calculate Percentages
        Integer profilePercentage = Math.round((Decimal.valueOf(profileCount) / 1000) * 100);
        Integer profilePercentageDec = Math.round((Decimal.valueOf(profileDescriptionCount) / profileCount) * 100);
        Integer permissionSetPercentage = Math.round((Decimal.valueOf(permissionSetCount) / 1500) * 100);
        
        Integer permissionSetPercentageDec = Math.round((Decimal.valueOf(permissionSetDescriptionCount) / permissionSetCount) * 100);
        Integer psetGroupPercentage = Math.round((Decimal.valueOf(permissionSetGroupCount) / 1000) * 100);
        Integer psetGroupPercentageDec = Math.round((Decimal.valueOf(permissionSetGroupCount) / permissionSetGroupDescriptionCount) * 100);
        
        // Prepare data
        ProPsetPermissionItem data = new ProPsetPermissionItem();
        data.ProfileCount = profileCount;
        data.ProfileDescriptionCount = profileDescriptionCount;
        data.PermissionSetCount = permissionSetCount;
        data.PermissionSetDescriptionCount = permissionSetDescriptionCount;
        data.PermissionSetGroupCount = permissionSetGroupCount;
        data.PermissionSetGroupDescriptionCount = permissionSetGroupDescriptionCount;
        
        data.ProfilePercentage = profilePercentage;
        data.ProfilePercentageDec = profilePercentageDec;
        data.PermissionSetPercentage = permissionSetPercentage;
        data.PermissionSetPercentageDec = permissionSetPercentageDec;
        data.PsetGroupPercentage = psetGroupPercentage;
        data.PsetGroupPercentageDec = psetGroupPercentageDec;
        
        
        
        // Add to list
        permissionData.add(data);
        
        return permissionData;
    }
    
    
    
    //saveReviewSelectionRecord will return the picklist values Yes/No for the audit section2:column4
    @AuraEnabled
    public static void saveReviewSelectionRecord(String picklistName, String selectedValue) {
        // Check if a record with the given picklistName exists
        List<AuditSelectionData__c> existingRecords = [SELECT Id FROM AuditSelectionData__c WHERE PicklistSelection__c = :picklistName LIMIT 1];
        
        if (existingRecords.isEmpty()) {
            // No existing record, create a new one
            AuditSelectionData__c reviewSelection = new AuditSelectionData__c();
            // Check FLS for the Name field
            if (Schema.sObjectType.AuditSelectionData__c.fields.Name.isCreateable()) {
                reviewSelection.Name = picklistName;
            }
            // Check FLS for the PicklistSelection__c field
            if (Schema.sObjectType.AuditSelectionData__c.fields.PicklistSelection__c.isCreateable()) {
                reviewSelection.PicklistSelection__c = picklistName;
            }
            // Check FLS for the Selection_value__c field
            if (Schema.sObjectType.AuditSelectionData__c.fields.Selection_value__c.isCreateable()) {
                reviewSelection.Selection_value__c = selectedValue;
            } 
            try {
                insert as User reviewSelection;
            } catch (Exception e) {
                // Handle exception if needed
                System.debug('Error creating record: ' + e.getMessage());
            }
        } else {
            // Update existing record
            AuditSelectionData__c reviewSelection = existingRecords[0];
            // Check FLS for the Name field during update
            if (Schema.sObjectType.AuditSelectionData__c.fields.Name.isUpdateable()) {
                reviewSelection.Name = picklistName;
            }
            
            // Check FLS for the Selection_value__c field
            if (Schema.sObjectType.AuditSelectionData__c.fields.Selection_value__c.isUpdateable()) {
                reviewSelection.Selection_value__c = selectedValue;
            }
            
            try {
                update as User reviewSelection;
            } catch (Exception e) {
                // Handle exception if needed
                System.debug('Error updating record: ' + e.getMessage());
            }
        }
    }
    
    //saveReviewDateRecord will return the date  for the audit section2:column10
    @AuraEnabled
    public static void saveReviewDateRecord(String dateName, String selectedDate) {
        List<AuditDateInfo__c> existingRecords = [SELECT Id FROM AuditDateInfo__c WHERE DateSelectionName__c = :dateName LIMIT 1];
        
        if (existingRecords.isEmpty()) {
            AuditDateInfo__c reviewDate = new AuditDateInfo__c();
            
            // Check FLS for the Name field
            if (Schema.sObjectType.AuditDateInfo__c.fields.Name.isCreateable()) {
                reviewDate.Name = dateName;
            }
            
            // Check FLS for the DateSelectionName__c field
            if (Schema.sObjectType.AuditDateInfo__c.fields.DateSelectionName__c.isCreateable()) {
                reviewDate.DateSelectionName__c = dateName;
            }
            
            // Check FLS for the Date_Selection_value__c field
            if (Schema.sObjectType.AuditDateInfo__c.fields.Date_Selection_value__c.isCreateable()) {
                reviewDate.Date_Selection_value__c = Date.valueOf(selectedDate);
            }
            
            try {
                insert as User reviewDate;
            } catch (Exception e) {
                System.debug('Error creating record: ' + e.getMessage());
            }
        } else {
            AuditDateInfo__c reviewDate = existingRecords[0];
            
            // Check FLS for the Date_Selection_value__c field
            if (Schema.sObjectType.AuditDateInfo__c.fields.Date_Selection_value__c.isUpdateable()) {
                reviewDate.Date_Selection_value__c = Date.valueOf(selectedDate);
            }
            
            try {
                update as User reviewDate;
            } catch (Exception e) {
                System.debug('Error updating record: ' + e.getMessage());
            }
        }
    }
    
    /*@AuraEnabled(cacheable=true)
public static String getDashboardIdByName(String selectedOption) {
// Query for the Dashboard using its DeveloperName or Name
List<Dashboard> dashboards = [
SELECT Id, DeveloperName, FolderName
FROM Dashboard
WHERE DeveloperName = :selectedOption
OR Title = :selectedOption
LIMIT 1
];

// Check if a Dashboard was found and return its ID
if (!dashboards.isEmpty()) {
return dashboards[0].Id;
}
return null;
}*/
    @AuraEnabled(cacheable=true)
    public static String getDashboardIdByName(String selectedOption) {
        // Check for object-level access (CRUD) and field-level access (FLS)
        if (!Schema.sObjectType.Dashboard.isAccessible()) {
            throw new AuraHandledException('You do not have access to the Dashboard object.');
        }
        
        if (!Schema.sObjectType.Dashboard.fields.DeveloperName.isAccessible() || 
            !Schema.sObjectType.Dashboard.fields.FolderName.isAccessible() ||
            !Schema.sObjectType.Dashboard.fields.Title.isAccessible()) {
                throw new AuraHandledException('You do not have access to one or more required fields on the Dashboard object.');
            }
        
        // Query for the Dashboard using its DeveloperName or Title
        List<Dashboard> dashboards = [
            SELECT Id, DeveloperName, FolderName
            FROM Dashboard
            WHERE DeveloperName = :selectedOption
            OR Title = :selectedOption
            LIMIT 1
        ];
        
        // Check if a Dashboard was found and return its ID
        if (!dashboards.isEmpty()) {
            return  dashboards[0].Id;
        }
        return null;
    }
    
    
    /*   @AuraEnabled
public static void scheduleReview(String timeFrame) {
// Get the current user's email
User currentUser = [SELECT Email, Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
String toAddress = currentUser.Email;

// Get the email template ID
Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Scheduled_Permission_Review' LIMIT 1].Id;

// Send the email
Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
mail.setToAddresses(new List<String>{toAddress});
mail.setTemplateId(templateId);
mail.setTargetObjectId(currentUser.Id);
mail.setSaveAsActivity(false);

Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});

// Define cron expression based on time frame
String cronExpression;

switch on timeFrame {
when '1 Day' {
cronExpression = '0 0 0 * * ?'; // Daily at midnight
}
when '1 Week' {
cronExpression = '0 0 0 ? * 1'; // Weekly at midnight on Sunday
}
when '1 Month' {
cronExpression = '0 0 0 1 * ?'; // First day of every month at midnight
}
when '1 Quarter' {
cronExpression = '0 0 0 1 1,4,7,10 ?'; // First day of each quarter
}
when '1 Year' {
cronExpression = '0 0 0 1 1 ?'; // First day of the year at midnight
}
when else {
throw new IllegalArgumentException('Invalid time frame selected');
}
}

// Schedule the job
System.schedule('Review Check: ' + timeFrame, cronExpression, new ReviewEmailScheduler());
}*/
    @AuraEnabled
    public static String scheduleReview(String timeFrame) {
        System.debug('TimeFrame received: ' + timeFrame); // Debugging incoming timeFrame
        
        // Get the current user's email
        User currentUser = [SELECT Email, Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String toAddress = currentUser.Email;
        
        // Get the email template ID (ensure the template exists in your org)
        Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Scheduled_Permission_Review' LIMIT 1].Id;
        
        // Define cron expression and notification date based on time frame
        String cronExpression;
        String notificationDate = '';
        Date nextNotificationDate;
        
        // Get today's date
        Date today = Date.today();
        
        // Define cron expression and calculate notification date based on time frame
        switch on timeFrame {
            when 'Daily' {
                cronExpression = '0 0 0 * * ?'; // Daily at midnight
                nextNotificationDate = today.addDays(1); // Tomorrow
                notificationDate = nextNotificationDate.format();
            }
            when 'Weekly' {
                cronExpression = '0 0 0 ? * 1'; // Weekly at midnight on Sunday
                
                // Find the next Sunday from today's date using DateTime to get the day of the week
                DateTime todayDateTime = DateTime.newInstance(today, Time.newInstance(0, 0, 0, 0)); // Convert Date to DateTime
                Integer dayOfWeek = Integer.valueOf(todayDateTime.format('u')); // Get day of the week (1=Monday, 7=Sunday)
                
                // Calculate how many days to add to reach the next Sunday
                Integer daysToAdd = (7 - dayOfWeek);  // If today is Sunday, we should add 7 days
                if (daysToAdd == 7) {
                    daysToAdd = 0; // If today is Sunday, schedule for the next Sunday
                }
                nextNotificationDate = today.addDays(daysToAdd);
                notificationDate = nextNotificationDate.format();
            }
            when 'Monthly' {
                cronExpression = '0 0 0 1 * ?'; // First day of every month at midnight
                // Get the next month's first day
                Integer nextMonth = today.month() == 12 ? 1 : today.month() + 1;
                nextNotificationDate = Date.newInstance(today.year(), nextMonth, 1);
                notificationDate = nextNotificationDate.format();
            }
            when 'Quarterly' {
                cronExpression = '0 0 0 1 1,4,7,10 ?'; // First day of each quarter
                
                // Calculate the next quarter's first day
                Integer nextQuarterMonth = 0;
                
                if (today.month() <= 3) {
                    nextQuarterMonth = 4; // If we are in the first quarter (Jan-Mar), next quarter starts in April
                } else if (today.month() <= 6) {
                    nextQuarterMonth = 7; // If we are in the second quarter (Apr-Jun), next quarter starts in July
                } else if (today.month() <= 9) {
                    nextQuarterMonth = 10; // If we are in the third quarter (Jul-Sep), next quarter starts in October
                } else {
                    nextQuarterMonth = 1; // If we are in the fourth quarter (Oct-Dec), next quarter starts in January next year
                }
                
                // If we are already in the last quarter (October - December), schedule for the next year
                if (nextQuarterMonth == 1) {
                    nextNotificationDate = Date.newInstance(today.year() + 1, nextQuarterMonth, 1); // January of the next year
                } else {
                    nextNotificationDate = Date.newInstance(today.year(), nextQuarterMonth, 1); // First day of the next quarter
                }
                
                notificationDate = nextNotificationDate.format(); // Format to a string for the UI
            }
            
            when 'Yearly' {
                cronExpression = '0 0 0 1 1 ?'; // First day of the year at midnight
                // Get the next year's first day
                nextNotificationDate = Date.newInstance(today.year() + 1, 1, 1);
                notificationDate = nextNotificationDate.format();
            }
            when else {
                System.debug('Error: Invalid time frame selected: ' + timeFrame);
                throw new IllegalArgumentException('Invalid time frame selected');
            }
        }
        
        // Send the email confirmation
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{toAddress});
        mail.setSubject('Review Scheduled Successfully');
        mail.setPlainTextBody('Your review has been successfully scheduled for the selected time frame: ' + timeFrame + '. You will be notified on: ' + notificationDate + '.');
        mail.setSaveAsActivity(false);  // Do not save this email as an activity on the user record
        
        // Try to send the email
        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
            System.debug('Confirmation email sent to: ' + toAddress);
        } catch (Exception e) {
            System.debug('Error sending confirmation email: ' + e.getMessage());
            // In case of email sending failure, log the error
        }
        
        // Schedule the job
        try {
            String jobName = 'Review Check: ' + timeFrame;
            System.schedule(jobName, cronExpression, new ReviewEmailScheduler());
            System.debug('Scheduled job successfully with name: ' + jobName);
        } catch (Exception e) {
            System.debug('Error scheduling job: ' + e.getMessage());
            // If job scheduling fails, log the error and send failure email
            Messaging.SingleEmailMessage errorMail = new Messaging.SingleEmailMessage();
            errorMail.setToAddresses(new List<String>{toAddress});
            errorMail.setSubject('Review Scheduled Already');
            errorMail.setPlainTextBody('Review scheduled already, for more info visit "Scheduled Jobs" inside Setup...');
            errorMail.setSaveAsActivity(false);
            
            try {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{errorMail});
                System.debug('Error notification email sent to: ' + toAddress);
            } catch (Exception errorE) {
                System.debug('Error sending error notification email: ' + errorE.getMessage());
            }
            
            System.debug('Error scheduling the job: ' + e.getMessage());
        }
        
        // Return the notification date back to the UI
        return notificationDate;
    }
    
    public class PermissionReviewItem {
        @AuraEnabled public Integer index;
        @AuraEnabled public String type;
        //count innfo
        @AuraEnabled public Decimal OrgHealthCount;
        @AuraEnabled public Integer Profilecount;
        @AuraEnabled public Integer Permissioncount;
        @AuraEnabled public Integer PermissionGroupcount;
        @AuraEnabled public Integer RestrictionGroupcount;
        @AuraEnabled public Integer Rolescount;
        @AuraEnabled public Integer Territoriescount;
        @AuraEnabled public Integer PublicGroupcount;
        @AuraEnabled public Integer InternalRolescount;
        @AuraEnabled public Integer ExternalRolescount;
        @AuraEnabled public Integer unusedProfilesCount;
        @AuraEnabled public Integer unusedPermissionCount;
        // delete info
        @AuraEnabled public String unusedProfilesCanDelete;
        @AuraEnabled public String unusedPermissionSetsCanDelete;
        @AuraEnabled public String unusedPermissionGroupCount;
        @AuraEnabled public Integer unusedRolesCanDelete;
        @AuraEnabled public Integer unusedTerritoriesCanDelete;
        @AuraEnabled public Integer unusedPublicGroupCanDelete;
        @AuraEnabled public Integer unusedInternalRolesCanDelete;
        @AuraEnabled public Integer unusedExternalRolesCanDelete;
        // unused Percentage
        @AuraEnabled public String percentageUnusedProfiles;
        @AuraEnabled public String percentageUnusedPermissions;
        @AuraEnabled public String percentageUnusedPsetGroup;
        @AuraEnabled public String percentageUnusedRoles;
        @AuraEnabled public String percentageUnusedTerritories;
        @AuraEnabled public String percentageUnusedPublicGroup;
        @AuraEnabled public String percentageUnusedInternalRoles;
        @AuraEnabled public String percentageUnusedExternalRoles;
        @AuraEnabled public String linkToReport;
        @AuraEnabled public String percentage;
        @AuraEnabled public String reviewDate;
        //Object Permissions
        @AuraEnabled public Integer TotalCustomObjects;
        @AuraEnabled public Integer DescPopulatedObjects;
        @AuraEnabled public Integer TotalManagedObjects;
        @AuraEnabled public Integer ManagedObjDesc;
        @AuraEnabled public Decimal CustomObjectPercentage;
        @AuraEnabled public Decimal DescriptionPopulatedPercentage; // Add this line
        @AuraEnabled public Decimal TotalManagedObjectsPercentage;
        
    }  
    
    public class ObjPermissionItem{
        
        //Object Permissions
        @AuraEnabled public Integer TotalCustomObjects;
        @AuraEnabled public Integer DescPopulatedObjects;
        @AuraEnabled public Integer TotalManagedObjects;
        @AuraEnabled public Integer ManagedObjDesc;
        @AuraEnabled public Integer EditableObjectsCount;
        @AuraEnabled public Integer BlankEditableDescCount;
        @AuraEnabled public Integer UneditableBlankCount;
        @AuraEnabled public Decimal CustomObjectPercentage;
        @AuraEnabled public Decimal DescriptionPopulatedPercentage; // Add this line
        @AuraEnabled public Decimal TotalManagedObjectsPercentage;
    }
    public class ProPsetPermissionItem { 
        @AuraEnabled public Integer ProfileCount { get; set; }
        @AuraEnabled public Integer ProfileDescriptionCount { get; set; }
        @AuraEnabled public Integer PermissionSetCount { get; set; }
        @AuraEnabled public Integer PermissionSetDescriptionCount { get; set; }
        @AuraEnabled public Integer PermissionSetGroupCount { get; set; }
        @AuraEnabled public Integer PermissionSetGroupDescriptionCount { get; set; }
        
        @AuraEnabled public Integer ProfilePercentage { get; set; }
        @AuraEnabled public Integer ProfilePercentageDec { get; set; }
        @AuraEnabled public Integer PermissionSetPercentage { get; set; }
        @AuraEnabled public Integer PermissionSetPercentageDec { get; set; }
        @AuraEnabled public Integer PsetGroupPercentage { get; set; }
        @AuraEnabled public Integer PsetGroupPercentageDec { get; set; }
        
    }
    
    
}