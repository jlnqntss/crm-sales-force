/*
 * Esta acción es llamada desde un flow para obtener los registros de casos de los cuales se quieren cerrar las interacciones
 * @author lrodriguez6@seidor.es
 * @date 13/12/2023
 */

 public class GetCaseCloseInteractions {
    /*
     * Método que obtiene los registros de los casos de los que se quiere cerrar la interaccion
     * Una vez que los recupera, activa el check closeInteractions y actualiza estos registros con el nuevo valor
     * Como parametro de entrada tiene una lista de String donde están los IDs de los casos a obtener
     * @author lrodriguez6@seidor.es
     * @date 13/12/2023
     * @param List<String>  Registros recibidos desde el flow
     * @return void Lista de respuestas que reciben los flows
     */

     @InvocableMethod
     (  
         label='Get Cases Close Interactions' 
         description='Active checkbox closeInteractions'
     )
     public static void getCaseCloseInteractions(List<List<String>> flowInputs)
     {
        getCaseCloseInteractionsFuture(flowInputs[0]);
     }

     @future
     public static void getCaseCloseInteractionsFuture(List<String> flowInputs)
     {
        List<Case> listCases= new List<Case>();

        listCases= [SELECT  CloseInteraction__c FROM Case WHERE Id IN: flowInputs ];


        for(case c:listCases)
        {
            c.CloseInteraction__c=true;
        }
        
        update listCases;

         
     }
}

