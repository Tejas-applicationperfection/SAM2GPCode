/*
Author/Modified Code By : Pradeep
*/
public with sharing class CustomAppExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public String reportBody{ get; set; }
    @AuraEnabled
    public String jobId{ get; set; }
    //public List<HierarchyService.ParentChildren> parentChildren{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public List<string> allHeaders{ get; set; }
    @AuraEnabled
    public list<List<string>> allCells{ get; set; }
    //public list<string> allCells{ get; set; }
    public CustomAppExcelController(){
        map<string,string>appId2Name=new map<string,string>();
        map<string,string>appName2Vis=new map<string,string>();
        map<string,map<string,string>>profile2visMap=new map<string,map<string,string>>();
        
        for(AppMenuItem ami:[SELECT ApplicationId,Name,IsAccessible,IsVisible FROM AppMenuItem Where ApplicationId != Null]){
            appId2Name.put(ami.ApplicationId,ami.name);
            appName2Vis.put(ami.name,' ');
        }
        for(profile p:[select id,name from profile Where name != Null ORDER BY NAME]){
            map<string,string>cloneMap=appName2Vis.clone();
            profile2visMap.put(p.name,cloneMap);
        }
        for(SetupEntityAccess sea:[SELECT Id,Parent.IsOwnedByProfile,Parent.Profile.Name,SetupEntityId,SetupEntityType FROM SetupEntityAccess 
                                   WHERE (Parent.IsOwnedByProfile=true AND SetupEntityId in:appId2Name.keySet())]){
                                       map<string,string>tmpMap=profile2visMap.get(sea.Parent.Profile.Name);
                                       tmpMap.put(appId2Name.get(sea.SetupEntityId),'Visible');
                                       profile2visMap.put(sea.Parent.Profile.Name,tmpMap);		
                                   }
        list<object>retList=new list<object>();
        list<string>appNames=new list<string>{' '};
            list<list<string>>visList=new list<list<string>>();
        appNames.addAll(appName2Vis.keySet());
        for(string str:profile2visMap.keySet()){
            map<string,string>tmpMap=profile2visMap.get(str);
            list<string>tmpList=new list<string>();
            for(string str1:appNames){
                if(tmpMap.containsKey(str1)){
                    tmpList.add(tmpMap.get(str1));
                }else{
                    tmpList.add(str);
                }
            }
            visList.add(tmpList);
        }
        map<string,object>respMap=new map<string,object>{'header'=>appNames,'body'=>visList};
        allHeaders=new list<string>();
        allHeaders.addAll(appNames);
        system.debug('======visList====='+visList.size());
        system.debug('======visList====='+visList);
        allCells=new list<list<string>>();
        
        for(List<string> strList : visList){
            integer i = 0;
            if(i == 200){
                break;
            
            system.debug('====strList===='+strList);
         //   allCells.add(strList);
            i++;
                }
    	/*for(Opportunity innerList : oppList){
      			finalListOpps.add(innerList);
    		} */
  		}
        for(integer i =0; i<=10; i++){
            allCells.add(visList[i]);
        }
        
        system.debug('====allCells===='+allCells.size());
                system.debug('===='+allCells);

        //allCells=visList;
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos();
     
    }
}