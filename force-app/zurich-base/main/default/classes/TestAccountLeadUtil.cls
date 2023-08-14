/**
 * @description       : Test funcionales de la asignación de Leads a Agentes.
 * @author            : jgallaga
 * @group             : Seidor
 * @last modified on  : 14/08/2023
 * @last modified by  : jgallaga
**/
@IsTest
public with sharing class TestAccountLeadUtil
{
    @TestSetup
    static void makeData()
    {
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


        for(String currentCommunityName : communityUserNames)
        {
            agentAccounts.put(currentCommunityName, new Account(
                Name = currentCommunityName,
                RecordTypeId = agentAccountRecordType.Id,
                INFOIntermediaryCode__c = currentCommunityName
            ));
        }

        insert agentAccounts.values();

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
        List<ForumOriginAssignment__mdt> testforumOriginAssignmentMetadata = new List<ForumOriginAssignment__mdt>();
        testforumOriginAssignmentMetadata.add(new ForumOriginAssignment__mdt(DeveloperName = 'formulario_accidentes', AssignmentType__c = 'Direct',AssignTo__c='IDIOMA-ES',ForumOrigin__c = 'formulario accidentes'));
        testforumOriginAssignmentMetadata.add(new ForumOriginAssignment__mdt(DeveloperName = 'formulario_automonos', AssignmentType__c = 'Province',AssignTo__c='IDIOMA-FR',ForumOrigin__c = 'formulario automonos'));
        testforumOriginAssignmentMetadata.add(new ForumOriginAssignment__mdt(DeveloperName = 'formulario_embarcaciones', AssignmentType__c = 'Municipality',AssignTo__c='IDIOMA-FR',ForumOrigin__c = 'formulario embarcaciones'));

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


    /*** ASSIGNMENT BY INTERMEDIARY CODE ***/

    @isTest
    static void test_intermediaryCodeContactCenter_OK()
    {
        String contactCenter = 'CONTACT_CENTER';

        Test.startTest();
        String result = AccountLeadUtil.leadAssignment(null, contactCenter, null, null, null);
        Test.stopTest();

        Assert.areEqual(contactCenter, result, 'No se ha devuelto el valor de contact center');
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
        User intermediary = [SELECT Id FROM User WHERE LastName = 'IDIOMA-ES'];

        Test.startTest();
        // Indicando el código de intermeadiario, el resto de parametros no se tienen en cuenta
        String assignedId = AccountLeadUtil.leadAssignment(new Account(), 'IDIOMA-ES', 'origen', 'idioma', 'código postal');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, assignedId, 'No es el intermediario correcto');
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
        String assignedId = AccountLeadUtil.leadAssignment(null, 'MadeUp Intermediary Code', null, null, null);
        Test.stopTest();

        Assert.areEqual(defaultUserId, assignedId, 'Se debería haber asignado el intermediario por defecto');
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
        User intermediary = [SELECT Id FROM User WHERE LastName = 'IDIOMA-QQ'];
        Account intermediaryAccount = [SELECT Id FROM Account WHERE INFOIntermediaryCode__c = 'IDIOMA-QQ'];

        Account testAccount = new Account(Name = 'TestAccount', Intermediary_Name__c = intermediaryAccount.Id);
        insert testAccount;
        testAccount = [SELECT Intermediary_Name__r.INFOIntermediaryCode__c FROM Account Where Id = :testAccount.Id];

        Test.startTest();
        String assignedId = AccountLeadUtil.leadAssignment(testAccount, null, 'origin', 'language', 'postalCode');
        Test.stopTest();

        Assert.areEqual(intermediary.Id, assignedId, 'No se ha asignado el intermediario esperado');
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
        Account testAccount = new Account(Name = 'TestAccount');

        Test.startTest();
        String assignedId = AccountLeadUtil.leadAssignment(testAccount, null, 'origin', 'language', 'postalCode');
        Test.stopTest();

        Assert.areEqual(defaultUserId, assignedId, 'No se ha asignado el intermediario esperado');
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
        testAccount = [SELECT Intermediary_Name__r.INFOIntermediaryCode__c FROM Account Where Id = :testAccount.Id];

        Test.startTest();
        String assignedId = AccountLeadUtil.leadAssignment(testAccount, null, 'origin','language', 'postalcode');
        Test.stopTest();

        Assert.areEqual(defaultUserId, assignedId, 'No se ha asignado el usuario por defecto');
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

        String frenchAgenteId = [SELECT Id FROM User WHERE Lastname = 'IDIOMA-FR'].Id;

        Test.startTest();
        String resultAssignmentUserId = AccountLeadUtil.leadAssignment(null, null, 'formulario test', 'FR', '99999');
        Test.stopTest();

        Assert.areEqual(frenchAgenteId, resultAssignmentUserId, 'El usuario asignado para el lenguaje frances no es correcto.');
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
        String resultAssignmentUserId = AccountLeadUtil.leadAssignment(null,null,null,'QQ',null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, resultAssignmentUserId, 'El usuario asignado para el lenguaje que no tiene configuración definida no es correcto.');
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
    static void test_AssigmentDirectly_OK()
    {
        setMetadataConfigurations();

        User intermediary = [SELECT ID FROM User WHERE LastName = 'IDIOMA-ES'];

        Test.startTest();
        String assignedId = AccountLeadUtil.leadAssignment(null, null, 'formulario accidentes','ES', null);
        Test.stopTest();

        Assert.areEqual(intermediary.Id, assignedId, 'No se ha asignado directamente al intermadiario esperado.');
    }

}