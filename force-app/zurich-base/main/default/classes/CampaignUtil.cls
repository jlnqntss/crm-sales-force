/**
 * Clase de utilidad para la entidad Campaign
 * @author arcortazar
 * @date 13/10/2023
 */
public with sharing class CampaignUtil {
    public static String ERROR_PERMISOS = 'No tiene permisos para realizar esta acción';

    /**
     * Método que comprueba si el agente que está eliminando Miembros de Campaña es del tipo Agente Ventas, en cuyo caso
     * lanzará un error y no permitirá la transacción
     * 
     * @author arcortazar
     * @date 13/10/2023
     */
    public static void checkIntermediaryProfile(List<Campaign> listaCampanyas)
    {
        Map<Id, Profile> listaPerfiles = ProfilesSelector.getProfilesByName(new List<String> {ProfilesSelector.PROFILE_AGENTE_VENTAS});
        if (listaPerfiles.keySet().contains(UserInfo.getProfileId()))
        {
            for (Campaign c: listaCampanyas)
            {
                c.addError(ERROR_PERMISOS);
            }
        }
    }
}