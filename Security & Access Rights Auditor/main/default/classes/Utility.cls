/*
Author      : Himanshu Kr. Varshney
Description : This Class is used to generate the Information like Org Name, User Name etc.
Dependencies: It is being used in ReportsExcelController.apxc
*/
public with sharing class Utility{
    @AuraEnabled
    public static Boolean orgIsAccessible{ 
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
                org = [SELECT Id, Name, NamespacePrefix FROM Organization WHERE ID =: orgId];
            }
            return org;
        } 
        set; 
    }
    public static ReportInfos getReportsInfos(){
        return new ReportInfos(orgIsAccessible, org, exportUser);
    }
    public class ReportInfos{
        @AuraEnabled
        public Boolean orgIsAccessible{ get; set; }
        @AuraEnabled
        public Organization org{ get; set; }
        @AuraEnabled
        public String exportUser{ get; set; }
        public ReportInfos(Boolean orgIsAccessible, Organization org, String exportUser){
            this.orgIsAccessible = orgIsAccessible;
            this.org = org;
            this.exportUser = exportUser;
        }
    }
}