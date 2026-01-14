public with sharing class customAppVisibility {
    @auraEnabled
    public static object met1(){
        map<string,string>appId2Name=new map<string,string>();
        map<string,string>appName2Vis=new map<string,string>();
        map<string,map<string,string>>profile2visMap=new map<string,map<string,string>>();
        
        for(AppMenuItem ami:[SELECT ApplicationId,Name,IsAccessible,IsVisible FROM AppMenuItem Where ApplicationId != Null]){
            appId2Name.put(ami.ApplicationId,ami.name);
            appName2Vis.put(ami.name,' ');
        }
        for(profile p:[select id,name from profile Where name != null]){
            map<string,string>cloneMap=appName2Vis.clone();
            profile2visMap.put(p.name,cloneMap);
        }
        for(SetupEntityAccess sea:[SELECT Id,Parent.IsOwnedByProfile,Parent.Profile.Name,SetupEntityId,SetupEntityType FROM SetupEntityAccess 
                                   WHERE (Parent.IsOwnedByProfile=true AND SetupEntityId in:appId2Name.keySet())]){
                                       map<string,string>tmpMap=profile2visMap.get(sea.Parent.Profile.Name);
                                       tmpMap.put(appId2Name.get(sea.SetupEntityId),'V');
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
            /*system.debug(JSON.serializePretty(appNames.size()));
system.debug(JSON.serializePretty(visList[0].size()));
system.debug(JSON.serializePretty(visList[1].size()));
system.debug(JSON.serializePretty(visList[2]));*/
            return respMap;
    }
}