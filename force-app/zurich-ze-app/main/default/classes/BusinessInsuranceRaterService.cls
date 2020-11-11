public without sharing class BusinessInsuranceRaterService
{
    public static List<Business_Quotes_Field__mdt> stepMetadataList = new List<Business_Quotes_Field__mdt>();
    public static Set<String> requiredFieldsMetadataSet = new Set<String>();
    public static Map<String, String> formattedFieldsMetadataMap = new Map<String, String>();
    public static Set<String> currentRequiredFieldsSet = new Set<String>();

    public static Integer version { get; set; }

    public static final String LASTSTEP_FIELD = 'lastStep';
    public static final String INVALID_FIELD_STATUSCODE = 'INVALID_FIELD';

    public static void processFormData(Request formData)
    {
        //Para todos los pasos
        //1. Buscamos el cliente y si no existe lo insertamos
        //TODO: Llamar al servicio que contenga la lógica de búsqueda de clientes

        //2. Creamos una tarea para el advisor
        createTasks(formData); //TODO: Confirmar si en todos los pasos se crea una tarea (Duda en el CRM-08)

        String lastStep = formData.LastStep;
        if (
            lastStep == 'CRM-03' ||
            lastStep == 'CRM-04' ||
            lastStep == 'CRM-06' ||
            lastStep == 'CRM-08'
            )
        {
            createOffers(formData);
        }

        if (lastStep == 'CRM-05' || lastStep == 'CRM-07')
        {
            createLostOffers(formData); //TODO: Si la creación de ofertas es igual pero simplemente cambiando el stage, se podría usar la misma pasando stage como parametro
        }

        if (lastStep == 'CRM-07' || lastStep == 'CRM-08')
        {
            createManagers(formData);
        }
    }

    private static void createTasks(Request formData)
    {
        //TODO: Crear una tarea con los datos necesarios del objeto Request formData
    }

    private static void createOffers(Request formData)
    {
        //TODO: Crear ofertas con los datos necesarios del objeto Request formData
    }

    private static void createLostOffers(Request formData)
    {
        //TODO: Crear ofertas perdidas con los datos necesarios del objeto Request formData
        //Si hay objeto riesgo en el formData
        createRisks(formData);
    }

    private static void createRisks(Request formData)
    {
        //TODO: Crear ofertas con los datos necesarios del objeto Request formData
    }

    private static void createManagers(Request formData)
    {
        //TODO: Crear un PersonAccount manager con los datos necesarios del objeto Request formData
    }

    /**
     * Método que recupera por metadatos los campos requeridos para el paso especificado
     *
     * @param String step Paso del formulario en el que nos han enviado la información
     * @return Map<String, Set<String>> Mapa por entidades con el listado de campos requeridos para cada entidad
     * @author rlopez
     * @date 21/10/2020
     */
    public static void getRequiredFieldsFromMetadata(String step)
    {
        if( String.isBlank(step) )
        {
            throw new BusinessInsuranceRaterServiceException(
                      INVALID_FIELD_STATUSCODE,
                      'LastStep field missing'
                      );
        }

        //String stepToSearch = '%' + step + '%';
        //Map<String, Set<String>> requiredFieldsPerEntity = new Map<String, Set<String>>();
        stepMetadataList = [
            SELECT
            OriginEntity__c,
            OriginField__c,
            Required__c,
            SalesforceEntity__c,
            SalesforceField__c,
            Type__c,
            FormSteps__c
            FROM Business_Quotes_Field__mdt
            WHERE
            /*FormSteps__c LIKE :stepToSearch
               AND Required__c = TRUE
               AND */IsActive__c = TRUE
        ];

        if ( !stepMetadataList.isEmpty() )
        {
            for (Business_Quotes_Field__mdt metadata : stepMetadataList)
            {
                /*if ( metadata.Required__c != null && metadata.Required__c == true && String.isNotBlank(metadata.OriginEntity__c) && String.isNotBlank(metadata.OriginField__c) )
                   {
                    String key = (metadata.OriginEntity__c + metadata.OriginField__c).toLowerCase();
                    requiredFieldsMetadataSet.add( key );
                    formattedFieldsMetadataMap.put(key, metadata.OriginEntity__c + ' - ' + metadata.OriginField__c);
                   }*/
                if ( metadata.FormSteps__c.contains(step) && String.isNotBlank(metadata.OriginEntity__c) && String.isNotBlank(metadata.OriginField__c) )
                {
                    String key = (metadata.OriginEntity__c + metadata.OriginField__c).toLowerCase();
                    requiredFieldsMetadataSet.add( key );
                    formattedFieldsMetadataMap.put(key, metadata.OriginEntity__c + ' - ' + metadata.OriginField__c);
                }
            }
        }
    }

    /**
     * Método que valida que el formato de la información recibida del formulario web es correcta
     *
     * @return List<String> fieldsNotFound listado de campos no encontrado en el JSON
     * @author rlopez
     * @date 21/10/2020
     */
    public static void validateReceivedInformation()
    {
        List<String> fieldsNotFound = new List<String>();

        for (String field : requiredFieldsMetadataSet)
        {
            if ( !currentRequiredFieldsSet.contains(field) )
            {
                fieldsNotFound.add( formattedFieldsMetadataMap.get(field) );
            }
        }

        if( !fieldsNotFound.isEmpty() )
        {
            throw new BusinessInsuranceRaterServiceException(
                      INVALID_FIELD_STATUSCODE,
                      'The following fields are missing: ' +
                      fieldsNotFound.toString()
                      );
        }
    }

    private static void setRequiredFields(String field)
    {
        if ( requiredFieldsMetadataSet.contains( field.toLowerCase() ) )
        {
            currentRequiredFieldsSet.add( field.toLowerCase() );
        }
    }
    /**
     *
     *
     * INNER CLASSES
     *
     *
     */
    /**
     * Clase interna que representa una solicitud recibida desde el formulario web de Zurich Empresas
     *
     * @author rlopez
     * @date 15/10/2020
     */
    public class Request
    {
        public String timeStamp {
            get;
            set {
                setRequiredFields('Request' + 'timeStamp');
                timeStamp = value;
            }
        }
        public String webEmail {
            get;
            set {
                setRequiredFields('Request' + 'webEmail');
                webEmail = value;
            }
        }
        public String webPhone {
            get;
            set {
                setRequiredFields('Request' + 'webPhone');
                webPhone = value;
            }
        }
        public String sessionId {
            get;
            set {
                setRequiredFields('Request' + 'sessionId');
                sessionId = value;
            }
        }
        public String businessCode {
            get;
            set {
                setRequiredFields('Request' + 'businessCode');
                businessCode = value;
            }
        }
        public String lastStep {
            get;
            set {
                setRequiredFields('Request' + 'lastStep');
                lastStep = value;
            }
        }
        public String status {
            get;
            set {
                setRequiredFields('Request' + 'status');
                status = value;
            }
        }
        public String bestTimeFrom {
            get;
            set {
                setRequiredFields('Request' + 'bestTimeFrom');
                bestTimeFrom = value;
            }
        }
        public String bestTimeUntil {
            get;
            set {
                setRequiredFields('Request' + 'bestTimeUntil');
                bestTimeUntil = value;
            }
        }
        public AccountInformation accountInformation {
            get;
            set {
                setRequiredFields('Request' + 'accountInformation');
                accountInformation = value;
            }
        }
        public Manager manager {
            get;
            set {
                setRequiredFields('Request' + 'manager');
                manager = value;
            }
        }
        public List<Offer> offers {
            get;
            set {
                setRequiredFields('Request' + 'offers');
                offers = value;
            }
        }
    }

    /**
     * Clase interna que representa la información de una cuenta, recibida en la solicitud inicial del formulario web de Zurich Empresas
     *
     * @author rlopez
     * @date 15/10/2020
     */
    public class AccountInformation
    {
        public String firstName {
            get;
            set {
                setRequiredFields('AccountInformation' + 'firstName');
                firstName = value;
            }
        }
        public String lastName {
            get;
            set {
                setRequiredFields('AccountInformation' + 'lastName');
                lastName = value;
            }
        }
        public String family {
            get;
            set {
                setRequiredFields('AccountInformation' + 'family');
                family = value;
            }
        }
        public String commercialActivity {
            get;
            set {
                setRequiredFields('AccountInformation' + 'commercialActivity');
                commercialActivity = value;
            }
        }
        public Double annualRevenue {
            get;
            set {
                setRequiredFields('AccountInformation' + 'annualRevenue');
                annualRevenue = value;
            }
        }
        public Integer numberOfEmployees {
            get;
            set {
                setRequiredFields('AccountInformation' + 'numberOfEmployees');
                numberOfEmployees = value;
            }
        }
        public String tradeName {
            get;
            set {
                setRequiredFields('AccountInformation' + 'tradeName');
                tradeName = value;
            }
        }
        public String companyName {
            get;
            set {
                setRequiredFields('AccountInformation' + 'companyName');
                companyName = value;
            }
        }
        public String nationalIdentifier {
            get;
            set {
                setRequiredFields('AccountInformation' + 'nationalIdentifier');
                nationalIdentifier = value;
            }
        }
    }

    /**
     * Clase interna que representa la información del manager, recibida en la solicitud inicial del formulario web de Zurich Empresas
     *
     * @author rlopez
     * @date 20/10/2020
     */
    public class Manager
    {
        public String firstName {
            get;
            set {
                setRequiredFields('Manager' + 'firstName');
                firstName = value;
            }
        }
        public String lastName {
            get;
            set {
                setRequiredFields('Manager' + 'lastName');
                lastName = value;
            }
        }
        public String email {
            get;
            set {
                setRequiredFields('Manager' + 'email');
                email = value;
            }
        }
        public String phone {
            get;
            set {
                setRequiredFields('Manager' + 'phone');
                phone = value;
            }
        }
    }

    /**
     * Clase interna que representa la información de las ofertas, recibidas en la solicitud inicial del formulario web de Zurich Empresas
     *
     * @author rlopez
     * @date 15/10/2020
     */
    public class Offer
    {
        public String quoteNumberINFO {
            get;
            set {
                setRequiredFields('Offer' + 'quoteNumberINFO');
                quoteNumberINFO = value;
            }
        }
        public String quoteNumberJRE {
            get;
            set {
                setRequiredFields('Offer' + 'quoteNumberJRE');
                quoteNumberJRE = value;
            }
        }
        public String policyNumber {
            get;
            set {
                setRequiredFields('Offer' + 'policyNumber');
                policyNumber = value;
            }
        }
        public String operationCode {
            get;
            set {
                setRequiredFields('Offer' + 'operationCode');
                operationCode = value;
            }
        }
        public String businessCode {
            get;
            set {
                setRequiredFields('Offer' + 'businessCode');
                businessCode = value;
            }
        }
        public Date effectiveDate {
            get;
            set {
                setRequiredFields('Offer' + 'effectiveDate');
                effectiveDate = value;
            }
        }
        public String commercialPC {
            get;
            set {
                setRequiredFields('Offer' + 'commercialPC');
                commercialPC = value;
            }
        }
        public String technicalPC {
            get;
            set {
                setRequiredFields('Offer' + 'technicalPC');
                technicalPC = value;
            }
        }
        public String paymentType {
            get;
            set {
                setRequiredFields('Offer' + 'paymentType');
                paymentType = value;
            }
        }
        public String paymentTypeSucc {
            get;
            set {
                setRequiredFields('Offer' + 'paymentTypeSucc');
                paymentTypeSucc = value;
            }
        }
        public String paymentChannel {
            get;
            set {
                setRequiredFields('Offer' + 'paymentChannel');
                paymentChannel = value;
            }
        }
        public String paymentChannelSucc {
            get;
            set {
                setRequiredFields('Offer' + 'paymentChannelSucc');
                paymentChannelSucc = value;
            }
        }
        public String language {
            get;
            set {
                setRequiredFields('Offer' + 'language');
                language = value;
            }
        }
        public Double buildingCapital {
            get;
            set {
                setRequiredFields('Offer' + 'buildingCapital');
                buildingCapital = value;
            }
        }
        public Double contentCapital {
            get;
            set {
                setRequiredFields('Offer' + 'contentCapital');
                contentCapital = value;
            }
        }
        public Double generalLiabilityLimit {
            get;
            set {
                setRequiredFields('Offer' + 'generalLiabilityLimit');
                generalLiabilityLimit = value;
            }
        }
        public Double netPremium {
            get;
            set {
                setRequiredFields('Offer' + 'netPremium');
                netPremium = value;
            }
        }
        public String validationErrors {
            get;
            set {
                setRequiredFields('Offer' + 'validationErrors');
                validationErrors = value;
            }
        }
        public OfferRiskInformation offerRiskInformation {
            get;
            set {
                setRequiredFields('Offer' + 'offerRiskInformation');
                offerRiskInformation = value;
            }
        }
    }

    /**
     * Clase interna que representa la información del riesgo de una oferta, recibida en la solicitud inicial del formulario web de Zurich Empresas
     *
     * @author rlopez
     * @date 15/10/2020
     */
    public class OfferRiskInformation
    {
        public String propertyStreetType {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'propertyStreetType');
                propertyStreetType = value;
            }
        }
        public String propertyStreet {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'propertyStreet');
                propertyStreet = value;
            }
        }
        public String propertyStreetNumber {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'propertyStreetNumber');
                propertyStreetNumber = value;
            }
        }
        public String propertyAdditionalInfo {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'propertyAdditionalInfo');
                propertyAdditionalInfo = value;
            }
        }
        public String propertyPostalCode {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'propertyPostalCode');
                propertyPostalCode = value;
            }
        }
        public String propertyCity {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'propertyCity');
                propertyCity = value;
            }
        }
        public String propertyState {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'propertyState');
                propertyState = value;
            }
        }
        public String propertyCountry {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'propertyCountry');
                propertyCountry = value;
            }
        }
        public Integer yearOfConstruction {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'yearOfConstruction');
                yearOfConstruction = value;
            }
        }
        public String ownership {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'ownership');
                ownership = value;
            }
        }
        public String insuredType {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'insuredType');
                insuredType = value;
            }
        }
        public String buildingType {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'buildingType');
                buildingType = value;
            }
        }
        public String height {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'height');
                height = value;
            }
        }
        public String riskFactor01 {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'riskFactor01');
                riskFactor01 = value;
            }
        }
        public String riskFactor02 {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'riskFactor02');
                riskFactor02 = value;
            }
        }
        public String riskFactor03 {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'riskFactor03');
                riskFactor03 = value;
            }
        }
        public String riskFactor04 {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'riskFactor04');
                riskFactor04 = value;
            }
        }
        public String riskFactor05 {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'riskFactor05');
                riskFactor05 = value;
            }
        }
        public String riskFactor06 {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'riskFactor06');
                riskFactor06 = value;
            }
        }
        public String riskFactor07 {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'riskFactor07');
                riskFactor07 = value;
            }
        }
        public String riskFactor08 {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'riskFactor08');
                riskFactor08 = value;
            }
        }
        public String riskFactor09 {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'riskFactor09');
                riskFactor09 = value;
            }
        }
        public String area {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'area');
                area = value;
            }
        }
        public Boolean lockType {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'lockType');
                lockType = value;
            }
        }
        public Boolean securityDoor {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'securityDoor');
                securityDoor = value;
            }
        }
        public Boolean bulletproofDoor {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'bulletproofDoor');
                bulletproofDoor = value;
            }
        }
        public Boolean connectedAlarm {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'connectedAlarm');
                connectedAlarm = value;
            }
        }
        public Boolean fireHydrant {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'fireHydrant');
                fireHydrant = value;
            }
        }
        public Boolean surveillance {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'surveillance');
                surveillance = value;
            }
        }
        public Boolean smokeDetector {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'smokeDetector');
                smokeDetector = value;
            }
        }
        public Boolean sprayer {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'sprayer');
                sprayer = value;
            }
        }
        public Boolean fireExtinguisher {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'fireExtinguisher');
                fireExtinguisher = value;
            }
        }
        public String typeOfWindows {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'typeOfWindows');
                typeOfWindows = value;
            }
        }
        public String strongbox {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'strongbox');
                strongbox = value;
            }
        }
    }

    @TestVisible
    public class BusinessInsuranceRaterServiceException extends Exception
    {
        public String statusCode;
        public String message
        {
            get
            {
                return this.getMessage();
            }
        }

        /**
         * Constructor por defecto
         * @author rlopez
         * @date 11/11/2020
         */
        public BusinessInsuranceRaterServiceException(String statusCode, String message)
        {
            this.setMessage(message);
            this.statusCode = statusCode;
        }
    }
}
