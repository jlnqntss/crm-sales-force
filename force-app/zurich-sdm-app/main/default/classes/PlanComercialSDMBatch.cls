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
            return Database.getQueryLocator([
                SELECT Id, CreatedById, AssignedTo__c,
                       Indicator__c, Intermediary__c, Product__c, Segment__c, AccumulateType__c
                FROM PlanComercial__c
                WHERE StartDate__c <= :System.today() AND EndDate__c >= :System.today()
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
                // System.debug('------ BEFORE => Queries: ' + Limits.getQueries() + ' / DML: ' + Limits.getDmlStatements() );

                if( Test.isRunningTest() && testUnknownError != null && testUnknownError ) 
                    throw new PlanComercialSDMBatchException('Unknown Error');                    

                List<PlanComercial__c> plans = (List<PlanComercial__c>)scope;

                sdm.calculateRealKPI(plans);

                // System.debug('------ AFTER => Queries: ' + Limits.getQueries() + ' / DML: ' + Limits.getDmlStatements() );
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
        Database.executeBatch(new PlanComercialSDMBatch(query), 200);
    }

    private class PlanComercialSDMBatchException extends Exception {}
}