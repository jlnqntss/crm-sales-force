/**
 * @description       : Test funcionales de la asignación de Leads a Agentes.
 * @author            : jgallaga
 * @group             : Seidor
 * @last modified on  : 12/08/2023
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
        List<LanguageAssignment__mdt> testLanguageAssignmentMetadata = new List<LanguageAssignment__mdt>();
        testLanguageAssignmentMetadata.add(new LanguageAssignment__mdt(DeveloperName = 'Español', AssignTo__c = 'IDIOMA-ES', Language__c = 'ES'));
        testLanguageAssignmentMetadata.add(new LanguageAssignment__mdt(DeveloperName = 'Frances', AssignTo__c = 'IDIOMA-FR', Language__c = 'FR'));

        AccountLeadAssignment.languageAssignmentMetadata = testLanguageAssignmentMetadata;
    }

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
    static void test_AssignmentMadeUpLanguageToDefaultAgent_OK()
    {
        setMetadataConfigurations();

        String defaultAgenteId = AccountLeadAssignment.getDefaultZRMAccountLeadOwnerId();

        Test.startTest();
        String resultAssignmentUserId = AccountLeadUtil.leadAssignment(null,null,null,'QQ',null);
        Test.stopTest();

        Assert.areEqual(defaultAgenteId, resultAssignmentUserId, 'El usuario asignado para el lenguaje que no tiene configuración definida no es correcto.');
    }

}