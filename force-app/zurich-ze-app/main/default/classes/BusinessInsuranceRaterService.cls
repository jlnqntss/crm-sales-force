public without sharing class BusinessInsuranceRaterService
{
    public static List<Business_Quotes_Field__mdt> stepMetadataList = new List<Business_Quotes_Field__mdt>();
    public static Map<String, Business_Insurance_Scope_Setting__mdt> scopeSettings = new Map<String, Business_Insurance_Scope_Setting__mdt>();
    public static Set<String> requiredFieldsMetadataSet = new Set<String>();
    public static Map<String, String> formattedFieldsMetadataMap = new Map<String, String>();
    public static Set<String> currentRequiredFieldsSet = new Set<String>();

    public static Set<String> offersSteps = new Set<String> {'CRM-04', 'CRM-05', 'CRM-06', 'CRM-07', 'CRM-08'};
    public static Set<String> managerSteps = new Set<String> {'CRM-07', 'CRM-08'};

    public static Integer version { get; set; }

    public static final String LASTSTEP_FIELD = 'lastStep';
    public static final String INVALID_FIELD_STATUSCODE = 'INVALID_FIELD';

    public static Account currentCustomer;
    public static Account currentManager;
    public static Scope__c currentScope;
    public static ContactPointEmail currentContactPointEmail;
    public static ContactPointPhone currentContactPointPhone;

    public static void processFormData(Request formData)
    {
        //0. Inicializamos scopeSettings
        initScopeSettings();
        //Para todos los pasos
        //1. Buscamos el cliente y si no existe lo insertamos
        //TODO: Llamar al servicio que contenga la lógica de búsqueda de clientes
        currentCustomer = searchCustomer(formData);

        //Sí el currentScope está inicializado, es que lo hemos creado porque no existía
        //la cuenta, si no, quiere decir que la cuenta existe y tenemos que ver si existe el Scope
        if(currentScope == null && currentCustomer != null)
        {
            currentScope = searchScope(formData.businessCode);
        }

        //Sí alguna de las vías de contacto no existe, es porque hemos encontrado el Scope,
        //si no, es que el scope se ha creado porque no existía y por lo tanto se han creado las vías
        //Sí el scope existe, buscamos las vías
        if( (currentContactPointEmail == null || currentContactPointPhone == null) && currentScope != null )
        {
            manageContactPoints(formData.webEmail, formData.webPhone);
        }

        //2. Creamos una tarea para el advisor
        //createTasks(formData); //TODO: Confirmar si en todos los pasos se crea una tarea (Duda en el CRM-08)
        createContactRequest(formData);

        createOffers(formData);

        //TODO: Confirmar donde va esta parte, puede que haya que buscar el manager antes de crear la poliza
        searchManager(formData);
    }

    private static void initScopeSettings()
    {
        List<Business_Insurance_Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Business_Insurance_Scope_Setting__mdt
        ];

        if( !scopeSettingsList.isEmpty() )
        {
            for(Business_Insurance_Scope_Setting__mdt setting: scopeSettingsList)
            {
                scopeSettings.put(setting.BusinessCode__c, setting);
            }
        }
    }

    private static Account searchCustomer(Request formData)
    {
        List<Account> customers = new List<Account>();

        AccountInformation accountInfo = formData.accountInformation;
        System.debug('accountInfo.nationalIdentifier: ' + accountInfo.nationalIdentifier);
        if( String.isNotBlank(accountInfo.nationalIdentifier) )
        {
            //Sí tenemos DNI --> customers = findCustomersByDocumentId(new List<String>{accountInfo.nationalIdentifier}, 'CIF', 'ze', Label.GeneralInsurance)
            customers = [SELECT Id FROM Account WHERE NationalId__c =: accountInfo.nationalIdentifier];
        }

        if( customers.isEmpty() && String.isNotBlank(formData.webEmail) )
        {
            //Buscamos por Email --> customers = findCustomersByEmail(new List<String>{formData.webEmail}, 'ze')
        }

        if( customers.isEmpty() && String.isNotBlank(formData.webPhone) )
        {
            //Buscamos por Telefono --> customers = findCustomersByPhoneNumber(new List<String>{formData.webPhone}, 'ze')
        }

        if( customers.isEmpty() )
        {
            //Creamos un nuevo Account
            customers.add( createLead(formData) );
        }

        //TODO: Borrar esto cuando tengamos las funciones de búsqueda
        /*customers = [
            SELECT Id FROM Account
           ];*/

        return customers.get(0);
    }

    private static Scope__c searchScope(String businessCode)
    {
        String scope = 'ZE';
        if( scopeSettings.containsKey(businessCode) )
        {
            scope = scopeSettings.get(businessCode).Scope__c;
        }

        List<Scope__c> scopes = new ScopesSelector(
            new Set<String> {'Id', 'AccountId__c', 'Scope__c'}
            ).selectByAccountIdAndScope(new Set<Id> {currentCustomer.Id}, scope);

        if( scopes.isEmpty() )
        {
            scopes.add(
                new Scope__c()
                );

            insert scopes;
        }

        return scopes.get(0);
    }

    private static void manageContactPoints(String email, String phone)
    {
        System.debug('email:' + email);
        System.debug('phone:' + phone);
        List<SObject> contactPointsToInsert = new List<SObject>();
        List<SObject> contactPointsToUpdate = new List<SObject>();

        //1. ContactPointEmail
        List<ContactPointEmail> contactPointEmailsByScope = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndEmailAddress(new Set<Id> {currentScope.Id}, email);

        if( contactPointEmailsByScope.isEmpty() && String.isNotBlank(email) )
        {
            //Creamos
            contactPointsToInsert.add(
                new ContactPointEmail(
                    IsPrimary = true,
                    ActiveFromDate = System.today(),
                    EmailAddress = email,
                    Scope__c = currentScope.Scope__c,
                    ParentId = currentScope.AccountId__c,
                    ScopeId__c = currentScope.Id
                    )
                );
        }
        else
        {
            //actualizamos el registro encontrado y añadimos a contactPointsToUpdate
            for(ContactPointEmail contactPointEmail: contactPointEmailsByScope)
            {
                if(!contactPointEmail.IsPrimary)
                {
                    contactPointEmail.IsPrimary = true;
                    contactPointsToUpdate.add(contactPointEmail);
                    break; //Solo debería existir 1 con ese email para el scope actual
                }
            }
        }

        //2. ContactPointPhone
        List<ContactPointPhone> contactPointPhonesByScope = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndTelephoneNumber(new Set<Id> {currentScope.Id}, phone);

        if( contactPointPhonesByScope.isEmpty() && String.isNotBlank(email) )
        {
            //Creamos
            contactPointsToInsert.add(
                new ContactPointPhone(
                    IsPrimary = true,
                    ActiveFromDate = System.today(),
                    TelephoneNumber = phone,
                    Scope__c = currentScope.Scope__c,
                    ParentId = currentScope.AccountId__c,
                    ScopeId__c = currentScope.Id
                    )
                );
        }
        else
        {
            //actualizamos el registro encontrado y añadimos a contactPointsToUpdate
            for(ContactPointPhone ContactPointPhone: ContactPointPhonesByScope)
            {
                if(!ContactPointPhone.IsPrimary)
                {
                    ContactPointPhone.IsPrimary = true;
                    contactPointsToUpdate.add(ContactPointPhone);
                    break; //Solo debería existir 1 con ese phone para el scope actual
                }
            }
        }

        if( !contactPointsToInsert.isEmpty() )
        {
            insert contactPointsToInsert;
        }
    }

    private static Account createLead(Request formData)
    {
        Account accountToCreate = new Account();
        insert accountToCreate;

        Contact contactToCreate = new Contact(
            AccountId = accountToCreate.Id
            );
        insert contactToCreate;

        currentScope = new Scope__c(
            Scope__c = 'ZE',
            AccountId__c = accountToCreate.Id
            );
        insert currentScope;

        //insert ContactPointEmail for Scope and Account
        List<SObject> contactPointsToCreate = new List<SObject>();
        contactPointsToCreate.add(
            new ContactPointEmail(
                IsPrimary = true,
                ActiveFromDate = System.today(),
                EmailAddress = formData.webEmail,
                Scope__c = currentScope.Scope__c,
                ParentId = currentScope.AccountId__c,
                ScopeId__c = currentScope.Id
                )
            );

        contactPointsToCreate.add(
            new ContactPointPhone(
                IsPrimary = true,
                ActiveFromDate = System.today(),
                TelephoneNumber = formData.webPhone,
                Scope__c = currentScope.Scope__c,
                ParentId = currentScope.AccountId__c,
                ScopeId__c = currentScope.Id
                )
            );
        insert contactPointsToCreate;

        return accountToCreate;
    }

    private static void createContactRequest(Request formData)
    {
        //TODO: Confirmar si hay que crear un ContactRequest para todos los pasos
        if(formData.lastStep == 'CRM-03')
        {}
        insert new ContactRequest(
            //TODO: Crear campos commercialPC, technicalPC y lookup a product
            );
    }

    private static void createOffers(Request formData)
    {
        if( offersSteps.contains(formData.lastStep) )
        {
            Business_Insurance_Scope_Setting__mdt currentScopeSettings = scopeSettings.get(formData.businessCode);
            List<Opportunity> offersToCreate = new List<Opportunity>();
            List<Policy__c> policiesToCreate = new List<Policy__c>();
            List<Asset> risksToCreate = new List<Asset>();

            Map<String, Asset> quoteNumberAssetMap = new Map<String, Asset>();
            Map<String, String> quoteNumberToPolicyNumberMap = new Map<String, String>();
            Map<String, String> commercialPCToProductIdMap = new Map<String, String>();

            List<BusinessInsuranceRaterService.Offer> receivedOffers = formData.offers;
            if( !receivedOffers.isEmpty() )
            {
                //Extraemos los valores de CommercialPC y TechnicalPC para buscar el producto relacionado
                Set<String> commercialPCCodes = new Set<String>();
                Set<String> technicalPCCodes = new Set<String>();
                for(BusinessInsuranceRaterService.Offer offer: receivedOffers)
                {
                    if( String.isNotBlank(offer.commercialPC) )
                    {
                        commercialPCCodes.add(offer.commercialPC);
                    }

                    if( String.isNotBlank(offer.technicalPC) )
                    {
                        technicalPCCodes.add(offer.technicalPC);
                    }
                }

                if( !commercialPCCodes.isEmpty() || !technicalPCCodes.isEmpty() )
                {
                    List<Product2> productsByCommercialPC = new ProductsSelector(
                        new Set<String> {'Id', 'CommercialCode__c'}
                        ).selectByCommercialPcAndTechnicalPC(commercialPCCodes, technicalPCCodes);
                    if( !productsByCommercialPC.isEmpty() )
                    {
                        for(Product2 relatedProduct: productsByCommercialPC)
                        {
                            commercialPCToProductIdMap.put(relatedProduct.CommercialCode__c, relatedProduct.Id);
                        }
                    }
                }

                for(BusinessInsuranceRaterService.Offer offer: receivedOffers)
                {
                    offersToCreate.add(
                        new Opportunity(
                            Name = (String.isNotBlank(offer.quoteNumberINFO) ? offer.quoteNumberINFO : 'Test Name'), //TODO: Que nombre ponemos si no tenemos quoteNumber?
                            Scope__c = (currentScopeSettings != null && String.isNotBlank(currentScopeSettings.Scope__c) ? currentScopeSettings.Scope__c : 'ZE'),
                            InfoQuoteNumber__c = offer.quoteNumberINFO,
                            StageName = 'Closed Lost', //TODO: Calculado
                            //Owner = new User(), //TODO: Calculado, buscar advisor relacionado o owner generico
                            AccountId = currentCustomer.Id,
                            Language__c = offer.language,
                            IssuedOnline__c = true,
                            ResultingPolicyNumber__c = offer.policyNumber,
                            EffectiveDate__c = offer.effectiveDate, //TODO: hacer el parse de texto a fecha?
                            BusinessCode__c = formData.businessCode,
                            BusinessName__c = (currentScopeSettings != null && String.isNotBlank(currentScopeSettings.Scope_Name__c) ? currentScopeSettings.Scope_Name__c : 'Zurich Empresas'),
                            CloseDate = System.today(),
                            ExpirationDate__c = System.today().addDays(15), //TODO: Mover a un metadato?
                            CommercialProductCode__c = offer.commercialPC,
                            TechnicalProductCode__c = offer.technicalPc,
                            TotalPremium__c = offer.netPremium,
                            BuildingCapital__c = offer.buildingCapital,
                            ContentCapital__c = offer.contentCapital,
                            GeneralLiabilityLimit__c = offer.generalLiabilityLimit,
                            PaymentType__c = offer.paymentType,
                            PaymentTypeSucc__c = offer.paymentTypeSucc,
                            PaymentChannel__c = offer.paymentChannel,
                            PaymentChannelSucc__c = offer.paymentChannelSucc,
                            ValidationErrors__c = offer.validationErrors,
                            ProductId__c = (commercialPCToProductIdMap.containsKey(offer.commercialPC) ? commercialPCToProductIdMap.get(offer.commercialPC) : null)
                            )
                        );

                    if( String.isNotBlank(offer.policyNumber) )
                    {
                        quoteNumberToPolicyNumberMap.put(offer.quoteNumberINFO, offer.policyNumber);
                    }

                    BusinessInsuranceRaterService.OfferRiskInformation risk = offer.offerRiskInformation;
                    if(risk != null)
                    {
                        quoteNumberAssetMap.put( offer.quoteNumberINFO, new Asset(
                                                     //TODO: Mapear todos los campos de Asset
                                                     ) );
                    }
                }

                if( !offersToCreate.isEmpty() )
                {
                    insert offersToCreate;

                    for(Opportunity offer: offersToCreate)
                    {
                        if( quoteNumberToPolicyNumberMap.containsKey(offer.InfoQuoteNumber__c) )
                        {
                            //TODO: Confirmar si es necesario mapear todos los campos o solo el InfoPolicyNumber
                            policiesToCreate.add(
                                new Policy__c(
                                    InfoPolicyNumber__c = quoteNumberToPolicyNumberMap.get(offer.InfoQuoteNumber__c),
                                    Scope__c = offer.Scope__c,
                                    BusinessCode__c = offer.BusinessCode__c,
                                    BusinessName__c = offer.BusinessName__c,
                                    ScopeId__c = offer.ScopeId__c,
                                    ProductId__c = offer.ProductId__c,
                                    OpportunityName__c = offer.Id
                                    )
                                );
                        }

                        if( quoteNumberAssetMap.containsKey(offer.InfoQuoteNumber__c) )
                        {
                            Asset risk = quoteNumberAssetMap.get(offer.InfoQuoteNumber__c);
                            if(risk != null)
                            {
                                //risk.OfferId__c = offer.Id;
                                risksToCreate.add(risk);
                            }
                        }
                    }

                    /*if(!policiesToCreate.isEmpty())
                       {
                        insert policiesToCreate;
                       }*/

                    /*if(!risksToCreate.isEmpty())
                       {
                        insert risksToCreate;
                       }*/
                }
            }
        }
    }

    private static void searchManager(Request formData)
    {
        //TODO: Crear un PersonAccount manager con los datos necesarios del objeto Request formData
        if( managerSteps.contains(formData.lastStep) )
        {
            List<Account> managers = new List<Account>();
            BusinessInsuranceRaterService.Manager managerInformation = formData.manager;
            if(managerInformation.phone != formData.webPhone && managerInformation.email != formData.webEmail)
            {
                if( String.isNotBlank(managerInformation.email) )
                {
                    //Buscamos por Email --> managers = findCustomersByEmail(new List<String>{managerInformation.email}, 'ze')
                }

                if( managers.isEmpty() && String.isNotBlank(managerInformation.phone) )
                {
                    //Buscamos por Telefono --> managers = findCustomersByPhoneNumber(new List<String>{formData.phone}, 'ze')
                }

                if( managers.isEmpty() )
                {
                    currentManager = new Account(
                        FirstName = managerInformation.firstName,
                        LastName = managerInformation.lastName
                        );
                    //TODO: Creamos vias de contacto con email y telefono?
                    insert currentManager;
                }
            }
            else
            {
                currentManager = currentCustomer;
            }
        }
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
