/**
 * Clase de utilidad para el proyecto de SDM (Sales Digital Management)
 *
 * @author nts (agonzalezisasi)
 * @date 23/06/20201
 */
public with sharing class IntermediarySDM {
    // CONSTANTES
    @testvisible
    private static final String INTERMEDIARY_STATUS_ACTIVE = 'Active';
    private static final String INTERMEDIARY_STATUS_INACTIVE = 'Inactive';
    private static final String ATM_ROL_STATUS_ACTIVE = 'Active';
    @testvisible
    private static final String ATM_ROL_STATUS_INACTIVE = 'Inactive';
    // 17.08.2021 - nts (agonzalezisasi) - bug sdm-361 - Limite de caracteres en el nombre del contacto
    private static final Integer CONTACT_NAME_MAX_SIZE = 80;
    @testvisible
    private static final String INTERMEDIARY_VACANT = 'VACANT';
    private static final String SETUP_RC_NAME = 'SDMIntermediaryRCName';
    private static final String SETUP_RC_FIELD = 'SDMIntermediaryRCField';
    private static final String SETUP_NOTIFICATION_TITLE = 'SDMNotificationTitle';
    private static final String SETUP_NOTIFICATION_BODY = 'SDMNotificationBody';
    public static final String ATM_ACCOUNT_ACCESS_LEVEL = 'Read';
    public static final String ATM_ACCOUNT_ACCESS_LEVEL_EDIT = 'Edit';
    public static final String ATM_CONTACT_ACCESS_LEVEL = 'Read';
    public static final String ATM_CASE_ACCESS_LEVEL = 'Edit';
    public static final String ATM_OFFER_ACCESS_LEVEL = 'Read';

    public static final String INTERMEDIARY_FIELD_NATIONALID = 'NationalId__c';
    public static final String INTERMEDIARY_FIELD_PARENTID = 'ParentId';
    public static final String INTERMEDIARY_FIELD_NAME = 'Name';
    public static final String INTERMEDIARY_FIELD_STATUS = 'Status__c';
    public static final String INTERMEDIARY_FIELD_STATUS_INTERMEDIARY = 'StatusIntermediary__c';
    public static final String INTERMEDIARY_FIELD_INACTIVE_NONEXISTENT_USERS = 'InactiveOrNonExistentUsers__c';

    // CONFIGURACION
    public SettingsSDM settings;

    // Relacion entre Rol de equipo de cuenta y campos de Mediador
    public List<SDMAccountTeamRole__mdt> SettingsATM {
        set;
        get {
            if( SettingsATM == null ) {
                SettingsATM = this.settings.getAccountRolesWithIntermediaryFields(
                    this.testSettingsATM
                );
            }
            return SettingsATM;
        }
    }
    public Set<String> SettingsATMFields {
        set;
        get {
            if( SettingsATMFields == null ) {
                SettingsATMFields = new Set<String>();
                if( SettingsATM != null && !SettingsATM.isEmpty() ) {
                    // Get the list of Intermediary fields
                    for( SDMAccountTeamRole__mdt s: SettingsATM ) {
                        SettingsATMFields.add(s.IntermediaryField__c);
                    }
                }
            }
            return SettingsATMFields;
        }
    }
    @testvisible
    private List<SDMAccountTeamRole__mdt> testSettingsATM;

    // Relacion entre Rol de cuenta-contacto y campos de Mediador
    public List<SDMAccountContactRelation__mdt> SettingsACR {
        set;
        get {
            if( SettingsACR == null ) {
                SettingsACR = this.settings.getContactRolesWithIntermediaryFields(
                    this.testSettingsACR
                );
            }
            return SettingsACR;
        }
    }
    public Set<String> SettingsACRFields {
        set;
        get {
            if( SettingsACRFields == null ) {
                SettingsACRFields = new Set<String>();
                if( SettingsACR != null && !SettingsACR.isEmpty() ) {
                    // Get the list of Intermediary fields
                    for( SDMAccountContactRelation__mdt s: SettingsACR ) {
                        SettingsACRFields.add(s.IntermediaryField__c);
                    }
                }
            }
            return SettingsACRFields;
        }
    }
    @testvisible
    private List<SDMAccountContactRelation__mdt> testSettingsACR;

    // Nombre del responsable de negocio: Director Territorial Centralizados => no tiene equipos de cuenta (ATM)
    private String rnNameNoATM {
        set;
        get {
            if( String.isBlank(rnNameNoATM) ) rnNameNoATM = getRNName();
            return rnNameNoATM;
        }
    }
    @testvisible
    private String testrnNameNoATM;
    public String rnFieldNoATM{
        set;
        get {
            if( String.isBlank(rnFieldNoATM) ) rnFieldNoATM = getRNField();
            return rnFieldNoATM;
        }
    }
    @testvisible
    private String testrnFieldNoATM;
    
    // Metadato de configuracion: Titulo de la notificacion
    private String notificationTitle {
        set;
        get {
            if( notificationTitle == null ) notificationTitle = this.getNotificationTitle();
            return notificationTitle;
        }
    }
    // Metadato de configuracion: Cuerpo de la notificacion
    private String notificationBody {
        set;
        get {
            if( notificationBody == null ) notificationBody = this.getNotificationBody();
            return notificationBody;
        }
    }

    // ACCOUNT TEAM MEMBER
    // Mapa de ATM por Id de mediador asociado y Rol de ATM, y Id de usuario
    public Map<ID, Map<String, Map<ID, AccountTeamMember>>> mapATMsByAccountRolUser;
    //Mapa de UserIds de las agrupaciones por CIF
    public Map<String, Set<Id>> mapExistingAgrupationUsers;
    //Mapa de id de ATM de las agrupaciones por CIF y por UserId
    public Map<String, Map<Id, Id>> mapExistingATMsByNationalIdAndUserId;
    // Mapa de UserIds de los mediadores por CIF
    public Map<String, Set<Id>> mapExistingIntermediaryUsers;
    // Mapa de los id de ATM de los mediadores por CIF y por UserId
    public Map<String, Map<Id, AccountTeamMember>> mapExistingInterATMsByNationalIdAndUserId;
    public List<AccountTeamMember> atmsToCreate;
    public List<AccountTeamMember> atmsToDeleteInAgr;

    // AGRUPACION MEDIADORES
    // Mapa de agrupaciones por CIF de agrupacion
    public Map<String, Account> mapAgrupationByCIF;
    // Mapa de intermediarios por Id de sus Agrupaciones
    public Map<Id, List<Account>> intermediariesByParentId;
    //Mapa de la posicion de la agrupación y la cuenta de tipo agrupación
    public Map<Integer, Account> mapAgrupationByPos;
    // Mapa del CIF de la cuenta de agrupación y la posición de la agrupación
    public  Map<String, Integer> mapAgrupationPosByCIF ;
    // Mapa posición de la agrupación y lista de mediadores para esa agrupación
    public  Map<Integer, List<Account>> mapIntermediaryByPos;
    // Lista de mediadores a actualizar
    public List<Account> listIntermediariesToUpdate;
    //Mapa de id de agrupación y cuenta de agrupación
    public Map<Id, Account> agrupationToUpdateById ;
    // Mapa de id de agrupación y cuenta de agrupación
    public Map<Id, Account> agrupationToCheckById ;
    
    //Posición a añadir la agrupación en el mapa
    public Integer positionAgruptation;

    // USUARIOS
    // Mapa de usuarios por Email de usuario
    private Map<String, User> mapUsersByEmail;

    // ACCOUNT CONTACT RELATION
    // Mapa de AccountContactRelation por Id de Mediador y por Id de Contacto
    public Map<ID, Map<ID, AccountContactRelation>> mapACRsByAccountContact;
    // Mapa de AccountContactRelation por Id de Mediador y por Role
    @testvisible
    private Map<ID, Map<String, AccountContactRelation>> mapACRsByAccountRole;
    //ACR que se debera borrar su relacion
    @testvisible
    private AccountContactRelation acrToDelete;
    // Mapa para los contactos nuevos que tengan varios roles en un mediador
    @testvisible
    private Map<String, Integer> mapContactPositionByEmail;
    //Mapa de contactos a insertar, indica la posición del contacto
    @testvisible
    private Map<Integer, Contact> mapContactsToInsert;
    //Posición del contacto
    @testvisible
    private Integer position;
    // Mapa para los roles de los contactos nuevos. Posición del contacto y lista de roles
    @testvisible
    private Map<Integer, List<String>> mapRolesForContacts;
    //Mapa de id de la cuenta, con id de contacto y la relación entre contacto y cuenta
    @testvisible
    private Map<Id, Map<Id, AccountContactRelation>> mapNewACRsByAccountAndContactIds;
    // Lista de relaciones de contacto a insertar o actualizar
    @testvisible
    private List<AccountContactRelation> acrsToUpsert;
    @testvisible
    // Lista de relaciones de contacto a eliminar
    private List<AccountContactRelation> acrsToDelete;


    // CONTACTO
    // Mapa de Contactos por Email
    private Map<String, Contact> mapContactsByEmail;

    // ACCOUNT id de tipo de registro de agrupacion de mediadores
    @TestVisible
    private Id rtAgrupationId;
    
    // Lista de CIFs de agrupaciones que se han creado o modificado el ATM de sus hijos. Nos dira que CIF de agrupacion
    // hay que recalcular su ATM
    public Set<String> listAgrupationCIFs;

    // Lista de usuarios a enviar la notificacion de cambio de visibilidad del mediador
    public Set<Id> listUserIdsToNotify;

    // Plan anual - Se registran los ATMs eliminados para ver si hay que borrar tambien planes anuales
    public List<AccountTeamMember> listDeletedAtms;

    // CONSTRUCTOR
    public IntermediarySDM()
    {
        settings = new SettingsSDM();
    }
    
    // METODOS

    /**
     * Recupera de la configuracion el nombre del responsable de negocio de mediadores
     */
    private String getRNName()
    {
        String result = this.settings.getSetupParameter(SETUP_RC_NAME, null);

        if( Test.isRunningTest() && String.isNotBlank(this.testrnNameNoATM) ) result = this.testrnNameNoATM;

        return result;
    }

    /**
     * Recupera de la configuracion el campo del Mediador donde esta el nombre del responsable de negocio
     */
    private String getRNField()
    {
        String result = this.settings.getSetupParameter(SETUP_RC_FIELD, null);

        if( Test.isRunningTest() && String.isNotBlank(this.testrnFieldNoATM) ) result = this.testrnFieldNoATM;

        return result;
    }

    /**
     * Recupera de la configuracion el titulo de la Notificacion de visibilidad
     */
    private String getNotificationTitle()
    {
        String result = this.settings.getSetupParameter(
            SETUP_NOTIFICATION_TITLE, 'Cambios en la visibilidad de tus Mediadores'
        );

        return result;
    }

    /**
     * Recupera de la configuracion el cuerpo de la Notificacion de visibilidad
     */
    private String getNotificationBody()
    {
        String result = this.settings.getSetupParameter(
            SETUP_NOTIFICATION_BODY, 'La asignación de mediadores relacionados con tu usuario ha sido modificada. Puedes comprobar los cambios en la sección de Cuentas.'
        );

        return result;
    }

    /**
     * Recupera todos los usuarios del sistema y crea un Mapa de usuarios por email
     */
    private void findAllUsers()
    {
        // Mapa de usuarios por su Email
        if( mapUsersByEmail == null ) {
            mapUsersByEmail = new Map<String, User>();
            for(User u: [SELECT Id, Email, isActive, Name FROM User]) {
                mapUsersByEmail.put(u.Email, u);
            }
        }
    }

    /**
     * Recupera todas las cuentas de tipo Agrupacion de Mediadores y crea un Mapa de Agrupaciones por CIF
     */
    private void findAgrupatedIntermediaries(List<Account> acList)
    {
        // Se recuperan las Agrupaciones de intermediarios para los elementos que se han recibido en la lista
        List<Account> agrupationIntermediary = new AccountsSelector().findAgrupatedIntermediaries(acList);

        // Mapa de agrupaciones por CIF de agrupacion
        this.mapAgrupationByCIF = new Map<String, Account>();
        for(Account a: agrupationIntermediary) {
            this.mapAgrupationByCIF.put(a.NationalID__c, a);
        }
    }

    /**
    * @description Recupera las cuentas de tipo intermediario y las agrupa por su ParentId
    * @author amiranda 
    * @date 16-01-2023 
    * @param Set<Id> parentIds Ids de las agrupaciones sobre las que realizar la consulta
    **/
    private void findIntermediariesByParentId(Set<Id> parentIds)
    {
        // Se buscan todos los mediadores relacionados con la agrupación
        List<Account> intermediaries = new AccountsSelector().findIntermediariesByParentId(parentIds);

        this.intermediariesByParentId = new Map<Id, List<Account>>();

        // Ordenar intermediarios por ParentId
        for (Account intermediary : intermediaries)
        {
            List<Account> intmd = this.intermediariesByParentId.get(intermediary.ParentId);

            if (intmd == null)
            {
                intmd = new List<Account>();
                this.intermediariesByParentId.put(intermediary.ParentId, intmd);
            }

            intmd.add(intermediary);
        }
    }

    /**
     * Recupera los objetos Account Team Member que pertenecen a alguna de las cuentas de Mediadores dadas
     * 
     * @param {List<Account> intermediaries} cuentas de Mediadores
     */
    private void findATMsByIntermediaries(List<Account> intermediaries)
    {
        List<AccountTeamMember> atms = (new AccountTeamMemberSelector()).findByIntermediary(intermediaries);

        // Mapa de ATM por Id de mediador asociado, Rol de ATM y por Id de usuario
        this.mapATMsByAccountRolUser = new Map<ID, Map<string, Map<ID, AccountTeamMember>>>();
        if( atms != null && !atms.isEmpty() ) {
            for(AccountTeamMember atm: atms) {
                Map<String, Map<ID, AccountTeamMember>> mapRoles = this.mapATMsByAccountRolUser.get(atm.AccountId);
                if( mapRoles == null ) {
                    mapRoles = new Map<String, Map<ID, AccountTeamMember>>();
                    this.mapATMsByAccountRolUser.put(atm.AccountId, mapRoles);
                }
                Map<ID, AccountTeamMember> mapUser = mapRoles.get(atm.TeamMemberRole);
                if( mapUser == null ) {
                    mapUser = new Map<ID, AccountTeamMember>();
                    mapRoles.put(atm.TeamMemberRole, mapUser);
                }
                mapUser.put(atm.UserId, atm);
            }
        }
    }

    /**
     * Recupera los objetos Account Contact Relation que pertenecen a las cuentas de Mediadores y crean dos mapas:
     * - ACRs por Id de Mediador y por Id de Contacto
     * - ACRs por Id de Mediador y por Role
     *
     * @param {List<Account> intermediaries} lista de Mediadores
     */
    private void findACRsByIntermediaries(List<Account> intermediaries)
    {
        List<AccountContactRelation> acrs = (new AccountContactRelationSelector()).findByIntermediaries(
            intermediaries
        );

        // Mapa de ACRs por Id de Mediador y por Id de Contacto
        this.mapACRsByAccountContact = new Map<ID, Map<ID, AccountContactRelation>>();
        // Mapa de ACRs por Id de Mediador y por Role
        this.mapACRsByAccountRole = new Map<ID, Map<String, AccountContactRelation>>();

        if( acrs != null && !acrs.isEmpty() ) {
            for( AccountContactRelation acr: acrs ) {
                // Mapa de ACRs por Id de Mediador y por Id de Contacto
                Map<ID, AccountContactRelation> mapContact = this.mapACRsByAccountContact.get(acr.AccountId);
                if( mapContact == null ) {
                    mapContact = new Map<ID, AccountContactRelation>();
                    this.mapACRsByAccountContact.put(acr.AccountId, mapContact);
                }
                mapContact.put(acr.Contactid, acr);
                
                createACRMap(acr); // Mapa de ACRs por Id de Mediador y por cada role que tenga la relacion
            }
        }
    }


    /**
     *  Mapa de ACRs por Id de Mediador y por cada role que tenga la relacion
     *
     * @param {AccountContactRelation acr} AccountContactRelation a procesar en el mapa de roles
     */    
    private void createACRMap(AccountContactRelation acr)
    {
        List<String> roles = acr.Roles?.split(';');
        if( roles != null ) {
            for(String role: roles) {
                Map<String, AccountContactRelation> mapRole = this.mapACRsByAccountRole.get(acr.AccountId);
                if( mapRole == null ) {
                    mapRole = new Map<String, AccountContactRelation>();
                    this.mapACRsByAccountRole.put(acr.AccountId, mapRole);
                }
                mapRole.put(role, acr);
            }
        }
    }

    /**
     * Recupera los contactos que tengan los emails dados como parametro
     *
     * @param {Set<String> emails} lista de emails de contacto
     */
    private void findContactByEmail(Set<String> emails)
    {
        List<Contact> contacts = new ContactsSelector().findByEmailField(new List<String>(emails));

        if( contacts != null && !contacts.isEmpty() ) {
            // Mapa de contactos por email del contacto
            this.mapContactsByEmail = new Map<String, Contact>();
            for(Contact c: contacts) {
                this.mapContactsByEmail.put(c.Email, c);
            }
        }
    }

    /**
     * Crea o actualiza los ATMs dados
     * 
     * @param {List<AccountTeamMember atmToUpser} lista de ATMs
     */
    public void upsertATMs(List<AccountTeamMember> atmToUpsert)
    {
        if( atmToUpsert != null && !atmToUpsert.isEmpty() ) {
            upsert atmToUpsert;
        }
    }

    /**
     * Borra los ATMs dados
     * 
     * @param {List<AccountTeamMember atmToDelete} lsita de ATMs
     */
    private void deleteATMs(List<AccountTeamMember> atmToDelete)
    {
        if( atmToDelete != null && !atmToDelete.isEmpty() ) {
            delete atmToDelete;
        }
    }

    /**
     * Añade un CIF a la lista de CIF de agrupacion para su posterior procesado
     * 
     * @param {String nationalId} El CIF
     */
    private void addNationalId(String nationalId)
    {
        if( nationalId != null && nationalId.length() != 0) {
            if(this.listAgrupationCIFs == null) this.listAgrupationCIFs = new Set<String>();
            this.listAgrupationCIFs.add(nationalId);
        }
    }

    /**
     * Añade un UserId a la lista de ids de usuario a notificar el cambio de visibilidad
     * 
     * @param {Id userId} Id de usuario
     */
    private void addUserToNotify(Id userId)
    {
        if(this.listUserIdsToNotify == null) this.listUserIdsToNotify = new Set<Id>();
        this.listUserIdsToNotify.add(userId);
    }

    /**
     * Añade varios UserId a la lista de ids de usuario a notificar el cambio de visibilidad
     * 
     * @param {Set<Id> userId} Lista de Ids de usuario
     */
    private void addUsersToNotify(Set<Id> userIds)
    {
        if(this.listUserIdsToNotify == null) this.listUserIdsToNotify = new Set<Id>();
        this.listUserIdsToNotify.addAll(userIds);
    }

    

    /**
     * Metodo que, para los Mediadores dados por parametro, calcula su correspondiente cuenta de Agrupacion de Mediador
     * y setea el estado de la Agrupación en base al estado de los Mediadores.
     *
     * @param {List<Account> intermedires} lista de Mediadores
     * change : aberuete 27/03/2023
     * Refactorizar la clase
     */
    public void assignIntermediaryAgrupation(List<Account> intermediaries)
    {
        // Si hay mediadores...
        if( intermediaries != null && !intermediaries.isEmpty() ) 
        {
            Map<String, Object> fieldsToValue = intermediaries[0].getPopulatedFieldsAsMap();
            // Comprobamos en el PRIMER Mediador si tienen el campo CIF y su Agrupacion Actual, 
            // sino lo tiene se vuelven a recuperar
            List<Account> intermediariesToProcess = ifAnyIntermediaryFieldIsMissingPopulateAgain (intermediaries, fieldsToValue);

            // Si hay Mediadores para obtener su Agrupacion...
            if( !intermediariesToProcess.isEmpty() ) 
            {
                // Recuperamos todos las cuentas de Agrupacion de Mediadores y creamos un mapa por CIF
                // (si la lista se vuelve muy grande se podria reducir el numero devuelto mirando primero los CIF de
                //  los mediadores a buscar)
                this.findAgrupatedIntermediaries(intermediariesToProcess);
                
                mapAgrupationByPos = new Map<Integer, Account>();
                mapIntermediaryByPos = new Map<Integer, List<Account>>();
                mapAgrupationPosByCIF = new Map<String, Integer>();
                positionAgruptation  = 0;
                listIntermediariesToUpdate  = new List<Account>();
                agrupationToUpdateById = new Map<Id, Account>();
                agrupationToCheckById = new Map<Id, Account>();

                // Por cada mediador...
                for(Account intermediary: intermediariesToProcess ) 
                {
                    // Si tienen campo CIF de agrupacion
                    if( String.isNotBlank(intermediary.NationalId__c) ) 
                    {
                        // Recuperamos el Id de Agrupacion que corresponderia a ese CIF
                        Account agrupation = this.mapAgrupationByCIF?.get(intermediary.NationalId__c);

                        // Creamos la agrupación si no existe o la actualizamos si ha sido creada pero no insertada
                        ifAgrupationNotExistOrIntermediaryNotHaveCifRightCreateOrUpdate (agrupation, intermediary);

                        // Comprobamos si es necesario activar el estado de la cuenta de agrupación , si el estado del mediador esta activo
                        agrupation = ifAgrupationExistCheckStatus (agrupation, intermediary);
                    }
                }

                //Comprobar si hay agrupaciones que hay que desactivar el estado
                checkAgrupationsToInactiveStatus ();

                // Si hay agrupaciones a crear o a actualizar
                ifAgrupationListToUpdateNotEmptyCreateOrUpdateAgrupation();

                // Si hay mediadores a modificar
                if( !listIntermediariesToUpdate.isEmpty() ) 
                {
                    update listIntermediariesToUpdate;
                }
            }
        }
    }

    /**
     * Metodo que, para los Mediadores dados por parametro, calcula los Equipos de Cuenta que les corresponde segun
     * los campos de email que tengan rellenados y referenciando a usuarios de Salesforce
     * 
     * @param {List<Account> intermediaries} lista de Mediadores
     */
    public void assignIntermediaryAccountTeam(List<Account> intermediaries)
    {
        // Si hay mediadores...
        if( intermediaries != null && !intermediaries.isEmpty() ) 
        { 
            List<Account> intermediariesToProcess = intermediaries;

            // 
            Map<String, Object> fieldsToValue = intermediariesToProcess[0].getPopulatedFieldsAsMap();
            intermediariesToProcess= fieldsToValueStatus(fieldsToValue,intermediariesToProcess,intermediaries);
            
            // Para las operaciones de DML
            List<AccountTeamMember> atmsToUpsert = new List<AccountTeamMember>();
            List<AccountTeamMember> atmsToDelete = new List<AccountTeamMember>();
            Map<Id,Account> mapIntermediaryToUpdate = new Map<Id,Account>();

            // Recuperamos todos los usuarios, crea mapa de usuarios por Email
            this.findAllUsers();
            // Recuperamos todos los ATMs de las cuentas implicadas, crea mapa de ATMs por cuenta, rol y usuario
            this.findATMsByIntermediaries(intermediariesToProcess);

            String settingsrnName = this.rnNameNoATM;
            // Por cada mediador...
            for( Account i: intermediariesToProcess ) 
            {
                assignIntermediaryLoop(i,settingsrnName,atmsToDelete,mapIntermediaryToUpdate,atmsToUpsert);
            }

            if(!mapIntermediaryToUpdate.isEmpty())
            {
                update mapIntermediaryToUpdate.values();
            }

            // El orden es importante para que funcionen los casos en los que se cambia el rol de un usuario en un
            // mismo mediador
            this.deleteATMs(atmsToDelete);
            // Planes anuales - se guarda la relacion de ATMs eliminados para ver si hay que borrar algun plan anual
            // de un mediador que ya no tiene permisos sobre un usuario
            if( !atmsToDelete.isEmpty() ) {
                if( listDeletedAtms == null ) listDeletedAtms = new List<AccountTeamMember>();
                listDeletedAtms.addAll(atmsToDelete);
            }
            this.upsertATMs(atmsToUpsert);
        }
    }

    /**
     * Metodo que, para los Mediadores dados por parametro, calcula las relaciones con Contacto que les corresponde
     * segun los campos de email que tengan rellenados
     * 
     * @param {List<Account> intermediaries} lista de Mediadores
     * change : aberuete 07/11/2022
     * solucionar error duplicated id al aparecer el id para actualizar dos veces en la lista upsert cuando
     * una relacion tiene un rol y cambia a otro rol
     * @change: aberuete 13/04/2023 - Refactorizar método
     */
    public void assignIntermediaryContactRelation(List<Account> intermediaries)
    {
        if( intermediaries != null && !intermediaries.isEmpty() ) 
        {
            List<Account> intermediariesToProcess = intermediaries;
            // Se buscan los emails para mirar si el contacto ya existe
            Set<String> emailsMediadores = getEmailsMediadores (intermediariesToProcess);
            // Se recuperan los contactos para los emails encontrados
            this.findContactByEmail(emailsMediadores);

            // Se recuperan los objetos AccountContactRelation para los mediadores dados
            this.findACRsByIntermediaries(intermediariesToProcess);

            // Para cuando hay que crear el Contacto y relacionarlo con un rol
            position = 0;
            mapContactsToInsert = new Map<Integer, Contact>();
            // Para los roles de los contactos nuevos. Puede ser que un contacto tenga mas de un rol para un mediador
            mapRolesForContacts = new Map<Integer, List<String>>();
            // Para los contactos nuevos que tengan varios roles en un mediador
            mapContactPositionByEmail = new Map<String, Integer>();

            mapNewACRsByAccountAndContactIds = new Map<Id, Map<Id, AccountContactRelation>>();

            // Para las DMLs al final            
            acrsToUpsert = new List<AccountContactRelation> ();
            acrsToDelete = new List<AccountContactRelation> ();
            
            // Por cada mediador...
            for( Account intermediary: intermediariesToProcess ) 
            {
                // Recuperamos los campos que hay en memoria del objeto Account
                Map<String, Object> fieldsToValue = intermediary.getPopulatedFieldsAsMap();
                // ACRs de Contactos para el Mediador
                Map<ID, AccountContactRelation> mapACRsByContact = this.mapACRsByAccountContact?.get(intermediary.Id);
                // Por cada relacion de rol contact - campo mediador
                for( SDMAccountContactRelation__mdt rel: this.SettingsACR) 
                {
                    // Buscamos la etiqueta del rol si la hay
                    String roleLabel = this.settings.getACRRoleLabel(rel.Role__c);
                    // ACRs de Contactos para el Mediador
                    // ACRs de Roles para el Mediador
                    Map<String, AccountContactRelation> mapACRsByRoles = this.mapACRsByAccountRole?.get(intermediary.Id);
                    // ACR para el rol actual (puede no existir y ser nulo)
                    AccountContactRelation acrForRol = mapACRsByRoles?.get(roleLabel);
                    // Hara referencia al ACR que se debera borrar su relacion
                    acrToDelete = null;
                    // Se mira si tiene valor de email en el campo de mediador actual, sino se borra los ACRs que hubiera
                    String fieldValue = String.valueOf(fieldsToValue.get(rel.IntermediaryField__c));
                    //Tiene valor de Email
                    if( String.isNotBlank(fieldValue) ) 
                    { 
                        // Miramos si hay contacto para ese email
                        Contact contact = mapContactsByEmail?.get(fieldValue);
                        ifContactNotExistCreate (contact, rel, intermediary,fieldValue, fieldsToValue,acrForRol, roleLabel );
                        ifContactExistCheckRelationWithAccount (contact,intermediary,acrForRol, mapACRsByContact, roleLabel); 
                    } 
                    else 
                    { 
                        // Si el campo de email esta vacio y hay ACR se debera eliminar la relacion
                        acrToDelete = acrForRol;
                    }
                    //Si hay que borrar el ACR con el rol actual, por estar el campo de email vacio o por cambio de contacto para el rol
                    mapACRsByContact = checkACRSToDelete( roleLabel, mapACRsByContact);
                }
            }
            
            // Si hay contactos para insertar
            insertContactsIfThereAreToInsertAndAssignRolToAcrToUpsert ();
            // Borrar, Actualizar o insertar Acrs si hay
            deleteOrUpsertACRs();
        }
    }

    /**
     * Metodo que, para la lista de CIFs de agrupacion dados, calcula los equipos de cuenta que le corresponden
     * a la agrupacion por los hijos que tiene
     * 
     * @param {List<String> agrupationNationalIDs} lista de CIFs de agrupaciones
     * @change aberuete - 05/04/2023 - Refactorización del método
     */
    public void assignAgrupationAccountTeam(Set<String> agrupationNationalIDs)
    {
        // Si hay CIFs
        if( agrupationNationalIDs != null && !agrupationNationalIDs.isEmpty() ) 
        {
            // 1. Recuperamos los ATMs que hay para los CIFs dados, tanto los de las agrupaciones como los 
            // de los mediadores
            List<AccountTeamMember> atms = (new AccountTeamMemberSelector()).findByNationalIDs(agrupationNationalIDs);

            // Si hay ATMs
            if( atms != null && !atms.isEmpty() ) 
            {
                // A partir de esta lista, miraremos que usuarios ya tienen permisos en las agrupaciones y cuales no
                // pero que si los tienen los mediadores hijos hay que crearselos

                // Guardara los UserIds de las agrupaciones por CIF
                mapExistingAgrupationUsers = new Map<String, Set<Id>>(); 
                // Guardara los id de ATM de las agrupaciones por CIF y por UserId
                mapExistingATMsByNationalIdAndUserId = new Map<String, Map<Id, Id>>();

                // Guardara los UserIds de los mediadores por CIF
                mapExistingIntermediaryUsers = new Map<String, Set<Id>>(); 
                // Guardara los id de ATM de los mediadores por CIF y por UserId
                mapExistingInterATMsByNationalIdAndUserId = new Map<String, Map<Id, AccountTeamMember>>();


                // Lista de ATMs a crear
                atmsToCreate = new List<AccountTeamMember>();
                // Lista de ATMs existentes de las agrupaciones a borrar
                atmsToDeleteInAgr = new List<AccountTeamMember>();

                // 2. Primero miramos los usuarios (a traves del atm) existentes tanto para las agrupaciones 
                // como para los mediadores

                // Por cada Account Team Member (atm)...
                for(AccountTeamMember atm: atms) 
                {
                    generateMapByATM (atm);
                }

                // 3. Despues comparamos la lista de Usuarios de los mediadores con los ya existentes de las
                // agrupaciones para saber cuales son nuevos y cuales ya existen

                forUserIfAtmAGRNotExistAndExistAtmIntermediaryCreate();

                // 4. Despues miramos los usuarios que quedan de las agrupaciones y que deberian ser los que ya no
                // existen en los mediadores y por tanto hay que borrar

                ifUsersLeftInAtmAgrRemoveATM ();

                this.deleteATMs(atmsToDeleteInAgr);
                this.upsertATMs(atmsToCreate);
            }
        }
    }

    /**
     * Metodo que envia la siguiente notificacion a todos los usuarios que se les ha cambiado la visibilidad
     * del mediador
     * 
     * @change amiranda 21/12/2022 Se modifica el developer name de la vista de lista que debe abrir el enlace de la notificación
     * @param {Set<Id> userIds} Lista de usuario receptores de la notificacion
     */
    public void sendNotification(Set<Id> userIds)
    {
        if( userIds != null && !userIds.isEmpty() ) {
            String title = this.notificationTitle;
            String bodyContent = this.notificationBody;

            Notification notif = new Notification(Notification.notificationType.SDMAlert);
            // Permite abrir la seccion de Cuentas, listview Mediadores de mi equipo
            notif.addPageReference('standard__objectPage', 'Account', 'list', 'Mediadores_de_mi_equipo');
            // Convertimos la lista de ids de usuario a string
            Set<String> stringSet = new Set<String>( (List<String>)new List<Id>( userIds ) );
            notif.send(stringSet, title, bodyContent);
        }
    }

    /**
     * Metodo que elimina los ATMs que haya de Roles inhabilitados
     */
    public void removeATMsForInactiveRoles()
    {
        List<String> inactiveRoles = new List<String>();

        // Miramos en la configuracion que roles estan Inactivos
        for( SDMAccountTeamRole__mdt s: this.SettingsATM ) {
            if( s.Status__c == ATM_ROL_STATUS_INACTIVE ) {
                // Recumperamos la etiqueta del rol
                String roleLabel = this.settings.getATMRoleLabel(s.Role__c);

                // Lo marcamos para borrar
                inactiveRoles.add(roleLabel);
            }
        }

        // Si hay roles inactivos...
        if( !inactiveRoles.isEmpty() ) {
            // Recuperamos los ATMs para esos roles
            List<AccountTeamMember> atmsToDelete = (new AccountTeamMemberSelector()).findByRoles(inactiveRoles);
            // Recorremos los ATMs recuperados para incluir a los usuarios en la notificacion de cambio de
            // visibilidad
            for(AccountTeamMember atm: atmsToDelete) {
                this.addUserToNotify(atm.UserId);
            }

            // Borrarmos los ATMs
            this.deleteATMs(atmsToDelete);
        }
    }

     /**
    * @description Método que comprueba que en el primer mediador no faltan campos por informar, en caso contrario informarlos
    * @author aberuete 
    * @date 27-03-2023 
    * @param List<Account> intermediaries: Lista de cuentas de intermediario
    * @param Map<String, Object> fieldsToValue : Mapa de valores y cuenta 
    **/
    @TestVisible
    private static List<Account> ifAnyIntermediaryFieldIsMissingPopulateAgain (List<Account> intermediaries, Map<String, Object> fieldsToValue)
    {
        List<Account> intermediariesToProcess = intermediaries;

        Boolean containNationalId = fieldsToValue.containsKey(INTERMEDIARY_FIELD_NATIONALID);
        Boolean containParentId = fieldsToValue.containsKey(INTERMEDIARY_FIELD_PARENTID);
        Boolean containName = fieldsToValue.containsKey(INTERMEDIARY_FIELD_NAME);
        Boolean containStatus = fieldsToValue.containsKey(INTERMEDIARY_FIELD_STATUS);
        Boolean containStatusIntermediary = fieldsToValue.containsKey(INTERMEDIARY_FIELD_STATUS_INTERMEDIARY);

        if( !containNationalId || !containParentId || !containName || !containStatus || !containStatusIntermediary)
        {
            Set<String> fields = new Set<String>
            {
                INTERMEDIARY_FIELD_NATIONALID, 
                INTERMEDIARY_FIELD_PARENTID, 
                INTERMEDIARY_FIELD_NAME, 
                INTERMEDIARY_FIELD_STATUS, 
                INTERMEDIARY_FIELD_STATUS_INTERMEDIARY
            };

            intermediariesToProcess = new AccountsSelector().findWithFields(intermediaries, fields);
        }
        
        return intermediariesToProcess;
    }

    /**
    * @description Método que añade la cuenta de agrupación al mapa para crear cuentas si la cuenta de agrupación no existe.
    * En caso de que se haya creado pero todavía no se ha insertado, se comprueba si el mediador está activo para actualizar 
    * el estado de la cuenta de agrupación a activo.
    * @author aberuete 
    * @date 27-03-2023 
    * @param Account intermediary : Cuenta de intermediario  
    **/
    @TestVisible
    private  Integer ifParentNotExistCreateOrUpdate (Account intermediary)
    {
        // Intentamos recuperar la posicion de la agrupacion si ya existe
        Integer agrpPos = this.mapAgrupationPosByCIF.get(intermediary.NationalId__c);
        // Si es la primera vez y no existe se crea
        if( agrpPos == null ) 
        {
            agrpPos = this.positionAgruptation;
            this.positionAgruptation++;

            // Si no se ha recuperado ya, recuperamos el id de tipo de registro de agrupacion
            if( this.rtAgrupationId == null ) this.rtAgrupationId = new AccountsSelector().rtAgrupationId;

            // Creamos a partir de los campos del mediador
            Account newAgrupation =  new Account(
                NationalID__c= intermediary.NationalID__c,
                Name= intermediary.Name,
                RecordTypeId= this.rtAgrupationId,
                AGRNationalId__c = 'AGR-'+intermediary.NationalID__c
            );

            // Si el intermediario está activo se informa el campo Status__c de la agrupación
            if (intermediary.StatusIntermediary__c == INTERMEDIARY_STATUS_ACTIVE)
            {
                newAgrupation.Status__c = intermediary.Status__c;
            }

            this.mapAgrupationByPos.put(agrpPos, newAgrupation);

            // Lo guardamos por si lo necesitan otros mediadores con el mismo CIF
            this.mapAgrupationPosByCIF.put(intermediary.NationalID__c, agrpPos);
        } 
        // Si la agrupación ya se ha creado (todavía no se ha insertado)
        else 
        { 
            Account agrupationByPos = this.mapAgrupationByPos?.get(agrpPos);

            // Si no se ha informado el campo 'Status__c' y el intermediario está activo
            if (agrupationByPos != null &&
                String.isBlank(agrupationByPos.Status__c) && 
                intermediary.StatusIntermediary__c == INTERMEDIARY_STATUS_ACTIVE)
            {
                agrupationByPos.Status__c = intermediary.Status__c;
            }
        } 

        return agrpPos;
    }

     /**
    * @description Método que añade la cuenta de agrupación al mapa para crear cuentas si la cuenta de agrupación no existe. 
    * En el caso contario, si el intermediario no tiene la cuenta de agrupación correcta, actualiza el parentId al correcto y añade al intermediario a la lista para actualizar. 
    * @author abereute 
    * @date 27-03-2023 
    * @param Account agrupation : Cuenta de tipo agrupación mediador
    * @param Account intermediary: Cuenta de tipo intermediario
    **/
    @TestVisible
    private void ifAgrupationNotExistOrIntermediaryNotHaveCifRightCreateOrUpdate (Account agrupation, Account intermediary)
    {
        if( agrupation?.Id == null )
        {
            // Si no se ha creado todavía se crea, si se ha creado pero no insertado se actualiza su estado
            Integer agrpPos = ifParentNotExistCreateOrUpdate (intermediary);
            // Creamos la referencia al mediador
            Account intermediaryRefer = new Account(
                Id= intermediary.Id
            );
            // Lo metemos en la lista de mediadores de la agrupacion en la posicion que corresponda
            List<Account> listIntermediaries = mapIntermediaryByPos.get(agrpPos);
            if( listIntermediaries == null ) 
            {
                listIntermediaries = new List<Account>();
                mapIntermediaryByPos.put(agrpPos, listIntermediaries);
            }
            listIntermediaries.add(intermediaryRefer);

            // Lo metemos tambien en la lista de mediadores a modificar
            listIntermediariesToUpdate.add(intermediaryRefer);
        }
        // SI existe
        else if( intermediary.ParentId == null || intermediary.ParentId != agrupation?.Id ) 
        { 
            // Si existe la agrupacion y el Mediador no tiene agrupacion o es diferente a la actual, actualizamos
            // Poner para modificar
            listIntermediariesToUpdate.add(new Account(
                Id= intermediary.Id,
                ParentId= agrupation.Id
            ));
        }
        // Añadimos el CIF a la lista de cifs de agrupacion para que se recalcule el ATM si es
        // necesario
        this.addNationalId(intermediary.NationalID__c);
    }

    /**
    * @description Método que actualiza el estado de la cuenta de agrupación si el intermediario está activo 
    * en caso contrario, se añade al mapa de cuentas a comprobar 
    * @author aberuete 
    * @date 27-03-2023 
    * @param Account agrupation : Cuenta de agrupación de mediador
    * @param Account intermediary: Cuenta de intermediario
    **/
    @TestVisible
    private Account ifAgrupationExistCheckStatus (Account agrupation, Account intermediary)
    {
        // Si existe la agrupación en el sistema
        if (String.isNotBlank(agrupation?.Id)) 
        { 
            // Si el intermediario se activa y no estaba activado previamente
            if (String.isBlank(agrupation.Status__c) && intermediary.StatusIntermediary__c == INTERMEDIARY_STATUS_ACTIVE)
            {
                // Se activa la agrupación y se añade al mapa para actualizar
                agrupation.Status__c = intermediary.Status__c;
                agrupationToUpdateById.put(agrupation.Id, agrupation);

                // Si estuviese en el mapa de agrupaciones a desactivar, se elimina
                agrupationToCheckById.remove(agrupation.Id);
            }
            else if (!agrupationToUpdateById.containsKey(agrupation.Id) &&
                     !agrupationToCheckById.containsKey(agrupation.Id) &&
                     String.isNotBlank(agrupation.Status__c) &&
                     intermediary.StatusIntermediary__c == INTERMEDIARY_STATUS_INACTIVE )
            {
                // Se marca la agrupación para checkear si hay que desactivarla
                agrupationToCheckById.put(agrupation.Id, agrupation);
            }
        } 
        return agrupation;
    }

    /**
    * @description Método que comprueba si algún mediador de una agrupación está activo, 
    * en caso de que todos estén inactivos se actualiza el estado de la cuenta de agrupación para que esté inactiva.
    * @author aberuete 
    * @date 27-03-2023  
    **/
    @TestVisible
    private void checkAgrupationsToInactiveStatus ()
    {
        if (!agrupationToCheckById.isEmpty())
        {
            this.findIntermediariesByParentId(agrupationToCheckById.keySet());
            
            // Por cada agrupación se comprueba si alguno de sus mediadores está activo.
            for (Id agrupationId : agrupationToCheckById.keySet())
            {
                List<Account> intermediariesToCheck = this.intermediariesByParentId.get(agrupationId);

                Boolean someIntermediaryIsActive = false;
                Integer intermediariesToCheckPos = 0;

                while (intermediariesToCheck != null && 
                        !intermediariesToCheck.isEmpty() &&
                        !someIntermediaryIsActive &&
                        intermediariesToCheckPos < intermediariesToCheck.size())
                {
                    someIntermediaryIsActive = (intermediariesToCheck.get(intermediariesToCheckPos).StatusIntermediary__c == INTERMEDIARY_STATUS_ACTIVE);
                    intermediariesToCheckPos++;
                }

                // Si no hay ningún intermediario activo, se desactiva la agrupación
                if (!someIntermediaryIsActive)
                {
                    Account agrupationToCheck = agrupationToCheckById.get(agrupationId);
                    agrupationToCheck.Status__c = '';

                    agrupationToUpdateById.put(agrupationToCheck.Id, agrupationToCheck);
                }
            }
        }
    }

    /**
    * @description Método que inserta o actualiza las cuentas de agrupación. 
    * En caso de que haya creado nuevas cuentas revisa si tiene que actualizar el parentId de alguno de los mediadores
    * @author aberuete 
    * @date 27-03-2023 
    **/
    @TestVisible
    private void ifAgrupationListToUpdateNotEmptyCreateOrUpdateAgrupation () 
    {
        // Si hay agrupaciones a crear o a actualizar
        if( !mapAgrupationByPos.isEmpty() ||  !agrupationToUpdateById.isEmpty()) 
        {
            List<Account> agrupationToUpsert = new List<Account>();
            agrupationToUpsert.addAll(mapAgrupationByPos.values());
            agrupationToUpsert.addAll(agrupationToUpdateById.values());
            upsert agrupationToUpsert;

            // Para cada agrupacion nueva...
            for(Integer key: mapAgrupationByPos.keySet()) 
            {
                // Recuperamos el id recien generado
                Account agrp = mapAgrupationByPos.get(key);
                // Y para cada mediador asociado a la agrupacion...
                for(Account a: mapIntermediaryByPos.get(key)) 
                {
                    // Asignamos el id de la agrupacion al campo de referencia
                    a.ParentId = agrp.Id;
                }

                // Se añaden las nuevas agrupaciones al mapa de agrupaciones por si mediadores de la misma
                // agrupacion se procesan en diferente batch...
                this.mapAgrupationByCIF.put(agrp.NationalID__c, agrp);

                // Añadimos el CIF a la lista de cifs de agrupacion para que se recalcule el ATM si es
                // necesario
                this.addNationalId(agrp.NationalID__c);
            }
        }
    }

    /**
     * Se comprueba si el primer Mediador tiene el campo Status
     * @author lrodriguez6@seidor.es
     * @date 16/03/2023
     * @param Map<String,Object>
     */
    private List<Account> fieldsToValueStatus(Map<String,Object> fieldsToValue,List<Account> intermediariesToProcess,List<Account> intermediaries)
    {
        if( !fieldsToValue.containsKey(INTERMEDIARY_FIELD_STATUS_INTERMEDIARY) || 
            !fieldsToValue.containsKey(INTERMEDIARY_FIELD_NATIONALID) ||
            !fieldsToValue.containsKey(INTERMEDIARY_FIELD_INACTIVE_NONEXISTENT_USERS)) 
            {
                Set<String> fields = this.SettingsATMFields;
                fields.add(INTERMEDIARY_FIELD_STATUS_INTERMEDIARY);
                fields.add(INTERMEDIARY_FIELD_NATIONALID);
                fields.add(INTERMEDIARY_FIELD_INACTIVE_NONEXISTENT_USERS);
 
                if( this.rnFieldNoATM != null ) fields.add(this.rnFieldNoATM);
                    intermediariesToProcess = new AccountsSelector().findWithFields(intermediaries, fields);
 
            }
            return intermediariesToProcess;
    }
 
    /**
    * assignIntermediaryAccountTeam para cada mediador recibido
    * @author lrodriguez6@seidor.es
    * @date 16/03/2023
    * @param Account
    */
    private void assignIntermediaryLoop (Account i,String settingsrnName, List<AccountTeamMember> atmsToDelete,Map<Id,Account> mapIntermediaryToUpdate,List<AccountTeamMember> atmsToUpsert)
    {
        // Se guarda en una variable temporal el valor actual
        String usersInfoPrevValue = i.InactiveOrNonExistentUsers__c;
 
        String rnName = null;
        if( this.rnFieldNoATM != null ) rnName = (String)i.get(rnFieldNoATM);
 
        if( i.StatusIntermediary__c == INTERMEDIARY_STATUS_INACTIVE 
            || (rnName != null && settingsrnName != null && rnName.equalsIgnoreCase(settingsrnName)) ) 
        { 
            //---- Es inactivo o tiene el valor adecuado en el campo RN
            List<AccountTeamMember> allATMs = null;
            // Recuperamos todos los ATM para la cuenta que haya, independientemente del rol y usuario
            List<Map<ID, AccountTeamMember>> listMapAtmByUserId = this.mapATMsByAccountRolUser?.get(i.Id)?.values();
 
            listMapAtmByUserIdAddNotifyDelete(listMapAtmByUserId,allATMs,atmsToDelete,i);
                 
            // Si el intermediario está inactivo eliminamos la información del campo
            i.InactiveOrNonExistentUsers__c = null;
        } 
        else if( i.StatusIntermediary__c == INTERMEDIARY_STATUS_ACTIVE ) 
        { 
            //-------------------------------------------- Si el mediador es Activo
            List<String> usersInfo = new List<String>();
            List<SDMAccountTeamRole__mdt> listAccountTeamRole= this.SettingsATM;
 
            accountTeamRoleLoop(listAccountTeamRole,i,mapIntermediaryToUpdate,atmsToDelete,usersInfo,atmsToUpsert);
 
            // Por cada rol-campo mediador
            i.InactiveOrNonExistentUsers__c = String.join(usersInfo, '\n');
        }
 
        // Si el valor del campo 'InactiveOrNonExistentUsers__c' se ha modificado se añade el mediador a modificar
        if (usersInfoPrevValue != i.InactiveOrNonExistentUsers__c && mapIntermediaryToUpdate.get(i.Id)==null)
        {
            mapIntermediaryToUpdate.put(i.Id,i);
        }
         
    }
 
    /**
    * Se añaden los usuarios para ser notificados y posteriormente borrados
    * @author lrodriguez6@seidor.es
    * @date 16/03/2023
    * @param Map<ID, AccountTeamMember>
    */
    private void listMapAtmByUserIdAddNotifyDelete(List<Map<ID, AccountTeamMember>> listMapAtmByUserId,List<AccountTeamMember> allATMs, List<AccountTeamMember> atmsToDelete,Account i)     
    {
        if( listMapAtmByUserId != null && !listMapAtmByUserId.isEmpty() ) 
        {
            allATMs = new List<AccountTeamMember>();
            for(Integer x=0,y=listMapAtmByUserId.size(); x < y; x++) 
            {
                allATMs.addAll(listMapAtmByUserId[x].values());
                 
                // Añadimos a los usuarios para notificarlos al final del batch
                this.addUsersToNotify(listMapAtmByUserId[x].keySet());
            }
        }
        // Y los ponemos para borrar
        if( allATMs != null && !allATMs.isEmpty() ) 
        {
            atmsToDelete.addAll(allATMs);

            // Añadimos el CIF para que se recalculen los ATMs del padre (agrupacion)
            this.addNationalId(i.NationalId__c);
        }
    }     
 
    /**
    * Proceso para cada rol-campo mediador  
    * @author lrodriguez6@seidor.es
    * @date 16/03/2023
    * @param SDMAccountTeamRole__mdt
    */
    private void accountTeamRoleLoop(List<SDMAccountTeamRole__mdt> listAccountTeamRole,Account i,Map<Id,Account> mapIntermediaryToUpdate,List<AccountTeamMember> atmsToDelete,List<String> usersInfo,List<AccountTeamMember> atmsToUpsert)
    {
        for( SDMAccountTeamRole__mdt s: listAccountTeamRole ) 
        {
            if( String.isNotBlank(s.IntermediaryField__c) && s.Status__c == ATM_ROL_STATUS_ACTIVE ) 
            {
                // Buscamos la etiqueta del rol si la hay
                String roleLabel = this.settings.getATMRoleLabel(s.Role__c);
 
                // Recuperamos el ATM, si existe, para esa cuenta y rol
                Map<ID, AccountTeamMember> mapAtmByUserId = this.mapATMsByAccountRolUser?.get(i.Id)?.get(roleLabel);
 
                // Y recuperamos el valor del campo, que deberia ser un email de usuario de Salesforce
                String fieldValue = (String)i.get(s.IntermediaryField__c);
 
                // Se intenta recuperar el usuario en base al email
                User u = mapUsersByEmail?.get(fieldValue);
 
                // Si el valor del campo es vacio o con el valor VACANT o el usuario no existe
                // o el usuario no existe, y si tiene ATMs, se ponen los ATMs para borrar
                if (String.isBlank(fieldValue) || 
                    fieldValue.equalsIgnoreCase(INTERMEDIARY_VACANT) ||
                    u == null || 
                    !u.isActive) 
                {
                    AccountTeamMemberUtil.emptyIntermediaryWithAccountTeamMembersName(i, s.IntermediaryNameField__c);
                    mapIntermediaryToUpdate.put(i.Id,i);
                    List<String> listString= new List<String> ();
                    listString.add(fieldValue);
                    listString.add(INTERMEDIARY_VACANT);
                    listString.add(roleLabel);
                    fieldNullOrUserNull(listString,u,mapAtmByUserId,atmsToDelete,usersInfo,i);
                } 
                else if(u != null) 
                { 
                    // Si el usuario existe
                 
                    AccountTeamMemberUtil.updateIntermediaryWithAccountTeamMembersName(i,s.IntermediaryNameField__c,u);
                    mapIntermediaryToUpdate.put(i.Id,i);
                    // Se recoge el ATM para ese usuario (puede que no exista y sea nulo)
                    AccountTeamMember atmOld = mapAtmByUserId?.get(u.Id);
 
                    // Si aun no existe...
                    userNotNull(atmOld,mapAtmByUserId,atmsToDelete,atmsToUpsert,i,u,roleLabel);
                }
            }
        }
    }
 
    /**
    * Si el valor del campo es vacio o con el valor VACANT o el usuario no existe 
    * @author lrodriguez6@seidor.es
    * @date 16/03/2023
    * @param SDMAccountTeamRole__mdt
    */
    private void fieldNullOrUserNull(List<String> listString,User u,Map<Id,AccountTeamMember> mapAtmByUserId,List<AccountTeamMember> atmsToDelete,List<String> usersInfo,Account i)
    {
        String fieldValue=listString[0];
        String iNTERMEDIARY_VACANT=listString[1];
        String roleLabel= listString[2];
 
        if (String.isNotBlank(fieldValue) && !fieldValue.equalsIgnoreCase(iNTERMEDIARY_VACANT))
        {
            // Formato del campo 'InactiveOrInexistentUsers__c'
            String userInfo = roleLabel + ' - ' + fieldValue;
 
            if (u == null) // Si el usuario no existe
            {
                userInfo += ' - no existe';
            }
            else // Si el usuario está inactivo
            {
                userInfo += ' - inactivo';
            }
 
            usersInfo.add(userInfo);
        } 
                     
        if( mapAtmByUserId != null && !mapAtmByUserId.values().isEmpty() )
        {
            atmsToDelete.addAll(mapAtmByUserId.values());
                         
            // Añadimos el CIF para que se recalculen los ATMs del padre (agrupacion)
            this.addNationalId(i.NationalId__c);
 
            // Añadimos los usuarios para notificarlos al final del batch
            this.addUsersToNotify(mapAtmByUserId.keySet());
        }
    }
 
    /**
    * Si el usuario existe 
    * @author lrodriguez6@seidor.es
    * @date 16/03/2023
    * @param SDMAccountTeamRole__mdt
    */
    private void userNotNull(AccountTeamMember atmOld,Map<Id,AccountTeamMember> mapAtmByUserId,List<AccountTeamMember> atmsToDelete,List<AccountTeamMember> atmsToUpsert,Account i,User u,String roleLabel)
    {
        if( atmOld == null ) 
        {
            // Como solo deberia haber un ATM por rol y no hay para ese usuario, 
            // se mira si hay otros y si los hay se ponen a borrar. No deja modificar los actuales
            if( mapAtmByUserId != null && !mapAtmByUserId.isEmpty()) 
            {
                atmsToDelete.addAll(mapAtmByUserId.values());
                // Añadimos los usuarios para notificarlos al final del batch
                this.addUsersToNotify(mapAtmByUserId.keySet());
            }
 
            AccountTeamMember atm = new AccountTeamMember(
                AccountId= i.Id,
                userId= u.Id,
                TeamMemberRole= roleLabel,
                AccountAccessLevel= ATM_ACCOUNT_ACCESS_LEVEL_EDIT,
                ContactAccessLevel= ATM_CONTACT_ACCESS_LEVEL,
                CaseAccessLevel= ATM_CASE_ACCESS_LEVEL,
                OpportunityAccessLevel= ATM_OFFER_ACCESS_LEVEL
            );
 
            atmsToUpsert.add(atm);
 
            // Añadimos el CIF para que se recalculen los ATMs del padre (agrupacion)
            this.addNationalId(i.NationalId__c);
            // Añadimos el usuario para notificarlo al final del batch
            this.addUserToNotify(u.Id);
        }
    }

    /**
    * @description Método que rellena los diferentes mapas de account team members de agrupación e intermediario
    * @author aberuete 
    * @date 05-04-2023 
    * @param AccountTeamMember atm : miembro de equipo de cuentas
    **/
    @testvisible
    private void generateMapByATM (AccountTeamMember atm)
    {
        String nationalId = atm.Account.NationalId__c;
        Id userId = atm.UserId;
        if( atm.Account.RecordType.DeveloperName == AccountsSelector.RT_NAME_AGRUPATION ) 
        {
            // Es ATM de Agrupacion
            // Incluimos el usuario para ese CIF en el mapa de usuarios existentes
            Set<Id> userIds = this.mapExistingAgrupationUsers.get(nationalId);
            if( userIds == null ) 
            {
                userIds = new Set<Id>();
                this.mapExistingAgrupationUsers.put(nationalId, userIds);
            }
            userIds.add(userId);

            // Nos guardamos tambien el id del atm por si luego hay que borrarlo
            Map<Id, Id> mapATMsByUserId = this.mapExistingATMsByNationalIdAndUserId.get(nationalId);
            if( mapATMsByUserId == null ) 
            {
                mapATMsByUserId = new Map<Id, Id>();
                this.mapExistingATMsByNationalIdAndUserId.put(nationalId, mapATMsByUserId);
            }
            mapATMsByUserId.put(userId, atm.Id);                    
            } 
        else 
        { 
            // Es ATM de Mediador hijo
            // Incluimos el usuario para ese CIF en el mapa de usuarios existentes
            Set<Id> userIds = this.mapExistingIntermediaryUsers.get(nationalId);
            if( userIds == null ) 
            {
                userIds = new Set<Id>();
                this.mapExistingIntermediaryUsers.put(nationalId, userIds);
            }
            userIds.add(userId);

            // Nos guardamos tambien el id del atm por si luego hay que borrarlo
            Map<Id, AccountTeamMember> mapATMsByUserId = this.mapExistingInterATMsByNationalIdAndUserId.get(nationalId);
            if( mapATMsByUserId == null ) 
            {
                mapATMsByUserId = new Map<Id, AccountTeamMember>();
                this.mapExistingInterATMsByNationalIdAndUserId.put(nationalId, mapATMsByUserId);
            }
            mapATMsByUserId.put(userId, atm);
        }
      }

    /**
    * @description Método que se encarga de crear los miembros de los equipos de cuentas que falten para las cuentas de agrupación
    * @author aberuete 
    * @date 05-04-2023 
    **/
    @testvisible
    private void forUserIfAtmAGRNotExistAndExistAtmIntermediaryCreate()
    {
        // Por cada CIF de agrupacion...
        for(String key: this.mapExistingIntermediaryUsers.keySet()) 
        {
            Set<id> userIds = mapExistingAgrupationUsers.get(key);

            // Por cada UserId del mediador...
            for(Id userId: this.mapExistingIntermediaryUsers.get(key)) 
            {
                if(userIds == null || !userIds.contains(userId) ) 
                {
                    AccountTeamMember intermediaryAtm = this.mapExistingInterATMsByNationalIdAndUserId.get(key)?.get(userId);

                    if( intermediaryAtm != null && intermediaryAtm.Account?.ParentId != null ) 
                    {
                        // Es nuevo
                        AccountTeamMember newAtm = new AccountTeamMember(
                            AccountId= intermediaryAtm.Account.ParentId,
                            UserId= userId,
                            TeamMemberRole= intermediaryAtm.TeamMemberRole,
                            AccountAccessLevel= ATM_ACCOUNT_ACCESS_LEVEL_EDIT,
                            ContactAccessLevel= ATM_CONTACT_ACCESS_LEVEL,
                            CaseAccessLevel= ATM_CASE_ACCESS_LEVEL,
                            OpportunityAccessLevel= ATM_OFFER_ACCESS_LEVEL
                        );
                        this.atmsToCreate.add(newAtm);
                        // Añadimos el usuario para notificarlo al final del batch, aunque probablemente
                        // ya este incluido por los cambios en los equipos de cuenta de los mediadores
                        this.addUserToNotify(userId);
                    }
                    } 
                    else 
                    {
                        // Ya existe, se quita para dejar en la agrupacion los que no existen ya en los 
                        // mediadores y por tanto habra que borrar
                        userIds.remove(userId);
                    }
                }
            }
    }

    /**
    * @description Método que se encarga de borrar los miembros de los equipos de cuentas de las cuentas de agrupación
    * @author aberuete 
    * @date 05-04-2023 
    **/
    @testvisible
    private void ifUsersLeftInAtmAgrRemoveATM ()
    {
        // Por cada CIF de agrupacion...
        for(String key: this.mapExistingAgrupationUsers.keySet()) 
        {
            // Por cada UserId de agrupacion...
            for(Id userId: this.mapExistingAgrupationUsers.get(key)) 
            {
                // Buscamos el Id de ATM
                Id atmId = this.mapExistingATMsByNationalIdAndUserId.get(key)?.get(userId);
                // Y si lo hay lo ponemos a borrar
                if( atmId != null ) 
                {
                    this.atmsToDeleteInAgr.add(new AccountTeamMember(Id= atmId));
                    // Añadimos el usuario para notificarlo al final del batch, aunque probablemente
                    // ya este incluido por los cambios en los equipos de cuenta de los mediadores
                    this.addUserToNotify(userId);
                }
            }
        }
    }

    /**
    * @description Método que obtiene los emails de los mediadores asociados a los roles de la relación contacto - cuenta
    * @author aberuete 
    * @date 13-04-2023 
    * @param List<Account> intermediariesToProcess : cuentas de intermediario
    **/
    @testvisible
    private Set<String> getEmailsMediadores (List<Account> intermediariesToProcess)
    {
        Set<String> emailsMediadores = new Set<String>();

        for( Account i: intermediariesToProcess ) 
        {
            // Recuperamos los campos que hay en memoria del objeto Account
            Map<String, Object> fieldsToValue = i.getPopulatedFieldsAsMap();
            // Por cada relacion de rol contact - campo mediador, miramos si el Account tiene el campo informado
            for( SDMAccountContactRelation__mdt rel: this.SettingsACR) 
            {
                String fieldValue = (String)fieldsToValue?.get(rel.IntermediaryField__c);
                if( String.isNotBlank(fieldValue) ) 
                {
                    emailsMediadores.add(fieldValue);
                }
            }
        }
        return emailsMediadores;
    }

    /**
    * @description Método que crea un contacto si no existe
    * @author aberuete 
    * @date 13-04-2023 
    * @param Contact contact : contacto 
    * @param SDMAccountContactRelation__mdt rel : metadato para guardar los campos de los emails de cuenta relacionados con el rol del contacto
    * @param Account intermediary : cuenta de intermediario
    * @param String fieldValue : email de la cuenta 
    * @param Map<String, Object> fieldsToValue : Mapa que contiene los campos de la cuenta
    * @param AccountContactRelation acrForRol : relación entre la cuenta y el contacto
    * @param String roleLabel : rol del contacto para la cuenta
    **/
    @testvisible
    private void ifContactNotExistCreate (Contact contact, SDMAccountContactRelation__mdt rel, Account intermediary,String fieldValue, Map<String, Object> fieldsToValue, AccountContactRelation acrForRol, String roleLabel )
    {
        // Si NO hay contacto, se pone para crear el contacto que creara el ACR
        if( contact == null ) 
        { 
            // Si hay ACR se tendra que eliminar la relacion (puede que sea nulo)
            acrToDelete = acrForRol;

            // Miramos si el contacto ya se ha creado previamente
            Integer contactPosition = mapContactPositionByEmail?.get(fieldValue);

            if( contactPosition == null ) 
            {
                // 17.08.2021 - nts (agonzalezisasi) - bug sdm-361 - Limite de caracteres en el nombre del contacto
                String contactName = rel.NameText__c + ' ' + intermediary.Name;

                // Se preparan los datos del nuevo contacto
                Contact newContact = new Contact(
                        AccountId= intermediary.Id,
                        LastName= contactName.left(CONTACT_NAME_MAX_SIZE),
                        RecordTypeId= new ContactsSelector().rtContactId,
                        Email= fieldValue
                );
                // Si es el principal, se copia tambien el telefono
                if( rel.IntermediaryField__c.equals(AccountsSelector.SDM_MAINEMAIL_FIELD) && fieldsToValue.containsKey(AccountsSelector.SDM_MAINMOBILEPHONE_FIELD) ) 
                {
                    newContact.MobilePhone = String.valueOf(fieldsToValue.get(AccountsSelector.SDM_MAINMOBILEPHONE_FIELD));
                }
                
                // Se preparan los mapas para la nueva relacion entre el contacto, la cuenta y el rol...
                // mapa de contactos
                mapContactsToInsert.put(position, newContact);
                // mapa para indicar la posicion del nuevo contacto por su email
                mapContactPositionByEmail.put(fieldValue, position);
                contactPosition = position;

                // Incrementamos el contador de posiciones
                position++;
            }

            // mapa de relaciones de roles por posicion del contacto
            List<String> rols = mapRolesForContacts.get(contactPosition);
            if( rols == null ) 
            {
                rols = new List<String>();
                mapRolesForContacts.put(contactPosition, rols);
            }
            rols.add(roleLabel);
        }     
    }

    /**
    * @description Método que verifica si existe relación con el rol correspondiente entre la cuenta y el contacto. En caso de que no existe ninguna relación la crea.
    * En el caso de que exista una relación pero con un rol incorrecto la actualiza. 
    * Y por último en caso de que la relación entre la cuenta y el rol es con un contacto distinto se eliminará la relación.
    * @author aberuete 
    * @date 13-04-2023 
    * @param Contact contact : contacto 
    * @param Account intermediary : cuenta de intermediario
    * @param AccountContactRelation acrForRol : relación entre la cuenta y el contacto
    * @param Map<ID, AccountContactRelation> mapACRsByContact : Mapa de ids de contactos con la relación entre contacto y cuenta
    * @param String roleLabel : rol del contacto para la cuenta
    **/
    @testvisible
    private void ifContactExistCheckRelationWithAccount (Contact contact,Account intermediary, AccountContactRelation acrForRol, Map<ID, AccountContactRelation> mapACRsByContact,String roleLabel)
    {
        if (contact != null) 
        { 
            // Si ya hay ACR pero no es para el contacto actual se debera eliminar la relacion
            if( acrForRol != null && acrForRol.ContactId != contact.Id ) acrToDelete = acrForRol;

            // Miramos si ya tienen relacion ACR para el contacto
            AccountContactRelation acr = mapACRsByContact?.get(contact.Id);
            List<String> roles = acr?.Roles?.split(';');

            // Si no tiene ACR, o no con ese rol, ponemos a crear o modificar la relacion
            if( acr == null || roles == null || !roles.contains(roleLabel) ) 
            {
                Boolean isIncluded = false;
                // Vemos si el mismo usuario tiene otro nuevo rol para el mismo mediador
                AccountContactRelation acrNew = mapNewACRsByAccountAndContactIds?.get(intermediary.Id)?.get(contact.Id);
                if( acrNew != null ) 
                {
                    isIncluded = true;
                    acr = acrNew;
                    roles = acr?.Roles?.split(';');
                }
                
                // Preparamos la lista de roles
                if( roles == null ) roles = new List<String>();
                roles.add(roleLabel);
                acr = ifNotExistRelationContactWithAccountCreate (isIncluded, acr, intermediary, contact);
                // Indicamos la nueva lista de roles, ya sea para la primera vez o para las sucesivas 
                acr.Roles = String.join(roles, ';');
            }
        }
    }

    /**
    * @description Método que crea la relación entre el contacto y la cuenta si no existe.
    * @author aberuete 
    * @date 13-04-2023 
    * @param Boolean isIncluded : Booleano que indica si la relación ya se encuentra en el mapa de acrs to upsert 
    * @param Contact contact : Contacto 
    * @param Account intermediary : Cuenta de intermediario
    * @param AccountContactRelation acr : Relación entre la cuenta y el contacto
    **/
    private AccountContactRelation ifNotExistRelationContactWithAccountCreate (Boolean isIncluded, AccountContactRelation acr, Account intermediary, Contact contact)
    {
        if (acrsToUpsert != null &&!acrsToUpsert.isEmpty() && acr!= null)
        {
            for (AccountContactRelation listaAcrsToUpdateWhenUpsert : acrsToUpsert)
            {
                if (listaAcrsToUpdateWhenUpsert.id != null && acr.id != null && listaAcrsToUpdateWhenUpsert.id == acr.id)
                {
                    isIncluded = true;
                }
            }
        }
        
        if( !isIncluded ) 
        { // Si es la primera vez para el contacto del mediador
            //Se pone un ACR para crear o actualizar
            acr = new AccountContactRelation(
                Id= acr?.Id,
                AccountId= intermediary.Id,
                ContactId= contact.Id,
                IsActive= true
            );
            // Se añade el ACR a la lista para insertar
            acrsToUpsert.add(acr);
                                    
            // Lo guardamos en el mapa por si el contacto esta en varios campos de email del mediador
            Map<Id, AccountContactRelation> mapACRsByContactId = mapNewACRsByAccountAndContactIds.get(intermediary.Id);
            if( mapACRsByContactId == null )
            {
                mapACRsByContactId = new Map<Id, AccountContactRelation> ();
                mapNewACRsByAccountAndContactIds.put(intermediary.Id, mapACRsByContactId);
            }
            mapACRsByContactId.put(contact.Id, acr);
        }   
        return acr;      
    }

    /**
    * @description Método que comprueba si realmente hay que borrar las relaciones 
    * que se encuentran en el mapa de relaciones a borrar o bien hay que actualizarlas y quitarles el rol.
    * @author aberuete 
    * @date 13-04-2023 
    * @param String roleLabel : Rol de la relación
    * @param Map<ID, AccountContactRelation> mapACRsByContact: Mapa de ids de contactos con la relación entre contacto y cuenta
    **/
    @testvisible
    private Map<ID, AccountContactRelation> checkACRSToDelete(String roleLabel, Map<ID, AccountContactRelation> mapACRsByContact)
    {
        Boolean isIcludedInAcrstoUpsert = false;

        if( acrToDelete != null ) 
        {
            // quitamos este rol del ACR
            List<String> roles = acrToDelete.Roles?.split(';');
            roles.remove(roles.indexOf(roleLabel));
            // Si es relacion directa o Si todavia tiene mas roles => se quita el rol y se pone a modificar
            if( acrToDelete.isDirect || !roles.isEmpty() ) 
            {
                ifACRToDeleteInAcrToUpsertRemoveRole(isIcludedInAcrstoUpsert, roleLabel, roles );           
            } 
            else 
            { // Si no se pone a borrar
                
                // Si no esta en la lista de borrar definitivamente, lo añadimos
                if( !acrsToDelete.contains(acrToDelete) ) acrsToDelete.add(acrToDelete);
                // Comprobamos si ya se ha puesto a actualizar previamente al tener mas de un rol y quitarle uno previamente
                Boolean isACRtoDeleteInACRStoUpsertWithOneRole = checkIfRelationHasToRemoveOrUpdate ( roleLabel); 

                //Si la relacion tiene menos de dos roles y esta para actualizar, la quitamos de la lista para actualizarla
                if (isACRtoDeleteInACRStoUpsertWithOneRole)
                {
                    acrsToUpsert.remove(acrsToUpsert.IndexOf(acrToDelete));
                }
                // Si hemos puesto una relacion a borrar, quitamos a ese contacto del mapa ACR -Contactos
                mapACRsByContact.remove(acrToDelete.ContactId);
            }
        } 
        return mapACRsByContact;
    }

     /**
    * @description Método que comprueba si la relación se encuentra en la lista de relaciones a actualizar. Si esta en la lista se actualiza el rol,
    * en caso de que no esté se quita el rol y se añade a la lista de relaciones a actualizar.
    * @author aberuete 
    * @date 13-04-2023 
    * @param Boolean isIcludedInAcrstoUpsert: Booleano que indica si el acr está incluido en la lista de acrs para upsert 
    * @param String roleLabel : Rol de la relación
    * @param List<String> roles : Lista de roles
    **/
    private void ifACRToDeleteInAcrToUpsertRemoveRole(Boolean isIcludedInAcrstoUpsert, String roleLabel, List<String> roles )
    {
        // Se comprueba que el acrToDelete no este en la lista de acrsToUpsert
        if (acrsToUpsert != null && !acrsToUpsert.isEmpty() )
        {
            for (AccountContactRelation listaAcrsToUpdate : acrsToUpsert)
            {
                if (listaAcrsToUpdate.id != null && acrToDelete.id != null && listaAcrsToUpdate.id == acrToDelete.id )
                {
                    isIcludedInAcrstoUpsert = true;
                    List<String> rolesInListaAcrToUpdate = listaAcrsToUpdate.Roles?.split(';');
                    rolesInListaAcrToUpdate.remove(rolesInListaAcrToUpdate.indexOf(roleLabel));
                    listaAcrsToUpdate.Roles = String.join(rolesInListaAcrToUpdate, ';');
                }
            }
        }
        
        if (!isIcludedInAcrstoUpsert)
        {
            acrToDelete.Roles = String.join(roles, ';');
            acrsToUpsert.add(acrToDelete);
        }     
    }

     /**
    * @description Método que comprueba si la relación se tiene que actualizar o borrar
    * @author aberuete 
    * @date 13-04-2023 
    * @param String roleLabel : Rol de la relación
    **/
    private Boolean checkIfRelationHasToRemoveOrUpdate (String roleLabel)
    {
        Boolean isACRtoDeleteInACRStoUpsertWithOneRole = false;
        // Comprobamos si ya se ha puesto a actualizar previamente al tener mas de un rol y quitarle uno previamente
        if (acrsToUpsert != null && !acrsToUpsert.isEmpty() )
        {
            for (AccountContactRelation listaACRToUpsert :acrsToUpsert)
            {
                if (listaACRToUpsert.id != null && listaACRToUpsert.id == acrToDelete.id )
                {
                    List<String> rolesToUpsert = listaACRToUpsert.Roles?.split(';');
                    // Comprobamos cuantos roles tiene para actualizar
                    //Si tiene menos de dos, la relacion hay que borrarla
                    if (rolesToUpsert.size() < 2 )
                    {
                        isACRtoDeleteInACRStoUpsertWithOneRole = true;
                    }
                    //En el caso que tenga 2 roles o mas , la relacion no hay que borrarla si no actualizarla
                    else 
                    {
                        acrsToDelete.remove(acrsToDelete.indexOf(acrToDelete));
                        rolesToUpsert.remove(rolesToUpsert.indexOf(roleLabel));
                        listaACRToUpsert.Roles = String.join(rolesToUpsert, ';');
                    }
                }
            }
        }
        return isACRtoDeleteInACRStoUpsertWithOneRole;
    }

     /**
    * @description Método que inserta los contactos y añade los roles a la relación para actualizarse
    * @author aberuete 
    * @date 13-04-2023 
    **/
    @testvisible
    private void insertContactsIfThereAreToInsertAndAssignRolToAcrToUpsert ()
    {
        // Si hay contactos para insertar
        if( !mapContactsToInsert.isEmpty() ) 
        {
            // Insertamos los contactos
            insert mapContactsToInsert.values();

            // Recuperamos los AccountContactRelation creados al insertar los contactos
            List<AccountContactRelation> acrs = [
                SELECT Id, Roles, ContactId FROM AccountContactRelation WHERE ContactId IN :mapContactsToInsert.values()
            ];
            // Generamos un mapa de ACRs por ContactId
            Map<ID, AccountContactRelation> mapACRsByContactId = new Map<ID, AccountContactRelation>();
            for(AccountContactRelation acr: acrs) 
            {
                mapACRsByContactId.put(acr.ContactId, acr);
            }
                
            // Recorremos los mapas que relacionan contactos con ACR para ponerle al ACR el rol que le corresponde
            for(Integer x=0,y=mapContactsToInsert.values().size(); x < y; x++ ) 
            {
                Contact c = mapContactsToInsert?.get(x);
                List<String> roles = mapRolesForContacts?.get(x);

                // Si el contacto, el rol y el ACR existen, se asigna el rol al ACR para ese contacto y se pone para
                // modificar
                if( c != null && roles != null && mapACRsByContactId.containsKey(c.Id) ) 
                {
                    mapACRsByContactId.get(c.Id).Roles = String.join(roles, ';');
                    acrsToUpsert.add(mapACRsByContactId.get(c.Id));
                }
            }
        }         
    }

     /**
    * @description Método que elimina , actualiza o crea las relaciones entre los contactos y las cuentas
    * @author aberuete 
    * @date 13-04-2023 
    **/
    @testvisible
    private void deleteOrUpsertACRs ()
    {
        // Si hay AccountContactRelation para borrar
        if( !acrsToDelete.isEmpty() ) 
        {
            delete acrsToDelete;
        }
         
        // Si hay AccountContactRelation para insertar
        if( !acrsToUpsert.isEmpty() ) 
        {  
            upsert acrsToUpsert;
        } 
    }
}