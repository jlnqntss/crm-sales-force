/**
 * Clase Selector para el objeto ContactRequest
 * 
 * @author nts (agonzalezisasi)
 * @date 02/06/2021
 */
public with sharing class ContactRequestSelector extends RecordsSelector {
    public static final String STATUS_CANCELLED = 'Cancelled';

    //#region Contructores
    public ContactRequestSelector() {
        super(ContactRequest.getSObjectType());
    }
    //#region

    /**
     * Metodo que recupera los ContactRequest de un cliente y que tienen una fecha y hora de preferencia
     * de contacto en el futuro con respecto a la fecha y hora indicada en los parametros.
     * 
     * No se consideran los que esten en estado Cancelado
     * 
     * El resultado vendra ordenado por prioridad en ascendente (0 es + prioritario) y por Fecha y hora
     * de preferencia de contacto en ascendente tambien.
     * 
     * Es decir que el primero de la lista deberia ser el mas prioritario y mas cercano en el tiempo a
     * la hora dada (normalmente la fecha y hora actual).
     * 
     * Ver campo formula Priority__c para determinar la relacion entre los estados y su prioridad
     * 
     * @author nts (agonzalezisasi)
     * @date 03/06/2021
     * @param {String customerId} Id del cliente
     * @param {Datetime fromWhen} fecha y hora a partir de la cual considerar los ContactRequest programados
     * @return {List<ContactRequest>} lista de objetos encontrados
     */
    public List<ContactRequest> findByCustomerIdAndContactDatetime(String customerId, Datetime fromWhen)
    {
        // Se añaden las condiciones de Cliente, Fecha y hora de contacto, Estado no Cancelado
        Query.Condition condition = Query.doAnd(
            Query.conditionEq(ContactRequest.WhoId, customerId),
            Query.conditionGt(ContactRequest.PreferredContactDatetime__c, fromWhen),
            Query.conditionNotEq(ContactRequest.Status, STATUS_CANCELLED)
        );

        // Se incluyen los siguientes campos, la condicion y ordenados por Prioridad en ascendente
        this.baseQuery.selectFields(new Set<Schema.SObjectField>{
            ContactRequest.Id,
            ContactRequest.GenesysInteractionId__c, 
            ContactRequest.PreferredContactDatetime__c, 
            ContactRequest.Status, 
            ContactRequest.Priority__c
        })
        .addCondition(condition)
        .addcondition(Query.conditionNotNull(ContactRequest.GenesysInteractionId__c))
        .orderBy(ContactRequest.Priority__c.getDescribe().getName(),'ASC' )
        .orderBy(ContactRequest.PreferredContactDatetime__c.getDescribe().getName(), 'ASC');

        return (List<ContactRequest>) this.baseQuery.run();
    }

    public List<ContactRequest> findByCustomerId(String customerId)
    {
        // TODO comprobar que funciona y deployear
        // Se añaden las condiciones de Cliente, Fecha y hora de contacto, Estado no Cancelado
        Query.Condition condition = Query.doAnd(
            Query.conditionEq(ContactRequest.WhoId, customerId),
            Query.conditionNotEq(ContactRequest.Status, STATUS_CANCELLED)
        );

        // Se incluyen los siguientes campos, la condicion y ordenados por Prioridad en ascendente
        this.baseQuery.selectFields(new Set<Schema.SObjectField>{
            ContactRequest.Id,
            ContactRequest.GenesysInteractionId__c, 
            ContactRequest.PreferredContactDatetime__c, 
            ContactRequest.Status, 
            ContactRequest.Preferred_Status__c
        })
        .addCondition(condition)
        .addcondition(Query.conditionNotNull(ContactRequest.GenesysInteractionId__c))
        .orderBy(ContactRequest.Preferred_Status__c.getDescribe().getName())
        .orderBy(ContactRequest.PreferredContactDatetime__c.getDescribe().getName());

        return (List<ContactRequest>) this.baseQuery.run();
    }
}