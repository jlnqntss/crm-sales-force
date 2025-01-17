/**
 *
 * @author rlopez
 * @date 19/11/2020
 */
public with sharing class ContactPointEmailUtil
{
    public static Map<Id, List<ContactPointEmail> > relatedContactPointEmailsMap;
    public static Map<Id, Scope__c> relatedScopesMap;

    public static Map<Id, ContactPointEmail> contactPointEmailsToUpdate;
    public static Map<Id, Scope__c> scopesToUpdate;

    /**
     * Método que, en caso de insert o update, recupera los ContactPointEmail marcados con IsPrimary = true
     * relacionados con el ámbito y los propios ámbitos de los registros que recibimos en el trigger,
     * para actualizarlos al final del trigger
     *
     * @author rlopez
     * @date 20/11/2020
     */
    public static void getRelatedPrimaryContactEmails(List<ContactPointEmail> newList, Map<Id, ContactPointEmail> oldMap)
    {
        if(Trigger.isInsert || Trigger.isUpdate)
        {
            //Inicializamos mapas de registros relacionados
            relatedContactPointEmailsMap = new Map<Id, List<ContactPointEmail> >();
            relatedScopesMap = new Map<Id, Scope__c>();

            //Inicializamos listas de registros a actualizar al finalizar el trigger
            contactPointEmailsToUpdate = new Map<Id, ContactPointEmail>();
            scopesToUpdate = new Map<Id, Scope__c>();

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
                ).selectByScopeIdAndIsPrimary(relatedScopes, true, null);

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

    /**
     * Método que, en caso de insert o update, accede a sus registros relacionados y a su ámbito
     * para actualizar los campos correspondientes.
     *
     * Si el nuevo registro tiene IsPrimary = true, en el caso de los ContactPointEmail relacionados
     * actualizará el campo IsPrimary a false, y en el caso del ámbito actualizará el campo PrimaryEmail__c
     *
     * Si el campo no tiene IsPrimary = true y es una actualización de registro, se comprobará si ese registro
     * esta siendo actualizado de true a false para lanzar un error de que no se puede realizar dicha acción
     *
     * Si no es ninguno de los casos anteriores, se comprueba que el scope relacionado tenga el campo PrimaryEmail__c
     * informado. Si no es así, se informa con el campo EmailAddress.
     *
     * @author rlopez
     * @date 20/11/2020
     * @change 04/01/2021 adelgado Cambio para informar el email primario del scope relacionado
     * @change 24/04/2023 aberuete - Refactorizar método
     */
    public static void updateRelatedPrimaryContactPointEmails(List<ContactPointEmail> newList, Map<Id, ContactPointEmail> oldMap)
    {
        for(ContactPointEmail newContactPointEmail: newList)
        {
            if(newContactPointEmail.ScopeId__c != null)
            {
                Id key = newContactPointEmail.ScopeId__c;
                if( (oldMap == null && newContactPointEmail.IsPrimary) ||
                    oldMap != null && newContactPointEmail.IsPrimary && newContactPointEmail.IsPrimary != oldMap.get(newContactPointEmail.Id).IsPrimary ||
                    oldMap != null && newContactPointEmail.IsPrimary && newContactPointEmail.ScopeId__c != oldMap.get(newContactPointEmail.Id).ScopeId__c 
                     )
                {
                    //Ha pasado de false a true (es decir, lo han marcado como IsPrimary)
                    //Hay que marcar los relacionados a false
                    //Actualizamos ContactPointEmails

                    updateMapContactPointEmails(key, newContactPointEmail);

                    //Actualizamos Scopes
                    updateMapScopesToUpdate(key, newContactPointEmail);
                }
                else if(oldMap != null && !newContactPointEmail.IsPrimary && newContactPointEmail.IsPrimary != oldMap.get(newContactPointEmail.Id).IsPrimary)
                {
                    //Ha pasado de true a false, no se puede quedar sin contacto primario
                    //Comprobamos si alguno de sus relacionados tiene primary = true, sino hay que devolver un error

                    ifIsPrimaryFoundFalseThrowError(key, newContactPointEmail);
                }
                else
                {
                    updateMapScopesToUpdate(key, newContactPointEmail);
                }
            }
        }
    }

    /**
     * Método que controla la generación del scope correspondiente
     * Actualmente solo se generá scope para ContactPointEmail que provengan de INFO
     *
     * @author adelgado
     * @date 07/12/2020
     */
    public static void generateScope(List<ContactPointEmail> newList)
    {
        List<ContactPointEmail> cpeToGenerateScope = new List<ContactPointEmail>();

        for(ContactPointEmail contactPointEmail : newList)
        {
            if( String.isNotBlank(contactPointEmail.INFOContactPointNumber__c) && contactPointEmail.ScopeId__c == null
                && contactPointEmail.ParentId != null)
            {
                cpeToGenerateScope.add(contactPointEmail);
            }
        }

        if( !cpeToGenerateScope.isEmpty() )
        {
            GenerateScopeUtil.generateScopeEvents('ParentId', null, cpeToGenerateScope);
        }
    }

    /**
     * Método que actualiza los registros relacionados al finalizar el trigger
     *
     * @author rlopez
     * @date 20/11/2020
     */
    public static void updateRelatedContactPoints()
    {
           
        if( scopesToUpdate != null && !scopesToUpdate.values().isEmpty() )
        {
            update scopesToUpdate.values();
        }

        if( contactPointEmailsToUpdate != null && !contactPointEmailsToUpdate.values().isEmpty() )
        {
            update contactPointEmailsToUpdate.values();
        }
    }

    public static void establishAsPrimary(List<ContactPointEmail> newList, Map<Id, ContactPointEmail> oldMap)
    {
        if (oldMap != null)
        {
            for(ContactPointEmail cNuevo : newList)
            {
                ContactPointEmail cViejo = oldMap.get(cNuevo.id); 
                if(!cViejo.IsPrimary)
                {
                    cNuevo.IsPrimary = true;
                }
            }
        }
        else 
        {
            for(ContactPointEmail cNuevo : newList)
            {
                cNuevo.IsPrimary = true;
            }
        }
    }

    /**
     * Método que añade los contact points emails al mapa a actualizar
     *
     * @author aberuete
     * @date 25/04/2023
     */
    @testvisible
    private static void updateMapContactPointEmails(Id key, ContactPointEmail newContactPointEmail)
    {
        if ( relatedContactPointEmailsMap.containsKey(key) )
        {
            List<ContactPointEmail> relatedContactPointEmails = relatedContactPointEmailsMap.get(key);
            for(ContactPointEmail relatedContactPoint: relatedContactPointEmails)
            {
                relatedContactPoint.IsPrimary = false;
                contactPointEmailsToUpdate.put(relatedContactPoint.id, relatedContactPoint);
            }
        }
        
        if(contactPointEmailsToUpdate.containsKey(newContactPointEmail.Id))
        {
            contactPointEmailsToUpdate.remove(newContactPointEmail.Id);
        }   
    }

    /**
     * Método que actualiza los scope y los añade al mapa para actualizar
     *
     * @author aberuete
     * @date 25/04/2023
     */
    @testvisible
    private static void updateMapScopesToUpdate(Id key, ContactPointEmail newContactPointEmail)
    {
        if ( relatedScopesMap.containsKey(key) )
        {
            Scope__c relatedScope = relatedScopesMap.get(key);

            if( relatedScope != null )
            {
                relatedScope.PrimaryEmail__c = newContactPointEmail.EmailAddress;
                scopesToUpdate.put(relatedScope.Id, relatedScope);
            }
        }  
    }

    /**
     * Método que en caso de que no haya ningun contact point email relacionado que sea primario, lanza un error
     *
     * @author aberuete
     * @date 25/04/2023
     */
    @testvisible
    private static void ifIsPrimaryFoundFalseThrowError(Id key, ContactPointEmail newContactPointEmail)
    {
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