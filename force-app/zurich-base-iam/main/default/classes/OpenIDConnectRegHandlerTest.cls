/**
 * @description       :
 * @author            : Enara Etxaniz
 * @group             :
 * @last modified on  : 01-02-2021
 * @last modified by  : nts (agonzalezisasi)
 * Modifications Log
 * Ver   Date         Author                Modification
 * 1.0   10-08-2020   Enara Etxaniz         Initial Version
 * 2.0   01-02-2021   nts (agonzalezisasi)  Refactorized the class for the new requirements
 *
 **/
@isTest
private class OpenIDConnectRegHandlerTest
{
    static final string IAM_ROLE_A = 'IAM_ROLE_A';
    static final string IAM_ROLE_B = 'IAM_ROLE_B';
    static final string IAM_ROLE_ADMIN = 'IAM_ROLE_ADMIN';
    static final string IAM_ROLE_A_NAME = 'TestRoleA';

    @TestSetup
    static void makeData()
    {
        // Create Groups
        List<Group> groups = new List<Group>();
        groups.add( new Group(Name='TestGroupA', DeveloperName='TestGroupA') );
        groups.add( new Group(Name='TestGroupB', DeveloperName='TestGroupB') );
        insert groups;

        // Create Permission Set Groups
        List<PermissionSetGroup> psGroups = new List<PermissionSetGroup>();
        psGroups.add( new PermissionSetGroup(
                          MasterLabel= 'TestPermissionSetGroupA',
                          DeveloperName= 'TestPermissionSetGroupA'
                          ) );
        psGroups.add( new PermissionSetGroup(
                          MasterLabel= 'TestPermissionSetGroupB',
                          DeveloperName= 'TestPermissionSetGroupB'
                          ) );
        insert psGroups;

        // Create Roles
        List<UserRole> roles = new List<UserRole>();
        roles.add( new UserRole(
                       Name= IAM_ROLE_A_NAME,
                       DeveloperName= IAM_ROLE_A_NAME
                       ) );
        insert roles;
    }

    /**
     * Creates the structure of Auth Data with the IAM roles
     *
     * @author nts (agonzalezisasi)
     * @date 01/02/2021
     * @param {string role_names} a list of roles separated by coma
     * @return {Auth.UserData} the auth user data structure
     */
    static Auth.UserData getSampleDataIAM(string role_names)
    {
        Auth.UserData sampleDataIAM = new Auth.UserData(
            'testId',
            'testFirst',
            'testLast',
            'testFirst testLast',
            'testuser@example.org',
            null,
            'testuserlong',
            UserInfo.getLocale(),
            'facebook',
            null,
            new Map<String, String> {});
        if( role_names != null )
            sampleDataIAM.attributeMap.put(
                OpenIDConnectRegHandler.AUTH_DATA_MAP_NAME,
                '{crm=[' + role_names + ']}'
                );

        return sampleDataIAM;
    }

    /**
     * Creates a list of AuthMapping__mdt to simulate the metadata configuration given a list of roles
     * separated by coma.
     *
     * @author nts (agonzalezisasi)
     * @date 01/02/2021
     * @param {OpenIdConnectRegHandler handler} reference to the object OpenIdConnectRegHandler
     * @param {string roles} the list of roles separated by coma
     * @return {Auth.UserData} the auth user data structure
     *
     */
    static Auth.UserData mockAuthData(OpenIDConnectRegHandler handler, string roles)
    {
        if( String.isBlank(roles) )
            throw new OpenIDConnectRegHandler.RegHandlerException('No role specified for the test');

        handler.testListAuthMappings = new List<AuthMapping__mdt>();

        // IAM_ROLE_A
        if( roles != null && roles.contains(IAM_ROLE_A) )
        {
            // PROFILES
            // Get one profile except admin
            List<Profile> profiles = [
                SELECT Id, Name FROM Profile
                WHERE Name NOT IN :OpenIDConnectRegHandler.SYS_ADMIN_TRANSLATIONS ORDER BY Name ASC
                LIMIT 1
            ];
            System.assertEquals(1, profiles.size(), 'There should be 1 profile');
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestProfile',
                                                  DeveloperName= 'TestProfile',
                                                  Role_Name__c= IAM_ROLE_A,
                                                  Permission__c= profiles[0].Name,
                                                  Permission_Type__c = OpenIDConnectRegHandler.PERMISSION_TYPE_PROFILE,
                                                  Order__c= 1
                                                  ) );

