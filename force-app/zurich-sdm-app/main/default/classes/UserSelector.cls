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
}