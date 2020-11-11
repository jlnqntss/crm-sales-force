public with sharing class RecordsSelector 
{
    // #Region Properties

    private Set<String> recordFieldsToQuery
    {
        get
        {
            if(recordFieldsToQuery == null)
            {
                recordFieldsToQuery = new Set<String> {'Id'};
            }

            return recordFieldsToQuery;
        }
        set;
    }

    private Schema.SObjectType sObjectType;
    @testVisible
    private String baseQuery
    {
        get
        {
            String fieldsToQuery = String.join(new List<String> (recordFieldsToQuery), ',');

            return 'SELECT ' + fieldsToQuery + ' FROM ' + sObjectType.getDescribe().getName();
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

    public RecordsSelector(Schema.SObjectType sObjectType)
    {
        this.sObjectType = sObjectType;
    }

    /**
     * Constructor de RecordsSelector para establecer campos a recuperar
     *
     * @author adelgado
     * @param  sObjectFields   Campos a recuperar
     */
    public RecordsSelector(Schema.SObjectType sObjectType, List<Schema.SObjectField> recordFields)
    {
        this.sObjectType = sObjectType;

        recordFieldsToQuery.clear();

        for(Schema.SObjectField recordField : recordFields)
        {
            recordFieldsToQuery.add(recordField + '');
        }
    }

    // #endregion

    /**
     * Aplica un límite a los resultados obtenidos en la SOQL realizada por el selector
     *
     * @author adelgado
     * @param  recordsLimit Número máximo de registros
     * @return Instancia de RecordsSelector
     */
    public RecordsSelector setLimit(Integer recordsLimit)
    {
        if(recordsLimit != null && recordsLimit > 0)
        {
            this.recordsLimit = recordsLimit;
        }

        return this;
    }

    // #region Selectors

    /**
     * Recupera una lista de registros a partir de un campo externalId y una lista de valores
     *
     * @author adelgado
     * @param  fieldname Campo externalId
     * @param  values Set de valores a incluir en la búsqueda
     * @return Listado de external request recuperadas. Si no se recibe ningún origen se devuelve una lista vacía
     */
    public List<sObject> selectByExternalId(Schema.sObjectField fieldname, Set<Object> values)
    {
        if( fieldname == null || values == null || values.isEmpty() )
        {
            return new List<sObject>();
        }

        List<String> textValuesToSelect = new List<String>();
        Schema.DisplayType fieldDisplayType = fieldname.getDescribe().getType();

        switch on fieldDisplayType
        {
            when STRING, EMAIL
            {
                for(Object obj: values)
                {
                    textValuesToSelect.add('\'' + obj + '\'');
                }
            }
            when else
            {
               //
            }
        }

        return Database.query( String.format('{0} {1} {2}', new List<String>
        {
            baseQuery,
            'WHERE ' + fieldname + ' IN ' + (textValuesToSelect.isEmpty() ? new List<Object>(values) : textValuesToSelect),
            limitCondition
        }) );
    }

    // #endregion
}