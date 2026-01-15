public with sharing class PermissionSetTabsConfig {   
public static List<WrapperOne> getTabSettings(){
    List<id> ids = new List<id>();
   List<WrapperOne> WrapData= new List<WrapperOne>();
    //Fetching App Durable Id Here...
    List<AppDefinition> TabsLabel = [ SELECT Description,DeveloperName,DurableId,Label FROM AppDefinition LIMIT 200 ];
    for(AppDefinition AD : TabsLabel){
        ids.add(AD.DurableId);
    }
    
    //Getting The Tabs Label Through The Durabl Id Here...
    for(List<AppTabMember> ab :[SELECT AppDefinitionId,SortOrder,TabDefinitionId, TabDefinition.Name,TabDefinition.Label FROM AppTabMember WHERE AppDefinition.DurableId =: ids LIMIT 200] ){ system.debug('AppTabMember=='+ ab); }
        
    List<PermissionSetTabSetting> Psets =  new List<PermissionSetTabSetting>();
    Psets =  [SELECT Visibility,name,Parent.Name  FROM PermissionSetTabSetting where NOT Parent.Name LIKE 'X00%' LIMIT 49000 ];
    //WHERE NAME==>> TABNAME & VISIBILITY==>> DEFAULT ON/OFF 
    for(PermissionSetTabSetting pp:Psets){
        //system.debug('pp== '+ pp);
        WrapperOne Wr = new WrapperOne();
        Wr.tabsName = pp.Visibility;
        Wr.tabsVisibility= pp.name;
        Wr.PermissionSetName = pp.Parent.Name;
        WrapData.add(Wr);
    }
    system.debug('WrapData=='+WrapData);
    return WrapData;
 
    }
     public class WrapperOne
     {
        @AuraEnabled
        public String tabsName {get; set;}    
        @AuraEnabled
        public String tabsVisibility {get; set;} 
          @AuraEnabled
        public String PermissionSetName {get; set;} 
    }
}


   
/*public static MetadataService.MetadataPort createService()
{ 
    MetadataService.MetadataPort service = new MetadataService.MetadataPort();
    service.SessionHeader = new MetadataService.SessionHeader_element();
    service.SessionHeader.sessionId = UserInfo.getSessionId();
    return service;     
}*/
    
    
   // MetadataService.MetadataPort service = createService();
   // MetadataService.PermissionSet admin = (MetadataService.PermissionSet) service.readMetadata('PermissionSet', new String[] { 'standard-Lead' }).getRecords()[0];
   //for(MetadataService.PermissionSetTabSetting ptv : admin.tabSettings){
     //   if(ptv != Null){
          //  system.debug('tab name = ' + ptv.tab + ' & ' + 'visibility = ' + ptv.visibility);
        //}else{
        //system.debug('Error');
   // }