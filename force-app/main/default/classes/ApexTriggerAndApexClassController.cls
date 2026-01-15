/*
Author       : Himanshu Kr. Varshney
Description  : It will generate the data(For Option 17)
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class ApexTriggerAndApexClassController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public WrapperData reportData{ get; set; }
    public ApexTriggerAndApexClassController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportData = getApexTriggersAndApexClassDetails();
        reportInfos = Utils.getReportsInfos(); 
    }
/*
Author  : Himanshu Kr. Varshney
Purpose : Below Method will Give Us Data related to Apex Triggers and Apex Classes
*/
    @AuraEnabled
    public static WrapperData getApexTriggersAndApexClassDetails(){
        List<TriggerWrapper> apexTriggersDataList = new List<TriggerWrapper>();
        List<List<ApexWrapper>> listOfList = new List<List<ApexWrapper>>();
        List<List<TriggerWrapper>> listOfListSecond = new List<List<TriggerWrapper>>();
        WrapperData finalWrapperData = new WrapperData();
        Integer flag = 0;
        List<ApexWrapper> apexClassDataList = new List<ApexWrapper>();
        List<ApexTrigger> apexTriggerList = [SELECT Id, Name, TableEnumOrId, ApiVersion, Status, LengthWithoutComments, LastModifiedBy.Name, CreatedDate, LastModifiedDate FROM ApexTrigger ORDER BY Name ASC LIMIT 2000];
        List<ApexClass> apexClassList = [SELECT Id, Name, ApiVersion, Status, LengthWithoutComments, LastModifiedBy.Name, LastModifiedDate, CreatedDate FROM ApexClass ORDER BY Name ASC LIMIT 2000];
        for(Integer i = 0; i < apexTriggerList.size(); i++){
            TriggerWrapper apexTriggerOneRecord = new TriggerWrapper();
            apexTriggerOneRecord.triggerName = apexTriggerList[i].Name;
            apexTriggerOneRecord.objectName = apexTriggerList[i].TableEnumOrId;
            apexTriggerOneRecord.apiVersion = apexTriggerList[i].ApiVersion;
            apexTriggerOneRecord.status = apexTriggerList[i].Status;
            apexTriggerOneRecord.lengthWithoutComments = apexTriggerList[i].LengthWithoutComments;
            apexTriggerOneRecord.createdDate = apexTriggerList[i].CreatedDate.format('MM/dd/yyyy hh:mm a');
            String strTimeInAMorPM = apexTriggerList[i].LastModifiedDate.format('MM/dd/yyyy hh:mm a');
            strTimeInAMorPM = apexTriggerList[i].LastModifiedBy.Name + ', ' + strTimeInAMorPM;
            apexTriggerOneRecord.dateAndTimeWithName = strTimeInAMorPM;
            apexTriggersDataList.add(apexTriggerOneRecord);
            flag++;
            if(flag == 1000){
                flag = 0;
                listOfListSecond.add(apexTriggersDataList);
                apexTriggersDataList = new List<TriggerWrapper>();
            }
        }
        listOfListSecond.add(apexTriggersDataList);
        finalWrapperData.apexTriggersData = listOfListSecond;
        flag = 0;
        for(Integer i = 0; i < apexClassList.size(); i++){
            ApexWrapper apexWrapperOneRecord = new ApexWrapper();
            apexWrapperOneRecord.className = apexClassList[i].Name;
            apexWrapperOneRecord.apiVersion = apexClassList[i].ApiVersion;
            apexWrapperOneRecord.status = apexClassList[i].Status;
            apexWrapperOneRecord.lengthWithoutComments = apexClassList[i].LengthWithoutComments;
            apexWrapperOneRecord.createdDate = apexClassList[i].CreatedDate.format('MM/dd/yyyy hh:mm a');
            String strTimeInAMorPM = apexClassList[i].LastModifiedDate.format('MM/dd/yyyy hh:mm a');
            strTimeInAMorPM = apexClassList[i].LastModifiedBy.Name + ', ' + strTimeInAMorPM;
            apexWrapperOneRecord.dateAndTimeWithName = strTimeInAMorPM;
            apexClassDataList.add(apexWrapperOneRecord);
            flag++;
            if(flag == 1000){
                flag = 0;
                listOfList.add(apexClassDataList);
                apexClassDataList = new List<ApexWrapper>();
            }
        }
        listOfList.add(apexClassDataList);
        finalWrapperData.apexClassData = listOfList;
        return finalWrapperData;
    }
    //Below are the Wrapper Classes which will store the Data which will be Related to Apex Classes and Apex Triggers
    public class WrapperData{
        @AuraEnabled
        public List<List<TriggerWrapper>> apexTriggersData {get; set;}
        @AuraEnabled
        public List<List<ApexWrapper>> apexClassData {get; set;}
    }
    public class TriggerWrapper{
        @AuraEnabled
        public String triggerName {get; set;}
        @AuraEnabled
        public String objectName {get; set;}
        @AuraEnabled
        public Decimal apiVersion {get; set;}
        @AuraEnabled
        public String status {get; set;}
        @AuraEnabled
        public Integer lengthWithoutComments {get; set;}
        @AuraEnabled
        public String createdDate {get; set;}
        @AuraEnabled
        public String dateAndTimeWithName {get; set;}
    }
    public class ApexWrapper{
        @AuraEnabled
        public String className {get; set;}
        @AuraEnabled
        public Decimal apiVersion {get; set;}
        @AuraEnabled
        public String status {get; set;}
        @AuraEnabled
        public Integer lengthWithoutComments {get; set;}
        @AuraEnabled
        public String createdDate {get; set;}
        @AuraEnabled
        public String dateAndTimeWithName {get; set;}
    }
}