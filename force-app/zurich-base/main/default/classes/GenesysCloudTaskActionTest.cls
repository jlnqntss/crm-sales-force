@isTest
public with sharing class GenesysCloudTaskActionTest 
{
    @isTest
    static void test_genesysCloudTaskActionTest_status_ok()
    {
        Case relatedCase = new Case();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId();
        relatedCase.LegalEntity__c = Label.GeneralInsurance;
        insert relatedCase;

        Task task = new Task();
        task.Status = 'Nueva';
        task.WhatId = relatedCase.Id;
        task.Subject = 'test status';
        task.CallObject = '1788029f-ad65-41ea-bc5f-ce41673fe109';
        insert task;

        List<Task> listaTemp = new List<Task>();
        listaTemp.add(task);

        List<List<Task>> listaTasks = new List<List<Task>>();
        listaTasks.add(listaTemp);

        String body = '{"id": "1788029f-ad65-41ea-bc5f-ce41673fe109",'
                      + '"participants": [{"id": "20714c8e-9a60-4efd-9e75-0efb4b95267f","name": "Javier García Martínez", "purpose": "customer", "state": "disconnected"},'
                      + '{"id": "25fcb71d-9ff3-4c45-8a07-091831376cdd", "name": "Email_CCS_Soporte", "purpose": "acd", "state": "connected"},'
                      + '{"id": "77f648d0-354f-4d07-8540-14604b87bffc", "name": "Agente1","purpose": "agent","state": "connected"}]}';
        Integer code = 200;
        GenesysCloud.StatusService.mock = new GenesysCloudMocks(body, code);

        Test.startTest();
        List<List<String> > inserciones = GenesysCloudTaskAction.execute(listaTasks);
        Test.stopTest();

        List<String> listaStatus = new List<String>();
        if (inserciones.size() > 0)
        {
            listaStatus = inserciones.get(0);
        }

        System.assertEquals( 1, listaStatus.size() );
    }
}
