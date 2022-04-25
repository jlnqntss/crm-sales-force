public with sharing class ExternalRequestsSelector
{
    // #Region Properties
    private static final String GENERIC_RECORD_TYPE_DEVELOPER_NAME = 'GENERIC';
    private static final String INFO_PROCESSED_RECORD_TYPE_DEVELOPER_NAME = 'INFOProcessed';
    private static final Integer LIMIT_BATCH_DELETE_EXTERNAL_REQUEST= 50000;
    public static final Id GENERIC_RECORD_TYPE_DEVELOPER_ID = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get(GENERIC_RECORD_TYPE_DEVELOPER_NAME).getRecordTypeId();
    public static final Id INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get(INFO_PROCESSED_RECORD_TYPE_DEVELOPER_NAME).getRecordTypeId();

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
     * Recupera external requests de un recordtype concreto
     *
     * @author adelgado
     * @param  recordTypeId RecordType a recuperar
     * @return Listado de external request recuperadas. Si no se recibe ningún recordtype se devuelve una lista vacía
     */
    public ExternalRequest__c[] selectPendingByRecordType(Id recordTypeId)
    {
        if( recordTypeId == null)
        {
            return new List<ExternalRequest__c>();
        }

        return Database.query( String.format('{0} {1} {2}', new List<String>
        {
            baseQuery,
            'WHERE RecordTypeId = :recordTypeId AND Processed__c = false',
            limitCondition
        }) );
    }

    /**
     * Recupera external requests a partir de la una lista de Ids
     *
     * @author adelgado
     * @param  recordIds Ids de registros de External Request
     * @return Listado de external request recuperadas. Si no se recibe ningún id se devuelve una lista vacía
     */
    public ExternalRequest__c[] selectById(Set<Id> recordIds)
    {
        if( recordIds == null || recordIds.isEmpty() )
        {
            return new List<ExternalRequest__c>();
        }

        return Database.query( String.format('{0} {1} {2}', new List<String>
        {
            baseQuery,
            'WHERE Id IN :recordIds',
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
     * Recupera external requests de un recordtype concreto
     *
     * @author adelgado
     * @param  recordTypeId RecordType a recuperar
     * @return Listado de external request recuperadas. Si no se recibe ningún recordtype se devuelve nulo
     */
    public Database.QueryLocator queryLocatorPendingByRecordtype(Id recordTypeId)
    {
        if( String.isBlank(recordTypeId) )
        {
            return null;
        }

        return Database.getQueryLocator( String.format('{0} {1} {2}', new List<String>
        {
            baseQuery,
            'WHERE RecordTypeId = :recordTypeId AND Processed__c = false ORDER BY CreatedDate, NumRetry__c',
            limitCondition
        }) );
    }


    /**
     * Recupera external requests de un recordtype concreto ordenadas por el Id
     *
     * @author adelgado
     * @param  recordTypeId RecordType a recuperar
     * @param  orderType ASC o DESC. Si es nulo será ASC
     * @return Listado de external request recuperadas. Si no se recibe ningún recordtype se devuelve una lista vacía
     */
    public ExternalRequest__c[] selectMinMaxPendingByRecordType(Id recordTypeId, String orderType)
    {
        if( recordTypeId == null)
        {
            return new List<ExternalRequest__c>();
        }

        return Database.query( String.format('{0} {1} {2}', new List<String>
        {
            baseQuery,
            'WHERE RecordTypeId = :recordTypeId AND Processed__c = false ORDER BY Id ' + orderType,
            limitCondition
        }) );
    }

     /**
     * Método para crear una query que seleccione las ER procesadas posteriormente a una determinada fecha
     * Se cumplen los requisitos:
     * - Procesada
     * - Fecha de procesamiento posterior a la fecha por parámetro
     * - Resultado de procesamiento igual al resultado de procesamiento por parámetro
     * - RecordTypeId sea igual a Generic o InfoProcessed
     * @author aberuete@nts-solutions.com
     * @date 25/04/2022
     * param Integer Days que muestra el numero de días
     * param String processedResult
     */
    public String getQueryProcessedAfterThan (Integer days , String processedResult)
    {
        recordsLimit=LIMIT_BATCH_DELETE_EXTERNAL_REQUEST;
        try 
        {
            return String.format('{0} {1} {2}', new List<String>
            {
                baseQuery,
                'WHERE Processed__c = true AND ProcessedDate__c < LAST_N_DAYS: ' + days + ' AND ProcessResult__c = \''+processedResult+'\' AND (RecordTypeId = \''+GENERIC_RECORD_TYPE_DEVELOPER_ID+'\' OR RecordTypeId = \''+INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID +'\')',
                limitCondition
            });
        }
        catch (Exception ex) 
        { 
            ErrorLogUtil.commitError(ex, 'ExternalRequestSelector');
            return null;
        }
    }

     /**
     * Método para contar las ER que cumplen determinados parámetros
     * En caso de querer añadir más parámetros, seguir la misma estructura y modificar cada aparición de este método
     * @author aberuete@nts-solutions.com
     * @date 25/04/2022
     * param Boolean processed 
     * param Integer days muestra el número de días
     * param String processedResult 
     * 
     */
    public Integer count (Boolean processed, Integer days, String processedResult)
    {
        try 
        {
            if(processed != null)
            {
                return Database.countQuery('SELECT count() FROM ExternalRequest__c WHERE Processed__c = :processed AND (RecordTypeId  = \''+GENERIC_RECORD_TYPE_DEVELOPER_ID+'\' OR RecordTypeId = \''+INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID +'\')' );
            }
            if(days != 0 && processedResult != null && processedResult != '')
            {
                return Database.countQuery(
                    'SELECT count () FROM ExternalRequest__c WHERE ProcessedDate__c < LAST_N_DAYS: '+ days + 'AND ProcessResult__c = \''+processedResult+'\' AND (RecordTypeId = \''+GENERIC_RECORD_TYPE_DEVELOPER_ID+'\' OR RecordTypeId = \''+INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID +'\')' );

            }
            else if (days == 0 && processedResult != null && processedResult != '')
            {
                return Database.countQuery(
                    'SELECT count () FROM ExternalRequest__c WHERE ProcessResult__c = \''+processedResult +'\' AND (RecordTypeId = \''+GENERIC_RECORD_TYPE_DEVELOPER_ID+'\' OR RecordTypeId = \''+INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID +'\')' );
            }

            return Database.countQuery('SELECT count() FROM ExternalRequest__c WHERE (RecordTypeId = \''+GENERIC_RECORD_TYPE_DEVELOPER_ID+'\' OR RecordTypeId = \''+INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID +'\')' );
        }
        catch (Exception ex) 
        { 
            ErrorLogUtil.commitError(ex, 'ExternalRequestSelector');
            return null;
        }
    }

    // #endregion
}