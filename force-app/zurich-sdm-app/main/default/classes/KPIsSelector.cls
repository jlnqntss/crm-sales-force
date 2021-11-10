/**
 * Clase selector del objeto KPI__c
 *
 * Proyecto: SDM (Sales Digital Management)
 *
 * @author nts (agonzalezisasi)
 * @date 28/07/2021
 */
public with sharing class KPIsSelector extends RecordsSelector {
    public static final String TEMPORALIDAD_YTD = 'YTD';
    public static final String TEMPORALIDAD_MONTH = 'Mensual';
    public static final String FIELD_MONTH = 'CalcMonth__c';

    /**
     * Constructor
     */
    public KPIsSelector() 
    {
        super(KPI__c.getSObjectType());
    }

    /**
     * Recupera los KPIs asociados a los mediadores datos.
     * En la consulta incluye los campos que se pasan como parametro
     * 
     * SDM-729 - Se modifica el proceso para reducir el numero de KPIs devueltos cada vez. Añadiendo tanto el tipo
     * de temporalidad (mensual, anual), como el año y mes de los kpis a recuperar.
     * 
     * @author nts (agonzalezisasi)
     * @date 28/07/2021
     * 
     * @param {List<ID> intermediaries} lista de ids mediadores
     * @param {List<String> tempoTypes} Tipos de temporalidad
     * @param {String theYear} año de calculo
     * @param {String theMonth} mes de calculo
     * @param {Set<String> fields} lista de campos de KPI
     * @return {List<KPI__c>} lista de KPIs encontrados
     */
    public List<KPI__c> findByIntermediaryIds(
        List<ID> intermediaries, List<String> tempoTypes, 
        String theYear, String theMonth,
        Set<String> fields)
    {
        List<KPI__c> result = null;

        if( intermediaries != null && !intermediaries.isEmpty() 
            && tempoTypes != null && !tempoTypes.isEmpty()
            && String.isNotBlank(theYear) && String.isNotBlank(theMonth)
            && fields != null && !fields.isEmpty() ) 
        {
            this.baseQuery.selectFields(fields);
            this.baseQuery.addConditionIn(KPI__c.Intermediary__c, intermediaries);
            this.baseQuery.addConditionIn(KPI__c.Temporalidad__c, tempoTypes);
            this.baseQuery.addConditionEq(KPI__c.CalcYear__c, theYear);
            this.baseQuery.addConditionEq(KPI__c.CalcMonth__c, theMonth);

            result = (List<KPI__c>)this.baseQuery.run();
        }

        return result;
    }

    /**
     * Recupera el ultimo mes que hay KPIs de tipo anual para el año en curso
     *
     * @author nts (agonzalezisasi)
     * @date 27/10/2021
     *
     * @return {String} el ultimo mes
     */
    public String findThisYearsLastMonth()
    {
        Integer thisYear = Date.today().year();

        if( Test.isRunningTest() ) thisYear = 2021;

        this.baseQuery.selectFields(new List<Schema.SObjectField> {
                KPI__c.CalcMonth__c
            });
        this.baseQuery.addConditionEq(KPI__c.Temporalidad__c, TEMPORALIDAD_YTD);
        this.baseQuery.addConditionEq(KPI__c.CalcYear__c, String.valueOf(thisYear));
        this.baseQuery.groupBy(FIELD_MONTH);

        
        // Como el campo mes es string. hay que convertirlos a integer para saber cual es el mayor numericamente
        // Ej.: 10,8,11,5
        Integer thisMonth = 0;
        List<AggregateResult> months = (List<AggregateResult>)this.baseQuery.run();
        for(AggregateResult agr: months) {
            Integer intValue = Integer.valueOf(agr.get(FIELD_MONTH));
            if( intValue > thisMonth ) thisMonth = intValue;
        }
        String result = (thisMonth != 0 ? String.valueOf(thisMonth) : null);

        return result;
    }
}
