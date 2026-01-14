/*
Author       : Himanshu Kr. Varshney
Description  : Apex Controller for Intel Tab(For Option 16)
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class ProfilesWithNoUserDetails {
    @AuraEnabled
    public String xmlheader { get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos { get; set; }
    @AuraEnabled
    public List<WrapperData> profilesWithNoUsers { get; set; }

    public ProfilesWithNoUserDetails() {
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        profilesWithNoUsers = getProfilesData();
        reportInfos = Utils.getReportsInfos();
    }

    /*
    Author  : Himanshu Kr. Varshney
    Purpose : Below Method will Give Us Data related to Profiles
    */
    @AuraEnabled
    @RemoteAction
    public static List<WrapperData> getProfilesData() {
        Map<Id, Profile> profileMap = new Map<Id, Profile>([SELECT Id, Name, UserLicense.Name FROM Profile  LIMIT 30000]);
        Map<Id, List<User>> profileUsersMap = new Map<Id, List<User>>();
        
        for (User user : [SELECT Id, ProfileId, IsActive FROM User WHERE ProfileId != null LIMIT 30000]) {
            if (!profileUsersMap.containsKey(user.ProfileId)) {
                profileUsersMap.put(user.ProfileId, new List<User>());
            }
            profileUsersMap.get(user.ProfileId).add(user);
        }
        
        List<WrapperData> wrapperDataList = new List<WrapperData>();
        
        for (PermissionSet permissionSetRecord : [SELECT ProfileId, isCustom FROM PermissionSet WHERE ProfileId != null LIMIT 30000]) {
            WrapperData oneWrapperData = new WrapperData();
            oneWrapperData.profileName = profileMap.get(permissionSetRecord.ProfileId).Name;
            oneWrapperData.licenseName = profileMap.get(permissionSetRecord.ProfileId).UserLicense.Name;
            oneWrapperData.isCustomProfile = permissionSetRecord.isCustom;
            
            List<User> users = profileUsersMap.get(permissionSetRecord.ProfileId);
            Integer activeUserCount = 0;
            Integer inactiveUserCount = 0;
            
            if (users != null) {
                for (User user : users) {
                    if (user.IsActive) {
                        oneWrapperData.usedByActiveUser = 'Yes';
                        activeUserCount++;
                    } else {
                        oneWrapperData.usedByInactiveUser = 'Yes';
                        inactiveUserCount++;
                    }
                }
            }
            
            oneWrapperData.ActiveUserCount = activeUserCount > 0 ? String.valueOf(activeUserCount) : 'No';
            oneWrapperData.InActiveUserCount = inactiveUserCount > 0 ? String.valueOf(inactiveUserCount) : 'No';
            
            wrapperDataList.add(oneWrapperData);
        }

        // Sort the wrapperDataList by profileName
        wrapperDataList.sort();
        
        return wrapperDataList;
    }

    // Below Class will Hold the Wrapper Data
    public class WrapperData implements Comparable {
        @AuraEnabled
        public String profileName { get; set; }
        @AuraEnabled
        public String licenseName { get; set; }
        @AuraEnabled
        public String usedByActiveUser { get; set; }
        @AuraEnabled
        public String usedByInactiveUser { get; set; }
        @AuraEnabled
        public Boolean isCustomProfile { get; set; }
        @AuraEnabled
        public String ActiveUserCount { get; set; }
        @AuraEnabled
        public String InActiveUserCount { get; set; }
        
        // Implementing the Comparable interface to sort by profileName
        public Integer compareTo(Object compareToObject) {
            WrapperData compareToWrapperData = (WrapperData) compareToObject;
            return this.profileName.compareTo(compareToWrapperData.profileName);
        }
    }
}