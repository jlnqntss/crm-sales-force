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
     * @return              Instancia de PoliciesSelector con el filtro de entidad legal aplicado
     */
    public PoliciesSelector setLegalEntity(RecordsSelector.LegalEntity legalEntity)
    {
        switch on legalEntity 
        {
            when GI, LIFE
            {
                this.baseQuery.addConditionEq(Policy__c.LegalEntity__c, RecordsSelector.getLegalEntity(legalEntity));
            }
            when else 
            {
                // else code
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
            this.baseQuery.selectReadableFields();
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
     * 
     * @change OCS-1512 - 04/05/2021 - nts (agonzalezisasi) - La condicion de poliza activa se cambia de fechas a Estado igual a V
     */
    public List<Policy__c> selectByHolder(Id policyHolder)
    {
        if(policyHolder != null)
        {
            this.baseQuery.addConditionEq(Policy__c.PolicyHolder__c, policyHolder).addConditionEq(Policy__c.PolicyStatus__c, 'V');

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
            this.baseQuery.selectReadableFields();
            this.baseQuery.addConditionEq(Policy__c.InfoPolicyNumber__c, policyNumber.leftPad(14, '0'));

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
    public List<Policy__c> selectByNumber(Set<String> lstPolicyNumber)
    {
        if(lstPolicyNumber != null && !lstPolicyNumber.isEmpty())
        {

            List<String> lstLeftPad = new List<String>();
            for(String s : lstPolicyNumber)
            {
                lstLeftPad.add(s.leftPad(14, '0'));
            }

            this.baseQuery.selectReadableFields();
            this.baseQuery.addConditionIn(Policy__c.InfoPolicyNumber__c, lstLeftPad);

            return (List<Policy__c>) this.baseQuery.run();
        }
        else
        {
            return new List<Policy__c>();
        }
    }

    /**
     * Busca pólizas a partir de un listado de NationalIds y números de póliza
     *
     * @author jpereztirado
     * @date 27/10/2022
     * @param List<String> infoPolicyNumbers Números de pólizas a buscar
     * @param List<String> nationalIds NationalIds a buscar
     * @return List<Policy__c> Listado de pólizas sobre los que se ha realizado match
     */
    public List<Policy__c> selectByInfoPolicyNumberAndNationalId(List<String>  nationalIds, List<String> infoPolicyNumbers) {       
        if(nationalIds != null && infoPolicyNumbers != null)
        {
            this.baseQuery.selectReadableFields();
            this.baseQuery.addConditionIn('Policy__c.PolicyHolder__r.NationalId__c', nationalIds).addConditionIn(Policy__c.InfoPolicyNumber__c, infoPolicyNumbers);
            this.baseQuery.orderBy('Policy__c.PolicyHolder__r.NationalId__c');

            return (List<Policy__c>) this.baseQuery.run();
        }
        else
        {
            return new List<Policy__c>();
        }
    }
    
     /**
      * Busca pólizas a partir de ids de cuenta
      *
      * @author fpalomo
      * @param accountIds
      * @return List<Policy__c>
      */
    public List<Policy__c> findPoliciesByAccountId(Set<Id> accountIds, Set<String> intermediaryCodes)
    {
        return new List<Policy__c>([
            SELECT PolicyHolder__c, IntermediaryId__r.IntermediaryGroup__c, IntermediaryId__r.INFOIntermediaryCode__c
            FROM Policy__c
            WHERE PolicyHolder__c IN :accountIds
                AND IntermediaryId__r.INFOIntermediaryCode__c IN :intermediaryCodes
                AND PolicyStatus__c IN ('V', 'A')
                AND Blocked__c = false
                AND Anonymized__c = false
        ]);
    }
    
     /**
     * Busca pólizas activas a partir de PolicyHolder (tomador)
     *
     * @author arcortazar
     * @date 03/08/2023
     * @param Id policyHolder  Id de la cuenta a la que pertenece la póliza
     * @param String groupDescription  Ramo al que pertenece la póliza
     * @return List<Policy__c> Listado de pólizas sobre los que se ha realizado match
     * 
     */
    public List<Policy__c> selectByHolderAndGroupDescription(Id policyHolder, String groupDescription)
    {
        if (policyHolder == null)
        {
            return new List<Policy__c>();
        }

        this.baseQuery.selectReadableFields();
        this.baseQuery.addConditionEq(Policy__c.PolicyHolder__c, policyHolder).addConditionEq(Policy__c.PolicyStatus__c, 'V');

        if (!String.isBlank(groupDescription) && !String.isEmpty(groupDescription))
        {
            String busquedaField = 'Policy__c.ProductId__r.GroupDescription__c';
            this.baseQuery.addConditionEq(busquedaField, groupDescription);

        }
        return (List<Policy__c>) this.baseQuery.run();
    }
    
    /**
     * Busca pólizas activas a partir de su Id de Salesforce
     *
     * @author jfherrero
     * @date 26/10/2023
     * @param Set<Id> policyIds  Ids de las pólizas a recuperar
     * @return List<Policy__c> Listado de pólizas sobre los que se ha realizado match
     * 
     */
    public List<Policy__c> selectByIdAndRecordType(Set<String> policyIds, Set<String> recordTypes, Set<String> policyStatus)
    {
        if (policyIds == null || policyIds.size() == 0)
        {
            return new List<Policy__c>();
        }

        this.baseQuery.selectReadableFields();
        this.baseQuery.addConditionIn(Policy__c.Id, policyIds);

        // Vamos añadir la condición si la lista es una, no está vacía o está poblada por valores no válidos
        if (recordTypes != null && recordTypes.size() > 0)
        {
            for (string record : recordTypes)
            {
                if (String.IsNotBlank(record))
                {
                    this.baseQuery.addConditionIn(Policy__c.PolicyType__c, recordTypes);
                	break;
                }
       		}
        }
        
        // Vamos añadir la condición si la lista es una, no está vacía o está poblada por valores no válidos
        if (policyStatus != null && policyStatus.size() > 0)
        {
            this.baseQuery.addConditionIn(Policy__c.PolicyStatus__c, policyStatus);
        }
        
        return (List<Policy__c>) this.baseQuery.run();
    }
    
    /**
     * Busca pólizas partir de su Id de Salesforce
     *
     * @author fpalomo
     * @date 20/11/2023
     * @param Set<Id> policyIds  Ids de las pólizas a recuperar
     * @return List<Policy__c> Listado de pólizas sobre los que se ha realizado match
     * 
     */
    public List<Policy__c> selectById(Set<String> policyIds)
    {
        if (policyIds == null || policyIds.size() == 0)
        {
            return new List<Policy__c>();
        }

        this.baseQuery.selectReadableFields();
        this.baseQuery.addConditionIn(Policy__c.Id, policyIds);
        
        return (List<Policy__c>) this.baseQuery.run();
    }


    /**
     * Obtiene las polizas no bloqueadas de un mediador
     *
     * @author dmunoz
     * @date 15/02/2024
     * 
     * 
     */
    public List<Policy__c> selectByIntermediaryId(Set<String> intermediaryIdsSet) {

        List<Policy__c> result = new List<Policy__c>();

        if (intermediaryIdsSet != null && !intermediaryIdsSet.isEmpty()) {
            result = new List<Policy__c>([SELECT Id, PolicyHolder__c, IntermediaryId__c 
                                        FROM Policy__c
                                        WHERE IntermediaryId__C IN: intermediaryIdsSet
                                        AND PolicyHolder__r.Blocked__c = FALSE
                                        AND PolicyHolder__r.Anonymized__c = FALSE
                                        AND PolicyStatus__c IN ('V', 'A') 
                                        AND Blocked__c = FALSE
                                        AND Anonymized__c = FALSE
                                        AND PolicyHolder__c != NULL]);

        }

        return result;
    }

    /**
     * Obtiene las polizas no bloqueadas de una agrupacion completa
     *
     * @author dmunoz
     * @date 15/02/2024
     * 
     * 
     */
    public List<Policy__c> selectByIntermediaryGroupId(Set<String> intermediaryGroupIdsSet) {

        List<Policy__c> result = new List<Policy__c>();

        if (intermediaryGroupIdsSet != null && !intermediaryGroupIdsSet.isEmpty()) {
            result = new List<Policy__c>([SELECT Id, PolicyHolder__c, IntermediaryId__c 
                                        FROM Policy__c
                                        WHERE IntermediaryId__r.IntermediaryGroup__c IN: intermediaryGroupIdsSet
                                        AND PolicyHolder__r.Blocked__c = FALSE
                                        AND PolicyHolder__r.Anonymized__c = FALSE
                                        AND PolicyStatus__c IN ('V', 'A') 
                                        AND Blocked__c = FALSE
                                        AND Anonymized__c = FALSE
                                        AND PolicyHolder__c != NULL]);

        }

        return result;
    }

    /**
     * Obtenemos las polizas de un mediador y las de una agrupacion con excepcion de un conjunto de polizas (necesario para el calculo de visibilidad)
     * QUERY: 
     * SELECT Id, PolicyHolder__c, IntermediaryId__c, IntermediaryId__r.IntermediaryGroup__c 
                                            FROM Policy__c 
                                            WHERE
                                            ID NOT IN: policiesToExclude
                                            AND PolicyHolder__c IN :policyHolderIdSet
                                            AND PolicyHolder__r.Blocked__c = FALSE
                                            AND PolicyHolder__r.Anonymized__c = FALSE
                                            AND (
                                                IntermediaryId__c IN :intermediaryIdsSet OR
                                                IntermediaryId__r.IntermediaryGroup__c IN :intermediaryGroupIdsSet
                                                )
                                            AND PolicyStatus__c IN ('V', 'A') 
                                            AND Blocked__c = FALSE
                                            AND Anonymized__c = FALSE
                                            AND PolicyHolder__c != NULL
     * @author dmunoz
     * @date 21/02/2024
     * 
     * 
     */
    public List<Policy__c> selectByIntermediaryAndIntermediaryGroupExcludingPolicies(Set<String> intermediaryIdsSet, Set<String> intermediaryGroupIdsSet, Set<String> policyHolderIdSet, Set<String> policiesToExclude)
    {
        List<Policy__c> result = new List<Policy__c>();

        if (intermediaryIdsSet != null && !intermediaryIdsSet.isEmpty() && policyHolderIdSet != null && !policyHolderIdSet.isEmpty())
        {
            this.baseQuery.selectFields(new List<Schema.SObjectField>{
                Policy__c.Id,
                Policy__c.PolicyHolder__c,
                Policy__c.IntermediaryId__c
            }).selectFields('Policy__c.IntermediaryId__r.IntermediaryGroup__c');

            this.baseQuery
                            .addConditionNotIn(Policy__c.Id, policiesToExclude)
                            .addConditionIn(Policy__c.PolicyHolder__c, policyHolderIdSet)
                            .addConditionEq(Policy__c.PolicyHolder__r.Blocked__c, false)
                            .addConditionEq(Policy__c.PolicyHolder__r.Anonymized__c, false)
                            .addConditionIn(Policy__c.PolicyStatus__c, new Set<String>{'V', 'A'})
                            .addConditionEq(Policy__c.Blocked__c, false)
                            .addConditionEq(Policy__c.Anonymized__c, false)
                            .addConditionNotEq(Policy__c.PolicyHolder__c, null);

            if (intermediaryGroupIdsSet != null && intermediaryGroupIdsSet.isEmpty())
            {
                this.baseQuery.addConditionIn(Policy__c.IntermediaryId__c, intermediaryIdsSet)
                            .setLimit(1);
            }

            else
            {
                this.baseQuery.addCondition(Query.doOr(
                    Query.conditionIn('IntermediaryId__c', intermediaryIdsSet),
                    Query.conditionIn('IntermediaryId__r.IntermediaryGroup__c', intermediaryGroupIdsSet)
                ));
            }

            result = this.baseQuery.enforceSecurity().run();
        }        

        return result;
    }

    /**
     * Obtenemos las polizas de un conjunto de clientes y una agrupación para el recalculo de visibilidad de zrm
     *
     * SELECT Id, PolicyHolder__c
     * FROM Policy__c 
     * WHERE PolicyHolder__c IN :policyHolderIdSet
     *  AND IntermediaryId__r.IntermediaryGroup__c = :intermediaryGroupId
     *  AND PolicyHolder__r.Blocked__c = FALSE
     *  AND PolicyHolder__r.Anonymized__c = FALSE
     *  AND PolicyStatus__c IN ('V', 'A') 
     *  AND Blocked__c = FALSE
     *  AND Anonymized__c = FALSE
     *  AND PolicyHolder__c != NULL
     * 
     * @author dmunoz
     * @date 19/03/2024
     * 
     */
    public List<Policy__c> policiesHoldersFromIntermediaryGroup(Set<String> policyHolderIdSet, String intermediaryGroupId) {

        List<Policy__c> result = new List<Policy__c>();

        if (policyHolderIdSet != null && !policyHolderIdSet.isEmpty() && intermediaryGroupId != null && String.isNotEmpty(intermediaryGroupId)) {
            Set<Schema.SObjectField> fieldsToRetrieve = new Set<Schema.SObjectField>
            {
                Policy__c.PolicyHolder__c
            };

            result = this.baseQuery
                            .selectFields(fieldsToRetrieve)
                            .addConditionIn(Policy__c.PolicyHolder__c, policyHolderIdSet)
                            .addConditionEq('Policy__c.IntermediaryId__r.IntermediaryGroup__c', intermediaryGroupId)
                            .addConditionEq(Policy__c.PolicyHolder__r.Blocked__c, false)
                            .addConditionEq(Policy__c.PolicyHolder__r.Anonymized__c, false)
                            .addConditionIn(Policy__c.PolicyStatus__c, new Set<String>{'V', 'A'})
                            .addConditionEq(Policy__c.Blocked__c, false)
                            .addConditionEq(Policy__c.Anonymized__c, false)
                            .addConditionNotEq(Policy__c.PolicyHolder__c, null)
                            .enforceSecurity()
                            .run();
        }

        return result;
    }

    /**
     * Obtenemos las polizas de un conjunto de clientes y una agrupación para el recalculo de visibilidad de zrm (Batch_RecalcVisibilityIntermediaryDMLs)
     *
     * @author dmunoz
     * @date 19/03/2024
     * 
     */
    public List<Policy__c> policiesHoldersFromIntermediaryGroupExcludePolicyHolders(Set<String> policyHolderIdSet, String intermediaryGroupId) {

        List<Policy__c> result = new List<Policy__c>();

        if (policyHolderIdSet != null && !policyHolderIdSet.isEmpty() && intermediaryGroupId != null && String.isNotEmpty(intermediaryGroupId)) {
            result = new List<Policy__c>([SELECT Id, PolicyHolder__c
                                        FROM Policy__c 
                                        WHERE PolicyHolder__c NOT IN :policyHolderIdSet
                                        AND IntermediaryId__r.IntermediaryGroup__c = :intermediaryGroupId
                                        AND PolicyHolder__r.Blocked__c = FALSE
                                        AND PolicyHolder__r.Anonymized__c = FALSE
                                        AND PolicyStatus__c IN ('V', 'A') 
                                        AND Blocked__c = FALSE
                                        AND Anonymized__c = FALSE
                                        AND PolicyHolder__c != NULL]);
        }

        return result;
    }

    
    /**
     * Devuelve un query locator para obtener las polizas de los mediadores a tener en cuenta para el batch de recalculo de visibilidad de mediador Batch_RecalcVisibilityIntermediary
     *
     * @author dmunoz
     * @date 19/03/2024
     * 
     */
    public String getIntermediaryPoliciesToRecalculateZRMVisibility(List<Account> intermediariesToProcess) {
        if (intermediariesToProcess != null && !intermediariesToProcess.isEmpty()) {
            return 'SELECT Id, PolicyHolder__c ' +
                    'FROM Policy__c  ' +
                    'WHERE IntermediaryId__c =  \'' + intermediariesToProcess.get(0).Id + '\'' +
                    'AND PolicyHolder__r.Blocked__c = FALSE ' +
                    'AND PolicyHolder__r.Anonymized__c = FALSE ' +
                    'AND PolicyStatus__c IN (\'V\', \'A\')  ' +
                    'AND Blocked__c = FALSE ' +
                    'AND Anonymized__c = FALSE ' + 
                    'AND PolicyHolder__c != NULL';
        } else {
            return null;
        }
    }


    /**
     * Obtenemos las polizas que han sufrido un cambio de mediador o cliente en las ultimas 24 horas y que el numero de reintentos sea menor al de la metadata
     * QUERY: 
     * SELECT Id, PolicyHolder__c, IntermediaryId__c, ZRMMovementType__c, LastAccountId__c
                                            FROM Policy__c 
                                            WHERE
                                            LastDateIntermediaryOrAccountChange__c = YESTERDAY
                                            AND VisibilityRetry__c <= :numMaxRetries
                                            
     * @author dmunoz
     * @date 08/04/2024
     * 
     * 
     */
    public List<Policy__c> getPoliciesToProcessIntermediaryOrAccountChange(Integer numMaxRetries) {

        List<Policy__c> result = new List<Policy__c>();

        // añado un valor por defecto por si viniera nulo el parámetro
        if (numMaxRetries == null || numMaxRetries <= 0) {
            numMaxRetries = 3;
        }

        this.baseQuery.selectFields
            (
                new List<Schema.SObjectField>
                {
                    Policy__c.Id,
                    Policy__c.PolicyHolder__c,
                    Policy__c.IntermediaryId__c,
                    Policy__c.ZRMMovementType__c,
                    Policy__c.LastAccountId__c,
                    Policy__c.VisibilityRetry__c
                }
            );

            this.baseQuery                            
                            .addConditionEq(Policy__c.LastDateIntermediaryOrAccountChange__c, Query.YESTERDAY)
                            .addConditionLe(Policy__c.VisibilityRetry__c, numMaxRetries);

            

            result = this.baseQuery.enforceSecurity().run();

        return result;
    }
    
}