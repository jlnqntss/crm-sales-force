public with sharing class ContactsSelector
{
    /**
     * Busca contactos a partir de sus puntos de contacto utilizando una SOSL y una SOQL para
     * maximizar resultados de búsqueda
     * @param  phones Listado de teléfonos. Válido cualquier formato
     * @return        return description
     */
    public static List<Contact> findByPhoneNumber(List<String> phones)
    {
        Set<Id> matchedRecordIds = findInContactPointsByPhoneNumber(phones);

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

                if(String.isNotBlank(contactPoint.ParentId) )
                {
                    recordIds.add(contactPoint.ContactId__c);
                }

                if(String.isNotBlank(contactPoint.ContactId__c) )
                {
                    recordIds.add(contactPoint.ContactId__c);
                }
            }
        }

        return recordIds;
    }
}
