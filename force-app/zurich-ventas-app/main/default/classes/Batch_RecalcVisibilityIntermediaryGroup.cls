/**
 * Batch que se ejecuta de forma diaria y que se encarga de recalcular la visibilidad de las agrupaciones en caso que se haya producido un cambio.
 * 
 * @author nts (dmunoz)
 * @date 15/02/2024
 *
 */

global with sharing class Batch_RecalcVisibilityIntermediaryGroup implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

    private static final String CLASS_NAME = 'Batch_RecalcVisibilityIntermediaryGroup';

    private Integer numDMLs = 5000;
    private List<Account> intermediariesToProcess; // guarda los mediadores a procesar por el batch


    /*********** Constructores **************************************************************************/
    public Batch_RecalcVisibilityIntermediaryGroup(Integer numDMLs) {
        this.numDMLs = numDMLs;
        this.intermediariesToProcess = new List<Account>();
    }

    public Batch_RecalcVisibilityIntermediaryGroup(List<Account> intermediariesToProcess, Integer numDMLs) {
        this.numDMLs = numDMLs;
        this.intermediariesToProcess = intermediariesToProcess;
    }

    
    /*********** Invocar Schedule Batch **************************************************************************/
    /**
     * Método para programar de forma sencilla al batch 
     * @param jobName: nombre del batch a ejecutar (opcional)
     * @param timeExpression: expresion CRON para programar el batch
     * @return String: job id
     * @author dmunoz
     * @date 15/02/2024
     */
    public static String createStandardSchedule(String jobName, String timeExpression, Integer numDMLs) {
        jobName = setJobName(jobName);
        timeExpression = setTimeExpression(timeExpression);
        
        return System.schedule(jobName, timeExpression, new Batch_RecalcVisibilityIntermediaryGroup(numDMLs));
    }


    /*********** Métodos Schedulable **************************************************************************/
    /**
     * Método execute necesario por la interfaz Schedulable
     * @param sc: Contexto Schedulable
     * @return void
     * @author dmunoz
     * @date 15/02/2024
     */
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new Batch_RecalcVisibilityIntermediaryGroup(numDMLs), 200);               
    }     

    /*********** Métodos Batch **************************************************************************/
    /**
     * Metodo start del batch, devuelve la lista de mediadores a procesar los recálculos de visibilidad. Hay dos tipo de entrada por query o por lista de mediadores en caso de querer invocar desde consola 
     * @param bc: batch context
     * @return List ofertas a modificar
     * @author dmunoz
     * @date 15/02/2024
     */
    global List<Account> start(Database.BatchableContext bc) { 
        
        // si no hay elementos en intermediariesToProcess lanzamos la consulta de BD
        if (intermediariesToProcess.isEmpty()) {
            intermediariesToProcess.addAll((new AccountsSelector()).findIntermediariesWithGroupChanges());
            return intermediariesToProcess; 
        } else {
            return intermediariesToProcess;
        }
    }


    /**
     * Metodo execute del batch, 
     * @param bc: batch context
     * @param scope lista de Opportunity procedentes del método start
     * @return void
     * @author dmunoz
     * @date 15/02/2024
     */
    global void execute(Database.BatchableContext bc, List<Account> scope) {
        try {

            // Do nothing este batch solo se encarga de lanzar el primero de los resultados encontrados
            
        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }
    
    /**
     * Metodo finish del batch, generamos una llamada al batch Batch_RecalcVisibilityIntermediary para que 
     * @param bc: batch context
     * @return void
     * @author dmunoz
     * @date 15/02/2024
     */
    global void finish(Database.BatchableContext bc) {
        if (!Test.isRunningTest()) {
            Database.executeBatch(new Batch_RecalcVisibilityIntermediary(intermediariesToProcess, false, numDMLs), numDMLs);   
        }
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
            jobName = 'Batch_RecalcVisibilityIntermediaryGroup';
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