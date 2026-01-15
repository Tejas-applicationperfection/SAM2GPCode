/*
Author/Modified Code By : Himanshu Kr. Varshney
*/
public with sharing class UserProfileExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    //public List<User> userRoles{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public List<List<User>> allUserRoles{ get; set;}
    public UserProfileExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        List<User> userRoles = HierarchyService.getUserProfileAndRoleList();
        reportInfos = Utils.getReportsInfos();
        Integer i = 0;
        allUserRoles = new List<List<User>>();
        List<User> tempUser = new List<User>();
        for(User u : userRoles){
            if(i < 1000){                
                tempUser.add(u);
                i++;
            } 
            else{
                allUserRoles.add(tempUser);
                i = 1;
                tempUser = new List<User>();
                tempUser.add(u);
            }
        }
        if(tempUser.size() > 0){
            allUserRoles.add(tempUser);
        }
        System.debug('allUserRoles===' + allUserRoles);
    }
}