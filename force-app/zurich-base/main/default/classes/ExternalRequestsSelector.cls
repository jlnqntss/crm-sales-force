public with sharing class ExternalRequestsSelector
{
    // #Region Properties

    private Set<String> externalRequestFieldsToQuery
    {
        get
        {
            if(externalRequestFieldsToQuery == null)
            {
                externalRequestFieldsToQuery = new Set<String> {'Id', 'Name'};
            }

            return externalRequestFieldsToQuery;
        }
        set;
    }

    @testVisible
    private String baseQuery
    {
        get
        {
            String fieldsToQuery = String.join(new List<String> (externalRequestFieldsToQuery), ',');

            return 'SELECT ' + fieldsToQuery + ' FROM ExternalRequest__c';
        }
    }

    private Integer recordsLimit = 0;
    @testVisible
    private String limitCondition
    {
        get
        {
            if(recordsLimit > 0)
            {
                return 'LIMIT ' + recordsLimit;
            }

            return '';
        }
    }

    // #region Constructor

    public ExternalRequestsSelector()
    {
    }

    /**
     * Constructor de ExternalRequestsSelector para establecer campos a recuperar
     *
     * @author adelgado
     * @param  sObjectFields   Campos a recuperar
     */
    public ExternalRequestsSelector(List<Schema.SObjectField> externalRequestFields)
    {
        externalRequestFieldsToQuery.clear();

        for(Schema.SObjectField externalRequestField : externalRequestFields)
        {
            externalRequestFieldsToQuery.add(externalRequestField + '');
        }
    }

    // #endregion

    /**
     * Aplica un límite a los resultados obtenidos en la SOQL realizada por el selector
     *
     * @author adelgado
     * @param  recordsLimit Número máximo de registros
     * @return Instancia de ExternalRequestsSelector
     */
    public ExternalRequestsSelector setLimit(Integer recordsLimit)
    {
        if(recordsLimit != null && recordsLimit > 0)
        {
            this.recordsLimit = recordsLimit;
        }

        return this;
    }

    // #region Selectors

    /**
     * Recupera external requests a partir de una lista de origenes
     *
     * @author adelgado
     * @param  origins Origenes a recuperar
     * @return Listado de external request recuperadas. Si no se recibe ningún origen se devuelve una lista vacía
     */
    public ExternalRequest__c[] selectByOrigin(Set<String> origins)
    {
        if( origins == null || origins.isEmpty() )
        {
            return new List<ExternalRequest__c>();
        }

        return Database.query( String.format('{0} {1} {2}', new List<String>
        {
            baseQuery,
            'WHERE Origin__c IN :origins',
            limitCondition
        }) );
    }

    /**
     * Recupera external requests procesadas a partir de una lista de origenes
     *
     * @author adelgado
     * @param  origins Origenes a recuperar
     * @return Listado de external request recuperadas. Si no se recibe ningún origen se devuelve una lista vacía
     */
    public ExternalRequest__c[] selectProcessedByOrigin(Set<String> origins)
    {
        if( origins == null || origins.isEmpty() )
        {
            return new List<ExternalRequest__c>();
        }

        return Database.query( String.format('{0} {1} {2}', new List<String>
        {
            baseQuery,
            'WHERE Origin__c IN :origins AND ProcessResult__c != NULL',
            limitCondition
        }) );
    }

    /**
     * Recupera external requests de un origen concreto
     *
     * @author adelgado
     * @param  origin Origen a recuperar
     * @return Listado de external request recuperadas. Si no se recibe ningún origen se devuelve nulo
     */
    public Database.QueryLocator queryLocatorByOrigin(String origin)
    {
        if( String.isBlank(origin) )
        {
            return null;
        }

        return Database.getQueryLocator( String.format('{0} {1} {2}', new List<String>
        {
            baseQuery,
            'WHERE Origin__c = :origin AND Processed__c = false ORDER BY CreatedDate, NumRetry__c',
            limitCondition
        }) );
    }

    // #endregion

}