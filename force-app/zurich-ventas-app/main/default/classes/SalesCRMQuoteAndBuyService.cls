/**
 * @description       : Nuevo Web Service REST que extiende de la clase APEX actual "WS_BaseAPIService"
 * @author            : nts - overes
 * @last modified on  : 09-04-2023
**/
public with sharing class SalesCRMQuoteAndBuyService {

    /**
     * Listado de campos que son requeridos
     */
    private static Set<String> requiredFields = new Set<String> {'Sesion', 'Origen', 'nombre', 'primerApellido', 'telefono', 'ramo'};

    /**
     * Listado de campos que deben estár informados desde el objeto correspondiente
     */
    private static Map<String, Schema.SObjectField> picklistTypeFieldsByJsonFieldName = new Map<String, Schema.SObjectField> {
        'ramo' => Opportunity.ProductBranch__c
    };

    private static Map<String, Schema.SObjectField> notNullableFields = new Map<String, Schema.SObjectField> {
        'Sesion' => Account.SesionId__c,
        'Origen' => Account.PersonLeadSource__c,
        'Cliente.idFiscal' => Account.NationalId__c,
        'Cliente.fechaNacimiento' => Account.Birthdate__c,
        'Cliente.Contacto.email' => Account.PersonEmail,
        'Cliente.Contacto.horaDesde' => Account.PreferedContactStart__c,
        'Cliente.Contacto.horaHasta' => Account.PreferedContactEnd__c
    };

    /**
     * Inicializando la variable desc
     */
    // FIXME: revisar si es Lead o requestdata para completar el valor
    private static String desc = 'Fecha de carnet:' + Lead.Cliente.fechaCarnet + 
        '\n País de carnet: ' + Lead.Cliente.paisCarnet +
        '\n Nuemero de oferta: ' + Lead.Poliza.numOferta +
        '\n Fecha de inicio: ' + Lead.Poliza.fechaInicio +
        '\n Precio Anual: ' + Lead.Poliza.precioAnual +
        '\n Paquete: ' + Lead.Poliza.paquete +
        '\n Marca: ' + Lead.Poliza.Coche.marca +
        '\n Modelo: ' + Lead.Poliza.Coche.Modelo +
        '\n Version: ' + Lead.Poliza.Coche.Version +
        '\n Matricula: ' + Lead.Poliza.Coche.matricula +
        '\n País matriculación: ' + Lead.Poliza.Coche.paisMatriculacion;

    private static AccountsSelector accountSelector = new AccountsSelector();

    private static List<Account> offerIntermediaryId = new List<Account>(accountSelector.findOfferIntermediaryId(Lead.Poliza.codigoIntermediario));


    /**
     * Error que representa que se ha indicado un campo inexistente o no válido (Code 400)
     */
    private static final String INVALID_FIELD = 'INVALID_FIELD';

    /**
    *
    * *
    * @author overes | 09-02-2023
    * @param requestData
    **/
    public static void validateRequestData(Lead requestData) {
        checkRequiredFields(requestData);
    }

    /**
    *
    * *
    * @author overes | 09-03-2023
    * @param requestData
    * @return Account
    **/
    public static Account manageLead(Lead requestData) {
        Account duplicateAcc = AccountLeadUtil.leadDuplicatesControl(requestData.Cliente.idFiscal, requestData.Cliente.Contacto.telefono);

        // Actualizar registro a partir de los datos de la request
        if ((duplicateAcc != null && duplicateAcc.RecordTypeId.equals(accountSelector.rtLeadId)) || duplicateAcc == null) {
            if (duplicateAcc == null) {
                duplicateAcc = new Account();
                duplicateAcc.RecordTypeId = accountSelector.rtLeadId;
                duplicateAcc.PersonLeadSource__c = requestData.origen;
                duplicateAcc.Name = requestData.Cliente.nombre + ' ' + requestData.Cliente.primerApellido + ' ' + requestData.Cliente.segundoApellido;
                duplicateAcc.NationalId__c = requestData.Cliente.idFiscal;
                duplicateAcc.Birthdate__c = requestData.Cliente.fechaNacimiento;
                duplicateAcc.Phone = requestData.Cliente.Contacto.telefono;
                duplicateAcc.PersonEmail = requestData.Cliente.Contacto.email;
                duplicateAcc.PreferedContactStart__c = requestData.Cliente.Contacto.horaDesde;
                duplicateAcc.PreferedContactEnd__c = requestData.Cliente.Contacto.horaHasta;
                duplicateAcc.Description = desc;
            }

            fillAccountFields(duplicateAcc, requestData);
            upsert duplicateAcc;
        }

        return duplicateAcc;
    }

    /**
    *
    * *
    * @author overes | 09-03-2023
    * @param requestData
    * @return Opportunity
    **/
    public static Opportunity manageOpportunity(Account leadAccount, Lead requestData) {
        OpportunitiesSelector opportunitiesSelector = new OpportunitiesSelector();
        
        //#region Fragmento de código temporal
        User userToAssign = [SELECT Contact.Account.Id FROM User WHERE Alias = 'agente.m' LIMIT 1];
        Account userToAssignRelatedAccount = [SELECT INFOIntermediaryCode__c FROM Account WHERE Id =: userToAssign.Contact.Account.Id];
        
        Id offerIntermediaryId = userToAssignRelatedAccount.Id;
        String intermediaryCode = userToAssignRelatedAccount.INFOIntermediaryCode__c;
        //#endregion
        
        Opportunity offer = new Opportunity();
        offer.SessionId__c = requestData.sesion;
        offer.Name = requestData.Cliente.nombre;
        offer.InfoQuoteNumber__c = requestData.Poliza.numeroOferta;
        offer.ResultingPolicyNumber__c = requestData.Poliza.numeroPoliza;
        offer.StageName = 'Cerrada-Ganada';
        offer.CloseDate = Date.today().addDays(10);
        offer.AccountId = leadAccount.Id;
        offer.IssuedOnline__c = true;
        offer.IntermediaryId__c = offerIntermediaryId;
        offer.IntermediaryCode__c = requestData.Poliza.codigoIntermediario;
        offer.PersonLeadSource__c = requestData.origen;
        offer.ProductBranch__c = requestData.Poliza.ramo;
        offer.PreferedContactStart__c = requestData.Cliente.Contacto.horaDesde;
        offer.PreferedContactEnd__c = requestData.Cliente.Contacto.horaHasta;
        offer.CarRegistration__c = requestData.Poliza.Coche.matricula;
        offer.Description = desc;

        if (requestData.Poliza.numeroPoliza != null && requestData.Poliza.numeroOferta != null) {
            offer.StageName = 'Cerrada-Ganada';
            offer.CloseDate = Date.today();
        }

        Policy__c pol = new Policy__c();
        pol.Name = requestData.Poliza.numeroPoliza;
        pol.InfoPolicyNumber__c = requestData.Poliza.numeroOferta;
        pol.InfoQuoteNumber__c = requestData.Poliza.numeroPoliza;
        pol.PolicyHolder__c = leadAccount.Id;
        pol.IssuedOnline__c = true;
        pol.InfoCreatedDate__c = Date.today();
        pol.StartDate__c = requestData.Poliza.fechaInicio;
        pol.IntermediaryId__c = offerIntermediaryId;
        pol.Intermediary_Code__c = intermediaryCode;

        // FIXME: revisar
        // AccountLeadOpportunityQueueJob.processOpportunityAndPolicy(acc, offer, pol, codigoPostal, telefono);
        return offer;
    }

    /**
    * Método que valida que los campos requeridos estén rellenos
    * *
    * @author overes | 09-02-2023
    * @param requestData
    **/
    private static void checkRequiredFields(Lead requestData) {
        Set<String> receivedFields = requestData.getReceivedFields();
        Set<String> missedRequiredFields = new Set<String>();

        for (String requiredField : requiredFields) {
            if (!receivedFields.contains(requiredField)) {
                missedRequiredFields.add(requiredField);
            }
        }

        if (!missedRequiredFields.isEmpty()) {
            throw new LeadGenerationException(INVALID_FIELD, 'The following required fields are missing: ' + String.join(missedRequiredFields, ', '));
        }
    }

    /**
    *
    * *
    * @author overes | 09-03-2023
    * @param requestData
    **/
    // FIXME: revisar si aquí es donde debo comprobar que el valor de 'ramo' debe ser 0000000001 | AUTOS
    private static void checkPicklistValues(Lead requestData) {
        Set<String> invalidFields = new Set<String>();

        for (String jsonField : picklistTypeFieldsByJsonFieldName.keySet()) {
            String requestDataFieldValue = (String) requestData.get(jsonField);

            if(requestDataFieldValue != null) {
                // Se obtienen todos lo valores de la picklist
                List<Schema.PicklistEntry> picklistEntries = picklistTypeFieldsByJsonFieldName.get(jsonField).getDescribe().getPicklistValues();
                List<String> picklistValues = new List<String>();

                for (Schema.PicklistEntry picklistEntry : picklistEntries) {
                    if (picklistEntry.isActive()) {
                        picklistValues.add(picklistEntry.getValue());
                    }
                }

                if (!picklistValues.contains(requestDataFieldValue)) {
                    invalidFields.add(jsonField);
                }
            }
        }

        if (!invalidFields.isEmpty()) {
            throw new LeadGenerationException(INVALID_FIELD,'The following fields send invalid values for the picklist entries: ' + String.join(invalidFields, ', ') );
        }
    }

    /**
     * Clase que representa los valores que tiene la solicitud de QuoteAndBuy
     */
    public class Lead {
        private Map<String, Object> valuesByProperty {
            get {
                if (valuesByProperty == null) {
                    valuesByProperty = new Map<String, Object>();
                }
                return valuesByProperty;
            }
            set;
        }
        // Propiedades para el campo "Sesion"
        public String sesion {
            get {
                return (String)valuesByProperty.get('Sesion');
            }
            set {
                valuesByProperty.put('Sesion', value);
            }
        }
        // Propiedades para el campo "Origen"
        public String origen {
            get {
                return (String)valuesByProperty.get('Origen');
            }
            set {
                valuesByProperty.put('Origen', value);
            }
        }
        // Propiedades para el campo "cliente"
        public class Cliente {
            public String idFiscal {
                get {
                    return (String)get('cliente.idFiscal');
                }
                set {
                    valuesByProperty.put('cliente.idFiscal', value);
                }
            }
            public String nombre {
                get {
                    return (String)get('cliente.nombre');
                }
                set {
                    valuesByProperty.put('cliente.nombre', value);
                }
            }
            public String primerApellido {
                get {
                    return (String)get('cliente.primerApellido');
                }
                set {
                    valuesByProperty.put('cliente.primerApellido', value);
                }
            }
            public String segundoApellido {
                get {
                    return (String)get('cliente.segundoApellido');
                }
                set {
                    valuesByProperty.put('cliente.segundoApellido', value);
                }
            }
            public Integer fechaNacimiento {
                get {
                    return (Integer)get('cliente.fechaNacimiento');
                }
                set {
                    valuesByProperty.put('cliente.fechaNacimiento', value);
                }
            }
            public Integer fechaCarnet {
                get {
                    return (Integer)get('cliente.fechaCarnet');
                }
                set {
                    valuesByProperty.put('cliente.fechaCarnet', value);
                }
            }
            public String paisCarnet {
                get {
                    return (String)get('cliente.paisCarnet');
                }
                set {
                    valuesByProperty.put('cliente.paisCarnet', value);
                }
            }
            public String sexo {
                get {
                    return (String)get('cliente.sexo');
                }
                set {
                    valuesByProperty.put('cliente.sexo', value);
                }
            }
            // Propiedades para el campo "contacto"
            public class Contacto {
                public String telefono {
                    get {
                        return (String)get('poliza.telefono');
                    }
                    set {
                        valuesByProperty.put('poliza.telefono', value);
                    }
                }
                public String email {
                    get {
                        return (String)get('poliza.email');
                    }
                    set {
                        valuesByProperty.put('poliza.email', value);
                    }
                }
                public String codigoPostal {
                    get {
                        return (String)get('poliza.codigoPostal');
                    }
                    set {
                        valuesByProperty.put('poliza.codigoPostal', value);
                    }
                }
                public String poblacion {
                    get {
                        return (String)get('poliza.poblacion');
                    }
                    set {
                        valuesByProperty.put('poliza.poblacion', value);
                    }
                }
                public Integer llamada {
                    get {
                        return (Integer)get('poliza.llamada');
                    }
                    set {
                        valuesByProperty.put('poliza.llamada', value);
                    }
                }
                public String horaDesde {
                    get {
                        return (String)get('poliza.horaDesde');
                    }
                    set {
                        valuesByProperty.put('poliza.horaDesde', value);
                    }
                }
                public String horaHasta {
                    get {
                        return (String)get('poliza.horaHasta');
                    }
                    set {
                        valuesByProperty.put('poliza.horaHasta', value);
                    }
                }
                public String quiereLlamada {
                    get {
                        return (String)get('poliza.quiereLlamada');
                    }
                    set {
                        valuesByProperty.put('poliza.quiereLlamada', value);
                    }
                }
            }
        }
        // Propiedades para el campo "poliza"
        public class Poliza {
            public String ramo {
                get {
                    return (String)get('poliza.ramo');
                }
                set {
                    valuesByProperty.put('poliza.ramo', value);
                }
            }
            public String numeroPoliza {
                get {
                    return (String)get('poliza.numeroPoliza');
                }
                set {
                    valuesByProperty.put('poliza.numeroPoliza', value);
                }
            }
            public String numeroOferta {
                get {
                    return (String)get('poliza.numeroOferta');
                }
                set {
                    valuesByProperty.put('poliza.numeroOferta', value);
                }
            }
            public Integer fechaInicio {
                get {
                    return (Integer)get('poliza.fechaInicio');
                }
                set {
                    valuesByProperty.put('poliza.fechaInicio', value);
                }
            }
            public Decimal precioAnual {
                get {
                    return (Decimal)get('poliza.precioAnual');
                }
                set {
                    valuesByProperty.put('poliza.precioAnual', value);
                }
            }
            public String codigoIntermediario {
                get {
                    return (String)get('poliza.codigoIntermediario');
                }
                set {
                    valuesByProperty.put('poliza.codigoIntermediario', value);
                }
            }
            public String paquete {
                get {
                    return (String)get('poliza.paquete');
                }
                set {
                    valuesByProperty.put('poliza.paquete', value);
                }
            }
            public class Conche {
                public String marca {
                    get {
                        return (String)get('poliza.marca');
                    }
                    set {
                        valuesByProperty.put('poliza.marca', value);
                    }
                }
                public String modelo {
                    get {
                        return (String)get('poliza.modelo');
                    }
                    set {
                        valuesByProperty.put('poliza.modelo', value);
                    }
                }
                public String version {
                    get {
                        return (String)get('poliza.version');
                    }
                    set {
                        valuesByProperty.put('poliza.version', value);
                    }
                }
                public String matricula {
                    get {
                        return (String)get('poliza.matricula');
                    }
                    set {
                        valuesByProperty.put('poliza.matricula', value);
                    }
                }
                public String paisMatriculacion {
                    get {
                        return (String)get('poliza.paisMatriculacion');
                    }
                    set {
                        valuesByProperty.put('poliza.paisMatriculacion', value);
                    }
                }
            }
        }

        // Propiedades para otros campos anidados o de nivel superior si es necesario
        private Set<String> getReceivedFields() {
            return valuesByProperty.keySet().clone();
        }

        private Object get(String property) {
            return valuesByProperty.get(property);
        }
    }

    /**
    *
    * *
    * @author overes | 09-02-2023
    * @param accountToFill
    * @param requestData
    **/
    private static void fillAccountFields(Account accountToFill, Lead requestData)
    {
        accountToFill.Name = requestData.Cliente.nombre + ' ' + requestData.Cliente.primerApellido + ' ' + requestData.Cliente.segundoApellido;
        accountToFill.Phone = requestData.Cliente.Contacto.telefono;
        accountToFill.Description = desc;

        for (String notNullableField : notNullableFields.keySet()) {
            if (requestData.get(notNullableField) != null) {
                accountToFill.put(notNullableFields.get(notNullableField), requestData.get(notNullableField));
            }
        }
    }

    /**
     * Clase que representa un error que se produce dentro de SalesCRMQuoteAndBuyService
     */
    public class LeadGenerationException extends Exception {
        public String statusCode {get; set;}
        public String message {get; set;}

        public LeadGenerationException(String statusCode, String message)
        {
            this.statusCode = statusCode;
            this.setMessage(message);
        }
    }
}