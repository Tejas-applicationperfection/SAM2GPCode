/*
Author       : Himanshu Kr. Varshney
Description  : Apex Test Class for ProfilesWithNoUserDetails.apxc
Dependencies : ProfilesWithNoUserDetails.apxc
*/
@isTest
public with sharing class ProfilesWithNoUserDetailsTest{
    @isTest
    static void getProfilesDataTest(){
        Test.startTest();
        ProfilesWithNoUserDetails classObj = new ProfilesWithNoUserDetails();
        List<ProfilesWithNoUserDetails.WrapperData> wrapperDataList = ProfilesWithNoUserDetails.getProfilesData();
        System.assertNotEquals(null, wrapperDataList);
        Test.stopTest();
    }
}