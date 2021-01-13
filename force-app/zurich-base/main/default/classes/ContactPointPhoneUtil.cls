/**
 *
 * @author rlopez
 * @date 23/11/2020
 */
public class ContactPointPhoneUtil
{
    public static Map<Id, List<ContactPointPhone> > relatedContactPointPhonesMap;
    public static Map<Id, Scope__c> relatedScopesMap;

    public static List<ContactPointPhone> contactPointPhonesToUpdate;
    public static List<Scope__c> scopesToUpdate;

    /**
     * Método que, en caso de insert o update, recupera los ContactPointPhone marcados con IsPrimary = true
     * relacionados con el ámbito y los propios ámbitos de los registros que recibimos en el trigger,
     * para actualizarlos al final del trigger
     *
     * @author rlopez
     * @date 23/11/2020
     */
    public static void getRelatedPrimaryContactPhones(List<ContactPointPhone> newList, Map<Id, ContactPointPhone> oldMap)
    {
        if(Trigger.isInsert || Trigger.isUpdate)
        {
            //Inicializamos mapas de registros relacionados
            relatedContactPointPhonesMap = new Map<Id, List<ContactPointPhone> >();
            relatedScopesMap = new Map<Id, Scope__c>();

            //Inicializamos listas de registros a actualizar al finalizar el trigger
            contactPointPhonesToUpdate = new List<ContactPointPhone>();
            scopesToUpdate = new List<Scope__c>();

            Set<Id> relatedScopes = new Set<Id>();

            for(ContactPointPhone newContactPointPhone: newList)
            {
                if(newContactPointPhone.ScopeId__c != null)
                {
                    relatedScopes.add(newContactPointPhone.ScopeId__c);
                }
            }

            List<ContactPointPhone> relatedContactPointPhones = new ContactPointPhonesSelector(
                new Set<String> {'Id', 'ScopeId__c', 'IsPrimary'}
                ).selectByScopeIdAndIsPrimary(relatedScopes, true, newList);

            for(ContactPointPhone relatedContactPointPhone: relatedContactPointPhones)
            {
                List<ContactPointPhone> ContactPointPhoneList = new List<ContactPointPhone>();
                if( relatedContactPointPhonesMap.containsKey(relatedContactPointPhone.ScopeId__c) )
                {
                    ContactPointPhoneList = relatedContactPointPhonesMap.get(relatedContactPointPhone.ScopeId__c);
                }

                ContactPointPhoneList.add(relatedContactPointPhone);
                relatedContactPointPhonesMap.put(relatedContactPointPhone.ScopeId__c, ContactPointPhoneList);
            }

            relatedScopesMap = new Map<Id, Scope__c>(
                new ScopesSelector(
                    new Set<String> {'Id', 'PrimaryPhone__c', 'AccountId__c', 'Scope__c'}
                    ).selectById(relatedScopes)
                );
        }
    }

