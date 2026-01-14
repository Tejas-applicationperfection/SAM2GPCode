/*
Author/Modified Code By : Himanshu Kr. Varshney
*/
public with sharing class InstalledPackagesReportExcelController{
    @AuraEnabled
    public String xmlheader { get; set; }
    @AuraEnabled
    public List<InstalledPackageFinal> packageList { get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos { get; set; }
    public InstalledPackagesReportExcelController(){
        String jobId = ApexPages.currentPage().getParameters().get('jobId');
        List<SA_Audit__Helper__c> helperList = new List<SA_Audit__Helper__c>([SELECT Id, SA_Audit__ResultBody_1__c, SA_Audit__ResultBody_2__c, SA_Audit__ResultBody_3__c, SA_Audit__ResultBody_4__c, SA_Audit__ResultBody_5__c,
                                                                              SA_Audit__ResultBody_6__c, SA_Audit__ResultBody_7__c, SA_Audit__ResultBody_8__c, SA_Audit__ResultBody_9__c, SA_Audit__ResultBody_10__c,
                                                                              SA_Audit__ResultBody_11__c, SA_Audit__ResultBody_12__c, SA_Audit__ResultBody_13__c, SA_Audit__ResultBody_14__c, SA_Audit__ResultBody_15__c,
                                                                              SA_Audit__ResultBody_16__c, SA_Audit__ResultBody_17__c, SA_Audit__ResultBody_18__c, SA_Audit__ResultBody_19__c, SA_Audit__ResultBody_20__c FROM SA_Audit__Helper__c WHERE SA_Audit__JobId__c =: jobId LIMIT 1]);
        String reportBody = '';
        packageList = new List<InstalledPackageFinal>();
        for(Integer i = 1; i <= 20; i++){
            reportBody += helperList != null && helperList.size() > 0 ? (String) helperList[0].get('SA_Audit__ResultBody_'+ i +'__c') : null;
        }
         system.debug('testing reportBody'+ reportBody);
        List<InstalledPackagesReportBatch.InstalledPackage> ipList = (List<InstalledPackagesReportBatch.InstalledPackage>)JSON.deserialize(reportBody, List<InstalledPackagesReportBatch.InstalledPackage>.class);
        Map<String, List<PackageLicense>> match = new Map<String, List<PackageLicense>>();
        Map<String, InstalledPackagesReportBatch.InstalledPackage> matchSelect = new Map<String, InstalledPackagesReportBatch.InstalledPackage>();        
        for(InstalledPackagesReportBatch.InstalledPackage ipf : ipList){
            matchSelect.put(ipf.nameSpacePrefix, ipf); 
        }
        for(PackageLicense pl : [SELECT NamespacePrefix, Status, AllowedLicenses, UsedLicenses, CreatedDate, LastModifiedDate, ExpirationDate FROM PackageLicense Limit 2000]){
            packageList.add(new InstalledPackageFinal(matchSelect.get(pl.NamespacePrefix), pl));
        }
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos();
    }
    public class InstalledPackageFinal{
        @AuraEnabled
        public InstalledPackagesReportBatch.InstalledPackage installedPackage { get; set; }
        @AuraEnabled
        public String Status { get; set; }
        @AuraEnabled
        public Integer AllowedLicenses { get; set; }
        @AuraEnabled
        public Integer UsedLicenses { get; set; }
        @AuraEnabled
        public String CreatedDate { get; set; }
        @AuraEnabled
        public String LastModifiedDate { get; set; }
        @AuraEnabled
        public String ExpirationDate { get; set; }
        public InstalledPackageFinal(InstalledPackagesReportBatch.InstalledPackage ip, PackageLicense pl){
            this.installedPackage = ip;
            this.Status = pl.Status;
            this.AllowedLicenses = pl.AllowedLicenses;
            this.UsedLicenses = pl.UsedLicenses;
            this.CreatedDate = pl.CreatedDate.format('MM/dd/yyyy hh:mm a');
            this.LastModifiedDate = pl.LastModifiedDate.format('MM/dd/yyyy hh:mm a');
            this.ExpirationDate = pl.ExpirationDate != null ? pl.ExpirationDate.format('MM/dd/yyyy hh:mm a') : 'Does not Expire or N/A';
        }
    }
}