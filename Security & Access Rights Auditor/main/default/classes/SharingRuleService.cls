public class SharingRuleService {

    public static MetadataService.MetadataPort createService() { 
		MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		  service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
          // service.endpoint_x = 'callout:SA_Audit__Tooling_API_Creds';
		service.timeout_x = 120000;
		return service;
	}
    
    public static void readSettings(String sName) {
        MetadataService.MetadataPort service = createService();
	  service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
           //service.endpoint_x = 'callout:SA_Audit__Tooling_API_Creds';
		//transient MetadataService.SharingCriteriaRule profile = (MetadataService.SharingCriteriaRule) service.readMetadata('SharingCriteriaRule', new String[]{}).getRecords()[0];
        //transient MetadataService.SharingRules rules = (MetadataService.SharingRules) service.readMetadata('SharingRules',new String[]{'Account'}).getRecords()[0];
    	transient SharingRules rules = new SharingRules( (MetadataService.SharingRules) service.readMetadata('SharingRules',new String[]{'Account'}).getRecords()[0]);
    	system.debug('rules:::' + rules);
    }
    
    public class SharingRules {
		public String type = 'SharingRules';
		public String fullName;
		public List<SharingCriteriaRule> sharingCriteriaRules;
		public MetadataService.SharingOwnerRule[] sharingOwnerRules;
		public MetadataService.SharingTerritoryRule[] sharingTerritoryRules;
		
		public SharingRules(MetadataService.SharingRules sr) {
			this.sharingCriteriaRules = new List<SharingCriteriaRule>();
			for (MetadataService.SharingCriteriaRule scr : sr.sharingCriteriaRules) {
				this.sharingCriteriaRules.add(new SharingCriteriaRule(scr));
			}
			this.sharingOwnerRules = sr.sharingOwnerRules;
			this.sharingTerritoryRules = sr.sharingTerritoryRules;
			this.fullName = sr.fullName;
		}
	}
	
	
	public class SharingCriteriaRule {
		public String fullName;
		public String accessLevel;
		//public MetadataService.AccountSharingRuleSettings accountSettings;
		public String description;
		public String label;
		public MetadataService.SharedTo sharedTo;
		public String booleanFilter;
		public List<FilterItem> criteriaItems;
		
		
		public SharingCriteriaRule(MetadataService.SharingCriteriaRule scr) {
			this.fullName = scr.fullName;
			this.accessLevel = scr.accessLevel;
			this.description = scr.description;
			this.label = scr.label;
			this.booleanFilter = booleanFilter;
			this.criteriaItems = new List<FilterItem>();
			for (MetadataService.FilterItem fi : scr.criteriaItems) {
				criteriaItems.add(new FilterItem(fi));
			}
		}
	}
	
	public class FilterItem {
		public String field;
		public String operation;
		public String value;
		public String valueField;
		
		public FilterItem(MetadataService.FilterItem fi) {
			this.field = fi.field;
			this.operation = fi.operation;
			this.value = fi.value;
			this.valueField = fi.valueField;
		}
	}
}