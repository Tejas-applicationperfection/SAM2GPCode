public with sharing class PermissionAccessDetectorController {
    
    /**
     * Main method to detect access for LWC
     */
    @AuraEnabled
    public static AccessResult detectAccess(String principalType, String principalName, String resourceType, String resourceName) {
        try {
            // Create request for the invocable method
            PermissionAccessDetector.AccessRequest req = new PermissionAccessDetector.AccessRequest();
            req.principalType = principalType;
            req.principalName = principalName;
            req.resourceType = resourceType;
            req.resourceName = resourceName;
            
            // Call the invocable method
            List<PermissionAccessDetector.AccessRequest> requests = new List<PermissionAccessDetector.AccessRequest>{req};
            List<PermissionAccessDetector.AccessResult> results = PermissionAccessDetector.detectAccess(requests);
            
            if (!results.isEmpty()) {
                PermissionAccessDetector.AccessResult result = results[0];
                return new AccessResult(result.accessSource, result.explanation);
            }
            
            return new AccessResult('Error', 'No results returned');
            
        } catch (Exception e) {
            throw new AuraHandledException('Error detecting access: ' + e.getMessage());
        }
    }
    
    /**
     * Execute dynamic SOQL query
     */
    @AuraEnabled
    public static List<SObject> executeQuery(String soql) {
        try {
            return Database.query(soql);
        } catch (Exception e) {
            throw new AuraHandledException('Query error: ' + e.getMessage());
        }
    }
    
    /**
     * Search for users
     */
    @AuraEnabled(cacheable=true)
    public static List<SearchResult> searchUsers(String searchTerm) {
        try {
            String searchPattern = '%' + searchTerm + '%';
            List<SearchResult> results = new List<SearchResult>();
            
            for (User u : [
                SELECT Name, Username, Email 
                FROM User 
                WHERE Name LIKE :searchPattern 
                   OR Username LIKE :searchPattern
                   OR Email LIKE :searchPattern
                ORDER BY Name
                LIMIT 10
            ]) {
                results.add(new SearchResult(u.Name, u.Username));
            }
            
            return results;
        } catch (Exception e) {
            throw new AuraHandledException('Error searching users: ' + e.getMessage());
        }
    }
    
    /**
     * Search for profiles
     */
    @AuraEnabled(cacheable=true)
    public static List<SearchResult> searchProfiles(String searchTerm) {
        try {
            String searchPattern = '%' + searchTerm + '%';
            List<SearchResult> results = new List<SearchResult>();
            
            for (Profile p : [
                SELECT Name 
                FROM Profile 
                WHERE Name LIKE :searchPattern
                ORDER BY Name
                LIMIT 10
            ]) {
                results.add(new SearchResult(p.Name, null));
            }
            
            return results;
        } catch (Exception e) {
            throw new AuraHandledException('Error searching profiles: ' + e.getMessage());
        }
    }
    
    /**
     * Search for permission sets
     */
    @AuraEnabled(cacheable=true)
    public static List<SearchResult> searchPermissionSets(String searchTerm) {
        try {
            String searchPattern = '%' + searchTerm + '%';
            List<SearchResult> results = new List<SearchResult>();
            
            for (PermissionSet ps : [
                SELECT Name, Label 
                FROM PermissionSet 
                WHERE (Name LIKE :searchPattern OR Label LIKE :searchPattern)
                  AND IsOwnedByProfile = false
                ORDER BY Label
                LIMIT 10
            ]) {
                results.add(new SearchResult(ps.Name, ps.Label));
            }
            
            return results;
        } catch (Exception e) {
            throw new AuraHandledException('Error searching permission sets: ' + e.getMessage());
        }
    }
    
    /**
     * Wrapper class for search results
     */
    public class SearchResult {
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        
        public SearchResult(String name, String label) {
            this.name = name;
            this.label = label != null ? label : name;
        }
    }
    
    /**
     * Wrapper class for access results
     */
    public class AccessResult {
        @AuraEnabled public String accessSource;
        @AuraEnabled public String explanation;
        
        public AccessResult(String accessSource, String explanation) {
            this.accessSource = accessSource;
            this.explanation = explanation;
        }
    }
}