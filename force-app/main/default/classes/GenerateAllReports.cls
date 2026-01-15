/*
Author       : Himanshu Kr. Varshney
Description  : Batch Apex to generate the Reports for all Options on Intel tab page and it will send an email as zip file to loggedin user's email address 
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class GenerateAllReports implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful{
    public List<String> excelFilesNames;
    public List<Attachment> attachmentList = new List<Attachment>();
    public List<String> listOfIDs{ get; set; }
      public List<String> selectedOption{ get; set; }
    public GenerateAllReports(List<String> listOfIDs,List<string> selectedOption){
        this.listOfIDs = listOfIDs;
        this.selectedOption = selectedOption;
    }
    public Iterable<String> start(Database.BatchableContext BC){
        excelFilesNames = new List<STring>();
      /*  for(Integer i = 1; i < 22; i++){
            excelFilesNames.add('option' + i);
        }
        */
        for(string s : selectedOption){
            system.debug('s'+s);
            excelFilesNames.add(s);
        }
        return excelFilesNames;
    }
    public void execute(Database.BatchableContext BC, List<String> scope){
        for(String s : scope){
           if(s != Null ){
                attachmentList.add(getExportFile(s));
               system.debug('options='+ s);
            }
        }//selectedOptionHelpr=option2,option3,option4,option5,option6,option7,option8,option9,option10,option11,option13,option14,option15,option16,option17,
        //option18,option19,option21,option25,option26,option27,option29,option30,option31,option32,option33
    }
    public void finish(Database.BatchableContext BC){
        List<Messaging.EmailFileAttachment> finalAttachmentList = new List<Messaging.EmailFileAttachment>();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> toAddresses = new String[]{UserInfo.getUserEmail()};
        String body = '';
        SA_Audit__OWD_Sharing_Report__c owdObjRecord = new SA_Audit__OWD_Sharing_Report__c();
        if(Schema.sObjectType.SA_Audit__OWD_Sharing_Report__c.fields.SA_Audit__Type__c.isCreateable()){
            owdObjRecord.SA_Audit__Type__c = 'AllReports';
            insert owdObjRecord;
        }
        if(Schema.sObjectType.Attachment.fields.ParentId.isCreateable()) {
            for (Attachment attach : attachmentList) {
                attach.ParentId = owdObjRecord.Id;  // Assuming you're assigning the ID of an object to the ParentId
            }
        } 
        insert attachmentList;
        //String fileName = 'RolesReport';
        //getExport(owdObjRecord.Id, fileName); 
        List<Attachment> listOfAttachment = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE ParentId =: owdObjRecord.Id];
        system.debug('listOfAttachment'+listOfAttachment);
        for(Attachment attach: listOfAttachment){
            Messaging.EmailFileAttachment emailAtt = new Messaging.EmailFileAttachment();
            emailAtt.setFileName(attach.Name);
            emailAtt.setBody(attach.Body);
            finalAttachmentList.add(emailAtt);
        }
        email.setFileAttachments(finalAttachmentList);
        email.setToAddresses(toAddresses);
        email.setSubject('Your Security & Access Manager Intel');
        body = 'Dear <b>' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + '</b>,';
        body += '<br/>';
        body += '<br/>';
        body += 'Your Security & Access Manager Intel reports attached.';
        body += '<br/>';
        body += '<br/>';
        body += '<br/>';
        body += '<br/>';
        body += 'Best regards,';
        body += '<br/>';
        body += '<b>Security & Access Manager</b>';
        body += '<br/>';
        body += '<b>By Application Perfection Ltd.</b>';
        email.setHTMLBody(body);
        Messaging.SendEmailResult [] result = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }
    public static Attachment getExportFile(String s){
        //GenerateAllReports obj = new GenerateAllReports();
        Blob excelData;
        String fileName;
        PageReference generateExcel;
        /*if(s == 'option1'){
            generateExcel = Page.SA_Audit__FolderSharesExcel;
            generateExcel.getParameters().put('jobId', obj.listOfIDs[0]);
            }
            else if(s == 'option2'){
            generateExcel = Page.SA_Audit__FolderSharesExcel;
            generateExcel.getParameters().put('jobId', obj.listOfIDs[1]);
        }*/
        if(s == 'option3'){
            generateExcel = Page.SA_Audit__RolesExcel;
            fileName = 'UserRolesReport';
        }
        else if(s == 'option4'){
            generateExcel = Page.SA_Audit__UserRoleExcel;
            fileName = 'RolesReport';
        }
        else if(s == 'option5'){
            generateExcel = Page.SA_Audit__UserProfileAndRoleExcel;
            fileName = 'UserProfilesAndRolesReport';
        }
        else if(s == 'option6'){
            generateExcel = Page.SA_Audit__UserProfileExcel;
            fileName = 'UserProfileReport';
        }
        else if(s == 'option7'){
            generateExcel = Page.SA_Audit__TerritoriesExcel;
            fileName = 'TerritoriesReport';
        }
        else if(s == 'option8'){
            generateExcel = Page.SA_Audit__UserTerritoryExcel;
            fileName = 'UserTerritoriesReport';
        }
        else if(s == 'option9'){
            generateExcel = Page.SA_Audit__UserPermissionSetExcel;
            fileName = 'UserPermissionSetsReport';
        } 
        else if(s == 'option10'){
            generateExcel = Page.SA_Audit__PermissionSetsWithUsersExcel;
            fileName = 'PermissionSetsWithUsersReport';
        }
        /*else if(s == 'option11'){
            generateExcel = Page.SA_Audit__InstalledPackagesReportExcel;
            generateExcel.getParameters().put('jobId', obj.listOfIDs[2]);
            }
            else if(s == 'option12'){
            generateExcel = Page.SA_Audit__RolesExcel;
        }*/
        else if(s == 'option13'){
            generateExcel = Page.SA_Audit__SharingRulesExcel;
            fileName = 'SharingRulesReport';
        }
        else if(s == 'option14'){
            generateExcel = Page.SA_Audit__OWDReportExcel;
            fileName = 'OrgWideDefaultsReport';
        }
        else if(s == 'option15'){
            generateExcel = Page.SA_Audit__PermissionSetWithNoUsersExcel;
            fileName = 'PermissionSetsWithNoUsersReport';
        }
        else if(s == 'option16'){
            generateExcel = Page.SA_Audit__ProfilesWithNoUserExcel;
            fileName = 'ProfilesWithNoUsersReport';
        }
        else if(s == 'option17'){
            generateExcel = Page.SA_Audit__ApexTriggersAndApexClassesExcel;
            fileName = 'ApexTriggersAndApexClassesReport';
        }
        else if(s == 'option18'){
            generateExcel = Page.SA_Audit__PublicGroupExcel;
            fileName = 'PublicGroupsReport';
        }
        else if(s == 'option19'){
            generateExcel = Page.SA_Audit__ManagedPackageLicenseExcel;
            fileName = 'ManagedPackageLicensesReport';
        }
        else if(s == 'option21'){
            generateExcel = Page.SA_Audit__DashboardReportExcel;
            fileName = 'DashboardReport';
        }
        else if(s == 'option27'){
           generateExcel = Page.SA_Audit__PublicGroupMembersExcel;
            fileName = 'PublicGroupMembersExcel';
           }
        else if(s == 'option29'){
            generateExcel =  Page.SA_Audit__UserLicenseExcel;
            fileName = 'UserLicenseExcel';
        }
        else if(s == 'option30'){
            generateExcel = Page.SA_Audit__UserPermissionSetGroupAccess;
            fileName = 'UserPermissionSetGroupAccess';
         }
        else if(s == 'option31'){
           generateExcel = Page.SA_Audit__InactiveUserPermissionSetExcel;
            fileName = 'InactiveUserPermissionSetExcel';
           }
          else if(s == 'option32'){
           generateExcel = Page.SA_Audit__ExternalRolesExcel;
              fileName = 'ExternalRolesExcel';
           }
        else if(s == 'option33'){
           generateExcel = Page.SA_Audit__PermissionsetGroupAndPermissionSets;
            fileName = 'PermissionsetGroupAndPermissionSets';
           }
        
        if(Test.isRunningTest()){ 
            excelData = blob.valueOf('Unit.Test');
        }
        else{
            excelData = generateExcel.getContent();
        }
        Attachment attach = new Attachment();
        //attach.parentId = parentId;
        attach.Name = fileName + '.xls';
        attach.Body = excelData;
        //obj.attachmentList.add(attach);
        return attach;
    }
}