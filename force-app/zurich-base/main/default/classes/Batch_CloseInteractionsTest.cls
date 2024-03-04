/**
 * Clase de test para el batch RelateCasesToNewAccountsBatch
 * @author jjuaristi@seidor.es
 * @date 20/10/2022
 */
@IsTest
public with sharing class Batch_CloseInteractionsTest
 {
    @TestSetup
    static void makeData()
    {
        Id idUSp=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('USPInquiry')?.getRecordTypeId();
            
        Case caseEmail= new Case();
        caseEmail.Subject='test Email ';
        caseEmail.status='New';
        caseEmail.Origin='Email';
        caseEmail.SourceArea__c='Mediator';
        caseEmail.Type='Venta';
        caseEmail.Subtype__c='Emisión';
        caseEmail.RecordTypeId=idUSp;
        caseEmail.CloseInteractionBatch__c=true;
        caseEmail.ExpectedClosingDate__c= System.TODAY();

        insert caseEmail;

        Case caseNoteINFO= new Case();
        caseEmail.Subject='test INFO';
        caseEmail.status='New';
        caseEmail.Origin='Email';
        caseEmail.SourceArea__c='Mediator';
        caseEmail.Type='Venta';
        caseEmail.Subtype__c='Emisión';
        caseEmail.RecordTypeId=idUSp;
        caseEmail.CloseInteractionBatch__c=true;
        caseEmail.ExpectedClosingDate__c= System.TODAY();

        insert caseNoteINFO;

        EmailMessage randomEmail= new EmailMessage();
        randomEmail.Subject = 'testsubject';
        randomEmail.FromAddress = 'fromaddress@nts-solutions.com.invalid';
        randomEmail.ToAddress = 'toaddress@nts-solutions.com.invalid';
        randomEmail.Incoming = true;
        randomEmail.GenesysInteractionId__c='1788029f-ad65-41ea-bc5f-ce41673fe109';
        randomEmail.RelatedToId=caseEmail.Id;

        insert randomEmail;

        Task task = new Task();
        task.Status = 'Nueva';
        task.WhatId = caseNoteINFO.Id;
        task.Subject = 'test status';
        task.Type='Email';
        task.Subtype__c='Note Info';

        insert task;
    }

    @IsTest
    static void test_CloseInteractions_OK()
    {
        Test.startTest();
        Database.executeBatch(new Batch_CloseInteractions());
        System.assertNotEquals(2,Batch_CloseInteractions.testCount);
        Test.stopTest();

    }
}