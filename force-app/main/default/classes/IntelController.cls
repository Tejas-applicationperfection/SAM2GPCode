/*
Author       : Himanshu Kr. Varshney
Description  : Apex Controller for Intel Tab(It will Generate the Reports for Layouts and its fields)
Dependencies : Called from intelTab.cmp
*/
public with sharing class IntelController{
    public Boolean isEdit { get; set; }
    //public Integer counter { get; set; }
    public Id jobId { get; set; }
    public Boolean keepPolling { get; set; }
    public String selectedReport { get; set; }
    public Boolean noEndpointMetadata { get; set; }
    public String sfdcUrl { get; set; }
    public static String staticSfdcUrl { get; set; }
    public static Set<String> nameSpacesList = new Set<String>();
    public static MAP<String, String> objectMapWithNameSpace = new MAP<String, String>();
    //xls Variables:
    public String xmlheader {get;set;}
    public String endfile {get;set;} 
    public IntelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        endfile = '</Workbook>';
    }
    // for get profile list 
    // -----------------------------------
    @AuraEnabled
    public List<Id> customProfilesIdList { get; set; }
    @AuraEnabled
    public List<SelectOption> remainingProfiles1 { get; set; }
    @AuraEnabled
    public Map<Id, String> profileMap { get; set; }
    @AuraEnabled
    public String standardProfileIds { get; set; }
    @AuraEnabled
    public List<SelectOption> remainingProfiles { get; set; }
    @AuraEnabled
    public Boolean existCustomProfiles { get; set; }
    @AuraEnabled
    public List<SelectOption> selectedProfiles { get; set; }
    @AuraEnabled
    public Boolean isAccessible { get; set; }
    
    //--------------------------------------
    public Pagereference exportAll(){
        return new Pagereference('/apex/ExportAll');
    }
    public class CustomException extends Exception{ 
    }
    @AuraEnabled(cacheable=true)
    public static Boolean PaidFeatureAccess() {
        // Check if the feature is enabled for the user
      //return FeatureManagement.checkPackageBooleanValue('IntelPaidAccess');
       //for data dictionary
             return true;
    }
    
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below Method will Give Us List of Standard and Custom Objects
*/  
    @AuraEnabled
    public static List<ObjectDetails> getAllObjectNames(){
        List<ObjectDetails> sObjectList = new List<ObjectDetails>();
        try{
            for(Schema.SObjectType objTyp : ProcessInstance.TargetObjectId.getDescribe().getReferenceTo()){
                Schema.DescribeSObjectResult describeSObjectResultObj = objTyp.getDescribe();
                String name = describeSObjectResultObj.getName();
                ObjectDetails objDetails = new ObjectDetails();
                if(!describeSObjectResultObj.isCreateable())
                    continue;
                if(describeSObjectResultObj.getRecordTypeInfos().size() > 0 
                   && !describeSObjectResultObj.isCustomSetting() 
                   && describeSObjectResultObj.isCreateable() 
                   && !name.containsignorecase('history') 
                   && !name.containsignorecase('tag') 
                   && !name.containsignorecase('share') 
                   && !name.containsignorecase('feed') 
                   && name != null){ 
                       objDetails.label = describeSObjectResultObj.getLabel();
                       objDetails.value = describeSObjectResultObj.getName();
                       objDetails.type = describeSObjectResultObj.isCustom();
                       objDetails.pluralName = describeSObjectResultObj.getLabelPlural();
                       objDetails.objectPrefix = describeSObjectResultObj.getKeyPrefix();
                   }
                sObjectList.add(objDetails);
            }
        }
        catch(Exception ex){
            //It Will Show Exception on UI.
            throw new AuraHandledException(ex.getMessage()); 
        }
        return sObjectList;     
    }
    /*------------------------------------------------------------------------------------------------------------------------------------------------*/
    //Tejas
    @AuraEnabled
    public static List<ProfileData> getProfilesList() {
        List<ProfileData> Allprofiles = new List<ProfileData>();
        List<profile> Profiles = [select Name from profile limit 45000];
        
        for(profile pr: Profiles){
            ProfileData pro = new ProfileData();
            pro.label = pr.Name;
            pro.value = pr.Name;
            Allprofiles.add(pro);
        }
        
        return Allprofiles;
        
    }
    
    /*---------------------------------------------------------------------------------------------------------------------------------------------------*/    
     /*------------------------------------------------------------------------------------------------------------------------------------------------*/
    //Tejas
    @AuraEnabled
    public static List<UserData> getUserList() {
        List<UserData> AllUsers = new List<UserData>();
        List<User> Users = [select Id,Name from User limit 40000];
        
        for(User Us: Users){
            UserData pro = new UserData();
            pro.label = Us.Name;
            pro.value = Us.Id;
            AllUsers.add(pro);
        }
        
        return AllUsers;
        
    }
    
    /*---------------------------------------------------------------------------------------------------------------------------------------------------*/    
 
    
    
    
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below Method will Give Us Object Id Based on Object API Name(It is for Custom Object Only)
*/
    
    public static string getSobjectId(String objName){
        HttpRequest req = new HttpRequest(); 
        String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm();
        string endPoint = sfdcURL + '/services/data/v41.0/tooling/query/?q=Select+Id+From+CustomObject+Where+DeveloperName+=\'' + String.escapeSingleQuotes(objName) + '\'';
        req.setEndpoint(endPoint);
        req.setMethod('GET');
         String sessionId = UserInfo.getSessionId();
       // String sessionId =  'callout:SA_Audit__Tooling_API_Creds';
        String authorizationHeader = 'OAuth ' + sessionId;
        req.setHeader('Authorization', authorizationHeader);
        Http http = new Http();
        HttpResponse res = http.send(req);
        string strResponse = res.getBody();
        Result jsonField = (Result)System.JSON.deserialize(strResponse, Result.class);
        return jsonField.records[0].Id;
    }
    /*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will give us the Scheduled Reports Data(It is Option 23 in Intel Tab)
*/
    @AuraEnabled
    public static List<ScheduledReportsData> fetchTableDataOption23(){
        List<ScheduledReportsData> scheduledReportsDataList = new List<ScheduledReportsData>();
        SA_Audit__BatchApexStatus__c customSettingRecord = SA_Audit__BatchApexStatus__c.getValues('ScheduledReports');
        system.debug('testing fst');
        if(customSettingRecord != null){
            system.debug('testing scnd');
           ///if(SA_Audit__BatchApexStatus__c.getDescribe().fields.getMap().get('Is_Batch_Apex_Executed__c').getDescribe().isUpdateable() && SA_Audit__BatchApexStatus__c.getDescribe().fields.getMap().get('Batch_Apex_Id__c').getDescribe().isUpdateable()){
               //objectType.getDescribe().fields.getMap().get('SA_Audit__Is_Batch_Apex_Executed__c').getDescribe().isUpdateable();
                if(!customSettingRecord.SA_Audit__Is_Batch_Apex_Executed__c){
                    String scheduledReportsBatchApexId = Database.executeBatch(new ScheduledReportsBatchApex(),100);
                   if(Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.SA_Audit__Batch_Apex_Id__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.SA_Audit__Batch_Apex_Id__c.isUpdateable() &&
                  Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.SA_Audit__Is_Batch_Apex_Executed__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.SA_Audit__Is_Batch_Apex_Executed__c.isUpdateable()){
                    customSettingRecord.SA_Audit__Batch_Apex_Id__c = scheduledReportsBatchApexId;
                    customSettingRecord.SA_Audit__Is_Batch_Apex_Executed__c = true; 
                    update customSettingRecord;
                        system.debug('testing frth');}
                }
          // }

            else{
                try{
                    system.debug('testing fifth');
                    
                    AsyncApexJob job = [SELECT JobItemsProcessed, TotalJobItems, Status FROM AsyncApexJob WHERE Id =: customSettingRecord.SA_Audit__Batch_Apex_Id__c];
                    system.debug('$$AsyncApexJob' + job);
                    if(job.Status != 'Completed'){
                        system.debug('testing 6');
                        system.debug('testing 6=='+ job.NumberOfErrors+ '==' + job.Status);
                        String errorMessage = 'We are in the ' + job.Status.toLowerCase() + ' status...' + 'We are processing this report to see the latest status press View Data/Export to Excel button again.';
                        throw new CustomException(errorMessage);
                    }
                    else{
                        system.debug('testing 7');
                        SA_Audit__OWD_Sharing_Report__c objData = [SELECT Id, SA_Audit__OWD_Data_Field__c, SA_Audit__Sharing_Rules_Details__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'ScheduledReports' ORDER BY CreatedDate DESC LIMIT 1];
                        system.debug('$$objData'+objData);
                        Attachment attach = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE ParentId =: objData.Id LIMIT 1];
                        scheduledReportsDataList = (List<ScheduledReportsData>)System.JSON.deserialize(attach.Body.toString(), List<ScheduledReportsData>.class);
                        system.debug('$$scheduledReportsDataList=='+scheduledReportsDataList);
                        system.debug('$$atach==' + attach);
                        system.debug('$$objData'+objData);
                    }
                }catch(Exception e){
                    system.debug('testing 6');
                    string ExpError = e.getMessage();
                    system.debug('error'+ ExpError);
                    system.debug('error'+ e);
                    
                }
            }
        }
        else{
            ///COMMENTED FOR fls cREATE
            /*if (Schema.sObjectType.SA_Audit__BatchApexStatus__c.isCreateable()) {
                customSettingRecord = new SA_Audit__BatchApexStatus__c();
                customSettingRecord.Name = 'ScheduledReports';
                insert customSettingRecord;
            }*/
       system.debug('$$scheduledReportsDataList=='+scheduledReportsDataList);
           
        }
        
        return scheduledReportsDataList; 
    }
    /*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will fetch Data of All the Reports which has either Cross or Field Filter(It is Option 24 in Intel tab)
*/
    @AuraEnabled
    public static List<FilteredReportsData> fetchTableDataOption24(){ 
        List<FilteredReportsData> filteredReportList = new List<FilteredReportsData>();
        SA_Audit__BatchApexStatus__c customSettingRecord = SA_Audit__BatchApexStatus__c.getValues('FilteredReports');
        if(test.isRunningTest()){
            customSettingRecord.SA_Audit__Is_Batch_Apex_Executed__c = true;
        }
        if(customSettingRecord != null){
            if(!customSettingRecord.SA_Audit__Is_Batch_Apex_Executed__c){
                String filteredBatchApexId = Database.executeBatch(new FilteredReportsBatchApex(),30);
                 if(Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.SA_Audit__Batch_Apex_Id__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.SA_Audit__Batch_Apex_Id__c.isUpdateable() &&
                  Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.SA_Audit__Is_Batch_Apex_Executed__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.SA_Audit__Is_Batch_Apex_Executed__c.isUpdateable()){
                customSettingRecord.SA_Audit__Batch_Apex_Id__c = filteredBatchApexId;
                customSettingRecord.SA_Audit__Is_Batch_Apex_Executed__c = true; 
                        update customSettingRecord;}
            }
            else{
                try{
                    AsyncApexJob job = [SELECT JobItemsProcessed, TotalJobItems, Status FROM AsyncApexJob WHERE Id =: customSettingRecord.SA_Audit__Batch_Apex_Id__c];
                    
                    if(job.Status != 'Completed'){ 
                        String errorMessage = 'We are in the ' + job.Status.toLowerCase() + ' status...' + 'We are processing this report to see the latest status press View Data/Export to Excel button again.';
                        throw new CustomException(errorMessage);
                    } 
                    else{
                        SA_Audit__OWD_Sharing_Report__c objData = [SELECT Id, SA_Audit__OWD_Data_Field__c, SA_Audit__Sharing_Rules_Details__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'FilteredReport' ORDER BY CreatedDate DESC LIMIT 1];
                        Attachment attach = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE ParentId =: objData.Id LIMIT 1];
                        filteredReportList = (List<FilteredReportsData>)System.JSON.deserialize(attach.Body.toString(), List<FilteredReportsData>.class);
                    }
                }catch(Exception e){
                    //if(e != null){
                    //     AsyncApexJob job = [SELECT JobItemsProcessed, TotalJobItems, Status FROM AsyncApexJob WHERE Id =: customSettingRecord.SA_Audit__Batch_Apex_Id__c]; 	
                    // String errorMessage = 'We are in the ' + job.Status.toLowerCase() + ' status...' + 'We are processing this report to see the latest status press View Data/Export to Excel button again.';
                    // throw new CustomException(errorMessage);
                    // }
                    system.debug('error'+e);
                    
                    
                }
                
            }
            
            
        }
         ///COMMENTED FOR fls cREATE
        else if(Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.SA_Audit__Batch_Apex_Id__c.isCreateable() &&
                  Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.Name.isCreateable()){
            customSettingRecord = new SA_Audit__BatchApexStatus__c();
            customSettingRecord.Name = 'FilteredReports';
            insert customSettingRecord;
        }
        return filteredReportList;
    }
    /*
Author            : Himanshu Kr. Varshney
Purpose of method : Below Wrapper class will store the JSON Data for Filtered Reports
*/
    public class FilteredReportsData{
        @AuraEnabled 
        public String reportName { get; set; }
        @AuraEnabled 
        public String folderName { get; set; }
        @AuraEnabled 
        public String reportUniqueName { get; set; }
        @AuraEnabled 
        public String filterBy { get; set; }
        @AuraEnabled 
        public String filterType { get; set; }
    }
    /*
Author            : Himanshu Kr. Varshney
Purpose of method : Below Wrapper class will store the JSON Data for Scheduled Reports
*/
    public class ScheduledReportsData{
        @AuraEnabled 
        public String reportName { get; set; }
        @AuraEnabled 
        public String folderName { get; set; }
        @AuraEnabled 
        public String reportUniqueName { get; set; }
        @AuraEnabled 
        public String runningUserName { get; set; }
        @AuraEnabled 
        public DateTime startTime { get; set; }
        @AuraEnabled 
        public DateTime endTime { get; set; } 
        @AuraEnabled 
        public DateTime previousRunTime { get; set; } 
        @AuraEnabled 
        public DateTime nextRunTime { get; set; } 
        @AuraEnabled 
        public String freequency { get; set; } 
    }
    /*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will fetch Data related to all Folders(It is option 25 in Intel Tab)
*/
    @AuraEnabled 
    public static List<FoldersData> fetchTableDataOption25(){
        List<FoldersData> customFoldersData = new List<FoldersData>();
        List<Folder> folderList = [SELECT Id, Name, DeveloperName, CreatedDate FROM Folder WHERE DeveloperName != 'Report_Manager_Archive_Folder' AND DeveloperName != null AND Name != null LIMIT 5];
        List<Report> reportList = [SELECT Id, OwnerId FROM Report WHERE FolderName != null];
        String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm();
        for(Folder folderOneRecord: folderList){
            Integer reportCount = 0;
            FoldersData customFolderOneRecord = new FoldersData();
            customFolderOneRecord.folderName = folderOneRecord.Name;
            customFolderOneRecord.folderUniqueName = folderOneRecord.DeveloperName;
            customFolderOneRecord.url = sfdcURL + '/' + folderOneRecord.Id;
            customFolderOneRecord.createdDate = folderOneRecord.CreatedDate;
            for(Report reportOneRecord: reportList){
                if(reportOneRecord.OwnerId == folderOneRecord.Id){
                    reportCount++;
                }
            }
            customFolderOneRecord.reportsCount = reportCount;
            customFoldersData.add(customFolderOneRecord);
        }
        return customFoldersData;
    }
    /*
Author            : Himanshu Kr. Varshney
Purpose of method : Below Wrapper class will store the JSON Data for all the Folders
*/
    public class FoldersData{
        @AuraEnabled 
        public String folderName { get; set; }
        @AuraEnabled 
        public String folderUniqueName { get; set; }
        @AuraEnabled 
        public String url { get; set; }
        @AuraEnabled 
        public DateTime createdDate { get; set; }
        @AuraEnabled 
        public Integer reportsCount { get; set; }
    }
    
   
    /*
Author  : Pradeep
Purpose : Below method will Give us  App visibility details for all the profiles
*/
    @auraEnabled
    public static object fetchTableDataOption26(){
        map<string,string>appId2Name=new map<string,string>();
        map<string,string>appName2Vis=new map<string,string>();
        map<string,map<string,string>>profile2visMap=new map<string,map<string,string>>();
        
        for(AppMenuItem ami:[SELECT ApplicationId,Name,Label,IsAccessible,IsVisible FROM AppMenuItem where Type ='TabSet']){
            appId2Name.put(ami.ApplicationId,ami.name);
            appName2Vis.put(ami.name,' ');
        }
        for(profile p:[select id,name from profile ORDER BY NAME LIMIT 20000]){
            map<string,string>cloneMap=appName2Vis.clone();
            profile2visMap.put(p.name,cloneMap);
        }
        for(SetupEntityAccess sea:[SELECT Id,Parent.IsOwnedByProfile,Parent.Profile.Name,SetupEntityId,SetupEntityType FROM SetupEntityAccess 
                                   WHERE (Parent.IsOwnedByProfile=true AND SetupEntityId in:appId2Name.keySet() AND SetupEntityType !='ConnectedApplication' AND SetupEntityType ='TabSet')]){
                                       map<string,string>tmpMap=profile2visMap.get(sea.Parent.Profile.Name);
                                       tmpMap.put(appId2Name.get(sea.SetupEntityId),'Visible');
                                       profile2visMap.put(sea.Parent.Profile.Name,tmpMap);      
                                   }
        list<object>retList=new list<object>();
        list<string>appNames=new list<string>{' '};
            list<list<string>>visList=new list<list<string>>();
        appNames.addAll(appName2Vis.keySet());
        appNames.sort();
        for(string str:profile2visMap.keySet()){
            map<string,string>tmpMap=profile2visMap.get(str);
            list<string>tmpList=new list<string>();
            for(string str1:appNames){
                if(tmpMap.containsKey(str1)){
                    tmpList.add(tmpMap.get(str1));
                }else{
                    tmpList.add(str);
                }
            }
            visList.add(tmpList);
        }
        map<string,object>respMap=new map<string,object>{'header'=>appNames,'body'=>visList};
            /*system.debug(JSON.serializePretty(appNames.size()));
system.debug(JSON.serializePretty(visList[0].size()));
system.debug(JSON.serializePretty(visList[1].size()));
system.debug(JSON.serializePretty(visList[2]));*/
            return respMap;
    }
    
    
    /*
Author  : Pradeep Joshi
Purpose : Below method will Give us all Object Details like Fields API Name, Label etc for a List of Object
*/    
    @auraEnabled
    public static void downloadApplicationAccess(){   
        list<ApplicationAccessWrapper> applicationAccessWrapperList = new list<ApplicationAccessWrapper>();
        map<string, AppMenuItem> appId2Name = new map<string, AppMenuItem>();
        map<string, SetupEntityAccess> setUpEntityAccessMap = new map<string, SetupEntityAccess>();
        list<Profile> profileList = [select id, Name from Profile Where Name != Null];
        set<string> profileNameSet = new set<string>();
        for(AppMenuItem ami:[SELECT ApplicationId,Name,Label,IsAccessible,IsVisible FROM AppMenuItem where Type ='TabSet']){
            appId2Name.put(ami.ApplicationId,ami);
        }
        

        
        for(SetupEntityAccess accs : [SELECT Id,Parent.IsOwnedByProfile,Parent.Profile.Name, Parent.Name, SetupEntityId,SetupEntityType FROM SetupEntityAccess WHERE (SetupEntityId in:appId2Name.keySet() AND Parent.IsOwnedByProfile=true AND SetupEntityType !='ConnectedApplication' AND SetupEntityType ='TabSet')]){
            ApplicationAccessWrapper wrp = new ApplicationAccessWrapper();
            if(appId2Name.containskey(accs.SetupEntityId)){
                    wrp.appName = appId2Name.get(accs.SetupEntityId).Label;
                    wrp.profileName = accs.Parent.Profile.Name;
                    wrp.visibility = 'v' ; 
                	profileNameSet.add(accs.Parent.Profile.Name);
                	applicationAccessWrapperList.add(wrp);
                    }
                }
        
        list<Profile> profileList1 = new  list<Profile>([select id, Name from Profile where Name NOT IN : profileNameSet]);
        
        for(AppMenuItem ami:[SELECT ApplicationId,Name,Label,IsAccessible,IsVisible FROM AppMenuItem where Type ='TabSet']){
            if(profileList1.size()>0){
                for(Profile prfile : profileList1){
                   ApplicationAccessWrapper wrp = new ApplicationAccessWrapper();
  					wrp.appName = ami.Label;
                    wrp.profileName = prfile.Name;
                    wrp.visibility = '' ; 
                	applicationAccessWrapperList.add(wrp);
                }
            }
        }
      list<SA_Audit__App_Access__c>  dd = new list<SA_Audit__App_Access__c>();     
    for(ApplicationAccessWrapper cc : applicationAccessWrapperList){
        SA_Audit__App_Access__c audit = new SA_Audit__App_Access__c();
        audit.SA_Audit__App_Name__c = cc.appName;
            audit.SA_Audit__Visibility__c = cc.visibility;
            audit.SA_Audit__Profile_Name__c =  cc.profileName;
            dd.add(audit);
    }
    if(Schema.sObjectType.SA_Audit__App_Access__c.fields.SA_Audit__App_Name__c.isCreateable() && Schema.sObjectType.SA_Audit__App_Access__c.fields.SA_Audit__Visibility__c.isCreateable() && Schema.sObjectType.SA_Audit__App_Access__c.fields.SA_Audit__Profile_Name__c.isCreateable()){

        insert dd;
    }

    system.debug('=====applicationAccessWrapperList====='+applicationAccessWrapperList);
    //    return applicationAccessWrapperList;
        
    }
    
    
    public class ApplicationAccessWrapper{
        @auraEnabled
        public string appName ='';
        @auraEnabled
        public string profileName ='';
        @auraEnabled
        public string visibility ='';
        
    }
    /*
Author  : TJ
Purpose : Below method will Give us all Object Details like Fields API Name, Label etc for a List of Object
  
    @auraEnabled
    public static list<PermissionSetWrapper> fetchTableDataOption30(){
        List<PermissionSetWrapper> permissionSetWrappertList = new List<PermissionSetWrapper>();
        map<Id, List<PermissionSetAssignment>> permissionSetMap = new map<Id, List<PermissionSetAssignment>>();
        map<Id, User> usrMap = new map<Id, User>();
        list<PermissionSetAssignment> permissionSetAssignmentList = new list<PermissionSetAssignment>([select id, PermissionSetGroupId, AssigneeId, Assignee.Name, Assignee.Email, PermissionSetId,PermissionSet.Label, PermissionSet.Name from PermissionSetAssignment order by Assignee.Name ASC]);
        PermissionSetWrapper wrp = new PermissionSetWrapper();
        wrp.permissionSetAssignmentList.addAll(permissionSetAssignmentList);
        permissionSetWrappertList.add(wrp);
        system.debug('======permissionSetWrappertList======'+permissionSetWrappertList);
        return permissionSetWrappertList;
        
}*/  
   @AuraEnabled
