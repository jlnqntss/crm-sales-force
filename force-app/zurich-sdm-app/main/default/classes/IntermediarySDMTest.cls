/**
 * Test para la clase IntermediarySDM
 *
 * @author nts (agonzalezisasi)
 * @date 29/06/2021
 */
@isTest
private with sharing class IntermediarySDMTest
{

    public static String queryString='SELECT Id, {0}, {1}, {2} FROM Account WHERE RecordTypeId = :rtIntermediaryId LIMIT 1';
    public static String unMediadorString='Deberia existir 1 mediador';
    public static String emailMediadorString='Deberia existir un usuario con el email de mediador';
    public static String tresATMString='Deberian existir 3 ATMs';
    public static String noATMString='No deberian existir ATMs';
    public static String user98String='username98@invalid.com';
    public static String user99String='username99@invalid.com';
    public static String diezMediadoresString='Deberian existir 10 mediadores';
    public static String usuariosNotificarString='Deberia haber usuarios a notificar';
    static final String RN_ROL = 'Responsable de Negocio';
    static final String NAME_CONTACT = 'Prueba principal';
    static final String EMAIL_CONTACT = 'principal@gmail.invalid';


    /**
     * Metodo comun para todas los metodos de test. Inicializa los datos de prueba
     *
     * @author nts (agonzalezisasi)
     * @date 29/06/2021
     */
    @TestSetup
    private static void makeData() 
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
    private static void testAssignIntermediaryAgrupation()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> intermediaries = [SELECT Id FROM Account WHERE RecordTypeId = :rtIntermediaryId];
        System.assertEquals(10, intermediaries.size(), diezMediadoresString);

        Test.startTest();
        IntermediarySDM sdm = new IntermediarySDM();
        sdm.assignIntermediaryAgrupation(intermediaries);
        Test.stopTest();

        List<Account> result = [SELECT Id FROM Account WHERE Id IN :intermediaries AND ParentId != null];
        System.assertEquals(10, result.size(), 'Deberia haber 10 mediadores con el ParentId de la agrupacion rellenado');
    }

    /**
     * Test del metodo que calcula la agrupacion de mediadores para una lista de mediadores dada
     * cuando la agrupacion no existe y se debe crear
     *
     * @author nts (agonzalezisasi)
     * @date 17/08/2021
     */
    @isTest
    private static void testAssignIntermediaryAgrupation_not_exist()
    {
        ID rtAgrupationId = new AccountsSelector().rtAgrupationId;
        List<Account> agrupations = [SELECT Id FROM Account WHERE RecordTypeId = :rtAgrupationId];
        System.assertEquals(false, agrupations.isEmpty(), 'Deberia haber agrupaciones de mediadores');
        delete agrupations;

        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> batch1 = [SELECT Id, NationalId__c FROM Account WHERE RecordTypeId = :rtIntermediaryId];
        System.assertEquals(10, batch1.size(), diezMediadoresString);
        // 0..3 mediadores con CIF 1111 -> ya lo tenian del setup
        // 4..6 mediadores con CIF 2222
        for(Integer i=4;i<7;i++) {
            batch1[i].NationalId__c = '2222';
        }
        // 7..9 mediadores con CIF 3333
        for(Integer i=7;i<10;i++) {
            batch1[i].NationalId__c = '3333';
        }
        update batch1;
        // Separamos los mediadores en 2 listas para simular 2 pases del batch
        // en el segundo pase no se deberian crear las agrupaciones porque ya existen
        List<Account> batch2 = new List<Account>();
        batch2.add(batch1[8]);
        batch2.add(batch1[9]);
        batch1.remove(9);
        batch1.remove(8);

        Test.startTest();
        IntermediarySDM sdm = new IntermediarySDM();
        sdm.assignIntermediaryAgrupation(batch1);
        sdm.assignIntermediaryAgrupation(batch2);
        Test.stopTest();

        // Reagrupamos los mediadores en una sola lista para comprobar los resultados
        batch1.addAll(batch2);

        List<Account> agrpResult = [SELECT Id FROM Account WHERE RecordTypeId = :rtAgrupationId];
        System.assertEquals(3, agrpResult.size(), 'Deberia haber 3 agrupaciones de mediadores');

        List<Account> result = [SELECT Id FROM Account WHERE Id IN :batch1 AND ParentId != null];
        System.assertEquals(10, result.size(), 'Deberia haber 10 mediadores con el ParentId de la agrupacion rellenado');
    }

    /**
    * @description Método que comprueba que el estado de la Agrupación de Mediadores es 'Active'
    * cuando alguno de sus Mediadores tienen el estado como 'Active'.
    * @author amiranda 
    * @date 30-01-2023 
    **/
    @isTest
    private static void testAssignIntermediaryAgrupation_set_status_activated()
    {
        ID rtAgrupationId = new AccountsSelector().rtAgrupationId;
        List<Account> agrupations = [SELECT Id, NationalId__c FROM Account WHERE RecordTypeId = :rtAgrupationId LIMIT 1];
        System.assertEquals(1, agrupations.size(), 'Deberia haber 1 Agrupación de Mediadores.');

        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> mediadores = [SELECT Id, Status__c FROM Account WHERE RecordTypeId = :rtIntermediaryId AND NationalId__c = :agrupations.get(0).NationalId__c];
        System.assert(!mediadores.isEmpty(), 'Deberian existir Mediadores.');

        for (Account mediador : mediadores)
        {
            // Estado activo
            mediador.Status__c = '001';
        }

        update mediadores;

        Test.startTest();
        // Se activa la agrupación
        IntermediarySDM sdm = new IntermediarySDM();
        sdm.assignIntermediaryAgrupation(mediadores);
        Test.stopTest();

        agrupations = [SELECT Id, StatusIntermediary__c FROM Account WHERE RecordTypeId = :rtAgrupationId AND Id = : agrupations.get(0).Id];
        System.assertEquals('Active', agrupations.get(0).StatusIntermediary__c, 'El estado de la Agrupación debería ser \'Active\'');
    }

    /**
    * @description Método que comprueba que el estado de la Agrupación de Mediadores es 'Inactive'
    * cuando todos sus Mediadores tienen el estado como 'Inactive'.
    * @author amiranda
    * @date 30-01-2023 
    **/
    @isTest
    private static void testAssignIntermeidaryAgrupation_set_status_inactive()
    {
        ID rtAgrupationId = new AccountsSelector().rtAgrupationId;
        List<Account> agrupations = [SELECT Id, NationalId__c FROM Account WHERE RecordTypeId = :rtAgrupationId LIMIT 1];
        System.assertEquals(1, agrupations.size(), 'Deberia haber 1 Agrupación de Mediadores.');

        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> mediadores = [SELECT Id, Status__c FROM Account WHERE RecordTypeId = :rtIntermediaryId AND NationalId__c = :agrupations.get(0).NationalId__c];
        System.assert(!mediadores.isEmpty(), 'Deberian existir Mediadores.');

        for (Account mediador : mediadores)
        {
            // Estado activo
            mediador.Status__c = '001';
        }

        update mediadores;

        // Se activa la agrupación
        IntermediarySDM sdm = new IntermediarySDM();
        sdm.assignIntermediaryAgrupation(mediadores);

        agrupations = [SELECT Id, StatusIntermediary__c FROM Account WHERE RecordTypeId = :rtAgrupationId AND Id = : agrupations.get(0).Id];
        System.assertEquals('Active', agrupations.get(0).StatusIntermediary__c, 'El estado de la Agrupación debería ser \'Active\'');

        for (Account mediador : mediadores)
        {
            // Estado inactivo
            mediador.Status__c = '003';
        }

        update mediadores;

        Test.startTest();
        // Se desactiva la agrupación
        sdm.assignIntermediaryAgrupation(mediadores);
        Test.stopTest();

        agrupations = [SELECT Id, StatusIntermediary__c FROM Account WHERE RecordTypeId = :rtAgrupationId AND Id = : agrupations.get(0).Id];
        System.assertEquals('Inactive', agrupations.get(0).StatusIntermediary__c, 'El estado de la Agrupación debería ser \'Inactive\'');        
    }

    /**
     * Test del metodo que calcula el Equipo de Cuenta (ATM) de la agrupacion de mediadores
     *
     * @author nts (agonzalezisasi)
     * @date 18/08/2021
     */
    @isTest
    private static void testAssignAgrupationAccountTeam()
    {
        ID rtAgrupationId = new AccountsSelector().rtAgrupationId;
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> intermediaries = [SELECT Id, NationalID__c FROM Account WHERE RecordTypeId = :rtIntermediaryId];
        System.assertEquals(10, intermediaries.size(), diezMediadoresString);
        // 0..3 mediadores con CIF 1111 -> ya esta definido en el setup
        // 4..6 mediadores con CIF 2222
        for(Integer i=4;i<7;i++) {
            intermediaries[i].NationalId__c = '2222';
        }
        // 7..9 mediadores con CIF 3333
        for(Integer i=7;i<10;i++) {
            intermediaries[i].NationalId__c = '3333';
        }
        update intermediaries;

        // Esta es la lista de CIFs para la prueba
        Set<String> nationalIDs = new Set<String>{'1111','2222','3333'};

        Test.startTest();

        // PRUEBA 1: insertar ATMs
        IntermediarySDM sdm = new IntermediarySDM();
        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            SettingsSDM.ATM_ROL_TERRITORY, AccountsSelector.SDM_DT_EMAIL_FIELD,AccountsSelector.SDM_DT_NAME_FIELD
        );
        // Se crean las agrupaciones si no existen
        sdm.assignIntermediaryAgrupation(intermediaries);
        // Se crean los ATMs de los mediadores
        sdm.assignIntermediaryAccountTeam(intermediaries);
        
        // Se crean los ATMs para la agrupacion
        sdm.assignAgrupationAccountTeam(nationalIDs);

        // Resultado: comprobamos que se han creado los ATMs de los mediadores para las agrupaciones
        List<AccountTeamMember> atmsIntermediary = [
            SELECT Id FROM AccountTeamMember WHERE Account.RecordTypeId = :rtIntermediaryId
        ];
        System.assertEquals(10, atmsIntermediary.size(), 'Deberia haber 10 atms para los intermediarios');

        // PRUEBA 2: borrar ATMs
        // Quitamos algunos ATMs de los mediadores
        intermediaries[3].put(AccountsSelector.SDM_DT_EMAIL_FIELD, null);
        intermediaries[5].put(AccountsSelector.SDM_DT_EMAIL_FIELD, null);
        intermediaries[7].put(AccountsSelector.SDM_DT_EMAIL_FIELD, null);
        update intermediaries;
        sdm.assignIntermediaryAccountTeam(intermediaries);
        // comprobamos que han desaparecido los ATMs de los mediadores
        atmsIntermediary = [
            SELECT Id FROM AccountTeamMember WHERE Account.RecordTypeId = :rtIntermediaryId
        ];
        System.assertEquals(7, atmsIntermediary.size(), 'Deberia haber 7 atms para los intermediarios');
        // pero que siguen existiendo los ATMs de las agrupaciones
        List<AccountTeamMember> atmsAgrupation = [
            SELECT Id FROM AccountTeamMember WHERE Account.RecordTypeId = :rtAgrupationId
        ];
        System.assertEquals(10, atmsAgrupation.size(), 'Deberia haber 10 atms para las agrupaciones');

        // Probamos a asignar los ATMs de las agrupaciones para ver si se borran los ATMs
        sdm.assignAgrupationAccountTeam(nationalIDs);
        Test.stopTest();

        // Resultado: comprobamos que ahora ya solo hay 7 ATMs para las agrupaciones tambien
        List<AccountTeamMember> atms = [
            SELECT Id FROM AccountTeamMember WHERE Account.RecordTypeId = :rtAgrupationId
        ];
        // 10 usuarios para 10 mediadores con 3 agrupaciones
        System.assertEquals(7, atms.size(), 'Deberia haber 7 atms de agrupacion');

        // Comprobamos las notificaciones a usuarios
        System.assertNotEquals(null, sdm.listUserIdsToNotify, usuariosNotificarString);
        System.assertEquals(10, sdm.listUserIdsToNotify.size(), 'Deberia haber 10 usuarios a notificar');
    }

    /**
     * Test del metodo que calcula los equipos de cuenta de los mediadores
     *
     * @author nts (agonzalezisasi)
     * @date 29/06/2021
     */
     @isTest
    private static void testAssignIntermediaryAccountTeam_Active()
    { 
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> intermediaries = [SELECT Id FROM Account WHERE RecordTypeId = :rtIntermediaryId];
        System.assertEquals(10, intermediaries.size(), diezMediadoresString);

        IntermediarySDM sdm = new IntermediarySDM();
        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            SettingsSDM.ATM_ROL_TERRITORY, AccountsSelector.SDM_DT_EMAIL_FIELD,AccountsSelector.SDM_DT_NAME_FIELD
        );
        
        Test.startTest();        
        sdm.assignIntermediaryAccountTeam(intermediaries);
        Test.stopTest();

        List<AccountTeamMember> atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(10, atms.size(), 'Deberia haber 10 ATMs');

        // Comprobamos las notificaciones a usuarios
        System.assertNotEquals(null, sdm.listUserIdsToNotify,usuariosNotificarString);
        System.assertEquals(10, sdm.listUserIdsToNotify.size(), 'Deberia haber 10 usuarios a notificar');
    }

    /**
     * @description Método que comprueba que cuando el nuevo RN es un usuario inactivo,
     * no se crea un nuevo ATM para este usuario y se elimina el ATM que había en su rol.
     * Además se informa el campo 'InactiveOrInexistentUsers__c' con la información sobre el usuario inactivo.
     * @author amiranda
     * @date 22-12-2022
     **/
    @isTest
    private static void testAssignAgrupationAccountTeam_InactiveUser()
    {
        // Se recupera el Id del RecordType de cuentas de tipo Mediador
        Id rtIntermediaryId = new AccountsSelector().rtIntermediaryId;

        // Se recuperan todos los mediadores
        List<Account> intermediaries = [SELECT Id FROM Account WHERE RecordTypeId = :rtIntermediaryId];
        Assert.isFalse(intermediaries.isEmpty(), 'Debería existir al menos un intermediario.');

        // Se recupera el Id del perfil RN
        Profile rnProfile = [SELECT Id FROM Profile WHERE Name = :TestDataFactorySDM.RN_PROFILE LIMIT 1];
        Assert.isNotNull(rnProfile, 'El perfil SDM RN deberia existir.');

        // Se crean dos usuarios para el perfil RN
        List<User> users = TestDataFactory.generateUsersByProfile(rnProfile.Id, 2);
        Assert.areEqual(2, users.size(), 'Deberían haberse creado dos usuarios.');
        users[0].Username = user98String;
        users[0].LastName = 'User98';
        users[0].Alias = 'user98';
        users[0].Email = user98String;
        users[1].Username = user99String;
        users[1].LastName = 'User99';
        users[1].Alias = 'user99';
        users[1].Email = user99String;

        /* El segundo usuario se inactiva para que al modificar el mediador con el usuario inactivo,
         * se eliminen los ATMs del rol del usuario inactivo.
         */
        users[1].IsActive = false;
        insert users;

        IntermediarySDM sdm = new IntermediarySDM();
        String roleTerritoryLabel = sdm.settings.getATMRoleLabel(SettingsSDM.ATM_ROL_BUSINESS);
        List<AccountTeamMember> atms = new List<AccountTeamMember>();

        // Se añade el email del RN activo al mediador y se crean los ATMs.
        for (Integer index = 0; index < intermediaries.size(); index++)
        {
            intermediaries.get(index).put( AccountsSelector.SDM_RN_EMAIL_FIELD, users.get(0).Email);

            atms.add( new AccountTeamMember(
                          AccountId = intermediaries.get(index).Id,
                          UserId = users.get(0).Id,
                          TeamMemberRole = roleTerritoryLabel
                          ) );
        }

        update intermediaries;
        insert atms;

        atms = [SELECT Id FROM AccountTeamMember WHERE AccountId = :intermediaries];
        Assert.areEqual(intermediaries.size(), atms.size(), 'Deberían haberse creado ' + intermediaries.size() + ' intermediarios.');

        // Se modifica el email del RN, asignándole el del usuario inactivo.
        for (Account intermediary : intermediaries)
        {
            intermediary.put(AccountsSelector.SDM_RN_EMAIL_FIELD, users.get(1).Email);
        }

        update intermediaries;

        // Se prepara la configuracion para el campo que interesa.
        sdm.testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            SettingsSDM.ATM_ROL_BUSINESS, AccountsSelector.SDM_RN_EMAIL_FIELD,AccountsSelector.SDM_DT_NAME_FIELD
            );

        Test.startTest();
        sdm.assignIntermediaryAccountTeam(intermediaries);
        Test.stopTest();

        // Se comprueba si se han almacenado los datos del usuario inactivo en el campo correspondiente
        List<Account> intermediariesUpdated = [SELECT Id, InactiveOrNonExistentUsers__c FROM Account WHERE RecordTypeId = :rtIntermediaryId AND Id IN :intermediaries];
        for (Account intermediaryUpdated : intermediariesUpdated)
        {
            Assert.isTrue(intermediaryUpdated.InactiveOrNonExistentUsers__c.contains(users.get(1).Email + ' - inactivo'));
        }

        atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        Assert.isTrue(atms.isEmpty(), 'No deberían existir ATMs.');

        // Se comprueba las notificaciones del usuario que ha sido eliminado de los ATMs.
        Assert.isNotNull(sdm.listUserIdsToNotify, usuariosNotificarString);
        Assert.areEqual(1, sdm.listUserIdsToNotify.size(), 'Deberia haber 1 usuario a notificar.');
    }

    /**
     * @description Método que comprueba que cuando el nuevo RN es un usuario que no existe,
     * si hay un ATM para el rol de este usuario, se elimina.
     * @author amiranda
     * @date 22-12-2022
     **/
    @isTest
    private static void testAssignAgrupationAccountTeam_NonExistentUser()
    {
        String nonExistentUserEmail = 'nonexistentuser@invalid.com';

        // Se recupera el Id del RecordType de cuentas de tipo Mediador
        Id rtIntermediaryId = new AccountsSelector().rtIntermediaryId;

        // Se recuperan todos los mediadores
        List<Account> intermediaries = [SELECT Id FROM Account WHERE RecordTypeId = :rtIntermediaryId];
        Assert.isFalse(intermediaries.isEmpty(), 'Debería existir al menos un intermediario.');

        // Se recupera el Id del perfil RN
        Profile rnProfile = [SELECT Id FROM Profile WHERE Name = :TestDataFactorySDM.RN_PROFILE LIMIT 1];
        Assert.isNotNull(rnProfile, 'El perfil SDM RN deberia existir.');

        // Se crean dos usuarios para el perfil RN
        List<User> users = TestDataFactory.generateUsersByProfile(rnProfile.Id, 1);
        Assert.areEqual(1, users.size(), 'Deberían haberse creado dos usuarios.');
        users[0].Username = user98String;
        users[0].LastName = 'User98';
        users[0].Alias = 'user98';
        users[0].Email = user98String;

        insert users;

        IntermediarySDM sdm = new IntermediarySDM();
        String roleTerritoryLabel = sdm.settings.getATMRoleLabel(SettingsSDM.ATM_ROL_BUSINESS);
        List<AccountTeamMember> atms = new List<AccountTeamMember>();

        // Se añade el email del RN activo al mediador y se crean los ATMs.
        for (Integer index = 0; index < intermediaries.size(); index++)
        {
            intermediaries.get(index).put( AccountsSelector.SDM_RN_EMAIL_FIELD, users.get(0).Email);

            atms.add( new AccountTeamMember(
                          AccountId = intermediaries.get(index).Id,
                          UserId = users.get(0).Id,
                          TeamMemberRole = roleTerritoryLabel
                          ) );
        }

        update intermediaries;
        insert atms;

        atms = [SELECT Id FROM AccountTeamMember WHERE AccountId = :intermediaries];
        Assert.areEqual(intermediaries.size(), atms.size(), 'Deberían haberse creado ' + intermediaries.size() + ' intermediarios.');

        // Se modifica el email del RN, asignándole el de un usuario que no existe.
        for (Account intermediary : intermediaries)
        {
            intermediary.put(AccountsSelector.SDM_RN_EMAIL_FIELD, nonExistentUserEmail);
        }

        update intermediaries;

        // Se prepara la configuracion para el campo que interesa.
        sdm.testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            SettingsSDM.ATM_ROL_BUSINESS, AccountsSelector.SDM_RN_EMAIL_FIELD,AccountsSelector.SDM_DT_NAME_FIELD
            );

        Test.startTest();
        sdm.assignIntermediaryAccountTeam(intermediaries);
        Test.stopTest();

        // Se comprueba si se han almacenado los datos del usuario que no existe en el campo correspondiente
        List<Account> intermediariesUpdated = [SELECT Id, InactiveOrNonExistentUsers__c FROM Account WHERE RecordTypeId = :rtIntermediaryId AND Id IN :intermediaries];
        for (Account intermediaryUpdated : intermediariesUpdated)
        {
            Assert.isTrue(intermediaryUpdated.InactiveOrNonExistentUsers__c.contains(nonExistentUserEmail + ' - no existe'));
        }

        atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        Assert.isTrue(atms.isEmpty(), 'No deberían existir ATMs.');

        // Se comprueba las notificaciones del usuario que ha sido eliminado de los ATMs.
        Assert.isNotNull(sdm.listUserIdsToNotify, usuariosNotificarString);
        Assert.areEqual(1, sdm.listUserIdsToNotify.size(), 'Deberia haber 1 usuario a notificar.');
    }

    /**
     * Test del metodo que elimina los ATMs por estar el mediador inactivo
     *
     * @author nts (agonzalezisasi)
     * @date 29/06/2021
     */
    @isTest
    private static void testAssignIntermediaryAccountTeam_Inactive()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        // Seleccionamos un mediador
        String soql = String.format(
            queryString,
            new List<String>{'StatusIntermediary__c', AccountsSelector.SDM_DT_EMAIL_FIELD, TestDataFactorySDM.RN_FIELD}
        );
        List<Account> intermediaries = Database.QUERY(soql);
        System.assertEquals(1, intermediaries.size(), unMediadorString);
        // Y lo marcamos como inactivo (cualquier valor que no sea 001 o 002)
        intermediaries[0].Status__c = '003';
        update intermediaries;
        
        // Seleccionamos el usuario asociado al email de ese campo para ese mediador
        String fieldValue = (String)intermediaries[0].get(AccountsSelector.SDM_DT_EMAIL_FIELD);
        List<User> users = [SELECT Id, Email, ProfileId FROM User WHERE Email = :fieldValue];
        System.assertEquals(1, users.size(), emailMediadorString);

        List<User> otherUser = TestDataFactory.generateUsersByProfile(users[0].ProfileId, 2);
        otherUser[0].Username = user98String;
        otherUser[0].LastName = 'User98';
        otherUser[0].Alias = 'user98';
        otherUser[0].Email = user98String;
        otherUser[1].Username = user99String;
        otherUser[1].LastName = 'User99';
        otherUser[1].Alias = 'user99';
        otherUser[1].Email = user99String;
        insert otherUser;

        IntermediarySDM sdm = new IntermediarySDM();
        String roleTerritoryLabel = sdm.settings.getATMRoleLabel(SettingsSDM.ATM_ROL_TERRITORY);
        String roleBusinessLabel = sdm.settings.getATMRoleLabel(SettingsSDM.ATM_ROL_BUSINESS);

        // Creamos el AccountTeamMember para que el metodo lo borre
        List<AccountTeamMember> atmNew = new List<AccountTeamMember>();
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            UserId= users[0].Id,
            TeamMemberRole= roleTerritoryLabel
        ));
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            UserId= otherUser[0].Id,
            TeamMemberRole= roleTerritoryLabel
        ));
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            UserId= otherUser[1].Id,
            TeamMemberRole= roleBusinessLabel
        ));
        insert atmNew;

        List<AccountTeamMember> atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(3, atms.size(), tresATMString);


        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            SettingsSDM.ATM_ROL_TERRITORY, AccountsSelector.SDM_DT_EMAIL_FIELD,AccountsSelector.SDM_DT_NAME_FIELD
        );
        
        Test.startTest();        
        sdm.assignIntermediaryAccountTeam(intermediaries);
        Test.stopTest();

        // Comprobamos que ya no existe el Account Team Member
        atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(true, atms.isEmpty(), noATMString);

        // Comprobamos las notificaciones a usuarios
        System.assertNotEquals(null, sdm.listUserIdsToNotify,usuariosNotificarString);
        System.assertEquals(3, sdm.listUserIdsToNotify.size(), 'Deberia haber 3 usuarios a notificar');
    }

    /**
     * Test del metodo que elimina los ATMs por ser el nombre del responsable de negocio del Mediador 
     * ZURICH CENTRALIZADOS
     *
     * @author nts (agonzalezisasi)
     * @date 07/07/2021
     */
    @isTest
    private static void testAssignIntermediaryAccountTeam_RN_NO_ATM()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        // Seleccionamos un mediador
        String soql = String.format(
            queryString,
            new List<String>{'StatusIntermediary__c', AccountsSelector.SDM_DT_EMAIL_FIELD, TestDataFactorySDM.RN_FIELD}
        );
        List<Account> intermediaries = Database.QUERY(soql);
        System.assertEquals(1, intermediaries.size(), unMediadorString);
        // Y lo marcamos con el RN que no tendra equipos de cuenta
        intermediaries[0].put(TestDataFactorySDM.RN_FIELD, TestDataFactorySDM.RN_NAME);
        update intermediaries;
        
        // Seleccionamos el usuario asociado al email de ese campo para ese mediador
        String fieldValue = (String)intermediaries[0].get(AccountsSelector.SDM_DT_EMAIL_FIELD);
        List<User> users = [SELECT Id, Email, ProfileId FROM User WHERE Email = :fieldValue];
        System.assertEquals(1, users.size(), emailMediadorString);

        List<User> otherUser = TestDataFactory.generateUsersByProfile(users[0].ProfileId, 2);
        otherUser[0].Username = user98String;
        otherUser[0].LastName = 'User98';
        otherUser[0].Alias = 'user98';
        otherUser[0].Email = user98String;
        otherUser[1].Username = user99String;
        otherUser[1].LastName = 'User99';
        otherUser[1].Alias = 'user99';
        otherUser[1].Email = user99String;
        insert otherUser;

        IntermediarySDM sdm = new IntermediarySDM();
        String roleTerritoryLabel = sdm.settings.getATMRoleLabel(SettingsSDM.ATM_ROL_TERRITORY);
        String roleBusinessLabel = sdm.settings.getATMRoleLabel(SettingsSDM.ATM_ROL_BUSINESS);

        // Creamos el AccountTeamMember para que el metodo lo borre
        List<AccountTeamMember> atmNew = new List<AccountTeamMember>();
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            UserId= users[0].Id,
            TeamMemberRole= roleTerritoryLabel
        ));
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            UserId= otherUser[0].Id,
            TeamMemberRole= roleTerritoryLabel
        ));
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            UserId= otherUser[1].Id,
            TeamMemberRole= roleBusinessLabel
        ));
        insert atmNew;

        List<AccountTeamMember> atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(3, atms.size(), tresATMString);


        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            SettingsSDM.ATM_ROL_TERRITORY, AccountsSelector.SDM_DT_EMAIL_FIELD,AccountsSelector.SDM_DT_NAME_FIELD
        );
        sdm.testrnNameNoATM = TestDataFactorySDM.RN_NAME;
        sdm.testrnFieldNoATM = TestDataFactorySDM.RN_FIELD;
        
        Test.startTest();        
        sdm.assignIntermediaryAccountTeam(intermediaries);
        Test.stopTest();

        // Comprobamos que ya no existe el Account Team Member
        atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(true, atms.isEmpty(), noATMString);
    }

     /**
     * Test del metodo que elimina los ATMs por estar el mediador inactivo
     *
     * @author nts (agonzalezisasi)
     * @date 29/06/2021
     */
    @isTest
    private static void testAssignIntermediaryAccountTeam_Vacant()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        // Seleccionamos un mediador
        String soql = 'SELECT Id, ' + AccountsSelector.SDM_DT_EMAIL_FIELD + ' FROM Account WHERE RecordTypeId = :rtIntermediaryId LIMIT 2';
        List<Account> intermediaries = Database.QUERY(soql);
        System.assertEquals(2, intermediaries.size(), 'Deberian existir 2 mediadores');
        
        // Seleccionamos el usuario asociado al email de ese campo para ese mediador
        List<String> emails = new List<String>();
        emails.add((String)intermediaries[0].get(AccountsSelector.SDM_DT_EMAIL_FIELD));
        emails.add((String)intermediaries[1].get(AccountsSelector.SDM_DT_EMAIL_FIELD));
        List<User> users = [SELECT Id, Email FROM User WHERE Email = :emails];
        System.assertEquals(2, users.size(), 'Deberian existir 2 usuarios con email de mediador');
        Map<String, User> mapUserByEmail = new Map<String, User>();
        for(User u: users) {
            mapUserByEmail.put(u.Email, u);
        }

        IntermediarySDM sdm = new IntermediarySDM();

        // Recuperamos el nombre del rol del picklist de configuracion
        String roleLabel = sdm.settings.getATMRoleLabel(SettingsSDM.ATM_ROL_TERRITORY);

        // Creamos el AccountTeamMember para que el metodo lo borre
        List<AccountTeamMember> atmNew = new List<AccountTeamMember>();
        
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            userId= mapUserByEmail.get((String)intermediaries[0].get(AccountsSelector.SDM_DT_EMAIL_FIELD)).Id,
            TeamMemberRole= roleLabel
        ));
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[1].Id,
            userId= mapUserByEmail.get((String)intermediaries[1].get(AccountsSelector.SDM_DT_EMAIL_FIELD)).Id,
            TeamMemberRole= roleLabel
        ));
        insert atmNew;
        List<AccountTeamMember> atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(2, atms.size(), 'Deberian existir 2 ATMs');

        // Modificamos el campo de email del mediador para dejarlo vacio
        intermediaries[0].put(AccountsSelector.SDM_DT_EMAIL_FIELD, null);
        intermediaries[1].put(AccountsSelector.SDM_DT_EMAIL_FIELD, IntermediarySDM.INTERMEDIARY_VACANT);
        update intermediaries;


        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            SettingsSDM.ATM_ROL_TERRITORY, AccountsSelector.SDM_DT_EMAIL_FIELD,AccountsSelector.SDM_DT_NAME_FIELD
        );
        
        Test.startTest();        
        sdm.assignIntermediaryAccountTeam(intermediaries);
        Test.stopTest();

        // Comprobamos que ya no existe el Account Team Member
        atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(true, atms.isEmpty(), noATMString);
    }

     /**
     * Test del metodo que crea Account Contact Relations (ACR) entre Mediadores y contactos segun unos campos de email
     * del mediador
     *
     * @author nts (agonzalezisasi)
     * @date 01/07/2021
     */
    @isTest
    private static void testAssignIntermediaryContactRelation_insert()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        String soql = 'SELECT Id, Name, ' + AccountsSelector.SDM_MAINEMAIL_FIELD + ' FROM Account WHERE RecordTypeId = :rtIntermediaryId';
        List<Account> intermediaries = Database.query(soql);
        System.assertEquals(10, intermediaries.size(), diezMediadoresString);

        IntermediarySDM sdm = new IntermediarySDM();
        String roleLabelMain = sdm.settings.getACRRoleLabel(SettingsSDM.ACR_ROL_MAINEMAIL);
        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsACR = TestDataFactorySDM.getSDMSettingsACR(
            roleLabelMain, AccountsSelector.SDM_MAINEMAIL_FIELD, TestDataFactorySDM.MAINEMAIL_TEXT
        );
        
        Test.startTest();        
        sdm.assignIntermediaryContactRelation(intermediaries);
        Test.stopTest();

        // Comprobamos que se han creado las relaciones (ACR) correctamente
        List<AccountContactRelation> acrs = [
            SELECT Id, Roles FROM AccountContactRelation 
            WHERE AccountId IN :intermediaries
            AND Roles includes(:roleLabelMain)
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
    private static void testAssignIntermediaryContactRelation_delete()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        // Recuperamos los Mediadores y les quitamos el campo de email para que se borren
        String soql = 'SELECT Id, Name, ' + AccountsSelector.SDM_MAINEMAIL_FIELD + ' FROM Account WHERE RecordTypeId = :rtIntermediaryId';
        List<Account> intermediaries = Database.query(soql);
        System.assertEquals(10, intermediaries.size(), diezMediadoresString);
        for(Account a: intermediaries) {
            a.put(AccountsSelector.SDM_MAINEMAIL_FIELD, null);
        }
        update intermediaries;

        IntermediarySDM sdm = new IntermediarySDM();
        String roleLabelMain = sdm.settings.getACRRoleLabel(SettingsSDM.ACR_ROL_MAINEMAIL);
        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsACR = TestDataFactorySDM.getSDMSettingsACR(
            SettingsSDM.ACR_ROL_MAINEMAIL, AccountsSelector.SDM_MAINEMAIL_FIELD, TestDataFactorySDM.MAINEMAIL_TEXT
        );

         // Para cobertura de test
        Set<String> fields = sdm.SettingsACRFields;
        Assert.isFalse(fields.isEmpty());
        
        // Recuperamos los ACRs creados en el setup
        List<AccountContactRelation> acrs = [SELECT Id, Roles FROM AccountContactRelation];
        System.assertEquals(4, acrs.size(), 'Deberian existir 4 ACRs');
        // A 2 les añadimos el rol nuestro => se deberia quitar solo el rol nuestro
        acrs[0].Roles += ';' + roleLabelMain;
        acrs[1].Roles += ';' + roleLabelMain;
        // A 2 les asignamos solo el rol nuestro => se deberian eliminar
        acrs[2].Roles = roleLabelMain; 
        acrs[3].Roles = roleLabelMain;
        update acrs;
        
        Test.startTest();        
        sdm.assignIntermediaryContactRelation(intermediaries);
        Test.stopTest();

        // Comprobamos que no hay relaciones (ACR) con ese Rol
        acrs = [
            SELECT Id, Roles FROM AccountContactRelation 
            WHERE AccountId IN :intermediaries
            AND Roles includes(:roleLabelMain)
        ];
        // Debido a que las relaciones directas no se pueden eliminar y por tanto no se puede comprobar esto
        // System.assertEquals(0, acrs.size(), 'Deberia haber 0 ACRs');
    }

    /**
     * Test del metodo que comprueba si un contacto cambia de rol, 
     * la account contact relation de ese contacto cambia de rol correctamente
     *
     * @author aberuete
     * @date 07/11/2022
     */
    @isTest
    private static void testAssignIntermediaryContactRelation_changeRole()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        String soql = 'SELECT Id, Name,ClaimsEmail__c, ' + AccountsSelector.SDM_MAINEMAIL_FIELD + ' FROM Account WHERE RecordTypeId = :rtIntermediaryId limit 1 ';
        List<Account> intermediaries = Database.query(soql);
        intermediaries.get(0).ClaimsEmail__c = 'cto.siniestos@invalid.com';
        intermediaries.get(0).SubscriptionEmail__c = 'cto.contratacion@invalid.com';
        update intermediaries.get(0);
        IntermediarySDM sdm = new IntermediarySDM();       
        sdm.assignIntermediaryContactRelation(intermediaries);

        AccountContactRelation accountContactRelationFromSinistrosBeforeBatch = [select id,contactId,Roles from AccountContactRelation where accountid =: intermediaries.get(0).id and Roles = 'Siniestros'];
        Id contactIdFromSiniestrosBeforeBatch = accountContactRelationFromSinistrosBeforeBatch.contactId ; 
        AccountContactRelation accountContactRelationFromContratacionBeforeBatch = [select id,contactId,Roles from AccountContactRelation where accountid =: intermediaries.get(0).id and Roles = 'Contratacion'];
        Id contactIdFromContratacionBeforeBatch = accountContactRelationFromContratacionBeforeBatch.contactId ; 
        intermediaries.get(0).ClaimsEmail__c = 'cto.contratacion@invalid.com';
        intermediaries.get(0).SubscriptionEmail__c = 'cto.siniestos@invalid.com';
        update intermediaries.get(0);

        Test.startTest();       
        sdm.assignIntermediaryContactRelation(intermediaries);
        Test.stopTest();

        AccountContactRelation accountContactRelationFromSinistrosAfterBatch = [select id,contactId,Roles from AccountContactRelation where accountid =: intermediaries.get(0).id and Roles = 'Siniestros'];
        Id contactIdFromSiniestrosAfterBatch = accountContactRelationFromSinistrosAfterBatch.contactId ; 
        AccountContactRelation accountContactRelationFromContratacionAfterBatch = [select id,contactId,Roles from AccountContactRelation where accountid =: intermediaries.get(0).id and Roles = 'Contratacion'];
        Id contactIdFromContratacionAfterBatch = accountContactRelationFromContratacionAfterBatch.contactId ;

        System.assertEquals(contactIdFromSiniestrosBeforeBatch, contactIdFromContratacionAfterBatch, 'El contacto con rol siniestros deberia tener ahora el rol de contratacion');
        System.assertEquals(contactIdFromContratacionBeforeBatch, contactIdFromSiniestrosAfterBatch, 'El contacto con rol contratacion deberia tener ahora el rol de siniestros');
    }
    
    /**
     * Test del metodo que envia las notificaciones a los usuarios del cambio de visibilidad del mediador
     */
    @isTest
    private static void testSendNotification()
    {
        Test.startTest();
        IntermediarySDM sdm = new IntermediarySDM();
        sdm.sendNotification(new Set<Id>{UserInfo.getUserId()});
        Test.stopTest();
    }

    /**
     * Test del metodo que elimina los ATMs por estar el mediador inactivo
     *
     * @author nts (agonzalezisasi)
     * @date 29/06/2021
     */
    @isTest
    private static void testRemoveATMsForInactiveRoles()
    {
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        // Seleccionamos un mediador
        String soql = String.format(
            queryString,
            new List<String>{'StatusIntermediary__c', AccountsSelector.SDM_DT_EMAIL_FIELD, TestDataFactorySDM.RN_FIELD}
        );
        List<Account> intermediaries = Database.QUERY(soql);
        System.assertEquals(1, intermediaries.size(), unMediadorString);
        
        // Seleccionamos el usuario asociado al email de ese campo para ese mediador
        String fieldValue = (String)intermediaries[0].get(AccountsSelector.SDM_DT_EMAIL_FIELD);
        List<User> users = [SELECT Id, Email, ProfileId FROM User WHERE Email = :fieldValue];
        System.assertEquals(1, users.size(), emailMediadorString);

        List<User> otherUser = TestDataFactory.generateUsersByProfile(users[0].ProfileId, 2);
        otherUser[0].Username = user98String;
        otherUser[0].LastName = 'User98';
        otherUser[0].Alias = 'user98';
        otherUser[0].Email = user98String;
        otherUser[1].Username = user99String;
        otherUser[1].LastName = 'User99';
        otherUser[1].Alias = 'user99';
        otherUser[1].Email = user99String;
        insert otherUser;

        IntermediarySDM sdm = new IntermediarySDM();
        String roleTerritoryLabel = sdm.settings.getATMRoleLabel(SettingsSDM.ATM_ROL_TERRITORY);
        String roleBusinessLabel = sdm.settings.getATMRoleLabel(SettingsSDM.ATM_ROL_BUSINESS);

        // Creamos el AccountTeamMember para que el metodo lo borre
        List<AccountTeamMember> atmNew = new List<AccountTeamMember>();
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            UserId= users[0].Id,
            TeamMemberRole= roleTerritoryLabel
        ));
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            UserId= otherUser[0].Id,
            TeamMemberRole= roleTerritoryLabel
        ));
        atmNew.add(new AccountTeamMember(
            AccountId= intermediaries[0].Id,
            UserId= otherUser[1].Id,
            TeamMemberRole= roleBusinessLabel
        ));
        insert atmNew;

        List<AccountTeamMember> atms = [SELECT Id,TeamMemberRole FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(3, atms.size(), tresATMString);


        // Preparamos la configuracion para el campo que nos interesa
        sdm.testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            SettingsSDM.ATM_ROL_TERRITORY, AccountsSelector.SDM_DT_EMAIL_FIELD,AccountsSelector.SDM_DT_NAME_FIELD
        );
        
        sdm.testSettingsATM[0].Status__c = IntermediarySDM.ATM_ROL_STATUS_INACTIVE;
        
        Test.startTest();        
        sdm.removeATMsForInactiveRoles();
        Test.stopTest();

        // Comprobamos que queda un Account Team Member para el rol Business Manager
        atms = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :intermediaries];
        System.assertEquals(1, atms.size(), 'Deberia haber 1 ATM');

        // Comprobamos las notificaciones a usuarios
        System.assertNotEquals(null, sdm.listUserIdsToNotify, usuariosNotificarString);
        System.assertEquals(2, sdm.listUserIdsToNotify.size(), 'Deberia haber 2 usuarios a notificar');
    }

    /**
     * Test que comprueba que se generan correctamente los mapas de los miembros de cuentas
     *
     * @author aberuete
     * @date 05/04/2023
     */
    @isTest
    private static void testGenerateMapByATM()
    {
        IntermediarySDM sdm = new IntermediarySDM();
        sdm.mapExistingAgrupationUsers = new Map <String, Set<Id>> ();
        sdm.mapExistingATMsByNationalIdAndUserId = new Map<String, Map<Id, Id>> ();
        sdm.mapExistingIntermediaryUsers = new Map<String, Set<Id>> ();
        sdm.mapExistingInterATMsByNationalIdAndUserId = new Map<String, Map<Id, AccountTeamMember>> ();
        

        ID rtAgrupationId = new AccountsSelector().rtAgrupationId;
        Account accountAgrupation = [Select id,NationalId__c  from Account where RecordTypeId = :rtAgrupationId and NationalId__c!= null limit 1];
        
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        Account intermediaries = [SELECT Id,NationalId__c  FROM Account WHERE RecordTypeId = :rtIntermediaryId limit 1];

        List<User> userToATM = [Select id from User where isActive = true and profile.name = 'SDM RN' limit 2];
        
        //Crear atm para cuenta de agrupación 
        AccountTeamMember atmAgruptation = new AccountTeamMember(
            AccountId= accountAgrupation.Id,
            UserId= userToATM[0].Id,
            TeamMemberRole= RN_ROL,
            AccountAccessLevel= 'Edit',
            ContactAccessLevel= 'Read'
        );
        insert atmAgruptation;

        //Crear atm para cuenta de intermediario 
        AccountTeamMember atmIntermediary = new AccountTeamMember(
            AccountId= intermediaries.Id,
            UserId= userToATM[1].Id,
            TeamMemberRole= RN_ROL,
            AccountAccessLevel= 'Edit',
            ContactAccessLevel= 'Read'
        );
        insert atmIntermediary;

        AccountTeamMember getAtmAgrupation = [Select id,UserId, Account.NationalId__c, Account.RecordType.DeveloperName from AccountTeamMember where  Account.RecordTypeId =: rtAgrupationId limit 1];
        AccountTeamMember getAtmIntermediary = [Select id,UserId, Account.NationalId__c, Account.RecordType.DeveloperName from AccountTeamMember where  Account.RecordTypeId =: rtIntermediaryId limit 1];
        
        Test.startTest();
        sdm.generateMapByATM (getAtmAgrupation);
        sdm.generateMapByATM (getAtmIntermediary);
        Test.stopTest();

        List<String> nationalIds = new List<String>(sdm.mapExistingAgrupationUsers.keySet());
        List<Id> userIds = new List<Id>(sdm.mapExistingAgrupationUsers.values()[0]);
        List<String> nationalIds2map = new List<String>(sdm.mapExistingATMsByNationalIdAndUserId.keySet());
        List<Id> userIds2map = new List<Id>(sdm.mapExistingATMsByNationalIdAndUserId.values().get(0).keySet());

        List<String> nationalIds2 = new List<String>(sdm.mapExistingIntermediaryUsers.keySet());
        List<Id> userIds2 = new List<Id>(sdm.mapExistingIntermediaryUsers.values()[0]);
        List<String> nationalIds3map = new List<String>(sdm.mapExistingInterATMsByNationalIdAndUserId.keySet());
        List<Id> userIds3map = new List<Id>(sdm.mapExistingInterATMsByNationalIdAndUserId.values().get(0).keySet());


        System.assertEquals(accountAgrupation.NationalId__c, nationalIds[0],'El mapa mapExistingAgrupationUsers debería tener el nationalid de la cuenta de agrupación');
        System.assertEquals(userToATM[0].Id, userIds[0],'El mapa mapExistingAgrupationUsers debería tener el id de usuario ');
        System.assertEquals(accountAgrupation.NationalId__c, nationalIds2map[0],'El mapa debería mapExistingATMsByNationalIdAndUserId tener el nationalid de la cuenta de agrupación');
        System.assertEquals(userToATM[0].Id, userIds2map[0],'El mapa mapExistingATMsByNationalIdAndUserId debería tener el id de usuario');
        
        System.assertEquals(intermediaries.NationalId__c, nationalIds2[0],'El mapa mapExistingIntermediaryUsers debería tener el nationalid de la cuenta de agrupación');
        System.assertEquals(userToATM[1].Id, userIds2[0],'El mapa mapExistingIntermediaryUsers debería tener el id de usuario ');
        System.assertEquals(intermediaries.NationalId__c, nationalIds3map[0],'El mapa debería mapExistingInterATMsByNationalIdAndUserId tener el nationalid de la cuenta de agrupación');
        System.assertEquals(userToATM[1].Id, userIds3map[0],'El mapa mapExistingInterATMsByNationalIdAndUserId debería tener el id de usuario');
        
    }

     /**
     * Test que comprueba que se crean correctamente los miembros del equipo de cuentas de las cuentas de agrupación
     *
     * @author aberuete
     * @date 05/04/2023
     */
    @isTest
    private static void testforUserIfAtmAGRNotExistAndExistAtmIntermediaryCreate()
    {
        IntermediarySDM sdm = new IntermediarySDM();
        sdm.mapExistingAgrupationUsers = new Map <String, Set<Id>> ();
        sdm.mapExistingIntermediaryUsers = new Map<String, Set<Id>> ();
        sdm.mapExistingInterATMsByNationalIdAndUserId = new Map<String, Map<Id, AccountTeamMember>> ();
        sdm.atmsToCreate = new List<AccountTeamMember>();

        List<User> userToATM = [Select id from User where isActive = true and profile.name = 'SDM RN' limit 1];
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        Account intermediaries = [SELECT Id,NationalId__c,ParentId  FROM Account WHERE RecordTypeId = :rtIntermediaryId and NationalId__c != null limit 1];
        
        ID rtAgrupationId = new AccountsSelector().rtAgrupationId;
        Account accountAgrupation = [Select id,NationalId__c  from Account where RecordTypeId = :rtAgrupationId and NationalId__c != null limit 1];
        accountAgrupation.NationalId__c = intermediaries.NationalId__c;
        update accountAgrupation;

        intermediaries.ParentId = accountAgrupation.Id;
        update intermediaries; 

        AccountTeamMember atmIntermediary = new AccountTeamMember(
            AccountId= intermediaries.Id,
            UserId= userToATM[0].Id,
            TeamMemberRole= RN_ROL,
            AccountAccessLevel= 'Edit',
            ContactAccessLevel= 'Read'
        );
        insert atmIntermediary;
        
        AccountTeamMember getAtmIntermediary = [Select id,UserId, Account.NationalId__c,Account.ParentId,TeamMemberRole, Account.RecordType.DeveloperName from AccountTeamMember where  AccountId =:intermediaries.Id limit 1];

        Set<Id> usersIds = new Set<Id>{userToATM[0].Id};
        sdm.mapExistingIntermediaryUsers.put(intermediaries.NationalId__c, usersIds);
        Map<Id, AccountTeamMember> mapATMsByUserId = new Map<Id, AccountTeamMember>();
        mapATMsByUserId.put(userToATM[0].Id, getAtmIntermediary);
        sdm.mapExistingInterATMsByNationalIdAndUserId.put(intermediaries.NationalId__c, mapATMsByUserId);

        Test.startTest();
        sdm.forUserIfAtmAGRNotExistAndExistAtmIntermediaryCreate();
        Test.stopTest();

        System.assertEquals(accountAgrupation.Id, sdm.atmsToCreate[0].AccountId,'Se debería de haber creado un atm para la cuenta padre');
    }

     /**
     * Test que comprueba que se borran correctamente los miembros de los equipos de las cuentas de agrupación
     *
     * @author aberuete
     * @date 05/04/2023
     */
    @isTest
    private static void testifUsersLeftInAtmAgrRemoveATM()
    {
        IntermediarySDM sdm = new IntermediarySDM();
        sdm.mapExistingAgrupationUsers = new Map <String, Set<Id>> ();
        sdm.mapExistingATMsByNationalIdAndUserId = new Map<String, Map<Id, Id>> ();
        sdm.atmsToDeleteInAgr = new List<AccountTeamMember>();

        List<User> userToATM = [Select id from User where isActive = true and profile.name = 'SDM RN' limit 1];
        Set<Id> usersIds = new Set<Id>{userToATM[0].Id};

        ID rtAgrupationId = new AccountsSelector().rtAgrupationId;
        Account accountAgrupation = [Select id,NationalId__c  from Account where RecordTypeId = :rtAgrupationId and NationalId__c != null limit 1];

        AccountTeamMember atmAgruptation = new AccountTeamMember(
            AccountId= accountAgrupation.Id,
            UserId= userToATM[0].Id,
            TeamMemberRole= RN_ROL,
            AccountAccessLevel= 'Edit',
            ContactAccessLevel= 'Read'
        );
        insert atmAgruptation;

        sdm.mapExistingAgrupationUsers.put(accountAgrupation.NationalId__c, usersIds);
        Map<Id, Id> mapATMsByUserId =new Map<Id, Id>();
        mapATMsByUserId.put(userToATM[0].Id, atmAgruptation.Id); 
        sdm.mapExistingATMsByNationalIdAndUserId.put(accountAgrupation.NationalId__c, mapATMsByUserId);

        Test.startTest();
        sdm.ifUsersLeftInAtmAgrRemoveATM();
        Test.stopTest();

        System.assertEquals(atmAgruptation.id, sdm.atmsToDeleteInAgr[0].id, 'En el mapa de atms a borrar debería estar el atm de la cuenta de agrupación');
    }

     /**
     * Test que comprueba que se obtienen correctamente los emails de los mediadores
     *
     * @author aberuete
     * @date 13/04/2023
     */
    @isTest
    private static void testGetEmailsMediadores()
    {
        IntermediarySDM sdm = new IntermediarySDM();

        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> intermediaries = [SELECT id,MainEmail__c  FROM Account WHERE RecordTypeId = :rtIntermediaryId and MainEmail__c!= null ];
        Set<String> emailsFromQuery = new Set<String>();
        for (Account intermediary :intermediaries )
        {
            emailsFromQuery.add(intermediary.MainEmail__c);
        }
        
        Test.startTest();
        Set<String> emailMediadores = sdm.getEmailsMediadores(intermediaries);
        Test.stopTest();

        System.assertEquals(true, emailMediadores.equals(emailsFromQuery), 'Los emails de ambos conjuntos deben ser iguales');
    }

     /**
     * Test que comprueba que se crea correctamente el contacto si no existe
     *
     * @author aberuete
     * @date 13/04/2023
     */
    @isTest
    private static void testIfContactNotExistCreate()
    {
        IntermediarySDM sdm = new IntermediarySDM();
        Contact contact = null; 
        SDMAccountContactRelation__mdt rel = [Select id,IntermediaryField__c,Role__c,NameText__c from SDMAccountContactRelation__mdt where Label = 'Main' limit 1];
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        Account intermediary = [SELECT Id,Name,MainEmail__c,MainMobilePhone__c FROM Account WHERE RecordTypeId = :rtIntermediaryId and MainEmail__c!= null limit 1 ];
        intermediary.MainMobilePhone__c = '698042331';
        update intermediary;
        Map<String, Object> fieldsToValue = intermediary.getPopulatedFieldsAsMap();
        String fieldValue = String.valueOf(fieldsToValue.get(rel.IntermediaryField__c));
        String roleLabel ='Principal';
        Map<String, AccountContactRelation> mapACRsByRoles = new Map<String, AccountContactRelation> ();
        AccountContactRelation acrForRol = mapACRsByRoles?.get(roleLabel);
        sdm.mapContactPositionByEmail = new Map<String, Integer>();
        sdm.position = 0;
        sdm.mapContactsToInsert = new Map<Integer, Contact>();
        sdm.mapRolesForContacts = new Map<Integer, List<String>>();

        Test.startTest();
        sdm.ifContactNotExistCreate (contact, rel, intermediary, fieldValue, fieldsToValue, acrForRol, roleLabel );
        Test.stopTest();

        
        System.assertEquals(new Set<Integer>{0}, sdm.mapContactsToInsert.keySet(), 'El contacto debería estar en la posición 0');
        System.assertEquals(intermediary.Id, sdm.mapContactsToInsert.values()[0].AccountId, 'El contacto debería estar asociado a la cuenta de intermediario');
        System.assertEquals(new Set<String>{intermediary.MainEmail__c}, sdm.mapContactPositionByEmail.keySet(), 'El email debería estar en el mapa de contactos por email y posición');
        System.assertEquals(roleLabel, sdm.mapRolesForContacts.values()[0][0], 'El rol debería estar en el mapa de contactos por rol y posición');
    }

    /**
     * Test que comprueba que si no existe una relación entre la cuenta y el contacto se crea correctamente
     *
     * @author aberuete
     * @date 13/04/2023
     */
    @isTest
    private static void testIfContactExistCheckRelationWithAccount()
    {
        IntermediarySDM sdm = new IntermediarySDM();
        sdm.mapNewACRsByAccountAndContactIds = new Map<Id, Map<Id, AccountContactRelation>>();
        sdm.acrsToUpsert = new List<AccountContactRelation> ();
        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        Account intermediary = [SELECT Id,Name,MainEmail__c FROM Account WHERE RecordTypeId = :rtIntermediaryId and MainEmail__c!= null limit 1 ];

        Contact newContact = new Contact(
            AccountId= intermediary.Id,
            LastName= NAME_CONTACT,
            RecordTypeId= new ContactsSelector().rtContactId,
            Email= EMAIL_CONTACT
        );

        insert newContact;

        String roleLabel ='Principal';
        Map<String, AccountContactRelation> mapACRsByRoles = new Map<String, AccountContactRelation> ();
        AccountContactRelation acrForRol = mapACRsByRoles?.get(roleLabel);
        Map<ID, AccountContactRelation> mapACRsByContact = new Map<ID, AccountContactRelation> ();

        Test.startTest();
        sdm.ifContactExistCheckRelationWithAccount (newContact,intermediary,acrForRol, mapACRsByContact,roleLabel);
        Test.stopTest();

        System.assertEquals(intermediary.Id, sdm.acrsToUpsert[0].AccountId, 'Debería haber una relación para crearse para la cuenta de intermediario');
        System.assertEquals(newContact.Id, sdm.acrsToUpsert[0].ContactId, 'Debería haber una relación para crearse para el contacto ');
        System.assertEquals(new Set<Id>{intermediary.Id}, sdm.mapNewACRsByAccountAndContactIds.keySet(), 'Debería estar la cuenta en el mapa de nuevos acrs ');
        System.assertEquals(new Set<Id>{newContact.Id}, sdm.mapNewACRsByAccountAndContactIds.values()[0].keySet(), 'Debería estar el contacto en el mapa de nuevos acrs');
    }

    /**
     * Test que comprueba que si existe una relación entre la cuenta y contacto y no debería existe la relación se borra correctamente
     *
     * @author aberuete
     * @date 13/04/2023
     */
    @isTest
    private static void testCheckACRSToDelete()
    {
        IntermediarySDM sdm = new IntermediarySDM();
        sdm.acrsToDelete = new List<AccountContactRelation> ();
        sdm.acrsToUpsert = new List<AccountContactRelation> ();

        String roleLabel ='Principal';
        Map<ID, AccountContactRelation> mapACRsByContact = new Map<ID, AccountContactRelation>();

        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> intermediary = [SELECT Id,Name,MainEmail__c FROM Account WHERE RecordTypeId = :rtIntermediaryId limit 2 ];

        Contact newContact = new Contact(
            AccountId= intermediary[0].Id,
            LastName= NAME_CONTACT,
            RecordTypeId= new ContactsSelector().rtContactId,
            Email= EMAIL_CONTACT
        );
        insert newContact;
        
        AccountContactRelation acrNew = new AccountContactRelation(
            AccountId= intermediary[1].Id,
            ContactId= newContact.Id,
            IsActive= true,
            Roles = 'Principal'
        );
        insert acrNew;

        sdm.acrToDelete = acrNew;
        sdm.acrsToUpsert.add(acrNew);
        mapACRsByContact.put(newContact.Id, acrNew);

        Test.startTest();
        mapACRsByContact = sdm.checkACRSToDelete(roleLabel,mapACRsByContact);
        Test.stopTest();

        System.assertEquals(true, mapACRsByContact.isEmpty(), 'El mapa de acrs por contacto debería estar vacío');
        System.assertEquals(true, sdm.acrsToUpsert.isEmpty(), 'La lista de acrs to upsert debería estar vacía');
        System.assertEquals(acrNew.Id, sdm.acrsToDelete[0].Id, 'La relación debería de estar en la lista a borrar');
    }

    /**
     * Test que comprueba que si existe una relación entre la cuenta y el contacto directa el rol de la relación se borra correctamente 
     *
     * @author aberuete
     * @date 13/04/2023
     */
    @isTest
    private static void testCheckACRSToDeleteDirectRelation()
    {
        IntermediarySDM sdm = new IntermediarySDM();
        sdm.acrsToDelete = new List<AccountContactRelation> ();
        sdm.acrsToUpsert = new List<AccountContactRelation> ();

        String roleLabel ='Principal';
        Map<ID, AccountContactRelation> mapACRsByContact = new Map<ID, AccountContactRelation>();

        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> intermediary = [SELECT Id,Name,MainEmail__c FROM Account WHERE RecordTypeId = :rtIntermediaryId limit 2 ];

        Contact newContact = new Contact(
            AccountId= intermediary[0].Id,
            LastName= NAME_CONTACT,
            RecordTypeId= new ContactsSelector().rtContactId,
            Email= EMAIL_CONTACT
        );
        insert newContact;
        
        AccountContactRelation acr = [Select id,Roles,isDirect from AccountContactRelation where AccountId =:intermediary[0].Id and ContactId =:newContact.Id and isDirect = true limit 1];
        acr.Roles = 'Administracion;Principal';
        update acr;

        sdm.acrToDelete = acr;
        sdm.acrsToUpsert.add(acr);

        Test.startTest();
        mapACRsByContact = sdm.checkACRSToDelete(roleLabel,mapACRsByContact);
        Test.stopTest();

        System.assertEquals('Administracion', sdm.acrsToUpsert[0].Roles,'No debería estar el rol Principal');
    }

    /**
     * Test que comprueba que si existe una relación entre la cuenta y el contacto directa el rol de la relación se borra correctamente 
     * y la relación se añade en el mapa de relaciones a actualizar
     *
     * @author aberuete
     * @date 13/04/2023
     */
    @isTest
    private static void testCheckACRSToDeleteDirectRelationToAddListUpsert()
    {
        IntermediarySDM sdm = new IntermediarySDM();
        sdm.acrsToDelete = new List<AccountContactRelation> ();
        sdm.acrsToUpsert = new List<AccountContactRelation> ();

        String roleLabel ='Principal';
        Map<ID, AccountContactRelation> mapACRsByContact = new Map<ID, AccountContactRelation>();

        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> intermediary = [SELECT Id,Name,MainEmail__c FROM Account WHERE RecordTypeId = :rtIntermediaryId limit 2 ];

        Contact newContact = new Contact(
            AccountId= intermediary[0].Id,
            LastName= NAME_CONTACT,
            RecordTypeId= new ContactsSelector().rtContactId,
            Email= EMAIL_CONTACT
        );
        insert newContact;
        
        AccountContactRelation acr = [Select id,Roles,isDirect from AccountContactRelation where AccountId =:intermediary[0].Id and ContactId =:newContact.Id and isDirect = true limit 1];
        acr.Roles = 'Administracion;Principal';
        update acr;

        sdm.acrToDelete = acr;
        
        Test.startTest();
        mapACRsByContact = sdm.checkACRSToDelete(roleLabel,mapACRsByContact);
        Test.stopTest();

        System.assertEquals(acr.Id, sdm.acrsToUpsert[0].Id,'El acr debería estar en la lista para upsert');
        System.assertEquals('Administracion', sdm.acrsToUpsert[0].Roles,'No debería estar el rol Principal');
    }

    /**
     * Test que comprueba que si existe una relación entre la cuenta y el contacto directa el rol de la relación se borra correctamente 
     * y la relación se añade en el mapa de relaciones a actualizar
     *
     * @author aberuete
     * @date 13/04/2023
     */
    @isTest
    private static void testInsertContactsIfThereAreToInsertAndAssignRolToAcrToUpsert()
    {
        IntermediarySDM sdm = new IntermediarySDM();
        sdm.mapContactsToInsert = new Map<Integer, Contact>();
        sdm.acrsToUpsert = new List<AccountContactRelation> ();
        sdm.mapRolesForContacts = new Map<Integer, List<String>>();

        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> intermediary = [SELECT Id,Name,MainEmail__c FROM Account WHERE RecordTypeId = :rtIntermediaryId limit 2 ];

        Contact newContact = new Contact(
            AccountId= intermediary[0].Id,
            LastName= NAME_CONTACT,
            RecordTypeId= new ContactsSelector().rtContactId,
            Email= intermediary[0].MainEmail__c
        );
        
        sdm.mapContactsToInsert.put(0, newContact);

        List<String> rols = new List<String>{'Principal'}; 
        sdm.mapRolesForContacts.put(0, rols);

        Test.startTest();
        sdm.insertContactsIfThereAreToInsertAndAssignRolToAcrToUpsert();
        Test.stopTest();

        AccountContactRelation acr = [Select id,Roles,isDirect from AccountContactRelation where AccountId =:intermediary[0].Id and ContactId =:newContact.Id and isDirect = true limit 1];
        
        System.assertNotEquals(null, newContact.Id, 'El contacto se debería de haber insertado');
        System.assertEquals(acr.Id, sdm.acrsToUpsert[0].Id, 'La acr debería de estar en la lista para upsert');
    }

    /**
     * Test que comprueba que se borran y actualizan correctamente las relaciones de contactos y cuentas
     *
     * @author aberuete
     * @date 13/04/2023
     */
    @isTest
    private static void testDeleteOrUpsertACRs()
    {
        IntermediarySDM sdm = new IntermediarySDM();
        sdm.acrsToDelete = new List<AccountContactRelation>();
        sdm.acrsToUpsert = new List<AccountContactRelation>();

        ID rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> intermediary = [SELECT Id,Name,MainEmail__c FROM Account WHERE RecordTypeId = :rtIntermediaryId limit 2];

        Contact newContact = new Contact(
            AccountId= intermediary[0].Id,
            LastName= 'prueba princial',
            RecordTypeId= new ContactsSelector().rtContactId,
            Email= EMAIL_CONTACT
        );
        insert newContact;
        
        AccountContactRelation acrNew = new AccountContactRelation(
            AccountId= intermediary[1].Id,
            ContactId= newContact.Id,
            IsActive= true,
            Roles = 'Principal'
        );

        AccountContactRelation acrToDelete = new AccountContactRelation(
            AccountId= intermediary[1].Id,
            ContactId= newContact.Id,
            IsActive= true,
            Roles = 'Administracion'
        );
        insert acrToDelete;

        sdm.acrsToDelete.add(acrToDelete);
        sdm.acrsToUpsert.add(acrNew);

        Test.startTest();
        sdm.deleteOrUpsertACRs();
        Test.stopTest();

        List<AccountContactRelation> acrToReview = [Select id from AccountContactRelation where id=:acrToDelete.id] ;
        System.assertEquals(true, acrToReview.isEmpty(), 'La relación se debería haber borrado' );
        System.assertNotEquals(null, acrNew.Id, 'La relación se debería haber insertado');
    }

}