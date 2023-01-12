public with sharing class SpecialConditionsSelector extends RecordsSelector
{
    public SpecialConditionsSelector() 
    {
        super(Special_Condition__c.getSObjectType());
    }

    /**
     * Método que devuelve los registros a partir de un identificador de cuenta
     * @author jjuaristi@seidor.es
     * @date 29/12/2022
     * @params identifier identificador de la cuenta (CIF o código de mediador), field Campo con el que comparar el identificador
     * @return acuerdos
     */
    public List<Special_Condition__c> findAgreements ( String Id, String dirTerritorial)
    {
        if( Id != null && Id != '')
        {
            this.baseQuery.selectReadableFields();
            this.baseQuery.addConditionEq(Special_Condition__c.Type__c, 'Agreement');
            
            // Lookup a Account = recordId
            // DT, nacional o varios DTs
                // varios DTs se duplica el registro y listo
                // nacional, se pone nacional en el campo
            Query.Condition condition = Query.doOr
            (
                Query.conditionEq(Special_Condition__c.Business_Name__c, Id),
                Query.conditionEq(Special_Condition__c.Global__c, true),
                Query.doAnd
                (
                    Query.conditionEq(Special_Condition__c.TerritorialDirection__c, dirTerritorial),
                    Query.conditionNull(Special_Condition__c.Business_Name__c)
                )
            );

            this.baseQuery.addCondition(condition);
            
            return (List<Special_Condition__c>) this.baseQuery.run();
        }
        else
        {
            return new List<Special_Condition__c>();
        }
    }
}
