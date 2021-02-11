/**
 * @description Gestiona las diversas funcionalidades al realizar un login en la plataforma por medio de un tercero.
 *              Para este caso de uso, el IAM a tratar es OpenID Connect, el cual proporcionará una respuesta con la confirmación del
 *              login de cada usuario a Salesforce que posteriormente ejecutará lo métodos de esta clase.
 * @date 03/06/2020
 * @author rpolvera@nts-solutions.com
 * @See ./authprovider/
 */
global class OpenIDConnectRegHandler implements Auth.RegistrationHandler
{
    private static final string USERNAME_SERVER = '@zurich-es.com';
    private static final string EMAIL_ENCODING = 'UTF-8';
    private static final string TIMEZONE = 'Europe/Paris';
    private static final string LANGUAGE_SPANISH = 'es';
    private static final Boolean SERVICE_CLOUD_USER = true;
    // Text to be used in the field AuthMapping__mdt.Permission__c to reference Aministrator profile
    @testvisible
    private static final string PROFILE_ADMIN = 'SystemAdmin';

    // Reference to the picklist field AuthMapping__mdt.Permission_Type__c
    @testvisible
    private static final string PERMISSION_TYPE_PROFILE = 'Profile';
    @testvisible
    private static final string PERMISSION_TYPE_PUBLIC_GROUP = 'PublicGroup';
    @testvisible
    private static final string PERMISSION_TYPE_PERMISSION_SET_GROUP = 'PermissionSetGroup';
    @testvisible
    private static final string PERMISSION_TYPE_CALL_CENTER = 'CallCenter';
    @testvisible
    private static final string PERMISSION_TYPE_ROLE = 'Role';

    @testvisible
    private static final string AUTH_DATA_MAP_NAME = 'roles';
    private static final string CLASS_NAME = 'OpenIDConnectRegHandler';

    private static final string ERROR_PARSE_ROLES = 'Error al parsear el usuario. Para más ayuda, póngase en contacto con su administrador.';
    private static final string ERROR_NO_PROFILE = 'No PROFILE found in the configuration for the given list of rols: ';

    // nts (agonzalezisasi) - 17/12/2020 - Include OCS Roles and correct System Admin for languages
    @testvisible
    private static final List<String> SYS_ADMIN_TRANSLATIONS = new List<String> {
        'System Administrator',
        'Administrador del sistema',
        'Systemadministrator',
        'Administrateur système',
        'Administrador do sistema',
        'システム管理者',
        'Amministratore del sistema'
    };

    @testvisible
    private List<AuthMapping__mdt> testListAuthMappings;

    /**
     * @Description Método ejecutado cuando el id de federación del usuario que intenta conectar no se corresponde con el de Salesforce.
     * @date 03/06/2020
     * @author rpolvera
     * @param {Id} portalId - Id de federación de usuario.
     * @param {Auth.UserData} data - Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl, attributeMap)
     * @return {User} Objeto de Salesforce que se corresponde con el usuario.
     */
    global User createUser(Id portalId, Auth.UserData data)
    {

        //System.debug('**** CREATE USER');
        // System.debug('**** CREATE USER, PORTAL ID: ' + portalId);
        // System.debug('**** CREATE USER, data: ' + data);

        // CHECK USER
        User u                        = checkUser(data);
        // Si un usuario con el mismo correo ya existe en el sistema, se actualiza y se retorna.
        if (u != null)
        {
            updateUser(u.Id, portalId, data);
            return u;
        }
        
        // GET ROLS: De lo contrario se instancia un nuevo usuario
        List<String> roleNameList     = getExternalRoleNames(data);

        // GET AUTH DATA
        Map<string, List<string>> mapAuthData = new Map<string, List<string>>();
        mapAuthData.put(PERMISSION_TYPE_PROFILE, null);
        mapAuthData.put(PERMISSION_TYPE_PUBLIC_GROUP, null);
        mapAuthData.put(PERMISSION_TYPE_PERMISSION_SET_GROUP, null);
        mapAuthData.put(PERMISSION_TYPE_CALL_CENTER, null);
        mapAuthData.put(PERMISSION_TYPE_ROLE, null);
        // fill the map with the configuration
        getAuthData( roleNameList, mapAuthData );

        // GET PROFILE ID
        Id profileId                  = getProfileIdFromRoles(mapAuthData.get(PERMISSION_TYPE_PROFILE), roleNameList);

        // Get ROLE ID
        Id roleId                     = getRoleIdFromRoles(mapAuthData.get(PERMISSION_TYPE_ROLE));

        // GET CALL CENTER ID
        Id callcenterId               = getCallCenterFromRoles(mapAuthData.get(PERMISSION_TYPE_CALL_CENTER));

        // NEW USER
        u                             = new User();
        u.firstName                   = data.firstName;
        u.lastName                    = data.lastName;
        u.email                       = data.email;
        u.username                    = data.username + USERNAME_SERVER;
        u.profileId                   = profileId;
        u.alias                       = data.username.left(8);
        u.CommunityNickname           = data.username;
        u.languagelocalekey           = LANGUAGE_SPANISH; //UserInfo.getLanguage();
        u.UserPermissionsSupportUser  = SERVICE_CLOUD_USER;
        u.localesidkey                = UserInfo.getLocale();
        u.emailEncodingKey            = EMAIL_ENCODING;
        u.timeZoneSidKey              = TIMEZONE;        
        if( roleId != null )
            u.UserRoleId              = roleId;
        if( callcenterId != null )
            u.CallCenterId            = callcenterId;

        insert u;

        // GROUPS
        // Obtener los ids de los grupos públicos en salesforce
        List<Id> publicGroupIdList = getPublicGroupsFromRoles(mapAuthData.get(PERMISSION_TYPE_PUBLIC_GROUP));
        // Actualizar de forma asincrona la asignación a grupos
        assignPublicGroups(u.Id, publicGroupIdList);

        // PERMISSION SETS
        List<Id> permissionSetGroupIdList = getPermissionSetGroupsFromRoles(mapAuthData.get(PERMISSION_TYPE_PERMISSION_SET_GROUP));
        assignPermissionSetGroup(u.Id, permissionSetGroupIdList);

        return u;
    }

    /**
     * @Description Método ejecutado cuando el id de federación del usuario que intenta conectar ya existe en Salesforce.
     * @date 03/06/2020
     * @author rpolvera
     * @param {Id} userId - Id de usuario de Salesforce.
     * @param {Id} portalId - Id de federación de usuario.
     * @param {Auth.UserData} data - Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl, attributeMap)
     */
    global void updateUser(Id userId, Id portalId, Auth.UserData data)
    {
        // System.debug('**** UPDATE USER');
        // System.debug('**** UPDATE USER, PORTAL ID: ' + portalId);
        // System.debug('**** UPDATE USER, data: ' + data);
        // System.debug('**** UPDATE USER ID: ' + userId);

        Boolean modified             = false;

        // GET ROLS: Obtener los roles del json
        List<String> roleNameList    = getExternalRoleNames(data);

        // GET AUTH DATA
        Map<string, List<string>> mapAuthData = new Map<string, List<string>>();
        mapAuthData.put(PERMISSION_TYPE_PROFILE, null);
        mapAuthData.put(PERMISSION_TYPE_PUBLIC_GROUP, null);
        mapAuthData.put(PERMISSION_TYPE_PERMISSION_SET_GROUP, null);
        mapAuthData.put(PERMISSION_TYPE_CALL_CENTER, null);
        mapAuthData.put(PERMISSION_TYPE_ROLE, null);
        getAuthData( roleNameList, mapAuthData );

        // Get PROFILE ID
        Id profileId                  = getProfileIdFromRoles(mapAuthData.get(PERMISSION_TYPE_PROFILE), roleNameList);

        // Get ROLE ID
        Id roleId                     = getRoleIdFromRoles(mapAuthData.get(PERMISSION_TYPE_ROLE));

        // GET CALL CENTER ID
        Id callcenterId               = getCallCenterFromRoles(mapAuthData.get(PERMISSION_TYPE_CALL_CENTER));

        // UPDATE USER
        User u = [
            SELECT Id, firstName, lastName, email, userName, profileId, alias, CommunityNickname, CallCenterId, UserRoleId
            FROM User WHERE Id =: userId LIMIT 1
        ];

        // Se comprueban los valores, se determina si ha habido cambios
        modified = (u.firstName != data.firstName || u.lastName != data.lastName || 
                    u.userName != data.username + USERNAME_SERVER || u.profileId != profileId || u.CallCenterId != callcenterId ||
                    u.UserRoleId != roleId || u.alias != data.username.left(8) || u.email != data.email);

        if (modified)
        {
            u.firstName             = data.firstName;
            u.lastName              = data.lastName;
            if (u.email != data.email) 
                u.email             = data.email;
            if (u.userName != data.username + USERNAME_SERVER) 
                u.userName          = data.username + USERNAME_SERVER;
            u.profileId             = profileId;
            u.alias                 = data.username.left(8);
            u.CommunityNickname     = data.username;
            if( u.UserRoleId != roleId )
                u.UserRoleId        = roleId;
            if( u.CallCenterId != callcenterId )
                u.CallCenterId      = callcenterId;

            update(u);
        }

        // UPDATE GROUPS
        // Obtener los ids de los grupos públicos en salesforce
        List<Id> publicGroupIdList = getPublicGroupsFromRoles(mapAuthData.get(PERMISSION_TYPE_PUBLIC_GROUP));
        // Actualizar de forma asincrona la asignación a grupos
        assignPublicGroups( u.Id, publicGroupIdList );
        
        // PERMISSION SETS
        List<Id> permissionSetGroupIdList = getPermissionSetGroupsFromRoles(mapAuthData.get(PERMISSION_TYPE_PERMISSION_SET_GROUP));
        assignPermissionSetGroup(u.Id, permissionSetGroupIdList);
    }

    /**
     * @Description Comprueba si el usuario introducido existe, es posible que al usar dos o mas proveedores de identidad, el mismo
     *              Ususario pueda acceder desde varios sitios. El método comprueba por email la existencia del usuario y lo devuelve.
     * @date 06/06/2020
     * @author rpolvera
     * @param {Auth.UserData} data - Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl,
     *                               attributeMap)
     * @return {User} si existe usuario lo devuelve.
     */
    private User checkUser(Auth.UserData data)
    {
        // System.debug('**** CHECK USER , USER EMAIL: ' + data.email);

        User result = null;
        
        List<User> users = [
            SELECT Id, firstName, lastName, email, userName, profileId, alias, CommunityNickname 
            FROM User WHERE email = :data.email 
            LIMIT 1
        ];
        if( !users.isEmpty() )
            result = users[0];
        
        return result;
    }

    /**
     * @Description Recupera la lista de roles externos para esta sesión.
     * @date 01/10/2020
     * @author eetxaniz
     * @param {Auth.UserData} data - Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl,
     *                               attributeMap)
     * @return {List<String>} Nombre de los roles recuperados
     */
    private List<String> getExternalRoleNames(Auth.UserData data)
    {
        try
        {
            // System.debug('**** GET EXTERNAL ROLE NAMES, DATA: ' + data);

            // Recuperación de los roles del usuario recibidos desde el IAM            
            //'{crm=[rol_name1, rol_name2, rol_name3]}'
            return data.attributeMap.get(AUTH_DATA_MAP_NAME).remove('{')
                   .remove('}')
                   .remove('[')
                   .remove(']')
                   .split('=')[1]
                   .remove(' ')
                   .split(',');

        }
        catch (Exception e)
        {
            throw new RegHandlerException(ERROR_PARSE_ROLES);
        }
    }

    /**
     * Get all the auth data for the given list of roles.
     * Auth data: profile, sf roles, groups, permission set groups, call centers
     * 
     * @author nts (agonzalezisasi)
     * @date 29/01/2021
     * @param {List<string> roles} A list of roles
     * @param {Map<string, List<string>> mapResult} Map of aud
     */
    private void getAuthData(List<string> roles, Map<string, List<string>> mapResult)
    {
        if( mapResult != null ) {
            // Get the list of Auth Mapping Data fro the given roles
            List<AuthMapping__mdt> authConfig = [
                SELECT Permission_Type__c, Permission__c, Order__c FROM AuthMapping__mdt 
                WHERE Role_Name__c IN :roles
                ORDER BY Order__c
            ];

            // if is a test, mock the result
            if( Test.isRunningTest() ) {
                if( testListAuthMappings != null ) {
                    authConfig.addAll(testListAuthMappings);
                }
            }

            // Convert all the data into a map
            if( !authConfig.isEmpty() ) {
                for(Integer i=0,j=authConfig.size(); i<j; i++) {
                    if( mapResult.containsKey(authConfig[i].Permission_Type__c) ) {
                        if( mapResult.get(authConfig[i].Permission_Type__c) == null ) {
                            mapResult.put(authConfig[i].Permission_Type__c, new List<String>{authConfig[i].Permission__c});
                        } else {
                            mapResult.get(authConfig[i].Permission_Type__c).add(authConfig[i].Permission__c);
                        }
                    }
                }
            }
        }
    }

    /**
     * Get the profile Id of the most important profile from the list of profiles configured for the given list of roles.
     * 
     * @author nts (agonzalezisasi)
     * @date 25/12/2021
     * @param {List<String> profileNames} A list of profile names
     * @param {List<string> roles} The list of roles to include in the exception
     * @return {Id}: The id of the profile
     */
    @testvisible
    private Id getProfileIdFromRoles(List<String> profileNames, List<string> roles ) 
    {
        Id result = null;

        if( profileNames != null && !profileNames.isEmpty() ) {
            // Get the profile Id from the Name
            List<Profile> profiles = null;
            if( profileNames.contains(PROFILE_ADMIN) ) {
                profiles = [SELECT Id FROM Profile WHERE Name IN :OpenIDConnectRegHandler.SYS_ADMIN_TRANSLATIONS LIMIT 1];
            } else {
                // if there is no admin, because of the order in the query, the first one should be the best one
                string profileName = profileNames[0];

                profiles = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
            }
            if( profiles != null && !profiles.isEmpty() ) {
                result = profiles[0].Id;
            }
        }

        if( result == null ) {
            throw new RegHandlerException(ERROR_NO_PROFILE + String.join(roles, ', '));
        }
        return result;
    }

    /**
     * Get the role Id configured for the given list of roles.
     * 
     * @author nts (agonzalezisasi)
     * @date 02/02/2021
     * @param {List<String> roleNames} A list of rol names
     * @return {Id}: The id of the role
     */
    private Id getRoleIdFromRoles(List<String> roleNames ) 
    {
        Id result = null;

        if( roleNames != null && !roleNames.isEmpty() ) {
            // because of the order in the query, the first one should be the best one
            List<UserRole> roles = [SELECT Id FROM UserRole WHERE DeveloperName = :roleNames[0] LIMIT 1];
        
            if( roles != null && !roles.isEmpty() ) {
                result = roles[0].Id;
            }
        }

        return result;
    }

    /**
     * Get the ids of the list of public groups configured for the given list of roles.
     * 
     * @author nts (agonzalezisasi)
     * @date 25/12/2021
     * @param {List<String>} A list of group names
     * @return {List<Id>}: A list of ids
     */
    private List<Id> getPublicGroupsFromRoles( List<String> groupNames )
    {
        List<Id> result = new List<Id>();

        if( groupNames != null && !groupNames.isEmpty() ) {
            result = new List<ID>(new Map<Id, Group>([
                SELECT Id FROM Group WHERE DeveloperName IN :groupNames
            ]).keySet());
        }

        return result;
    }

    /**
     * Get the ids of the list of permission set groups configured for the given list of roles.
     * 
     * @author nts (agonzalezisasi)
     * @date 28/12/2021
     * @param {List<String>} A list of permission set group names
     * @return {List<Id>}: A list of ids
     */
    private List<Id> getPermissionSetGroupsFromRoles( List<String> groupNames )
    {
        List<Id> result = new List<Id>();

        if( groupNames != null && !groupNames.isEmpty() ) {
            result = new List<ID>(new Map<Id, PermissionSetGroup>([
                SELECT Id FROM PermissionSetGroup WHERE DeveloperName IN :groupNames
            ]).keySet());
        }

        return result;
    }

    /**
     * Get the ids of the list of call centers configured for the given list of roles.
     * 
     * @author nts (agonzalezisasi)
     * @date 28/12/2021
     * @param {List<String>} A list of call center names
     * @return {List<Id>}: An Id of a call center
     */
    private Id getCallCenterFromRoles( List<String> callCenterNames )
    {
        Id result = null;

        if( callCenterNames != null && !callCenterNames.isEmpty() ) {
            string firstCallCenterName = callCenterNames[0];

            List<CallCenter> callCenters = [
                SELECT Id FROM CallCenter WHERE InternalName = :firstCallCenterName
            ];

            if( !callCenters.isEmpty() )
                result = callCenters[0].Id;
        }

        return result;
    }

    /**
     * @Description Actualiza la asignación de grupos públicos para el usuario especificado
     * @date 01/10/2020
     * @author eetxaniz
     * @param Id userId - Id del usuario a actualizar
     * @param List<GroupMember> groupMemberList - Mapa de grupos públicos a asignar. 
     * 
     * @change nts (agonzalezisasi) - 01/02/2021 - Se ha refactorizado
     * 
     *! @future
     */
    @future
    private static void assignPublicGroups(Id userId, List<ID> newGroupList)
    {
        try
        {
            if( String.isNotBlank(userId) ) {
                // Get the existing Groups for the user
                List<GroupMember> actualGroupMemberList = [
                    SELECT Id, GroupId FROM GroupMember WHERE GroupId != null AND userOrGroupId = :userId
                ];

                // for the groups that are not in the new list
                List<GroupMember> deleteGroups = new List<GroupMember>();
                
                // Compare the existing ones with the new ones
                // - if old not in the new list -> delete
                // - if old in the new list -> remove from new list
                for(Integer i=0,j=actualGroupMemberList.size();i<j;i++) {
                    Id oldId = actualGroupMemberList[i].GroupId;
                    if( !newGroupList.contains(oldId) ) {
                        deleteGroups.add(actualGroupMemberList[i]);
                    } else {
                        newGroupList.remove(newGroupList.indexOf(oldId));
                    }
                }

                if( !deleteGroups.isEmpty() )
                    delete deleteGroups;
                
                // Assign the new groups to the user
                if( newGroupList != null && !newGroupList.isEmpty() ) {
                    List<GroupMember> newGroupMemberList = new List<GroupMember>();
                    for(Integer i=0,j=newGroupList.size(); i<j; i++ ) {
                        newGroupMemberList.add(new GroupMember(
                            groupId= newGroupList[i],
                            userOrGroupId= userId
                        ));
                    }

                    if( !newGroupMemberList.isEmpty() )
                        insert newGroupMemberList;
                }
            }

        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
            //throw new RegHandlerException('Error durante la asignación de grupos, contacte con su administrador.');
        }
    }

    /**
     * Assign a List of permission Set Groups to the user
     * 
     * @author nts (agonzalezisasi)
     * @date 28/01/2021
     * 
     * @param {Id userId} the user
     * @param {List<ID> newPermissionSetGroups} the list of permission set groups
     * 
     *! @future
     */
    @future
    private static void assignPermissionSetGroup(Id userId, List<ID> newPermissionSetGroups)
    {
        try {
            if( String.isNotBlank(userId) ) {
                // Get the EXISTING permission set groups
                List<PermissionSetAssignment> existingPSG = [
                    SELECT id, PermissionSetGroupId FROM PermissionSetAssignment
                    WHERE PermissionSetGroupId != null AND AssigneeId = :userId
                ];

                // for the old permissions set groups that are not in the new list
                List<PermissionSetAssignment> deletePSG = new List<PermissionSetAssignment>();
                
                // Compare the existing ones with the new ones
                // - if old not in the new list -> delete
                // - if old in the new list -> remove from new list
                for(Integer i=0,j=existingPSG.size();i<j;i++) {
                    Id oldId = existingPSG[i].PermissionSetGroupId;
                    if( !newPermissionSetGroups.contains(oldId) ) {
                        deletePSG.add(existingPSG[i]);
                    } else {
                        newPermissionSetGroups.remove(newPermissionSetGroups.indexOf(oldId));
                    }
                }

                // DELETE the ones not used any more
                if( !deletePSG.isEmpty() ) {
                    delete deletePSG;
                }

                // Create the assignments to the user for the NEW permission set groups
                if( newPermissionSetGroups != null && !newPermissionSetGroups.isEmpty() ) {
                    List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();
                    for(Integer i=0,j=newPermissionSetGroups.size();i<j;i++) {
                        newAssignments.add(new PermissionSetAssignment(
                            PermissionSetGroupId = newPermissionSetGroups[i],
                            AssigneeId = userId
                        ));
                    }       

                    if( !newAssignments.isEmpty() )
                        insert newAssignments;
                }
            }        
        } catch( Exception e ) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }

    /**
     * @Description Excepción personalizada para oncluir el mensaje de error en la pantalla de lógin.
     * @date 03/06/2020
     * @author rpolvera
     */
    @testvisible
    class RegHandlerException extends Exception
    {}
}
