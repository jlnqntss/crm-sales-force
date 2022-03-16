public with sharing class ProfilesSelector {

    /**
     * Método que devuelve un mapa con los perfiles autorizados
     * 
     * @author arcortazar - nts
     * @created date 14/03/2022
     */
    public static Map<Id, Profile> getProfilesByName(List<String> nombresPerfiles)
    {
        Map<Id, Profile> mapaAuth = new Map<Id, Profile>([SELECT Id FROM Profile WHERE Name IN :nombresPerfiles]);
        if (mapaAuth == null)
        {
            return (new Map<Id, Profile>());
        }
        else 
        {
            return mapaAuth;
        }
        
    }
}
