public with sharing class ClaimsSelector extends RecordsSelector
{
    //#region Contructores

    public ClaimsSelector()
    {
        super(Claim__c.getSObjectType());
    }
   
    //#endregion

    /**
     * Aplicar el filtro de scope a los registros obtenidos en la búsqueda
     * @author adelgado
     * @date 28/01/2021
     * @param  scope  Scope a aplicar en el filtro
     * @return        Instancia de ClaimsSelector con el filtro de scope aplicado
     */
    public ClaimsSelector setScope(RecordsSelector.Scope scope)
    {
        switch on scope 
        {
            when Z 
            {
                this.baseQuery.addConditionEq(Claim__c.Scope__c, 'Z');
            }
            when ZE  
            {
                this.baseQuery.addConditionEq(Claim__c.Scope__c, 'ZE');
            }
            when ZEO
            {
                this.baseQuery.addConditionEq(Claim__c.Scope__c, 'ZEO');
            }
            when else 
            {
                // else code
            }
        }

        return this;
    }

    /**
     * Aplicar el filtro de entidad legal a los registros obtenidos en la búsqueda
     * @author adelgado
     * @date 28/01/2021
     * @param  legalEntity  Entidad legal a aplicar en el filtro
     * @return              Instancia de ClaimsSelector con el filtro de entidad legal aplicado
     */
    public ClaimsSelector setLegalEntity(RecordsSelector.LegalEntity legalEntity)
    {
        switch on legalEntity 
        {
            when GI, LIFE
            {
                this.baseQuery.addConditionEq(Claim__c.LegalEntity__c, RecordsSelector.getLegalEntity(legalEntity));
            }
            when else 
            {
                // else code
            }
        }

        return this;
    }

    /**
     * Busca siniestros a partir de número de siniestro en INFO
     **
     * @author xsobera
     * @date 21/01/2021
     * @param   String          claimNumber   Números de siniestro a buscar
     * @return  List<Claim__c>  Listado de siniestros sobre los que se ha realizado match
     */
    public List<Claim__c> selectByNumber(String claimNumber)
    {
        if(String.isNotBlank(claimNumber))
        {
            this.baseQuery.addConditionEq(Claim__c.INFOClaimNumber__c, claimNumber);

            return (List<Claim__c>) this.baseQuery.run();
        }
        else
        {
            return new List<Claim__c>();
        }
    }

    /**
     * Busca siniestros a partir de número matrícula del vehículo
     * No devuelve los siniestros marcados como Terminados
     **
     * @author xsobera
     * @date 21/01/2021
     * @param   String          plateNumber   Matrícula del vehículo
     * @return  List<Claim__c>  Listado de siniestros sobre los que se ha realizado match
     */
    public List<Claim__c> selectByPlate(String plateNumber)
    {
        if(String.isNotBlank(plateNumber))
        {
            this.baseQuery.addConditionNotEq(Claim__c.Status__c, 'T').addConditionEq('InsuredObject__r.RegistrationNumber__c', plateNumber);

            return (List<Claim__c>) this.baseQuery.run();
        }
        else
        {
            return new List<Claim__c>();
        }
    }

    /**
     * Busca siniestros de pólizas activas a partir Id de la cuenta del cliente
     * No devuelve los siniestros marcados como Terminados
     **
     * @author xsobera
     * @date 21/01/2021
     * @param   String          claimNumber   Listado de números de póliza a buscar
     * @return  List<Claim__c>  Listado de siniestros sobre los que se ha realizado match
     */
    public List<Claim__c> selectByHolder(Id policyHolder)
    {
        if(policyHolder != null)
        {
            Query.Condition condition = Query.doOr
            (
                Query.conditionEq('Policy__r.EndDate__c', null),
                Query.conditionGe('Policy__r.EndDate__c', Query.TODAY)
            );

            this.baseQuery.addConditionNotEq(Claim__c.Status__c, 'T').addConditionEq(Claim__c.PolicyHolder__c, policyHolder);

            return (List<Claim__c>) this.baseQuery.run();
        }
        else
        {
            return new List<Claim__c>();
        }
    }

    /**
     * Busca siniestros de pólizas activas a partir Id de la cuenta del cliente
     * Permite filtrar por status y orden
     **
     * @author jfherrero
     * @date 15/03/2024
     * @param   String          policyHolder    Tomador de la póliza asociada al siniestro
     * @param   String          branch          Ramo de la póliza asociada al siniestro
     * @param   Boolean         branch         Buscar sólo siniestros no cerrados
     * @param   String          orderByField    Campo para ordenar
     * @param   String          order           Orden de resultados
     * @return  List<Claim__c>  Listado de siniestros sobre los que se ha realizado match
     */
    public List<Claim__c> selectByHolderAndBranch(Id policyHolder, String branch, Boolean active, String orderByField, String order)
    {
        if(policyHolder != null)
        {
            Query.Condition condition = Query.doOr
            (
                Query.conditionEq('Policy__r.EndDate__c', null),
                Query.conditionGe('Policy__r.EndDate__c', Query.TODAY)
            );

            this.baseQuery.addConditionEq(Claim__c.PolicyHolder__c, policyHolder);

            if(String.isNotBlank(branch))
            {
                this.baseQuery.addConditionEq('Claim__c.Policy__r.PolicyType__c', branch);
            }

            if(active)
            {
                this.baseQuery.addConditionNotEq(Claim__c.Status__c, 'T');
            }

            if(String.isNotBlank(orderByField))
            {
                if ( order.toLowerCase() == 'asc' || order.toLowerCase() == 'desc')
                {
                    this.baseQuery.orderBy(orderByField, order);
                }
                else 
                {
                    this.baseQuery.orderBy(orderByField);
                }
            }

            this.baseQuery.setLimit(2000);

            return (List<Claim__c>) this.baseQuery.run();
        }
        else
        {
            return new List<Claim__c>();
        }
    }

}