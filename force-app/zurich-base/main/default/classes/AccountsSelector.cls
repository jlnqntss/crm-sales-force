public with sharing class AccountsSelector
{
    public Set<Id> recordTypeIds;

    /**
     * Busca cuentas a partir de un listado de DNIs
     *
     * @author rlopez
     * @date 04/11/2020
     * @change 25/11/2020 adelgado Cambio para hacer la query dinámica en base a los parámetros recibidos
     * @param  nationalIds          Listado de DNIs. Válido cualquier formato
     * @param  nationalIdType       Tipo de documento a buscar
     * @param  legalEntity          Entidad legal en la que buscar
     * @return                      Listado de cuentas sobre los que se ha realizado match
     */
    public List<Account> findByNationalId(List<String> nationalIds, String nationalIdType, String legalEntity)
    {
        String query = 'SELECT Id, Name, PersonContactId, NationalId__c, NumPolicies__pc, NumQuotes__pc FROM Account WHERE RecordTypeId IN: recordTypeIds AND NationalId__c IN : nationalIds';

        if(!String.isBlank(nationalIdType))
        {
            query += '  AND NationalIdType__c =: nationalIdType';
        }

        if(!String.isBlank(legalEntity))
        {
            query += '  AND LegalEntity__c =: legalEntity';
        }


        return Database.query(query);
    }

    /**
     * Instancia AccountsSelector inicializando la variable recordTypeIds con los IDs
     * de los tipos de registro que se utilizan en el Scope indicado com parámetro
     *
     * @author rlopez
     * @date 06/11/2020
     * @param  scope    Contexto en el que se utilizarán las búsqueda de contacto (ZE, OCS, ...)
     * @return          Instancia de AccountsSelector con la variable recordTypeIds inicializada
     */
    public AccountsSelector applyScope(String scope)
    {
        Map<ID, Schema.RecordTypeInfo> recordTypeInfosById = Schema.SObjectType.Account.getRecordTypeInfosById();
        Map<String, Schema.RecordTypeInfo> recordTypeInfosByDeveloperName = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();

        //Por defecto añadimos todos los recordTypeIds, y en los distintos scopes controlamos cuales se utilizan
        this.recordTypeIds = recordTypeInfosById.keySet();

        // Rellenamos el recordTypeIds con los Ids de cada scope
        switch on scope.toLowerCase() {
            when 'zurich empresas' {
                this.recordTypeIds = new Set<Id>();
                for (String recordTypeName: recordTypeInfosByDeveloperName.keySet()) {
                    if(recordTypeName == 'Customer' || recordTypeName == 'Lead')
                    {
                        this.recordTypeIds.add(recordTypeInfosByDeveloperName.get(recordTypeName).getRecordTypeId());
                    }
                }
            }
            when 'klink' {

            }
            when 'csm'
            {
                this.recordTypeIds = new Set<Id>();
                this.recordTypeIds.add(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId());
            }
        }

        return this;
    }

    /**
     * Busca cuentas a partir de sus puntos de contacto utilizando una SOSL y una SOQL para
     * maximizar resultados de búsqueda
     * @param  phones Listado de teléfonos. Válido cualquier formato
     * @return        Listado de cuentas sobre los que se ha realizado match
     */
    public List<Account> findByPhoneNumber(List<String> phones)
    {
        Set<Id> matchedRecordIds = ContactsSelector.findInContactPointsByPhoneNumber(phones);

        return [SELECT Id, Name, PersonContactId, NumPolicies__pc, NumQuotes__pc FROM Account WHERE (Id IN :matchedRecordIds) AND RecordTypeId IN :this.recordTypeIds];
    }

    /**
     * Busca cuentas a partir de sus puntos de contacto utilizando una SOSL y una SOQL para
     * maximizar resultados de búsqueda
     * @param  emails Listado de emails. Válido cualquier formato
     * @return        Listado de cuentas sobre los que se ha realizado match
     */
    public List<Account> findByEmail(List<String> emails)
    {
        Set<Id> matchedRecordIds = ContactsSelector.findInContactPointsByEmail(emails);

        return [SELECT Id, Name, PersonContactId, NumPolicies__pc, NumQuotes__pc FROM Account WHERE (Id IN :matchedRecordIds) AND RecordTypeId IN :this.recordTypeIds];
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
                if(policyNumbers.get(i) != null && policyNumbers.get(i).length() < 14)
                {
                    policyNumbers.set(i, policyNumbers.get(i).leftPad(14, '0'));
                }
            }
            return [SELECT Id, NumPolicies__pc, NumQuotes__pc FROM Account WHERE Id IN (SELECT PolicyHolder__c FROM Policy__c WHERE InfoPolicyNumber__c IN :policyNumbers) AND RecordTypeId IN :this.recordTypeIds];
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
                if(quoteNumbers.get(i) != null && quoteNumbers.get(i).length() < 14)
                {
                    quoteNumbers.set(i, quoteNumbers.get(i).leftPad(14, '0'));
                }
            }
            return [SELECT Id, NumPolicies__pc, NumQuotes__pc FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE InfoQuoteNumber__c IN :quoteNumbers) AND RecordTypeId IN :this.recordTypeIds];
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

        return [SELECT TerritorialDirectionCode__c, ChannelZoneCode__c, ZoneCode__c, CsmIndividualsManager__c, CsmAdministrationManager__c FROM Account WHERE Id IN :recordIds AND RecordTypeId IN :this.recordTypeIds];
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

            return [SELECT TerritorialDirectionCode__c, ChannelZoneCode__c, ZoneCode__c, CsmIndividualsManager__c, CsmAdministrationManager__c FROM Account WHERE INFOIntermediaryCode__c IN :paddedCodes AND RecordTypeId IN :this.recordTypeIds];
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
    public static List<Account> selectById(Set<Id> accountIds, Set<String> selectFields)
    {
        //Devolver lista vacía
        if ( accountIds == null || accountIds.isEmpty() )
        {
            return new List<Account>();
        }

        String query = String.format('SELECT {0} FROM Account WHERE Id IN :accountIds', new List<String> {String.join(new List<String> (selectFields), ',')});

        return (List<Account>) Database.query(query);
    }
}