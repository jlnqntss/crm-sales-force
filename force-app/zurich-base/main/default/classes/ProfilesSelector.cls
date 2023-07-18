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


    /**
     * Método que devuelve el perfil del usuario
     * 
     * @author dmunoz - nts
     * @created date 17/07/2023
     */
    public static String getLoggedUserProfile() {
        String result = '';

        List<Profile> profilesQuery = new List<Profile>([SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()]);

        if (profilesQuery != null && !profilesQuery.isEmpty()) {
            result = profilesQuery.get(0).Name;
        }

        return result;
    }
}
