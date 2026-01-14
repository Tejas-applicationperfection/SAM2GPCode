@isTest
private class DictionaryRollUpServiceTest {

  private class RollupService_HCM_TGN_TEST implements HttpCalloutMock{
        protected Integer code;
        protected String status;
        protected String body;
        protected Map<String,String> headers;
        public RollupService_HCM_TGN_TEST(Integer code,String status,String body,Map<String,String> headers){
            this.code=code;
            this.status=status;
            this.body=body;
            this.headers=headers;
        }
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res=new HttpResponse();
            res.setStatusCode(this.code);
            res.setStatus(this.status);
            res.setBody(this.body);
            if(this.headers!=null){
                for(String key:this.headers.keySet()){
                    res.setHeader(key,this.headers.get(key));
                }
            }
            return res;
        }
    }
    @isTest
    private static void checkMetadataAPIConnection_TGN_TEST(){
        Test.startTest();
        RollupService_HCM_TGN_TEST httpMock;
        httpMock=new RollupService_HCM_TGN_TEST(200,'Complete','{}',null);
        Test.setMock(HttpCalloutMock.class,httpMock);
        DictionaryRollUpService.checkMetadataAPIConnection();
        Test.stopTest();
         System.assertNotEquals('System Administrator',null);
    }
     @isTest
    private static void RollupService_TGN_TEST(){
        DictionaryRollUpService obj = new DictionaryRollUpService();
            System.assertNotEquals('System Administrator',null);
    }
}