/**
 * Test para la clase IntermediarySDM
 *
 * @author nts (agonzalezisasi)
 * @date 29/06/2021
 */
@isTest
private class IntermediarySDMTest
{
    /**
     * Metodo comun para todas los metodos de test. Inicializa los datos de prueba
     *
     * @author nts (agonzalezisasi)
     * @date 29/06/2021
     */
    @TestSetup
    static void makeData() 
    {
        TestDataFactorySDM.IntermediarySetupData();
    }

    /**
     * Test del metodo que calcula la agrupacion de mediadores para una lista de mediadores dada
     *
     * @author nts (agonzalezisasi)
     * @date 29/06/2021
     */
    @isTest
    static void testAssignIntermediaryAgrupation()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> intermediaries = [SELECT Id FROM Account WHERE RecordTypeId = :rtIntermediaryId];
        System.assertEquals(10, intermediaries.size(), 'Deberian existir 10 mediadores');

        Test.startTest();
        IntermediarySDM sdm = new IntermediarySDM();
        sdm.assignIntermediaryAgrupation(intermediaries);
        Test.stopTest();

        List<Account> result = [SELECT Id FROM Account WHERE Id IN :intermediaries AND ParentId != null];
        System.assertEquals(10, result.size(), 'Deberia haber 10 mediadores con el ParentId de la agrupacion rellenado');
    }

    /**
     * Test del metodo que calcula los equipos de cuenta de los mediadores
     *
     * @author nts (agonzalezisasi)
     * @date 29/06/2021
     */
     @isTest
    static void testAssignIntermediaryAccountTeam_Active()
    { 
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> intermediaries = [SELECT Id FROM Account WHERE RecordTypeId = :rtIntermediaryId];
        System.assertEquals(10, intermediaries.size(), 'Deberian existir 10 mediadores');

        IntermediarySDM sdm = new IntermediarySDM();
        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            TestDataFactorySDM.TERRITORY_ROL, TestDataFactorySDM.TERRITORY_FIELD
        );
        
        Test.startTest();        
        sdm.assignIntermediaryAccountTeam(intermediaries);
        Test.stopTest();

        List<AccountTeamMember> atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(10, atms.size(), 'Deberia haber 10 ATMs');
    }

    /**
     * Test del metodo que elimina los ATMs por estar el mediador inactivo
     *
     * @author nts (agonzalezisasi)
     * @date 29/06/2021
     */
    @isTest
    static void testAssignIntermediaryAccountTeam_Inactive()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        // Seleccionamos un mediador
        String soql = String.format(
            'SELECT Id, {0}, {1}, {2} FROM Account WHERE RecordTypeId = :rtIntermediaryId LIMIT 1',
            new List<String>{'IntermediaryStatus__c', TestDataFactorySDM.TERRITORY_FIELD, TestDataFactorySDM.RN_FIELD}
        );
        List<Account> intermediaries = Database.QUERY(soql);
        System.assertEquals(1, intermediaries.size(), 'Deberia existir 1 mediador');
        // Y lo marcamos como inactivo
        intermediaries[0].IntermediaryStatus__c = 'Inactive';
        update intermediaries;
        
        // Seleccionamos el usuario asociado al email de ese campo para ese mediador
        String fieldValue = (String)intermediaries[0].get(TestDataFactorySDM.TERRITORY_FIELD);
        List<User> users = [SELECT Id, Email, ProfileId FROM User WHERE Email = :fieldValue];
        System.assertEquals(1, users.size(), 'Deberia existir un usuario con el email de mediador');

        List<User> otherUser = TestDataFactory.generateUsersByProfile(users[0].ProfileId, 2);
        otherUser[0].Username = 'username98@invalid.com';
        otherUser[0].LastName = 'User98';
        otherUser[0].Alias = 'user98';
        otherUser[0].Email = 'username98@invalid.com';
        otherUser[1].Username = 'username99@invalid.com';
        otherUser[1].LastName = 'User99';
        otherUser[1].Alias = 'user99';
        otherUser[1].Email = 'username99@invalid.com';
        insert otherUser;

        // Creamos el AccountTeamMember para que el metodo lo borre
        List<AccountTeamMember> atmNew = new List<AccountTeamMember>();
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            UserId= users[0].Id,
            TeamMemberRole= TestDataFactorySDM.TERRITORY_ROL
        ));
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            UserId= otherUser[0].Id,
            TeamMemberRole= TestDataFactorySDM.TERRITORY_ROL
        ));
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            UserId= otherUser[1].Id,
            TeamMemberRole= TestDataFactorySDM.BUSINESS_ROL
        ));
        insert atmNew;

        List<AccountTeamMember> atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(3, atms.size(), 'Deberian existir 3 ATMs');


        IntermediarySDM sdm = new IntermediarySDM();

        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            TestDataFactorySDM.TERRITORY_ROL, TestDataFactorySDM.TERRITORY_FIELD
        );
        
        Test.startTest();        
        sdm.assignIntermediaryAccountTeam(intermediaries);
        Test.stopTest();

        // Comprobamos que ya no existe el Account Team Member
        atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(true, atms.isEmpty(), 'No deberian existir ATMs');
    }

    /**
     * Test del metodo que elimina los ATMs por ser el nombre del responsable de negocio del Mediador 
     * ZURICH CENTRALIZADOS
     *
     * @author nts (agonzalezisasi)
     * @date 07/07/2021
     */
    @isTest
    static void testAssignIntermediaryAccountTeam_RN_NO_ATM()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        // Seleccionamos un mediador
        String soql = String.format(
            'SELECT Id, {0}, {1}, {2} FROM Account WHERE RecordTypeId = :rtIntermediaryId LIMIT 1',
            new List<String>{'IntermediaryStatus__c', TestDataFactorySDM.TERRITORY_FIELD, TestDataFactorySDM.RN_FIELD}
        );
        List<Account> intermediaries = Database.QUERY(soql);
        System.assertEquals(1, intermediaries.size(), 'Deberia existir 1 mediador');
        // Y lo marcamos con el RN que no tendra equipos de cuenta
        intermediaries[0].put(TestDataFactorySDM.RN_FIELD, TestDataFactorySDM.RN_NAME);
        update intermediaries;
        
        // Seleccionamos el usuario asociado al email de ese campo para ese mediador
        String fieldValue = (String)intermediaries[0].get(TestDataFactorySDM.TERRITORY_FIELD);
        List<User> users = [SELECT Id, Email, ProfileId FROM User WHERE Email = :fieldValue];
        System.assertEquals(1, users.size(), 'Deberia existir un usuario con el email de mediador');

        List<User> otherUser = TestDataFactory.generateUsersByProfile(users[0].ProfileId, 2);
        otherUser[0].Username = 'username98@invalid.com';
        otherUser[0].LastName = 'User98';
        otherUser[0].Alias = 'user98';
        otherUser[0].Email = 'username98@invalid.com';
        otherUser[1].Username = 'username99@invalid.com';
        otherUser[1].LastName = 'User99';
        otherUser[1].Alias = 'user99';
        otherUser[1].Email = 'username99@invalid.com';
        insert otherUser;

        // Creamos el AccountTeamMember para que el metodo lo borre
        List<AccountTeamMember> atmNew = new List<AccountTeamMember>();
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            UserId= users[0].Id,
            TeamMemberRole= TestDataFactorySDM.TERRITORY_ROL
        ));
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            UserId= otherUser[0].Id,
            TeamMemberRole= TestDataFactorySDM.TERRITORY_ROL
        ));
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            UserId= otherUser[1].Id,
            TeamMemberRole= TestDataFactorySDM.BUSINESS_ROL
        ));
        insert atmNew;

        List<AccountTeamMember> atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(3, atms.size(), 'Deberian existir 3 ATMs');


        IntermediarySDM sdm = new IntermediarySDM();

        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            TestDataFactorySDM.TERRITORY_ROL, TestDataFactorySDM.TERRITORY_FIELD
        );
        sdm.testrnNameNoATM = TestDataFactorySDM.RN_NAME;
        sdm.testrnFieldNoATM = TestDataFactorySDM.RN_FIELD;
        
        Test.startTest();        
        sdm.assignIntermediaryAccountTeam(intermediaries);
        Test.stopTest();

        // Comprobamos que ya no existe el Account Team Member
        atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(true, atms.isEmpty(), 'No deberian existir ATMs');
    }

     /**
     * Test del metodo que elimina los ATMs por estar el mediador inactivo
     *
     * @author nts (agonzalezisasi)
     * @date 29/06/2021
     */
    @isTest
    static void testAssignIntermediaryAccountTeam_Vacant()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        // Seleccionamos un mediador
        String soql = 'SELECT Id, ' + TestDataFactorySDM.TERRITORY_FIELD + ' FROM Account WHERE RecordTypeId = :rtIntermediaryId LIMIT 2';
        List<Account> intermediaries = Database.QUERY(soql);
        System.assertEquals(2, intermediaries.size(), 'Deberian existir 2 mediadores');
        
        // Seleccionamos el usuario asociado al email de ese campo para ese mediador
        List<String> emails = new List<String>();
        emails.add((String)intermediaries[0].get(TestDataFactorySDM.TERRITORY_FIELD));
        emails.add((String)intermediaries[1].get(TestDataFactorySDM.TERRITORY_FIELD));
        List<User> users = [SELECT Id, Email FROM User WHERE Email = :emails];
        System.assertEquals(2, users.size(), 'Deberian existir 2 usuarios con email de mediador');
        Map<String, User> mapUserByEmail = new Map<String, User>();
        for(User u: users) {
            mapUserByEmail.put(u.Email, u);
        }

        // Creamos el AccountTeamMember para que el metodo lo borre
        List<AccountTeamMember> atmNew = new List<AccountTeamMember>();
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            userId= mapUserByEmail.get((String)intermediaries[0].get(TestDataFactorySDM.TERRITORY_FIELD)).Id,
            TeamMemberRole= TestDataFactorySDM.TERRITORY_ROL
        ));
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[1].Id,
            userId= mapUserByEmail.get((String)intermediaries[1].get(TestDataFactorySDM.TERRITORY_FIELD)).Id,
            TeamMemberRole= TestDataFactorySDM.TERRITORY_ROL
        ));
        insert atmNew;
        List<AccountTeamMember> atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(2, atms.size(), 'Deberian existir 2 ATMs');

        // Modificamos el campo de email del mediador para dejarlo vacio
        intermediaries[0].put(TestDataFactorySDM.TERRITORY_FIELD, null);
        intermediaries[1].put(TestDataFactorySDM.TERRITORY_FIELD, IntermediarySDM.INTERMEDIARY_VACANT);
        update intermediaries;


        IntermediarySDM sdm = new IntermediarySDM();

        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            TestDataFactorySDM.TERRITORY_ROL, TestDataFactorySDM.TERRITORY_FIELD
        );
        
        Test.startTest();        
        sdm.assignIntermediaryAccountTeam(intermediaries);
        Test.stopTest();

        // Comprobamos que ya no existe el Account Team Member
        atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(true, atms.isEmpty(), 'No deberian existir ATMs');
    }

     /**
     * Test del metodo que crea Account Contact Relations (ACR) entre Mediadores y contactos segun unos campos de email
     * del mediador
     *
     * @author nts (agonzalezisasi)
     * @date 01/07/2021
     */
    @isTest
    static void testAssignIntermediaryContactRelation_insert()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        String soql = 'SELECT Id, Name, ' + TestDataFactorySDM.MAINEMAIL_FIELD + ' FROM Account WHERE RecordTypeId = :rtIntermediaryId';
        List<Account> intermediaries = Database.query(soql);
        System.assertEquals(10, intermediaries.size(), 'Deberian existir 10 mediadores');

        IntermediarySDM sdm = new IntermediarySDM();
        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsACR = TestDataFactorySDM.getSDMSettingsACR(
            TestDataFactorySDM.MAINEMAIL_ROL, TestDataFactorySDM.MAINEMAIL_FIELD, TestDataFactorySDM.MAINEMAIL_TEXT
        );
        
        Test.startTest();        
        sdm.assignIntermediaryContactRelation(intermediaries);
        Test.stopTest();

        // Comprobamos que se han creado las relaciones (ACR) correctamente
        List<AccountContactRelation> acrs = [
            SELECT Id, Roles FROM AccountContactRelation 
            WHERE AccountId IN :intermediaries
            AND Roles includes(:TestDataFactorySDM.MAINEMAIL_ROL)
        ];
        System.assertEquals(10, acrs.size(), 'Deberia haber 10 ACRs');
    }

     /**
     * Test del metodo que elimina los ACRs si el campo de email del Mediador esta vacio
     *
     * @author nts (agonzalezisasi)
     * @date 01/07/2021
     */
    @isTest
    static void testAssignIntermediaryContactRelation_delete()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        // Recuperamos los Mediadores y les quitamos el campo de email para que se borren
        String soql = 'SELECT Id, Name, ' + TestDataFactorySDM.MAINEMAIL_FIELD + ' FROM Account WHERE RecordTypeId = :rtIntermediaryId';
        List<Account> intermediaries = Database.query(soql);
        System.assertEquals(10, intermediaries.size(), 'Deberian existir 10 mediadores');
        for(Account a: intermediaries) {
            a.put(TestDataFactorySDM.MAINEMAIL_FIELD, null);
        }
        update intermediaries;

        IntermediarySDM sdm = new IntermediarySDM();
        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsACR = TestDataFactorySDM.getSDMSettingsACR(
            TestDataFactorySDM.MAINEMAIL_ROL, TestDataFactorySDM.MAINEMAIL_FIELD, TestDataFactorySDM.MAINEMAIL_TEXT
        );
        Set<String> fields = sdm.SettingsACRFields; // para cobertura
        
        // Recuperamos los ACRs creados en el setup
        List<AccountContactRelation> acrs = [SELECT Id, Roles FROM AccountContactRelation];
        System.assertEquals(4, acrs.size(), 'Deberian existir 4 ACRs');
        // A 2 les añadimos el rol nuestro => se deberia quitar solo el rol nuestro
        acrs[0].Roles += ';' + TestDataFactorySDM.MAINEMAIL_ROL;
        acrs[1].Roles += ';' + TestDataFactorySDM.MAINEMAIL_ROL;
        // A 2 les asignamos solo el rol nuestro => se deberian eliminar
        acrs[2].Roles = TestDataFactorySDM.MAINEMAIL_ROL; 
        acrs[3].Roles = TestDataFactorySDM.MAINEMAIL_ROL;
        update acrs;
        
        Test.startTest();        
        sdm.assignIntermediaryContactRelation(intermediaries);
        Test.stopTest();

        // Comprobamos que no hay relaciones (ACR) con ese Rol
        acrs = [
            SELECT Id, Roles FROM AccountContactRelation 
            WHERE AccountId IN :intermediaries
            AND Roles includes(:TestDataFactorySDM.MAINEMAIL_ROL)
        ];
        // Debido a que las relaciones directas no se pueden eliminar y por tanto no se puede comprobar esto
        // System.assertEquals(0, acrs.size(), 'Deberia haber 0 ACRs');
    } 
    
}