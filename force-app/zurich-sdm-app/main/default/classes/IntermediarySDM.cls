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

    public static final String INTERMEDIARY_FIELD_NATIONALID = 'NationalId__c';
    public static final String INTERMEDIARY_FIELD_PARENTID = 'ParentId';
    public static final String INTERMEDIARY_FIELD_NAME = 'Name';
    public static final String INTERMEDIARY_FIELD_STATUS = 'StatusIntermediary__c';

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

    // AGRUPACION MEDIADORES
    // Mapa de agrupaciones por CIF de agrupacion
    public Map<String, Account> mapAgrupationByCIF;

    // USUARIOS
    // Mapa de usuarios por Email de usuario
    private Map<String, User> mapUsersByEmail;

    // ACCOUNT CONTACT RELATION
    // Mapa de AccountContactRelation por Id de Mediador y por Id de Contacto
    public Map<ID, Map<ID, AccountContactRelation>> mapACRsByAccountContact;
    // Mapa de AccountContactRelation por Id de Mediador y por Role
    private Map<ID, Map<String, AccountContactRelation>> mapACRsByAccountRole;

    // CONTACTO
    // Mapa de Contactos por Email
    private Map<String, Contact> mapContactsByEmail;

    // ACCOUNT id de tipo de registro de agrupacion de mediadores
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
            for(User u: [SELECT Id, Email FROM User]) {
                mapUsersByEmail.put(u.Email, u);
            }
        }
    }

    /**
     * Recupera todas las cuentas de tipo Agrupacion de Mediadores y crea un Mapa de Agrupaciones por CIF
     */
    private void findAgrupatedIntermediaries()
    {
        // Se recuperan las Agrupaciones de intermediarios si no se ha hecho ya
        if( this.mapAgrupationByCIF == null ) {
            List<Account> agrupationIntermediary = new AccountsSelector().findAgrupatedIntermediaries();

            // Mapa de agrupaciones por CIF de agrupacion
            this.mapAgrupationByCIF = new Map<String, Account>();
            for(Account a: agrupationIntermediary) {
                this.mapAgrupationByCIF.put(a.NationalID__c, a);
            }
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
                
                // Mapa de ACRs por Id de Mediador y por cada role que tenga la relacion
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
     *
     * @param {List<Account> intermedires} lista de Mediadores
     */
    public void assignIntermediaryAgrupation(List<Account> intermediaries)
    {
        // Si hay mediadores...
        if( intermediaries != null && !intermediaries.isEmpty() ) {
            List<Account> intermediariesToProcess = intermediaries;

            // Comprobamos en el PRIMER Mediador si tienen el campo CIF y su Agrupacion Actual, 
            // sino lo tiene se vuelven a recuperar
            Map<String, Object> fieldsToValue = intermediariesToProcess[0].getPopulatedFieldsAsMap();
            if( !fieldsToValue.containsKey(INTERMEDIARY_FIELD_NATIONALID) || !fieldsToValue.containsKey(INTERMEDIARY_FIELD_PARENTID) || !fieldsToValue.containsKey(INTERMEDIARY_FIELD_NAME) ) {
                Set<String> fields = new Set<String>{INTERMEDIARY_FIELD_NATIONALID, INTERMEDIARY_FIELD_PARENTID, INTERMEDIARY_FIELD_NAME};
                intermediariesToProcess = new AccountsSelector().findWithFields(intermediaries, fields);
            }

            // Si hay Mediadores para obtener su Agrupacion...
            if( !intermediariesToProcess.isEmpty() ) {
                // Recuperamos todos las cuentas de Agrupacion de Mediadores y creamos un mapa por CIF
                // (si la lista se vuelve muy grande se podria reducir el numero devuelto mirando primero los CIF de
                //  los mediadores a buscar)
                this.findAgrupatedIntermediaries();
                
                Map<Integer, Account> mapAgrupationByPos = new Map<Integer, Account>();
                Map<Integer, List<Account>> mapIntermediaryByPos = new Map<Integer, List<Account>>();
                Map<String, Integer> mapAgrupationPosByCIF = new Map<String, Integer>();
                Integer pos = 0;
                List<Account> intermediariesToUpdate = new List<Account>();

                // Por cada mediador...
                for(Account i: intermediariesToProcess ) {
                    // Si tienen campo CIF de agrupacion
                    if( String.isNotBlank(i.NationalId__c) ) {
                        // Recuperamos el Id de Agrupacion que corresponderia a ese CIF
                        ID agrupationId = this.mapAgrupationByCIF?.get(i.NationalId__c)?.Id;
                        if( agrupationId == null ) { //--------------------------------------------------- NO existe la agrupacion
                            // Intentamos recuperar la posicion de la agrupacion si ya existe
                            Integer agrpPos = mapAgrupationPosByCIF.get(i.NationalId__c);

                            // Si es la primera vez y no existe se crea
                            if( agrpPos == null ) {
                                agrpPos = pos;
                                pos++;

                                // Si no se ha recuperado ya, recuperamos el id de tipo de registro de agrupacion
                                if( this.rtAgrupationId == null ) this.rtAgrupationId = new AccountsSelector().rtAgrupationId;

                                // Creamos a partir de los campos del mediador
                                mapAgrupationByPos.put(agrpPos, new Account(
                                    NationalID__c= i.NationalID__c,
                                    Name= i.Name,
                                    RecordTypeId= this.rtAgrupationId
                                ));
                                // Lo guardamos por si lo necesitan otros mediadores con el mismo CIF
                                mapAgrupationPosByCIF.put(i.NationalID__c, agrpPos);
                            }

                            // Creamos la referencia al mediador
                            Account intermediary = new Account(
                                Id= i.Id
                            );
                            // Lo metemos en la lista de mediadores de la agrupacion en la posicion que corresponda
                            List<Account> listIntermediaries = mapIntermediaryByPos.get(agrpPos);
                            if( listIntermediaries == null ) {
                                listIntermediaries = new List<Account>();
                                mapIntermediaryByPos.put(agrpPos, listIntermediaries);
                            }
                            listIntermediaries.add(intermediary);

                            // Lo metemos tambien en la lista de mediadores a modificar
                            intermediariesToUpdate.add(intermediary);

                            // Añadimos el CIF a la lista de cifs de agrupacion para que se recalcule el ATM si es
                            // necesario
                            this.addNationalId(i.NationalID__c);
                        } else if( i.ParentId == null || i.ParentId != agrupationId ) { //---------------- SI existe
                            // Si existe la agrupacion y el Mediador no tiene agrupacion o es diferente a la actual, actualizamos
                            // Poner para modificar
                            intermediariesToUpdate.add(new Account(
                                Id= i.Id,
                                ParentId= agrupationId
                            ));

                            // Añadimos el CIF a la lista de cifs de agrupacion para que se recalcule el ATM si es
                            // necesario
                            this.addNationalId(i.NationalID__c);
                        }
                    }
                }

                // Si hay agrupaciones a crear
                if( !mapAgrupationByPos.isEmpty() ) {
                    // Insertamos las nuevas agrupaciones
                    insert mapAgrupationByPos.values();

                    // Para cada agrupacion nueva...
                    for(Integer key: mapAgrupationByPos.keySet()) {
                        // Recuperamos el id recien generado
                        Account agrp = mapAgrupationByPos.get(key);

                        // Y para cada mediador asociado a la agrupacion...
                        for(Account a: mapIntermediaryByPos.get(key)) {
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

                // Si hay mediadores a modificar
                if( !intermediariesToUpdate.isEmpty() ) {
                    update intermediariesToUpdate;
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
        if( intermediaries != null && !intermediaries.isEmpty() ) { 
            List<Account> intermediariesToProcess = intermediaries;

            // Comprobamos si el primer Mediador tiene el campo Status
            Map<String, Object> fieldsToValue = intermediariesToProcess[0].getPopulatedFieldsAsMap();
            if( !fieldsToValue.containsKey(INTERMEDIARY_FIELD_STATUS) || !fieldsToValue.containsKey(INTERMEDIARY_FIELD_NATIONALID) ) {
                Set<String> fields = this.SettingsATMFields;
                fields.add(INTERMEDIARY_FIELD_STATUS);
                fields.add(INTERMEDIARY_FIELD_NATIONALID);
                if( this.rnFieldNoATM != null ) fields.add(this.rnFieldNoATM);
                intermediariesToProcess = new AccountsSelector().findWithFields(intermediaries, fields);
            }
            
            // Para las operaciones de DML
            List<AccountTeamMember> atmsToUpsert = new List<AccountTeamMember>();
            List<AccountTeamMember> atmsToDelete = new List<AccountTeamMember>();

            // Recuperamos todos los usuarios, crea mapa de usuarios por Email
            this.findAllUsers();
            // Recuperamos todos los ATMs de las cuentas implicadas, crea mapa de ATMs por cuenta, rol y usuario
            this.findATMsByIntermediaries(intermediariesToProcess);

            String settingsrnName = this.rnNameNoATM;
            // Por cada mediador...
            for( Account i: intermediariesToProcess ) {
                String rnName = null;
                if( this.rnFieldNoATM != null ) rnName = (String)i.get(rnFieldNoATM);

                if( i.StatusIntermediary__c == INTERMEDIARY_STATUS_INACTIVE 
                    || (rnName != null && settingsrnName != null && rnName.equalsIgnoreCase(settingsrnName)) ) { //---- Es inactivo o tiene el valor adecuado en el campo RN
                    List<AccountTeamMember> allATMs = null;
                    // Recuperamos todos los ATM para la cuenta que haya, independientemente del rol y usuario
                    List<Map<ID, AccountTeamMember>> listMapAtmByUserId = this.mapATMsByAccountRolUser?.get(i.Id)?.values();
                    if( listMapAtmByUserId != null && !listMapAtmByUserId.isEmpty() ) {
                        allATMs = new List<AccountTeamMember>();
                        for(Integer x=0,y=listMapAtmByUserId.size(); x < y; x++) {
                            allATMs.addAll(listMapAtmByUserId[x].values());
                            
                            // Añadimos a los usuarios para notificarlos al final del batch
                            this.addUsersToNotify(listMapAtmByUserId[x].keySet());
                        }
                    }
                    // Y los ponemos para borrar
                    if( allATMs != null && !allATMs.isEmpty() ) {
                        atmsToDelete.addAll(allATMs);

                        // Añadimos el CIF para que se recalculen los ATMs del padre (agrupacion)
                        this.addNationalId(i.NationalId__c);
                    }
                } else if( i.StatusIntermediary__c == INTERMEDIARY_STATUS_ACTIVE ) { //-------------------------------------------- Si el mediador es Activo
                    // Por cada rol-campo mediador
                    for( SDMAccountTeamRole__mdt s: this.SettingsATM ) {
                        if( String.isNotBlank(s.IntermediaryField__c) && s.Status__c == ATM_ROL_STATUS_ACTIVE ) {
                            // Buscamos la etiqueta del rol si la hay
                            String roleLabel = this.settings.getATMRoleLabel(s.Role__c);

                            // Recuperamos el ATM, si existe, para esa cuenta y rol
                            Map<ID, AccountTeamMember> mapAtmByUserId = this.mapATMsByAccountRolUser?.get(i.Id)?.get(roleLabel);

                            // Y recuperamos el valor del campo, que deberia ser un email de usuario de Salesforce
                            String fieldValue = (String)i.get(s.IntermediaryField__c);

                            // Si el valor del campo es vacio o con el valor VACANT, y si tiene ATMs, 
                            // se ponen los ATMs para borrar
                            if( String.isBlank(fieldValue) 
                                || fieldValue.equalsIgnoreCase(INTERMEDIARY_VACANT)
                            ) {
                                if( mapAtmByUserId != null && !mapAtmByUserId.values().isEmpty() ) {
                                    atmsToDelete.addAll(mapAtmByUserId.values());
                                    
                                    // Añadimos el CIF para que se recalculen los ATMs del padre (agrupacion)
                                    this.addNationalId(i.NationalId__c);
                                    // Añadimos los usuarios para notificarlos al final del batch
                                    this.addUsersToNotify(mapAtmByUserId.keySet());
                                }
                            } else {
                                // Sino, se mira si se corresponde con el email de un Usuario
                                User u = mapUsersByEmail?.get(fieldValue);
                                // Si el usuario existe
                                if( u != null ) {
                                    // Se recoge el ATM para ese usuario (puede que no exista y sea nulo)
                                    AccountTeamMember atmOld = mapAtmByUserId?.get(u.Id);

                                    // Si aun no existe...
                                    if( atmOld == null ) {
                                        // Como solo deberia haber un ATM por rol y no hay para ese usuario, 
                                        // se mira si hay otros y si los hay se ponen a borrar. No deja modificar los actuales
                                        if( mapAtmByUserId != null && !mapAtmByUserId.isEmpty() ) {
                                            atmsToDelete.addAll(mapAtmByUserId.values());
                                            // Añadimos los usuarios para notificarlos al final del batch
                                            this.addUsersToNotify(mapAtmByUserId.keySet());
                                        }

                                        AccountTeamMember atm = new AccountTeamMember(
                                            AccountId= i.Id,
                                            userId= u.Id,
                                            TeamMemberRole= roleLabel,
                                            AccountAccessLevel= ATM_ACCOUNT_ACCESS_LEVEL,
                                            ContactAccessLevel= ATM_CONTACT_ACCESS_LEVEL
                                        );

                                        atmsToUpsert.add(atm);

                                        // Añadimos el CIF para que se recalculen los ATMs del padre (agrupacion)
                                        this.addNationalId(i.NationalId__c);
                                        // Añadimos el usuario para notificarlo al final del batch
                                        this.addUserToNotify(u.Id);
                                    }
                                }
                            }
                        }
                    }
                }
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
     */
    public void assignIntermediaryContactRelation(List<Account> intermediaries)
    {
        if( intermediaries != null && !intermediaries.isEmpty() ) {
            List<Account> intermediariesToProcess = intermediaries;
            
            // Se buscan los emails para mirar si el contacto ya existe
            Set<String> emailsMediadores = new Set<String>();
            // Por cada mediador...
            for( Account i: intermediariesToProcess ) {
                // Recuperamos los campos que hay en memoria del objeto Account
                Map<String, Object> fieldsToValue = i.getPopulatedFieldsAsMap();
                // Por cada relacion de rol contact - campo mediador, miramos si el Account tiene el campo informado
                for( SDMAccountContactRelation__mdt rel: this.SettingsACR) {
                    String fieldValue = (String)fieldsToValue?.get(rel.IntermediaryField__c);
                    if( String.isNotBlank(fieldValue) ) {
                        emailsMediadores.add(fieldValue);
                    }
                }
            }

            // Se recuperan los contactos para los emails encontrados
            this.findContactByEmail(emailsMediadores);

            // Se recuperan los objetos AccountContactRelation para los mediadores dados
            this.findACRsByIntermediaries(intermediariesToProcess);

            // Para cuando hay que crear el Contacto y relacionarlo con un rol
            Integer position = 0;
            Map<Integer, Contact> mapContactsToInsert = new Map<Integer, Contact>();
            // Para los roles de los contactos nuevos. Puede ser que un contacto tenga mas de un rol para un mediador
            Map<Integer, List<String>> mapRolesForContacts = new Map<Integer, List<String>>();
            // Para los contactos nuevos que tengan varios roles en un mediador
            Map<String, Integer> mapContactPositionByEmail = new Map<String, Integer>();

            Map<Id, Map<Id, AccountContactRelation>> mapNewACRsByAccountAndContactIds = new Map<Id, Map<Id, AccountContactRelation>>();

            // Para las DMLs al final            
            List<AccountContactRelation> acrsToUpsert = new List<AccountContactRelation> ();
            List<AccountContactRelation> acrsToDelete = new List<AccountContactRelation> ();

            // Por cada mediador...
            for( Account i: intermediariesToProcess ) {
                // Recuperamos los campos que hay en memoria del objeto Account
                Map<String, Object> fieldsToValue = i.getPopulatedFieldsAsMap();
                // Por cada relacion de rol contact - campo mediador
                for( SDMAccountContactRelation__mdt rel: this.SettingsACR) {
                    // Buscamos la etiqueta del rol si la hay
                    String roleLabel = this.settings.getACRRoleLabel(rel.Role__c);

                    // ACRs de Contactos para el Mediador
                    Map<ID, AccountContactRelation> mapACRsByContact = this.mapACRsByAccountContact?.get(i.Id);
                    // ACRs de Roles para el Mediador
                    Map<String, AccountContactRelation> mapACRsByRoles = this.mapACRsByAccountRole?.get(i.Id);
                    // ACR para el rol actual (puede no existir y ser nulo)
                    AccountContactRelation acrForRol = mapACRsByRoles?.get(roleLabel);
                    // Hara referencia al ACR que se debera borrar su relacion
                    AccountContactRelation acrToDelete = null;

                    

                    // Se mira si tiene valor de email en el campo de mediador actual, sino se borra los ACRs que hubiera
                    String fieldValue = String.valueOf(fieldsToValue.get(rel.IntermediaryField__c));
                    if( String.isNotBlank(fieldValue) ) { //------------------------------------------------------------ Tiene valor de Email
                        // Miramos si hay contacto para ese email
                        Contact contact = mapContactsByEmail?.get(fieldValue);

                        if( contact == null ) { // Si NO hay contacto, se pone para crear el contacto que creara el ACR
                            // Si hay ACR se tendra que eliminar la relacion (puede que sea nulo)
                            acrToDelete = acrForRol;

                            // Miramos si el contacto ya se ha creado previamente
                            Integer contactPosition = mapContactPositionByEmail?.get(fieldValue);
                            if( contactPosition == null ) {
                                // 17.08.2021 - nts (agonzalezisasi) - bug sdm-361 - Limite de caracteres en el nombre del contacto
                                String contactName = rel.NameText__c + ' ' + i.Name;

                                // Se preparan los datos del nuevo contacto
                                Contact newContact = new Contact(
                                        AccountId= i.Id,
                                        LastName= contactName.left(CONTACT_NAME_MAX_SIZE),
                                        RecordTypeId= new ContactsSelector().rtContactId,
                                        Email= fieldValue
                                );
                                // Si es el principal, se copia tambien el telefono
                                // todo: poner esta parte en configuracion
                                if( rel.IntermediaryField__c.equals(AccountsSelector.SDM_MAINEMAIL_FIELD) && fieldsToValue.containsKey(AccountsSelector.SDM_MAINMOBILEPHONE_FIELD) ) {
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
                            if( rols == null ) {
                                rols = new List<String>();
                                mapRolesForContacts.put(contactPosition, rols);
                            }
                            rols.add(roleLabel);
                        } else { // Si hay contacto
                            // Si ya hay ACR pero no es para el contacto actual se debera eliminar la relacion
                            if( acrForRol != null && acrForRol.ContactId != contact.Id ) acrToDelete = acrForRol;

                            // Miramos si ya tienen relacion ACR para el contacto
                            AccountContactRelation acr = mapACRsByContact?.get(contact.Id);
                            List<String> roles = acr?.Roles?.split(';');

                            // Si no tiene ACR, o no con ese rol, ponemos a crear o modificar la relacion
                            if( acr == null || roles == null || !roles.contains(roleLabel) ) {
                                Boolean isIncluded = false;

                                // Vemos si el mismo usuario tiene otro nuevo rol para el mismo mediador
                                AccountContactRelation acrNew = mapNewACRsByAccountAndContactIds?.get(i.Id)?.get(contact.Id);
                                if( acrNew != null ) {
                                    isIncluded = true;
                                    acr = acrNew;
                                    roles = acr?.Roles?.split(';');
                                }

                                // Preparamos la lista de roles
                                if( roles == null ) roles = new List<String>();
                                roles.add(roleLabel);

                                if( !isIncluded ) { // Si es la primera vez para el contacto del mediador
                                    //Se pone un ACR para crear o actualizar
                                    acr = new AccountContactRelation(
                                        Id= acr?.Id,
                                        AccountId= i.Id,
                                        ContactId= contact.Id,
                                        IsActive= true
                                    );

                                    // Se añade el ACR a la lista para insertar
                                    acrsToUpsert.add(acr);

                                    // Lo guardamos en el mapa por si el contacto esta en varios campos de email del mediador
                                    Map<Id, AccountContactRelation> mapACRsByContactId = mapNewACRsByAccountAndContactIds.get(i.Id);
                                    if( mapACRsByContactId == null ) {
                                        mapACRsByContactId = new Map<Id, AccountContactRelation> ();
                                        mapNewACRsByAccountAndContactIds.put(i.Id, mapACRsByContactId);
                                    }
                                    mapACRsByContactId.put(contact.Id, acr);
                                }

                                // Indicamos la nueva lista de roles, ya sea para la primera vez o para las sucesivas 
                                acr.Roles = String.join(roles, ';');
                            }
                        }
                    } else { //----------------------------------------------------------------------------------------- NO tiene valor
                        // Si el campo de email esta vacio y hay ACR se debera eliminar la relacion
                        acrToDelete = acrForRol;
                    }

                    // Si hay que borrar el ACR con el rol actual, por estar el campo de email vacio o por cambio de contacto para el rol
                    if( acrToDelete != null ) { 
                        // quitamos este rol del ACR
                        List<String> roles = acrToDelete.Roles?.split(';');
                        roles.remove(roles.indexOf(roleLabel));

                        // Si es relacion directa o Si todavia tiene mas roles => se quita el rol y se pone a modificar
                        if( acrToDelete.isDirect || !roles.isEmpty() ) {
                            acrToDelete.Roles = String.join(roles, ';');
                            if( !acrsToUpsert.contains(acrToDelete) ) acrsToUpsert.add(acrToDelete);
                        } else { // Si no se pone a borrar
                            // Comprobamos si ya se ha puesto a actualizar previamente al tener mas de un rol y quitarle uno previamente
                            if( acrsToUpsert.contains(acrToDelete) ) acrsToUpsert.remove(acrsToUpsert.IndexOf(acrToDelete));
                            // Y lo ponemos a borrar definitivamente
                            if( !acrsToDelete.contains(acrToDelete) ) acrsToDelete.add(acrToDelete);
                        }
                    }
                }
            }

            // Si hay contactos para insertar
            if( !mapContactsToInsert.isEmpty() ) {
                // Insertamos los contactos
                insert mapContactsToInsert.values();

                // Recuperamos los AccountContactRelation creados al insertar los contactos
                List<AccountContactRelation> acrs = [
                    SELECT Id, Roles, ContactId FROM AccountContactRelation WHERE ContactId IN :mapContactsToInsert.values()
                ];
                // Generamos un mapa de ACRs por ContactId
                Map<ID, AccountContactRelation> mapACRsByContactId = new Map<ID, AccountContactRelation>();
                for(AccountContactRelation acr: acrs) {
                    mapACRsByContactId.put(acr.ContactId, acr);
                }
                
                // Recorremos los mapas que relacionan contactos con ACR para ponerle al ACR el rol que le corresponde
                for(Integer x=0,y=mapContactsToInsert.values().size(); x < y; x++ ) {
                    Contact c = mapContactsToInsert?.get(x);
                    List<String> roles = mapRolesForContacts?.get(x);

                    // Si el contacto, el rol y el ACR existen, se asigna el rol al ACR para ese contacto y se pone para
                    // modificar
                    if( c != null && roles != null && mapACRsByContactId.containsKey(c.Id) ) {
                        mapACRsByContactId.get(c.Id).Roles = String.join(roles, ';');
                        acrsToUpsert.add(mapACRsByContactId.get(c.Id));
                    }
                }
            }

            // Si hay AccountContactRelation para borrar
            if( !acrsToDelete.isEmpty() ) {
                delete acrsToDelete;
            }

            // Si hay AccountContactRelation para insertar
            if( !acrsToUpsert.isEmpty() ) {
                upsert acrsToUpsert;
            }
        }
    }

    /**
     * Metodo que, para la lista de CIFs de agrupacion dados, calcula los equipos de cuenta que le corresponden
     * a la agrupacion por los hijos que tiene
     * 
     * @param {List<String> agrupationNationalIDs} lista de CIFs de agrupaciones
     */
    public void assignAgrupationAccountTeam(Set<String> agrupationNationalIDs)
    {
        // Si hay CIFs
        if( agrupationNationalIDs != null && !agrupationNationalIDs.isEmpty() ) {
            // 1. Recuperamos los ATMs que hay para los CIFs dados, tanto los de las agrupaciones como los 
            // de los mediadores
            List<AccountTeamMember> atms = (new AccountTeamMemberSelector()).findByNationalIDs(agrupationNationalIDs);

            // Si hay ATMs
            if( atms != null && !atms.isEmpty() ) {
                // A partir de esta lista, miraremos que usuarios ya tienen permisos en las agrupaciones y cuales no
                // pero que si los tienen los mediadores hijos hay que crearselos

                // Guardara los UserIds de las agrupaciones por CIF
                Map<String, Set<Id>> mapExistingAgrupationUsers = new Map<String, Set<Id>>(); 
                // Guardara los id de ATM de las agrupaciones por CIF y por UserId
                Map<String, Map<Id, Id>> mapExistingATMsByNationalIdAndUserId = new Map<String, Map<Id, Id>>();

                // Guardara los UserIds de los mediadores por CIF
                Map<String, Set<Id>> mapExistingIntermediaryUsers = new Map<String, Set<Id>>(); 
                // Guardara los id de ATM de los mediadores por CIF y por UserId
                Map<String, Map<Id, AccountTeamMember>> mapExistingInterATMsByNationalIdAndUserId = new Map<String, Map<Id, AccountTeamMember>>();


                // Lista de ATMs a crear
                List<AccountTeamMember> atmsToCreate = new List<AccountTeamMember>();
                // Lista de ATMs existentes de las agrupaciones a borrar
                List<AccountTeamMember> atmsToDelete = new List<AccountTeamMember>();

                // 2. Primero miramos los usuarios (a traves del atm) existentes tanto para las agrupaciones 
                // como para los mediadores

                // Por cada Account Team Member (atm)...
                for(AccountTeamMember atm: atms) {
                    String nationalId = atm.Account.NationalId__c;
                    Id userId = atm.UserId;

                    if( atm.Account.RecordType.DeveloperName == AccountsSelector.RT_NAME_AGRUPATION ) {
                        // Es ATM de Agrupacion

                        // Incluimos el usuario para ese CIF en el mapa de usuarios existentes
                        Set<Id> userIds = mapExistingAgrupationUsers.get(nationalId);
                        if( userIds == null ) {
                            userIds = new Set<Id>();
                            mapExistingAgrupationUsers.put(nationalId, userIds);
                        }
                        userIds.add(userId);

                        // Nos guardamos tambien el id del atm por si luego hay que borrarlo
                        Map<Id, Id> mapATMsByUserId = mapExistingATMsByNationalIdAndUserId.get(nationalId);
                        if( mapATMsByUserId == null ) {
                            mapATMsByUserId = new Map<Id, Id>();
                            mapExistingATMsByNationalIdAndUserId.put(nationalId, mapATMsByUserId);
                        }
                        mapATMsByUserId.put(userId, atm.Id);                    
                    } else { 
                        // Es ATM de Mediador hijo

                        // Incluimos el usuario para ese CIF en el mapa de usuarios existentes
                        Set<Id> userIds = mapExistingIntermediaryUsers.get(nationalId);
                        if( userIds == null ) {
                            userIds = new Set<Id>();
                            mapExistingIntermediaryUsers.put(nationalId, userIds);
                        }
                        userIds.add(userId);

                        // Nos guardamos tambien el id del atm por si luego hay que borrarlo
                        Map<Id, AccountTeamMember> mapATMsByUserId = mapExistingInterATMsByNationalIdAndUserId.get(nationalId);
                        if( mapATMsByUserId == null ) {
                            mapATMsByUserId = new Map<Id, AccountTeamMember>();
                            mapExistingInterATMsByNationalIdAndUserId.put(nationalId, mapATMsByUserId);
                        }
                        mapATMsByUserId.put(userId, atm);
                    }
                }


                // 3. Despues comparamos la lista de Usuarios de los mediadores con los ya existentes de las
                // agrupaciones para saber cuales son nuevos y cuales ya existen
                
                // Por cada CIF de mediador...
                for(String key: mapExistingIntermediaryUsers.keySet()) {
                    Set<id> userIds = mapExistingAgrupationUsers.get(key);

                    // Por cada UserId del mediador...
                    for(Id userId: mapExistingIntermediaryUsers.get(key)) {
                        if(userIds == null || !userIds.contains(userId) ) {
                            AccountTeamMember intermediaryAtm = mapExistingInterATMsByNationalIdAndUserId.get(key)?.get(userId);

                            if( intermediaryAtm != null && intermediaryAtm.Account?.ParentId != null ) {
                                // Es nuevo
                                AccountTeamMember newAtm = new AccountTeamMember(
                                    AccountId= intermediaryAtm.Account.ParentId,
                                    UserId= userId,
                                    TeamMemberRole= intermediaryAtm.TeamMemberRole,
                                    AccountAccessLevel= ATM_ACCOUNT_ACCESS_LEVEL_EDIT,
                                    ContactAccessLevel= ATM_CONTACT_ACCESS_LEVEL
                                );
                                atmsToCreate.add(newAtm);
                                
                                // Añadimos el usuario para notificarlo al final del batch, aunque probablemente
                                // ya este incluido por los cambios en los equipos de cuenta de los mediadores
                                this.addUserToNotify(userId);
                            }
                        } else {
                            // Ya existe, se quita para dejar en la agrupacion los que no existen ya en los 
                            // mediadores y por tanto habra que borrar
                            userIds.remove(userId);
                        }
                    }
                }

                // 4. Despues miramos los usuarios que quedan de las agrupaciones y que deberian ser los que ya no
                // existen en los mediadores y por tanto hay que borrar

                // Por cada CIF de agrupacion...
                for(String key: mapExistingAgrupationUsers.keySet()) {

                    // Por cada UserId de agrupacion...
                    for(Id userId: mapExistingAgrupationUsers.get(key)) {
                        // Buscamos el Id de ATM
                        Id atmId = mapExistingATMsByNationalIdAndUserId.get(key)?.get(userId);
                        // Y si lo hay lo ponemos a borrar
                        if( atmId != null ) {
                            atmsToDelete.add(new AccountTeamMember(Id= atmId));
                            // Añadimos el usuario para notificarlo al final del batch, aunque probablemente
                            // ya este incluido por los cambios en los equipos de cuenta de los mediadores
                            this.addUserToNotify(userId);
                        }
                    }
                }

                this.deleteATMs(atmsToDelete);
                this.upsertATMs(atmsToCreate);
            }
        }
    }

    /**
     * Metodo que envia la siguiente notificacion a todos los usuarios que se les ha cambiado la visibilidad
     * del mediador
     * 
     * @param {Set<Id> userIds} Lista de usuario receptores de la notificacion
     */
    public void sendNotification(Set<Id> userIds)
    {
        if( userIds != null && !userIds.isEmpty() ) {
            String title = this.notificationTitle;
            String bodyContent = this.notificationBody;

            Notification notif = new Notification(Notification.notificationType.SDMAlert);
            // Permite abrir la seccion de Cuentas, listview Mis Mediadores
            notif.addPageReference('standard__objectPage', 'Account', 'list', 'Mis_mediadores_SDM');
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
}