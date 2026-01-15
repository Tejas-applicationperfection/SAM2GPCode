@isTest
public class WelcomeControllerTest {
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
		WelcomeController ctrl = new WelcomeController();
		System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
		MetadataService metaDataService = new MetadataService();
		MetadataService.MetadataPort metaDataPort = new MetadataService.MetadataPort();
		ctrl.checkMetadataAPIConnection();
		//system.assertNotEquals(ctrl.MetadataApiException, null);
		ctrl.MetadataResponse = 'Test ';
		ctrl.displayMetadataResponse();
		system.assertEquals(ctrl.MetadataConnectionWarning, true);
		ctrl.MetadataResponse = '';
		ctrl.displayMetadataResponse();
		system.assertEquals(ctrl.MetadataConnectionWarning, false);
		ctrl.inputRemoteSiteName();
		system.assertEquals(ctrl.existRemoteSiteName, false);
		ctrl.Back();
		Test.stopTest(); 
	}
}