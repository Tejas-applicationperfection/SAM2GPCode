public with sharing class retrievePicklistValueExcelController {

    @AuraEnabled 
    public List<PicklistWrapper> picklistWrappers { get; set; }
      @AuraEnabled
    public static String xmlheader{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public List<String> objectNames{ get; set; }
    
       
    public retrievePicklistValueExcelController(){
        // picklistWrappers =  retrievePicklistValueofRecordTypes.getPicklistValuesByRecordType();
         xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos(); 
         String objects1 ;
       
             objects1 = ApexPages.currentPage().getParameters().get('selectedOptions');
            
             List<String> objectNames = objects1.split(',');
       system.debug('objects='+objectNames);
      
        picklistWrappers = getPicklistValuesByRecordType(objectNames);
    }
    public static MetadataService.MetadataPort createService() { 
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
           //service.endpoint_x = 'callout:SA_Audit__Tooling_API_Creds';
        return service; 
    }
    
    @AuraEnabled 
    public static List<PicklistWrapper> getPicklistValuesByRecordType(List<String> objectNames) {  
        system.debug('objectNames=='+objectNames);     
        List<string> rStrs = new List<string>();
        //Fetching DeveloperNames From REccordtype Object via objectNames.
        List<RecordType> recordTypes = [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE SObjectType = :objectNames];
      try {
            for (RecordType rt : recordTypes) {
                //storing ObjectName.RecordtypeName into rStrs, Ex:-SA_Audit__Account__c.SA_Audit__Mr //SELECT NamespacePrefix FROM PackageLicense/Organization  LIMIT 2000 
               
                List<Organization> namespaces = new List<Organization>([
                    SELECT NamespacePrefix FROM Organization LIMIT 1
                ]);
                
                String ObjectN = rt.SObjectType;
                String ObjectNamespacee = ObjectN.substringBefore('__');
                System.debug('obj names=='+ObjectNamespacee);
                /*List<Organization> namespaces = new List<Organization>([
                    SELECT NamespacePrefix FROM Organization LIMIT 20
                ]);*/
                
                if(ObjectNamespacee != null){
                    system.debug('NAmespace'+ObjectNamespacee);
                    if(rt.SObjectType.containsIgnoreCase('__c')){
                        //SA_Audit__OWD_Sharing_Report__c
                        string nmspc = ObjectNamespacee;
                        system.debug('nmspc='+nmspc);
                        string NamespaceLessStrt = rt.SObjectType.removeStart(nmspc);//OWD_Sharing_Report__c
                        system.debug('NamespaceLessStrt='+NamespaceLessStrt);
                        string NamespaceLessEnd = rt.SObjectType.removeEnd('__c');//OWD_Sharing_Report
                        system.debug('NamespaceLessEnd='+NamespaceLessEnd);
                        rStrs.add(NamespaceLessEnd + '__c.'+ObjectNamespacee+'__'+ rt.DeveloperName);
                        //debug:- sStrs(SA_Audit__Test_Object__c.SA_Audit__Test_Record_Type1); 
                        System.debug('rStrs==' + rStrs);
                    }else{
                        rStrs.add(rt.SObjectType + '.'+namespaces[0].NamespacePrefix+'__'+ rt.DeveloperName);
                        System.debug('rStrs==' + rStrs);
                    }
                }
                if(namespaces[0].NamespacePrefix == null){
                   if(rt.SObjectType.containsIgnoreCase('__c')){
                       string nmspc = ObjectNamespacee;
                        system.debug('nmspc='+nmspc);
                        string NamespaceLessStrt = rt.SObjectType.removeStart(nmspc);//OWD_Sharing_Report__c
                        system.debug('NamespaceLessStrt='+NamespaceLessStrt);
                        string NamespaceLessEnd = rt.SObjectType.removeEnd('__c');//OWD_Sharing_Report
                        system.debug('NamespaceLessEnd='+NamespaceLessEnd);
                        rStrs.add(NamespaceLessEnd + '__c.'+ObjectNamespacee+'__'+ rt.DeveloperName);
                        //debug:- sStrs(SA_Audit__Test_Object__c.SA_Audit__Test_Record_Type1); 
                        System.debug('rStrs==' + rStrs);
                    }
                    else{rStrs.add(rt.SObjectType + '.'+ rt.DeveloperName);
                         System.debug('rStrs==' + rStrs);}
                }
                 
                System.debug('rStrs==' + rStrs);
            }
      
        }catch(Exception e){
            system.debug('error'+e);
        }
        List<PicklistWrapper> picklistWrappers = new List<PicklistWrapper>();
        if(!test.isRunningTest()){
        MetadataService.MetadataPort service = createService();
        service.timeout_x=120000; 
        for(string rStr : rStrs){
            MetadataService.RecordType recordType = (MetadataService.RecordType) service.readMetadata('RecordType', new String[] {rStr}).getRecords()[0];
            system.debug('rStrObj='+rStr);
            List<MetadataService.RecordTypePicklistValue> profileRecordTypeList = recordType.picklistValues;
            try {
                for(MetadataService.RecordTypePicklistValue rr : recordType.picklistValues){
                    system.debug('Entry');
                    PicklistWrapper bb = new PicklistWrapper();
                    bb.picklistName = rr.picklist;
                    string rTName = recordType.fullName.substringAfter('.');//  Account.Mr,(string rTName = Mr)
                    bb.recordType = rTName;
                    bb.picklistValues = rr.values;
                    string obbj = recordType.fullName.substringBefore('.');
                    bb.ObjectNme = obbj;
                    List<string> avl = new List<string>();
                    for (MetadataService.PicklistValue picklistValue : rr.values) {
                        
                        avl.add(picklistValue.fullName + '\n');
                    }
                    bb.Vall = avl;
                   // Vallt.addall(avl);
                    system.debug('avl'+bb.Vall);
                    picklistWrappers.add(bb);
                }
            }catch(Exception e){
                system.debug('error'+e);
            }
        }
        }else{
            PicklistWrapper bb = new PicklistWrapper();
            bb.picklistName = '';
            bb.recordType = '';
           // bb.picklistValues = Vallt;
            bb.ObjectNme = '';
           // bb.Vall.add('');
            picklistWrappers = new List<PicklistWrapper>();
        }
        system.debug('picklistWrappers=='+picklistWrappers); 
        return picklistWrappers;
    }
    public class PicklistWrapper {
        @AuraEnabled 
        public String picklistName {get; set;}
        @AuraEnabled 
        public String ObjectNme {get; set;}
        @AuraEnabled 
        public List<MetadataService.PicklistValue> picklistValues {get; set;}
        @AuraEnabled 
        public String recordType {get; set;}
        @AuraEnabled 
        public List<string> Vall {get; set;}
    }
}