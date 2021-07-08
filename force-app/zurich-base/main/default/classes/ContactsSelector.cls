public with sharing class ContactsSelector extends RecordsSelector
{
    public RecordsSelector.Scope relatedRecordsScope;

    //#region Contructores

    public ContactsSelector()
    {
        super(Contact.getSObjectType());
    }

    //#endregion

    public static final String RT_NAME_CONTACT = 'Contact';

    // Recupera el Id del RecordType de cuentas de tipo CONTACT
    public ID rtContactId {
        get {
            return Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(RT_NAME_CONTACT)?.getRecordTypeId();
        }
    }

    /**
     * Aplicar el filtro de scope a los registros obtenidos en la búsqueda
     * @author adelgado
     * @date 02/02/2021
     * @param  scope  Scope a aplicar en el filtro
     * @return        Instancia de ContactsSelector con el filtro de scope aplicado
     */
    public ContactsSelector setScope(RecordsSelector.Scope scope)
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
                this.baseQuery.addConditionIn('Account.RecordTypeId', new Set<String>{customerRecordType, businessRecordType, leadRecordType});
            }
            when Z 
            {
                this.baseQuery.addConditionIn('Account.RecordTypeId', new Set<String>{customerRecordType, businessRecordType});

                this.relatedRecordsScope = RecordsSelector.Scope.Z;
            }
            when ZE  
            {
                this.baseQuery.addConditionIn('Account.RecordTypeId', new Set<String>{customerRecordType, leadRecordType, businessRecordType, partnerOCSRecordType});

                this.relatedRecordsScope = RecordsSelector.Scope.ZE;
            }
            when ZEO
            {
                this.baseQuery.addConditionIn('Account.RecordTypeId', new Set<String>{customerRecordType, leadRecordType, businessRecordType, partnerOCSRecordType});
                
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
     * @return              Instancia de ContactsSelector con el filtro de entidad legal aplicado
     */
    public ContactsSelector setLegalEntity(RecordsSelector.LegalEntity legalEntity)
    {
        switch on legalEntity 
        {
            when GI, LIFE
            {
                Query.Condition condition = Query.doOr
                (
                    Query.conditionEq(Contact.LegalEntity__c, RecordsSelector.getLegalEntity(legalEntity)),
                    Query.conditionEq('Account.LegalEntity__c', RecordsSelector.getLegalEntity(legalEntity))
                );

                this.baseQuery.addCondition(condition);
            }
        }

        return this;
    }

    /**
     * Busca contactos a partir de sus puntos de contacto utilizando una SOSL y una SOQL para
     * maximizar resultados de búsqueda
     *
     * @author jmartinezpisson
     * @date 02/11/2020
     * @param  phones Listado de teléfonos. Válido cualquier formato
     * @return        Listado de contactos sobre los que se ha realizado match
     */
    public List<Contact> findByPhoneNumber(List<String> phones)
    {
        Set<Id> matchedRecordIds = findInContactPointsByPhoneNumber(phones, relatedRecordsScope);

        Query.Condition condition = Query.doOr
        (
            Query.conditionIn(Contact.Id, matchedRecordIds),
            Query.conditionIn(Contact.AccountId, matchedRecordIds)
        );

        this.baseQuery.selectFields
        (
            new Set<Schema.SObjectField>
            {
                Contact.Id, 
                Contact.AccountId
            }
        )
        .addCondition(condition);
       

        return (List<Contact>) this.baseQuery.run();

        //return [SELECT Id, AccountId FROM Contact WHERE (Id IN : matchedRecordIds OR AccountId IN : matchedRecordIds) AND (RecordTypeId IN: this.recordTypeIds OR Account.RecordTypeId IN :this.recordTypeIds) ];
    }

    /**
     * Busca contactos a partir de sus puntos de contacto utilizando una SOSL y una SOQL para
     * maximizar resultados de búsqueda
     *
     * @author jmartinezpisson
     * @date 02/11/2020
     * @param  emails Listado de emails. Válido cualquier formato
     * @return        Listado de contactos sobre los que se ha realizado match
     */
    public List<Contact> findByEmail(List<String> emails)
    {
        Set<Id> matchedRecordIds = findInContactPointsByEmail(emails, relatedRecordsScope);

        Query.Condition condition = Query.doOr
        (
            Query.conditionIn(Contact.Id, matchedRecordIds),
            Query.conditionIn(Contact.AccountId, matchedRecordIds)
        );

        this.baseQuery.selectFields
        (
            new Set<Schema.SObjectField>
            {
                Contact.Id, 
                Contact.AccountId
            }
        ).addCondition(condition);

        return (List<Contact>) this.baseQuery.run();

        //return [SELECT Id, AccountId FROM Contact WHERE (Id IN : matchedRecordIds OR AccountId IN : matchedRecordIds) AND (RecordTypeId IN: this.recordTypeIds OR Account.RecordTypeId IN :this.recordTypeIds)];
    }

    public static Set<Id> findInContactPointsByPhoneNumber(List<String> phones, RecordsSelector.Scope scope)
    {
        Set<Id> recordIds = new Set<Id>();

        for(List<SObject> records : [FIND :String.join(phones, ' OR ').replace('+', '\\+') IN PHONE FIELDS RETURNING ContactPointPhone(Id, ParentId, ContactId__c, Scope__c)])
        {
            for(sObject record : records)
            {
                ContactPointPhone contactPoint = (ContactPointPhone) record;

                if(scope == null || contactPoint.Scope__c == scope.name())
                {
                    if( String.isNotBlank(contactPoint.ParentId) )
                    {
                        recordIds.add(contactPoint.ParentId);
                    }

                    if( String.isNotBlank(contactPoint.ContactId__c) )
                    {
                        recordIds.add(contactPoint.ContactId__c);
                    }
                }
            }
        }

        return recordIds;
    }


    public static Set<Id> findInContactPointsByEmail(List<String> emails, RecordsSelector.Scope scope)
    {
        Set<Id> recordIds = new Set<Id>();

        for(List<SObject> records : [FIND :String.join(emails, ' OR ') IN EMAIL FIELDS RETURNING ContactPointEmail(Id, ParentId, ContactId__c, Scope__c)])
        {
            for(sObject record : records)
            {
                ContactPointEmail contactPoint = (ContactPointEmail) record;

                if(scope == null || contactPoint.Scope__c == scope.name())
                {
                    if( String.isNotBlank(contactPoint.ParentId) )
                    {
                        recordIds.add(contactPoint.ParentId);
                    }

                    if( String.isNotBlank(contactPoint.ContactId__c) )
                    {
                        recordIds.add(contactPoint.ContactId__c);
                    }
                }
            }
        }

        return recordIds;
    }

    /**
     * Busca contactos que tengan los emails dados por parametro en el campo Email
     *
     * @author nts (agonzalezisasi)
     * @date 05/07/2021
     * @param  emails Listado de emails. Válido cualquier formato
     * @return        Listado de contactos sobre los que se ha realizado match
     */
    public List<Contact> findByEmailField(List<String> emails)
    {
        List<Contact> result = null;

        if( emails != null && !emails.isEmpty() ) {
            this.baseQuery.selectFields (
                new Set<Schema.SObjectField> {
                    Contact.Id, 
                    Contact.Email
                }
            );
            this.baseQuery.addConditionIn(Contact.Email, emails);

            result = (List<Contact>) this.baseQuery.run();
        }
        return result;
    }

}