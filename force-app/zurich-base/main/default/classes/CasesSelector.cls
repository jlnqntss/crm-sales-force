public with sharing class CasesSelector extends RecordsSelector
{
    //#region Contructores

    public CasesSelector()
    {
        super(Case.getSObjectType());
    }

    //#endregion

    /**
     * Aplicar el filtro de scope a los registros obtenidos en la búsqueda
     * @author adelgado
     * @date 28/01/2021
     * @param  scope  Scope a aplicar en el filtro
     * @return        Instancia de CasesSelector con el filtro de scope aplicado
     */
    public CasesSelector setScope(RecordsSelector.Scope scope)
    {
        switch on scope 
        {
            when Z 
            {
                this.baseQuery.addConditionEq(Case.Scope__c, 'Z');
            }
            when ZE  
            {
                this.baseQuery.addConditionEq(Case.Scope__c, 'ZE');
            }
            when ZEO
            {
                this.baseQuery.addConditionEq(Case.Scope__c, 'ZEO');
            }
        }

        return this;
    }

    /**
     * Aplicar el filtro de entidad legal a los registros obtenidos en la búsqueda
     * @author adelgado
     * @date 28/01/2021
     * @param  legalEntity  Entidad legal a aplicar en el filtro
     * @return              Instancia de CasesSelector con el filtro de entidad legal aplicado
     */
    public CasesSelector setLegalEntity(RecordsSelector.LegalEntity legalEntity)
    {
        switch on legalEntity 
        {
            when GI, LIFE
            {
                this.baseQuery.addConditionEq(Case.LegalEntity__c, RecordsSelector.getLegalEntity(legalEntity));
            }
        }

        return this;
    }

    /**
     * Busca casos abiertos ordenados por fecha de creación a partir de una lista de ids de cuentas
     * @author adelgado
     * @date 26/11/2020
     * @param  accountIds ids de cuentas
     * @return listado de casos
     */
    public List<Case> findOpenByAccount(String[] accountIds)
    {
        if(accountIds != null && !accountIds.isEmpty() )
        {
            this.baseQuery.addConditionEq(Case.isClosed, false).addConditionIn(Case.AccountId, accountIds).orderBy('CreatedDate', 'DESC');

            return (List<Case>) this.baseQuery.run();
        }
        else
        {
            return new List<Case>();
        }

    }

    /**
     * Busca casos a partir de una lista de Id
     * @author arcortazar
     * @date 05/04/2022
     * @param  caseIds ids de los casos
     * @return listado de casos
     */
    public List<Case> findById(Set<String> caseIds)
    {
        if(caseIds != null && !caseIds.isEmpty() )
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField>{
                Case.Id,
                Case.OwnerId
            })
            .selectFields('Owner.Type')
            .selectFields('Owner.Profile.Name')
            .addConditionString('Case.Id IN (\'' + String.join(new List<String>(caseIds), '\',\'') + '\')');

            this.baseQuery.debug();

            return (List<Case>) this.baseQuery.run();
        }
        else
        {
            return new List<Case>();
        }

    }

}