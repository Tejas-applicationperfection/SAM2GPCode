@isTest
public class DictionaryWelcomeControllerTest {
    public class WebServiceMockImpl implements WebServiceMock {
        public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) { 
            MetadataService.listMetadataResponse_element remoteResponse = new MetadataService.listMetadataResponse_element();
            MetadataService.FileProperties fp = new MetadataService.FileProperties();
            fp.type_x = 'RemoteSiteSetting';
            fp.fullName = 'endpoint';
            remoteResponse.result = new List<MetadataService.FileProperties>{fp};
            response.put('response_x', remoteResponse);
        }
    }

    static testMethod void testDictionaryWelcomeController() {
        Test.startTest();
        
        // Initialize controller
        DictionaryWelcomeController ctrl = new DictionaryWelcomeController();
        
        // Test isFromIntel condition when 'retPage' parameter is 'Intel'
        ApexPages.currentPage().getParameters().put('retPage', 'Intel');
        ctrl = new DictionaryWelcomeController();
        System.assertEquals(true, ctrl.isFromIntel, 'isFromIntel should be true when retPage is Intel');
        
        // Set Mock and test checkMetadataAPIConnection
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        ctrl.checkMetadataAPIConnection();
        
        // Test inputRemoteSiteName method
        ctrl.inputRemoteSiteName();
        
        // Test displayMetadataResponse with empty response
        ctrl.MetadataResponse = '';
        ctrl.displayMetadataResponse();
        System.assertEquals(false, ctrl.MetadataConnectionWarning, 'MetadataConnectionWarning should be false when response is empty');

        // Test displayMetadataResponse with error message in response
        ctrl.MetadataResponse = 'This Remote Site Name already exists or has been previously used';
        ctrl.displayMetadataResponse();
        System.assertEquals(true, ctrl.existRemoteSiteName, 'existRemoteSiteName should be true for specific error message');
        System.assertEquals(true, ctrl.MetadataConnectionWarning, 'MetadataConnectionWarning should be true when there is an error');

        // Test Back method
        ApexPages.currentPage().getParameters().put('retPage', 'TestPage');
        PageReference result = ctrl.Back();
        System.assertEquals('/apex/SA_Audit__TestPage', result.getUrl(), 'Back method should redirect to the retPage URL');
        
        Test.stopTest();
    }
}



/*@isTest
public class DictionaryWelcomeControllerTest {
	public class WebServiceMockImpl implements WebServiceMock {
		public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) { 
		
			MetadataService.listMetadataResponse_element remoteResponse = new MetadataService.listMetadataResponse_element();
			MetadataService.FileProperties fp = new MetadataService.FileProperties();
			fp.type_x = 'RemoteSiteSetting';
			fp.fullName = 'endpoint';
			remoteResponse.result = new List<MetadataService.FileProperties>{fp};
			system.debug('response_x::' + remoteResponse);
			response.put('response_x', remoteResponse);
			return;
		}
	}
    static testMethod void test1() { 
		Test.startTest();
		DictionaryWelcomeController ctrl = new DictionaryWelcomeController();
		System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
		MetadataService metaDataService = new MetadataService();
		MetadataService.MetadataPort metaDataPort = new MetadataService.MetadataPort();
		Test.stopTest(); 
        System.assertNotEquals('System Administrator',null);
	}
}*/