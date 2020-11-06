public with sharing class ContactsSelector
{
    /**
     * Busca contactos a partir de sus puntos de contacto utilizando una SOSL y una SOQL para
     * maximizar resultados de búsqueda
     *
     * @author jmartinezpisson
     * @date 02/11/2020
     * @param  phones Listado de teléfonos. Válido cualquier formato
     * @return        Listado de contactos sobre los que se ha realizado match
     */
    public static List<Contact> findByPhoneNumber(List<String> phones)
    {
        Set<Id> matchedRecordIds = findInContactPointsByPhoneNumber(phones);

        return [SELECT Id, AccountId FROM Contact WHERE Id IN : matchedRecordIds OR AccountId IN : matchedRecordIds];
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
    public static List<Contact> findByEmail(List<String> emails)
    {
        Set<Id> matchedRecordIds = findInContactPointsByEmail(emails);

        return [SELECT Id, AccountId FROM Contact WHERE Id IN : matchedRecordIds OR AccountId IN : matchedRecordIds];
    }

    private static Set<Id> findInContactPointsByPhoneNumber(List<String> phones)
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


    private static Set<Id> findInContactPointsByEmail(List<String> emails)
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
     * Busca contactos a partir de un listado de DNIs
     *
     * @author rlopez
     * @date 04/11/2020
     * @param  nationalIds          Listado de DNIs. Válido cualquier formato
     * @param  nationalIdType       Tipo de documento a buscar
     * @param  legalEntity          Entidad legal en la que buscar
     * @param  recordTypeName       Tipo de registro a buscar
     * @return                      Listado de contactos sobre los que se ha realizado match
     */
    public static List<Contact> findByNationalId(List<String> nationalIds, String nationalIdType, String legalEntity, String recordTypeName)
    {
        if( nationalIds != null && !nationalIds.isEmpty() )
        {
            if( String.isBlank(nationalIdType) )
            {
                nationalIdType = 'N';
            }
            if( String.isBlank(legalEntity) )
            {
                legalEntity = Label.LifeInsurance;
            }
            if( String.isBlank(recordTypeName) )
            {
                recordTypeName = 'Master';
            }
            Id accountRecordTypeId;
            Schema.RecordTypeInfo accountRecordTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeName);

            if(accountRecordTypeInfo != null)
            {
                accountRecordTypeId = accountRecordTypeInfo.getRecordTypeId();
            }

            return [SELECT Id, AccountId FROM Contact WHERE Account.NationalId__c IN : nationalIds AND Account.NationalIdType__c =: nationalIdType AND Account.LegalEntity__c =: legalEntity AND Account.RecordTypeId =: accountRecordTypeId];
        }
        else
        {
            return new List<Contact>();
        }
    }
}
