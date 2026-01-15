/*
Author :Pradeep
*/
public with sharing class UserLicenseExcelController {
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public String str1{ get; set; }
    @AuraEnabled
    public String str2{ get; set; }
    
    //public List<User> userRoles{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public List<List<User>> allUserLicenses{ get; set;}
    public UserLicenseExcelController(){
        str1 = 'Active';
        str2 = 'Inactive';
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        List<User> userLicenses = HierarchyService.getUserLicenseList();
        reportInfos = Utils.getReportsInfos();
        Integer i = 0;
        allUserLicenses = new List<List<User>>();
        List<User> tempUser = new List<User>();
        for(User u : userLicenses){
            if(i < 1000){                
                tempUser.add(u);
                i++;
            } 
            else{
                allUserLicenses.add(tempUser);
                i = 1;
                tempUser = new List<User>();
                tempUser.add(u);
            }
        }
        if(tempUser.size() > 0){
            allUserLicenses.add(tempUser);
        }
        System.debug('allUserLicenses===' + allUserLicenses);
    }
}