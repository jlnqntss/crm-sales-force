/**
 * Clase selector del objeto KPI__c
 *
 * Proyecto: SDM (Sales Digital Management)
 *
 * @author nts (agonzalezisasi)
 * @date 28/07/2021
 */
public with sharing class KPIsSelector extends RecordsSelector {
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
     * @author nts (agonzalezisasi)
     * @date 28/07/2021
     * 
     * @param {List<ID> intermediaries} lista de ids mediadores
     * @param {Set<String> fields} lista de campos de KPI
     * @return {List<KPI__c>} lista de KPIs encontrados
     */
    public List<KPI__c> findByIntermediaryIds(List<ID> intermediaries, Set<String> fields)
    {
        List<KPI__c> result = null;

        if( intermediaries != null && !intermediaries.isEmpty() && fields != null && !fields.isEmpty() ) {
            this.baseQuery.selectFields(fields);
            this.baseQuery.addConditionIn(KPI__c.Intermediary__c, intermediaries);

            result = (List<KPI__c>)this.baseQuery.run();
        }

        return result;
    }
}
