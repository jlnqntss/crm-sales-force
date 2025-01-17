/**
 * Clase Selector para el objeto ContactRequest
 *
 * @author nts (agonzalezisasi)
 * @date 02/06/2021
 */
public with sharing class ContactRequestSelector extends RecordsSelector
{
    public static final String STATUS_CANCELLED = 'Cancelled';

    //#region Contructores
    public ContactRequestSelector()
    {
        super( ContactRequest.getSObjectType() );
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
        this.baseQuery.selectFields(new Set<Schema.SObjectField> {
            ContactRequest.Id,
            ContactRequest.GenesysInteractionId__c,
            ContactRequest.PreferredContactDatetime__c,
            ContactRequest.Status,
            ContactRequest.Priority__c
        })
        .addCondition(condition)
        .addcondition( Query.conditionNotNull(ContactRequest.GenesysInteractionId__c) )
        .orderBy(ContactRequest.Priority__c.getDescribe().getName(),'ASC' )
        .orderBy(ContactRequest.PreferredContactDatetime__c.getDescribe().getName(), 'ASC');

        return (List<ContactRequest>) this.baseQuery.run();
    }

    /**
     * Función que instancia el Selector de la entidad Contact Request.
     * Consulta la BBDD de Salesforce y retorna los registros relacionados de un cliente (Account)
     * @date 17/11/2021
     * @author jjuaristi@nts-solutions.com
     * @last modified by  : arcortazar@nts-solutions.com
     * @param customerId Identificador de la cuenta a la que pertenecen los Contact Request buscados.
     * @param name Nombre de la cuenta (Account) relacionada con las Contact Request
     * @return Lista de ContactRequest encontrados en el sistema.
     */
    public List<ContactRequest> findByCustomerId(String customerId, String name)
    {

        // Si el customerId que llega es nulo, buscamos un contacto con el mismo
        // nombre y nos quedamos con su ID para hacer las búsquedas
        if ( String.isBlank(customerId) )
        {
            List<Contact> contactos = [SELECT Id FROM Contact WHERE name = : name];
            if (contactos.size() > 0)
            {
                customerId = contactos.get(0).Id;
            }
        }

        // arcortazar - 24/01/2022
        // Comprobamos si en este punto el customerId es nulo. Si no lo es, buscamos los ContactRequest asociados
        // si no, devolvemos una lista vacía
        if ( !String.isBlank(customerId) )
        {
            // Se añaden las condiciones:
            // Status != Cancelled
            // WhoId = customerId
            // GenesysInteractionId__c != null
            Query.Condition condition = Query.doAnd(
                Query.conditionNotEq(ContactRequest.Status, STATUS_CANCELLED),
                Query.conditionEq(ContactRequest.WhoId, customerId),
                Query.conditionNotNull(ContactRequest.GenesysInteractionId__c)
                );

            // Se estructura la query.
            this.baseQuery.selectReadableFields()
            .addCondition(condition)
            .orderBy( ContactRequest.Preferred_Status__c.getDescribe().getName() )
            .orderBy( ContactRequest.PreferredContactDatetime__c.getDescribe().getName() );

            // Se ejecuta la Query.
            return (List<ContactRequest>) this.baseQuery.run();
        }
        else
        {
            return ( new List<ContactRequest>() );
        }
    }

    /**
     * Busca ContactRequest por Id de interacción de la plataforma Genesys Cloud y revuelve una colección con las coincidencias.
     *
     * @author pitt.olvera@seidor.com
     * @date 12/11/2024
     * @param interactionIds Conjunto de Ids de las interacciones de la plataforma Genesys Cloud a buscar.
     * @return Lista de ContactRequest encontrados en el sistema.
     */
    public List<ContactRequest> findByGenesysInteractionIds(Set<String> interactionIds)
    {
        List<ContactRequest> contactRequests = new List<ContactRequest>();
        List<String> relatedFields = new list<String> {
            'GenesysCloudQueueId__r.Name'
        };
        List<Schema.SObjectField> fields = new list<Schema.SObjectField> {
            ContactRequest.field.GenesysInteractionId__c
        };
        if ( interactionIds != null && !interactionIds.isEmpty() )
        {
            this.baseQuery.selectFields(relatedFields)
            .selectFields(fields)
            .addConditionIn(ContactRequest.GenesysInteractionId__c, interactionIds);

            contactRequests = (List<ContactRequest>) this.baseQuery.run();
        }
        return contactRequests;
    }
}