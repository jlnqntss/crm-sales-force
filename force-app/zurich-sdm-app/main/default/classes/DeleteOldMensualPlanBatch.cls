/**
 * Batch que se encarga de eliminar los planes mensuales anteriores a una fecha
 * 
 * @author nts (dmunoz)
 * @date 09/09/2022
 *
 */
global with sharing class DeleteOldMensualPlanBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    private static final String CLASS_NAME = 'DeleteOldMensualPlanBatch';
    private String query;
    private Integer numMonths;    
    

    /*********** Constructores Batch ********************************************************************/
    public DeleteOldMensualPlanBatch(Integer numMonths) {
        this.numMonths = numMonths;
    }

    public DeleteOldMensualPlanBatch(String query) {
        this.query = query;
    }

    /*********** Métodos Batch **************************************************************************/
    /**
     * Metodo start del batch, devuelve la lista de elementos que se eliminarán en el paso execute
     * @param bc: batch context
     * @return List los planes mensuales que se eliminarán
     * @author dmunoz
     * @date 09/09/2022
     */
    global List<PlanComercial__c> start(Database.BatchableContext bc) {        
        if(String.isBlank(query)) {
            Date maxDate = getMaxDate(numMonths);
            return (new PlanComercialSelector()).findMensualPlanToDeleteByMaxDate(maxDate);

        } else {
            return (List<PlanComercial__c>) Database.query(query);
        }
    }
      
    /**
     * Metodo execute del batch, se ejecutará un borrado de datos N veces en paquetes de 10k registros (ver método createStandardScheduleByQuery y createStandardScheduleByDate)
     * @param bc: batch context
     * @param scope lista de planes mensuales a borrar procedentes del método start
     * @return void
     * @author dmunoz
     * @date 09/09/2022
     */
    global void execute(Database.BatchableContext bc, List<PlanComercial__c> scope) {
        try {
            if ( scope != null && !scope.isEmpty() ) {
                delete scope;
            }
        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        // nothing
    }

    /*********** Métodos Schedule ***********************************************************************/

    /**
     * Método para programar de forma sencilla al batch pasando una query como parámetro
     * @param jobName: nombre del batch a ejecutar (opcional)
     * @param timeExpression: expresion CRON para programar el batch
     * @param query consulta SOQL para obtener los datos a borrar
     * @return String: job id
     * @author dmunoz
     * @date 09/09/2022
     */
    public static String createStandardScheduleByQuery(String jobName, String timeExpression, String query) {
        jobName = setJobName(jobName);
        timeExpression = setTimeExpression(timeExpression);   
        
        return System.schedule(jobName, timeExpression, new DeleteOldMensualPlanBatch(query));
    }

    /**
     * Método para programar de forma sencilla al batch pasando una fecha como parámetro
     * @param jobName: nombre del batch a ejecutar (opcional)
     * @param timeExpression: expresion CRON para programar el batch
     * @param numMonths los planes mensuales con fecha fin anteriores a esta fecha serán objetivo de esta batch y por lo tanto eliminados
     * @return String: job id
     * @author dmunoz
     * @date 09/09/2022
     */
    public static String createStandardScheduleByDate(String jobName, String timeExpression, Integer numMonths) {
        jobName = setJobName(jobName);
        timeExpression = setTimeExpression(timeExpression);
        
        return System.schedule(jobName, timeExpression, new DeleteOldMensualPlanBatch(numMonths));
    }

    /**
     * Método execute necesario por la interfaz Schedulable
     * @param sc: Contexto Schedulable
     * @return void
     * @author dmunoz
     * @date 09/09/2022
     */
    global void execute(SchedulableContext sc) {
        Integer numRecordsToDelete = getNumRecordsToDelete();     
        if (numMonths != null) {
            Database.executeBatch(new DeleteOldMensualPlanBatch(numMonths), numRecordsToDelete);
        } else {
            Database.executeBatch(new DeleteOldMensualPlanBatch(query), numRecordsToDelete);
        }        
    }


    /*********** Métodos Auxiliares *********************************************************************/
    
    /**
     * Obtengo de forma dinámica la fecha a partir de la que borraremos los planes mensuales
     * @param numMonths: Numero de meses a restar a la fecha actual
     * @return Date
     * @author dmunoz
     * @date 13/09/2022
     */
    private Date getMaxDate(Integer numMonths) {
        Date today = Date.today();

        return today.addMonths(numMonths * -1);
    }

    /**
     * Obtener el numero de registros a procesar por el batch, valor inicial 10000
     * @return Integer
     * @author dmunoz
     * @date 13/09/2022
     */
    private Integer getNumRecordsToDelete() {
        String numRecordsToDeleteMDT = 'NumRecordsToDeleteOldMensualPlanBatch';
        AdminSetupParameter__mdt adminSetupParameterMDT = AdminSetupParameter__mdt.getInstance(numRecordsToDeleteMDT);

        String numRecordsToDeleteString = adminSetupParameterMDT.Value__c;

        if (String.isEmpty(numRecordsToDeleteString)) {
            throw new HandledException('Se debe informar un valor para el registro NumRecordsToDeleteOldMensualPlanBatch de la metadata Admin Setup Parameter');
        } 

        return Integer.valueOf(numRecordsToDeleteString);
    }

    /**
     * Dar un nombre por defecto al Job programado en caso de no informar este valor
     * @param jobName: Nombre del batch programado
     * @return String
     * @author dmunoz
     * @date 09/09/2022
     */
    private static String setJobName(String jobName) {
        if( String.isBlank(jobName) ){
            jobName = 'SDM Automatismos Eliminar Plan Mensuales';
        } 
        return jobName; 
    }

    /**
     * Dar una expresión CRON por defecto al Job programado en caso de no informar este valor
     * @param timeExpression: Expresión CRON a utilizar
     * @return String
     * @author dmunoz
     * @date 09/09/2022
     */
    private static String setTimeExpression(String timeExpression) {
        if( String.isBlank(timeExpression) ){
            timeExpression = '0 0 5 1 * ?' ; 
        } 
        return timeExpression; 
    }

}
