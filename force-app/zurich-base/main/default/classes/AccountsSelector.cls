public with sharing class AccountsSelector extends RecordsSelector
{
    public RecordsSelector.Scope relatedRecordsScope;

    // SDM: Campos del mediador donde se guardan los emails de los usuarios que cumplen una funcion dentro del mediador
    public static final String SDM_RN_EMAIL_FIELD = 'BusinessManagerEmail__c';      // Responsable de negocio
    public static final String SDM_DT_EMAIL_FIELD = 'TerritoryManagerEmail__c';     // Director Territorial
    public static final String SDM_DV_EMAIL_FIELD = 'LifeManagerEmail__c';          // Director Vida
    public static final String SDM_CV_EMAIL_FIELD = 'LifeConsultantEmail__c';       // Consultor Vida

    //#region Contructores

    public AccountsSelector()
    {
        super(Account.getSObjectType());
    }

    //#endregion

    //#region RECORD TYPES
    
    public static final String RT_NAME_AGRUPATION = 'AgrupacionMediador';
    public static final String RT_NAME_INTERMEDIARY = 'Intermediary';

    // Recupera el Id del RecordType de cuentas de Agrupacion de Mediadores
    public ID rtAgrupationId {
        get {
            return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RT_NAME_AGRUPATION)?.getRecordTypeId();
        }
    }
    // Recupera el Id del RecordType de Mediadores
    public ID rtIntermediaryId {
        get {
            return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RT_NAME_INTERMEDIARY)?.getRecordTypeId();
        }
    }

    //#endregion

    /**
     * Aplicar el filtro de scope a los registros obtenidos en la búsqueda
     * @author adelgado
     * @date 02/02/2021
     * @param  scope  Scope a aplicar en el filtro
     * @return        Instancia de AccountsSelector con el filtro de scope aplicado
     */
    public AccountsSelector setScope(RecordsSelector.Scope scope)
    {
        Map<String, Schema.RecordTypeInfo> accountRecordTypeInfosByDeveloperName = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();

        String customerRecordType = accountRecordTypeInfosByDeveloperName.get('Customer').getRecordTypeId();
        String businessRecordType = accountRecordTypeInfosByDeveloperName.get('BusinessCustomer').getRecordTypeId();
        String leadRecordType = accountRecordTypeInfosByDeveloperName.get('Lead').getRecordTypeId();
        String partnerOCSRecordType = accountRecordTypeInfosByDeveloperName.get('PartnerOCS').getRecordTypeId();

        switch on scope
        {
            when ALL
            {
                this.baseQuery.addConditionIn(Account.RecordTypeId, new Set<String>{customerRecordType, businessRecordType, leadRecordType});
            }
            when Z
            {
                this.baseQuery.addConditionIn(Account.RecordTypeId, new Set<String>{customerRecordType, businessRecordType});

                this.relatedRecordsScope = RecordsSelector.Scope.Z;
            }
            when ZE
            {
                this.baseQuery.addConditionIn(Account.RecordTypeId, new Set<String>{customerRecordType, leadRecordType, businessRecordType, partnerOCSRecordType});

                this.relatedRecordsScope = RecordsSelector.Scope.ZE;
            }
            when ZEO
            {
                this.baseQuery.addConditionIn(Account.RecordTypeId, new Set<String>{customerRecordType, leadRecordType, businessRecordType, partnerOCSRecordType});
                
                this.relatedRecordsScope = RecordsSelector.Scope.ZEO;
            }
        }

        return this;
    }

    /**
     * Aplicar el filtro de entidad legal a los registros obtenidos en la búsqueda
     * @author adelgado
     * @date 28/01/2021
     * @param  legalEntity  Entidad legal a aplicar en el filtro
     * @return              Instancia de AccountsSelector con el filtro de entidad legal aplicado
     */
    public AccountsSelector setLegalEntity(RecordsSelector.LegalEntity legalEntity)
    {
        switch on legalEntity
        {
            when GI, LIFE
            {
                this.baseQuery.addConditionEq(Account.LegalEntity__c, RecordsSelector.getLegalEntity(legalEntity));
            }
        }

        return this;
    }

    /**
     * Busca cuentas a partir de un listado de DNIs
     *
     * @author rlopez
     * @date 04/11/2020
     * @change 25/11/2020 adelgado Cambio para hacer la query dinámica en base a los parámetros recibidos
     * @param  nationalIds          Listado de DNIs. Válido cualquier formato
     * @param  nationalIdType       Tipo de documento a buscar
     * @return                      Listado de cuentas sobre los que se ha realizado match
     */
    public List<Account> findByNationalId(List<String> nationalIds, String nationalIdType)
    {
        this.baseQuery.selectFields
        (
            new List<Schema.SObjectField>
            {
                Account.Id,
                Account.Name,
                Account.PersonContactId,
                Account.NationalId__c,
                Account.NumPolicies__pc,
                Account.NumQuotes__pc,
                Account.MainMobilePhone__c,
                Account.Phone,
                Account.MainEmail__c,
                Account.NationalId__c
            }
        );

        this.baseQuery.addConditionIn(Account.NationalId__c, nationalIds);

        //String query = 'SELECT Id, Name, PersonContactId, NationalId__c, NumPolicies__pc, NumQuotes__pc FROM Account WHERE RecordTypeId IN: recordTypeIds AND NationalId__c IN : nationalIds';

        if(!String.isBlank(nationalIdType))
        {
            this.baseQuery.addConditionEq(Account.NationalIdType__c, nationalIdType);
        }

        return (List<Account>) this.baseQuery.run();
    }

    /**
     * Busca cuentas a partir de sus puntos de contacto utilizando una SOSL y una SOQL para
     * maximizar resultados de búsqueda
     * @param  phones Listado de teléfonos. Válido cualquier formato
     * @return        Listado de cuentas sobre los que se ha realizado match
     */
    public List<Account> findByPhoneNumber(List<String> phones)
    {
        Set<Id> matchedRecordIds = ContactsSelector.findInContactPointsByPhoneNumber(phones, relatedRecordsScope);

        this.baseQuery.selectFields
        (
            new List<Schema.SObjectField>
            {
                Account.Id,
                Account.Name,
                Account.PersonContactId,
                Account.NationalId__c,
                Account.NumPolicies__pc,
                Account.NumQuotes__pc,
                Account.MainMobilePhone__c,
                Account.Phone,
                Account.MainEmail__c,
                Account.NationalId__c
            }
        );

        return (List<Account>) this.baseQuery.byId( matchedRecordIds).run();

        //return [SELECT Id, Name, PersonContactId, NumPolicies__pc, NumQuotes__pc FROM Account WHERE (Id IN :matchedRecordIds) AND RecordTypeId IN :this.recordTypeIds];
    }

    /**
     * Busca cuentas a partir de sus puntos de contacto utilizando una SOSL y una SOQL para
     * maximizar resultados de búsqueda
     * @param  emails Listado de emails. Válido cualquier formato
     * @return        Listado de cuentas sobre los que se ha realizado match
     */
    public List<Account> findByEmail(List<String> emails)
    {
        Set<Id> matchedRecordIds = ContactsSelector.findInContactPointsByEmail(emails, relatedRecordsScope);

        this.baseQuery.selectFields
        (
            new List<Schema.SObjectField>
            {
                Account.Id,
                Account.Name,
                Account.PersonContactId,
                Account.NationalId__c,
                Account.NumPolicies__pc,
                Account.NumQuotes__pc,
                Account.MainMobilePhone__c,
                Account.Phone,
                Account.MainEmail__c,
                Account.NationalId__c
            }
        );

        return (List<Account>) this.baseQuery.byId( matchedRecordIds).run();

        //return [SELECT Id, Name, PersonContactId, NumPolicies__pc, NumQuotes__pc FROM Account WHERE (Id IN :matchedRecordIds) AND RecordTypeId IN :this.recordTypeIds];
    }

    /**
     * Busca cuentas a partir de números de póliza
     * @param  policyNumbers números de póliza
     * @return listado de cuentas
     */
    public List<Account> findByPolicyNumber(String[] policyNumbers)
    {
        if(policyNumbers != null && !policyNumbers.isEmpty())
        {
            for (Integer i = 0; i < policyNumbers.size(); i++)
            {
                // rellenar con 0 hasta completar 14 digitos
                if(policyNumbers.get(i) != null)
                {
                    policyNumbers.set(i, policyNumbers.get(i).leftPad(14, '0'));
                }
            }

            this.baseQuery.selectFields
            (
                new List<Schema.SObjectField>
                {
                    Account.Id,
                    Account.Name,
                    Account.PersonContactId,
                    Account.NationalId__c,
                    Account.NumPolicies__pc,
                    Account.NumQuotes__pc,
                    Account.MainMobilePhone__c,
                    Account.Phone,
                    Account.MainEmail__c,
                    Account.NationalId__c
                }
            );

            this.baseQuery.lookup
            (
                'Id',
                new Query('Policy__c').selectField(Policy__c.PolicyHolder__c).addConditionIn(Policy__c.InfoPolicyNumber__c, policyNumbers)
            );

            return (List<Account>) this.baseQuery.run();

            //return [SELECT Id, NumPolicies__pc, NumQuotes__pc FROM Account WHERE Id IN (SELECT PolicyHolder__c FROM Policy__c WHERE InfoPolicyNumber__c IN :policyNumbers) AND RecordTypeId IN :this.recordTypeIds];
        }
        else
        {
            return new List<Account>();
        }

    }

    /**
     * Busca cuentas a partir de números de póliza
     * @param  policyNumbers números de póliza
     * @return listado de cuentas
     */
    public List<Account> findByQuoteNumber(String[] quoteNumbers)
    {
        if(quoteNumbers != null && !quoteNumbers.isEmpty())
        {
            for (Integer i = 0; i < quoteNumbers.size(); i++)
            {
                // rellenar con 0 hasta completar 14 digitos
                if(quoteNumbers.get(i) != null)
                {
                    quoteNumbers.set(i, quoteNumbers.get(i).leftPad(14, '0'));
                }
            }

            this.baseQuery.selectFields
            (
                new List<Schema.SObjectField>
                {
                    Account.Id,
                    Account.Name,
                    Account.PersonContactId,
                    Account.NationalId__c,
                    Account.NumPolicies__pc,
                    Account.NumQuotes__pc,
                    Account.MainMobilePhone__c,
                    Account.Phone,
                    Account.MainEmail__c,
                    Account.NationalId__c
                }
            );

            this.baseQuery.lookup
            (
                'Id',
                new Query('Opportunity').selectField(Opportunity.AccountId).addConditionIn(Opportunity.InfoQuoteNumber__c, quoteNumbers)
            );

            return (List<Account>) this.baseQuery.run();

            //return [SELECT Id, NumPolicies__pc, NumQuotes__pc FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE InfoQuoteNumber__c IN :quoteNumbers) AND RecordTypeId IN :this.recordTypeIds];
        }
        else
        {
            return new List<Account>();
        }
    }

    /**
     * Busca cuentas de MEDIADORES partir de un número de teléfono (No usan ContactPointPhone)
     * @param phones teléfonos
     * @param inIntermediary boolean para redirigir a la búsqueda de customers en vez de a mediadores
     * @return listado de cuentas
     */
    public List<Account> findByIntermediaryPhoneNumber(List<String> phones)
    {
        Set<Id> recordIds = new Set<Id>();

        for(List<SObject> records : [FIND :String.join(phones, ' OR ').replace('+', '\\+') IN PHONE FIELDS RETURNING Account(Id)])
        {
            for(sObject record : records)
            {
                recordIds.add(record.Id);
            }
        }

        String intermediaryRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();

        this.baseQuery.selectFields
        (
            new List<Schema.SObjectField>
            {
                Account.Id,
                Account.TerritorialDirectionCode__c,
                Account.ChannelZoneCode__c,
                Account.ZoneCode__c,
                Account.CsmIndividualsManager__c,
                Account.CsmAdministrationManager__c,
                Account.MainMobilePhone__c,
                Account.Phone,
                Account.MainEmail__c,
                Account.NationalId__c
            }
        );

        this.baseQuery.addConditionEq(Account.RecordTypeId, intermediaryRecordTypeId);

        return (List<Account>) this.baseQuery.byId(recordIds).run();

        //return [SELECT TerritorialDirectionCode__c, ChannelZoneCode__c, ZoneCode__c, CsmIndividualsManager__c, CsmAdministrationManager__c FROM Account WHERE Id IN :recordIds AND RecordTypeId IN :this.recordTypeIds];
    }

    /**
     * Busca cuentas de MEDIADORES partir de un código de intermediario
     * @param codes códigos de intermediario
     * @return listado de cuentas
     */
    public List<Account> findByIntermediaryCode(List<String> codes)
    {
        if(codes != null && !codes.isEmpty())
        {
            Set<String> paddedCodes = new Set<String>();

            for(String code : codes)
            {
                paddedCodes.add(code.leftPad(10, '0'));

            }

            String intermediaryRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();

            this.baseQuery.selectFields
            (
                new List<Schema.SObjectField>
                {
                    Account.Id,
                    Account.TerritorialDirectionCode__c,
                    Account.ChannelZoneCode__c,
                    Account.ZoneCode__c,
                    Account.CsmIndividualsManager__c,
                    Account.CsmAdministrationManager__c,
                    Account.MainMobilePhone__c,
                    Account.Phone,
                    Account.MainEmail__c,
                    Account.NationalId__c
                }
            );

            this.baseQuery.addConditionEq(Account.INFOIntermediaryCode__c, paddedCodes);
            this.baseQuery.addConditionEq(Account.RecordTypeId, intermediaryRecordTypeId);

            return (List<Account>) this.baseQuery.run();

            //return [SELECT TerritorialDirectionCode__c, ChannelZoneCode__c, ZoneCode__c, CsmIndividualsManager__c, CsmAdministrationManager__c FROM Account WHERE INFOIntermediaryCode__c IN :paddedCodes AND RecordTypeId IN :this.recordTypeIds];
        }
        else
        {
            return new List<Account>();
        }
    }

    /**
     * Find Accounts by Ids. Include the Scope__c childs of the Account, filtering them by Scope
     * Used:
     *    ScopeUtil.cls
     *
     * @author NTS (agonzalezisasi)
     * @date 10/12/2020
     * @param accountIds   list of account ids
     * @param scopeTypes    list of type of scopes to filter (ZE, ZEO)
     */
    public List<Account> findByIdsAndScope(Set<Id> accountIds, List<String> scopeTypes) {
        List<Account> result = new List<Account>();
        if( accountIds != null && !accountIds.isEmpty() && scopeTypes != null && !scopeTypes.isEmpty() ) {
            result = [SELECT Id, SincronizarMC__pc,
                        (SELECT Id, Contactable__c FROM Scope__r WHERE Scope__c IN :scopeTypes)
                      FROM Account
                      WHERE Id IN :accountIds];
        }
        return result;
    }

    /**
     * Obtiene un listado de cuentas según los IDs recibidos
     * @param accountIds: Listado de cuentas.  Si null, devolver Lista vacía.
     * @param selectFields: campos de la query.
     * @return Listado de cuentas
     */
    public List<Account> selectById(Set<Id> accountIds)
    {
        //Devolver lista vacía
        if ( accountIds == null || accountIds.isEmpty() )
        {
            return new List<Account>();
        }

        //String query = String.format('SELECT {0} FROM Account WHERE Id IN :accountIds', new List<String> {String.join(new List<String> (selectFields), ',')});

        return (List<Account>) this.baseQuery.byId(accountIds).run();
    }

    /**
     * Obtiene un listado de cuentas de Agrupacion 
     */
    public List<Account> findAgrupatedIntermediaries()
    {
        this.baseQuery.selectFields (
            new List<Schema.SObjectField> {
                Account.Id,
                Account.NationalId__c
            }
        );
        this.baseQuery.addConditionEq(Account.RecordTypeId, rtAgrupationId);

        return (List<Account>) this.baseQuery.run();
    }

    /**
     * Recupera los Mediadores que tengan el email dado en alguno de los campos de la lista dada.
     * 
     * @param {String email} el email a buscar
     * @param {List<String> fields} la lista de campos donde buscar
     */
    public List<Account> findIntermediariesByEmailInFields(String email, Set<String> fields)
    { 
        List<Account> result = null;

        if( String.isNotBlank(email) && fields != null & !fields.isEmpty() ) {
            Set<String> queryFields = new Set<String>{
                'Id', 'Name'
            };
            queryFields.addAll(fields);
            this.baseQuery.selectFields(queryFields);
            String condition = String.join(new List<String>(fields), ' = \'' + email + '\' OR ') + ' = \'' + email + '\'';
            this.baseQuery.addConditionString(condition);
            this.baseQuery.addConditionEq(Account.RecordTypeId, this.rtIntermediaryId);

            result = (List<Account>)this.baseQuery.run();
        }
        
        return result;
    }

    /**
     * Recupera las cuentas indicadas como parametro pero incluyendo los campos dados
     *
     * @param {List<Account> accounts} lista de cuentas
     * @param {List<String> fields} lista de campos
     */
    public List<Account> findWithFields(List<Account> accounts, Set<String> fields)
    {
        List<Account> result = null;

        if( accounts != null && !accounts.isEmpty() && fields != null & !fields.isEmpty() ) {
            this.baseQuery.selectFields(fields);
            this.baseQuery.addConditionIn(Account.Id, accounts);

            result = (List<Account>)this.baseQuery.run();
        }
        
        return result;
    }

    /**
     * Recupera los mediadores de tipo agrupacion cuyo id lo cumpla una subquery
     * Ejemplo: SELECT id FROM Account WHERE Id IN (SELECT AccountId FROM contact)
     * 
     * @author nts (agonzalezisasi)
     * @date 28/07/2021
     * 
     * @param {Query subquery} subquery con los ids a buscar
     * @return {List<Account>} lista de agrupaciones de mediador
     */
    public List<Account> findAgrupationsBySubquery(Query subquery)
    {
        List<Account> result = null;

        if( subquery != null ) {
            this.baseQuery.selectFields(new Set<String>{
                'Id', 'NationalId__c'
            });
            this.baseQuery.addConditionEq(Account.RecordTypeId, this.rtAgrupationId);
            this.baseQuery.addConditionIn(Account.Id, subquery);

            result = (List<Account>)this.baseQuery.run();            
        }

        return result;
    }
}