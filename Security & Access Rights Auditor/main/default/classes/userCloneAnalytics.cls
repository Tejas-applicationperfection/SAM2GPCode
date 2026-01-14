public with sharing class userCloneAnalytics {
   


    public class LicenseInfo {
            @AuraEnabled public String licenseName;
            @AuraEnabled public Integer totalLicenses;
            @AuraEnabled public Integer usedLicenses;
            @AuraEnabled public List<UserLicenseInfo> users;
            
            public LicenseInfo(String name, Integer total, Integer used, List<UserLicenseInfo> users) {
                this.licenseName = name;
                this.totalLicenses = total;
                this.usedLicenses = used;
                this.users = users;
            }
        }
    
        public class UserLicenseInfo {
            @AuraEnabled public String userName;
            @AuraEnabled public String userEmail;
            @AuraEnabled public String profileName;
            @AuraEnabled public Datetime assignedDate;
            
            public UserLicenseInfo(String name, String email, String profile, Datetime assigned) {
                this.userName = name;
                this.userEmail = email;
                this.profileName = profile;
                this.assignedDate = assigned;
            }
        }
    
        @AuraEnabled(cacheable=true)
        public static List<LicenseInfo> getLicenseUtilization() {
            // First check if user has access to required objects
            if (!Schema.sObjectType.UserLicense.isAccessible() || 
                !Schema.sObjectType.User.isAccessible() || 
                !Schema.sObjectType.Profile.isAccessible()) {
                throw new SecurityException('Insufficient access permissions for required objects.');
            }
            
            // Check field level security for UserLicense
            if (!Schema.sObjectType.UserLicense.fields.Name.isAccessible() ||
                !Schema.sObjectType.UserLicense.fields.LicenseDefinitionKey.isAccessible() ||
                !Schema.sObjectType.UserLicense.fields.TotalLicenses.isAccessible() ||
                !Schema.sObjectType.UserLicense.fields.UsedLicenses.isAccessible()) {
                throw new SecurityException('Insufficient access permissions for UserLicense fields.');
            }
            
            // Check field level security for User
            if (!Schema.sObjectType.User.fields.Name.isAccessible() ||
                !Schema.sObjectType.User.fields.Email.isAccessible() ||
                !Schema.sObjectType.User.fields.IsActive.isAccessible() ||
                !Schema.sObjectType.User.fields.CreatedDate.isAccessible()) {
                throw new SecurityException('Insufficient access permissions for User fields.');
            }
            
            List<LicenseInfo> licenseInfos = new List<LicenseInfo>();
            
            // Query all license types
            for(UserLicense ul : [SELECT Id, Name, LicenseDefinitionKey, TotalLicenses, UsedLicenses 
                                FROM UserLicense
                                WITH SECURITY_ENFORCED
                                LIMIT 1000]) {
                // Get users for this license type
                List<UserLicenseInfo> users = new List<UserLicenseInfo>();
                for(User u : [SELECT Name, Email, Profile.Name, CreatedDate 
                             FROM User 
                             WHERE IsActive = true 
                             AND Profile.UserLicense.Id = :ul.Id
                             WITH SECURITY_ENFORCED]) {
                    users.add(new UserLicenseInfo(
                        u.Name,
                        u.Email,
                        u.Profile.Name,
                        u.CreatedDate
                    ));
                }
                
                licenseInfos.add(new LicenseInfo(
                    ul.Name,
                    Integer.valueOf(ul.TotalLicenses),
                    Integer.valueOf(ul.UsedLicenses),
                    users
                ));
            }
            
            return licenseInfos;
        }
    
     

    public class CloneHistory {
        @AuraEnabled public Datetime cloneDate;
        @AuraEnabled public String sourceUser;
        @AuraEnabled public String newUser;
        @AuraEnabled public String clonedBy;
        @AuraEnabled public String status;

        public CloneHistory(Datetime cloneDate, String sourceUser, String newUser, 
                          String clonedBy, String status) {
            this.cloneDate = cloneDate;
            this.sourceUser = sourceUser;
            this.newUser = newUser;
            this.clonedBy = clonedBy;
            this.status = status;
        }
    }

    public class PermissionData {
        @AuraEnabled public String name;
        @AuraEnabled public Integer count;
        @AuraEnabled public String permissionSetId;
        
        public PermissionData(String name, Integer count, String permissionSetId) {
            this.name = name;
            this.count = count;
            this.permissionSetId = permissionSetId;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PermissionData> getPermissionDistribution(Integer offset, Integer plimit) {
        // Check object permissions
        if (!Schema.sObjectType.PermissionSetAssignment.isAccessible() || 
            !Schema.sObjectType.PermissionSet.isAccessible()) {
            throw new SecurityException('Insufficient access permissions for required objects.');
        }
        
        // Check field level security
        if (!Schema.sObjectType.PermissionSet.fields.Name.isAccessible() ||
            !Schema.sObjectType.PermissionSet.fields.IsOwnedByProfile.isAccessible()) {
            throw new SecurityException('Insufficient access permissions for PermissionSet fields.');
        }
        
        List<PermissionData> distribution = new List<PermissionData>();
        
        // Ensure offset and limit are not null and have valid values
        Integer queryOffset = offset != null ? offset : 0;
        Integer queryLimit = plimit != null ? Math.min(plimit, 1000) : 10; // Default limit if not provided, max 1000
        
        // Prevent negative values
        queryOffset = Math.max(0, queryOffset);
        queryLimit = Math.max(1, queryLimit);

        AggregateResult[] results = [
            SELECT PermissionSet.Name name, 
                   PermissionSet.Id permSetId, 
                   COUNT(Id) userCount
            FROM PermissionSetAssignment
            WHERE PermissionSet.IsOwnedByProfile = false
            WITH SECURITY_ENFORCED
            GROUP BY PermissionSet.Name, PermissionSet.Id
            ORDER BY COUNT(Id) DESC
            LIMIT :queryLimit OFFSET :queryOffset
        ];
        
        for(AggregateResult ar : results) {
            distribution.add(new PermissionData(
                String.valueOf(ar.get('name')),
                Integer.valueOf(ar.get('userCount')),
                String.valueOf(ar.get('permSetId'))
            ));
        }
        return distribution;
    }

    // Add this class definition after the existing inner classes
        public class ClonePattern {
            @AuraEnabled public String label;
            @AuraEnabled public Integer value;
            
            public ClonePattern(String label, Integer value) {
                this.label = label;
                this.value = value;
            }
        }
    @AuraEnabled(cacheable=true)
    public static List<ClonePattern> getCloningPatterns() {
        // Check object permissions
        if (!Schema.sObjectType.User.isAccessible()) {
            throw new SecurityException('Insufficient access permissions for User object.');
        }
        
        // Check field level security
        if (!Schema.sObjectType.User.fields.CreatedDate.isAccessible()) {
            throw new SecurityException('Insufficient access permissions for User.CreatedDate field.');
        }
        
        List<ClonePattern> patterns = new List<ClonePattern>();
        
        // Get cloning patterns for the last 7 days
        for(Integer i = 6; i >= 0; i--) {
            Date currentDate = Date.today().addDays(-i);
            Integer userCount = [SELECT COUNT() 
                               FROM User 
                               WHERE CreatedDate = :currentDate
                               WITH SECURITY_ENFORCED];
            
            patterns.add(new ClonePattern(
                currentDate.format(),
                userCount
            ));
        }
        return patterns;
    }
    @AuraEnabled(cacheable=true)
        public static List<RecentCloneUserLog__c> getCloneHistory() {
            // Check object permissions
            if (!Schema.sObjectType.RecentCloneUserLog__c.isAccessible()) {
                throw new SecurityException('Insufficient access permissions for RecentCloneUserLog__c object.');
            }
            
            // Check field level security
            if (!Schema.sObjectType.RecentCloneUserLog__c.fields.source_User__c.isAccessible() ||
                !Schema.sObjectType.RecentCloneUserLog__c.fields.Name.isAccessible() ||
                !Schema.sObjectType.RecentCloneUserLog__c.fields.UserClonedDate__c.isAccessible()) {
                throw new SecurityException('Insufficient access permissions for RecentCloneUserLog__c fields.');
            }
            
            return [
                SELECT Id, source_User__c, Name, UserClonedDate__c 
                FROM RecentCloneUserLog__c 
                WHERE UserClonedDate__c = LAST_N_DAYS:30 
                WITH SECURITY_ENFORCED
                ORDER BY UserClonedDate__c ASC
            ];
        }

    // Custom exception class for security errors
    public class SecurityException extends Exception {}
}