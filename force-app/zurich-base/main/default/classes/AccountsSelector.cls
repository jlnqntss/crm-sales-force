/**
 * @description       :
 * @author            :
 * @group             :
 * @last modified on  : 25/09/2023
 * @last modified by  : jgallaga
 **/
public with sharing class AccountsSelector extends RecordsSelector
{
    public RecordsSelector.Scope relatedRecordsScope;

    // SDM: Campos del mediador donde se guardan los emails de los usuarios que cumplen una funcion dentro del mediador
    public static final String SDM_RN_EMAIL_FIELD = 'BusinessManagerEmail__c';      // Responsable de negocio
    public static final String SDM_DT_EMAIL_FIELD = 'TerritoryManagerEmail__c';     // Director Territorial
    public static final String SDM_DT_NAME_FIELD = 'TerritoryManagerName__c';
    public static final String SDM_DZ_EMAIL_FIELD = 'ManagerEmail__c';              // Director Zona
    public static final String SDM_DV_EMAIL_FIELD = 'LifeManagerEmail__c';          // Director Vida
    public static final String SDM_CV_EMAIL_FIELD = 'LifeConsultantEmail__c';       // Consultor Vida

    public static final String SDM_MAINEMAIL_FIELD = 'MainEmail__c';
    public static final String SDM_MAINMOBILEPHONE_FIELD = 'MainMobilePhone__c';
    public static final String SDM_RN_FIELD = 'TerritorialDirection__c';

    //#region Contructores

    public AccountsSelector()
    {
        super( Account.getSObjectType() );
    }

    //#endregion

    //#region RECORD TYPES
    public static final String RT_NAME_FIELD = 'Account.RecordType.DeveloperName';
    public static final String TYPE_FIELD = 'Account.Type';
    public static final String RT_NAME_AGRUPATION = 'AgrupacionMediador';
    public static final String RT_NAME_INTERMEDIARY = 'Intermediary';
    public static final String RT_NAME_CUSTOMER = 'Customer';
    public static final String RT_NAME_BUSINESSCUSTOMER = 'BusinessCustomer';
    public static final String RT_NAME_ACCOUNT_INTERMEDIARY= 'Intermediary';
    public static final String RT_NAME_LEAD= 'Lead';

    public static final String INTERMEDIARY_ACTIVE_1='001';
    public static final String INTERMEDIARY_ACTIVE_2='002';

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
    // Recupera el Id del RecordType de clientes personales
    public ID rtCustomerId {
        get {
            return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RT_NAME_CUSTOMER)?.getRecordTypeId();
        }
    }
    // Recupera el Id del RecordType de clientes Lead
    public ID rtLeadId {
        get {
            return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RT_NAME_LEAD)?.getRecordTypeId();
        }
    }
    // Recupera el Id del RecordType de clientes
    public ID rtBusinessCustomerId {
        get {
            return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RT_NAME_BUSINESSCUSTOMER)?.getRecordTypeId();
        }
    }

    //Recupera el Id del RecordType de cuentas Intermediario
    public ID rtAccountIntermediaryId {
        get {
            return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RT_NAME_ACCOUNT_INTERMEDIARY)?.getRecordTypeId();
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


        if( scope == RecordsSelector.Scope.ALL )   // ALL
        {
            this.baseQuery.addConditionIn(Account.RecordTypeId, new Set<String> {customerRecordType, businessRecordType, leadRecordType});
        }
        else if( scope == RecordsSelector.Scope.Z )     // Z
        {
            this.baseQuery.addConditionIn(Account.RecordTypeId, new Set<String> {customerRecordType, businessRecordType});

            this.relatedRecordsScope = RecordsSelector.Scope.Z;
        }
        else if( scope == RecordsSelector.Scope.ZE )     // ZE
        {
            this.baseQuery.addConditionIn(Account.RecordTypeId, new Set<String> {customerRecordType, leadRecordType, businessRecordType, partnerOCSRecordType});

            this.relatedRecordsScope = RecordsSelector.Scope.ZE;
        }
        else if( scope == RecordsSelector.Scope.ZEO )     // ZEO
        {
            this.baseQuery.addConditionIn(Account.RecordTypeId, new Set<String> {customerRecordType, leadRecordType, businessRecordType, partnerOCSRecordType});

            this.relatedRecordsScope = RecordsSelector.Scope.ZEO;
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
        if( legalEntity == RecordsSelector.LegalEntity.GI || legalEntity == RecordsSelector.LegalEntity.LIFE )   // GI,LIFE
        {
            this.baseQuery.addConditionEq( Account.LegalEntity__c, RecordsSelector.getLegalEntity(legalEntity) );
        }

        return this;
    }

    /**
     * Aplicar el filtro de record type name a los registros obtenidos en la búsqueda
     * @author aberuete
     * @date 02/06/2023
     * @param List<String> recordTypeNames : Listado de record type names a filtrar
     */
    public AccountsSelector setRecordType (List<String> recordTypeNames)
    {
        if ( recordTypeNames != null && !recordTypeNames.isEmpty() )
        {
            this.baseQuery.addConditionIn(RT_NAME_FIELD, recordTypeNames);
        }
        return this;
    }

    /**
     * Aplicar el filtro de tipo de cuenta a los registros obtenidos en la búsqueda
     * @author aberuete
     * @date 06/06/2023
     * @param List<String> typeNames : Listado de tipos de cuentas a filtrar
     */
    public AccountsSelector setTypeOfAccount (List<String> typeNames)
    {
        if ( typeNames != null && !typeNames.isEmpty() )
        {
            this.baseQuery.addConditionIn(TYPE_FIELD, typeNames);
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

        if( !String.isBlank(nationalIdType) )
        {
            this.baseQuery.addConditionEq(Account.NationalIdType__c, nationalIdType);
        }

        return (List<Account>) this.baseQuery.run();
    }

    /**
     * Busca cuentas a partir de un listado de DNIs y record type Customer o Business Customer
     * @author overes
     * @date 16/08/2023
     * @param  documents Listado de DNIs
     * @return           Listado de cuentas
     * **
     * @modification    Se añade que se ordene por fecha de creación
     * @author          jgallaga
     * @date            21/09/2023
     */
    public List<Account> findByNationalIdAndRcTypeCustAndBC(List<String> documents)
    {
        List<Account> result = new List<Account>();

        if (documents != null && !documents.isEmpty())
        {
            result = new List<Account>(
                [
                    SELECT  Id, FirstName, LastName, Intermediary_Name__c, Intermediary_Name__r.INFOIntermediaryCode__c,
                            NationalIdType__c, RecordType.DeveloperName, NationalId__c
                    FROM    Account
                    WHERE   NationalId__c IN :documents
                    AND     (
                                RecordTypeId = :rtCustomerId
                            OR
                                RecordTypeId = :rtBusinessCustomerId
                            )
                    ORDER BY LastModifiedDate DESC
                ]);
        }
        return result;
    }

    /**
    * Método que recupera el Name de id de cuenta pasado por parámentro
    * *
    * @author overes | 09-10-2023
    * @param documents
    * @return List<Account>
    **/
    public List<Account> findAccountNameById(List<String> ids)
    {
        return [SELECT Id, Name FROM account WHERE Id IN :ids];
    }

    /**
     * Busca cuentas a partir de un listado de DNIs y lecord type Lead
     * @author overes
     * @date 16/08/2023
     * @param  documents   Listado de DNIs
     * @return             Listado de cuentas sobre los que se ha realizado match
     *
     * @change amiranda 31/08/2023 Se elimina el campo 'Name' de la query. Es un
     * campo de solo lectura que se conforma por la concatenación de los campos
     * 'FirstName' y 'LastName' (entre otros) que son los que se consultarán
     * en la query. Por lo tanto, al intentar actualizar la lista de cuentas que
     *  nos devuelve este método, Salesforce lanza una excepción.
     * *
     * @modification    Se añade que el resultado este ordenado por fecha de creación, mas reciente primero
     * @author          jgallaga
     * @date            21/09/2023
     */
    public List<Account> findByNationalIdAndRcTypeLead(List<String> documents)
    {
        List<Account> result = new List<Account>();

        if (documents != null && !documents.isEmpty())
        {
            result = new List<Account>(
                [
                    SELECT  Id, FirstName, LastName, NationalIdType__c, Intermediary_Name__c, Intermediary_Name__r.INFOIntermediaryCode__c, RecordType.DeveloperName, NationalId__c
                    FROM    account
                    WHERE   NationalId__c IN :documents
                    AND     RecordTypeId = :rtLeadId
                    ORDER BY LastModifiedDate DESC
                ]);
        }
        return result;
    }

    /**
     * Busca cuentas a partir de un listado de números de teléfono y record types Lead
     * @author overes
     * @date 16/08/2023
     * @param  phones  Listado de números de teléfono
     * @return         Listado de cuentas sobre los que se ha realizado match
     */
    public List<Account> findByPhoneAndRcTypeLead(List<String> phones)
    {
        List<Account> result = new List<Account>();

        if (phones != null && !phones.isEmpty())
        {
            result = new List<Account>(
                [
                    SELECT  Id, FirstName, LastName, NationalIdType__c, Intermediary_Name__c, Intermediary_Name__r.INFOIntermediaryCode__c, NationalId__c, RecordType.DeveloperName, Phone
                    FROM    Account
                    WHERE   Phone IN :phones
                    AND     RecordTypeId = :rtLeadId
                    ORDER BY LastModifiedDate DESC]
                );
        }
        return result;
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
    }

    /**
     * Busca cuentas a partir de números de póliza
     * @param  policyNumbers números de póliza
     * @return listado de cuentas
     */
    public List<Account> findByPolicyNumber(String[] policyNumbers)
    {
        if( policyNumbers != null && !policyNumbers.isEmpty() )
        {
            for (Integer i = 0; i < policyNumbers.size(); i++)
            {
                // rellenar con 0 hasta completar 14 digitos
                if(policyNumbers.get(i) != null)
                {
                    policyNumbers.set( i, policyNumbers.get(i).leftPad(14, '0') );
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
        if( quoteNumbers != null && !quoteNumbers.isEmpty() )
        {
            for (Integer i = 0; i < quoteNumbers.size(); i++)
            {
                // rellenar con 0 hasta completar 14 digitos
                if(quoteNumbers.get(i) != null)
                {
                    quoteNumbers.set( i, quoteNumbers.get(i).leftPad(14, '0') );
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
            Account.NationalId__c,
            Account.Channel__c,
            Account.Segment__c,
            Account.Association__c
        }
        );

        this.baseQuery.addConditionEq(Account.RecordTypeId, intermediaryRecordTypeId);

        return (List<Account>) this.baseQuery.byId(recordIds).run();
    }

    /**
     * Busca cuentas de MEDIADORES partir de un código de intermediario
     * @param codes códigos de intermediario
     * @return listado de cuentas
     */
    public List<Account> findByIntermediaryCode(List<String> codes)
    {
        if( codes != null && !codes.isEmpty() )
        {
            Set<String> paddedCodes = new Set<String>();

            for(String code : codes)
            {
                paddedCodes.add( code.leftPad(10, '0') );

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
                Account.NationalId__c,
                Account.Channel__c,
                Account.Segment__c,
                Account.INFOIntermediaryCode__c,
                Account.IntermediaryGroup__c,
                Account.IsPartner,
                Account.Association__c
            }
            ).selectFields('Account.IntermediaryGroup__r.IntermediaryWithUser__c');

            this.baseQuery.addConditionEq(Account.INFOIntermediaryCode__c, paddedCodes);
            this.baseQuery.addConditionEq(Account.RecordTypeId, intermediaryRecordTypeId);

            return (List<Account>) this.baseQuery.run();
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
    public List<Account> findByIdsAndScope(Set<Id> accountIds, List<String> scopeTypes)
    {
        List<Account> result = new List<Account>();
        if( accountIds != null && !accountIds.isEmpty() && scopeTypes != null && !scopeTypes.isEmpty() )
        {
            result = [SELECT Id, SincronizarMC__pc,
                      (SELECT Id, Contactable__c FROM Scope__r WHERE Scope__c IN : scopeTypes)
                      FROM Account
                      WHERE Id IN : accountIds];
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
        this.baseQuery.selectFields (
            new List<Schema.SObjectField> {
            Account.Id,
            Account.ZoneCode__c,
            Account.MainMobilePhone__c,
            Account.Phone,
            Account.MainEmail__c,
            Account.NationalId__c,
            Account.INFOIntermediaryCode__c,
            Account.TerritorialDirection__c
        }
            ).selectFields('Account.RecordType.DeveloperName');

        //Devolver lista vacía
        if ( accountIds == null || accountIds.isEmpty() )
        {
            return new List<Account>();
        }

        return (List<Account>) this.baseQuery.byId(accountIds).run();
    }

    /**
     * Obtiene un listado de cuentas de Agrupacion
     */
    public List<Account> findAgrupatedIntermediaries(List<Account> acList)
    {
        Set<String> natIdSet = new Set<String>();
        for (Account a: acList)
        {
            if ( String.isNotBlank(a.NationalId__c) && !natIdSet.contains(a.NationalId__c) )
                natIdSet.add(a.NationalId__c);
        }

        this.baseQuery.selectFields (
            new List<Schema.SObjectField> {
            Account.Id,
            Account.NationalId__c,
            Account.Status__c,
            Account.StatusIntermediary__c
        }
            );
        this.baseQuery.addConditionEq(Account.RecordTypeId, rtAgrupationId);
        this.baseQuery.addConditionIn(Account.NationalId__c, natIdSet); //Meter parte del filtro del NationalId

        return (List<Account>) this.baseQuery.run();
    }

    public List<Account> findIntermediariesByParentId(Set<Id> parentIds)
    {
        List<Account> intermediaries = new List<Account>();

        if ( parentIds != null && !parentIds.isEmpty() )
        {
            this.baseQuery.selectFields
            (
                new List<Schema.SObjectField>
            {
                Account.Id,
                Account.ParentId,
                Account.NationalId__c,
                Account.Status__c,
                Account.StatusIntermediary__c
            }
            );

            this.baseQuery.addConditionIn(Account.ParentId, parentIds);
            this.baseQuery.addConditionEq(Account.RecordTypeId, rtIntermediaryId);

            intermediaries = (List<Account>) this.baseQuery.run();
        }

        return intermediaries;
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

        if( String.isNotBlank(email) && fields != null & !fields.isEmpty() )
        {
            Set<String> queryFields = new Set<String> {
                'Id', 'Name', 'ParentId', 'IntermediaryDescription__c', 'Zone__c'
            };
            queryFields.addAll(fields);
            this.baseQuery.selectFields(queryFields);
            String condition = String.join(new List<String>(fields), ' = \'' + email + '\' OR ') + ' = \'' + email + '\'';
            this.baseQuery.addConditionString(condition);
            this.baseQuery.addConditionEq(Account.RecordTypeId, this.rtIntermediaryId);

            result = (List<Account>) this.baseQuery.run();
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

        if( accounts != null && !accounts.isEmpty() && fields != null & !fields.isEmpty() )
        {
            this.baseQuery.selectFields(fields);
            this.baseQuery.addConditionIn(Account.Id, accounts);

            result = (List<Account>) this.baseQuery.run();
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

        if( subquery != null )
        {
            this.baseQuery.selectFields(new Set<String> {
                'Id', 'NationalId__c'
            });
            this.baseQuery.addConditionEq(Account.RecordTypeId, this.rtAgrupationId);
            this.baseQuery.addConditionIn(Account.Id, subquery);

            result = (List<Account>) this.baseQuery.run();
        }

        return result;
    }

    /**
     * Método utilizado por el batch RelateCasesToNewAccountsBatch para definir el scope
     * @author jjuaristi@seidor.es
     * @date 19/10/2022
     * @param String days para filtrar la query
     * @return String query que se va a lanzar en el batch
     */
    public List<Account> findByCIFAndCreationDate(List<String> cifs, String daysToRetrieve)
    {
        if( daysToRetrieve != null && !String.isBlank(daysToRetrieve) && cifs != null && !cifs.isEmpty() )
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField> {
                Account.Id,
                Account.NationalId__c,
                Account.Blocked__c
            })
            .addConditionIn(Account.NationalId__c, cifs)
            .addConditionNotEq(Account.Blocked__c, true)
            .addConditionString('CreatedDate = LAST_N_DAYS:' + daysToRetrieve);

            // Añadimos la condición de que el RT sea Customer o BusinessCustomer
            Query.Condition condition = Query.doOr
                                        (
                Query.conditionEq(Account.RecordTypeId, rtCustomerId),
                Query.conditionEq(Account.RecordTypeId, rtBusinessCustomerId)
                                        );

            this.baseQuery.addCondition(condition);

            return (List<Account>) this.baseQuery.run();
        }
        else
        {
            return new List<Account>();
        }
    }

    /**
     * Recupera las cuentas y los contactpointemails asociadas a ellas filtrando por tipo de cuenta, recordtype name y
     * que exista al menos un contactpointemail asociado para una lista de emails dada
     * @author aberuete
     * @date 16/08/2023
     * @param List<String> emails : Lista de direcciones de correo
     * @param List<String> recordTypeNames : Lista de record type names
     * @param List<String> typeNames : Lista de tipos de cuenta
     */
    public List<Account> findByEmailAdressRecordTypeNameAndType (List<String> emails,List<String> recordTypeNames, List<String> typeNames )
    {
        Query subquery = new Query( ContactPointEmail.getSObjectType() );
        subquery.selectFields(new List<Schema.SObjectField> {
            ContactPointEmail.ParentId
        });
        subquery.addConditionIn(ContactPointEmail.EmailAddress, emails);

        this.baseQuery.selectFields
        (
            new List<Schema.SObjectField>
        {
            Account.Id,
            Account.PersonContactId
        }
        );

        this.baseQuery.addSubquery(Query.subquery('ContactPointEmails').selectFields
                                   (
                                       new List<Schema.SObjectField>
        {
            ContactPointEmail.EmailAddress
        }
                                   )
                                   .addConditionIn(ContactPointEmail.EmailAddress,emails)
                                   );
        if ( recordTypeNames != null && !recordTypeNames.isEmpty() )
        {
            this.baseQuery.addConditionIn(RT_NAME_FIELD, recordTypeNames);
        }

        if ( typeNames != null && !typeNames.isEmpty() )
        {
            this.baseQuery.addConditionIn(TYPE_FIELD, typeNames);
        }

        this.baseQuery.addConditionIn(Account.Id, subquery);
        return (List<Account>) this.baseQuery.run();
    }

    /**
     * Recupera las cuentas y los contactpointphones asociadas a ellas filtrando por tipo de cuenta, recordtype name y
     * que exista al menos un contactpointphone asociado para una lista de teléfonos dada
     * @author aberuete
     * @date 16/08/2023
     * @param List<String> phones : Lista de teléfonos
     * @param List<String> recordTypeNames : Lista de record type names
     * @param List<String> typeNames : Lista de tipos de cuenta
     */
    public List<Account> findByPhoneRecordTypeNameAndType (List<String> phones,List<String> recordTypeNames, List<String> typeNames )
    {
        Query subquery = new Query( ContactPointPhone.getSObjectType() );
        subquery.selectFields(new List<Schema.SObjectField> {
            ContactPointPhone.ParentId
        });
        subquery.addConditionIn(ContactPointPhone.TelephoneNumber, phones);

        this.baseQuery.selectFields
        (
            new List<Schema.SObjectField>
        {
            Account.Id,
            Account.PersonContactId
        }
        );

        this.baseQuery.addSubquery(Query.subquery('ContactPointPhones').selectFields
                                   (
                                       new List<Schema.SObjectField>
        {
            ContactPointPhone.TelephoneNumber
        }
                                   )
                                   .addConditionIn(ContactPointPhone.TelephoneNumber,phones)
                                   );
        if ( recordTypeNames != null && !recordTypeNames.isEmpty() )
        {
            this.baseQuery.addConditionIn(RT_NAME_FIELD, recordTypeNames);
        }

        if ( typeNames != null && !typeNames.isEmpty() )
        {
            this.baseQuery.addConditionIn(TYPE_FIELD, typeNames);
        }

        this.baseQuery.addConditionIn(Account.Id, subquery);
        return (List<Account>) this.baseQuery.run();
    }


    /**
     * Método utilizado por el batch Batch_RatioConversionIntermediary para definir el scope
     * @author lrodriguez6@seidor.es
     * @date 06/02/2023
     * @return String query que se va a lanzar en el batch
     */

    public String getQueryStringAccountIntermediaryRatio()
    {

        this.baseQuery.selectFields(new Set<Schema.SObjectField> {
            Account.Id

        })

        .addConditionEq(Account.RecordTypeId, rtAccountIntermediaryId);

        // Añadimos la condición de que el RT sea Customer o BusinessCustomer
        Query.Condition condition = Query.doOr
                                    (
            Query.conditionEq(Account.Status__c,INTERMEDIARY_ACTIVE_1),
            Query.conditionEq(Account.Status__c,INTERMEDIARY_ACTIVE_2)
                                    );

        this.baseQuery.addCondition(condition);

        return this.baseQuery.toQueryString();
    }
    /**
     * Método utilizado por OpenIDConnectSalesforceCommunity para buscar la cuenta dummy a la que asociar los usuarios
     * @author dmunoz
     * @date 15/06/2023
     */
    public List<Account> findAccountByBusinessCode(List<String> businessCodeList)
    {

        List<Account> result = new List<Account>();

        if ( businessCodeList != null && !businessCodeList.isEmpty() )
        {
            result = new List<Account>([SELECT Id FROM Account WHERE INFOBusinessCode__c IN: businessCodeList]);
        }
        return result;

    }

    /**
     * Método que obtiene los cuentas tipo Lead que no tengan ofertas asociadas para borrarlas
     **
     * @author mfernandezcarrera
     * @date 28/06/2023
     **/
    public static String getAccountsToDelete()
    {
        String query =
            'SELECT Id from Account WHERE Id NOT IN (select AccountId from Opportunity) AND RecordType.Name=\'Lead\'';
        return query;
    }

    /**
     * Método que obtiene las cuentas filtradas por un conjunto de ids de cuentas, recordtype name y tipo de cuenta
     **
     * @author aberuete
     * @date 22/08/2023
     * @param Set<Id> accountIds: Conjunto de ids de cuentas
     * @param List<String> recordtypeNames : Lista de record type names
     * @param List<String> typeNames : Lista de nombres de tipo de cuenta
     **/
    public List<Account> findByAccountIdsRecordTypeNameAndType (Set<Id> accountIds, List<String> recordtypeNames, List<String> typeNames)
    {
        this.baseQuery.selectFields
        (
            new List<Schema.SObjectField>
        {
            Account.Id,
            Account.PersonContactId
        }
        );

        if ( recordTypeNames != null && !recordTypeNames.isEmpty() )
        {
            this.baseQuery.addConditionIn(RT_NAME_FIELD, recordTypeNames);
        }

        if ( typeNames != null && !typeNames.isEmpty() )
        {
            this.baseQuery.addConditionIn(TYPE_FIELD, typeNames);
        }

        return (List<Account>) this.baseQuery.byId(accountIds).run();
    }

    /**
     * @description Selector para conseguir las cuentas que tenga el código intermediario en el campo INFOIntermediaryCode__c
     * @author      jgallaga
     * @date        16/08/2023
     * *
     * @modification
     *              El query selector parece no ser capaz de recoger un campo del Parent, por lo que la query original no
     *              funciona. Se pone directamente la query para poder recuperar la información necesaria.
     *
     * @change amiranda 15/09/2023 se elimina la condición
     * 'IntermediaryGroup__r.IntermediaryWithUser__c != null' debido a que este
     * campo no siempre estará informado. Si una cuenta de tipo 'Agrupación'
     * solamente tiene asociada una cuenta de tipo 'Mediador' con usuario nominal,
     * no será necesario informar este campo ya que a los registros relacionados
     * se le asignará como Owner el Id del propio Mediador. No existe la necesidad
     * de buscar en su Agrupación cuál es el Mediador principal.
     *
     */
    public List<Account> findByINFOIntermediaryCode(List<String> intermediaryCodes)
    {
        List<Account> intermediaryAccounts = new List<Account>();

        if( intermediaryCodes == null || intermediaryCodes.isEmpty() )
        {
            return intermediaryAccounts;
        }

        this.baseQuery.selectFields(new List<Schema.SObjectField> {
            Account.INFOIntermediaryCode__c,
            Account.IntermediaryGroup__r.IntermediaryWithUser__c,
            Account.ParentId
        });

        this.baseQuery.addConditionIn(Account.INFOIntermediaryCode__c, intermediaryCodes);
        this.baseQuery.addConditionNotEq(Account.Parent.IntermediaryWithUser__c, null);

        return
        [
            SELECT  INFOIntermediaryCode__c, IntermediaryGroup__r.IntermediaryWithUser__c, IsPartner
            FROM    Account
            WHERE   INFOIntermediaryCode__c IN :intermediaryCodes
            AND     IntermediaryGroup__r.IntermediaryWithUser__c != null
        ];
    }


    /**
     * Busca account a las cuales se recalculará la visibilidad de ZRM para esos registros
     *
     * @author dmunoz
     * @date 21/09/2023
     * @return List<Account> Listado de account a las que recalcular la visibilidad
     */
    public List<Account> findAccountsWithIncorrectVisibility() {

        List<Account> result = new List<Account>([SELECT Id, Blocked__c, Intermediary_Name__c, Intermediary_Name__r.IsPartner, Intermediary_Name__r.IntermediaryGroup__c, 
                                                    Intermediary_Name__r.IntermediaryGroup__r.IntermediaryWithUser__c, IntermediaryVisibilityAcc__c 
                                                    FROM Account
                                                    WHERE RecordType.DeveloperName IN ('Customer','BusinessCustomer')
                                                    AND Intermediary_Name__r.IntermediaryGroup__c != null AND (IntermediaryVisibilityForm__c = null
                                                    OR (Intermediary_Name__r.IsPartner = true AND IntermediaryVisibilityForm__c = 'MainIntermediary')
                                                    OR (Intermediary_Name__r.IsPartner = false AND IntermediaryVisibilityForm__c = 'CurrentIntermediary'))]);

        return result;
    }

    /**
     * Busca account a las cuales se recalculará la visibilidad de ZRM para esos registros a partir de unos ids de clientes
     *
     * @author dmunoz
     * @date 21/09/2023
     * @return List<Account> Listado de account a las que recalcular la visibilidad
     */
    public List<Account> findAccountsWithIncorrectVisibilityByAccountId(Set<String> accountIds) {

        List<Account> result = new List<Account>();

        if (accountIds != null && !accountIds.isEmpty()) {
            result = new List<Account>([SELECT Id, Blocked__c, Intermediary_Name__c, Intermediary_Name__r.IsPartner, Intermediary_Name__r.IntermediaryGroup__c, 
                                            Intermediary_Name__r.IntermediaryGroup__r.IntermediaryWithUser__c, IntermediaryVisibilityAcc__c 
                                            FROM Account
                                            WHERE RecordType.DeveloperName IN ('Customer','BusinessCustomer') AND Id IN :accountIds
                                            AND Intermediary_Name__r.IntermediaryGroup__c != null AND (IntermediaryVisibilityForm__c = null
                                            OR (Intermediary_Name__r.IsPartner = true AND IntermediaryVisibilityForm__c = 'MainIntermediary')
                                            OR (Intermediary_Name__r.IsPartner = false AND IntermediaryVisibilityForm__c = 'CurrentIntermediary'))]);

        }

        return result;
    }


    /**
     * Busca account a las cuales hay que quitar la visibilidad de sus tareas y eventos
     *
     * @author dmunoz
     * @date 21/09/2023
     * @return List<Account> Listado de account a las que recalcular la visibilidad
     */
    public List<Account> findZRMBlockedAccountWithActivitiesFromIds(Set<String> accountIds) {

        List<Account> result = new List<Account>();

        if (accountIds != null && !accountIds.isEmpty()) {
            result = new List<Account>([SELECT Id, (SELECT Id, OwnerId FROM Tasks WHERE Owner.Profile.Name = 'Agente Ventas'),
                                        (SELECT Id, OwnerId FROM PersonTasks WHERE Owner.Profile.Name = 'Agente Ventas'),
                                        (SELECT Id, OwnerId FROM Events WHERE Owner.Profile.Name = 'Agente Ventas'),
                                        (SELECT Id, OwnerId FROM PersonEvents WHERE Owner.Profile.Name = 'Agente Ventas')
                                        FROM Account WHERE Id IN :accountIds AND Blocked__c = true]);

        }

        return result;
    }

}