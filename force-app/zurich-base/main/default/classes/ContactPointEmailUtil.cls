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
        relatedContactPointEmailsMap = new Map<Id, List<ContactPointEmail> >();
        relatedScopesMap = new Map<Id, Scope__c>();

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

        List<ContactPointEmail> relatedContactPointEmails = [
            SELECT Id, ScopeId__c, IsPrimary
            FROM ContactPointEmail
            WHERE ScopeId__c IN: relatedScopes AND IsPrimary = true AND Id NOT IN: newList
        ];

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

        relatedScopesMap = new Map<Id, Scope__c>([
                                                     SELECT Id, PrimaryEmail__c, PrimaryPhone__c, AccountId__c, Scope__c
                                                     FROM Scope__c
                                                     WHERE Id IN: relatedScopes
                                                 ]);
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
                            newContactPointEmail.addError('There should be at least one primary contact point email');
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