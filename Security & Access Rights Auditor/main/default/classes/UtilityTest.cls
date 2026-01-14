/*
Author      : Himanshu Kr. Varshney
Description : This Class is Test class for Utility.apxc
*/
@isTest
public with sharing class UtilityTest{
    @isTest
    static void getReportsInfosTest(){
        Test.startTest();
        //Utility classObj = new Utility();
        Utility.getReportsInfos();
        System.assertEquals(true, Utility.orgIsAccessible);
        Test.stopTest();
    }
}