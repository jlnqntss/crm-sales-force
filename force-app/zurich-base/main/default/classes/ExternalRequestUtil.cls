/**
** Utility class for ExternalRequest__c object
* @author nbizkarra
* @date 01/04/2020
*
* @update Enara Etxaniz
* @date 25/08/2020
* Fix identation
* Add Customer EMEA logic
**/
global without sharing class ExternalRequestUtil
{
    // Declare variables

    // Parsing
    public static ExternalRequest__c actualRequest = new ExternalRequest__c();

    public static Map<String, Object> recordsToProcess = new Map<String, Object>();

    public static Set<String> contactsToSearch = new Set<String>();
    public static Set<String> contactEmails = new Set<String>();

    public static Set<String> quotesToSearch = new Set<String>();
    public static Set<String> policiesToSearch = new Set<String>();
    public static Set<String> orderItemsToSearch = new Set<String>();
    public static Set<String> productsToSearch = new Set<String>();
    public static Set<String> partnersToSearch = new Set<String>();
    public static Set<String> coversToSearch = new Set<String>();
    public static Set<String> claimsToSearch = new Set<String>();

    public static Map<String, Order> quotesToProcess = new Map<String, Order>();
    public static Map<String, List<OrderItem> > orderItemsToProcess = new Map<String, List<OrderItem> >();
    public static Map<String, List<Discount__c> > discountsToProcess = new Map<String, List<Discount__c> >();
    public static Map<String, List<Cover__c> > coversToProcess = new Map<String, List<Cover__c> >();

    // Querying
    public static Map<String, Contact> mapContacts = new Map<String, Contact>();
    public static Map<String, Contact> mapContactsEmailBirthDateLECountry = new Map<String, Contact>();
    public static Map<String, Contact> mapContactsEmailBirthDateLE = new Map<String, Contact>();
    public static Map<String, Contact> mapContactsEmailBirthDate = new Map<String, Contact>();

    public static Map<String, Account> mapPartners = new Map<String, Account>();

    public static Map<String, Order> mapQuotes = new Map<String, Order>();
    public static Map<String, Order> mapPolicies = new Map<String, Order>();
    public static Map<String, OrderItem> mapOrderItem = new Map<String, OrderItem>();

    public static Map<String, Case> mapClaims = new Map<String, Case>();
    public static Map<String, Contact> contactPolicyDateUpdate = new Map<String, Contact>();

    public static Map<String, PricebookEntry> mapProducts = new Map<String, PricebookEntry>();
    public static Map<String, Cover__c> mapCovers = new Map<String, Cover__c>();
    public static Pricebook2 pricebook = SystemUtil.getStandardPricebook();
    public static AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
    public static User recordOwner = SystemUtil.recordOwnerSelector();

    // Process
    public static Map<String, Account> mastersToUpdate = new Map<String, Account>();
    public static Map<String, Account> mastersToUpdateEMEA = new Map<String, Account>();
    public static Map<String, Account> mastersToUpdateById = new Map<String, Account>();
    public static Map<String, Contact> contactsToUpdate = new Map<String, Contact>();
    public static Map<String, Order> quotesToUpdateList = new Map<String, Order>();
    public static Map<String, Order> ordersToUpdateList = new Map<String, Order>();
    public static Map<String, Order> policiesToUpdateList = new Map<String, Order>();
    public static Map<String, Contact> contactsToUpdateWithPartner = new Map<String, Contact>();
    public static Map<String, Order> ordersToUpdateWithPartner = new Map<String, Order>();
    public static Map<String, Order> policiesToUpdateWithPartner = new Map<String, Order>();
    public static Map<String, Discount__c> discountsToInsert = new Map<String, Discount__c>();
    public static Map<String, Discount__c> discountsToDelete = new Map<String, Discount__c>();
    public static List<Discount__c> listDiscounts = new List<Discount__c>();
    public static Map<String, Product2> productsToInsert = new Map<String, Product2>();
    public static Map<String, PricebookEntry> pricebookEntryToInsert = new Map<String, PricebookEntry>();
    public static List<OrderItem> listOrderItems = new List<OrderItem>();
    public static Map<String, OrderItem> orderItemsToInsert = new Map<String, OrderItem>();
    public static Map<String, Cover__c> subCoversToInsertQuote = new Map<String, Cover__c>();

    public static Map<String, Case> claimsToUpsert = new Map<String, Case>();
    public static Map<String, Cover__c> updateCover = new Map<String, Cover__c>();

    public static List<Cover__c> insertCover = new List<Cover__c>();
    public static Map<String, Cover__c> mapInsertedCovers = new Map<String, Cover__c>();
    public static List<Cover__c> listCovers = new List<Cover__c>();
    public static Map<String, Account> partnersToUpdateList = new Map<String, Account>();
    public static Map<String, PolicyVersion__c> policyVersionsToUpdateList = new Map<String, PolicyVersion__c>();

    // Main mehod
    public static void processExternalRequests(
        List<ExternalRequest__c> externalRequestList
        )
    {
        System.debug(
            '- - - - - ExternalRequestUtil.processExternalRequests - - - - -'
            );
        if (externalRequestList != null && !externalRequestList.isEmpty() )
        {
            emptyStaticVariables();
            parseExternalRequests(externalRequestList);
            getDataForProcessing();
            processObjects(externalRequestList);
            upsertData();
        }
    }

    // Empty static variables
    private static void emptyStaticVariables()
    {
        System.debug(
            '- - - - - ExternalRequestUtil.emptyStaticVariables - - - - -'
            );
        actualRequest = new ExternalRequest__c();

        recordsToProcess = new Map<String, Object>();

        contactsToSearch = new Set<String>();
        contactEmails = new Set<String>();

        quotesToSearch = new Set<String>();
        policiesToSearch = new Set<String>();
        orderItemsToSearch = new Set<String>();
        productsToSearch = new Set<String>();
        partnersToSearch = new Set<String>();
        coversToSearch = new Set<String>();
        claimsToSearch = new Set<String>();

        quotesToProcess = new Map<String, Order>();
        orderItemsToProcess = new Map<String, List<OrderItem> >();
        discountsToProcess = new Map<String, List<Discount__c> >();
        coversToProcess = new Map<String, List<Cover__c> >();

        // Querying
        mapContacts = new Map<String, Contact>();
        mapContactsEmailBirthDateLECountry = new Map<String, Contact>();
        mapContactsEmailBirthDateLE = new Map<String, Contact>();
        mapContactsEmailBirthDate = new Map<String, Contact>();

        mapPartners = new Map<String, Account>();

        mapQuotes = new Map<String, Order>();
        mapPolicies = new Map<String, Order>();
        mapOrderItem = new Map<String, OrderItem>();

        mapClaims = new Map<String, Case>();
        contactPolicyDateUpdate = new Map<String, Contact>();

        mapProducts = new Map<String, PricebookEntry>();
        mapCovers = new Map<String, Cover__c>();
        pricebook = SystemUtil.getStandardPricebook();
        adminSetup = SystemUtil.getAdminSetupMetadata();
        recordOwner = SystemUtil.recordOwnerSelector();

        // Process
        mastersToUpdate = new Map<String, Account>();
        mastersToUpdateEMEA = new Map<String, Account>();
        mastersToUpdateById = new Map<String, Account>();
        contactsToUpdate = new Map<String, Contact>();
        quotesToUpdateList = new Map<String, Order>();
        ordersToUpdateList = new Map<String, Order>();
        policiesToUpdateList = new Map<String, Order>();
        contactsToUpdateWithPartner = new Map<String, Contact>();
        ordersToUpdateWithPartner = new Map<String, Order>();
        policiesToUpdateWithPartner = new Map<String, Order>();
        discountsToInsert = new Map<String, Discount__c>();
        discountsToDelete = new Map<String, Discount__c>();
        listDiscounts = new List<Discount__c>();
        productsToInsert = new Map<String, Product2>();
        pricebookEntryToInsert = new Map<String, PricebookEntry>();
        listOrderItems = new List<OrderItem>();
        orderItemsToInsert = new Map<String, OrderItem>();
        subCoversToInsertQuote = new Map<String, Cover__c>();

        claimsToUpsert = new Map<String, Case>();
        updateCover = new Map<String, Cover__c>();

        insertCover = new List<Cover__c>();
        mapInsertedCovers = new Map<String, Cover__c>();
        listCovers = new List<Cover__c>();
        partnersToUpdateList = new Map<String, Account>();
        policyVersionsToUpdateList = new Map<String, PolicyVersion__c>();
    }

    // Parse External requests
    private static void parseExternalRequests(
        List<ExternalRequest__c> externalRequestList
        )
    {
        System.debug(
            '- - - - - ExternalRequestUtil.parseExternalRequests - - - - -'
            );
        System.debug('externalRequestList >>> ' + externalRequestList);
        for (ExternalRequest__c externalRequestItem : externalRequestList)
        {
            try
            {
                System.debug('externalRequestItem >>> ' + externalRequestItem);
                actualRequest = externalRequestItem;
                if (externalRequestItem.Entity__c != null)
                {
                    switch on externalRequestItem.Entity__c {
                        // Order
                        when 'QuoteEntry' {
                            parseQuoteEntry();
                        }
                        // Contact && Account
                        when 'Customer' {
                            parseCustomer();
                        }
                        // Order
                        when 'Policy' {
                            parsePolicy();
                        }
                        // Case
                        when 'Claim' {
                            parseClaim();
                        }
                        when else
                        {
                            throw new IntegrationException(
                                      Label.ParseError +
                                      'Unsupported entity type: ' +
                                      externalRequestItem.Entity__c
                                      );
                        }
                    }
                }
            }
            catch (Exception e)
            {
                //ErrorLogUtil.commitError(e, 'ExternalRequestUtil', externalRequestItem.Id);
                externalRequestItem.processed__c = true;
                externalRequestItem.processedDate__c = Datetime.now();
                externalRequestItem.processResult__c = 'KO';
                externalRequestItem.error_Log__c =
                    e.getMessage() +
                    '\n' +
                    e.getStackTraceString();
            }
        }
    }

    private static void parseQuoteEntry()
    {
        System.debug('- - - - - ExternalRequestUtil.parseQuoteEntry - - - - -');
        System.debug('actualRequest >>> ' + actualRequest);
        System.debug('actualRequest.json__c >>> ' + actualRequest.json__c);
        if (actualRequest != null && String.isNotBlank(actualRequest.json__c) )
        {
            if (Test.isRunningTest() )
            {
                // Parse quote
                parseOrder('{}');

                // Parse customer
                parseCustomer('{}');
            }
            else
            {
                // Quote entries contains both lead and quote data. Split in separated objects.
                List<String> splittedQuoteEntry = actualRequest.json__c.split(
                    '"quoteEntry":'
                    );
                if (splittedQuoteEntry.size() == 2)
                {
                    splittedQuoteEntry = splittedQuoteEntry[1].split(',"customer":');
                    if (splittedQuoteEntry.size() == 2)
                    {
                        // Reformat properly as indepedent objects
                        String quoteJson = '[' + splittedQuoteEntry[0] + ']';
                        String leadJson = '[' + splittedQuoteEntry[1].removeEnd('}]') + ']';

                        // Parse quote
                        parseOrder(quoteJson);

                        // Parse customer
                        parseCustomer(leadJson);
                    }
                }
            }
        }
    }

    private static void parseOrder(String orderJson)
    {
        System.debug('- - - - - ExternalRequestUtil.parseOrder - - - - -');

        String entityType = actualRequest.entity__c;

        Map<String, String> errorMessages = new Map<String, String>();
        Map<String, String> errorMessages2 = new Map<String, String>();
        Map<String, sObject> recordsMap = new Map<String, sObject>();
        Map<String, sObject> recordsMap2 = new Map<String, sObject>();
        Map<String, List<SObject> > secLvlRecordsMap = new Map<String, List<SObject> >();
        Map<String, List<SObject> > thrLvlRecordsMap = new Map<String, List<SObject> >();
        if (Test.isRunningTest() )
        {
            if (entityType == 'Policy')
            {
                recordsMap = Mock_Parser.MockParser('Policy');
                secLvlRecordsMap = Mock_Parser.MockParserSecondLevel('Policy');
                thrLvlRecordsMap = Mock_Parser.MockParserThirdLevel('Policy');
            }
            else if (entityType == 'QuoteEntry')
            {
                recordsMap = Mock_Parser.MockParser('QuoteEntry');
                //recordsMap2.put('9090', recordsMap.values().get(1));
                secLvlRecordsMap = Mock_Parser.MockParserSecondLevel('QuoteEntry');
                thrLvlRecordsMap = Mock_Parser.MockParserThirdLevel('QuoteEntry');
            }
        }
        else
        {
            // Reorder
            orderJson = reorderOrderJson(orderJson);

            // Parse
            Schema.SObjectType orderEntity = Schema.getGlobalDescribe().get('Order');
            WebServicesParser.WebParserResult parserResultQuote;
            if (entityType == 'Policy')
            {
                parserResultQuote = WebServicesParser.parseObject(
                    orderEntity,
                    orderJson,
                    'Internal',
                    'ProcessRequest'
                    );
            }
            else if (entityType == 'QuoteEntry')
            {
                parserResultQuote = WebServicesParser.parseObject(
                    orderEntity,
                    orderJson,
                    'Internal',
                    'QuoteEntry'
                    );
            }
            recordsMap = parserResultQuote.recordsMap;
            errorMessages = parserResultQuote.errorMessagesMap;
            secLvlRecordsMap = parserResultQuote.secLvlRecordsMap;
            thrLvlRecordsMap = parserResultQuote.thrLvlRecordsMap;
        }

        // Parsing errors?
        if (!errorMessages.isEmpty() )
        {
            throw new IntegrationException(Label.ParseError + ': ' + errorMessages);
        }

        // Quote or policy
        Order incomingOrder = (Order) recordsMap.values().get(0);

        // Set source country, timestamp and after processing check
        incomingOrder.sourceCountry__c = actualRequest.country__c;

        incomingOrder.processing_Timestamp__c = actualRequest.timestamp__c;
        incomingOrder.after_Processing_Check__c = true;

        if (!String.isBlank(incomingOrder.masterPolicyNum__c) )
        {
            partnersToSearch.add(incomingOrder.masterPolicyNum__c);
        }

        // Add prefix to quotes coming from IBA EMEA to avoid potential repetition of this identifier
        if (incomingOrder.sourceCountry__c != 'Spain')
        {
            if (entityType == 'Policy')
            {
                incomingOrder.policyNum__c = 'EMEA-' + incomingOrder.policyNum__c;
            }
            else
            {
                incomingOrder.quoteEntry__c = 'EMEA-' + incomingOrder.quoteEntry__c;
            }
        }

        String customerNumber = ContactUtil.adaptCustomerNum(
            incomingOrder.customerNum__c,
            incomingOrder.legalEntity__c
            );
        // If the order is a policy
        if (
            entityType == 'Policy' &&
            !String.isBlank(incomingOrder.customerNum__c) &&
            !String.isBlank(incomingOrder.legalEntity__c)
            )
        {
            if (
                !String.isBlank(incomingOrder.QuoteEntry__c) &&
                incomingOrder.sourceCountry__c != 'Spain'
                )
            {
                incomingOrder.QuoteEntry__c = 'EMEA-' + incomingOrder.QuoteEntry__C;
            }
            // Assign prefix to the related customer number
            if (incomingOrder.sourceCountry__c != 'Spain')
            {
                customerNumber = 'EMEA-' + customerNumber;
                incomingOrder.customerNum__c = customerNumber;
            }
            // Add customer to search
            contactsToSearch.add(customerNumber);

            recordsToProcess.put(actualRequest.id, incomingOrder);
            policiesToSearch.add(incomingOrder.policyNum__c);
        }
        else if (entityType == 'QuoteEntry')
        {
            // Assign prefix to the related customer number
            if (incomingOrder.sourceCountry__c != 'Spain')
            {
                customerNumber = 'EMEA-' + customerNumber;
                incomingOrder.customerNum__c = customerNumber;
            }
            quotesToProcess.put(actualRequest.id, incomingOrder);
        }

        if (!String.isBlank(incomingOrder.quoteEntry__c) )
        {
            quotesToSearch.add(incomingOrder.quoteEntry__c);
        }

        // Order Items
        List<OrderItem> orderItemList = (List<OrderItem>) secLvlRecordsMap.get(
            'OrderItem'
            );
        if (orderItemList != null && !orderItemList.isEmpty() )
        {
            // Throw error if it is a General insurance quote and any itemId is empty
            if (incomingOrder.LegalEntity__c.equals(Label.GeneralInsurance) )
            {
                for (OrderItem orderItem : orderItemList)
                {
                    if (String.isBlank(orderItem.itemId__c) )
                    {
                        throw new IntegrationException(
                                  Label.ParseError + ': Missing objectID'
                                  );
                    }
                    // Set source country and timestamp
                    orderItem.sourceCountry__c = actualRequest.country__c;

                    // Add prefix to quotes coming from IBA EMEA to avoid potential repetition of this identifier
                    if (orderItem.sourceCountry__c != 'Spain')
                    {
                        orderItem.itemId__c = 'EMEA-' + orderItem.itemId__c;
                        if (entityType == 'Policy')
                        {
                            orderItem.Order.PolicyNum__c =
                                'EMEA-' + orderItem.Order.PolicyNum__c;
                        }
                    }
                    orderItem.processing_Timestamp__c = actualRequest.timestamp__c;
                    orderItemsToSearch.add(orderItem.ItemId__c);

                    if (orderItem.itemModel__c != null)
                    {
                        // GI insurance
                        productsToSearch.add(orderItem.itemModel__c);
                    }
                    else
                    {
                        // Life insurance, category: insured person
                        productsToSearch.add(orderItem.category__c);
                    }
                }
            }
            orderItemsToProcess.put(actualRequest.Id, orderItemList);
        }

        // Covers
        List<Cover__c> coverList = (List<Cover__c>) thrLvlRecordsMap.get(
            'Cover__c'
            );
        if (coverList != null)
        {
            for (Cover__c coverItem : coverList)
            {
                coverItem.sourceCountry__c = actualRequest.country__c;

                // Add prefix to quotes coming from IBA EMEA to avoid potential repetition of this identifier
                if (coverItem.sourceCountry__c != 'Spain')
                {
                    coverItem.coverId__c = 'EMEA-' + coverItem.coverId__c;
                    if (entityType == 'Policy')
                    {
                        coverItem.PolicyProduct__r.ItemId__c =
                            'EMEA-' + coverItem.PolicyProduct__r.ItemId__c;
                    }
                }
                coverItem.processing_Timestamp__c = actualRequest.timestamp__c;
                coversToSearch.add(
                    coverItem.policyProduct__r.itemId__c +
                    '-' +
                    coverItem.name
                    );
            }
            coversToProcess.put(actualRequest.Id, coverList);
        }

        // Discounts
        List<Discount__c> discountList = (List<Discount__c>) secLvlRecordsMap.get(
            'Discount__c'
            );
        if (discountList != null)
        {
            for (Discount__c discountItem : discountList)
            {
                // Set source country and timestamp
                discountItem.sourceCountry__c = actualRequest.country__c;
                if (discountItem.sourceCountry__c != 'Spain')
                {
                    discountItem.DiscountId__c =
                        'EMEA-' + discountItem.DiscountIdNumber__c;
                    if (entityType == 'Policy')
                    {
                        discountItem.Policy__r.PolicyNum__c =
                            'EMEA-' + discountItem.Policy__r.PolicyNum__c;
                    }
                }
                else
                {
                    discountItem.DiscountId__c = String.valueOf(
                        discountItem.DiscountIdNumber__c
                        );
                }
                discountItem.processing_Timestamp__c = actualRequest.timestamp__c;
            }
            discountsToProcess.put(actualRequest.Id, discountList);
        }
    }

    private static void parseCustomer(String customerJson)
    {
        System.debug('- - - - - ExternalRequestUtil.parseCustomer - - - - -');

        String entityType = actualRequest.entity__c;

        Map<String, String> errorMessages = new Map<String, String>();
        Map<String, String> errorMessages2 = new Map<String, String>();
        Map<String, sObject> recordsMap = new Map<String, sObject>();
        if (Test.isRunningTest() )
        {
            recordsMap = Mock_Parser.MockParser('Customer');
        }
        else
        {
            Schema.SObjectType contactEntity = Schema.getGlobalDescribe()
                                               .get('Contact');
            WebServicesParser.WebParserResult parserResultCustomer = WebServicesParser.parseObject(
                contactEntity,
                customerJson,
                'Internal',
                'ProcessRequest'
                );
            recordsMap = parserResultCustomer.recordsMap;
            errorMessages = parserResultCustomer.errorMessagesMap;
        }

        // Parsing errors?
        if (!errorMessages.isEmpty() )
        {
            throw new IntegrationException(Label.ParseError + ': ' + errorMessages);
        }
        Contact contact = (Contact) recordsMap.values().get(0);

        contact.sourceCountry__c = actualRequest.country__c;
        contact.customerNum__c = ContactUtil.adaptCustomerNum(
            contact.customerNum__c,
            contact.legalEntity__c
            );

        // If the contact has declined to receive marketing communications, set HasOptedOutOfEmail to true
        if (contact.receiveMarketing__c == false)
        {
            contact.HasOptedOutOfEmail = true;
        }

        // The Lastname field is required, it is set to 'unknown' if it comes empty in the request
        if (String.isBlank(contact.LastName) )
        {
            contact.LastName = Label.LeadLastName;
            contact.FirstName = Label.LeadLastName;
        }

        // Add prefix to quotes coming from IBA EMEA to avoid potential repetition of this identifier
        if (contact.sourceCountry__c != 'Spain')
        {
            contact.customerNum__c = 'EMEA-' + contact.customerNum__c;
        }

        contactsToSearch.add(contact.customerNum__c);
        contactEmails.add(contact.email);

        if (!String.isBlank(contact.masterPolicyNum__c) )
        {
            partnersToSearch.add(contact.masterPolicyNum__c);
        }

        recordsToProcess.put(actualRequest.id, contact);
    }

    private static void parseCustomer()
    {
        if (null != actualRequest.json__c)
            parseCustomer(actualRequest.json__c);
    }

    private static void parsePolicy()
    {
        if (null != actualRequest.json__c)
            parseOrder(actualRequest.json__c);
    }

    private static void parseClaim()
    {
        System.debug('- - - - - ExternalRequestUtil.parseClaim - - - - -');

        Map<String, String> errorMessages = new Map<String, String>();
        Map<String, String> errorMessages2 = new Map<String, String>();
        Map<String, sObject> recordsMap = new Map<String, sObject>();

        if (Test.isRunningTest() )
        {
            recordsMap = Mock_Parser.MockParser(actualRequest.Entity__c);
        }
        else
        {
            Schema.SObjectType claimEntity = Schema.getGlobalDescribe().get('Case');
            WebServicesParser.WebParserResult parserResult = WebServicesParser.parseObject(
                claimEntity,
                actualRequest.Json__c,
                'Internal',
                'ProcessRequest'
                );
            recordsMap = parserResult.recordsMap;
            errorMessages = parserResult.errorMessagesMap;
        }

        // Parsing errors?
        if (!errorMessages.isEmpty() )
        {
            throw new IntegrationException(Label.ParseError + ': ' + errorMessages);
        }

        if (recordsMap != null)
        {
            Case claim = (Case) recordsMap.values().get(0);

            claim.sourceCountry__c = actualRequest.country__c;
            if (claim.sourceCountry__c != 'Spain')
            {
                claim.claimNumber__c = 'EMEA-' + claim.claimNumber__c;
            }

            recordsToProcess.put(actualRequest.id, claim);
            claimsToSearch.add(claim.claimNumber__c);

            // Policy
            if (!String.isBlank(claim.PolicyNum__c) )
            {
                if (claim.sourceCountry__c != 'Spain')
                {
                    claim.PolicyNum__c = 'EMEA-' + claim.PolicyNum__c;
                }
                policiesToSearch.add(claim.PolicyNum__c);
            }

            // Customer
            if (!String.isBlank(claim.customerNum__c) )
            {
                // Search customer of both legal entity because claim doesn't specify Legal Entity
                if (claim.sourceCountry__c != 'Spain')
                {
                    contactsToSearch.add(
                        'EMEA-' +
                        ContactUtil.adaptCustomerNum(
                            claim.customerNum__c,
                            Label.GeneralInsurance
                            )
                        );
                    contactsToSearch.add(
                        'EMEA-' +
                        ContactUtil.adaptCustomerNum(
                            claim.customerNum__c,
                            Label.LifeInsurance
                            )
                        );
                }
                else
                {
                    contactsToSearch.add(
                        ContactUtil.adaptCustomerNum(
                            claim.customerNum__c,
                            Label.GeneralInsurance
                            )
                        );
                    contactsToSearch.add(
                        ContactUtil.adaptCustomerNum(
                            claim.customerNum__c,
                            Label.LifeInsurance
                            )
                        );
                }
            }

            // Insured object
            if (!String.isBlank(claim.insuredObjectId__c) )
            {
                if (claim.sourceCountry__c != 'Spain')
                {
                    claim.insuredObjectId__c = 'EMEA-' + claim.insuredObjectId__c;
                }
                orderItemsToSearch.add(claim.insuredObjectId__c);
            }
        }
    }

    /**
    ** Method to reorder children and grandchildren (discounts, items and covers) in the received json.
    * The method returns the related objects in the bottom of the json in order that the parser processes it correctly
    * @author nbizkarra
    * @date 25/05/2020
    **/
    public static String reorderOrderJson(String receivedJson)
    {
        List<Object> objectList = (List<Object>) JSON.deserializeUntyped(
            receivedJson
            );
        Map<String, Object> objectMap = (Map<String, Object>) objectList[0];

        // Discounts
        Object discountsItem = objectMap.remove('discounts');
        String discountsSerialized = JSON.serialize(discountsItem);

        // Items
        Object items = objectMap.remove('items');
        String itemSerialized = JSON.serialize(items);
        List<Object> itemsList = (List<Object>) JSON.deserializeUntyped(
            itemSerialized
            );

        String itemsString = '';
        for (Object objectItem : itemsList)
        {
            Map<String, Object> mapItems = (Map<String, Object>) objectItem;
            String covers = JSON.serialize(mapItems.remove('covers') );

            // Item without covers
            String item = JSON.serialize(mapItems);
            item = item.removeEnd('}');

            // Add covers in the end
            item = item + ',"covers":' + covers;
            itemsString = itemsString + item + '},';
        }
        itemsString = itemsString.removeEnd(',');
        itemsString = '[' + itemsString + ']';

        // Add discount and items to order
        String order = JSON.serialize(objectMap);
        order = order.removeEnd('}');
        order = order + ',"discounts":' + discountsSerialized;
        order = '[' + order + ',"items":' + itemsString + '}]';

        return order;
    }

    // Query data needed for processing
    private static void getDataForProcessing()
    {
        System.debug(
            '- - - - - ExternalRequestUtil.getDataForProcessing - - - - -'
            );
        mapContacts = SystemUtil.contactsSelector(contactsToSearch);
        mapContactsEmailBirthDateLECountry = SystemUtil.contactsSelectorEmailBirthDateLECountry(
            contactEmails
            );
        mapContactsEmailBirthDateLE = SystemUtil.contactsSelectorEmailBirthDateLE(
            contactEmails
            );
        mapContactsEmailBirthDate = SystemUtil.contactsSelectorEmailBirthDate(
            contactEmails
            );
        mapPartners = SystemUtil.partnerSelector(partnersToSearch);
        mapPolicies = SystemUtil.policySelector(policiesToSearch);
        mapQuotes = SystemUtil.quoteSelector(quotesToSearch);
        mapClaims = SystemUtil.claimsSelector(claimsToSearch);
        mapOrderItem = SystemUtil.orderItemSelector(orderItemsToSearch);
        mapProducts = SystemUtil.productsSelector(productsToSearch);
        mapCovers = SystemUtil.coversSelector(coversToSearch);
    }

    // Process
    private static void processObjects(
        List<ExternalRequest__c> externalRequestList
        )
    {
        System.debug('- - - - - ExternalRequestUtil.processObjects - - - - -');
        for (ExternalRequest__c externalRequestItem : externalRequestList)
        {
            try
            {
                actualRequest = externalRequestItem;
                if (externalRequestItem.entity__c != null)
                {
                    switch on externalRequestItem.entity__c {
                        when 'Customer' {
                            processCustomer();
                        }
                        when 'QuoteEntry' {
                            processQuoteEntry();
                        }
                        when 'Policy' {
                            processPolicy();
                        }
                        when 'Claim' {
                            processClaim();
                        }
                    }
                    externalRequestItem.processed__c = true;
                    externalRequestItem.processedDate__c = Datetime.now();
                    externalRequestItem.processResult__c = 'OK';
                    externalRequestItem.error_Log__c = ' ';
                }
            }
            catch (Exception e)
            {
                //ErrorLogUtil.commitError(e, 'ExternalRequestUtil', externalRequestItem.Id);
                externalRequestItem.processed__c = true;
                externalRequestItem.processedDate__c = Datetime.now();
                externalRequestItem.processResult__c = 'KO';
                externalRequestItem.error_Log__c =
                    e.getMessage() +
                    '\n' +
                    e.getStackTraceString();
            }
        }
    }

    private static void processCustomer()
    {
        System.debug('- - - - - ExternalRequestUtil.processCustomer - - - - -');
        // Get the customer
        if (recordsToProcess.containsKey(actualRequest.id) )
        {
            System.debug('LISTA >>> ' + recordsToProcess);
            Contact incomingContact = (Contact) recordsToProcess.get(
                actualRequest.id
                );
            ContactUtil.upsertContact(incomingContact, null);
        }
    }

    private static void processQuoteEntry()
    {
        System.debug('- - - - - ExternalRequestUtil.processQuoteEntry - - - - -');
        // Get the policy
        if (
            recordsToProcess.containsKey(actualRequest.id) &&
            quotesToProcess.containsKey(actualRequest.id)
            )
        {
            /*List<OrderItem> orderItems = orderItemsToProcess.get(actualRequest.id);
                  List<Discount__c> discounts = discountsToProcess.get(actualRequest.id);
                  List<Cover__c> covers = coversToProcess.get(actualRequest.id);*/

            listOrderItems = orderItemsToProcess.get(actualRequest.id);
            listDiscounts = discountsToProcess.get(actualRequest.id);
            listCovers = coversToProcess.get(actualRequest.id);

            Contact contact = (Contact) recordsToProcess.get(actualRequest.id);
            Order quote = (Order) quotesToProcess.get(actualRequest.id);

            OrderUtil.upsertQuote(contact, quote);

            /*OrderUtil.upsertQuote(contact, quote, mapQuotes,quotesToUpdateList,mapContacts,contactsToUpdateList,
                                        mapContactsEmailBirthDateLECountry, mapContactsEmailBirthDateLE, mastersToUpdate,
                                        mastersToUpdateEMEA, mapPartners, contactsToUpdateWithPartner,
                                        ordersToUpdateWithPartner, partnersToUpdateList, discounts, discountsToInsert,
                                        mapOrderItem,orderItems,mapProducts, productsToInsert, pricebookEntryToInsert,
                                        Pricebook, orderItemsToInsert, covers,subCoversToInsertQuote,mapCovers,
                                        updateCover,recordOwner);*/
        }
    }

    private static void processPolicy()
    {
        System.debug('- - - - - ExternalRequestUtil.processPolicy - - - - -');
        // Get the policy
        if (recordsToProcess.containsKey(actualRequest.id) )
        {
            /*List<OrderItem> orderItems = orderItemsToProcess.get(actualRequest.id);
                  List<Discount__c> discounts = discountsToProcess.get(actualRequest.id);
                  List<Cover__c> covers = coversToProcess.get(actualRequest.id);*/

            listOrderItems = orderItemsToProcess.get(actualRequest.id);
            listDiscounts = discountsToProcess.get(actualRequest.id);
            listCovers = coversToProcess.get(actualRequest.id);

            Order policy = (Order) recordsToProcess.get(actualRequest.id);

            /*OrderUtil.upsertPolicy(policy,mapPolicies,policyVersionsToUpdateList,ordersToUpdateList,policiesToUpdateList,
                                         mapContacts,contactsToUpdateList,mapPartners,policiesToUpdateWithPartner,
                                         ordersToUpdateWithPartner,partnersToUpdateList,discounts, discountsToInsert,
                                         discountsToDelete,mapOrderItem,orderItems,mapProducts,productsToInsert,
                                         pricebookEntryToInsert, Pricebook, orderItemsToInsert, covers,subCoversToInsertQuote,
                                         mapCovers,updateCover,adminSetup,mapQuotes,quotesToUpdateList,
                                         contactPolicyDateUpdate,recordOwner);*/

            OrderUtil.upsertPolicy(policy);
            //if quote has been processed first, remove it
            if (!String.isBlank(policy.QuoteEntry__c) )
            {
                quotesToUpdateList.remove(policy.QuoteEntry__c);
            }
        }
    }

    private static void processClaim()
    {
        System.debug('- - - - - ExternalRequestUtil.processClaim - - - - -');
        // Get the claim
        if (recordsToProcess.containsKey(actualRequest.id) )
        {
            Case claim = (Case) recordsToProcess.get(actualRequest.id);

            /*CaseUtil.upsertClaim(claim, mapClaims, mapPolicies, mapContacts, mapOrderItem,
               claimsToUpsert, recordOwner);*/
            CaseUtil.upsertClaim(claim);
        }
    }

    // Upsert objects
    private static void upsertData()
    {
        if (mastersToUpdate != null && !mastersToUpdate.isEmpty() )
        {
            upsert mastersToUpdate.values() Account.Fields.CustomerNum__c;
        }

        if (mastersToUpdateEMEA != null && !mastersToUpdateEMEA.isEmpty() )
        {
            upsert mastersToUpdateEMEA.values() Account.Fields.CustomerNum_EMEA__c;
        }

        if (mastersToUpdateById != null && !mastersToUpdateById.isEmpty() )
        {
            upsert mastersToUpdateById.values();
        }

        if (partnersToUpdateList != null && !partnersToUpdateList.isEmpty() )
        {
            upsert partnersToUpdateList.values();
        }

        if (contactsToUpdate != null && !contactsToUpdate.isEmpty() )
        {
            //upsert contactsToUpdate.values() Contact.Fields.CustomerNum__c;
            upsert contactsToUpdate.values();
        }

        if (
            contactsToUpdateWithPartner != null &&
            !contactsToUpdateWithPartner.isEmpty()
            )
        {
            upsert contactsToUpdateWithPartner.values() Contact.Fields.CustomerNum__c;
        }

        if (contactPolicyDateUpdate != null && !contactPolicyDateUpdate.isEmpty() )
        {
            upsert contactPolicyDateUpdate.values();
        }

        if (quotesToUpdateList != null && !quotesToUpdateList.isEmpty() )
        {
            upsert quotesToUpdateList.values() Order.Fields.QuoteEntry__c;
        }

        if (ordersToUpdateList != null && !ordersToUpdateList.isEmpty() )
        {
            //Actualizar por id, para evitar error
            //upsert ordersToUpdateList.values() Order.Fields.PolicyNum__c;
            upsert ordersToUpdateList.values();
        }

        if (policiesToUpdateList != null && !policiesToUpdateList.isEmpty() )
        {
            upsert policiesToUpdateList.values() Order.Fields.PolicyNum__c;
        }

        if (
            ordersToUpdateWithPartner != null && !ordersToUpdateWithPartner.isEmpty()
            )
        {
            upsert ordersToUpdateWithPartner.values() Order.Fields.QuoteEntry__c;
        }

        if (
            policiesToUpdateWithPartner != null &&
            !policiesToUpdateWithPartner.isEmpty()
            )
        {
            upsert policiesToUpdateWithPartner.values() Order.Fields.PolicyNum__c;
        }

        if (
            policyVersionsToUpdateList != null &&
            !policyVersionsToUpdateList.isEmpty()
            )
        {
            upsert policyVersionsToUpdateList.values();
        }

        if (productsToInsert != null && !productsToInsert.isEmpty() )
        {
            upsert productsToInsert.values() Product2.Fields.ProductID__c;
            upsert pricebookEntryToInsert.values() PricebookEntry.Fields.ProductID__c;
        }
        if (orderItemsToInsert != null && !orderItemsToInsert.isEmpty() )
        {
            upsert orderItemsToInsert.values() OrderItem.Fields.ItemId__c;
        }
        if (discountsToInsert != null && !discountsToInsert.isEmpty() )
        {
            upsert discountsToInsert.values() Discount__c.Fields.DiscountId__c;
        }

        //Delete discounts from quotes that have converted because id changes
        if (discountsToDelete != null && !discountsToDelete.isEmpty() )
        {
            delete discountsToDelete.values();
        }

        //insert covers and then subcovers related to covers
        if (updateCover != null && !updateCover.isEmpty() )
        {
            upsert updateCover.values() Cover__c.Fields.CoverId__c;
            for (Cover__c cover : updateCover.values() )
            {
                mapInsertedCovers.put(cover.CoverId__c, cover);
            }
        }

        if (subCoversToInsertQuote != null && !subCoversToInsertQuote.isEmpty() )
        {
            List<Cover__c> relatedSubCover = new List<Cover__c>();
            for (Cover__c subcover : subCoversToInsertQuote.values() )
            {
                Cover__c insertedCover = mapInsertedCovers.get(
                    subcover.ParentCoverId__c
                    );
                if (insertedCover != null)
                {
                    subcover.ParentCover__c = insertedCover.id;
                    relatedSubCover.add(subcover);
                }
            }
            if (relatedSubCover != null && !relatedSubCover.isEmpty() )
            {
                upsert relatedSubCover;
            }
        }

        if (claimsToUpsert != null && !claimsToUpsert.isEmpty() )
        {
            upsert claimsToUpsert.values() Case.Fields.ClaimNumber__c;
        }
    }
}