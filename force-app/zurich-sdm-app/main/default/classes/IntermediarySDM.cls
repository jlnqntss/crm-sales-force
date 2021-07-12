/**
 * Clase de utilidad para el proyecto de SDM (Sales Digital Management)
 *
 * @author nts (agonzalezisasi)
 * @date 23/06/20201
 */
public with sharing class IntermediarySDM {
    // CONSTANTES
    private static final String INTERMEDIARY_STATUS_ACTIVE = 'Active';
    private static final String INTERMEDIARY_STATUS_INACTIVE = 'Inactive';
    @testvisible
    private static final String INTERMEDIARY_VACANT = 'VACANT';
    private static final String SETUP_RC_NAME = 'SDMIntermediaryRCName';
    private static final String SETUP_RC_FIELD = 'SDMIntermediaryRCField';

    // CONFIGURACION
    // Relacion entre Rol de equipo de cuenta y campos de Mediador
    private List<SDMAccountTeamRole__mdt> pSettingsATM; 
    public List<SDMAccountTeamRole__mdt> SettingsATM {
        get {
            if( psettingsATM == null ) {
                psettingsATM = getAccountRolesWithIntermediaryFields();
            }
            return psettingsATM;
        }
    }
    private Set<String> pSettingsATMFields;
    public Set<String> SettingsATMFields {
        get {
            if( pSettingsATMFields == null ) {
                pSettingsATMFields = new Set<String>();
                if( SettingsATM != null && !SettingsATM.isEmpty() ) {
                    // Get the list of Intermediary fields
                    for( SDMAccountTeamRole__mdt s: SettingsATM ) {
                        pSettingsATMFields.add(s.IntermediaryField__c);
                    }
                }
            }
            return pSettingsATMFields;
        }
    }
    @testvisible
    private List<SDMAccountTeamRole__mdt> testSettingsATM;

    // Relacion entre Rol de cuenta-contacto y campos de Mediador
    List<SDMAccountContactRelation__mdt> pSettingsACR;
    public List<SDMAccountContactRelation__mdt> SettingsACR {
        get {
            if( pSettingsACR == null ) {
                pSettingsACR = getContactRolesWithIntermediaryFields();
            }
            return pSettingsACR;
        }
    }
    private Set<String> pSettingsACRFields;
    public Set<String> SettingsACRFields {
        get {
            if( pSettingsACRFields == null ) {
                pSettingsACRFields = new Set<String>();
                if( SettingsACR != null && !SettingsACR.isEmpty() ) {
                    // Get the list of Intermediary fields
                    for( SDMAccountContactRelation__mdt s: SettingsACR ) {
                        pSettingsACRFields.add(s.IntermediaryField__c);
                    }
                }
            }
            return pSettingsACRFields;
        }
    }
    @testvisible
    private List<SDMAccountContactRelation__mdt> testSettingsACR;

    // Nombre del responsable de negocio: Director Territorial Centralizados => no tiene equipos de cuenta (ATM)
    private String rnNameNoATM {
        get {
            if( String.isBlank(rnNameNoATM) ) rnNameNoATM = getRNName();
            return rnNameNoATM;
        }
        set {
            rnNameNoATM = value;
        }
    }
    @testvisible
    private String testrnNameNoATM;
    public String rnFieldNoATM{
        get {
            if( String.isBlank(rnFieldNoATM) ) rnFieldNoATM = getRNField();
            return rnFieldNoATM;
        }
        set {
            rnFieldNoATM = value;
        }
    }
    @testvisible
    private String testrnFieldNoATM;

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
    Map<String, Contact> mapContactsByEmail;

    // METODOS    
    /**
     * Recupera la relacion entre los roles del objeto Account Team Member y los campos de la cuenta de tipo 
     * Mediador (Intermediary)
     */
    private List<SDMAccountTeamRole__mdt> getAccountRolesWithIntermediaryFields()
    {
        List<SDMAccountTeamRole__mdt> result = [
            SELECT Role__c, IntermediaryField__c, Status__c 
            FROM SDMAccountTeamRole__mdt
        ];

        // Solo para los test cambiamos los datos de configuracion
        if( Test.isRunningTest() && this.testSettingsATM != null && !this.testSettingsATM.isEmpty() ) {
            result.clear();
            result.addAll(this.testSettingsATM);
        }
        return result;
    }

    /**
     * Recupera la relacion entre los roles del objeto Account Contact Relation y los campos de la cuenta de tipo 
     * Mediador (Intermediary)
     */
    private List<SDMAccountContactRelation__mdt> getContactRolesWithIntermediaryFields()
    {
        List<SDMAccountContactRelation__mdt> result = [
            SELECT Role__c, IntermediaryField__c, NameText__c 
            FROM SDMAccountContactRelation__mdt
        ];

        // Solo para los test cambiamos los datos de configuracion
        if( Test.isRunningTest() && this.testSettingsACR != null && !this.testSettingsACR.isEmpty() ) {
            result.clear();
            result.addAll(this.testSettingsACR);
        }

        return result;
    }

    /**
     * Recupera de la configuracion el nombre del responsable de negocio de mediadores
     */
    private String getRNName()
    {
        String result = [
            SELECT Value__c FROM AdminSetupParameter__mdt WHERE KeyName__c = :SETUP_RC_NAME LIMIT 1
        ]?.Value__c;

        if( Test.isRunningTest() && String.isNotBlank(this.testrnNameNoATM) ) result = this.testrnNameNoATM;

        return result;
    }

    /**
     * Recupera de la configuracion el campo del Mediador donde esta el nombre del responsable de negocio
     */
    private String getRNField()
    {
        String result = [
            SELECT Value__c FROM AdminSetupParameter__mdt WHERE KeyName__c = :SETUP_RC_FIELD LIMIT 1
        ]?.Value__c;

        if( Test.isRunningTest() && String.isNotBlank(this.testrnFieldNoATM) ) result = this.testrnFieldNoATM;

        return result;
    }

    /**
     * Recupera todos los usuarios del sistema y crea un Mapa de usuarios por email
     */
    public void findAllUsers()
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
    public void findAgrupatedIntermediaries()
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
    public void findATMsByIntermediaries(List<Account> intermediaries)
    {
        List<AccountTeamMember> atms = [
            SELECT Id, AccountId, UserId, User.Email, TeamMemberRole 
            FROM AccountTeamMember 
            WHERE AccountId IN :intermediaries
        ];

        // Mapa de ATM por Id de mediador asociado, Rol de ATM y por Id de usuario
        this.mapATMsByAccountRolUser = new Map<ID, Map<string, Map<ID, AccountTeamMember>>>();
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

    /**
     * Recupera los objetos Account Contact Relation que pertenecen a las cuentas de Mediadores y crean dos mapas:
     * - ACRs por Id de Mediador y por Id de Contacto
     * - ACRs por Id de Mediador y por Role
     *
     * @param {List<Account> intermediaries} lista de Mediadores
     */
    public void findACRsByIntermediaries(List<Account> intermediaries)
    {
        List<AccountContactRelation> acrs = [
            SELECT Id, AccountId, ContactId, Contact.Email, Roles, StartDate, EndDate, IsActive, isDirect
            FROM AccountContactRelation
            WHERE AccountId IN :intermediaries
        ];

        // Mapa de ACRs por Id de Mediador y por Id de Contacto
        this.mapACRsByAccountContact = new Map<ID, Map<ID, AccountContactRelation>>();
        // Mapa de ACRs por Id de Mediador y por Role
        this.mapACRsByAccountRole = new Map<ID, Map<String, AccountContactRelation>>();

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

    /**
     * Recupera los contactos que tengan los emails dados como parametro
     *
     * @param {Set<String> emails} lista de emails de contacto
     */
    public void findContactByEmail(Set<String> emails)
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
    public void deleteATMs(List<AccountTeamMember> atmToDelete)
    {
        if( atmToDelete != null && !atmToDelete.isEmpty() ) {
            delete atmToDelete;
        }
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
            if( !fieldsToValue.containsKey('NationalId__c') || !fieldsToValue.containsKey('ParentId') ) {
                Set<String> fields = new Set<String>{'NationalId__c', 'ParentId'};
                intermediariesToProcess = new AccountsSelector().findWithFields(intermediaries, fields);
            }

            // Si hay Mediadores para obtener su Agrupacion...
            if( !intermediariesToProcess.isEmpty() ) {
                // Recuperamos todos las cuentas de Agrupacion de Mediadores y creamos un mapa por CIF
                // (si la lista se vuelve muy grande se podria reducir el numero devuelto mirando primero los CIF de
                //  los mediadores a buscar)
                this.findAgrupatedIntermediaries();
                
                // Si hay Agrupaciones...
                if( this.mapAgrupationByCIF != null && !this.mapAgrupationByCIF.isEmpty() ) {
                    List<Account> intermediariesToUpdate = new List<Account>();

                    // Por cada mediador...
                    for(Account i: intermediariesToProcess ) {
                        // Si tienen campo CIF de agrupacion
                        if( String.isNotBlank(i.NationalId__c) ) {
                            // Recuperamos el Id de Agrupacion que corresponderia a ese CIF
                            ID agrupationId = this.mapAgrupationByCIF.get(i.NationalId__c)?.Id;
                            // Si existe la agrupacion y el Mediador no tiene agrupacion o es diferente a la actual, actualizamos
                            if( agrupationId != null 
                                && (i.ParentId == null || i.ParentId != agrupationId) ) 
                            {
                                // Poner para modificar
                                intermediariesToUpdate.add(new Account(
                                    Id= i.Id,
                                    ParentId= agrupationId
                                ));
                            }
                        }
                    }

                    if( !intermediariesToUpdate.isEmpty() ) {
                        update intermediariesToUpdate;
                    }
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
            if( !fieldsToValue.containsKey('IntermediaryStatus__c') ) {
                Set<String> fields = this.SettingsATMFields;
                fields.add('IntermediaryStatus__c');
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

                if( i.IntermediaryStatus__c == INTERMEDIARY_STATUS_INACTIVE 
                    || (rnName != null && settingsrnName != null && rnName.equalsIgnoreCase(settingsrnName)) ) { //---- Es inactivo o tiene el valor adecuado en el campo RN
                    List<AccountTeamMember> allATMs = null;
                    // Recuperamos todos los ATM para la cuenta que haya, independientemente del rol y usuario
                    List<Map<ID, AccountTeamMember>> listMapAtmByUserId = this.mapATMsByAccountRolUser?.get(i.Id)?.values();
                    if( listMapAtmByUserId != null && !listMapAtmByUserId.isEmpty() ) {
                        allATMs = new List<AccountTeamMember>();
                        for(Integer x=0,y=listMapAtmByUserId.size(); x < y; x++) {
                            allATMs.addAll(listMapAtmByUserId[x].values());
                        }
                    }
                    // Y los ponemos para borrar
                    if( allATMs != null && !allATMs.isEmpty() ) atmsToDelete.addAll(allATMs);
                } else if( i.IntermediaryStatus__c == INTERMEDIARY_STATUS_ACTIVE ) { //-------------------------------------------- Si el mediador es Activo
                    // Por cada rol-campo mediador
                    for( SDMAccountTeamRole__mdt s: this.SettingsATM ) {
                        if( String.isNotBlank(s.IntermediaryField__c) ) {
                            // Recuperamos el ATM, si existe, para esa cuenta y rol
                            Map<ID, AccountTeamMember> mapAtmByUserId = this.mapATMsByAccountRolUser?.get(i.Id)?.get(s.Role__c);

                            // Y recuperamos el valor del campo, que deberia ser un email de usuario de Salesforce
                            String fieldValue = (String)i.get(s.IntermediaryField__c);

                            // Si el valor del campo es vacio o con el valor VACANT, y si tiene ATM, se pone el ATM para borrar
                            if( String.isBlank(fieldValue) || fieldValue.equalsIgnoreCase(INTERMEDIARY_VACANT) ) {
                                if( mapAtmByUserId != null && !mapAtmByUserId.values().isEmpty() ) atmsToDelete.addAll(mapAtmByUserId.values());
                            } else {
                                // Sino, se mira si se corresponde con el email de un Usuario
                                User u = mapUsersByEmail?.get(fieldValue);
                                if( u != null ) {
                                    AccountTeamMember atmOld = null;
                                    if( mapAtmByUserId != null && mapAtmByUserId.containsKey(u.Id) ) atmOld = mapAtmByUserId.get(u.Id);

                                    AccountTeamMember atm = new AccountTeamMember(
                                        Id= atmOld?.Id,
                                        AccountId= i.Id,
                                        userId= u.Id,
                                        TeamMemberRole= s.Role__c
                                    );

                                    // Si no existe ATM o si el usuario del ATM actual es diferente, se pone a modificar
                                    if( atmOld == null || atmOld.UserId != u.Id ) {                                     
                                        atmsToUpsert.add(atm);       
                                    }
                                }
                            }
                        }
                    }
                }
            }

            this.upsertATMs(atmsToUpsert);
            this.deleteATMs(atmsToDelete);
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
            findContactByEmail(emailsMediadores);

            // Se recuperan los objetos AccountContactRelation para los mediadores dados
            this.findACRsByIntermediaries(intermediariesToProcess);

            Map<Integer, Contact> mapContactsToInsert = new Map<Integer, Contact>();
            Map<Integer, String> mapRolesForContacts = new Map<Integer, String>();
            // Map<Integer, AccountContactRelation> mapAcrsToInsert = new Map<Integer, AccountContactRelation>();
            Integer position = 0;
            // List<Contact> contactsToInsert = new List<Contact>();
            List<AccountContactRelation> acrsToUpsert = new List<AccountContactRelation> ();
            List<AccountContactRelation> acrsToDelete = new List<AccountContactRelation> ();
            // Por cada mediador...
            for( Account i: intermediariesToProcess ) {
                // Recuperamos los campos que hay en memoria del objeto Account
                Map<String, Object> fieldsToValue = i.getPopulatedFieldsAsMap();
                // Por cada relacion de rol contact - campo mediador
                for( SDMAccountContactRelation__mdt rel: this.SettingsACR) {
                    // Recuperamos los ACRs que pudiera haber para el mediador y el rol
                    // Map<String, AccountContactRelation> mapACRByEmail = this.mapACRsByAccountRolContact?.get(i.Id)?.get(rel.Role__c);

                    // ACRs de Contactos para el Mediador
                    Map<ID, AccountContactRelation> mapACRsByContact = this.mapACRsByAccountContact?.get(i.Id);
                    // ACRs de Roles para el Mediador
                    Map<String, AccountContactRelation> mapACRsByRoles = this.mapACRsByAccountRole?.get(i.Id);

                    // Se mira si tiene valor de email en el campo de mediador actual, sino se borra los ACRs que hubiera
                    String fieldValue = String.valueOf(fieldsToValue.get(rel.IntermediaryField__c));
                    if( String.isNotBlank(fieldValue) ) { //------------------------------------------------------------ Tiene valor de Email
                        // Miramos si hay contacto para ese email
                        Contact contact = mapContactsByEmail?.get(fieldValue);

                        if( contact == null ) { // Si no hay contacto, se pone para crear el contacto que creara el ACR
                            mapContactsToInsert.put(
                                position, 
                                    new Contact(
                                    AccountId= i.Id,
                                    LastName= rel.NameText__c + ' ' + i.Name,
                                    RecordTypeId= new ContactsSelector().rtContactId,
                                    Email= fieldValue
                                )
                            );
                            mapRolesForContacts.put(position, rel.Role__c);
                            position++;
                        } else { // Si hay contacto
                            // Miramos si ya tienen relacion ACR
                            AccountContactRelation acr = mapACRsByContact?.get(contact.Id);
                            List<String> roles = acr?.Roles?.split(';');

                            // Si no tiene ACR, o no con ese rol, ponemos a crear o modificar
                            if( acr == null || roles == null || !roles.contains(rel.Role__c) ) {
                                if( roles == null ) roles = new List<String>();
                                roles.add(rel.Role__c);

                                //Se pone un ACR para crear
                                acr = new AccountContactRelation(
                                    Id= acr?.Id,
                                    AccountId= i.Id,
                                    ContactId= contact.Id,
                                    Roles= String.join(roles, ';'),
                                    IsActive= true
                                );
                                // Se añade el ACR a la lista para insertar
                                acrsToUpsert.add(acr);
                            }
                        }
                    } else { //----------------------------------------------------------------------------------------- NO tiene valor
                        // Tiene relacion (ACR) para este rol?
                        AccountContactRelation acr = mapACRsByRoles?.get(rel.Role__c);
                        if( acr != null ) { // si tiene
                            // quitamos este rol del ACR
                            List<String> roles = acr.Roles?.split(';');
                            roles.remove(roles.indexOf(rel.Role__c));

                            // Si todavia tiene mas roles => se quita y se pone a modificar
                            if( !roles.isEmpty() ) {
                                acr.Roles = String.join(roles, ';');
                                acrsToUpsert.add(acr);
                            } else { // Si no tiene mas roles => se pone a borrar
                                if( !acr.isDirect) acrsToDelete.add(acr);
                            }
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
                    String role = mapRolesForContacts?.get(x);
                    // Si el contacto, el rol y el ACR existen, se asigna el rol al ACR para ese contacto y se pone para
                    // modificar
                    if( c != null && role != null && mapACRsByContactId.containsKey(c.Id) ) {
                        mapACRsByContactId.get(c.Id).Roles = role;
                        acrsToUpsert.add(mapACRsByContactId.get(c.Id));
                    }
                }
            }

            // Si hay AccountContactRelation para insertar
            if( !acrsToUpsert.isEmpty() ) {
                upsert acrsToUpsert;
            }

            // Si hay AccountContactRelation para borrar
            if( !acrsToDelete.isEmpty() ) {
                delete acrsToDelete;
            }
        }
    }
}