public static Map<String, Object> fetchTableDataOption30(Integer pageNumber, Integer pageSize){
    Map<String, Object> resultMap = new Map<String, Object>();

    // Count total records
    Integer totalRecords = [SELECT Count() FROM PermissionSetAssignment  LIMIT 39000];

    // Calculate the offset
    Integer offset = (pageNumber - 1) * pageSize;

    // Retrieve the paginated PermissionSetAssignment records
    List<PermissionSetAssignment> permissionSetAssignmentList = [
        SELECT Id, PermissionSetGroupId, AssigneeId, Assignee.Name, Assignee.Email, PermissionSetId, PermissionSet.Label, PermissionSet.Name 
        FROM PermissionSetAssignment WHERE NOT(PermissionSet.Name LIKE 'X00%')
        ORDER BY Assignee.Name ASC
        LIMIT :pageSize OFFSET :offset
    ];

    resultMap.put('data', permissionSetAssignmentList);
    resultMap.put('totalRecords', totalRecords);

    system.debug('======resultMap======'+resultMap);
    return resultMap;
}


    
    /*
Author  : Tejas kshirsagar
Purpose : Below method will Give us all Object Details like Fields API Name, Label etc for a List of Object
*/  
   /* @auraEnabled
    public static list<PermissionSetWrapper1> fetchTableDataOption33(){
        map<string, List<string>> permissionSetListMap = new map<string, List<string>>();
        map<string, PermissionSetGroupComponent> permissionSetListMap1 = new map<string, PermissionSetGroupComponent>(); 
        List<PermissionSetWrapper1> wrpList = new List<PermissionSetWrapper1>();
        for(PermissionSetGroupComponent permissionSetGrpCmp : [SELECT PermissionSetGroupId, CreatedBy.Name, CreatedDate, PermissionSetGroup.DeveloperName, PermissionSetId, PermissionSet.Name, PermissionSet.Label FROM PermissionSetGroupComponent Limit 40000]){
            permissionSetListMap1.put(permissionSetGrpCmp.PermissionSetGroup.DeveloperName, permissionSetGrpCmp);
            if(permissionSetListMap.containsKey(permissionSetGrpCmp.PermissionSetGroup.DeveloperName)){
                permissionSetListMap.get(permissionSetGrpCmp.PermissionSetGroup.DeveloperName).add(permissionSetGrpCmp.PermissionSet.Name); 
            }else{
                permissionSetListMap.put(permissionSetGrpCmp.PermissionSetGroup.DeveloperName, new List<String>{permissionSetGrpCmp.PermissionSet.Name}); 
            }
        }
        
        system.debug('====wrpList123===='+permissionSetListMap);
        
        for(string str : permissionSetListMap.keyset()){
            PermissionSetWrapper1 wrp = new PermissionSetWrapper1();
            wrp.psgcmp = permissionSetListMap1.get(str);
            for(string str1 : permissionSetListMap.get(str)){
                wrp.strList.add(str1);
            }
            wrpList.add(wrp);
        }
        system.debug('====wrpList===='+wrpList);
        return wrpList;
    }*/
    @auraEnabled
