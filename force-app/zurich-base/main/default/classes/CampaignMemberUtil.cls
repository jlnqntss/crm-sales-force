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
}