/*
Author       : Himanshu Kr. Varshney
Description  : Apex Test Class for OrgWideDefaultsController.apxc
Dependencies : OrgWideDefaultsController.apxc
*/
@isTest
public with sharing class OrgWideDefaultsControllerTest{
    private static List<SA_Audit__OWD_Sharing_Report__c> owdSharingReportList = new List<SA_Audit__OWD_Sharing_Report__c>();
    static final Integer size = 1;
    @testSetup
    static void setUpData(){
        SA_Audit__OWD_Sharing_Report__c owdSharingReportRecord = new SA_Audit__OWD_Sharing_Report__c();
        owdSharingReportRecord = createOWDSharingReportRecord();
        owdSharingReportList.add(owdSharingReportRecord);
        insert owdSharingReportList;
    }
    static SA_Audit__OWD_Sharing_Report__c createOWDSharingReportRecord(){
        SA_Audit__OWD_Sharing_Report__c owdSharingReportRecord = new SA_Audit__OWD_Sharing_Report__c();
        owdSharingReportRecord.Name = 'Test';
        owdSharingReportRecord.SA_Audit__OWD_Data_Field__c = 'Lead?Public Read/Write/Transfer?Private?Checked|Account, Contract and Asset?Public Read/Write?Private?Checked|Contact?Controlled by Parent?Controlled by Parent?Checked|Order?Controlled by Parent?Controlled by Parent?Checked|Opportunity?Public Read/Write?Private?Checked|Case?Public Read/Write/Transfer?Private?Checked|Campaign?Public Full Access?Private?Checked|Campaign Member?Controlled by Campaign?Controlled by Campaign?Checked|User?Public Read Only?Private?Checked|Activity?Private?Private?Checked|Calendar?Hide Details and Add Events?Hide Details and Add Events?Checked|Price Book?Use?Use?Checked|Individual?Public Read/Write?Private?Checked|Action Plan?Private?Private?Checked|Action Plan Template?Private?Private?Checked|Assessment Indicator Definition?Private?Private?Checked|Assessment Task?Private?Private?Checked|Assessment Task Definition?Private?Private?Checked|Authorization Form?Private?Private?Checked|Authorization Form Consent?Private?Private?Checked|Authorization Form Data Use?Private?Private?Checked|Coaching?Private?Private?|Communication Subscription?Private?Private?Checked|Communication Subscription Channel Type?Private?Private?Checked|Communication Subscription Consent?Private?Private?Checked|Consumption Schedule?Public Read Only?Private?Checked|Contact Point Address?Controlled by Parent?Controlled by Parent?Checked|Contact Point Consent?Private?Private?Checked|Contact Point Email?Controlled by Parent?Controlled by Parent?Checked|Contact Point Phone?Controlled by Parent?Controlled by Parent?Checked|Contact Point Type Consent?Private?Private?Checked|Contact Request?Public Read/Write?Private?Checked|Crisis?Private?Private?Checked|Data Use Legal Basis?Private?Private?Checked|Data Use Purpose?Private?Private?Checked|Delivery Task?Private?Private?Checked|Employee?Private?Private?Checked|Employee Crisis Assessment?Private?Private?Checked|Engagement Channel Type?Private?Private?Checked|Feedback?Private?Private?|Feedback Question?Private?Private?|Feedback Question Set?Private?Private?|Feedback Request?Private?Private?|Feedback Template?Private?Private?|Flow Interview?Private?Private?Checked|Flow Interview Log?Private?Private?Checked|Goal?Private?Private?|Image?Private?Private?Checked|Internal Organization Unit?Private?Private?Checked|List Email?Private?Private?Checked|Location?Public Read/Write?Private?Checked|Macro?Private?Private?Checked|Macro Usage?Private?Private?Checked|Metric?Private?Private?|Party Consent?Private?Private?Checked|Performance Cycle?Private?Private?|Product Fulfillment Location?Private?Private?Checked|Product Item?Private?Private?Checked|Product Transfer?Private?Private?Checked|Quick Text?Private?Private?Checked|Quick Text Usage?Private?Private?Checked|Scorecard?Private?Private?Checked|Shipment?Private?Private?Checked|SOS Session?Private?Private?Checked|Streaming Channel?Public Read/Write?Private?Checked|User Provisioning Request?Private?Private?Checked|Visit?Private?Private?Checked|Helper?Public Read/Write?Private?Checked|OWD Sharing Report?Public Read/Write?Private?Checked|Test Custom Object?Public Read/Write?Private?Checked|Test Second Object?Public Read/Write?Private?Checked';
        owdSharingReportRecord.SA_Audit__Sharing_Rules_Details__c = 'PerObjectRelatedDataStarts ObjectNameStarts Lead Sharing Rules ObjectNameEnds HeaderDataStarts Criteria++ Shared With++ Lead++ HeaderDataEnds LeftDataStarts BodyDataStarts Owner in All Internal Users? All Internal Users? Read Only? BodyDataEnds BodyDataStarts Owner in Queue: International Leads? Role: Channel Sales Team? Read Only? BodyDataEnds LeftDataEnds PerObjectRelatedDataENDs PerObjectRelatedDataStarts ObjectNameStarts Account Sharing Rules ObjectNameEnds HeaderDataStarts Criteria++ Shared With++ Account, Contract and Asset++ Opportunity++ Case++ HeaderDataEnds LeftDataStarts BodyDataStarts Owner in All Internal Users? All Internal Users? Read Only? Private? Private? BodyDataEnds LeftDataEnds PerObjectRelatedDataENDs PerObjectRelatedDataStarts ObjectNameStarts Opportunity Sharing Rules ObjectNameEnds HeaderDataStarts Criteria++ Shared With++ Opportunity++ HeaderDataEnds LeftDataStarts BodyDataStarts ( Opportunity: Stage equals Prospecting ) or ( Opportunity: Type not equal to Existing Customer - Upgrade )? All Internal Users? Read Only? BodyDataEnds BodyDataStarts Owner in All Internal Users? All Internal Users? Read/Write? BodyDataEnds LeftDataEnds PerObjectRelatedDataENDs';
        owdSharingReportRecord.SA_Audit__Type__c = 'OWDReport';
        return owdSharingReportRecord;
    }
    static List<SA_Audit__OWD_Sharing_Report__c> getOWDObjectRecords(){
        return [SELECT Id, Name, SA_Audit__OWD_Data_Field__c, SA_Audit__Sharing_Rules_Details__c, SA_Audit__Type__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'OWDReport'];
    }
    @isTest
    static void fetchOWDReportDataTest(){
        Test.startTest();
        OrgWideDefaultsController classObj = new OrgWideDefaultsController();
        owdSharingReportList = getOWDObjectRecords();
        System.assertEquals(size, owdSharingReportList.size());
        Test.stopTest();
    }
}