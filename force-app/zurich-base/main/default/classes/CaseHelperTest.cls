/**
 * Clase de test para la clase Helper de Caso
 * @author acortazar@seidor.es
 * @date 25/06/2024
 */
@IsTest
private with sharing class CaseHelperTest 
{
    @TestSetup
    private static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;

        // Crear casos relacionados con los intermediarios
        List<Case> lstCases = TestDataFactory.generateCasesForEachAccount(accounts, 4);
        
        lstCases[0].Subject='test Email ';
        lstCases[0].status='New';
        lstCases[0].Origin='Email';
        lstCases[0].ExpectedClosingDate__c= System.TODAY();

        lstCases[1].Subject='test INFO';
        lstCases[1].status='New';
        lstCases[1].Origin='Single channel';
        lstCases[1].ExpectedClosingDate__c= System.TODAY();

        insert lstCases;

        EmailMessage randomEmail= new EmailMessage();
        randomEmail.Subject = 'testsubject';
        randomEmail.FromAddress = 'fromaddress@nts-solutions.com.invalid';
        randomEmail.ToAddress = 'toaddress@nts-solutions.com.invalid';
        randomEmail.Incoming = true;
        randomEmail.GenesysInteractionId__c='1788029f-ad65-41ea-bc5f-ce41673fe109';
        randomEmail.GenesysQueueName__c='QUEUE_PRUEBA';
        randomEmail.RelatedToId=lstCases[0].Id;

        insert randomEmail;

        Task task = new Task();
        task.Status = 'Nueva';
        task.WhatId = lstCases[1].Id;
        task.Subject = 'test status';
        task.Type='Email';
        task.Subtype__c='Single channel';
        task.CallObject = '1788029f-ad65-41ea-bc5f-ce41673fe200';

        insert task;
    }

    @IsTest
    private static void test_CloseInteractions_OK()
    {
        List<Case> casos = [SELECT Id FROM Case];
        List<String> idsCasos = new List<String>();
        for (Case caso : casos)
        {
            idsCasos.add(caso.Id);
        }

        Test.startTest();
        CaseHelper.closeInteractions(idsCasos);
        Test.stopTest();

        Assert.isFalse(CaseHelper.testingResult.isEmpty());
        for(List<String> outString : CaseHelper.testingResult)
        {
            System.debug('++++ outString: ' + outString[0]);
            Assert.isTrue(outString[0].contains('disconnected'));
        }
    }
}