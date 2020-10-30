public without sharing class BusinessInsuranceRaterService
{
    public class BusinessInsuranceRaterServiceException extends Exception
    {
    }

    public static List<Business_Quotes_Field__mdt> stepMetadataList = new List<Business_Quotes_Field__mdt>();
    public static Set<String> requiredFieldsMetadataSet = new Set<String>();
    public static Set<String> currentRequiredFieldsSet = new Set<String>();

    public static Integer version { get; set; }

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
        String stepToSearch = '%' + step + '%';
        //Map<String, Set<String>> requiredFieldsPerEntity = new Map<String, Set<String>>();
        stepMetadataList = [
            SELECT
            OriginEntity__c,
            OriginField__c,
            Required__c,
            SalesforceEntity__c,
            SalesforceField__c,
            Type__c
            FROM Business_Quotes_Field__mdt
            WHERE
            FormSteps__c LIKE :stepToSearch
            //AND Required__c = TRUE
            AND IsActive__c = TRUE
        ];

        if ( !stepMetadataList.isEmpty() )
        {
            for (Business_Quotes_Field__mdt metadata : stepMetadataList)
            {
                if (metadata.Required__c != null && metadata.Required__c == true)
                {
                    requiredFieldsMetadataSet.add(metadata.OriginField__c);
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
    public static List<String> validateReceivedInformation()
    {
        List<String> fieldsNotFound = new List<String>();

        //TODO: Mejorar esto para que puedas especificar el field name y su entity
        for (String field : requiredFieldsMetadataSet)
        {
            if ( !currentRequiredFieldsSet.contains(field) )
            {
                fieldsNotFound.add(field);
            }
        }

        return fieldsNotFound;
    }

    private static void setRequiredFields(String field)
    {
        if ( requiredFieldsMetadataSet.contains(field) )
        {
            currentRequiredFieldsSet.add(field);
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
                setRequiredFields('timeStamp');
                timeStamp = value;
            }
        }
        public String webEmail {
            get;
            set {
                setRequiredFields('webEmail');
                webEmail = value;
            }
        }
        public String webPhone {
            get;
            set {
                setRequiredFields('webPhone');
                webPhone = value;
            }
        }
        public String sessionId {
            get;
            set {
                setRequiredFields('sessionId');
                sessionId = value;
            }
        }
        public String businessCode {
            get;
            set {
                setRequiredFields('businessCode');
                businessCode = value;
            }
        }
        public String lastStep {
            get;
            set {
                setRequiredFields('lastStep');
                lastStep = value;
            }
        }
        public String status {
            get;
            set {
                setRequiredFields('status');
                status = value;
            }
        }
        public String bestTimeFrom {
            get;
            set {
                setRequiredFields('bestTimeFrom');
                bestTimeFrom = value;
            }
        }
        public String bestTimeUntil {
            get;
            set {
                setRequiredFields('bestTimeUntil');
                bestTimeUntil = value;
            }
        }
        public AccountInformation accountInformation {
            get;
            set {
                setRequiredFields('accountInformation');
                accountInformation = value;
            }
        }
        public Manager manager {
            get;
            set {
                setRequiredFields('manager');
                manager = value;
            }
        }
        public List<Offer> offers {
            get;
            set {
                setRequiredFields('offers');
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
                setRequiredFields('firstName');
                firstName = value;
            }
        }
        public String lastName {
            get;
            set {
                setRequiredFields('lastName');
                lastName = value;
            }
        }
        public String family {
            get;
            set {
                setRequiredFields('family');
                family = value;
            }
        }
        public String commercialActivity {
            get;
            set {
                setRequiredFields('commercialActivity');
                commercialActivity = value;
            }
        }
        public Double annualRevenue {
            get;
            set {
                setRequiredFields('annualRevenue');
                annualRevenue = value;
            }
        }
        public Integer numberOfEmployees {
            get;
            set {
                setRequiredFields('numberOfEmployees');
                numberOfEmployees = value;
            }
        }
        public String tradeName {
            get;
            set {
                setRequiredFields('tradeName');
                tradeName = value;
            }
        }
        public String companyName {
            get;
            set {
                setRequiredFields('companyName');
                companyName = value;
            }
        }
        public String nationalIdentifier {
            get;
            set {
                setRequiredFields('nationalIdentifier');
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
                setRequiredFields('firstName');
                firstName = value;
            }
        }
        public String lastName {
            get;
            set {
                setRequiredFields('lastName');
                lastName = value;
            }
        }
        public String email {
            get;
            set {
                setRequiredFields('email');
                email = value;
            }
        }
        public String phone {
            get;
            set {
                setRequiredFields('phone');
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
                setRequiredFields('quoteNumberINFO');
                quoteNumberINFO = value;
            }
        }
        public String quoteNumberJRE {
            get;
            set {
                setRequiredFields('quoteNumberJRE');
                quoteNumberJRE = value;
            }
        }
        public String policyNumber {
            get;
            set {
                setRequiredFields('policyNumber');
                policyNumber = value;
            }
        }
        public String operationCode {
            get;
            set {
                setRequiredFields('operationCode');
                operationCode = value;
            }
        }
        public String businessCode {
            get;
            set {
                setRequiredFields('businessCode');
                businessCode = value;
            }
        }
        public Date effectiveDate {
            get;
            set {
                setRequiredFields('effectiveDate');
                effectiveDate = value;
            }
        }
        public String commercialPC {
            get;
            set {
                setRequiredFields('commercialPC');
                commercialPC = value;
            }
        }
        public String technicalPC {
            get;
            set {
                setRequiredFields('technicalPC');
                technicalPC = value;
            }
        }
        public String paymentType {
            get;
            set {
                setRequiredFields('paymentType');
                paymentType = value;
            }
        }
        public String paymentTypeSucc {
            get;
            set {
                setRequiredFields('paymentTypeSucc');
                paymentTypeSucc = value;
            }
        }
        public String paymentChannel {
            get;
            set {
                setRequiredFields('paymentChannel');
                paymentChannel = value;
            }
        }
        public String paymentChannelSucc {
            get;
            set {
                setRequiredFields('paymentChannelSucc');
                paymentChannelSucc = value;
            }
        }
        public String language {
            get;
            set {
                setRequiredFields('language');
                language = value;
            }
        }
        public Double buildingCapital {
            get;
            set {
                setRequiredFields('buildingCapital');
                buildingCapital = value;
            }
        }
        public Double contentCapital {
            get;
            set {
                setRequiredFields('contentCapital');
                contentCapital = value;
            }
        }
        public Double generalLiabilityLimit {
            get;
            set {
                setRequiredFields('generalLiabilityLimit');
                generalLiabilityLimit = value;
            }
        }
        public Double netPremium {
            get;
            set {
                setRequiredFields('netPremium');
                netPremium = value;
            }
        }
        public String validationErrors {
            get;
            set {
                setRequiredFields('validationErrors');
                validationErrors = value;
            }
        }
        public OfferRiskInformation offerRiskInformation {
            get;
            set {
                setRequiredFields('offerRiskInformation');
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
                setRequiredFields('propertyStreetType');
                propertyStreetType = value;
            }
        }
        public String propertyStreet {
            get;
            set {
                setRequiredFields('propertyStreet');
                propertyStreet = value;
            }
        }
        public String propertyStreetNumber {
            get;
            set {
                setRequiredFields('propertyStreetNumber');
                propertyStreetNumber = value;
            }
        }
        public String propertyAdditionalInfo {
            get;
            set {
                setRequiredFields('propertyAdditionalInfo');
                propertyAdditionalInfo = value;
            }
        }
        public String propertyPostalCode {
            get;
            set {
                setRequiredFields('propertyPostalCode');
                propertyPostalCode = value;
            }
        }
        public String propertyCity {
            get;
            set {
                setRequiredFields('propertyCity');
                propertyCity = value;
            }
        }
        public String propertyState {
            get;
            set {
                setRequiredFields('propertyState');
                propertyState = value;
            }
        }
        public String propertyCountry {
            get;
            set {
                setRequiredFields('propertyCountry');
                propertyCountry = value;
            }
        }
        public Integer yearOfConstruction {
            get;
            set {
                setRequiredFields('yearOfConstruction');
                yearOfConstruction = value;
            }
        }
        public String ownership {
            get;
            set {
                setRequiredFields('ownership');
                ownership = value;
            }
        }
        public String insuredType {
            get;
            set {
                setRequiredFields('insuredType');
                insuredType = value;
            }
        }
        public String buildingType {
            get;
            set {
                setRequiredFields('buildingType');
                buildingType = value;
            }
        }
        public String height {
            get;
            set {
                setRequiredFields('height');
                height = value;
            }
        }
        public String riskFactor01 {
            get;
            set {
                setRequiredFields('riskFactor01');
                riskFactor01 = value;
            }
        }
        public String riskFactor02 {
            get;
            set {
                setRequiredFields('riskFactor02');
                riskFactor02 = value;
            }
        }
        public String riskFactor03 {
            get;
            set {
                setRequiredFields('riskFactor03');
                riskFactor03 = value;
            }
        }
        public String riskFactor04 {
            get;
            set {
                setRequiredFields('riskFactor04');
                riskFactor04 = value;
            }
        }
        public String riskFactor05 {
            get;
            set {
                setRequiredFields('riskFactor05');
                riskFactor05 = value;
            }
        }
        public String riskFactor06 {
            get;
            set {
                setRequiredFields('riskFactor06');
                riskFactor06 = value;
            }
        }
        public String riskFactor07 {
            get;
            set {
                setRequiredFields('riskFactor07');
                riskFactor07 = value;
            }
        }
        public String riskFactor08 {
            get;
            set {
                setRequiredFields('riskFactor08');
                riskFactor08 = value;
            }
        }
        public String riskFactor09 {
            get;
            set {
                setRequiredFields('riskFactor09');
                riskFactor09 = value;
            }
        }
        public String area {
            get;
            set {
                setRequiredFields('area');
                area = value;
            }
        }
        public Boolean lockType {
            get;
            set {
                setRequiredFields('lockType');
                lockType = value;
            }
        }
        public Boolean securityDoor {
            get;
            set {
                setRequiredFields('securityDoor');
                securityDoor = value;
            }
        }
        public Boolean bulletproofDoor {
            get;
            set {
                setRequiredFields('bulletproofDoor');
                bulletproofDoor = value;
            }
        }
        public Boolean connectedAlarm {
            get;
            set {
                setRequiredFields('connectedAlarm');
                connectedAlarm = value;
            }
        }
        public Boolean fireHydrant {
            get;
            set {
                setRequiredFields('fireHydrant');
                fireHydrant = value;
            }
        }
        public Boolean surveillance {
            get;
            set {
                setRequiredFields('surveillance');
                surveillance = value;
            }
        }
        public Boolean smokeDetector {
            get;
            set {
                setRequiredFields('smokeDetector');
                smokeDetector = value;
            }
        }
        public Boolean sprayer {
            get;
            set {
                setRequiredFields('sprayer');
                sprayer = value;
            }
        }
        public Boolean fireExtinguisher {
            get;
            set {
                setRequiredFields('fireExtinguisher');
                fireExtinguisher = value;
            }
        }
        public String typeOfWindows {
            get;
            set {
                setRequiredFields('typeOfWindows');
                typeOfWindows = value;
            }
        }
        public String strongbox {
            get;
            set {
                setRequiredFields('strongbox');
                strongbox = value;
            }
        }
    }
}
