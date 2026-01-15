/*
Author       : Himanshu Kr. Varshney
Description  : Apex Test Class for PublicGroupController.apxc
Dependencies : PublicGroupController.apxc
*/
@isTest
public with sharing class PublicGroupControllerTest{
    @isTest
    static void getPublicGroupDetailsTest(){
        Test.startTest();
        PublicGroupController classObj = new PublicGroupController();
        List<PublicGroupController.WrapperData> finalWrapperData = PublicGroupController.getPublicGroupDetails();
        System.assertNotEquals(null, finalWrapperData);
        Test.stopTest();
    }
     @isTest
    static void getPublicGroupMembersDetails(){
        Test.startTest();
         PublicGroupController classObj2 = new PublicGroupController();
           List<PublicGroupController.WrapperData> finalWrapperData = PublicGroupController.getPublicGroupMembersDetails();
        System.assertNotEquals(null, finalWrapperData);
        Test.stopTest();

    }
}