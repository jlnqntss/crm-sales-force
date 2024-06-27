@isTest
public with sharing class TaskSelectorTest 
{
    @isTest
    static void test_TaskSelector_ok()
    {
        Case relatedCase = new Case();
        List<Case> listaCaso = new List<Case>();
        relatedCase.RecordTypeId = CaseUtil.RT_ID_USPINQUIRY;
        
        insert relatedCase;

        listaCaso.add(relatedCase);
        
        //Tareas vinculadas casos
        
        List<Task> listaTask = new List<Task>();
        Task task = new Task();
            task.Status = 'Nueva';
            task.WhatId = relatedCase.Id;
            task.Subject = 'test status';
            task.Type='Email';
            task.Subtype__c='Note Info';

            listaTask.add(task);

        Task task2 = new Task();
            task2.Status = 'Nueva';
            task2.WhatId = relatedCase.Id;
            task2.Subject = 'test status';
            task2.Type='Email';
            task2.Subtype__c='Note Info';

            listaTask.add(task2);

        Task task3 = new Task();
            task3.Status = 'Nueva';
            task3.WhatId = relatedCase.Id;
            task3.Subject = 'test status';
            task3.Type='Email';
            task3.Subtype__c='Email';

            listaTask.add(task3);

        insert listaTask;
       

        List<Task> listaTareas = new List <Task> ();

        Test.startTest();
        listaTareas = new TaskSelector().getTaskRelatedWithCases(listaCaso);
        Test.stopTest();

        System.assertEquals(2,listaTareas.size());
        
    }


    @isTest
    static void test_getTaskFromSingleChannel_ok()
    {
        //Importante usar el RT Customer porque es personal account y se necesita que esté relleno PersonContactId
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1); //Importante que solo se cree 1 porque sino habrá varios con mismo email
        insert accounts;

        List<Case> lstCases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        insert lstCases;

        List<Task> listaTask = new List<Task>();
        Task task = new Task();
            task.Status = 'Nueva';
            task.WhatId = lstCases[0].Id;
            task.Subject = 'test status';
            task.Type='Email';
            task.Subtype__c='Single channel';

        Task task2 = new Task();
            task2.Status = 'Nueva';
            task2.WhatId = lstCases[0].Id;
            task2.Subject = 'test status';
            task2.Type='Email';
            task2.Subtype__c='Single channel';

        listaTask.add(task);
        listaTask.add(task2);
        insert listaTask;

        Test.startTest();
        List<Task> listaTareasFull = new TaskSelector().getTaskFromSingleChannel(lstCases);
        List<Task> listaTareasEmpty = new TaskSelector().getTaskFromSingleChannel(new List<Case> ());
        Test.stopTest();

        Assert.isFalse(listaTareasFull.isEmpty());
        Assert.isTrue(listaTareasEmpty.isEmpty());
    }



}