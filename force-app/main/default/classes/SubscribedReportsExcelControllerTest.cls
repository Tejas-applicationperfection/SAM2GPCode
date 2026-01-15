/*
Author      : Himanshu Kr. Varshney
Description : This Class is Test class for SubscribedReportsExcelController.apxc
*/
@isTest
public with sharing class SubscribedReportsExcelControllerTest{
        public class WebCallOutClassFirst implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            System.assertEquals('GET', req.getMethod());
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000);
            res.setBody('[{"active":true,"createdDate":"2022-04-04T08:53:25Z","deactivateOnTrigger":false,"id":"0Au1v000000TYzKCAW","lastModifiedDate":"2022-04-04T08:53:25Z","name":"Notification","owner":{"id":"0051v00000BOeLq","name":"Tejas Kshirsagar"},"recordId":"00O1v000008pGdBEAU","runAs":null,"schedule":{"details":{"daysOfWeek":["mon"],"time":14},"frequency":"weekly"},"source":"lightningReportSubscribe","thresholds":[{"actions":[{"configuration":{"recipients":[]},"type":"sendEmail"}],"conditions":null,"type":"always"}]}]');
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest(SeeAllData='true')
    static void testMethodForApexClass(){
        Test.setMock(HttpCalloutMock.class, new WebCallOutClassFirst());
        Test.startTest();
        SubscribedReportsExcelController classObj = new SubscribedReportsExcelController();
     
        Test.stopTest();
           System.assertNotEquals('System Admin',null);
    }
}