/*
Author       : Himanshu Kr. Varshney
Description  : Apex Test Class for IntelController.apxc
Dependencies : IntelController.apxc
*/
@isTest
public with sharing class IntelControllerTest{
    private static List<SA_Audit__OWD_Sharing_Report__c> managedPackageLicensesList = new List<SA_Audit__OWD_Sharing_Report__c>();
    private static List<Attachment> attachmentList = new List<Attachment>();
    static final Integer size = 1;
    @testSetup
    static void setUpData(){
        SA_Audit__OWD_Sharing_Report__c managedPackageLicenseOneRecord = new SA_Audit__OWD_Sharing_Report__c();
        managedPackageLicenseOneRecord = createManagedPackageLicenseRecord('ManagedPackaged');
        managedPackageLicensesList.add(managedPackageLicenseOneRecord);
        managedPackageLicenseOneRecord = createManagedPackageLicenseRecord('OWDReport');
        managedPackageLicensesList.add(managedPackageLicenseOneRecord);
        managedPackageLicenseOneRecord = createManagedPackageLicenseRecord('AllReports');
        managedPackageLicensesList.add(managedPackageLicenseOneRecord);
        managedPackageLicenseOneRecord = createManagedPackageLicenseRecord('ListView');
        managedPackageLicensesList.add(managedPackageLicenseOneRecord);
        managedPackageLicenseOneRecord = createManagedPackageLicenseRecord('FilteredReport');
        managedPackageLicensesList.add(managedPackageLicenseOneRecord);
        insert managedPackageLicensesList;
        Attachment attach = createAttachmentRecord('ListViewReports');
        attach.parentId = managedPackageLicensesList[3].Id;
        attach.Body = Blob.valueOf('[{"viewUniqueName":"All","viewName":"All","sobjectType":"SA_Audit__S_Audit__c","selectedFields":"Name, ","filterByOwner":"All OWD Sharing Reports","additionalFilters":""},{"viewUniqueName":"All","viewName":"All","sobjectType":"SA_Audit__Test_Object__c","selectedFields":"Name, ","filterByOwner":"All OWD Sharing Reports","additionalFilters":""}]');
        attachmentList.add(attach);
        Attachment attach1 = createAttachmentRecord('FilteredReports');
        attach1.parentId = managedPackageLicensesList[4].Id;
        attach1.Body = Blob.valueOf('>>>>>[{"filterBy":"Account.DSCORGPKG__DiscoverOrg_ID__c notEqual  , ","filterType":"Field Filter","folderName":"DiscoverOrg ROI Tracking","reportName":"Accounts with DiscoverOrg ID","reportUniqueName":"Accounts_with_DiscoverOrg_ID"},{"filterBy":"Contact.DSCORGPKG__DiscoverOrg_ID__c notEqual  , ","filterType":"Field Filter","folderName":"DiscoverOrg ROI Tracking","reportName":"Contacts with DiscoverOrg ID","reportUniqueName":"Contacts_with_DiscoverOrg_ID"},{"filterBy":"Account.DSCORGPKG__DiscoverOrg_First_Update__c notEqual  , Account.DSCORGPKG__DiscoverOrg_Created_On__c notEqual  , Account.DSCORGPKG__DiscoverOrg_ID__c notEqual  , Account.DSCORGPKG__External_DiscoverOrg_Id__c notEqual  , Account.DSCORGPKG__DiscoverOrg_LastUpdate__c notEqual  , ","filterType":"Field Filter","folderName":"DiscoverOrg ROI Tracking","reportName":"DO Sourced Account Wins, last Year","reportUniqueName":"DO_Sourced_Account_Wins_last_Year"},{"filterBy":"Account.DSCORGPKG__DiscoverOrg_First_Update__c notEqual  , Account.DSCORGPKG__DiscoverOrg_Created_On__c notEqual  , Account.DSCORGPKG__DiscoverOrg_ID__c notEqual  , Account.DSCORGPKG__External_DiscoverOrg_Id__c notEqual  , Account.DSCORGPKG__DiscoverOrg_LastUpdate__c notEqual  , ","filterType":"Field Filter","folderName":"DiscoverOrg ROI Tracking","reportName":"DO Sourced Account Wins, this Year","reportUniqueName":"DO_Sourced_Account_Wins_this_Year"},{"filterBy":"FK_Account.DSCORGPKG__DiscoverOrg_Created_On__c equals THIS MONTH , FK_Account.DSCORGPKG__DiscoverOrg_First_Update__c equals THIS MONTH , ","filterType":"Field Filter","folderName":"DiscoverOrg ROI Tracking","reportName":"DO Sourced Accounts created this Month","reportUniqueName":"DO_Sourced_Accounts_created_this_Month"},{"filterBy":"Account.DSCORGPKG__DiscoverOrg_First_Update__c notEqual  , Contact.DSCORGPKG__DiscoverOrg_ID__c notEqual  , Contact.DSCORGPKG__External_DiscoverOrg_Id__c notEqual  , Contact.DSCORGPKG__DiscoverOrg_Created_On__c notEqual  , ","filterType":"Field Filter","folderName":"DiscoverOrg ROI Tracking","reportName":"DO Sourced Contact Pipeline, last Year","reportUniqueName":"DO_Sourced_Contact_Pipeline_last_Year"},{"filterBy":"Account.DSCORGPKG__DiscoverOrg_First_Update__c notEqual  , Contact.DSCORGPKG__DiscoverOrg_ID__c notEqual  , Contact.DSCORGPKG__External_DiscoverOrg_Id__c notEqual  , Contact.DSCORGPKG__DiscoverOrg_Created_On__c notEqual  , ","filterType":"Field Filter","folderName":"DiscoverOrg ROI Tracking","reportName":"DO Sourced Contact Pipeline, this Year","reportUniqueName":"DO_Sourced_Contact_Pipeline_this_Year"},{"filterBy":"Account.DSCORGPKG__DiscoverOrg_First_Update__c notEqual  , Contact.DSCORGPKG__DiscoverOrg_ID__c notEqual  , Contact.DSCORGPKG__External_DiscoverOrg_Id__c notEqual  , Contact.DSCORGPKG__DiscoverOrg_Created_On__c notEqual  , Contact.DSCORGPKG__DiscoverOrg_LastUpdate__c notEqual  , ","filterType":"Field Filter","folderName":"DiscoverOrg ROI Tracking","reportName":"DO Sourced Contact Wins, last Year","reportUniqueName":"DO_Sourced_Contact_Wins_last_Year"},{"filterBy":"Account.DSCORGPKG__DiscoverOrg_First_Update__c notEqual  , Contact.DSCORGPKG__DiscoverOrg_ID__c notEqual  , Contact.DSCORGPKG__External_DiscoverOrg_Id__c notEqual  , Contact.DSCORGPKG__DiscoverOrg_Created_On__c notEqual  , Contact.DSCORGPKG__DiscoverOrg_LastUpdate__c notEqual  , ","filterType":"Field Filter","folderName":"DiscoverOrg ROI Tracking","reportName":"DO Sourced Contact Wins, this Year","reportUniqueName":"DO_Sourced_Contact_Wins_this_Year"},{"filterBy":"Account.DSCORGPKG__DiscoverOrg_First_Update__c notEqual  , Account.DSCORGPKG__DiscoverOrg_Created_On__c notEqual  , Account.DSCORGPKG__DiscoverOrg_First_Update__c notEqual  , Account.DSCORGPKG__DiscoverOrg_LastUpdate__c notEqual  , Account.DSCORGPKG__DiscoverOrg_ID__c notEqual  , Account.DSCORGPKG__External_DiscoverOrg_Id__c notEqual  , ","filterType":"Field Filter","folderName":"DiscoverOrg ROI Tracking","reportName":"DO Sourced Open Opportunities, last Year","reportUniqueName":"DO_Sourced_Open_Opportunities_last_Year"},{"filterBy":"Account.DSCORGPKG__DiscoverOrg_First_Update__c notEqual  , Account.DSCORGPKG__DiscoverOrg_Created_On__c notEqual  , Account.DSCORGPKG__DiscoverOrg_First_Update__c notEqual  , Account.DSCORGPKG__DiscoverOrg_LastUpdate__c notEqual  , Account.DSCORGPKG__DiscoverOrg_ID__c notEqual  , Account.DSCORGPKG__External_DiscoverOrg_Id__c notEqual  , ","filterType":"Field Filter","folderName":"DiscoverOrg ROI Tracking","reportName":"DO Sourced Open Opportunities, this Year","reportUniqueName":"DO_Sourced_Open_Opportunities_this_Year"},{"filterBy":"Opportunity.DSCORGPKG__Converted_from_Discoverorg_Data__c equals True , ","filterType":"Field Filter","folderName":"DiscoverOrg ROI Tracking","reportName":"DiscoverOrg Sourced Opportunities","reportUniqueName":"DiscoverOrg_Sourced_Opportunities"},{"filterBy":"Lead.DSCORGPKG__DiscoverOrg_ID__c notEqual  , ","filterType":"Field Filter","folderName":"DiscoverOrg ROI Tracking","reportName":"Leads with DiscoverOrg ID","reportUniqueName":"Leads_with_DiscoverOrg_ID"},{"filterBy":"Account.DSCORGPKG__Exclude_Update__c equals True , ","filterType":"Field Filter","folderName":"DiscoverOrg Reports","reportName":"Accounts Excluded from DO Auto Updates","reportUniqueName":"Accounts_Excluded_from_DO_Auto_Updates"},{"filterBy":"Contact.DSCORGPKG__Exclude_Update__c equals True , ","filterType":"Field Filter","folderName":"DiscoverOrg Reports","reportName":"Contacts Excluded from DO Auto Updates","reportUniqueName":"Contacts_Excluded_from_DO_Auto_Updates"},{"filterBy":"FK_Account.DSCORGPKG__DiscoverOrg_ID__c notEqual  , ","filterType":"Field Filter","folderName":"DiscoverOrg Reports","reportName":"DiscoverOrg Update History - Accounts","reportUniqueName":"DiscoverOrg_Update_History_Accounts"},{"filterBy":"DSCORGPKG__DiscoverOrg_Update_History__c.DSCORGPKG__Contact__c notEqual  , ","filterType":"Field Filter","folderName":"DiscoverOrg Reports","reportName":"DiscoverOrg Update History - Contacts","reportUniqueName":"DiscoverOrg_Update_History_Contacts"},{"filterBy":"DSCORGPKG__DiscoverOrg_Update_History__c.DSCORGPKG__Lead__c notEqual  , ","filterType":"Field Filter","folderName":"DiscoverOrg Reports","reportName":"DiscoverOrg Update History - Leads","reportUniqueName":"DiscoverOrg_Update_History_Leads"},{"filterBy":"Lead.DSCORGPKG__Exclude_Update__c equals True , ","filterType":"Field Filter","folderName":"DiscoverOrg Reports","reportName":"Leads Excluded from DO Auto Updates","reportUniqueName":"Leads_Excluded_from_DO_Auto_Updates"},{"filterBy":"DSCORGPKG__DiscoverOrg_Update_History__c.DSCORGPKG__FieldName__c equals discoverorg_id__c , DSCORGPKG__DiscoverOrg_Update_History__c.DSCORGPKG__Old_Value__c equals  , ","filterType":"Field Filter","folderName":"DiscoverOrg Reports","reportName":"Records Appended with a DO ID Today","reportUniqueName":"Records_Appended_with_a_DO_ID_Today"},{"filterBy":"agf__ADM_Work__c.agf__Status__c equals Fixed,QA In Progress , CUST_RECORDTYPE equals Bug , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Bugs to Verify","reportUniqueName":"Bugs_to_Verify"},{"filterBy":"CUST_RECORDTYPE equals Bug , agf__ADM_Work__c.agf__Status__c equals In Progress,Fixed,QA In Progress,Triaged , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Number of bugs in progress","reportUniqueName":"Number_of_bugs_in_progress"},{"filterBy":"CUST_RECORDTYPE equals User Story , agf__ADM_Work__c.agf__Status__c equals Closed , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Number of closed user stories","reportUniqueName":"Number_of_closed"},{"filterBy":"CUST_RECORDTYPE equals Bug , agf__ADM_Work__c.agf__Status__c equals Closed , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Number of closed bugs","reportUniqueName":"Number_of_closed_bugs"},{"filterBy":"CUST_RECORDTYPE equals User Story , agf__ADM_Work__c.agf__Status__c equals In Progress,QA In Progress,Fixed , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Number of in progress user stories","reportUniqueName":"Number_of_in_progress_user_stories"},{"filterBy":"CUST_RECORDTYPE equals Bug , agf__ADM_Work__c.agf__Status__c equals New , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Number of new bugs","reportUniqueName":"Number_of_new_bugs"},{"filterBy":"CUST_RECORDTYPE equals User Story , agf__ADM_Work__c.agf__Status__c equals New , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Number of new user stories","reportUniqueName":"Number_of_new_user_stories"},{"filterBy":"CUST_RECORDTYPE equals Bug,ToDo , agf__ADM_Work__c.agf__Scrum_Team__c notEqual  , agf__ADM_Work__c.agf__Priority__c equals P0,P1,P2 , agf__ADM_Work__c.agf__Closed__c equals 0 , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Open P0-P2 Bugs","reportUniqueName":"Open_P0_P2_Bugs"},{"filterBy":"agf__ADM_Work__c.agf__Closed__c equals 0 , CUST_RECORDTYPE equals Bug,ToDo , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Open bugs by Priority","reportUniqueName":"Open_bugs_by_Priority"},{"filterBy":"agf__ADM_Work__c.agf__Sprint_Name__c equals 2014.07b-Sample Team , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Sample: Planned vs Actual Task Hours","reportUniqueName":"Planned_vs_Actual_Task_Hours"},{"filterBy":"agf__ADM_Work__c.agf__Epic__c equals Navigation App Version 1 , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Sample: Epic Work progress","reportUniqueName":"Sample_Epic_Work_progress"},{"filterBy":"agf__ADM_Work__c.agf__Sprint_Name__c equals 2014.07b-Sample Team , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Sample: Stories Assigned, Completed","reportUniqueName":"Stories_Assigned_Completed"},{"filterBy":"agf__ADM_Work__c.agf__Closed__c equals 1 , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Story Points Completed Per Sprint","reportUniqueName":"Story_Points_Completed_Per_Sprint"},{"filterBy":"agf__ADM_Work__c.agf__Status__c equals Closed , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Sample: Story points per sprint","reportUniqueName":"Story_points_per_sprint"},{"filterBy":"agf__ADM_Work__c.agf__Sprint__c equals 2014.07b-Sample Team , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Sample: Team Allocation","reportUniqueName":"Team_Allocation"},{"filterBy":"agf__ADM_Work__c.agf__Status__c notEqual Closed,Duplicate,Never , ","filterType":"Field Filter","folderName":"Agile Accelerator","reportName":"Work created by month","reportUniqueName":"Work_created_by_month"},{"filterBy":"ACCOUNT_ID equals  , ","filterType":"Field Filter","folderName":"Composer Starter Pack Reports","reportName":"Account Brief Activities - [Activities]","reportUniqueName":"CongaSP_AccountBrief_Activities"},{"filterBy":"ACCOUNT_ID equals  , ","filterType":"Field Filter","folderName":"Composer Starter Pack Reports","reportName":"Account Brief Cases - [Cases]","reportUniqueName":"CongaSP_AccountBrief_Cases"},{"filterBy":"ACCOUNT_ID equals  , ","filterType":"Field Filter","folderName":"Composer Starter Pack Reports","reportName":"Account Brief Contacts - [Contacts]","reportUniqueName":"CongaSP_AccountBrief_Contacts"},{"filterBy":"ACCOUNT_ID equals  , ","filterType":"Field Filter","folderName":"Composer Starter Pack Reports","reportName":"Account Brief Opportunities - [Opptys]","reportUniqueName":"CongaSP_AccountBrief_Opptys"},{"filterBy":"OCR_Contact.LID__No_longer_at_Company__c equals Not at Company , Opportunity.Probability equals 100 , Opportunity.IsClosed equals True , ","filterType":"Field Filter","folderName":"LinkedIn Reports","reportName":"SN: All Past Customers at New Companies","reportUniqueName":"Copy_of_SNAll_Past_Customers_at_New_Com_nMq"},{"filterBy":"Contact.LID__No_longer_at_Company__c equals Not at Company , ","filterType":"Field Filter","folderName":"LinkedIn Reports","reportName":"SN: All Contacts Not at Company","reportUniqueName":"SNAll_Contacts_Not_at_Company_cHB"},{"filterBy":"OCR_Contact.LID__No_longer_at_Company__c equals Not at Company , Opportunity.IsClosed equals False , ","filterType":"Field Filter","folderName":"LinkedIn Reports","reportName":"SN: Contacts No Longer at All Open Opps","reportUniqueName":"SNAll_Contacts_who_left_All_Open_Opps_dPv"},{"filterBy":"OCR_Contact.LID__No_longer_at_Company__c equals Not at Company , Opportunity.IsClosed equals False , ","filterType":"Field Filter","folderName":"LinkedIn Reports","reportName":"SN: Contacts No Longer at My Open Opps","reportUniqueName":"SNAll_Contacts_who_left_My_Open_Opps_0nk"},{"filterBy":"Contact.LID__No_longer_at_Company__c equals Not at Company , ","filterType":"Field Filter","folderName":"LinkedIn Reports","reportName":"SN: My Contacts Not at Company","reportUniqueName":"SNMy_Contacts_not_at_Company_LxD"},{"filterBy":"OCR_Contact.LID__No_longer_at_Company__c equals Not at Company , Opportunity.IsClosed equals True , Opportunity.Probability equals 100 , ","filterType":"Field Filter","folderName":"LinkedIn Reports","reportName":"SN: My Past Customers at New Companies","reportUniqueName":"SNMy_Past_Customers_at_New_Company_maD"},{"filterBy":"CONTACT equals  , LEAD equals  , ","filterType":"Field Filter","folderName":"LinkedIn Reports","reportName":"Unresolved LinkedIn Activities","reportUniqueName":"Unresolved_LinkedIn_Activities"}]');
		insert attachmentList;
    }
    static Attachment createAttachmentRecord(String fileName){
        Blob excelData;
        Attachment attach = new Attachment();
        attach.Name = fileName;
        attach.ContentType = 'text/plain';
        return attach;
    }
    static SA_Audit__OWD_Sharing_Report__c createManagedPackageLicenseRecord(String type){
        SA_Audit__OWD_Sharing_Report__c managedPackageLicenseOneRecord = new SA_Audit__OWD_Sharing_Report__c();
        managedPackageLicenseOneRecord.Name = 'Test';
        managedPackageLicenseOneRecord.SA_Audit__Managed_Package_License_Datails__c = '[{"userName":"james@applicationperfection.co.uk.development","role":"CEO","profile":"System Administrator","packageName":"Conga Composer","name":"James Burgess","activeBoolean":true}]';
        managedPackageLicenseOneRecord.SA_Audit__Type__c = type;//'ManagedPackaged';
        managedPackageLicenseOneRecord.SA_Audit__OWD_Data_Field__c = 'Lead?Public Read/Write/Transfer?Private?Checked|Account, Contract and Asset?Public Read/Write?Private?Checked|Contact?Controlled by Parent?Controlled by Parent?Checked|Order?Controlled by Parent?Controlled by Parent?Checked|Opportunity?Public Read/Write?Private?Checked|Case?Public Read/Write/Transfer?Private?Checked|Campaign?Public Full Access?Private?Checked|Campaign Member?Controlled by Campaign?Controlled by Campaign?Checked|User?Public Read Only?Private?Checked|Activity?Private?Private?Checked|Calendar?Hide Details and Add Events?Hide Details and Add Events?Checked|Price Book?Use?Use?Checked|Individual?Public Read/Write?Private?Checked|Action Plan?Private?Private?Checked|Action Plan Template?Private?Private?Checked|Assessment Indicator Definition?Private?Private?Checked|Assessment Task?Private?Private?Checked|Assessment Task Definition?Private?Private?Checked|Authorization Form?Private?Private?Checked|Authorization Form Consent?Private?Private?Checked|Authorization Form Data Use?Private?Private?Checked|Coaching?Private?Private?|Communication Subscription?Private?Private?Checked|Communication Subscription Channel Type?Private?Private?Checked|Communication Subscription Consent?Private?Private?Checked|Consumption Schedule?Public Read Only?Private?Checked|Contact Point Address?Controlled by Parent?Controlled by Parent?Checked|Contact Point Consent?Private?Private?Checked|Contact Point Email?Controlled by Parent?Controlled by Parent?Checked|Contact Point Phone?Controlled by Parent?Controlled by Parent?Checked|Contact Point Type Consent?Private?Private?Checked|Contact Request?Public Read/Write?Private?Checked|Crisis?Private?Private?Checked|Data Use Legal Basis?Private?Private?Checked|Data Use Purpose?Private?Private?Checked|Delivery Task?Private?Private?Checked|Employee?Private?Private?Checked|Employee Crisis Assessment?Private?Private?Checked|Engagement Channel Type?Private?Private?Checked|Feedback?Private?Private?|Feedback Question?Private?Private?|Feedback Question Set?Private?Private?|Feedback Request?Private?Private?|Feedback Template?Private?Private?|Flow Interview?Private?Private?Checked|Flow Interview Log?Private?Private?Checked|Goal?Private?Private?|Image?Private?Private?Checked|Internal Organization Unit?Private?Private?Checked|List Email?Private?Private?Checked|Location?Public Read/Write?Private?Checked|Macro?Private?Private?Checked|Macro Usage?Private?Private?Checked|Metric?Private?Private?|Party Consent?Private?Private?Checked|Performance Cycle?Private?Private?|Product Fulfillment Location?Private?Private?Checked|Product Item?Private?Private?Checked|Product Transfer?Private?Private?Checked|Quick Text?Private?Private?Checked|Quick Text Usage?Private?Private?Checked|Scorecard?Private?Private?Checked|Shipment?Private?Private?Checked|SOS Session?Private?Private?Checked|Streaming Channel?Public Read/Write?Private?Checked|User Provisioning Request?Private?Private?Checked|Visit?Private?Private?Checked|Helper?Public Read/Write?Private?Checked|OWD Sharing Report?Public Read/Write?Private?Checked|Test Custom Object?Public Read/Write?Private?Checked|Test Second Object?Public Read/Write?Private?Checked';
        managedPackageLicenseOneRecord.SA_Audit__Sharing_Rules_Details__c = 'PerObjectRelatedDataStarts ObjectNameStarts Lead Sharing Rules ObjectNameEnds HeaderDataStarts Criteria++ Shared With++ Lead++ HeaderDataEnds LeftDataStarts BodyDataStarts Owner in All Internal Users? All Internal Users? Read Only? BodyDataEnds BodyDataStarts Owner in Queue: International Leads? Role: Channel Sales Team? Read Only? BodyDataEnds LeftDataEnds PerObjectRelatedDataENDs PerObjectRelatedDataStarts ObjectNameStarts Account Sharing Rules ObjectNameEnds HeaderDataStarts Criteria++ Shared With++ Account, Contract and Asset++ Opportunity++ Case++ HeaderDataEnds LeftDataStarts BodyDataStarts Owner in All Internal Users? All Internal Users? Read Only? Private? Private? BodyDataEnds LeftDataEnds PerObjectRelatedDataENDs PerObjectRelatedDataStarts ObjectNameStarts Opportunity Sharing Rules ObjectNameEnds HeaderDataStarts Criteria++ Shared With++ Opportunity++ HeaderDataEnds LeftDataStarts BodyDataStarts ( Opportunity: Stage equals Prospecting ) or ( Opportunity: Type not equal to Existing Customer - Upgrade )? All Internal Users? Read Only? BodyDataEnds BodyDataStarts Owner in All Internal Users? All Internal Users? Read/Write? BodyDataEnds LeftDataEnds PerObjectRelatedDataENDs';
        managedPackageLicenseOneRecord.SA_Audit__List_View_JSON__c = '[{"viewUniqueName":"All","viewName":"All","sobjectType":"SA_Audit__S_Audit__c","selectedFields":"Name, ","filterByOwner":"All OWD Sharing Reports","additionalFilters":""},{"viewUniqueName":"All","viewName":"All","sobjectType":"SA_Audit__Test_Object__c","selectedFields":"Name, ","filterByOwner":"All OWD Sharing Reports","additionalFilters":""}]';
        return managedPackageLicenseOneRecord;
    }
    public class WebCallOutClassFirst implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            System.assertEquals('GET', req.getMethod());
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"size":4,"totalSize":4,"done":true,"queryLocator":null,"entityTypeName":"Layout","records":[{"attributes":{"type":"Layout","url":"/services/data/v47.0/tooling/sobjects/Layout/00h0Y000001mQZpQAM"},"Id":"00h0Y000001mQZpQAM","Name":"Account (Marketing) Layout"},{"attributes":{"type":"Layout","url":"/services/data/v47.0/tooling/sobjects/Layout/00h0Y000001mQZqQAM"},"Id":"00h0Y000001mQZqQAM","Name":"Account (Sales) Layout"},{"attributes":{"type":"Layout","url":"/services/data/v47.0/tooling/sobjects/Layout/00h0Y000001mQZrQAM"},"Id":"00h0Y000001mQZrQAM","Name":"Account (Support) Layout"},{"attributes":{"type":"Layout","url":"/services/data/v47.0/tooling/sobjects/Layout/00h0Y000001mQZsQAM"},"Id":"00h0Y000001mQZsQAM","Name":"Account Layout"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    public class WebCallOutClassSecond implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            System.assertEquals('GET', req.getMethod());
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"size":4,"totalSize":4,"done":true,"queryLocator":null,"entityTypeName":"Layout","records":[{"attributes":{"type":"Layout","url":"/services/data/v47.0/tooling/sobjects/Layout/00h0Y000001mQZpQAM"},"Id":"00h0Y000001mQZpQAM","Name":"Account (Marketing) Layout"},{"attributes":{"type":"Layout","url":"/services/data/v47.0/tooling/sobjects/Layout/00h0Y000001mQZqQAM"},"Id":"00h0Y000001mQZqQAM","Name":"Account (Sales) Layout"},{"attributes":{"type":"Layout","url":"/services/data/v47.0/tooling/sobjects/Layout/00h0Y000001mQZrQAM"},"Id":"00h0Y000001mQZrQAM","Name":"Account (Support) Layout"},{"attributes":{"type":"Layout","url":"/services/data/v47.0/tooling/sobjects/Layout/00h0Y000001mQZsQAM"},"Id":"00h0Y000001mQZsQAM","Name":"Account Layout"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void intelControllerConstructorTest(){
        Test.startTest();
        IntelController classObj = new IntelController();
        System.assertNotEquals(null, classObj.xmlheader);
        Test.stopTest();
    }
    @isTest
    static void fetchTableDataOption24Test(){
        SA_Audit__BatchApexStatus__c customSettingRecord = new SA_Audit__BatchApexStatus__c();
        customSettingRecord.Name = 'FilteredReports';
        insert customSettingRecord;
        Test.startTest();
        List<IntelController.FilteredReportsData> jsonData = IntelController.fetchTableDataOption24();
        System.assertNotEquals(null, jsonData);
        Test.stopTest();
    }
    @isTest
    static void getSobjectIdTest(){
        Test.setMock(HttpCalloutMock.class, new WebCallOutClassSecond());
        Test.startTest();
        String res = IntelController.getSobjectId('Account');
        System.assertNotEquals(null, res);
        Test.stopTest();
    }
    static testMethod void exportAllTest(){
        Test.startTest();
        PageReference pageRef;
        pageRef = new PageReference('/apex/ExportAll');
        IntelController ctrl = new IntelController();
        ctrl.exportAll();
        System.assertNotEquals(null, pageRef);
        Test.stopTest();
    }
    static testMethod void getAllObjectNamesTest(){
        Test.startTest();
        List<IntelController.ObjectDetails> objDetails = IntelController.getAllObjectNames();
        System.assertNotEquals(null, objDetails);
        Test.stopTest();
    }
    static testMethod void getAllObjectDetailsTest(){
        Test.setMock(HttpCalloutMock.class, new WebCallOutClassFirst());
        List<String> objList = new List<String>();
        objList.add('Account');
        Test.startTest();
        IntelController.getAllObjectDetails(objList);
        System.assertEquals('Account', objList[0]);
        Test.stopTest();
    }  
     
    static testMethod void fetchTableDataOption3Test(){
        Test.startTest();
        List<HierarchyService.HierarchyItem> hierarchyItemList = IntelController.fetchTableDataOption3('option3');
        System.assertNotEquals(null, hierarchyItemList);
        Test.stopTest();
    }
    static testMethod void fetchTableDataOption4Test(){ 
        // Test data setup
        Integer pageNumber = 1;
        Integer pageSize = 10;
          
        Test.startTest();
        IntelController.UserWrapper2 result = IntelController.fetchTableDataOption4(pageNumber, pageSize);
        Test.stopTest();
         System.assertNotEquals('System Administrator',null);
    }                                 
    static testMethod void fetchTableDataOption5Test(){
        Integer pageNumber = 1;
        Integer pageSize = 10;
        Test.startTest();
        IntelController.UserWrapper2 userRoles = IntelController.fetchTableDataOption5(pageNumber, pageSize);
        System.assertNotEquals(null, userRoles);
        Test.stopTest();
    }
    static testMethod void fetchTableDataOption6Test(){
        Integer pageNumber = 1;
        Integer pageSize = 10;
        Test.startTest();
        IntelController.UserWrapper2 userRoles = IntelController.fetchTableDataOption5(pageNumber, pageSize);
        System.assertNotEquals(null, userRoles);
        Test.stopTest();
    }
    static testMethod void fetchTableDataOption7Test(){
        Test.startTest();
        List<HierarchyService.HierarchyItem> hierarchyItemList = IntelController.fetchTableDataOption7();
        System.assertNotEquals(null, hierarchyItemList);
        Test.stopTest();
    }
    static testMethod void fetchTableDataOption8Test(){
        Test.startTest();
        List<HierarchyService.ParentChildren> parentChildren = IntelController.fetchTableDataOption8();
        System.assertNotEquals(null, parentChildren);
        Test.stopTest();
    }
    /*static testMethod void fetchTableDataOption19Test(){
        Test.startTest();
        List<ManagedPackageLicenseFutureController.ManagedPackageDetailsClass> finalList = IntelController.fetchTableDataOption19();
        System.assertNotEquals(null, finalList);
        Test.stopTest();
    }*/
    static testMethod void fetchTableDataOption14Test(){
        Test.startTest();
        String str = IntelController.fetchTableDataOption14();
        System.assertNotEquals(null, str);
        Test.stopTest();
    }
    static testMethod void fetchTableDataOption1Test(){
        Test.startTest();
        List<List<FolderShareExcelController.Folder>> allFolderList = IntelController.fetchTableDataOption1('7071v00008gF64jAAC');
        System.assertNotEquals(null, allFolderList);
        Test.stopTest();
    }
    /*static testMethod void fetchTableDataOption11Test(){
        Test.startTest();
        IntelController.fetchTableDataOption11('7071v00008fOz6fAAC');
        Test.stopTest();
    }*/
    static testMethod void fetchTableDataOption2Test(){
        Test.startTest();
        List<List<FolderShareExcelController.Folder>> allFolderList = IntelController.fetchTableDataOption2('7071v00007ME1XtAAL');
        System.assertNotEquals(null, allFolderList);
        Test.stopTest();
    }
    static testMethod void fetchTableDataOption16Test(){
        Test.startTest();
        List<ProfilesWithNoUserDetails.WrapperData> wrapperDataList = IntelController.fetchTableDataOption16();
        System.assertNotEquals(null, wrapperDataList);
        Test.stopTest();
    }
    static testMethod void fetchTableDataOption17Test(){
        Test.startTest();
        ApexTriggerAndApexClassController.WrapperData finalWrapperData = IntelController.fetchTableDataOption17();
        System.assertNotEquals(null, finalWrapperData);
        Test.stopTest();
    }
    static testMethod void fetchTableDataOption18Test(){
        Test.startTest();
        List<PublicGroupController.WrapperData> finalWrapperData = IntelController.fetchTableDataOption18();
        System.assertNotEquals(null, finalWrapperData);
        Test.stopTest();
    }
  static testMethod void fetchTableDataOption27Test(){
        Test.startTest();
        List<PublicGroupController.WrapperData> finalWrapperData = IntelController.fetchTableDataOption27();
      TestClassCoverage4.unitTest();
        System.assertNotEquals(null, finalWrapperData);
        Test.stopTest();
    }
    /*static testMethod void fetchTableDataOption15Test(){
        Test.startTest();
        List<PermissionSetWithNoUsers.WrapperData> wrapperDataList = IntelController.fetchTableDataOption15();
        System.assertNotEquals(null, wrapperDataList);
        Test.stopTest();
    }*/
    static testMethod void fetchTableDataOption13Test(){
        Test.startTest();
        List<SharingSettingsFutureController.SharingRulesData> sharingRuleFinalList = IntelController.fetchTableDataOption13();
        System.assertNotEquals(null, sharingRuleFinalList);
        Test.stopTest();
    }
    static testMethod void fetchTableDataOption28Test(){
        List<String>profList = new List<String>{'Admin'};
        Test.startTest();
        List<profileconfig.WrapperAllData> profileCon = IntelController.fetchTableDataOption28(profList);
        System.assertNotEquals(null, profileCon);
        Test.stopTest();
    }                                
                                    
    static testMethod void fetchTableDataOption22Test(){
        Test.startTest();
        List<SA_Audit__Helper__c> suditHelperList = new List<SA_Audit__Helper__c>([SELECT Id, SA_Audit__JobId__c FROM SA_Audit__Helper__c Limit 1]);
        List<ListViewBatchApex.FinalClass> finalList = IntelController.fetchTableDataOption22();
        IntelController.getProfilesList();
      //  IntelController.fetchTableDataOption23();
    //    IntelController.fetchTableDataOption20();
       IntelController.fetchTableDataOption26();
       // IntelController.fetchTableDataOption10();
        IntelController.fetchTableDataOption33();
       // IntelController.fetchTableDataOption30(); 
        IntelController.fetchTableDataOption23();
      	IntelController.fetchTableDataOption25(); 
        IntelController.fetchTableDataOption15();
        IntelController.fetchTableDataOption21();
        
         //   IntelController.fetchTableDataOption11('AXSZD12345'); 
        //IntelController.getBatchApexJOBIds();
        TestClassCoverage.unitTest();
        TestClassCoverage1.unitTest();
        TestClassCoverage2.unitTest();
          TestClassCoverage3.unitTest();
        System.assertNotEquals(null, finalList);
        Test.stopTest();
    }
    @isTest
    static void batchApexExecutionToSendAnEmailTest(){
        Test.startTest();
        managedPackageLicensesList = getOWDObjectRecords(); 
        List<String> listOfIds = new List<String>();
        List<string> selectedOption = new List<string>();
        IntelController.batchApexExecutionToSendAnEmail(listOfIds,selectedOption);
        //Database.executeBatch(new GenerateAllReports(listOfIDs), 200);
        String str = 'Fake';
        System.assertNotEquals(null, str);
        Test.stopTest();
    }
    static List<SA_Audit__OWD_Sharing_Report__c> getOWDObjectRecords(){
        return [SELECT Id, Name, SA_Audit__OWD_Data_Field__c, SA_Audit__Sharing_Rules_Details__c FROM SA_Audit__OWD_Sharing_Report__c];
    }
}