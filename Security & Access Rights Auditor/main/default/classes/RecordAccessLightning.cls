public with sharing class RecordAccessLightning {
	/**
	 * @description Check if user has access to paid features
	 * @return Boolean True if user has access
	 */
	@AuraEnabled(cacheable=true)
	public static Boolean PaidFeatureAccess() {
		//return FeatureManagement.checkPackageBooleanValue('RecordAccessPaidAccess');
		return true;
	}
	
	@AuraEnabled
	public static  List<String> getObjectNameAndLabel(String objectId) {
		Boolean isError = false;
		String sObjLabel;
		String sObjName;
		Sobject sObj;
		List<String> returnList = new List<String>();
		try {
			Id currentId = (Id)ObjectId;
			sObjLabel = currentId.getSObjectType().getDescribe().getLabel();
			sObjName = currentId.getSObjectType().getDescribe().getName();
			String query1;
			if(!Schema.getGlobalDescribe().get(sObjName).getDescribe().isAccessible()) {
				returnList.add('true');
				returnList.add('You don\'t have access to ' + sObjName);
			} else {
				if(sObjName == 'Case') {
					query1 = 'SELECT Id, CaseNumber, OwnerId FROM ' + sObjName + ' WHERE ID = :currentId';
				} else {
					query1 = 'SELECT Id, Name, OwnerId FROM ' + sObjName + ' WHERE ID = :currentId';
				}
				system.debug('String.escapeSingleQuotes(query1::' + String.escapeSingleQuotes(query1));
				sObj = Database.query(String.escapeSingleQuotes(query1));
				system.debug('sObj::' + sObj);
				returnList.add('false');
				returnList.add(sObjLabel);
				sObjName = (String)sObj.get('Name');
				returnList.add(sObjName);
			}
		} catch(Exception e) {
			returnList.add('true');
			returnList.add('Please enter a valid record ID.');
		}
        system.debug('$#$#returnlist'+returnList);
		return returnList;
	}
	
	@AuraEnabled
	public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName) {
		String searchKey = String.escapeSingleQuotes(searchKeyWord) + '%';
		
		List < sObject > returnList = new List < sObject > ();
	  
		// Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5   
		String sQuery =  'select id, Name from ' + String.escapeSingleQuotes(ObjectName) + ' where Name LIKE: searchKey order by createdDate DESC limit 10';
		List < sObject > lstOfRecords = Database.query(String.escapeSingleQuotes(sQuery));
		
		for (sObject obj: lstOfRecords) {
			returnList.add(obj);
		}
		return returnList;
	}
	
	@AuraEnabled
	public static owdWrapperClass OWD(String objectName, String objectLabel) {
		owdWrapperClass owdW = new owdWrapperClass();
		if(String.escapeSingleQuotes(objectName) != 'null') {
			if(!Schema.getGlobalDescribe().get('Organization').getDescribe().isAccessible()) {
				owdW.errorMSG = 'You don\'t have access to Organization object';
			} else {
				String query;
				Organization organization;
				String fieldOrg;
				system.debug('objectName:;' + String.escapeSingleQuotes(objectName));
				if (!String.escapeSingleQuotes(objectName).contains('__c')) {
					fieldOrg = 'Default' + String.escapeSingleQuotes(objectName) + 'Access';
					if(SecurityUtil.getFieldDescribeMap('Organization').containsKey(fieldOrg.toLowerCase())) {
						query = 'SELECT Id, IsSandbox, Name, OrganizationType, PrimaryContact, ' + String.escapeSingleQuotes(fieldOrg) + ' FROM Organization';
					} else {
						query = 'SELECT Id, IsSandbox, Name, OrganizationType, PrimaryContact FROM Organization';
						fieldOrg ='';
					}
					organization = Database.query(String.escapeSingleQuotes(query));
					system.debug('organization:;' + organization);
					owdW.defaultAccess = (String)organization.get(fieldOrg) != 'None' ? (String)organization.get(fieldOrg) : 'Private';
				} else {
					query = 'SELECT Id, IsSandbox, Name, OrganizationType, PrimaryContact FROM Organization';
					organization = Database.query(String.escapeSingleQuotes(query));
					system.debug('query2:;' + String.escapeSingleQuotes(query));
					system.debug('organization:;' + organization);
					fieldOrg = 'Default' + objectLabel + 'Access';
					try{
						 owdW.defaultAccess = readCustomObject(objectName); 
					} catch(Exception e) {
						system.debug('exception::' + e);
					}
				}
				owdW.organizationName = organization.Name;
				owdW.fieldOrg = fieldOrg;
				owdW.errorMSG = 'false';
			} 
		} else {
			owdW.organizationName = 'aa';
			owdW.defaultAccess = 'aa';
			owdW.fieldOrg = 'aaa';
			owdW.errorMSG = 'false';
		}
		system.debug('owdW::' + owdW);
		return owdW;
	}
	
	@AuraEnabled
	public static ProfileWrapper Profile (String userID, String objectAPI) {
		ProfileWrapper pw = new ProfileWrapper();
		if(objectAPI != 'null') {	 
			String profileName = [SELECT Id, Profile.Name, Name FROM User WHERE Id =:userId].Profile.Name;
			system.debug('ProfileName::' + user.Profile.Name);
			if(!Schema.getGlobalDescribe().get('Profile').getDescribe().isAccessible() || 
			   !Schema.getGlobalDescribe().get('PermissionSet').getDescribe().isAccessible() ||
			   !Schema.getGlobalDescribe().get('ObjectPermissions').getDescribe().isAccessible()) {
				   pw.errorMSG = 'You don\'t have access to Profile object';
				   return pw;
			}
			PermissionSet userPermission = [SELECT Id, Name, PermissionsModifyAllData, Profile.Name 
							  FROM PermissionSet where IsOwnedByProfile = true AND Profile.Name = :ProfileName];
			List<ObjectPermissions> objPermissionList = [SELECT Id, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
														 FROM ObjectPermissions WHERE SobjectType = :objectAPI AND ParentId = :userPermission.Id];
			pw.modifyAllData = userPermission.PermissionsModifyAllData;
			pw.profileName = profileName;
			// Initialize default values in case no ObjectPermissions are found
			pw.create = false;
			pw.read = false;
			pw.edit = false;
			pw.del = false;
			pw.viewAllRecords = false;
			pw.modifyAllRecords = false;
			pw.errorMSG = 'false';
			for(ObjectPermissions op : objPermissionList) {
				if(!((string)op.Id).startsWith('000')) {
					pw.create = op.PermissionsCreate;
					pw.read = op.PermissionsRead;
					pw.edit = op.PermissionsEdit;
					pw.del = op.PermissionsDelete;
					pw.viewAllRecords = op.PermissionsViewAllRecords;
					pw.modifyAllRecords = op.PermissionsModifyAllRecords ;
				}
			}
			system.debug('userPermission::' + userPermission);
		} else {
			pw.modifyAllData = false;
			pw.profileName = 'aa';
			pw.create = false;
			pw.read = false;
			pw.edit = false;
			pw.del = false;
			pw.viewAllRecords = false;
			pw.modifyAllRecords = false;
			pw.errorMSG = 'false';
		}
		return pw;
	}
	
	@AuraEnabled
	public static List<ProfileWrapper> permissionSetAssigned(String userID, String objectAPI) {
		List<ProfileWrapper> pwList = new List<ProfileWrapper>();
		if(objectAPI != 'null') {
			if(!Schema.getGlobalDescribe().get('PermissionSetAssignment').getDescribe().isAccessible()) {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'You don\'t have access to PermissionSetAssignment object');
				ApexPages.addMessage(myMsg);
			}
			List<PermissionSetAssignment> permSetAssignList = new List<PermissionSetAssignment>();
			permSetAssignList = [SELECT Id, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :userID];
			Set<Id> idSet = new Set<Id>();
			for(PermissionSetAssignment permAssign : permSetAssignList) {
				idSet.add(permAssign.PermissionSetId);
			}
			system.debug('permSetAssignList::' + permSetAssignList);
			List<PermissionSet> permisionSetList = [SELECT Id, Name, Label, PermissionsModifyAllData, Profile.Name, 
								(SELECT Id, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords from Objectperms where SobjectType = :objectAPI) 
								FROM PermissionSet where IsOwnedByProfile = false AND Id IN :idSet];
			
			
			for (PermissionSet permSet : permisionSetList) {
				for (ObjectPermissions objPerm : permSet.ObjectPerms) {
					if(!((string)objPerm.Id).startsWith('000')) {
						ProfileWrapper pw = new ProfileWrapper();
						pw.modifyAllData = permSet.PermissionsModifyAllData;
						pw.profileName = permSet.Name;
						pw.create = objPerm.PermissionsCreate;
						pw.read = objPerm.PermissionsRead;
						pw.edit = objPerm.PermissionsEdit;
						pw.del = objPerm.PermissionsDelete;
						pw.viewAllRecords = objPerm.PermissionsViewAllRecords;
						pw.modifyAllRecords = objPerm.PermissionsModifyAllRecords ;
						pw.errorMSG = 'false';
						pwList.add(pw);
					}
				}
			}
		}
		system.debug('pwList::' + pwList);
		return pwList;
	}
	
	public static Map<Id, SObject> sharringMap(String ObjectId) {
		String query;
		String pId;
		String ShareObject;
		Id currentId = (Id)ObjectId;
		system.debug('currentId::' + currentId);
		String sObjLabel = currentId.getSObjectType().getDescribe().getLabel();
		String sObjName = currentId.getSObjectType().getDescribe().getName();
		if(query == null) {
			query = 'SELECT ';
		} else {
			query += ' ';
		}
		String access;
		String accessLabel;
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
		accessLabel = sObjLabel + ' Access Level';
		//check if the our organization has Sharing for the Object
		Map<String, Schema.SObjectType> tokens = Schema.getGlobalDescribe();
		if(!Schema.getGlobalDescribe().get(ShareObject).getDescribe().isAccessible()) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'You don\'t have access to' + ShareObject + ' object');
			ApexPages.addMessage(myMsg);
			return null;
		}
		Map<Id, SObject> shrGroupMap = new Map<Id, SObject>();
		if(tokens.containsKey(ShareObject)) {
			query += access + ', RowCause, UserOrGroupId FROM '+ ShareObject + ' WHERE ' + pId + ' = :currentId';
			system.debug('query:;;' + query);
			List<SObject> shrList;
			shrList = Database.query(query);
			List<SObject> shrObjList = new List<SObject>();
			system.debug('user.Id::' + user.Id);
			for(SObject shr : shrList) {
				if(shr.get('UserOrGroupId') == user.Id) {
					shrObjList.add(shr);
				} else {
					shrGroupMap.put((Id)shr.get('UserOrGroupId'), shr);
				}
			}
			system.debug('shrObjList:;;' + shrObjList);
		}
		return shrGroupMap;
	}
	
	@AuraEnabled
	public static UserRoleWrapperClass sharingHierarchyRole(String userId, String ObjectID) {
		system.debug('1ObjectId: '  + ObjectID);
		system.debug('userId: '  + userId);
		UserRoleWrapperClass userRolewrapper = new UserRoleWrapperClass();
		Map<Id, SObject> shrGroupMap = new Map<Id, SObject>(sharringMap(ObjectID));
		Map<ID, UserRole> userRoleMap = new Map<ID, UserRole>([SELECT Id, Name, DeveloperName, ParentRoleId  FROM UserRole WHERE PortalType = 'None' OR PortalType = 'CustomerPortal' OR PortalType = 'Partner']);
		Map<Id, User> userMap = new Map<Id, User>([SELECT Name, UserRoleId, Profile.Name FROM User WHERE IsActive = true Limit 50000]);
		Boolean noUserRole = false;
		Boolean noSharingRole;
		User user = userMap.get((Id)userId);
		Map<User, List<UserRole>> userSharingRoleMap = new Map<User, List<UserRole>>();
		userRolewrapper.userRoleName = user.UserRoleId != null ? userRoleMap.get(user.UserRoleId).Name : ' No User Role defined';
		if (user.UserRoleId != null) {
			Id currentUserRoleId = userMap.get((Id)userId).UserRoleId;
			system.debug('currentUserRoleId:::::' + currentUserRoleId);
			userSharingRoleMap = new Map<User, List<UserRole>>();
			List<UserRole> userRoleSharingList;
			UserRole sharingUserRole;
			for(Id userOrGroupId : shrGroupMap.keySet()) {
				if(userMap.KeySet().contains(userOrGroupId)) {
					noSharingRole = true;
					sharingUserRole = new UserRole();
					sharingUserRole = userRoleMap.get(userMap.get(userOrGroupId).userRoleId);
					system.debug('sharingUserRole::' + sharingUserRole);
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
						system.debug('userRoleSharingList;;;' + userRoleSharingList);
						if (!noSharingRole && !userSharingRoleMap.keySet().contains(userMap.get(userOrGroupId))) {
							Integer index = userRoleSharingList.size();
							system.debug('index ;;;' + index );
							List<UserRole> urList = new UserRole[index];
							for(UserRole ur : userRoleSharingList) {
								index = index - 1;
								urList.add(index, ur);
							}
							
							system.debug('urList;;;' + urList);
							userSharingRoleMap.put(userMap.get(userOrGroupId), new List<UserRole>(urList));
						}
					}
				}
			}
		}
		
		List<UserSharingRoleWrapperClass> userSharingRoleWrapperList = new List<UserSharingRoleWrapperClass>();
		for(User u : userSharingRoleMap.keySet()) {
			List<String> userRoleNameList = new List<String>();
			if(userSharingRoleMap.containskey(u) && userSharingRoleMap.get(u) != null) {
				for(UserRole ur: userSharingRoleMap.get(u)){
					if(ur != null) {
						userRoleNameList.add(ur.Name);
					}
				}
			}
			UserSharingRoleWrapperClass userSharingRoleWrapper = new UserSharingRoleWrapperClass();
			userSharingRoleWrapper.userSharingRoleName = userRoleMap.get(u.UserRoleId).Name != null ? userRoleMap.get(u.UserRoleId).Name : '';
			userSharingRoleWrapper.userName = u.Name;
			userSharingRoleWrapper.userSharingRoleList = new List<String>(userRoleNameList);
			userSharingRoleWrapperList.add(userSharingRoleWrapper);
		}
		userRolewrapper.userSharingRoleWrapperList = new List<UserSharingRoleWrapperClass>(userSharingRoleWrapperList);
		return userRolewrapper;
	}
	
	public static List<UserRole> RoleAsigned (User user) {
		List<UserRole> userRoleList = new List<UserRole>();
		Id currentParentRoleId;
		Map<ID, UserRole> userRoleMap = new Map<ID, UserRole>([SELECT Id, Name, DeveloperName, ParentRoleId  FROM UserRole WHERE PortalType = 'None' OR PortalType = 'CustomerPortal' OR PortalType = 'Partner']);
		UserRole currentUserRole = userRoleMap.get(user.UserRoleId);
		system.debug('currentUserRole::' + currentUserRole);
		if (currentUserRole != null) {
			currentParentRoleId = currentUserRole.ParentRoleId;
			system.debug('currentParentRoleId::' + currentParentRoleId);
			while (currentParentRoleId != null) {
				userRoleList.add(userRoleMap.get(currentParentRoleId));
				currentParentRoleId = userRoleMap.get(currentParentRoleId).ParentRoleId;
			}
			system.debug('userRoleList::' + userRoleList);
		}
		return userRoleList;
	}
	
	@AuraEnabled
	public static GroupSharingWrapperClass GroupAsigned (String userIdRemote, String ObjectID) {
      
        system.debug('$$testdebug'+userIdRemote +'ObjectID='+ObjectID);
		GroupSharingWrapperClass groupSharingWrapper = new GroupSharingWrapperClass();
		Map<Id, User> userMap = new Map<Id, User>([SELECT Name, UserRoleId, Profile.Name FROM User WHERE IsActive = true Limit 20000]);
		User user = userMap.get(userIdRemote);
		Map<Id, SObject> shrGroupMap = new Map<Id, SObject>(sharringMap(ObjectID));
		Map<ID, UserRole> userRoleMap = new Map<ID, UserRole>([SELECT Id, Name, DeveloperName, ParentRoleId  FROM UserRole WHERE PortalType = 'None' OR PortalType = 'CustomerPortal' OR PortalType = 'Partner']);
		Boolean isRoleGroupShare = false;
		Boolean isRoleSubordinatesGroupShare = false;
		Boolean isRolePublicGroupShare = false;
		Map<Group, List<UserRole>> roleGroupMap = new Map<Group, List<UserRole>>();
		Map<Group, User> userGroupSharingMap = new Map<Group, User>();
		Map<Group, List<UserRole>> roleGroupSharingMap = new Map<Group, List<UserRole>>();
		if(!Schema.getGlobalDescribe().get('Group').getDescribe().isAccessible()) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'You don\'t have access to Group object');
			ApexPages.addMessage(myMsg);
			return null;
		}
		Map<Id, Group> groupMap = new Map<Id, Group>([SELECT ID, Type, Name, RelatedId, DeveloperName FROM Group WHERE Type != 'Queue']);

		List<GroupMember> groupMemberList;
		system.debug('shrGroupMap::' + shrGroupMap);
		Set<Id> groupIdSet = new Set<Id>();
		groupIdSet.addAll(groupMap.Keyset());
		groupMemberList = [SELECT UserOrGroupId, GroupID FROM GroupMember WHERE GroupID IN :groupIdSet];
		groupIdSet = new Set<Id>();
		Map<Id, Set<ID>> GroupMemberMap = new Map<Id, Set<ID>>();
		Map<Id, Set<ID>> userOrGroupIdMemberMap = new Map<Id, Set<ID>>();
		system.debug('groupMemberList::' + groupMemberList);
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
		Boolean isGroupShr = false;
		system.debug('GroupMemberMap::' + GroupMemberMap);
		system.debug('userOrGroupIdMemberMap::' + userOrGroupIdMemberMap);
		Set<Id> groupSearchIdSet = new Set<Id>();
		for (ID UserOrGroupId : shrGroupMap.KeySet()) {
			system.debug('GroupMemberMap.get(UserOrGroupId)::' + GroupMemberMap.get(UserOrGroupId));
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
		Id currentId = (Id)ObjectId;
		String sObjName = currentId.getSObjectType().getDescribe().getName();
		Map<String, String> sharingCriteriaRuleMap = new Map<String, String>(readSharingRule(currentId,sObjName, userMap, userRoleMap));
		for(Group gr : roleGroupSharingMap.keySet()) {
			if(!sharingCriteriaRuleMap.containsKey(gr.DeveloperName)) {
				sharingCriteriaRuleMap.put(gr.DeveloperName, '');
			}
		}
		system.debug('roleGroupSharingMap:' + roleGroupSharingMap);
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
		system.debug('groupIdSet::' + groupIdSet);
		system.debug('groupSearchIdSet::' + groupSearchIdSet);
		
		List<Group> groupList = new List<Group>();
		if (groupIdSet.size() > 0) {
			for(Id gr : groupMap.keySet()) {
				if(groupIdSet.contains(gr)) {
					groupList.add(groupMap.get(gr));
				}
			}
			system.debug('groupList::' + groupList);
		}
		system.debug('groupMap::' + groupMap);
		Map<Group, List<UserRole>> roleAndSubordinatesGroupMap = new Map<Group, List<UserRole>>();
		for(Id grId : groupMap.keySet()) {
			Group groupItem = groupMap.get(grId);
			if(shrGroupMap.containsKey(grId) && (groupItem.Type == 'Role' || groupItem.Type == 'RoleAndSubordinates')) {
				if(groupItem.RelatedId != null && groupItem.RelatedId == user.UserRoleId) {
					roleGroupMap.put(groupItem, new List<UserRole>());
					isRoleGroupShare = true;
					isGroupShr = true;
				} else {
					system.debug('userRoleMap1::' + groupItem.RelatedId);
					List<User> userList = new List<User>();
					for(Id userId: UserMap.KeySet()) {
						if(UserMap.get(userId).UserRoleId == groupItem.RelatedId) {
							userList.add(UserMap.get(userId));
						}
					}
					system.debug('userList12:::' + userList);
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
					system.debug('userRoleMap2::' + groupMap.get(grId).RelatedId);
					
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
						system.debug('roleAndSubordinatesGroupMap::' + roleGroupMap);
					}
				}
			}
		}
		for (Group gr : roleGroupMap.Keyset()) {
			if(!sharingCriteriaRuleMap.containsKey(gr.DeveloperName)) {
				sharingCriteriaRuleMap.put(gr.DeveloperName, '');
			}
		}
		system.debug('$#$#roleGroupMap::' + roleGroupMap);
		system.debug('groupList;;' + groupList);
		if (groupList.size() > 0) {
			for (Group gr : groupList) {
				system.debug('gr.DeveloperName::;;' + gr.DeveloperName);
				if(!sharingCriteriaRuleMap.containsKey(gr.DeveloperName)) {
					sharingCriteriaRuleMap.put(gr.DeveloperName, '');
				}
			}
			isGroupShr = true;
			Set<Group> groupSet = new Set<Group>(groupList);
			groupList = new List<Group>(groupSet);
		}
		groupSharingWrapper.groupList = new List<Group>(groupList);
		groupSharingWrapper.shrGroupMap = new Map<Id, SObject>(shrGroupMap);
        system.debug('groupSharingWrapper+'+groupSharingWrapper);
		return groupSharingWrapper;
	}
	
    
    
    
  
    
    /*public static MetadataService.MetadataPort createService() { 
        system.debug('TestingProfiles');  
        system.debug('debugg createService');
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        service.timeout_x = 120000;
        return service;
    } */
    public static MetadataService.MetadataPort createService() {
    System.debug('>>> createService invoked');

    MetadataService.MetadataPort service = new MetadataService.MetadataPort();
    service.SessionHeader = new MetadataService.SessionHeader_element();
    service.SessionHeader.sessionId = getSessionIdSafe();
    service.timeout_x = 120000;

    System.debug('>>> SessionId used for MetadataService: ' + service.SessionHeader.sessionId);
    return service;
}
public static String getSessionIdSafe() {
    try {
        Boolean isAsync = (System.isBatch() || System.isFuture() || System.isQueueable() || System.isScheduled());
        Boolean isLightning = UserInfo.getUiThemeDisplayed().contains('Theme4');

        // If Lightning OR async → use VF page hack
        if (isLightning || isAsync) {
            String content = Page.sessionidpage.getContent().toString();
            System.debug('@@@ VF Content: ' + content);

            Integer s = content.indexOf('Start_Of_Session_Id');
            Integer e = content.indexOf('End_Of_Session_Id');

            if (s == -1 || e == -1) {
                System.debug('@@@ FAILED TO EXTRACT SESSION ID');
                return null;
            }

            s += 'Start_Of_Session_Id'.length();
            String sid = content.substring(s, e);

            System.debug('@@@ Extracted Session ID: ' + sid);
            return sid;
        }

        // Otherwise use normal call (Classic only)
        String sidNormal = UserInfo.getSessionId();
        System.debug('@@@ Normal Session ID: ' + sidNormal);
        return sidNormal;

    } catch (Exception ex) {
        System.debug('@@@ ERROR in getSessionIdSafe: ' + ex.getMessage());
        return null;
    }
}

    
    
    /* public static MetadataService.MetadataPort createService() {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
       service.SessionHeader = new MetadataService.SessionHeader_element();
      //service.endpoint_x = 'callout:SA_Audit__Tooling_API_Creds';
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        service.timeout_x = 120000;
        return service;
    }
    
    
   public static String getSessionId() {        
        return Page.UserSessionPage.getContent().toString().trim();
    }
*/    
    
	@AuraEnabled
	public static String readCustomObject(String objName) {
		system.debug('customObjectMetadata::');
		MetadataService.MetadataPort service = createService();
		MetadataService.ReadCustomObjectResult rs = (MetadataService.ReadCustomObjectResult) 
			service.readMetadata('CustomObject', new String[] {objName});
		system.debug('customObjectMetadata::' + rs);
		string customShr;
		for (MetadataService.Metadata md : rs.getRecords()) {
			if (md != null) {
				MetadataService.CustomObject obj = (MetadataService.CustomObject) md;
				customShr = (String)obj.sharingmodel;
				System.debug('Custom object full name: ' + obj.fullName);
				System.debug('Label: ' + obj.label);
				System.debug('Sharing model: ' + obj.sharingmodel);
			} else {
				System.debug('Empty metadata.');
			}
		}
		return customShr;
	}
    
	 
	public static Map<String, String> readSharingRule(ID currentId,String objName, Map<Id, User> userMap, Map<ID, UserRole> userRoleMap){
		 System.debug('currentId: ' + currentId);
    System.debug('objName: ' + objName);
    System.debug('userMap: ' + userMap);
    System.debug('userRoleMap: ' + userRoleMap);

    // Initialize the query string
    String query1;
    sObject sObj;
     
        // Validate that the object name is supported and valid
        if (objName == 'Case') {
            query1 = 'SELECT Id, CaseNumber, OwnerId FROM ' + objName + ' WHERE ID = :currentId';
        } else if (Schema.getGlobalDescribe().containsKey(objName)) {
            query1 = 'SELECT Id, Name, OwnerId FROM ' + objName + ' WHERE ID = :currentId';
        } else {
            throw new IllegalArgumentException('Invalid object name provided: ' + objName);
        }
        
        // Log the final query string for debugging
        System.debug('Query to be executed: ' + query1);
        System.debug('Executing query with currentId value: ' + currentId);

        // Execute the query
        sObj = Database.query(query1);
        System.debug('Query executed successfully. Result: ' + sObj);
    Map<String, String> sharingCriteriaRuleMap = new Map<String, String>();
    
        // Create Metadata Service with valid session
        MetadataService.MetadataPort service = createService();
		transient MetadataService.SharingRules sharingRules = (MetadataService.SharingRules) 
            service.readMetadata('SharingRules',new String[] {'SA_Audit__'+objName}).getRecords()[0];

    system.debug('sharingRules::' + sharingRules);
		String sharingCriteriaRule;
		
		if(sharingRules.sharingCriteriaRules != null) {
			for(MetadataService.SharingCriteriaRule scr: sharingRules.sharingCriteriaRules) {
				
				for(MetadataService.FilterItem crit : scr.criteriaItems){
					sharingCriteriaRule = crit.field + ' ' + crit.operation + ' ' + (crit.value != null ? crit.value : crit.valueField);
					system.debug('sharingCriteriaRule::' + sharingCriteriaRule);
				
					if(scr.sharedTo.group_x != null) {
						for(String groupName : scr.sharedTo.group_x) {
							system.debug('scr.sharedTo::' + groupName);
							sharingCriteriaRuleMap.put(groupName, sharingCriteriaRule);
						}
					}
					if(scr.sharedTo.allCustomerPortalUsers != null) {
						sharingCriteriaRuleMap.put(scr.sharedTo.allCustomerPortalUsers, sharingCriteriaRule);
					}
					if(scr.sharedTo.allInternalUsers != null) {
						sharingCriteriaRuleMap.put(scr.sharedTo.allInternalUsers, sharingCriteriaRule);
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
					system.debug('sharingCriteriaRuleMap1::' + sharingCriteriaRuleMap);
				}
			}
			
			system.debug('sharingCriteriaRuleMap::' + sharingCriteriaRuleMap);
		}
		if(sharingRules.sharingOwnerRules != null) {
			String userRoleDevName = userRoleMap.get(userMap.get((Id)sObj.get('OwnerId')).UserRoleId).DeveloperName;
			String userRoleLabel = userRoleMap.get(userMap.get((Id)sObj.get('OwnerId')).UserRoleId).Name;
			system.debug('userRoleDevName:' + userRoleDevName);
			Set<String> userRoleDevNameSet = new Set<String>();
			List<UserRole> roleAssignedList = new List<UserRole>(RoleAsigned(userMap.get((Id)sObj.get('OwnerId'))));
			for(UserRole ur : roleAssignedList ) {
				userRoleDevNameSet.add(ur.DeveloperName);
			}
			Boolean isFound;
			for(MetadataService.SharingOwnerRule scr: sharingRules.sharingOwnerRules) {
				isFound = false;
				system.debug('scr.sharedFrom::' + scr.sharedFrom);
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
						system.debug('roleAndSubordinates::' + roleAndSubordinates + '  ' + userRoleDevNameSet);
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
				
				system.debug('sharingCriteriaRule11::' + sharingCriteriaRule);
				system.debug('scr.sharedTo::::' + scr.sharedTo.group_x );
				if(isFound) {
					if(scr.sharedTo.group_x != null) {
						for(String groupName : scr.sharedTo.group_x) {
							if(!sharingCriteriaRuleMap.containsKey(groupName)){
								system.debug('groupName::::' + groupName );
								sharingCriteriaRule += groupName;
								sharingCriteriaRuleMap.put(groupName, sharingCriteriaRule);
							}
						}
					}
					system.debug('sharingCriteriaRule12::' + sharingCriteriaRule);
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
				system.debug('sharingCriteriaRuleMap1::' + sharingCriteriaRuleMap);
				
			}
			
			system.debug('sharingCriteriaRuleMap::' + sharingCriteriaRuleMap);
		}
		return sharingCriteriaRuleMap;
	}
	
	public class owdWrapperClass {
		@AuraEnabled public String organizationName { get; set; }
		@AuraEnabled public String defaultAccess { get; set; }
		@AuraEnabled public String fieldOrg { get; set; }
		@AuraEnabled public String errorMSG { get; set; }
	}
	
	public class UserRoleWrapperClass {
		@AuraEnabled public String userRoleName { get; set; }
		@AuraEnabled public List<UserSharingRoleWrapperClass> userSharingRoleWrapperList { get; set; }
		@AuraEnabled public String errorMSG { get; set; }
	}
	
	public class UserSharingRoleWrapperClass {
		@AuraEnabled public String userSharingRoleName { get; set; }
		@AuraEnabled public String userName { get; set; }
		@AuraEnabled public List<String> userSharingRoleList { get; set; }
	}
	
	public class GroupSharingWrapperClass {
		@AuraEnabled public List<Group> groupList{ get; set; } 
		@AuraEnabled public Map<Id, SObject> shrGroupMap { get; set; }
		@AuraEnabled public Map<Group, List<UserRole>> roleGroupSharingMap { get; set; }
		@AuraEnabled public Map<Group, List<UserRole>> roleGroupMap { get; set; }
	}
	
	public class shrGroupWrapperClass {
		@AuraEnabled public Id id { get; set; }
		@AuraEnabled public SObject shrGroup { get; set; }
	}
}