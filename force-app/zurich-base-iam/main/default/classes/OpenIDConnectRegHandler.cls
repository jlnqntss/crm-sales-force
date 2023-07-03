/**
 * @description Gestiona las diversas funcionalidades al realizar un login en la plataforma por medio de un tercero.
 *              Para este caso de uso, el IAM a tratar es OpenID Connect, el cual proporcionará una respuesta con la confirmación del
 *              login de cada usuario a Salesforce que posteriormente ejecutará lo métodos de esta clase.
 * @date 03/06/2020
 * @author rpolvera@nts-solutions.com
 *  * Ver   Date         Author                Modification
 *   2.0    07/06/2023   nts (dmunoz)          Se mueve la lógica a clases utilidad y esta será una clase que invoque el login para licencias sf y licencias partner

 * @See ./authprovider/
 */
global class OpenIDConnectRegHandler implements Auth.RegistrationHandler {

    @testvisible
    private List<AuthMapping__mdt> testListAuthMappings;

    @testvisible
    private static final string AUTH_DATA_MAP_NAME = 'roles';    

    private static final string CLASS_NAME = 'OpenIDConnectRegHandler';


    // mensajes de error a devolver
    private static final string ERROR_PARSE_ROLES = 'Error al parsear el usuario. Para más ayuda, póngase en contacto con su administrador.';
    
    /**
     * @Description Método ejecutado cuando el id de federación del usuario que intenta conectar no se corresponde con el de Salesforce.
     * @date 03/06/2020
     * @author rpolvera
     * @param {Id} portalId - Id de federación de usuario.
     * @param {Auth.UserData} data - Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl, attributeMap)
     * @return {User} Objeto de Salesforce que se corresponde con el usuario.
     */
    global User createUser(Id portalId, Auth.UserData data) {
        System.debug('Entro en Create User ' + data.attributeMap);
        User u;
        
        // obtener rol recibido de IAM
        List<String> iamRoleReceived = getExternalRoleNames(data); // devuelve una lista pero solo nos llegará uno
        // consulta de metadata
        Boolean isCommunity = isCommnunityLogin(iamRoleReceived);

        if (isCommunity) {
            if (Test.isRunningTest()) {
                u = createMockUserTest('CommunityUser');
            } else {
                OpenIDConnectSalesforceCommunity salesforceCommunityHandler = new OpenIDConnectSalesforceCommunity();
                u = salesforceCommunityHandler.createUser(portalId, data, iamRoleReceived);
            }
        } else if (Test.isRunningTest() && !isCommunity){
            u = createMockUserTest('SFUser');

        } else {
            OpenIDConnectSalesforceLicense salesforceLicenseHandler = new OpenIDConnectSalesforceLicense();
            u = salesforceLicenseHandler.createUser(portalId, data);            

        }

        return u;

        
    }
    /**
     * @Description Método ejecutado cuando el id de federación del usuario que intenta conectar ya existe en Salesforce.
     * @date 03/06/2020
     * @author rpolvera
     * @param {Id} userId - Id de usuario de Salesforce.
     * @param {Id} portalId - Id de federación de usuario.
     * @param {Auth.UserData} data - Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl, attributeMap)
     */
    global void updateUser(Id userId, Id portalId, Auth.UserData data) {
        
        System.debug('Entro en Update User ' + data.attributeMap);
        // obtener rol recibido de IAM
        List<String> iamRoleReceived = getExternalRoleNames(data); // devuelve una lista pero solo nos llegará uno
        // consulta de metadata
        Boolean isCommunity = isCommnunityLogin(iamRoleReceived);        
        
        if (isCommunity) {
            if (Test.isRunningTest()) {
                createMockUserTest('CommunityUserUpdated');
            } else {
                OpenIDConnectSalesforceCommunity salesforceCommunityHandler = new OpenIDConnectSalesforceCommunity();
                salesforceCommunityHandler.updateUser(userId, portalId, data, iamRoleReceived);
            }
        } else if (Test.isRunningTest() && !isCommunity){
            createMockUserTest('SFUserUpdated');

        } else {
            OpenIDConnectSalesforceLicense salesforceLicenseHandler = new OpenIDConnectSalesforceLicense();
            salesforceLicenseHandler.updateUser(userId, portalId, data);            

        }
    }


    ///////////////////////////////////////////// Métodos Auxiliares////////////////////////////////////////////////
    /**
     * @Description Recupera la lista de roles externos para esta sesión.
     * @date 01/10/2020
     * @author eetxaniz
     * @param {Auth.UserData} data - Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl,
     *                               attributeMap)
     * @return {List<String>} Nombre de los roles recuperados
     */
    private List<String> getExternalRoleNames(Auth.UserData data) {
        try {
            // Recuperación de los roles del usuario recibidos desde el IAM            
            //'{crm=[rol_name1, rol_name2, rol_name3]}'
            return data.attributeMap.get(AUTH_DATA_MAP_NAME).remove('{')
                   .remove('}')
                   .remove('[')
                   .remove(']')
                   .split('=')[1]
                   .remove(' ')
                   .split(',');

        } catch (Exception e) {
            throw new RegHandlerException(ERROR_PARSE_ROLES);
        }
    }

    /**
     * @Description busca en la metadata si nos encontramos ante un login de comunidad o no.
     * @date 09/06/2023
     * @author dmunoz
     * @param iamRoleReceived rol de IAM recibido
     * @return Boolean indica si tiene el check de 
     */
    private Boolean isCommnunityLogin(List<String> iamRoleReceived) {
        Boolean result = false;

        List<AuthMapping__mdt> roleMetadata = new List<AuthMapping__mdt>([SELECT Id FROM AuthMapping__mdt 
                                WHERE Role_Name__c IN :iamRoleReceived AND IsCommunity__c = TRUE]);

                                // if is a test, mock the result
        if (Test.isRunningTest() && testListAuthMappings != null) {
            for (AuthMapping__mdt mdt: testListAuthMappings) {
                if (mdt.IsCommunity__c) {
                    result = true;
                    break;
                }
            }
        }

        if (roleMetadata != null && !roleMetadata.isEmpty()) {
            result = true;
        }

        return result;
    }

    /**
     * @Description Excepción personalizada para oncluir el mensaje de error en la pantalla de lógin.
     * @date 03/06/2020
     * @author rpolvera
     */
    private User createMockUserTest(String userLastName) {
        User u = new User();
        u.LastName = userLastName;
        return u;

    }
    
    /**
     * @Description Excepción personalizada para oncluir el mensaje de error en la pantalla de lógin.
     * @date 03/06/2020
     * @author rpolvera
     */
    @testvisible
    class RegHandlerException extends Exception {}    
}