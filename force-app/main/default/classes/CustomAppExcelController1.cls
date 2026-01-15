/*
Author/Modified Code By : Pradeep
*/
public with sharing class CustomAppExcelController1{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public String reportBody{ get; set; }
    @AuraEnabled
    public String jobId{ get; set; }
    //public List<HierarchyService.ParentChildren> parentChildren{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public list<ApplicationAccessWrapper> applicationAccessWrapperList { get; set; }
    
    //public list<string> allCells{ get; set; }
    public CustomAppExcelController1(){
    	 map<string, AppMenuItem> appId2Name = new map<string, AppMenuItem>();
        applicationAccessWrapperList = new list<ApplicationAccessWrapper>();
        map<string, SetupEntityAccess> setUpEntityAccessMap = new map<string, SetupEntityAccess>();
        list<Profile> profileList = [select id, Name from Profile Where Name != null];
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
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos();
     
    }
    public class ApplicationAccessWrapper{
        @auraEnabled
        public string appName{ get; set; }
        @auraEnabled
        public string profileName { get; set; }
        @auraEnabled
        public string visibility { get; set; }
        
    }
}