public static List<PermissionSetWrapper1> fetchTableDataOption33(){
    Map<String, List<String>> permissionSetListMap = new Map<String, List<String>>();
    Map<String, PermissionSetGroupComponent> permissionSetListMap1 = new Map<String, PermissionSetGroupComponent>(); 
    List<PermissionSetWrapper1> wrpList = new List<PermissionSetWrapper1>();

    for(PermissionSetGroupComponent permissionSetGrpCmp : [SELECT PermissionSetGroupId, CreatedBy.Name, CreatedDate, PermissionSetGroup.DeveloperName, PermissionSetId, PermissionSet.Name, PermissionSet.Label FROM PermissionSetGroupComponent Limit 30000]){
        // Add null check for PermissionSetGroup.DeveloperName
        if(permissionSetGrpCmp.PermissionSetGroup != null && permissionSetGrpCmp.PermissionSetGroup.DeveloperName != null) {
            permissionSetListMap1.put(permissionSetGrpCmp.PermissionSetGroup.DeveloperName, permissionSetGrpCmp);
            if(permissionSetListMap.containsKey(permissionSetGrpCmp.PermissionSetGroup.DeveloperName)){
                // Add null check for PermissionSet.Name
                if(permissionSetGrpCmp.PermissionSet != null && permissionSetGrpCmp.PermissionSet.Name != null) {
                    permissionSetListMap.get(permissionSetGrpCmp.PermissionSetGroup.DeveloperName).add(permissionSetGrpCmp.PermissionSet.Name); 
                } else {
                    System.debug('Null PermissionSet or PermissionSet.Name: ' + permissionSetGrpCmp);
                }
            } else {
                if(permissionSetGrpCmp.PermissionSet != null && permissionSetGrpCmp.PermissionSet.Name != null) {
                    permissionSetListMap.put(permissionSetGrpCmp.PermissionSetGroup.DeveloperName, new List<String>{permissionSetGrpCmp.PermissionSet.Name}); 
                } else {
                    System.debug('Null PermissionSet or PermissionSet.Name: ' + permissionSetGrpCmp);
                }
            }
        } else {
            System.debug('Null PermissionSetGroup or PermissionSetGroup.DeveloperName: ' + permissionSetGrpCmp);
        }
    }

    System.debug('====wrpList123====' + permissionSetListMap);

    for(String str : permissionSetListMap.keySet()){
        PermissionSetWrapper1 wrp = new PermissionSetWrapper1();
        wrp.psgcmp = permissionSetListMap1.get(str);
        // Initialize strList to avoid null reference
        wrp.strList = new List<String>();

        for(String str1 : permissionSetListMap.get(str)){
            wrp.strList.add(str1);
        }
        wrpList.add(wrp);
    }

    System.debug('====wrpList====' + wrpList);
    return wrpList;
}
    
    
    
   /* @auraEnabled(cacheable=true)
    public static List<PermissionSet> fetchTableDataOption39() {
        // Get all Permission Set IDs assigned to Permission Set Groups
        Set<Id> assignedPermSetIds = new Set<Id>();
        for (PermissionSetAssignment psa : [
            SELECT PermissionSetId FROM PermissionSetAssignment WHERE PermissionSetGroupId != null
        ]) {
            assignedPermSetIds.add(psa.PermissionSetId);
        }
        
        // Query permission sets that are not in any group
        return [
            SELECT Id, Name, Label FROM PermissionSet
            WHERE Id NOT IN :assignedPermSetIds AND (NOT PermissionSet.Name LIKE 'X00%')
        ];
    }*/
    @auraEnabled(cacheable=true)
