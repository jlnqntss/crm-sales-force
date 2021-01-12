public without sharing class BusinessInsuranceRaterService
{
    public static AccountSearchService.Scope accSearchServiceScope = new AccountSearchService.Scope();

    public static List<Business_Quotes_Field__mdt> stepMetadataList = new List<Business_Quotes_Field__mdt>();
    public static Map<String, Scope_Setting__mdt> scopeSettings = new Map<String, Scope_Setting__mdt>();
    public static Set<String> requiredFieldsMetadataSet = new Set<String>();
    public static Map<String, String> formattedFieldsMetadataMap = new Map<String, String>();
    public static Set<String> currentRequiredFieldsSet = new Set<String>();

    public static Set<String> contactRequestSteps = new Set<String> {'CRM-01', 'CRM-02', 'CRM-03', 'CRM-04', 'CRM-05', 'CRM-06', 'CRM-07'};
    public static Set<String> offersSteps = new Set<String> {'CRM-03', 'CRM-04', 'CRM-05', 'CRM-06', 'CRM-07', 'CRM-08'};
    public static Set<String> managerSteps = new Set<String> {'CRM-07', 'CRM-08'};
    public static Set<String> legitLeadStageSteps = new Set<String> {'CRM-03'};

    public static Integer version { get; set; }

    public static final String LASTSTEP_FIELD = 'lastStep';
    public static final String INVALID_FIELD_STATUSCODE = 'INVALID_FIELD';
    public static final String INVALID_BUSINESS_CODE_STATUSCODE = 'INVALID_BUSINESS_CODE';

    public static final String QUEUE_NAME = 'ZurichEmpresas';
    public static final String ZURICH_LEGAL_ENTITY = '001';
    public static final String SPANISH_PHONE_PREFIX = '+34';
    public static final String PROFILE_NAME = 'ZE User';

    public static Account currentCustomer;
    public static Account currentManager;
    public static Scope__c currentScope;
    public static Id currentAdvisorId;
    public static ContactPointEmail currentContactPointEmail;
    public static ContactPointPhone currentContactPointPhone;

    public static void processFormData(Request formData)
    {
        if( String.isBlank(formData.webEmail) )
        {
            throw new BusinessInsuranceRaterServiceException(
                      INVALID_FIELD_STATUSCODE,
                      'WebEmail field is empty'
                      );
        }

        //0. Inicializamos scopeSettings
        initScopeSettings(formData);

        //1. Buscamos el cliente y si no existe lo insertamos
        currentCustomer = manageCustomer(formData);

        //2. Buscamos el scope y si no existe lo insertamos
        //   - Sí el currentScope está inicializado, es que lo hemos creado porque no existía la cuenta
        //   - Sí no, quiere decir que la cuenta existe y tenemos que ver si existe el Scope
        if(currentScope == null && currentCustomer != null)
        {
            currentScope = manageScope(currentCustomer, formData.businessCode);
        }

        //3. Buscamos vías de contacto y si no existen las insertamos
        //   - Sí alguna de las vías de contacto no existe, es porque hemos encontrado el Scope
        //   - Sí no, es que el scope se ha creado porque no existía y por lo tanto se han creado las vías
        //      - Sí el scope existe, buscamos las vías
        if( (currentContactPointEmail == null || currentContactPointPhone == null) && currentScope != null )
        {
            manageContactPoints(currentScope, formData.webEmail, formData.webPhone);
        }

        //4. Buscamos un advisor para asignar a la oportunidad y a la tarea
        searchAdvisor();

        //5. Buscamos a la persona autorizada
        manageAuthorizedPerson(formData);

        //6. Creamos las ofertas recibidas en la petición y su información relacionada:
        //   - Objetos asegurados (Asset)
        //   - Polizas (Policy__c)
        //   - Call me back o abandono (ContactRequest)
        manageOffersAndRelatedInformation(formData);
    }

    /**
     * Método encargado de cargar los datos de scope para identificar
     * correctamente a que scope pertenece la petición a partir del BusinessCode
     *
     * @author rlopez
     */
    private static void initScopeSettings(Request formData)
    {
        accSearchServiceScope.scope = AccountSearchService.SCOPE_CODE_ZE;
        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt
        ];

        if( !scopeSettingsList.isEmpty() )
        {
            for(Scope_Setting__mdt setting: scopeSettingsList)
            {
                scopeSettings.put(setting.BusinessCode__c, setting);
            }
        }

        if( !scopeSettings.containsKey(formData.businessCode) )
        {
            //Sí el businessCode que hemos recibido en el formulario no coincide con los que hemos recuperado en los metadatos, lanzamos error
            throw new BusinessInsuranceRaterServiceException(
                      INVALID_BUSINESS_CODE_STATUSCODE,
                      'Invalid businessCode received: ' + formData.businessCode
                      );
        }
    }

    /**
     * Método que busca si el cliente realizando la solicitud existe en el CRM. (DNI > Email > Teléfono)
     *
     * En caso de no existir, se creará un PersonAccount de tipo Lead (y sus registros relacionados: Scope y ContactPoints)
     *
     * @author rlopez
     * 
     * @change nts (agonzalezisasi) - 08/12/2021 - Actualizar algunos datos del Customer encontrado con los datos de la Request
     */
    private static Account manageCustomer(Request formData)
    {
        List<Account> customers = new List<Account>();

        AccountInformation accountInfo = formData.accountInformation;
        if( String.isNotBlank(accountInfo.nationalIdentifier) )
        {
            //Sí tenemos DNI
            customers = AccountSearchService.findCustomersByDocumentId(new List<String> {accountInfo.nationalIdentifier}, 'N', accSearchServiceScope, ZURICH_LEGAL_ENTITY);
        }

        if( customers.isEmpty() && String.isNotBlank(formData.webEmail) )
        {
            //Buscamos por Email
            customers = AccountSearchService.findCustomersByEmail(new List<String> {formData.webEmail}, accSearchServiceScope);
        }

        if( customers.isEmpty() && String.isNotBlank(formData.webPhone) )
        {
            //Buscamos por Telefono
            customers = AccountSearchService.findCustomersByPhoneNumber(new List<String> {formData.webPhone}, accSearchServiceScope);
        }

        if( customers.isEmpty() )
        {
            //Creamos un nuevo Account
            customers.add( createLead(formData) );
        } else {
            // Se actualizan algunos datos del Customer con lo que llega de la request
            updateCustomer(customers.get(0), formData);
        }

        return customers.get(0);
    }

    /**
     * Método que busca si ya existe un Scope con el BusinessCode recibido
     * para el cliente que realiza la solicitud.
     *
     * Sí lo encuentra, se actualizarán los campos correspondientes
     * Sí no lo encuenta, se creará uno nuevo
     *
     * @author rlopez
     */
    private static Scope__c manageScope(Account relatedAccount, String businessCode)
    {
        Scope__c searchedScope = new Scope__c();

        String scope = 'ZE';
        if( scopeSettings.containsKey(businessCode) )
        {
            scope = scopeSettings.get(businessCode).Scope__c;
        }

        List<Scope__c> scopesByAccountAndScope = new ScopesSelector(
            new Set<String> {'Id', 'AccountId__c', 'Scope__c', 'HasOptedOutOfEmail__c', 'Contactable__c', 'LastContactableModifiedDate__c'}
            ).selectByAccountIdAndScope(new Set<Id> {relatedAccount.Id}, scope);

        if( scopesByAccountAndScope.isEmpty() )
        {
            searchedScope = createScope(relatedAccount, businessCode);
        }
        else
        {
            searchedScope = scopesByAccountAndScope.get(0);
            searchedScope.HasOptedOutOfEmail__c = false;
            if(!searchedScope.Contactable__c)
            {
                searchedScope.Contactable__c = true;
                searchedScope.LastContactableModifiedDate__c = System.now();
            }

            update searchedScope;
        }

        return searchedScope;
    }

    /**
     * Método que busca vías de contacto para el email y telefono especificados en la petición y
     * para el cliente y ámbito encontrados previamente
     *
     * Sí existen vías de contacto para ese email o teléfono, se actualizarán como vías de contacto principales
     * Sí no existen, se crearán esos registros como vías de contacto principales
     *
     * @author rlopez
     */
    private static void manageContactPoints(Scope__c relatedScope, String email, String phone)
    {
        List<SObject> contactPointsToUpsert = new List<SObject>();
        //List<SObject> contactPointsToUpsert = new List<SObject>();

        //1. ContactPointEmail
        List<ContactPointEmail> contactPointEmailsByScope = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndEmailAddress(new Set<Id> {relatedScope.Id}, email);

        if( contactPointEmailsByScope.isEmpty() && String.isNotBlank(email) )
        {
            //Sí no hemos encontrado y tenemos email --> Creamos
            contactPointsToUpsert.add(
                new ContactPointEmail(
                    IsPrimary = true,
                    ActiveFromDate = System.today(),
                    EmailAddress = email,
                    Scope__c = relatedScope.Scope__c,
                    ParentId = relatedScope.AccountId__c,
                    ScopeId__c = relatedScope.Id
                    )
                );
        }
        else
        {
            //Sí hemos encontrado, actualizamos el registro encontrado
            for(ContactPointEmail contactPointEmail: contactPointEmailsByScope)
            {
                if(!contactPointEmail.IsPrimary)
                {
                    contactPointEmail.IsPrimary = true;
                    contactPointsToUpsert.add(contactPointEmail);
                    break; //Solo debería existir 1 con ese email para el scope actual
                }
            }
        }

        //2. ContactPointPhone
        List<ContactPointPhone> contactPointPhonesByScope = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'IsPrimary'}
            ).selectByScopeIdAndTelephoneNumber(new Set<Id> {relatedScope.Id}, phone);

        if( contactPointPhonesByScope.isEmpty() && String.isNotBlank(phone) )
        {
            //Sí no hemos encontrado y tenemos phone --> Creamos
            contactPointsToUpsert.add(
                new ContactPointPhone(
                    IsPrimary = true,
                    ActiveFromDate = System.today(),
                    TelephoneNumber = phone,
                    Scope__c = relatedScope.Scope__c,
                    ParentId = relatedScope.AccountId__c,
                    ScopeId__c = relatedScope.Id
                    )
                );
        }
        else
        {
            //Sí hemos encontrado, actualizamos el registro encontrado
            for(ContactPointPhone ContactPointPhone: ContactPointPhonesByScope)
            {
                if(!ContactPointPhone.IsPrimary)
                {
                    ContactPointPhone.IsPrimary = true;
                    contactPointsToUpsert.add(ContactPointPhone);
                    break; //Solo debería existir 1 con ese phone para el scope actual
                }
            }
        }

        if( !contactPointsToUpsert.isEmpty() )
        {
            upsert contactPointsToUpsert;
        }
    }

    /**
     * Método encargado de generar un nuevo cliente de tipo Lead cuando no se ha encontrado
     * en el CRM con los datos recibidos.
     *
     * Además, se encarga de crear el ámbito y las vías de contacto para ese cliente
     *
     * @author rlopez
     */
    private static Account createLead(Request formData)
    {
        Scope_Setting__mdt currentScopeSettings = scopeSettings.get(formData.businessCode);
        Id leadRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Lead').getRecordTypeId();
        BusinessInsuranceRaterService.AccountInformation accountInformation = formData.accountInformation;
        Account accountToCreate = new Account(
            FirstName = (String.isNotBlank(accountInformation.lastName) ? accountInformation.firstName : ''),
            LastName = (String.isNotBlank(accountInformation.lastName) ? accountInformation.lastName : accountInformation.firstName),
            Family__c = accountInformation.family,
            CommercialActivity__c = accountInformation.commercialActivity,
            AnnualRevenue = accountInformation.annualRevenue,
            NumberOfEmployees = accountInformation.numberOfEmployees,
            TradeName__c = accountInformation.tradeName,
            CompanyName__pc = accountInformation.companyName,
            NationalId__c = accountInformation.nationalIdentifier,
            NationalIdType__c = (String.isBlank(accountInformation.nationalIdentifier) ? '' : 'N'),
            RecordTypeId = leadRecordTypeId,
            LegalEntity__c = ZURICH_LEGAL_ENTITY
            );
        insert accountToCreate;

        Account createdLead = [SELECT Id, PersonContactId, Name FROM Account WHERE Id =: accountToCreate.Id LIMIT 1];

        //Creamos un Scope para el cliente que acabamos de crear
        currentScope = createScope(accountToCreate, formData.businessCode);

        //Creamos vías de contacto para ese cliente y ese scope
        createContactPointsForScope(currentScope, formData.webEmail, formData.webPhone);

        return createdLead;
    }

    /**
     * Método encargado de actualizar algunos de los campos del Customer encontrado con los datos recibidos del request
     *  
     * @author nts (agonzalezisasi)
     * @date 08/01/2021
     */
    private static void updateCustomer(Account customer, Request formData) 
    {
        if( customer != null && formData != null ) {
            Account accountToUpdate = new Account(Id= customer.Id);

            accountToUpdate.Family__c = formData.accountInformation.family;
            accountToUpdate.CommercialActivity__c = formData.accountInformation.commercialActivity;
            accountToUpdate.AnnualRevenue = formData.accountInformation.annualRevenue;
            accountToUpdate.NumberOfEmployees = formData.accountInformation.numberOfEmployees;
            accountToUpdate.TradeName__c = formData.accountInformation.tradeName;
            accountToUpdate.CompanyName__pc = formData.accountInformation.companyName;

            update accountToUpdate;

            // Si se ha hecho el update, para evitar hacer una soql copiamos los datos a la variable customer original
            customer.Family__c = formData.accountInformation.family;
            customer.CommercialActivity__c = formData.accountInformation.commercialActivity;
            customer.AnnualRevenue = formData.accountInformation.annualRevenue;
            customer.NumberOfEmployees = formData.accountInformation.numberOfEmployees;
            customer.TradeName__c = formData.accountInformation.tradeName;
            customer.CompanyName__pc = formData.accountInformation.companyName;
        }
    }

    /**
     * Método encargado de generar un nuevo ámbito para el cliente y BusinessCode especificados
     *
     * @author rlopez
     */
    private static Scope__c createScope(Account relatedAccount, String businessCode)
    {
        Scope_Setting__mdt currentScopeSettings = scopeSettings.get(businessCode);
        Scope__c scopeForRelatedAccount = new Scope__c(
            Scope__c = currentScopeSettings.Scope__c,
            Name = currentScopeSettings.Scope_Name__c,
            AccountId__c = relatedAccount.Id,
            HasOptedOutOfEmail__c = false,
            Contactable__c = true,
            LastContactableModifiedDate__c = System.now()
            );
        insert scopeForRelatedAccount;

        return scopeForRelatedAccount;
    }

    /**
     * Método encargado de crear las ofertas a partir de la información recibida en la petición.
     *
     * Se encarga además de crear los riesgos y la póliza, en caso de recibir la información necesaria para ambos.
     *
     * En cualquier caso, excepto en el paso CRM-08, se creará un registro ContactRequest
     *
     * @author rlopez
     */
    private static void manageOffersAndRelatedInformation(Request formData)
    {
        Id addressRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Address').getRecordTypeId();

        Scope_Setting__mdt currentScopeSettings = scopeSettings.get(formData.businessCode);
        List<Opportunity> offersToCreate = new List<Opportunity>();
        List<Policy__c> policiesToCreate = new List<Policy__c>();
        List<Asset> risksToCreate = new List<Asset>();
        List<ContactRequest> contactRequestsToCreate = new List<ContactRequest>();

        Map<Integer, BusinessInsuranceRaterService.OfferRiskInformation> quoteNumberRiskMap = new Map<Integer, BusinessInsuranceRaterService.OfferRiskInformation>();
        Map<Integer, String> quoteNumberToPolicyNumberMap = new Map<Integer, String>();
        Map<String, Product2> productCodesToProductMap = new Map<String, Product2>();

        if( offersSteps.contains(formData.lastStep) )
        {
            List<BusinessInsuranceRaterService.Offer> receivedOffers = formData.offers;
            if( !receivedOffers.isEmpty() )
            {
                productCodesToProductMap = getProductsFromOfferCodes(receivedOffers);

                for(Integer i=0; i < receivedOffers.size(); i++)
                {
                    BusinessInsuranceRaterService.Offer offer = receivedOffers.get(i);
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

                    String stageName = 'Legit Lead';
                    if( offer.netPremium == null && String.isNotBlank(formData.webPhone) )
                    {
                        stageName = 'App Submitted';
                    }
                    if(offer.netPremium != null)
                    {
                        stageName = 'Quoted';
                    }
                    if( String.isNotBlank(offer.policyNumber) )
                    {
                        stageName = 'Closed Won';
                    }

                    offersToCreate.add(
                        new Opportunity(
                            Name = offerName,
                            ScopeId__c = currentScope.Id,
                            Scope__c = (currentScopeSettings != null && String.isNotBlank(currentScopeSettings.Scope__c) ? currentScopeSettings.Scope__c : 'ZE'),
                            InfoQuoteNumber__c = offer.quoteNumberINFO,
                            StageName = stageName,
                            OwnerId = currentAdvisorId,
                            AccountId = currentCustomer.Id,
                            Language__c = offer.language,
                            IssuedOnline__c = true,
                            ResultingPolicyNumber__c = offer.policyNumber,
                            EffectiveDate__c = offer.effectiveDate,
                            BusinessCode__c = (String.isNotBlank(offer.businessCode) ? offer.businessCode : formData.businessCode),
                            BusinessName__c = (currentScopeSettings != null && String.isNotBlank(currentScopeSettings.Scope_Name__c) ? currentScopeSettings.Scope_Name__c : 'Zurich Empresas'),
                            CloseDate = System.today(),
                            ExpirationDate__c = System.today().addDays(15),
                            CommercialProductCode__c = offer.commercialPC,
                            TechnicalProductCode__c = offer.technicalPC,
                            TotalPremium__c = offer.netPremium,
                            BuildingCapital__c = offer.buildingCapital,
                            ContentCapital__c = offer.contentCapital,
                            GeneralLiabilityLimit__c = offer.generalLiabilityLimit,
                            PaymentType__c = offer.paymentType,
                            PaymentTypeSucc__c = offer.paymentTypeSucc,
                            PaymentChannel__c = offer.paymentChannel,
                            PaymentChannelSucc__c = offer.paymentChannelSucc,
                            ValidationErrors__c = offer.validationErrors,
                            ProductId__c = (productCodesToProductMap.containsKey(productCodes) && productCodesToProductMap.get(productCodes) != null ? productCodesToProductMap.get(productCodes).Id : null),
                            LegalEntity__c = ZURICH_LEGAL_ENTITY
                            )
                        );

                    if( String.isNotBlank(offer.policyNumber) )
                    {
                        quoteNumberToPolicyNumberMap.put(i, offer.policyNumber);
                    }

                    BusinessInsuranceRaterService.OfferRiskInformation risk = offer.offerRiskInformation;
                    if(risk != null)
                    {
                        quoteNumberRiskMap.put( i, risk);
                    }
                }

                if( !offersToCreate.isEmpty() )
                {
                    insert offersToCreate;

                    for(Integer i=0; i < offersToCreate.size(); i++)
                    {
                        Opportunity offer = offersToCreate.get(i);
                        //Creamos las polizas
                        if( quoteNumberToPolicyNumberMap.containsKey(i) )
                        {
                            String policyNumber = quoteNumberToPolicyNumberMap.get(i);
                            policiesToCreate.add(
                                new Policy__c(
                                    Name = policyNumber,
                                    InfoPolicyNumber__c = policyNumber,
                                    PolicyHolder__c = currentCustomer.Id,
                                    InfoQuoteNumber__c = offer.InfoQuoteNumber__c,
                                    BusinessCode__c = offer.BusinessCode__c,
                                    ScopeId__c = currentScope.Id
                                    )
                                );
                        }

                        //Creamos los riesgos
                        if( quoteNumberRiskMap.containsKey(i) )
                        {
                            BusinessInsuranceRaterService.OfferRiskInformation risk = quoteNumberRiskMap.get(i);
                            if(risk != null)
                            {
                                String riskName = 'Desconocido';
                                if( String.isNotBlank(risk.propertyStreet) )
                                {
                                    riskName = risk.propertyStreet + ', ';
                                    if( String.isNotBlank(risk.propertyStreetNumber) )
                                    {
                                        riskName += risk.propertyStreetNumber;
                                    }
                                }

                                risksToCreate.add(
                                    new Asset(
                                        Name = riskName,
                                        INFOInsuredObjectCode__c = (String.isBlank(offer.InfoQuoteNumber__c) ? null : offer.InfoQuoteNumber__c + '01'),
                                        OfferId__c = offer.Id,
                                        AccountId = currentCustomer.Id,
                                        Scope__c = currentScope.Scope__c,
                                        AddressType__c = risk.propertyStreetType,
                                        AddressName__c = risk.propertyStreet,
                                        AddressNumber__c = risk.propertyStreetNumber,
                                        AddressAdditionalInfo__c = risk.propertyAdditionalInfo,
                                        PostalCode__c = risk.propertyPostalCode,
                                        City__c = risk.propertyCity,
                                        State__c = risk.propertyState,
                                        Country__c = risk.propertyCountry,
                                        YearOfConstruction__c = risk.yearOfConstruction,
                                        Ownership__c = risk.ownership,
                                        InsuredType__c = risk.insuredType,
                                        Building_Type__c = risk.buildingType,
                                        Height__c = risk.height,
                                        RiskFactor01__c = risk.riskFactor01,
                                        RiskFactor02__c = risk.riskFactor02,
                                        RiskFactor03__c = risk.riskFactor03,
                                        RiskFactor04__c = risk.riskFactor04,
                                        RiskFactor05__c = risk.riskFactor05,
                                        RiskFactor06__c = risk.riskFactor06,
                                        RiskFactor07__c = risk.riskFactor07,
                                        RiskFactor08__c = risk.riskFactor08,
                                        RiskFactor09__c = risk.riskFactor09,
                                        Area__c = risk.area,
                                        LockType__c = risk.lockType,
                                        SecurityDoor__c = risk.securityDoor,
                                        BulletproofDoor__c = risk.bulletproofDoor,
                                        ConnectedAlarm__c = risk.connectedAlarm,
                                        FireHydrant__c = risk.fireHydrant,
                                        X24h_Security__c = risk.surveillance,
                                        SmokeDetector__c = risk.smokeDetector,
                                        Sprayer__c = risk.sprayer,
                                        FireExtinguisher__c = risk.fireExtinguisher,
                                        TypeOfWindows__c = risk.typeOfWindows,
                                        Safe__c = risk.strongbox,
                                        recordTypeId = addressRecordTypeId,
                                        LegalEntity__c = ZURICH_LEGAL_ENTITY
                                        )
                                    );
                            }
                        }
                    }

                    if( !policiesToCreate.isEmpty() )
                    {
                        insert policiesToCreate;
                        createRelationPolicyManager(policiesToCreate);
                    }

                    if( !risksToCreate.isEmpty() )
                    {
                        insert risksToCreate;
                    }
                }
            }
        }

        if( contactRequestSteps.contains(formData.lastStep) && formData.doNotCreateCallback == false )
        {
            //Crear Campaign Member
            manageCampaignAssignment(offersToCreate, formData.webPhone);

            //OPCIONAL - puede que no requiera funcionar con genesys
            List<purecloud__PureCloud_Queue__c> genesysQueue = new List<purecloud__PureCloud_Queue__c>();
            genesysQueue = [SELECT Id, purecloud__PureCloud_Queue_ID__c FROM purecloud__PureCloud_Queue__c WHERE Name = :QUEUE_NAME];

            //Creamos ContactRequest para cualquiera de los pasos
            ContactRequest contactRequestToCreate = new ContactRequest(
                GenesysCloudQueueId__c = (!genesysQueue.isEmpty() ? genesysQueue.get(0).Id : null),
                OwnerId = currentAdvisorId,
                PreferredChannel = (String.isBlank(formData.webPhone) ? 'Email' : 'Phone'),
                PreferredContactDatetime__c = ( String.isNotBlank(formData.bestTimeFrom) ? Datetime.valueOf( JSON.deserialize(formData.bestTimeFrom, Datetime.class) ) : System.now() ),
                PreferredPhone = formData.webPhone,
                RequestReason = 'Offer',
                Status = 'New',
                WebName__c = formData.accountInformation.firstName + ' ' + formData.accountInformation.lastName,
                WhoId = currentCustomer.PersonContactId//currentCustomer.Id
                );

            if( !offersToCreate.isEmpty() )
            {
                contactRequestToCreate.WhatId = offersToCreate.get(0).Id;
            }

            insert contactRequestToCreate;
        }
    }

    /**
     * Método encargado de recuperar los productos a partir de los Commercial y Technical Codes de las ofertas
     *
     * @return Map<String, Product2> mapa que contiene los productos identificados por la concatenación de Commercial y Technical Codes
     * @author rlopez
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
     * Método encargado de buscar a la persona autorizada (Email > Phone)
     *
     * Sí no la encuentra, creará un registro PersonAccount, su Scope y sus vías de contacto
     *
     * @author rlopez
     */
    private static void manageAuthorizedPerson(Request formData)
    {
        if( managerSteps.contains(formData.lastStep) )
        {
            List<Account> managers = new List<Account>();
            BusinessInsuranceRaterService.Manager managerInformation = formData.manager;
            if(String.isBlank(managerInformation.phone) && String.isBlank(managerInformation.email) ||
               managerInformation.phone == formData.webPhone && managerInformation.email == formData.webEmail
               )
            {
                //Sí el teléfono y el email son iguales que los introducidos en el primer paso del formulario
                //la persona autorizada es el propio cliente
                currentManager = currentCustomer;
            }
            else
            {
                if( String.isNotBlank(managerInformation.email) )
                {
                    //Buscamos por Email
                    managers = AccountSearchService.findCustomersByEmail(new List<String> {managerInformation.email}, accSearchServiceScope);
                }

                if( managers.isEmpty() && String.isNotBlank(managerInformation.phone) )
                {
                    //Buscamos por Telefono
                    managers = AccountSearchService.findCustomersByEmail(new List<String> {managerInformation.phone}, accSearchServiceScope);
                }

                if( managers.isEmpty() )
                {
                    createManagerAndContactPoints(formData);
                }
                else
                {
                    currentManager = managers.get(0);
                    updateManagerScopeAndContactPoints(formData);
                }
            }
        }
    }

    /**
     * Método encargado de buscar un advisor que ya haya atentido ofertas para el cliente y el ámbito de la petición actual
     *
     * @author rlopez
     */
    private static void searchAdvisor()
    {
        List<Opportunity> existingOffers = new OpportunitiesSelector(
            new Set<String> {'Id', 'OwnerId'}
            ).selectByAccountIdScopesAndOwnerProfile(currentCustomer.Id, new Set<Id> {currentScope.Id}, new Set<String>{PROFILE_NAME});

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
     * Método encargado de generar el PersonAccount y los registros relacionados (ámbito y vías de contacto)
     * de la persona autorizada
     *
     * @author rlopez
     */
    private static void createManagerAndContactPoints(Request formData)
    {
        BusinessInsuranceRaterService.Manager managerInformation = formData.manager;
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        currentManager = new Account(
            FirstName = managerInformation.firstName,
            LastName = managerInformation.lastName,
            RecordTypeId = customerRecordTypeId
            );
        insert currentManager;

        //Scope para el manager
        Scope__c managerScope = createScope(currentManager, formData.businessCode);

        //Vías de contacto para el manager
        createContactPointsForScope(managerScope, managerInformation.email, managerInformation.phone);
    }

    /**
     * Método encargado de crear las vías de contacto para un ámbito, y la cuenta de ese ámbito, a partir de un email y un teléfono
     *
     * @author rlopez
     */
    private static void createContactPointsForScope(Scope__c relatedScope, String email, String phone)
    {
        List<SObject> contactPointsToCreate = new List<SObject>();

        if(relatedScope != null && String.isNotBlank(relatedScope.Scope__c) && relatedScope.AccountId__c != null && relatedScope.Id != null)
        {
            if( String.isNotBlank(email) )
            {
                currentContactPointEmail = new ContactPointEmail(
                    IsPrimary = true,
                    ActiveFromDate = System.today(),
                    EmailAddress = email,
                    Scope__c = relatedScope.Scope__c,
                    ParentId = relatedScope.AccountId__c,
                    ScopeId__c = relatedScope.Id
                    );
                contactPointsToCreate.add(currentContactPointEmail);
            }

            if( String.isNotBlank(phone) )
            {
                currentContactPointPhone = new ContactPointPhone(
                    IsPrimary = true,
                    ActiveFromDate = System.today(),
                    TelephoneNumber = phone,
                    Scope__c = relatedScope.Scope__c,
                    ParentId = relatedScope.AccountId__c,
                    ScopeId__c = relatedScope.Id
                    );
                contactPointsToCreate.add(currentContactPointPhone);
            }
        }

        if( !contactPointsToCreate.isEmpty() )
        {
            insert contactPointsToCreate;
        }
    }

    /**
     * Método encargado de actualizar los registros relacionados (ámbito y vías de contacto)
     * de la persona autorizada que hemos encontrado en la búsqueda
     *
     * @author rlopez
     */
    private static void updateManagerScopeAndContactPoints(Request formData)
    {
        BusinessInsuranceRaterService.Manager managerInformation = formData.manager;

        //1. Buscamos Scope
        Scope__c managerScope = manageScope(currentManager, formData.businessCode);

        //2. Buscamos ContactPoints
        manageContactPoints(managerScope, managerInformation.email, managerInformation.phone);
    }

    /**
     * Método encargado de comprobar si existe el contacto en su campaña correspondiente
     * y de añadirlo a dicha campaña en caso de no encontrarlo
     *
     * @author rlopez
     */
    private static void manageCampaignAssignment(List<Opportunity> createdOffers, String phone)
    {
        if( String.isNotBlank(currentCustomer.PersonContactId) )
        {
            List<Campaign> businessInsuranceCampaigns = new List<Campaign>();
            String campaingName = '';
            if( !createdOffers.isEmpty() )
            {
                Boolean allOffersQuoted = true;
                Boolean offersWithProduct = false;
                for(Opportunity offer: createdOffers)
                {
                    if(offer.StageName != 'Quoted')
                    {
                        //Hay alguna oferta que no tiene StageName = Quoted
                        //no puede ir a la campaña de Quoted Leads
                        allOffersQuoted = false;
                    }

                    if( String.isNotBlank(offer.ProductId__c) )
                    {
                        offersWithProduct = true;
                    }
                }

                //Solo creamos el miembro de campaña si existe alguna oferta con producto
                if(offersWithProduct)
                {
                    if (currentScope.Scope__c.toLowerCase() == 'ze')
                    {
                        campaingName = 'ZE_Quoted Leads';
                        if(!allOffersQuoted)
                        {
                            if( String.isNotBlank(phone) )
                            {
                                campaingName = 'ZE_App Submitted Leads';
                            }
                            else
                            {
                                campaingName = 'ZE_Legit Leads';
                            }
                        }
                    }
                    else
                    {
                        campaingName = 'ZEO_Quoted Leads';
                        if(!allOffersQuoted)
                        {
                            if( String.isNotBlank(phone) )
                            {
                                campaingName = 'ZEO_App Submitted Leads';
                            }
                            else
                            {
                                campaingName = 'ZEO_Legit Leads';
                            }
                        }
                    }

                    businessInsuranceCampaigns = new CampaignsSelector(
                        new Set<String> {'Id'}
                        ).selectByName(new Set<String> {campaingName});

                    if( !businessInsuranceCampaigns.isEmpty() )
                    {
                        //Primero, comprobamos si el cliente ya existe en la campaña
                        List<CampaignMember> campaingMembers = new CampaignMembersSelector(
                            new Set<String> {'Id'}
                            ).selectByCampaignAndContact(businessInsuranceCampaigns.get(0).Id, new Set<Id> {currentCustomer.PersonContactId});
                        if( campaingMembers.isEmpty() )
                        {
                            //Si no hemos encontrado al cliente en la campaña, creamos su CampaignMember
                            insert new CampaignMember(
                                CampaignId = businessInsuranceCampaigns.get(0).Id,
                                ContactId = currentCustomer.PersonContactId,
                                Status = 'Subscribed',
                                ScopeId__c = currentScope.Id
                                );
                        }
                    }
                }
            }
        }
    }

    /**
     * Método encargado de crear la relación entre las pólizas creadas
     * y la persona autorizada
     *
     * @author rlopez
     */
    private static void createRelationPolicyManager(List<Policy__c> createdPolicies)
    {
        if( !createdPolicies.isEmpty() )
        {
            Id policyRelationshipRecordTypeId = Schema.SObjectType.Relationship__c.getRecordTypeInfosByDeveloperName().get('Policy').getRecordTypeId();
            List<Relationship__c> relations = new List<Relationship__c>();
            for(Policy__c policy: createdPolicies)
            {
                relations.add(
                    new Relationship__c(
                        LegalEntity__c = ZURICH_LEGAL_ENTITY,
                        PolicyId__c = policy.Id,
                        PrimaryAccountId__c = currentManager.Id,
                        RecordTypeId = policyRelationshipRecordTypeId,
                        Role__c = 'OCSPAU',
                        Scope__c = currentScope.Scope__c
                        )
                    );
            }

            if( !relations.isEmpty() )
            {
                insert relations;
            }
        }
    }

    /**
     * Método que añade el prefijo español a un número de teléfono si no lo tiene
     *
     * @param String phone teléfono al que añadir el prefijo
     * @return String phone teléfono con prefijo añadido
     * @author rlopez
     * @date 23/12/2020
     */
    public static String addPrefixToPhone(String phone)
    {
        if( !phone.startsWith('+') )
        {
            return SPANISH_PHONE_PREFIX + phone;
        }
        else
        {
            return phone;
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

        stepMetadataList = [
            SELECT
            OriginEntity__c,
            OriginField__c,
            SalesforceEntity__c,
            SalesforceField__c,
            FormSteps__c
            FROM Business_Quotes_Field__mdt
            WHERE IsActive__c = TRUE
        ];

        if ( !stepMetadataList.isEmpty() )
        {
            for (Business_Quotes_Field__mdt metadata : stepMetadataList)
            {
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
        //Desde el Flow ZECreateLead no se quiere crear ContactRequest
        public Boolean doNotCreateCallback {
            get {
                if(doNotCreateCallback == null){
                    return false;
                }else{
                    return doNotCreateCallback;
                }
            }
            set {
                doNotCreateCallback = value;
            }
        }

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
                webPhone = String.isNotBlank(value) ? addPrefixToPhone(value) : value;
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
        public String yearOfConstruction {
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
