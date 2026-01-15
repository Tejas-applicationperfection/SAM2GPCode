/*
Author/Modified Code By : Himanshu Kr. Varshney
*/
public with sharing class  Utils{
    @AuraEnabled
    public static String reportBody{ get; set; }  
    @AuraEnabled
    public static Boolean OrgIsAccessible{ 
        get{
            if(!Schema.getGlobalDescribe().get('Organization').getDescribe().isAccessible()){
                return false;
            } 
            else{
                return true;
            }
        } 
        set; 
    }
    @AuraEnabled
    public static String exportUser{ 
        get{
            return UserInfo.getName();
        }
        set; 
    }
    @AuraEnabled
    public static Organization org{ 
        get{
            if(org == null){
                String orgId = UserInfo.getOrganizationId();
                org = [SELECT Id, Name, NamespacePrefix FROM Organization WHERE ID = :orgID];
            }
            return org;
        } 
        set; 
    }
    public static ReportInfos getReportsInfos(){
        return new ReportInfos(OrgIsAccessible, org, exportUser);
    }
    public class ReportInfos{
        @AuraEnabled
        public Boolean OrgIsAccessible{ get; set; }
        @AuraEnabled
        public Organization org{ get; set; }
        @AuraEnabled
        public String exportUser{ get; set; }
        public ReportInfos(Boolean OrgIsAccessible, Organization org, String exportUser){
            this.OrgIsAccessible = OrgIsAccessible;
            this.org = org;
            this.exportUser = exportUser;
        }
    }
}