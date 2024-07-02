/**
 * @description       : 
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 06-03-2024
 * @last modified by  : aberuete
**/
public with sharing class CasesSelector extends RecordsSelector
{
    //#region Contructores

    public CasesSelector()
    {
        super(Case.getSObjectType());
    }

    //#endregion

   

    public static final String CASES_LAST_DATE = 'Case.CreatedDate = LAST_N_DAYS:';
    public static final String CASES_MODIFY_LAST_DATE = 'Case.LastModifiedDate = LAST_N_DAYS:';
    public static final String CASES_END_DATE = 'Case.PolicyEndDate__c <= LAST_N_MONTHS:';
    public static final String ACCOUNT_RT_NAME_FIELD = 'Case.Account.RecordType.DeveloperName';
    public static final String CONTACT_PERSON_ACCOUNT_FIELD = 'Case.Account.PersonContactId';
    public static final String CASE_RT_NAME_FIELD = 'Case.RecordType.DeveloperName';
    public static final String CASE_ZRM_RT_NAME = 'ZRMInquiry';
    public static final String CASE_STATUS_WIN_CLOSED = 'Cerrado Ganado';
    public static final String CASE_STATUS_LOOSE_CLOSED = 'Cerrado Perdido';
    String uSPRecordTypeId = GlobalConfigUtil.getGlobalConfigurationValueId('Case_RecordType_USP_Id');
    String filterCallCenter = GlobalConfigUtil.getGlobalConfigurationValue('Query_Filter_Call_Center_USP');
    String filterStatusCerrado = GlobalConfigUtil.getGlobalConfigurationValue('Query_Filter_Status_Cerrado');
    String filterStatusPendiente = GlobalConfigUtil.getGlobalConfigurationValue('Query_Filter_Status_Pendiente');
    String filterStatusCombinado = GlobalConfigUtil.getGlobalConfigurationValue('Query_Filter_Status_Combinado');
    String filterTypeVenta = GlobalConfigUtil.getGlobalConfigurationValue('Query_Filter_Type_Venta');
    String filterSourceMediator = GlobalConfigUtil.getGlobalConfigurationValue('Query_Filter_Source_Area_Mediator');

   

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
            when else 
            {
                // else code
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
                    Case.Query__c, 
                    Case.RecordTypeId, 
                    Case.Status
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
            .addConditionEq(Case.RecordTypeId, CaseUtil.RT_ID_USPINQUIRY)
            .addConditionNotNull(Case.RobotDocumentId__c)
            .addConditionNull(Case.MediatedCustomer__c)
            .addConditionString(CASES_LAST_DATE + days);

            return this.baseQuery.toQueryString();
        }
        else
        {
            return '';
        }
    }
    
    /**
     * Método utilizado por la clase EmailMessageutil 
     * @author lrodriguez6@seidor.es
     * @date 01/04/2024
     * @param String days para filtrar la query
     * @return String query que se va a lanzar en el batch
     */
    public List<Case> findByIdControlCC(Set<String> caseIds)
    {
        Set<Schema.SObjectField> setFields =  new Set<Schema.SObjectField>{
            Case.Id,
            Case.ControlEmailCC__c,
            Case.RecordTypeId,
            Case.GenesysID__c
        };

        if(caseIds != null && !caseIds.isEmpty() )
        {
            
            this.baseQuery.selectFields(setFields)
            .addConditionIn(Case.Id,caseIds);
          
            return (List<Case>) this.baseQuery.run(); 
        }
        else
        {
            return new List<Case>();
        }
    }

    /**
     * Método utilizado por Batch_CloseInteractions para definir el scope
     * @author lrodriguez6@seidor.es
     * @date 12/02/2024
     * @return List<Case> que se va a lanzar en el batch
     */
    public List<Case> getCasesToCloseInteractions()
    {
        this.baseQuery.selectFields(new Set<Schema.SObjectField>{
            Case.Id
        })
        .addConditionEq(Case.RecordTypeId, CaseUtil.RT_ID_USPINQUIRY)
        .addConditionEq(Case.CloseInteractionBatch__c,true)
        .addConditionEq(Case.ExpectedClosingDate__c,System.TODAY())
        .addConditionEq(Case.CloseByBatch__c,false);

        System.debug('Casos recuperados desde Selector: '+(List<Case>)this.baseQuery.run());
        return (List<Case>) this.baseQuery.run();
        
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
            .addConditionEq(Case.RecordTypeId, CaseUtil.RT_ID_USPINQUIRY)
            .addConditionNotNull(Case.CreatedOffer__c)
            .addConditionNull(Case.OfferId__c)
            .addConditionString(CASES_LAST_DATE + days);

            return this.baseQuery.toQueryString();
        }
        else
        {
            return '';
        }
    }

    /**
     * Método utilizado por el batch Batch_RatioConversionIntermediary para obtener los casos que se tendrán en cuenta para
     * calcular el ratio sobre el mediador.
     * @author lrodriguez6@seidor.es
     * @date 08/02/2023
     * @param String days para filtrar la query
     * @return String query que se va a lanzar en el batch
     */
    public List<Case> getQueryCasesConversionRatio(List<Account> accountsIntermediary,String statusCombinado,String closeResult, String typeVenta, String rtCasesUSPId, String queryDays, String cerrado)
    {
        if(accountsIntermediary != null && closeResult!=null && statusCombinado!=null && !String.isBlank(statusCombinado) && typeVenta!=null && !String.isBlank(typeVenta) && rtCasesUSPId!=null && !String.isBlank(rtCasesUSPId) )
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField>{
                Case.AccountId,
                Case.QuotationStage__c
            })
            .addConditionIn(Case.AccountId, accountsIntermediary)
            .addConditionEq(Case.ParentId,null)
            .addConditionNotEq(Case.Status, statusCombinado)
            .addConditionNotEq(Case.CloseResult__c, closeResult)
            .addConditionNotEq(Case.AutomaticNotifications__c,true)
            .addConditionEq(Case.Type, typeVenta)
            .addConditionString(CASES_MODIFY_LAST_DATE+queryDays)
            .addConditionEq(Case.RecordTypeId,rtCasesUSPId )
            .addConditionEq(Case.Status,cerrado);

            return (List<Case>) this.baseQuery.run();
        }
        else
        {
            return new List<Case>() ;
        }
    }

    /**
     * Método utilizado por el batch Batch_RatioConversionIntermediary para obtener los casos hijos que se encuentran en estado ganado para 
     * calcular el ratio sobre el mediador.
     * @author lrodriguez6@seidor.es
     * @date 18/12/2023
     * @param List<Id> idsCasesFiltered, String statusWon
     * @return Map Casos Padre que tienen Casos Hijos Ganados
     */
    public Map <Id, Decimal> getMapChildCasesConversionRatio(List<Case> parentCases,String statusWon,String closeResult,String statusCombinado, String typeVenta, String rtCasesUSPId, String queryDays, String cerrado)
    {   
        List<Case> childCases = new List<Case>();
        Map <Id, Decimal> mapAllChildCases= new Map <Id,Decimal>();
        if(parentCases != null && statusWon!=null && !String.isBlank(statusWon) && closeResult!=null && !String.isBlank(closeResult) && statusCombinado!=null && !String.isBlank(statusCombinado) && typeVenta!=null && !String.isBlank(typeVenta) && rtCasesUSPId!=null && !String.isBlank(rtCasesUSPId) )
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField>{
                Case.QuotationStage__c,
                Case.ParentId
            })
            .addConditionIn(Case.ParentId, parentCases)
            .addConditionEq(Case.QuotationStage__c,statusWon)
            .addConditionNotEq(Case.Status, statusCombinado)
            .addConditionNotEq(Case.CloseResult__c, closeResult)
            .addConditionNotEq(Case.AutomaticNotifications__c,true)
            .addConditionEq(Case.Type, typeVenta)
            .addConditionString(CASES_MODIFY_LAST_DATE+queryDays)
            .addConditionEq(Case.RecordTypeId,rtCasesUSPId )
            .addConditionEq(Case.Status,cerrado);

            childCases=this.baseQuery.run();

            for (Case c:childCases)
            {
                if(mapAllChildCases.get(c.ParentId)==null)
                {
                    mapAllChildCases.put(c.ParentId,0);
                }

                mapAllChildCases.put(c.ParentId,(mapAllChildCases.get(c.ParentId)+1));

            }

            return mapAllChildCases;
        }
        else
        {
            return new Map <Id, Decimal>() ;
        }
    }



    /**
     * Método utilizado por el batch Batch_CompleteCases para obtener los casos de la última semana sin vinculación a Poliza u Oferta
     * @author arcortazar
     * @date 23/03/2022
     * @param String days para filtrar la query
     * @return String query que se va a lanzar en el batch
     */
    public String getQueryStringCasesWithoutPolicyOffer(String days, List<String> origins, List<String> recordTypes)
    {
        if(days != null && !String.isBlank(days) )
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField>{
                Case.Id,
                Case.PolicyId__c,
                Case.OfferId__c,
                Case.HegeoOfferId__c,
                Case.HegeoPolicyId__c,
                Case.HegeoPrePolicyId__c
            })
            .addConditionNull(Case.PolicyId__c)
            .addConditionNull(Case.OfferId__c)
            .addConditionString(CASES_LAST_DATE + days);

            if(origins != null && !origins.isEmpty())
            {
                this.baseQuery.addConditionIn(Case.Origin, origins);
            }

            if(recordTypes != null && !recordTypes.isEmpty())
            {
                List<String> idsRecordType = new List<String>();
                for(String rt : recordTypes)
                {
                    String recordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(rt).getRecordTypeId();
                    idsRecordType.add(recordTypeID);
                }
                this.baseQuery.addConditionIn(Case.RecordTypeId, idsRecordType);
            }

            System.debug('++++: ' + this.baseQuery.toQueryString());

            return this.baseQuery.toQueryString();
        }
        else
        {
            return '';
        }
    }

    /**
     * Busca los casos (de recordtype ZDA) cuyo CuTicketId__c coincide con los pasados por parametro
     * 
     * @author mario.navarro@seidor.com
     * @date 09/04/2029
     * @param ticketIds lista de CuTicketId__c a buscar
     * @return la lista de casos cuyo CuTicketId__c coincide con los de entrada
     */
    public List<Case> getCasesByTicketId(Set<String> ticketIds)
    {
        if (ticketIds == null || ticketIds.isEmpty())
        {
            return new List<Case>();
        }
        this.baseQuery.selectFields(new Set<Schema.SObjectField>{
            Case.CuTicketId__c
        })
        .addConditionEq(Case.RecordTypeId,CaseUtil.RT_ID_ZDA)
        .addConditionIn(Case.CuTicketId__c, ticketIds);

        return (List<Case>) this.baseQuery.run();
    }

    /**
     * Busca casos de tipo ZDA cuyo campo RelatedCuTicketId__c este informado
     * con alguno de los proporcionados en el set
     * 
     * Query que se ejecuta:
     * SELECT CuTicketId__c, Status, RelatedCuTicketId__c
     * FROM Case
     * WHERE RecordTypeId = :CaseUtil.RT_ID_ZDA
     * AND RelatedCuTicketId__c IN :relatedCuTicketIds
     * 
     * @author mario.navarro@seidor.com
     * @date 05/06/2024
     * @param relatedCuTicketIds lista de identificadores a buscar
     * @return lista de casos hijos encontrados por el campo RelatedCuTicketId__c
     */
    public List<Case> getZdaChildCases(Set<String> relatedCuTicketIds)
    {
        if (relatedCuTicketIds == null || relatedCuTicketIds.isEmpty())
        {
            return new List<Case>();
        }
        this.baseQuery.selectFields(new Set<Schema.SObjectField>{
            Case.CuTicketId__c,
            Case.Status,
            Case.RelatedCuTicketId__c
        })
        .addConditionEq(Case.RecordTypeId,CaseUtil.RT_ID_ZDA)
        .addConditionIn(Case.RelatedCuTicketId__c, relatedCuTicketIds);

        return (List<Case>) this.baseQuery.run();
    }

    /**
     * Busca el caso por identificador filtrando por (aparte del id) el recordtype de ZDA.
     * Retorna el caso con los campos CuTicketId__c, CaseNumber, Status, PendingBy__c, Owner.Name
     * 
     * @author mario.navarro@seidor.com
     * @date 25/04/2024
     * @param caseId identificador del caso a buscar
     * @return el caso encontrado o nulo si no se proporciona un id o no se encuentra
     */
    public Case getByIdWithZDAInfo(Id caseId)
    {
        Case caseFound = null;
        if (caseId == null)
        {
            return caseFound;
        }
        this.baseQuery.selectFields(new Set<Schema.SObjectField>{
            Case.CuTicketId__c,
            Case.CaseNumber,
            Case.Status,
            Case.PendingBy__c,
            Case.ResponseCanalUnico__c,
            Case.CloseResult__c,
            Case.RelatedCuTicketId__c,
            Case.Description
        })
        .selectFields('Case.Owner.Name')
        .addConditionEq(Case.RecordTypeId,CaseUtil.RT_ID_ZDA)
        .addConditionEq(Case.Id, caseId);
        List<Case> casesFound = (List<Case>) this.baseQuery.run();
        if (casesFound != null && !casesFound.isEmpty())
        {
            caseFound = casesFound[0];
        }
        return caseFound;
    }

    /**
     * Método que obtiene una lista de casos filtrados por el record type name de la cuenta asociada al caso
     * @author aberuete
     * @date 06/03/2024
     * @param List<Case> caseList : lista de casos a filtrar
     * @param List<String> recordTypeNamesAccount : lista de nombres de record types de cuenta a filtrar
    */
    public List<Case> getCasesFilterByRecordTypeNamesAccount (List<Case> caseList, List<String> recordTypeNamesAccount)
    {
        if (recordTypeNamesAccount != null && !recordTypeNamesAccount.isEmpty() && caseList != null && !caseList.isEmpty() )
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField>
            {
                Case.Id,
                Case.AccountId,
                Case.SprinklrSocialPersona__c
            })
            .selectFields(CONTACT_PERSON_ACCOUNT_FIELD)
            .addConditionIn(Case.Id, caseList)
            .addConditionIn(ACCOUNT_RT_NAME_FIELD, recordTypeNamesAccount);

            return (List<Case>) this.baseQuery.run();
        }
        
        return new List<Case>();
    }

    /**
     * Método que obtiene una lista de casos abiertos de Retenciones ZRM filtrados por las pólizas asociadas.
     * @author ivan.garcia.belen@seidor.com
     * @date 22/04/2024
     * @param relatedPolicyIds identificadores de póliza a filtrar 
    */
    public List<Case> getNotClosedZrmCasesByRelatedPolicy (Set<String> relatedPolicyIds)
    {
        if(relatedPolicyIds != null && !relatedPolicyIds.isEmpty())
        {
            Query.Condition andCondition = Query.doAnd(
                Query.conditionNotEq(Case.Status, CASE_STATUS_LOOSE_CLOSED),
                Query.conditionNotEq(Case.Status, CASE_STATUS_WIN_CLOSED));
                
            this.baseQuery.selectFields(new Set<Schema.SObjectField>
            {
                Case.Id,
                Case.PolicyId__c,
                Case.Status,
                Case.CaseNumber

            })
            .addConditionIn(Case.PolicyId__c, relatedPolicyIds)
            .addConditionEq(CASE_RT_NAME_FIELD, CASE_ZRM_RT_NAME)
            .addCondition(andCondition);
            
        
            return (List<Case>) this.baseQuery.run();
        }

        return new List<Case>();
    }

    /**
     * Método selector que devuelve los Casos de la comunidad ZRM, que no figuren como 'Cerrado'/'Cerrado Perdido'/'Cerrado Ganado'
     * y que su fecha de vencimiento haya pasado los 2 meses.
     * @author nikola.cobian@seidor.com
     * @date 22/04/2024
     * @param String recordTypeName, String months
     * RT y Fecha de vencimiento para filtrar la query
     * @return String query que se devuelve para operar en el batch
     */
    public String getQueryStringZRMExpiredAndNotClosedCasesWithPolicy(String recordTypeName, String months)
    {
        if(months != null && String.isNotEmpty(months) 
        && recordTypeName != null && String.isNotEmpty(recordTypeName) && recordTypeName == CaseUtil.RT_NAME_ZRM)
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField>{
                Case.Id,
                Case.Status,
                Case.RecordTypeId,
                Case.CauseOfLoss__c
            })
            .addConditionEq(Case.RecordTypeId, CaseUtil.RT_ID_ZRM)
            .addConditionNotNull(Case.PolicyId__c)
            .addConditionNotEq(Case.Status, Caseutil.CASE_CLOSED_LOST)
            .addConditionNotEq(Case.Status, Caseutil.CASE_CLOSED_WON)
            .addConditionNotEq(Case.Status, Caseutil.estadoCerrado)
            .addConditionString(CASES_END_DATE + months);

            return this.baseQuery.toQueryString();
        } 
        else 
        {
            return '';    
        }
    }

    /**
     * Método utilizado por Batch_CloseInteractions para definir el scope automaticamente (sin botón)
     * @author lrodriguez6@seidor.es
     * @date 04/06/2024
     * @return List<Case> que se va a lanzar en el batch
     */
    public List<Case> getCasesToCloseInteractionsAutomatic()
    {
        this.baseQuery.selectFields(new Set<Schema.SObjectField>{
            Case.Id
        })
        .addConditionEq(Case.RecordTypeId,uSPRecordTypeId)
        .addConditionEq(Case.CloseByBatch__c,false)
        .addConditionEq(Case.CallCenter__c,filterCallCenter)
        .addConditionNotEq(Case.Status,filterStatusCerrado)
        .addConditionNotEq(Case.Status,filterStatusPendiente)
        .addConditionNotEq(Case.Status,filterStatusCombinado)
        .addConditionEq(Case.AutomaticClosing__c,false)
        .addConditionEq(Case.InteractionStatus__c,false)
        .addConditionNotEq(Case.Type,filterTypeVenta)
        .addConditionEq(Case.OwnerUser__c,true)
        .addConditionEq(Case.SourceArea__c,filterSourceMediator);
        

        return (List<Case>) this.baseQuery.run();

    }
}