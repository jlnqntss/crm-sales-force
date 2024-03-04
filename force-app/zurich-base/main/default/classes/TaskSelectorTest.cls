@isTest
public with sharing class TaskSelectorTest 
{
    @isTest
    static void test_TaskSelector_ok()
    {
        Case relatedCase = new Case();
        List<Case> listaCaso = new List<Case>();
        relatedCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('USPInquiry').getRecordTypeId();
        
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

}