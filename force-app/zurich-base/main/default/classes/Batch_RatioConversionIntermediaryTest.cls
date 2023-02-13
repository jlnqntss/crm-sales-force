/**
 * Clase de test para el batch Batch_RatioConversionIntermediary
 * @author lrodriguez6@seidor.es
 * @date 20/01/2023
 */
@IsTest
public with sharing class Batch_RatioConversionIntermediaryTest 
{
    @TestSetup
    static void makeData()
    {
        //Se crean cuentas 
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary',2);
        insert accounts;

        accounts[0].Status__c='001';
        accounts[1].Status__c='002';
        
        update accounts;

        //Se crean casos 
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('USPInquiry').getRecordTypeId();
        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 4);
        insert cases;


        for(case c:cases)
        {
            c.RecordTypeId=caseRecordTypeId;
            c.Type='Venta';
        }

        //Casos de la primera cuenta
        cases[0].Status='Assigned';
        cases[0].QuotationStage__c='Quoted';
        cases[1].Status='Assigned';
        cases[2].Status='Assigned';
        cases[3].Status='Assigned';

        //Casos de la segunda cuenta
        cases[4].Status='Assigned';
        cases[4].QuotationStage__c='Quoted';
        cases[5].Status='Combinado';
        cases[6].Status='Combinado';
        cases[7].Status='Assigned';
        update cases;
        cases[0].QuotationStage__c='Work in Progress';
        cases[2].QuotationStage__c='Work in Progress';
        cases[4].QuotationStage__c='Work in Progress';
        cases[7].QuotationStage__c='Work in Progress';

        update cases;
        cases[0].QuotationStage__c='Won';
        cases[4].QuotationStage__c='Won';
        cases[2].QuotationStage__c='Lost';
        cases[2].QuotationStage__c='Won';

        cases[2].Status='Cerrado';
        cases[0].Status='Cerrado';
        cases[4].Status='Cerrado';
        cases[7].Status='Cerrado';

        update cases;
    }



    @IsTest
    static void test_RatioConversionIntermediaryTest_OK()
    {
        Batch_RatioConversionIntermediary batch= new Batch_RatioConversionIntermediary();
        List<Case> cases = [SELECT Id, Status, QuotationStage__c,AccountId FROM Case];
        cases[0].QuotationStage__c='Won';
        cases[4].QuotationStage__c='Won';
        cases[7].QuotationStage__c='Won';
        update cases;
        
        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        List<Account> allAccountsUpdate= [SELECT USPConversionRatio__c FROM Account];
       
        //Primera cuenta 1 caso won de 4 // Ratio debe ser 0.25
        System.assertEquals(50,allAccountsUpdate[0].USPConversionRatio__c);
        
        //Segunda cuenta 1 caso ganado 2 combinados 1 asignado // Ratio debe ser 0.5
        System.assertEquals(100,allAccountsUpdate[1].USPConversionRatio__c);

    }
}