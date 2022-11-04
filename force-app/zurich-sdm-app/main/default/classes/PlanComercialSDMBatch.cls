/**
 * Batch que se encarga de relizar los siguientes automatismos para los Mediadores del proyecto SDM (Sales Digital 
 * 
 * @author nts (agonzalezisasi)
 * @date 05/07/2021
 *
 */
global class PlanComercialSDMBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable
{
    private static final String CLASS_NAME = 'PlanComercialSDMBatch';
    private String query;
    
    @TestVisible
    private Boolean testUnknownError;

    private PlanComercialSDM sdm;

    /**
     * Constructor
     */
    global PlanComercialSDMBatch()
    {
        sdm = new PlanComercialSDM();
    }

    
    /**
     * Constructor. Use a custom query
     */
    global PlanComercialSDMBatch(String p_query)
    {
        this();

        query = p_query;
    }

    //------------------------------------------------------------------------- batchable methods

    /**
     * Start. Execute the query locator for the batch
     */
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        if( String.isBlank(query) ) {
            Date todayValue = System.today();
            
            if( Test.isRunningTest() ) todayValue = Date.newInstance(2021, 9, 10);

            // SDM-729 - Añadimos la ordenacion por tipo acumulado (YTD, Mensual) para que, en la medida de lo posible, 
            // los lotes sean solo de planes mensuales o anuales. Para minimizar el numero de KPIs recuperados
            return Database.getQueryLocator([
                SELECT Id, CreatedById, AssignedTo__c, StartDate__c, EndDate__c,
                       Indicator__c, Intermediary__c, Product__c, Segment__c, AccumulateType__c
                FROM PlanComercial__c
                WHERE StartDate__c <= :todayValue AND EndDate__c >= :todayValue
                ORDER BY AccumulateType__c
            ]);
        } else {
            return Database.getQueryLocator(query);
        }
    }

    /**
     * Execute. The method for each batch
     */
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        if ( scope != null && !scope.isEmpty() ) {
            try {
                

                if( Test.isRunningTest() && testUnknownError != null && testUnknownError ) 
                    throw new PlanComercialSDMBatchException('Unknown Error');                    

                List<PlanComercial__c> plans = (List<PlanComercial__c>)scope;

                sdm.calculateRealKPI(plans);

                
            } catch (Exception e) {
                ErrorLogUtil.commitError(e, CLASS_NAME);
            }
        }
    }

    /**
     * Finish. The postprocesing method
     */
    global void finish(Database.BatchableContext BC)
    {}

    
    //------------------------------------------------------------------------- schedulable methods

    public static String createStandardSchedule(String jobName, String timeExpression, String query)
    {
        if( String.isBlank(jobName) ) jobName = 'SDM Automatismos Plan Comercial';
        if( Test.isRunningTest() ) jobName = 'Test ' + jobName;

        if( String.isBlank(timeExpression) ) timeExpression = '0 0 07 * * ?';
        
        return System.schedule(jobName, timeExpression, new PlanComercialSDMBatch(query));
    }

    /**
     * Execute. The method for the scheduled batch
     */
    global void execute(SchedulableContext SC)
    {
        // SDM-729 - Se reduce el numero de planes a procesar cada vez para minimizar el numero de KPIs a considerar en cada
        // lote del batch
        Database.executeBatch(new PlanComercialSDMBatch(query), 20);
    }

    private class PlanComercialSDMBatchException extends Exception {}
}
