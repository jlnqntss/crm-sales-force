/**
 * @description       : Nuevo Web Service REST que extiende de la clase APEX actual "WS_BaseAPIService"
 * @author            : nts - overes
 * @last modified on  : 02-10-2023
 **/
public with sharing class SalesCRMQuoteAndBuyService
{

    private static Set<String> requiredFields = new Set<String> {'sesion', 'origen', 'nombre', 'primerApellido', 'telefono', 'ramo'};
    private static Map<String, Schema.SObjectField> picklistTypeFieldsByJsonFieldName = new Map<String, Schema.SObjectField> {
        'ramo' => Opportunity.ProductBranch__c
    };

    private enum NonNullableFieldKey {
        ACCOUNT_NATIONAL_ID,
        ACCOUNT_BIRTHDATE,
        ACCOUNT_PERSON_EMAIL,
        ACCOUNT_PREFERED_CONTACT_START,
        ACCOUNT_PREFERED_CONTACT_END
    }

    private static Map<NonNullableFieldKey, Schema.SObjectField> notNullableFields = new Map<NonNullableFieldKey, Schema.SObjectField> {
        NonNullableFieldKey.ACCOUNT_NATIONAL_ID => Account.NationalId__c,
        NonNullableFieldKey.ACCOUNT_BIRTHDATE => Account.Birthdate__c,
        NonNullableFieldKey.ACCOUNT_PERSON_EMAIL => Account.PersonEmail,
        NonNullableFieldKey.ACCOUNT_PREFERED_CONTACT_START => Account.PreferedContactStart__c,
        NonNullableFieldKey.ACCOUNT_PREFERED_CONTACT_END => Account.PreferedContactEnd__c
    };

    private static AccountsSelector accountSelector = new AccountsSelector();

    private static final String INVALID_FIELD = 'INVALID_FIELD';
    @TestVisible
    private static final String NATIONAL_ID_TYPE_NIF = 'N';

    /**
     * Método que construye el contenido para el campo "Description" con la información
     * recibida en la request
     * *
     * @author overes | 09-04-2023
     * @param requestData
     * @return String
     **/
    public static String setDesc(Lead requestData)
    {
        return 'Fecha de carnet: ' + requestData.cliente.fechaCarnet +
               '\n País de carnet: ' + requestData.cliente.paisCarnet +
               '\n Numero de oferta: ' + requestData.poliza.numeroOferta +
               '\n Fecha de inicio: ' + requestData.poliza.fechaInicio +
               '\n Precio Anual: ' + requestData.poliza.precioAnual +
               '\n Paquete: ' + requestData.poliza.paquete +
               '\n Marca: ' + requestData.poliza.Coche.marca +
               '\n Modelo: ' + requestData.poliza.Coche.Modelo +
               '\n Version: ' + requestData.poliza.Coche.Version +
               '\n Matricula: ' + requestData.poliza.Coche.matricula +
               '\n País matriculación: ' + requestData.poliza.Coche.paisMatriculacion;
    }

    /**
     * Método que recupera el Id de la oferta con el condigoIntermediario correspondiente
     * *
     * @author overes | 09-04-2023
     * @param requestData
     * @return  String
     */
    public static String getOfferIntermediaryId(Lead requestData)
    {
        List<Account> offerIntermediaryId = new List<Account>( accountSelector.findByINFOIntermediaryCode(new List<String> {requestData.poliza.codigoIntermediario}) );
        if (offerIntermediaryId.size() > 0 )
        {
            return (String) offerIntermediaryId.get(0).Id;
        }
        return null;
    }

    /**
     * Método que comprueba que los valores requeridos vinenen informados
     * *
     * @author overes | 09-02-2023
     * @param requestData
     **/
    public static void validateRequestData(Lead requestData)
    {
        checkRequiredFields(requestData);
        checkPicklistValues(requestData);
    }

    /**
     * Método que gestiona el la creación/actualización del Lead
     * *
     * @author overes | 09-03-2023
     * @param requestData
     * @return Account
     **/
    public static Account manageLead(Lead requestData)
    {
        Account acc = AccountLeadUtil.leadDuplicatesControl(requestData.cliente.idFiscal, requestData.cliente.contacto.telefono);

        // Actualizar registro a partir de los datos de la request
        if ( ( acc != null && acc.RecordTypeId.equals(accountSelector.rtLeadId) ) || acc == null )
        {
            if (acc == null)
            {
                acc = new Account();
                acc.RecordTypeId = accountSelector.rtLeadId;
                acc.PersonLeadSource__c = requestData.origen;
                acc.NationalIdType__c = NATIONAL_ID_TYPE_NIF;
            }

            fillAccountFields(acc, requestData);
            upsert acc;
        }

        return acc;
    }

    /**
     * Método que convierte el String "10:15" recibido en el Json a DateTime
     * *
     * @author overes | 09-04-2023
     * @param timeString
     * @return DateTime
     **/
    public static DateTime convertStringToDateTime(String timeString)
    {
        Date today = Date.today();

        // Divide la cadena en partes (hora y minuto)
        List<String> timeParts = timeString.split(':');

        if (timeParts.size() == 2)
        {
            Integer hour = Integer.valueOf(timeParts[0]);
            Integer minute = Integer.valueOf(timeParts[1]);

            // Combina la fecha de referencia y la hora para crear un DateTime
            DateTime dateTimeValue = DateTime.newInstance(
                today.year(), today.month(), today.day(),
                hour, minute, 0
                );
            return dateTimeValue;
        }
        else
        {
            // Manejar el caso en que la cadena no tenga el formato esperado
            return null;
        }
    }

    /**
     * Método que convierte el entero de fechaNaciemiento a Date para el Objeto Account y considerando que le llega este formato '19900121'
     * *
     * @author overes | 09-04-2023
     * @param numeroEntero
     * @return Date
     **/
    public static Date convertIntegerToDate(Integer inputInteger)
    {
        String integerAsText = String.valueOf(inputInteger);
        // Los primeros 4 caracteres son el año
        String year = integerAsText.substring(0, 4);
        // Los siguientes 2 caracteres son el mes
        String month = integerAsText.substring(4, 6);
        // Los últimos 2 caracteres son el día
        String day = integerAsText.substring(6, 8);

        Date dateFromInteger = Date.newInstance( Integer.valueOf(year), Integer.valueOf(month), Integer.valueOf(day) );

        return dateFromInteger;
    }

    /**
     * Método que gestiona la información de la oferta
     * *
     * @author overes | 09-03-2023
     * @param requestData
     * @return Opportunity
     **/
    public static Opportunity manageOpportunity(Account leadAccount, Lead requestData)
    {
        Opportunity offer = new Opportunity();
        offer.SessionId__c = requestData.sesion;
        // Es un campo reuerido para la inserción de Opportunity y se asigna un valor quererido en la request
        offer.Name = requestData.poliza.numeroOferta;
        offer.InfoQuoteNumber__c = requestData.poliza.numeroOferta;
        offer.ResultingPolicyNumber__c = requestData.poliza.numeroPoliza;
        offer.IntermediaryCode__c = requestData.poliza.codigoIntermediario;
        offer.CarRegistration__c = requestData.poliza.Coche.matricula;

        offer.CloseDate = Date.today().addDays(10);
        offer.AccountId = leadAccount.Id;
        offer.IssuedOnline__c = true;
        offer.IntermediaryId__c = getOfferIntermediaryId(requestData);
        offer.PersonLeadSource__c = requestData.origen;
        offer.ProductBranch__c = requestData.poliza.ramo;
        offer.Description = setDesc(requestData);

        if ( String.isNotBlank(requestData.poliza.numeroPoliza)  && String.isNotBlank(requestData.poliza.numeroOferta) )
        {
            offer.StageName = 'Cerrada-Ganada';
            offer.CloseDate = Date.today();
        }

        return offer;
    }

    /**
     * Método que gestiona la creación/actualización de la Poliza
     * *
     * @author overes | 09-04-2023
     * @param leadAccount
     * @param requestData
     * @return Opportunity
     **/
    public static Policy__c managePolicy(Account leadAccount, Lead requestData)
    {
        Policy__c pol = new Policy__c();
        pol.Name = requestData.poliza.numeroPoliza;
        pol.InfoPolicyNumber__c = requestData.poliza.numeroPoliza;
        pol.InfoQuoteNumber__c = requestData.poliza.numeroOferta;
        pol.PolicyHolder__c = leadAccount.Id;
        pol.IssuedOnline__c = true;
        pol.InfoCreatedDate__c = Date.today();
        if( requestData.poliza.fechaInicio != null )
        {
            pol.StartDate__c = convertIntegerToDate(requestData.poliza.fechaInicio);
        }
        else
        {
            pol.StartDate__c = null;
        }
        pol.IntermediaryId__c = getOfferIntermediaryId(requestData);
        pol.Intermediary_Code__c = requestData.poliza.codigoIntermediario;

        return pol;
    }

    /**
     * Método que llama a la clase AccountLeadOpportunityQueueJob con un delay de 30min
     * en caso que el número de Póliza sea nulo pero el número de oferta no
     * *
     * @author overes | 09-25-2023
     * @param acc
     * @param offer
     * @param postalCode
     * @param phone
     **/
    public static void manageOfferStage(Account acc, Opportunity offer, Lead requestData, Id leadId)
    {
        if ( String.isBlank(requestData.poliza.numeroPoliza) )
        {
            if ( String.isBlank(requestData.poliza.numeroOferta) )
            {
                offer.Name = ( 'OF' + Datetime.now().getTime() / 1000 + leadId.to15() ).left(120);
                offer.StageName = 'App Submitted';
                if (requestData.cliente.contacto.quiereLlamada == 'S')
                {
                    AccountLeadOpportunityQueueJob.processOpportunityAndPolicy(acc, offer, null, requestData.cliente.contacto.codigoPostal, acc.Phone);
                }
                else
                {
                    System.enqueueJob(new AccountLeadOpportunityQueueJob(acc, offer, null, requestData.cliente.contacto.codigoPostal, acc.Phone), 5);
                }
            }
            else
            {
                offer.StageName = 'Quoted';
                System.enqueueJob(new AccountLeadOpportunityQueueJob(acc, offer, null, requestData.cliente.contacto.codigoPostal, acc.Phone), 10);
            }

        }
    }

    /**
     * Método que valida que los campos requeridos estén rellenos
     * *
     * @author overes | 09-02-2023
     * @param requestData
     **/
    @TestVisible
    private static void checkRequiredFields(Lead requestData)
    {
        Set<String> receivedFieldsLead = requestData.getReceivedFields();
        Set<String> receivedFieldsCliente = requestData.cliente.getReceivedFields();
        Set<String> receivedFieldsContacto = requestData.cliente.contacto.getReceivedFields();
        Set<String> receivedFieldsPoliza = requestData.poliza.getReceivedFields();
        Set<String> missedRequiredFields = new Set<String>();

        for (String requiredField : requiredFields)
        {
            if ( !receivedFieldsLead.contains(requiredField) && !receivedFieldsCliente.contains(requiredField) && !receivedFieldsContacto.contains(requiredField) && !receivedFieldsPoliza.contains(requiredField) )
            {
                missedRequiredFields.add(requiredField);
            }
        }

        if ( !missedRequiredFields.isEmpty() )
        {
            throw new QuoteAndBuyException( INVALID_FIELD, 'The following required fields are missing: ' + String.join(missedRequiredFields, ', ') );
        }
    }

    /**
     * Comprobando los valores informado en la Picklist
     * *
     * @author overes | 09-03-2023
     * @param requestData
     **/
    @TestVisible
    private static void checkPicklistValues(Lead requestData)
    {
        Set<String> invalidFields = new Set<String>();

        for ( String jsonField : picklistTypeFieldsByJsonFieldName.keySet() )
        {
            String requestDataFieldValue = (String) requestData.get(jsonField);

            if(requestDataFieldValue != null)
            {
                // Se obtienen todos lo valores de la picklist
                List<Schema.PicklistEntry> picklistEntries = picklistTypeFieldsByJsonFieldName.get(jsonField).getDescribe().getPicklistValues();
                List<String> picklistValues = new List<String>();

                for (Schema.PicklistEntry picklistEntry : picklistEntries)
                {
                    if ( picklistEntry.isActive() )
                    {
                        picklistValues.add( picklistEntry.getValue() );
                    }
                }

                if ( !picklistValues.contains(requestDataFieldValue) )
                {
                    invalidFields.add(jsonField);
                }
            }
        }

        if ( !invalidFields.isEmpty() )
        {
            throw new QuoteAndBuyException( INVALID_FIELD,'The following fields send invalid values for the picklist entries: ' + String.join(invalidFields, ', ') );
        }
    }

    /**
     * Método que rellena los campos del registro Account y se almacena en SF
     * *
     * @author overes | 09-02-2023
     * @param accountToFill se rellena con los datos del Lead
     * @param requestData contiene la configuración del Lead
     *
     * @change overes 02/10/2023 Se añade una condición para informar el campo
     * LastName únicamente si la cuenta que se pasa por parámetro se encuentra en
     * Salesforce.
     **/
    @TestVisible
    private static void fillAccountFields(Account acc, Lead requestData)
    {
        // Si el Id no está informado se considera que no se ha encontrado una cuenta duplicada en el sistema
        if ( !acc.isSet(Account.Id) )
        {
            acc.LastName = requestData.cliente.nombre + ' ' + requestData.cliente.primerApellido;

            // fpalomo - 17/10/2023 - CV-1159
            if (String.isNotBlank(requestData.cliente.segundoApellido))
            {
                acc.LastName += ' ' + requestData.cliente.segundoApellido;
            }
        }

        acc.Phone = requestData.cliente.contacto.telefono;
        acc.Description = setDesc(requestData);
        setNationalIdType( acc, requestData.cliente.idFiscal );

        for ( NonNullableFieldKey notNullableField : notNullableFields.keySet() )
        {
            Object nonNullableFieldValue = getNonNullableFieldValue(notNullableField, requestData);

            if (nonNullableFieldValue != null)
            {
                acc.put( notNullableFields.get(notNullableField), nonNullableFieldValue );
            }
        }
    }

    /**
     * Devuelve un valor asociado a cada clave del enum NonNullableFieldKey
     * *
     * @param key clave del campo a devolver
     * @param requestData contiene la configuración del Lead
     **/
    private static Object getNonNullableFieldValue(NonNullableFieldKey key, Lead requestData)
    {
        switch on key {
            when ACCOUNT_NATIONAL_ID {
                return requestData.cliente.idFiscal;
            }
            when ACCOUNT_BIRTHDATE {
                Integer birthdate = requestData.cliente.fechaNacimiento;
                return birthdate != null ? convertIntegerToDate(birthdate) : null;
            }
            when ACCOUNT_PERSON_EMAIL {
                return requestData.cliente.contacto.email;
            }
            when ACCOUNT_PREFERED_CONTACT_START {
                String contactStart = requestData.cliente.contacto.horaDesde;
                return contactStart != null ? convertStringToDateTime(contactStart) : null;
            }
            when ACCOUNT_PREFERED_CONTACT_END {
                String contactEnd = requestData.cliente.contacto.horaHasta;
                return contactEnd != null ? convertStringToDateTime(contactEnd) : null;
            }
            when else {
                return null;
            }
        }
    }

    /**
     * @description Método que se encarga de informar el campo 'NationalIdType__c'
     * con valor 'N' (NIF). Se informará siempre y cuando el parámetro 'documentId'
     * no sea nulo y la cuenta sobre la que se informará el campo `NationalIdType__c'
     * (accountToFill) no tenga este último campo informado o no tenga el campo
     * 'NationalId__c' informado.
     * @author overes | 09-21-2023
     * @param accountToFill
     * @param documentId
     **/
    @TestVisible
    private static void setNationalIdType(Account acc, String documentId)
    {
        if ( String.isNotBlank(documentId) && (acc.NationalIdType__c == null || acc.NationalId__c == null) )
        {
            acc.NationalIdType__c = NATIONAL_ID_TYPE_NIF;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*   Clase que representa los valores que tiene la solicitud de QuoteAndBuy   */
    /* -------------------------------------------------------------------------- */
    public class Lead
    {
        @TestVisible
        private Map<String, Object> valuesByProperty {
            get {
                if (valuesByProperty == null)
                {
                    valuesByProperty = new Map<String, Object>();
                }
                return valuesByProperty;
            }
            set;
        }
        // Propiedades para el campo "sesion"
        public String sesion {
            get {
                return (String) valuesByProperty.get('sesion');
            }
            set {
                valuesByProperty.put('sesion', value);
            }
        }

        // Propiedades para el campo "origen"
        public String origen {
            get {
                return (String) valuesByProperty.get('origen');
            }
            set {
                valuesByProperty.put('origen', value);
            }
        }

        // Propiedades para el campo "cliente"
        public Cliente cliente {
            get {
                if (cliente == null)
                {
                    cliente = new Cliente();
                }
                return cliente;
            }
            set;
        }

        // Propiedades para el campo "poliza"
        public Poliza poliza {
            get {
                if (poliza == null)
                {
                    poliza = new Poliza();
                }
                return poliza;
            }
            set;
        }

        // Propiedades para otros campos anidados o de nivel superior si es necesario
        private Set<String> getReceivedFields()
        {
            return valuesByProperty.keySet().clone();
        }
        @TestVisible
        private Object get(String property)
        {
            return valuesByProperty.get(property);
        }
    }

    /* ----- * Clase interna para la propiedad "cliente" de la clase "Lead" ----- */
    public class Cliente
    {
        @TestVisible
        private Map<String, Object> valuesByProperty {
            get {
                if (valuesByProperty == null)
                {
                    valuesByProperty = new Map<String, Object>();
                }
                return valuesByProperty;
            }
            set;
        }
        public String idFiscal {
            get {
                return (String) get('idFiscal');
            }
            set {
                valuesByProperty.put('idFiscal', value);
            }
        }

        public String nombre {
            get {
                return (String) get('nombre');
            }
            set {
                valuesByProperty.put('nombre', value);
            }
        }
        public String primerApellido {
            get {
                return (String) get('primerApellido');
            }
            set {
                valuesByProperty.put('primerApellido', value);
            }
        }
        public String segundoApellido {
            get {
                return (String) get('segundoApellido');
            }
            set {
                valuesByProperty.put('segundoApellido', value);
            }
        }
        public Integer fechaNacimiento {
            get {
                return (Integer) get('fechaNacimiento');
            }
            set {
                valuesByProperty.put('fechaNacimiento', value);
            }
        }
        public Integer fechaCarnet {
            get {
                return (Integer) get('fechaCarnet');
            }
            set {
                valuesByProperty.put('fechaCarnet', value);
            }
        }
        public String paisCarnet {
            get {
                return (String) get('paisCarnet');
            }
            set {
                valuesByProperty.put('paisCarnet', value);
            }
        }
        public String sexo {
            get {
                return (String) get('sexo');
            }
            set {
                valuesByProperty.put('sexo', value);
            }
        }
        public Contacto contacto {
            get {
                if (contacto == null)
                {
                    contacto = new Contacto();
                }
                return contacto;
            }
            set;
        }

        // Propiedades para otros campos anidados o de nivel superior si es necesario
        private Set<String> getReceivedFields()
        {
            return valuesByProperty.keySet().clone();
        }
        @TestVisible
        private Object get(String property)
        {
            return valuesByProperty.get(property);
        }
    }

    /* Clase interna para la propiedad "contacto" de la clase "Cliente" */
    public class Contacto
    {
        @TestVisible
        private Map<String, Object> valuesByProperty {
            get {
                if (valuesByProperty == null)
                {
                    valuesByProperty = new Map<String, Object>();
                }
                return valuesByProperty;
            }
            set;
        }
        public String telefono {
            get {
                return (String) get('telefono');
            }
            set {
                valuesByProperty.put('telefono', value);
            }
        }
        public String email {
            get {
                return (String) get('email');
            }
            set {
                valuesByProperty.put('email', value);
            }
        }
        public String codigoPostal {
            get {
                return (String) get('codigoPostal');
            }
            set {
                valuesByProperty.put('codigoPostal', value);
            }
        }
        public String poblacion {
            get {
                return (String) get('poblacion');
            }
            set {
                valuesByProperty.put('poblacion', value);
            }
        }
        public Integer llamada {
            get {
                return (Integer) get('llamada');
            }
            set {
                valuesByProperty.put('llamada', value);
            }
        }
        public String horaDesde {
            get {
                return (String) get('horaDesde');
            }
            set {
                valuesByProperty.put('horaDesde', value);
            }
        }
        public String horaHasta {
            get {
                return (String) get('horaHasta');
            }
            set {
                valuesByProperty.put('horaHasta', value);
            }
        }
        public String quiereLlamada {
            get {
                return (String) get('quiereLlamada');
            }
            set {
                valuesByProperty.put('quiereLlamada', value);
            }
        }
        // Propiedades para otros campos anidados o de nivel superior si es necesario
        private Set<String> getReceivedFields()
        {
            return valuesByProperty.keySet().clone();
        }
        @TestVisible
        private Object get(String property)
        {
            return valuesByProperty.get(property);
        }
    }

    /* ------- Clase interna para la propiedad "poliza" de la clase "Lead" ------ */
    public class Poliza
    {
        @TestVisible
        private Map<String, Object> valuesByProperty {
            get {
                if (valuesByProperty == null)
                {
                    valuesByProperty = new Map<String, Object>();
                }
                return valuesByProperty;
            }
            set;
        }
        public String ramo {
            get {
                return (String) get('ramo');
            }
            set {
                valuesByProperty.put('ramo', value);
            }
        }
        public String numeroPoliza {
            get {
                return (String) get('numeroPoliza');
            }
            set {
                valuesByProperty.put('numeroPoliza', value);
            }
        }
        public String numeroOferta {
            get {
                return (String) get('numeroOferta');
            }
            set {
                valuesByProperty.put('numeroOferta', value);
            }
        }
        public Integer fechaInicio {
            get {
                return (Integer) get('fechaInicio');
            }
            set {
                valuesByProperty.put('fechaInicio', value);
            }
        }
        public Decimal precioAnual {
            get {
                return (Decimal) get('precioAnual');
            }
            set {
                valuesByProperty.put('precioAnual', value);
            }
        }
        public String codigoIntermediario {
            get {
                return (String) get('codigoIntermediario');
            }
            set {
                valuesByProperty.put('codigoIntermediario', value);
            }
        }
        public String paquete {
            get {
                return (String) get('paquete');
            }
            set {
                valuesByProperty.put('paquete', value);
            }
        }
        public Coche coche {
            get {
                if (coche == null)
                {
                    coche = new Coche();
                }
                return coche;
            }
            set;
        }
        public Errores errores {
            get {
                if (errores == null)
                {
                    errores = new Errores();
                }
                return errores;
            }
            set;
        }
        // Propiedades para otros campos anidados o de nivel superior si es necesario
        private Set<String> getReceivedFields()
        {
            return valuesByProperty.keySet().clone();
        }
        @TestVisible
        private Object get(String property)
        {
            return valuesByProperty.get(property);
        }
    }

    /* Clase interna para la propiedad "coche" de la clase "Poliza" */
    public class Coche
    {
        @TestVisible
        private Map<String, Object> valuesByProperty {
            get {
                if (valuesByProperty == null)
                {
                    valuesByProperty = new Map<String, Object>();
                }
                return valuesByProperty;
            }
            set;
        }
        public String marca {
            get {
                return (String) get('marca');
            }
            set {
                valuesByProperty.put('marca', value);
            }
        }
        public String modelo {
            get {
                return (String) get('modelo');
            }
            set {
                valuesByProperty.put('modelo', value);
            }
        }
        public String version {
            get {
                return (String) get('version');
            }
            set {
                valuesByProperty.put('version', value);
            }
        }
        public String matricula {
            get {
                return (String) get('matricula');
            }
            set {
                valuesByProperty.put('matricula', value);
            }
        }
        public String paisMatriculacion {
            get {
                return (String) get('paisMatriculacion');
            }
            set {
                valuesByProperty.put('paisMatriculacion', value);
            }
        }
        // Propiedades para otros campos anidados o de nivel superior si es necesario
        private Set<String> getReceivedFields()
        {
            return valuesByProperty.keySet().clone();
        }
        @TestVisible
        private Object get(String property)
        {
            return valuesByProperty.get(property);
        }
    }

    /* Clase interna para la propiedad "errores" de la clase "Poliza" */
    public class Errores
    {
        @TestVisible
        private Map<String, Object> valuesByProperty {
            get {
                if (valuesByProperty == null)
                {
                    valuesByProperty = new Map<String, Object>();
                }
                return valuesByProperty;
            }
            set;
        }
        public String oferta {
            get {
                return (String) get('marca');
            }
            set {
                valuesByProperty.put('marca', value);
            }
        }
        public String poliza {
            get {
                return (String) get('modelo');
            }
            set {
                valuesByProperty.put('modelo', value);
            }
        }
        // Propiedades para otros campos anidados o de nivel superior si es necesario
        private Set<String> getReceivedFields()
        {
            return valuesByProperty.keySet().clone();
        }
        @TestVisible
        private Object get(String property)
        {
            return valuesByProperty.get(property);
        }
    }

    /* ----------------------------------------------------------------------------------- */
    /*  Clase que representa un error que se produce dentro de SalesCRMQuoteAndBuyService  */
    /* ----------------------------------------------------------------------------------- */
    public class QuoteAndBuyException extends Exception
    {
        public String statusCode {get; set;}
        public String message {get; set;}

        public QuoteAndBuyException(String statusCode, String message)
        {
            this.statusCode = statusCode;
            this.setMessage(message);
        }
    }
}