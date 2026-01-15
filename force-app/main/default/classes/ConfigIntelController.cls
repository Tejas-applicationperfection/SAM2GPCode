public with sharing class ConfigIntelController {
    @AuraEnabled(cacheable=true)
    public static ConfigReportData getValidationRules(List<String> filters) {
        // Always include Validation Rule Name as the first column
        List<String> orderedFilters = new List<String>{'validationRuleName'};
        for (String filter : filters) {
            if (filter != 'validationRuleName') orderedFilters.add(filter);
        }

        // Tooling API query for ValidationRule metadata
        String soql = 'SELECT Id, ValidationName, NamespacePrefix, Active, TableEnumOrId, Description, ErrorDisplayField, ErrorMessage, Formula FROM ValidationRule LIMIT 1000';
        List<Map<String, Object>> rules = queryTooling(soql);

        List<ConfigReportRow> rows = new List<ConfigReportRow>();
        for (Map<String, Object> rule : rules) {
            ConfigReportRow row = new ConfigReportRow();
            row.values = new List<String>();
            for (String field : orderedFilters) {
                row.values.add(getFieldValue(rule, field));
            }
            rows.add(row);
        }

        ConfigReportData data = new ConfigReportData();
        data.headers = orderedFilters;
        data.rows = rows;
        return data;
    }

    // Helper to call Tooling API and return a list of maps
    private static List<Map<String, Object>> queryTooling(String soql) {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v57.0/tooling/query/?q=' + EncodingUtil.urlEncode(soql, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> records = (List<Object>) json.get('records');
            for (Object rec : records) {
                results.add((Map<String, Object>) rec);
            }
        }
        return results;
    }

    // Returns the correct value for each column, handling nulls and formatting as needed
    private static String getFieldValue(Map<String, Object> rule, String field) {
        switch on field {
            when 'validationRuleName' { return (String)rule.get('ValidationName'); }
            when 'namespacePrefix' { return (String)rule.get('NamespacePrefix'); }
            when 'active' { return (rule.get('Active') == true) ? 'YES' : 'NO'; }
            when 'object' { return (String)rule.get('TableEnumOrId'); }
            when 'description' { return (String)rule.get('Description'); }
            when 'errorDisplayField' { return (String)rule.get('ErrorDisplayField'); }
            when 'errorMessage' { return (String)rule.get('ErrorMessage'); }
            when 'criteria' { return (String)rule.get('Formula'); }
            when else { return ''; }
        }
    }

    public class ConfigReportData {
        @AuraEnabled public List<String> headers { get; set; }
        @AuraEnabled public List<ConfigReportRow> rows { get; set; }
    }
    public class ConfigReportRow {
        @AuraEnabled public List<String> values { get; set; }
    }
}