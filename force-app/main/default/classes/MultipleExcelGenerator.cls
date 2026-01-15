/*
Author       : Himanshu Kr. Varshney
Description  : Apex Controller of VF Page, It will Fetch Data to Generate the Excel Based on Record ID 
Dependencies : Called from multipleExcelGenerator.vfp
*/
public with sharing class MultipleExcelGenerator{
    //xls Variables
    public String xmlheader {get;set;}
    public String endfile {get;set;}
    public Utils.ReportInfos reportInfos { get; set; }
    public List<RefactorDataToGenerateExcel> jsonData {get; set;}
    //Below Constructor will Fetch Record Id and Will Return Data Based on Record Id
    public MultipleExcelGenerator(){              
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        endfile = '</Workbook>';
        String recordId = ApexPages.currentPage().getParameters().get('recordId');
        //System.debug('recordId>>>>' + recordId);
        List<String> objNames = recordId.split(',');
        List<RefactorDataToGenerateExcel> jsonDataFinal = new List<RefactorDataToGenerateExcel>();
        List<IntelController.JSONData> jsonData1;
        if(Test.isRunningTest()){ 
            List<IntelController.JSONData> dummyJsonDataList = new List<IntelController.JSONData>();
            IntelController.JSONData dummyJsonData = new IntelController.JSONData();
            List<IntelController.LayoutData> dummyLayoutDataList = new List<IntelController.LayoutData>();
            IntelController.LayoutData dummyLayoutData = new IntelController.LayoutData();
            List<IntelController.FieldInfo> dummyFieldInfoList = new List<IntelController.FieldInfo>();
            IntelController.FieldInfo dummyFieldInfo = new IntelController.FieldInfo();
            List<String> dummyList = new List<String>();
            dummyJsonData.objectName = 'Account';
            dummyJsonData.developerName = 'Account';
            dummyLayoutData.layoutName = 'Account (Marketing) Layout';
            dummyList.add('OwnerId');
            dummyList.add('Name');
            dummyList.add('ParentId');
            dummyList.add('AccountNumber');
            dummyLayoutData.fieldInfos = dummyList;
            dummyLayoutDataList.add(dummyLayoutData);
            dummyJsonData.layoutDatas = dummyLayoutDataList;
            dummyFieldInfo.apiName = 'Id';
            dummyFieldInfo.label = 'Id';
            dummyFieldInfo.type = 'TEXT';
            dummyFieldInfoList.add(dummyFieldInfo);
            dummyJsonData.allFieldInfos = dummyFieldInfoList;
            dummyJsonDataList.add(dummyJsonData);
            jsonData1 = dummyJsonDataList;
        } 
        else{
            jsonData1 = IntelController.getAllObjectDetails(objNames);
        }
        for(Integer i = 0; i < jsonData1.size(); i++){
            RefactorDataToGenerateExcel dataJSON = new RefactorDataToGenerateExcel();
            dataJSON.objectName = jsonData1[i].objectName;
            List<List<String>> data = new List<List<String>>();
            List<String> firstColumn = new List<String>();
            firstColumn.add('Object Name');
            firstColumn.add('Field Name');
            firstColumn.add('API Name');
            firstColumn.add('Page Layout Name');
            data.add(firstColumn);
            List<String> secondColumn = new List<String>();
            secondColumn.add(jsonData1[i].objectName);
            secondColumn.add('');
            secondColumn.add('');
            Integer dummyCells = jsonData1[i].layoutDatas.size();
            for(Integer h = 0; h < dummyCells; h++){
                secondColumn.add(jsonData1[i].layoutDatas[h].layoutName);
            }
            data.add(secondColumn);
            for(Integer j = 0; j < jsonData1[i].allFieldInfos.size(); j++){
                List<String> thirdColumn = new List<String>();
                thirdColumn.add('');
                thirdColumn.add(jsonData1[i].allFieldInfos[j].label);
                thirdColumn.add(jsonData1[i].allFieldInfos[j].apiName);
                String fieldApiName = jsonData1[i].allFieldInfos[j].apiName;
                for(Integer k = 0; k < jsonData1[i].layoutDatas.size(); k++){
                    List<String> fieldInfoList = jsonData1[i].layoutDatas[k].fieldInfos;
                    if(fieldInfoList.indexOf(fieldApiName) >= 0){
                        thirdColumn.add('Yes');
                    }
                    else{
                        thirdColumn.add('No');
                    }
                }
                data.add(thirdColumn);
            }
            dataJSON.fieldInfo = data;
            jsonDataFinal.add(dataJSON);
        }
        jsonData = jsonDataFinal;
        reportInfos = Utils.getReportsInfos();
    }
    //Below Function is Used to Return to Previous Page
    public Pagereference exportAll(){
        return new Pagereference('/apex/ExportAll');
    }
    //Below Wrapper Class will Hold the Data in JSON Format
    public class RefactorDataToGenerateExcel{
        @AuraEnabled
        public string objectName{
            get; set;
        }
        @AuraEnabled
        public List<List<String>> fieldInfo{
            get; set;
        }
    }
}