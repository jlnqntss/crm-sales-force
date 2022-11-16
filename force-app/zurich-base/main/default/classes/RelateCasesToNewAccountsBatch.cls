/**
 * Batch que al lanzarse relaciona casos con clientes cuando el caso ha sido creado antes que el cliente
 * Así, evitamos que queden casos huérfanos en la base de datos.
 * @author jjuaristi@seidor.es
 * @date 19/10/2022
 */
global class RelateCasesToNewAccountsBatch implements Database.Batchable<sObject>, Schedulable
{

    public String query;
    // Se carga metadato de los días para la query a Case
    private static final String CASE_DAYS_TO_RETRIEVE = 'USPLinkCustomerCaseDaysRetrieval';
    private static final AdminSetupParameter__mdt daysToQueryCases = AdminSetupParameter__mdt.getInstance(CASE_DAYS_TO_RETRIEVE);
    // Se carga metadato de los días para la query a Account
    private static final String ACCOUNT_DAYS_TO_RETRIEVE = 'USPLinkCustomerAccountDaysRetrieval';
    private static final AdminSetupParameter__mdt daysToQueryAccounts = AdminSetupParameter__mdt.getInstance(ACCOUNT_DAYS_TO_RETRIEVE);

    /**
     * Constructor por defecto, la query se calcula con el método general (start)
     * @author jjuaristi@seidor.es
     * @date 19/10/2022
     */
    public RelateCasesToNewAccountsBatch() 
    {}

    /**
     * Constructor que recibe query
     * @author jjuaristi@seidor.es
     * @date 19/10/2022
     */
    public RelateCasesToNewAccountsBatch(String query) 
    {
        // query recibida por parámetro
        if(!String.isBlank(query))
        {
            this.query = query;
        }
    }

    /**
     * En caso de que no se haya introducido una query en el constructor, se carga la query por defecto
     * @author jjuaristi@seidor.es
     * @date 19/10/2022
     */
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        if (query == null || query == '')
        {
            query = new CasesSelector().getQueryStringCasesToRelateToNewAccounts(daysToQueryCases.Value__c);
        }
        
        return Database.getQueryLocator(query);
    }
    
    /**
     * Método necesario en todas las clases batchable
     * @author jjuaristi@seidor.es
     * @date 19/10/2022
     */
    global void execute(SchedulableContext SC)
    {
        Database.executeBatch(new RelateCasesToNewAccountsBatch(query), 200);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        if ( scope != null && !scope.isEmpty() )
        {
            // Se convierte el Scope en casos
            List<Case> casesToRelate = (List<Case>) scope;
            try
            {
                // Método que comprueba si hay que actualizar alguno de los casos obtenidos en la query
                List<Case> casesToUpdate = CaseUtil.relateCasesToNewAccounts(casesToRelate, daysToQueryAccounts.Value__c);

                // Si hay algún caso a actualizar
                if(casesToUpdate != null && !casesToUpdate.isEmpty())
                {
                    // Se actualizan los registros que han sido relacionados con su cliente
                    update casesToUpdate;
                }
            }
            catch (Exception ex)
            {
                ErrorLogUtil.commitError(ex, 'RelateCasesToNewAccountsBatch');
            }
        }
    }

    global void finish(Database.BatchableContext BC)
    {}
}
