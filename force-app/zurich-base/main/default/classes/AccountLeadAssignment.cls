/**
 * @description       : Clase centrada en la asignación a agentes de la comunidad de Mi Agencia
 *                      de las cuentas de tipo Lead que llegan a Salesforce.
 * @author            : jgallaga
 * @group             : Seidor
 * @last modified on  : 28/08/2023
 * @last modified by  : jgallaga
**/
public with sharing class AccountLeadAssignment
{

    public class Assignment
    {
        String assignee;
        Account relatedTo;

        public Assignment(String assigneeValue)
        {
            assignee = assigneeValue;
        }

        public Assignment setRelatedAccount(Account record)
        {
            relatedTo = record;
            return this;
        }

        public Map<String, Account> getAssignmentAsMap()
        {
            return new Map<String,Account> { assignee => relatedTo};
        }
    }

    private static final String CONTACT_CENTER = 'CONTACT_CENTER';
    @TestVisible private static final String DEFAULT_ASSIGNEMENT_TYPE = 'Province';

    /*** MEDATADA ***/
    @TestVisible
    private static List<LanguageAssignment__mdt> languageAssignmentMetadata
    {
        get
        {
            if(languageAssignmentMetadata != null)
            {
                return languageAssignmentMetadata;
            }

            languageAssignmentMetadata = LanguageAssignment__mdt.getAll().values();
            return languageAssignmentMetadata;
        }
        set;
    }

    @TestVisible
    private static List<ForumOriginAssignment__mdt> forumOriginAssignmentMetadata
    {
        get
        {
            if(forumOriginAssignmentMetadata != null)
            {
                return forumOriginAssignmentMetadata;
            }

            forumOriginAssignmentMetadata = ForumOriginAssignment__mdt.getAll().values();
            return forumOriginAssignmentMetadata;
        }
        set;
    }

    @TestVisible
    private static List<MunicipalityAssignment__mdt> municipalityAssignmentMetadata
    {
        get
        {
            if(municipalityAssignmentMetadata != null)
            {
                return municipalityAssignmentMetadata;
            }

            municipalityAssignmentMetadata = MunicipalityAssignment__mdt.getAll().values();
            return municipalityAssignmentMetadata;
        }
        set;
    }

    @TestVisible
    private static List<ProvinceAssignment__mdt> provinceAssignmentMetadata
    {
        get
        {
            if(provinceAssignmentMetadata != null)
            {
                return provinceAssignmentMetadata;
            }

            provinceAssignmentMetadata = ProvinceAssignment__mdt.getAll().values();
            return provinceAssignmentMetadata;
        }
        set;
    }

    /**
     * @description Variable con el usuario por defecto que se asigna a aquellos
     *              Leads a los que no se le encuentra un Agente adecuado
     * @author      jgallaga
     * @date        11/08/2023
     */
    private static Assignment defaultUser
    {
        get
        {
            if(defaultUser != null)
            {
                return defaultUser;
            }

            defaultUser = new Assignment(getDefaultZRMAccountLeadOwnerId());

            return defaultUser;
        }
        set;
    }

    /**
     * @description Devuelve el Id de Usuario al que le corresponde el código de
     *              Intermediario o el Id del usuario por defecto si no se encuentra
     *              a quien pertenece dicho código.
     *              En caso de que el código de intermediario recibido sea
     *              CONTACT_CENTER, devolverá ese mismo valor.
     * @author      jgallaga
     * @date        11/08/2023
     * @param       String - intermediaryCode
     *              Código de intermediario de un agente.
     * @return      String
     *              Id de usuario o 'CONTACT_CENTER'
     */
    public static Assignment getAssignedUserIdByIntermediaryCode(String intermediaryCode)
    {
        if(String.isNotBlank(intermediaryCode) && intermediaryCode == CONTACT_CENTER)
        {
            return new Assignment(CONTACT_CENTER);
        }

        return getIntermediaryUserId(intermediaryCode);
    }

    /**
     * @description Devuelve el Id de Usuario segun el idioma recibido.
     *              La asignación corresponde segun la defición en el metadato LanguageAssignment__mdt.
     *              De no encontrar un agente para el idioma facilitado devolverá
     *              el Id del usuario por defecto.
     * @author      jgallaga
     * @date        11/08/2023
     * @param       String - language
     *              Valor de idioma a buscar entre los valores de metadato para
     *              conseguir el Id del usuario.
     * @return      String
     *              Id de usuario.
     */
    public static Assignment getAssignedUserIdByLanguage(String language)
    {
        for(LanguageAssignment__mdt currentLanguageAssignment : languageAssignmentMetadata)
        {
            if(currentLanguageAssignment.Language__c == language && String.isNotBlank(currentLanguageAssignment.AssignTo__c))
            {
                return getIntermediaryUserId(currentLanguageAssignment.AssignTo__c);
            }
        }

        return defaultUser;
    }

    /**
     * @description Devuelve el Id de Usuario segun el valor de origen o código postal
     *              segun el tipo de asignación que tenga configurado en metadatos.
     *              De no encontrar una configuración para el origen, se realizará
     *              asignación por provincia.
     * @author      jgallaga
     * @date        11/08/2023
     * @param       String - origin
     *              Valor de origen de la información
     * @patam       String - postalCode
     *              Valor del código de postal
     * @return      String
     *              Id de Usuario
     */
    public static Assignment getAssignedUserIdByAssignmentType(String origin, String postalCode)
    {
        Assignment assignedUser;
        String assignmentType = getAssigmentType(origin);

        switch on assignmentType
        {
            when 'Direct'
            {
                assignedUser = assignedUserDirectly(origin);
            }
            when 'Municipality'
            {
                assignedUser = assignedUserByMunicipality(postalCode);
            }
            when 'Province'
            {
                assignedUser = assignedUserByProvince(postalCode);
            }
            when else
            {
                assignedUser = defaultUser;
            }
        }

        return assignedUser;
    }

    /**
     * @description Proceso para conseguir el Id del intermediario a partir
     *              del origen recibido. Se utiliza el metadato FormOriginAssignment__mdt
     *              para conocer el código de intermedario al que le corresponde
     *              el origen con el que se obtiene el Id de usuario.
     * @author      jgallaga
     * @date        11/08/2023
     * @param       String - origin
     *              Valor de origen de la información
     * @return      String
     *              Id de usuario.
     */
    @TestVisible
    private static Assignment assignedUserDirectly(String origin)
    {
        if(String.isBlank(origin))
        {
            return defaultUser;
        }

        for(ForumOriginAssignment__mdt currentFOA : forumOriginAssignmentMetadata)
        {
            if(currentFOA.ForumOrigin__c == origin && String.isNotBlank(currentFOA.AssignTo__c))
            {
                return getIntermediaryUserId(currentFOA.AssignTo__c);
            }
        }

        return defaultUser;
    }

    /**
     * @description Proceso para conseguir el Id del intermediario a partir
     *              del código postal recibido. Se utiliza el metadato MunicipalityAssignment__mdt
     *              para conocer el código de intermedario al que le corresponde
     *              el código postal con el que se obtiene el Id de usuario.
     * @author      jgallaga
     * @date        11/08/2023
     * @param       String - postalCode
     *              Valor del código postal
     * @return      String
     *              Id de usuario.
     */
    @TestVisible
    private static Assignment assignedUserByMunicipality(String postalCode)
    {
        if(String.isBlank(postalCode))
        {
            return defaultUser;
        }

        for(MunicipalityAssignment__mdt currentMA : municipalityAssignmentMetadata)
        {
            if(currentMA.PostalCode__c == Integer.valueOf(postalCode) && String.isNotBlank(currentMA.AssignTo__c))
            {
                return getIntermediaryUserId(currentMA.AssignTo__c);
            }
        }

        return defaultUser;
    }

    /**
     * @description Proceso para conseguir el Id del intermediario a partir
     *              del los dos primeros números del código postal recibido para
     *              conocer la provincia.
     *              Se utiliza el metadato ProvinceAssignment__mdt
     *              para conocer el código de intermedario al que le corresponde
     *              el código postal con el que se obtiene el Id de usuario.
     * @author      jgallaga
     * @date        11/08/2023
     * @param       String - postalCode
     *              Valor del código postal, deben ser en formato de 5 carácteres
     * @return      String
     *              Id de usuario.
     */
    @TestVisible
    private static Assignment assignedUserByProvince(String postalCode)
    {
        if(String.isBlank(postalCode))
        {
            return defaultUser;
        }

        Integer postalProvince = Integer.valueOf(postalCode.substring(0, 2));

        for(ProvinceAssignment__mdt currentPA : provinceAssignmentMetadata)
        {
            if(currentPA.PostalCode__c == postalProvince && String.isNotBlank(currentPA.AssignTo__c))
            {
                return getIntermediaryUserId(currentPA.AssignTo__c);
            }
        }

        return defaultUser;
    }

    /**
     * @description Método que devuelve la forma de buscar en la que hay que
     *              realizar la búsqueda del agente intermediario a partir
     *              del origen recibido.
     *              El modo de asignación segun origen viene definido en el
     *              metadato ForumOriginAssignment__mdt.
     *              De no encontrar una configuración, devolverá el valor de
     *              la variable DEFAULT_ASSIGNEMENT_TYPE como tipo de asignación.
     * @author      jgallaga
     * @date        11/08/2023
     * @param       String - origin
     *              Valor del origen
     * @return      String
     *              La forma de asignación segun origen
     */
    @TestVisible
    private static String getAssigmentType(String origin)
    {
        if(String.isBlank(origin))
        {
            return DEFAULT_ASSIGNEMENT_TYPE;
        }

        for(ForumOriginAssignment__mdt currentFOA : forumOriginAssignmentMetadata)
        {
            if(currentFOA.ForumOrigin__c == origin && String.isNotBlank(currentFOA.AssignmentType__c))
            {
                return currentFOA.AssignmentType__c;
            }
        }

        return DEFAULT_ASSIGNEMENT_TYPE;
    }

    /**
     * @description Método para obtener el usuario por defecto segun el entorno
     *              en el que se encuentre la lógica de asignación.
     *              De forma automatica conocerá el nombre del entorno en el que
     *              se encuentra para obtener el usuario correspondiente.
     * @return      String
     *              Id del usuario por defecto
     * @throws      QueryException
     *              El método lanzará una excepción si no se encuentra el usuario
     *              por defecto.
     */
    @TestVisible
    private static String getDefaultZRMAccountLeadOwnerId()
    {
        // Se recupera el alias? del usuario por defecto de un custom setting
        String aliasDefaultUser = Cross_Selling__c.getinstance().DefaultUser__c;

        System.debug('Alias entonctado en Custom setting '+ aliasDefaultUser);

        if(String.isNotBlank(aliasDefaultUser))
        {
            UsersSelector userQuery = new UsersSelector();
            List<User> defaultUser = userQuery.findUsersByAlias(new List<String>{aliasDefaultUser});

            if(! defaultUser.isEmpty())
            {
                return defaultUser.get(0).id;
            }
        }

        throw new QueryException('No default User found for Lead Account assignments.');

    }

    /**
     * @description Devuelve el Id de Usuario a partir del código de intermediario.
     *              Se busca una cuenta cuyo campo INFOIntermediaryCode__c tenga el
     *              cógido de intermediario. Después se busca aquel usuario que apunte
     *              mediante su relación con el contacto a esa cuenta para conseguir
     *              el identificador de intermediario.
     * @author      jgallaga
     * @date        11/08/2023
     * @param       String - intermediaryCode
     *              Código de intermediario del agente
     * @return      String
     *              Id de usuario.
     */
    @TestVisible
    private static Assignment getIntermediaryUserId(String intermediaryCode)
    {

        if(String.isBlank(intermediaryCode))
        {
            return defaultUser;
        }

        AccountsSelector accountQuery = new AccountsSelector();
        List<Account> intermediaryAccount = accountQuery.findByINFOIntermediaryCode(new List<String>{intermediaryCode});

        if(intermediaryAccount.isEmpty())
        {
            return defaultUser;
        }

        UsersSelector userQuery = new UsersSelector();
        List<User> intermediary = userQuery.findUsersByAccountId(new List<String>{intermediaryAccount.get(0).Parent.IntermediaryWithUser__c});

        if(! intermediary.isEmpty())
        {
            return new Assignment(intermediary.get(0).Id).setRelatedAccount(intermediaryAccount.get(0));
        }

        return defaultUser;
    }
}