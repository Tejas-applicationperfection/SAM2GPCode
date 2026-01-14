public with sharing class DataDictionaryService {
    
    public static Map<String,CustomObject> objMap { get; set; }
    
    public static MetadataService.MetadataPort createService() { 
		MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		 service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
          // service.endpoint_x = 'callout:SA_Audit__Tooling_API_Creds';
		service.timeout_x = 60000;
		return service;
	}
    
    public static CustomObject retrieveCustomObjectMetadata(String objName) {
    	if (objMap != null && objMap.containsKey(objName)) {
    		system.debug('exista::');
	    	return objMap.get(objName);
    	} else if (objMap == null) {
    		objMap = new Map<String,CustomObject>();
    	}
    	
	    system.debug('NU exista::');
	    system.debug('customObjectMetadata::' + objName);
	    MetadataService.MetadataPort service = createService();
	    
	    CustomObject obj = new CustomObject((MetadataService.CustomObject) 
	                                        service.readMetadata('CustomObject', new String[] {objName}).getRecords()[0]);
	   system.debug('customObjectMetadata::' + obj);
	    objMap.put(objName, obj);
	    return obj;
    }
    
	public class CustomObject extends MetadataService.Metadata {
		public String type = 'CustomObject';
		public String fullName;
		private String[] fullName_type_info = new String[]{'fullName',MetadataService.SOAP_M_URI,null,'0','1','false'};
		public String label;
		public List<CustomField> fields;
		
		public CustomObject(MetadataService.CustomObject co) {
			this.fullName = fullName;
			this.label = label;
			this.fields = new List<CustomField>();
			if (co != null && co.fields != null) {
				for (MetadataService.CustomField cf : co.fields) {
					this.fields.add(new CustomField(cf));
				}
			}
		}
	}
	
	public class CustomField {
		public String type = 'CustomField';
		public String fullName;
		private String[] fullName_type_info = new String[]{'fullName',MetadataService.SOAP_M_URI,null,'0','1','false'};
		public String label;
		public String description;
		public String inlineHelpText;
		public String defaultValue;
		public String formula;
		public Integer length;
		public String maskChar;
		public String maskType;
		public Integer precision;
		public String referenceTargetField;
		public String referenceTo;
		public String relationshipLabel;
		public String relationshipName;
		public Integer scale;
		public String type_x;
		public ValueSet valueSet;
		public Integer visibleLines;
		
		public CustomField(MetadataService.CustomField cf) {
			this.fullName = cf.fullName;
			this.label = cf.label;
			this.description = cf.description;
			this.inlineHelpText = cf.inlineHelpText;
			this.defaultValue = cf.defaultValue;
			this.formula = cf.formula;
			this.length = cf.length;
			this.maskChar = cf.maskChar;
			this.maskType = cf.maskType;
			this.precision = cf.precision;
			this.referenceTargetField = cf.referenceTargetField;
			this.referenceTo = cf.referenceTo;
			this.relationshipLabel = cf.relationshipLabel;
			this.relationshipName = cf.relationshipName;
			this.scale = cf.scale;
			this.type_x = cf.type_x;
			this.valueSet = new ValueSet(cf.valueSet);
			this.visibleLines = cf.visibleLines;
		}
	}
	
	public class ValueSet {
		public String controllingField;
		public Boolean restricted;
		public ValueSetValuesDefinition valueSetDefinition;
		public String valueSetName;
		//public MetadataService.ValueSettings[] valueSettings;
		
		public ValueSet(MetadataService.ValueSet valueSet) {
			if (valueSet != null) {
				this.controllingField = valueSet.controllingField;
				this.restricted = valueSet.restricted;
				this.valueSetName = valueSet.valueSetName;
                
				this.valueSetDefinition = new ValueSetValuesDefinition(valueSet.valueSetDefinition);
			}
		}
	}
	
	public class ValueSetValuesDefinition {
		public Boolean sorted;
		public List<CustomValue> value;
		
		public ValueSetValuesDefinition(MetadataService.ValueSetValuesDefinition valueSetDefinition) {
			if (valueSetDefinition != null) {
				this.sorted = valueSetDefinition.sorted;
				//CustomFieldthis.value = valueSetDefinition.value;
				this.value = new List<CustomValue>();
				if (valueSetDefinition.value != null) {
					for (MetadataService.CustomValue val : valueSetDefinition.value) {
						this.value.add(new CustomValue(val));
					}
				}
			}
		}
	}
	
	public virtual class CustomValue {
		public String type = 'CustomValue';
        
        public String fullName;
      
        
        public CustomValue(MetadataService.CustomValue value) {
        	this.fullName = value.fullName;
           //  system.debug('$#$#type'+ type);
            system.debug('$#$#value'+ value);
             // system.debug('$#$#fullname'+ fullName);
        }
	}
}