@isTest
public with sharing class RemoveDuplicatesActionTest 
{
    
    @isTest
    static void test_removeDuplicates_OK()
    {
        Id caseUspRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('USPInquiry').getRecordTypeId();
        Case casoPrueba= new Case(RecordTypeId=caseUspRecordType,Subject='Test caso',Status='New',Origin='Phone',
                                  SourceArea__c='Partner',Type='Venta',Subtype__c='Apoyo Captación',TypeN3__c='Con oferta');
        Case casoDiferente= new Case(RecordTypeId=caseUspRecordType,Subject='Test caso2',Status='New',Origin='Phone',
                                  SourceArea__c='Partner',Type='Venta',Subtype__c='Apoyo Captación',TypeN3__c='Con oferta');
        List<Case> listaCasosRepetidos=new List<Case>();

        //Este bucle tiene como función repetir el caso para ver si se elimina en el método
        for (Integer i=0; i<4;i++)
        {
            listaCasosRepetidos.add(casoPrueba);
        }

        listaCasosRepetidos.add(casoDiferente);

        String fieldApi='Subject';

        RemoveDuplicatesAction.FlowInputs flowInput= new RemoveDuplicatesAction.FlowInputs();
		flowInput.listToRemove=listaCasosRepetidos;
        flowInput.fieldApiName=fieldApi;
        List<List<Case>> listaReturn= new List<List<Case>>();
        List<RemoveDuplicatesAction.FlowInputs> listFlowInputs= new List<RemoveDuplicatesAction.FlowInputs>();
        listFlowInputs.add(flowInput);

        Test.startTest();
        listaReturn= RemoveDuplicatesAction.removeDuplicates(listFlowInputs);
        Test.stopTest();
        
        System.assertEquals(2, listaReturn[0].size());
    }
}
