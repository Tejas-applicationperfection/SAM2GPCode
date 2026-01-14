/*
Author/Modified Code By : Himanshu Kr. Varshney
*/
public with sharing class FolderShareExcelController{
    @AuraEnabled
    public String xmlheader { get; set; }
    @AuraEnabled
    public String reportBody { get; set; }
    @AuraEnabled
    public String jobId { get; set; }
    //public List<Folder> foldersList { get; set; }
    @AuraEnabled
    public List<List<Folder>> allFolderList { get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos { get; set; }
    public FolderShareExcelController(){
        xmlheader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos();
        jobId = ApexPages.currentPage().getParameters().get('jobId');
        List<SA_Audit__Helper__c> helperList = new List<SA_Audit__Helper__c>([SELECT Id, SA_Audit__ResultBody_1__c, SA_Audit__ResultBody_2__c, SA_Audit__ResultBody_3__c, SA_Audit__ResultBody_4__c, SA_Audit__ResultBody_5__c,
                                                                              SA_Audit__ResultBody_6__c, SA_Audit__ResultBody_7__c, SA_Audit__ResultBody_8__c, SA_Audit__ResultBody_9__c, SA_Audit__ResultBody_10__c,
                                                                              SA_Audit__ResultBody_11__c, SA_Audit__ResultBody_12__c, SA_Audit__ResultBody_13__c, SA_Audit__ResultBody_14__c, SA_Audit__ResultBody_15__c,
                                                                              SA_Audit__ResultBody_16__c, SA_Audit__ResultBody_17__c, SA_Audit__ResultBody_18__c, SA_Audit__ResultBody_19__c, SA_Audit__ResultBody_20__c FROM SA_Audit__Helper__c WHERE SA_Audit__JobId__c =: jobId LIMIT 1]);
        List<Folder> foldersList = new List<Folder>();
        Folder f;
        for(Integer i = 1; i <= 20; i++){
            reportBody = helperList != null && helperList.size() > 0 ? (String) helperList[0].get('SA_Audit__ResultBody_' + i + '__c') : null;
            if(reportBody != null){
                List<String> recs = reportBody.split('/n');
                for(String rec : recs){
                    String [] fields = rec.split('~#~');
                    f = new Folder();
                    f.name = fields[0];
                    f.accessType = fields[1];
                    f.shareType = fields[2];
                    f.sharedWith = fields[3];
                    foldersList.add(f);
                }
            }    
        }
        Integer i = 0;
        allFolderList = new List<List<Folder>>();
        List<Folder> tempFolder = new List<Folder>();
        for(Folder fol : foldersList){
            if(i < 1000){                
                tempFolder.add(fol);
                i++;
            } 
            else{
                allFolderList.add(tempFolder);
                i = 1;
                tempFolder = new List<Folder>();
                tempFolder.add(fol);
            }
        }
        if(tempFolder.size() > 0){
            allFolderList.add(tempFolder);
        } 
    }
    public class Folder{
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String accessType { get; set; }
        @AuraEnabled
        public String shareType { get; set; }
        @AuraEnabled
        public String sharedWith { get; set; }
    }
}