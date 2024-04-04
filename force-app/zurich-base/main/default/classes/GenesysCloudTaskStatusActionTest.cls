@isTest
public with sharing class GenesysCloudTaskStatusActionTest 
{
    @isTest
    static void test_genesysCloudTaskStatusActionTest_ok()
    {
        Case relatedCase = new Case();
        relatedCase.RecordTypeId = CaseUtil.RT_ID_OCSINQUIRY;
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

        Test.startTest();
        List<List<String> > inserciones = GenesysCloudTaskStatusAction.execute(listaTasks);
        Test.stopTest();

        List<String> listaStatus = new List<String>();
        if (inserciones.size() > 0)
        {
            listaStatus = inserciones.get(0);
        }

        System.assertEquals( 1, listaStatus.size() );
    }
}