public static List<PermissionSet> fetchTableDataOption39() {
    try {
        // Get all Permission Set IDs assigned to Permission Set Groups
        Set<Id> assignedPermSetIds = new Set<Id>();
        for (PermissionSetGroupComponent psgc : [
            SELECT PermissionSetId FROM PermissionSetGroupComponent LIMIT 2000  ]) {
            assignedPermSetIds.add(psgc.PermissionSetId);
        }
        
        // Query Permission Sets that are NOT assigned to any group
        return [
            SELECT Id, Name, Label, CreatedBy.Name,CreatedDate 
            FROM PermissionSet
            WHERE Id NOT IN :assignedPermSetIds AND (NOT PermissionSet.Name LIKE 'X00%') ORDER By Name LIMIT 2000
        ];
    } catch (Exception e) {
        // Handle unexpected errors
        System.debug('Error in fetchTableDataOption39: ' + e.getMessage());
        throw new AuraHandledException('An error occurred while fetching permission sets.');
    }
}

    

    

    
    /*
@auraEnabled
public static list<PermissionSetWrapper1> fetchTableDataOption33(){
List<PermissionSetWrapper1> permissionSetWrappertList = new List<PermissionSetWrapper1>();
map<Id, String> permissionSetGroupMap = new map<Id, String>();
map<Id, List<String>> permissionSetMap = new map<Id, List<String>>();
map<Id, User> usrMap = new map<Id, User>();
list<PermissionSetAssignment> permissionSetAssignmentList = new list<PermissionSetAssignment>([select id, PermissionSetGroupId, AssigneeId, Assignee.Name, Assignee.Email, PermissionSetId,PermissionSet.Label, PermissionSet.Name from PermissionSetAssignment where PermissionSetGroupId !=null order by Assignee.Name ASC]);
for(PermissionSetAssignment permissionSetAssign : permissionSetAssignmentList) {
permissionSetGroupMap.put(permissionSetAssign.PermissionSetGroupId, permissionSetAssign.PermissionSet.Label); 
} 
List<PermissionSet> PermissionSetList = new List<PermissionSet>([select Id, Label, PermissionSetGroupId from permissionSet]);
system.debug('======PermissionSetList=22==='+PermissionSetList);
for(PermissionSet permission : PermissionSetList){
system.debug('======a==='+permission);
if(permissionSetMap.containsKey(permission.PermissionSetGroupId)){
permissionSetMap.get(permission.PermissionSetGroupId).add(permission.Label);
}else{
permissionSetMap.put(permission.PermissionSetGroupId, new List<String>{permission.Label}); 
}
}
for(Id ids : permissionSetGroupMap.Keyset()){
PermissionSetWrapper1 wrp = new PermissionSetWrapper1();
wrp.str = permissionSetGroupMap.get(ids);
wrp.permissionSetGrpId = ids;
system.debug('======inside loop==='+permissionSetMap.get(ids));
for(String assign : permissionSetMap.get(ids)){
wrp.strList.add(assign);
}
permissionSetWrappertList.add(wrp);
} 
return permissionSetWrappertList;
}*/
    
    /*
Author  : Pradeep Joshi
*/   
    public Class PermissionSetWrapper1{
        
        /*   @auraEnabled
public String str = '';

@auraEnabled
public Id permissionSetGrpId ;
*/ 
        @auraEnabled
        public PermissionSetGroupComponent psgcmp = new PermissionSetGroupComponent();
        
        @auraEnabled
        public List<String> strList = new List<String>();
    }
    
    /*
Author  : Pradeep Joshi
*/   
    public Class PermissionSetWrapper{
        /*
@auraEnabled
public User usr = new User();
*/
        @auraEnabled
        public List<PermissionSetAssignment> permissionSetAssignmentList = new List<PermissionSetAssignment>();
    }
    
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will Give us all Object Details like Fields API Name, Label etc for a List of Object
*/
    @AuraEnabled
    public static List<JSONData> getAllObjectDetails(List<String> objectNames){ 
        List<PackageLicense> packageLicenseList = [SELECT NamespacePrefix FROM PackageLicense Limit 2000];
        for(PackageLicense onePackageLicense: packageLicenseList){
            nameSpacesList.add(onePackageLicense.NamespacePrefix + '__');
        }
        String currentOrgNameSpace = [SELECT NamespacePrefix FROM Organization Limit 1].NamespacePrefix;
        if(String.isNotBlank(currentOrgNameSpace)){
            nameSpacesList.add(currentOrgNameSpace + '__');
        }
        List<JSONData> allJsonData = new List<JSONData>();
        List<String> layoutNames = new List<String>();
        for(String objName : objectNames){
            JSONData oneJsonData = new JSONData();
            oneJsonData.objectName = objName;
            if(objName.endsWith('__c')){
                String key = objName;
                String str = objName.substring(0, objName.length() - 3);
                for(String nameSpace: nameSpacesList){
                    if(str.contains(nameSpace)){
                        str = str.substring(nameSpace.length(), str.length());
                        objectMapWithNameSpace.put(key, nameSpace);
                        break;
                    }
                }
                oneJsonData.developerName = str;
                oneJsonData.allFieldInfos = getAllFields(objName);
                layoutNames = getLayouts(str, true);
                oneJsonData.layoutDatas = getLayoutFields(objName, layoutNames);
            }
            else{
                oneJsonData.allFieldInfos = getAllFields(objName);
                layoutNames = getLayouts(objName, false);
                oneJsonData.layoutDatas = getLayoutFields(objName, layoutNames);
            }
            allJsonData.add(oneJsonData);
        }
        return allJsonData;
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will Give us all Details of a Layout for an Object
*/
    @AuraEnabled
    public static List<String> getLayouts(String objName, Boolean isCustom){
        List<String> layouts = new List<String>();
        string objectId;
        if(isCustom){
            objectId = getSobjectId(objName);
        }
        else{
            objectId = objName;
        }
        HttpRequest req = new HttpRequest();
        string layoutType = 'Standard';
        String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm();
        string endpoint =  sfdcURL + '/services/data/v47.0/tooling/query/?q=SELECT+Id,Name+FROM+Layout+WHERE+TableEnumOrId+=\'' + objectId + '\'+and+LayoutType+=\'' + layoutType + '\'';
        String sessionId = UserInfo.getSessionId();
       // String sessionId =  'callout:SA_Audit__Tooling_API_Creds';
        String authorizationHeader = 'OAuth ' + sessionId;
        req.setHeader('Authorization', authorizationHeader);
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        Http http = new Http();
        HttpResponse res = http.send(req);
        String strResponse = res.getBody();
        Result jsonField = (Result) System.JSON.deserialize(strResponse, Result.class);
        
        // Check if records exist before iterating to prevent List index out of bounds
        if(jsonField != null && jsonField.records != null && !jsonField.records.isEmpty()){
            for(Record recordObj : jsonField.records){
                if(recordObj != null && !String.isBlank(recordObj.Name)){
                    layouts.add(recordObj.Name);
                }
            }
        } else {
            System.debug('No layout records found for object: ' + objName);
        }
        return layouts;
    }
    
    
/*
Author  : TJ
Purpose : retrieve PicklistValueofRecordTypes.
*/
   @AuraEnabled
   public static List<retrievePicklistValueofRecordTypes.picklistWrapper> fetchTableDataOption35(List<String> selectedOptions) { 
       selectedOptions.sort(); 
        List<retrievePicklistValueofRecordTypes.picklistWrapper> AllData2 = retrievePicklistValueofRecordTypes.getPicklistValuesByRecordType(selectedOptions);
        
        return AllData2;
    }
    
    @AuraEnabled
   public static List<TrackFieldHistoryController.FieldData> fetchTableDataOption38(List<String> selectedOptions) { 
       selectedOptions.sort(); 
        List<TrackFieldHistoryController.FieldData> AllData2 = TrackFieldHistoryController.getFieldHistoryTrackingStatus(selectedOptions);
        
        return AllData2;
    }
    
    /*
Author  : TJ
Purpose : retrieve pagelayouts.
*/
@AuraEnabled
public static PageLayoutAssignmentClass.ProfileLayoutAssignment fetchTableDataOption36(List<String> selectedOptions) { 
    PageLayoutAssignmentClass.ProfileLayoutAssignment AllData3 = PageLayoutAssignmentClass.readProfileLayoutAssignmentsForObject(selectedOptions);
    return AllData3;
}


/*
Author  : TJ
Purpose : It shows RecordTypeAssignment for 
*/ 
    
      @AuraEnabled
   public static List<RecordTypeAssignment.RecordTypeWrapper> fetchTableDataOption34(List<String> Selectedpro) {
       system.debug('Entry in fetchTableDataOption30=='+Selectedpro);
        List<RecordTypeAssignment.RecordTypeWrapper> AllData = RecordTypeAssignment.RecordTypeAssignmentmeth(Selectedpro);
       system.debug('Entry in fetchTableDataOptionAllData=='+AllData);
        return AllData;
    }
    
    
    
    
       
/*
Author  : Himanshu Kr. Varshney
Purpose : Below method will Give us all field Details for an Object
modified by : Pradeep
*/
    @AuraEnabled
    public static List<FieldInfo> getAllFields(String objectAPIName){
        try{
            List<FieldInfo> fieldNames = new List<FieldInfo>();
            List<String> fieldLabels = new List<String>();
            Map<String, Schema.DescribeFieldResult> fieldLabelMap = new Map<String, Schema.DescribeFieldResult>();
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap();
            for(Schema.SObjectField sfield : fieldMap.Values()){
                Schema.DescribeFieldResult dfield = sfield.getDescribe();
                //String type = String.valueOf(dfield.getType());
                fieldLabels.add(dfield.getLabel());
                fieldLabelMap.put(dfield.getLabel(), sfield.getDescribe());
                /*    FieldInfo fieldInfo = new FieldInfo();
fieldInfo.label = dfield.getLabel();
fieldInfo.apiName = dfield.getName();
fieldInfo.type = type;
fieldNames.add(fieldInfo);
*/
            }
            fieldLabels.sort();
            for(String str : fieldLabels){
                if(fieldLabelMap.containsKey(str)){
                    Schema.DescribeFieldResult dfield = fieldLabelMap.get(str);
                    String type = String.valueOf(dfield.getType());
                    FieldInfo fieldInfo = new FieldInfo();
                    fieldInfo.label = dfield.getLabel();
                    fieldInfo.apiName = dfield.getName();
                    fieldInfo.type = type;
                    fieldNames.add(fieldInfo);
                }
            }
            //  fieldLabels.sort();
            return fieldNames;
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will Give us all fields Details of Layouts for an Object
*/
    @AuraEnabled
    public static List<LayoutData> getLayoutFields(String objectName, List<String> layoutNames){
        List<LayoutData> allLayoutData = new List<LayoutData>();
        
        // Check if layoutNames is null or empty
        if(layoutNames == null || layoutNames.isEmpty()){
            System.debug('No layout names provided for object: ' + objectName);
            return allLayoutData;
        }
        
        for(String layout: layoutNames){
            LayoutData oneLayoutData = new LayoutData();
            oneLayoutData.layoutName = layout;
            String prefix = objectMapWithNameSpace.get(objectName) != null ? objectMapWithNameSpace.get(objectName) : '';
            String layoutName = String.format('{0}-{1}', new String[]{objectName, prefix + layout}); 
            
            try {
                List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String>{layoutName});
                
                // Check if layouts list is empty before accessing index 0
                if(layouts == null || layouts.isEmpty()){
                    System.debug('No layout metadata found for layoutName: ' + layoutName + ' for object: ' + objectName);
                    // Create empty layout data with just the layout name
                    oneLayoutData.fieldInfos = new List<String>();
                    allLayoutData.add(oneLayoutData);
                    continue;
                }
                
                //Get Only Layout Name
                List<String> fields = new List<String>();
                Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
                
                // Check if layoutSections exists
                if(layoutMd.layoutSections != null){
                    for(Metadata.LayoutSection section : layoutMd.layoutSections){
                        if(section.layoutColumns != null){
                            for(Metadata.LayoutColumn column : section.layoutColumns){
                                if(column.layoutItems != null){
                                    for(Metadata.LayoutItem item : column.layoutItems){
                                        if(item.field != null){
                                            fields.add(item.field);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                oneLayoutData.fieldInfos = fields;
            } catch(Exception e) {
                System.debug('Error retrieving layout metadata for ' + layoutName + ': ' + e.getMessage());
                // Create empty layout data in case of error
                oneLayoutData.fieldInfos = new List<String>();
            }
            
            allLayoutData.add(oneLayoutData);
        }
        return allLayoutData;
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 3
*/
    @AuraEnabled
   /* public static List<HierarchyService.HierarchyItem> fetchTableDataOption3(string selectedVal){
        List<HierarchyService.HierarchyItem> hierarchyItemList = HierarchyService.getRolesHierarchyList(selectedVal);
        system.debug('hierarchyItemList==='+hierarchyItemList);
        return hierarchyItemList;
    }*/
    
    public static List<HierarchyService.HierarchyItem> fetchTableDataOption3(string selectedVal) {
    List<HierarchyService.HierarchyItem> hierarchyItemList = HierarchyService.getRolesHierarchyList(selectedVal);
    
    // Iterate over the hierarchy items to remove dashes
    for(HierarchyService.HierarchyItem item : hierarchyItemList) {
        item.itemValue = item.itemValue.replaceAll('--', '');
    }
    
    system.debug('hierarchyItemList===' + hierarchyItemList);
    return hierarchyItemList;
}


    
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 19
*/
    /*@AuraEnabled
    public static List<ManagedPackageLicenseFutureController.ManagedPackageDetailsClass> fetchTableDataOption19(){
         SA_Audit__OWD_Sharing_Report__c owdSharingReport = [SELECT Id, SA_Audit__Type__c, SA_Audit__Managed_Package_License_Datails__c
                                                            FROM SA_Audit__OWD_Sharing_Report__c
                                                            WHERE SA_Audit__Type__c = 'ManagedPackaged' 
                                                            ORDER BY CreatedDate DESC LIMIT 1]; 
        List<ManagedPackageLicenseFutureController.ManagedPackageDetailsClass> finalList =  (List<ManagedPackageLicenseFutureController.ManagedPackageDetailsClass>)
            System.JSON.deserialize(owdSharingReport.SA_Audit__Managed_Package_License_Datails__c,  
            List<ManagedPackageLicenseFutureController.ManagedPackageDetailsClass>.class);
        return finalList;
    }*/
    @AuraEnabled
public static List<ManagedPackageLicenseFutureController.ManagedPackageDetailsClass> fetchTableDataOption19() {
    // Call the method to fetch managed package details
    ManagedPackageLicenseFutureController.getManagedPackageDetails();
    
    // Query the SA_Audit__OWD_Sharing_Report__c record to retrieve the data
    SA_Audit__OWD_Sharing_Report__c owdSharingReport = [
        SELECT Id, SA_Audit__Type__c, SA_Audit__Managed_Package_License_Datails__c
        FROM SA_Audit__OWD_Sharing_Report__c
        WHERE SA_Audit__Type__c = 'ManagedPackaged' 
        ORDER BY CreatedDate DESC LIMIT 1
    ]; 
    
    // Deserialize the JSON data into a list of ManagedPackageDetailsClass objects
    List<ManagedPackageLicenseFutureController.ManagedPackageDetailsClass> finalList = 
        (List<ManagedPackageLicenseFutureController.ManagedPackageDetailsClass>)
        JSON.deserialize(owdSharingReport.SA_Audit__Managed_Package_License_Datails__c,  
        List<ManagedPackageLicenseFutureController.ManagedPackageDetailsClass>.class);
    
    return finalList;
}

    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 7
*/
    @AuraEnabled
    public static List<HierarchyService.HierarchyItem> fetchTableDataOption7(){
        Type objName = Type.forName('','Territory');
        List<HierarchyService.HierarchyItem> hierarchyItemList;
        if(objName != null){
            hierarchyItemList = HierarchyService.getOldTerritoriesHierarchyList();
        }
        else{
            hierarchyItemList = HierarchyService.getTerritoriesHierarchyList();
        }
        return hierarchyItemList;
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 8
*/
    @AuraEnabled
    public static List<HierarchyService.ParentChildren> fetchTableDataOption8(){
        Type objName = Type.forName('','Territory');
        List<HierarchyService.ParentChildren> parentChildren;
        if(objName != null){
            parentChildren = HierarchyService.getOldParentChildrenList(HierarchyService.getOldUserTerritoryList(),'User');
        }
        else{
            parentChildren = HierarchyService.getParentChildrenList(HierarchyService.getUserTerritoryList(), 'User');
        }
        return parentChildren;
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 14
*/
    @AuraEnabled
    public static String fetchTableDataOption14(){
        SA_Audit__OWD_Sharing_Report__c objData = [SELECT Id, SA_Audit__OWD_Data_Field__c, SA_Audit__Sharing_Rules_Details__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'OWDReport' ORDER BY CreatedDate DESC LIMIT 1];
        //List<OrgWideDefaultsController.OWDData> owdListData = (List<OrgWideDefaultsController.OWDData>)System.JSON.deserialize(objData.OWD_Data_Field__c, List<OrgWideDefaultsController.OWDData>.class);
        return objData.SA_Audit__OWD_Data_Field__c;
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will check the Progress of the Batch
*/
    @AuraEnabled
    public static String checkBatchApexProgress(String jobId){
        AsyncApexJob job = [SELECT JobItemsProcessed, TotalJobItems, Status FROM AsyncApexJob WHERE Id =: jobId];
        String message;
        system.debug('testing jobId'+jobId);
        if(job.Status == 'Queued' || job.Status == 'Holding' || job.Status == 'Preparing'){
            message = 'We are in the ' + job.Status.toLowerCase() + ' status...' + 'We are processing this report to see the latest status press View Data/Export to Excel button again.';
        } 
        else if(job.Status != 'Completed' && job.Status != 'Aborted'){
            message = 'We are in ' + job.Status.toLowerCase() + ' status: ' + Math.floor(100.0 * job.JobItemsProcessed/job.TotalJobItems) + '%...' + 'We are processing this report to see the latest status press View Data/Export to Excel button again.';
        } 
        else if(job.Status == 'Completed'){
            message = 'Completed';
        }
        return message;
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 1
*/
    @AuraEnabled
    public static List<List<FolderShareExcelController.Folder>> fetchTableDataOption1(String jobId){
        List<List<FolderShareExcelController.Folder>> allFolderList = new List<List<FolderShareExcelController.Folder>>();
        List<SA_Audit__Helper__c> helperList = new List<SA_Audit__Helper__c>([SELECT Id, SA_Audit__ResultBody_1__c, SA_Audit__ResultBody_2__c, SA_Audit__ResultBody_3__c, SA_Audit__ResultBody_4__c, SA_Audit__ResultBody_5__c,
                                                                              SA_Audit__ResultBody_6__c, SA_Audit__ResultBody_7__c, SA_Audit__ResultBody_8__c, SA_Audit__ResultBody_9__c, SA_Audit__ResultBody_10__c,
                                                                              SA_Audit__ResultBody_11__c, SA_Audit__ResultBody_12__c, SA_Audit__ResultBody_13__c, SA_Audit__ResultBody_14__c, SA_Audit__ResultBody_15__c,
                                                                              SA_Audit__ResultBody_16__c, SA_Audit__ResultBody_17__c, SA_Audit__ResultBody_18__c, SA_Audit__ResultBody_19__c, SA_Audit__ResultBody_20__c FROM SA_Audit__Helper__c WHERE SA_Audit__JobId__c =: jobId LIMIT 1]);
        system.debug('testing helperList=='+helperList);
        List<FolderShareExcelController.Folder> foldersList = new List<FolderShareExcelController.Folder>();
        FolderShareExcelController.Folder f;
        String reportBody;
        for(Integer i = 1; i <= 20; i++){
            reportBody = helperList != null && helperList.size() > 0 ? (String) helperList[0].get('SA_Audit__ResultBody_' + i + '__c') : null;
            if(reportBody != null){
                List<String> recs = reportBody.split('/n');
                for(String rec : recs){
                    String [] fields = rec.split('~#~');
                    f = new FolderShareExcelController.Folder();
                    f.name = fields[0];
                    f.accessType = fields[1];
                    f.shareType = fields[2];
                    f.sharedWith = fields[3];
                    foldersList.add(f);
                }
            }    
        }
        Integer i = 0;
        allFolderList = new List<List<FolderShareExcelController.Folder>>();
        List<FolderShareExcelController.Folder> tempFolder = new List<FolderShareExcelController.Folder>();
        for(FolderShareExcelController.Folder fol : foldersList){
            if(i < 1000){                
                tempFolder.add(fol);
                i++;
            } 
            else{
                allFolderList.add(tempFolder);
                i = 1;
                tempFolder = new List<FolderShareExcelController.Folder>();
                tempFolder.add(fol);
            }
        }
        if(tempFolder.size() > 0){
            allFolderList.add(tempFolder);
        } 
        return allFolderList;
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 11
*/
    @AuraEnabled
    public static List<InstalledPackagesReportExcelController.InstalledPackageFinal> fetchTableDataOption11(String jobId){
        List<InstalledPackagesReportExcelController.InstalledPackageFinal> packageList = new List<InstalledPackagesReportExcelController.InstalledPackageFinal>();
        List<SA_Audit__Helper__c> helperList = new List<SA_Audit__Helper__c>([SELECT Id, SA_Audit__ResultBody_1__c, SA_Audit__ResultBody_2__c, SA_Audit__ResultBody_3__c, SA_Audit__ResultBody_4__c, SA_Audit__ResultBody_5__c,
                                                                              SA_Audit__ResultBody_6__c, SA_Audit__ResultBody_7__c, SA_Audit__ResultBody_8__c, SA_Audit__ResultBody_9__c, SA_Audit__ResultBody_10__c,
                                                                              SA_Audit__ResultBody_11__c, SA_Audit__ResultBody_12__c, SA_Audit__ResultBody_13__c, SA_Audit__ResultBody_14__c, SA_Audit__ResultBody_15__c,
                                                                              SA_Audit__ResultBody_16__c, SA_Audit__ResultBody_17__c, SA_Audit__ResultBody_18__c, SA_Audit__ResultBody_19__c, SA_Audit__ResultBody_20__c FROM SA_Audit__Helper__c WHERE SA_Audit__JobId__c =: jobId LIMIT 1]);
        String reportBody = '';
        for(Integer i = 1; i <= 20; i++){
            reportBody += helperList != null && helperList.size() > 0 ? (String) helperList[0].get('SA_Audit__ResultBody_'+ i +'__c') : null;
            system.debug('testing reportBody inside for'+ reportBody);
        }
        system.debug('testing reportBody'+ reportBody);
        List<InstalledPackagesReportBatch.InstalledPackage> ipList = (List<InstalledPackagesReportBatch.InstalledPackage>)JSON.deserialize(reportBody, List<InstalledPackagesReportBatch.InstalledPackage>.class);
        Map<String, List<PackageLicense>> match = new Map<String, List<PackageLicense>>();
        Map<String, InstalledPackagesReportBatch.InstalledPackage> matchSelect = new Map<String, InstalledPackagesReportBatch.InstalledPackage>();        
        for(InstalledPackagesReportBatch.InstalledPackage ipf : ipList){
            matchSelect.put(ipf.nameSpacePrefix, ipf); 
        }
        for(PackageLicense pl : [SELECT NamespacePrefix, Status, AllowedLicenses, UsedLicenses, CreatedDate, LastModifiedDate, ExpirationDate FROM PackageLicense LIMIT 2000]){
            packageList.add(new InstalledPackagesReportExcelController.InstalledPackageFinal(matchSelect.get(pl.NamespacePrefix), pl));
        }
        system.debug('testing packageList'+ packageList);
        return packageList;
        
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 2
*/
    @AuraEnabled
    public static List<List<FolderShareExcelController.Folder>> fetchTableDataOption2(String jobId){
        List<List<FolderShareExcelController.Folder>> allFolderList = new List<List<FolderShareExcelController.Folder>>();
        List<SA_Audit__Helper__c> helperList = new List<SA_Audit__Helper__c>([SELECT Id, SA_Audit__ResultBody_1__c, SA_Audit__ResultBody_2__c, SA_Audit__ResultBody_3__c, SA_Audit__ResultBody_4__c, SA_Audit__ResultBody_5__c,
                                                                              SA_Audit__ResultBody_6__c, SA_Audit__ResultBody_7__c, SA_Audit__ResultBody_8__c, SA_Audit__ResultBody_9__c, SA_Audit__ResultBody_10__c,
                                                                              SA_Audit__ResultBody_11__c, SA_Audit__ResultBody_12__c, SA_Audit__ResultBody_13__c, SA_Audit__ResultBody_14__c, SA_Audit__ResultBody_15__c,
                                                                              SA_Audit__ResultBody_16__c, SA_Audit__ResultBody_17__c, SA_Audit__ResultBody_18__c, SA_Audit__ResultBody_19__c, SA_Audit__ResultBody_20__c FROM SA_Audit__Helper__c WHERE SA_Audit__JobId__c =: jobId LIMIT 1]);
        List<FolderShareExcelController.Folder> foldersList = new List<FolderShareExcelController.Folder>();
        FolderShareExcelController.Folder f;
        String reportBody;
        for(Integer i = 1; i <= 20; i++){
            reportBody = helperList != null && helperList.size() > 0 ? (String) helperList[0].get('SA_Audit__ResultBody_' + i + '__c') : null;
            if(reportBody != null){
                List<String> recs = reportBody.split('/n');
                for(String rec : recs){
                    String [] fields = rec.split('~#~');
                    f = new FolderShareExcelController.Folder();
                    f.name = fields[0];
                    f.accessType = fields[1];
                    f.shareType = fields[2];
                    f.sharedWith = fields[3];
                    foldersList.add(f);
                }
            }    
        }
        Integer i = 0;
        allFolderList = new List<List<FolderShareExcelController.Folder>>();
        List<FolderShareExcelController.Folder> tempFolder = new List<FolderShareExcelController.Folder>();
        for(FolderShareExcelController.Folder fol : foldersList){
            if(i < 1000){                
                tempFolder.add(fol);
                i++;
            } 
            else{
                allFolderList.add(tempFolder);
                i = 1;
                tempFolder = new List<FolderShareExcelController.Folder>();
                tempFolder.add(fol);
            }
        }
        if(tempFolder.size() > 0){
            allFolderList.add(tempFolder);
        } 
        return allFolderList;
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch all the Job Ids of Batch Apex 
*/
    @AuraEnabled
    public static List<Id> getBatchApexJOBIds(){
        String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm();
        List<Id> listOfIDs = new List<Id>();
        String firstJobId = Database.executeBatch(new InstalledPackagesReportBatch(sfdcURL), 10);
         List<Folder> folderList = [SELECT Id, Name, Type FROM Folder WHERE Type = 'Report'];
        try{
            if(folderList.size() > 0){
                String secondJobId = Database.executeBatch(new ReportFolderBatch('Report', sfdcURL),10);
                listOfIDs.add(secondJobId);
            }
            List<Folder> secondFolderList = [SELECT Id, Name, Type FROM Folder WHERE Type = 'Dashboard'];
            // if(secondFolderList.size() > 0){
            String thirdJobId = Database.executeBatch(new ReportFolderBatch('Dashboard', sfdcURL),10);
            listOfIDs.add(thirdJobId);
            // }
        }catch(Exception  e){
            string error  = e.getMessage();
            if(error != null){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please Try Again ,Batch Is In Process!!.');
                ApexPages.addMessage(myMsg);
            }
            
        } 
        String forthJobId = Database.executeBatch(new ValidationRulesBatch(), 10);
        String fifthJobId = Database.executeBatch(new ListViewBatchApex(), 20);
        listOfIDs.add(firstJobId);
        listOfIDs.add(forthJobId);
        listOfIDs.add(fifthJobId);
        
        return listOfIDs;
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 16
*/
    @AuraEnabled
    public static List<ProfilesWithNoUserDetails.WrapperData> fetchTableDataOption16(){
        List<ProfilesWithNoUserDetails.WrapperData> wrapperDataList = new List<ProfilesWithNoUserDetails.WrapperData>();
        wrapperDataList = ProfilesWithNoUserDetails.getProfilesData();
        return wrapperDataList;
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 17
*/
    @AuraEnabled
    public static ApexTriggerAndApexClassController.WrapperData fetchTableDataOption17(){
        ApexTriggerAndApexClassController.WrapperData finalWrapperData = new ApexTriggerAndApexClassController.WrapperData();
        finalWrapperData = ApexTriggerAndApexClassController.getApexTriggersAndApexClassDetails();
        return finalWrapperData;
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 18
*/
    @AuraEnabled
    public static List<PublicGroupController.WrapperData> fetchTableDataOption18(){
        List<PublicGroupController.WrapperData> finalWrapperData = PublicGroupController.getPublicGroupDetails();
        return finalWrapperData;
    }
    // Tejas
    @AuraEnabled
    public static List<PublicGroupController.WrapperData> fetchTableDataOption27(){
        List<PublicGroupController.WrapperData> finalWrapperData = PublicGroupController.getPublicGroupMembersDetails();
        return finalWrapperData;
    }//Tejas
    
    
    
    /*
Author  : Tejas kshirsagar
Purpose : Below method will fetch Table Data for Option 28
*/  
    @AuraEnabled
    public static List<profileconfig.WrapperAllData> fetchTableDataOption28(List<string> Selectedpro){ 
        
        List<profileconfig.WrapperAllData> finalWrapper = profileconfig.getTabSettings(Selectedpro); 
        system.debug('------finalWrapper--'+finalWrapper);
        return finalWrapper; 
    }
    
    
    
    /*
Author  :Roopal
Purpose : Below Method will Give Us User access data Based on user API Name 
*/
    @AuraEnabled
    public static UserAccessCompareController.UserWrapper fetchTableDataOption37(List<string> SelectedUsers){
        UserAccessCompareController.UserWrapper UserWrapper = UserAccessCompareController.getUserBooleanFieldData(SelectedUsers); 
        system.debug('------UserWrapper--'+UserWrapper);
        return UserWrapper; 
        
        
    }
    
  /* @AuraEnabled
public static List<UserAccessCompareController.UserWrapper> fetchTableDataOption37(List<String> SelectedUsers) {
    // Directly call the static method without 'new'
    List<UserAccessCompareController.UserWrapper> UserWrapper = UserAccessCompareController.getUserBooleanFieldData(SelectedUsers); 
    system.debug('------UserWrapper--' + UserWrapper);
    return UserWrapper;
}*/
    
    
       /*
Author  : tj
Purpose : Below method will fetch Table Data for Option 30 excel

     @AuraEnabled
    public static List<UserPermissionSetgroupAccessExcel.PermissionSetWrapper> fetchUserPermissionDataExcel(){
        List<UserPermissionSetgroupAccessExcel.PermissionSetWrapper> PermissionwrapperDataList = new List<UserPermissionSetgroupAccessExcel.PermissionSetWrapper>();
    return PermissionwrapperDataList;
    }*/
    @AuraEnabled
public static List<UserPermissionSetgroupAccessExcel.PermissionSetWrapper> fetchUserPermissionDataExcel() {
    List<UserPermissionSetgroupAccessExcel.PermissionSetWrapper> wrapperDataList = new List<UserPermissionSetgroupAccessExcel.PermissionSetWrapper>();

    for (SA_Audit__IntelUserPermissionData__c customRecord : [SELECT SA_Audit__UserId__c, SA_Audit__UserNam__c, SA_Audit__UserEmail__c, SA_Audit__AssignedPermission__c, SA_Audit__PermissionSetGroups__c FROM SA_Audit__IntelUserPermissionData__c  LIMIT 30000]) {
        UserPermissionSetgroupAccessExcel.PermissionSetWrapper wrapper = new UserPermissionSetgroupAccessExcel.PermissionSetWrapper();
        wrapper.UserId = customRecord.SA_Audit__UserId__c;
        wrapper.UserNam = customRecord.SA_Audit__UserNam__c;
        wrapper.UserEmail = customRecord.SA_Audit__UserEmail__c;
        wrapper.AssignedPermission = customRecord.SA_Audit__AssignedPermission__c;
        wrapper.PermissionSetGroups = customRecord.SA_Audit__PermissionSetGroups__c;
        wrapperDataList.add(wrapper);
    }
    return wrapperDataList;
}

    
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 15
*/
    @AuraEnabled
    public static List<PermissionSetsWithNoUsersBatchApex.WrapperData> fetchTableDataOption15(){
        SA_Audit__BatchApexStatus__c customSettingRecord = SA_Audit__BatchApexStatus__c.getValues('PermissionSet');
        List<PermissionSetsWithNoUsersBatchApex.WrapperData> wrapperDataList = new List<PermissionSetsWithNoUsersBatchApex.WrapperData>();
        if(customSettingRecord != null){
            //if(Schema.sObjectType.customSettingRecord.isUpdatable()){
            if(!customSettingRecord.SA_Audit__Is_Batch_Apex_Executed__c){
                String permissionSetBatchApexId = Database.executeBatch(new PermissionSetsWithNoUsersBatchApex(), 10);
                
                if(Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.SA_Audit__Batch_Apex_Id__c.isCreateable() &&
                   Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.SA_Audit__Batch_Apex_Id__c.isUpdateable() &&
                   Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.SA_Audit__Is_Batch_Apex_Executed__c.isCreateable() &&
                   Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.SA_Audit__Is_Batch_Apex_Executed__c.isUpdateable()){
                       
                       customSettingRecord.SA_Audit__Batch_Apex_Id__c = permissionSetBatchApexId;
                       customSettingRecord.SA_Audit__Is_Batch_Apex_Executed__c = true; 
                       update  customSettingRecord;
                   }
            }
            // }
            else{
                AsyncApexJob job = [SELECT JobItemsProcessed, TotalJobItems, Status FROM AsyncApexJob WHERE Id =: customSettingRecord.SA_Audit__Batch_Apex_Id__c];
                if(job.Status != 'Completed'){
                    String errorMessage = 'We are in the ' + job.Status.toLowerCase() + ' status...' + 'We are processing this report to see the latest status press View Data/Export to Excel button again.';
       
                    throw new AuraHandledException(errorMessage);
                }
                else{
                    if(Schema.sObjectType.SA_Audit__OWD_Sharing_Report__c.isAccessible() && Schema.sObjectType.Attachment.isAccessible()){
                        SA_Audit__OWD_Sharing_Report__c objData = [SELECT Id, SA_Audit__OWD_Data_Field__c, SA_Audit__Sharing_Rules_Details__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'PermissionSet' ORDER BY CreatedDate DESC LIMIT 1];
                        Attachment attach = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE ParentId =: objData.Id LIMIT 1];
                        wrapperDataList = (List<PermissionSetsWithNoUsersBatchApex.WrapperData>)System.JSON.deserialize(attach.Body.toString(), List<PermissionSetsWithNoUsersBatchApex.WrapperData>.class);
                    }
                }
            }
        }
        else if(Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.SA_Audit__Batch_Apex_Id__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__BatchApexStatus__c.fields.Name.isCreateable()){
                    system.debug('customSettingRecord');
                    customSettingRecord = new SA_Audit__BatchApexStatus__c();
                    customSettingRecord.Name = 'PermissionSet';
                    insert customSettingRecord;
                }
        system.debug('wrapperDataList=='+wrapperDataList);
        return wrapperDataList; 
        
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 13
*/
    @AuraEnabled
    public static List<SharingSettingsFutureController.SharingRulesData> fetchTableDataOption13(){
         List<SharingSettingsFutureController.SharingRulesData> sharingRuleFinalList = new List<SharingSettingsFutureController.SharingRulesData>();
        try {
            SA_Audit__OWD_Sharing_Report__c objData = [SELECT Id, SA_Audit__OWD_Data_Field__c, SA_Audit__Sharing_Rules_Details__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'OWDReport' ORDER BY CreatedDate DESC LIMIT 1];
            system.debug('^^^objDAta' + objData);
            
            String fieldData = objData.SA_Audit__Sharing_Rules_Details__c;
            Integer flag = 3;
            while((fieldData != null) && (flag > 0)){
                List<String> secondPartList = new List<String>();
                SharingSettingsFutureController.SharingRulesData sharingRulesOneRecord = new SharingSettingsFutureController.SharingRulesData();
                String firstPart = fieldData.substringBetween('PerObjectRelatedDataStarts', 'PerObjectRelatedDataENDs');
                fieldData = fieldData.substringAfter('PerObjectRelatedDataENDs');
                flag = fieldData.trim().length();
                system.debug('^^^firstpart=='+ firstPart + 'fieldData' + fieldData+ 'flag'+ flag );
                //Below String will store the Object Name
                String secondPart = firstPart.substringBetween('ObjectNameStarts', 'ObjectNameEnds');
                secondPartList.add(secondPart);
                system.debug('^^^Secondpart'+ secondPart);
                firstPart = firstPart.substringAfter('ObjectNameEnds');
                String thirdPart = firstPart.substringBetween('HeaderDataStarts', 'HeaderDataEnds');
                firstPart = firstPart.substringAfter('HeaderDataEnds');
                //Below List will Store the Header Part
                List<String> headerPart = thirdPart.split('\\++');
                headerPart.remove(headerPart.size() - 1);
                //Below List of List will Store the Body Part
                List<List<String>> bodyPartData = new List<List<String>>();
                String forthPart = firstPart.substringBetween('LeftDataStarts', 'LeftDataEnds');
                //firstPart = firstPart.substringAfter('BodyDataStarts');
                Integer flagSecond = 3;
                List<String> anotherList = new List<String>();
                while((forthPart != null) && (flagSecond > 0)){
                    String fifthString = forthPart.substringBetween('BodyDataStarts', 'BodyDataEnds');
                    if(fifthString != null){
                        anotherList = fifthString.split('\\?');  
                        anotherList.remove(anotherList.size() - 1);
                        forthPart = forthPart.substringAfter('BodyDataEnds');
                        flagSecond = forthPart.trim().length();
                        bodyPartData.add(anotherList);
                    }
                    else{
                        break;
                    }
                }
                for(Integer k = 0; k < (anotherList.size() - 1); k++){
                    secondPartList.add('');
                }
                sharingRulesOneRecord.sharingRuleObjectName = secondPartList;
                sharingRulesOneRecord.headerData = headerPart;
                sharingRulesOneRecord.bodyData = bodyPartData;
                //headerPart.clear();
                //bodyPartData.clear();
                if(sharingRulesOneRecord.bodyData != null && sharingRulesOneRecord.headerData !=null && sharingRulesOneRecord.bodyData.size() != 0 && sharingRulesOneRecord.headerData.size() != 0){
                    sharingRuleFinalList.add(sharingRulesOneRecord);
                    
                }
                system.debug('sharingRuleFinalList'+sharingRuleFinalList);
            }
        } catch (QueryException e) {
            // Handle the case where no records are returned by the query
            System.debug('No records found for SA_Audit__OWD_Sharing_Report__c');
        }
        return sharingRuleFinalList;
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will call the Future method to get the OWD Data
*/
    @AuraEnabled
    public static void fetchOWDRelatedData(){
        SharingSettingsFutureController.getOWDDetails();
    }
    /*
Author  : Tj
Purpose : Below method will sync the data for Permission set ,fitlred Report and Schedule report Data.
*/
    
    @AuraEnabled
    public static void fetchDeleteRecords(){
        DeletePermissionSetRecords.DeleteRecords();
    }   
    
    
    
    
    
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 9*/

    @AuraEnabled
    public static ListWrapper fetchTableDataOption9(Integer pageNumber, Integer pageSize) {
        List<HierarchyService.ParentChildren> parentChildren = HierarchyService.getParentChildrenList(
            HierarchyService.getActiveUserPermission(pageNumber, pageSize), 'Assignee');
        Integer total = [SELECT COUNT() FROM PermissionSetAssignment WHERE Assignee.IsActive = true AND (NOT PermissionSet.Name LIKE 'X00%')];
        return new ListWrapper(parentChildren, total);
    }
     @AuraEnabled
    public static ListWrapper fetchTableDataOption31(Integer pageNumber, Integer pageSize) {
        List<HierarchyService.ParentChildren> parentChildren = HierarchyService.getParentChildrenList(
            HierarchyService.getInActiveUserPermission(pageNumber, pageSize), 'Assignee');
        Integer total = [SELECT COUNT() FROM PermissionSetAssignment WHERE Assignee.IsActive = false AND (NOT PermissionSet.Name LIKE 'X00%')];
        return new ListWrapper(parentChildren, total);
    }

    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 10
    @AuraEnabled
    public static ListWrapper fetchTableDataOption10(Integer pageNumber, Integer pageSize) {
        List<HierarchyService.ParentChildren> parentChildren = HierarchyService.getParentChildrenList(
            HierarchyService.getUserPermissionSetList1( pageNumber, pageSize), 'PermissionSet'
        );
        Integer total = [SELECT COUNT() FROM PermissionSetAssignment WHERE NOT PermissionSet.Name LIKE 'X00%'];
        return new ListWrapper(parentChildren, total);
    }*/
    public class ListWrapper {
        @AuraEnabled public List<HierarchyService.ParentChildren> data;
        @AuraEnabled public Integer totalRecords;
        
        public ListWrapper(List<HierarchyService.ParentChildren> data, Integer totalRecords) {
            this.data = data;
            this.totalRecords = totalRecords;
        }
    }
    @AuraEnabled
public static List<PermissionSetAssignment> fetchTableDataOption10(Integer pageNumber, Integer pageSize) {
    try {
        // Validate input parameters
        if (pageNumber < 1 || pageSize < 1) {
            throw new AuraHandledException('Invalid pageNumber or pageSize.');
        }

        // Calculate the offset for pagination
        Integer offset = (pageNumber - 1) * pageSize;

        // Query the PermissionSetAssignment records directly
        return [SELECT Id, Assignee.Profile.Name, Assignee.UserRole.Name, AssigneeId, Assignee.Name, Assignee.Title, Assignee.Department, Assignee.LastLoginDate, PermissionSetId, PermissionSet.Name, PermissionSet.Label, PermissionSet.License.Name, PermissionSet.IsCustom 
                FROM PermissionSetAssignment 
                WHERE Assignee.IsActive = true AND (NOT PermissionSet.Name LIKE 'X00%') 
                LIMIT :pageSize OFFSET :offset];
    } catch (Exception e) {
        // Log the error and throw an AuraHandledException
        System.debug('Error in fetchTableDataOption10: ' + e.getMessage());
        throw new AuraHandledException('Error fetching data: ' + e.getMessage());
    }
}
 
   /* @AuraEnabled
    public static UserWrapper fetchTableDataOption4(Integer pageNumber, Integer pageSize) {
        system.debug('pageNumber='+pageNumber);
         system.debug('pageSize='+pageSize);
        
       Integer offset = (pageNumber - 1) * pageSize;
       List<User> userRoles =  [SELECT id,Name, UserRoleId, UserRole.Name, LastLoginDate FROM User WHERE IsActive = true LIMIT :pageSize OFFSET :offset];
        system.debug('userRoles='+userRoles);
        Integer total = [SELECT COUNT() FROM User WHERE IsActive = true ];
        return new UserWrapper(userRoles, total);
    } */
    @AuraEnabled
    public static UserWrapper2 fetchTableDataOption4(Integer pageNumber, Integer pageSize) {
        Integer offset = (pageNumber - 1) * pageSize;
        List<User> userRoles = [SELECT Id, Name, UserRoleId, UserRole.Name, LastLoginDate 
                                FROM User 
                                WHERE IsActive = true 
                                LIMIT :pageSize OFFSET :offset];
        Integer total = [SELECT COUNT() FROM User WHERE IsActive = true];
        
        List<UserSanitized> sanitizedList = new List<UserSanitized>();
        for (User usr : userRoles) {
            sanitizedList.add(new UserSanitized(
                usr.Id, 
                sanitizeString(usr.Name), 
                null, // Email not fetched in this query
                true, // IsActive assumed to be true based on query
                null, // Manager not fetched in this query
                usr.UserRole != null ? sanitizeString(usr.UserRole.Name) : null, 
                usr.UserRoleId,
                null, // UserLicenseCustom not applicable here
                null, // Profile not fetched in this query
                usr.LastLoginDate
            ));
        }
        return new UserWrapper2(sanitizedList, total);
    }

    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 5

    @AuraEnabled
    public static UserWrapper fetchTableDataOption5(Integer pageNumber, Integer pageSize){
          Integer offset = (pageNumber - 1) * pageSize;
    List<User> userProfile =  [SELECT id,Name, IsActive, Manager.Name, UserRole.Name, UserRole.Id, Profile.Name, LastLoginDate From User WHERE IsActive = true LIMIT :pageSize OFFSET :offset]; 
         Integer total = [SELECT COUNT() FROM User WHERE IsActive = true ];
        return new UserWrapper(userProfile, total);
    }*/
    @AuraEnabled
    public static UserWrapper2 fetchTableDataOption5(Integer pageNumber, Integer pageSize) {
        Integer offset = (pageNumber - 1) * pageSize;
        List<User> userProfile = [SELECT Id, Name, IsActive, Manager.Name, UserRole.Name, UserRole.Id, Profile.Name, LastLoginDate 
                                  FROM User 
                                  WHERE IsActive = true 
                                  LIMIT :pageSize OFFSET :offset];
        Integer total = [SELECT COUNT() FROM User WHERE IsActive = true];
        
        List<UserSanitized> sanitizedList = new List<UserSanitized>();
        for (User usr : userProfile) {
            sanitizedList.add(new UserSanitized(
                usr.Id, 
                sanitizeString(usr.Name), 
                null, // Email not fetched in this query
                usr.IsActive, 
                usr.Manager != null ? sanitizeString(usr.Manager.Name) : null,
                usr.UserRole != null ? sanitizeString(usr.UserRole.Name) : null, 
                usr.UserRole.Id,
                null, // UserLicenseCustom not applicable here
                usr.Profile != null ? sanitizeString(usr.Profile.Name) : null,
                usr.LastLoginDate
            ));
        }
        return new UserWrapper2(sanitizedList, total);
    }

    
/*
Author  : Pradeep
Purpose : Below method will Give us the Assigned User License report 

    @AuraEnabled
    public static UserWrapper fetchTableDataOption29(Integer pageNumber, Integer pageSize){
        try {
        Integer offset = (pageNumber - 1) * pageSize; 
        List<User> usrList = [SELECT Id, Name, Email, IsActive, SA_Audit__User_License_Custom__c, Profile.Name 
                              FROM User 
                              WHERE SA_Audit__User_License_Custom__c != null 
                              ORDER BY Name ASC 
                              LIMIT :pageSize OFFSET :offset];
         
        Integer total = [SELECT COUNT() FROM User WHERE SA_Audit__User_License_Custom__c != null];
        return new UserWrapper(usrList, total);
    } catch (Exception e) {
        
        System.debug('Error fetching user data: ' + e.getMessage());
        throw new AuraHandledException('Error fetching user data: ' + e.getMessage());
    }
        
    } */
    public class UserWrapper {
        @AuraEnabled public List<User> dataa;
        @AuraEnabled public Integer totalRecordss;
        
        public UserWrapper(List<User> dataa, Integer totalRecordss) {
            this.dataa = dataa;
            this.totalRecordss = totalRecordss;
        }
    }
    
    @AuraEnabled
    public static UserWrapper2 fetchTableDataOption29(Integer pageNumber, Integer pageSize) {
        Integer offset = (pageNumber - 1) * pageSize;
        List<User> usrList = [SELECT Id, Name, Email, IsActive, SA_Audit__User_License_Custom__c, Profile.Name 
                              FROM User 
                              WHERE SA_Audit__User_License_Custom__c != null 
                              ORDER BY Name ASC 
                              LIMIT :pageSize OFFSET :offset];
        Integer total = [SELECT COUNT() FROM User WHERE SA_Audit__User_License_Custom__c != null];
        
        List<UserSanitized> sanitizedList = new List<UserSanitized>();
        for (User usr : usrList) {
            sanitizedList.add(new UserSanitized(
                usr.Id, 
                sanitizeString(usr.Name), 
                sanitizeString(usr.Email), 
                usr.IsActive, 
                null, // Manager not fetched in this query
                null, // UserRole not fetched in this query
                null, //userroll id not pressent
                sanitizeString(usr.SA_Audit__User_License_Custom__c), 
                usr.Profile != null ? sanitizeString(usr.Profile.Name) : null,
                null // LastLoginDate not fetched in this query
            ));
        }
        return new UserWrapper2(sanitizedList, total);
    }
    
    // Wrapper for sanitized user data
    public class UserSanitized {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String email;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String managerName;
        @AuraEnabled public String userRoleName;
        @AuraEnabled public Id UserRoleId;
        @AuraEnabled public String userLicenseCustom;
        @AuraEnabled public String profileName;
        @AuraEnabled public DateTime lastLoginDate;
        
        public UserSanitized(String id, String name, String email, Boolean isActive, 
                             String managerName, String userRoleName, Id UserRoleId,
                             String userLicenseCustom, String profileName, 
                             DateTime lastLoginDate) {
                                 this.id = id;
                                 this.name = name;
                                 this.email = email;
                                 this.isActive = isActive;
                                 this.managerName = managerName;
                                 this.userRoleName = userRoleName;
                                 this.UserRoleId = UserRoleId;
                                 this.userLicenseCustom = userLicenseCustom;
                                 this.profileName = profileName;
                                 this.lastLoginDate = lastLoginDate;
                             }
    }
    
    // Wrapper for table data
    public class UserWrapper2 {
        @AuraEnabled public List<UserSanitized> dataa;
        @AuraEnabled public Integer totalRecordss;
        
        public UserWrapper2(List<UserSanitized> dataa, Integer totalRecordss) {
            this.dataa = dataa;
            this.totalRecordss = totalRecordss;
        }
    }
    
    // Sanitize string fields to prevent XSS
    private static String sanitizeString(String input) {
        if (String.isEmpty(input)) {
            return input;
        }
        return input.replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;');
    }

    
    
    
    
    
    
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 20
*/
    @AuraEnabled
    public static List<ValidationRulesBatch.FinalClass> fetchTableDataOption20(){
        SA_Audit__OWD_Sharing_Report__c owdSharingReport = new SA_Audit__OWD_Sharing_Report__c();
        
        if(!test.isRunningTest()){
            owdSharingReport = [SELECT Id, SA_Audit__Type__c, SA_Audit__Validation_Rules_JSON__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'ValidationRules' ORDER BY CreatedDate DESC LIMIT 1];
            
        }
        Attachment attach = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE ParentId =: owdSharingReport.Id LIMIT 1];
        List<ValidationRulesBatch.FinalClass> finalList = (List<ValidationRulesBatch.FinalClass>)System.JSON.deserialize(attach.Body.toString(), List<ValidationRulesBatch.FinalClass>.class);
       system.debug('finalList='+finalList);
        return finalList;
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 21
*/
    @AuraEnabled
    public static List<DashboardClass> fetchTableDataOption21(){
        List<DashboardClass> dashboardWrapperData = new List<DashboardClass>();
        List<Dashboard> dashboardList = [SELECT Id, Title, NamespacePrefix, Description, RunningUser.Name, RunningUserId FROM Dashboard ORDER BY Title ASC LIMIT 2000];
        String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm();
        String userId = UserInfo.getUserId();
        for(Dashboard dashboardRecord: dashboardList){
            DashboardClass dashboardWrapperOneRecord = new DashboardClass();
            dashboardWrapperOneRecord.dashboardName = dashboardRecord.Title;
            dashboardWrapperOneRecord.url = sfdcURL + '/' + dashboardRecord.Id;
            if(userId != dashboardRecord.RunningUserId){
                dashboardWrapperOneRecord.setToSpecifiedUser = 'Yes';
                dashboardWrapperOneRecord.userName = dashboardRecord.RunningUser.Name;
            }
            else{
                dashboardWrapperOneRecord.setToSpecifiedUser = 'No';
            }
            dashboardWrapperData.add(dashboardWrapperOneRecord);
        }
        return dashboardWrapperData;
    }
    
    
    
    
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will execute the Batch to generate all reports and send it as zip file to Loggedin user's Email address
*/
    @AuraEnabled
    public static void batchApexExecutionToSendAnEmail(List<String> listOfIDs, List<string> selectedOption){
        system.debug('selectedOption1 ='+selectedOption);
        Database.executeBatch(new GenerateAllReports(listOfIDs,selectedOption), 100);
        system.debug('selectedOption2='+selectedOption);
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will Execute the Batch Apex to get the List Views Details for All of the Objects in the JSON format 
*/
    @AuraEnabled
    public static List<ListViewBatchApex.FinalClass> fetchTableDataOption22(){
        SA_Audit__OWD_Sharing_Report__c owdSharingReport = [SELECT Id, SA_Audit__Type__c, SA_Audit__List_View_JSON__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'ListView' ORDER BY CreatedDate DESC LIMIT 1];
        Attachment attach = [SELECT Id, Name, Body, ParentId FROM Attachment WHERE ParentId =: owdSharingReport.Id LIMIT 1];
        List<ListViewBatchApex.FinalClass> finalList = (List<ListViewBatchApex.FinalClass>)System.JSON.deserialize(attach.Body.toString(), List<ListViewBatchApex.FinalClass>.class);
        return finalList;
        /*List<FinalClass> finalDataList = new List<FinalClass>();
Integer totalListViews = [SELECT Count() FROM ListView WHERE Id != null AND SObjectType != null];
if(offsetValue > totalListViews){
offsetValue -= totalListViews;
}
List<ListView> listViewRecords = new List<ListView>();
listViewRecords = [SELECT Id, Name, DeveloperName, NamespacePrefix, SobjectType FROM ListView WHERE Id != null AND SObjectType != null ORDER BY SobjectType ASC LIMIT 90 OFFSET : offsetValue];
for(ListView listviewRecord: listViewRecords){
FinalClass finalDataOneRecord = new FinalClass();
String selectedFields = '';
String whereConditions = '';
String toolingAPIURL = '/services/data/v32.0/sobjects/' + listviewRecord.SobjectType + '/listviews/' + listviewRecord.Id + '/describe'; 
HttpResponse response = getListViewDetails(toolingAPIURL);
if(response.getStatusCode() == 200){
ListViewJSONData finalResponse = (ListViewJSONData)JSON.deserialize(response.getBody(), ListViewJSONData.class);
for(Columns firstColumnData: finalResponse.columns){
if(!firstColumnData.hidden){
selectedFields += firstColumnData.fieldNameOrPath + ', ';
}
}
finalDataOneRecord.sobjectType = finalResponse.sobjectType;
finalDataOneRecord.filterByOwner = finalResponse.scope;
if(finalDataOneRecord.filterByOwner == null){
finalDataOneRecord.filterByOwner = 'All OWD Sharing Reports';
}
else{
finalDataOneRecord.filterByOwner = 'My OWD Sharing Reports';
}
if(finalResponse.whereCondition.conditions != null){
for(Conditions oneConditionsRec : finalResponse.whereCondition.conditions){
if(oneConditionsRec.field != null && oneConditionsRec.operator != null && oneConditionsRec.values.size() > 0){
whereConditions += oneConditionsRec.field + ' ' + oneConditionsRec.operator + ' ' + oneConditionsRec.values[0] + ' ,';
}
}
}
finalDataOneRecord.viewName = listviewRecord.Name;
finalDataOneRecord.viewUniqueName = listviewRecord.DeveloperName;
finalDataOneRecord.additionalFilters = whereConditions;
finalDataOneRecord.selectedFields = selectedFields;
finalDataOneRecord.totalRecords = totalListViews;
finalDataList.add(finalDataOneRecord);
}
}
return finalDataList;*/
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will Execute the Batch Apex to get the all List View Records 
*/
    @AuraEnabled
    public static String listViewBatchExecution(){
        String listViewBatchApexId = Database.executeBatch(new ListViewBatchApex(),20);
        return listViewBatchApexId;
    }
    public class FinalClass{
        @AuraEnabled
        public String viewName { get; set; }
        @AuraEnabled
        public String sobjectType { get; set; }
        @AuraEnabled
        public String viewUniqueName { get; set; }
        @AuraEnabled
        public String filterByOwner { get; set; }
        @AuraEnabled
        public String additionalFilters { get; set; }
        @AuraEnabled
        public String selectedFields { get; set; }
        @AuraEnabled
        public Integer totalRecords { get; set; }
    } 
    public class ListViewJSONData{
        @AuraEnabled
        public List<Columns> columns { get; set; }
        @AuraEnabled
        public String scope { get; set; }
        @AuraEnabled
        public String sobjectType { get; set; }
        @AuraEnabled
        public WhereConditions whereCondition { get; set; }
    }
    public class Columns{
        @AuraEnabled
        public String fieldNameOrPath { get; set; }
        @AuraEnabled
        public Boolean hidden { get; set; }
    }
    public class WhereConditions{
        @AuraEnabled
        public List<Conditions> conditions { get; set; }
    }
    public class Conditions{
        @AuraEnabled
        public String field { get; set; }
        @AuraEnabled
        public String operator { get; set; }
        @AuraEnabled
        public List<String> values { get; set; }
    }
    
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will Execute to get the Data for ListView 
*/
    public static HttpResponse getListViewDetails(String toolingAPIURL){
        HttpRequest req = new HttpRequest();
        String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm();
        req.setEndpoint(sfdcURL + toolingAPIURL);
        req.setMethod('GET');
        req.setTimeout(120000);
        String sessionId = UserInfo.getSessionId();
     //  String sessionId =  'callout:SA_Audit__Tooling_API_Creds';
        String authorizationHeader = 'OAuth ' + sessionId;
        req.setHeader('Authorization', authorizationHeader);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res;
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will run Future method to get Managed Package Assigned Users details
*/
    @AuraEnabled
    public static void fetchManagedPackageLicenseData(){
        
        ManagedPackageLicenseFutureController.getManagedPackageDetails();
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below method will fetch Table Data for Option 10
*/
   /* @AuraEnabled
    public static List<HierarchyService.ParentChildren> fetchTableDataOption10(){
        List<HierarchyService.ParentChildren> parentChildren = HierarchyService.getParentChildrenList(HierarchyService.getUserPermissionSetList(null), 'PermissionSet');
        system.debug('=======parentChildren===>===intel==='+parentChildren.size());
        system.debug('=======parentChildren===>===intel=123=='+parentChildren);
        return parentChildren;
    }*/
    
    
    

    
    /*@AuraEnabled
    public static PermissionWrapper fetchPermissionSet1 (Integer pageNumber, Integer pageSize) {
        PermissionWrapper wrapper = new PermissionWrapper();
        wrapper.pageNumber = pageNumber;
        wrapper.pageSize = pageSize;
        
        Integer offset = (pageNumber - 1) * pageSize;
        
        List<PermissionSetAssignment> psetList = [
            SELECT Id, Assignee.Profile.Name, Assignee.UserRole.Name, AssigneeId, Assignee.Name, Assignee.LastLoginDate,
            PermissionSetId, PermissionSet.Name, PermissionSet.Label, PermissionSet.License.Name, PermissionSet.IsCustom
            FROM PermissionSetAssignment
            WHERE NOT PermissionSet.Name LIKE 'X00%'
            ORDER BY Assignee.Name
            LIMIT :pageSize
            OFFSET :offset
        ];
        
        wrapper.PsetList = psetList;
        
        // Get the total number of records
        List<AggregateResult> aggregates = [
            SELECT COUNT(Id) total
            FROM PermissionSetAssignment
            WHERE NOT PermissionSet.Name LIKE 'X00%'
        ];
        wrapper.totalRecords = (Integer)aggregates[0].get('total');
        
        wrapper.recordStart = Math.min((pageNumber - 1) * pageSize + 1, wrapper.totalRecords);
        wrapper.recordEnd = Math.min(pageNumber * pageSize, wrapper.totalRecords);
        
        return wrapper;
    }
    public class PermissionWrapper {
        @AuraEnabled
        public Integer pageSize {get;set;}
        @AuraEnabled
        public Integer pageNumber {get;set;}
        @AuraEnabled
        public Integer totalRecords {get;set;}
        @AuraEnabled
        public Integer recordStart {get;set;}
        @AuraEnabled
        public Integer recordEnd {get;set;}
        @AuraEnabled
        public List<PermissionSetAssignment> PsetList {get;set;}
    }*/

    public class Result{
        @AuraEnabled
        public List<Record> records{
            get;
            set;
        }
    }
    public class Record{
        @AuraEnabled
        public string Id{
            get;
            set;
        }
        @AuraEnabled
        public string Name{
            get;
            set;
        }
    }
    //It will Store the JSON as Custom and Standard Object Information
    public class ObjectDetails{   
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public Boolean type;
        @AuraEnabled
        public String pluralName;
        @AuraEnabled
        public String objectPrefix;   
    }
    public class ProfileData{   
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;        
        
    }
     public class UserData{   
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;        
        
    }
    
    
    //Below Wrapper Class will Store Data Related to Layouts
    public class JSONData{
        @AuraEnabled
        public String objectName{
            get;
            set;
        }
        @AuraEnabled
        public String developerName{
            get;
            set;
        }
        @AuraEnabled
        public List<LayoutData> layoutDatas{
            get;
            set;
        }
        @AuraEnabled
        public List<FieldInfo> allFieldInfos{
            get;
            set;  
        }
    }
    public class LayoutData{
        @AuraEnabled
        public String layoutName{
            get;
            set;
        }
        @AuraEnabled
        public List<String> fieldInfos{
            get;
            set;  
        }
    }
    public class FieldInfo{
        @AuraEnabled
        public string label{
            get; set;
        }
        @AuraEnabled
        public string apiName{
            get; set;
        }
        @AuraEnabled
        public string type{
            get; set;
        }
    }  
    //Below Wrapper Class will Save the Data of Store in Custom Object
    public class RefactorDataToGenerateExcel{
        @AuraEnabled
        public string objectName{
            get; set;
        }
        @AuraEnabled
        public List<List<String>> fieldInfo{
            get; set;
        }
    }
    //Below Wrapper Class will store the Data for Option 21
    public class DashboardClass{
        @AuraEnabled
        public string dashboardName{
            get; set;
        }
        @AuraEnabled
        public String url{
            get; set;
        }
        @AuraEnabled
        public String setToSpecifiedUser{
            get; set;
        }
        @AuraEnabled
        public String userName{
            get; set;
        }
    }
}