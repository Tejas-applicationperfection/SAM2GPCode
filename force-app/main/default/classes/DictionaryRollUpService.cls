global with sharing class DictionaryRollUpService {
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
}