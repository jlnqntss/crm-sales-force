public with sharing class PoliciesSelector extends RecordsSelector
{
    //#region Contructores

    public PoliciesSelector()
    {
        super(Policy__c.getSObjectType());
    }

    //#endregion

    /**
     * Aplicar el filtro de scope a los registros obtenidos en la búsqueda
     * @author adelgado
     * @date 28/01/2021
     * @param  scope  Scope a aplicar en el filtro
     * @return        Instancia de PoliciesSelector con el filtro de scope aplicado
     */
    public PoliciesSelector setScope(RecordsSelector.Scope scope)
    {
        switch on scope 
        {
            when Z 
            {
                this.baseQuery.addConditionEq(Policy__c.Scope__c, 'Z');
            }
            when ZE  
            {
                this.baseQuery.addConditionEq(Policy__c.Scope__c, 'ZE');
            }
            when ZEO
            {
                this.baseQuery.addConditionEq(Policy__c.Scope__c, 'ZEO');
            }
        }

        return this;
    }

    /**
     * Aplicar el filtro de entidad legal a los registros obtenidos en la búsqueda
     * @author adelgado
     * @date 28/01/2021
     * @param  legalEntity  Entidad legal a aplicar en el filtro
     * @return              Instancia de PoliciesSelector con el filtro de entidad legal aplicado
     */
    public PoliciesSelector setLegalEntity(RecordsSelector.LegalEntity legalEntity)
    {
        switch on legalEntity 
        {
            when GI
            {
                this.baseQuery.addConditionEq(Policy__c.LegalEntity__c, '001');
            }
            when LIFE
            {
                this.baseQuery.addConditionEq(Policy__c.LegalEntity__c, '005');
            }
        }

        return this;
    }

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
            this.baseQuery.addConditionEq(Policy__c.PolicyHolder__c, policyHolder).addConditionIn(Policy__c.InfoPolicyNumber__c, policyNumbers);

            return (List<Policy__c>) this.baseQuery.run();
        }
        else
        {
            return new List<Policy__c>();
        }
    }

    /**
     * Busca pólizas a partir del Id de la oportunidad relacionada
     *
     * @author rlopez
     * @date 11/12/2020
     * @param  policyNumbers   Listado de Ids de oportunidades
     * @return                 Listado de pólizas sobre los que se ha realizado match
     */
    public List<Policy__c> selectByOpportunityName(Set<Id> offers)
    {
        if(offers != null)
        {
            this.baseQuery.addConditionIn(Policy__c.OpportunityName__c, offers);

            return (List<Policy__c>) this.baseQuery.run();
        }
        else
        {
            return new List<Policy__c>();
        }
    }

    /**
     * Busca pólizas activas a partir de PolicyHolder (tomador)
     *
     * @author xsobera
     * @date 20/01/2021
     * @param Id policyHolder  Id de la cuenta a la que pertenece la póliza
     * @return List<Policy__c> Listado de pólizas sobre los que se ha realizado match
     */
    public List<Policy__c> selectByHolder(Id policyHolder)
    {
        if(policyHolder != null)
        {
            Query.Condition condition = Query.doOr
            (
                Query.conditionEq(Policy__c.EndDate__c, null),
                Query.conditionGe(Policy__c.EndDate__c, Query.TODAY)
            );

            this.baseQuery.addConditionEq(Policy__c.PolicyHolder__c, policyHolder).addCondition(condition);

            return (List<Policy__c>) this.baseQuery.run();
        }
        else
        {
            return new List<Policy__c>();
        }
    }

    /**
     * Busca pólizas a partir de InfoPolicyNumber__c (Número de Póliza en transaccional INFO)
     * No se tiene en cuenta activa o no ya que se busca por un número de póliza específico
     *
     * @author xsobera
     * @date 20/01/2021
     * @param String policyNumber Número de póliza a buscar
     * @return List<Policy__c> Listado de pólizas sobre los que se ha realizado match
     */
    public List<Policy__c> selectByNumber(String policyNumber)
    {
        if(String.isNotBlank(policyNumber))
        {
            this.baseQuery.addConditionEq(Policy__c.InfoPolicyNumber__c, policyNumber.leftPad(14, '0'));

            return (List<Policy__c>) this.baseQuery.run();
        }
        else
        {
            return new List<Policy__c>();
        }
    }
}