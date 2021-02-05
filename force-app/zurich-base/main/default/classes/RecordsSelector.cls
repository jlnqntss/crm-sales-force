public abstract class RecordsSelector
{
    // #Region Properties

    public Query baseQuery;

    public enum Scope { ALL, Z, ZE, ZEO }
    static Map<String, Scope> scopesByCode
    {
        get
        {
            if (scopesByCode == null)
            {
                scopesByCode = new Map<String, Scope>
                {
                    'ALL'   => Scope.ALL,
                    'Z'     => Scope.Z,
                    'ZE'    => Scope.ZE,
                    'ZEO'   => Scope.ZEO
                };
            }
            return scopesByCode;
        }
        private set;
    }

    public enum LegalEntity { ALL, GI, LIFE }
    static Map<LegalEntity, String> legalEntitiesByCode
    {
        get
        {
            if (legalEntitiesByCode == null)
            {
                legalEntitiesByCode = new Map<LegalEntity, String>
                {
                    LegalEntity.GI    => '001',
                    LegalEntity.LIFE  => '005'
                };
            }
            return legalEntitiesByCode;
        }
        private set;
    }
    static Map<String, LegalEntity> legalEntitiesByStringCode
    {
        get
        {
            if (legalEntitiesByStringCode == null)
            {
                legalEntitiesByStringCode = new Map<String, LegalEntity>
                {
                    LegalEntity.GI.name()    => LegalEntity.GI,
                    LegalEntity.LIFE.name()  => LegalEntity.LIFE
                };
            }
            return legalEntitiesByStringCode;
        }
        private set;
    }

    // #region Constructor

    public RecordsSelector(Schema.SObjectType objectType)
    {
        this.baseQuery = new Query(objectType);
    }

    // #endregion

    // #Region Methods

    public static Scope getScope(String scope)
    {
        return String.isBlank(scope) || !scopesByCode.containsKey(scope.toUpperCase()) ? scopesByCode.get('ALL') : scopesByCode.get(scope.toUpperCase());
    }

    public static String getLegalEntity(LegalEntity legalEntity)
    {
        return legalEntity == null || !legalEntitiesByCode.containsKey(legalEntity) ? null : legalEntitiesByCode.get(legalEntity);
    }

    public static LegalEntity getLegalEntity(String legalEntity)
    {
        return String.isBlank(legalEntity) || !legalEntitiesByStringCode.containsKey(legalEntity.toUpperCase()) ? null : legalEntitiesByStringCode.get(legalEntity.toUpperCase());
    }

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
     * @param  fields Campos a recuperar
     */
    public void setFields(Schema.SobjectField[] fields, String[] relationshipFields) 
    {
        this.setFields(fields);
        this.baseQuery.selectFields(relationshipFields);
    }

    public void setFields(Schema.SobjectField[] fields) 
    {
        this.baseQuery.selectFields(fields);
    }

    // #endregion
}