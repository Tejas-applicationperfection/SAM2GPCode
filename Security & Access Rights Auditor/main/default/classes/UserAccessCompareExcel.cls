public with sharing class UserAccessCompareExcel {
    @AuraEnabled
    public static String xmlheader { get; set; }
    @AuraEnabled
    public static List<String> fields { get; set; }
    @AuraEnabled
    public static List<UserWrapper> userWrappers { get; set; }
    @AuraEnabled
    public static String delimitedKeys { get; set; }

    public UserAccessCompareExcel() {
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        fields = new List<String>();
        userWrappers = new List<UserWrapper>();
        delimitedKeys = '';

        String userParam = ApexPages.currentPage().getParameters().get('selectedUsers');
        List<String> userr = new List<String>();
        if (userParam != null) {
            userr = userParam.split(',');
        }

        fetchTableDataOption37(userr);

        // Create a delimited string of all keys
        Set<String> allKeys = new Set<String>();
        for (UserWrapper wrapper : userWrappers) {
            allKeys.addAll(wrapper.fieldValues.keySet());
        }
        delimitedKeys = String.join(allKeys, ',');
    }

    public class UserWrapper {
        public String userId { get; set; }
        public String userName { get; set; }
        public Map<String, Boolean> fieldValues { get; set; }

        public UserWrapper(String userId, String userName, Map<String, Boolean> fieldValues) {
            this.userId = userId;
            this.userName = userName;
            this.fieldValues = fieldValues;
        }
    }

    @AuraEnabled
    public static void fetchTableDataOption37(List<String> selectedUsers) {
        if (selectedUsers.size() < 2) {
            throw new AuraHandledException('Please select at least two users.');
        }

        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('User').getDescribe().fields.getMap();
        List<String> booleanFields = new List<String>();
        List<String> booleanFieldLabels = new List<String>();

        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            if (fieldDescribe.getType() == Schema.DisplayType.Boolean) {
                booleanFields.add(fieldName);
                booleanFieldLabels.add(fieldDescribe.getLabel());
            }
        }

        if (booleanFields.isEmpty()) {
            throw new AuraHandledException('No boolean fields found on User object.');
        }

        fields = booleanFieldLabels;

        userWrappers = new List<UserWrapper>();

        for (String userId : selectedUsers) {
            User user = fetchUserBooleanFields(userId, booleanFields);
            if (user == null) {
                continue;
            }

            Map<String, Boolean> fieldValues = new Map<String, Boolean>();
            for (String fieldName : booleanFields) {
                fieldValues.put(fieldName, (Boolean) user.get(fieldName));
            }

            userWrappers.add(new UserWrapper(userId, user.Name, fieldValues));
        }
    }

    public static User fetchUserBooleanFields(String userId, List<String> booleanFields) {
        if (!booleanFields.isEmpty()) {
            String query = 'SELECT Id, Name, ' + String.join(booleanFields, ',') + ' FROM User WHERE Id = :userId';
            return Database.query(query);
        }
        return null;
    }
}