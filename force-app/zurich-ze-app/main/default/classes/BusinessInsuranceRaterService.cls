public without sharing class BusinessInsuranceRaterService {
  public class BusinessInsuranceRaterServiceException extends Exception {
  }

  public static Set<String> requiredFieldsMetadataSet = new Set<String>();
  public static Set<String> requiredFieldsSet = new Set<String>();

  public static Integer version { get; set; }

  public static void processFormData(Request formData) {
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
    ) {
      createOffers(formData);
    }

    if (lastStep == 'CRM-05' || lastStep == 'CRM-07') {
      createLostOffers(formData); //TODO: Si la creación de ofertas es igual pero simplemente cambiando el stage, se podría usar la misma pasando stage como parametro
    }

    if (lastStep == 'CRM-07' || lastStep == 'CRM-08') {
      createManagers(formData);
    }
  }

  private static void createTasks(Request formData) {
    //TODO: Crear una tarea con los datos necesarios del objeto Request formData
  }

  private static void createOffers(Request formData) {
    //TODO: Crear ofertas con los datos necesarios del objeto Request formData
  }

  private static void createLostOffers(Request formData) {
    //TODO: Crear ofertas perdidas con los datos necesarios del objeto Request formData
    //Si hay objeto riesgo en el formData
    createRisks(formData);
  }

  private static void createRisks(Request formData) {
    //TODO: Crear ofertas con los datos necesarios del objeto Request formData
  }

  private static void createManagers(Request formData) {
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
  public static void getRequiredFieldsFromMetadata(String step) {
    String stepToSearch = '%' + step + '%';
    //Map<String, Set<String>> requiredFieldsPerEntity = new Map<String, Set<String>>();
    List<Business_Quotes_Field__mdt> requiredFieldsMetadata = [
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
        AND Required__c = TRUE
        AND IsActive__c = TRUE
    ];

    if (!requiredFieldsMetadata.isEmpty()) {
      for (Business_Quotes_Field__mdt metadata : requiredFieldsMetadata) {
        requiredFieldsMetadataSet.add(metadata.OriginField__c);
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
  public static List<String> validateReceivedInformation() {
    List<String> fieldsNotFound = new List<String>();

    //TODO: Mejorar esto para que puedas especificar el field name y su entity
    for (String field : requiredFieldsMetadataSet) {
      if (!requiredFieldsSet.contains(field)) {
        fieldsNotFound.add(field);
      }
    }

    return fieldsNotFound;
  }

  private static void setRequiredFields(String field) {
    if (requiredFieldsMetadataSet.contains(field)) {
      requiredFieldsSet.add(field);
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
  public class Request {
    public String TimeStamp {
      get;
      set {
        setRequiredFields('TimeStamp');
        TimeStamp = value;
      }
    }
    public String WebEmail {
      get;
      set {
        setRequiredFields('WebEmail');
        WebEmail = value;
      }
    }
    public String WebPhone {
      get;
      set {
        setRequiredFields('WebPhone');
        WebPhone = value;
      }
    }
    public String SessionId {
      get;
      set {
        setRequiredFields('SessionId');
        SessionId = value;
      }
    }
    public String BusinessCode {
      get;
      set {
        setRequiredFields('BusinessCode');
        BusinessCode = value;
      }
    }
    public String LastStep {
      get;
      set {
        setRequiredFields('LastStep');
        LastStep = value;
      }
    }
    public String Status {
      get;
      set {
        setRequiredFields('Status');
        Status = value;
      }
    }
    public String BestTimeFrom {
      get;
      set {
        setRequiredFields('BestTimeFrom');
        BestTimeFrom = value;
      }
    }
    public String BestTimeUntil {
      get;
      set {
        setRequiredFields('BestTimeUntil');
        BestTimeUntil = value;
      }
    }
    public AccountInformation AccountInformation {
      get;
      set {
        setRequiredFields('AccountInformation');
        AccountInformation = value;
      }
    }
    public Manager Manager {
      get;
      set {
        setRequiredFields('Manager');
        Manager = value;
      }
    }
    public List<Offer> Offers {
      get;
      set {
        setRequiredFields('Offers');
        Offers = value;
      }
    }
  }

  /**
   * Clase interna que representa la información de una cuenta, recibida en la solicitud inicial del formulario web de Zurich Empresas
   *
   * @author rlopez
   * @date 15/10/2020
   */
  public class AccountInformation {
    public String FirstName {
      get;
      set {
        setRequiredFields('FirstName');
        FirstName = value;
      }
    }
    public String LastName {
      get;
      set {
        setRequiredFields('LastName');
        LastName = value;
      }
    }
    public String Family {
      get;
      set {
        setRequiredFields('Family');
        Family = value;
      }
    }
    public String CommercialActivity {
      get;
      set {
        setRequiredFields('CommercialActivity');
        CommercialActivity = value;
      }
    }
    public Double AnnualRevenue {
      get;
      set {
        setRequiredFields('AnnualRevenue');
        AnnualRevenue = value;
      }
    }
    public Integer NumberOfEmployees {
      get;
      set {
        setRequiredFields('NumberOfEmployees');
        NumberOfEmployees = value;
      }
    }
    public String TradeName {
      get;
      set {
        setRequiredFields('TradeName');
        TradeName = value;
      }
    }
    public String CompanyName {
      get;
      set {
        setRequiredFields('CompanyName');
        CompanyName = value;
      }
    }
    public String NationalIdentifier {
      get;
      set {
        setRequiredFields('NationalIdentifier');
        NationalIdentifier = value;
      }
    }
  }

  /**
   * Clase interna que representa la información del manager, recibida en la solicitud inicial del formulario web de Zurich Empresas
   *
   * @author rlopez
   * @date 20/10/2020
   */
  public class Manager {
    public String FirstName {
      get;
      set {
        setRequiredFields('FirstName');
        FirstName = value;
      }
    }
    public String LastName {
      get;
      set {
        setRequiredFields('LastName');
        LastName = value;
      }
    }
    public String Email {
      get;
      set {
        setRequiredFields('Email');
        Email = value;
      }
    }
    public String Phone {
      get;
      set {
        setRequiredFields('Phone');
        Phone = value;
      }
    }
  }

  /**
   * Clase interna que representa la información de las ofertas, recibidas en la solicitud inicial del formulario web de Zurich Empresas
   *
   * @author rlopez
   * @date 15/10/2020
   */
  public class Offer {
    public String QuoteNumberINFO {
      get;
      set {
        setRequiredFields('QuoteNumberINFO');
        QuoteNumberINFO = value;
      }
    }
    public String QuoteNumberJRE {
      get;
      set {
        setRequiredFields('QuoteNumberJRE');
        QuoteNumberJRE = value;
      }
    }
    public String PolicyNumber {
      get;
      set {
        setRequiredFields('PolicyNumber');
        PolicyNumber = value;
      }
    }
    public String OperationCode {
      get;
      set {
        setRequiredFields('OperationCode');
        OperationCode = value;
      }
    }
    public String BusinessCode {
      get;
      set {
        setRequiredFields('BusinessCode');
        BusinessCode = value;
      }
    }
    public Date EffectiveDate {
      get;
      set {
        setRequiredFields('EffectiveDate');
        EffectiveDate = value;
      }
    }
    public String CommercialPC {
      get;
      set {
        setRequiredFields('CommercialPC');
        CommercialPC = value;
      }
    }
    public String TechnicalPC {
      get;
      set {
        setRequiredFields('TechnicalPC');
        TechnicalPC = value;
      }
    }
    public String PaymentType {
      get;
      set {
        setRequiredFields('PaymentType');
        PaymentType = value;
      }
    }
    public String PaymentTypeSucc {
      get;
      set {
        setRequiredFields('PaymentTypeSucc');
        PaymentTypeSucc = value;
      }
    }
    public String PaymentChannel {
      get;
      set {
        setRequiredFields('PaymentChannel');
        PaymentChannel = value;
      }
    }
    public String PaymentChannelSucc {
      get;
      set {
        setRequiredFields('PaymentChannelSucc');
        PaymentChannelSucc = value;
      }
    }
    public String Language {
      get;
      set {
        setRequiredFields('Language');
        Language = value;
      }
    }
    public Double BuildingCapital {
      get;
      set {
        setRequiredFields('BuildingCapital');
        BuildingCapital = value;
      }
    }
    public Double ContentCapital {
      get;
      set {
        setRequiredFields('ContentCapital');
        ContentCapital = value;
      }
    }
    public Double GeneralLiabilityLimit {
      get;
      set {
        setRequiredFields('GeneralLiabilityLimit');
        GeneralLiabilityLimit = value;
      }
    }
    public Double NetPremium {
      get;
      set {
        setRequiredFields('NetPremium');
        NetPremium = value;
      }
    }
    public String ValidationErrors {
      get;
      set {
        setRequiredFields('ValidationErrors');
        ValidationErrors = value;
      }
    }
    public OfferRiskInformation OfferRiskInformation {
      get;
      set {
        setRequiredFields('OfferRiskInformation');
        OfferRiskInformation = value;
      }
    }
  }

  /**
   * Clase interna que representa la información del riesgo de una oferta, recibida en la solicitud inicial del formulario web de Zurich Empresas
   *
   * @author rlopez
   * @date 15/10/2020
   */
  public class OfferRiskInformation {
    public String PropertyStreetType {
      get;
      set {
        setRequiredFields('PropertyStreetType');
        PropertyStreetType = value;
      }
    }
    public String PropertyStreet {
      get;
      set {
        setRequiredFields('PropertyStreet');
        PropertyStreet = value;
      }
    }
    public String PropertyStreetNumber {
      get;
      set {
        setRequiredFields('PropertyStreetNumber');
        PropertyStreetNumber = value;
      }
    }
    public String PropertyAdditionalInfo {
      get;
      set {
        setRequiredFields('PropertyAdditionalInfo');
        PropertyAdditionalInfo = value;
      }
    }
    public String PropertyPostalCode {
      get;
      set {
        setRequiredFields('PropertyPostalCode');
        PropertyPostalCode = value;
      }
    }
    public String PropertyCity {
      get;
      set {
        setRequiredFields('PropertyCity');
        PropertyCity = value;
      }
    }
    public String PropertyState {
      get;
      set {
        setRequiredFields('PropertyState');
        PropertyState = value;
      }
    }
    public String PropertyCountry {
      get;
      set {
        setRequiredFields('PropertyCountry');
        PropertyCountry = value;
      }
    }
    public Integer YearOfConstruction {
      get;
      set {
        setRequiredFields('YearOfConstruction');
        YearOfConstruction = value;
      }
    }
    public String Ownership {
      get;
      set {
        setRequiredFields('Ownership');
        Ownership = value;
      }
    }
    public String InsuredType {
      get;
      set {
        setRequiredFields('InsuredType');
        InsuredType = value;
      }
    }
    public String BuildingType {
      get;
      set {
        setRequiredFields('BuildingType');
        BuildingType = value;
      }
    }
    public String Height {
      get;
      set {
        setRequiredFields('Height');
        Height = value;
      }
    }
    public String RiskFactor01 {
      get;
      set {
        setRequiredFields('RiskFactor01');
        RiskFactor01 = value;
      }
    }
    public String RiskFactor02 {
      get;
      set {
        setRequiredFields('RiskFactor02');
        RiskFactor02 = value;
      }
    }
    public String RiskFactor03 {
      get;
      set {
        setRequiredFields('RiskFactor03');
        RiskFactor03 = value;
      }
    }
    public String RiskFactor04 {
      get;
      set {
        setRequiredFields('RiskFactor04');
        RiskFactor04 = value;
      }
    }
    public String RiskFactor05 {
      get;
      set {
        setRequiredFields('RiskFactor05');
        RiskFactor05 = value;
      }
    }
    public String RiskFactor06 {
      get;
      set {
        setRequiredFields('RiskFactor06');
        RiskFactor06 = value;
      }
    }
    public String RiskFactor07 {
      get;
      set {
        setRequiredFields('RiskFactor07');
        RiskFactor07 = value;
      }
    }
    public String RiskFactor08 {
      get;
      set {
        setRequiredFields('RiskFactor08');
        RiskFactor08 = value;
      }
    }
    public String RiskFactor09 {
      get;
      set {
        setRequiredFields('RiskFactor09');
        RiskFactor09 = value;
      }
    }
    public String Area {
      get;
      set {
        setRequiredFields('Area');
        Area = value;
      }
    }
    public Boolean LockType {
      get;
      set {
        setRequiredFields('LockType');
        LockType = value;
      }
    }
    public Boolean SecurityDoor {
      get;
      set {
        setRequiredFields('SecurityDoor');
        SecurityDoor = value;
      }
    }
    public Boolean BulletproofDoor {
      get;
      set {
        setRequiredFields('BulletproofDoor');
        BulletproofDoor = value;
      }
    }
    public Boolean ConnectedAlarm {
      get;
      set {
        setRequiredFields('ConnectedAlarm');
        ConnectedAlarm = value;
      }
    }
    public Boolean FireHydrant {
      get;
      set {
        setRequiredFields('FireHydrant');
        FireHydrant = value;
      }
    }
    public Boolean Surveillance {
      get;
      set {
        setRequiredFields('Surveillance');
        Surveillance = value;
      }
    }
    public Boolean SmokeDetector {
      get;
      set {
        setRequiredFields('SmokeDetector');
        SmokeDetector = value;
      }
    }
    public Boolean Sprayer {
      get;
      set {
        setRequiredFields('Sprayer');
        Sprayer = value;
      }
    }
    public Boolean FireExtinguisher {
      get;
      set {
        setRequiredFields('FireExtinguisher');
        FireExtinguisher = value;
      }
    }
    public String TypeOfWindows {
      get;
      set {
        setRequiredFields('TypeOfWindows');
        TypeOfWindows = value;
      }
    }
    public String Strongbox {
      get;
      set {
        setRequiredFields('Strongbox');
        Strongbox = value;
      }
    }
  }
}
