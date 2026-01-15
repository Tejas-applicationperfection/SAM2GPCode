public with sharing class SharingSettingsFutureController{ 

    @AuraEnabled  

    @future(callout=true) 

    public static void getOWDDetails(){ 

        //List<OWDData> owdListData = new List<OWDData>(); 

        //List<SharingRulesData> sharingRulesFinalList = new List<SharingRulesData>(); 

        String finalString = ''; 

        List<String> sharingRulesList = new List<String>(); 

         

        String sharingRulesFinalString = ''; 

        List<String> sharingRulesListSecond = new List<String>(); 

        List<OWD_Sharing_Report__c> owdObjectList = [SELECT Id, OWD_Data_Field__c, Type__c FROM OWD_Sharing_Report__c WHERE Type__c = 'OWDReport' LIMIT 200]; 

       

        /*List<EntityDefinition> listEntityDef = [SELECT Label, DeveloperName, DurableId, MasterLabel, InternalSharingModel, ExternalSharingModel, IsProcessEnabled, IsCustomizable, IsApexTriggerable, IsWorkflowEnabled, IsCompactLayoutable, IsSearchable, IsTriggerable FROM EntityDefinition WHERE IsCustomizable = True AND IsApexTriggerable = True AND IsWorkflowEnabled = True AND IsCompactLayoutable = True AND IsSearchable = True AND IsTriggerable = True];*/ 

        String url = URL.getOrgDomainUrl().toExternalForm() + '/p/own/OrgSharingDetail?setupid=SecuritySharing&div_filter=&st=' + 'allObjects'; 

        PageReference pg = new PageReference(url); 

        if(Test.isRunningTest()){  

            Blob content = blob.valueOf('Unit.Test'); 

        }  

        else{ 

            String str = pg.getContent().toString(); 

            String sharingModelStr = str.substringAfter('Sharing Rules'); 

            sharingModelStr = sharingModelStr.substringAfter('<!-- WrappingClass -->');  

            //sharingModelStr = sharingModelStr.stripHtmlTags(); 

            str = str.substringBetween('Organization-Wide Defaults', 'Other Settings'); 

            List<String> lstData = str.split('<!-- ListRow -->'); 

            for(Integer i = 1; i < lstData.size(); i++){ 

                //OWDData owdOneData = new OWDData(); 

                String eachRow = lstData[i]; 

                String objName = eachRow.substringBetween('dataCell  ">', '</th><td'); 

                eachRow = eachRow.subStringAfter('</th><td'); 

                String secondColumn = eachRow.substringBetween('dataCell  ">', '</td><td'); 

                eachRow = eachRow.subStringAfter('</td><td'); 

                String thirdColumn = eachRow.substringBetween('dataCell  ">', '</td><td'); 

                String forthColumn = eachRow.substringBetween(' booleanColumn">', '</td>'); 

                Boolean isChecked = forthColumn.contains('/img/checkbox_checked.gif'); 

                /*owdOneData.objectLabel = objName; 

                  owdOneData.InternalSharingModel = secondColumn; 

                  owdOneData.ExternalSharingModel = thirdColumn; 

                  owdOneData.isChecked = isChecked ? 'Checked' : 'NotChecked'; 

                  owdListData.add(owdOneData);*/ 

                if(i == (lstData.size() - 1)){ 

                    finalString += objName + '?' + secondColumn + '?' + thirdColumn + '?' + (isChecked ? 'Checked' : '');  

                } 

                else{ 

                    finalString += objName + '?' + secondColumn + '?' + thirdColumn + '?' + (isChecked ? 'Checked' : '') + '|'; 

                } 

            } 

           /* if(owdObjectList.size() > 0 && OWD_Sharing_Report__c.sObjectType.getDescribe().isDeletable()){ 

                delete owdObjectList; 

            }*/ 

            List<String> sharingRulesDummyList = new List<String>(); 

            String sharingModelDummyStr; 

            while(sharingModelStr.length() > 1000000){ 

                sharingModelDummyStr = sharingModelStr.substring(0, 500000); 

                sharingRulesDummyList = sharingModelDummyStr.split('<!-- WrappingClass -->'); 

                sharingRulesList.addAll(sharingRulesDummyList); 

                sharingModelStr = sharingModelStr.substring(sharingModelDummyStr.length(), sharingModelStr.length()); 

            } 

            sharingRulesDummyList = sharingModelStr.split('<!-- WrappingClass -->'); 

            sharingRulesList.addAll(sharingRulesDummyList); 

            for(Integer i = 0; i < sharingRulesList.size(); i++){ 

                if(!sharingRulesList[i].contains('No sharing rules specified.')){ 

                    sharingRulesListSecond.add(sharingRulesList[i]); 

                } 

            } 

            system.debug('lstData'+lstData); 

            String secondRowString = ''; 

            String sixthString = ' '; 

            for(Integer i = 0; i < sharingRulesListSecond.size(); i++){ 

                //List<String> secondRowData = new List<String>(); 

                //List<List<String>> thirdRowData = new List<List<String>>(); 

                List<String> dummyList = new List<String>(); 

                //SharingRulesData sharingRulesOne = new SharingRulesData(); 

                String objectName = sharingRulesListSecond[i].substringBetween('<h3>', '</h3>'); 

                String firstStr = sharingRulesListSecond[i].subStringAfter('</h3>'); 

                String secondStr = firstStr.substringBetween('</h3>', '<!-- ListRow -->'); 

                secondStr = firstStr.subStringAfter('Action</th>'); 

                String thirdString = 'DummyData'; 

                while((thirdString != null)){ 

                    //secondRowData.add(secondStr.substringBetween('zen-deemphasize">', '</th>')); 

                    secondRowString += ' ' + secondStr.substringBetween('zen-deemphasize">', '</th>') + '++'; 

                    secondStr = secondStr.substringAfter('</th>'); 

                    thirdString = secondStr.substringBetween('zen-deemphasize">', '</th>'); 

                } 

                firstStr = firstStr.substringAfter('<!-- ListRow -->'); 

                dummyList = firstStr.split('\\<!-- ListRow -->'); 

                String seventhString = ''; 

                String eightString = ' '; 

                for(Integer j = 0; j < dummyList.size(); j++){ 

                    //List<String> thirdList = new List<String>();  

                    Integer counter = 0; 

                    String forthString = 'DummyData'; 

                    String fifthString = dummyList[j]; 

                    while(forthString != null && String.isNotBlank(fifthString)){ 

                        if(counter == 0){ 

                            //thirdList.add(fifthString.substringBetween('dataCell  ">', '</th>').replaceAll('<[/a-zAZ0-9]*>', ' ').stripHtmlTags()); 

                            eightString += ' BodyDataStarts ' + fifthString.substringBetween('dataCell  ">', '</th>').replaceAll('<[/a-zAZ0-9]*>', ' ').stripHtmlTags() + '?'; 

                            fifthString = fifthString.substringAfter('</th>'); 

                            counter++; 

                        } 

                        else{ 

                            //thirdList.add(fifthString.substringBetween('dataCell  ">', '</td>').replaceAll('<[/a-zAZ0-9]*>', ' ').stripHtmlTags()); 

                            eightString += ' ' + fifthString.substringBetween('dataCell  ">', '</td>').replaceAll('<[/a-zAZ0-9]*>', ' ').stripHtmlTags() + '?'; 

                            fifthString = fifthString.substringAfter('</td>'); 

                            forthString = fifthString.substringBetween('dataCell  ">', '</td>'); 

                            counter++; 

                        } 

                    } 

                    eightString += ' BodyDataEnds '; 

                    sixthString += eightString; 

                    //thirdRowData.add(thirdList); 

                } 

                sharingRulesFinalString += ' PerObjectRelatedDataStarts ' + ' ObjectNameStarts ' + objectName + ' ObjectNameEnds ' + ' HeaderDataStarts ' + secondRowString + ' HeaderDataEnds ' + ' LeftDataStarts ' + eightString + ' LeftDataEnds ' + ' PerObjectRelatedDataENDs '; 

                /*sharingRulesOne.sharingRuleObjectName = objectName; 

                  sharingRulesOne.headerData = secondRowData; 

                  sharingRulesOne.bodyData = thirdRowData; 

                  sharingRulesFinalList.add(sharingRulesOne);*/ 

                secondRowString = ' '; 

            } 

        } 

        OWD_Sharing_Report__c obj = new OWD_Sharing_Report__c(); 

        if(Schema.sObjectType.OWD_Sharing_Report__c.fields.Sharing_Rules_Details__c.isCreateable() 

           && Schema.sObjectType.OWD_Sharing_Report__c.fields.Type__c.isCreateable() 

           && Schema.sObjectType.OWD_Sharing_Report__c.fields.OWD_Data_Field__c.isCreateable()){ 

               obj.Sharing_Rules_Details__c = sharingRulesFinalString; 

               obj.Type__c = 'OWDReport'; 

               obj.OWD_Data_Field__c = finalString;//String.valueof(owdListData); 

               insert obj; 

        } 

        system.debug(obj); 

    }  

    //Below Wrapper Class will Save the Data which are Related to Sharing Rules 

    public class SharingRulesData{ 

        @AuraEnabled 

        public List<String> sharingRuleObjectName{ get; set; } 

        @AuraEnabled 

        public List<String> headerData {get; set;} 

        @AuraEnabled 

        public List<List<String>> bodyData {get; set;} 

    } 

}