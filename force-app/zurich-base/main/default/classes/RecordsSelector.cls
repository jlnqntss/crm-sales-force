public abstract class RecordsSelector
{
    // #Region Properties

    public Query baseQuery;

    public enum Scope { ALL, Z, ZE, ZEO }

    public enum LegalEntity { ALL, GI, LIFE }

    // #region Constructor

    public RecordsSelector(Schema.SObjectType objectType)
    {
        this.baseQuery = new Query(objectType);
    }

    // #endregion

    // #Region Methods

    /**
     * Aplica un límite a los resultados obtenidos en la SOQL realizada por el selector
     *
     * @author adelgado
     * @param  recordsLimit Número máximo de registros
     */
    public void setLimit(Integer recordsLimit)
    {
        if(recordsLimit != null && recordsLimit > 0)
        {
            baseQuery.setLimit(recordsLimit);
        }
    }

    /**
     * Aplica un offset a los resultados obtenidos en la SOQL realizada por el selector
     *
     * @author adelgado
     * @param  offset Offset a aplicar
     */
    public void setOffset(Integer offset)
    {
        if(offset != null && offset > 0)
        {
            baseQuery.setOffset(offset);
        }
    }

    /**
     * Indicar los campos del objeto que se desean obtener en la SOQL realizada por el selector
     *
     * @author adelgado
     * @param  fieldsToQuery Campos a recuperar
     */
    public void setFields(List<Schema.SobjectField> fieldsToQuery)
    {
        if(fieldsToQuery != null && !fieldsToQuery.isEmpty())
        {
            baseQuery.selectFields(fieldsToQuery);
        }
    }

    // #endregion
}