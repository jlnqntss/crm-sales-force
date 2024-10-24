/**
 * @description       : Test para comprobar el funcionamiento unitario de los metodos de la clase Account Lead Assignment
 * @author            : jgallaga
 * @group             : Seidor
 * @last modified on  : 31-01-2024
 * @last modified by  : amiranda
 **/
@isTest
public with sharing class Test_AccountLeadAssignment
{
    @TestSetup
    static void makeData()
    {
        // Crear los datos
        TestDataFactory.insertCrossSellingCustomSetting();
        TestDataFactory.insertAccountLeadAssignmentCriterias();
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
                                       RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('AgrupacionMediador').getRecordTypeId()
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

    /**
     * @description Test que asegura que si el el código de intermediario es Contact center
     *              la asignación se genera como "CONTACT_CENTER" con cuenta a null.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getAssignedUserIdByIntermediaryCode_CONTACTCENTER_OK()
    {
        String contactCenter = 'CONTACT_CENTER';

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getIntermediaryUserId(contactCenter);
        Test.stopTest();

        Assert.areEqual(contactCenter, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'Para el valor de CONTACT CENTER, no ha devuelto CONTACT_CENTER');
    }

    /**
     * @description Test para probar que mediante el código de intermediario de un
     *              agente existenten en el sistema, se recupera su ID de Salesforce.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getAssignedUserIdByIntermediaryCode_OK()
    {
        
        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;		
		User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];
        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByIntermediaryCode(aliasDefaultUser);
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( result.getAssignmentAsMap().keySet() ).get(0), 'No es el intermediario esperado');
    }

    /**
     * @description Test para asegurar que recibiendo un valor nulo, el método devuelve el
     *              valor del usuario por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getAssignedUserIdByIntermediaryCode_null_KO()
    {
        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByIntermediaryCode(null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0), 'No ha duelto el usuario por defecto');
    }

    /**
     * @description Test que asegura que en caso de que el código de intermediario no
     *              exista en el sistema, se recupera el usuario por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getAssignedUserIdByIntermediaryCode_NoIntermediary_KO()
    {
        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByIntermediaryCode('FAKE INTERMEDIARY');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0), 'No ha duelto el usuario por defecto');
    }

    /**
     * @description Test para probar que mediante el idioma indicado se consigue
     *              el intermediario que se ha configurado para dicho valor.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getAssignedUserIdByLanguage_OK()
    {

        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;
		User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];
        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByLanguage('FR');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'No es el intermediario para este idioma');
    }

    /**
     * @description Test que comprueba que si el lenguage que se facilita es nulo
     *              se devuelve el usuario por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getAssignedUserIdByLanguage_null_KO()
    {

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByLanguage(null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0), 'No ha devuelto el usuario por defecto');
    }

    /**
     * @description Test para comprubar que de recibir un idioma que no esta indicado
     *              en los metadatos de asignación por idioma, se devuelve el usuario
     *              por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getAssignedUserIdByLanguage_NoLanguageInConfig_KO()
    {

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByLanguage('IT');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0), 'No ha devuelto el usuario por defecto');
    }

    /**
     * @description Test para comprobar que con la asignación de tipo directa, devuelve al intermediario
     *              indicando el formulario de origen definido en metadatos.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getAssignedUserIdByAssignmentType_Directly_OK()
    {

        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;
		User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByAssignmentType('formulario accidentes', null);
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( result.getAssignmentAsMap().keySet() ).get(0), 'No ha devuelto el intermediario esperado');
    }

    /**
     * @description Test para asegurar que de no recibir ningun valor de origen o codigo postal
     *              se devuelve al usuario por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getAssignedUserIdByAssignmentType_null_KO()
    {

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByAssignmentType(null, null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0), 'No ha devuelto el usuario por defecto');
    }

    /**
     * @description Test para probar que un origen definido para ser por provincia
     *              devuelve al intermediario definido en metadatos.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getAssignedUserIdByAssignmentType_Province_OK()
    {

        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;	
		User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByAssignmentType('formulario automonos', '02000');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( result.getAssignmentAsMap().keySet() ).get(0), 'No ha devuelto el intermediario esperado');
    }

    /**
     * @description Test que comprueba que indicando un origen configurado en metadatos
     *              para asignar por municipio, devuelve al intermediario correspondiente.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getAssignedUserIdByAssignmentType_Municipality_OK()
    {

        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;
		User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByAssignmentType('formulario embarcaciones', '25000');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'No ha devuelto el intermediario esperado');
    }

    /**
     * @description Test que comprueba que indicando el origen de un metadato definido como
     *              directo, devuelve al intermediario correspondiente.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_assignedUserDirectly_OK()
    {

        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;	
		User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserDirectly('formulario accidentes');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'No se ha conseguido el intermediario esperado');
    }

    /**
     * @description Test que comprueba que aunque existe una configuración de asignación directa,
     *              si esa configuración no tiene indicado una asignación, devuelve al usuario
     *              por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_assignedUserDirectly_NoDirectOrigin_KO()
    {

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserDirectly('formulario desconocido');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'No se ha asignado al usuario por defecto');
    }

    /**
     * @description Test para comprobar que si se recibe un valor nulo en la asignación directa
     *              del intermediario se consigue el usuario por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_assignedUserDirectly_null_KO()
    {

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserDirectly(null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'No se ha asignado al usuario por defecto');
    }

    /**
     * @description Test que asegura que se devuelve al usuario por defecto en caso que en
     *              la asignación directa en metadatos no tiene indicado un intermediario
     *              en su configuración.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_assigneduserDirectly_NoAssignment_KO()
    {

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        AccountLeadAssignment.forumOriginAssignmentMetadata.add(new LeadAssignmentConfiguration__c
                                                                (
                                                                    AssignmentType__c = 'Direct',
                                                                    ForumOrigin__c = 'formulario asignacion')
                                                                );

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserDirectly('formulario asignacion');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'No ha devuelto el usuario por defecto');
    }

    /**
     * @description Test para comprobar que mediante un código postal se puede obtener el
     *              intermediario correspondiente indicado en la configuración de metadatos
     *              de municipio.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_assignedUserByMunicipality_OK()
    {

        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;
		User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByMunicipality('25000');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'No se ha conseguido el intermediario esperado');
    }

    /**
     * @description Test para comprobar que de recibir un valor nulo, la asignación por municipio
     *              devuelve al usuario por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_assignedUserByMunicipality_null_KO()
    {

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByMunicipality(null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'Tendría que haber devuelto el usuario por defecto');
    }

    /**
     * @description Test que comprueba de que no existir un registro para el municipio recibido
     *              devuelve al usuario por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_assignedUserByMunicipality_NoMunicipality_KO()
    {

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByMunicipality('12639');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'Tendría que haber devuelto el usuario por defecto');
    }

    /**
     * @description Test que comprueba que si la configuracion de asignación por municipio no tiene
     *              indicado un código de intermediario, devuelve al usuario por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_assignedUserByMunicipality_NoAssignment_KO()
    {

        AccountLeadAssignment.MunicipalityAssignmentMetadata.add( new LeadAssignmentConfiguration__c(ZIPRanges__c='12639') );

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByMunicipality('12639');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'Tendría que haber devuelto el usuario por defecto');
    }

    /**
     * @description Test para comprobar que de pasar un código postal, se consigue al intermediario
     *              que se ha configurado para dicho postal en la asignación por provincia.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_assignedUserByProvince_OK()
    {

        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;	
		User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByProvince('02365');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'No se ha asignado el intermediario esperado');
    }

    /**
     * @description Test que recupera al usuario por defecto en caso de indicar un valor nulo.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_assignedUserByProvince_null_KO()
    {

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByProvince(null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'No se ha asignado el intermediario esperado');
    }

    /**
     * @description Test para asegurar que de no existir una provincia en la configuración del
     *              metadato de asignación por provincia, se recupera al usuario por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_assignedUserByProvince_NoProvince_KO()
    {

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByProvince('15000');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'No se ha asignado el intermediario esperado');
    }

    /**
     * @description Test para comprobar que de haber una configuración para la provincia pero
     *              no tiene indicado un código de intermediario, se devuelve al usuario por
     *              defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_assignedUserByProvince_NoAssign_KO()
    {

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        AccountLeadAssignment.ProvinceAssignmentMetadata.add( new LeadAssignmentConfiguration__c(PostalCode__c='17',Province__c='Albacete') );

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByProvince('17845');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'No se ha asignado el intermediario esperado');
    }

    /**
     * @description Test para comprobar la correcta configuración de asignación por origen de formulario
     * @author      jgallaga
     * @date        16/08/2023
     */
    @istest
    static void test_getAssigmentType_OK()
    {

        //TestDataFactory.insertAccountLeadAssignmentCriterias();


        List<LeadAssignmentConfiguration__c> selected1 = [SELECT Id,RecordType.DeveloperName, AssignmentType__c,ForumOrigin__c FROM LeadAssignmentConfiguration__c];
        System.debug('selected1: ' + selected1);

        for(LeadAssignmentConfiguration__c seln : selected1 ){
            System.debug('seln: ' + seln);
        }
        System.debug('Asignación: ' + AccountLeadAssignment.getAssigmentType('formulario accidentes'));



        Test.startTest();
        String directResult         = AccountLeadAssignment.getAssigmentType('formulario accidentes');
        String provicenResult       = AccountLeadAssignment.getAssigmentType('formulario automonos');
        String municipalityResult   = AccountLeadAssignment.getAssigmentType('formulario salud');
        Test.stopTest();

        Assert.areEqual('Direct', directResult, 'No se ha conseguido el tipo de asignación de directo.');
        Assert.areEqual('Province', provicenResult, 'No se ha conseguido el tipo de asignación de provincia.');
        Assert.areEqual('Municipality', municipalityResult, 'No se ha conseguido el tipo de asignación de municipio.');
    }

    /**
     * @description Test para asegurar que de recibir un valor nulo para obtener el tipo de asignación
     *              se consigue la asignación por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getAssigmentType_null_KO()
    {

        Test.startTest();
        String defaultResult = AccountLeadAssignment.getAssigmentType(null);
        Test.stopTest();

        Assert.areEqual(AccountLeadAssignment.DEFAULT_ASSIGNEMENT_TYPE, defaultResult, 'No se ha conseguido el tipo de asignación por defecto');
    }

    /**
     * @description Test para comprobar que de recibir un origen de formulario que no tiene configurado
     *              un tipo de asignación, devuelve el tipo de asignación por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getAssigmentType_NoAssignmentType_KO()
    {

        AccountLeadAssignment.forumOriginAssignmentMetadata.add( new LeadAssignmentConfiguration__c
                                                                 (
                                                                     AssignTo__c='IDIOMA-QQ',
                                                                     ForumOrigin__c = 'formulario test') );

        Test.startTest();
        String defaultResult = AccountLeadAssignment.getAssigmentType('formulario test');
        Test.stopTest();

        Assert.areEqual(AccountLeadAssignment.DEFAULT_ASSIGNEMENT_TYPE, defaultResult, 'No se ha conseguido el tipo de asignación por defecto');
    }

    /**
     * @description Test que recupera el intermediario a partir de su código de filiación a partir
     *              de su relación entre cuenta, contact y usuario.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getIntermediaryUserId_OK()
    {
        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;
		User intermediary = [SELECT Id FROM User WHERE Alias = :aliasDefaultUser];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getIntermediaryUserId('IDIOMA-FR');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'No se ha encontrado al intermediario esperado');
    }

    /**
     * @description Test que comprueba que de no recibir un código de intermediario, se recupera
     *              al usuario por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getIntermediaryUserId_null_KO()
    {
        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getIntermediaryUserId(null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'No ha devuelto al usuario por defecto.');
    }

    /**
     * @description Test para comprobar que si no se encuentra la cuenta para el intermediario
     *              recibido se recupera al usuario por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getIntermediaryUserId_NoAccount_KO()
    {
        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result =  AccountLeadAssignment.getIntermediaryUserId('IDIOMA-FALSE');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'No ha devuelto al usuario por defecto.');
    }

    /**
     * @description Test que comprueba que a pesar de poder existir la cuenta del intermediario
     *              si no se consigue la relación con su usuario, se recupera al usuario por defecto.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getIntermediaryUserId_AccountButNoAgent_KO()
    {
        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Account testAccount = new Account(Name = 'Test Account', INFOIntermediaryCode__c = 'IDIOMA-FALSE' );
        Insert testAccount;

        Test.startTest();
        AccountLeadAssignment.Assignment result =  AccountLeadAssignment.getIntermediaryUserId('IDIOMA-FALSE');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>( result.getAssignmentAsMap().keySet() ).get(0),'No ha devuelto al usuario por defecto.');
    }

    /**
     * @description Test que asegura que compueba funcionamiento con languageAssignmentMetadata no informado (null)
     * @author      jlnavarroq
     * @date        14/10/2024
     */
    @isTest
    static void testlanguageAssignmentMetadata_NullCase() {
        // Limpiar el estado antes de la prueba
        Test.startTest();

        // Llamar al método que accede a languageAssignmentMetadata
        List<LeadAssignmentConfiguration__c> assignments = AccountLeadAssignment.languageAssignmentMetadata;

        // Asegurarse de que la propiedad no sigue siendo nula después de la llamada
        Assert.areNotEqual(null, AccountLeadAssignment.languageAssignmentMetadata,'Se espera un valor nulo: ' + AccountLeadAssignment.languageAssignmentMetadata);

        Test.stopTest();
    }

    /**
     * @description Test que asegura que compueba funcionamiento con forumOriginAssignmentMetadata no informado (null)
     * @author      jlnavarroq
     * @date        14/10/2024
     */
    @isTest
    static void testForumOriginAssignmentMetadata_NullCase() {
        // Limpiar el estado antes de la prueba
        Test.startTest();

        // Llamar al método que accede a forumOriginAssignmentMetadata
        List<LeadAssignmentConfiguration__c> assignments = AccountLeadAssignment.forumOriginAssignmentMetadata;

        // Asegurarse de que la propiedad no sigue siendo nula después de la llamada
        Assert.areNotEqual(null, AccountLeadAssignment.forumOriginAssignmentMetadata,'Se espera un valor nulo: ' + AccountLeadAssignment.forumOriginAssignmentMetadata);

        Test.stopTest();
    }

    /**
     * @description Test que asegura que compueba funcionamiento con municipalityAssignmentMetadata no informado (null)
     * @author      jlnavarroq
     * @date        14/10/2024
     */
    @isTest
    static void testmunicipalityAssignmentMetadata_NullCase() {
        // Limpiar el estado antes de la prueba
        Test.startTest();

        // Llamar al método que accede a municipalityAssignmentMetadata
        List<LeadAssignmentConfiguration__c> assignments = AccountLeadAssignment.municipalityAssignmentMetadata;

        // Asegurarse de que la propiedad no sigue siendo nula después de la llamada
        Assert.areNotEqual(null, AccountLeadAssignment.municipalityAssignmentMetadata,'Se espera un valor nulo: ' + AccountLeadAssignment.municipalityAssignmentMetadata);

        Test.stopTest();
    }

    /**
     * @description Test que asegura que compueba funcionamiento con provinceAssignmentMetadata no informado (null)
     * @author      jlnavarroq  
     * @date        14/10/2024
     */
    @isTest
    static void testprovinceAssignmentMetadata_NullCase() {
        // Limpiar el estado antes de la prueba
        Test.startTest();

        // Llamar al método que accede a provinceAssignmentMetadata
        List<LeadAssignmentConfiguration__c> assignments = AccountLeadAssignment.provinceAssignmentMetadata;
        Test.stopTest();
    }
}