    /**
     * Método que, en caso de insert o update, accede a sus registros relacionados y a su ámbito
     * para actualizar los campos correspondientes.
     *
     * Si el nuevo registro tiene IsPrimary = true, en el caso de los ContactPointPhone relacionados
     * actualizará el campo IsPrimary a false, y en el caso del ámbito actualizará el campo PrimaryPhone__c
     *
     * Si el campo no tiene IsPrimary = true y es una actualización de registro, se comprobará si ese registro
     * esta siendo actualizado de true a false para lanzar un error de que no se puede realizar dicha acción
     *
     * Si no es ninguno de los casos anteriores, se comprueba que el scope relacionado tenga el campo PrimaryPhone__c
     * informado. Si no es así, se informa con el campo TelephoneNumber.
     *
     * @author rlopez
     * @date 23/11/2020
     * @change 04/01/2021 adelgado Cambio para informar el teléfono primario del scope relacionado
     */
    public static void updateRelatedPrimaryContactPointPhones(List<ContactPointPhone> newList, Map<Id, ContactPointPhone> oldMap)
    {
        for(ContactPointPhone newContactPointPhone: newList)
        {
            if(newContactPointPhone.ScopeId__c != null)
            {
                Id key = newContactPointPhone.ScopeId__c;
                if( (oldMap == null && newContactPointPhone.IsPrimary) ||
                    oldMap != null && newContactPointPhone.IsPrimary && newContactPointPhone.IsPrimary != oldMap.get(newContactPointPhone.Id).IsPrimary
                     )
                {
                    //Ha pasado de false a true (es decir, lo han marcado como IsPrimary)
                    //Hay que marcar los relacionados a false
                    //Actualizamos ContactPointPhones
                    if ( relatedContactPointPhonesMap.containsKey(key) )
                    {
                        List<ContactPointPhone> relatedContactPointPhones = relatedContactPointPhonesMap.get(key);
                        for(ContactPointPhone relatedContactPoint: relatedContactPointPhones)
                        {
                            relatedContactPoint.IsPrimary = false;
                        }

                        contactPointPhonesToUpdate.addAll(relatedContactPointPhones);
                    }

                    //Actualizamos Scopes
                    if ( relatedScopesMap.containsKey(key) )
                    {
                        Scope__c relatedScope = relatedScopesMap.get(key);
                        if(relatedScope != null)
                        {
                            relatedScope.PrimaryPhone__c = newContactPointPhone.TelephoneNumber;
                            scopesToUpdate.add(relatedScope);
                        }
                    }
                }
                else if(oldMap != null && !newContactPointPhone.IsPrimary && newContactPointPhone.IsPrimary != oldMap.get(newContactPointPhone.Id).IsPrimary)
                {
                    //Ha pasado de true a false, no se puede quedar sin contacto primario
                    //Comprobamos si alguno de sus relacionados tiene primary = true, sino hay que devolver un error
                    Boolean isPrimaryFound = false;

                    if ( relatedContactPointPhonesMap.containsKey(key) )
                    {
                        List<ContactPointPhone> relatedContactPointPhones = relatedContactPointPhonesMap.get(key);
                        for(ContactPointPhone relatedContactPoint: relatedContactPointPhones)
                        {
                            if(relatedContactPoint.IsPrimary)
                            {
                                isPrimaryFound = true;
                            }
                        }
                    }

                    if(!isPrimaryFound)
                    {
                        newContactPointPhone.addError(Label.PrimaryContactPointPhoneRequired);
                    }
                }
                else
                {
                    if( relatedScopesMap.containsKey(key) && String.isBlank(relatedScopesMap.get(key).PrimaryPhone__c) )
                    {
                        Scope__c relatedScope = relatedScopesMap.get(key);
                        if(relatedScope != null)
                        {
                            relatedScope.PrimaryPhone__c = newContactPointPhone.TelephoneNumber;
                            scopesToUpdate.add(relatedScope);
                        }
                    }
                }
            }
        }
    }

    /**
     * Método que controla la generación del scope correspondiente
     * Actualmente solo se generá scope para ContactPointPhone que provengan de INFO
     *
     * @author adelgado
     * @date 07/12/2020
     */
    public static void generateScope(List<ContactPointPhone> newList)
    {
        List<ContactPointPhone> cppToGenerateScope = new List<ContactPointPhone>();

        for(ContactPointPhone contactPointPhone : newList)
        {
            if( String.isNotBlank(contactPointPhone.INFOContactPointNumber__c) && contactPointPhone.ScopeId__c == null)
            {
                cppToGenerateScope.add(contactPointPhone);
            }
        }

        if( !cppToGenerateScope.isEmpty() )
        {
            GenerateScopeUtil.generateScopeEvents('ParentId', null, cppToGenerateScope);
        }
    }

    /**
     * Método que actualiza los registros relacionados al finalizar el trigger
     *
     * @author rlopez
     * @date 23/11/2020
     */
    public static void updateRelatedContactPoints()
    {
        if( scopesToUpdate != null && !scopesToUpdate.isEmpty() )
        {
            update scopesToUpdate;
        }

        if( contactPointPhonesToUpdate != null && !contactPointPhonesToUpdate.isEmpty() )
        {
            update contactPointPhonesToUpdate;
        }
    }
}