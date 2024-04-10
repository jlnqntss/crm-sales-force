/**
 Proceso que obtiene aquellas polizas y ofertas que hayan sufrido un cambio de cliente o cambio de mediador
 * 
 * @author dmunoz
 * @date 04/04/2024
 **/

global with sharing class Batch_IntermediaryOrAccountChangeZRM implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    private static final String CLASS_NAME = 'Batch_IntermediaryOrAccountChangeZRM';
    private static final String ZRM_NUM_MAX_RETRIES = 'ZRMNumMaxRetries';

    private Integer numDMLs = 5000;
    private List<sObject> recordsToProcess;

    public Batch_IntermediaryOrAccountChangeZRM(Integer numDMLs) {
        this.recordsToProcess = new List<sObject>();
        this.numDMLs = numDMLs;
    }


    /******************** Métodos Schedulable ******************************************************/
    /**
     * Método para programar de forma sencilla al batch 
     * @param jobName: nombre del batch a ejecutar (opcional)
     * @param timeExpression: expresion CRON para programar el batch
     * @return String: job id
     * @author dmunoz
     * @date 04/04/2024
     */
    public static String createStandardSchedule(String jobName, String timeExpression, Integer numDMLs) {
        jobName = setJobName(jobName);
        timeExpression = setTimeExpression(timeExpression);
        
        return System.schedule(jobName, timeExpression, new Batch_IntermediaryOrAccountChangeZRM(numDMLs));
    }


    /**
     * Método execute necesario por la interfaz Schedulable
     * @param sc: Contexto Schedulable
     * @return void
     * @author dmunoz
     * @date 04/04/2024
     */
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new Batch_IntermediaryOrAccountChangeZRM(numDMLs), numDMLs);               
    }

    /******************** Métodos Batch ******************************************************/

    /**
     * Obtenemos la información de pólizas y ofertas que han cambiado de tomador o mediador en las últimas 24 horas y no se han reprocesado más de 3 veces
     * @author dmunoz
     * @date 04/04/2024
     */
    public List<sObject> start(Database.BatchableContext bc) {

        // Obtengo el valor de la metadata del número de intentos
        AdminSetupParameter__mdt numMaxRetriesMTD = AdminSetupParameter__mdt.getInstance(ZRM_NUM_MAX_RETRIES);

        List<Policy__c> policiesToProcess = (new PoliciesSelector()).getPoliciesToProcessIntermediaryOrAccountChange(Integer.valueOf(numMaxRetriesMTD.Value__c));
        List<Opportunity> offersToProcess = (new OpportunitiesSelector()).getOffersToProcessIntermediaryOrAccountChange(Integer.valueOf(numMaxRetriesMTD.Value__c));

        recordsToProcess.addAll(policiesToProcess);
        recordsToProcess.addAll(offersToProcess);
    
        return recordsToProcess;
    }

    /**
     * Este proceso solo se encarga de iniciar el proceso por lo que el método execute está vacío para enviar la información y calcularlo de manera individual de forma controlada
     * @author dmunoz
     * @date 04/04/2024
     */
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        // Do nothing este batch solo se encarga de lanzar el primero de los resultados encontrados
    }


    global void finish(Database.BatchableContext bc) {
        if (!Test.isRunningTest() && recordsToProcess != null && !recordsToProcess.isEmpty()) {
            Database.executeBatch(new Batch_ProcessIntermediaryOrAccountChange(recordsToProcess, numDMLs), numDMLs);    
        }
    }



    /******************** Métodos Auxiliares ******************************************************/
    /**
     * Dar un nombre por defecto al Job programado en caso de no informar este valor
     * @param jobName: Nombre del batch programado
     * @return String 
     * @author dmunoz
     * @date 04/04/2024
     */
    private static String setJobName(String jobName) {
        if (String.isEmpty(jobName)){
            jobName = 'Batch_IntermediaryOrAccountChangeZRM';
        } 
        return jobName; 
    }

    /**
     * Dar una expresión CRON por defecto al Job programado en caso de no informar este valor
     * @param timeExpression: Expresión CRON a utilizar
     * @return String
     * @author dmunoz
     * @date 04/04/2024
     */
    private static String setTimeExpression(String timeExpression) {
        if (String.isEmpty(timeExpression)){
            timeExpression = '0 0 3 * * ?' ; 
        } 
        return timeExpression; 
    }
    
}