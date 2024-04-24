/**
 * @description       : Clase de test que comprueba el correcto funcionamiento
 * de la clase 'Batch_IntermediaryOrAccountChangeDML'.
 * @author            : amiranda
 * @date              : 11-04-2024
 * @last modified on  : 11-04-2024
 * @last modified by  : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   11-04-2024   amiranda   Initial Version
 **/
@IsTest
private with sharing class Batch_IntermediaryOrAccountChangeDMLTest
{

    /**
    * @description Método para inicializar los datos de prueba
    * @author amiranda
    * @date 11-04-2024 
    **/
    @TestSetup
    private static void makeData()
    {
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

        List<Account> customers = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 2);
        insert customers;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(customers, 1);
        for (Policy__c policy : policies)
        {
            policy.IntermediaryId__c = intermediaryAccounts.get(0).Id;
        }
        insert policies;
    }

    /**
    * @description Método de test que comprueba que se insertan y eliminan
    * AccountTeamMember desde el batch 'Batch_IntermediaryOrAccountChangeDML'
    * @author amiranda
    * @date 11-04-2024 
    **/
    @IsTest
    private static void test_executeBatch_insertAndDelete()
    {
        List<Policy__c> policies = [SELECT VisibilityRetry__c FROM Policy__c LIMIT 1];
        List<AccountTeamMember> atms = [SELECT UserId, AccountId, TeamMemberRole FROM AccountTeamMember];

        List<AccountTeamMember> atmsToInsert = new List<AccountTeamMember>();
        for (AccountTeamMember atm : atms)
        {
            atmsToInsert.add( atm.clone(false, true, false, false) );
        }

        Test.startTest();
        Database.executeBatch( new Batch_IntermediaryOrAccountChangeDMLs(policies,
                                                                         atms,
                                                                         atmsToInsert,
                                                                         10000) );
        Test.stopTest();

        List<AccountTeamMember> atmsInserted = [SELECT Id FROM AccountTeamMember];
        Assert.areEqual(atms.size(), atmsInserted.size(), 'El número total de AccountTeamMembers debería ser el mismo.');
    }

    /**
    * @description Método de test que comprueba que se capturan los errores
    * correctamente en la ejecución del batch 'Batch_IntermediaryOrAccountChangeDML'
    * @author amiranda
    * @date 11-04-2024 
    **/
    @IsTest
    private static void test_executeBatch_ko()
    {
        List<Policy__c> policies = [SELECT VisibilityRetry__c FROM Policy__c LIMIT 1];
        List<AccountTeamMember> atms = [SELECT Id FROM AccountTeamMember];

        List<AccountTeamMember> atmsToInsert = new List<AccountTeamMember>();
        for (AccountTeamMember atm : atms)
        {
            atmsToInsert.add( atm.clone(false, false, false, false) );
        }

        Test.startTest();
        Database.executeBatch( new Batch_IntermediaryOrAccountChangeDMLs(policies,
                                                                         atms,
                                                                         atmsToInsert,
                                                                         10000) );
        Test.stopTest();

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        Assert.isTrue(!errors.isEmpty(), 'La lista de errores no debería estar vacía.');
    }

    /**
    * @description Método de test que comprueba que se eliminan los AccountTeamMember
    * desde el batch 'Batch_IntermediaryOrAccountChangeDML'
    * @author amiranda
    * @date 11-04-2024 
    **/
    @IsTest
    private static void test_executeBatch_delete()
    {
        List<Policy__c> policies = [SELECT VisibilityRetry__c FROM Policy__c LIMIT 1];
        List<AccountTeamMember> atmsToDelete = [SELECT Id FROM AccountTeamMember];

        Test.startTest();
        Database.executeBatch( new Batch_IntermediaryOrAccountChangeDMLs(policies,
                                                                         atmsToDelete,
                                                                         new List<AccountTeamMember>(),
                                                                         10000) );
        Test.stopTest();

        List<AccountTeamMember> atms = [SELECT LastModifiedDate FROM AccountTeamMember];
        Assert.isTrue(atms.isEmpty(), 'La lista de AccountTeamMembers debería estar vacía');
    }

    /**
    * @description Método de test que comprueba que se insertan los AccountTeamMember
    * desde el batch 'Batch_IntermediaryOrAccountChangeDML'
    * @author amiranda
    * @date 11-04-2024 
    **/
    @IsTest
    private static void test_executeBatch_insert()
    {
        List<Policy__c> policies = [SELECT VisibilityRetry__c FROM Policy__c LIMIT 1];
        List<AccountTeamMember> atms = [SELECT LastModifiedDate, UserId, AccountId, TeamMemberRole FROM AccountTeamMember];

        List<AccountTeamMember> atmsToInsert = new List<AccountTeamMember>();
        for (AccountTeamMember atm : atms)
        {
            atmsToInsert.add( atm.clone(false, true, false, false) );
        }

        Test.startTest();
        Database.executeBatch( new Batch_IntermediaryOrAccountChangeDMLs(policies,
                                                                         new List<AccountTeamMember>(),
                                                                         atmsToInsert,
                                                                         10000) );
        Test.stopTest();

        List<AccountTeamMember> atmInserted = new List<AccountTeamMember>([SELECT LastModifiedDate FROM AccountTeamMember]);
        Assert.areEqual(atmInserted.size(),
                        atms.size(),
                        'Debe haber el mismo número de atms'); 
    }
}