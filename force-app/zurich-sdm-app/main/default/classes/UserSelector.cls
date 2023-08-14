/**
 * Clase selector del objeto User
 *
 * Proyecto: SDM (Sales Digital Management)
 *
 * @author nts (dmunoz)
 * @date 23/02/2023
 */
public with sharing class UserSelector {
    public UserSelector() {

    }

    /**
     * Obtener los ids de los usuarios a partir de los emails
     * @param obj: objetivo a consultar
     * @author dmunoz
     * @date 23/02/2023
     */
    public List<User> getIdsValidUser(List<String> emailList) {
        List<User> result = new List<User>();

        if (emailList != null && !emailList.isEmpty()) {
            result = new List<User>([SELECT Id FROM User WHERE Email IN :emailList]);
        }

        return result;
    }

    /**
     * Obtener un id de usuario SDM_Director activo para ejecutar en los test que haya que generar planes de siniestralidad/retencion
     * @author dmunoz
     * @date 23/02/2023
     */
    public List<User> getSDMUserId() {

        List<User> result = new List<User>([SELECT Id FROM User WHERE UserRole.DeveloperName = 'SDM_DT' AND IsActive = TRUE LIMIT 1]);        

        return result;
    }

    /**
     * Obtiene la lista de usuarios DT SDM, RN SDM y el usuario que lanza la query, se usa en el componente Generar Plan Anual
     * @author dmunoz
     * @date 06/04/2023
     */
    public List<User> getSDMUsers() {

        List<User> result = new List<User>([SELECT Id, Name, UserRole.DeveloperName FROM user WHERE UserRole.DeveloperName IN ('SDM_DT', 'SDM_RN') OR Id = :UserInfo.getUserId() ORDER BY Name ASC]);

        return result;
    }

    public User getUserInfo(String userId) {
        User result;

        result = [SELECT Id, UserRole.DeveloperName, Profile.Name, Email FROM User WHERE Id =: userId];

        return result;
    }
}