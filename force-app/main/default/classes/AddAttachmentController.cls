public with sharing class AddAttachmentController {
	public transient Blob body { get; set; }
	public String fname { get; set; }
	public Id currentRecordId { get; set; }
	public boolean isError { get; set; }
	
	public AddAttachmentController() {
		isError = false;
		currentRecordId = ApexPages.currentPage().getParameters().get('id');
	}
	
	public void saveAtt(){
		system.debug('body:::' + body);
		system.debug('fname:::' + fname);
		String csvData = EncodingUtil.base64Encode(body);
		system.debug('csvData:::' + csvData);
		CSVIterator it = new CSVIterator(csvData);
		system.debug('it:::' + it);
		while (true) {
			CSVIterator.ROW row = it.nextRow();
			if (row == null) break;
			system.debug('coloana:::' + row.fieldMap.get(it.headerMap.get(1)));
			if(row.fieldMap.get(it.headerMap.get(1)) != null) {
				system.debug('test:::');
				createField('Test_Object__c.' + row.fieldMap.get(it.headerMap.get(1)), row.fieldMap.get(it.headerMap.get(0)), row.fieldMap.get(it.headerMap.get(2)), Integer.valueOf(row.fieldMap.get(it.headerMap.get(3))));
			}
		}
	}
	
	public static MetadataService.MetadataPort createService() { 
		MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		 service.SessionHeader = new MetadataService.SessionHeader_element();
       service.SessionHeader.sessionId = UserInfo.getSessionId();
           //service.endpoint_x = 'callout:SA_Audit__Tooling_API_Creds';
		return service;
	}
	
	public static void createField(String fullName, String label, String type_x, Integer length) {
		MetadataService.MetadataPort service = createService();
		MetadataService.CustomField customField = new MetadataService.CustomField();
		system.debug('fullName::' + fullName);
		customField.fullName = fullName;
		customField.label = label;
		customField.type_x = type_x;
		customField.length = length;
		List<MetadataService.SaveResult> results =
			service.createMetadata(
				new MetadataService.Metadata[] { customField });
		handleSaveResults(results[0]);
	}
	
	public static void handleSaveResults(MetadataService.SaveResult saveResult) {
		// Nothing to see?
		if(saveResult==null || saveResult.success)
			return;
		// Construct error message and throw an exception
		if(saveResult.errors!=null)
		{
			List<String> messages = new List<String>();
			messages.add(
				(saveResult.errors.size()==1 ? 'Error ' : 'Errors ') +
					'occured processing component ' + saveResult.fullName + '.');
			for(MetadataService.Error error : saveResult.errors)
				messages.add(
					error.message + ' (' + error.statusCode + ').' +
					( error.fields!=null && error.fields.size()>0 ?
						' Fields ' + String.join(error.fields, ',') + '.' : '' ) );
			if(messages.size()>0)
				throw new MetadataServiceExamplesException(String.join(messages, ' '));
		}
		if(!saveResult.success)
			throw new MetadataServiceExamplesException('Request failed with no specified error.');
	}
	
	public class MetadataServiceExamplesException extends Exception { }
}