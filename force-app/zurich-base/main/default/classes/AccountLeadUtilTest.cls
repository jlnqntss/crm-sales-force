/**
 * @description       : Clase de test para la clase AccountsSelector
 * @author            : overes
 * @group             :
 * @created           : 16-08-2023
**/
@isTest
private class AccountLeadUtilTest
{
    /**
     * Se inicialian los datos necesarios para el test
     * *
     * @author overes
     * @date 16/08/2023
     */
    @TestSetup
    static void makeData()
    {
        List<Account> leadAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Lead', 2);
        leadAccounts.get(0).NationalId__c = '222';
        leadAccounts.get(1).Phone = '6666';
        insert leadAccounts;

        List<Account> customerAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 2);
        customerAccounts.get(0).NationalId__c = '333';
        customerAccounts.get(1).Phone = '444';
        insert customerAccounts;

        TestDataFactorySDM.IntermediarySetupData();
    }

    /**
     * Validar que se comprueba el duplicado de lead con un phone informado
     * *
     * @author overes
     * @date 16/08/2023
     */
    @isTest
    static void testRecTypeLeadPhone()
    {
        List<Account> a = [SELECT Id,Phone FROM account WHERE Phone = '6666'];

        Test.startTest();
        Account acc = AccountLeadUtil.leadDuplicatesControl(null, a.get(0).Phone);
        Test.stopTest();

        System.assertNotEquals(null,acc, 'No hay duplicados con el teléfono indicado');
    }

    /**
     * Validar que se comprueba el duplicado de lead con el NationalId informado
     * *
     * @author overes
     * @date 16/08/2023
     */
    @isTest
    static void testRecTypeLeadNationalId()
    {
        List<Account> a = [SELECT Id,NationalId__c FROM account WHERE NationalId__c = '222'];

        Test.startTest();
        Account acc = AccountLeadUtil.leadDuplicatesControl(a.get(0).NationalId__c, null);
        Test.stopTest();

        System.assertNotEquals(null,acc, 'No hay duplicados con le National Id indicado');
    }

    /**
     * Validar que se comprueba el duplicado de Customer con un National Id informado
     * *
     * @author overes
     * @date 16/08/2023
     */
    @isTest
    static void testRecTypeCustomerNationalId()
    {
        List<Account> a = [SELECT Id,NationalId__c FROM account WHERE NationalId__c = '333'];

        Test.startTest();
        Account acc = AccountLeadUtil.leadDuplicatesControl(a.get(0).NationalId__c, null);
        Test.stopTest();

        System.assertNotEquals(null,acc, 'No hay duplicados con le National Id indicado');
    }

    /**
     * Validar que se comprueba el duplicado de lead con un listado de cuentas informado
     * *
     * @author overes
     * @date 16/08/2023
     */
    @isTest
    static void testcheckLeads()
    {
        List<Account> a = [SELECT Id,NationalId__c,Phone,RecordType.DeveloperName FROM account WHERE NationalId__c = '222'];

        Test.startTest();
        List<Account> acc = AccountLeadUtil.checkLeads(a);
        Test.stopTest();

        System.assertNotEquals(null,acc, 'No hay duplicados con le National Id indicado');

    }

    /**
     * Validar que se comprueba el caso que le lleguen todos los valores a null
     * *
     * @author overes
     * @date 16/08/2023
     */
    @isTest
    static void testNull()
    {
        Test.startTest();
        Account acc = AccountLeadUtil.leadDuplicatesControl(null, null);
        Test.stopTest();

        System.assertEquals(null,acc, 'No hay duplicados con el teléfono');
    }

    @isTest
    static void test_NewLeadVentasAccounts_CreateScope_OK()
    {
        Id accountLeadRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Lead').getRecordTypeId();

        List<Account> newAccounts = new List<Account>();

        for(Integer i = 0; i < 4 ; i++)
        {
            newAccounts.add(new account(
                LastName = 'Test'+i,
                RecordTypeId = accountLeadRecordTypeId,
                Phone = '1111'+i
            ));
        }

        Test.startTest();
        insert newAccounts;
        Test.stopTest();

        Map<Id,Account> insertedAccount = new Map<Id,Account>(newAccounts);

        List<Scope__c> scopes = [SELECT Scope__c From Scope__c WHERE AccountId__c IN : newAccounts];

        Assert.areEqual(insertedAccount.size(), scopes.size());
    }

    @isTest
    static void test_UpdateLeadVentasPhone_CreateScope_OK()
    {
        Id accountLeadRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Lead').getRecordTypeId();

        List<Account> oldAccounts = new List<Account>();

        for(Integer i = 0; i < 4; i++)
        {
            oldAccounts.add(new Account(
                LastName = 'Test'+i,
                RecordTypeId = accountLeadRecordTypeId
            ));
        }

        insert oldAccounts;

        for(Integer i = 0; i < 4; i++)
        {
            oldAccounts[i].Phone = '0000' + i;
        }

        Test.startTest();
        update oldAccounts;
        Test.stopTest();

        List<Scope__c> scopes = [SELECT Scope__c FROM Scope__c WHERE AccountId__c IN : oldAccounts];

        Assert.areEqual(oldAccounts.size(), scopes.size());

    }
}