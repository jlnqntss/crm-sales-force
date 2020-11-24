/**
 *
 * @author rlopez
 * @date 19/11/2020
 */
public class ContactPointEmailUtil
{
    public static Map<Id, List<ContactPointEmail> > relatedContactPointEmailsMap;
    public static Map<Id, Scope__c> relatedScopesMap;

    public static List<ContactPointEmail> contactPointEmailsToUpdate;
    public static List<Scope__c> scopesToUpdate;

    public static void getRelatedPrimaryContactEmails(List<ContactPointEmail> newList, Map<Id, ContactPointEmail> oldMap)
    {
        if(Trigger.isInsert || Trigger.isUpdate)
        {
            //Inicializamos mapas de registros relacionados
            relatedContactPointEmailsMap = new Map<Id, List<ContactPointEmail> >();
            relatedScopesMap = new Map<Id, Scope__c>();

            //Inicializamos listas de registros a actualizar al finalizar el trigger
            contactPointEmailsToUpdate = new List<ContactPointEmail>();
            scopesToUpdate = new List<Scope__c>();

            Set<Id> relatedScopes = new Set<Id>();

            for(ContactPointEmail newContactPointEmail: newList)
            {
                if(newContactPointEmail.ScopeId__c != null)
                {
                    relatedScopes.add(newContactPointEmail.ScopeId__c);
                }
            }

            List<ContactPointEmail> relatedContactPointEmails = new ContactPointEmailsSelector(
                new Set<String> {'Id', 'ScopeId__c', 'IsPrimary'}
                ).selectByScopeIdAndIsPrimary(relatedScopes, true, newList);

            for(ContactPointEmail relatedContactPointEmail: relatedContactPointEmails)
            {
                List<ContactPointEmail> contactPointEmailList = new List<ContactPointEmail>();
                if( relatedContactPointEmailsMap.containsKey(relatedContactPointEmail.ScopeId__c) )
                {
                    contactPointEmailList = relatedContactPointEmailsMap.get(relatedContactPointEmail.ScopeId__c);
                }

                contactPointEmailList.add(relatedContactPointEmail);
                relatedContactPointEmailsMap.put(relatedContactPointEmail.ScopeId__c, contactPointEmailList);
            }

            relatedScopesMap = new Map<Id, Scope__c>(
                new ScopesSelector(
                    new Set<String> {'Id', 'PrimaryEmail__c', 'AccountId__c', 'Scope__c'}
                    ).selectById(relatedScopes)
                );
        }
    }

    public static void updateRelatedPrimaryContactPointEmails(List<ContactPointEmail> newList, Map<Id, ContactPointEmail> oldMap)
    {
        for(ContactPointEmail newContactPointEmail: newList)
        {
            if(newContactPointEmail.ScopeId__c != null)
            {
                Id key = newContactPointEmail.ScopeId__c;
                if( (Trigger.isInsert && newContactPointEmail.IsPrimary) ||
                    Trigger.isUpdate && newContactPointEmail.IsPrimary && newContactPointEmail.IsPrimary != oldMap.get(newContactPointEmail.Id).IsPrimary
                     )
                {
                    //Ha pasado de false a true (es decir, lo han marcado como IsPrimary)
                    //Hay que marcar los relacionados a false
                    //Actualizamos ContactPointEmails
                    if ( relatedContactPointEmailsMap.containsKey(key) )
                    {
                        List<ContactPointEmail> relatedContactPointEmails = relatedContactPointEmailsMap.get(key);
                        for(ContactPointEmail relatedContactPoint: relatedContactPointEmails)
                        {
                            relatedContactPoint.IsPrimary = false;
                        }

                        contactPointEmailsToUpdate.addAll(relatedContactPointEmails);
                    }

                    //Actualizamos Scopes
                    if ( relatedScopesMap.containsKey(key) )
                    {
                        Scope__c relatedScope = relatedScopesMap.get(key);
                        if(relatedScope != null)
                        {
                            relatedScope.PrimaryEmail__c = newContactPointEmail.EmailAddress;
                            scopesToUpdate.add(relatedScope);
                        }
                    }
                }
                else
                {
                    if(Trigger.isUpdate && !newContactPointEmail.IsPrimary && newContactPointEmail.IsPrimary != oldMap.get(newContactPointEmail.Id).IsPrimary)
                    {
                        //Ha pasado de true a false, no se puede quedar sin contacto primario
                        //Comprobamos si alguno de sus relacionados tiene primary = true, sino hay que devolver un error
                        Boolean isPrimaryFound = false;

                        if ( relatedContactPointEmailsMap.containsKey(key) )
                        {
                            List<ContactPointEmail> relatedContactPointEmails = relatedContactPointEmailsMap.get(key);
                            for(ContactPointEmail relatedContactPoint: relatedContactPointEmails)
                            {
                                if(relatedContactPoint.IsPrimary)
                                {
                                    isPrimaryFound = true;
                                }
                            }
                        }

                        if(!isPrimaryFound)
                        {
                            newContactPointEmail.addError(Label.PrimaryContactPointEmailRequired);
                        }
                    }
                }
            }
        }
    }

    public static void updateRelatedContactPoints()
    {
        if( !scopesToUpdate.isEmpty() )
        {
            update scopesToUpdate;
        }

        if( !contactPointEmailsToUpdate.isEmpty() )
        {
            update contactPointEmailsToUpdate;
        }
    }
}