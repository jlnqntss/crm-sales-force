/*
 * Esta acción es llamada desde un flow para obtener los registros de casos de los cuales se quieren cerrar las interacciones
 * meidante batch 
 * @author lrodriguez6@seidor.es
 * @date 14/02/2024
 */

 public with sharing class GetCaseCloseBatchInteractions {
    /*
     * Método que obtiene los registros de los casos de los que se quiere cerrar la interacción mediante batch
     * Una vez recuperados, activa el check CloseInteractionBatch__c y fija el campo ExpectedClosingDate al día en el que se pulsa el boton
     * Cerrar Interacciones Bartch y actualiza estos registros con los nuevos valores
     * Como parametro de entrada tiene una lista de String donde están los IDs de los casos a obtener
     * @author lrodriguez6@seidor.es
     * @date 14/02/2024
     * @param List<String>  Registros recibidos desde el flow
     */

     @InvocableMethod
     (  
        label = 'Get Cases Close Interactions' 
        description = 'Active checkbox closeInteractions'
     )

     public static void getCaseCloseBatchInteractions(List<List<String>> flowInputs)
     {
        getCaseCloseBatchInteractionsFuture(flowInputs[0]);
     }

     @future
     public static void getCaseCloseBatchInteractionsFuture(List<String> flowInputs)
     {
        List<Case> listCases = new List<Case>();

        listCases = [SELECT  CloseInteractionBatch__c,ExpectedClosingDate__c FROM Case WHERE Id IN: flowInputs ];

        for(case c:listCases)
        {
            c.CloseInteractionBatch__c = true;
            c.ExpectedClosingDate__c = System.TODAY();
        }
        
        update listCases;
   
     }
}