/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 08-07-2023
 * @last modified by  : aberuete
**/
public with sharing class OpenIDConnectSalesforceCommunity {

    private static final string USERNAME_SERVER = '@zurich-es.com';
    private static final string EMAIL_ENCODING = 'UTF-8';
    private static final string TIMEZONE = 'Europe/Paris';
    private static final string LANGUAGE_SPANISH = 'es';
    private static final Boolean SERVICE_CLOUD_USER = false;

    // signature
    private static final String CONFIG_API_SIGNATURE_CONTENT = 'Content';
    private static final String CONFIG_API_SIGNATURE_FIELDS = 'Fields';
    @testvisible
    private String testSignatureContent;
    @testvisible
    private String testSignatureFields;

    // Text to be used in the field AuthMapping__mdt.Permission__c to reference Aministrator profile
    @testvisible
    private static final string PROFILE_ADMIN = 'SystemAdmin';

    @testvisible
    private List<AuthMapping__mdt> testListAuthMappings;

    @testvisible
    private static final string GROUP_MEMBER_QUEUE = 'Queue';
    @testvisible
    private static final string AUTH_DATA_MAP_NAME = 'roles';

    @testvisible
    private static final string PERMISSION_TYPE_PROFILE = 'Profile';
    @testvisible
    private static final string PERMISSION_TYPE_PUBLIC_GROUP = 'PublicGroup';
    @testvisible
    private static final string PERMISSION_TYPE_PERMISSION_SET_GROUP = 'PermissionSetGroup';
    @testvisible
    private static final string PERMISSION_TYPE_ROLE = 'Role';
    @testvisible
    private static final string PERMISSION_TYPE_USER_PERMISSION = 'UserPermission';
    @testvisible
    private static final string PERMISSION_TYPE_DEPARTMENT = 'Department';
    @testvisible
    private static final string PERMISSION_TYPE_SIGNATURE = 'Signature';
    @testvisible
    private static final string PERMISSION_TYPE_TITLE = 'Title';
    @testvisible
    private static final string PERMISSION_TYPE_AFFILIATION_CODE = 'AffiliationCode';
    @testvisible
    private static final string AUTH_DATA_ATTRIBUTE_MANAGER = 'manager';
    @testvisible
    private static final string AUTH_DATA_ATTRIBUTE_ACCOUNT_CODE = 'accountcode';    
    @testvisible
    private static final string PERMISSION_TYPE_LICENSE_GROUP = 'LicenseGroup';

    private static final string CLASS_NAME = 'OpenIDConnectSalesforceLicense';
    // errores
    private static final string ERROR_NO_PROFILE = 'No PROFILE found in the configuration for the given list of rols: ';
    private static final String ERROR_NO_ACCOUNT_CODE = 'No AccountCode received from IAM';
    private static final String ERROR_NO_INTERMEDIARY_ACCOUNT = 'No Intermediary Account found';
    private static final String ERROR_NEW_CONTACT = 'The new Contact cannot be inserted: ';
    private static final String ERROR_NO_DUMMY_ACCOUNT = 'Dummy Account not found';


    public User createUser(Id portalId, Auth.UserData data, List<String> iamRoleReceived) {

        // CHECK USER
        User u = checkUser(data);
        // Si un usuario con el mismo correo ya existe en el sistema, se actualiza y se retorna.
        if (u != null) {
            updateUser(u.Id, portalId, data, iamRoleReceived);
            return u;
        }

        // GET AUTH DATA
        Map<string, Object> metadataInfoMap = getAuthData(iamRoleReceived);

        // Enrutamos el login al flujo de login correspondiente
        if (checkAffiliationCode(metadataInfoMap)) { // si tiene el valor en la metadata
            u = createContactAndAssingDummyToDummyAccount(data, metadataInfoMap, iamRoleReceived);
        } else {
            u = createUserAndAssingToExistingContact(data, metadataInfoMap, iamRoleReceived);
        }

        return u;
    }

    public void updateUser(Id userId, Id portalId, Auth.UserData data, List<String> iamRoleReceived) {

        // GET AUTH DATA
        Map<string, Object> metadataInfoMap = getAuthData(iamRoleReceived);

        // comprueba si los datos del usuario han cambiado respecto al rol recibido y a los registros de la metadata
        User u = updateUserData(userId, data, metadataInfoMap, iamRoleReceived);

        // añadir configuración restante
        addUserRelated(u.Id, metadataInfoMap);        
    }




    ///////////////////////////////////////////////// Métodos Principales /////////////////////////////////////////////////
    /**
     * @Description Comprueba si el usuario introducido existe, es posible que al usar dos o mas proveedores de identidad, el mismo
     *              Ususario pueda acceder desde varios sitios. El método comprueba por email la existencia del usuario y lo devuelve.
     * @date 06/06/2020
     * @author rpolvera
     * @param {Auth.UserData} data - Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl,
     *                               attributeMap)
     * @return {User} si existe usuario lo devuelve.
     */
    private User checkUser(Auth.UserData data) {

        User result = null;
        result = (new UsersSelector()).findUserByEmail(data.email); 
        return result;
    }


    /**
     * Get all the auth data for the given role.
     * Auth data: profile, sf roles, groups, permission set groups, call centers
     * 
     * @author nts (dmunoz)
     * @date 12/06/2023
     * @param {String iamRoleReceived} iam rol
     */
    private Map<String, Object> getAuthData(List<String> iamRoleReceived) {

        Map<String, Object> result = new Map<String, Object>();

        // Marcar algún campo check del ususario
        Map<String, Boolean> userPermissionMap = new Map<string, Boolean>();

        // permisos a los
        Map<String, List<String>> authMap = new Map<String, List<String>>();
        authMap.put(PERMISSION_TYPE_PROFILE, new List<String>());
        authMap.put(PERMISSION_TYPE_PUBLIC_GROUP, new List<String>());
        authMap.put(PERMISSION_TYPE_PERMISSION_SET_GROUP, new List<String>());
        authMap.put(PERMISSION_TYPE_ROLE, new List<String>());
        authMap.put(PERMISSION_TYPE_DEPARTMENT, new List<String>());
        authMap.put(PERMISSION_TYPE_SIGNATURE, new List<String>());
        authMap.put(PERMISSION_TYPE_TITLE, new List<String>());
        authMap.put(PERMISSION_TYPE_AFFILIATION_CODE, new List<String>());
        authMap.put(PERMISSION_TYPE_LICENSE_GROUP, new List<String>());

        
        // Get the list of Auth Mapping Data fro the given roles
        List<AuthMapping__mdt> authConfig = new List<AuthMapping__mdt>([
            SELECT Permission_Type__c, Permission__c, Order__c, User_Permision_Value__c FROM AuthMapping__mdt 
            WHERE Role_Name__c IN :iamRoleReceived
            ORDER BY Order__c
        ]);
        // if is a test, mock the result
        if (Test.isRunningTest() && testListAuthMappings != null) {
            authConfig.addAll(testListAuthMappings);
        }

        if (!authConfig.isEmpty()) {            
            for (AuthMapping__mdt mdt: authConfig) {
                // si el tipo es "UserPermission" 
                if (PERMISSION_TYPE_USER_PERMISSION.equals(mdt.Permission_Type__c)) {
                    userPermissionMap.put(mdt.Permission__c, mdt.User_Permision_Value__c);
                } else {
                    authMap.get(mdt.Permission_Type__c).add(mdt.Permission__c);
                }
            }
        }

        result.put('AuthMap', authMap);
        result.put('UserPermissionMap', userPermissionMap);            
        
        return result;
    }

    /**
     * @Description obtener el valor de AffiliationCode desde el atributo del data que nos viene del IAM
     * @date 12/06/2023
     * @author dmunoz
     */
    private Boolean checkAffiliationCode(Map<string, Object> metadataInfoMap) {
        Boolean result = false;
        Map<String, List<String>> authMap = (Map<String, List<String>>) metadataInfoMap.get('AuthMap');

        if (!authMap.get(PERMISSION_TYPE_AFFILIATION_CODE).isEmpty()) {
           result = true;
        }
        return result;
    }

    private User createUserAndAssingToExistingContact(Auth.UserData data, Map<String, Object> metadataInfoMap, List<String> iamRoleReceived) {
        // buscar contacto, si no existe lo crea
        Id contactId = getIntermediaryContactId(data);

        User u = createUserData(data, metadataInfoMap, contactId, iamRoleReceived);        
        insert u;

        // añadir configuración restante
        addUserRelated(u.Id, metadataInfoMap);

        // ZRM ATMs (generamos los AccountTeamsMember solo para el primer login)
        Map<String, List<String>> authMap = (Map<String, List<String>>) metadataInfoMap.get('AuthMap');
        generateZRMATMs(u.Id, authMap.get(PERMISSION_TYPE_PROFILE));

        return u;

    }

    private User createContactAndAssingDummyToDummyAccount(Auth.UserData data, Map<String, Object> metadataInfoMap, List<String> iamRoleReceived) {
        
        // buscamos el account dummy y si es necesario creamos el contacto
        Id contactId = getContactIdFromDummyAccount(data, metadataInfoMap);

        User u = createUserData(data, metadataInfoMap, contactId, iamRoleReceived); 
        insert u;
        // añadir configuración restante
        addUserRelated(u.Id, metadataInfoMap);

        return u;

    }




    //////////////////////////////////////////// Métodos Auxiliares//////////////////////////////////////////////////

    /**
     * @Description Buscar el contacto al que asociar el nuevo usuario, por código de afiliación y por email
     * @date 12/06/2023
     * @author dmunoz
     */
    private Id getIntermediaryContactId(Auth.UserData data) {
        Id result;
        String accountCode;

        // obtener el código de mediador que llega desde IAM
        if (data.attributeMap.containsKey(AUTH_DATA_ATTRIBUTE_ACCOUNT_CODE)) {
            accountCode = data.attributeMap.get(AUTH_DATA_ATTRIBUTE_ACCOUNT_CODE);
        }

        if (accountCode == null || String.isEmpty(accountCode)) { // si no ha llegado un código devolvemos error
            throw new RegHandlerException(ERROR_NO_ACCOUNT_CODE);
        }

        List<Contact> contactList = (new ContactsSelector()).findIntermediaryContactByEmailAndAccountCode(data.email, accountCode);

        if (contactList.isEmpty()) { // si no existe contacto
            // consulta de account
            List<String> accountCodeList = new List<String>{accountCode};
            List<Account> accountList = (new AccountsSelector()).findByIntermediaryCode(accountCodeList); // debe llegar solo 1

            if (accountList == null || accountList.isEmpty()) { // si no existe cuenta
                throw new RegHandlerException(ERROR_NO_INTERMEDIARY_ACCOUNT);
            } else { // existe cuenta
                Account account = accountList.get(0);
                result = createContact(account.Id, data, 'AgentMediator');
            }
        } else { // si existe devolvemos el primero
            result = contactList.get(0).Id;
        }

        return result;
    }

    /**
     * @Description Buscamos la cuenta dummy y creamos el contacto
     * @date 12/06/2023
     * @author dmunoz
     */
    private Id getContactIdFromDummyAccount(Auth.UserData data, Map<String, Object> metadataInfoMap) {
        Id result;

        // obtener el codigo de filiación de la metadata
        Map<String, List<String>> authMap = (Map<String, List<String>>) metadataInfoMap.get('AuthMap');

        List<Account> accountList = (new AccountsSelector()).findAccountByBusinessCode(authMap.get(PERMISSION_TYPE_AFFILIATION_CODE));

        if (accountList.isEmpty()) {
            throw new RegHandlerException(ERROR_NO_DUMMY_ACCOUNT);
        }

        result = createContact(accountList.get(0).Id, data, 'ContactPartner');        

        return result;
    }

    /**
     * @Description Crear registro de contacto y asociar a un account dado
     * @date 12/06/2023
     * @author dmunoz
     */
    private Id createContact(Id accountId, Auth.UserData data, String recordTypeDeveloperName) {

        try {
            Id result;
    
            Contact c = new Contact();
            c.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName).getRecordTypeId();
            c.FirstName = data.firstName;
            c.LastName = data.lastName;
            c.Email = data.email;
            c.accountId = accountId;
            c.LegalEntity__c = '999';
            insert c;
    
            result = c.Id;
    
            return result;
        } catch (Exception e) {
            throw new RegHandlerException(ERROR_NEW_CONTACT + e.getMessage());
        }
    }

    /**
     * @Description Preparar el registro User para su inserción
     * @date 12/06/2023
     * @author dmunoz
     * change aberuete - 07/08/2023 - Añadir firma del usuario 
     */
    private User createUserData(Auth.UserData data, Map<String, Object> metadataInfoMap, Id contactId, List<String> iamRoleReceived) {

        Map<String, List<String>> authMap = (Map<String, List<String>>) metadataInfoMap.get('AuthMap');
        Map<String, Boolean> userPermissionMap = (Map<String, Boolean>) metadataInfoMap.get('UserPermissionMap');

        Id profileId = getProfileIdFromRoles(authMap.get(PERMISSION_TYPE_PROFILE), iamRoleReceived);
        // Get ROLE ID
        Id roleId = getRoleIdFromRoles(authMap.get(PERMISSION_TYPE_ROLE));
        // GET Department
        String department = getDepartmentFromRoles(authMap.get(PERMISSION_TYPE_DEPARTMENT));
        // GET Title
        String title = getTitleFromRoles(authMap.get(PERMISSION_TYPE_TITLE));
        // GET LicenseGroup
        String licenseGroup = getLicenseGroupFromRoles(authMap.get(PERMISSION_TYPE_LICENSE_GROUP));
        // GET Manager
        Id managerId = getManagerIdFromNickname(data);
        // NEW USER
        User u = new User();
        u.firstName = data.firstName;
        u.lastName = data.lastName;
        u.email = data.email;
        u.username = data.username + USERNAME_SERVER;
        u.profileId = profileId;
        u.alias = data.username.left(8);
        u.CommunityNickname = data.username;
        u.languagelocalekey = LANGUAGE_SPANISH;
        u.UserPermissionsSupportUser = SERVICE_CLOUD_USER;
        u.localesidkey = UserInfo.getLocale();
        u.emailEncodingKey = EMAIL_ENCODING;
        u.timeZoneSidKey = TIMEZONE; 
        u.contactId = contactId; // añado el id de contacto a asociar
        if (roleId != null ) {
            u.UserRoleId = roleId;
        }
        if (userPermissionMap != null && !userPermissionMap.isEmpty()) {
            activateUserPermission(userPermissionMap, u);
        }
        if (String.isNotBlank(department)) {
            u.Department = department;
        }
        if (String.isNotBlank(title)) {
            u.Title = title;
        }
        if( String.isNotBlank(licenseGroup) ) {
            u.License_Group__c = licenseGroup;
        }
        if (ManagerId != null) {
            u.ManagerId = ManagerId;
        }

        String signature = getSignature(u, authMap.get(PERMISSION_TYPE_SIGNATURE));

        if (String.isNotBlank(signature)) 
        {
            u.Signature = signature;
        }
        return u;
    }


    private User updateUserData(Id userId, Auth.UserData data, Map<String, Object> metadataInfoMap, List<String> iamRoleReceived) 
    {
        Boolean modified = false;
        User u;

        Map<String, List<String>> authMap = (Map<String, List<String>>) metadataInfoMap.get('AuthMap');
        Map<String, Boolean> userPermissionMap = (Map<String, Boolean>) metadataInfoMap.get('UserPermissionMap');

        Id profileId = getProfileIdFromRoles(authMap.get(PERMISSION_TYPE_PROFILE), iamRoleReceived);
        // Get ROLE ID
        Id roleId = getRoleIdFromRoles(authMap.get(PERMISSION_TYPE_ROLE));
        // GET Department
        String department = getDepartmentFromRoles(authMap.get(PERMISSION_TYPE_DEPARTMENT));
        // GET Title
        String title = getTitleFromRoles(authMap.get(PERMISSION_TYPE_TITLE));
        // GET LicenseGroup
        String licenseGroup = getLicenseGroupFromRoles(authMap.get(PERMISSION_TYPE_LICENSE_GROUP));
        // GET Manager
        Id managerId = getManagerIdFromNickname(data);

        // buscar usuario en la bd
        u = (new UsersSelector()).getLoginUserToUpdate(userId);
        // Get signature
        String signature = getSignature(u, authMap.get(PERMISSION_TYPE_SIGNATURE));
        // si hay modificaciones se actualiza el usuario
        modified = (u.firstName != data.firstName || u.lastName != data.lastName || u.Department != department ||
                    u.userName != data.username + USERNAME_SERVER || u.profileId != profileId || 
                    u.UserRoleId != roleId || u.alias != data.username.left(8) || u.email != data.email ||
                    (String.isNotBlank(signature) && signature != u.Signature) ||
                    u.Title != title || (ManagerId != null && u.ManagerId != ManagerId) || 
                    (String.isNotBlank(licenseGroup) && licenseGroup != u.License_Group__c)
                );
        
        if (modified) {
            u.firstName = data.firstName;
            u.lastName = data.lastName;            
            u.profileId = profileId;
            u.alias = data.username.left(8);
            u.CommunityNickname = data.username;
            updateEmail(u, data.email);
            updateUserName(u, data.username);
            updateUserRoleId(u, roleId);
            updateDepartment(u, department);
            updateSignature(u, signature);
            updateTitle(u, title);
            updateManager(u, managerId);
            if( String.isNotBlank(licenseGroup) ) {
                u.License_Group__c = licenseGroup;
            }

            if( userPermissionMap != null && !userPermissionMap.isEmpty()){
                activateUserPermission(userPermissionMap, u);
            }
            if (!Test.isRunningTest()) { // para evitar un error en el test no actualizo el registro de usuario si es un test
                update u;
            }
        }
        return u;
    }    


    /**
     * @Description Se ha de actualizar el usuario con la información de grupo público y asignar un permission set group
     * @date 12/06/2023
     * @author dmunoz
     * change aberuete - 07/08/2023 - Quitar actualizar la firma del usuario en este método y añadirlo en método createUserData y updateUserData
     */
    private void addUserRelated(Id userId, Map<String, Object> metadataInfoMap) 
    {
        Map<String, List<String>> authMap = (Map<String, List<String>>) metadataInfoMap.get('AuthMap');
        // GROUPS
        // Obtener los ids de los grupos públicos en salesforce
        List<Id> publicGroupIdList = getPublicGroupsFromRoles(authMap.get(PERMISSION_TYPE_PUBLIC_GROUP));
        // Actualizar de forma asincrona la asignación a grupos
        assignPublicGroups(userId, publicGroupIdList);
        // PERMISSION SETS
        List<Id> permissionSetGroupIdList = getPermissionSetGroupsFromRoles(authMap.get(PERMISSION_TYPE_PERMISSION_SET_GROUP));
        assignPermissionSetGroup(userId, permissionSetGroupIdList);       
    }


    /**
     * Obtener el id del perfil
     * 
     * @author nts (dmunoz)
     * @date 12/06/2023
     * @param {List<String> profileNames} siempre llegará solo 1
     * @param {String iamRoleReceived} rol recibido desde iam
     * @return {Id}: The id of the profile
     */
    @testvisible
    private Id getProfileIdFromRoles(List<String> profileNames, List<String> iamRoleReceived) {

        Id result = null;
        Map<Id, Profile> profileMap; 

        if (profileNames != null && !profileNames.isEmpty() ) {
            
            if (profileNames.contains(PROFILE_ADMIN)) {
                profileMap = ProfilesSelector.getProfilesByName(OpenIDConnectSalesforceLicense.SYS_ADMIN_TRANSLATIONS); 
            } else {
                profileMap = ProfilesSelector.getProfilesByName(profileNames);
            }

            // me quedo con el primer id de perfil ya que solo vendrá uno
            if (profileMap != null && !profileMap.keySet().isEmpty()) {
                List<Id> keyList = new List<Id>();
                keyList.addAll(profileMap.keySet());
                result = keyList.get(0);
            }
        }
        if (result == null) {
            throw new RegHandlerException(ERROR_NO_PROFILE + String.join(iamRoleReceived, ', '));
        }

        return result;
    }

    /**
     * Obtener el id del rol
     * 
     * @author nts (dmunoz)
     * @date 12/06/2023
     * @param {List<String> roleNames} A list of rol names
     * @return {Id}: The id of the role
     */
    private Id getRoleIdFromRoles(List<String> roleNames) {
        Id result = null;
        if (roleNames != null && !roleNames.isEmpty()) {
            UserRole userRole = (new UserRoleSelector()).findUserRoleByDeveloperName(roleNames.get(0));
            if (userRole != null) {
                result = userRole.Id;
            }
        }
        return result;
    }

    /**
     * Get the department configured for the given list of roles.
     * 
     * @author nts (dmunoz)
     * @date 12/06/2023
     * @param {List<String> deptNames} A list of deptarments
     * @return {string}: The deptartment
     */
    private String getDepartmentFromRoles(List<String> deptNames ) {
        String result = null;
        if (deptNames != null && !deptNames.isEmpty()) {
            // because of the order in the query, the first one should be the best one
            result = deptNames[0];
        }
        return result;
    }

    /**
     * Get the title configured for the given list of roles.
     * 
     * @author nts (dmunoz)
     * @date 12/06/2023
     * @param {List<String> titleNames} A list of titles
     * @return {string}: The title
     */
    private String getTitleFromRoles(List<String> titleNames) {
        String result = null;
        if (titleNames != null && !titleNames.isEmpty()) {
            // because of the order in the query, the first one should be the best one
            result = titleNames[0];
        }
        return result;
    }

    /**
     * Get the licenseGroup configured for the given list of roles.
     * 
     * @author zurih (jonander.sanjuanlago)
     * @date 18/01/2024
     * @param {List<String> licenseGroupNames} A list of licenseGroup
     * @return {string}: The licenseGroup
     */
    private String getLicenseGroupFromRoles(List<String> licenseGroupNames ) 
    {
        String result = null;
        if( licenseGroupNames != null && !licenseGroupNames.isEmpty() ) {
            // because of the order in the query, the first one should be the best one
            result = licenseGroupNames[0];
        }
        return result;
    }

    /**
     * @Description obtener el ManagerId desde el atributo Manager del data que nos viene del IAM
     * @date 12/06/2023
     * @author dmunoz
     */
    private Id getManagerIdFromNickname(Auth.UserData data) {

        Id result = null;
        if (data.attributeMap.containsKey(AUTH_DATA_ATTRIBUTE_MANAGER)) {
            String attribute = data.attributeMap.get(AUTH_DATA_ATTRIBUTE_MANAGER);
            User user = (new UsersSelector()).findUserByCommunityNickname(attribute);

            if (user != null) {
                result = user.Id;
            }
        }
        return result;
    }

    /**
     * Get the ids of the list of public groups configured for the given list of roles.
     * 
     * @author nts (dmunoz)
     * @date 12/06/2023
     * @param {List<String>} A list of group names
     * @return {List<Id>}: A list of ids
     */
    private List<Id> getPublicGroupsFromRoles(List<String> groupNames) {
        List<Id> result = new List<Id>();
        Map<Id, Group> groupMap = (new GroupSelector()).findPublicGroupByDeveloperName(groupNames);
        
        if (!groupMap.isEmpty()) {
            result = new List<Id>(groupMap.keySet());
        }
        
        return result;
    }


    /**
     * @Description Actualiza la asignación de grupos públicos para el usuario especificado, eliminamos los grupos que no coinciden con la metadata e insertamos los que faltan
     * @date 12/06/2023
     * @author dmunoz
     * @param Id userId - Id del usuario a actualizar
     * @param List<GroupMember> groupMemberList - Mapa de grupos públicos a asignar. 
     * 
     * @change nts (agonzalezisasi) - 01/02/2021 - Se ha refactorizado
     * 
     *! @future
     */
    @future
    private static void assignPublicGroups(Id userId, List<Id> newGroupList) {
        
        try {
            if (String.isNotBlank(userId)) {

                // Obtener los grupos actuales del usuario
                List<GroupMember> actualGroupMemberList = (new GroupSelector()).findUserNotQueueGroups(userId);

                // obtengo un conjunto de grupos a partir de los miembros actuales a los que pertenece el usuario para comparar con los grupos obtenidos por la metadata
                Set<Id> actualGroupIdList = new Set<Id>();
                for (GroupMember member: actualGroupMemberList) {
                    actualGroupIdList.add(member.GroupId);
                }

                removeUnusedGroups(userId, newGroupList);
                addGroupsToUser(userId, newGroupList, actualGroupIdList);
            }
        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }

   /**
    * @Description eliminamos los grupos a los que ya no debe pertenecer el usuario
    * @date 12/06/2023
    * @author dmunoz
    * @param List<Id> newGroupList - Mapa de grupos públicos a asignar.
    * @param Set<Id> actualGroupIdList - grupos a los que pertenece actualmente el usuario
    */
    private static void removeUnusedGroups(Id userId, List<Id> newGroupList) {
        
        List<GroupMember> groupMemberToDelete = (new GroupSelector()).findUserNotQueueGroupsNotInMetadata(userId, newGroupList);
        
        if (!groupMemberToDelete.isEmpty()) {
            delete groupMemberToDelete;
        }
    }

    /**
    * @Description añadir los grupos a los que pertenece el usuario
    * @date 12/06/2023
    * @author dmunoz
    * @param Id userId - Id del usuario a actualizar
    * @param List<Id> newGroupList - Lista de grupos públicos a asignar. 
    * @param Set<Id> actualGroupIdList - grupos a los que pertenece actualmente el usuario
    */
    private static void addGroupsToUser(Id userId, List<Id> newGroupList, Set<Id> actualGroupIdList) {
        List<GroupMember> newGroupMemberToInsertList = new List<GroupMember>();
        // insertamos los grupos nuevos
        // Crear un conjunto para gruposMetadata
        Set<Id> newGroupMemberList = new Set<Id>(newGroupList);
        // Eliminar los coincidentes
        newGroupMemberList.removeAll(actualGroupIdList);        

        if (!newGroupMemberList.isEmpty()) {                    
            for (Id groupId: newGroupMemberList) {
                newGroupMemberToInsertList.add(
                    new GroupMember(
                    groupId = groupId,
                    userOrGroupId = userId
                ));
            }                  
        }

        if (!newGroupMemberToInsertList.isEmpty()) {            
            insert newGroupMemberToInsertList;
        }
    }

    /**
     * Get the ids of the list of permission set groups configured for the given list of roles.
     * 
     * @author nts (dmunoz)
     * @date 13/06/2023
     * @param {List<String>} A list of permission set group names
     * @return {List<Id>}: A list of ids
     */
    private List<Id> getPermissionSetGroupsFromRoles(List<String> permissionSetGroupList) {
        
        List<Id> result = new List<Id>();
        Map<Id, PermissionSetGroup> permissionSetGroupMap = (new PermissionSetGroupSelector()).findPermissionSetGroupFromDeveloperName(permissionSetGroupList);
        
        if (!permissionSetGroupMap.isEmpty()) {
            result = new List<Id>(permissionSetGroupMap.keySet());
        }
        
        return result;        
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
    public static void assignPermissionSetGroup(Id userId, List<Id> newPermissionSetGroups) {
        try {
            if (String.isNotBlank(userId)) {
                // obtener los permission set groups actuales del usuario
                List<PermissionSetAssignment> actualPermissionAssigmentList = (new PermissionSetGroupSelector()).findUserPermissionSetGroupFromUserId(userId);

                // Obtengo los ids de los permission set group de la query anterior
                Set<Id> actualUserPSGList = new Set<Id>();
                for (PermissionSetAssignment psa: actualPermissionAssigmentList) {
                    actualUserPSGList.add(psa.PermissionSetGroupId);
                }

                removeUnusedPermissionSetGroups(userId, newPermissionSetGroups);
                addPermissionSetGroupsToUser(userId, newPermissionSetGroups, actualUserPSGList);
            }        
        } catch( Exception e ) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }

    /**
    * @Description eliminamos los psg a los que ya no debe pertenecer el usuario
    * @date 12/06/2023
    * @author dmunoz
    * @param List<Id> newPermissionSetGroups - Mapa de grupos públicos a asignar.
    * @param Set<Id> actualUserPSGList - psg a los que pertenece actualmente el usuario
    */
    private static void removeUnusedPermissionSetGroups(Id userId, List<Id> newPermissionSetGroups) {
        List<PermissionSetAssignment> permissionSetGroupAssingmentToDelete = (new PermissionSetGroupSelector()).findUserPermissionSetGroupFromUserIdNotInMetadata(userId, newPermissionSetGroups);
        
        if (!permissionSetGroupAssingmentToDelete.isEmpty()) {
            delete permissionSetGroupAssingmentToDelete;
        }
    }

    /**
    * @Description añadir los psg a los que pertenece el usuario
    * @date 12/06/2023
    * @author dmunoz
    * @param Id userId - Id del usuario a actualizar
    * @param List<Id> newPermissionSetGroups - Lista de psg a asignar. 
    * @param Set<Id> actualUserPSGList - grupos a los que pertenece actualmente el usuario
    */
    private static void addPermissionSetGroupsToUser(Id userId, List<Id> newPermissionSetGroups, Set<Id> actualUserPSGList) {
        List<PermissionSetAssignment> newPSGToInsertList = new List<PermissionSetAssignment>();
        // insertamos los grupos nuevos
        // Crear un conjunto para gruposMetadata
        Set<Id> newPSGList = new Set<Id>(newPermissionSetGroups);
        // Eliminar los coincidentes
        newPSGList.removeAll(actualUserPSGList);

        if (!newPSGList.isEmpty()) {                    
            for (Id permissionSetAssignmentId: newPSGList) {
                newPSGToInsertList.add(
                    new PermissionSetAssignment(
                        PermissionSetGroupId = permissionSetAssignmentId,
                        AssigneeId = userId
                    )
                );
            }                  
        }

        if (!newPSGToInsertList.isEmpty()) {
            insert newPSGToInsertList;
        }
    }

    /**
     * Get the configured text for the signature
     * Example:
     *     Text: {0} {1}<br/>{2}<br/><br/>Zurich Seguros
     *     Fields: FirstName,LastName,Department
     *     Field values: John,Doe,Marketing
     *     Result: John Doe<br/>Marketing<br/><br/>Zurich Seguros
     *  
     * @author nts (agonzalezisasi)
     */
    private String getSignature(User user, List<String> signatureSettings) {
       String result = '';
       if (signatureSettings != null && !signatureSettings.isEmpty()) {
           try {
                // First get the api name of the admin setup parameter "prefix" for the signature that, because the order, the first one should be good
                String signatureName = signatureSettings[0];
                // Get the name of the parameters in the metadata, concatenating the signature name with the text "Content" and "Fields"
                // Example: IAMUserSignature + Content = IAMUserSignatureContent / IAMUserSignature + Fields = IAMUserSignatureFields
                String configContent = signatureName + CONFIG_API_SIGNATURE_CONTENT;
                String configFieldsQuery = signatureName + CONFIG_API_SIGNATURE_FIELDS;
                // Get Text for the Signature from the metadata configuration
                String configFirma = '';                
                List<AdminSetupParameter__mdt> config = new List<AdminSetupParameter__mdt>([SELECT Value__c FROM AdminSetupParameter__mdt WHERE KeyName__c = :configContent]);
                if (!config.isEmpty()) {
                    configFirma = config[0].Value__c;
                }
                // Get the fields of the User sobject to be included in the Signature from the metadata configuration
                String configFields = '';
                config = new List<AdminSetupParameter__mdt>([SELECT Value__c FROM AdminSetupParameter__mdt WHERE KeyName__c = :configFieldsQuery]);
                if (!config.isEmpty()) {
                    configFields = config[0].Value__c;
                }
                // For the Testing, to avoid problems, we overwrite the configuration parameters
                if (Test.isRunningTest()) {
                    configFirma = this.testSignatureContent;
                    configFields = this.testSignatureFields;
                }

               result = calculateSignature(user, configFirma, configFields);
           } catch (Exception ex) {
               ErrorLogUtil.commitError(ex, CLASS_NAME);
           }
       }
       return result;
    }

    private String calculateSignature(User user, String configFirma, String configFields) 
    { 
        String result = '';
        String userFields = JSON.serialize(user);
        Map<String, Object> mapUserFields = (Map<String,Object>) JSON.deserializeUntyped(userFields);
        List<String> listValues = new List<String>();
        if (String.IsNotBlank(configFields)) 
        {
            List<String> listFields = configFields.split(',');
            for (String s: listFields) 
            {
                 String fieldText = '';
                 if ((mapUserFields.keySet()).contains(s))
                 {
                    fieldText = (String) mapUserFields.get(s);
                 }
                 listValues.add(fieldText);
            }
        }
        // Put the values of the User fields in the slots ({n}) of the configured text
        result = String.format(configFirma, listValues);
        result = result + '<br>' + Label.IAMUserSignatureLegal; 
        return result;
    }

    /**
     * @Description Activar los permisos de usuario o desactivarlo si el campo User_Permision_Value__c está a false
     * @date 12/06/2023
     * @author dmunoz
     */
    private void activateUserPermission(Map<string, Boolean> userPermissionsMap, User usuario) {

        for(String userPermission : userPermissionsMap.keySet()) {
            if(userPermissionsMap.get(userPermission) != null && userPermissionsMap.get(userPermission) == true) {
                usuario.put(userPermission, true);
            } else {
                usuario.put(userPermission, false);
            }
        }
    }

    private void updateEmail(User u, String email) {
        if (u.email != email) {
            u.email = email;
        }
    }

    private void updateUserName(User u, String userName) {
        if (u.userName != userName + USERNAME_SERVER) {
            u.userName = userName + USERNAME_SERVER;
        }
    }

    private void updateUserRoleId(User u, Id roleId) {
        if (u.UserRoleId != roleId) {
            u.UserRoleId = roleId;
        }
    }

    private void updateDepartment(User u, String department) {
        if (u.Department != department) {
            u.Department = department;
        }
    }

    private void updateSignature(User u, String signature) {
        if (String.isNotBlank(signature) && u.Signature != signature) {
            u.Signature = signature;
        }
    }

    private void updateTitle(User u, String title) {
        if( u.Title != title ) {
            u.Title= title;
        }
    }

    private void updateManager(User u, String managerId) {
        if( managerId != null ) {
            u.ManagerId = ManagerId;
        }
    }

    /**
     * @Description Generar los account team member en caso que se esté 
     * @date 03/06/2020
     * @author rpolvera
     */
    @Future
    @TestVisible
    private static void generateZRMATMs(String userId, List<String> profileList) {

        String profile = profileList.get(0);

        if ('Agente Ventas'.equals(profile)) {
            // 1º Obtengo el Mediador del usuario
            UsersSelector usersSelector = new UsersSelector();
            User userInserted = usersSelector.findUserIntermediaryByUserId(userId);
            generateATMsAgenteVentas(userInserted, userId);
            

        } else if ('Agente Ventas - AGR'.equals(profile)) {
            // 1º Obtengo el Mediador del usuario y agrupacion
            UsersSelector usersSelector = new UsersSelector();
            User userInserted = usersSelector.findUserIntermediaryByUserId(userId); 
            generateATMsAgenteVentasAGR(userInserted, userId);
        }        
    }

    /**
     * @Description Generar los account team member para un usuario con perfil Agente Ventas
     * @date 24/2/2024
     * @author dmunoz
     */
    private static void generateATMsAgenteVentas(User userInserted, String userId) {
        // 2º Si existe algun otro usuario agr del mediador o de la agrupacion a la que pertenezca para dicho mediador clonamos los atm
        List<User> intermediariesUsers = (new UsersSelector()).findZRMAgenteVentaAGRActiveUsersByIntermediaryId(userInserted);

        if (intermediariesUsers != null && !intermediariesUsers.isEmpty()) {
            List<AccountTeamMember> accountTeamsToClone = (new AccountTeamMemberSelector()).findZRMATMsByUser(new List<User> {intermediariesUsers.get(0)});
            List<AccountTeamMember> clonedATMsList = AccountTeamMemberUtil.cloneUserATMZRMRecordList(accountTeamsToClone, userId);

            if (!clonedATMsList.isEmpty()) {
                insert clonedATMsList;
            }

        } else { // 3º Si no existe otro usuario obtenemos los tomadores de todas las polizas de la agrupacion y generamos los atm
            List<Policy__c> intermediaryPolicies = (new PoliciesSelector()).selectByIntermediaryGroupId(new Set<String> {userInserted.contact.Account.IntermediaryGroup__c});
            List<AccountTeamMember> atmsToInsert = new List<AccountTeamMember>();
            AccountTeamMember atm;

            for (Policy__c policy: intermediaryPolicies) {
                atm = AccountTeamMemberUtil.createATMZRMRecord(policy.PolicyHolder__c, userId);
                atmsToInsert.add(atm);
            }

            if (!atmsToInsert.isEmpty()) {
                insert atmsToInsert;
            }
        }
    }


    /**
     * @Description Generar los account team member para un usuario con perfil Agente Ventas
     * @date 24/2/2024
     * @author dmunoz
     */
    private static void generateATMsAgenteVentasAGR(User userInserted, String userId) {
        // 2º Si existe algun otro usuario nominal para dicho mediador clonamos los atm
        List<User> intermediariesUsers = (new UsersSelector()).findZRMAgenteVentaActiveUsersByIntermediaryId(userInserted);

        if (intermediariesUsers != null && !intermediariesUsers.isEmpty()) {
            List<AccountTeamMember> accountTeamsToClone = (new AccountTeamMemberSelector()).findZRMATMsByUser(new List<User> {intermediariesUsers.get(0)});
            List<AccountTeamMember> clonedATMsList = AccountTeamMemberUtil.cloneUserATMZRMRecordList(accountTeamsToClone, userId);

            if (!clonedATMsList.isEmpty()) {
                insert clonedATMsList;
            }

        } else { // 3º Si no existe otro usuario obtenemos los tomadores de polizas de dicho mediador e insertamos los atm
            List<Policy__c> intermediaryPolicies = (new PoliciesSelector()).selectByIntermediaryId(new Set<String> {userInserted.contact.AccountId});
            List<AccountTeamMember> atmsToInsert = new List<AccountTeamMember>();
            AccountTeamMember atm;

            for (Policy__c policy: intermediaryPolicies) {
                atm = AccountTeamMemberUtil.createATMZRMRecord(policy.PolicyHolder__c, userId);
                atmsToInsert.add(atm);
            }

            if (!atmsToInsert.isEmpty()) {
                insert atmsToInsert;
            }
        }
    }

    /**
     * @Description Excepción personalizada para incluir el mensaje de error en la pantalla de lógin.
     * @date 03/06/2020
     * @author rpolvera
     */
    @testvisible
    class RegHandlerException extends Exception
    {}

}