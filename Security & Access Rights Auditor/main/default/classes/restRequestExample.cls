public class restRequestExample {
    public Static String response = '' ;
    public Static String oAuthResponse;
    public Static String InstanceURL = '';
    public Static String accessToken = '';
    public static string endPointURL = '';
    public static Map<String, Object> m = new  Map<String, Object> ();
  
                                                  // Method to generate Http Request
                                                  
                                                  public static HttpRequest httpRequestGenerator(String reqMethod, String endpoint, String accessToken, String reqBody){
                                                      String authorizationHeader = 'Bearer ' +accessToken;
                                                      HttpRequest httpRequest = new HttpRequest();
                                                      httpRequest.setMethod(reqMethod);
                                                      httpRequest.setEndpoint(endpoint);
                                                      httpRequest.setHeader('Authorization', authorizationHeader);
                                                      httpRequest.setHeader('Content-Type', 'application/json;charset=UTF-8');
                                                      httpRequest.setBody(reqBody);
                                                      return httpRequest;
                                                  }
                                                  
                                                  // update Field on Account — PATCH Method is used
                                                  public static void updateFieldOnAccount(String accessToken, string instanceURL ){
                                                      endPointURL = instanceURL + '/services/data/v20.0/sobjects/Account/0014K00000CVFzb';
                                                      Http http = new Http();
                                                      HttpRequest httpRequest = httpRequestGenerator('PUT', endPointURL, accessToken, null);
                                                      HTTPResponse httpResponse = http.send(httpRequest);
                                                      system.debug('httpResponse -> '+ httpResponse);
                                                      system.debug('httpResponse.getHeaderKeys() -> '+ httpResponse.getHeaderKeys());
                                                  }
}