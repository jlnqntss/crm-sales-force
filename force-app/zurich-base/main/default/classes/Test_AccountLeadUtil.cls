/**
 * @description       : Test funcionales de la asignación de Leads a Agentes.
 * @author            : jgallaga
 * @group             : Seidor
 * @last modified on  : 31-01-2024
 * @last modified by  : amiranda
 **/
@isTest
public with sharing class Test_AccountLeadUtil
{
    @TestSetup
    static void makeData()
    {
        TestDataFactory.insertCrossSellingCustomSetting();
        createCommnunityUsers(); // Crea usuarios de comunidad con su cuenta y contact correspondiente
    }

    /**
     * @description Funcionalidad para crear agentes de comunidad a los que podes asignar las cuenta de tipo Lead
     *              de los Tests.
     *              Se utiliza un usuario con perfil de administrador diferente al usuario que lanza el test para
     *              poder insertar Users, Accounts y Contacts para evitar errores de MIXED DML.
     * @author      jgallaga
     * @date        11/08/2023
     */
    private static void createCommnunityUsers()
    {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name IN ('Administrador del sistema', 'System Administrator') AND Id != : UserInfo.getUserId() AND IsActive = true LIMIT 1];

        Map<String, User> communityAgents = prepareNewUsers();

        Map<String, Account> communityAgentAccounts = insertAccounts( communityAgents.keySet() );
        Map<String, Contact> communitAgentContacts = insertContacts(communityAgents.keySet(), communityAgentAccounts); //Contact

        System.runAs(adminUser)
        {
            relateRecordsToAgents(communityAgents, communitAgentContacts);
        }
    }

    /**
     * @description Lógica que crea la relación del usuario de comunidad con sus registros de contacto y cuenta.
     * @author      jgallaga
     * @date        11/08/2023
     */
    private static void relateRecordsToAgents(Map<String, User> communityAgents, Map<String, Contact> communityAgentContacts)
    {
        Profile zrmCommunityProfile = [Select Id from Profile where name = : ProfilesSelector.PROFILE_AGENTE_VENTAS]; // Perfil de comunidad de agentes de Mi Agencia

        for( String currentUserName : communityAgents.keySet() )
        {
            User currentUser = communityAgents.get(currentUserName);
            currentUser.ContactId = communityAgentContacts.get(currentUserName).Id;
            currentUser.ProfileId = zrmCommunityProfile.Id;
        }

        insert communityAgents.values();
    }


    /**
     * description  Funcionalidad para insertar los contactos que se utilizarán para crear los
     *              usuario de la comunidad. Recoge la cuenta ya existente para crear la relación
     *              entre cuenta y contacto para el agente.
     * @author      jgallaga
     * @date        11/08/2023
     */
    private static Map<String, Contact> insertContacts(Set<String> communityUserNames, Map<String, Account> agentAccounts)
    {
        Map<String, Contact> agentContactRecords = new Map<String, Contact>();

        for(String currentUserName : communityUserNames)
        {
            Account agentAccount = agentAccounts.get(currentUserName);
            agentContactRecords.put( currentUserName, new Contact(
                                         LastName = currentUserName,
                                         AccountId = agentAccount.Id
                                         ) );
        }

        insert agentContactRecords.values();

        return agentContactRecords;
    }

    /**
     * @description Funcionalidad para insertar las cuenta de agente.
     * @author      jgallaga
     * @date        11/08/2023
     */
    private static Map<String, Account> insertAccounts(Set<String> communityUserNames)
    {
        Map<String,Account> agentAccounts = new Map<String, Account>();
        RecordType agentAccountRecordType = [SELECT Id FROM RecordType WHERE Name = 'Parent Account' AND SobjectType = 'Account'];
        RecordType intermediaryAccountRecordType = [SELECT Id FROM RecordType WHERE Name = 'Intermediary' AND SobjectType = 'Account'];

        for(String currentCommunityName : communityUserNames)
        {
            agentAccounts.put( currentCommunityName, new Account(
                                   Name = currentCommunityName + 'a',
                                   RecordTypeId = agentAccountRecordType.Id
                                   ) );
        }

        insert agentAccounts.values();

        Map<String,Account> intermediaryGroup = new Map<String,Account>();
        for(String currentCommunityName : communityUserNames)
        {
            intermediaryGroup.put( currentCommunityName,new Account(
                                       Name = currentCommunityName + 'p',
                                       RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('AgrupacionMediador').getRecordTypeId(),
                                       IntermediaryWithUser__c = agentACcounts.get(currentCommunityName).Id
                                       ) );
        }

        insert intermediaryGroup.values();

        Map<String,Account> intermediaryAccounts = new Map<String,Account>();
        for(String currentCommunityName : communityUserNames)
        {
            intermediaryAccounts.put( currentCommunityName,new Account(
                                          Name = currentCommunityName + 'i',
                                          RecordTypeId = intermediaryAccountRecordType.Id,
                                          INFOIntermediaryCode__c = currentCommunityName,
                                          IntermediaryGroup__c = intermediaryGroup.get(currentCommunityName).Id
                                          ) );
        }

        insert intermediaryAccounts.values();

        return agentAccounts;
    }

    /**
     * @description Método para generar los dintintos usuario que se utilizarán en los test.
     *              El indice se define como el nombre de usuario de comunidad o código de intermediario
     * @author      jgallaga
     * @date        11/08/2023
     */
    private static Map<String, User> prepareNewUsers()
    {
        Map<String, User> communityAgents = new Map<String, User>();

        communityAgents.put( 'IDIOMA-ES', new User(
                                 Username = 'testAssignmetZurich@zurich.com' + '1',
                                 Alias = 'sfdc',
                                 Email='testAssignmetZurich@zurich.com',
                                 EmailEncodingKey='UTF-8',
                                 Firstname='Test',
                                 Lastname='IDIOMA-ES',
                                 LanguageLocaleKey='es',
                                 LocaleSidKey='es',
                                 TimeZoneSidKey='Europe/Madrid'
                                 ) );

        communityAgents.put( 'IDIOMA-FR', new User(
                                 Username = 'testAssignmetZurich@zurich.com' + '2',
                                 Alias = 'sfdc',
                                 Email='testAssignmetZurich@zurich.com',
                                 EmailEncodingKey='UTF-8',
                                 Firstname='Test',
                                 Lastname='IDIOMA-FR',
                                 LanguageLocaleKey='es',
                                 LocaleSidKey='es',
                                 TimeZoneSidKey='Europe/Madrid'
                                 ) );

        communityAgents.put( 'IDIOMA-QQ', new User(
                                 Username = 'testAssignmetZurich@zurich.com' + '3',
                                 Alias = 'sfdc',
                                 Email='testAssignmetZurich@zurich.com',
                                 EmailEncodingKey='UTF-8',
                                 Firstname='Test',
                                 Lastname='IDIOMA-QQ',
                                 LanguageLocaleKey='es',
                                 LocaleSidKey='es',
                                 TimeZoneSidKey='Europe/Madrid'
                                 ) );

        communityAgents.put( 'IDIOMA-DE', new User(
                                 Username = 'testAssignmetZurich@zurich.com' + '4',
                                 Alias = 'sfdc',
                                 Email='testAssignmetZurich@zurich.com',
                                 EmailEncodingKey='UTF-8',
                                 Firstname='Test',
                                 Lastname='IDIOMA-DE',
                                 LanguageLocaleKey='es',
                                 LocaleSidKey='es',
                                 TimeZoneSidKey='Europe/Madrid'
                                 ) );

        return communityAgents;
    }

    private static void setMetadataConfigurations()
    {
        //Creación de metadatos

        //LANGUAGE
        List<LanguageAssignment__mdt> testLanguageAssignmentMetadata = new List<LanguageAssignment__mdt>();
        testLanguageAssignmentMetadata.add( new LanguageAssignment__mdt(DeveloperName = 'Español', AssignTo__c = 'IDIOMA-ES', Language__c = 'ES') );
        testLanguageAssignmentMetadata.add( new LanguageAssignment__mdt(DeveloperName = 'Frances', AssignTo__c = 'IDIOMA-FR', Language__c = 'FR') );

        AccountLeadAssignment.languageAssignmentMetadata = testLanguageAssignmentMetadata;

        //FORUM ASSIGNMENT
        List<ForumOriginAssignment__mdt> testforumOriginAssignmentMetadata = new List<ForumOriginAssignment__mdt>();
        testforumOriginAssignmentMetadata.add( new ForumOriginAssignment__mdt(DeveloperName = 'formulario_accidentes', AssignmentType__c = 'Direct',AssignTo__c='IDIOMA-ES',ForumOrigin__c = 'formulario accidentes') );
        testforumOriginAssignmentMetadata.add( new ForumOriginAssignment__mdt(DeveloperName = 'formulario_automonos', AssignmentType__c = 'Province',AssignTo__c='IDIOMA-DE',ForumOrigin__c = 'formulario automonos') );
        testforumOriginAssignmentMetadata.add( new ForumOriginAssignment__mdt(DeveloperName = 'formulario_pymes', AssignmentType__c = 'Province',AssignTo__c='IDIOMA-FR',ForumOrigin__c = 'formulario pymes') );
        testforumOriginAssignmentMetadata.add( new ForumOriginAssignment__mdt(DeveloperName = 'formulario_embarcaciones', AssignmentType__c = 'Municipality',AssignTo__c='IDIOMA-QQ',ForumOrigin__c = 'formulario embarcaciones') );
        testforumOriginAssignmentMetadata.add( new ForumOriginAssignment__mdt(DeveloperName = 'formulario_salud', AssignmentType__c = 'Municipality',AssignTo__c='IDIOMA-QQ',ForumOrigin__c = 'formulario salud') );
        testforumOriginAssignmentMetadata.add( new ForumOriginAssignment__mdt(DeveloperName = 'ContactCenter', AssignmentType__c = 'Direct',AssignTo__c='CONTACT_CENTER',ForumOrigin__c = 'ContactCenter') );

        AccountLeadAssignment.forumOriginAssignmentMetadata = testforumOriginAssignmentMetadata;

        //MUNICIPALITY ASSIGNMENT
        List<MunicipalityAssignment__mdt> testMunicipalityAssignmentMetadata = new List<MunicipalityAssignment__mdt>();
        testMunicipalityAssignmentMetadata.add( new MunicipalityAssignment__mdt(DeveloperName = 'Lleida', ZIPRanges__c= '{"25999": "IDIOMA-ES"}', ProvinceCode__c='25') );

        AccountLeadAssignment.MunicipalityAssignmentMetadata = testMunicipalityAssignmentMetadata;

        //PROVINCE ASSIGNMENT
        List<ProvinceAssignment__mdt> testProvinceAssignmentMetadata = new List<ProvinceAssignment__mdt>();
        testProvinceAssignmentMetadata.add( new ProvinceAssignment__mdt(DeveloperName = 'Albacete',AssignTo__c='IDIOMA-FR',PostalCode__c='02',Province__c='Albacete') );

        AccountLeadAssignment.ProvinceAssignmentMetadata = testProvinceAssignmentMetadata;
    }

    /*** ASSIGNMENT BY INTERMEDIARY CODE ***/


    /**
     * @description Test que comprueba que recibiendo un origen de formulario que
     *              corresponde a un Contact Center se recupera una asignación con
     *              valor "CONTACT CENTER" sin una cuenta asociada.
     * @author      jgallaga
     * @date        14/08/2023
     * **
     * @modification
     *              La asignacion del Contact Center se realiza desde metadatos también
     *              Se modifica el Test para que genere los metadatos que permiten
     *              comprobar la asignacion al Contact Center segun configuracion
     * @author      jgallaga
     * @date        28/09/2023
     */
    @isTest
    static void test_intermediaryCodeContactCenter_OK()
    {
        setMetadataConfigurations();
        String origin = 'ContactCenter';
        String resultIntermediary = 'CONTACT_CENTER';

        Test.startTest();
        Map<String,Account> result = AccountLeadUtil.leadAssignment(null, null, origin, null, null);
        Test.stopTest();

        Assert.areEqual(resultIntermediary, new List<String>( result.keySet() ).get(0), 'No se ha devuelto el valor de contact center');
    }

    /**
     * @description Test que comprueba que recibiendo un código de intermediario
     *              es posible encontrar el Id del usuario. El usuario se encuentra
     *              buscando una cuenta que tenga asignado su código intermediario en
     *              el campo INFOIntermediaryCode__c.
     * @author      jgallaga
     * @date        14/08/2023
     */
    @isTest
    static void test_intermediaryAssignment_OK()
    {

        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;
		User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];

        Test.startTest();
        // Indicando el código de intermeadiario, el resto de parametros no se tienen en cuenta
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(new Account(), 'IDIOMA-ES', 'origen', 'idioma', 'código postal');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( assignee.keySet() ).get(0), 'No es el intermediario correcto');

        Account intermediaryAccount = assignee.get(intermediary.Id);
        Assert.isNotNull(intermediaryAccount, 'No se ha recuperado la cuenta del intermediario');
        Assert.isNotNull(intermediaryAccount.INFOIntermediaryCode__c, 'No se ha recuperado el valor del campo');
    }

    /**
     * @description Test que comprueba que recibiendo un código de intermediario
     *              que no tiene ninguna cuenta asignada a su nombre, la lógica
     *              devuelve el ID del usuario por defecto indicado en los metadatos
     *              para la sandbox correspondiente.
     * @author      jgallaga
     * @date        14/08/2023
     */
    @isTest
    static void test_intermediaryAssignment_KO()
    {
        String defaultUserId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(null, 'MadeUp Intermediary Code', null, null, null);
        Test.stopTest();

        Assert.areEqual(defaultUserId, new List<String>( assignee.keySet() ).get(0), 'Se debería haber asignado el intermediario por defecto');
    }

    /*** ASSIGNMENT BY ACCOUNT ***/

    /**
     * @description Test que comprueba que se consigue el Id del intermediario que esta relacionado
     *              con la cuenta que se recibe.
     * @author      jgallaga
     * @date        14/08/2023
     */
    @isTest
    static void test_AssignmnetIntermediaryAccount_OK()
    {
        Account intermediaryAccount = [SELECT Id FROM Account WHERE INFOIntermediaryCode__c = 'IDIOMA-QQ'];
        RecordType leadAccountRT = [SELECT Id FROM RecordType WHERE Name = 'Customer' AND SobjectType = 'Account'];

        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;
		User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];

        Account testAccount = new Account(Lastname = 'TestAccount', Intermediary_Name__c = intermediaryAccount.Id, RecordTypeId = leadAccountRT.Id);
        insert testAccount;
        testAccount = [SELECT Intermediary_Name__r.INFOIntermediaryCode__c, RecordTypeId FROM Account Where Id = : testAccount.Id];

        Test.startTest();
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(testAccount, null, 'origin', 'language', 'postalCode');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( assignee.keySet() ).get(0), 'No se ha asignado el intermediario esperado');

        Account intermediaryAccountAsignee = assignee.get(intermediary.Id);
        Assert.isNotNull(intermediaryAccountAsignee, 'No se ha recuperado la cuenta del intermediario');
        Assert.isNotNull(intermediaryAccountAsignee.INFOIntermediaryCode__c, 'No se ha recuperado el valor del campo');
    }

    /**
     * @description Test que asegura que cuando se quiere asignar un Lead a partir de una cuenta que
     *              no tiene relacionada la cuenta de intermediario, se recibe el usuario por defecto.
     * @author      jgallaga
     * @date        14/08/2023
     */
    @isTest
    static void test_AssignmentIntermadiaryAccount_NoRelatedIntermediaryAccount_KO()
    {
        String defaultUserId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();
        RecordType leadAccountRT = [SELECT Id FROM RecordType WHERE Name = 'Lead' AND SobjectType = 'Account'];
        Account testAccount = new Account(Name = 'TestAccount', RecordtypeId = leadAccountRT.id);

        Test.startTest();
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(testAccount, null, 'origin', 'language', 'postalCode');
        Test.stopTest();

        Assert.areEqual(defaultUserId, new List<String>( assignee.keySet() ).get(0), 'No se ha asignado el usuario por defecto');
    }

    /**
     * @description Test que asegura que se asigna el usuario por defecto si la cuenta de intermediario
     *              relacionada con la cuenta recibida, no tiene un código de intermediario de un usuario
     *              existente.
     * @author      jgallaga
     * @date        14/08/2023
     */
    @isTest
    static void test_AssignmentIntermediaryAccount_NoIntermediaryCodeInRelatedIntermediaryAccount_KO()
    {
        String defaultUserId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();
        Account madeUpIntermediaryAccount = new Account(Name = 'MadeUp', INFOIntermediaryCode__c = 'NO-ACCOUNT');
        insert madeUpIntermediaryAccount;
        Account testAccount = new Account(Name = 'TestAccount', Intermediary_Name__c = madeUpIntermediaryAccount.Id);
        insert testAccount;
        testAccount = [SELECT Intermediary_Name__r.INFOIntermediaryCode__c, RecordTypeId FROM Account Where Id = : testAccount.Id];

        Test.startTest();
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(testAccount, null, 'origin','language', 'postalcode');
        Test.stopTest();

        Assert.areEqual(defaultUserId, new List<String>( assignee.keySet() ).get(0), 'No se ha asignado el usuario por defecto');
    }

    /*** ASSIGNMENT BY LANGUAGE ***/

    /**
     * @description Test que comprueba que a partir del idioma FR se consigue
     *              el ID del dicho agente desde los metadatos.
     *              El camino que sigue debe ser la asignación por idioma y
     *              que encuentre el registro de configuración para el idioma
     *              FR con el código de intermediario que le permite encontrar
     *              el Id del usuario correspondiente.
     *              Para ello es necesario que la cuenta este a nulo y que
     *              no se facilite un código de intermediario. El valor de origen
     *              y código postal no deben afectar.
     * @author      jgallaga
     * @date        11/08/2023
     */
    @isTest
    static void test_AssignmentFrenchLanguageAgent_OK()
    {
        setMetadataConfigurations();

        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;
        User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];

        Test.startTest();
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(null, null, 'formulario test', 'FR', '99999');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( assignee.keySet() ).get(0), 'El usuario asignado para el lenguaje frances no es correcto.');

        Account intermediaryAccount = assignee.get(intermediary.Id);
        Assert.isNotNull(intermediaryAccount, 'No se ha recuperado la cuenta del intermediario');
        Assert.isNotNull(intermediaryAccount.INFOIntermediaryCode__c, 'No se ha recuperado el valor del campo');
    }

    /**
     * @description Test que comprueba que a partir del idioma QQ se consigue
     *              el ID del agente por defecto.
     *              El camino que sigue debe ser la asignación por idioma y
     *              que no encuentre un registro de configuración para el idioma
     *              QQ. Al no encontrarlo, devolverá el ID del usuario por defecto
     *              indicado en los métadatos (En el entorno en el que se este).
     *              Para ello es necesario que la cuenta este a nulo y que
     *              no se facilite un código de intermediario. El valor de origen
     *              y código postal no deben afectar.
     * @author      jgallaga
     * @date        11/08/2023
     */
    @isTest
    static void test_AssignmentMadeUpLanguage_KO()
    {
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(null,null,null,'QQ',null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( assignee.keySet() ).get(0), 'El usuario asignado para el lenguaje que no tiene configuración definida no es correcto.');
    }

    /*** ASSIGNMENT BY ASSIGNMENT TYPE */

    /**
     * @description Test para comprobar la asignación directa de un intermediario segun
     *              la configuración indicada en metadatos para un origen concreto del
     *              formulario.
     * @author      jgallaga
     * @date        14/08/2023
     */
    @isTest
    static void test_AssignmentDirectly_OK()
    {
        setMetadataConfigurations();

        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;
		User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];

        Test.startTest();
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(null, null, 'formulario accidentes','ES', null);
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( assignee.keySet() ).get(0), 'No se ha asignado directamente al intermadiario esperado.');

        Account intermediaryAccount = assignee.get(intermediary.Id);
        Assert.isNotNull(intermediaryAccount, 'No se ha recuperado la cuenta del intermediario');
        Assert.isNotNull(intermediaryAccount.INFOIntermediaryCode__c, 'No se ha recuperado el valor del campo');
    }

    /**
     * @description Test que asegura que si la configuración para un origen de formulario que no tiene
     *              asignado el tipo de asignación, realiza una asignación por provincia y en este
     *              caso al no tener una configuración para el codigo postal, devuelve al usuario por defecto
     * @author      jgallaga
     * @date        14/08/2023
     */
    @isTest
    static void test_AssignmentDirectly_NoMetadataAssignTo_KO()
    {
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        AccountLeadAssignment.forumOriginAssignmentMetadata.add( new ForumOriginAssignment__mdt
                                                                 (
                                                                     DeveloperName = 'formulario_inventado',
                                                                     AssignTo__c='IDIOMA-ES',
                                                                     ForumOrigin__c = 'formulario inventado'
                                                                 ) );

        Test.startTest();
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(null, null, 'formulario inventado', 'ES', null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( assignee.keySet() ).get(0), 'No se ha asignado el usuario por defecto');
    }

    /**
     * @description Prueba que asegura que al indicar una asignación directa, si no encuentra la
     *              consiguración apropiada, el tipo de asignación cambia a tipo provincia y
     *              encuentra el agente correspondiente para dicha zona.
     * @author      jgallga
     * @date        14/08/2023
     */
    @isTest
    static void test_AssignmentDirectlyNoConfiguration_AssignmentProvice_OK()
    {
        setMetadataConfigurations();

        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;	
        User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];
        AccountLeadAssignment.forumOriginAssignmentMetadata.add( new ForumOriginAssignment__mdt
                                                                 (
                                                                     DeveloperName = 'formulario_inventado',
                                                                     AssignTo__c='IDIOMA-FR',
                                                                     ForumOrigin__c = 'formulario inventado'
                                                                 ) );

        Test.startTest();
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(null, null, 'formulario inventado', 'ES', '02458');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( assignee.keySet() ).get(0), 'No se ha asignado el usuario por defecto');

        Account intermediaryAccount = assignee.get(intermediary.Id);
        Assert.isNotNull(intermediaryAccount, 'No se ha recuperado la cuenta del intermediario');
        Assert.isNotNull(intermediaryAccount.INFOIntermediaryCode__c, 'No se ha recuperado el valor del campo');
    }

    /**
     * @description Test que comprueba que si en una asignación de tipo directa, tampoco se
     *              encuentra el agente por provincia, finalmente queda asignada el Lead al
     *              usuario por defecto.
     * @author      jgallaga
     * @date        14/08/2023
     */
    @isTest
    static void test_AssignmentDirectlyNoConfiguration_AssignmentProviceNoPostCode_KO()
    {
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        AccountLeadAssignment.forumOriginAssignmentMetadata.add( new ForumOriginAssignment__mdt
                                                                 (
                                                                     DeveloperName = 'formulario_inventado',
                                                                     AssignTo__c='IDIOMA-FR',
                                                                     ForumOrigin__c = 'formulario inventado'
                                                                 ) );

        Test.startTest();
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(null, null, 'formulario inventado', 'ES', null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( assignee.keySet() ).get(0), 'No se ha asignado el usuario por defecto');
    }

    /**
     * @description Test para comprobar que una asignación por provincia recupera al
     *              agente correspondiente en metadatos.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_AssignmentProvince_OK()
    {
        setMetadataConfigurations();

        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;
		User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];

        //formulario_automonos - 2
        Test.startTest();
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(null, null, 'formulario automonos', 'ES', '02340');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( assignee.keySet() ).get(0), 'No se ha asignado al intermediario de la provincia correctamente.');

        Account intermediaryAccount = assignee.get(intermediary.Id);
        Assert.isNotNull(intermediaryAccount, 'No se ha recuperado la cuenta del intermediario');
        Assert.isNotNull(intermediaryAccount.INFOIntermediaryCode__c, 'No se ha recuperado el valor del campo');
    }

    /**
     * @description Test para comprobar que si no existe una configuración de asignación por
     *              Provincia para un código postal concreto, se asigna el usuario por defecto.
     * @author      jgallaga
     * @date        16/05/2023
     */
    @isTest
    static void test_AssignmentProvince_NoProvinceConfig_KO()
    {
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(null, null, 'formulario automonos', 'ES', '41555');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( assignee.keySet() ).get(0), 'Se debería haber asignado al usuario por defecto');
    }

    /**
     * @description Test que comprueba que a pesar de tener un registro de configuración para
     *              asignar por provincia, si no hay indicado a quien asignarselo, devuelve al
     *              usuario por defecto
     * @author      jgallaga
     * @date        16/05/2023
     */
    @isTest
    static void test_AssignmentProvince_NoAssignTo_KO()
    {
        setMetadataConfigurations();

        ProvinceAssignment__mdt noAssignment = new ProvinceAssignment__mdt(DeveloperName = 'Bizkaia',PostalCode__c='48',Province__c='Bizkaia');
        AccountLeadAssignment.ProvinceAssignmentMetadata.add(noAssignment);

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(null, null, 'formulario pymes', 'ES', '48522');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( assignee.keySet() ).get(0), 'No se ha asignado el usuario por defecto');
    }


    /**
     * @description Test para comprobar la asignación del intermediario indicando un origen de formulario preparado
     *              para la asignación mediante municipio.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_AssignmetMunicipality_OK()
    {
        setMetadataConfigurations();

       String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;	
       User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];

        Test.startTest();
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(null, null, 'formulario embarcaciones', 'ES', '25000');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( assignee.keySet() ).get(0), 'No se ha asignado al intermediario correcto para este municipio.');

        Account intermediaryAccount = assignee.get(intermediary.Id);
        Assert.isNotNull(intermediaryAccount, 'No se ha recuperado la cuenta del intermediario');
        Assert.isNotNull(intermediaryAccount.INFOIntermediaryCode__c, 'No se ha recuperado el valor del campo');
    }

    /**
     * @description Test para comprobar que si hay una asignación por municipio, pero no existe
     *              una entrada que indique a que intermediario corresponde, se asigna al usuario
     *              por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_AssignmentMunicipality_NoConfig_KO()
    {
        setMetadataConfigurations();
        String defaultAgentId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        Map<String,Account> assignee = AccountLeadUtil.leadAssignment(null, null,'formulario salud','ES','12458');
        Test.stopTest();

        Assert.areEqual(defaultAgentId, new List<String>( assignee.keySet() ).get(0), 'No se ha asignado al usuario por defecto.');
    }
}