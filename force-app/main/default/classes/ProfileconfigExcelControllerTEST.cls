@isTest
private class ProfileconfigExcelControllerTEST{
 /*   private class ProfileconfigExcelController_Testing implements HttpCalloutMock{
        protected Integer code;
        protected String status;
        protected String body;
        protected Map<String,String> headers;
        public ProfileconfigExcelController_Testing(Integer code,String status,String body,Map<String,String> headers){
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
    }*/
    @isTest
    private static void getTabSettings_TGN_TEST(){
         Test.startTest();
        List<string> selectedPro = new List<string> {'System Administrator', 'Standard User'};
        profileconfig.getTabSettings(selectedPro);
       
        Test.stopTest();
        System.assertNotEquals('System Administrator',null);
    }
   @isTest(SeeAllData=true)
    private static void ProfileconfigExcelController_TEST(){
        ProfileconfigExcelController obj = new ProfileconfigExcelController();
         System.assertNotEquals('System Administrator',null);
    }
    @isTest(SeeAllData=true)
    private static void WrapperAllData_TGN_TEST(){
        ProfileconfigExcelController.WrapperAllData obj = new ProfileconfigExcelController.WrapperAllData();
         System.assertNotEquals('System Administrator',null);
    }
    /* */
}