            // GROUPS
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestGroupA',
                                                  DeveloperName= 'TestGroupA',
                                                  Role_Name__c= IAM_ROLE_A,
                                                  Permission__c= 'TestGroupA',
                                                  Permission_Type__c = OpenIDConnectRegHandler.PERMISSION_TYPE_PUBLIC_GROUP,
                                                  Order__c= 1
                                                  ) );

            //PERMISSION SET GROUPS
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestPermissionSetGroupA',
                                                  DeveloperName= 'TestPermissionSetGroupA',
                                                  Role_Name__c= IAM_ROLE_A,
                                                  Permission__c= 'TestPermissionSetGroupA',
                                                  Permission_Type__c = OpenIDConnectRegHandler.PERMISSION_TYPE_PERMISSION_SET_GROUP,
                                                  Order__c= 1
                                                  ) );

            // Call Center
            List<CallCenter> callCenters = [SELECT Id, InternalName FROM CallCenter LIMIT 1];
            if( !callCenters.isEmpty() )
            {
                handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                      Label= 'TestCallCenter',
                                                      DeveloperName= 'TestCallCenter',
                                                      Role_Name__c= IAM_ROLE_A,
                                                      Permission__c= callCenters[0].InternalName,
                                                      Permission_Type__c = OpenIDConnectRegHandler.PERMISSION_TYPE_CALL_CENTER,
                                                      Order__c= 1
                                                      ) );
            }

            // Role
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= IAM_ROLE_A_NAME,
                                                  DeveloperName= IAM_ROLE_A_NAME,
                                                  Role_Name__c= IAM_ROLE_A,
                                                  Permission__c= IAM_ROLE_A_NAME,
                                                  Permission_Type__c = OpenIDConnectRegHandler.PERMISSION_TYPE_ROLE,
                                                  Order__c= 1
                                                  ) );

            // Department
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                Label= 'TestDeptA',
                                                DeveloperName= 'TestdeptA',
                                                Role_Name__c= IAM_ROLE_A,
                                                Permission__c= 'TestDeptA',
                                                Permission_Type__c = OpenIDConnectRegHandler.PERMISSION_TYPE_DEPARTMENT,
                                                Order__c= 1
                                                ) );
            
            // Signature
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                Label= 'TestSignaA',
                                                DeveloperName= 'TestSignaA',
                                                Role_Name__c= IAM_ROLE_A,
                                                Permission__c= 'TestSignaA',
                                                Permission_Type__c = OpenIDConnectRegHandler.PERMISSION_TYPE_SIGNATURE,
                                                Order__c= 1
                                                ) );

            // Title
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                Label= 'TestTitleA',
                                                DeveloperName= 'TestTitleA',
                                                Role_Name__c= IAM_ROLE_A,
                                                Permission__c= 'TestTitleA',
                                                Permission_Type__c = OpenIDConnectRegHandler.PERMISSION_TYPE_TITLE,
                                                Order__c= 1
                                                ) );
        }

        // ROLE_ADMIN - Must be first because in the select there is the order field
        if( roles != null && roles.contains(IAM_ROLE_ADMIN) )
        {
            // Profile Admin
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestProfileAdmin',
                                                  DeveloperName= 'TestProfileAdmin',
                                                  Role_Name__c= IAM_ROLE_ADMIN,
                                                  Permission__c= OpenIDConnectRegHandler.PROFILE_ADMIN,
                                                  Permission_Type__c = OpenIDConnectRegHandler.PERMISSION_TYPE_PROFILE,
                                                  Order__c= 0
                                                  ) );
        }

        // IAM_ROLE_B
        if( roles != null && roles.contains(IAM_ROLE_B) )
        {
            // PROFILES
            // Get one profile except admin
            List<Profile> profiles = [
                SELECT Id, Name FROM Profile
                WHERE Name NOT IN :OpenIDConnectRegHandler.SYS_ADMIN_TRANSLATIONS ORDER BY Name ASC
                LIMIT 1
            ];
            System.assertEquals(1, profiles.size(), 'There should be 1 profile');
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestProfileB',
                                                  DeveloperName= 'TestProfileB',
                                                  Role_Name__c= IAM_ROLE_B,
                                                  Permission__c= profiles[0].Name,
                                                  Permission_Type__c = OpenIDConnectRegHandler.PERMISSION_TYPE_PROFILE,
                                                  Order__c= 2
                                                  ) );
            // GROUPS
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestGroupB',
                                                  DeveloperName= 'TestGroupB',
                                                  Role_Name__c= IAM_ROLE_B,
                                                  Permission__c= 'TestGroupB',
                                                  Permission_Type__c = OpenIDConnectRegHandler.PERMISSION_TYPE_PUBLIC_GROUP,
                                                  Order__c= 2
                                                  ) );
            //PERMISSION SETS
            handler.testListAuthMappings.add( new AuthMapping__mdt(
                                                  Label= 'TestPermissionSetGroupB',
                                                  DeveloperName= 'TestPermissionSetGroupB',
                                                  Role_Name__c= IAM_ROLE_B,
                                                  Permission__c= 'TestPermissionSetGroupB',
                                                  Permission_Type__c = OpenIDConnectRegHandler.PERMISSION_TYPE_PERMISSION_SET_GROUP,
                                                  Order__c= 1
                                                  ) );
            // NO Call center
            // NO SF Role
            // NO Department
            // NO Signature
            // NO Title
        }

        // return de data structure from IAM
        return getSampleDataIAM(roles);
    }

    /**
     * @description Test de cración y actualización de usuario de manera exitosa loas datos de entrada se encuentran en Auth.UserData
     * Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl, attributeMap)
     * @author rpolvera
     * @date 05/06/2020
     */
    @isTest
    static void testCreateAndUpdateUser()
    {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A);

        Test.startTest();
        User u = handler.createUser(null, sampleDataIAM);
        Test.stopTest();

        User createdUser = [SELECT userName, email, firstName, lastName, alias FROM user WHERE id=:u.Id];
        System.assertEquals('testuserlong@zurich-es.com', createdUser.userName);
        System.assertEquals('testuser@example.org', createdUser.email);
        System.assertEquals('testLast', createdUser.lastName);
        System.assertEquals('testFirst', createdUser.firstName);

        // test update user on create
        handler.createUser(null, sampleDataIAM);
    }

    /**
     * @Description Se fuerza la excepción no informando el rol en los datos de entrada.
     * @author rpolvera
     * @date 05/06/2020
     */
    @isTest
    static void testFailCreateUserNoProfile()
    {
        try
        {
            Auth.UserData sampleDataIAM = getSampleDataIAM(null);
            OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();

            Test.startTest();
            User u = handler.createUser(null, sampleDataIAM);
            Test.stopTest();
        }
        catch (Exception e)
        {
            System.assertEquals( 'OpenIDConnectRegHandler.RegHandlerException', e.getTypeName() );
        }
    }

    /**
     * @Description Se fuerza la excepción, se informa un rol no válido en los datos de entrada.
     * @author rpolvera
     * @date 05/06/2020
     */
    @isTest
    static void testFailCreateUserNoValidProfile()
    {
        Auth.UserData sampleDataIAM = getSampleDataIAM('testFailProfile');

        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();

        Test.startTest();
        try
        {
            User u = handler.createUser(null, sampleDataIAM);
        }
        catch (Exception e)
        {
            System.assertEquals( 'OpenIDConnectRegHandler.RegHandlerException', e.getTypeName() );
        }
        Test.stopTest();
    }

    /**
     * Test creating a user with ROL A and then changing same data and to ROL B
     */
    @isTest
    static void testUpdateUser()
    {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();

        // Create User for Rol A
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A);
        User u = handler.createUser(null, sampleDataIAM);

        // Update User for Rol B
        sampleDataIAM = mockAuthData(handler, IAM_ROLE_B);
        sampleDataIAM.email = 'testnewuser@example.org';
        sampleDataIAM.username = 'testnewuserlong';

        Test.startTest();
        handler.updateUser(u.Id, null, sampleDataIAM);
        Test.stopTest();

        // Check the user info
        User updatedUser = [SELECT userName, email, firstName, lastName, alias, UserRoleId, CallCenterId FROM user WHERE id=:u.Id];
        System.assertEquals('testnewuserlong@zurich-es.com', updatedUser.userName);
        System.assertEquals('testnewuser@example.org', updatedUser.email);
        // Role
        System.assertEquals(null, updatedUser.UserRoleId, 'The UserRoleId should be null');
        // CallCenter
        System.assertEquals(null, updatedUser.CallCenterId, 'The CallCenterId should be null');

        // Create a list of group names
        List<string> groupNames = new List<string>();
        for(GroupMember gm: [SELECT groupId, group.developername FROM GroupMember WHERE userOrGroupId = :updatedUser.Id])
        {
            groupNames.add(gm.Group.developername);
        }
        // Check each group
        System.assertEquals( false, groupNames.contains('TestGroupA') );
        System.assertEquals( true, groupNames.contains('TestGroupB') );

        // Create a list of Permission Set Group names
        List<string> psgroupNames = new List<string>();
        for(PermissionSetAssignment psa: [SELECT PermissionSetGroupId, PermissionSetGroup.DeveloperName FROM PermissionSetAssignment WHERE AssigneeId = :updatedUser.Id])
        {
            psgroupNames.add(psa.PermissionSetGroup.DeveloperName);
        }
        // Check each group
        System.assertEquals( false, psgroupNames.contains('TestPermissionSetGroupA') );
        System.assertEquals( true, psgroupNames.contains('TestPermissionSetGroupB') );
    }

    /**
     * Test creation of a user with the Admin Profile and another profile to check if the Admin profile is selected
     */
    @isTest
    static void testCreateAdminMultiRole()
    {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A + ',' + IAM_ROLE_ADMIN);

        Test.startTest();
        User u = handler.createUser(null, sampleDataIAM);
        Test.stopTest();

        User createdUser = [SELECT userName, Profile.Name FROM user WHERE id=:u.Id];
        System.assertEquals( true, OpenIDConnectRegHandler.SYS_ADMIN_TRANSLATIONS.contains(createdUser.Profile.Name) );
    }

    /**
     * Test that with multiple ROLES from IAM, multiple Groups are asigned
     */
    @isTest
    static void testGroupsMultiRol()
    {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A + ',' + IAM_ROLE_B);

        Test.startTest();
        User u = handler.createUser(null, sampleDataIAM);
        Test.stopTest();

        // Check that the new created user has all the groups

        // Create a list of group names
        List<string> groupNames = new List<string>();
        for(GroupMember gm: [SELECT groupId, group.developername FROM GroupMember WHERE userOrGroupId = :u.Id])
        {
            groupNames.add(gm.Group.developername);
        }
        // Check each group
        System.assertEquals( true, groupNames.contains('TestGroupA') );
        System.assertEquals( true, groupNames.contains('TestGroupB') );
    }

    /**
     * Test the assignment of permission set groups with multiple roles
     *
     * @author nts (agonzalezisasi)
     * @date 28/01/2021
     */
    @isTest
    static void testPermissionSetGroupMultiRole()
    {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A + ',' + IAM_ROLE_B);

        Test.startTest();
        User u = handler.createUser(null, sampleDataIAM);
        Test.stopTest();

        // Get the list of group names
        List<string> groupNames = new List<string>();
        for(PermissionSetAssignment psa: [SELECT PermissionSetGroupId, PermissionSetGroup.DeveloperName FROM PermissionSetAssignment WHERE AssigneeId = :u.Id])
        {
            groupNames.add(psa.PermissionSetGroup.DeveloperName);
        }
        // Check each group
        System.assertEquals(true, groupNames.contains('TestPermissionSetGroupA'), 'The group A should be assigned');
        System.assertEquals(true, groupNames.contains('TestPermissionSetGroupB'), 'The group B should be assigned');
    }

    /**
     * Test the assignment of a CallCenter to the user
     *
     * @author nts (agonzalezisasi)
     * @date 28/01/2021
     */
    @isTest
    static void testCallCenter()
    {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A);

        Test.startTest();
        User u = handler.createUser(null, sampleDataIAM);
        Test.stopTest();

        User createdUser = [SELECT userName, CallCenterId FROM user WHERE id=:u.Id];
        // Commented because it may not exist and cant be created for testing in the setup method
        //System.assertNotEquals(null, createdUser.CallCenterId, 'The call center id should not be null');
    }

    /**
     * Test the assignment of a Department and signature to the user
     *
     * @author nts (agonzalezisasi)
     * @date 18/03/2021
     */
    @isTest
    static void testSignatureAndDept()
    {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A);

        handler.testSignatureContent = '{0} {1} Zurich Seguros';
        handler.testSignatureFields = 'firstname,lastname'; // list of User fields separated by comma and without spaces

        Test.startTest();
        User u = handler.createUser(null, sampleDataIAM);
        Test.stopTest();

        User createdUser = [SELECT userName, Department, Signature FROM user WHERE id=:u.Id];
        System.assertEquals('TestDeptA', createdUser.Department, 'The department of the user should be TestDeptA');
        System.assertEquals('testFirst testLast Zurich Seguros', createdUser.Signature, 'The signature is not correct');
    }

    /**
     * Test error in the assignment of a signature to the user
     *
     * @author nts (agonzalezisasi)
     * @date 18/03/2021
     */
    @isTest
    static void testSignature_ko()
    {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A);

        handler.testSignatureContent = '{0} {1} Zurich Seguros';
        handler.testSignatureFields = 'incorrectField'; // list of User fields separated by comma and without spaces

        String result = '';
        Test.startTest();
        try {
            User u = handler.createUser(null, sampleDataIAM);
        } catch( Exception ex ) {
            result = ex.getMessage();
        }
        Test.stopTest();

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        System.assertEquals(1, errors.size(), 'There should be 1 error log');
    }

    /**
     * Test that without IAM Role with Signature the field Signature of the user is empty in the creation
     *
     * @author nts (agonzalezisasi)
     * @date 25/03/2021
     */
    @isTest
    static void testSignatureNotCreated()
    {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_B);

        Test.startTest();
        User u = handler.createUser(null, sampleDataIAM);
        Test.stopTest();

        User createdUser = [SELECT Signature FROM user WHERE id=:u.Id];
        System.assertEquals(null, createdUser.Signature, 'The signature should be empty');
    }    

    /**
     * Test that with IAM Role with Signature if the configured signature change, the users signature change too
     *
     * @author nts (agonzalezisasi)
     * @date 03/04/2021
     */
    @isTest
    static void testSignatureUpdate()
    {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A);

        handler.testSignatureContent = '{0} {1} Zurich Seguros';
        handler.testSignatureFields = 'firstname,lastname'; // list of User fields separated by comma and without spaces

        Test.startTest();
        // Insert user with some signature content
        User u = handler.createUser(null, sampleDataIAM);

        // Update the configured signature content
        handler.testSignatureContent = 'Klinc seguros';
        handler.updateUser(u.Id, null, sampleDataIAM);
        Test.stopTest();

        User createdUser = [SELECT Signature FROM user WHERE id=:u.Id];
        System.assertEquals('Klinc seguros', createdUser.Signature, 'The signature should have changed');
    }  

    /**
     * Test that without IAM Role with Signature the field Signature of the user doesnt change in the update
     *
     * @author nts (agonzalezisasi)
     * @date 25/03/2021
     */
    @isTest
    static void testSignatureNotUpdated()
    {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_B);

        String textSignature = 'My signature';

        Test.startTest();
        User u = handler.createUser(null, sampleDataIAM);
        u.Signature = textSignature;
        update u;
        handler.updateUser(u.Id, null, sampleDataIAM);
        Test.stopTest();

        User createdUser = [SELECT Signature FROM user WHERE id=:u.Id];
        System.assertEquals(textSignature, createdUser.Signature, 'The signature should not change');
    }    

    
    /**
     * Test the assignment of a Title to the user
     *
     * @author nts (agonzalezisasi)
     * @date 09/04/2021
     */
    @isTest
    static void testTitleInsert()
    {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A);

        Test.startTest();
        User u = handler.createUser(null, sampleDataIAM);
        Test.stopTest();

        User createdUser = [SELECT userName, Title FROM user WHERE id=:u.Id];
        System.assertEquals('TestTitleA', createdUser.Title, 'The title of the user should be TestTitleA');
    }

    /**
     * Test the update of a Title to the user
     *
     * @author nts (agonzalezisasi)
     * @date 09/04/2021
     */
    @isTest
    static void testTitleUpdate()
    {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A);

        Test.startTest();
        User u = handler.createUser(null, sampleDataIAM);

        // Add a second title with higher order (put first in the list) so the process can find a change in the title
        handler.testListAuthMappings.add(0, new AuthMapping__mdt(
                                                Label= 'TestTitleA2',
                                                DeveloperName= 'TestTitleA2',
                                                Role_Name__c= IAM_ROLE_A,
                                                Permission__c= 'TestTitleA2',
                                                Permission_Type__c = OpenIDConnectRegHandler.PERMISSION_TYPE_TITLE,
                                                Order__c= 0
                                                ) );
        handler.updateUser(u.Id, null, sampleDataIAM);
        
        Test.stopTest();

        User updatedUser = [SELECT userName, Title FROM user WHERE id=:u.Id];
        System.assertEquals('TestTitleA2', updatedUser.Title, 'The title of the user should be TestTitleA2');
    }

    /**
     * Test the assignement of the AccountTeamMember for new users if they have the email in an Intermediry account
     * 
     * @author nts (agonzalezisasi)
     * @date 28/06/2021
     */
    @isTest
    static void testAssignAccountTeam_ok()
    {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A);

        handler.testATMSettings = new Map<String, String>();
        handler.testATMSettings.put('TerritoryManager', 'TerritoryManagerEmail__c');

        // Create another user to assign as AccountTeamMember
        User otherUser = null;
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'SDM RN'];
        if( !profiles.isEmpty() ) {
            List<User> otherUsers = TestDataFactory.generateUsersByProfile(profiles[0].Id, 1);
            insert otherUsers;
            otherUser = otherUsers[0];
        }

        // SDM, create intermediary account
        // Because of MIXED-DML error, we have to create the account this way
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            // Agrupation account creation
            List<Account> agrupations = TestDataFactory.generateAccounts('001', AccountsSelector.RT_NAME_AGRUPATION, 1);
            agrupations[0].NationalId__c = '77777';
            insert agrupations;

            // Intermediary account creation
            List<Account> intermediaries = TestDataFactory.generateAccounts('001', AccountsSelector.RT_NAME_INTERMEDIARY, 1);
            intermediaries[0].NationalId__c = '77777';
            intermediaries[0].TerritoryManagerEmail__c = sampleDataIAM.email;
            intermediaries[0].ParentId = agrupations[0].Id;
            insert intermediaries;
        }

        // Test user Creation
        Test.startTest();
        User u = handler.createUser(null, sampleDataIAM);
        Test.stopTest();

        // check if the account team member has been created
        List<AccountTeamMember> atms = [SELECT Id FROM AccountTeamMember WHERE UserId = :u.Id];
        System.assertEquals(false, atms.isEmpty(), 'There should be AccountTeamMembers');
        // 2 = 1 for the intermediary, 1 for the parent agrupation account
        System.assertEquals(2, atms.size(), 'There should be 2 AccountTeamMembers');
    }

    /**
     * Test the Error log creation when the assignement of the AccountTeamMember fails
     * 
     * @author nts (agonzalezisasi)
     * @date 28/06/2021
     */
    @isTest
    static void testAssignAccountTeam_ko()
    {
        OpenIDConnectRegHandler handler = new OpenIDConnectRegHandler();
        Auth.UserData sampleDataIAM = mockAuthData(handler, IAM_ROLE_A);

        // Set the settings incorrectly
        handler.testATMSettings = new Map<String, String>();
        handler.testATMSettings.put('TerritoryManagerA', 'InvalidField__c');

        Test.startTest();
        User u = handler.createUser(null, sampleDataIAM);
        Test.stopTest();

        // Check that the error log is being created
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c WHERE Source_Class__c = :OpenIDConnectRegHandler.CLASS_NAME];
        System.assertEquals(false, errorLogs.isEmpty(), 'There should be an error log');
    }
}
