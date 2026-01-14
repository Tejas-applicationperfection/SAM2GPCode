public with sharing class CSVDownloadController {
    @AuraEnabled
   public static list <Contact> fetchContact(){
      
      List <contact> returnConList = new List < contact > ();
        
      for(Contact con: [SELECT FirstName, LastName, Department, MobilePhone From Contact LIMIT 1000]) {
             returnConList.add(con);
          }
         return returnConList;
   }

}