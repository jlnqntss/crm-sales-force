@isTest
private with sharing class PolicyUtilTest
{
    private static final String BUSINESS_CODE = '320000001';

    @TestSetup
    private static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;
        accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'PartnerOCS', 1);
        accounts[0].INFOBusinessCode__c = BUSINESS_CODE;
        insert accounts;

        /** Insertar usuarios ZRM ***************************************************************/
        // Crear cuentas de agrupacion
        List<Account> agrupaciones = TestDataFactory.generateAccounts(Label.GeneralInsurance,'AgrupacionMediador', 1);
        insert agrupaciones;
        // Crear cuentas de mediadores
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 2);
        intermediaryAccounts.get(0).IntermediaryGroup__c = agrupaciones.get(0).Id;
        intermediaryAccounts.get(0).Name = 'MediadorTest';
        intermediaryAccounts.get(1).Name = 'MediadorTest2';
        insert intermediaryAccounts;

        // Crear contactos de mediadores
        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(intermediaryAccounts, ContactsSelector.RT_NAME_CONTACT, 2);
        insert contacts;

        // Crear los usurios para recuperar
        List<User> userList = new List<User>();
        List<User> userAGRList = new List<User>();

        List<String> adminProfiles = new List<String> {'Administrador del sistema', 'System Administrator'};
        List<Boolean> activeStatus = new List<Boolean> {true};
        User adminUser = ( new UsersSelector() ).findByProfileName(adminProfiles, activeStatus, 1)[0];

        System.runAs (adminUser)
        {
            // Usuario Nominal
            String portalProfile = [SELECT Id FROM Profile WHERE Name = 'Agente Ventas' LIMIT 1].Id;

            userList = TestDataFactory.generateUsersByProfile(portalProfile, 1);
            userList[0].ContactId = contacts[0].Id;
            insert userList;

            // Usuario AGR
            String portalAGRProfile = [SELECT Id FROM Profile WHERE Name = 'Agente Ventas - AGR' LIMIT 1].Id;

            userAGRList = TestDataFactory.generateUsersByProfile(portalAGRProfile, 1);            
            userAGRList[0].ContactId = contacts[1].Id;

            insert userAGRList;
        }
    }

    /**
     * Test que comprueba la generación del ámbito correspondiente para cada póliza
     *
     * @author adelgado
     * @date 08/01/2021
     */
    @isTest
    private static void test_generateScope()
    {
        List<Account> accounts = [SELECT Name FROM Account WHERE RecordType.DeveloperName = 'BusinessCustomer'];

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);

        Test.startTest();
        insert policies;
        Test.stopTest();

        List<Scope__c> scopes = [SELECT Id, Name FROM Scope__c WHERE AccountId__c IN : accounts];
        List<Policy__c> policiesUpdated = [SELECT Scope__c, ScopeId__c FROM Policy__c];

        System.assertEquals(10, scopes.size(), 'No se han generado todos los ámbitos necesarios');
        System.assertEquals(10, policiesUpdated.size(), 'No se han generado todas las pólizas');

        for(Policy__c policy : policiesUpdated)
        {
            System.assert (String.isNotBlank(policy.Scope__c), 'No se ha informado la picklist de scope');
            System.assert (policy.ScopeId__c != null, 'No se ha asignado el scope correspondiente');
        }
    }

    /**
     * Test que comprueba la generación del partner correspondiente para cada poliza
     *
     * @author nts (agonzalezisasi)
     * @date 10/05/2021
     */
    @isTest
    private static void test_generatePartner()
    {
        List<Account> accounts = [SELECT Name FROM Account WHERE RecordType.DeveloperName != 'PartnerOCS'];
        
        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);
        policies[0].BusinessCode__c = BUSINESS_CODE;
        
        Test.startTest();
        insert policies;
        Test.stopTest();

        List<Policy__c> policiesWithPartner = [SELECT Id FROM Policy__c WHERE Partner__c != null];
        System.assertEquals(1, policiesWithPartner.size(), 'No se ha informado del partner de la poliza');
    }

    @isTest
    private static void test_visibilityZRM() {
        List<AccountTeamMember> atmBefore = new List<AccountTeamMember>([SELECT Id FROM AccountTeamMember]);

        List<Account> accounts = [SELECT Name FROM Account WHERE RecordType.DeveloperName = 'BusinessCustomer' LIMIT 1];
        User zrmIntermediary = [SELECT Id, Contact.AccountId FROM User WHERE Profile.Name = 'Agente Ventas' AND  Contact.Account.Name = 'MediadorTest' LIMIT 1];

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);        
        policies[0].IntermediaryId__c = zrmIntermediary.Contact.AccountId;

        Test.startTest();
        insert policies;
        Test.stopTest();


        List<AccountTeamMember> atmAfter = new List<AccountTeamMember>([SELECT Id FROM AccountTeamMember]);

        System.assertNotEquals(atmBefore.size(), atmAfter.size(), 'Deben de haberse insertado nuevos registros de ATM');
    }


    @isTest
    private static void test_visibilityUpdatePolicyHolderZRM() {

        // Insertamos una poliza
        List<Account> accounts = [SELECT Name FROM Account WHERE RecordType.DeveloperName = 'BusinessCustomer' LIMIT 1];
        User zrmIntermediary = [SELECT Id, Contact.AccountId FROM User WHERE Profile.Name = 'Agente Ventas' AND  Contact.Account.Name = 'MediadorTest' LIMIT 1];

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);        
        policies[0].IntermediaryId__c = zrmIntermediary.Contact.AccountId;

        insert policies;

        // actualizamos el el cliente de la poliza
        List<Account> otherAccount = [SELECT Name FROM Account WHERE RecordType.DeveloperName = 'BusinessCustomer' AND Id != :accounts.get(0).Id LIMIT 1];
        policies[0].PolicyHolder__c = otherAccount.get(0).Id;

        Test.startTest();
        update policies;
        Test.stopTest();

        List<Policy__c> policiesWithChage = new List<Policy__c>([SELECT Id FROM Policy__c WHERE LastDateIntermediaryOrAccountChange__c != NULL LIMIT 1]);

        Assert.isTrue(policiesWithChage.size() > 0, 'Debe haber ofertas con el campo LastDateIntermediaryOrAccountChange__c informado');
    }


    @isTest
    private static void test_visibilityUpdateIntermediaryZRM() {

        // Insertamos una poliza

        List<Account> accounts = [SELECT Name FROM Account WHERE RecordType.DeveloperName = 'BusinessCustomer' LIMIT 1];
        User zrmIntermediary = [SELECT Id, Contact.AccountId FROM User WHERE Profile.Name = 'Agente Ventas' AND  Contact.Account.Name = 'MediadorTest' LIMIT 1];

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);        
        policies[0].IntermediaryId__c = zrmIntermediary.Contact.AccountId;

        insert policies;

        // actualizamos el el cliente de la poliza
        List<Account> otherIntermediary = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Intermediary' AND Name = 'MediadorTest2' LIMIT 1];
        policies[0].IntermediaryId__c = otherIntermediary.get(0).Id;

        Test.startTest();
        update policies;
        Test.stopTest();

        List<Policy__c> policiesWithChage = new List<Policy__c>([SELECT Id FROM Policy__c WHERE LastDateIntermediaryOrAccountChange__c != NULL LIMIT 1]);

        Assert.isTrue(policiesWithChage.size() > 0, 'Debe haber ofertas con el campo LastDateIntermediaryOrAccountChange__c informado');
    }
}
