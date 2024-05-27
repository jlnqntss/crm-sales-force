/**
 * Clase de utilidad para la entidad CampaignMember
 * @author rlopez
 * @date 21/12/2020
 */
public with sharing class CampaignMemberUtil
{

    public static String ERROR_CAMPAIGN_MEMBER = 'Campaña en curso, finalizada o no válida';
    public static String ERROR_PERMISOS = 'No tiene permisos para realizar esta acción';

    
    /**
     * Método que recupera y elimina los miembros de campaña marcados con Status = "Delete"
     *
     * Se llama desde: DeletedCampaignMemberSchedulableJob
     *
     * @author rlopez
     * @date 21/12/2020
     */
    public static void deleteMembers()
    {
        try
        {
            List<CampaignMember> deletedMembers = new CampaignMembersSelector().selectByStatus('Delete');
            if( !deletedMembers.isEmpty() )
            {
                delete deletedMembers;
            }
        }
        catch (Exception ex)
        {
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_CRITICAL, ex.getMessage(), 'CampaignMemberUtil');
        }
    }

    /**
     * Método que comprueba las características de la campaña asociada a los miembros de campaña eliminados 
     * de manera que lance un error si no tiene las características adecuadas
     *
     * @author arcortazar
     * @date 11/10/2023
     */
    public static void validateCampaign(Map<Id, CampaignMember> mapCampaignMembers)
    {
        boolean agenteVentas = false;
        Map<Id, Profile> listaPerfiles = ProfilesSelector.getProfilesByName(new List<String> {ProfilesSelector.PROFILE_AGENTE_VENTAS});
        if (listaPerfiles.keySet().contains(UserInfo.getProfileId()))
        {
            agenteVentas = true;
        }

        List<String> idCampaigns = new List<String>();
        Map<String, List<CampaignMember>> mapCampainWithCampMember = new Map<String, List<CampaignMember>>();
        for (CampaignMember miembro : mapCampaignMembers.values())
        {
            if(!mapCampainWithCampMember.keyset().contains(miembro.CampaignId))
            {
                mapCampainWithCampMember.put(miembro.CampaignId, new List<CampaignMember>());
            }
            mapCampainWithCampMember.get(miembro.CampaignId).add(miembro);

            if(!idCampaigns.contains(miembro.CampaignId))
            {
                idCampaigns.add(miembro.CampaignId);
            }
        }

        if(!idCampaigns.isEmpty())
        {
            List<Campaign> listaCampanyas = new CampaignsSelector().findZRMInitiatedCrossSellingCampaings(idCampaigns);
            if(!listaCampanyas.isEmpty() && agenteVentas)
            {
                for(Campaign c : listaCampanyas)
                {
                    List<CampaignMember> miembrosError = mapCampainWithCampMember.get(c.Id);
                    miembrosError.get(0).addError(ERROR_CAMPAIGN_MEMBER);
                }
                
            }
        }
    }

    /**
     * Método que comprueba si el agente que está eliminando Miembros de Campaña es del tipo Agente Ventas, en cuyo caso
     * cierra las ofertas relacionadas al Miembro eliminado
     * 
     * @author arcortazar
     * @date 13/11/2023
     */
    public static void closeRelatedOffer(Map<Id, CampaignMember> miembros)
    {
        Map<Id, Profile> listaPerfiles = ProfilesSelector.getProfilesByName(new List<String> {ProfilesSelector.PROFILE_AGENTE_VENTAS, ProfilesSelector.PROFILE_AGENTE_VENTAS_AGR});
        if (listaPerfiles.keySet().contains(UserInfo.getProfileId()) || Test.isRunningTest())
        {
            // Aqui buscamos la oferta relacionada y la cerramos
            // Tiene que tener el 'Agent removes from the campaign'
            Set<String> idCampaigns = new Set<String>();
            Set<String> idContactos = new Set<String>();
            Set<String> idAccounts = new Set<String>();
            for(CampaignMember cm : miembros.values())
            {
                idCampaigns.add(cm.CampaignId);
                idContactos.add(cm.ContactId);
            }

            List<Contact> lstContactos = (new ContactsSelector()).findById(idContactos);
            for(Contact c : lstContactos)
            {
                idAccounts.add(c.AccountId);
            }

            // Llamamos al selector de ofertas (en base a la/s campaña/s y los miembros)
            OpportunitiesSelector selector = new OpportunitiesSelector();
            List<Opportunity> offersToClose = selector.findByCampaignAndCampaignMember(idCampaigns, idAccounts);

            // Cambiamos el estado de las ofertas
            for(Opportunity o : offersToClose)
            {
                if (o.Campaign.Type == 'Cross Selling')
                {
                    o.StageName = 'Closed Lost';
                    if(o.SalesProcess__c == 'VC')
                    {
                        o.Sales_Loss_Reason__c = 'Agent removes from the campaign';
                    }
                }
            }
            update offersToClose;
        }
    }

    /**
     * Método que desconecta los callbacks futuros en Genesys para un miembro de campaña, la llamada al WS que los cierra se realiza en
     * el método disconnectGenesysCallbacks_future
     * 
     * @author fpalomo
     * @date 23/05/2024
     */
    public static void disconnectGenesysCallbacks(Map<Id, CampaignMember> oldMap)
    {
        Set<String> campaignMemberAccountIdSet = new Set<String>();
        for (CampaignMember campaignMember : oldMap.values())
        {
            campaignMemberAccountIdSet.add(campaignMember.ContactId);
        }

        // Recuperamos las tareas de callbacks a futuro asociadas al cliente, actualizamos la descripción con el contenido de la label
        // Label.Cliente_eliminado_de_campa_a (Miembro de campaña eliminado) y las cerramos
        List<Task> callbackTaskList = (new TaskSelector()).getCallbackTasksByWhoIdSet(campaignMemberAccountIdSet);
        Set<String> conversationIdSet = new Set<String>();
        for (Task callbackTask : callbackTaskList)
        {
            conversationIdSet.add(callbackTask.CallObject);
            
            callbackTask.Status = 'Cerrada';
            callbackTask.Description = Label.Cliente_eliminado_de_campa_a;
        }

        // Si no se han recuperado tareas no es necesario hacer nada mas
        if (callbackTaskList.isEmpty())
        {
            return;
        }

        update callbackTaskList;


        // Enviamos los datos al metodo futuro para que realice la llamada al WS
        disconnectGenesysCallbacks_future(conversationIdSet);
    }

    /**
     * Método futuro encargado de hacer la llamada al WS de genesys para cerrar los callbacks
     * 
     * @author fpalomo
     * @date 23/05/2024
     */
    @future (callout = true)
    public static void disconnectGenesysCallbacks_future(Set<String> conversationIdSet)
    {
        // Lanzamos una petición a Genesys para recuperar los detalles de todas las conversaciones que tenemos en conversationIdSet
        GenesysCloud.AnalyticsResponseWrapper analyticsResponse = GenesysCloud.AnalyticsService.getConversationDetails(conversationIdSet);
        
        // Para evitar impactar todos los test en los que se eliminan miembros de campaña, se ha hecho que el webservice devuelva nulo
        // si se está ejecutando en contexto de test y no se ha implementado un mock. Si se da el caso que nos llegue un nulo evitamos
        // ejecutar el resto del proceso.
        if (analyticsResponse == null)
        {
            return;
        }

        // Procesamos la respuesta de Genesys y mapeamos cada conversationId con sus callbacks
        Map<String, Set<String>> conversationToCallbacksMap = new Map<String, Set<String>>();
        for (GenesysCloud.AnalyticsConversationWithoutAttributes analyticsConversation : analyticsResponse.conversations)
        {
            conversationToCallbacksMap.put(analyticsConversation.conversationId, new Set<String>());

            for (GenesysCloud.AnalyticsParticipantWithoutAttributes analyticsParticipant : analyticsConversation.participants)
            {
                Set<String> callbackIdSet = getCallbackIdListFromSessions(analyticsParticipant.sessions);
                conversationToCallbacksMap.get(analyticsConversation.conversationId).addAll(callbackIdSet);
            }
        }

        // Generamos un nuevo objeto BulkCallbackDisconnectRequest con los datos de las conversaciones y los callbacks
        GenesysCloud.BulkCallbackDisconnectRequest bulkCallbackDisconnectRequest = generateCallbackDisconnectRequest(conversationToCallbacksMap);

        // El test del metodo del webservice se realiza con un mock en la clase GenesysCloudTest
        if (!Test.isRunningTest())
        {
            GenesysCloud.CallbacksService.disconnectBulk(bulkCallbackDisconnectRequest);
        }
    }

    /**
     * Obtiene una lista de ID de callbacks a partir de una lista del objeto GenesysCloud.AnalyticsSession (respuesta del servicio de anaíticas de Genesys)
     * 
     * @author fpalomo
     * @date 23/05/2024
     */
    public static Set<String> getCallbackIdListFromSessions(List<GenesysCloud.AnalyticsSession> analyticsSessionList)
    {
        Set<String> callbackIdList = new Set<String>();
        for (GenesysCloud.AnalyticsSession analyticsSession : analyticsSessionList)
        {
            if(analyticsSession.mediaType == 'callback')
            {
                callbackIdList.add(analyticsSession.sessionId);
            }
        }
        return callbackIdList;
    }

    /**
     * Genera un objeto GenesysCloud.BulkCallbackDisconnectRequest para los callbacks que recibe en el parámetro conversationToCallbacksMap,
     * el cual es un mapa de <IdConversacion, Lista<CallbackId>>
     * 
     * @author fpalomo
     * @date 23/05/2024
     */
    public static GenesysCloud.BulkCallbackDisconnectRequest generateCallbackDisconnectRequest(Map<String, Set<String>> conversationToCallbacksMap)
    {
        GenesysCloud.BulkCallbackDisconnectRequest bulkCallbackDisconnectRequest = new GenesysCloud.BulkCallbackDisconnectRequest();
        bulkCallbackDisconnectRequest.callbackDisconnectIdentifiers = new List<GenesysCloud.CallbackDisconnectIdentifier>();

        for (String conversationId : conversationToCallbacksMap.keySet())
        {
            for (String callbackId : conversationToCallbacksMap.get(conversationId))
            {
                GenesysCloud.CallbackDisconnectIdentifier callbackDisconnectIdentifier = new GenesysCloud.CallbackDisconnectIdentifier();
                callbackDisconnectIdentifier.callbackId = callbackId;
                callbackDisconnectIdentifier.conversationId = conversationId;
    
                bulkCallbackDisconnectRequest.callbackDisconnectIdentifiers.add(callbackDisconnectIdentifier);
            }
        }

        return bulkCallbackDisconnectRequest;
    }
}