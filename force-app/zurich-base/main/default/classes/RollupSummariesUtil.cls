public class RollupSummariesUtil
{
    //        0 : Fields to display
    //        1 : Object
    //        2 : Optional WHERE clause to filter records
    //        3 : grouping field
    static String SOQL_TEMPLATE = 'SELECT {0} FROM {1} WHERE {3} in :masterRecordId {2} GROUP BY {3}{4}';

    static String MASTERCURRENCYALIAS = 'mastercc';
    public static String CURRENCYISOCODENAME = 'CurrencyIsoCode';
    //http://advancedapex.com/2013/07/07/optional-features/
    private static Boolean m_IsMultiCurrency = null;
    public static Boolean IsMultiCurrencyOrg()
    {
        if (m_IsMultiCurrency != null)
        {
            return m_IsMultiCurrency;
        }
        m_IsMultiCurrency = UserInfo.isMultiCurrencyOrganization();
        return m_IsMultiCurrency;
    }

    // Currency search
    static final Map<String, Decimal> currencyConversionMap = new Map<String, Decimal>();
    private static Decimal convertCurrency(String iso, Decimal val)
    {
        if ( currencyConversionMap.isEmpty() )
        {
            String query = 'select IsoCode, ConversionRate from CurrencyType where IsActive = true';
            for ( sObject ct : Database.query(query) )
            {
                currencyConversionMap.put(
                    (String) ct.get('IsoCode'),
                    (Decimal) ct.get('ConversionRate')
                    );
            }
        }
        return val * currencyConversionMap.get(iso);
    }

    /* Method that summarizes search fields based on the context. Useful in triggers      
                 @param ctx Full context that defines the summary
                 @param detailRecords Master / detail objects that are created / modified / deleted during the trigger
                 @returns Memory list of master objects. They are not updated in the BBDD directly.*/
    // public static Sobject[] summarize(Context ctx, Sobject[] detailRecords) {
    //   // API name of the search field in the detail object
    //   String searchFieldName = ctx.searchField.getName();

    //   Set<Id> masterRecordId = new Set<Id>();
    //   for (Sobject kid : detailRecords) {
    //     masterRecordId.add((Id) kid.get(searchFieldName));
    //   }
    //   //Utils.Debug(LoggingLevel.FINE, 'masterRecordId: ' + masterRecordId);
    //   return summarize(ctx, masterRecordId);
    // }

    /* Method that summarizes search fields based on the context. Useful in context as batch processes or scheduled processes
                 @param ctx Full context that defines the summary
                 @param detailRecords Master / detail objects that are created / modified / deleted during the trigger
                 @returns Memory list of master objects. They are not updated in the BBDD directly.*/
    public static Sobject[] summarize(Context context, Set<Id> masterRecordId)
    {
        //Utils.Debug(LoggingLevel.FINE, 'context: ' + context);
        //Utils.Debug(LoggingLevel.FINE, 'masterRecordId: ', masterRecordId);
        // It is cloned to modify it after
        masterRecordId = masterRecordId.clone();
        Map<Id, Sobject> masterRecordsMap = new Map<Id, Sobject>(); //{Master record id, Empty object with id, to update masters}
        for (Id masterId : masterRecordId)
        {
            masterRecordsMap.put( masterId, context.master.newSobject(masterId) );
        }

        // variable # 0 of query
        String selectFields = context.searchField.getName();
        //System.Debug('selectFields: ' + selectFields);
        Integer expressionIndex = 0;
        Boolean requiresCurrency = false;
        Map<String, RollupSummaryField> mapReferencesAlias = new Map<String, RollupSummaryField>(); //{Alias field detail, Name field master}
        for (RollupSummaryField summaryField : context.fieldsToSummarize)
        {
            /*System.Debug('summaryField: ' + summaryField);
                   create expression added with alias for easy recovery in the AggregateResult class
                            Example: SUM (Amount) Amount*/
            String alias = 'lre' + expressionIndex++; // Generic alias, use the name of the field can exceed the limit of 25 characters
            selectFields += ', ' + summaryField.operation + '(' + summaryField.detailField.getName() + ') ' + alias;
            //System.Debug('selectFields: ' + selectFields);
            mapReferencesAlias.put(alias, summaryField);
            if (
                IsMultiCurrencyOrg() == true &&
                requiresCurrency == false &&
                summaryField.currencyTypeCurrency
                )
            {
                requiresCurrency = true;
            }
        }

        // Add a field selection to get the currency from the parent record if we are depositing values into a currency field
        if (IsMultiCurrencyOrg() == true && requiresCurrency == true)
        {
            String searchRelationName = context.searchField.getRelationshipName();
            selectFields += ', ' + summaryOperation.Max + '(' + searchRelationName + '.' + CURRENCYISOCODENAME + ') ' + MASTERCURRENCYALIAS;
            //System.Debug('selectFields: ' + selectFields);
        }

        //variable #1
        String tableDetailName = context.detail.getDescribe().getName();

        //Variable #2
        String whereClause = '';
        //System.Debug('whereClause: ' + whereClause);
        if (
            context.detailWhereClause != null &&
            context.detailWhereClause.trim().length() > 0
            )
        {
            whereClause = 'AND ' + context.detailWhereClause;
            //System.Debug('whereClause: ' + whereClause);
        }

        //Variable #3
        String groupingGroupName = context.searchField.getName();
        String otherGroups = context.additionalAggregationFieldsList;

        //System.Debug('selectFields: ' + selectFields);
        //System.Debug('tableDetailName: ' + tableDetailName);
        //System.Debug('whereClause: ' + whereClause);
        //System.Debug('groupingGroupName: ' + groupingGroupName);
        //System.Debug('otherGroups: ' + otherGroups);
        //System.Debug('masterRecordId: ' + masterRecordId);

        String soql = String.format(
            SOQL_TEMPLATE,
            new List<String> {
            selectFields,
            tableDetailName,
            whereClause,
            groupingGroupName,
            otherGroups
        }
            );

        List<AggregateResult> results = Database.query(soql);
        //Utils.Debug(LoggingLevel.FINE, 'results: ' + results);

        for (AggregateResult result : results)
        {
            Id masterRecordId1 = (Id) result.get(groupingGroupName);
            Sobject masterObject = masterRecordsMap.get(masterRecordId1);
            if (masterObject == null)
            {
                System.Debug(
                    Logginglevel.WARN,
                    'No master record found for the Id:' + masterRecordId1
                    );
                continue;
            }

            for ( String alias : mapReferencesAlias.keySet() )
            {
                RollupSummaryField summaryField = mapReferencesAlias.get(alias);
                Object agregateDetail = result.get(alias);
                if (agregateDetail != null)
                {
                    System.Debug(
                        'Nuevo valor agregado ' +
                        agregateDetail +
                        ' para el master ' +
                        masterRecordId
                        );

                    if (
                        IsMultiCurrencyOrg() == true && summaryField.currencyTypeCurrency
                        )
                    {
                        masterObject.put(
                            summaryField.masterField.getName(),
                            convertCurrency( (String) result.get(MASTERCURRENCYALIAS), (Decimal) agregateDetail ) );
                    }
                    else
                    {
                        masterObject.put( summaryField.masterField.getName(), agregateDetail );
                    }
                }
            }
            // Deletes the master record already processed
            masterRecordId.remove(masterRecordId1);
        }

        // zero value for unprocessed masters (without detail relationships)
        for (Id masterRecordIds : masterRecordId)
        {
            for (RollupSummaryField summaryField : context.fieldsToSummarize)
            {
                masterRecordsMap.get(masterRecordIds)
                .put(
                    summaryField.masterField.getName(),
                    summaryField.numberTypeMaster ? 0 : null
                    );
                //Utils.Debug(LoggingLevel.FINE, 'masterRecordsMap: ', masterRecordsMap);
            }
        }
        return masterRecordsMap.values();
    }

    public class BadRollUpSummaryStateException extends Exception
    {}

    public enum summaryOperation {
        Sum,
        Max,
        Min,
        Avg,
        Count
    }

    //Represents an individual summary field
    public class RollupSummaryField
    {
        //master field where the summary information will be stored
        public Schema.Describefieldresult masterField;
        //detail field that will be summarized
        public Schema.Describefieldresult detailField;
        //summary operation to be applied
        public summaryOperation operation;

        public boolean numberTypeMaster;
        public boolean numberTypeDetail;
        public boolean dateHourTypeMaster;
        public boolean dateHourTypeDetail;
        public boolean currencyTypeCurrency;

        public RollupSummaryField(
            Schema.Describefieldresult m,
            Schema.Describefieldresult d,
            summaryOperation op
            )
        {
            this.masterField = m;
            this.detailField = d;
            this.operation = op;

            this.numberTypeMaster = isNumber( masterField.getType() );
            this.numberTypeDetail = isNumber( detailField.getType() );
            this.dateHourTypeMaster = isDateTime( masterField.getType() );
            this.dateHourTypeDetail = isDateTime( detailField.getType() );
            this.currencyTypeCurrency = isCurrency( masterField.getType() );
            validate();
        }

        void validate()
        {
            if (masterField == null || detailField == null || operation == null)
            {
                throw new BadRollUpSummaryStateException( 'It is necessary to define all the information of the summary operation' );
            }

            if (operation != summaryOperation.Count)
            {
                if (
                    (!dateHourTypeMaster && !numberTypeMaster) ||
                    (!dateHourTypeDetail && !numberTypeDetail)
                    )
                {
                    throw new BadRollUpSummaryStateException( 'Only the Date / Date Time / Time / Number fields are allowed for Sum, Max, Min and Avg' );
                }
            }

            if (
                dateHourTypeMaster &&
                (summaryOperation.Sum == operation ||
                 summaryOperation.Avg == operation)
                )
            {
                throw new BadRollUpSummaryStateException( 'Sum / Avg are not valid for dates' );
            }
        }

        boolean isNumber(Schema.Displaytype dt)
        {
            return dt == Schema.Displaytype.Currency ||
                   dt == Schema.Displaytype.Integer ||
                   dt == Schema.Displaytype.Percent ||
                   dt == Schema.Displaytype.Double;
        }

        boolean isDateTime(Schema.DisplayType dt)
        {
            return dt == Schema.Displaytype.Time ||
                   dt == Schema.Displaytype.Date ||
                   dt == Schema.Displaytype.Datetime;
        }

        boolean isCurrency(Schema.DisplayType dt)
        {
            return dt == Schema.Displaytype.Currency;
        }
    }

    //ontains all the information for the summaries to be made (multiples)
    public class Context
    {
        public Schema.Sobjecttype master;
        public Schema.Sobjecttype detail;
        public Schema.Describefieldresult searchField;
        public List<RollupSummaryField> fieldsToSummarize;

        public String additionalAggregationFieldsList;

        // Where clause to filter detail records
        public String detailWhereClause;

        public Context(
            Schema.Sobjecttype m,
            Schema.Sobjecttype d,
            Schema.Describefieldresult field
            )
        {
            this(m, d, field, '', '');
        }

        public Context(
            Schema.Sobjecttype m,
            Schema.Sobjecttype d,
            Schema.Describefieldresult field,
            String detailWhereClause
            )
        {
            this(m, d, field, detailWhereClause, '');
        }

        public Context(
            Schema.Sobjecttype m,
            Schema.Sobjecttype d,
            Schema.Describefieldresult field,
            String detailWhereClause,
            String otherGroups
            )
        {
            this.master = m;
            this.detail = d;
            this.searchField = field;
            this.detailWhereClause = detailWhereClause;
            this.fieldsToSummarize = new List<RollupSummaryField>();
            if (otherGroups != null && otherGroups != '')
            {
                this.additionalAggregationFieldsList = ', ' + otherGroups;
            }
            else
            {
                this.additionalAggregationFieldsList = '';
            }
        }

        //Adds a new summary to be made to the context
        public void add(RollupSummaryField field)
        {
            this.fieldsToSummarize.add(field);
        }
    }
}