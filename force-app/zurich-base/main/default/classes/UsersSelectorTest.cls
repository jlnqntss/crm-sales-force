/**
 * @description       : Clase de test para la clase selectora del sobject User
 * @author            : aberuete
 * @group             :
 * @last modified on  : 10-24-2023
 * @last modified by  : aberuete
 **/
@isTest
private with sharing class UsersSelectorTest
{
    private static final string PROFILE_USP_USER = 'USP User';

    @TestSetup
    public static void createScenario()
    {
        List<Profile> profileRN = [SELECT Id FROM Profile WHERE Name = 'SDM RN'];
        List<User> usersRN = TestDataFactory.generateUsersByProfile(profileRN[0].Id, 5);

        for( Integer i=0; i < usersRN.size(); i++ )
        {
            usersRN[i].FirstName = 'testUser';
        }

        insert usersRN;
    }

    /**
     * Test del metodo que recupera los Usuarios por un conjunto de ids dado
     */
    @isTest
    static void test_findById ()
    {
        List<User> usersBefore = [Select id from User where name like '%testUser%'];

        Test.startTest();
        List<User> usersAfter = new UsersSelector().findById( new Map<Id,User>(usersBefore).keySet() );
        Test.stopTest();

        // Comprobamos el resultado
        System.assertEquals(usersAfter.size(), usersBefore.size(), 'El número de usuarios antes y después debería ser el mismo');
    }

     /**
     * Test del metodo que recupera los Usuarios por un conjunto de emails dado
     */
    @isTest
    static void test_findByEmails ()
    {
        List<User> usersBefore = [Select id,email from User where name like '%testUser%' limit 2];

        List<String> emailList = new List<String>();

        for (User user:usersBefore )
        {
            emailList.add(user.email);
        }

        Test.startTest();
        List<User> usersAfter = new UsersSelector().findByEmails(emailList);
        Test.stopTest();

        // Comprobamos el resultado
        System.assertEquals(usersAfter.size(), usersBefore.size(), 'El número de usuarios antes y después no es el mismo');
        System.assertEquals (2, usersAfter.size(), 'El número de usuarios devueltos no es correcto');
    }

    @isTest
    static void test_getUsersByName()
    {
        Test.startTest();
        List<String> nombresList = new List<String> {'Integrator'};
        Map<Id, User> userMap = ( new UsersSelector() ).getUsersByName(nombresList);
        Test.stopTest();

        System.assertEquals(1, userMap.size(), 'Debe haber 1 usuario en el mapa');
    }


    @isTest
    static void testFindUserByEmail()
    {

        List<User> userQuery = new List<User>([SELECT Id, Email FROM User LIMIT 1]);

        if ( !userQuery.isEmpty() )
        {
            User result = new UsersSelector().findUserByEmail(userQuery.get(0).Email);

            System.assertEquals(true, result != null, 'Debe encontrar resultado');

        }
    }

    @isTest
    static void testFindUserByCommunityNickname()
    {

        List<User> userQuery = new List<User>([SELECT Id, CommunityNickname FROM User WHERE IsActive = TRUE LIMIT 1]);

        if ( !userQuery.isEmpty() )
        {
            User result = new UsersSelector().findUserByCommunityNickname(userQuery.get(0).CommunityNickname);

            System.assertEquals(true, result != null, 'Debe encontrar resultado');

        }
    }


    @isTest
    static void testGetLoginUserToUpdate()
    {

        List<User> userQuery = new List<User>([SELECT Id, CommunityNickname FROM User WHERE IsActive = TRUE LIMIT 1]);

        if ( !userQuery.isEmpty() )
        {
            User result = new UsersSelector().getLoginUserToUpdate(userQuery.get(0).Id);

            System.assertEquals(true, result != null, 'Debe encontrar resultado');

        }
    }

    @isTest
    static void test_findByContactAccountId()
    {

        // Crear cuentas de clientes
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 3);
        insert accounts;

        // Crear contactos de clientes
        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(accounts, ContactsSelector.RT_NAME_CONTACT, 1);
        insert contacts;

        // Crear los usurios para recuperar
        List<User> userList = new List<User>();

        List<String> adminProfiles = new List<String> {'Administrador del sistema', 'System Administrator'};
        List<Boolean> activeStatus = new List<Boolean> {true};
        User adminUser = ( new UsersSelector() ).findByProfileName(adminProfiles, activeStatus, 1)[0];

        System.runAs (adminUser)
        {
            String portalProfile = [SELECT Id FROM Profile WHERE Name = 'Agente Ventas' LIMIT 1].Id;

            userList = TestDataFactory.generateUsersByProfile(portalProfile, 3);
            userList[0].ContactId = contacts[0].Id;
            userList[1].ContactId = contacts[1].Id;
            userList[2].ContactId = contacts[2].Id;

            insert userList;
        }

        Set<Id> contactAccountIds = new Set<Id>();

        for (Account u : accounts)
        {
            contactAccountIds.add(u.Id);
        }

        Test.startTest();
        List<User> userQuery = ( new UsersSelector() ).findByContactAccountId(contactAccountIds);
        Test.stopTest();

        System.assertEquals(userList.size(), userQuery.size(), 'No se ha encontrado el número esperado');
    }

    /**
     * @description Test que comprueba que se recupera un usuario a partir de su alias.
     * @author      jgallaga
     * @date        18/08/2023
     */
    @isTest
    static void test_findUsersByAlias_OK()
    {
        String testAlias = 'fiali';
        List<User> aliasesTestUsers = new List<User>();

        Profile testForProfile = [Select Id from Profile where name = 'Super User']; // Perfil de comunidad de agentes de Mi Agencia

        User aliasTestUser = new User(
            Username        = 'testFindAliasZurich1@zurich.com',
            Alias           = testAlias,
            Email           = 'testFindAlias@zurich.com',
            EmailEncodingKey ='UTF-8',
            Firstname       = 'Test',
            Lastname        = 'Find Alias',
            LanguageLocaleKey ='es',
            LocaleSidKey    = 'es',
            TimeZoneSidKey  = 'Europe/Madrid',
            ProfileId       = testForProfile.Id
        );

        User aliasTestUserNOT = new User(
            Username        = 'testFindAliasZurich2@zurich.com',
            Alias           = testAlias + 'not',
            Email           = 'testFindAlias@zurich.com',
            EmailEncodingKey ='UTF-8',
            Firstname       = 'Test',
            Lastname        = 'Find Alias',
            LanguageLocaleKey ='es',
            LocaleSidKey    = 'es',
            TimeZoneSidKey  = 'Europe/Madrid',
            ProfileId       = testForProfile.Id
        );

        aliasesTestUsers.add(aliasTestUser);
        aliasesTestUsers.add(aliasTestUserNOT);

        insert aliasesTestUsers;

        UsersSelector userSelection = new UsersSelector();

        Test.startTest();
        List<User> results = userSelection.findUsersByAlias(new List<String>{testAlias});
        Test.stopTest();

        Assert.isTrue(results.size() == 1, 'Se ha encontrado mas de un usuario con el alias de test');
        Assert.areEqual(testAlias, results.get(0).Alias, 'El alias del usuario recuperado no es el esperado');
    }

    @isTest
    static void test_findByProfileName()
    {

        List<String> adminProfiles = new List<String> {'Administrador del sistema', 'System Administrator'};

        Test.startTest();
        List<User> userQuery = ( new UsersSelector() ).findByProfileName(adminProfiles, null, null);
        Test.stopTest();

        System.assertEquals(true, userQuery != null, 'Debe encontrar uno');
    }

    /**
     * Test del método que devuelve los usuarios que son gestores activos
     * @author aberuete
     * @date 28/06/2024
     */
    @isTest
    private static void test_getUsersWithAgentActiveOrderByAssignedCases()
    {
        List<Profile> profileUsp= [SELECT Id FROM Profile WHERE Name =: PROFILE_USP_USER];
        List<User> userUsp = TestDataFactory.generateUsersByProfile(profileUsp[0].Id, 1);
        userUsp[0].ActiveAgent__c = true;
        userUsp[0].AssignedCases__c = 5;
        userUsp[0].Capacity__c = 10;
        insert userUsp;

        Test.startTest();
        List<User> usersWithAgentActive = new UsersSelector().selectUsersWithAgentActiveOrderByAssignedCases();
        Test.stopTest();

        Map<Id,User> mapUsersWithAgentActive = new Map<Id,User> (usersWithAgentActive);
        
        Assert.areEqual(5,mapUsersWithAgentActive.get(userUsp[0].id).AssignedCases__c,'El número de casos asignados no es correcto'); 
        Assert.areEqual(10,mapUsersWithAgentActive.get(userUsp[0].id).Capacity__c,'La capacidad no es correcta');
    }

    /**
     * Test del método que devuelve el número de usuarios con gestor activo y capacidad nula
     * @author aberuete
     * @date 28/06/2024
     */
    @isTest
    private static void test_getNumberOfUsersActiveWithInfiniteCapacity()
    {
        List<Profile> profileUsp= [SELECT Id FROM Profile WHERE Name =: PROFILE_USP_USER];
        List<User> userUsp = TestDataFactory.generateUsersByProfile(profileUsp[0].Id, 1);
        userUsp[0].ActiveAgent__c = true;
        userUsp[0].AssignedCases__c = 5;
        insert userUsp;

        Test.startTest();
        Integer numUsersWthInfiniteCapacity = new UsersSelector().selectNumberOfUsersActiveWithInfiniteCapacity();
        Test.stopTest();

        Assert.isTrue(numUsersWthInfiniteCapacity > 0, 'Debería de haber algun usuario con capacidad infinita');
    }
}