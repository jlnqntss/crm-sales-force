/**
 * @description Gestiona las diversas funcionalidades al realizar un login en la plataforma por medio de un tercero.
 *              Para este caso de uso, el IAM a tratar es OpenID Connect, el cual proporcionará una respuesta con la confirmación del
 *              login de cada usuario a Salesforce que posteriormente ejecutará lo métodos de esta clase.
 * @date 03/06/2020
 * @author rpolvera@nts-solutions.com
 * @See ./authprovider/
 */
global class OpenIDConnectRegHandler implements Auth.RegistrationHandler {
  /**
   * @Description Método ejecutado cuando el id de federación del usuario que intenta conectar no se corresponde con el de Salesforce.
   * @date 03/06/2020
   * @author rpolvera
   * @param {Id} portalId - Id de federación de usuario.
   * @param {Auth.UserData} data - Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl, attributeMap)
   * @return {User} Objeto de Salesforce que se corresponde con el usuario.
   */
  global User createUser(Id portalId, Auth.UserData data) {
    User u = checkUser(data);
    // Si un usuario con el mismo correo ya existe en el sistema, se actualiza y se retorna.
    if (u != null) {
      updateUser(u.Id, portalId, data);
      return u;
    }
    // De lo contrario se instancia un nuevo usuario
    Map<String, String> details = getExternalColaboration(data);
    Id profileId = (details.containsKey('profile'))
      ? getProfileId(details.get('profile'))
      : null;
    Id roleId = (details.containsKey('role'))
      ? getUserRoleId(details.get('role'))
      : null;
    u = new User();
    u.firstName = data.firstName;
    u.lastName = data.lastName;
    u.email = data.email;
    u.username = data.username + '@zurich-es.com';
    u.profileId = profileId;
    u.userRoleId = roleId;
    u.alias = data.username.left(8);
    u.CommunityNickname = data.username;
    u.languagelocalekey = UserInfo.getLanguage();
    u.localesidkey = UserInfo.getLocale();
    u.emailEncodingKey = 'UTF-8';
    u.timeZoneSidKey = 'Europe/Paris';
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
    Boolean modified = false;
    Map<String, String> details = getExternalColaboration(data);
    Id profileId = (details.containsKey('profile'))
      ? getProfileId(details.get('profile'))
      : null;
    Id roleId = (details.containsKey('role'))
      ? getUserRoleId(details.get('role'))
      : null;
    User u = [
      SELECT
        Id,
        firstName,
        lastName,
        email,
        userName,
        profileId,
        UserRoleId,
        alias,
        CommunityNickname,
        IsActive
      FROM User
      WHERE Id = :userId
      LIMIT 1
    ];

    // Se comprueban los valores, se determina si ha habido cambios
    if (!u.IsActive)
      modified = true;
    if (u.firstName != data.firstName)
      modified = true;
    else if (u.lastName != data.lastName)
      modified = true;
    else if (u.email != data.email)
      modified = true;
    else if (u.userName != data.username + '@zurich-es.com')
      modified = true;
    else if (u.profileId != profileId)
      modified = true;
    else if (u.userRoleId != roleId)
      modified = true;
    else if (u.alias != data.username.left(8))
      modified = true;

    if (modified) {
      u.IsActive = true;
      u.firstName = data.firstName;
      u.lastName = data.lastName;
      if (u.email != data.email)
        u.email = data.email;
      if (u.userName != data.username + '@zurich-es.com')
        u.userName = data.username + '@zurich-es.com';
      u.profileId = profileId;
      u.userRoleId = roleId;
      u.alias = data.username.left(8);
      u.CommunityNickname = data.username;
      update (u);
    }
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
  global User checkUser(Auth.UserData data) {
    User result;
    try {
      result = [
        SELECT
          Id,
          firstName,
          lastName,
          email,
          userName,
          profileId,
          UserRoleId,
          alias,
          CommunityNickname,
          IsActive
        FROM User
        WHERE email = :data.email
        LIMIT 1
      ];
    } catch (Exception e) {
      result = null;
    }
    return result;
  }

  /**
   * @Description Recupera el nombre del perfil externo para esta sesión, este perfil puede contener el rol de Salesforce concatenado po "_".
   * @date 06/06/2020
   * @author rpolvera
   * @param {Auth.UserData} data - Almacena la información del usuario: UserData(identifier, firstName, lastName, fullName, email, link, userName, locale, provider, siteLoginUrl,
   *                               attributeMap)
   * @return {Map<String, String>} Asignación para la colaboración de este usuario, la primera posición.
   */
  global Map<String, String> getExternalColaboration(Auth.UserData data) {
    Map<String, String> result = new Map<String, String>();

    try {
      // Recuperación del perfil de usuario de los datos recibidos por desde el IAM
      // Este perfil puede estar concatenado con el role por el siguiente caracter "_".
      List<String> details = data.attributeMap.get('roles')
            .remove('{')
            .remove('}')
            .remove('[')
            .remove(']')
            .split('=')[1]
          .split(',')[0]
        .split('_');
      result.put('profile', details[0]);
      if (details.size() > 1)
        result.put('role', details[1]);
    } catch (Exception e) {
      throw new RegHandlerException(
        'Sus datos no son correctos. Para más ayuda, póngase en contacto con su administrador.'
      );
    }

    return result;
  }

  /**
   * @Description Recupera el id del perfil asignado al valor recibido en la llamada, utiliza el metadato: Profile_mapping__mdt
   * @See Profile_mapping__mdt - Metadata Type
   * @date 03/06/2020
   * @author rpolvera
   * @param {String} profileName - Nombre del perfil recibido en la llamada.
   * @return {Id} Id del perfil de Salesforce, si el núlo, no se ha encontrado un perfil válido.
   */
  global Id getProfileId(String profileName) {
    try {
      Id result;
      // Se recupera el mapero entre el perfil recibido y el perfil de Salesforce por medio del siguiente metadato.
      Profile_mapping__mdt mapping = [
        SELECT Salesforce_profile_name__c
        FROM Profile_mapping__mdt
        WHERE External_profile_name__c = :profileName
        LIMIT 1
      ];
      // Se recupera el Id del perfil
      Profile pf = [
        SELECT Id
        FROM Profile
        WHERE Name = :mapping.Salesforce_profile_name__c
        LIMIT 1
      ];
      // El usuario está autorizado y su perfil se corresponde a alguno dentro de Salesforce.
      result = pf.Id;
      return result;
    } catch (Exception e) {
      throw new RegHandlerException(
        'Su perfil de usuario no es válido. Para más ayuda, póngase en contacto con su administrador.'
      );
    }
  }

  /**
   * @Description Recupera el id del rol asignado al valor recibido en la llamada, utiliza el metadato: Role_mapping__mdt
   * @See Role_mapping__mdt - Metadata Type
   * @date 06/07/2020
   * @author rpolvera
   * @param {String} roleName - Nombre del role recibido en la llamada.
   * @return {Id} Id del role de Salesforce, si es núlo, no se ha encontrado un role válido.
   */
  global Id getUserRoleId(String roleName) {
    try {
      Id result;
      // Se recupera el mapero entre el perfil recibido y el perfil de Salesforce por medio del siguiente metadato.
      Role_mapping__mdt mapping = [
        SELECT Salesforce_role_name__c
        FROM Role_mapping__mdt
        WHERE External_role_name__c = :roleName
        LIMIT 1
      ];
      // Se recupera el Id del perfil
      UserRole rl = [
        SELECT Id
        FROM UserRole
        WHERE DeveloperName = :mapping.Salesforce_role_name__c
        LIMIT 1
      ];
      // El usuario está autorizado y su perfil se corresponde a alguno dentro de Salesforce.
      result = rl.Id;
      return result;
    } catch (Exception e) {
      throw new RegHandlerException(
        'Su role de usuario no es válido. Para más ayuda, póngase en contacto con su administrador.'
      );
    }
  }

  /**
   * @Description Excepción personalizada para oncluir el mensaje de error en la pantalla de lógin.
   * @date 03/06/2020
   * @author rpolvera
   */
  class RegHandlerException extends Exception {
  }
}
