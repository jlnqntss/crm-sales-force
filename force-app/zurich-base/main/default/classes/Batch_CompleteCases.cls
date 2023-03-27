global class Batch_CompleteCases implements Database.Batchable<sObject>, Database.Stateful, Schedulable
{
    public String query;
    // Se carga metadato de los días para la query a Case
    private static final String CASE_DAYS_TO_RETRIEVE = 'BatchCasesUpdateLastNdays';
    private static final AdminSetupParameter__mdt daysToQueryCases = AdminSetupParameter__mdt.getInstance(CASE_DAYS_TO_RETRIEVE);
    // Se carga metadato de los días para la query a Case
    private static final String ORIGIN = 'BatchCasesUpdateOrigin';
    private static final AdminSetupParameter__mdt originsToQueryCases = AdminSetupParameter__mdt.getInstance(ORIGIN);
    // Se carga metadato de los RecordTypes de Case para la actualización
    private static final String RECORD_TYPES_TO_RETRIEVE = 'BatchCasesUpdateRecordTypes';
    private static final AdminSetupParameter__mdt recordTypesToQueryCases = AdminSetupParameter__mdt.getInstance(RECORD_TYPES_TO_RETRIEVE);

    global Batch_CompleteCases() 
    {}

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        if (query == null || query == '')
        {
            List<String> originsToKeep = originsToQueryCases.Value__c.split(',');
            List<String> recordTypesToKeep = recordTypesToQueryCases.Value__c.split(',');
            query = new CasesSelector().getQueryStringCasesWithoutPolicyOffer(daysToQueryCases.Value__c, originsToKeep, recordTypesToKeep);

        }
        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext sc)
    {
        database.executeBatch(new Batch_CompleteCases(), 10);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        if ( scope != null && !scope.isEmpty() )
        {
            // Se convierte el Scope en casos
            List<Case> casesToRelate = (List<Case>) scope;
            try
            {
                // Método que comprueba si hay que actualizar alguno de los casos obtenidos en la query
                List<Case> casesToUpdate = CaseUtil.relateCasesToPolicyOffers(casesToRelate);

                // Si hay algún caso a actualizar
                if(casesToUpdate != null && !casesToUpdate.isEmpty())
                {
                    // Se actualizan los registros que han sido relacionados con su oferta
                    update casesToUpdate;
                }
            }
            catch (Exception ex)
            {
                ErrorLogUtil.commitError(ex, 'Batch_CompleteCases');
            }
        }
    }

    global void finish(Database.BatchableContext bc)
    {}
}