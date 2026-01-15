public with sharing class WelcomeController {
	public String Host { get; set; }
    public String callURL { get; set; }
	public String RemoteSiteName { get; set; }
	public String MetadataResponse { get; set; }
	public Boolean MetadataConnectionWarning { get; set; }
	public String MetadataApiException { get; set; }
	public Boolean existRemoteSiteName { get; set; }
	public Boolean isFromIntel { get; set; }
	
	public WelcomeController() {
		isFromIntel = false;
        
        Map<String,String> paramsMap = ApexPages.currentPage().getParameters();
        if (paramsMap != null && paramsMap.containsKey('retPage') && paramsMap.get('retPage') == 'Intel') {
            isFromIntel = true;
        }
        
        if (isFromIntel) {
            RemoteSiteName = 'endpoint_metadata_report';
        } else {
			RemoteSiteName = 'endpoint_metadata';
        }
        system.debug('isFromIntel == ' + isFromIntel);
		
	}
	
	public PageReference checkMetadataAPIConnection() {
        system.debug('isFromIntel1 == ' + isFromIntel);
		// Get Host Domain
		if (isFromIntel) {
            Host = System.URL.getOrgDomainUrl().toExternalForm();
            //Host = ApexPages.currentPage().getHeaders().get('Host');//URL.getSalesforceBaseUrl().toExternalForm();
        } else {
            Host = 'https://' + ApexPages.currentPage().getHeaders().get('Host');
        }
        callURL = 'https://' + ApexPages.currentPage().getHeaders().get('Host');
        system.debug('RemoteSiteName::' + RemoteSiteName);
        system.debug('Host::' + Host);
		system.debug('callURL::' + callURL);		
		// Attempt to connect to the Metadata API
		MetadataConnectionWarning = false;
        Boolean existConnection = true;
		
        if (isFromIntel) {
            existConnection = RollupService.checkFolderAPIConnection();
        } else {
            existConnection = RollupService.checkMetadataAPIConnection();
        }        
		if(!existConnection) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Unable to connect to the Salesforce Metadata API.'));
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'A Remote Site Setting must be created in your org before you can use this tool.'));
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Press the Create Remote Site Setting button to perform this step or refer to the post install step below to perform this manually.'));
			MetadataConnectionWarning = true;
			MetadataApiException = '';
			if(RollupService.LastMetadataAPIConnectionException != null) {
				MetadataApiException = RollupService.LastMetadataAPIConnectionException.getMessage();
			}
		}
		
		return null;
	}
	
	public PageReference displayMetadataResponse() {
		// Display the response from the client side Metadata API callout
		if(metadataResponse.length()==0) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Remote Site Setting ' + RemoteSiteName + ' has been created.' ));
			MetadataConnectionWarning = false;
		}
		else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, metadataResponse));
			MetadataConnectionWarning = true;
			if(metadataResponse.contains('This Remote Site Name already exists or has been previously used')) {
				existRemoteSiteName = true;
			}
		}
		return null;
	}
	
	public PageReference inputRemoteSiteName() {
		existRemoteSiteName = false;
		return checkMetadataAPIConnection();
	}
	
	public PageReference Back() {
		String retPage =  ApexPages.currentPage().getParameters().get('retPage');
		system.debug('retPage:::' + retPage);
		PageReference pageRef = new PageReference('/apex/' + retPage);
		pageRef.setRedirect(true);
		return pageRef;
	}
}