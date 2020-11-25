/**
 * @description Gestiona las diversas funcionalidades al realizar un login en la plataforma por medio de un tercero.
 *              Para este caso de uso, el IAM a tratar es OpenID Connect, el cual proporcionará una respuesta con la confirmación del
 *              login de cada usuario a Salesforce que posteriormente ejecutará lo métodos de esta clase.
 * @date 03/06/2020
 * @author rpolvera@nts-solutions.com
 * @See ./authprovider/
 */
global class OpenIDConnectRegHandler implements Auth.RegistrationHandler
{
    /**
     * @Description Método ejecutado cuando el id de federación del usuario que intenta conectar no se corresponde con el de Salesforce.
     * @date 03/06/2020
     * @author rpolvera
     * @param {Id} portalId - Id de federación de usuario.
     * @param {Auth.UserData} data - Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl, attributeMap)
     * @return {User} Objeto de Salesforce que se corresponde con el usuario.
     */
    global User createUser(Id portalId, Auth.UserData data)
    {

        System.debug('**** CREATE USER');
        System.debug('**** CREATE USER, PORTAL ID: ' + portalId);
        System.debug('**** CREATE USER, data: ' + data);


        User u                        = checkUser(data);
        // Si un usuario con el mismo correo ya existe en el sistema, se actualiza y se retorna.
        if (u != null)
        {
            updateUser(u.Id, portalId, data);
            return u;
        }
        // De lo contrario se instancia un nuevo usuario
        // @OLD List<String> externalProfile  = getExternalProfileName(data);
        List<String> roleNameList     = getExternalRoleNames(data);
        Id profileId                  = getProfileBasedOnRoles(roleNameList);
        u                             = new User();
        u.firstName                   = data.firstName;
        u.lastName                    = data.lastName;
        u.email                       = data.email;
        u.username                    = data.username + '@zurich-es.com';
        u.profileId                   = profileId;
        u.alias                       = data.username.left(8);
        u.CommunityNickname           = data.username;
        u.languagelocalekey           = UserInfo.getLanguage();
        u.localesidkey                = UserInfo.getLocale();
        u.emailEncodingKey            = 'UTF-8';
        u.timeZoneSidKey              = 'Europe/Paris';

        insert u;

        // Obtener los ids de los grupos públicos en salesforce
        List<String> publicGroupIdList = getPublicGroups(roleNameList);
        List<GroupMember> groupMemberList = assignPublicGroups(u.Id, publicGroupIdList);

        // Actualizar asignación a grupos

        futureGroupMemberUpdate(JSON.serialize(groupMemberList));

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
    global void updateUser(Id userId, Id portalId, Auth.UserData data)
    {
        System.debug('**** UPDATE USER');
        System.debug('**** UPDATE USER, PORTAL ID: ' + portalId);
        System.debug('**** UPDATE USER, data: ' + data);
        System.debug('**** UPDATE USER ID: ' + userId);

        Boolean modified                = false;
        // @OLD List<String> externalProfile    = getExternalProfileName(data);

        // Obtener los roles del json
        List<String> roleNameList    = getExternalRoleNames(data);

        // @OLD Id profileId                    = getProfileId(externalProfile);
        
        // Obtener id de los perfiles según roles.
        Id profileId = getProfileBasedOnRoles(roleNameList); 
        
        // Obtener los ids de los grupos públicos en salesforce
        List<String> publicGroupIdList = getPublicGroups(roleNameList);

        User u = [SELECT Id, firstName, lastName, email, userName, profileId, alias, CommunityNickname FROM User WHERE Id =: userId LIMIT 1];

        // Se comprueban los valores, se determina si ha habido cambios
        if      (u.firstName    != data.firstName)                      modified = true;
        else if (u.lastName     != data.lastName)                       modified = true;
        else if (u.email        != data.email)                          modified = true;
        else if (u.userName     != data.username + '@zurich-es.com')   modified = true;
        else if (u.profileId    != profileId)                           modified = true;
        else if (u.alias        != data.username.left(8))               modified = true;

        if (modified)
        {
            u.firstName         = data.firstName;
            u.lastName          = data.lastName;
            if (u.email        != data.email) u.email = data.email;
            if (u.userName     != data.username + '@zurich-es.com') u.userName = data.username + '@zurich-es.com';
            u.profileId         = profileId;
            u.alias             = data.username.left(8);
            u.CommunityNickname = data.username;
            update(u);
        }

        List<GroupMember> groupMemberList = assignPublicGroups(userId, publicGroupIdList);

        futureGroupMemberUpdate(JSON.serialize(groupMemberList));
    }

    /**
     * @Description Comprueba si el usuario introducido existe, es posible que al usar dos o mas proveedores de identidad, el mismo
     *              Ususario pueda acceder desde varios sitios. El método comprueba por email la existencia del usuario y lo devuelve.
     * @date 06/06/2020
     * @author rpolvera
     * @param {Auth.UserData} data - Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl,
     *                               attributeMap)
     * @return {User} si existe usuario lo devuelve.
     */
    global User checkUser(Auth.UserData data)
    {
        User result;
        System.debug('**** CHECK USER , USER EMAIL: ' + data.email);
        try
        {
            result = [SELECT Id, firstName, lastName, email, userName, profileId, alias, CommunityNickname FROM User WHERE email =: data.email LIMIT 1];
        }
        catch (Exception e)
        {
            result = null;
        }
        return result;
    }

    /**
     * @Description Recupera el nombre del perfil externo para esta sesión.
     * @date 06/06/2020
     * @author rpolvera
     * @param {Auth.UserData} data - Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl,
     *                               attributeMap)
     * @return {String} Nombre del perfil recuperado.
     */
    global List<String> getExternalProfileName(Auth.UserData data)
    {
        try
        {
            // Recuperación del perfil de usuario de los datos recibidos por desde el IAM
            return data.attributeMap.get('roles').remove('{')
                                                 .remove('}')
                                                 .remove('[')
                                                 .remove(']')
                                                 .split('=')[1]
                                                 .split(',');
        }
        catch (Exception e)
        {
            throw new RegHandlerException('External Cambiado: Su perfil de usuario no es válido. Para más ayuda, póngase en contacto con su administrador.');
        }
    }

     /**
     * @Description Recupera la lista de roles externos para esta sesión.
     * @date 01/10/2020
     * @author eetxaniz
     * @param {Auth.UserData} data - Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl,
     *                               attributeMap)
     * @return {List<String>} Nombre de los roles recuperados
     */
    global List<String> getExternalRoleNames(Auth.UserData data)
    {
        try
        {
            System.debug('**** GET EXTERNAL ROLE NAMES, DATA: ' + data);
            // Recuperación de los roles del usuario recibidos desde el IAM

            
            System.debug('**** GET EXTERNAL ROLE NAMES, ROLES: ' + data.attributeMap.get('roles').remove('{')
            .remove('}')
            .remove('[')
            .remove(']')
            .split('=')[1]
            .split(','));


            return data.attributeMap.get('roles').remove('{')
                                                .remove('}')
                                                .remove('[')
                                                .remove(']')
                                                .split('=')[1]
                                                .remove(' ')
                                                .split(',');
                                      
        }
        catch (Exception e)
        {
            throw new RegHandlerException('Error al parsear el usuario. Para más ayuda, póngase en contacto con su administrador.');
        }
    }

    /**
     * @Description Recupera el id del perfil asignado al valor recibido en la llamada, utiliza el metadato: Profile_mapping__mdt
     * @See Profile_mapping__mdt - Metadata Type
     * @date 03/06/2020
     * @author rpolvera
     * @param {List<String>} profileName - Nombre del perfil recibido en la llamada.
     * @return {Id} Id del perfil de Salesforce, si el núlo, no se ha encontrado un perfil válido.
    */
    global Id getProfileId(List<String> profileName)
    {
        try {
            Id result;
            // Se recupera el mapero entre el perfil recibido y el perfil de Salesforce por medio del siguiente metadato.
            Profile_mapping__mdt mapping = [SELECT Salesforce_profile_name__c FROM Profile_mapping__mdt WHERE External_profile_name__c IN : profileName LIMIT 1];            
            // Se recupera el Id del perfil
            Profile pf = [SELECT Id FROM Profile WHERE Name =: mapping.Salesforce_profile_name__c LIMIT 1];
            // El usuario está autorizado y su perfil se corresponde a alguno dentro de Salesforce.
            result = pf.Id;
            return result;
        }
        catch (Exception e)
        {
            throw new RegHandlerException('Cambiado: Su perfil de usuario no es válido. Para más ayuda, póngase en contacto con su administrador.');
        }
    }
    
    /**
     * @Description Recupera el id del grupo publico asignado al valor recibido en la llamada, utiliza el metadato: Public_Group_Mapping__mdt
     * @See Public_Group_Mapping__mdt - Metadata Type
     * @date 01/10/2020
     * @author eetxaniz
     * @param {List<String>} roleNameList - Nombre del rol recibido en la llamada.
     * @return {List>Id>} Mapa que relaciona los ids del grupo de Salesforce con los roles proporcionados mediante el IAM.
     */
    global List<Id> getPublicGroups(List<String> roleNameList)
    {
        try 
        {
            System.debug('**** GET PUBLIC GROUPS, ROLE NAME LIST: ' + roleNameList);
            List<Id> result = new List<Id>();
            // Se recupera el mapa entre el nombre del rol recibido recibido y el grupo publico de Salesforce por medio del siguiente metadato.
            List<Public_Group_Mapping__mdt> groupMappingList = [SELECT External_role_name__c, Salesforce_group_name__c FROM Public_Group_Mapping__mdt WHERE External_role_name__c IN :roleNameList];            
            
            System.debug('**** GET PUBLIC GROUPS, GROUP MAPPING LIST: ' + groupMappingList);


            List<String> salesforceGroupNames = new List<String>();
            for(Public_Group_Mapping__mdt groupItem : groupMappingList)
            {
                salesforceGroupNames.add(groupItem.Salesforce_group_name__c);   
            }           

            System.debug('**** GET PUBLIC GROUPS, SALESFORCE GROUP NAMES: ' + salesforceGroupNames);

            // Se recuperan los ids de grupos
            List<Group> salesforceGroupList = [SELECT Id FROM Group WHERE DeveloperName IN :salesforceGroupNames];


            System.debug('**** GET PUBLIC GROUPS, SALESFORCE GROUP LIST: ' + salesforceGroupList);

            for(Group groupItem : salesforceGroupList)
            {
                result.add(groupItem.Id);
            }

            return result;
        } catch (Exception e) 
        {
            System.debug('**** GET PUBLIC GROUPS, EXCEPTION: ' + e.getMessage());
            throw new RegHandlerException('Error al obtener los grupos públicos del usuario. Compruebe que los nombres de los roles proporcionados son válidos. Para más ayuda, póngase en contacto con su administrador.');
        }
    }

    /**
     * @Description Recupera el id del perfil en función de los roles de usuario que llegan. 
     * Si contiene algún rol de admin, se devolverá el id del perfil de administrador del sistema.
     * Si no contiene admin pero contiene algún rol de Customer Care, se devolverá el id del perfil de customer care.
     * Si no contiene admin ni customer care, devolverá el id del perfil de Analytics.
     * @date 01/10/2020
     * @author eetxaniz
     * @param {List<String>} roleNameList - Lista de roles recibidos en la llamada.
     * @return {Id} Id del perfil de Salesforce, si el nulo, no se ha encontrado un perfil válido.
     */
    global Id getProfileBasedOnRoles(List<String> roleNameList)
    {
        System.debug('**** GET PROFILE BASED ON ROLES');
        System.debug('**** GET PROFILE BASED ON ROLES, ROLE NAME LIST: ' + roleNameList);

        try
        {
            Id result;
            // Se recupera el id del perfil que corresponde en base a los roles que llegan.
            Boolean admin = false;
            Boolean customerCare = false;

            for(String role : roleNameList)
            {
                if(role == 'KLINC_Admin')
                    admin = true;
                if(role.contains('KLINC_CustomerCare'))
                    customerCare = true;
            }

            // Return admin profile id
            if(admin)
                return [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;

            // Return customer care profile id
            if(customerCare)
                return [SELECT Id FROM Profile WHERE Name = 'Customer Care' LIMIT 1].Id;


            // Return analytics profile id
            return [SELECT Id FROM Profile WHERE Name = 'Analytics' LIMIT 1].Id;

        } catch (Exception e) 
        {
            System.debug('**** GET PROFILE BASED ON ROLES, EXCEPTION: ' + e.getMessage());
            throw new RegHandlerException('Error al obtener perfil. Compruebe que los roles del usuario son válidos. Para más ayuda, póngase en contacto con su administrador.');    
        }
    }

    /**
     * @Description Devuelve la lista de group members que relacionan al usuario con los grupos públicos
     * @date 01/10/2020
     * @author eetxaniz
     * @param {Map<Id, List<Id>>} userPublicGroupMap - Mapa de grupos públicos .
     * @return List<GroupMember> Lista de groupMembers que relacionan al usuario con uno o varios grupos públicos.
     */
    global List<GroupMember> assignPublicGroups(Id userId, List<Id> userPublicGroupMap)
    {
        System.debug('**** ASSIGN PUBLIC GROUPS');
        System.debug('**** ASSIGN PUBLIC GROUPS USERID: ' + userId);
        System.debug('**** ASSIGN PUBLIC GROUPS USERPUBLICGROUPMAP: ' + userPublicGroupMap);
        try 
        {
        
            List<GroupMember> groupMemberList = new List<GroupMember>();
        
            for(Id groupId : userPublicGroupMap)
            {
                GroupMember groupMemberItem = new GroupMember();
                groupMemberItem.groupId = groupId;
                groupMemberItem.userOrGroupId = userId;
                groupMemberList.add(groupMemberItem);
            }    
            
            return groupMemberList;
        } catch (Exception e) {
            
            System.debug('**** ASSIGN PUBLIC GROUPS EXCEPTION: ' + e.getMessage());
            throw new RegHandlerException('Error al asignar grupos públicos. Para más ayuda contacte con su administrador.');
        }
    }
    
    /**
     * @Description Actualiza la asignación de grupos públicos para el usuario especificado
     * @date 01/10/2020
     * @author eetxaniz
     * @param Id userId - Id del usuario a actualizar
     * @param List<GroupMember> groupMemberList - Mapa de grupos públicos a asignar.
     */
    global static void updatePublicGroupMembership(Id userId, List<GroupMember> groupMemberList)
    {
        List<GroupMember> actualGroupMemberList = new List<GroupMember>();
        if(!String.isBlank(userId))
            actualGroupMemberList = [SELECT groupId FROM GroupMember WHERE userOrGroupId = :userId];
        
        if(!actualGroupMemberList.isEmpty())
            delete actualGroupMemberList;

        if(!groupMemberList.isEmpty())
            insert groupMemberList;
    }

    
    @future
    public static void futureGroupMemberUpdate(String groupMemberListJson)
    {   
        try 
        { 
            List<GroupMember> groupMemberList = (List<GroupMember>)(JSON.deserialize(groupMemberListJson, List<GroupMember>.class));

            if(!groupMemberList.isEmpty())
                updatePublicGroupMembership(groupMemberList.get(0).UserOrGroupId, groupMemberList);
        }
        catch (Exception e) {
            throw new RegHandlerException('Error durante la asignación de grupos, contacte con su administrador.');
        }
    }


    /**
     * @Description Excepción personalizada para oncluir el mensaje de error en la pantalla de lógin.
     * @date 03/06/2020
     * @author rpolvera
     */
    class RegHandlerException extends Exception {}
}