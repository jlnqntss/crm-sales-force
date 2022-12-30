public with sharing class CustomerWarningsSelector extends RecordsSelector
{
    public CustomerWarningsSelector() 
    {
        super(CustomerWarning__c.getSObjectType());
    }

    /**
     * Método que recupera todos los registros
     * @author jjuaristi@seidor.es
     * @date 29/12/2022
     */
    public List<CustomerWarning__c> findAllWarnings()
    {
        this.baseQuery.selectReadableFields();

        return (List<CustomerWarning__c>) this.baseQuery.run();
    }

    /**
     * Método que devuelve los registros a partir de un set de ids
     * @author jjuaristi@seidor.es
     * @date 29/12/2022
     * @param ids
     * @return warnings asociadas a los ids
     */
    public List<CustomerWarning__c> findWarningsByIds ( Set<Id> ids)
    {
        if( ids != null && !ids.isEmpty() )
        {
            this.baseQuery.selectReadableFields();
    
            this.baseQuery.addConditionIn(CustomerWarning__c.Id, ids);
            return (List<CustomerWarning__c>) this.baseQuery.run();
        }
        else
        {
            return new List<CustomerWarning__c>();
        }
    }
}
