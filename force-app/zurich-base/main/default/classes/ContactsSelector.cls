public with sharing class ContactsSelector
{
    public Set<Id> recordTypeIds;
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
        Set<Id> matchedRecordIds = findInContactPointsByPhoneNumber(phones);

        return [SELECT Id, AccountId FROM Contact WHERE (Id IN : matchedRecordIds OR AccountId IN : matchedRecordIds) AND (RecordTypeId IN: this.recordTypeIds OR Account.RecordTypeId IN :this.recordTypeIds) ];
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
        Set<Id> matchedRecordIds = findInContactPointsByEmail(emails);

        return [SELECT Id, AccountId FROM Contact WHERE (Id IN : matchedRecordIds OR AccountId IN : matchedRecordIds) AND (RecordTypeId IN: this.recordTypeIds OR Account.RecordTypeId IN :this.recordTypeIds)];
    }

    public static Set<Id> findInContactPointsByPhoneNumber(List<String> phones)
    {
        Set<Id> recordIds = new Set<Id>();

        for(List<SObject> records : [FIND :String.join(phones, ' OR ').replace('+', '\\+') IN PHONE FIELDS RETURNING ContactPointPhone(Id, ParentId, ContactId__c)])
        {
            for(sObject record : records)
            {
                ContactPointPhone contactPoint = (ContactPointPhone) record;

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

        return recordIds;
    }


    public static Set<Id> findInContactPointsByEmail(List<String> emails)
    {
        Set<Id> recordIds = new Set<Id>();

        for(List<SObject> records : [FIND :String.join(emails, ' OR ') IN EMAIL FIELDS RETURNING ContactPointEmail(Id, ParentId, ContactId__c)])
        {
            for(sObject record : records)
            {
                ContactPointEmail contactPoint = (ContactPointEmail) record;

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

        return recordIds;
    }

    /**
     * Instancia ContactSelector inicializando la variable recordTypeIds con los IDs
     * de los tipos de registro que se utilizan en el Scope indicado com parámetro
     *
     * @author rlopez
     * @date 06/11/2020
     * @param  scope    Contexto en el que se utilizarán las búsqueda de contacto (ZE, OCS, ...)
     * @return          Instancia de ContactSelector con la variable recordTypeIds inicializada
     */
    public ContactsSelector applyScope(String scope)
    {
        Map<ID, Schema.RecordTypeInfo> recordTypeInfosById = Schema.SObjectType.Contact.getRecordTypeInfosById();
        Map<String, Schema.RecordTypeInfo> recordTypeInfosByDeveloperName = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName();

        Set<Id> accountRecordTypeIds = Schema.SObjectType.Account.getRecordTypeInfosById().keySet();
        Map<String, Schema.RecordTypeInfo> accountRecordTypeInfosByDeveloperName = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();

        //Por defecto añadimos todos los recordTypeIds, y en los distintos scopes controlamos cuales se utilizan
        this.recordTypeIds = new Set<Id>();
        this.recordTypeIds.addAll(recordTypeInfosById.keySet());
        this.recordTypeIds.addAll(accountRecordTypeIds );

        // Rellenamos el recordTypeIds con los Ids de cada scope
        switch on scope.toLowerCase() {
            when 'zurich empresas' {
                this.recordTypeIds = new Set<Id>();
                for (String recordTypeName: accountRecordTypeInfosByDeveloperName.keySet()) {
                    if(recordTypeName == 'Customer' || recordTypeName == 'Lead')
                    {
                        this.recordTypeIds.add(accountRecordTypeInfosByDeveloperName.get(recordTypeName).getRecordTypeId());
                    }
                }
            }
            when 'klink' {
                
            }
        }

        return this;
    }
}
