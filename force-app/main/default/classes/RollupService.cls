global with sharing class RollupService {
    global static Exception LastMetadataAPIConnectionException { get; private set;}
    
    global static Boolean checkMetadataAPIConnection() {
        try {
            MetadataService.MetadataPort service = new MetadataService.MetadataPort();
         service.SessionHeader = new MetadataService.SessionHeader_element();
       service.SessionHeader.sessionId = UserInfo.getSessionId();
          // service.endpoint_x = 'callout:SA_Audit__Tooling_API_Creds';
            List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();		
            MetadataService.ListMetadataQuery remoteSites = new MetadataService.ListMetadataQuery();
            remoteSites.type_x = 'RemoteSiteSetting';
            queries.add(remoteSites);
            system.debug('queries::' + queries);
            service.listMetadata(queries, 44);
        } catch (Exception e) {
            LastMetadataAPIConnectionException = e;
            system.debug('LastMetadataAPIConnectionException::' + LastMetadataAPIConnectionException);
            if(e.getMessage().contains('Unauthorized endpoint, please check Setup->Security->Remote site settings')) {
                return false;
            }
        }
        LastMetadataAPIConnectionException = null;
        return true;
    }
    
    public static boolean checkFolderAPIConnection() {
        try {
            getReportShareDetails();
        }  catch (Exception e) {
            LastMetadataAPIConnectionException = e;
            system.debug('res==' + e.getMessage());
            if(e.getMessage().containsIgnoreCase('Unauthorized endpoint, please check Setup->Security->Remote site settings')) {
                return false;
            }
        }
        LastMetadataAPIConnectionException = null;
        return true;
    }
    
    public static String getReportShareDetails() {
        HttpRequest req = new HttpRequest();
        String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm();//URL.getSalesforceBaseUrl().toExternalForm();
        IntelController.staticSfdcUrl = sfdcURL;
        system.debug('sfdcURL:::' + sfdcURL);
        system.debug('IntelController.staticSfdcUrl:::' + IntelController.staticSfdcUrl);
        req.setEndpoint(sfdcURL + '/services/data/v45.0/folders/');
        req.setMethod('GET');
        
        // As well as the header and header information 
        String sessionId = UserInfo.getSessionId();
      //    String sessionId = 'callout:SA_Audit__Tooling_API_Creds';
        String authorizationHeader = 'OAuth ' + sessionId;
        req.setHeader('Authorization', authorizationHeader);
        //Authorization: OAuth 
        
        // A response object is generated as a result of the request   
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        return res.getBody();
    }
}