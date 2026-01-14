/*public class UserPermissionSetGroupAccessController implements Database.Batchable<sObject>, Database.Stateful {
    private Map<Id, User> usrMap = new Map<Id, User>();
     
    
    @AuraEnabled
    public  List<PermissionSetWrapper> permissionSetWrappertList { get; set; }
    public List<String> excelFilesNames;
    public List<Attachment> attachmentList = new List<Attachment>();
   // @AuraEnabled
    //public static List<UserPermissionSetGroupAccessController.PermissionSetWrapper> processedData { get; set; }
    
      public UserPermissionSetGroupAccessController() {
       
          system.debug('batchCalled');
        this.permissionSetWrappertList = new List<PermissionSetWrapper>();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        system.debug('batchCalled');
         list<PermissionSetAssignment> quer = [select id, PermissionSetGroupId, AssigneeId, Assignee.Name, Assignee.Email, PermissionSetId,PermissionSet.Label, PermissionSet.Name from PermissionSetAssignment  where Assignee.Name != Null order by Assignee.Name ASC];
        system.debug('quer='+quer);
        return Database.getQueryLocator([
            SELECT Id, PermissionSetGroupId, AssigneeId, Assignee.Name, Assignee.Email, PermissionSetId,
                   PermissionSet.Label, PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE Assignee.Name != null
            ORDER BY Assignee.Name ASC
        ]);
        
    }

    public void execute(Database.BatchableContext bc, List<PermissionSetAssignment> scope) {
         system.debug('scope='+scope);
        permissionSetWrappertList = new List<PermissionSetWrapper>();
        map<Id, List<PermissionSetAssignment>> permissionSetMap = new map<Id, List<PermissionSetAssignment>>();
        map<Id, User> usrMap = new map<Id, User>();
        list<PermissionSetAssignment> permissionSetAssignmentList = new list<PermissionSetAssignment>([select id, PermissionSetGroupId, AssigneeId, Assignee.Name, Assignee.Email, PermissionSetId,PermissionSet.Label, PermissionSet.Name from PermissionSetAssignment  where Assignee.Name != Null order by Assignee.Name ASC]);
         system.debug('permissionSetAssignmentList='+permissionSetAssignmentList);
        for (PermissionSetAssignment assignment : scope) {
            PermissionSetWrapper wrapper = new PermissionSetWrapper();
            wrapper.UserId = assignment.AssigneeId;
            wrapper.UserEmail = assignment.Assignee.Email;
            wrapper.UserNam = assignment.Assignee.Name;
            wrapper.AssignedPermission = assignment.PermissionSet.Name;
            wrapper.PermissionSetGroups = assignment.PermissionSetGroupId;
            permissionSetWrappertList.add(wrapper);
        }
         system.debug('permissionSetWrappertList='+permissionSetWrappertList);
        //permissionSetWrapperList = processPermissionSetWrappers(permissionSetWrappertList);
           
    }
    

    public void finish(Database.BatchableContext bc) { 
        Document doc = new Document();
        doc.Body = Blob.valueOf(JSON.serialize(permissionSetWrappertList));
        List<Messaging.EmailFileAttachment> finalAttachmentList = new List<Messaging.EmailFileAttachment>();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> toAddresses = new String[]{UserInfo.getUserEmail()};
        String body = '';
        SA_Audit__OWD_Sharing_Report__c owdObjRecord = new SA_Audit__OWD_Sharing_Report__c();
        if(Schema.sObjectType.SA_Audit__OWD_Sharing_Report__c.fields.SA_Audit__Type__c.isCreateable()){
            owdObjRecord.SA_Audit__Type__c = 'UserPermissionSetGroup';
            insert owdObjRecord;
        }
        for(Attachment attach: attachmentList){
            attach.parentId = owdObjRecord.Id;
        }
        insert attachmentList;

     List<Attachment> listOfAttachment = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE ParentId =: owdObjRecord.Id];
        system.debug('listOfAttachment'+listOfAttachment);
        for(Attachment attach: listOfAttachment){
            Messaging.EmailFileAttachment emailAtt = new Messaging.EmailFileAttachment();
            emailAtt.setFileName(attach.Name);
            emailAtt.setBody(doc.Body);
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
    public static Attachment getExportFile(){
        //GenerateAllReports obj = new GenerateAllReports();
        Blob excelData;
        String fileName;
        PageReference generateExcel;
        generateExcel = Page.SA_Audit__UserPermissionSetGroupAccess;
        fileName = 'UserPermissionSetGroupAccess';
        excelData = generateExcel.getContent();
         
        Attachment attach = new Attachment();
        //attach.parentId = parentId;
        attach.Name = fileName + '.xls';
        attach.Body = excelData;
        //obj.attachmentList.add(attach);
        return attach;
    }
 

    public Class PermissionSetWrapper {
        @auraEnabled
        public String UserId{get;set;}
         @auraEnabled
        public String UserNam{get;set;}
         @auraEnabled
        public String UserEmail{get;set;}
         @auraEnabled
        public String AssignedPermission{get;set;}
         @auraEnabled
        public String PermissionSetGroups{get;set;}
    }
}


public with sharing class UserPermissionSetGroupAccessController {

    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public static List<PermissionSetWrapper> permissionSetWrappertList { get; set; }
    
    
   
    
    public UserPermissionSetGroupAccessController(){
         xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
         reportInfos = Utils.getReportsInfos();
        fetchTableDataOption30();
    }
    
    @AuraEnabled
    public static list<PermissionSetWrapper> fetchTableDataOption30(){
       permissionSetWrappertList = new List<PermissionSetWrapper>();
        map<Id, List<PermissionSetAssignment>> permissionSetMap = new map<Id, List<PermissionSetAssignment>>();
        map<Id, User> usrMap = new map<Id, User>();
        list<PermissionSetAssignment> permissionSetAssignmentList = new list<PermissionSetAssignment>([select id, PermissionSetGroupId, AssigneeId, Assignee.Name, Assignee.Email, PermissionSetId,PermissionSet.Label, PermissionSet.Name from PermissionSetAssignment  where Assignee.Name != Null order by Assignee.Name ASC LIMIT 1000]);
        for (PermissionSetAssignment assignment : permissionSetAssignmentList) {
            PermissionSetWrapper wrapper = new PermissionSetWrapper();
            wrapper.UserId = assignment.AssigneeId;
            wrapper.UserEmail = assignment.Assignee.Email;
             wrapper.UserNam = assignment.Assignee.Name;
            wrapper.AssignedPermission = assignment.PermissionSet.Name;
            wrapper.PermissionSetGroups = assignment.PermissionSetGroupId;
            permissionSetWrappertList.add(wrapper);
        }


        
        system.debug('======permissionSetWrappertList======'+permissionSetWrappertList);
       
        return permissionSetWrappertList;
        
    }
     public Class PermissionSetWrapper{
      
        @auraEnabled
         public String UserId{get;set;}
         public String UserNam{get;set;}
          public String UserEmail{get;set;}
          public String  AssignedPermission{get;set;}
          public String PermissionSetGroups{get;set;}
    }
    
}
public with sharing class UserPermissionSetGroupAccessController {

    @AuraEnabled
    public String xmlheader { get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos { get; set; }
    @AuraEnabled
    public List<PermissionSetWrapper> permissionSetWrappertList { get; set; }
    
    public UserPermissionSetGroupAccessController() {
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos();
        getfetchTableDataOption30();
    }
    
    @AuraEnabled
    public List<PermissionSetWrapper> getfetchTableDataOption30() {
        permissionSetWrappertList = new List<PermissionSetWrapper>();
        List<PermissionSetAssignment> permissionSetAssignmentList = fetchPermissionSetAssignments();
        
        for (PermissionSetAssignment assignment : permissionSetAssignmentList) {
            PermissionSetWrapper wrapper = new PermissionSetWrapper();
            wrapper.UserId = assignment.AssigneeId;
            wrapper.UserEmail = assignment.Assignee.Email;
            wrapper.UserNam = assignment.Assignee.Name;
            wrapper.AssignedPermission = assignment.PermissionSet.Name;
            wrapper.PermissionSetGroups = assignment.PermissionSetGroupId;
            permissionSetWrappertList.add(wrapper);
        }
        
        System.debug('======permissionSetWrapperList======'+permissionSetWrappertList);
        return permissionSetWrappertList;
    }
    
    private List<PermissionSetAssignment> fetchPermissionSetAssignments() {
        List<PermissionSetAssignment> allAssignments = new List<PermissionSetAssignment>();
        Integer offset = 0;
        Integer batchSize = 200;
        Boolean done = false;
        
        while (!done) {
            List<PermissionSetAssignment> batch = [
                SELECT Id, PermissionSetGroupId, AssigneeId, Assignee.Name, Assignee.Email, PermissionSetId, PermissionSet.Label, PermissionSet.Name 
                FROM PermissionSetAssignment 
                WHERE Assignee.Name != NULL 
                ORDER BY Assignee.Name ASC 
                LIMIT :batchSize OFFSET :offset
            ];
            
            if (batch.isEmpty()) {
                done = true;
            } else {
                allAssignments.addAll(batch);
                offset += batchSize;
            }
        }
        
        return allAssignments;
    }
    
    public class PermissionSetWrapper {
        @AuraEnabled
        public String UserId { get; set; }
        @AuraEnabled
        public String UserNam { get; set; }
        @AuraEnabled
        public String UserEmail { get; set; }
        @AuraEnabled
        public String AssignedPermission { get; set; }
        @AuraEnabled
        public String PermissionSetGroups { get; set; }
    }
}*/
public with sharing class UserPermissionSetGroupAccessController {

    @AuraEnabled
    public String xmlheader { get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos { get; set; }
    @AuraEnabled
    public List<PermissionSetWrapper> permissionSetWrappertList { get; set; }
    
    public UserPermissionSetGroupAccessController() {
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos();
        permissionSetWrappertList = getfetchTableDataOption30();
    }
    
    @AuraEnabled
    public List<PermissionSetWrapper> getfetchTableDataOption30() {
        List<PermissionSetWrapper> permissionSetWrappertList = new List<PermissionSetWrapper>();
        List<PermissionSetAssignment> permissionSetAssignmentList = fetchPermissionSetAssignments();
        
        for (PermissionSetAssignment assignment : permissionSetAssignmentList) {
            PermissionSetWrapper wrapper = new PermissionSetWrapper();
            wrapper.UserId = assignment.AssigneeId;
            wrapper.UserEmail = assignment.Assignee.Email;
            wrapper.UserNam = assignment.Assignee.Name;
            wrapper.AssignedPermission = assignment.PermissionSet.Name;
            wrapper.PermissionSetGroups = assignment.PermissionSetGroupId;
            permissionSetWrappertList.add(wrapper);
        }
        
        System.debug('======permissionSetWrapperList======'+permissionSetWrappertList);
        return permissionSetWrappertList;
    }
    
    private List<PermissionSetAssignment> fetchPermissionSetAssignments() {
        List<PermissionSetAssignment> allAssignments = new List<PermissionSetAssignment>();
        Integer offset = 0;
        Integer batchSize = 200;
        Boolean done = false;
        
        while (!done) {
            List<PermissionSetAssignment> batch = [
                 SELECT Id, PermissionSetGroupId, AssigneeId, Assignee.Name, Assignee.Email, PermissionSetId, PermissionSet.Label, PermissionSet.Name 
        FROM PermissionSetAssignment WHERE NOT(PermissionSet.Name LIKE 'X00%')
        ORDER BY Assignee.Name ASC
        LIMIT :batchSize OFFSET :offset
            ];
            
            if (batch.isEmpty()) {
                done = true;
            } else {
                allAssignments.addAll(batch);
                offset += batchSize;
            }
        }
        
        return allAssignments;
    }
    
    public class PermissionSetWrapper {
        @AuraEnabled
        public String UserId { get; set; }
        @AuraEnabled
        public String UserNam { get; set; }
        @AuraEnabled
        public String UserEmail { get; set; }
        @AuraEnabled
        public String AssignedPermission { get; set; }
        @AuraEnabled
        public String PermissionSetGroups { get; set; }
    }
}