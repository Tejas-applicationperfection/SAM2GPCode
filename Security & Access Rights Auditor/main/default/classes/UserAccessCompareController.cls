public with sharing class UserAccessCompareController {
    @AuraEnabled
    public String xmlheader {get; set;}
    
    
    // @AuraEnabled
    
    //public static List<UserWrapper> UserWrap { get; set; }
    
    // Wrapper class to hold UserId, UserName, Fields, and values for each user
    
    public class UserWrapper {
        
        @AuraEnabled
        public String userId { get; set; }
        @AuraEnabled
        public String userName { get; set; }
        @AuraEnabled
        public List<String> fields { get; set; } // List of field labels
        @AuraEnabled
        public List<Boolean> fieldValues1 { get; set; } // Values of User 1 for each field
        @AuraEnabled
        public List<Boolean> fieldValues2 { get; set; } // Values of User 2 for each field
        
        public UserWrapper(String userId, String userName, List<String> fields, List<Boolean> fieldValues1, List<Boolean> fieldValues2) {
            this.userId = userId;
            this.userName = userName;
            this.fields = fields;
            this.fieldValues1 = fieldValues1;
            this.fieldValues2 = fieldValues2;
        }
    }
    public UserAccessCompareController() {
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';


    }
        
    @AuraEnabled
    public static UserWrapper getUserBooleanFieldData(List<String> selectedUsers) {
        String userId1;
        String userId2;
        
        if (selectedUsers.size() > 1) {
            userId1 = selectedUsers.get(0); // First ID
            userId2 = selectedUsers.get(1); // Second ID
        } else {
            System.debug('List does not contain at least two IDs');
            return null;
        }
        
        // Fetch boolean fields of the User object
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('User').getDescribe().fields.getMap();
        List<String> booleanFields = new List<String>();
        List<String> booleanFieldLabels = new List<String>();
        
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            if (fieldDescribe.getType() == Schema.DisplayType.Boolean) {
                booleanFields.add(fieldName);
                booleanFieldLabels.add(fieldDescribe.getLabel()); // Store the label of the field
            }
        }
        
        if (booleanFields.isEmpty()) {
            System.debug('No boolean fields found on User object.');
            return null;
        }
        
        // Fetch data for both users
        User user1 = fetchUserBooleanFields(userId1, booleanFields);
        User user2 = fetchUserBooleanFields(userId2, booleanFields);
        
        if (user1 == null || user2 == null) {
            System.debug('Could not fetch user data.');
            return null;
        }
        
        // Prepare values for comparison
        List<Boolean> fieldValues1 = new List<Boolean>();
        List<Boolean> fieldValues2 = new List<Boolean>();
        
        for (String fieldName : booleanFields) {
            fieldValues1.add((Boolean) user1.get(fieldName));
            fieldValues2.add((Boolean) user2.get(fieldName));
        }
        
        return new UserWrapper(userId1 + ' vs ' + userId2, user1.Name + ' vs ' + user2.Name, booleanFieldLabels, fieldValues1, fieldValues2);
    }
    
    // Method to fetch boolean fields for a given User ID
    public static User fetchUserBooleanFields(String userId, List<String> booleanFields) {
        if (!booleanFields.isEmpty()) {
            String query = 'SELECT Id, Name, ' + String.join(booleanFields, ',') + ' FROM User WHERE Id = :userId';
            system.debug('query' + query);
            return Database.query(query);
        }
        return null;
    }
}

/*public class UserAccessCompareController {

// Wrapper class to hold UserId, UserName, and User object
public class UserWrapper {
@AuraEnabled
public String userId { get; set; }
@AuraEnabled
public String userName { get; set; }
//  @AuraEnabled
//  public String Fields { get; set; } //fieldsname
//  @AuraEnabled
// public Boolean FieldValues1 { get; set; } //user1Values  i.e True || False
//    @AuraEnabled
// public Boolean FieldValues2 { get; set; }  //user2Values  i.e True || False
@AuraEnabled
public User userRecord { get; set; }
public UserWrapper(String userId, String userName, User userRecord) {
this.userId = userId;
this.userName = userName;
//  this.Fields = Fields;
//  this.FieldValues1 = FieldValues1;
// this.FieldValues2 = FieldValues2;
this.userRecord = userRecord;
}
}


@AuraEnabled
public static List<UserWrapper> getUserBooleanFieldData(List<string> SelectedUsers) {
String userId1;
String userId2;
if (SelectedUsers.size() > 1) {
userId1 = SelectedUsers.get(0); // First ID
userId2 = SelectedUsers.get(1); // Second ID
} else {
// Handle cases where there are fewer than two elements
System.debug('List does not contain at least two IDs');
}

// List to hold UserWrapper objects
List<UserWrapper> userWrappers = new List<UserWrapper>();

// Fetch user data for the first user ID
system.debug('userId1'+userId1);
User user1 = fetchUserBooleanFields(userId1);
if (user1 != null) {
userWrappers.add(new UserWrapper(userId1, user1.Name, user1));
}

// Fetch user data for the second user ID
system.debug('userId2'+userId2);
User user2 = fetchUserBooleanFields(userId2);
if (user2 != null) {
userWrappers.add(new UserWrapper(userId2, user2.Name, user2));
}
system.debug('userWrappers'+userWrappers);
return userWrappers;
}

// Method to fetch boolean fields for a given User ID
private static User fetchUserBooleanFields(String userId) {
// Get all fields of the User object
Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('User').getDescribe().fields.getMap();
// List to store boolean fields
List<String> booleanFields = new List<String>();

// Iterate over all fields to find boolean ones
for (String fieldName : fieldMap.keySet()) {
Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
if (fieldDescribe.getType() == Schema.DisplayType.Boolean) {
booleanFields.add(fieldName);
}
}
//now booleanFields contains the fields name

// Dynamically query the boolean fields for the provided user ID
if (!booleanFields.isEmpty()) {
String query = 'SELECT Id, Name, ' + String.join(booleanFields, ',') + ' FROM User WHERE Id = :userId';
return Database.query(query);
} else {
System.debug('No boolean fields found on User object.');
return null;
}
}
}*/