/**
 * Clase repositorio de las queries SOQL y SOSL del objeto Survey__c utilizadas en la instancia SF
 **
 * @author nts
 * @date 04/05/2022
 */
public with sharing class SurveySelector extends RecordsSelector 
{
    List<Schema.SobjectField> fieldList;
    private static final Integer LIMIT_BATCH_UPDATE_SURVEY= 500000;

    //#region Contructores

    public SurveySelector() 
    {
        super(Survey__c.getSObjectType());
        fieldList=
            new List<Schema.SobjectField>
            {
                Survey__c.fields.Id,
                Survey__c.fields.CanBeRemoved__c,
                Survey__c.fields.LastModifiedDate

            };
    }
    
    /**
     * Método para crear una query que seleccione las encuentas cuya última modificación sea posterior a una determinada fecha
     * Se cumplen los requisitos:
     * - Campo canBeRemoved es falso
     * - Última fecha de modificación posterior a la fecha por parámetro
     * @author aberuete
     * @date 04/05/2022
     * param Integer Days que muestra el numero de días
     */
    public String getQueryLastModifiedDateAfterThan(Integer days)
    {
        this.baseQuery.selectFields(fieldList)
        .addConditionEq(Survey__c.fields.CanBeRemoved__c, false)
        .addConditionString('LastModifiedDate < LAST_N_DAYS:' + days)
        .setLimit(LIMIT_BATCH_UPDATE_SURVEY);
        return this.baseQuery.toQueryString();  
    }

    /**
     * Método para contar las encuestas que cumplen determinados parámetros
     * En caso de querer añadir más parámetros, seguir la misma estructura y modificar cada aparición de este método
     * @author aberuete
     * @date 04/05/2022
     * param Integer days muestra el número de días
     * param Boolean CanBeRemoved 
     * 
     */
    public Integer count (Integer days, Boolean CanBeRemoved)
    {
        if(days != 0 && CanBeRemoved == null )
        {
            this.baseQuery.addConditionEq(Survey__c.fields.CanBeRemoved__c, false);
            this.baseQuery.addConditionString('LastModifiedDate < LAST_N_DAYS:' + days);
        }
        else if (days == 0 && CanBeRemoved != null )
        {
            this.baseQuery.addConditionEq(Survey__c.fields.CanBeRemoved__c, CanBeRemoved);   
        }
        return this.baseQuery.countQuery();
    }
}