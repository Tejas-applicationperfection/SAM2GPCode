public with sharing class CircularBarChartHomeApex {
    
    public CircularBarChartHomeApex(){
        system.debug('CircularBarChartHomeApex inialize');
    }
    
    
 @AuraEnabled
    public static List<PermissionReviewItem> getPermissionReviewData() { 
        List<PermissionReviewItem> permissionReviewData = new List<PermissionReviewItem>();
        
        // Use direct COUNT queries for simple counts
        Integer totalProfiles = [SELECT COUNT() FROM PermissionSet WHERE Iscustom=true AND ProfileId != null];
        Integer totalPermissionSets = [SELECT COUNT() FROM PermissionSet WHERE IsCustom = true AND (NOT Name LIKE 'X00%')];
        Integer totalPermissionSetGroups = [SELECT COUNT() FROM PermissionSetGroup WHERE ID != NULL];
        
        // Use subqueries for unused counts
        Integer unusedPermissionSetsCanDelete = [SELECT COUNT() 
                                               FROM PermissionSet 
                                               WHERE IsCustom = true 
                                               AND Id NOT IN (SELECT PermissionSetId FROM PermissionSetAssignment) 
                                               AND (NOT Name LIKE 'X00%')];
        
        Integer unusedPermissionSetGroupsCanDelete = [SELECT COUNT() 
                                                    FROM PermissionSetGroup 
                                                    WHERE Id NOT IN (SELECT PermissionSetGroupId FROM PermissionSetAssignment)];
        
        Integer unusedProfilesCanDelete = [SELECT COUNT() 
                                         FROM PermissionSet 
                                         WHERE Iscustom=true 
                                         AND ProfileId != null 
                                         AND ProfileId NOT IN (SELECT ProfileId FROM User)];
        
        // Use direct COUNT queries instead of processing all records
        Integer totalGroupMembers = [SELECT COUNT() FROM GroupMember WHERE GroupId != NULL];
        Integer totalUsers = [SELECT COUNT() FROM User WHERE UserRoleId != NULL];
        Integer totalUserRoles = [SELECT COUNT() FROM UserRole WHERE ParentRoleId != NULL];
        
        // Use subqueries to get counts directly
        Integer unusedPublicGroupCount = [SELECT COUNT() 
                                        FROM Group 
                                        WHERE Type = 'Regular' 
                                        AND Id NOT IN (SELECT GroupId FROM GroupMember)];
        
        Integer unusedRoleCount = [SELECT COUNT() 
                                 FROM UserRole 
                                 WHERE Id NOT IN (SELECT UserRoleId FROM User)];
        
        Integer totalRolesCount = [SELECT COUNT() FROM UserRole WHERE Id != NULL];
        
        // Calculate internal and external role counts using direct queries
        Integer unusedInternalRoleCount = [SELECT COUNT() 
                                         FROM UserRole 
                                         WHERE Id NOT IN (SELECT UserRoleId FROM User)
                                         AND (PortalType = 'None' OR PortalType = null)];
        
        Integer unusedExternalRoleCount = [SELECT COUNT() 
                                         FROM UserRole 
                                         WHERE Id NOT IN (SELECT UserRoleId FROM User)
                                         AND PortalType != 'None'];
        
        Integer totalpublicGroupCount = [SELECT COUNT() 
                                       FROM Group 
                                       WHERE Type = 'Regular' 
                                       AND DeveloperName != 'AllInternalUsers'];
        Integer totalinternalRoleCount = [SELECT COUNT() 
                                        FROM UserRole 
                                        WHERE PortalType = 'None'];
        Integer totalexternalRoleCount = [SELECT COUNT() 
                                        FROM UserRole 
                                        WHERE PortalType != 'None'];
        
        // Create and populate the PermissionReviewItem
        PermissionReviewItem profilesItem = new PermissionReviewItem();
        profilesItem.index = 1;
        profilesItem.type = 'Profile';
        profilesItem.Profilecount = totalProfiles;
        profilesItem.Permissioncount = totalPermissionSets;
        profilesItem.PermissionGroupcount = totalPermissionSetGroups;
        profilesItem.Rolescount = totalRolesCount;
        profilesItem.PublicGroupcount = totalpublicGroupCount;
        profilesItem.InternalRolescount = totalinternalRoleCount;
        profilesItem.ExternalRolescount = totalexternalRoleCount;
        profilesItem.unusedRolesCanDelete = unusedRoleCount;
        profilesItem.unusedPublicGroupCanDelete = unusedPublicGroupCount;
        profilesItem.unusedInternalRolesCanDelete = unusedInternalRoleCount;
        profilesItem.unusedExternalRolesCanDelete = unusedExternalRoleCount;
        profilesItem.unusedProfilesCount = unusedProfilesCanDelete;
        profilesItem.unusedPermissionCount = unusedPermissionSetsCanDelete;
        profilesItem.unusedPermissionGroupCount = String.valueOf(unusedPermissionSetGroupsCanDelete);
        
        // Calculate percentages
        Decimal ProfilePrValue = (totalProfiles != 0) ? Math.floor((Decimal.valueOf(unusedProfilesCanDelete) / Decimal.valueOf(totalProfiles) * 100)) : 0;
        profilesItem.percentageUnusedProfiles = ProfilePrValue + '%';
        
        Decimal PermissionPrValue = (totalPermissionSets != 0) ? Math.floor((Decimal.valueOf(unusedPermissionSetsCanDelete) / Decimal.valueOf(totalPermissionSets) * 100)) : 0;
        profilesItem.percentageUnusedPermissions = PermissionPrValue + '%';
        
        Decimal percentPsetGroupValue = (totalPermissionSetGroups != 0) ? Math.floor((Decimal.valueOf(unusedPermissionSetGroupsCanDelete) / Decimal.valueOf(totalPermissionSetGroups) * 100)) : 0;
        profilesItem.percentageUnusedPsetGroup = percentPsetGroupValue + '%';
        
        Decimal RolesPrValue = (totalRolesCount != 0) ? Math.floor((Decimal.valueOf(unusedRoleCount) / Decimal.valueOf(totalRolesCount) * 100)) : 0;
        profilesItem.percentageUnusedRoles = RolesPrValue + '%';
        
        Decimal PublicGroupPrValue = (totalpublicGroupCount != 0) ? Math.floor((Decimal.valueOf(unusedPublicGroupCount) / Decimal.valueOf(totalpublicGroupCount) * 100)) : 0;
        profilesItem.percentageUnusedPublicGroup = PublicGroupPrValue + '%';
        
        Decimal InternalRolesPrValue = (totalinternalRoleCount != 0) ? Math.floor((Decimal.valueOf(unusedInternalRoleCount) / Decimal.valueOf(totalinternalRoleCount) * 100)) : 0;
        profilesItem.percentageUnusedInternalRoles = InternalRolesPrValue + '%';
        
        Decimal ExternalRolesPrValue = (totalexternalRoleCount != 0) ? Math.floor((Decimal.valueOf(unusedExternalRoleCount) / Decimal.valueOf(totalexternalRoleCount) * 100)) : 0;
        profilesItem.percentageUnusedExternalRoles = ExternalRolesPrValue + '%';
        
        // Calculate org health
        Decimal orghealth = (ProfilePrValue + PermissionPrValue + percentPsetGroupValue + RolesPrValue + PublicGroupPrValue + InternalRolesPrValue + ExternalRolesPrValue) / 7;
        profilesItem.OrgHealthCount = orghealth;
        
        permissionReviewData.add(profilesItem);
        return permissionReviewData;
    }
       public class PermissionReviewItem {
        @AuraEnabled public Integer index;
        @AuraEnabled public String type;
        //count innfo
        @AuraEnabled public Decimal OrgHealthCount;//
        @AuraEnabled public Integer Profilecount;//
        @AuraEnabled public Integer Permissioncount;//
        @AuraEnabled public Integer PermissionGroupcount;
        @AuraEnabled public Integer RestrictionGroupcount;
        @AuraEnabled public Integer Rolescount;
        @AuraEnabled public Integer Territoriescount;
        @AuraEnabled public Integer PublicGroupcount;
        @AuraEnabled public Integer InternalRolescount;
        @AuraEnabled public Integer ExternalRolescount;
        @AuraEnabled public Integer unusedProfilesCount;//
        @AuraEnabled public Integer unusedPermissionCount;//
        // delete info
        @AuraEnabled public String unusedProfilesCanDelete;
        @AuraEnabled public String unusedPermissionSetsCanDelete;
        @AuraEnabled public String unusedPermissionGroupCount;
        @AuraEnabled public Integer unusedRolesCanDelete;
        @AuraEnabled public Integer unusedTerritoriesCanDelete;
        @AuraEnabled public Integer unusedPublicGroupCanDelete;
        @AuraEnabled public Integer unusedInternalRolesCanDelete;
        @AuraEnabled public Integer unusedExternalRolesCanDelete;
        // unused Percentage
        @AuraEnabled public String percentageUnusedProfiles;
        @AuraEnabled public String percentageUnusedPermissions;
        @AuraEnabled public String percentageUnusedPsetGroup;
        @AuraEnabled public String percentageUnusedRoles;
        @AuraEnabled public String percentageUnusedTerritories;
        @AuraEnabled public String percentageUnusedPublicGroup;
        @AuraEnabled public String percentageUnusedInternalRoles;
        @AuraEnabled public String percentageUnusedExternalRoles;
        @AuraEnabled public String linkToReport;
        @AuraEnabled public String percentage;
        @AuraEnabled public String reviewDate;
    }  
    
    
    @AuraEnabled
    public static Date getExistingDatesFromServer(String recordName) {
        system.debug('recordName=='+recordName);
        SA_Audit__AuditDateInfo__c dateData = [SELECT Id, SA_Audit__DateSelectionName__c, SA_Audit__Date_Selection_value__c FROM SA_Audit__AuditDateInfo__c WHERE SA_Audit__DateSelectionName__c = :recordName limit 1];
        
        return dateData != null ? dateData.SA_Audit__Date_Selection_value__c : null;
        //return dateData
    } 

}