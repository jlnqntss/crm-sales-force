/**
 * @description       : 
 * @author            : rserrano
 * @group             : 
 * @last modified on  : 11/09/2024
 * @last modified by  : rserrano
**/
@isTest
public class TriggerBypassUtilityTest 
{
    static final String NO_BLOQUEADO_NI_ANONIMIZADO = 'No bloqueado ni anonimizado';
    
    @testSetup
    static void setupTestData() 
    {

        List<Account> customerLst = TestDataFactory.generateAccounts('001', 'Customer', 20);

        for(Integer i = 0; i < customerLst.size(); i++)
        {
            if(i <= 4)
            {
                customerLst.get(i).LastName = 'Bloqueado y anonimizado';
                customerLst.get(i).Blocked__c = true;
                customerLst.get(i).Anonymized__c = true;
            } 
            else if (i <= 9)
            {
                customerLst.get(i).LastName = 'Bloqueado';
                customerLst.get(i).Blocked__c = true;
                customerLst.get(i).Anonymized__c = false;
            } else if (i <= 14)
            {
                customerLst.get(i).LastName = 'Anonimizado';
                customerLst.get(i).Blocked__c = false;
                customerLst.get(i).Anonymized__c = true;
            } else 
            { 
                customerLst.get(i).LastName = NO_BLOQUEADO_NI_ANONIMIZADO;
                customerLst.get(i).Blocked__c = false;
                customerLst.get(i).Anonymized__c = false;
            }
        }

        insert customerLst;
    }
    
    /**
    * @description     : Test que prueba el método gdprBypass(List<sObject> triggerRecords) de la clase TriggerBypassUtility
    * @author rserrano | 10/09/2024 
    **/
    @isTest
    static void testGdprBypassBeforeHandler() 
    {
        // Obtener los registros de prueba creados en el método testSetup
        List<Account> accounts = [SELECT Id, Name, Blocked__c, Anonymized__c FROM Account];

        Test.startTest();
        
        List<Account> result = TriggerBypassUtility.gdprBypass(accounts);

        Test.stopTest();
        
        System.assertEquals(5, result.size(), 'Debe haber 5 registros que no estén bloqueados ni anonimizados');
        
        for (Account acc : result)
        {
            System.assertEquals(NO_BLOQUEADO_NI_ANONIMIZADO, acc.Name, 'El nombre del registro debería ser \'' + NO_BLOQUEADO_NI_ANONIMIZADO + '\'');
        }
    }
    
    /**
    * @description     : Test que prueba el método gdprBypass(List<sObject> triggerRecords, Map<Id, sObject> oldMap) de la clase TriggerBypassUtility
    * @author rserrano | 10/09/2024 
    **/
    @isTest
    static void testGdprBypassAfterHandlerWithOldMap() 
    {
        // Obtener los registros de prueba creados en el método testSetup
        List<Account> accounts = [SELECT Id, Name, Blocked__c, Anonymized__c FROM Account];
        
        // Crear un mapa oldMap para simular los valores anteriores en un after trigger
        Map<Id, Account> oldMap = new Map<Id, Account>([SELECT Id, Blocked__c, Anonymized__c FROM Account WHERE Id IN :accounts]);
        
        // Modificar algunos registros como si el campo Blocked__c hubiera cambiado
        for (Account customer : accounts)
        {
            if(customer.Name == 'Anonimizado')
            {
                customer.Blocked__c = true;
            }
        }

        Test.startTest();
        
        List<Account> result = TriggerBypassUtility.gdprBypass(accounts, oldMap);

        Test.stopTest();

        System.assertEquals(15, result.size(), 'Debe haber 15 registros que no están bloqueados ni anonimizados');
    }
    
    /**
    * @description     : Test que prueba el método gdprBypass(Map<Id, sObject> oldMap) de la clase TriggerBypassUtility
    * @author rserrano | 10/09/2024 
    **/
    @isTest
    static void testGdprBypassWithOldMapOnly() 
    {
        // Obtener los registros de prueba creados en el método testSetup
        Map<Id, Account> oldMap = new Map<Id, Account>([SELECT Id, Name, Blocked__c, Anonymized__c FROM Account]);

        Test.startTest();

        // Ejecutar el método gdprBypass que solo usa el oldMap
        List<Account> result = TriggerBypassUtility.gdprBypass(oldMap);

        Test.stopTest();
        
        System.assertEquals(5, result.size(), 'Debe haber 5 registros que no estén bloqueados ni anonimizados');

        for(Account acc : result)
        {
            System.assertEquals(NO_BLOQUEADO_NI_ANONIMIZADO, acc.Name, 'El nombre del registro debe ser \'' + NO_BLOQUEADO_NI_ANONIMIZADO + '\'');
        }
    }
    
    /**
    * @description     : Test que prueba el método throwExceptionIfBlockedOrAnonymized(List<sObject> triggerRecords, Map<Id, sObject> oldMap) de la clase TriggerBypassUtility
    * @author rserrano | 10/09/2024 
    **/
    @isTest
    static void testThrowExceptionIfBlockedOrAnonymized() 
    {
        // Obtener los registros de prueba creados en el método testSetup
        List<Account> accounts = [SELECT Id, LegalEntity__c, Blocked__c, Anonymized__c FROM Account];
        
        // Crear un mapa oldMap para simular los valores anteriores
        Map<Id, Account> oldMap = new Map<Id, Account>([SELECT Id, LegalEntity__c, Blocked__c, Anonymized__c FROM Account WHERE Id IN :accounts]);

        // Ejecutar el método throwExceptionIfBlockedOrAnonymized
        Test.startTest();

        TriggerBypassUtility.throwExceptionIfBlockedOrAnonymized(accounts, oldMap);

        Test.stopTest();

        for(Account acc : accounts)
        {
            if(acc.Blocked__c == true || acc.Anonymized__c == true)
            {
                System.assert(! acc.getErrors().isEmpty(), 'El registro debería tener un error');
            }
        }
    }
}