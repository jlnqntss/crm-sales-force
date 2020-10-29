public with sharing class ExternalJobQueueBatchesSelector
{
    // #Region Properties

    private Set<String> externalJobQueueBatchFieldsToQuery
    {
        get
        {
            if(externalJobQueueBatchFieldsToQuery == null)
            {
                externalJobQueueBatchFieldsToQuery = new Set<String> {'Id'};
            }

            return externalJobQueueBatchFieldsToQuery;
        }
        set;
    }

    @testVisible
    private String baseQuery
    {
        get
        {
            String fieldsToQuery = String.join(new List<String> (externalJobQueueBatchFieldsToQuery), ',');

            return 'SELECT ' + fieldsToQuery + ' FROM ExternalJobQueueBatch__mdt';
        }
    }

    // #region Constructor

    public ExternalJobQueueBatchesSelector()
    {
    }

    /**
     * Constructor de ExternalJobQueueBatchesSelector para establecer campos a recuperar
     *
     * @author adelgado
     * @param  sObjectFields   Campos a recuperar
     */
    public ExternalJobQueueBatchesSelector(List<Schema.SObjectField> externalJobQueueBatchFields)
    {
        externalJobQueueBatchFieldsToQuery.clear();

        for(Schema.SObjectField externalJobQueueBatchField : externalJobQueueBatchFields)
        {
            externalJobQueueBatchFieldsToQuery.add(externalJobQueueBatchField + '');
        }
    }

    // #endregion

    // #region Selectors

    /**
     * Recupera metadatos a partir de una lista de orígenes
     *
     * @author adelgado
     * @param  origins Orígenes a recuperar
     * @return Listado de metadatos recuperados. Si no se recibe ningún nombre se devuelve una lista vacía
     */
    public ExternalJobQueueBatch__mdt[] selectByOrigin(Set<String> origins)
    {
        if( origins == null || origins.isEmpty() )
        {
            return new List<ExternalJobQueueBatch__mdt>();
        }

        return Database.query( String.format('{0} {1}', new List<String>
        {
            baseQuery,
            'WHERE Origin__c IN :origins'
        }) );
    }

    // #endregion
}