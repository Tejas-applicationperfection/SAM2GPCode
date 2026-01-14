public with sharing class SchemaBuilderController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getSchemaData(String objectName) {
        try {
            Map<String, Object> result = new Map<String, Object>();
            
            if(String.isBlank(objectName)) {
                result.put('objects', getAvailableObjects());
                return result;
            }
            
            // Get the primary object
            Schema.DescribeSObjectResult primaryObj = Schema.describeSObjects(new List<String>{objectName})[0];
            
            List<Map<String, Object>> nodes = new List<Map<String, Object>>();
            List<Map<String, Object>> edges = new List<Map<String, Object>>();
            
            // Add the primary object
            nodes.add(new Map<String, Object>{
                'name' => primaryObj.getName(),
                'label' => primaryObj.getLabel()
            });
            
            // Get fields with references (parent relationships)
            for(Schema.SObjectField field : primaryObj.fields.getMap().values()) {
                Schema.DescribeFieldResult fieldDesc = field.getDescribe();
                
                // Check if this is a reference field
                if(fieldDesc.getType() == Schema.DisplayType.REFERENCE) {
                    List<Schema.SObjectType> referenceTo = fieldDesc.getReferenceTo();
                    
                    for(Schema.SObjectType refObj : referenceTo) {
                        String refObjName = refObj.getDescribe().getName();
                        
                        // Skip certain system objects
                        if(refObjName == 'RecordType' || refObjName == 'User') continue;
                        
                        // Add the referenced object
                        nodes.add(new Map<String, Object>{
                            'name' => refObjName,
                            'label' => refObj.getDescribe().getLabel()
                        });
                        
                        // Add the relationship edge
                        edges.add(new Map<String, Object>{
                            'source' => primaryObj.getName(),
                            'target' => refObjName,
                            'type' => 'Reference'
                        });
                    }
                }
            }
            
            // Get child relationships
            for(Schema.ChildRelationship childRel : primaryObj.getChildRelationships()) {
                if(childRel.getRelationshipName() != null && childRel.getChildSObject() != null) {
                    String childObjName = childRel.getChildSObject().getDescribe().getName();
                    
                    // Skip certain system objects
                    if(childObjName == 'RecordType' || childObjName == 'User') continue;
                    
                    // Add the child object
                    nodes.add(new Map<String, Object>{
                        'name' => childObjName,
                        'label' => childRel.getChildSObject().getDescribe().getLabel()
                    });
                    
                    // Add the relationship edge
                    edges.add(new Map<String, Object>{
                        'source' => childObjName,
                        'target' => primaryObj.getName(),
                        'type' => childRel.isCascadeDelete() ? 'Master-Detail' : 'Lookup'
                    });
                }
            }
            
            result.put('nodes', nodes);
            result.put('edges', edges);
            return result;
        } catch(Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getSchemaDataWithPermissions(String objectName, String userId, Boolean loadRelatedObjects) {
        try {
            Map<String, Object> result = new Map<String, Object>();
            
            if(String.isBlank(objectName)) {
                result.put('objects', getAvailableObjects());
                return result;
            }
            
            // Get only the primary object and its immediate relationships
            List<Map<String, Object>> nodes = new List<Map<String, Object>>();
            List<Map<String, Object>> edges = new List<Map<String, Object>>();
            
            // Add the primary object
            Schema.DescribeSObjectResult primaryObj = Schema.describeSObjects(new List<String>{objectName})[0];
            nodes.add(new Map<String, Object>{
                'name' => primaryObj.getName(),
                'label' => primaryObj.getLabel(),
                'isCustom' => primaryObj.isCustom()
            });
            
            // Only load related objects if requested
            if(loadRelatedObjects) {
                // Get direct relationships only
                addDirectRelationships(primaryObj, nodes, edges);
            }
            
            // Get user's permissions
            Map<String, Map<String, Object>> permissionsMap = getUserObjectPermissions(userId);
            
            // Enhance nodes with permission data
            for(Map<String, Object> node : nodes) {
                String objName = (String)node.get('name');
                
                // Add permission data if available
                if(permissionsMap.containsKey(objName)) {
                    node.put('permissions', permissionsMap.get(objName));
                } else {
                    // Default no access
                    node.put('permissions', new Map<String, Object>{
                        'hasAccess' => false,
                        'read' => false,
                        'create' => false,
                        'edit' => false,
                        'delete' => false,
                        'sources' => new List<Map<String, Object>>()
                    });
                }
            }
            
            result.put('nodes', nodes);
            result.put('edges', edges);
            return result;
        } catch(Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getSchemaDataWithMultipleSecondaryObjects(String primaryObjectName, List<String> secondaryObjectNames, String userId) {
        try {
            Map<String, Object> result = new Map<String, Object>();
            
            if(String.isBlank(primaryObjectName)) {
                result.put('objects', getAllObjects());
                return result;
            }
            
            // Get the primary object and its immediate relationships
            List<Map<String, Object>> nodes = new List<Map<String, Object>>();
            List<Map<String, Object>> edges = new List<Map<String, Object>>();
            
            // Add the primary object
            Schema.DescribeSObjectResult primaryObj = Schema.describeSObjects(new List<String>{primaryObjectName})[0];
            nodes.add(new Map<String, Object>{
                'name' => primaryObj.getName(),
                'label' => primaryObj.getLabel(),
                'isCustom' => primaryObj.isCustom(),
                'isPrimary' => true
            });
            
            // Process each secondary object
            if(secondaryObjectNames != null && !secondaryObjectNames.isEmpty()) {
                Set<String> addedObjects = new Set<String>();
                addedObjects.add(primaryObjectName);
                
                // First, add all secondary objects to the nodes list
                List<Schema.DescribeSObjectResult> secondaryObjs = new List<Schema.DescribeSObjectResult>();
                for(String secondaryObjName : secondaryObjectNames) {
                    if(String.isBlank(secondaryObjName) || addedObjects.contains(secondaryObjName)) {
                        continue;
                    }
                    
                    // Add the secondary object
                    Schema.DescribeSObjectResult secondaryObj = Schema.describeSObjects(new List<String>{secondaryObjName})[0];
                    secondaryObjs.add(secondaryObj);
                    nodes.add(new Map<String, Object>{
                        'name' => secondaryObj.getName(),
                        'label' => secondaryObj.getLabel(),
                        'isCustom' => secondaryObj.isCustom(),
                        'isSecondary' => true
                    });
                    addedObjects.add(secondaryObjName);
                }
                
                // Find relationships between primary and all secondary objects
                for(Schema.DescribeSObjectResult secondaryObj : secondaryObjs) {
                    findDirectRelationships(primaryObj, secondaryObj, nodes, edges, addedObjects);
                }
                
                // Find relationships between all secondary objects
                for(Integer i = 0; i < secondaryObjs.size(); i++) {
                    for(Integer j = i + 1; j < secondaryObjs.size(); j++) {
                        findDirectRelationships(secondaryObjs[i], secondaryObjs[j], nodes, edges, addedObjects);
                    }
                }
            } else {
                // If no secondary objects, just get primary object relationships
                addDirectRelationships(primaryObj, nodes, edges);
            }
            
            // Get user's permissions
            Map<String, Map<String, Object>> permissionsMap = getUserObjectPermissions(userId);
            
            // Enhance nodes with permission data
            for(Map<String, Object> node : nodes) {
                String objName = (String)node.get('name');
                
                // Add permission data if available
                if(permissionsMap.containsKey(objName)) {
                    node.put('permissions', permissionsMap.get(objName));
                } else {
                    // Default no access
                    node.put('permissions', new Map<String, Object>{
                        'hasAccess' => false,
                        'read' => false,
                        'create' => false,
                        'edit' => false,
                        'delete' => false,
                        'sources' => new List<Map<String, Object>>()
                    });
                }
            }
            
            result.put('nodes', nodes);
            result.put('edges', edges);
            return result;
        } catch(Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    private static List<Map<String, Object>> getAvailableObjects() {
        List<Map<String, Object>> objects = new List<Map<String, Object>>();
    
        // Add standard objects
        List<String> standardObjects = new List<String>{
            'Account', 'Contact', 'Opportunity', 'Lead', 'Case'
        };
    
        for(String objName : standardObjects) {
            Schema.DescribeSObjectResult describe = Schema.describeSObjects(new List<String>{objName})[0];
            objects.add(new Map<String, Object>{
                'name' => describe.getName(),
                'label' => describe.getLabel()
            });
        }
    
        // Add custom objects
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for(String objName : globalDescribe.keySet()) {
            Schema.DescribeSObjectResult describe = globalDescribe.get(objName).getDescribe();
            if(describe.isCustom() && !describe.getName().endsWith('__mdt')) {
                objects.add(new Map<String, Object>{
                    'name' => describe.getName(),
                    'label' => describe.getLabel()
                });
            }
        }
    
        return objects;
    }
    
    
    private static Map<String, Map<String, Object>> getUserObjectPermissions(String userId) {
        Map<String, Map<String, Object>> permissionsMap = new Map<String, Map<String, Object>>();
        
        try {
            // Get user's profile
            User u = [SELECT Id, Name, ProfileId, Profile.Name FROM User WHERE Id = :userId LIMIT 1];
            System.debug('Processing permissions for user: ' + u.Name + ', Profile: ' + u.Profile.Name);
            
            // Get object permissions from profile
            List<ObjectPermissions> profilePerms = [
                SELECT SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete
                FROM ObjectPermissions 
                WHERE ParentId = :u.ProfileId
            ];
            System.debug('Found ' + profilePerms.size() + ' object permissions from profile');
            
            // Get permission sets assigned to user
            List<PermissionSetAssignment> psetAssignments = [
                SELECT PermissionSetId, PermissionSet.Name 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :userId
            ];
            System.debug('Found ' + psetAssignments.size() + ' permission set assignments for user');
            
            Set<Id> permSetIds = new Set<Id>();
            Map<Id, String> permSetNames = new Map<Id, String>();
            for(PermissionSetAssignment psa : psetAssignments) {
                permSetIds.add(psa.PermissionSetId);
                permSetNames.put(psa.PermissionSetId, psa.PermissionSet.Name);
                System.debug('Permission Set: ' + psa.PermissionSet.Name + ' (' + psa.PermissionSetId + ')');
            }
            
            // Store all object names that have any permissions
            Set<String> allObjectsWithPermissions = new Set<String>();
            
            // Get object permissions from permission sets
            List<ObjectPermissions> permSetPerms = new List<ObjectPermissions>();
            Map<Id, List<String>> permSetToObjects = new Map<Id, List<String>>();
            Map<String, Map<Id, ObjectPermissions>> objectToPermSetPerms = new Map<String, Map<Id, ObjectPermissions>>();
            
            if(!permSetIds.isEmpty()) {
                permSetPerms = [
                    SELECT SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, ParentId
                    FROM ObjectPermissions 
                    WHERE ParentId IN :permSetIds
                ];
                System.debug('Found ' + permSetPerms.size() + ' object permissions from permission sets');
                
                // Organize permissions by object and permission set ID
                for(ObjectPermissions op : permSetPerms) {
                    String objName = op.SobjectType;
                    allObjectsWithPermissions.add(objName);
                    
                    if(!objectToPermSetPerms.containsKey(objName)) {
                        objectToPermSetPerms.put(objName, new Map<Id, ObjectPermissions>());
                    }
                    objectToPermSetPerms.get(objName).put(op.ParentId, op);
                    
                    if(!permSetToObjects.containsKey(op.ParentId)) {
                        permSetToObjects.put(op.ParentId, new List<String>());
                    }
                    permSetToObjects.get(op.ParentId).add(op.SobjectType);
                }
                
                // Log counts
                for(Id permSetId : permSetIds) {
                    String permSetName = permSetNames.get(permSetId);
                    Integer objCount = permSetToObjects.containsKey(permSetId) ? 
                                    permSetToObjects.get(permSetId).size() : 0;
                    System.debug('Permission Set: ' + permSetName + ' has ' + objCount + ' object permissions');
                    
                    if(objCount > 0) {
                        List<String> objects = permSetToObjects.get(permSetId);
                        String objectSample = '';
                        for(Integer i = 0; i < Math.min(5, objects.size()); i++) {
                            objectSample += (objectSample.length() > 0 ? ', ' : '') + objects[i];
                        }
                        System.debug('First 5 objects for ' + permSetName + ': ' + objectSample);
                    }
                }
            }
            
            // Process profile permissions
            for(ObjectPermissions op : profilePerms) {
                String objName = op.SobjectType;
                allObjectsWithPermissions.add(objName);
                
                Boolean hasAnyAccess = op.PermissionsRead || op.PermissionsCreate || op.PermissionsEdit || op.PermissionsDelete;
                
                Map<String, Object> permData = new Map<String, Object>{
                    'hasAccess' => hasAnyAccess,
                    'read' => op.PermissionsRead,
                    'create' => op.PermissionsCreate,
                    'edit' => op.PermissionsEdit,
                    'delete' => op.PermissionsDelete,
                    'sources' => new List<Map<String, Object>>{
                        new Map<String, Object>{
                            'type' => 'Profile',
                            'name' => u.Profile.Name,
                            'read' => op.PermissionsRead,
                            'create' => op.PermissionsCreate,
                            'edit' => op.PermissionsEdit,
                            'delete' => op.PermissionsDelete
                        }
                    }
                };
                permissionsMap.put(objName, permData);
                System.debug('Added profile permissions for object: ' + objName);
            }
            
            // Now process all objects that have any permissions
            for(String objName : allObjectsWithPermissions) {
                Boolean hasAnyPermission = false;
                Boolean hasRead = false, hasCreate = false, hasEdit = false, hasDelete = false;
                
                // Initialize if not already there
                if(!permissionsMap.containsKey(objName)) {
                    permissionsMap.put(objName, new Map<String, Object>{
                        'hasAccess' => false,
                        'read' => false,
                        'create' => false,
                        'edit' => false,
                        'delete' => false,
                        'sources' => new List<Map<String, Object>>()
                    });
                }
                
                Map<String, Object> permData = permissionsMap.get(objName);
                List<Map<String, Object>> sources = (List<Map<String, Object>>)permData.get('sources');
                
                // Update permission flags based on profile permissions
                hasRead = (Boolean)permData.get('read');
                hasCreate = (Boolean)permData.get('create');
                hasEdit = (Boolean)permData.get('edit');
                hasDelete = (Boolean)permData.get('delete');
                
                // Add permission sources from permission sets
                if(objectToPermSetPerms.containsKey(objName)) {
                    Map<Id, ObjectPermissions> permsBySet = objectToPermSetPerms.get(objName);
                    
                    // Add sources for each permission set
                    for(Id permSetId : permSetIds) {
                        String permSetName = permSetNames.get(permSetId);
                        
                        if(permsBySet.containsKey(permSetId)) {
                            ObjectPermissions op = permsBySet.get(permSetId);
                            Boolean psRead = op.PermissionsRead;
                            Boolean psCreate = op.PermissionsCreate;
                            Boolean psEdit = op.PermissionsEdit;
                            Boolean psDelete = op.PermissionsDelete;
                            
                            // Add permission source with correct values
                            sources.add(new Map<String, Object>{
                                'type' => 'Permission Set',
                                'name' => permSetName,
                                'read' => psRead,
                                'create' => psCreate,
                                'edit' => psEdit,
                                'delete' => psDelete
                            });
                            
                            // Update aggregate permissions
                            hasRead = hasRead || psRead;
                            hasCreate = hasCreate || psCreate;
                            hasEdit = hasEdit || psEdit;
                            hasDelete = hasDelete || psDelete;
                            
                            System.debug('Added accurate permission source for ' + permSetName + ' on ' + objName + 
                                        ' - Read: ' + psRead + ', Create: ' + psCreate + 
                                        ', Edit: ' + psEdit + ', Delete: ' + psDelete);
                        } 
                        // For permission sets that don't have permissions for this object
                        // We'll add them with explicit "false" values to ensure they show up in the UI
                        else if (permissionsMap.containsKey(objName)) {
                            // Only add no-access sources if we're already tracking this object
                            // and if the overall object has access (no need to show permission sets without access for objects the user can't access at all)
                            Boolean objHasAccess = (Boolean)permData.get('hasAccess');
                            if (objHasAccess) {
                                sources.add(new Map<String, Object>{
                                    'type' => 'Permission Set',
                                    'name' => permSetName,
                                    'read' => false,
                                    'create' => false,
                                    'edit' => false,
                                    'delete' => false
                                });
                                System.debug('Added no-access permission source for ' + permSetName + ' on ' + objName);
                            }
                        }
                    }
                }
                // For objects that the user has access to, but none of the permission sets grant access explicitly
                // Add all permission sets with explicit "false" values
                else if ((Boolean)permData.get('hasAccess')) {
                    for(Id permSetId : permSetIds) {
                        String permSetName = permSetNames.get(permSetId);
                        sources.add(new Map<String, Object>{
                            'type' => 'Permission Set',
                            'name' => permSetName,
                            'read' => false,
                            'create' => false,
                            'edit' => false,
                            'delete' => false
                        });
                    }
                }
                
                // Update the aggregate permissions
                hasAnyPermission = hasRead || hasCreate || hasEdit || hasDelete;
                permData.put('hasAccess', hasAnyPermission);
                permData.put('read', hasRead);
                permData.put('create', hasCreate);
                permData.put('edit', hasEdit);
                permData.put('delete', hasDelete);
            }
            
            // Debug final permissions map
            System.debug('Final permissions map contains ' + permissionsMap.size() + ' objects');
            for(String objName : permissionsMap.keySet()) {
                Map<String, Object> permData = permissionsMap.get(objName);
                List<Map<String, Object>> sources = (List<Map<String, Object>>)permData.get('sources');
                System.debug('Object: ' + objName + ' has ' + sources.size() + ' permission sources');
                
                // Log aggregate permissions
                System.debug('Aggregate permissions for ' + objName + ': Read=' + permData.get('read') + 
                          ', Create=' + permData.get('create') + ', Edit=' + permData.get('edit') + 
                          ', Delete=' + permData.get('delete'));
            }
        } catch(Exception e) {
            System.debug('Error getting user permissions: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        return permissionsMap;
    }
    
    // Helper method to add only direct relationships
    private static void addDirectRelationships(Schema.DescribeSObjectResult objDesc, List<Map<String, Object>> nodes, List<Map<String, Object>> edges) {
        Set<String> addedObjects = new Set<String>();
        addedObjects.add(objDesc.getName());
        
        // Add parent relationships (lookup fields)
        for(Schema.SObjectField field : objDesc.fields.getMap().values()) {
                    Schema.DescribeFieldResult fieldDesc = field.getDescribe();
            
            if(fieldDesc.getType() == Schema.DisplayType.REFERENCE) {
                for(Schema.SObjectType refObj : fieldDesc.getReferenceTo()) {
                    String refObjName = refObj.getDescribe().getName();
                    
                    // Skip system objects and already added objects
                    if(refObjName == 'RecordType' || refObjName == 'User' || addedObjects.contains(refObjName)) {
                        continue;
                    }
                    
                    // Add the referenced object
                    nodes.add(new Map<String, Object>{
                        'name' => refObjName,
                        'label' => refObj.getDescribe().getLabel(),
                        'isCustom' => refObj.getDescribe().isCustom()
                    });
                    addedObjects.add(refObjName);
                    
                    // Create a list of relationship fields
                    List<Map<String, Object>> relationshipFields = new List<Map<String, Object>>();
                    relationshipFields.add(new Map<String, Object>{
                        'name' => fieldDesc.getName(),
                        'label' => fieldDesc.getLabel(),
                        'type' => String.valueOf(fieldDesc.getType())
                    });
                    
                    // Add the relationship edge with fields
                    edges.add(new Map<String, Object>{
                        'source' => objDesc.getName(),
                        'target' => refObjName,
                        'relationshipType' => 'Lookup',
                        'relationshipName' => fieldDesc.getLabel(),
                        'fields' => relationshipFields,
                        'label' => fieldDesc.getLabel()
                    });
                }
            }
        }
        
        // Add child relationships
        for(Schema.ChildRelationship childRel : objDesc.getChildRelationships()) {
            if(childRel.getRelationshipName() != null && childRel.getChildSObject() != null) {
                String childObjName = childRel.getChildSObject().getDescribe().getName();
                
                // Skip system objects and already added objects
                if(childObjName == 'RecordType' || childObjName == 'User' || addedObjects.contains(childObjName)) {
                    continue;
                }
                
                // Add the child object
                nodes.add(new Map<String, Object>{
                    'name' => childObjName,
                    'label' => childRel.getChildSObject().getDescribe().getLabel(),
                    'isCustom' => childRel.getChildSObject().getDescribe().isCustom()
                });
                addedObjects.add(childObjName);
                
                // Get the field that creates this relationship
                Schema.DescribeFieldResult fieldDesc = childRel.getField().getDescribe();
                
                // Create a list of relationship fields
                List<Map<String, Object>> relationshipFields = new List<Map<String, Object>>();
                relationshipFields.add(new Map<String, Object>{
                    'name' => fieldDesc.getName(),
                    'label' => fieldDesc.getLabel(),
                    'type' => String.valueOf(fieldDesc.getType())
                });
                
                // Find any other fields that reference the same object
                for(Schema.SObjectField field : childRel.getChildSObject().getDescribe().fields.getMap().values()) {
                    Schema.DescribeFieldResult otherFieldDesc = field.getDescribe();
                    
                    if(otherFieldDesc.getType() == Schema.DisplayType.REFERENCE && 
                       otherFieldDesc.getName() != fieldDesc.getName()) {
                        
                        for(Schema.SObjectType refObj : otherFieldDesc.getReferenceTo()) {
                            if(refObj.getDescribe().getName() == objDesc.getName()) {
                                relationshipFields.add(new Map<String, Object>{
                                    'name' => otherFieldDesc.getName(),
                                    'label' => otherFieldDesc.getLabel(),
                                    'type' => String.valueOf(otherFieldDesc.getType())
                                });
                            }
                        }
                    }
                }
                
                // Add the relationship edge with fields
                edges.add(new Map<String, Object>{
                    'source' => childObjName,
                    'target' => objDesc.getName(),
                    'relationshipType' => childRel.isCascadeDelete() ? 'Master-Detail' : 'Lookup',
                    'relationshipName' => childRel.getRelationshipName(),
                    'fields' => relationshipFields,
                    'label' => fieldDesc.getLabel()
                });
            }
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAllObjects() {
        List<Map<String, Object>> objects = new List<Map<String, Object>>();
        
        try {
            // Query EntityDefinition for object metadata
            List<EntityDefinition> entities = [
                SELECT QualifiedApiName, DeveloperName, MasterLabel, Label, PluralLabel, 
                       NamespacePrefix, IsCustomizable, IsCustomSetting, IsQueryable
                FROM EntityDefinition
                WHERE IsQueryable = true
                AND IsCustomSetting = false
                AND (NOT QualifiedApiName LIKE '%__mdt')
                AND (NOT Label LIKE '%: %')
                AND IsCustomizable = true
                ORDER BY Label
                LIMIT 2000
            ];
            
            // Convert to the expected format
            for(EntityDefinition entity : entities) {
                // Determine if this is a custom object
                Boolean isCustom = entity.QualifiedApiName.endsWith('__c');
                
                objects.add(new Map<String, Object>{
                    'name' => entity.QualifiedApiName,
                    'label' => entity.Label,
                    'isCustom' => isCustom
                });
            }
            
            return objects;
        } catch(Exception e) {
            System.debug('Error getting objects: ' + e.getMessage());
            return new List<Map<String, Object>>();
        }
    }
    
    // Helper method to find direct relationships between two specific objects
    private static void findDirectRelationships(
        Schema.DescribeSObjectResult objA, 
        Schema.DescribeSObjectResult objB, 
        List<Map<String, Object>> nodes, 
        List<Map<String, Object>> edges,
        Set<String> addedObjects
    ) {
        String objAName = objA.getName();
        String objBName = objB.getName();
        
        // Check for relationships from A to B
        List<Map<String, Object>> aToBrefs = new List<Map<String, Object>>();
        
        for(Schema.SObjectField field : objA.fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDesc = field.getDescribe();
            
            if(fieldDesc.getType() == Schema.DisplayType.REFERENCE) {
                for(Schema.SObjectType refObj : fieldDesc.getReferenceTo()) {
                    String refObjName = refObj.getDescribe().getName();
                    
                    if(refObjName == objBName) {
                        // Add this field to the relationship fields list
                        aToBrefs.add(new Map<String, Object>{
                            'name' => fieldDesc.getName(),
                            'label' => fieldDesc.getLabel(),
                            'type' => String.valueOf(fieldDesc.getType())
                        });
                    }
                }
            }
        }
        
        // If we found any relationships from A to B, add an edge
        if(!aToBrefs.isEmpty()) {
            edges.add(new Map<String, Object>{
                'source' => objAName,
                'target' => objBName,
                'relationshipType' => 'Lookup',
                'relationshipName' => aToBrefs[0].get('label') + (aToBrefs.size() > 1 ? ' +' + (aToBrefs.size()-1) + ' more' : ''),
                'fields' => aToBrefs,
                'label' => aToBrefs[0].get('label') + (aToBrefs.size() > 1 ? ' +' + (aToBrefs.size()-1) + ' more' : '')
            });
        }
        
        // Check for relationships from B to A
        List<Map<String, Object>> bToArefs = new List<Map<String, Object>>();
        
        for(Schema.SObjectField field : objB.fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDesc = field.getDescribe();
            
            if(fieldDesc.getType() == Schema.DisplayType.REFERENCE) {
                for(Schema.SObjectType refObj : fieldDesc.getReferenceTo()) {
                    String refObjName = refObj.getDescribe().getName();
                    
                    if(refObjName == objAName) {
                        // Add this field to the relationship fields list
                        bToArefs.add(new Map<String, Object>{
                            'name' => fieldDesc.getName(),
                            'label' => fieldDesc.getLabel(),
                            'type' => String.valueOf(fieldDesc.getType())
                        });
                    }
                }
            }
        }
        
        // If we found any relationships from B to A, add an edge
        if(!bToArefs.isEmpty()) {
            edges.add(new Map<String, Object>{
                'source' => objBName,
                'target' => objAName,
                'relationshipType' => 'Lookup',
                'relationshipName' => bToArefs[0].get('label') + (bToArefs.size() > 1 ? ' +' + (bToArefs.size()-1) + ' more' : ''),
                'fields' => bToArefs,
                'label' => bToArefs[0].get('label') + (bToArefs.size() > 1 ? ' +' + (bToArefs.size()-1) + ' more' : '')
            });
        }
        
        // Check for child relationships from A to B
        for(Schema.ChildRelationship childRel : objA.getChildRelationships()) {
            if(childRel.getRelationshipName() != null && 
               childRel.getChildSObject() != null &&
               childRel.getChildSObject().getDescribe().getName() == objBName) {
                
                Schema.DescribeFieldResult fieldDesc = childRel.getField().getDescribe();
                
                // Create a list of relationship fields
                List<Map<String, Object>> relationshipFields = new List<Map<String, Object>>();
                relationshipFields.add(new Map<String, Object>{
                    'name' => fieldDesc.getName(),
                    'label' => fieldDesc.getLabel(),
                    'type' => String.valueOf(fieldDesc.getType())
                });
                
                edges.add(new Map<String, Object>{
                    'source' => objBName,
                    'target' => objAName,
                    'relationshipType' => childRel.isCascadeDelete() ? 'Master-Detail' : 'Lookup',
                    'relationshipName' => childRel.getRelationshipName(),
                    'fields' => relationshipFields,
                    'label' => fieldDesc.getLabel()
                });
            }
        }
        
        // Check for child relationships from B to A
        for(Schema.ChildRelationship childRel : objB.getChildRelationships()) {
            if(childRel.getRelationshipName() != null && 
               childRel.getChildSObject() != null &&
               childRel.getChildSObject().getDescribe().getName() == objAName) {
                
                Schema.DescribeFieldResult fieldDesc = childRel.getField().getDescribe();
                
                // Create a list of relationship fields
                List<Map<String, Object>> relationshipFields = new List<Map<String, Object>>();
                relationshipFields.add(new Map<String, Object>{
                    'name' => fieldDesc.getName(),
                    'label' => fieldDesc.getLabel(),
                    'type' => String.valueOf(fieldDesc.getType())
                });
                
                edges.add(new Map<String, Object>{
                    'source' => objAName,
                    'target' => objBName,
                    'relationshipType' => childRel.isCascadeDelete() ? 'Master-Detail' : 'Lookup',
                    'relationshipName' => childRel.getRelationshipName(),
                    'fields' => relationshipFields,
                    'label' => fieldDesc.getLabel()
                });
            }
        }
    }
    
    // Helper method to check if an object has a reference to another object
    private static Boolean hasReferenceToObject(Schema.DescribeSObjectResult objDesc, String targetObjName) {
        // Check reference fields
        for(Schema.SObjectField field : objDesc.fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDesc = field.getDescribe();
            
            if(fieldDesc.getType() == Schema.DisplayType.REFERENCE) {
                for(Schema.SObjectType refObj : fieldDesc.getReferenceTo()) {
                    if(refObj.getDescribe().getName() == targetObjName) {
                        return true;
                    }
                }
            }
        }
        
        // Check child relationships
        for(Schema.ChildRelationship childRel : objDesc.getChildRelationships()) {
            if(childRel.getRelationshipName() != null && 
               childRel.getChildSObject() != null &&
               childRel.getChildSObject().getDescribe().getName() == targetObjName) {
                return true;
            }
        }
        
        return false;
    }

    // Helper class for sorting
    private class ObjectWrapper implements Comparable {
        public Map<String, Object> objData;
        
        public ObjectWrapper(Map<String, Object> objData) {
            this.objData = objData;
        }
        
        public Integer compareTo(Object compareTo) {
            ObjectWrapper compareToObj = (ObjectWrapper)compareTo;
            String thisLabel = (String)this.objData.get('label');
            String otherLabel = (String)compareToObj.objData.get('label');
            
            return thisLabel.compareTo(otherLabel);
        }
    }
}