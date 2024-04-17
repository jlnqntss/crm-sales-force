public with sharing class LeadMatch {

    private static final String SCOPE_OPPORTUNITY_MAP = 'ScopeMap';
    private static final String SCOPE_OPPORTUNITY_PRODUCT_BRANCH = 'ProductBranch';
    private static final String SCOPE_OPPORTUNITY_ACCOUNTID = 'AccountId';
    private static final String SCOPE_OPPORTUNITY_INTERMEDIARY = 'Intermediary';
    private static final String SCOPE_OPPORTUNITY_INTERMEDIARY_GROUP = 'IntermediaryGroup';

    //#region calculo de merge de oferta cliente

    /**
     * Método que devueve los registros a actualizar del match de ofertas de cliente
     * @author dmunoz
     * @date 09/04/2024
     */
    public Map<String, List<sObject>> calculateClientOpportunitiesWithMatch(List<Opportunity> scope) {

        Map<String, List<sObject>> result = new Map<String, List<sObject>>();

        // 1º obtener los datos del scope para los siguientes métodos
        Map<String, Object> opportunityDataMap = getDataFromOpportunities(scope);

        // 2º Obtener el mapa de match par las ofertas de scope
        Map<String, Opportunity> matchMap = getMatchOffersByParams(opportunityDataMap);

        // 3º match de ofertas        
        result = mergeOffers((Map<String, Opportunity>) opportunityDataMap.get(SCOPE_OPPORTUNITY_MAP), matchMap);

        return result;
    }

    //#region Obtener datos y matcheo
    
    
    /**
     * Método que devueve a partir de la lista de ofertas los campos necesarios para buscar las ofertas coincidentes
     * @author dmunoz
     * @date 09/04/2024
     */
    private Map<String, Object> getDataFromOpportunities(List<Opportunity> scope) {

        Map<String, Object> result = new Map<String, Object>();
        Set<String> productBranchSet = new Set<String>(); // guarda los api name de ramo
        Set<String> accountIdSet = new Set<String>(); // guarda el id del cliente de la oferta, si lo ves conveninente lo cambias a codigo afiliación 
        Set<String> intermediaryIdSet = new Set<String>(); // guarda los ids de los mediadores de las ofertas
        Set<String> intermediaryGroupIdSet = new Set<String>(); // guarda los ids de las agrupaciones de mediador de aquellos que tengan asociado una agrupación
        Map<Id, Opportunity> scopeMap = new Map<Id, Opportunity>(); // convierto la lista de ofertas en un mapa

        for (Opportunity offer: scope) {
            productBranchSet = addElementToSet(productBranchSet, offer.ProductBranch__c);
            accountIdSet = addElementToSet(accountIdSet, offer.AccountId);
            intermediaryIdSet = addElementToSet(intermediaryIdSet, offer.IntermediaryId__c);
            intermediaryGroupIdSet = addElementToSet(intermediaryGroupIdSet, offer.IntermediaryId__r.IntermediaryGroup__c);
            scopeMap.put(offer.Id, offer);            
        }

        result.put(SCOPE_OPPORTUNITY_PRODUCT_BRANCH, productBranchSet);
        result.put(SCOPE_OPPORTUNITY_ACCOUNTID, accountIdSet);
        result.put(SCOPE_OPPORTUNITY_INTERMEDIARY, intermediaryIdSet);
        result.put(SCOPE_OPPORTUNITY_INTERMEDIARY_GROUP, intermediaryGroupIdSet);
        result.put(SCOPE_OPPORTUNITY_MAP, scopeMap);

        return result;
    }


    /**
     * Método que devueve a partir de unos parámetros las ofertas que coincidan con los siguientes criterios:
     * - Mismo Ramo
     * - Estado "No Iniciado", "Pendiente INFO"
     * - Mismo Código de Filiación (id cliente)
     * - Mismo mediador
     * - Misma Agrupacion
     * - Código oferta en blanco
     * - Registros de los pasados 2 meses
     * 
     * AL recorrer las ofertas tenemos la siguiente lógica:
     * - Si para un mediador/agrupacion, cliente y ramo hay n ofertas nos quedamos con la que tenga informado el campo "CampaignId" (gana a todas), si no con la mas reciente. 
     * 
     * @return mapa con clave id oferta scope y oferta match
     * 
     * @author dmunoz
     * @date 09/04/2024
     */
    private Map<String, Opportunity> getMatchOffersByParams(Map<String, Object> opportunityDataMap) {

        Map<String, Opportunity> result = new Map<String, Opportunity>();

        // Obtengo los datos

        // recupero la informacion de las ofertas
        Set<String> productBranchSet = (Set<String>) opportunityDataMap.get(SCOPE_OPPORTUNITY_PRODUCT_BRANCH);
        Set<String> accountIdSet = (Set<String>) opportunityDataMap.get(SCOPE_OPPORTUNITY_ACCOUNTID);
        Set<String> intermediaryIdSet = (Set<String>) opportunityDataMap.get(SCOPE_OPPORTUNITY_INTERMEDIARY);
        Set<String> intermediaryGroupIdSet = (Set<String>) opportunityDataMap.get(SCOPE_OPPORTUNITY_INTERMEDIARY_GROUP);
        Map<String, Opportunity> scopeMap = (Map<String, Opportunity>) opportunityDataMap.get(SCOPE_OPPORTUNITY_MAP);

        // Ejecuto la consulta de ofertas match
        List<Opportunity> offersMatchQuery = (new OpportunitiesSelector()).findMatchOffers(productBranchSet, accountIdSet, intermediaryIdSet, intermediaryGroupIdSet);

        // Recorro los resultados para montar el mapa de resultado
        for (Opportunity scopeOffer: scopeMap.values()) {
            for (Opportunity queryOffer: offersMatchQuery) {
                if (matchConditions(scopeOffer, queryOffer) && checkMatchMap(result, scopeOffer, queryOffer)) {
                    result.put(scopeOffer.Id, queryOffer);
                }
            }
        }        

        return result;
    }


    /**
     * Método que compara dos ofertas usando los criterios
     * - Mismo Ramo
     * - Mismo Código de Filiación (id cliente)
     * - Mismo mediador
     * - El resto de condiciones del match ya se hace en la query findMatchOffers por lo que solo tenemos que comparar estos datos
     * 
     * AL recorrer las ofertas tenemos la siguiente lógica:
     * - Si para un mediador/agrupacion, cliente y ramo hay n ofertas nos quedamos con la que tenga informado el campo "CampaignId" (gana a todas), si no con la mas reciente. 
     * 
     * @return boolean
     * 
     * @author dmunoz
     * @date 09/04/2024
     */
    private Boolean matchConditions(Opportunity scopeOpportunity, Opportunity queryOpportunity) {
        Boolean result = false;

        if (scopeOpportunity.ProductBranch__c != null && scopeOpportunity.ProductBranch__c.equals(queryOpportunity.ProductBranch__c) && 
            scopeOpportunity.AccountId != null && scopeOpportunity.AccountId.equals(queryOpportunity.AccountId) && 
            checkIntermediaryEquals(scopeOpportunity, queryOpportunity)) 
        {
            result = true;
        }

        return result;

    }

    /**
     * Método que compara los mediadores de dos ofertas. Tenemos dos escenarios:
     * Los mediadores coinciden -> result true
     * Los mediadores no coinciden -> comprobar si esos mediadores tienen agrupacion y si es la misma -> result = true
     * 
     * 
     * @return boolean
     * 
     * @author dmunoz
     * @date 09/04/2024
     */
    private Boolean checkIntermediaryEquals(Opportunity scopeOpportunity, Opportunity queryOpportunity) {
        Boolean result = false;

        if (scopeOpportunity.IntermediaryId__c != null && scopeOpportunity.IntermediaryId__c.equals(queryOpportunity.IntermediaryId__c)) {
            result = true;

        } else if (scopeOpportunity.IntermediaryId__r.IntermediaryGroup__c != null && scopeOpportunity.IntermediaryId__r.IntermediaryGroup__c.equals(queryOpportunity.IntermediaryId__r.IntermediaryGroup__c)) {
            result = true;
        }

        return result;
    }


    /**
     * Método que una vez se ha comprobado que la oportunidad de la query es un match, si se añade al mapa de resultado. Para ello tenemos 3 condiciones:
     * . Si el mapa para la oferta del scope no tiene ningun match se añade la primera que haya pasado el filtro
     * - Si la oferta tiene id de campaña informado, gana a todas.
     * - Si el mapa resultado para la oferta scope no tiene ya una oferta con campaña informado nos quedamos con la más reciente
     * 
     * 
     * @return boolean
     * 
     * @author dmunoz
     * @date 09/04/2024
     */
    private Boolean checkMatchMap(Map<String, Opportunity> matchMap, Opportunity scopeOffer, Opportunity queryOffer) {

        Boolean result = false;

        if (!matchMap.containsKey(scopeOffer.Id)) {
            result = true;
        } else if (queryOffer.CampaignId != null && String.isNotEmpty(queryOffer.CampaignId)) {
            result = true;
        } else if (matchMap.containsKey(scopeOffer.Id) && String.isEmpty(matchMap.get(scopeOffer.Id).CampaignId) && queryOffer.CreatedDate < matchMap.get(scopeOffer.Id).createdDate) {
            result = true;
        }

        return result;
    }

    //#region Calculo de Match

    private Map<String, List<sObject>> mergeOffers(Map<String, Opportunity> scopeMap, Map<String, Opportunity> matchOppByScopeId) {

        Map<String, List<sObject>> result = new  Map<String, List<sObject>>();

        List<Opportunity> updatedOffer = new List<Opportunity>(); // devolvemos la lista de ofertas de scope modificadas, las que tengan match se modican todos los campos y las que no solo se blanquea el potencial match
        List<Task> movedTasks = new List<Task>();
        List<Event> movedEvents = new List<Event>();

        //Mapa que enlaza la oferta scope con la oferta que hace match
        Map<String, String> matchIdByScopeId = new Map<String, String>();

        Opportunity matchOffer;
        // recorrer el scope y ver si en el mapa existe algun resultado
        for (Opportunity scopeOffer: scopeMap.values()) {

            if(matchOppByScopeId.containsKey(scopeOffer.Id)) {
                matchOffer = matchOppByScopeId.get(scopeOffer.Id);
                // 1º Mergeamos la oferta del match en la oferta del scope (ER) NOS QUEDAMOS CON LA OFERTA DE ER.
                scopeOffer = mergeOffer(scopeOffer, matchOffer);

                // 2º Identificar esa oferta para mover sus tareas y eventos
                matchIdByScopeId.put(scopeOffer.Id, matchOffer.Id);
            }

            scopeOffer.PotentialMatch__c = false; //Desmarcamos para que no vuelva a pasar por el flujo
            updatedOffer.add(scopeOffer);  //Añadimos la oferta modificada tenga match o no.
                
        }

        // Mover tareas y eventos de aquellas ofertas que si tienen un match
        movedTasks = moveTasksToScopeOffers(matchIdByScopeId);
        movedEvents = moveEventsToScopeOffers(matchIdByScopeId);

        result.put('updatedOffer', updatedOffer);
        result.put('movedTasks', movedTasks);
        result.put('movedEvents', movedEvents);

        return result;
    }

    /**
     * Método que sobrescribe los campos "Description" y "CampaignId" de una oportunidad a otra y pasa a la etapa "Oferta Realizada"
     * @author igarcia
     * @param scopeOffer - La oferta donde se sobrescribira los campos
     * @param offerMatch - Oferta de donde se recogerá los campos
     * 
     * @return scopeOffer - Se devuelve el scoppeOffer que pasa como parámetro pero con los campos modificados
     * @date 15/04/2024
     */
    public Opportunity mergeOffer(Opportunity scopeOffer, Opportunity offerMatch) {
        if(String.isNotBlank(offerMatch.Description)) {
            scopeOffer.Description = offerMatch.Description;
        }

        if(String.isNotBlank(offerMatch.CampaignId)) {
            scopeOffer.CampaignId = offerMatch.CampaignId;
        }

        scopeOffer.StageName = 'Quoted'; // TODO: CREO QUE NO HACE FALTA PERO PROBAR POR SI ACASO

        return scopeOffer;
    }

    /**
     * Método que modifica el WhatId de las tareas relacionadas en las ofertas match(value) por la oferta scope(key)
     * @author igarcia
     * @date 15/04/2024
     */
    public List<Task> moveTasksToScopeOffers(Map<String, String> matchIdByScopeId)
    {
        Map<String, List<Task>> tasksByOppMatchId = getTaskByOppMatchId(matchIdByScopeId.values());
        List<Task> movedTasks = new List<Task>();
        String matchId; 
        for(String scopeId : matchIdByScopeId.keySet())
        {   
            matchId = matchIdByScopeId.get(scopeId);

            if(tasksByOppMatchId.containsKey(matchId))
            {
                for(Task tarea : tasksByOppMatchId.get(matchId))
                {
                    tarea.WhatId = scopeId;
                    movedTasks.add(tarea);
                }
            }
        }

        return movedTasks;
    }

    
    /**
     * Método que modifica el WhatId de los eventos relacionados en las ofertas match(value) por la oferta scope(key)
     * @author igarcia
     * @date 15/04/2024
     */
    public List<Event> moveEventsToScopeOffers(Map<String, String> matchIdByScopeId)
    {
        Map<String, List<Event>> eventsByOppMatchId = getEventsByOppMatchId(matchIdByScopeId.values());
        List<Event> movedEvents = new List<Event>();
        String matchId; 

        for(String scopeId : matchIdByScopeId.keySet())
        { 
            if(eventsByOppMatchId.containsKey(matchId))
            {
                for(Event evento : eventsByOppMatchId.get(matchId))
                {
                    evento.WhatId = scopeId;
                    movedEvents.add(evento);
                }
            }
        }

        return movedEvents;

    }

    /**
     * Método que obtiene las tareas relacionadas a los ids pasados como parámetro.
     * Devuelve un mapa cuya "key" es el id de la oferta y "value" la lista de tareas relacionadas a esta
     * @author igarcia
     * @date 15/04/2024
     */
    public Map<String, List<Task>> getTaskByOppMatchId(List<String> matchIds)
    {
        List<Task> relatedTasks;// = new TaskSelector().getTaskRelatedWithOffers(matchIds);
        return fillMapList(relatedTasks, 'WhatId');

    }

    /**
     * Método que obtiene los eventos relacionadas a los ids pasados como parámetro.
     * Devuelve un mapa cuya "key" es el id de la oferta y "value" la lista de eventos relacionados a esta
     * @author igarcia
     * @date 15/04/2024
     */
    public Map<String, List<Event>> getEventsByOppMatchId(List<String> matchIds)
    {
        List<Event> relatedEvents;// = EventSelector.getRelatedEventsFromRecord(matchIds);
        return fillMapList(relatedEvents, 'WhatId');
    }



    /**
    * Método que transforma una lista introducida como parámetro en un mapa cuya "Key" sea el campo especificado
    * @date: 19/08/2020 
    * @author  igarcia
    */ 
    public static Map<String, List<Sobject>> fillMapList(List<Sobject> valuesSet, String key)
    {
        
        Map<String, List<Sobject>> mapList = new Map<String, List<Sobject>>();

        if(valuesSet == null || valuesSet.isEmpty()){
            return mapList; 
        }
        
        String mapkey;
        
        for(Sobject o : valuesSet){
            mapkey = (String)o.get(key);
            
            if(!mapList.containsKey(mapkey)){
                
                mapList.put(mapkey, new List<Sobject>());
                
            }
            
            mapList.get(mapkey).add(o);
            
        }
        
        return mapList;
    }

    //#region Metodos Auxiliares


    /**
     * Método que inserta en un conjunto si el valor seleccionado no es vacío o nulo
     * @author dmunoz
     * @date 09/04/2024
     */
    private Set<String> addElementToSet(Set<String> result, String value) {
        if (value != null && String.isNotEmpty(value)) {
            result.add(value);
        }
        return result;
    }
}