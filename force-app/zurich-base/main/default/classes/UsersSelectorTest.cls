/**
 * @description       : Clase de test para la clase selectora del sobject User
 * @author            : aberuete
 * @group             :
 * @last modified on  : 18/08/2023
 * @last modified by  : jgallaga
 **/
@isTest
private with sharing class UsersSelectorTest
{
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

}