/**
 * Batch que al lanzarse relaciona casos con ofertas cuando el caso ha sido creado antes que la oferta
 * Así, evitamos que queden casos huérfanos en la base de datos.
 * @author lrodriguez6@seidor.es
 * @date 11/11/2022
 */
global class RelateCasesToNewOffersBatch implements Database.Batchable<sObject>, Schedulable
{

    public String query;
    // Se carga metadato de los días para la query a Case
    private static final String OFFER_CASE_DAYS_TO_RETRIEVE = 'USPLinkOfferCaseDaysRetrieval';
    private static final AdminSetupParameter__mdt daysToQueryOfferCases = AdminSetupParameter__mdt.getInstance(OFFER_CASE_DAYS_TO_RETRIEVE);
    // Se carga metadato de los días para la query a Oportunidades
    private static final String OFFER_OPPORTUNITY_DAYS_TO_RETRIEVE = 'USPLinkOfferOpportunityDaysRetrieval';
    private static final AdminSetupParameter__mdt daysToQueryOfferOportunity = AdminSetupParameter__mdt.getInstance(OFFER_OPPORTUNITY_DAYS_TO_RETRIEVE);

    /**
     * Constructor por defecto, la query se calcula con el método general (start)
     * @author lrodriguez6@seidor.es
     * @date 11/11/2022
     */
    public RelateCasesToNewOffersBatch() 
    {}

    /**
     * Constructor que recibe query
     * @author lrodriguez6@seidor.es
     * @date 11/11/2022
     */
    public RelateCasesToNewOffersBatch(String query) 
    {
        // Query recibida por parámetro
        if(!String.isBlank(query))
        {
            this.query = query;
        }
    }
 
    /**
     * En caso de que no se haya introducido una query en el constructor, se carga la query por defecto
     * @author lrodriguez6@seidor.es
     * @date 11/11/2022
     */
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        if (query == null || query == '')
        {
          query = new CasesSelector().getQueryStringCasesToRelateToNewOffers(daysToQueryOfferCases.Value__c);
        }
        
        return Database.getQueryLocator(query);
    }
    
    /**
     * Método necesario en todas las clases batchable
     * @author lrodriguez6@seidor.es
     * @date 11/11/2022
     */
    global void execute(SchedulableContext SC)
    {
        Database.executeBatch(new RelateCasesToNewOffersBatch(query), 200);
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
                List<Case> casesToUpdate = CaseUtil.relateCasesToNewOffers(casesToRelate, daysToQueryOfferOportunity.Value__c);

                // Si hay algún caso a actualizar
                if(casesToUpdate != null && !casesToUpdate.isEmpty())
                {
                    // Se actualizan los registros que han sido relacionados con su oferta
                    update casesToUpdate;
                }
            }
            catch (Exception ex)
            {
                ErrorLogUtil.commitError(ex, 'RelateCasesToNewOffersBatch');
            }
        }
    }

    global void finish(Database.BatchableContext BC)
    {}
}