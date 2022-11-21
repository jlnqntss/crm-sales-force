public with sharing class CasesSelector extends RecordsSelector
{
    //#region Contructores

    public CasesSelector()
    {
        super(Case.getSObjectType());
    }

    //#endregion

    public static final String RT_NAME_USPINQUIRY = 'USPInquiry';

    // Recupera el Id del RecordType de casos USP
    public ID rtUSPId {
        get {
            return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(RT_NAME_USPINQUIRY)?.getRecordTypeId();
        }
    }

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
    public List<Case> findById(Set<String> caseIds, Boolean allData)
    {
        if(caseIds != null && !caseIds.isEmpty() )
        {
            if (allData == false) //Si no hay que obtener todos los datos se especifican cuales
            {
                this.baseQuery.selectFields(new Set<Schema.SObjectField>{
                    Case.Id,
                    Case.OwnerId, 
                    Case.Query__c
                 })
                .selectFields('Owner.Type')
                .selectFields('Owner.Profile.Name');
            }
            else {
                this.baseQuery.selectReadableFields();
            }
            this.baseQuery.addConditionString('Case.Id IN (\'' + String.join(new List<String>(caseIds), '\',\'') + '\')');

            this.baseQuery.debug();

            return (List<Case>) this.baseQuery.run(); 
        }
        else
        {
            return new List<Case>();
        }
    }

    public List<Case> findById(Set<String> caseIds)
    {
        return this.findById(caseIds, false);
    }

    public List<Case> findAllDataById(Set<String> caseIds)
    {
        return this.findById(caseIds, true);
    }


    /**
     * Método utilizado por el batch RelateCasesToNewAccountsBatch para definir el scope
     * @author jjuaristi@seidor.es
     * @date 19/10/2022
     * @param String days para filtrar la query
     * @return String query que se va a lanzar en el batch
     */
    public String getQueryStringCasesToRelateToNewAccounts(String days)
    {
        if(days != null && !String.isBlank(days) )
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField>{
                Case.Id,
                Case.RobotDocumentId__c,
                Case.MediatedCustomer__c
            })
            .addConditionEq(Case.RecordTypeId, rtUSPId)
            .addConditionNotNull(Case.RobotDocumentId__c)
            .addConditionNull(Case.MediatedCustomer__c)
            .addConditionString('Case.CreatedDate = LAST_N_DAYS:' + days);

            return this.baseQuery.toQueryString();
        }
        else
        {
            return '';
        }
    }

    /**
     * Método utilizado por el batch RelateCasesToNewOffersBatch para definir el scope
     * @author lrodriguez6@seidor.es
     * @date 11/11/2022
     * @param String days para filtrar la query
     * @return String query que se va a lanzar en el batch
     */
    public String getQueryStringCasesToRelateToNewOffers(String days)
    {
        if(days != null && !String.isBlank(days) )
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField>{
                Case.Id,
                Case.CreatedOffer__c,
                Case.OfferId__c
            })
            .addConditionEq(Case.RecordTypeId, rtUSPId)
            .addConditionNotNull(Case.CreatedOffer__c)
            .addConditionNull(Case.OfferId__c)
            .addConditionString('Case.CreatedDate = LAST_N_DAYS:' + days);

            return this.baseQuery.toQueryString();
        }
        else
        {
            return '';
        }
    }

}