/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-16-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class RecordTypesReportController {
    @AuraEnabled
    public static list<string> getAllTypeOfPermission(){
        try {
            return SecurityUtil.getPermissionTypeForLightning();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}