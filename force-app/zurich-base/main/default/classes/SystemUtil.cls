/**
 * Clase con utilidades génericas
 **
 * @author nts
 * @date 02/04/2020
 * @testClass Test_SystemUtil
 */
public without sharing class SystemUtil
{
    private static final String ADMINSETUP_LABEL = 'AdminSetup';
    private static final String EMAIL_TO_RETURN = 'mng.dev';

    // Map<String, String> legalIdentityByShort = new Map<String, String> {
    //     'GI' => Label.GeneralInsurance,
    //     'Life' => Label.LifeInsurance
    // };

    private static final Map<String, String> legalIdentityByLabel = new Map<String, String> {
        Label.GeneralInsurance => 'GI',
        Label.LifeInsurance => 'Life'
    };

    /**
     * Método que obtiene los settings de metadatos para la configutracion de errores en log.
     *
     *
     * @return Estructura con los metadatos
     *
     * @author nts
     * @date 24/02/2020
     */
    public static ErrorManagementSetting__mdt getErrorLogSettingsMetadata()
    {
        List<ErrorManagementSetting__mdt> results = new List<ErrorManagementSetting__mdt>();

        results = [
            SELECT
            Id,
            DeveloperName,
            MasterLabel,
            Language,
            NamespacePrefix,
            Label,
            QualifiedApiName,
            Min_Log_Level__c,
            Notify_To__c,
            Notify_From__c,
            Send_Email__c
            FROM ErrorManagementSetting__mdt
            WHERE MasterLabel = :Label.ErrorMetadata
        ];

        if ( !results.isEmpty() )
        {
            return results[0];
        }

        return null;
    }

    /**
     * Método que obtiene los settings de metadatos para la configutracion genérica de Salesforce.
     **
     * @return Estructura con los metadatos
     *
     * @author nts
     * @date 22/04/2020
     *
     * @udpate nts (agonzalezisasi) - 27/10/2020 - Include Multi-Partner logic
     * @udpate nts (adelgado) - 24/11/2020 - Include ExternalJobQueueBatchJobs__c
     */
    public static AdminSetup__mdt getAdminSetupMetadata()
    {
        List<AdminSetup__mdt> results = new List<AdminSetup__mdt>();

        // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
        results = [
            SELECT
            Id,
            DeveloperName,
            MasterLabel,
            Language,
            NamespacePrefix,
            Label,
            QualifiedApiName,
            NumberDaysDeleteErrors__c,
            NumberDaysDeleteRequests__c,
            NumberDaysDeleteRequestErrors__c,
            NumDaysDeleteLeads__c,
            IBACaseworker__c,
            MaxRetries__c,
            IBA_Auth_token__c,
            IBA_endpoint__c,
            IBA_EMEA_Authorization_token__c,
            IBA_EMEA_endpoint__c,
            IBA_Multi_Partner_endpoint__c,
            IBA_Multi_Partner_Authorization_token__c,
            SameMasterPolicy__c,
            IBA_EMEA_Non_Country__c,
            IBA_Multi_Partner_Origin__c,
            Multi_Partners__c,
            WS_Service_Process_Request__c,
            WS_Service_Quote_Entry__c,
            WS_Source_IBA__c,
            WS_Source_IBA_Multi_Partner__c,
            IBA_EMEA_Prefix__c,
            ExternalJobQueueBatchJobs__c,
            WS_Source_IBA_EMEA__c,
            NumDaysCallAtribution__c
            FROM AdminSetup__mdt
            WHERE MasterLabel = :ADMINSETUP_LABEL
        ];

        if ( !results.isEmpty() )
        {
            return results[0];
        }

        return null;
    }

    /**
     * Método que enmascara una dirección de email para dev
     **
     * @param String dirección de email
     * @param String código o prefijo (opcional)
     * @return String dirección de email transformada para dev
     *
     * @author nts
     * @date 24/02/2020
     */

    public static String maskEmail(String emailToMask, String code)
    {
        if ( !String.isBlank(emailToMask) )
        {
            String[] aux = emailToMask.split('@', 2);
            if ( aux != null && !aux.isEmpty() )
            {
                String emailToReturn = aux[0] + '@';
                if ( !String.isBlank(code) )
                {
                    emailToReturn += code + '-';
                }

                return emailToReturn + EMAIL_TO_RETURN;
            }
        }

        return emailToMask;
    }

    /**
     * Método que comprueba si la fecha es válida para insertar en Salesforce: yyyy-mm-dd
     **
     * @param String fecha
     * @return Boolean true -> valid, false -> invalid
     *
     * @author nts
     * @date 02/04/2020
     */
    public static Boolean isValidDate(String strDate)
    {
        return Pattern.matches(
            '[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])',
            strDate
            );
    }

    /**
     * Método que genera el hash de seguridad de un string
     **
     * @param String id
     * @return String
     *
     * @author iortega
     * @date 14/05/2020
     */
    public static String generateHash(String id)
    {
        // Se contruye el hash a partir del contactId recibido
        Blob data = Blob.valueOf(id);
        Blob digest = Crypto.generatedigest('SHA256', data); // SHA256
        String returnHash = EncodingUtil.convertToHex(digest);
        return returnHash;
    }

    /**
     * Método que obtiene las peticiones externas sin procesar
     **
     * @author nbizkarra
     * @date 04/05/2020
     */
    public static String getExternalRequests()
    {
        String query =
            'SELECT Id, ' +
            'Origin__c, ' +
            'Country__c, ' +
            'Entity__c, ' +
            'Json__c, ' +
            'Processed__c, ' +
            'ProcessedDate__c, ' +
            'ProcessResult__c, ' +
            'Error_Log__c, ' +
            'Sent__c, ' +
            'Timestamp__c,' +
            'Retry__c ' +
            'FROM ExternalRequest__c ' +
            'WHERE Processed__c = false ' +
            'AND RecordType.DeveloperName = \'GENERIC\' ' +
            'ORDER BY CreatedDate ';

        return query;
    }
    /**
     * Método que obtiene las peticiones externas procesadas y sin enviar respuesta
     **
     * @author nbizkarra
     * @date 04/05/2020
     */
    public static String getProcessedExternalRequests()
    {
        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();

        String query =
            'SELECT Id, ' +
            'Timestamp__c, ' +
            'Origin__c, ' +
            'Country__c, ' +
            'Entity__c, ' +
            'Json__c, ' +
            'Processed__c, ' +
            'ProcessedDate__c, ' +
            'ProcessResult__c, ' +
            'Error_Log__c, ' +
            'Sent__c, ' +
            'Retry__c ' +
            'FROM ExternalRequest__c ' +
            'WHERE Processed__c = true AND RecordType.DeveloperName = \'GENERIC\' AND Sent__c = false AND Retry__c <' +
            adminSetup.MaxRetries__c +
            ' ' +
            'ORDER BY CreatedDate';

        return query;
    }

    /**
     * Método que obtiene las peticiones externas procesadas para borarlas
     **
     * @author nbizkarra
     * @change adelgado 13/11/2020 Convertir valor decimal a integer para incluirlo en la query
     * @date 04/05/2020
     */
    public static String getOldExternalRequests()
    {
        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();

        String query =
            'SELECT Id from ExternalRequest__c where CreatedDate < LAST_N_DAYS:' +
            adminSetup.NumberDaysDeleteRequests__c.intValue();

        return query;
    }

    /**
     * Método que obtiene los errores de peticiones externas procesadas para borrarlas
     **
     * @author adelgado
     * @date 03/12/2020
     */
    public static String getOldExternalRequestErrors()
    {
        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();

        String query =
            'SELECT Id from ExternalRequestError__c where CreatedDate < LAST_N_DAYS:' +
            adminSetup.NumberDaysDeleteRequestErrors__c.intValue();

        return query;
    }

    /**
     * Método que obtiene los error logs para borrarlos
     **
     * @author nbizkarra
     * @date 04/05/2020
     */

    public static String getErrorLogs()
    {
        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();

        String query =
            'SELECT Id from Error_Log__c where CreatedDate < LAST_N_DAYS:' +
            adminSetup.NumberDaysDeleteErrors__c.intValue();

        return query;
    }
    /**
     * Método que obtiene las quotes para borrarlas
     **
     * @author nbizkarra
     * @date 04/05/2020
     */
    public static String getQuotesToDelete()
    {
        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();

        String query =
            'SELECT Id, (Select id from Casos__r), (Select itemId__c from OrderItems) from Order where LastModifiedDate < LAST_N_DAYS:' +
            adminSetup.NumDaysDeleteLeads__c.intValue() +
            ' AND (RecordType.DeveloperName=\'' +
            Label.QuoteGI +
            '\' OR RecordType.DeveloperName=\'' +
            Label.QuoteLife +
            '\')';

        return query;
    }

    /**
     * Método que obtiene los leads para borrarlos
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static String getLeadsToDelete()
    {
        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();

        // nts (nbizkarra) -  17/dic/2020 - Modificación de borrado de Subscribers
            /* Los Leads que no sean suscriptores se borrarán (IsSubscriber__c = false)
               Los Subscriptores que se hayan desuscrito se borrarán (IsSubscriber__c = true AND HasOptedOutOfEmail=true)
               Los Leads que sean Suscriptores no se borrarán, solo se mantendrá la información del suscriptor. Todos los
               campos de la tarificación deben ser borrados (IsSubscriber__c = true AND CustomerNum__c !=null AND HasOptedOutOfEmail = false)  */

        String query =
            'SELECT Id , AccountId, IsSubscriber__c, HasOptedOutOfEmail, Balance__c, Birthdate, CNO__c,' +
            'CreditCard__c, CustomerID__c, CustomerNum__c, DNI__c, EmailHash__c, Gender__c, Job__c,' +
            'JobPosition__c, MailingCity, MailingCountry, MailingPostalCode, MailingState, MailingStreet,' +
            'MasterPolicy__c, MasterPolicyDesc__c, MasterPolicyNum__c, MobilePhone, MonthExpiryDate__c, ' +
            'Nationality__c, YearExpiryDate__c, Abandoned_Lead__c from Contact '+
            'where (RecordType.DeveloperName=\'' +
            Label.LeadLife +
            '\' OR RecordType.DeveloperName=\'' +
            Label.LeadGI +
            '\')' +
            'AND Id NOT IN (SELECT ContactId__c  from Order )' +
            'AND Id NOT IN (SELECT ContactId from Case)' +
            'AND (' +
                '(( IsSubscriber__c = false OR (IsSubscriber__c = true AND CustomerNum__c !=null)) AND CreatedDate < LAST_N_DAYS:'+ 
                    adminSetup.NumDaysDeleteLeads__c.intValue() +')'+
                    // nts (nbizkarra) - 14/ene/2021 - Un subscriptor que no es lead, si se desuscribe se borra sin tener en cuenta los 10 días
                'OR (IsSubscriber__c = true AND HasOptedOutOfEmail=true AND CustomerNum__c =null) ' +
            ')';

        return query;
    }

    /**
     * Método que obtiene los masters para borrarlos
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static String getMastersToDelete()
    {
        String query =
            ' SELECT Id from Account WHERE Id NOT IN  (select AccountId from Contact) ' +
            'AND ID NOT IN (select AccountId from Order) AND RecordType.Name=\'' +
            Label.Master +
            '\'';

        return query;
    }

    /**
     * Método que obtiene los orders que han sido procesados
     **
     * @author nbizkarra
     * @date 17/06/2020
     **/
    public static String getOutdatedOrderInfo()
    {
        String query =
            'SELECT Id , After_Processing_Check__c, (Select id from OrderItems where Updated__c=false),' +
            '(Select id from Descuentos__r where  Updated__c=false) from Order where After_Processing_Check__c=true';

        return query;
    }

    /**
     * Método que obtiene los leads (subscribers) generados a través de web-to-lead
     **
     * @author nbizkarra
     * @date 16/11/2020
     **/
    public static String getSubscribers()
    {
        String query =
            'SELECT id, FirstName, Email, LastName, CheckGI__c, CheckLife__c, Country, LeadSource  from Lead ';

        return query;
    }

    /**
     * Método que obtiene el ID del tipo de registro del objeto Contacto
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static ID getContactRecordTypeIdByName(String name)
    {
        return Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
               .get(name)
               .getRecordTypeId();
    }

    /**
     * Método que obtiene el ID del tipo de registro del objeto Cuenta
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static ID getAccountRecordTypeIdByName(String name)
    {
        ID identifier;

        if ( name.equals(Label.Partner) )
        {
            identifier = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                         .get(name)
                         .getRecordTypeId();

            //el recordtypeId que devuelve para master no es el correcto, workaround:
        }
        else if ( name.equals(Label.Master) )
        {
            RecordType rt = [
                SELECT id
                FROM RecordType
                WHERE sObjectType = 'Account' AND DeveloperName = :Label.Master
            ];
            identifier = rt.id;
        }

        return identifier;
    }

    /**
     * Método que obtiene el ID del tipo de registro del objeto Pedido
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static ID getOrderRecordTypeIdByName(String name)
    {
        return Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName()
               .get(name)
               .getRecordTypeId();
    }

    /**
     * Método que obtiene el ID del tipo de registro de siniestro
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static ID getClaimRecordType()
    {
        return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
               .get(Label.Claim)
               .getRecordTypeId();
    }

    /**
     * Método que obtiene el id del usuario integrador para asignarlo como owner de los registros
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static User recordOwnerSelector()
    {
        User user = [SELECT ID FROM User WHERE Name = :Label.RecordOwner];

        return user;
    }

    /**
     * Método que obtiene todos los registros de Partner existentes
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static Map<String, Account> partnerSelector(SET<String> keys)
    {
        Map<String, Account> mapaPartner = new Map<String, Account>();
        List<Account> listaPartner = [
            SELECT Id, Name, Masterpolicy__c
            FROM Account
            WHERE RecordType.Name = :Label.Partner AND Masterpolicy__c IN :keys
        ];
        //Rellenar el mapa cuyo key es el número de Masterpolicy de IBA
        for (Account acc : listaPartner)
        {
            mapaPartner.put(acc.Masterpolicy__c, acc);
        }

        return mapaPartner;
    }

    /**
     * Método que obtiene todos los registros de Contacto existentes
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static Map<String, Contact> contactsSelector(SET<String> keys)
    {
        Map<String, Contact> mapaContactos = new Map<String, Contact>();
        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
        // nts (nbizkarra) - 07/ene/2021 - Include interaction tasks
        Date startDate = Date.today().addDays(-Integer.valueOf(adminSetup.NumDaysCallAtribution__c));

        List<Contact> listaContactos = [
            SELECT
            Id,
            DNI__c,
            Email,
            MobilePhone,
            Birthdate,
            FirstName,
            LastName,
            CustomerNum__c,
            LegalEntity__c,
            MailingStreet,
            MailingPostalCode,
            MailingCity,
            MailingState,
            MailingCountry,
            Nationality__c,
            CreditCard__c,
            MonthExpiryDate__c,
            YearExpiryDate__c,
            Job__c,
            JobPosition__c,
            CNO__c,
            Gender__c,
            Status__c,
            LastPolicyDate__c,
            MasterPolicy__c,
            MasterPolicyNum__c,
            MasterPolicyDesc__c,
            Balance__c,
            RecordTypeId,
            AccountId,
            Account.CustomerNum__c,
            Account.CustomerNum_EMEA__c,
            Account.CustomerNum_Partner__c,
            SourceCountry__c,
            (Select id , WhatId, OwnerId from Tasks where RecordType.DeveloperName =: Label.Interaction and CallResult__c=: Label.Valid and 
            CustomerInterest__c =: Label.Interested and CreatedDate >= :startDate ) 
            FROM Contact
            WHERE CustomerNum__c IN :keys
        ];

        //Rellenar el mapa cuyo key es el número de cliente de IBA
        for (Contact con : listaContactos)
        {
            mapaContactos.put(con.CustomerNum__c, con);
        }

        return mapaContactos;
    }

    /**
     * Método que obtiene todos los registros de Contacto existentes por email
     **
     * @author nbizkarra
     * @date 16/11/2020
     **/
    public static Map<String, List<Contact> > contactsSelectorEmail(SET<String> emails)
    {
        Map<String, List<Contact> > mapaContactos = new Map<String, List<Contact> >();

        List<String> developerNames = new List<String> {
            Label.CustomerGI, Label.CustomerLife, Label.LeadGI, Label.LeadLife
        };

        List<Contact> listaContactos = [
            SELECT
            Id,
            DNI__c,
            Email,
            MobilePhone,
            Birthdate,
            FirstName,
            LastName,
            CustomerNum__c,
            LegalEntity__c,
            MailingStreet,
            MailingPostalCode,
            MailingCity,
            MailingState,
            MailingCountry,
            Nationality__c,
            CreditCard__c,
            MonthExpiryDate__c,
            YearExpiryDate__c,
            Job__c,
            JobPosition__c,
            CNO__c,
            Gender__c,
            Status__c,
            LastPolicyDate__c,
            MasterPolicy__c,
            MasterPolicyNum__c,
            MasterPolicyDesc__c,
            Balance__c,
            RecordTypeId,
            AccountId,
            Account.CustomerNum__c,
            Account.CustomerNum_EMEA__c,
            Account.CustomerNum_Partner__c,
            SourceCountry__c,
            Partner__c
            FROM Contact
            WHERE email IN :emails
            AND RecordType.DeveloperName IN :developerNames
        ];

        //Rellenar el mapa cuyo key es el email
        for (Contact con : listaContactos)
        {
            if( mapaContactos.containsKey(con.Email) )
            {

                mapaContactos.get(con.Email).add(con);

            }
            else
            {

                mapaContactos.put(con.Email, new List<Contact> {con});

            }
        }

        return mapaContactos;
    }

    /**
     * Método que obtiene todos los registros de Contacto existentes por email (únicamente los subscribers)
     **
     * @author nbizkarra
     * @date 17/11/2020
     **/
    /*
       public static Map<String, List<Contact>> contactsSelectorSubscribers(SET<String> emails)
       {
        Map<String, List<Contact>> mapaContactos = new Map<String, List<Contact>>();

        List<Contact> listaContactos = [
            SELECT
            Id,
            DNI__c,
            Email,
            MobilePhone,
            Birthdate,
            FirstName,
            LastName,
            CustomerNum__c,
            LegalEntity__c,
            MailingStreet,
            MailingPostalCode,
            MailingCity,
            MailingState,
            MailingCountry,
            Nationality__c,
            CreditCard__c,
            MonthExpiryDate__c,
            YearExpiryDate__c,
            Job__c,
            JobPosition__c,
            CNO__c,
            Gender__c,
            Status__c,
            LastPolicyDate__c,
            MasterPolicy__c,
            MasterPolicyNum__c,
            MasterPolicyDesc__c,
            Balance__c,
            RecordTypeId,
            AccountId,
            Account.CustomerNum__c,
            Account.CustomerNum_EMEA__c,
            Account.CustomerNum_Partner__c,
            SourceCountry__c,
            Partner__c
            FROM Contact
            WHERE email IN :emails
            AND CustomerNum__c = null
            AND Birthdate = null
            AND IsSubscriber__c  = true
        ];

        //Rellenar el mapa cuyo key es el email
        for (Contact con : listaContactos)
        {
            if(mapaContactos.containsKey(con.Email)) {

                mapaContactos.get(con.Email).add(con);

            } else {

                mapaContactos.put(con.Email, new List<Contact>{con});

            }
        }

        return mapaContactos;
       }*/

    /**
     * Método que obtiene todos los registros de contacto existentes con matchcode email+fechaNacimiento
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    /*public static Map<String, Contact> contactsSelectorEmailBirthDateLECountry(
       SET<String> keys
       ) {
       Map<String, Contact> mapaContactos = new Map<String, Contact>();
       List<Contact> listaContactos = [
        SELECT
          Id,
          DNI__c,
          Email,
          MobilePhone,
          Birthdate,
          FirstName,
          LastName,
          CustomerNum__c,
          LegalEntity__c,
          MailingStreet,
          MailingPostalCode,
          MailingCity,
          MailingState,
          MailingCountry,
          Nationality__c,
          CreditCard__c,
          MonthExpiryDate__c,
          YearExpiryDate__c,
          Job__c,
          JobPosition__c,
          CNO__c,
          Gender__c,
          Status__c,
          MasterPolicy__c,
          MasterPolicyNum__c,
          MasterPolicyDesc__c,
          Balance__c,
          RecordTypeId,
          AccountId,
          Account.CustomerNum__c,
          Account.CustomerNum_EMEA__c,
          Account.CustomerNum_Partner__c,
          SourceCountry__c
        FROM Contact
        WHERE Email IN :keys
       ];

       for (Contact con : listaContactos) {
        String legalEntityName;
        if (con.LegalEntity__c.equals(Label.GeneralInsurance)) {
          legalEntityName = 'GI';
        } else {
          legalEntityName = 'Life';
        }

        // EMEA
        String matchCode =
          con.Email +
          String.valueOfGmt(con.Birthdate) +
          legalEntityName +
          con.SourceCountry__c;
        // END EMEA

        mapaContactos.put(matchCode, con);
       }

       return mapaContactos;
       }*/

    /**
     * Método que obtiene todos los registros de contacto existentes con matchcode email+fechaNacimiento+EntidadLegal
     *
     * @author nbizkarra
     * @date 04/05/2020
     **/
    /*public static Map<String, Contact> contactsSelectorEmailBirthDateLE(
       SET<String> keys
       ) {
       Map<String, Contact> mapaContactos = new Map<String, Contact>();
       List<Contact> listaContactos = [
        SELECT
          Id,
          DNI__c,
          Email,
          MobilePhone,
          Birthdate,
          FirstName,
          LastName,
          CustomerNum__c,
          LegalEntity__c,
          MailingStreet,
          MailingPostalCode,
          MailingCity,
          MailingState,
          MailingCountry,
          Nationality__c,
          CreditCard__c,
          MonthExpiryDate__c,
          YearExpiryDate__c,
          Job__c,
          JobPosition__c,
          CNO__c,
          Gender__c,
          Status__c,
          MasterPolicy__c,
          MasterPolicyNum__c,
          MasterPolicyDesc__c,
          Balance__c,
          RecordTypeId,
          AccountId,
          Account.CustomerNum__c,
          Account.CustomerNum_EMEA__c,
          Account.CustomerNum_Partner__c,
          SourceCountry__c
        FROM Contact
        WHERE Email IN :keys
       ];

       String matchCode;
       for (Contact con : listaContactos) {
        String legalEntityName;
        if (con.LegalEntity__c.equals(Label.GeneralInsurance)) {
          legalEntityName = 'GI';
        } else {
          legalEntityName = 'Life';
        }

        matchCode =
          con.Email +
          String.valueOfGmt(con.Birthdate) +
          legalEntityName;
        mapaContactos.put(matchCode, con);
       }

       return mapaContactos;
       }*/

    /**
     * Método que obtiene todos los registros de contacto existentes con matchcode email+fechaNacimiento
     *
     * @author gpacho
     * @date 18/09/2020
     **/
    /*public static Map<String, Contact> contactsSelectorEmailBirthDate(
       SET<String> keys
       ) {
       Map<String, Contact> mapaContactos = new Map<String, Contact>();
       List<Contact> listaContactos = [
        SELECT
          Id,
          DNI__c,
          Email,
          MobilePhone,
          Birthdate,
          FirstName,
          LastName,
          CustomerNum__c,
          LegalEntity__c,
          MailingStreet,
          MailingPostalCode,
          MailingCity,
          MailingState,
          MailingCountry,
          Nationality__c,
          CreditCard__c,
          MonthExpiryDate__c,
          YearExpiryDate__c,
          Job__c,
          JobPosition__c,
          CNO__c,
          Gender__c,
          Status__c,
          MasterPolicy__c,
          MasterPolicyNum__c,
          MasterPolicyDesc__c,
          Balance__c,
          RecordTypeId,
          AccountId,
          Account.CustomerNum__c,
          Account.CustomerNum_EMEA__c,
          Account.CustomerNum_Partner__c,
          SourceCountry__c
        FROM Contact
        WHERE Email IN :keys
       ];

       String matchCode;
       for (Contact con : listaContactos) {
        matchCode = con.Email + String.valueOfGmt(con.Birthdate);
        mapaContactos.put(matchCode, con);
       }
       return mapaContactos;
       }*/

    /**
     * Método que obtiene todos los registros de contacto existentes con matchcode email+fechaNacimiento
     *
     * @author gpacho
     * @date 18/09/2020
     **/
    public static void contactsSelectorMatchCode(
        SET<String> emails,
        SET<String> mobiles,
        Map<String, Contact> mapEmailBirthLECountry,
        Map<String, Contact> mapEmailBirthLE,
        Map<String, Contact> mapEmailBirth,
        Map<String, List<Contact> > mapSubscribers
        )
    {
        //Map<String, Contact> mapaContactos = new Map<String, Contact>();
        // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
        List<Contact> listaContactos = [
            SELECT
            Id,
            DNI__c,
            Email,
            MobilePhone,
            Birthdate,
            FirstName,
            LastName,
            CustomerNum__c,
            LegalEntity__c,
            MailingStreet,
            MailingPostalCode,
            MailingCity,
            MailingState,
            MailingCountry,
            Nationality__c,
            CreditCard__c,
            MonthExpiryDate__c,
            YearExpiryDate__c,
            Job__c,
            JobPosition__c,
            CNO__c,
            Gender__c,
            Status__c,
            MasterPolicy__c,
            MasterPolicyNum__c,
            MasterPolicyDesc__c,
            Balance__c,
            RecordTypeId,
            AccountId,
            Account.CustomerNum__c,
            Account.CustomerNum_EMEA__c,
            Account.CustomerNum_Partner__c,
            SourceCountry__c,
            IsSubscriber__c,
            Partner__c
            FROM Contact
            WHERE Email IN :emails 
            OR MobilePhone IN:mobiles
        ];

        String legalEntityName;
        String matchCode;
        for (Contact con : listaContactos)
        {
            legalEntityName = legalIdentityByLabel.get(con.LegalEntity__c);

            matchCode = con.Email + String.valueOfGmt(con.Birthdate);
            if( mapEmailBirth != null )
                mapEmailBirth.put(matchCode, con);

            matchCode += legalEntityName;
            if( mapEmailBirthLE != null)
                mapEmailBirthLE.put(matchCode, con);

            // EMEA + PARTNER 
            // nts (agonzalezisasi) - 08/dic/2021 - Force to find the contact by Country and Partner
            matchCode += con.SourceCountry__c + con.Partner__c;
            if( mapEmailBirthLECountry != null )
                mapEmailBirthLECountry.put(matchCode, con);

            // nts (nbizkarra) - 11/ene/2021 - build matchcode with sourceCountry + mobilephone
            matchCode = con.SourceCountry__c + con.MobilePhone + String.valueOfGmt(con.Birthdate);
            if( mapEmailBirth != null )
                mapEmailBirth.put(matchCode, con);

            matchCode += legalEntityName;
            if( mapEmailBirthLE != null)
                mapEmailBirthLE.put(matchCode, con);

            matchCode += con.SourceCountry__c + con.Partner__c;
            if( mapEmailBirthLECountry != null )
                mapEmailBirthLECountry.put(matchCode, con);


            // nts (nbizkarra) - 17/11/2020 - get subscribed contacts by email
            // Subscribers from lead
            if( mapSubscribers != null )
            {
                if( con.CustomerNum__c == null && con.Birthdate == null && con.IsSubscriber__c )
                {
                    if( mapSubscribers.containsKey(con.Email) )
                    {
                        mapSubscribers.get(con.Email).add(con);
                    }
                    else
                    {
                        mapSubscribers.put(con.Email, new List<Contact> {con});
                    }
                }
            }
        }
    }

    /**
     * Método que obtiene todos los registros de polizas existentes
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static Map<String, Order> PolicySelector(SET<String> keys)
    {
        Map<String, Order> mapaPolicy = new Map<String, Order>();
        // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
        List<Order> listaPolicy = [
            SELECT
            Id,
            AccountId,
            LegalEntity__c,
            PolicyNum__c,
            CustomerNum__c,
            Masterpolicy__c,
            PolicyContractSerial__c,
            RecordType.DeveloperName,
            (
                SELECT Id, Name, EndDate__c
                FROM PolicyVersions__r
                WHERE EndDate__c = NULL
            ),
            (
                SELECT Id, Name, DiscountId__c, DiscountPct__c, DiscountAmount__c
                FROM Descuentos__r
            ),
            (
                SELECT Id, Product2.Name, itemId__c, Active__c, ItemStatus__c
                FROM OrderItems
                WHERE Active__c = TRUE
            )
            FROM Order
            WHERE
                (RecordType.DeveloperName = :Label.PolicyGI
                                            OR RecordType.DeveloperName = :Label.PolicyLife)
            AND PolicyNum__c IN :keys
        ];

        for (Order acc : listaPolicy)
        {
            mapaPolicy.put(acc.PolicyNum__c, acc);
        }

        return mapaPolicy;
    }

    /**
     * Método que obtiene todos las quotes del mismo producto
     **
     * @author nbizkarra
     * @date 18/11/2020
     **/
    public static Map<String, List<Order> > getQuoteSameProduct(SET<String> customerNum, SET<String> products)
    {
        Map<String, List<Order> > mapaQuote = new Map<String, List<Order> >();

        List<Order> listaQuote = [
            SELECT
            Id,
            AccountId,
            ContactId__r.Id,
            ContactId__r.CustomerNum__c,
            LegalEntity__c,
            QuoteEntry__c,
            QbLastPage__c,
            CustomerNum__c,
            Masterpolicy__c,
            PolicyNum__c,
            RecordType.DeveloperName,
            GoogleCID__c,
            CampaignParams__c,
            QuoteStatus__c
            FROM Order
            WHERE
                (RecordType.DeveloperName = :Label.QuoteGI
                                            OR RecordType.DeveloperName = :Label.QuoteLife)
            AND ContactId__r.CustomerNum__c IN :customerNum
            AND Id IN (Select OrderId from OrderItem where Product2.Name IN :products)
        ];


        //Rellenar el mapa cuyo key es el customerNum
        for (Order quote : listaQuote)
        {
            if( mapaQuote.containsKey(quote.ContactId__r.CustomerNum__c) )
            {

                mapaQuote.get(quote.ContactId__r.CustomerNum__c).add(quote);

            }
            else
            {

                mapaQuote.put(quote.ContactId__r.CustomerNum__c, new List<Order> {quote});

            }
        }

        return mapaQuote;
    }

    /**
     * Método que obtiene todos los registros de quotes existentes
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static Map<String, Order> QuoteSelector(SET<String> keys)
    {
        Map<String, Order> mapaQuote = new Map<String, Order>();

        List<Order> listaQuote = [
            SELECT
            Id,
            AccountId,
            ContactId__r.Id,
            ContactId__r.CustomerNum__c,
            LegalEntity__c,
            QuoteEntry__c,
            QbLastPage__c,
            CustomerNum__c,
            Masterpolicy__c,
            PolicyNum__c,
            RecordType.DeveloperName,
            GoogleCID__c,
            CampaignParams__c,
            QuoteStatus__c,
            (SELECT Id, DiscountId__c FROM Descuentos__r)
            // (SELECT Id, Product2.Name, itemId__c,ItemAge__c,Active__c,ServiceDate,ItemStatus__c,IMEIDocumentation__c,TicketDocumentation__c,OrderId from OrderItems)
            FROM Order
            WHERE
                (RecordType.DeveloperName = :Label.QuoteGI
                                            OR RecordType.DeveloperName = :Label.QuoteLife)
            AND QuoteEntry__c IN :keys
        ];

        for (Order acc : listaQuote)
        {
            mapaQuote.put(acc.QuoteEntry__c, acc);
        }

        return mapaQuote;
    }

    /**
     * Método que obtiene todos los registros de order item existentes
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static Map<String, OrderItem> OrderItemSelector(SET<String> keys)
    {
        Map<String, OrderItem> mapaOrderItem = new Map<String, OrderItem>();

        List<OrderItem> listaOrderItem = [
            SELECT id, ItemId__c, ItemAge__c, OrderId
            FROM OrderItem
            WHERE ItemId__c IN :keys
        ];

        for (OrderItem ord : listaOrderItem)
        {
            mapaOrderItem.put(ord.ItemId__c, ord);
        }

        return mapaOrderItem;
    }

    /**
     * Método que obtiene todos los registros de Productos existentes
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static Map<String, PricebookEntry> ProductsSelector(SET<String> keys)
    {
        Map<String, PricebookEntry> mapaProducto = new Map<String, PricebookEntry>();
        List<PricebookEntry> listaProductos = [
            SELECT
            Id,
            Product2Id,
            Product2.ProductID__c,
            Product2.Name,
            Product2.Family,
            Product2.Brand__c
            FROM PricebookEntry
            WHERE Product2.ProductID__c IN :keys
        ];

        for (PricebookEntry prod : listaProductos)
        {
            mapaProducto.put(prod.Product2.ProductID__c, prod);
        }

        return mapaProducto;
    }

    /**
     * Método que obtiene todos el ID del libro de precios estandar
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static Pricebook2 getStandardPricebook()
    {
        return [SELECT Id FROM Pricebook2 WHERE name = : Label.PriceBook];
    }

    /**
     * Método que obtiene todas las covers existentes
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static Map<String, Cover__c> CoversSelector(SET<String> keys)
    {
        Map<String, Cover__c> mapaCovers = new Map<String, Cover__c>();

        List<Cover__c> listaCovers = [
            SELECT Id, PolicyProduct__r.ItemId__c, CoverId__c, ParentCoverId__c, Name
            FROM Cover__c
            WHERE CoverId__c IN :keys
        ];

        for (Cover__c cover : listaCovers)
        {
            mapaCovers.put(cover.CoverId__c, cover);
        }

        return mapaCovers;
    }

    /**
     * Método que obtiene todas los siniestros existentes
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static Map<String, Case> ClaimsSelector(SET<String> keys)
    {
        Map<String, Case> mapaClaims = new Map<String, Case>();
        List<Case> listaClaims = [
            SELECT Id, ClaimNumber__c
            FROM Case
            WHERE RecordType.DeveloperName = :Label.Claim AND ClaimNumber__c IN :keys
        ];

        for (Case claim : listaClaims)
        {
            mapaClaims.put(claim.ClaimNumber__c, claim);
        }
        return mapaClaims;
    }

    /**
     * Método que crea el json de respuesta del callout al sistema externo
     **
     * @author nbizkarra
     * @date 04/05/2020
     **/
    public static String createJSON(
        ID ID,
        String errorCode,
        String errorDescription,
        Datetime timeStamp,
        String Origin,
        String Country,
        String Entity,
        Datetime TimestampJson,
        String Json
        )
    {
        String response = '';

        if ( String.isBlank(errorDescription) )
        {
            errorDescription = ' ';
        }

        JSONGenerator jsGen = System.JSON.createGenerator(false);
        // start object ({)
        jsGen.writeStartObject();
        jsGen.writeStringField('salesForceId', ID);
        jsGen.writeStringField('errorCode', errorCode);
        jsGen.writeStringField('errorDescription', errorDescription);
        jsGen.writeStringField( 'timeStamp', String.valueOf(timeStamp) );

        jsGen.writeFieldName('json');
        jsGen.writeStartObject();
        jsGen.writeStringField('Origin', Origin);
        jsGen.writeStringField('Country', Country);
        jsGen.writeStringField('Entity', Entity);
        jsGen.writeStringField( 'TimestampJson', String.valueOf(TimestampJson) );
        jsGen.writeStringField('Json', Json);
        jsGen.writeEndObject();
        // end object (})
        jsGen.writeEndObject();
        response = jsGen.getAsString();

        return response;
    }
}