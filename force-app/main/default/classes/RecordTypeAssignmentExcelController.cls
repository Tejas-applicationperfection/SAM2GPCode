public with sharing class RecordTypeAssignmentExcelController {
    
    @AuraEnabled 
    public List<RecordTypeWrapper> recordTypeWrapperList { get; set; }
      @AuraEnabled
    public static String xmlheader{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    
    public RecordTypeAssignmentExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos(); 
         String Props ;
        if(!test.isRunningTest()){
             Props = ApexPages.currentPage().getParameters().get('selectedprofile');
            system.debug('Props='+Props);
        }else{
            Props = '["Force.com - App Subscription User","Sales Manager"]';
        }
        List<string> deserializedProps = (List<string>)JSON.deserialize(Props, List<string>.class);
        system.debug('deserializedProps==='+deserializedProps);
          recordTypeWrapperList = RecordTypeAssignmentmeth(deserializedProps);
       // RecordTypeAssignmentmeth(deserializedProps);
    }
      
    @AuraEnabled 
    public static List<RecordTypeWrapper> RecordTypeAssignmentmeth(List<string> Selectedpro) {
        string rName ;
        system.debug('RecordTypeAssignmentmeth=='+Selectedpro);
        map<string, string> profileMap = new map<string, string>{'System Administrator' => 'Admin','Standard User'=> 'Standard','Standard Platform User'=>'StandardAul','High Volume Customer Portal'=>'HighVolumePortal','Solution Manager'=>'SolutionManager','Marketing User'=> 'MarketingProfile','Contract Manager'=>'ContractManager','Chatter Free User'=>'Chatter Free User','Analytics Cloud Integration User'=>'Analytics Cloud Integration User','Analytics Cloud Security User'=>'Analytics Cloud Security User','Customer Community Login User'=>'Customer Community Login User', 'Cross Org Data Proxy User'=> 'Cross Org Data Proxy User','Work.com Only User'=>'Work.com Only User','Identity User'=>'Identity User','Customer Community Plus User'=>'Customer Community Plus User','silver Partner User'=>'silver Partner User','Gold Partner User'=>'Gold Partner User','Customer Portal Manager'=>'Customer Portal Manager Standard','Force.com - App Subscription User'=>'Force.com - App Subscription User','Customer Community Plus Login User'=>'Customer Community Plus Login User','Partner App Subscription User'=>'Partner App Subscription User','External Identity User'=>'External Identity User','Partner Community Login User'=>'Partner Community Login User','Customer Community User'=>'Customer Community User','Force.com - Free User'=>'Force.com - Free User','Chatter Moderator User'=>'Chatter Moderator User','Chatter External User'=>'Chatter External User','High Volume Customer Portal User'=>'High Volume Customer Portal User','Read Only'=>'Read Only','Standard User'=>'Standard','Service Cloud'=>'ServiceCloud','Partner User'=>'Partner'};
        List<RecordTypeWrapper>  recordTypeWrapperList = new List<RecordTypeWrapper>();  
        if(!test.isRunningTest()){
        MetadataService.MetadataPort service = createService();  
        service.timeout_x=120000; 
        for (String pp : Selectedpro) {if (profileMap.containsKey(pp)) { pp = profileMap.get(pp);  }
                transient MetadataService.Profile profile = (MetadataService.Profile) service.readMetadata('Profile', new String[] {pp}).getRecords()[0];
                List<MetadataService.ProfileRecordTypeVisibility> profileRecordTypeList = profile.recordTypeVisibilities;
                List<String> recordTypeList = new List<String>();
                if (profile.recordTypeVisibilities != null)
                {for (MetadataService.ProfileRecordTypeVisibility rt : profile.recordTypeVisibilities) {
                    if (rt.visible != null && rt.visible) {recordTypeList.add(rt.recordType); } } }
                for (String rtName : recordTypeList) {
                    rName = rtName;
                    String objectName = rtName.substringBefore('.'); 
                    String RecordName = rtName.substringAfter('.');
                    recordTypeWrapperList.add(new RecordTypeWrapper(objectName, pp, RecordName));   }}
        }else{
                   string pp = '';
                    String objectName =''; 
                    String RecordName = '';
                    recordTypeWrapperList.add(new RecordTypeWrapper(objectName, pp, RecordName));   
        }

        return recordTypeWrapperList;
    }
    
    public static MetadataService.MetadataPort createService() { 
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
    service.SessionHeader.sessionId = UserInfo.getSessionId();
           //service.endpoint_x = 'callout:SA_Audit__Tooling_API_Creds';
        return service; }
    
    public class RecordTypeWrapper {
        @AuraEnabled 
        public string objectName { get; set; }
        @AuraEnabled 
        public string profileName { get; set; }
        @AuraEnabled 
        public string recordTypeName { get; set; }
        
        public RecordTypeWrapper(string objName, string profName, string rtName) {
            objectName = objName;
            profileName = profName;
            recordTypeName = rtName;
        }
    }

}