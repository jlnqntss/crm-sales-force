public without sharing class BusinessInsuranceRaterService
{
    public static List<Business_Quotes_Field__mdt> stepMetadataList = new List<Business_Quotes_Field__mdt>();
    public static Map<String, Scope_Setting__mdt> scopeSettings = new Map<String, Scope_Setting__mdt>();
    public static Set<String> requiredFieldsMetadataSet = new Set<String>();
    public static Map<String, String> formattedFieldsMetadataMap = new Map<String, String>();
    public static Set<String> currentRequiredFieldsSet = new Set<String>();

    public static Set<String> contactRequestSteps = new Set<String> {'CRM-01', 'CRM-02', 'CRM-03', 'CRM-04', 'CRM-05', 'CRM-06', 'CRM-07', 'CRM-08'};
    public static Set<String> campaignMemberSteps = new Set<String> {'CRM-01', 'CRM-02', 'CRM-03', 'CRM-04', 'CRM-05', 'CRM-06', 'CRM-07'};
    public static Set<String> offersSteps = new Set<String> {'CRM-03', 'CRM-04', 'CRM-05', 'CRM-06', 'CRM-07', 'CRM-08'};
    public static Set<String> managerSteps = new Set<String> {'CRM-07', 'CRM-08'};
    public static Set<String> legitLeadStageSteps = new Set<String> {'CRM-03'};

    public static Integer version { get; set; }

    public static final String LASTSTEP_FIELD = 'lastStep';
    public static final String INVALID_FIELD_STATUSCODE = 'INVALID_FIELD';
    public static final String INVALID_BUSINESS_CODE_STATUSCODE = 'INVALID_BUSINESS_CODE';
    public static final String DUPLICATE_REQUEST_STATUSCODE = 'DUPLICATE_LEAD_REQUEST';
    public static final String MISSING_PURECLOUD_QUEUE = 'No se ha encontrado la cola de Genesys Cloud configurada.';

    public static final String SPANISH_PHONE_PREFIX = '+34';
    public static final String PROFILE_NAME = 'ZE User';

    public static Account currentCustomer;
    public static Account currentManager;
    public static Scope__c currentScope;
    public static Id currentAdvisorId;
    public static ContactPointEmail currentContactPointEmail;
    public static ContactPointPhone currentContactPointPhone;

    public static Boolean isTest;

    // Mapa que relaciona los estados que vienen del formulario con su prioridad (a menor valor mas prioridad).
    private static final Map<String, Integer> mapPriorities = new Map<String, Integer> {
        'Completado' => 0,
        'Telefonico' => 1,
        'Callmeback' => 2,
        'Abandono' => 3,
        'Activo' => 4
    };

    // Mapa que relaciona los estado que vienen del formulario con los estados del objeto ContactRequest
    private static final Map<String, String> mapStatusToSF = new Map<String, String> {
        'Activo' => 'New',
        'Telefonico' => 'Phone',
        'Callmeback' => 'Callmeback',
        'Abandono' => 'Abandoned'
    };

    private static final String FORM_STATUS_COMPLETED = 'Completado';

    public static Account processFormData(Request formData)
    {

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
        // arcortazar - 11/01/2022 - Modificamos para que sólo se haga la búsqueda en caso de no ser una Opportunity de test
        // Si la oferta es de Test, entonces, que no busque el advisor
        isTest = isBotTestingExecution(formData);
        if(!isTest)
        {
            searchAdvisor();
        }
        else 
        {
            currentAdvisorId = System.UserInfo.getUserId();   
        }

        //5. Buscamos a la persona autorizada
        manageAuthorizedPerson(formData);

        //6. Creamos las ofertas recibidas en la petición y su información relacionada:
        //   - Objetos asegurados (Asset)
        //   - Polizas (Policy__c)
        //   - Call me back o abandono (ContactRequest)
        manageOffersAndRelatedInformation(formData);

        return currentCustomer;
    }

    /**
     * Método encargado de cargar los datos de scope para identificar
     * correctamente a que scope pertenece la petición a partir del BusinessCode
     *
     * @author rlopez
     */
    private static void initScopeSettings(Request formData)
    {
        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, Label, BusinessCode__c, Scope__c, Scope_Name__c, GenesysCloudQueueName__c
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
            customers = AccountSearchService.findCustomersByDocumentId(new List<String> {accountInfo.nationalIdentifier}, 'N', RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.GI);
        }

        if( customers.isEmpty() && String.isNotBlank(formData.webEmail) )
        {
            //Buscamos por Email
            customers = AccountSearchService.findCustomersByEmail(new List<String> {formData.webEmail}, RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.GI);
        }

        if( customers.isEmpty() && String.isNotBlank(formData.webPhone) )
        {
            //Buscamos por Telefono
            customers = AccountSearchService.findCustomersByPhoneNumber(new List<String> {formData.webPhone}, RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.GI);
        }

        if( customers.isEmpty() )
        {
            //Creamos un nuevo Account
            customers.add( createLead(formData) );
        }
        else
        {
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
            ).selectByAccountIdAndScope( new Set<Id> {relatedAccount.Id}, RecordsSelector.getScope(scope) );

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
     *
     * @change nts (agonzalezisasi) - 19/12/2021 - fix bug: peticiones repetidas que crean Cuentas (leads) repetidas
     */
    private static Account createLead(Request formData)
    {
        Scope_Setting__mdt currentScopeSettings = scopeSettings.get(formData.businessCode);
        Id leadRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Lead').getRecordTypeId();
        BusinessInsuranceRaterService.AccountInformation accountInformation = formData.accountInformation;
        String lastName = (String.isNotBlank(accountInformation.lastName) ? accountInformation.lastName : accountInformation.firstName);
        if( String.isBlank(lastName) )
        {
            lastName = 'Desconocido';
        }
        Account accountToCreate = new Account(
            FirstName = (String.isNotBlank(accountInformation.lastName) ? accountInformation.firstName : ''),
            LastName = lastName,
            Family__c = accountInformation.family,
            CommercialActivity__c = accountInformation.commercialActivity,
            AnnualRevenue = accountInformation.annualRevenue,
            NumberOfEmployees = accountInformation.numberOfEmployees,
            TradeName__c = accountInformation.tradeName,
            NationalId__c = accountInformation.nationalIdentifier,
            NationalIdType__c = (String.isBlank(accountInformation.nationalIdentifier) ? '' : 'N'),
            RecordTypeId = leadRecordTypeId,
            LegalEntity__c = RecordsSelector.getLegalEntity(RecordsSelector.LegalEntity.GI),
            WebIdentifier__c = accountInformation.webIdentifier
            );

        // nts (agonzalezisasi) - 02/09/2021 - fix bug: SOPZUR-304 APR Registros duplicados al enviar trazas al CRM desde ZE 
        Boolean isCreated = true;
        // nts (agonzalezisasi) - 19/12/2021 - fix bug: peticiones repetidas que crean Cuentas (leads) repetidas
        // Preparamos el external id con los campos webEmail y webPhone si estan informados
        string externalid = '';
        if( String.isNotBlank(formData.webEmail) )
            externalid = formData.webEmail;
        if( String.isNotBlank(formData.webPhone) )
            externalid += formData.webPhone;

        // Si alguno de ellos no esta en blanco hacemos upsert
        if( String.isNotBlank(externalid) )
        {
            accountToCreate.LeadWebId__c = externalid;

            Database.UpsertResult result = Database.upsert(accountToCreate, Schema.Account.LeadWebId__c);
            isCreated = result.isCreated();
        }
        else
        {
            insert accountToCreate;
        }

        Account createdLead = [SELECT Id, PersonContactId, Name FROM Account WHERE Id =: accountToCreate.Id LIMIT 1];

        // nts (rpolvera) - 27/08/2021 - fix bug: SOPZUR-304 APR Registros duplicados al enviar trazas al CRM desde ZE 
        // Cuando se crea una nueva cuenta es necesario actualizar el scope.
        if( isCreated ) {            
            //Creamos un Scope para el cliente que acabamos de crear
            currentScope = createScope(accountToCreate, formData.businessCode);
            //Creamos vías de contacto para ese cliente y ese scope
            createContactPointsForScope(currentScope, formData.webEmail, formData.webPhone);
        }

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
        if( customer != null && formData != null )
        {
            Account accountToUpdate = new Account(Id= customer.Id);

            accountToUpdate.Family__c = formData.accountInformation.family;
            accountToUpdate.CommercialActivity__c = formData.accountInformation.commercialActivity;
            accountToUpdate.AnnualRevenue = formData.accountInformation.annualRevenue;
            accountToUpdate.NumberOfEmployees = formData.accountInformation.numberOfEmployees;
            accountToUpdate.TradeName__c = formData.accountInformation.tradeName;
            accountToUpdate.WebIdentifier__c = formData.accountInformation.webIdentifier;
            update accountToUpdate;

            // Si se ha hecho el update, para evitar hacer una soql copiamos los datos a la variable customer original
            customer.Family__c = formData.accountInformation.family;
            customer.CommercialActivity__c = formData.accountInformation.commercialActivity;
            customer.AnnualRevenue = formData.accountInformation.annualRevenue;
            customer.NumberOfEmployees = formData.accountInformation.numberOfEmployees;
            customer.TradeName__c = formData.accountInformation.tradeName;
            customer.WebIdentifier__c = formData.accountInformation.webIdentifier;
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
            LastContactableModifiedDate__c = System.now(),
            LegalEntity__c = RecordsSelector.getLegalEntity(RecordsSelector.LegalEntity.GI)
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
     * 
     * @change 02/06/2021 - nts (agonzalezisasi) - SOPZUR-4 Evolutivo Tarificador Web
     */
    private static void manageOffersAndRelatedInformation(Request formData)
    {
        Scope_Setting__mdt currentScopeSettings = scopeSettings.get(formData.businessCode);
        List<Opportunity> offersToCreate = new List<Opportunity>();
        // Gestión de Ofertas
        if( offersSteps.contains(formData.lastStep) )
        {
            checkOffers(formData, offersToCreate, currentScopeSettings, isTest);
        }
        // Gestión de otros registros relacionados como Campaign Member o Contact Request.
        if( !isTest && !formData.doNotCreateCallback )
        {
            if( campaignMemberSteps.contains(formData.lastStep) )
            {
                //Crear Campaign Member 
                manageCampaignAssignment(offersToCreate, formData.webPhone);
            }

            if( contactRequestSteps.contains(formData.lastStep) )
            {
                // Crear Call Me Back
                checkCallMeBack(formData, offersToCreate, currentScopeSettings);
            }
        }
    }

    //#region CallMeBack

    /**
     * Metodo que gestiona la creacion y cancelacion de CallMeBacks segun lo que viene en el formulario
     * 
     * @author nts (agonzalezisasi)
     * @date 02/06/2021
     * @param {Request} Los datos del formulario
     * @param {List<Opportunity>} Lista de las ofertas
     * @param {Scope_Setting__mdt} Datos de configuracion para el proceso
     */
    private static void checkCallMeBack(Request formData, List<Opportunity> offersToCreate, Scope_Setting__mdt currentScopeSettings)
    {
        ContactRequest contactReqActual = null;

        // Recuperamos los callmeback que haya programados durante el tiempo en el que el usuario esta
        // rellenando el flujo
        List<ContactRequest> contactReqs = new ContactRequestSelector().findByCustomerIdAndContactDatetime(
            currentCustomer.PersonContactId, System.now()
        );
        // Miramos si hay alguno
        if( !contactReqs.isEmpty() ) {
            // Si lo hay, le primero deberia ser el mas prioritario y cercano en el tiempo
            contactReqActual = contactReqs.get(0);
        }
        Boolean isCancel = false;
        Boolean isCreate = false;

        //Si estado Completado -> poner para cancelar
        if( formData.isFinished ) {
            isCancel = true;
        } else { // estado distinto de completado
            if( contactReqActual == null ) { // No existe callback programado actualmente
                isCreate = true;
            } else { // Si existe algun callmeback programado, vemos si hay que sustituirlo...
                // El del formulario es mas PRIORITARIO? o sino, si es mas CERCANO EN EL TIEMPO
                if( formData.hasHigherPriority(Integer.valueOf(contactReqActual.Priority__c))
                    || formData.isCloserInTime(contactReqActual.PreferredContactDatetime__c)) 
                {
                    isCreate = true;
                    isCancel = true;
                }
            }
        }
        
        // Si es cancelar y existe alguno
        if( isCancel && contactReqActual != null ) {
            cancelCallMeBack(contactReqActual);
        }

        // Si es crear
        if( isCreate ) {
            createCallMeBack(formData, offersToCreate, currentScopeSettings);
        }
    }

    /**
     * Metodo que crea un CallMeBack a traves del objeto ContactRequest
     * 
     * @author nts (agonzalezisasi)
     * @date 02/06/2021
     * @param {Request} Los datos del formulario
     * @param {List<Opportunity>} Lista de las ofertas
     * @param {Scope_Setting__mdt} Datos de configuracion para el proceso
     */
    private static void createCallMeBack(Request formData, List<Opportunity> offersToCreate, Scope_Setting__mdt currentScopeSettings)
    {
        //OPCIONAL - puede que no requiera funcionar con genesys
        purecloud__PureCloud_Queue__c genesysQueue;
        try
        {
            if (String.isNotBlank(currentScopeSettings.GenesysCloudQueueName__c))
            {
                genesysQueue = [
                    SELECT  Id,
                            purecloud__PureCloud_Queue_ID__c
                    FROM purecloud__PureCloud_Queue__c
                    WHERE Name = :currentScopeSettings.GenesysCloudQueueName__c
                    LIMIT 1
                ];
            }
        }
        catch (QueryException qe)
        {
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, MISSING_PURECLOUD_QUEUE, BusinessInsuranceRaterService.class.getName(), qe.getStackTraceString());
        }

        Datetime preferredContactDatetime = BusinessInsuranceUtil.getPreferredContactDatetime(
            formData.bestTimeFrom != null ? formData.bestTimeFrom : System.now()
        );

        //Creamos ContactRequest para cualquiera de los pasos
        ContactRequest contactRequestToCreate = new ContactRequest(
            GenesysCloudQueueId__c = genesysQueue?.Id,
            OwnerId = currentAdvisorId,
            PreferredChannel = (String.isBlank(formData.webPhone) ? 'Email' : 'Phone'),
            PreferredContactDatetime__c = preferredContactDatetime,
            PreferredPhone = formData.webPhone,
            RequestReason = 'Offer',
            Status = formData.statusSF,
            WebName__c = formData.accountInformation.firstName + ' ' + formData.accountInformation.lastName,
            WhoId = currentCustomer.PersonContactId
            );

        if( !offersToCreate.isEmpty() )
        {
            contactRequestToCreate.WhatId = offersToCreate.get(0).Id;
        }

        insert contactRequestToCreate;
    }

    /**
     * Solicita la cancelacion de un CallMeBack en Genesys
     * 
     * @author nts (agonzalezisasi)
     * @date  02/06/2021
     * @param {ContactRequest} El ContactRequest a cancelar
     */
    private static void cancelCallMeBack(ContactRequest contactReq)
    {
        // Creamos la cancelacion del CallMeBack poniendo el id de genesys
        GenesysCloud.CallbackCancel callback = new GenesysCloud.CallbackCancel();
        callback.genesysId = contactReq.GenesysInteractionId__c;

        // Creamos la relacion entre el CallMeBack y el ContactRequest para actualizar el estado 
        // de este ultimo
        Map<GenesysCloud.CallbackCancel, String> mapCallbackContactReq = new Map<GenesysCloud.CallbackCancel, String>{
            callback => contactReq.Id
        };

        // Solicitamos la cancelacion del CallMeBack a Genesys
        GenesysCloud.CallbacksService.cancel(
            new List<GenesysCloud.CallbackCancel>{callback},
            new UpdateCallbackCancel(mapCallbackContactReq)
        );
    }

    /**
     * Clase Helper que recibe el resultado de la solicitud de cancelacion hecha a Genesys y si ha
     * ido todo bien actualiza el ContactRequest al estado cancelado
     */
    public class UpdateCallbackCancel implements GenesysCloud.IAPICallback
    {
        // Mapa de relacion entre el CallMeBack y el ContactRequest
        Map<GenesysCloud.CallbackCancel, String> contactRequestIdsByCallback;

        // Constructor
        public UpdateCallbackCancel(Map<GenesysCloud.CallbackCancel, String> contactRequestIdsByCallback)
        {
            this.contactRequestIdsByCallback = contactRequestIdsByCallback;
        }

        // onSuccess Method
        public void onSuccess(List<Object> results, List<GenesysCloud.IAPIRequest> requests)
        {
            List<ContactRequest> contactReqToUpdate = new List<ContactRequest>();

            // Por cada peticion
            for(Object result : results) {
                // Recuperamos el callmeback que se cancelo
                GenesysCloud.CallbackCancel callback = (GenesysCloud.CallbackCancel) result;
                // Obtenemos el Id de la ContactRequest del mapa
                String contactRequestId = contactRequestIdsByCallback.get(callback);

                // Lo añadimos a la lista de ContactRequest a modificar
                contactReqToUpdate.add(
                    new ContactRequest(
                        Id= contactRequestId,
                        Status= ContactRequestSelector.STATUS_CANCELLED
                    )
                );
            }

            // Modificamos los ContactRequest para cancelarlos
            if( !contactReqToUpdate.isEmpty() ) {
                update contactReqToUpdate;
            }
        }

        // onError Method
        public void onError(Exception error)
        {
            ErrorLogUtil.commitError(error);
        }
    }

    //endregion

    //#region Offer Creation And Update

    private static void checkOffers(Request formData, List<Opportunity> offersToCreate, Scope_Setting__mdt currentScopeSettings, Boolean isTest)
    {
        if( formData.offers != null && !formData.offers.isEmpty() ) {
            List<BusinessInsuranceRaterService.Offer> receivedOffers = formData.offers;

            // Obtenemos todos los quoteNumberINFO que nos vienen de la Request
            Set<String> listaQuoteNumbers = new Set<String>();
            for (BusinessInsuranceRaterService.Offer rOffer : receivedOffers)
            {
                if (!String.isBlank(rOffer.quoteNumberINFO))
                {
                    listaQuoteNumbers.add(rOffer.quoteNumberINFO);
                }
            }

            // Obtenemos los QuoteNumber que están en SF y que están ya modificadas por Info (los que no deben actualizarse).
            Set<String> existingSFQuoteNumbers = new OpportunitiesSelector().findUpdatedFromInfoByQuoteNumber(listaQuoteNumbers);

            // Checkeamos si las ofertas que nos llegan del tarificador han de ser procesadas a continuacion o no
            List<BusinessInsuranceRaterService.Offer> toProcessReceivedOffers = new List<BusinessInsuranceRaterService.Offer>();

            if (existingSFQuoteNumbers.size() > 0)
            {
                for (BusinessInsuranceRaterService.Offer rOffer : receivedOffers)
                {
                    // Si la oferta no tiene quoteInfo, o no está contenido en los que hemos obtenido, se procesará
                    if(String.isBlank(rOffer.quoteNumberINFO) || !existingSFQuoteNumbers.contains(rOffer.quoteNumberINFO))
                    {
                        toProcessReceivedOffers.add(rOffer);
                    }
                    else
                    {
                        ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_WARNING, 'No se puede actualizar la oferta porque existe en INFO. QuoteNumber: ' + rOffer.quoteNumberINFO, 'BusinessInsuranceRaterService');   
                    }
                }
                // actualizamos y dejamos sólo las ofertas que vamos a procesar
                receivedOffers = toProcessReceivedOffers;
            }

            // Finalmente, machacamos los datos que nos venian del request por los datos filtrados.
            List<Policy__c> policiesToCreate = new List<Policy__c>();
            List<Asset> risksToCreate = new List<Asset>();
            Map<Integer, BusinessInsuranceRaterService.OfferRiskInformation> quoteNumberRiskMap = new Map<Integer, BusinessInsuranceRaterService.OfferRiskInformation>();
            Map<Integer, String> quoteNumberToPolicyNumberMap = new Map<Integer, String>();

            // Productos - a partir de los codigos comercial y tecnico
            Map<String, Product2> productCodesToProductMap = getProductsFromOfferCodes(receivedOffers);
            String sessionId = formData.sessionId;
            String scope = (String.isNotBlank(currentScopeSettings?.Scope__c) ? currentScopeSettings.Scope__c : 'ZE');

            List<Opportunity> existingOffers = new OpportunitiesSelector().findByAccountIdAndScope(
                currentCustomer.Id, scope
            );
            // Relacion de ofertas que no vienen en el formulario y puede que se tengan que borrar
            Map<String, Opportunity> mapOffersToDelete = new Map<String, Opportunity>();

            // Por cada Oferta que hay en Salesforce....
            for (Opportunity o : existingOffers) {
                // Miramos cual de los dos id externos tiene, dando prioridad al INFOQuoteNumber
                if( o.INFOQuoteNumber__c != null ) {
                    mapOffersToDelete.put(o.INFOQuoteNumber__c, o);
                } else if( o.SessionId__c != null && o.SessionId__c.Contains(sessionId) ) {
                    mapOffersToDelete.put(o.SessionId__c, o);
                } 
            }

            List<Opportunity> offersBySessionId = new List<Opportunity>();
            List<Opportunity> offersByQuoteNumber = new List<Opportunity>();

            // Por cada Oferta que viene del formulario...
            if(!receivedOffers.isEmpty())
            {
                for(Integer i=0; i < receivedOffers.size(); i++) {
                    BusinessInsuranceRaterService.Offer offer = receivedOffers.get(i);

                    // Producto - calculamos el codigo conjunto para la oferta
                    String productCodes = offer.productCodes;
                    // Producto - miramos si lo conocemos, sino sera nulo
                    Product2 product = productCodesToProductMap?.get(productCodes);

                    // Oferta - calculamos el nombre que tendra la oferta
                    String offerName = offer.quoteNumberINFO;
                    if( String.isBlank(offerName) ) {
                        if( product != null ) {
                            offerName = product.Name + ' - ' + currentCustomer.Name;
                        } else {
                            offerName = offer.commercialPC + ' - ' + offer.technicalPC + ' - ' + currentCustomer.Name;
                        }
                    }

                    // Oferta - calculamos el id externo: SessionId
                    String externalSessionId = sessionId + productCodes;

                    // Oferta - calculamos el paso de la oferta: Stage
                    String stageName = 'Legit Lead';
                    if( String.isNotBlank(offer.policyNumber) ) {
                        stageName = 'Closed Won';
                    } else if(offer.netPremium != null) {
                        stageName = 'Quoted';
                    } else if( offer.netPremium == null && String.isNotBlank(formData.webPhone) ) {
                        stageName = 'App Submitted';
                    }

                    // Oferta - obtenemos una oferta con todos los datos que vienen del formulario 
                    Opportunity sfOffer = offer.toOpportunity();

                    // Oferta - a partir del id externo miramos si ya existe en Salesforce
                    if( mapOffersToDelete.containsKey(sfOffer.INFOQuoteNumber__c) ) {
                        mapOffersToDelete.remove(sfOffer.INFOQuoteNumber__c);
                    } else if( mapOffersToDelete.containsKey(externalSessionId) ) {
                        mapOffersToDelete.remove(externalSessionId);
                    } 

                    // Oferta - finalmente rellenamos los campos calculados que faltan de la oferta
                    sfOffer.SessionId__c = externalSessionId;
                    sfOffer.Name = offerName;
                    sfOffer.ScopeId__c = currentScope.Id;
                    sfOffer.Scope__c = scope;
                    sfOffer.StageName = stageName;
                    sfOffer.OwnerId = currentAdvisorId;
                    sfOffer.AccountId = currentCustomer.Id;
                    sfOffer.BusinessCode__c = (String.isNotBlank(offer.businessCode) ? offer.businessCode : formData.businessCode);
                    sfOffer.BusinessName__c = (String.isNotBlank(currentScopeSettings?.Label) ? currentScopeSettings.Label : 'ZURICH EMPRESAS DIGITAL');
                    sfOffer.ProductId__c = product?.Id;
                    sfOffer.LegalEntity__c = RecordsSelector.getLegalEntity(RecordsSelector.LegalEntity.GI);
                    sfOffer.LegalAuth__c = (formData.legalAuth != null ? formData.legalAuth : false);
                    sfOffer.IsTest__c = isTest;

                    offersToCreate.add(sfOffer);

                    if( sfOffer.INFOQuoteNumber__c != null ) {
                        offersByQuoteNumber.add(sfOffer);
                    } else {
                        offersBySessionId.add(sfOffer);
                    }

                    // Poliza
                    if( String.isNotBlank(offer.policyNumber) ) {
                        quoteNumberToPolicyNumberMap.put(i, offer.policyNumber);
                    }

                    // Risk (objeto asegurado)
                    BusinessInsuranceRaterService.OfferRiskInformation risk = offer.offerRiskInformation;
                    if(risk != null) {
                        quoteNumberRiskMap.put( i, risk);
                    }
                }
            }

            // Creacion de la oferta
            if( !offersToCreate.isEmpty() ) {
                // Creamos o actualizamos las ofertas por id externos
                if( !offersByQuoteNumber.isEmpty() ) upsert offersByQuoteNumber Opportunity.INFOQuoteNumber__c;
                if( !offersBySessionId.isEmpty() ) upsert offersBySessionId Opportunity.SessionId__c;

                Id addressRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Address').getRecordTypeId();

                // Por cada Oferta insertada o actualizada...
                for(Integer i=0; i < offersToCreate.size(); i++)
                {
                    Opportunity offer = offersToCreate.get(i);


                    // Polizas - si tiene numero de poliza la preparamos para crearla
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
                                ScopeId__c = currentScope.Id,
                                OpportunityName__c= offer.Id
                                )
                            );
                    }

                    // Riesgo - si hay riesgo lo preparamos
                    if( quoteNumberRiskMap.containsKey(i) )
                    {
                        BusinessInsuranceRaterService.OfferRiskInformation risk = quoteNumberRiskMap.get(i);
                        
                        // Obtenemos un objeto Asset con los datos que hay en el formulario
                        Asset sfRisk = risk.toAsset();

                        // Rellenamos el resto de campos calculados
                        sfRisk.INFOInsuredObjectCode__c = (String.isBlank(offer.InfoQuoteNumber__c) ? offer.SessionId__c : offer.InfoQuoteNumber__c) + '01';
                        sfRisk.OfferId__c = offer.Id;
                        sfRisk.AccountId = currentCustomer.Id;
                        sfRisk.Scope__c = currentScope.Scope__c;
                        sfRisk.recordTypeId = addressRecordTypeId;
                        sfRisk.LegalEntity__c = RecordsSelector.getLegalEntity(RecordsSelector.LegalEntity.GI);

                        risksToCreate.add( sfRisk );
                    }
                }

                // Poliza - insercion o actualizacion
                if( !policiesToCreate.isEmpty() )
                {
                    // Actualizamos o insertamos las polizas
                    List<Database.UpsertResult> results = Database.upsert(policiesToCreate, Policy__c.InfoPolicyNumber__c);

                    // Si existe el manager establecemos la relacion con la poliza
                    if( currentManager?.Id != null  ) {
                        // Miramos que polizas han sido creadas
                        List<Policy__c> createdPolicies = new List<Policy__c>();
                        for( Database.UpsertResult r: results ) {
                            if( r.isCreated() ) {
                                createdPolicies.add(new Policy__c(
                                    Id= r.Id
                                ));
                            }
                        }
                        // Y establecemos la relacion
                        createRelationPolicyManager(createdPolicies);
                    }
                }

                // Riesgo - insercion o actualizacion
                if( !risksToCreate.isEmpty() )
                {
                    upsert risksToCreate INFOInsuredObjectCode__c;
                }
            }

            // Borrado - Ofertas del id de sesion actual pero que ya no vienen en el formulario
            if( !mapOffersToDelete.isEmpty() ) {
                List<Opportunity> offersToDelete = new List<Opportunity>();
                for (Opportunity o : mapOffersToDelete.values() ) {
                    if( o.SessionId__c != null && o.SessionId__c.contains(sessionId) ) {
                        offersToDelete.add(o);
                    }
                }
                if( !offersToDelete.isEmpty() ) {
                    delete offersToDelete;
                }
            }
        }
    }

    //#endregion

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
                    managers = AccountSearchService.findCustomersByEmail(new List<String> {managerInformation.email}, RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.GI);
                }

                if( managers.isEmpty() && String.isNotBlank(managerInformation.phone) )
                {
                    //Buscamos por Telefono
                    managers = AccountSearchService.findCustomersByEmail(new List<String> {managerInformation.phone}, RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.GI);
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
        List<Opportunity> existingOffers = new OpportunitiesSelector().selectByAccountIdScopesAndOwnerProfile(
            currentCustomer.Id, new Set<Id> {currentScope.Id}, new Set<String> {PROFILE_NAME}
        );

        System.debug('Lista existingOffers ' + existingOffers.size());
        if(existingOffers.size() > 0)
        {
            System.debug('Lista existingOffers ' + existingOffers.get(0).OwnerId);
        }

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
        if( createdPolicies != null && !createdPolicies.isEmpty() )
        {
            Id policyRelationshipRecordTypeId = Schema.SObjectType.Relationship__c.getRecordTypeInfosByDeveloperName().get('Policy').getRecordTypeId();
            List<Relationship__c> relations = new List<Relationship__c>();
            for(Policy__c policy: createdPolicies)
            {
                relations.add(
                    new Relationship__c(
                        LegalEntity__c = RecordsSelector.getLegalEntity(RecordsSelector.LegalEntity.GI),
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
                upsert relations;
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

    /**
     * Comprueba los datos de la solicitud, si el teléfono o el correo electrónico se encuentra identificado como inválido retorna verdadero.
     * Estos datos son generados a partir de un bot que lanza diariamente una serie de pruebas para comprobar
     * que la web del tarificador de Zurich Empresas funciona correctamente y sin errores.
     * Datos inválidos:
     * --Teléfono: 
     *              600000000
     *              615462099
     *              655004026
     * --Correo:
     *              test@zurichtest.com
     * @author rpolvera@nts-solutions.com
     * @date 17/08/2021
     * @param request Clase contenedora de la información de la soliitud -> BusinessInsuranceRaterService.Request
     * @return Verdadero si la solicitud ha sido generada por el bot de pruebas, de lo contrario retorna falso.
     */
    public static Boolean isBotTestingExecution(BusinessInsuranceRaterService.Request request)
    {
        List<String> fakeEmails = [SELECT Value__c FROM AdminSetupParameter__mdt WHERE DeveloperName = 'BusinessRaterEmailsToIgnore']?.Value__c?.split(',');
        List<String> fakePhones = [SELECT Value__c FROM AdminSetupParameter__mdt WHERE DeveloperName = 'BusinessRaterPhonesToIgnore']?.Value__c?.split(',');
        return (fakeEmails != null && fakeEmails.contains(request.webEmail)) || (fakePhones != null && fakePhones.contains(request.webPhone));
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
     * 
     * @change 02/06/2021 - nts (agonzalezisasi) - Se incluye el campo prioridad
     * @change 04/02/2022 - nts (arcortazar) - Se incluye el campo webIdentifier
     */
    public class Request
    {
        //Desde el Flow ZECreateLead no se quiere crear ContactRequest
        public Boolean doNotCreateCallback {
            get {
                if(doNotCreateCallback == null)
                {
                    return false;
                }
                else
                {
                    return doNotCreateCallback;
                }
            }
            set {
                doNotCreateCallback = value;
            }
        }

        public Datetime timeStamp {
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
        public Datetime bestTimeFrom {
            get;
            set {
                setRequiredFields('Request' + 'bestTimeFrom');
                bestTimeFrom = value;
            }
        }
        public Datetime bestTimeUntil {
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
        public Boolean legalAuth {
            get;
            set {
                setRequiredFields('Request' + 'legalAuth');
                legalAuth = value;
            }
        }
        public List<Offer> offers {
            get;
            set {
                setRequiredFields('Request' + 'offers');
                offers = value;
            }
        }

        // Propiedad que convierte el Status que viene del formulario a un valor numerico
        // que representa la Prioridad (menor valor + prioridad) a la hora de gestionar
        // los call me back que pueda haber ya programados para el cliente.
        // Ver tambien el campo formula Priority__c del objeto ContactRequest
        public Integer priority {
            get {
                Integer result = mapPriorities.get(status);
                if( result == null ) result = 6; // para un estado desconocido se pone la menor prioridad
                return result;
            }
        }

        // Propiedad que convierte el Status que viene del formulario al valor que tendra
        // el campo RequestStatus en el objeto ContactRequest
        // Ver tambien el campo formula Priority__c del objeto ContactRequest
        public String statusSF {
            get {
                String result = mapStatusToSF.get(status);
                if( result == null ) result = 'New';
                return result;
            }
        }

        // Porpiedad que indica si el formulario llega con el estado Completado (true) o no (false)
        public Boolean isFinished {
            get {
                Boolean result = false;
                if( this.status != null && this.status.equals(FORM_STATUS_COMPLETED) ) result = true;
                return result;
            }
        }
    
        // Determina si la prioridad del estado del formulario es mayor que la indicada
        // Teniendo en cuenta que 0 es mayor prioridad y 6 la de menor prioridad
        public Boolean hasHigherPriority( Integer priority ) {
            return (this.priority < priority);
        }

        // Determina si la fecha y hora de contacto del formulario es mas cercana en el tiempo
        // que la fecha y hora indicadas
        public Boolean isCloserInTime( Datetime contactDatetime ) {
            Datetime preferredContactDatetime = BusinessInsuranceUtil.getPreferredContactDatetime(
                this.bestTimeFrom != null ? this.bestTimeFrom : System.now()
            );
            // fix: ZE-1091 - correccion del error en el test al ejecutarlo fuera del horario laboral
            if( Test.isRunningTest() ) {
                preferredContactDatetime = this.bestTimeFrom;
            }

            return (preferredContactDatetime < contactDatetime);
        }
    }

    /**
     * Clase interna que representa la información de una cuenta, recibida en la solicitud inicial del formulario web de Zurich Empresas
     *
     * @author rlopez
     * @date 15/10/2020
     * 
     * @change 04/02/2022 - nts (arcortazar) - Se incluye el campo webIdentifier
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
            get {
                // nts (agonzalezisasi) - 06/04/2020 - OCS-1606 [ZE] Incidencia - Completar LastName cuando se detecte vacío
                if( String.isBlank(lastName) ) {
                    return '.';
                }
                return lastName;
            }
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

        // arcortazar - 04/02/2022: feat-ZE-1234
        public String webIdentifier {
            get;
            set {
                setRequiredFields('AccountInformation' + 'webIdentifier');
                webIdentifier = value;
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
            get {
                // nts (agonzalezisasi) - 06/04/2020 - OCS-1606 [ZE] Incidencia - Completar LastName cuando se detecte vacío
                if( String.isBlank(lastName) ) {
                    return '.';
                }
                return lastName;
            }
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
                phone =  String.isNotBlank(value) ? addPrefixToPhone(value) : value;
            }
        }
    }

    /**
     * Clase interna que representa la información de las ofertas, recibidas en la solicitud inicial del formulario web de Zurich Empresas
     *
     * @author rlopez
     * @date 15/10/2020
     * 
     * @change 04/06/2021 - nts (agonzalezisasi) - se añaden propiedades calculadas a partir de los datos
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
        public Double firstReceipt {
            get;
            set {
                setRequiredFields('Offer' + 'firstReceipt');
                firstReceipt = value;
            }
        }
        public Double nextReceipts {
            get;
            set {
                setRequiredFields('Offer' + 'nextReceipts');
                nextReceipts = value;
            }
        }
        public OfferRiskInformation offerRiskInformation {
            get;
            set {
                setRequiredFields('Offer' + 'offerRiskInformation');
                offerRiskInformation = value;
            }
        }
    
        // Propiedad que devuelve los codigos de producto concatenados
        public String productCodes {
            get {
                String result = '';
                if( commercialPC != null ) result += commercialPC;
                if( technicalPC != null ) result += technicalPC;
                return result;
            }
        }

        // Metodo que devuelve un Offer (Opportunity) a partir de los datos del formulario
        public Opportunity toOpportunity() {
            return new Opportunity(
                InfoQuoteNumber__c = quoteNumberINFO,
                Language__c = language,
                IssuedOnline__c = true,
                ResultingPolicyNumber__c = policyNumber,
                EffectiveDate__c = effectiveDate,
                CloseDate = System.today(),
                ExpirationDate__c = System.today().addDays(15),
                CommercialProductCode__c = commercialPC,
                TechnicalProductCode__c = technicalPC,
                TotalPremium__c = netPremium,
                BuildingCapital__c = buildingCapital,
                ContentCapital__c = contentCapital,
                GeneralLiabilityLimit__c = generalLiabilityLimit,
                PaymentType__c = paymentType,
                PaymentTypeSucc__c = paymentTypeSucc,
                PaymentChannel__c = paymentChannel,
                PaymentChannelSucc__c = paymentChannelSucc,
                ValidationErrors__c = validationErrors,
                OperationCode__c = operationCode,
                FirstReceipt__c = firstReceipt,
                NextReceipts__c = nextReceipts
            );
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
        public Integer capacity {
            get;
            set {
                setRequiredFields('OfferRiskInformation' + 'capacity');
                capacity = value;
            }
        }

        // Propiedad que calcula el nombre del Riesgo a partir de los datos que vienen del 
        // formulario
        public String riskName {
            get {
                String result = 'Desconocido';
                if( String.isNotBlank(propertyStreet) ) {
                    result = propertyStreet + ', ';
                    if( String.isNotBlank(propertyStreetNumber) ) {
                        result += propertyStreetNumber;
                    }
                }

                return result;
            }
        }

        // Metodo que devuelve un objeto de tipo Asset con los datos que vienen del formulario
        public Asset toAsset() {
            return new Asset(
                Name = riskName,
                AddressType__c = propertyStreetType,
                AddressName__c = propertyStreet,
                AddressNumber__c = propertyStreetNumber,
                AddressAdditionalInfo__c = propertyAdditionalInfo,
                PostalCode__c = propertyPostalCode,
                City__c = propertyCity,
                State__c = propertyState,
                Country__c = propertyCountry,
                YearOfConstruction__c = yearOfConstruction,
                Ownership__c = ownership,
                InsuredType__c = insuredType,
                Building_Type__c = buildingType,
                Height__c = height,
                RiskFactor01__c = riskFactor01,
                RiskFactor02__c = riskFactor02,
                RiskFactor03__c = riskFactor03,
                RiskFactor04__c = riskFactor04,
                RiskFactor05__c = riskFactor05,
                RiskFactor06__c = riskFactor06,
                RiskFactor07__c = riskFactor07,
                RiskFactor08__c = riskFactor08,
                RiskFactor09__c = riskFactor09,
                Area__c = area,
                LockType__c = lockType,
                SecurityDoor__c = securityDoor,
                BulletproofDoor__c = bulletproofDoor,
                ConnectedAlarm__c = connectedAlarm,
                FireHydrant__c = fireHydrant,
                X24h_Security__c = surveillance,
                SmokeDetector__c = smokeDetector,
                Sprayer__c = sprayer,
                FireExtinguisher__c = fireExtinguisher,
                TypeOfWindows__c = typeOfWindows,
                Safe__c = strongbox,
                Capacity__c = capacity
            );
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