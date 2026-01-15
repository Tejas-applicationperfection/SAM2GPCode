/*
Author       : Himanshu Kr. Varshney
Description  : Apex Controller for Intel Tab(For Option 18)
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class PublicGroupController {
    @AuraEnabled
    public String xmlheader {get; set;}
    @AuraEnabled
    public Utils.ReportInfos reportInfos {get; set;}
    @AuraEnabled
    public List<WrapperData> publicGroupData {get; set;}  
    @AuraEnabled
    public List<WrapperData> publicGroupData2 {get; set;}
    
    public PublicGroupController() {
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        publicGroupData = getPublicGroupDetails();
        publicGroupData2 = getPublicGroupMembersDetails();
        reportInfos = Utils.getReportsInfos(); 
    }
    
    private static String sanitizeInput(String input) {
        if (String.isBlank(input)) {
            return input;
        }
        // Replace characters that can be used in XSS attacks
        String sanitized = input.replaceAll('[<]', '&lt;');
        sanitized = sanitized.replaceAll('[>]', '&gt;');
        sanitized = sanitized.replaceAll('[&]', '&amp;');
        sanitized = sanitized.replaceAll('["]', '&quot;');
         
                                           return sanitized;
                                           }

    
   @AuraEnabled
public static List<WrapperData> getPublicGroupDetails() {
    // all groups
    List<Group> groupList = [
        SELECT Id, Name, DeveloperName, LastModifiedDate, CreatedDate, CreatedBy.Name, Type 
        FROM Group 
        WHERE Type = 'Regular' 
        LIMIT 1000
    ];

    //  group member IDs for all groups
    Set<Id> groupIds = new Set<Id>();
    for (Group groupe : groupList) {
        groupIds.add(groupe.Id);
    }

    //  all group members for the fetched group IDs
    Map<Id, List<GroupMember>> groupMembersMap = new Map<Id, List<GroupMember>>();
    for (GroupMember member : [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE GroupId IN :groupIds Limit 25000]) {
        if (!groupMembersMap.containsKey(member.GroupId)) {
            groupMembersMap.put(member.GroupId, new List<GroupMember>());
        }
        groupMembersMap.get(member.GroupId).add(member);
    }

    //active users based on the group member IDs
    Set<Id> userOrGroupIds = new Set<Id>();
    for (List<GroupMember> groupMembers : groupMembersMap.values()) {
        for (GroupMember groupMember : groupMembers) {
            userOrGroupIds.add(groupMember.UserOrGroupId);
        }
    }

    Map<Id, User> activeUsersMap = new Map<Id, User>([
        SELECT Id, Alias, Name, UserName, UserRole.Name, IsActive, Profile.Name, LastLoginDate 
        FROM User 
        WHERE Id IN :userOrGroupIds AND IsActive = true
    ]);

    // final list of wrapper data
    List<WrapperData> finalWrapperData = new List<WrapperData>();
    /*for (Group groupe : groupList) {
        WrapperData wrapperData = new WrapperData();
        wrapperData.label = groupe.Name;
        wrapperData.groupName = groupe.DeveloperName;
        wrapperData.createdBy = groupe.CreatedBy.Name;
        wrapperData.createdDate = groupe.CreatedDate.format('MM/dd/yyyy hh:mm a');
        wrapperData.lastModifiedDate = groupe.LastModifiedDate.format('MM/dd/yyyy hh:mm a');

        //  group members associated with the current group
        List<GroupMember> groupMembers = groupMembersMap.get(groupe.Id);

        if (groupMembers != null && !groupMembers.isEmpty()) {
            //  group member is an active user
            for (GroupMember groupMember : groupMembers) {
                if (activeUsersMap.containsKey(groupMember.UserOrGroupId)) {
                    wrapperData.memberIncludesActiveUser = 'Yes';
                    break;
                }
            }
        } else {
            wrapperData.memberIncludesActiveUser = 'No';
        }

        finalWrapperData.add(wrapperData);
}*/
    
    for (Group groupe : groupList) {
        WrapperData wrapperData = new WrapperData();
        wrapperData.label = sanitizeInput(groupe.Name);
        wrapperData.groupName = sanitizeInput(groupe.DeveloperName);
        wrapperData.createdBy = sanitizeInput(groupe.CreatedBy.Name);
        wrapperData.createdDate = sanitizeInput(groupe.CreatedDate.format('MM/dd/yyyy hh:mm a'));
        wrapperData.lastModifiedDate = sanitizeInput(groupe.LastModifiedDate.format('MM/dd/yyyy hh:mm a'));
        
        // Group members associated with the current group
        List<GroupMember> groupMembers = groupMembersMap.get(groupe.Id);
        
        if (groupMembers != null && !groupMembers.isEmpty()) {
            for (GroupMember groupMember : groupMembers) {
                if (activeUsersMap.containsKey(groupMember.UserOrGroupId)) {
                    wrapperData.memberIncludesActiveUser = sanitizeInput('Yes');
                    break;
                }
            }
        } else {
            wrapperData.memberIncludesActiveUser = sanitizeInput('No');
        }
        
        finalWrapperData.add(wrapperData);
    }

    

    System.debug('finalWrapperData=' + finalWrapperData);
    return finalWrapperData;
}

    
    @AuraEnabled
    public static List<WrapperData> getPublicGroupMembersDetails() {
        // Fetching groups
        List<Group> groupList = [
            SELECT Id, Name, DeveloperName, LastModifiedDate, LastModifiedBy.Name, CreatedDate, CreatedBy.Name, Type
            FROM Group 
            WHERE Type != NULL AND DeveloperName != NULL 
            LIMIT 1000
        ];
        
        //  all GroupMembers for the groups in a separate query
        Set<Id> groupIds = new Set<Id>();
        for (Group groupe : groupList) {
            groupIds.add(groupe.Id);
        } 
        Map<Id, List<GroupMember>> groupMembersMap = new Map<Id, List<GroupMember>>();
        for (GroupMember member : [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE GroupId IN :groupIds Limit 20000]) {
            if (!groupMembersMap.containsKey(member.GroupId)) {
                groupMembersMap.put(member.GroupId, new List<GroupMember>());
            }
            groupMembersMap.get(member.GroupId).add(member);
        }
        
        // active users based on the GroupMembers fetched
        Set<Id> userIds = new Set<Id>();
        for (List<GroupMember> members : groupMembersMap.values()) {
            for (GroupMember member : members) {
                userIds.add(member.UserOrGroupId);
            }
        }
        
        Map<Id, User> activeUsersMap = new Map<Id, User>([
            SELECT Id, Alias, Name, UserName, UserRole.Name, IsActive, Profile.Name, LastLoginDate 
            FROM User 
            WHERE Id IN :userIds AND IsActive = true
        ]); 
        
        // the final list of wrapper data
        List<WrapperData> finalWrapperData = new List<WrapperData>();
      /*  for (Group groupm : groupList) {
            List<GroupMember> members = groupMembersMap.get(groupm.Id);
            if (members != null) {
                for (GroupMember member : members) {
                    if (activeUsersMap.containsKey(member.UserOrGroupId)) {
                        User activeUser = activeUsersMap.get(member.UserOrGroupId);
                        WrapperData wrapperData = new WrapperData();
                        wrapperData.label = groupm.Name;
                        wrapperData.groupName = groupm.DeveloperName;
                        wrapperData.createdBy = groupm.CreatedBy.Name;
                        wrapperData.createdDate = groupm.CreatedDate.format('MM/dd/yyyy hh:mm a');
                        wrapperData.modifyby = groupm.LastModifiedBy.Name;
                        wrapperData.Alias = activeUser.Alias;
                        wrapperData.UserID = activeUser.Id;
                        wrapperData.Name = activeUser.Name;
                        wrapperData.UserName = activeUser.UserName;
                        wrapperData.UserRole = activeUser.UserRole.Name;
                        wrapperData.Active = activeUser.IsActive;
                        wrapperData.ProfileName = activeUser.Profile.Name;
                        wrapperData.LastLogin = activeUser.LastLoginDate;
                        finalWrapperData.add(wrapperData);
                    }
                }
            }
        }*/
        
        for (Group groupm : groupList) {
    List<GroupMember> members = groupMembersMap.get(groupm.Id);
    if (members != null) {
        for (GroupMember member : members) {
            if (activeUsersMap.containsKey(member.UserOrGroupId)) {
                User activeUser = activeUsersMap.get(member.UserOrGroupId);
                WrapperData wrapperData = new WrapperData();
                wrapperData.label = sanitizeInput(groupm.Name);
                wrapperData.groupName = sanitizeInput(groupm.DeveloperName);
                wrapperData.createdBy = sanitizeInput(groupm.CreatedBy.Name);
                wrapperData.createdDate = sanitizeInput(groupm.CreatedDate.format('MM/dd/yyyy hh:mm a'));
                wrapperData.modifyby = sanitizeInput(groupm.LastModifiedBy.Name);
                wrapperData.Alias = sanitizeInput(activeUser.Alias);
                wrapperData.UserID = sanitizeInput(activeUser.Id);
                wrapperData.Name = sanitizeInput(activeUser.Name);
                wrapperData.UserName = sanitizeInput(activeUser.UserName);
                wrapperData.UserRole = sanitizeInput(activeUser.UserRole.Name);
                wrapperData.Active = activeUser.IsActive;
                wrapperData.ProfileName = sanitizeInput(activeUser.Profile.Name);
                wrapperData.LastLogin = activeUser.LastLoginDate;
                finalWrapperData.add(wrapperData);
            }
        }
    }
}

        
        
        System.debug('finalWrapperData--' + finalWrapperData);
        return finalWrapperData;
    }

    
    //
    //Below Wrapper Class will store the Data which will be Related to Public Groups
    public class WrapperData{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String groupName {get; set;}
        @AuraEnabled
        public String createdBy {get; set;}
        @AuraEnabled
        public String createdDate {get; set;}
        @AuraEnabled
        public String UserID {get; set;}
        @AuraEnabled
        public String lastModifiedDate {get; set;}
        @AuraEnabled
        public String modifyby {get; set;}
        @AuraEnabled
        public String memberIncludesActiveUser {get; set;}
        @AuraEnabled
        public String memberIncludesInActiveUser {get; set;}
        
        //getPublicGroupMembersDetails @TEJAS
        @AuraEnabled
        public String Alias {get; set;}
        @AuraEnabled
        public String Name {get; set;}
        @AuraEnabled
        public String UserName {get; set;}
        @AuraEnabled
        public String UserRole {get; set;}
        @AuraEnabled
        public Boolean Active {get; set;}
        @AuraEnabled
        public String ProfileName {get; set;}
        @AuraEnabled
        public DateTime LastLogin {get; set;}
        @AuraEnabled
        public String SubGroups {get; set;}
        
        
        
    }
}