public with sharing class PoliciesSelector extends BaseSelector
{
    //#region Contructores
    public PoliciesSelector()
    {}

    public PoliciesSelector(Set<String> fieldsToQuery)
    {
        this();
        this.sObjectToQuery = 'Policy__c';
        this.fieldsToQuery = fieldsToQuery;
    }
    //#endregion

    /**
     * Busca pólizas a partir de PolicyHolder y InfoPolicyNumber__c
     *
     * @author rlopez
     * @date 03/12/2020
     * @param  policyHolder    Id de la cuenta a la que pertenece la póliza
     * @param  policyNumbers   Listado de números de póliza a buscar
     * @return                 Listado de pólizas sobre los que se ha realizado match
     */
    public List<Policy__c> selectByHolderAndNumber(Id policyHolder, Set<String> policyNumbers)
    {
        if(policyHolder != null && policyNumbers != null)
        {
            String query = String.format(
                'SELECT {0} FROM Policy__c ' +
                'WHERE PolicyHolder__c = : policyHolder AND InfoPolicyNumber__c IN : policyNumbers ',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<Policy__c>) Database.query(query);
        }
        else
        {
            return new List<Policy__c>();
        }
    }
}