/**
 * Batch que se ejecuta de forma diaria y se encarga de terminar las ofertas que el mediador no ha podido terminar (cerrada ganada/perdida) asociadas a una campaña de venta cruzada, asi como completar las tareas relacionadas 
 * 
 * @author nts (dmunoz)
 * @date 06/10/2023
 *
 */
global with sharing class Batch_FinishCrossSellingCampaign implements Database.Batchable<sObject>, Schedulable {

    private static final String CLASS_NAME = 'Batch_FinishCrossSellingCampaign';


     /*********** Invocar Schedule Batch **************************************************************************/
    /**
     * Método para programar de forma sencilla al batch 
     * @param jobName: nombre del batch a ejecutar (opcional)
     * @param timeExpression: expresion CRON para programar el batch
     * @return String: job id
     * @author dmunoz
     * @date 06/10/2023
     */
    public static String createStandardSchedule(String jobName, String timeExpression) {
        jobName = setJobName(jobName);
        timeExpression = setTimeExpression(timeExpression);
        
        return System.schedule(jobName, timeExpression, new Batch_FinishCrossSellingCampaign());
    }


    /*********** Métodos Schedulable **************************************************************************/
    /**
     * Método execute necesario por la interfaz Schedulable
     * @param sc: Contexto Schedulable
     * @return void
     * @author dmunoz
     * @date 06/10/2023
     */
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new Batch_FinishCrossSellingCampaign(), 200);               
    }




    /*********** Métodos Batch **************************************************************************/
    /**
     * Metodo start del batch, devuelve la lista de ofertas a las que hay que modificar la etapa y motivo de cierre
     * @param bc: batch context
     * @return List ofertas a modificar
     * @author dmunoz
     * @date 06/10/2023
     */
    global Database.QueryLocator start(Database.BatchableContext bc) { 
        return Database.getQueryLocator((new OpportunitiesSelector()).findCrossSellingCampaignNotClosedOffer());        
    }


    /**
     * Metodo execute del batch, 
     * @param bc: batch context
     * @param scope lista de Opportunity procedentes del método start
     * @return void
     * @author dmunoz
     * @date 06/10/2023
     */
    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        try {

            // Modificar los registros obtenidos por la query
            Map<Id, Opportunity> offersToUpdate = updateOffers(scope);

            // actualizar las ofertas
            update offersToUpdate.values();

            // completar las tareas asociadas 
            List<Task> completedTaskList = TaskUtil.completeTaskByWhatId(offersToUpdate.keySet());

            if (completedTaskList != null && !completedTaskList.isEmpty()) {
                update completedTaskList;
            }
            
        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }
    
    /**
     * Metodo finish del batch, 
     * @param bc: batch context
     * @return void
     * @author dmunoz
     * @date 06/10/2023
     */
    global void finish(Database.BatchableContext bc) {
        // nothing
    }




    /******************************************************************************************* Métodos auxiliares ************************************************************************************************/

    /**
     * Actualizar la información de oferta para cambiar la etapa a Cerrada-Perdida y seleccionar un motivo de cierre
     * @param bc: batch context
     * @return void
     * @author dmunoz
     * @date 06/10/2023
     */
    private Map<Id, Opportunity> updateOffers(List<Opportunity> scope) {
        Map<Id, Opportunity> result = new Map<Id, Opportunity>();

        for (Opportunity o: scope) {
            
            if ('Legit Lead'.equals(o.StageName)) {
                o.Sales_Loss_Reason__c = GlobalConfigUtil.getGlobalConfigurationValue('Offer_SalesLossReason_NotManagedByAgent');
                
            } else { // solo llegarán App Submitted, Quoted

                o.Sales_Loss_Reason__c = GlobalConfigUtil.getGlobalConfigurationValue('Offer_SalesLossReason_CampaignCompleted');
            }

            o.StageName = 'Closed Lost';
            
            result.put(o.Id, o);
        }

        return result;
    }


    /******************************************************************************************* Métodos auxiliares Schedule****************************************************************************************/
    /**
     * Dar un nombre por defecto al Job programado en caso de no informar este valor
     * @param jobName: Nombre del batch programado
     * @return String
     * @author dmunoz
     * @date 06/10/2023
     */
    private static String setJobName(String jobName) {
        if (String.isEmpty(jobName)){
            jobName = 'Ventas_Batch_FinishCrossSellingCampaign';
        } 
        return jobName; 
    }

    /**
     * Dar una expresión CRON por defecto al Job programado en caso de no informar este valor
     * @param timeExpression: Expresión CRON a utilizar
     * @return String
     * @author dmunoz
     * @date 06/10/2023
     */
    private static String setTimeExpression(String timeExpression) {
        if (String.isEmpty(timeExpression)){
            timeExpression = '0 0 5 * * ?' ; 
        } 
        return timeExpression; 
    }

}