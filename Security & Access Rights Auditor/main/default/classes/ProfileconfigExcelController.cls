/*
Author       : Tejas Kshirsagar
Purpose      : Below Method will Give Us Data related to Profile & PermissionSets TAB Settings..
Dependencies : Called from IntelController.apxc Class
*/

public class ProfileconfigExcelController
{
    @AuraEnabled
    public static List<WrapperAllData> tabdata { get; set; }
    
    
    @AuraEnabled
    public static List<WrapperAllData> finalWrapperList { get; set; }
   
    @AuraEnabled
    public static String xmlheader{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    public ProfileconfigExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos(); 
         String Props ;
        if(!test.isRunningTest()){
             Props = ApexPages.currentPage().getParameters().get('selectedprofile');
        }else{
            Props = '["Force.com - App Subscription User","Sales Manager"]';
        }
        List<string> deserializedProps = (List<string>)JSON.deserialize(Props, List<string>.class);
        system.debug('deserializedProps==='+deserializedProps);
        getTabSettings(deserializedProps);
    }
    
    public static MetadataService.MetadataPort createService(){ 
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
         // service.endpoint_x = 'callout:SA_Audit__Tooling_API_Creds';
        return service; 
    }
    
    @AuraEnabled
public static List<WrapperAllData> getTabSettings(List<String> selectedProfiles){
   map<string, string> profileMap = new map<string, string>{'System Administrator' => 'Admin','Standard User'=> 'Standard','Standard Platform User'=>'StandardAul','High Volume Customer Portal'=>'HighVolumePortal','Solution Manager'=>'SolutionManager','Marketing User'=> 'MarketingProfile','Contract Manager'=>'ContractManager','Chatter Free User'=>'Chatter Free User','Analytics Cloud Integration User'=>'Analytics Cloud Integration User','Analytics Cloud Security User'=>'Analytics Cloud Security User','Customer Community Login User'=>'Customer Community Login User', 'Cross Org Data Proxy User'=> 'Cross Org Data Proxy User','Work.com Only User'=>'Work.com Only User','Identity User'=>'Identity User','Customer Community Plus User'=>'Customer Community Plus User','silver Partner User'=>'silver Partner User','Gold Partner User'=>'Gold Partner User','Customer Portal Manager'=>'Customer Portal Manager Standard','Force.com - App Subscription User'=>'Force.com - App Subscription User','Customer Community Plus Login User'=>'Customer Community Plus Login User','Partner App Subscription User'=>'Partner App Subscription User','External Identity User'=>'External Identity User','Partner Community Login User'=>'Partner Community Login User','Customer Community User'=>'Customer Community User','Force.com - Free User'=>'Force.com - Free User','Chatter Moderator User'=>'Chatter Moderator User','Chatter External User'=>'Chatter External User','High Volume Customer Portal User'=>'High Volume Customer Portal User','Read Only'=>'Read Only','Standard User'=>'Standard','Service Cloud'=>'ServiceCloud','Partner User'=>'Partner'};
        Set<string> standardObjectSet = new Set<string>{'Account','Authorization Form Consent','Authorization Form Platform Use','Authorization Form','Authorization Form Text','Contact Point Type Consent','Data Use Purpose','Quick Text','Asset','Campaign','Case','Contact','Contract','Credit Memo','Invoice','Lead','Location','Macro','Order','Price Book','Product','User Provisioning Request'};
     
     finalWrapperList = new List<WrapperAllData>();

    MetadataService.MetadataPort service = createService();
    service.timeout_x = 120000;

    for(String profileName : selectedProfiles){
        if(profileMap.containsKey(profileName)){
            profileName = profileMap.get(profileName);
        }

        WrapperAllData wrapper = new WrapperAllData();
        List<WrapperAllData1> tabsData = new List<WrapperAllData1>();

        try {
            MetadataService.Profile profileTabs = (MetadataService.Profile) service.readMetadata('Profile', new String[] {profileName}).getRecords()[0];

            if(profileTabs != null && profileTabs.tabVisibilities != null){
                for(MetadataService.ProfileTabVisibility ptv : profileTabs.tabVisibilities){
                    if(ptv != null && ptv.tab != null){
                        String tabName = ptv.tab;
                        List<String> tabSplit = tabName.containsIgnoreCase('standard') ? tabName.split('standard-') : new List<String>();

                        if((!tabSplit.isEmpty() && standardObjectSet.contains(tabSplit[1])) || (!tabSplit.isEmpty() && !standardObjectSet.contains(tabSplit[1]) && !tabName.containsIgnoreCase('standard')) || tabSplit.isEmpty()){
                            WrapperAllData1 tabWrapper = new WrapperAllData1();
                            tabWrapper.tabName = tabName;
                            tabWrapper.tabVisibility = ptv.visibility;
                            tabsData.add(tabWrapper);
                        }
                    }
                }
            }
        } catch(Exception e) {
            System.debug('Error processing profile ' + profileName + ': ' + e.getMessage());
            continue; // Skip to the next profile in case of an error
        }

        wrapper.ProfileNamm = profileName;
        wrapper.subvar = tabsData;
        finalWrapperList.add(wrapper);
    }
 
     
    return finalWrapperList;
}

    
    
    public class WrapperAllData{ //2nd
        @AuraEnabled
        public List<WrapperAllData1> subvar {get; set;}
        @AuraEnabled
        public String ProfileNamm {get; set;} 
        
    }
    public class WrapperAllData1{
        @AuraEnabled
        public String tabName {get; set;}    
        @AuraEnabled
        public String tabVisibility {get; set;} 
    }
}