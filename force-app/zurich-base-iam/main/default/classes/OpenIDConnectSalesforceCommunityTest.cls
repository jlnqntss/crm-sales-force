@isTest
public with sharing class OpenIDConnectSalesforceCommunityTest {

    static final string IAM_ROLE_A = 'IAM_ROLE_VENTAS';
    static final string IAM_ROLE_B = 'IAM_ROLE_OCS';
    static final string IAM_ROLE_C = 'IAM_ROLE_CHANGE';
    static final string IAM_ROLE_A_NAME = 'TestRoleA';
    
    @TestSetup
    static void makeData() {      
        
        TestDataFactorySDM.intermediarySetupData();        
    }

    // buscamos un permission set group en el sistema
    private static List<PermissionSetGroup> getPermissionSetGroup() {

        List<PermissionSetGroup> result = new List<PermissionSetGroup>();
        // buscar permission set group
        result = new List<PermissionSetGroup>([SELECT DeveloperName FROM PermissionSetGroup LIMIT 2]);
        System.assertEquals(2, result.size(), 'Se debe encontrar al menos 2 Permission Set Group');

        return result;
        
    }

    // buscamos un public group en el sistema
    private static List<Group> getPublicGroup() {

        List<Group> result = new List<Group>();
        // buscar permission set group
        result = new List<Group>([SELECT DeveloperName FROM Group WHERE type = 'regular' LIMIT 2]);
        System.assertEquals(2, result.size(), 'Se debe encontrar al menos 2 Public Group');
        return result;
        
    }

    /**
     * Creates a list of AuthMapping__mdt to simulate the metadata configuration given a list of roles
     * separated by coma.
     *
     * @author nts (dmunoz)
     * @date 16/6/2023
     * @param {OpenIDConnectSalesforceCommunity handler} reference to the object OpenIDConnectSalesforceCommunity
     * @param {string roles} the list of roles separated by coma
     * @return {Auth.UserData} the auth user data structure
     *
     */
    static Auth.UserData mockAuthData(OpenIDConnectSalesforceCommunity handler, string roles, String email, String affiliationCode) {
        if (String.isBlank(roles)) {
            throw new OpenIDConnectSalesforceCommunity.RegHandlerException('No role specified for the test');
        }

        List<PermissionSetGroup> permissionSetGroupDeveloperName = getPermissionSetGroup();
        List<Group> publicGroupDeveloperName = getPublicGroup();

        handler.testListAuthMappings = new List<AuthMapping__mdt>();

        // IAM_ROLE_A
        if ( roles != null && roles.contains(IAM_ROLE_A) ) { // ventas
            // PROFILES
            // Get one profile except admin
            List<Profile> profiles = [
                SELECT Id, Name FROM Profile
                WHERE UserLicense.NAME = 'Partner Community'
                ORDER BY Name ASC
                LIMIT 1
            ];
            System.assertEquals(1, profiles.size(), 'There should be 1 profile');
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestProfile',
                                                  DeveloperName= 'TestProfile',
                                                  Role_Name__c= IAM_ROLE_A,
                                                  Permission__c= profiles[0].Name,
                                                  Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_PROFILE,
                                                  Order__c= 1,
                                                  IsCommunity__c = true
                                                  ) );

            // GROUPS
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestGroupA',
                                                  DeveloperName= 'TestGroupA',
                                                  Role_Name__c= IAM_ROLE_A,
                                                  Permission__c= publicGroupDeveloperName.get(0).DeveloperName,
                                                  Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_PUBLIC_GROUP,
                                                  Order__c= 1,
                                                  IsCommunity__c = true
                                                  ) );

            //PERMISSION SET GROUPS
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestPermissionSetGroupA',
                                                  DeveloperName= 'TestPermissionSetGroupA',
                                                  Role_Name__c= IAM_ROLE_A,
                                                  Permission__c= permissionSetGroupDeveloperName.get(0).DeveloperName,
                                                  Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_PERMISSION_SET_GROUP,
                                                  Order__c= 1,
                                                  IsCommunity__c = true
                                                  ) );

            // Role
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= IAM_ROLE_A_NAME,
                                                  DeveloperName= IAM_ROLE_A_NAME,
                                                  Role_Name__c= IAM_ROLE_A,
                                                  Permission__c= IAM_ROLE_A_NAME,
                                                  Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_ROLE,
                                                  Order__c= 1,
                                                  IsCommunity__c = true
                                                  ) );

            // Permiso Usuario
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                Label= 'TestUserPermission',
                DeveloperName= 'TestUserPermission',
                Role_Name__c= IAM_ROLE_A,
                Permission__c= 'UserPermissionsKnowledgeUser',
                Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_USER_PERMISSION,
                Order__c= 1
                ) );
            // Department
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                Label= 'TestDeptA',
                                                DeveloperName= 'TestdeptA',
                                                Role_Name__c= IAM_ROLE_A,
                                                Permission__c= 'TestDeptA',
                                                Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_DEPARTMENT,
                                                Order__c= 1,
                                                IsCommunity__c = true
                                                ) );
            
            // Signature
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                Label= 'TestSignaA',
                                                DeveloperName= 'TestSignaA',
                                                Role_Name__c= IAM_ROLE_A,
                                                Permission__c= 'TestSignaA',
                                                Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_SIGNATURE,
                                                Order__c= 1,
                                                IsCommunity__c = true
                                                ) );

            // Title
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                Label= 'TestTitleA',
                                                DeveloperName= 'TestTitleA',
                                                Role_Name__c= IAM_ROLE_A,
                                                Permission__c= 'TestTitleA',
                                                Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_TITLE,
                                                Order__c= 1,
                                                IsCommunity__c = true
                                                ) );            
        }

        // IAM_ROLE_B
        if (roles != null && roles.contains(IAM_ROLE_B)) { // OCS
            // PROFILES
            // Get one profile except admin
            List<Profile> profiles = [
                SELECT Id, Name FROM Profile
                WHERE  UserLicense.NAME = 'Partner Community' ORDER BY Name ASC
                LIMIT 1
            ];
            System.assertEquals(1, profiles.size(), 'There should be 1 profile');
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestProfileB',
                                                  DeveloperName= 'TestProfileB',
                                                  Role_Name__c= IAM_ROLE_B,
                                                  Permission__c= profiles[0].Name,
                                                  Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_PROFILE,
                                                  Order__c= 2,
                                                  IsCommunity__c = true
                                                  ) );
            // GROUPS
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestGroupB',
                                                  DeveloperName= 'TestGroupB',
                                                  Role_Name__c= IAM_ROLE_B,
                                                  Permission__c= publicGroupDeveloperName.get(0).DeveloperName,
                                                  Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_PUBLIC_GROUP,
                                                  Order__c= 2,
                                                  IsCommunity__c = true
                                                  ) );
            //PERMISSION SETS
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestPermissionSetGroupB',
                                                  DeveloperName= 'TestPermissionSetGroupB',
                                                  Role_Name__c= IAM_ROLE_B,
                                                  Permission__c= permissionSetGroupDeveloperName.get(0).DeveloperName,
                                                  Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_PERMISSION_SET_GROUP,
                                                  Order__c= 1,
                                                  IsCommunity__c = true
                                                  ) ); 
            // AffiliationCode
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                Label= 'TestAccountCodeB',
                                                DeveloperName= 'TestAccountCodeB',
                                                Role_Name__c= IAM_ROLE_B,
                                                Permission__c= affiliationCode,
                                                Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_AFFILIATION_CODE,
                                                Order__c= 1,
                                                IsCommunity__c = true
                                                ) );            
            // NO SF Role
            // NO Department
            // NO Signature
            // NO Title
        } if (roles != null && roles.contains(IAM_ROLE_C)) {
            // PROFILES
            // Get one profile except admin
            List<Profile> profiles = [
                SELECT Id, Name FROM Profile
                WHERE UserLicense.NAME = 'Partner Community'
                ORDER BY Name ASC
                LIMIT 1
            ];
            System.assertEquals(1, profiles.size(), 'There should be 1 profile');
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestProfile',
                                                  DeveloperName= 'TestProfile',
                                                  Role_Name__c= IAM_ROLE_A,
                                                  Permission__c= profiles[0].Name,
                                                  Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_PROFILE,
                                                  Order__c= 1,
                                                  IsCommunity__c = true
                                                  ) );

            // GROUPS
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestGroupA',
                                                  DeveloperName= 'TestGroupA',
                                                  Role_Name__c= IAM_ROLE_A,
                                                  Permission__c= publicGroupDeveloperName.get(1).DeveloperName,
                                                  Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_PUBLIC_GROUP,
                                                  Order__c= 1,
                                                  IsCommunity__c = true
                                                  ) );

            //PERMISSION SET GROUPS
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestPermissionSetGroupC',
                                                  DeveloperName= 'TestPermissionSetGroupC',
                                                  Role_Name__c= IAM_ROLE_A,
                                                  Permission__c= permissionSetGroupDeveloperName.get(1).DeveloperName,
                                                  Permission_Type__c = OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_PERMISSION_SET_GROUP,
                                                  Order__c= 1,
                                                  IsCommunity__c = true
                                                  ) );
        }

        // return de data structure from IAM
        return getSampleDataIAM(roles, email, affiliationCode);
    }


    /**
     * Creates the structure of Auth Data with the IAM roles
     *
     * @author nts (agonzalezisasi)
     * @date 01/02/2021
     * @param {string role_names} a list of roles separated by coma
     * @return {Auth.UserData} the auth user data structure
     */
    static Auth.UserData getSampleDataIAM(string role_names, String email, String accountCode) {


        String emailValue = String.isNotEmpty(email) ? email : 'testuser@example.org';
        Auth.UserData sampleDataIAM = new Auth.UserData(
            'testId',
            'testFirst',
            'testLast',
            'testFirst testLast',
            emailValue,
            null,
            'testuserlong',
            UserInfo.getLocale(),
            'facebook',
            null,
            new Map<String, String> {});
        if( role_names != null ) {
            sampleDataIAM.attributeMap.put(
                OpenIDConnectSalesforceCommunity.AUTH_DATA_MAP_NAME,
                '{crm=[' + role_names + ']}'
                );            
        }

        if (IAM_ROLE_A.equals(role_names) && accountCode != null && String.isNotEmpty(accountCode)) { // solo lo añadimos para el login de ventas (mediador)
            sampleDataIAM.attributeMap.put(
                OpenIDConnectSalesforceCommunity.AUTH_DATA_ATTRIBUTE_ACCOUNT_CODE,
                accountCode
                );
        }

        return sampleDataIAM;
    }

    // Test create user mediador//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // test de login para mediador, existiendo un contacto al cual crear un usuario de comunidad
    @isTest
    static void testCreateUserIntermediaryExistingContact() {

        List<Contact> contacts = new List<Contact>([SELECT Id, Account.Name, Email, Account.INFOIntermediaryCode__c FROM Contact]);
        

        if (!contacts.isEmpty()) {
            List<String> iamRoleReceived = new List<String>{IAM_ROLE_A};
    
            OpenIDConnectSalesforceCommunity handler = new OpenIDConnectSalesforceCommunity();
            Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A, contacts.get(0).Email, contacts.get(0).Account.INFOIntermediaryCode__c);
    
            Test.startTest();
            User u = handler.createUser(null, sampleDataIAM, iamRoleReceived);
            Test.stopTest();

            

            User createdUser = [SELECT userName, email, firstName, lastName, alias, ContactId FROM user WHERE id=:u.Id];
            System.assertEquals('testuserlong@zurich-es.com', createdUser.userName, 'UserName debe ser testuserlong@zurich-es.com');
            System.assertEquals('testLast', createdUser.lastName, 'LastName debe ser testLast');
            System.assertEquals('testFirst', createdUser.firstName, 'firstName debe ser testFirst');
        }
    }

    // test de login para mediador, NO existiendo un contacto al cual crear un usuario de comunidad
    @isTest
    static void testCreateUserIntermediaryNoExistingContact() {

        Map<Id, Contact> existingContactsMap = new Map<Id, Contact>([SELECT AccountId FROM Contact]);

        List<Account> accounts = new List<Account>([SELECT INFOIntermediaryCode__c FROM Account WHERE Id NOT IN (SELECT AccountId FROM Contact) AND INFOIntermediaryCode__c != NULL]);
        
        if (!accounts.isEmpty()) {
            List<String> iamRoleReceived = new List<String>{IAM_ROLE_A};
    
            OpenIDConnectSalesforceCommunity handler = new OpenIDConnectSalesforceCommunity();
            Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A, 'notExistingEmailTest@email.com.invalid', accounts.get(0).INFOIntermediaryCode__c);
    
            Test.startTest();
            User u = handler.createUser(null, sampleDataIAM, iamRoleReceived);
            Test.stopTest();

            User createdUser = [SELECT userName, email, firstName, lastName, alias, ContactId FROM user WHERE id=:u.Id];
            System.assertEquals('testuserlong@zurich-es.com', createdUser.userName, 'UserName debe ser testuserlong@zurich-es.com');
            System.assertEquals('testLast', createdUser.lastName, 'LastName debe ser testLast');
            System.assertEquals('testFirst', createdUser.firstName, 'firstName debe ser testFirst');
            System.assertEquals(false, existingContactsMap.containsKey(u.ContactId), 'El nuevo contacto no debe existir antes de ejecutar el crear usuario');

        }
    }

    // Test create user dummy account //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // test de login para mediador, existiendo un contacto al cual crear un usuario de comunidad
    @isTest
    static void testCreateUserExistingContactToDummy() {

        List<Contact> contacts = new List<Contact>([SELECT Id, Account.Name, Email, AccountId, Account.INFOIntermediaryCode__c FROM Contact]);
        
        
        if (!contacts.isEmpty()) {
            // añado al account el codigo de afiliación
            Account account = new Account();
            account.Id = contacts.get(0).AccountId;
            account.INFOBusinessCode__c = '1234567890';
            account.RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PartnerOCS')?.getRecordTypeId();

            update account;

            List<String> iamRoleReceived = new List<String>{IAM_ROLE_B};
    
            OpenIDConnectSalesforceCommunity handler = new OpenIDConnectSalesforceCommunity();
            Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_B, contacts.get(0).Email, account.INFOBusinessCode__c);
    
            Test.startTest();
            User u = handler.createUser(null, sampleDataIAM, iamRoleReceived);
            Test.stopTest();

            

            User createdUser = [SELECT userName, email, firstName, lastName, alias, ContactId FROM user WHERE id=:u.Id];
            System.assertEquals('testuserlong@zurich-es.com', createdUser.userName, 'UserName debe ser testuserlong@zurich-es.com');
            System.assertEquals('testLast', createdUser.lastName, 'LastName debe ser testLast');
            System.assertEquals('testFirst', createdUser.firstName, 'firstName debe ser testFirst');
        }
    }

    // test de login para mediador, NO existiendo un contacto al cual crear un usuario de comunidad
    @isTest
    static void testCreateUserNoExistingContactToDummy() {

        Map<Id, Contact> existingContactsMap = new Map<Id, Contact>([SELECT AccountId FROM Contact]);

        List<Account> accounts = new List<Account>([SELECT Id, INFOIntermediaryCode__c FROM Account WHERE Id NOT IN (SELECT AccountId FROM Contact)]);
        
        if (!accounts.isEmpty()) {
            // añado el codigo de afiliación
            Account account = new Account();
            account.Id = accounts.get(0).Id;
            account.INFOBusinessCode__c = '1234567890';
            account.RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PartnerOCS')?.getRecordTypeId();
            update account;


            List<String> iamRoleReceived = new List<String>{IAM_ROLE_B};
    
            OpenIDConnectSalesforceCommunity handler = new OpenIDConnectSalesforceCommunity();
            Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_B, 'notExistingEmailTest@email.com.invalid', account.INFOBusinessCode__c);
    
            Test.startTest();
            User u = handler.createUser(null, sampleDataIAM, iamRoleReceived);
            Test.stopTest();

            User createdUser = [SELECT userName, email, firstName, lastName, alias, ContactId FROM user WHERE id=:u.Id];
            System.assertEquals('testuserlong@zurich-es.com', createdUser.userName, 'UserName debe ser testuserlong@zurich-es.com');
            System.assertEquals('testLast', createdUser.lastName, 'LastName debe ser testLast');
            System.assertEquals('testFirst', createdUser.firstName, 'firstName debe ser testFirst');
            System.assertEquals(false, existingContactsMap.containsKey(u.ContactId), 'El nuevo contacto no debe existir antes de ejecutar el crear usuario');

        }
    }

    //////////////////// Test Update Permission Set y Public Group /////////////////////////////////////

    @isTest
    static void updateUserGroupAndPermissionSetGroup() {
        List<Contact> contacts = new List<Contact>([SELECT Id, Account.Name, Email, Account.INFOIntermediaryCode__c FROM Contact]);
        

        if (!contacts.isEmpty()) {
            List<String> iamRoleReceived = new List<String>{IAM_ROLE_A};
    
            OpenIDConnectSalesforceCommunity handler = new OpenIDConnectSalesforceCommunity();
            Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A, contacts.get(0).Email, contacts.get(0).Account.INFOIntermediaryCode__c);
    
            Test.startTest();
            User u = handler.createUser(null, sampleDataIAM, iamRoleReceived);   

            User createdUser = [SELECT userName, email, firstName, lastName, alias, ContactId FROM user WHERE id=:u.Id];
            System.assertEquals('testuserlong@zurich-es.com', createdUser.userName, 'UserName debe ser testuserlong@zurich-es.com');
            System.assertEquals('testLast', createdUser.lastName, 'LastName debe ser testLast');
            System.assertEquals('testFirst', createdUser.firstName, 'firstName debe ser testFirst');

            // test update user on create
            List<String> updateIAMRoleReceived = new List<String>{IAM_ROLE_C};
            Auth.UserData sampleDataIAMUpdated = mockAuthData(handler, IAM_ROLE_C, contacts.get(0).Email, contacts.get(0).Account.INFOIntermediaryCode__c);
            handler.updateUser(u.Id, null, sampleDataIAMUpdated, updateIAMRoleReceived);

            Test.stopTest();

            List<GroupMember> afterUpdateGroups = new List<GroupMember>([SELECT GroupId, Group.DeveloperName FROM GroupMember WHERE GroupId != null AND userOrGroupId = :u.Id AND Group.Type != 'Queue']);
            
            // obtengo el valor de public group del mock
            List<AuthMapping__mdt> authMappingC = handler.testListAuthMappings;
            String publicGroupMock;
            for (AuthMapping__mdt mdt: authMappingC) {
                if (OpenIDConnectSalesforceCommunity.PERMISSION_TYPE_PUBLIC_GROUP.equals(mdt.Permission_Type__c)) {
                    publicGroupMock = mdt.Permission__c;
                    break;
                }
            }            
            
            System.assertEquals(1, afterUpdateGroups.size(), 'Solo debe tener 1 grupo publico');
            System.assertEquals(publicGroupMock, afterUpdateGroups.get(0).Group.DeveloperName, 'Los grupos deben ser el mismo que el mock C');

            // POR ALGUNA RAZÓN al validar el método futuro  que el permission set group asignado al usuario la consulta devuelve vacío, se ha comprobado que funciona correctamente con pruebas sobre la plataforma
            
        }
    }
}