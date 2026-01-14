public with sharing class AccessRiskAnalyzer{
    
    /**
     * Wrapper class for risk analysis results
     */
    public class RiskResult{
        @AuraEnabled public Integer highRiskCount = 0;
        @AuraEnabled public Integer riskScore = 0;
        @AuraEnabled public String riskLevel = 'Low';
        @AuraEnabled public List<String> criticalFindings = new List<String>();
        @AuraEnabled public List<CriticalFinding> criticalFindingsDetailed = new List<CriticalFinding>();
    }
    
    /**
     * Wrapper class for detailed critical findings with source information
     */
    public class CriticalFinding {
        @AuraEnabled public String message;
        @AuraEnabled public String source; // 'system' or 'object'
        @AuraEnabled public String sourceDescription;
        @AuraEnabled public String iconName;
        
        public CriticalFinding(String message, String source, String sourceDescription, String iconName) {
            this.message = message;
            this.source = source;
            this.sourceDescription = sourceDescription;
            this.iconName = iconName;
        }
    }
    /**
     * Analyzes the security risk level of a user based on their permissions
     * @param userId The Id of the user to analyze
     * @return RiskResult containing risk score, level, and critical findings
     */
    @AuraEnabled
    public static RiskResult analyzeUserRisk(Id userId) {
        RiskResult result = new RiskResult();
        UserPermController.UserPermissionAccess perms = UserPermController.getUserPermissionAccess(userId);
        
        // Count unique objects instead of all permission entries
        Set<String> uniqueObjects = new Set<String>();
        for(ObjectPermissions objPerm : perms.objectPermissions) {
            uniqueObjects.add(objPerm.SobjectType);
        }
        Integer uniqueObjectCount = uniqueObjects.size();
        
        // Define risk factors with explanations
        List<RiskCheck> riskChecks = new List<RiskCheck>{
            new RiskCheck(
                perms.systemPermissions.contains('ModifyAllData'),
                50,
                'Modify All Data permission grants full access to all records',
                true,
                'system',
                'System-level permission that provides unrestricted access to all data in the organization',
                'utility:shield'
            ),
            new RiskCheck(
                perms.systemPermissions.contains('ManageUsers'),
                30,
                'Manage Users permission allows user administration privileges',
                true,
                'system',
                'System-level permission that allows creating, editing, and managing user accounts',
                'utility:people'
            ),
            new RiskCheck(
                perms.systemPermissions.contains('ApiEnabled'),
                20,
                'API Access enables programmatic access to data',
                false,
                'system',
                'System-level permission that enables API access for external integrations',
                'utility:connected_apps'
            ),
            new RiskCheck(
                uniqueObjectCount > 100,
                20,
                'Excessive object access (' + uniqueObjectCount + ' unique objects)',
                true,
                'object',
                'Object-level permissions that grant access to an unusually high number of Salesforce objects',
                'utility:database'
            ),
            new RiskCheck(
                perms.systemPermissions.contains('ModifyAllData') && 
                perms.systemPermissions.contains('ApiEnabled'),
                0, // Score already accounted for in individual checks
                'Critical combination: Modify All Data + API Access',
                true,
                'system',
                'Dangerous combination of system permissions that allows unrestricted data access via API',
                'utility:warning'
            )
        };

        // Process risk checks
        for(RiskCheck check : riskChecks) {
            if(check.condition) {
                result.riskScore += check.score;
                if(check.isCritical) {
                    result.criticalFindings.add(check.message);
                    result.criticalFindingsDetailed.add(new CriticalFinding(
                        check.message,
                        check.source,
                        check.sourceDescription,
                        check.iconName
                    ));
                    result.highRiskCount++;
                }
            }
        }

        // Cap maximum score at 100
        result.riskScore = Math.min(result.riskScore, 100);
        
        // Determine risk level based on score
        if (result.riskScore >= 80) {
            result.riskLevel = 'Critical';
        } else if (result.riskScore >= 50) {
            result.riskLevel = 'High';
        } else if (result.riskScore >= 20) {
            result.riskLevel = 'Medium';
        } else {
            result.riskLevel = 'Low';
        }
        
        return result;
    }
    
    /**
     * Bulk version of analyzeUserRisk to avoid SOQL limits when processing multiple users
     * @param userIds Set of user Ids to analyze
     * @return Map of user Id to RiskResult
     */
    public static Map<Id, RiskResult> analyzeUserRiskBulk(Set<Id> userIds) {
        Map<Id, RiskResult> results = new Map<Id, RiskResult>();
        
        // Initialize results map
        for (Id userId : userIds) {
            results.put(userId, new RiskResult());
        }
        
        // Get user permissions in bulk
        Map<Id, UserPermController.UserPermissionAccess> userPermsMap = UserPermController.getUserPermissionAccessBulk(userIds);
        
        // Process each user's risk
        for (Id userId : userIds) {
            UserPermController.UserPermissionAccess perms = userPermsMap.get(userId);
            RiskResult result = results.get(userId);
            
            // Count unique objects instead of all permission entries
            Set<String> uniqueObjects = new Set<String>();
            for(ObjectPermissions objPerm : perms.objectPermissions) {
                uniqueObjects.add(objPerm.SobjectType);
            }
            Integer uniqueObjectCount = uniqueObjects.size();
            
            // Define risk factors with explanations
            List<RiskCheck> riskChecks = new List<RiskCheck>{
                new RiskCheck(
                    perms.systemPermissions.contains('ModifyAllData'),
                    50,
                    'Modify All Data permission grants full access to all records',
                    true,
                    'system',
                    'System-level permission that provides unrestricted access to all data in the organization',
                    'utility:shield'
                ),
                new RiskCheck(
                    perms.systemPermissions.contains('ManageUsers'),
                    30,
                    'Manage Users permission allows user administration privileges',
                    true,
                    'system',
                    'System-level permission that allows creating, editing, and managing user accounts',
                    'utility:people'
                ),
                new RiskCheck(
                    perms.systemPermissions.contains('ApiEnabled'),
                    20,
                    'API Access enables programmatic access to data',
                    false,
                    'system',
                    'System-level permission that enables API access for external integrations',
                    'utility:connected_apps'
                ),
                new RiskCheck(
                    uniqueObjectCount > 100,
                    20,
                    'Excessive object access (' + uniqueObjectCount + ' unique objects)',
                    true,
                    'object',
                    'Object-level permissions that grant access to an unusually high number of Salesforce objects',
                    'utility:database'
                ),
                new RiskCheck(
                    perms.systemPermissions.contains('ModifyAllData') && 
                    perms.systemPermissions.contains('ApiEnabled'),
                    0, // Score already accounted for in individual checks
                    'Critical combination: Modify All Data + API Access',
                    true,
                    'system',
                    'Dangerous combination of system permissions that allows unrestricted data access via API',
                    'utility:warning'
                )
            };

            // Process risk checks
            for(RiskCheck check : riskChecks) {
                if(check.condition) {
                    result.riskScore += check.score;
                    if(check.isCritical) {
                        result.criticalFindings.add(check.message);
                        result.criticalFindingsDetailed.add(new CriticalFinding(
                            check.message,
                            check.source,
                            check.sourceDescription,
                            check.iconName
                        ));
                        result.highRiskCount++;
                    }
                }
            }

            // Cap maximum score at 100
            result.riskScore = Math.min(result.riskScore, 100);
            
            // Determine risk level based on score
            if (result.riskScore >= 80) {
                result.riskLevel = 'Critical';
            } else if (result.riskScore >= 50) {
                result.riskLevel = 'High';
            } else if (result.riskScore >= 20) {
                result.riskLevel = 'Medium';
            } else {
                result.riskLevel = 'Low';
            }
        }
        
        return results;
    }

    // Helper class for risk factors
    private class RiskCheck {
        Boolean condition;
        Integer score;
        String message;
        Boolean isCritical;
        String source;
        String sourceDescription;
        String iconName;
        
        RiskCheck(Boolean condition, Integer score, String message, Boolean isCritical, String source, String sourceDescription, String iconName) {
            this.condition = condition;
            this.score = score;
            this.message = message;
            this.isCritical = isCritical;
            this.source = source;
            this.sourceDescription = sourceDescription;
            this.iconName = iconName;
        }
    }
}