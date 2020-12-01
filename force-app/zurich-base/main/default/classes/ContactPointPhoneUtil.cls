/**
 *
 * @author rlopez
 * @date 23/11/2020
 */
public class ContactPointPhoneUtil
{
    public static Map<Id, List<ContactPointPhone> > relatedContactPointPhonesMap;
    public static Map<Id, Scope__c> relatedScopesMap;

    public static List<ContactPointPhone> ContactPointPhonesToUpdate;
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
            ContactPointPhonesToUpdate = new List<ContactPointPhone>();
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
     * @author rlopez
     * @date 23/11/2020
     */
    public static void updateRelatedPrimaryContactPointPhones(List<ContactPointPhone> newList, Map<Id, ContactPointPhone> oldMap)
    {
        for(ContactPointPhone newContactPointPhone: newList)
        {
            if(newContactPointPhone.ScopeId__c != null)
            {
                Id key = newContactPointPhone.ScopeId__c;
                if( (Trigger.isInsert && newContactPointPhone.IsPrimary) ||
                    Trigger.isUpdate && newContactPointPhone.IsPrimary && newContactPointPhone.IsPrimary != oldMap.get(newContactPointPhone.Id).IsPrimary
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

                        ContactPointPhonesToUpdate.addAll(relatedContactPointPhones);
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
                else
                {
                    if(Trigger.isUpdate && !newContactPointPhone.IsPrimary && newContactPointPhone.IsPrimary != oldMap.get(newContactPointPhone.Id).IsPrimary)
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
                }
            }
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
        if( !scopesToUpdate.isEmpty() )
        {
            update scopesToUpdate;
        }

        if( !ContactPointPhonesToUpdate.isEmpty() )
        {
            update ContactPointPhonesToUpdate;
        }
    }
}