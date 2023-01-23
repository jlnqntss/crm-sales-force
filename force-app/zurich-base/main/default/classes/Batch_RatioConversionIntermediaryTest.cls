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

        //Se crean casos 
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('USPInquiry').getRecordTypeId();
        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 4);
        insert cases;

        CasesSelector casesSel = new CasesSelector();

        for(case c:cases)
        {
            c.RecordTypeId=caseRecordTypeId;
        }

        //Casos de la primera cuenta
        cases[0].Status='Closed';
        cases[0].QuotationStage__c='Won';
        cases[1].Status='Asigned';
        cases[2].Status='Asigned';
        cases[3].Status='Asigned';

        //Casos de la segunda cuenta
        cases[4].Status='Closed';
        cases[4].QuotationStage__c='Won';
        cases[5].Status='Combinado';
        cases[6].Status='Combinado';
        cases[7].Status='Asigned';

        update cases;

    }



    @IsTest
    static void Batch_RatioConversionIntermediaryTest_OK()
    {
        Batch_RatioConversionIntermediary batch= new Batch_RatioConversionIntermediary();


        Test.startTest();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();

        List<Account> allAccountsUpdate= [SELECT USPConversionRatio__c FROM Account];
       
        //Primera cuenta 1 caso won de 4 // Ratio debe ser 0.25
        System.assertEquals(0.25,allAccountsUpdate[0].USPConversionRatio__c);
        
        //Segunda cuenta 1 caso ganado 2 combinados 1 asignado // Ratio debe ser 0.5
        System.assertEquals(0.5,allAccountsUpdate[1].USPConversionRatio__c);

    }
}