public with sharing class ExternalIdFieldsSelector
{
    // #Region Properties

    private Set<String> externalIdFieldsFieldsToQuery
    {
        get
        {
            if(externalIdFieldsFieldsToQuery == null)
            {
                externalIdFieldsFieldsToQuery = new Set<String> {'Id'};
            }

            return externalIdFieldsFieldsToQuery;
        }
        set;
    }

    @testVisible
    private String baseQuery
    {
        get
        {
            String fieldsToQuery = String.join(new List<String> (externalIdFieldsFieldsToQuery), ',');

            return 'SELECT ' + fieldsToQuery + ' FROM ExternalIdField__mdt';
        }
    }

    // #region Constructor

    public ExternalIdFieldsSelector()
    {}

    /**
     * Constructor de ExternalIdFieldsSelector para establecer campos a recuperar
     *
     * @author adelgado
     * @param  sObjectFields   Campos a recuperar
     */
    public ExternalIdFieldsSelector(List<Schema.SObjectField> externalIdFieldFields)
    {
        externalIdFieldsFieldsToQuery.clear();

        for(Schema.SObjectField externalIdFieldField : externalIdFieldFields)
        {
            externalIdFieldsFieldsToQuery.add(externalIdFieldField + '');
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
    public ExternalIdField__mdt[] selectByOrigin(Set<String> origins)
    {
        if( origins == null || origins.isEmpty() )
        {
            return new List<ExternalIdField__mdt>();
        }

        return Database.query( String.format('{0} {1}', new List<String>
        {
            baseQuery,
            'WHERE Origin__c IN :origins'
        }) );
    }

    // #endregion
}