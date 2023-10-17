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
        Map<Id, Profile> listaPerfiles = ProfilesSelector.getProfilesByName(new List<String> {'Agente Ventas'});
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
     * lanza el batch de cierre de oportunidades pasándole el valor requerido 
     * 
     * @author arcortazar
     * @date 13/10/2023
     */
    public static void executeBatchCloseOpps()
    {
        Map<Id, Profile> listaPerfiles = ProfilesSelector.getProfilesByName(new List<String> {'Agente Ventas'});
        if (listaPerfiles.keySet().contains(UserInfo.getProfileId()))
        {
            Database.executeBatch( new Batch_CloseOppsWithoutCampMemb('Agent removes from the campaign') );
        }
    }

    /**
     * Método que comprueba si el agente que está eliminando Miembros de Campaña es del tipo Agente Ventas, en cuyo caso
     * lanzará un error y no permitirá la transacción
     * 
     * @author arcortazar
     * @date 13/10/2023
     */
    public static void checkIntermediaryProfile(List<CampaignMember> listaMiembros)
    {
        Map<Id, Profile> listaPerfiles = ProfilesSelector.getProfilesByName(new List<String> {'Agente Ventas'});
        if (listaPerfiles.keySet().contains(UserInfo.getProfileId()))
        {
            for (CampaignMember c: listaMiembros)
            {
                c.addError(ERROR_PERMISOS);
            }
        }
    }

}