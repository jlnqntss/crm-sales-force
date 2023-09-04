/**
 * @description       : Test para comprobar el funcionamiento unitario de los metodos de la clase Account Lead Assignment
 * @author            : jgallaga
 * @group             : Seidor
 * @last modified on  : 23/08/2023
 * @last modified by  : jgallaga
**/
@isTest
public with sharing class Test_AccountLeadAssignment
{
    private static String DEFAULT_ADMIN_ALIAS // Añadir el alias de cada user admin para cada entorno si fuera necesario
    {
        get
        {
            if(String.isBlank(DEFAULT_ADMIN_ALIAS))
            {
                if(SystemUtil.getSandboxName() == 'qa')
                {
                    DEFAULT_ADMIN_ALIAS = 'ntsadmin';
                }
                else
                {
                    DEFAULT_ADMIN_ALIAS = 'adminkli';
                }
            }
            return DEFAULT_ADMIN_ALIAS;
        }
        set;
    }

    @TestSetup
    static void makeData()
    {
        createCommnunityUsers(); // Crea usuarios de comunidad con su cuenta y contact correspondiente

        // Crear Custom Setting para default user
        Cross_Selling__c setting = new Cross_Selling__c();
        setting.Name = 'Test Setting';
        setting.ContactCenterUser__c = '-';
        setting.DefaultUser__c = DEFAULT_ADMIN_ALIAS;
        insert setting;
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
        User adminUser = [SELECT Id FRom User WHERE Profile.Name = 'System Administrator' AND Id != :UserInfo.getUserId() AND isActive = true LIMIT 1];

        Map<String, User> communityAgents = prepareNewUsers();

        Map<String, Account> communityAgentAccounts = insertAccounts(communityAgents.keySet());
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
        Profile zrmCommunityProfile = [Select Id from Profile where name = 'Agente Ventas']; // Perfil de comunidad de agentes de Mi Agencia

        for(String currentUserName : communityAgents.keySet())
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
            agentContactRecords.put(currentUserName, new Contact(
                LastName = currentUserName,
                AccountId = agentAccount.Id
            ));
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
        Map<String ,Account> agentAccounts = new Map<String, Account>();
        RecordType agentAccountRecordType = [SELECT Id FROM RecordType WHERE Name = 'Parent Account' AND SobjectType = 'Account'];
        RecordType intermediaryAccountRecordType = [SELECT Id FROM RecordType WHERE Name = 'Intermediary' AND SobjectType = 'Account'];


        for(String currentCommunityName : communityUserNames)
        {
            agentAccounts.put(currentCommunityName, new Account(
                Name = currentCommunityName + 'a',
                RecordTypeId = agentAccountRecordType.Id
            ));
        }

        insert agentAccounts.values();

        Map<String,Account> parentAccounts = new Map<String,Account>();
        for(String currentCommunityName : communityUserNames)
        {
            parentAccounts.put(currentCommunityName,new Account(
                Name = currentCommunityName + 'p',
                RecordTypeId = intermediaryAccountRecordType.Id,
                IntermediaryWithUser__c = agentACcounts.get(currentCommunityName).Id
            ));
        }

        insert parentAccounts.values();

        Map<String,Account> intermediaryAccounts = new Map<String,Account>();
        for(String currentCommunityName : communityUserNames)
        {
            intermediaryAccounts.put(currentCommunityName,new Account(
                Name = currentCommunityName + 'i',
                RecordTypeId = intermediaryAccountRecordType.Id,
                INFOIntermediaryCode__c = currentCommunityName,
                ParentId = parentAccounts.get(currentCommunityName).Id
            ));
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

        communityAgents.put('IDIOMA-ES', new User(
            Username = 'testAssignmetZurich@zurich.com' + '1',
            Alias = 'sfdc',
            Email='testAssignmetZurich@zurich.com',
            EmailEncodingKey='UTF-8',
            Firstname='Test',
            Lastname='IDIOMA-ES',
            LanguageLocaleKey='es',
            LocaleSidKey='es',
            TimeZoneSidKey='Europe/Madrid'
        ));

        communityAgents.put('IDIOMA-FR', new User(
            Username = 'testAssignmetZurich@zurich.com' + '2',
            Alias = 'sfdc',
            Email='testAssignmetZurich@zurich.com',
            EmailEncodingKey='UTF-8',
            Firstname='Test',
            Lastname='IDIOMA-FR',
            LanguageLocaleKey='es',
            LocaleSidKey='es',
            TimeZoneSidKey='Europe/Madrid'
        ));

        communityAgents.put('IDIOMA-QQ', new User(
            Username = 'testAssignmetZurich@zurich.com' + '3',
            Alias = 'sfdc',
            Email='testAssignmetZurich@zurich.com',
            EmailEncodingKey='UTF-8',
            Firstname='Test',
            Lastname='IDIOMA-QQ',
            LanguageLocaleKey='es',
            LocaleSidKey='es',
            TimeZoneSidKey='Europe/Madrid'
        ));

        communityAgents.put('IDIOMA-DE', new User(
            Username = 'testAssignmetZurich@zurich.com' + '4',
            Alias = 'sfdc',
            Email='testAssignmetZurich@zurich.com',
            EmailEncodingKey='UTF-8',
            Firstname='Test',
            Lastname='IDIOMA-DE',
            LanguageLocaleKey='es',
            LocaleSidKey='es',
            TimeZoneSidKey='Europe/Madrid'
        ));

        return communityAgents;
    }

    private static void setMetadataConfigurations()
    {
        //Creación de metadatos

        //LANGUAGE
        List<LanguageAssignment__mdt> testLanguageAssignmentMetadata = new List<LanguageAssignment__mdt>();
        testLanguageAssignmentMetadata.add(new LanguageAssignment__mdt(DeveloperName = 'Español', AssignTo__c = 'IDIOMA-ES', Language__c = 'ES'));
        testLanguageAssignmentMetadata.add(new LanguageAssignment__mdt(DeveloperName = 'Frances', AssignTo__c = 'IDIOMA-FR', Language__c = 'FR'));

        AccountLeadAssignment.languageAssignmentMetadata = testLanguageAssignmentMetadata;

        //FORUM ASSIGNMENT
        // Muchisimo cuidado en cambiar el Assignment type, puede romper un gran numero de tests.
        List<ForumOriginAssignment__mdt> testforumOriginAssignmentMetadata = new List<ForumOriginAssignment__mdt>();
        testforumOriginAssignmentMetadata.add(new ForumOriginAssignment__mdt(DeveloperName = 'formulario_accidentes', AssignmentType__c = 'Direct',AssignTo__c='IDIOMA-ES',ForumOrigin__c = 'formulario accidentes'));
        testforumOriginAssignmentMetadata.add(new ForumOriginAssignment__mdt(DeveloperName = 'formulario_automonos', AssignmentType__c = 'Province',AssignTo__c='IDIOMA-DE',ForumOrigin__c = 'formulario automonos'));
        testforumOriginAssignmentMetadata.add(new ForumOriginAssignment__mdt(DeveloperName = 'formulario_pymes', AssignmentType__c = 'Province',AssignTo__c='IDIOMA-FR',ForumOrigin__c = 'formulario pymes'));
        testforumOriginAssignmentMetadata.add(new ForumOriginAssignment__mdt(DeveloperName = 'formulario_embarcaciones', AssignmentType__c = 'Municipality',AssignTo__c='IDIOMA-QQ',ForumOrigin__c = 'formulario embarcaciones'));
        testforumOriginAssignmentMetadata.add(new ForumOriginAssignment__mdt(DeveloperName = 'formulario_salud', AssignmentType__c = 'Municipality',AssignTo__c='IDIOMA-QQ',ForumOrigin__c = 'formulario salud'));

        AccountLeadAssignment.forumOriginAssignmentMetadata = testforumOriginAssignmentMetadata;

        //MUNICIPALITY ASSIGNMENT
        List<MunicipalityAssignment__mdt> testMunicipalityAssignmentMetadata = new List<MunicipalityAssignment__mdt>();
        testMunicipalityAssignmentMetadata.add(new MunicipalityAssignment__mdt(DeveloperName = 'X01520', AssignTo__c= 'IDIOMA-ES', PostalCode__c= 25000));

        AccountLeadAssignment.MunicipalityAssignmentMetadata = testMunicipalityAssignmentMetadata;

        //PROVINCE ASSIGNMENT
        List<ProvinceAssignment__mdt> testProvinceAssignmentMetadata = new List<ProvinceAssignment__mdt>();
        testProvinceAssignmentMetadata.add(new ProvinceAssignment__mdt(DeveloperName = 'Albacete',AssignTo__c='IDIOMA-FR',PostalCode__c=2,Province__c='Albacete'));

        AccountLeadAssignment.ProvinceAssignmentMetadata = testProvinceAssignmentMetadata;
    }


    /**
     * @description Test que asegura que si se recibe el valor CONTACT_CENTER se devuelve
     *              ese valor.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_getAssignedUserIdByIntermediaryCode_CONTACTCENTER_OK()
    {
        String contactCenter = 'CONTACT_CENTER';

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByIntermediaryCode(contactCenter);
        Test.stopTest();

        Assert.areEqual(contactCenter, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'Para el valor de CONTACT CENTER, no ha devuelto CONTACT_CENTER');
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
        String intermediaryCode = 'IDIOMA-QQ';
        User intermediary = [SELECT Id FROM User WHERE LastName = :intermediaryCode];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByIntermediaryCode(intermediaryCode);
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>(result.getAssignmentAsMap().keySet()).get(0), 'No es el intermediario esperado');
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

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0), 'No ha duelto el usuario por defecto');
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

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0), 'No ha duelto el usuario por defecto');
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
        setMetadataConfigurations();

        User intermediary = [SELECT Id FROM User WHERE LastName = 'IDIOMA-FR'];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByLanguage('FR');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'No es el intermediario para este idioma');
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
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByLanguage(null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0), 'No ha devuelto el usuario por defecto');
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
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByLanguage('IT');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0), 'No ha devuelto el usuario por defecto');
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
        setMetadataConfigurations();

        User intermediary = [SELECT Id FROM User WHERE LastName = 'IDIOMA-ES'];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByAssignmentType('formulario accidentes', null);
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>(result.getAssignmentAsMap().keySet()).get(0), 'No ha devuelto el intermediario esperado');
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
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByAssignmentType(null, null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0), 'No ha devuelto el usuario por defecto');
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
        setMetadataConfigurations();

        User intermediary = [SELECT Id FROM User WHERE LastName = 'IDIOMA-FR'];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByAssignmentType('formulario automonos', '02000');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>(result.getAssignmentAsMap().keySet()).get(0), 'No ha devuelto el intermediario esperado');
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
        setMetadataConfigurations();

        User intermediary = [SELECT Id FROM User WHERE LastName = 'IDIOMA-ES'];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getAssignedUserIdByAssignmentType('formulario embarcaciones', '25000');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'No ha devuelto el intermediario esperado');
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
        setMetadataConfigurations();

        User intermediary = [SELECT Id FROM User WHERE LastName = 'IDIOMA-ES'];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserDirectly('formulario accidentes');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'No se ha conseguido el intermediario esperado');
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
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserDirectly('formulario desconocido');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'No se ha asignado al usuario por defecto');
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
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserDirectly(null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'No se ha asignado al usuario por defecto');
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
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        AccountLeadAssignment.forumOriginAssignmentMetadata.add(new ForumOriginAssignment__mdt
        (
            DeveloperName = 'formulario_asignacion',
            AssignmentType__c = 'Direct',
            ForumOrigin__c = 'formulario asignacion')
        );

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserDirectly('formulario asignacion');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'No ha devuelto el usuario por defecto');
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
        setMetadataConfigurations();

        User intermediary = [SELECT Id FROM User WHERE LastName = 'IDIOMA-ES'];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByMunicipality('25000');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'No se ha conseguido el intermediario esperado');
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
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByMunicipality(null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'Tendría que haber devuelto el usuario por defecto');
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
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByMunicipality('12639');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'Tendría que haber devuelto el usuario por defecto');
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
        setMetadataConfigurations();

        AccountLeadAssignment.MunicipalityAssignmentMetadata.add(new MunicipalityAssignment__mdt(DeveloperName = 'X01520', PostalCode__c= 12639));

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByMunicipality('12639');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'Tendría que haber devuelto el usuario por defecto');
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
        setMetadataConfigurations();

        User intermediary = [SELECT Id FROM User WHERE LastName = 'IDIOMA-FR'];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByProvince('02365');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'No se ha asignado el intermediario esperado');
    }

    /**
     * @description Test que recupera al usuario por defecto en caso de indicar un valor nulo.
     * @author      jgallaga
     * @date        16/08/2023
     */
    @isTest
    static void test_assignedUserByProvince_null_KO()
    {
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByProvince(null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'No se ha asignado el intermediario esperado');
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
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByProvince('15000');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'No se ha asignado el intermediario esperado');
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
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        AccountLeadAssignment.ProvinceAssignmentMetadata.add(new ProvinceAssignment__mdt(
            DeveloperName = 'Albacete',PostalCode__c=17,Province__c='Albacete'));

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.assignedUserByProvince('17845');
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'No se ha asignado el intermediario esperado');
    }

    /**
     * @description Test para comprobar la correcta configuración de asignación por origen de formulario
     * @author      jgallaga
     * @date        16/08/2023
     */
    @istest
    static void test_getAssigmentType_OK()
    {
        setMetadataConfigurations();

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
        setMetadataConfigurations();

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
        setMetadataConfigurations();

        AccountLeadAssignment.forumOriginAssignmentMetadata.add(new ForumOriginAssignment__mdt
        (
            DeveloperName = 'formulario_test',
            AssignTo__c='IDIOMA-QQ',
            ForumOrigin__c = 'formulario test'));

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
        User intermediary = [SELECT Id FROM User WHERE LastName = 'IDIOMA-FR'];

        Test.startTest();
        AccountLeadAssignment.Assignment result = AccountLeadAssignment.getIntermediaryUserId('IDIOMA-FR');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'No se ha encontrado al intermediario esperado');
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

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'No ha devuelto al usuario por defecto.');
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

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'No ha devuelto al usuario por defecto.');
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

        Assert.areEqual(defaultAgenteId, new List<String>(result.getAssignmentAsMap().keySet()).get(0),'No ha devuelto al usuario por defecto.');
    }
}