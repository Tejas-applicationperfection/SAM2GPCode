/**
* @description       : 
* @author            : TejasKshirsagar
* @group             : 
* @last modified on  : 10-12-2021
* @last modified by  : TejasKshirsagar
**/
public with sharing class RecordAccess {
    
     public Boolean hasAccess { get; set; }
    
      //public Boolean showContent { get; set; }
    public Utils.ReportInfos reportInfos{ get; set; }
    public SA_Audit__Test_Object__c dummycontact { get; set; }
    public String xmlheader { get; set; }
    public String endfile { get; set; }
    public Id currentId { get; set; }
     public Id currentId2 { get; set; }
    public List<Sobject> shrObjList { get; set;}
     public Integer ForCount { get; set; }
    public  List<Group> groupList { get; set;}
    public String access { get; set; }
    public String access1 { get; set; }
    public String sObjName { get; set; }
    public String sObjLabel { get; set; }
    public List<String> userIdList {get; set;}
    public Boolean noSharing {get; set; }
    public Sobject sObj { get; set; }
    public Boolean owdRW { get; set; }
    public Boolean noError { get; set; }
    public User user { get; set; }
    public User selectedUserRecord { get; set; }
    public Sobject userTerritory { get; set; }
    public Boolean noTerritory2 { get; set; }
    public Boolean noTerritory { get; set; }
    public String enabledTerritory { get; set; }
    public Boolean enableTerritory { get; set; }
    public Boolean enableEnterpriseTerritory { get; set; }
    public transient Map<Id, String> objTer2IdMap { get; set; }
    public transient Map<Id, Sobject> userTerrMap { get; set; }
    public transient List<Sobject> territoryList { get; set; }
    public transient List<Territory2Wrapper> territory2WrapperList { get; set; }
    public transient List<TerritoryWrapper> territoryWrapperList { get; set; }
    public transient List<ManagerWraplist> wrp{get; set;}
    public  List<ExportUserWrapper> AccUser{get; set;}
    public Id profileId { get; set; }
    public String profileName { get; set; }
    public transient Map<PermissionSet, ObjectPermissions> permissionSetMap { get; set; }
    public SObject organization { get; set; }
    public SObject EntityDefinition { get; set; }
    public String fieldOrg { get; set; }
    public Boolean prSet { get; set; }
    public transient Set<UserRole> userRoleSet { get; set; }
    public UserRole currentUserRole { get; set; }
    public transient List<RecordType> recTypeList { get; set; }
    public String existRT { get; set; }
    public Boolean noUserRole { get; set; }
    public Boolean isGroupShr { get; set; }
    public transient Map<Id, SObject> shrGroupMap { get; set; }
    public transient Map<Id, User> userMap { get; set; }
    public transient Map<ID, UserRole> userRoleMap { get; set; }
    public transient Map<User, List<UserRole>> userSharingRoleMap { get; set; }
    public Boolean noSharingRole { get; set; }
    public PermissionSet userPermission { get; set; }
    public List<user> Manager {get; set;}
    public ObjectPermissions objPermission { get; set; }
    public transient List<PermissionSet> permisionSetList { get; set; }
    public Boolean isCustom { get; set; }
    public String sharingCriteriaRule { get; set; }
    public transient Map<Group, List<UserRole>> roleGroupMap { get; set; }
    public transient Map<Group, List<UserRole>> roleAndSubordinatesGroupMap { get; set; }
    public transient Map<Group, List<UserRole>> roleGroupSharingMap { get; set; }
    public transient Map<Group, User> userGroupSharingMap { get; set; }
    public Boolean isRolePublicGroupShare { get; set; }
    public Boolean isRoleGroupShare { get; set; }
    public Boolean isRoleSubordinatesGroupShare { get; set; }
    public String customShr { get; set; }
    public  List<ExportUserWrapper> usersAccess {get; set;}
    public transient Map<String, String> sharingCriteriaRuleMap { get; set; }
    public transient List<String> recordTypeList { get; set; }
    public Boolean isExpandOrg { get; set; }
    public Boolean isExpandMan { get; set; }
    public Boolean isExpandProf { get; set; }
    public Boolean isExpandAccess { get; set; }
     public Boolean isExpandAccess1 { get; set; }
    public Boolean isExpandPerm { get; set; }
    public Boolean isExpandRole { get; set; }
    public Boolean isExpandTerritory { get; set; }
    public Boolean isExpandSharing { get; set; }
    public Boolean isExpandGroupSharing { get; set; }
    public Boolean isExpandRecordType { get; set; }
    public Boolean pushGo { get; set; }
    public String isPdf { get; set; }
    public String userPDFID { get; set; }
    public String exportUser { get; set; }
    public static List<String> userNameList { get; set; }
    public String selectedUser { get; set; }
    @RemoteAction
    public static List<String> getUser(String userName) {
        if(userName.length() > 0) {
            userName = '%' + userName + '%';
            ////system.debug('userName::' + userName);
            List<User> userList = [SELECT ID, Name, UserType, Profile.Name, UserRoleId  FROM User WHERE isActive = true AND Name LIKE :userName LIMIT 100];
            userNameList = new List<String>();
            if(userList.size()>0){ for(User u : userList) {userNameList.add(u.Name); }  }
            return userNameList;
        } else {
            List<User> userList = [SELECT ID, Name, UserType, Profile.Name, UserRoleId  FROM User WHERE isActive = true AND Name LIKE :userName LIMIT 100];
            userNameList = new List<String>();
            for(User u : userList) {userNameList.add(u.Name);}
            return userNameList;
        }
    }
    public Boolean getPaidFeatureAccess() {
         
         try {
            // Attempt to check if the feature is enabled for the user
         //return FeatureManagement.checkPackageBooleanValue('RecordAccessPaidAccess');
           //for data dictionary
            return false;
        } catch (System.NoDataFoundException e) {
            // Log the exception for debugging purposes
            System.debug('Feature parameter not found: ' + e.getMessage());
            // Handle the exception gracefully, return false to indicate no access
            return false;
        } catch (Exception e) {
            // Catch any other exceptions that might occur
            System.debug('An unexpected error occurred: ' + e.getMessage());
            // Handle the exception gracefully, return false to indicate no access
            return false;
        }
    }
    
    public recordAccess() {
           //   showContent = false;
          ForCount = 0;
        xmlheader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
           reportInfos  = Utils.getReportsInfos(); 

        endfile = '</Workbook>';
          hasAccess = getPaidFeatureAccess();
        sharingCriteriaRuleMap = new Map<String, String>();
        isPdf = ApexPages.currentPage().getParameters().get('isPdf');
        if (isPdf != 'true') {
            dummycontact = new SA_Audit__Test_Object__c(UserId__c = UserInfo.getUserId());
            system.debug('dummycontact=='+dummycontact);
            //dummycontact = [SELECT ID, UserId__c FROM Test_Object__c where UserId__c != null LIMIT 1];
            //user = new User(FirstName = dummycontact.Owner.FirstName, LastName = dummycontact.Owner.LastName );
            //user = [SELECT ID, Name, UserType, Profile.Name, UserRoleId  FROM User WHERE Id =:dummycontact.UserId__c];
            /*List<User> userList = [SELECT ID, Name, UserType, Profile.Name, UserRoleId  FROM User WHERE isActive = true LIMIT 100];
userNameList = new List<String>();
user = new User();
for(User u : userList) {
userNameList.add( u.Name);
if(u.Id == currentUserId) {
user = u;
//selectedUser = u.Name;
}
}*/
            pushGo = false;
        } else {
            exportUser = UserInfo.getName() != null ? UserInfo.getName() : '';
            userPDFID = ApexPages.currentPage().getParameters().get('userPDFID');
            currentId = (ID)ApexPages.currentPage().getParameters().get('currentId');

            go();
        }
        ////system.debug('selectedUser:::' + selectedUser);
        ////system.debug('userId:::' + selectedUserRecord.Id);
        ////system.debug('userName:::' + selectedUserRecord.Name);
    }
    public PageReference redirectToWelcomeMetadataPage() {
        PageReference pageRef = Page.WelcomeMetadataPage;
        pageRef.getParameters().put('retPage', 'RecordAccess');
        pageRef.setRedirect(true);
        return pageRef;
    }
    public PageReference openContactUSLink(){
        PageReference pageRef;
        pageRef = new PageReference('https://applicationperfection.com/contact/');
        return pageRef;
    }
    
    public PageReference openHelpTraining(){
        PageReference pageRef;
        pageRef = new PageReference('https://applicationperfection.com/security-access-manager-help-training/');
        return pageRef;
    }
    public PageReference openFAQ(){
        PageReference pageRef;
        pageRef = new PageReference('https://applicationperfection.com/security-access-manager-faqs/');
        return pageRef;
    }
    public PageReference openReleaseNotes(){
        PageReference pageRef;
        pageRef = new PageReference('https://applicationperfection.com/security-access-manager-release-notes/');
        return pageRef;
    }
    
  	public PageReference Go() {
		sharingCriteriaRuleMap = new Map<String, String>();
		//selectedUser = selectedUserRecord.Id;
		////system.debug('selectedUser:::' + selectedUser);
		////system.debug('userId:::' + selectedUserRecord.Id);
		////system.debug('userName:::' + selectedUserRecord.Name);
		pushGo = true;

		////system.debug('conection' + RollupService.checkMetadataAPIConnection());
		if(!RollupService.checkMetadataAPIConnection()) {
			return redirectToWelcomeMetadataPage();
		} else {
			/*if(!Schema.getGlobalDescribe().get('User').getDescribe().isAccessible()) {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You don\'t have access on User object');
				ApexPages.addMessage(myMsg);
				return null;
			}*/
			//if(Schema.getGlobalDescribe().get('User').getDescribe().isAccessible()) {
				if(isPdf == 'true') {
					user = [SELECT Name, UserRoleId, Profile.Name, Profile.USERLICENSE.Name FROM User WHERE Id = :userPDFID limit 7000];
					//user = userMap.get((ID)userPDFID);
				} else {
				Id currentUserId = dummycontact.UserId__c;
				user = [SELECT ID, Name, UserRoleId, Profile.Name, Profile.USERLICENSE.Name FROM User WHERE Id = :currentUserId limit 7000];
				}
			//}
			
			system.debug('$$user::' + user);
			if(user.Profile.USERLICENSE.Name.contains('Salesforce')) {
				userMap = new Map<Id, User>([SELECT Name, UserRoleId, Profile.Name FROM User WHERE IsActive = true AND Profile.USERLICENSE.Name LIKE '%Salesforce%' limit 7000]);
			} else {
				userMap = new Map<Id, User>([SELECT Name, UserRoleId, Profile.Name FROM User WHERE IsActive = true AND (NOT Profile.USERLICENSE.Name LIKE '%Salesforce%') limit 7000]);
			}
 
			userRoleMap = new Map<ID, UserRole>([SELECT Id, Name, DeveloperName, ParentRoleId  FROM UserRole WHERE PortalType = 'None' OR PortalType = 'CustomerPortal' OR PortalType = 'Partner' limit 7000]);

			isExpandOrg = true;
			isExpandProf = true;
            isExpandAccess = true;
            isExpandMan = true;
			isExpandPerm = true;
			isExpandRole = true;
			isExpandTerritory = true;
			isExpandSharing = true;
			isExpandGroupSharing = true;
			isExpandRecordType = true;
			owdRW = false;
			noError = true;
			
			if(currentId != null) {
				try {
					sObjLabel = currentId.getSObjectType().getDescribe().getLabel();
					sObjName = currentId.getSObjectType().getDescribe().getName();
					////system.debug('sObjName::' + sObjName);
					//check if the currentId is in our org
					String query1;
					/*if(!Schema.getGlobalDescribe().get(sObjName).getDescribe().isAccessible()) {
						ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'You don\'t have access to ' + sObjName);
						ApexPages.addMessage(myMsg);
						noError = false;
						return null;
					}*/
					
					if(sObjName == 'Case') {
						query1 = 'SELECT Id, CaseNumber, OwnerId FROM ' + sObjName + ' WHERE ID = :currentId';
					} else {
						query1 = 'SELECT Id, Name FROM ' + sObjName + ' WHERE ID = :currentId';
					}
					////system.debug('String.escapeSingleQuotes(query1::' + String.escapeSingleQuotes(query1));
					sObj = Database.query(String.escapeSingleQuotes(query1));
					////system.debug('sObj::' + sObj);
					
				} catch(Exception e) {
					ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'Please enter a valid record ID.');
					ApexPages.addMessage(myMsg);
					noError = false;
				}
				if(noError) {
					SharringSetting();
					territoryManagement();
					profile();
					permissionSetAssigned();
                    assidnedManager();
					if(user.Profile.USERLICENSE.Name.contains('Salesforce')) RecordTypeAssigned();
				}
			} else {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'Please enter record ID.');
					ApexPages.addMessage(myMsg);
					noError = false;
			}
		}
		////system.debug('4. Amount of CPU time (in ms) used so far: ' + Limits.getCpuTime());
		userMap = new Map<Id, User>();
		return null;
	}
	
	 public void SharringSetting() {

		fieldOrg = '';
		isGroupShr = false;
		noSharing = false;
		
		isCustom = false;
		try {

			String query2;
			 
			if (!sObjName.contains('__c')) {

				fieldOrg = 'Default' + sObjName + 'Access';
				if(SecurityUtil.getFieldDescribeMap('Organization').containsKey(fieldOrg.toLowerCase())) {
					query2 = 'SELECT Id, IsSandbox, Name, OrganizationType, PrimaryContact, ' + fieldOrg + ' FROM Organization';
				} else {

					query2 = 'SELECT Id, IsSandbox, Name, OrganizationType, PrimaryContact FROM Organization';
					fieldOrg ='';
				}
				organization = Database.query(query2);

				////system.debug('query2:;' + query2);
				////system.debug('organization:;' + organization);
			} else {

				query2 = 'SELECT Id, IsSandbox, Name, OrganizationType, PrimaryContact FROM Organization';
				organization = Database.query(query2);
				////system.debug('query2:;' + query2);
				////system.debug('organization:;' + organization);
				isCustom = true;
				fieldOrg = 'Default' + sObjLabel + 'Access';
			}
			
			//buil the query for the MyObject__Share
			String query;
			String pId;
			String ShareObject;
			if(query == null) {
				query = 'SELECT ';
			} else {
				query += ' ';
			}
			
			if (sObjName.contains('__c')) {
	
					String objName = sObjName.removeEnd('c');
					access = 'AccessLevel';
					pId = 'ParentId';
					ShareObject = objName + 'Share';
			} else {
					ShareObject = sObjName + 'Share';
					access = sObjName + 'AccessLevel';
					pId = sObjName + 'Id';
			}
			access1 = sObjLabel + ' Access Level';
			//check if the our organization has Sharing for the Object
			Map<String, Schema.SObjectType> tokens = Schema.getGlobalDescribe();
			 
			if(tokens.containsKey(ShareObject)) {
				
				tokens = null;
				query += access + ', RowCause, UserOrGroupId FROM '+ ShareObject + ' WHERE ' + pId + ' = :currentId';

				List<SObject> shrList;
				shrList = Database.query(query);
				shrObjList = new List<SObject>();
				shrGroupMap = new Map<Id, SObject>();
				////system.debug('user.Id::' + user.Id);
				for(SObject shr : shrList) {

					 if (((String)shr.get('UserOrGroupId')).startsWith('005') || shr.get('UserOrGroupId') == user.Id) {
						shrObjList.add(shr);

					} else {
						shrGroupMap.put((Id)shr.get('UserOrGroupId'), shr);

					}
				}

				if(shrObjList.size() == 0) {
					owdRW = true;
				}

				if(shrGroupMap.KeySet().size() > 0) {
					GroupAsigned(shrGroupMap);

					sharingHierarchyRole(shrGroupMap);
				}
			} else {
				owdRW = true;
			}
		} catch(Exception e) {

			noSharing = true;
		}
		try{
			readSharingRule(sObjName); 
		} catch(Exception e) {

		}
		if(isCustom){
			try{
				readCustomObject(sObjName); 
			} catch(Exception e) {

			}
		}
	}
	 
	/*public void SharringSetting() {
    fieldOrg = '';
    isGroupShr = false;
    noSharing = false;
    isCustom = false;

    try {
        String query2;
        if (!sObjName.contains('__c')) {
            fieldOrg = 'Default' + sObjName + 'Access';
            if (SecurityUtil.getFieldDescribeMap('Organization').containsKey(fieldOrg.toLowerCase())) {
                query2 = 'SELECT Id, IsSandbox, Name, OrganizationType, PrimaryContact, ' + fieldOrg + ' FROM Organization';
            } else {
                query2 = 'SELECT Id, IsSandbox, Name, OrganizationType, PrimaryContact FROM Organization';
                fieldOrg = '';
            }
        } else {
            query2 = 'SELECT Id, IsSandbox, Name, OrganizationType, PrimaryContact FROM Organization';
            isCustom = true;
            fieldOrg = 'Default' + sObjLabel + 'Access';
        }

        organization = Database.query(query2);

        String query;
        String pId;
        String ShareObject;
        if (sObjName.contains('__c')) {
            String objName = sObjName.removeEnd('c');
            access = 'AccessLevel';
            pId = 'ParentId';
            ShareObject = objName + 'Share';
        } else {
            ShareObject = sObjName + 'Share';
            access = sObjName + 'AccessLevel';
            pId = sObjName + 'Id';
        }
        access1 = sObjLabel + ' Access Level';

        Map<String, Schema.SObjectType> tokens = Schema.getGlobalDescribe();
        if (tokens.containsKey(ShareObject)) {
            tokens = null;
            query = 'SELECT ' + access + ', RowCause, UserOrGroupId FROM ' + ShareObject + ' WHERE ' + pId + ' = :currentId';
            List<SObject> shrList = Database.query(query);

            shrObjList = new List<SObject>();
            shrGroupMap = new Map<Id, SObject>();

            for (SObject shr : shrList) {
                if (((String) shr.get('UserOrGroupId')).startsWith('005') || shr.get('UserOrGroupId') == user.Id) {
                    shrObjList.add(shr);
                } else {
                    shrGroupMap.put((Id) shr.get('UserOrGroupId'), shr);
                }
            }

            if (shrObjList.size() == 0) {
                owdRW = true;
            }

            if (shrGroupMap.KeySet().size() > 0) {
                GroupAsigned(shrGroupMap);
                sharingHierarchyRole(shrGroupMap);
            }
        } else {
            owdRW = true;
        }
    } catch (Exception e) {
        noSharing = true;
    }

    try {
        readSharingRule(sObjName);
    } catch (Exception e) {
    }

    if (isCustom) {
        try {
            readCustomObject(sObjName);
        } catch (Exception e) {
        }
    }
}
    */
	public void territoryManagement() {

		noTerritory2 = false;
		noTerritory = false;
		enableTerritory = false;
		enableEnterpriseTerritory = false;
		enabledTerritory = '';
		//check for Territory Management for Account
		/*if(Schema.getGlobalDescribe().get('Territory2') != null && !Schema.getGlobalDescribe().get('Territory2').getDescribe().isAccessible()) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'You don\'t have access to Territory2 object');
			ApexPages.addMessage(myMsg);
			return;
		}
		if(Schema.getGlobalDescribe().get('Territory') != null && !Schema.getGlobalDescribe().get('Territory').getDescribe().isAccessible()) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'You don\'t have access to Territory object');
			ApexPages.addMessage(myMsg);
			return;
		}*/
		if(sObjName == 'Account' || sObjName == 'Opportunity') {
			String query;
			//check if it is enabled Enterprise Territory Management
			try {

				Map<Id, Set<Id>> userTerr2Map = new Map<Id, Set<Id>>();
				Map<Id, Set<Id>> terr2UserMap = new Map<Id, Set<Id>>();
				query = 'SELECT RoleInTerritory2, UserId, Territory2Id FROM UserTerritory2Association';

				List<Sobject> userTerList;
				userTerList = Database.query(query);
				for(Sobject userTerr : userTerList) {
					if(!userTerr2Map.KeySet().contains((Id)userTerr.get('UserId'))) {
						userTerr2Map.put((Id)userTerr.get('UserId'), new Set<Id>());
					}
					userTerr2Map.get((Id)userTerr.get('UserId')).add((Id)userTerr.get('Territory2Id'));
					if(!terr2UserMap.KeySet().contains((Id)userTerr.get('Territory2Id'))) {
						terr2UserMap.put((Id)userTerr.get('Territory2Id'), new Set<Id>());
					}
					terr2UserMap.get((Id)userTerr.get('Territory2Id')).add((Id)userTerr.get('UserId'));
				}

				////system.debug('userTerr2Map::' + userTerr2Map);
				List<Sobject> objTer2List = new List<Sobject>();
				String AssociationCause;
				objTer2IdMap = new Map<Id, String>();
				Set<Id> objTer2IdSet = new Set<Id>();
				if(sObjName == 'Account') {
					query = 'SELECT id, AssociationCause, ObjectId, SobjectType, Territory2Id FROM ObjectTerritory2Association WHERE ObjectId = :currentId';
					objTer2List = Database.query(query);
				} else {
					Set<Id> groupIdSet = new Set<Id>();
					for(Id userOrGroupID : shrGroupMap.KeySet()) {
						if(shrGroupMap.get(userOrGroupID).get('RowCause') == 'Territory2Forecast' || shrGroupMap.get(userOrGroupID).get('RowCause') == 'ImplicitChild' ) {
							groupIdSet.add(userOrGroupID);
						}
					}
					query = 'SELECT id, DeveloperName, Name, RelatedId, Type FROM Group WHERE ID IN :groupIdSet';

					List<Sobject> groupList;
					groupList = Database.query(query);

					for(SObject gr : groupList) {
						if(gr.get('Type') == 'Territory') {
							objTer2IdSet.add((Id)gr.get('RelatedId'));
							objTer2IdMap.put((ID)gr.get('RelatedId'), (String)shrGroupMap.get(gr.Id).get('RowCause'));
						}
					} 
				}
				
				if(objTer2List.size() > 0 || objTer2IdSet.size() > 0) {

					if(objTer2List.size() > 0) {
						////system.debug('objTer2List::' + objTer2List);
						for (Sobject objTer2 : objTer2List) {
							AssociationCause = (String)objTer2.get('AssociationCause');
							objTer2IdMap.put((Id)objTer2.get('Territory2Id'), AssociationCause.substring(10));
							objTer2IdSet.add((Id)objTer2.get('Territory2Id'));
						}
					}
					query = 'SELECT Name, ParentTerritory2Id, AccountAccessLevel, CaseAccessLevel, ContactAccessLevel, Description, OpportunityAccessLevel FROM Territory2';

					Map<Id, Sobject> territory2IdMap = new Map<Id, Sobject>(Database.query(query));

					List<SObject> terList;
					Id currentTerParentID;
					Boolean existParentTer2;
					UserRole currUserRole = new UserRole();
					territory2WrapperList = new List<Territory2Wrapper>();

					for(Id objTer2Id : objTer2IdSet) {
						existParentTer2 = false;
						Boolean isRoleTerritory;

						if (!userTerr2Map.containsKey(user.id) || !userTerr2Map.get(user.Id).contains(objTer2Id)) {
							terList = new List<Sobject>();
							terList.add(territory2IdMap.get(objTer2Id));
							currentTerParentID = (ID)territory2IdMap.get(objTer2Id).get('ParentTerritory2Id');

							while (currentTerParentID != null) {
								terList.add(territory2IdMap.get(currentTerParentID));
								if(userTerr2Map.keySet().contains(user.id) && userTerr2Map.get(user.Id).contains(currentTerParentID)) {
									currentTerParentID = null;
									existParentTer2 = true;
								} else {
									currentTerParentID = (Id)territory2IdMap.get(currentTerParentID).get('ParentTerritory2Id');
								}
							}
							List<SObject> terRoleList = new List<SObject>();

							isRoleTerritory = false;
							for (SObject ter2 : terList) {
								if(!isRoleTerritory) {
									terRoleList.add(ter2);
								}
							//check if in the territory exist user who has current user above in Role Hierarchy

								if(terr2UserMap.get((Id)ter2.get('Id')) != null) {
									for (ID userId : terr2UserMap.get((Id)ter2.get('Id'))){
										if(!isRoleTerritory) {
											Id currentParentRoleId;
											
											currUserRole = userRoleMap.get(userMap.get(userId).UserRoleId);
											////system.debug('currUserRole;;' + currUserRole);
											if (currUserRole != null) {
												currentParentRoleId = currUserRole.ParentRoleId;
												userRoleSet = new Set<UserRole>();
												////system.debug('currentParentRoleId::;' + currentParentRoleId);
												while (currentParentRoleId != null) {
													userRoleSet.add(userRoleMap.get(currentParentRoleId));
													////system.debug('userMap.get(user.Id).UserRoleId::;' + userMap.get(user.Id).UserRoleId);
													if(currentParentRoleId == userMap.get(user.Id).UserRoleId) {
														currentParentRoleId = null;
														isRoleTerritory = true;
													} else {
														currentParentRoleId = userRoleMap.get(currentParentRoleId).ParentRoleId;
													}
												}
												//system.debug('userRoleSet::' + userRoleSet);
											}
										}
									}
								}
							}
							//system.debug('terRoleList::' + terRoleList);
							//system.debug('isRoleTerritory::' + isRoleTerritory);
							if(existParentTer2) {
								territory2WrapperList.add(new Territory2Wrapper(territory2IdMap.get(objTer2Id), terList, existParentTer2));
							}
							if(isRoleTerritory) {
								User userTerritory;
								for(Id userID : userMap.KeySet()) {
									if(userMap.get(userId).UserRoleId == currUserRole.Id) {
										userTerritory = userMap.get(userId);
										break;
									}
								}
								territory2WrapperList.add(new Territory2Wrapper(territory2IdMap.get(objTer2Id), terRoleList, true, userRoleSet, isRoleTerritory, userTerritory));
							} 
							
						} else {
							territory2WrapperList.add(new Territory2Wrapper(territory2IdMap.get(objTer2Id),  existParentTer2));
						}
					}

					if (territory2WrapperList.size() > 0) {
						enableEnterpriseTerritory = True;
					} else {
						noTerritory2 = true;
					}
				}else {
					noTerritory2 = true;
				}
			} catch (Exception e) {

				noTerritory2 = true;
			}
			//check if it is enabled Territory Management
			try {
				List<Sobject> accShrList;
				if(sObjName == 'Account') {
					query = 'SELECT  Id, UserOrGroupId, AccountId, RowCause FROM AccountShare WHERE AccountId = :currentId';
					query += ' AND RowCause IN (\'Territory\', \'TerritoryManual\', \'TerritoryRule\', \'Rule\')';
				} else {
					query = 'SELECT  Id, UserOrGroupId, OpportunityId, RowCause FROM OpportunityShare WHERE OpportunityId = :currentId';
				}
				
				accShrList = Database.query(query);

				//check if the account is assigned to a territory
				if (accShrList.size() > 0){
					List<Sobject> userTerritoryList;
					//Id usrId = user.Id;
					query = 'SELECT TerritoryId, UserId FROM UserTerritory';

					userTerritoryList = Database.query(query);
					Set<Id> userTerrIdSet = new Set<Id>();
					Map<Id, Set<Id>> terrUserMap = new Map<Id, Set<Id>>(); 
					for(Sobject userTerritory : userTerritoryList) {
						if(userTerritory.get('UserId') == user.Id) {
							userTerrIdSet.add((Id)userTerritory.get('TerritoryId'));
						}
						if(!terrUserMap.KeySet().contains((Id)userTerritory.get('TerritoryId'))) {
							terrUserMap.put((Id)userTerritory.get('TerritoryId'), new Set<Id>());
						}
						terrUserMap.get((Id)userTerritory.get('TerritoryId')).add((Id)userTerritory.get('UserId'));
					}

					//check if the user is assigned to a territory
					if(userTerrIdSet.size() > 0) {

						objTer2IdMap = new Map<Id, String>();
						Set<Id> groupIdSet = new Set<Id>();
						for (Sobject accShr : accShrList) {
							groupIdSet.add((ID)accShr.get('UserOrGroupId'));
							objTer2IdMap.put((ID)accShr.get('UserOrGroupId'), (String)accShr.get('RowCause'));
						}
						query = 'SELECT Id, RelatedId FROM Group WHERE Id IN :groupIdSet AND Type = \'Territory\'';
						List<Sobject> groupList;


						groupList = Database.query(query);
						Set<Id> terIdSet = new Set<Id>();
						for (Sobject Gr : groupList) {
							terIdSet.add((ID)gr.get('RelatedId'));
						}
						
						query = 'SELECT ID, Name, ParentTerritoryId, AccountAccessLevel, OpportunityAccessLevel, CaseAccessLevel, ContactAccessLevel From Territory';
						Map<Id, Sobject> territoryIdMap = new Map<Id, Sobject>(Database.query(query));
						//system.debug('territoryIdMap::' + territoryIdMap);
						List<Sobject> terList;
						Id currentTerParentID;
						Boolean existParentTer;
						UserRole currUserRole = new UserRole();
						territoryWrapperList = new List<TerritoryWrapper>();
						for(Id terId : terIdSet) {
							existParentTer = false;
							if (!userTerrIdSet.contains(terId)) {
								terList = new List<Sobject>();
								terList.add(territoryIdMap.get(terId));
								currentTerParentID = (ID)territoryIdMap.get(terId).get('ParentTerritoryId');
								while (currentTerParentID != null) {
									terList.add(territoryIdMap.get(currentTerParentID));
									if(userTerrIdSet.contains(currentTerParentID)) {
										currentTerParentID = null;
										existParentTer = true;
									} else {
										currentTerParentID = (Id)territoryIdMap.get(currentTerParentID).get('ParentTerritoryId');
									}
								}
								
								//system.debug('terList::' + terList);
								Boolean isRoleTerritory;
								isRoleTerritory = false;
								List<SObject> terRoleList = new List<SObject>();
								for (SObject ter : terList) {
									if(!isRoleTerritory) {
										terRoleList.add(ter);
									}
									//check if in the territory exist user who has current user above in Role Hierarchy
									//system.debug('terrUserMap.get((Id)ter.get(Id))::' + terrUserMap.get((Id)ter.get('Id')));
									if(terrUserMap.get((Id)ter.get('Id')) != null) {
										for (ID userId : terrUserMap.get((Id)ter.get('Id'))){
											if(!isRoleTerritory && userMap.get(userId) != null) {
												Id currentParentRoleId;
												currUserRole = userRoleMap.get(userMap.get(userId).UserRoleId);
												//system.debug('currUserRole;;' + currUserRole);
												if (currUserRole != null) {
													currentParentRoleId = currUserRole.ParentRoleId;
													userRoleSet = new Set<UserRole>();
													//system.debug('currentParentRoleId::;' + currentParentRoleId);
													while (currentParentRoleId != null) {
														userRoleSet.add(userRoleMap.get(currentParentRoleId));
														//system.debug('userMap.get(user.Id).UserRoleId::;' + userMap.get(user.Id).UserRoleId);
														if(currentParentRoleId == userMap.get(user.Id).UserRoleId) {
															currentParentRoleId = null;
															isRoleTerritory = true;
														} else {
															currentParentRoleId = userRoleMap.get(currentParentRoleId).ParentRoleId;
														}
													}
													//system.debug('userRoleSet::' + userRoleSet);
												}
											}
										}
									}
								}
								//system.debug('terRoleList::' + terRoleList);
								if(existParentTer) {
									territoryWrapperList.add(new TerritoryWrapper(territoryIdMap.get(terId), terList, existParentTer));
								}else {
									if(isRoleTerritory) {
										User userTerritory;
										for(Id userID : userMap.KeySet()) {
											if(userMap.get(userId).UserRoleId == currUserRole.Id) {
												userTerritory = userMap.get(userId);
												break;
											}
										}
										territoryWrapperList.add(new TerritoryWrapper(territoryIdMap.get(TerId), terRoleList, true, userRoleSet, isRoleTerritory, userTerritory));
									} 
								}
							} else {
								territoryWrapperList.add(new TerritoryWrapper(territoryIdMap.get(terId),  existParentTer));
							}
						}
						//system.debug('territoryWrapperList::' + territoryWrapperList);
						if (territoryWrapperList.size() > 0) {
							enableTerritory = True;
						} else {
							noTerritory = true;
						}
					}
				}else {
					noTerritory = true;
				}
			} catch (Exception e) {
				//system.debug('Eroare territory::' + e);
				noTerritory = true;
			}
			
			if (noTerritory2 && noTerritory) {
				if(sObjName != 'Case') {
					enabledTerritory = ' The ' + sObj.get('Name') + ' Account has no assignament in Territory Management for this user';
				}
			}
		} 
	}
	
	public void Profile () {
         if(!test.isRunningTest()){
             profileName = user.Profile.Name;
             profileId =  user.ProfileId;

		 
		userPermission = [SELECT Id, Name, PermissionsModifyAllData, Profile.Name 
							FROM PermissionSet where IsOwnedByProfile = true AND Profile.Name = :ProfileName limit 7000];
        
		List<ObjectPermissions> objPermissionList = [SELECT Id, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
							FROM ObjectPermissions WHERE SobjectType = :sObjName AND ParentId = :userPermission.Id limit 7000];
		for(ObjectPermissions op : objPermissionList) {
			if(!((string)op.Id).startsWith('000')) {
				objPermission = op;
			}
		}
        system.debug('objPermission=='+objPermission);

         }
        else{
            profileName = 'System Administrator';
            userPermission = [SELECT Id, Name, PermissionsModifyAllData, Profile.Name 
							FROM PermissionSet where IsOwnedByProfile = true AND Profile.Name = :ProfileName limit 7000];
        
		List<ObjectPermissions> objPermissionList = [SELECT Id, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
							FROM ObjectPermissions WHERE SobjectType = :sObjName AND ParentId = :userPermission.Id limit 7000];
		for(ObjectPermissions op : objPermissionList) {
			if(!((string)op.Id).startsWith('000')) {
				objPermission = op;
			}
		}
        system.debug('objPermission=='+objPermission);
        }
        
	}
    
    public List<ManagerWraplist> assidnedManager() {

        List<ManagerWraplist> wrp = new List<ManagerWraplist>();
        ManagerWraplist mng = new ManagerWraplist();
        Manager = [select userName,id,manager.name,manager.Id, manager.profile.name from user where Id =: user.Id limit 7000];
        
        for(user Man:Manager){
        mng.ManagerName = string.valueOf(Man.manager.name);
        mng.ManagerProfName = string.valueOf(Man.manager.profile.name);
        wrp.add(mng);
        }

       return wrp;
       
       
    }
	
	public void permissionSetAssigned() {

		prSet = false;
		/*if(!Schema.getGlobalDescribe().get('PermissionSetAssignment').getDescribe().isAccessible()) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'You don\'t have access to PermissionSetAssignment object');
			ApexPages.addMessage(myMsg);
			return;
		}*/
		List<PermissionSetAssignment> permSetAssignList = new List<PermissionSetAssignment>();
		permSetAssignList = [SELECT Id, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :user.Id limit 7000];
		Set<Id> idSet = new Set<Id>();
		for(PermissionSetAssignment permAssign : permSetAssignList) {
			idSet.add(permAssign.PermissionSetId);
		}

		permisionSetList = [SELECT Id, Name, Label, PermissionsModifyAllData, Profile.Name, 
							(SELECT Id, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords from Objectperms where SobjectType = :sObjName) 
							FROM PermissionSet where IsOwnedByProfile = false AND Id IN :idSet limit 7000];

		permissionSetMap = new Map<PermissionSet, ObjectPermissions>();
		for (PermissionSet permSet : permisionSetList) {
			for (ObjectPermissions objPerm : permSet.ObjectPerms) {
				if(!((string)objPerm.Id).startsWith('000')) {
					permissionSetMap.put(permSet, objPerm);
					prSet = true;

				}
			}

		}

		permisionSetList = new List<PermissionSet>();
	}
	
	public void RecordTypeAssigned () {
		existRT = 'Record Type : ';
		 
		recordTypeList = new List<String>();
		try {
			readProfileObject(profileName);
			 
			List<RecordType> rTList = [SELECT Name, DeveloperName, BusinessProcessId  FROM RecordType WHERE sObjectType = :sObjName limit 7000];

			recTypeList = new List<RecordType>();
			for(RecordType rt : rTList) {
				for(String rTName : recordTypeList) {
					if(rTName.contains(rt.DeveloperName)) {
						recTypeList.add(rt);
					}
				}
			}
			//system.debug('recTypeList::' + recTypeList);
			if(recTypeList.size() == 0) {
				existRT = 'No Record Type';
			}
		} catch (Exception e) {
			existRT = 'No Record Type';
		}
	}
	
	public void sharingHierarchyRole(Map<Id, SObject> shrGroupMap) {
		//system.debug('shrGroupMap:::::' + shrGroupMap);
		noUserRole = false;
		if (user.UserRoleId != null) {
			//Id currentUserRoleId = userRoleMap.get(user.UserRoleId).Id;
			Id currentUserRoleId = user.UserRoleId;
			////system.debug('currentUserRoleId:::::' + userRoleMap.get(user.UserRoleId));
			userSharingRoleMap = new Map<User, List<UserRole>>();
			List<UserRole> userRoleSharingList;
			UserRole sharingUserRole;
			for(Id userOrGroupId : shrGroupMap.keySet()) {
				if(userMap.KeySet().contains(userOrGroupId)) {
					noSharingRole = true;
					sharingUserRole = new UserRole();
					sharingUserRole = userRoleMap.get(userMap.get(userOrGroupId).userRoleId);
					////system.debug('sharingUserRole::' + sharingUserRole);
					Id parentRoleId;
					if (sharingUserRole != null) {
						userRoleSharingList = new List<UserRole>();
						userRoleSharingList.add(userRoleMap.get(sharingUserRole.Id));
						parentRoleId = sharingUserRole.ParentRoleId;
						while (parentRoleId != null) {
							userRoleSharingList.add(userRoleMap.get(parentRoleId));
							if(parentRoleId == currentUserRoleId) {
								parentRoleId = null;
								noSharingRole = false;
								noUserRole = true;
							} else {
								parentRoleId = userRoleMap.get(parentRoleId).ParentRoleId;
							}
						}
						////system.debug('userRoleSharingList;;;' + userRoleSharingList);
						////system.debug('noSharingRole;;;' + noSharingRole);
						if (!noSharingRole && !userSharingRoleMap.keySet().contains(userMap.get(userOrGroupId))) {
							Integer index = userRoleSharingList.size();
							//system.debug('index ;;;' + index );
							List<UserRole> urList = new UserRole[index];
							for(UserRole ur : userRoleSharingList) {
								index = index - 1;
								urList.add(index, ur);
							}
							
							////system.debug('urList;;;' + urList);
							userSharingRoleMap.put(userMap.get(userOrGroupId), new List<UserRole>(urList));
						}
					}
				}
			}
		}
	}
	
    
    /* public void toggleContent() {
            
            
         if(showContent){
             showContent = false;
             system.debug('showContent==false');
         }
         else{
             showContent = true;
             system.debug('showContent==true');
         }
    } 
      public pageReference ExportExcel() {
        PageReference pageRef;
        pageRef = new PageReference('/apex/RecordAccessExportExcel');
         return pageRef;
    }
    */
    
    
	public List<UserRole> RoleAsigned (User user) {
		List<UserRole> userRoleList = new List<UserRole>();
		Id currentParentRoleId;
		currentUserRole = userRoleMap.get(user.UserRoleId);
		//system.debug('currentUserRole::' + currentUserRole);
		if (currentUserRole != null) {
			currentParentRoleId = currentUserRole.ParentRoleId;
			//system.debug('currentParentRoleId::' + currentParentRoleId);
			while (currentParentRoleId != null) {
				userRoleList.add(userRoleMap.get(currentParentRoleId));
				currentParentRoleId = userRoleMap.get(currentParentRoleId).ParentRoleId;
			}
			//system.debug('userRoleList::' + userRoleList);
		}
		return userRoleList;
	}
	
 	public void GroupAsigned (Map<Id, SObject> shrGroupMap) {

		isRoleGroupShare = false;
		isRoleSubordinatesGroupShare = false;
		isRolePublicGroupShare = false;
		roleGroupMap = new Map<Group, List<UserRole>>();
		userGroupSharingMap = new Map<Group, User>();
		roleGroupSharingMap = new Map<Group, List<UserRole>>();
        //system.debug('$#$#testing=='+ userGroupSharingMap + '   roleGroupMap=='+ roleGroupMap);
	 
		Map<Id, Group> groupMap = new Map<Id, Group>([SELECT ID, Type, Name, RelatedId, DeveloperName FROM Group LIMIT 1000]); //WHERE Type != 'Queue']);
		
        List<GroupMember> groupMemberList;


		Set<Id> groupIdSet = new Set<Id>();

		groupIdSet.addAll(groupMap.Keyset());
		groupMemberList = [SELECT UserOrGroupId, GroupID FROM GroupMember WHERE GroupID IN :groupIdSet limit 7000];
		groupList = new List<Group>();
		for(Id groupId : shrGroupMap.KeySet()) {
            
			if(groupMap.containsKey(groupId) ) { //&& groupMap.get(groupId).Type == 'Organization'
				groupList.add(groupMap.get(groupId));

			}
            if(groupMap.get(groupId).Type == 'Organization' ) {
				groupList.add(groupMap.get(groupId));

			}
            
		}
        
			
		groupIdSet = new Set<Id>();
		Map<Id, Set<ID>> GroupMemberMap = new Map<Id, Set<ID>>();
		Map<Id, Set<ID>> userOrGroupIdMemberMap = new Map<Id, Set<ID>>();


		for(GroupMember gm : groupMemberList){
			if(!GroupMemberMap.KeySet().contains(gm.GroupID)) {
				GroupMemberMap.put(gm.GroupID, new Set<Id>());

			}
			GroupMemberMap.get(gm.GroupID).add(gm.UserOrGroupId);
			if(!userOrGroupIdMemberMap.keySet().contains(gm.UserOrGroupId)){
				userOrGroupIdMemberMap.put(gm.UserOrGroupId,  new Set<Id>());
			}
			userOrGroupIdMemberMap.get(gm.UserOrGroupId).add(gm.GroupID);
		}


		Set<Id> groupSearchIdSet = new Set<Id>();
		for (ID UserOrGroupId : shrGroupMap.KeySet()) {


			if(GroupMemberMap.containsKey(UserOrGroupId)) {

				if (GroupMemberMap.get(UserOrGroupId).contains(user.Id)){
					groupIdSet.add(UserOrGroupId);
				} else {
					List<UserRole> userRoleList;

					if(GroupMemberMap.containsKey(UserOrGroupId)) {

						for(Id userID : GroupMemberMap.get(UserOrGroupId)) {
							if(userMap.containsKey(userID)) {

								userRoleList = new List<UserRole>();
								userRoleList.addAll(RoleAsigned(userMap.get(userID)));
								List<UserRole> roleList = new List<UserRole>();
								roleList.add(userRoleMap.get(userMap.get(userID).UserRoleId));
								for(UserRole ur : userRoleList) {

									roleList.add(ur);
									if(ur.id == user.UserRoleId){
                                       isRolePublicGroupShare = true;

										isGroupShr = true;
										break;
									}
								}

								if(isRolePublicGroupShare){

									List<UserRole> urList = new List<UserRole>(roleList);
									roleList.clear();
									Integer index = urList.size();
									for(UserRole ur : urList) {

										index = index - 1;
										roleList.add(urList.get(index));
									}
									roleGroupSharingMap.put(groupMap.get(UserOrGroupId), roleList);
									userGroupSharingMap.put(groupMap.get(UserOrGroupId), userMap.get(userId));

								}
							} else {

								if(groupMap.containsKey(userID) && groupMap.get(userID).RelatedId == user.UserRoleId) {

									groupIdSet.add(UserOrGroupId);
								} else {

									groupSearchIdSet.add(userID);
								}
							}
						}
					}
				}
			}
		}

		for(Group gr : roleGroupSharingMap.keySet()) {

			if(!sharingCriteriaRuleMap.containsKey(gr.DeveloperName)) {

				sharingCriteriaRuleMap.put(gr.DeveloperName, '');


			}

		}

		if (groupSearchIdSet.size() > 0) {

			for(Id groupId : groupSearchIdSet) {

				if(GroupMemberMap.containsKey(groupId) && GroupMemberMap.get(groupId) != null) {

					if(GroupMemberMap.get(groupId).contains(user.Id)) {

						groupIdSet.add(groupId);
					}else {

						groupSearchIdSet.addAll(GroupMemberMap.get(groupId));
					}
				}
			}
		}
 
		if (groupIdSet.size() > 0) {

			for(Id gr : groupMap.keySet()) {

				if(groupIdSet.contains(gr)) {
					groupList.add(groupMap.get(gr));
				}
			}

		} 

		roleAndSubordinatesGroupMap = new Map<Group, List<UserRole>>(); 
		for(Id grId : groupMap.keySet()) {
			Group groupItem = groupMap.get(grId);
			if(shrGroupMap.containsKey(grId)&& (groupItem.Type == 'Role' || groupItem.Type == 'RoleAndSubordinates')) { //

				if(groupItem.RelatedId != null && groupItem.RelatedId == user.UserRoleId) {

					roleGroupMap.put(groupItem, new List<UserRole>());
					isRoleGroupShare = true;
					isGroupShr = true;
				} else { 
					List<User> userList = new List<User>();
					for(Id userId: UserMap.KeySet()) {
						if(UserMap.get(userId).UserRoleId == groupItem.RelatedId) {
							userList.add(UserMap.get(userId));
						}
					}

					//system.debug('userList12:::' + userList);
					List<UserRole> userRoleList = new List<UserRole>();
					Boolean isRole;
					if(userList.size() > 0) {
						for(User usr : userList) {
							isRole = false;
							userRoleList.addAll(RoleAsigned(usr));
							List<UserRole> roleList = new List<UserRole>();
							if(userRoleList.size() > 0) {
								for(UserRole ur : userRoleList) {
									roleList.add(ur);
									if(ur.id == user.UserRoleId) {
										isRoleGroupShare = true;
										isGroupShr = true;
										isRole = true;
										break;
									}
								}
							}
							if(isRole){
								List<UserRole> urList = new List<UserRole>(roleList);
								roleList.clear();
								Integer index = urList.size();
								for(UserRole ur : urList) {
									index = index - 1;
									roleList.add(urList.get(index));
								}
								roleGroupMap.put(groupItem, roleList);
								
								break;
							}
						}
					}
				}
				
			}
			if(shrGroupMap.containsKey(grId) && (groupItem.Type == 'RoleAndSubordinates')) {

				if(groupItem.RelatedId != null && groupItem.RelatedId != user.UserRoleId) {
					//system.debug('userRoleMap2::' + groupMap.get(grId).RelatedId);
					
					List<UserRole> userRoleSubordinatesList = new List<UserRole>(RoleAsigned(user));
					List<UserRole> roleList = new List<UserRole>();
					for(UserRole ur : userRoleSubordinatesList) {

						roleList.add(ur);
						if(ur.id == groupItem.RelatedId) {
							isRoleSubordinatesGroupShare = true;
							isGroupShr = true;
							break;
						}
					}
					if(isRoleSubordinatesGroupShare){

						List<UserRole> urList = new List<UserRole>(roleList);
						roleList.clear();
						Integer index = urList.size();
						for(UserRole ur : urList) {
							index = index - 1;
							roleList.add(urList.get(index));
						}
						roleAndSubordinatesGroupMap.put(groupItem, roleList);

					}
				}
			}
		}
		for (Group gr : roleGroupMap.Keyset()) {

			if(!sharingCriteriaRuleMap.containsKey(gr.DeveloperName)) {

				sharingCriteriaRuleMap.put(gr.DeveloperName, '');
			}
		}


		if (groupList.size() > 0) {

            for (Group gr : groupList) { 
				if(!sharingCriteriaRuleMap.containsKey(gr.DeveloperName)) {

					sharingCriteriaRuleMap.put(gr.DeveloperName, '');
				}
			}
			isGroupShr = true;

			Set<Group> groupSet = new Set<Group>(groupList);
			groupList = new List<Group>(groupSet); 

		}
	}
	 
     
	public static MetadataService.MetadataPort createService() { 
		MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = UserInfo.getSessionId();
		//service.endpoint_x = 'callout:SA_Audit__Tooling_API_Creds';
		service.timeout_x = 120000;
		return service;
	}
	
	public void readCustomObject(String objName) {
		//system.debug('customObjectMetadata::');
		MetadataService.MetadataPort service = createService();
		MetadataService.ReadCustomObjectResult rs = (MetadataService.ReadCustomObjectResult) 
			service.readMetadata('CustomObject', new String[] {objName});
		//system.debug('customObjectMetadata::' + rs);
		for (MetadataService.Metadata md : rs.getRecords()) {
			if (md != null) {
				MetadataService.CustomObject obj = (MetadataService.CustomObject) md;
				isCustom = true;
				customShr = (String)obj.sharingmodel;
				//system.debug('Custom object full name: ' + obj.fullName);
				//system.debug('Label: ' + obj.label);
				//system.debug('Sharing model: ' + obj.sharingmodel);
			} else {
				//system.debug('Empty metadata.');
			}
		}
	}
	
	public void readSharingRule(String objName){

		// Read Sharing Rule
		MetadataService.MetadataPort service = createService();
		transient MetadataService.SharingRules sharingRules = (MetadataService.SharingRules) service.readMetadata('SharingRules',new String[] {objName}).getRecords()[0];

		String sharingCriteriaRule;
		
		if(sharingRules.sharingCriteriaRules != null) {
			for(MetadataService.SharingCriteriaRule scr: sharingRules.sharingCriteriaRules) {

				for(MetadataService.FilterItem crit : scr.criteriaItems){
					sharingCriteriaRule = crit.field + ' ' + crit.operation + ' ' + (crit.value != null ? crit.value : crit.valueField);
                      if(scr.sharedTo.group_x != null) {
						for(String groupName : scr.sharedTo.group_x) {

							sharingCriteriaRuleMap.put(groupName, sharingCriteriaRule);

						}
					}
					if(scr.sharedTo.allCustomerPortalUsers != null) {
						sharingCriteriaRuleMap.put(scr.sharedTo.allCustomerPortalUsers, sharingCriteriaRule);

					}
					if(scr.sharedTo.allInternalUsers != null) {
						sharingCriteriaRuleMap.put('AllInternalUsers', sharingCriteriaRule);

					}
					if(scr.sharedTo.allPartnerUsers != null) {
						sharingCriteriaRuleMap.put(scr.sharedTo.allPartnerUsers, sharingCriteriaRule);

					}
					if(scr.sharedTo.portalRole != null) {
						for(String portalUser : scr.sharedTo.portalRole) {
							sharingCriteriaRuleMap.put(portalUser, sharingCriteriaRule);

						}
					}
					if(scr.sharedTo.portalRoleandSubordinates != null) {
						for(String portalUser : scr.sharedTo.portalRoleandSubordinates) {
							sharingCriteriaRuleMap.put(portalUser, sharingCriteriaRule);

						}
					}
					if(scr.sharedTo.role != null) {
						for(String userRole : scr.sharedTo.role) {
							sharingCriteriaRuleMap.put(userRole + 'A', sharingCriteriaRule);
							sharingCriteriaRuleMap.put(userRole, sharingCriteriaRule);

						}
					}
					if(scr.sharedTo.roleAndSubordinates != null) {
						for(String userRole : scr.sharedTo.roleAndSubordinates) {
							sharingCriteriaRuleMap.put(userRole + 'D', sharingCriteriaRule);
							sharingCriteriaRuleMap.put(userRole, sharingCriteriaRule);

						}
					}
					if(scr.sharedTo.roleAndSubordinatesInternal != null) {
						for(String userRole : scr.sharedTo.roleAndSubordinatesInternal) {
							sharingCriteriaRuleMap.put(userRole, sharingCriteriaRule);

						}
					}
					if(scr.sharedTo.queue != null) {
						for(String que : scr.sharedTo.queue) {
							sharingCriteriaRuleMap.put(que, sharingCriteriaRule);

						}
					}


				}
			}
			

			for(String x : sharingCriteriaRuleMap.Keyset()) {
 
			}
		}
		if(sharingRules.sharingOwnerRules != null) {
			String userRoleDevName = userRoleMap.get(userMap.get((Id)sObj.get('OwnerId')).UserRoleId).DeveloperName;
			String userRoleLabel = userRoleMap.get(userMap.get((Id)sObj.get('OwnerId')).UserRoleId).Name;

			Set<String> userRoleDevNameSet = new Set<String>();
			List<UserRole> roleAssignedList = new List<UserRole>(RoleAsigned(userMap.get((Id)sObj.get('OwnerId'))));
			for(UserRole ur : roleAssignedList ) {
				userRoleDevNameSet.add(ur.DeveloperName);
			}
			Boolean isFound;
			for(MetadataService.SharingOwnerRule scr: sharingRules.sharingOwnerRules) {
				isFound = false;

				sharingCriteriaRule = 'Owner in  ';
				if(scr.sharedFrom.allCustomerPortalUsers != null && scr.sharedFrom.allCustomerPortalUsers == userRoleDevName) {
					sharingCriteriaRule += 'allCustomerPortalUsers(' + userRoleLabel + ')';
					isFound = true;
				}
				if(scr.sharedFrom.allInternalUsers != null && scr.sharedFrom.allInternalUsers == userRoleDevName) {
					sharingCriteriaRule += 'allInternalUsers (' + userRoleLabel + ')';
					isFound = true;
				}
				if(scr.sharedFrom.allPartnerUsers != null && scr.sharedFrom.allPartnerUsers == userRoleDevName) {
					sharingCriteriaRule += 'AllPartnerUsers(' + userRoleLabel + ')';
					isFound = true;
				}
				if(scr.sharedFrom.portalRole != null) {
					for(String portalRole : scr.sharedFrom.portalRole) {
						if(portalRole == userRoleDevName) {
							sharingCriteriaRule += 'PortalRole (' + userRoleLabel + ')';
							isFound = true;
						}
					}
					
				}
				if(scr.sharedFrom.portalRoleandSubordinates != null) {
					for(String portalRoleandSubordinates : scr.sharedFrom.portalRoleandSubordinates) {
						if(userRoleDevNameSet.contains(portalRoleandSubordinates)) {
							sharingCriteriaRule += 'PortalRoleandSubordinates (' + portalRoleandSubordinates + ')';
							isFound = true;
						}
					}
				}
				if(scr.sharedFrom.role != null) {
					for(String role : scr.sharedFrom.role) {

						if(role == userRoleDevName) {

							sharingCriteriaRule += 'Role (' + userRoleLabel + ')';

							isFound = true;
						}
					}
				}
				if(scr.sharedFrom.roleAndSubordinates != null) {
					for(String roleAndSubordinates : scr.sharedFrom.roleAndSubordinates) {

						if(userRoleDevNameSet.contains(roleAndSubordinates)) {
							sharingCriteriaRule += 'RoleAndSubordinates (' + roleAndSubordinates + ')';
							isFound = true;
						}
					}
				}
				if(scr.sharedFrom.roleAndSubordinatesInternal != null) {
					for(String roleAndSubordinatesInternal : scr.sharedFrom.roleAndSubordinatesInternal) {
						if(userRoleDevNameSet.contains(roleAndSubordinatesInternal)) {
							sharingCriteriaRule += 'RoleAndSubordinatesInternal (' + roleAndSubordinatesInternal + ')';
							isFound = true;
						}
					}
				}
				if(scr.sharedFrom.queue != null) {
					for(String queue : scr.sharedFrom.queue) {
						if(queue == userRoleDevName) {
							sharingCriteriaRule += 'Queue (' + userRoleLabel + ')';
							isFound = true;
						}
					}
				}
				sharingCriteriaRule += ' Shared With ';
				
				//system.debug('sharingCriteriaRule11::' + sharingCriteriaRule);
				//system.debug('scr.sharedTo::::' + scr.sharedTo.group_x );
				if(isFound) {
					if(scr.sharedTo.group_x != null) {
						for(String groupName : scr.sharedTo.group_x) {
							if(!sharingCriteriaRuleMap.containsKey(groupName)){
								//system.debug('groupName::::' + groupName );
								sharingCriteriaRule += groupName;
								sharingCriteriaRuleMap.put(groupName, sharingCriteriaRule);
							}
						}
					}
					//system.debug('sharingCriteriaRule12::' + sharingCriteriaRule);
					if(scr.sharedTo.allCustomerPortalUsers != null) {
						sharingCriteriaRule += 'allCustomerPortalUsers ' + scr.sharedTo.allCustomerPortalUsers;
						sharingCriteriaRuleMap.put(scr.sharedTo.allCustomerPortalUsers, sharingCriteriaRule);
					}
					if(scr.sharedTo.allInternalUsers != null) {
						sharingCriteriaRule += 'allInternalUsers ' + scr.sharedTo.allInternalUsers;
						sharingCriteriaRuleMap.put(scr.sharedTo.allInternalUsers, sharingCriteriaRule);
					}
					if(scr.sharedTo.allPartnerUsers != null) {
						sharingCriteriaRule += 'allPartnerUsers ' + scr.sharedTo.allPartnerUsers;
						sharingCriteriaRuleMap.put(scr.sharedTo.allPartnerUsers, sharingCriteriaRule);
					}
					if(scr.sharedTo.portalRole != null) {
						for(String portalUser : scr.sharedTo.portalRole) {
							sharingCriteriaRule += 'portalRole ' + portalUser;
							sharingCriteriaRuleMap.put(portalUser, sharingCriteriaRule);
						}
					}
					if(scr.sharedTo.portalRoleandSubordinates != null) {
						for(String portalUser : scr.sharedTo.portalRoleandSubordinates) {
							sharingCriteriaRule += 'portalRoleandSubordinates ' +  portalUser;
							sharingCriteriaRuleMap.put(portalUser, sharingCriteriaRule);
						}
					}
					if(scr.sharedTo.role != null) {
						for(String userRole : scr.sharedTo.role) {
							sharingCriteriaRule += 'Role ' + userRole;
							sharingCriteriaRuleMap.put(userRole + 'A', sharingCriteriaRule);
							sharingCriteriaRuleMap.put(userRole, sharingCriteriaRule);
						}
					}
					if(scr.sharedTo.roleAndSubordinates != null) {
						for(String userRole : scr.sharedTo.roleAndSubordinates) {
							sharingCriteriaRule += 'RoleAndSubordinates ' + userRole;
							sharingCriteriaRuleMap.put(userRole + 'A', sharingCriteriaRule);
							sharingCriteriaRuleMap.put(userRole, sharingCriteriaRule);
						}
					}
					if(scr.sharedTo.roleAndSubordinatesInternal != null) {
						for(String userRole : scr.sharedTo.roleAndSubordinatesInternal) {
							sharingCriteriaRule += 'RoleAndSubordinatesInternal' + userRole;
							sharingCriteriaRuleMap.put(userRole, sharingCriteriaRule);
						}
					}
					if(scr.sharedTo.queue != null) {
						for(String que : scr.sharedTo.queue) {
							sharingCriteriaRule += 'Queue ' + que;
							sharingCriteriaRuleMap.put(que, sharingCriteriaRule);
						}
					}
				}
				//system.debug('sharingCriteriaRuleMap1::' + sharingCriteriaRuleMap);
				
			}
			
			//system.debug('sharingCriteriaRuleMap::' + sharingCriteriaRuleMap);
		}
		////system.debug('sharingRules::' + sharingRules.sharingCriteriaRules[0].criteriaItems[0]);
	}
	
	public void readProfileObject(String profName) {
		MetadataService.MetadataPort service = createService();
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = UserInfo.getSessionId();
       // service.SessionHeader.sessionId = 'callout:SA_Audit__Tooling_API_Creds';
		transient MetadataService.Profile profile = (MetadataService.Profile) service.readMetadata('Profile', new String[] {profName}).getRecords()[0];
		List<MetadataService.ProfileRecordTypeVisibility> profileRecordTypeList = profile.recordTypeVisibilities;
		//system.debug('profileRecordTypeList::' + profileRecordTypeList);
		//system.debug('profName::' + profName);
			recordTypeList = new List<String>();
			if(profile.recordTypeVisibilities != null) {
				for(MetadataService.ProfileRecordTypeVisibility rt : profile.recordTypeVisibilities) {
					//system.debug('rt::' + rt);
					if(rt.visible != null && rt.visible) {
						recordTypeList.add(rt.recordType);
					}
				}
			}
		//system.debug('recordTypeList::' + recordTypeList);
		//return profile.custom;
	}
	
	public void readRecordType(String recordTypeName) {
		MetadataService.MetadataPort service = createService();
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = UserInfo.getSessionId();
		//service.SessionHeader.sessionId = 'callout:SA_Audit__Tooling_API_Creds';
        MetadataService.RecordType recordType = (MetadataService.RecordType) service.readMetadata('RecordType', new String[] {recordTypeName}).getRecords()[0];
		//system.debug('recordType::' + recordType);
	}
	
	public void ExpandProf() {
		if (isExpandProf == false) {
			isExpandProf = true;
		}else {
			isExpandProf = false;
		}
	}
    public void ExpandAccess() {
        if (isExpandAccess == false) {
            isExpandAccess = true;
        }else {
            isExpandAccess = false;
        }
    }
    public void ExpandMan() {
		if (isExpandMan == false) {
			isExpandMan = true;
		}else {
			isExpandMan = false;
		}
	}
	
	public void ExpandOrg() {
		if (isExpandOrg == false) {
			isExpandOrg = true;
		}else {
			isExpandOrg = false;
		}
	}
	
	public void ExpandPerm() {
		if (isExpandPerm == false) {
			isExpandPerm = true;
		}else {
			isExpandPerm = false;
		}
	}
	
	public void ExpandRole() {
		if (isExpandRole == false) {
			isExpandRole = true;
		}else {
			isExpandRole = false;
		}
	}
	
	public void ExpandTerritory() {
		if (isExpandTerritory == false) {
			isExpandTerritory = true;
		}else {
			isExpandTerritory = false;
		}
	}
	
	public void ExpandSharing() {
		if (isExpandSharing == false) {
			isExpandSharing = true;
		}else {
			isExpandSharing = false;
		}
	}
	
	public void ExpandGroupSharing() {
		if (isExpandGroupSharing == false) {
			isExpandGroupSharing = true;
		}else {
			isExpandGroupSharing = false;
		}
	}
	
	public void ExpandRecordType() {
		if (isExpandRecordType == false) {
			isExpandRecordType = true;
		}else {
			isExpandRecordType = false;
		}
	}
	
	public pageReference printPDF() {
		PageReference pageRef;
		pageRef = new PageReference('/apex/RecordAccess2PDF');
		pageRef.getParameters().put('isPdf', 'true');
		pageRef.getParameters().put('userPDFID', user.ID);
		pageRef.getParameters().put('currentId', currentId);
		return pageRef;
	}
    
	public class Territory2Wrapper {
		public Sobject territory2 { get; set; }
		public List<Sobject> territory2Hierarchy { get; set; }
		public Boolean existParentTer2 { get; set; }
		public List<UserRole> userRolelist { get; set; }
		public Boolean isRoleTerritory { get; set; }
		public User userTerritory { get; set; }
		public Integer lastTerritory { get; set; }
		
		public Territory2Wrapper(Sobject territory2, List<Sobject> territory2Hierarchy, Boolean existParentTer2, Set<UserRole> userRoleSet, Boolean isRoleTerritory, User  userTerritory) {
			this.territory2 = territory2;
			this.territory2Hierarchy = territory2Hierarchy;
			this.existParentTer2 = existParentTer2;
			this.userRolelist = new List<SObject>();
			this.userRolelist.addAll(userRoleSet);
			this.isRoleTerritory = isRoleTerritory;
			this.userTerritory = userTerritory;
			this.lastTerritory = territory2Hierarchy.size() - 1;
		}
		
		public Territory2Wrapper(Sobject territory2, List<Sobject> territory2Hierarchy, Boolean existParentTer2) {
			this.territory2 = territory2;
			this.territory2Hierarchy = territory2Hierarchy;
			this.existParentTer2 = existParentTer2;
		}
		
		public Territory2Wrapper(Sobject territory2,  Boolean existParentTer2) {
			this.territory2 = territory2;
			this.existParentTer2 = existParentTer2;
		}
	}
	
	public class TerritoryWrapper {
		public Sobject territory { get; set; }
		public List<Sobject> territoryHierarchy { get; set; }
		public Boolean existParentTer { get; set; }
		public List<UserRole> userRolelist { get; set; }
		public Boolean isRoleTerritory { get; set; }
		public User userTerritory { get; set; }
		public Integer lastTerritory { get; set; }
		
		public TerritoryWrapper(Sobject territory, List<Sobject> territoryHierarchy, Boolean existParentTer, Set<UserRole> userRoleSet, Boolean isRoleTerritory, User  userTerritory) {
			this.territory = territory;
			this.territoryHierarchy = territoryHierarchy;
			this.existParentTer = existParentTer;
			this.userRolelist = new List<SObject>();
			this.userRolelist.addAll(userRoleSet);
			this.isRoleTerritory = isRoleTerritory;
			this.userTerritory = userTerritory;
			this.lastTerritory = territoryHierarchy.size() - 1;
		}
       
        
		public TerritoryWrapper(Sobject territory, List<Sobject> territoryHierarchy, Boolean existParentTer) {
			this.territory = territory;
			this.territoryHierarchy = territoryHierarchy;
			this.existParentTer = existParentTer;
		}
		public TerritoryWrapper(Sobject territory,  Boolean existParentTer) {
			this.territory = territory;
			this.existParentTer = existParentTer;
		}
	}
     public class ManagerWraplist{
            public string ManagerName {get;set;}
            public string ManagerProfName{get; set;}
            
        }
       public class ExportUserWrapper{
        public boolean Access {get;set;}
        public string userId{get; set;}
         public string userNamee{get; set;}
    }
}