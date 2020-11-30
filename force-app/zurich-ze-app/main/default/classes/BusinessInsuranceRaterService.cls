public without sharing class BusinessInsuranceRaterService
{
    public static List<Business_Quotes_Field__mdt> stepMetadataList = new List<Business_Quotes_Field__mdt>();
    public static Map<String, Business_Insurance_Scope_Setting__mdt> scopeSettings = new Map<String, Business_Insurance_Scope_Setting__mdt>();
    public static Set<String> requiredFieldsMetadataSet = new Set<String>();
    public static Map<String, String> formattedFieldsMetadataMap = new Map<String, String>();
    public static Set<String> currentRequiredFieldsSet = new Set<String>();

    public static Set<String> offersSteps = new Set<String> {'CRM-03', 'CRM-04', 'CRM-05', 'CRM-06', 'CRM-07', 'CRM-08'};
    public static Set<String> managerSteps = new Set<String> {'CRM-07', 'CRM-08'};

    public static Map<String, String> opportunityStageByStep = new Map<String, String>
    {
        'CRM-03' => 'Qualification',
        'CRM-04' => 'Closed Lost',
        'CRM-05' => 'Closed Lost',
        'CRM-06' => 'Negotiation',
        'CRM-07' => 'Closed Lost',
        'CRM-08' => 'Closed Won'
    };

    public static Integer version { get; set; }

    public static final String LASTSTEP_FIELD = 'lastStep';
    public static final String INVALID_FIELD_STATUSCODE = 'INVALID_FIELD';

    public static Account currentCustomer;
    public static Account currentManager;
    public static Scope__c currentScope;
    public static Id currentAdvisorId;
    public static ContactPointEmail currentContactPointEmail;
    public static ContactPointPhone currentContactPointPhone;

    public static void processFormData(Request formData)
    {
        //0. Inicializamos scopeSettings
        initScopeSettings();

        //1. Buscamos el cliente y si no existe lo insertamos
        currentCustomer = searchCustomer(formData);

        //2. Buscamos el scope y si no existe lo insertamos
        //Sí el currentScope está inicializado, es que lo hemos creado porque no existía
        //la cuenta, si no, quiere decir que la cuenta existe y tenemos que ver si existe el Scope
        if(currentScope == null && currentCustomer != null)
        {
            searchScope(formData.businessCode);
        }

        //3. Buscamos vías de contacto y si no existen las insertamos
        //Sí alguna de las vías de contacto no existe, es porque hemos encontrado el Scope, si no,
        //es que el scope se ha creado porque no existía y por lo tanto se han creado las vías
        //Sí el scope existe, buscamos las vías
        if( (currentContactPointEmail == null || currentContactPointPhone == null) && currentScope != null )
        {
            manageContactPoints(formData.webEmail, formData.webPhone);
        }

        //4. Buscamos un advisor para asignar a la oportunidad y a la tarea
        searchAdvisor();

        //5. Creamos la tarea para el advisor
        //TODO: Confirmar si en todos los pasos se crea una tarea (Duda en el CRM-08)
        createContactRequest(formData);

        //6. Buscamos a la persona autorizada
        searchManager(formData);

        //7. Creamos las ofertas recibidas en la petición
        createOffers(formData);
    }

    /**
     * Método encargado de cargar los datos de scope para identificar
     * correctamente a que scope pertenece la petición a partir del BusinessCode
     */
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

    /**
     * Método que busca si el cliente realizando la solicitud existe en el CRM.
     * En caso de no existir, se creará un PersonAccount de tipo Lead (y sus registros relacionados: Scope y ContactPoints)
     */
    private static Account searchCustomer(Request formData)
    {
        List<Account> customers = new List<Account>();

        AccountInformation accountInfo = formData.accountInformation;
        System.debug('accountInfo.nationalIdentifier: ' + accountInfo.nationalIdentifier);
        if( String.isNotBlank(accountInfo.nationalIdentifier) )
        {
            //Sí tenemos DNI --> customers = findCustomersByDocumentId(new List<String>{accountInfo.nationalIdentifier}, 'CIF', 'ze', Label.GeneralInsurance)
            customers = [SELECT Id, Name FROM Account WHERE NationalId__c =: accountInfo.nationalIdentifier];
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

    /**
     * Método que busca si ya existe un Scope con el BusinessCode recibido
     * para el cliente que realiza la solicitud.
     *
     * Si lo encuentra, se actualizarán los campos correspondientes
     * Si no lo encuenta, se creará uno nuevo
     */
    private static void searchScope(String businessCode)
    {
        String scope = 'ZE';
        if( scopeSettings.containsKey(businessCode) )
        {
            scope = scopeSettings.get(businessCode).Scope__c;
        }

        List<Scope__c> scopes = new ScopesSelector(
            new Set<String> {'Id', 'AccountId__c', 'Scope__c', 'HasOptedOutOfEmail__c', 'Contactable__c', 'LastContactableModifiedDate__c'}
            ).selectByAccountIdAndScope(new Set<Id> {currentCustomer.Id}, scope);

        if( scopes.isEmpty() )
        {
            createScope(currentCustomer, businessCode);
        }
        else
        {
            currentScope = scopes.get(0);
            currentScope.HasOptedOutOfEmail__c = false;
            if(!currentScope.Contactable__c)
            {
                currentScope.Contactable__c = true;
                currentScope.LastContactableModifiedDate__c = System.now();
            }

            update currentScope;
        }
    }

    /**
     * Método que busca vías de contacto para el email y telefono especificados en la petición y
     * para el cliente y ámbito encontrados.
     *
     * Si existen vías de contacto para ese email o teléfono, se actualizarán como vías de contacto principales
     * Si no existen, se crearán esos registros como vías de contacto principales
     */
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

    /**
     * Método encargado de generar un nuevo cliente de tipo Lead cuando no se ha encontrado
     * en el CRM con los datos recibidos.
     *
     * Además se encarga de crear el ámbito y las vías de contacto para ese cliente
     */
    private static Account createLead(Request formData)
    {
        Business_Insurance_Scope_Setting__mdt currentScopeSettings = scopeSettings.get(formData.businessCode);
        BusinessInsuranceRaterService.AccountInformation accountInformation = formData.accountInformation;
        Account accountToCreate = new Account(
            FirstName = (String.isNotBlank(accountInformation.firstName) ? accountInformation.firstName : accountInformation.lastName),
            LastName = (String.isNotBlank(accountInformation.lastName) ? accountInformation.lastName : accountInformation.firstName),
            Family__c = accountInformation.family,
            CommercialActivity__c = accountInformation.commercialActivity,
            AnnualRevenue = accountInformation.annualRevenue,
            NumberOfEmployees = accountInformation.numberOfEmployees
            );
        insert accountToCreate;

        Contact contactToCreate = new Contact(
            AccountId = accountToCreate.Id
            );
        insert contactToCreate;

        createScope(accountToCreate, formData.businessCode);

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

    /**
     * Método encargado de generar un nuevo ámbito para el cliente y BusinessCode especificados
     */
    private static void createScope(Account relatedAccount, String businessCode)
    {
        Business_Insurance_Scope_Setting__mdt currentScopeSettings = scopeSettings.get(businessCode);
        currentScope = new Scope__c(
            Scope__c = currentScopeSettings.Scope__c,
            Name = currentScopeSettings.Scope_Name__c,
            AccountId__c = relatedAccount.Id,
            HasOptedOutOfEmail__c = false,
            Contactable__c = true,
            LastContactableModifiedDate__c = System.now()
            );
        insert currentScope;
    }

    /**
     * Método encargado de crear la tarea para el advisor
     */
    private static void createContactRequest(Request formData)
    {
        insert new ContactRequest(

            );
    }

    /**
     * Método encargado de crear las ofertas a partir de la información recibida en la petición.
     *
     * Se encarga además de crear los riesgos y la póliza, en caso de recibir la información necesaria para ambos.
     */
    private static void createOffers(Request formData)
    {
        if( offersSteps.contains(formData.lastStep) )
        {
            Business_Insurance_Scope_Setting__mdt currentScopeSettings = scopeSettings.get(formData.businessCode);
            List<Opportunity> offersToCreate = new List<Opportunity>();
            List<Policy__c> policiesToCreate = new List<Policy__c>();
            List<Asset> risksToCreate = new List<Asset>();
            List<ContactRequest> contactRequestsToCreate = new List<ContactRequest>();

            Map<String, Asset> quoteNumberAssetMap = new Map<String, Asset>();
            Map<String, String> quoteNumberToPolicyNumberMap = new Map<String, String>();
            Map<String, Product2> productCodesToProductMap = new Map<String, Product2>();

            List<BusinessInsuranceRaterService.Offer> receivedOffers = formData.offers;
            if( !receivedOffers.isEmpty() )
            {
                productCodesToProductMap = getProductsFromOfferCodes(receivedOffers);

                for(BusinessInsuranceRaterService.Offer offer: receivedOffers)
                {
                    String productCodes = offer.commercialPC + offer.technicalPC;
                    String offerName = offer.quoteNumberINFO;
                    if( String.isBlank(offerName) )
                    {
                        if(productCodesToProductMap.containsKey(productCodes) && productCodesToProductMap.get(productCodes) != null)
                        {
                            offerName = productCodesToProductMap.get(productCodes).Name + ' - ' + currentCustomer.Name;
                        }
                        else
                        {
                            offerName = offer.commercialPC + ' - ' + offer.technicalPC + ' - ' + currentCustomer.Name;
                        }
                    }

                    offersToCreate.add(
                        new Opportunity(
                            Name = offerName,
                            ScopeId__c = currentScope.Id,
                            Scope__c = (currentScopeSettings != null && String.isNotBlank(currentScopeSettings.Scope__c) ? currentScopeSettings.Scope__c : 'ZE'),
                            InfoQuoteNumber__c = offer.quoteNumberINFO,
                            StageName = (opportunityStageByStep.containsKey(formData.lastStep) && String.isNotBlank(offer.quoteNumberINFO) ? opportunityStageByStep.get(formData.lastStep) : 'Qualification'),
                            OwnerId = currentAdvisorId,
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
                            ProductId__c = (productCodesToProductMap.containsKey(productCodes) && productCodesToProductMap.get(productCodes) != null ? productCodesToProductMap.get(productCodes).Id : null)
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

    /**
     * Método encargado de recuperar los productos a partir de los Commercial y Technical Codes de las ofertas
     */
    private static Map<String, Product2> getProductsFromOfferCodes(List<BusinessInsuranceRaterService.Offer> offers)
    {
        Map<String, Product2> productCodesToProduct = new Map<String,Product2>();
        if( offers != null && !offers.isEmpty() )
        {
            Set<String> commercialPCCodes = new Set<String>();
            Set<String> technicalPCCodes = new Set<String>();
            for(BusinessInsuranceRaterService.Offer offer: offers)
            {
                if( String.isNotBlank(offer.commercialPC) )
                {
                    commercialPCCodes.add(offer.commercialPC);
                }

                if( String.isNotBlank(offer.technicalPC) )
                {
                    technicalPCCodes.add(offer.technicalPC);
                }

                productCodesToProduct.put(offer.commercialPC + offer.technicalPC, null);
            }

            if( !commercialPCCodes.isEmpty() || !technicalPCCodes.isEmpty() )
            {
                List<Product2> productsByCommercialPC = new ProductsSelector(
                    new Set<String> {'Id', 'Name', 'CommercialCode__c', 'TechnicalCode__c'}
                    ).selectByCommercialPcAndTechnicalPC(commercialPCCodes, technicalPCCodes);
                if( !productsByCommercialPC.isEmpty() )
                {
                    for(Product2 relatedProduct: productsByCommercialPC)
                    {
                        if( productCodesToProduct.containsKey(relatedProduct.CommercialCode__c + relatedProduct.TechnicalCode__c) )
                        {
                            productCodesToProduct.put(relatedProduct.CommercialCode__c + relatedProduct.TechnicalCode__c, relatedProduct);
                        }
                    }
                }
            }
        }

        return productCodesToProduct;
    }

    /**
     * Método encargado de buscar a la persona autorizada para gestionar la póliza
     */
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
     * Método encargado de buscar un advisor que ya haya atentido ofertas para el cliente y el ámbito de la petición actual
     */
    private static void searchAdvisor()
    {
        //TODO: Limite de fecha?
        List<Opportunity> existingOffers = new OpportunitiesSelector(
            new Set<String> {'Id', 'OwnerId'}
            ).selectByAccountIdAndScopes(currentCustomer.Id, new Set<Id> {currentScope.Id});

        if( existingOffers.isEmpty() )
        {
            currentAdvisorId = System.UserInfo.getUserId();
        }
        else
        {
            currentAdvisorId = existingOffers.get(0).OwnerId;
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
