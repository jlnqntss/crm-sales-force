public with sharing class AsyncApexJobsSelector
{
    // #Region Properties

    private Set<String> asyncApexJobFieldsToQuery
    {
        get
        {
            if(asyncApexJobFieldsToQuery == null)
            {
                asyncApexJobFieldsToQuery = new Set<String> {'Id'};
            }

            return asyncApexJobFieldsToQuery;
        }
        set;
    }

    @testVisible
    private String baseQuery
    {
        get
        {
            String fieldsToQuery = String.join(new List<String> (asyncApexJobFieldsToQuery), ',');

            return 'SELECT ' + fieldsToQuery + ' FROM AsyncApexJob';
        }
    }

    // #region Constructor

    public AsyncApexJobsSelector()
    {
    }

    /**
     * Constructor de AsyncApexJobsSelector para establecer campos a recuperar
     *
     * @author adelgado
     * @param  sObjectFields   Campos a recuperar
     */
    public AsyncApexJobsSelector(List<Schema.SObjectField> asyncApexJobFields)
    {
        asyncApexJobFieldsToQuery.clear();

        for(Schema.SObjectField asyncApexJobField : asyncApexJobFields)
        {
            asyncApexJobFieldsToQuery.add(asyncApexJobField + '');
        }
    }

    // #endregion

    // #region Selectors

    /**
     * Recupera clases apex a partir de una lista de ids de clases apex
     *
     * @author adelgado
     * @param  classIds Trabajos asíncronos de apex a recuperar
     * @return Listado de trabajos asíncronos de apex recuperados. Si no se recibe ningún nombre se devuelve una lista vacía
     */
    public AsyncApexJob[] selectByClassId(Set<String> classIds)
    {
        if( classIds == null || classIds.isEmpty() )
        {
            return new List<AsyncApexJob>();
        }

        return Database.query( String.format('{0} {1}', new List<String>
        {
            baseQuery,
            'WHERE Status NOT IN (\'Completed\', \'Aborted\', \'Failed\') AND ApexClassId IN :classIds AND JobType = \'BatchApex\''
        }) );
    }

    // #endregion
}