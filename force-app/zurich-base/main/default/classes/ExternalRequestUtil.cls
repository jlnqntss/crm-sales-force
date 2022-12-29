/**
 ** Utility class for ExternalRequest__c object
 * @author nbizkarra
 * @date 01/04/2020
 *
 * @update Enara Etxaniz
 * @date 25/08/2020
 * Fix identation
 * Add Customer EMEA logic
 * 
 * @update 26/oct/2020 - nts (agonzalezisasi) - Add Customer Multi-Partner logic
 * 
 **/
global without sharing class ExternalRequestUtil {
  // Declare variables

  // nts (agonzalezisasi) - 26/oct/2020 - Include Multi-Partner
  // get this values from adminSetup in the metadata
  public static String IBA_EMEA_NON_COUNTRY;  // Used in this class and Batch_ResponseExternalRequest.cls
  private static String IBA_MULTI_PARTNER_ORIGIN;  // Used in this class and Batch_ResponseExternalRequest.cls
  private static String WS_SOURCE_IBA;
  // nts (agonzalezisasi) - 24/nov/2020 - Separate Spain and EMEA parser
  private static String WS_SOURCE_IBA_EMEA;
  private static String WS_SOURCE_IBA_MULTI_PARTNER;
  private static String WS_SERVICE_NAME_PROCESS_REQUEST;
  private static String WS_SERVICE_NAME_QUOTE_ENTRY;
  @testvisible private static Map<String, String> mapMultiPartner;
  public static String IBA_EMEA;

  private static final String ACCOUNT_FIELD_IBA = 'CustomerNum__c';
  private static final String ACCOUNT_FIELD_IBA_EMEA = 'CustomerNum_EMEA__c';
  private static final String ACCOUNT_FIELD_IBA_MULTI_PARTNER = 'CustomerNum_Partner__c';

  private static String IBA_Prefix;
  private static String IBA_Source;
  public static Boolean isIBAMultiPartner; 
  public static Boolean isEMEA;
  public static String AccountFieldCustomerNum;
  public static Map<String, Account> AccountMastersToUpdate;

  // Parsing
  public static ExternalRequest__c actualRequest;

  public static Map<String, Object> recordsToProcess;

  public static Set<String> contactsToSearch;
  // nts (nbizkarra) - 17/11/2020 - Include search among subscribers
  public static Set<String> contactEmails;
  // nts (nbizkarra) - 19/11/2020 - Include search quote with same product
  public static Set<String> contactSameProd;
  public static Set<String> sameProd;
  public static Set<String> mobilePhones;

  public static Set<String> quotesToSearch;
  public static Set<String> policiesToSearch;
  public static Set<String> orderItemsToSearch;
  public static Set<String> productsToSearch;
  public static Set<String> partnersToSearch;
  public static Set<String> coversToSearch;
  public static Set<String> claimsToSearch;

  public static Map<String, Order> quotesToProcess;
  public static Map<String, List<OrderItem>> orderItemsToProcess;
  public static Map<String, List<Discount__c>> discountsToProcess;
  public static Map<String, List<Cover__c>> coversToProcess;

  // Querying
  public static Map<String, Contact> mapContacts;
  public static Map<String, Contact> mapContactsEmailBirthDateLECountry;
  public static Map<String, Contact> mapContactsEmailBirthDateLE;
  public static Map<String, Contact> mapContactsEmailBirthDate;

  public static Map<String, List<Contact>> mapSubscribers;
  public static Map<String, List<Order>> mapQuoteSameProd;
 
  public static Map<String, Account> mapPartners;

  public static Map<String, Order> mapQuotes;
  public static Map<String, Order> mapPolicies;
  

  public static Map<String, OrderItem> mapOrderItem;

  public static Map<String, Case> mapClaims;
  public static Map<String, Contact> contactPolicyDateUpdate;

  public static Map<String, PricebookEntry> mapProducts;
  public static Map<String, Cover__c> mapCovers;
  public static Pricebook2 pricebook;
  public static AdminSetup__mdt adminSetup;
  public static User recordOwner;

  // Process
  public static Map<String, Account> mastersToUpdate;
  public static Map<String, Account> mastersToUpdateEMEA;
  public static Map<String, Account> mastersToUpdateMultiPartner;
  public static Map<String, Account> mastersToUpdateById;
  public static Map<String, Contact> contactsToUpdate;
  public static Map<String, Order> quotesToUpdateList;
  public static Map<String, Order> ordersToUpdateList;
  public static Map<String, Order> policiesToUpdateList;
  public static Map<String, Contact> contactsToUpdateWithPartner;
  public static Map<String, Order> ordersToUpdateWithPartner;
  public static Map<String, Order> policiesToUpdateWithPartner;
  public static Map<String, Discount__c> discountsToInsert;
  public static Map<String, Discount__c> discountsToDelete;
  public static List<Discount__c> listDiscounts;
  public static Map<String, Product2> productsToInsert;
  public static Map<String, PricebookEntry> pricebookEntryToInsert;
  public static List<OrderItem> listOrderItems;
  public static Map<String, OrderItem> orderItemsToInsert;
  public static Map<String, Cover__c> subCoversToInsertQuote;

  public static Map<String, Case> claimsToUpsert;
  public static Map<String, Cover__c> updateCover;

  public static List<Cover__c> insertCover;
  public static Map<String, Cover__c> mapInsertedCovers;
  public static List<Cover__c> listCovers;
  public static Map<String, Account> partnersToUpdateList;
  public static Map<String, PolicyVersion__c> policyVersionsToUpdateList;

  public static Map<String, Task> tasksToUpdate;

  //---------------------------------------------------------------------------
  // Main method
  public static void processExternalRequests(
    List<ExternalRequest__c> externalRequestList
  )
  {
    if (externalRequestList != null && !externalRequestList.isEmpty()) {
      emptyStaticVariables();
      //-------------------
      parseExternalRequests(externalRequestList);
      //-------------------
      getDataForProcessing();
      processObjects(externalRequestList);
      upsertData();
    }
  }

  //---------------------------------------------------------------------------
  // Empty static variables
  public static void emptyStaticVariables()
  {
    actualRequest = new ExternalRequest__c();

    recordsToProcess = new Map<String, Object>();

    contactsToSearch = new Set<String>();
    // nts (nbizkarra) - 17/11/2020 - Include search among subscribers
    contactEmails = new Set<String>();
    // nts (nbizkarra) - 19/11/2020 - Include search quote with same product 
    contactSameProd = new Set<String>();
    sameProd = new Set<String>();

    mobilePhones = new Set<String>();

    quotesToSearch = new Set<String>();
    policiesToSearch = new Set<String>();
    orderItemsToSearch = new Set<String>();
    productsToSearch = new Set<String>();
    partnersToSearch = new Set<String>();
    coversToSearch = new Set<String>();
    claimsToSearch = new Set<String>();

    quotesToProcess = new Map<String, Order>();
    orderItemsToProcess = new Map<String, List<OrderItem>>();
    discountsToProcess = new Map<String, List<Discount__c>>();
    coversToProcess = new Map<String, List<Cover__c>>();

    // Querying
    mapContacts = new Map<String, Contact>();
    mapContactsEmailBirthDateLECountry = new Map<String, Contact>();
    mapContactsEmailBirthDateLE = new Map<String, Contact>();
    mapContactsEmailBirthDate = new Map<String, Contact>();
    mapSubscribers = new Map<String, List<Contact>>();
    mapQuoteSameProd = new Map<String, List<Order>>();

    mapPartners = new Map<String, Account>();

    mapQuotes = new Map<String, Order>();
    mapPolicies = new Map<String, Order>();
    mapOrderItem = new Map<String, OrderItem>();

    mapClaims = new Map<String, Case>();
    contactPolicyDateUpdate = new Map<String, Contact>();

    mapProducts = new Map<String, PricebookEntry>();
    mapCovers = new Map<String, Cover__c>();
    if( pricebook == null ) pricebook = SystemUtil.getStandardPricebook();
    if( recordOwner == null ) recordOwner = SystemUtil.recordOwnerSelector();
    // Get setup data the first time
    if( adminSetup == null ) adminSetup = SystemUtil.getAdminSetupMetadata();
    if( adminSetup != null ) {
        if( IBA_EMEA_NON_COUNTRY == null ) IBA_EMEA_NON_COUNTRY = adminSetup.IBA_EMEA_Non_Country__c;
        if( IBA_MULTI_PARTNER_ORIGIN == null ) IBA_MULTI_PARTNER_ORIGIN = adminSetup.IBA_Multi_Partner_Origin__c;
        if( WS_SOURCE_IBA == null ) WS_SOURCE_IBA = adminSetup.WS_Source_IBA__c;
        // nts (agonzalezisasi) - 24/nov/2020 - Separate Spain and EMEA parser
        if( WS_SOURCE_IBA_EMEA == NULL ) WS_SOURCE_IBA_EMEA = adminSetup.WS_Source_IBA_EMEA__c;
        if( WS_SOURCE_IBA_MULTI_PARTNER == null ) WS_SOURCE_IBA_MULTI_PARTNER = adminSetup.WS_Source_IBA_Multi_Partner__c;
        if( WS_SERVICE_NAME_PROCESS_REQUEST == null ) WS_SERVICE_NAME_PROCESS_REQUEST = adminSetup.WS_Service_Process_Request__c;
        if( WS_SERVICE_NAME_QUOTE_ENTRY == null ) WS_SERVICE_NAME_QUOTE_ENTRY = adminSetup.WS_Service_Quote_Entry__c;
        if( IBA_EMEA == null ) IBA_EMEA = adminSetup.IBA_EMEA_Prefix__c + '-';
        if( mapMultiPartner == null && !String.isBlank(adminSetup.Multi_Partners__c)  ) {
            mapMultiPartner = new Map<String, String>();
            for(String pair: adminSetup.Multi_Partners__c.split(';')) {
                List<String> values = pair.split(':');
                if( values.size() == 2 ) {
                    mapMultiPartner.put(values.get(0), values.get(1));
                }
            }
        }
    }

    // Process
    mastersToUpdate = new Map<String, Account>();
    mastersToUpdateEMEA = new Map<String, Account>();
    mastersToUpdateMultiPartner = new Map<String, Account>();
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

    tasksToUpdate = new Map<String, Task>();

    // By default is the original IBA (spain)
    AccountFieldCustomerNum = ACCOUNT_FIELD_IBA;
    AccountMastersToUpdate = mastersToUpdate;
    isIBAMultiPartner = false;
    isEMEA = false;
    IBA_Prefix = '';
    IBA_Source = WS_SOURCE_IBA;
  }

  //---------------------------------------------------------------------------
  // Parse External requests
  private static void parseExternalRequests(
    List<ExternalRequest__c> externalRequestList
  ) {
    
    

    // For each External Request
    for (ExternalRequest__c externalRequestItem : externalRequestList) {
        try {
            
            actualRequest = externalRequestItem;

            if (externalRequestItem.Entity__c != null) {
              // nts (agonzalezisasi) - 26/nov/2020 - for if the external request is caming from a fail
                externalRequestItem.processResult__c = null;

                // nts (agonzalezisasi) - 26/oct/2020 - Include Multi-Partner
                // IBA (Spain) => default value
                IBA_Prefix = '';
                IBA_Source = WS_SOURCE_IBA;
                isIBAMultiPartner = false;
                isEMEA = false;
                AccountFieldCustomerNum = ACCOUNT_FIELD_IBA;
                AccountMastersToUpdate = mastersToUpdate;
                if( actualRequest.Origin__c == IBA_MULTI_PARTNER_ORIGIN ) { // IBA Multi Partner => Origin = IBA Multi-Partner
                    isIBAMultiPartner = true;
                    IBA_Source = WS_SOURCE_IBA_MULTI_PARTNER;
                    AccountFieldCustomerNum = ACCOUNT_FIELD_IBA_MULTI_PARTNER;
                    AccountMastersToUpdate = mastersToUpdateMultiPartner;
                } else if( actualRequest.Country__c != IBA_EMEA_NON_COUNTRY ) { // IBA EMEA => Country <> Spain
                    isEMEA = true;
                    IBA_Source = WS_SOURCE_IBA_EMEA;
                    IBA_Prefix = IBA_EMEA;
                    AccountFieldCustomerNum = ACCOUNT_FIELD_IBA_EMEA;
                    AccountMastersToUpdate = mastersToUpdateEMEA;
                }

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
                    when else {
                      throw new IntegrationException( 
                        Label.ParseError + 'Unsupported entity type: ' + externalRequestItem.Entity__c
                      );
                    }
                }
            }
        } catch (Exception e) {
            externalRequestItem.processed__c = true;
            externalRequestItem.processedDate__c = Datetime.now();
            externalRequestItem.processResult__c = 'KO';
            externalRequestItem.error_Log__c = e.getMessage() + '\n' + e.getStackTraceString();
        }
    }
  }

  private static void parseQuoteEntry() {
    
    String quoteEntryText = '"quoteEntry":';
    String customerText = '"customer":';
    
    if (actualRequest != null && String.isNotBlank(actualRequest.json__c)) {
      String json = actualRequest.json__c;
      String first_text = quoteEntryText;
      String second_text = customerText;
      Integer first = 0;
      Integer second = 1;
      Integer posQuoteEntry = json.indexOf(quoteEntryText);
      Integer posConsumer = json.indexOf(customerText);
      if( posConsumer < posQuoteEntry ) {
          first = 1;
          first_text = customerText;
          second = 0;
          second_text = quoteEntryText;
      }
      // Quote entries contains both lead and quote data. Split in separated objects.
      List<String> splittedQuoteEntry = actualRequest.json__c.split(first_text);
      if (splittedQuoteEntry.size() == 2) {
        splittedQuoteEntry = splittedQuoteEntry[1].split(',' + second_text);
        if (splittedQuoteEntry.size() == 2) {
          // Reformat properly as indepedent objects
          String quoteJson = '[' + splittedQuoteEntry[first] + ']';
          String leadJson = '[' + splittedQuoteEntry[second].removeEnd('}]') + ']';

          // Parse quote
          parseOrder(quoteJson);

          // Parse customer
          parseCustomer(leadJson);
        }
      }
    }
  }

  /**
   * parseOrder
   */
  private static void parseOrder(String orderJson) {
    

    String entityType = actualRequest.entity__c;

    Map<String, String> errorMessages = new Map<String, String>();
    Map<String, sObject> recordsMap = new Map<String, sObject>();
    Map<String, List<SObject>> secLvlRecordsMap = new Map<String, List<SObject>>();
    Map<String, List<SObject>> thrLvlRecordsMap = new Map<String, List<SObject>>();
    

    // Reorder
    
    orderJson = reorderOrderJson(orderJson);
    

    // Parse
    
    Schema.SObjectType orderEntity = Schema.getGlobalDescribe().get('Order');
    WebServicesParser.WebParserResult parserResultQuote;
    if (entityType == 'Policy') {
      parserResultQuote = WebServicesParser.parseObject(
        orderEntity,
        orderJson,
        IBA_Source,
        WS_SERVICE_NAME_PROCESS_REQUEST
      );
    } else if (entityType == 'QuoteEntry') {
      parserResultQuote = WebServicesParser.parseObject(
        orderEntity,
        orderJson,
        IBA_Source,
        WS_SERVICE_NAME_QUOTE_ENTRY
      );
    }
    recordsMap = parserResultQuote.recordsMap;
    errorMessages = parserResultQuote.errorMessagesMap;
    secLvlRecordsMap = parserResultQuote.secLvlRecordsMap;
    thrLvlRecordsMap = parserResultQuote.thrLvlRecordsMap;
    


    if (Test.isRunningTest()) {
        
        Mock_Parser.isIBA_MultiPart = isIBAMultiPartner;
        Mock_Parser.isIBA_EMEA = isEMEA;
        if (entityType == 'Policy') {
            recordsMap = Mock_Parser.MockParser('Policy');
            secLvlRecordsMap = Mock_Parser.MockParserSecondLevel('Policy');
            thrLvlRecordsMap = Mock_Parser.MockParserThirdLevel('Policy');
        } else if (entityType == 'QuoteEntry') {
            recordsMap = Mock_Parser.MockParser('QuoteEntry');
            secLvlRecordsMap = Mock_Parser.MockParserSecondLevel('QuoteEntry');
            thrLvlRecordsMap = Mock_Parser.MockParserThirdLevel('QuoteEntry');
        }
        errorMessages.clear();
        
    }

    
    // Parsing errors?
    if (!errorMessages.isEmpty()) {
        throw new IntegrationException(Label.ParseError + ': ' + errorMessages);
    }

    // Quote or policy
    Order incomingOrder = (Order) recordsMap.values().get(0);
    

    // nts (agonzalezisasi) - 26/oct/2020 - Include Multi-Partner
    if( isIBAMultiPartner ) {IBA_Prefix = getMultiPartner(incomingOrder.Partner__c);}

    // FIELDS
    // Set source country, timestamp and after processing check
    incomingOrder.sourceCountry__c = actualRequest.country__c;
    // Processing Timestamp
    incomingOrder.processing_Timestamp__c = actualRequest.timestamp__c;
    // After Processing check
    incomingOrder.after_Processing_Check__c = true;
    // Partner (account)
    if (!String.isBlank(incomingOrder.masterPolicyNum__c)) {
      partnersToSearch.add(incomingOrder.masterPolicyNum__c);
    }

    String customerNumber = ContactUtil.adaptCustomerNum(incomingOrder.customerNum__c,incomingOrder.legalEntity__c);
    // Add prefix to quotes to avoid potential repetition of this identifier
    // nts (agonzalezisasi) - 26/oct/2020 - Include Multi-Partner
    if( !String.isBlank(IBA_Prefix) ) {// if (incomingOrder.sourceCountry__c != 'Spain') {
        if (entityType == 'Policy') {
            incomingOrder.policyNum__c = IBA_Prefix + incomingOrder.policyNum__c;
            if ( !String.isBlank(incomingOrder.QuoteEntry__c) ) { //incomingOrder.sourceCountry__c != 'Spain'
                incomingOrder.QuoteEntry__c = IBA_Prefix + incomingOrder.QuoteEntry__C;
              }
        } else {
            incomingOrder.QuoteEntry__c = IBA_Prefix + incomingOrder.QuoteEntry__c;
        }
        customerNumber = IBA_Prefix + customerNumber;
    }
    incomingOrder.customerNum__c = customerNumber;

    // If the order is a policy
    if ( entityType == 'Policy' && 
        !String.isBlank(incomingOrder.customerNum__c) && !String.isBlank(incomingOrder.legalEntity__c) 
    ) {
          // Add customer to search
          contactsToSearch.add(customerNumber);
          // nts (nbizkarra) - 19/11/2020 - Include search quote with same product
          contactSameProd.add(customerNumber);

          recordsToProcess.put(actualRequest.id, incomingOrder);
          policiesToSearch.add(incomingOrder.policyNum__c);
    } else if (entityType == 'QuoteEntry') {
          quotesToProcess.put(actualRequest.id, incomingOrder);
    }

    if (!String.isBlank(incomingOrder.quoteEntry__c)) {
      quotesToSearch.add(incomingOrder.quoteEntry__c);
    }

    //---------------------------------
    // Order Items
    List<OrderItem> orderItemList = (List<OrderItem>) secLvlRecordsMap.get( 'OrderItem' );
    if (orderItemList != null && !orderItemList.isEmpty()) {
      // Throw error if it is a General insurance quote and any itemId is empty
      // if (incomingOrder.LegalEntity__c.equals(Label.GeneralInsurance)) {
        for (OrderItem orderItem : orderItemList) {
          if (incomingOrder.LegalEntity__c.equals(Label.GeneralInsurance)) {
              // Throw error if it is a General insurance quote and any itemId is empty
              if (String.isBlank(orderItem.itemId__c)) {
                throw new IntegrationException( Label.ParseError + ': Missing objectID' );
              }
          }
          // nts (agonzalezisasi) - 27/nov/2020 - add prefix to all
          if( String.isNotBlank(orderItem.itemId__c) ) {
              // nts (agonzalezisasi) - 26/oct/2020 - Include Multi-Partner
              if( !String.isBlank(IBA_Prefix) ) { // if (orderItem.sourceCountry__c != 'Spain') {
                orderItem.itemId__c = IBA_Prefix + orderItem.itemId__c;
              }    
              orderItemsToSearch.add(orderItem.ItemId__c);
          }
          // Set source country and timestamp
          orderItem.sourceCountry__c = actualRequest.country__c;
          orderItem.Partner__c = incomingOrder.Partner__c;
          orderItem.processing_Timestamp__c = actualRequest.timestamp__c;

          // Add prefix to quotes coming from IBA EMEA to avoid potential repetition of this identifier
          // nts (agonzalezisasi) - 26/oct/2020 - Include Multi-Partner
          if( !String.isBlank(IBA_Prefix) ) { // if (orderItem.sourceCountry__c != 'Spain') {
            // orderItem.itemId__c = IBA_Prefix + orderItem.itemId__c;
            if (entityType == 'Policy') {
              orderItem.Order.PolicyNum__c = IBA_Prefix + orderItem.Order.PolicyNum__c;
            } else {
              orderItem.Order.QuoteEntry__c = IBA_Prefix + orderItem.Order.QuoteEntry__c;
            }
          }

          
          if (orderItem.itemModel__c != null) {   // GI insurance
              
            productsToSearch.add(orderItem.itemModel__c);
              // nts (nbizkarra) - 19/11/2020 - Include search quote with same product
              if(entityType == 'Policy'){
                  sameProd.add(orderItem.itemModel__c);
              }

          } else if (orderItem.TransportType__c == null) {    // Life insurance, category: insured person
              orderItem.category__c = Label.InsuredPerson;
              productsToSearch.add(orderItem.category__c);
              // nts (nbizkarra) - 19/11/2020 - Include search quote with same product
              if(entityType == 'Policy'){
                sameProd.add(Label.InsuredPerson);
              }

          }
          
        }
      // }
      orderItemsToProcess.put(actualRequest.Id, orderItemList);

      // nts (nbizkarra) - 05/01/2021 - fill insured device name in the order, used to help customer care team
      // Only for  GI
      if (incomingOrder.LegalEntity__c == Label.GeneralInsurance){

        String deviceName;
        
        if( incomingOrder.Bundle__c != null ){

          if( incomingOrder.Bundle__c.equals(Label.NoBundle)  ){
          
            if (orderItemList.get(0).itemModel__c != null)
            {
              deviceName = orderItemList.get(0).itemModel__c;
            }
            
          }else{ //If it is a bundle, fill it with bundle name
            
            deviceName = incomingOrder.Bundle__c;
            
          }

        }else{ //Multiproduct

          if (orderItemList.get(0).TransportType__c != null){

            deviceName = orderItemList.get(0).TransportType__c;
          }

        }
        
        //update Order device name field
        if ( entityType == 'Policy' ){

          if(recordsToProcess.containsKey(actualRequest.id)){

            Order policy =  (Order) recordsToProcess.get(actualRequest.id);
            policy.InsuredObjectName__c = deviceName;
            recordsToProcess.put(actualRequest.id, policy);

          }

        } else if (entityType == 'QuoteEntry') {

          if(quotesToProcess.containsKey(actualRequest.id))
            quotesToProcess.get(actualRequest.id).InsuredObjectName__c = deviceName;

        }
      }  
    }

    //---------------------------------
    // Covers
    List<Cover__c> coverList = (List<Cover__c>) thrLvlRecordsMap.get( 'Cover__c' );
    if (coverList != null && !coverList.isEmpty() ) {
      for (Cover__c coverItem : coverList) {
          coverItem.sourceCountry__c = actualRequest.country__c;
          coverItem.Partner__c = incomingOrder.Partner__c;

          // Add prefix to quotes coming from IBA EMEA to avoid potential repetition of this identifier
          // nts (agonzalezisasi) - 26/oct/2020 - Include Multi-Partner
          if( !String.isBlank(IBA_Prefix) ) { // if (coverItem.sourceCountry__c != 'Spain') {
            coverItem.coverId__c = IBA_Prefix + coverItem.coverId__c;
            // if (entityType == 'Policy') {
              coverItem.PolicyProduct__r.ItemId__c = IBA_Prefix + coverItem.PolicyProduct__r.ItemId__c;
            // }
          }
          coverItem.processing_Timestamp__c = actualRequest.timestamp__c;
          coversToSearch.add( coverItem.policyProduct__r.itemId__c + '-' + coverItem.name );
      }
      coversToProcess.put(actualRequest.Id, coverList);
    }

    //---------------------------------
    // Discounts
    List<Discount__c> discountList = (List<Discount__c>) secLvlRecordsMap.get( 'Discount__c' );
    if( discountList != null && !discountList.isEmpty() ) {
      for (Discount__c discountItem : discountList) {
          // Set source country and timestamp
          discountItem.sourceCountry__c = actualRequest.country__c;    
          discountItem.Partner__c = incomingOrder.Partner__c;      
          // nts (agonzalezisasi) - 26/oct/2020 - Include Multi-Partner
          if( !String.isBlank(IBA_Prefix) ) { // if (discountItem.sourceCountry__c != 'Spain') {
              discountItem.DiscountId__c = IBA_Prefix + discountItem.DiscountIdNumber__c;
              if (entityType == 'Policy') {
                discountItem.Policy__r.PolicyNum__c = IBA_Prefix + discountItem.Policy__r.PolicyNum__c;
              } else {
                discountItem.Policy__r.QuoteEntry__c = IBA_Prefix + discountItem.Policy__r.QuoteEntry__c;
              }
          } else {
              discountItem.DiscountId__c = String.valueOf( discountItem.DiscountIdNumber__c );
          }
          discountItem.processing_Timestamp__c = actualRequest.timestamp__c;
        }
        discountsToProcess.put(actualRequest.Id, discountList);
    }
  }

  /**
   * parseCustomer
   */
  private static void parseCustomer(String customerJson) {

    Map<String, String> errorMessages = new Map<String, String>();
    Map<String, sObject> recordsMap = new Map<String, sObject>();
    
    Schema.SObjectType contactEntity = Schema.getGlobalDescribe().get('Contact');
    WebServicesParser.WebParserResult parserResultCustomer = WebServicesParser.parseObject(
      contactEntity,
      customerJson,
      IBA_Source,
      WS_SERVICE_NAME_PROCESS_REQUEST
    );
    recordsMap = parserResultCustomer.recordsMap;
    errorMessages = parserResultCustomer.errorMessagesMap;
    
    if (Test.isRunningTest()) {
        Mock_Parser.isIBA_MultiPart = isIBAMultiPartner;
        Mock_Parser.isIBA_EMEA = isEMEA;
        recordsMap = Mock_Parser.MockParser('Customer');
        errorMessages.clear();
    }

    // Parsing errors?
    
    if (!errorMessages.isEmpty()) {
      throw new IntegrationException(Label.ParseError + ': ' + errorMessages);
    }

    Contact contact = (Contact) recordsMap.values().get(0);
    // nts (agonzalezisasi) - 26/oct/2020 - Include Multi-Partner
    if( isIBAMultiPartner ) {IBA_Prefix = getMultiPartner(contact.Partner__c);}

    // FIELDS ---------------------
    // Country
    contact.sourceCountry__c = actualRequest.country__c;

    // Customer Num
    contact.customerNum__c = ContactUtil.adaptCustomerNum( contact.customerNum__c, contact.legalEntity__c );
    // Add prefix to quotes to avoid potential repetition of this identifier
    // nts (agonzalezisasi) - 26/oct/2020 - Include Multi-Partner
    if( !String.isBlank(IBA_Prefix) ) { // if (contact.sourceCountry__c != 'Spain') {
      contact.customerNum__c = IBA_Prefix + contact.customerNum__c;
    }

    // If the contact has declined to receive marketing communications, set HasOptedOutOfEmail to true
    if (contact.receiveMarketing__c == false) {
      contact.HasOptedOutOfEmail = true;
    }
    // The Lastname field is required, it is set to 'unknown' if it comes empty in the request 
    if(String.isBlank(contact.LastName))
    {
        contact.LastName = Label.LeadLastName;
    }

    // The Firsname field is set to 'unknown' if it comes empty in the request 
    if(String.isBlank(contact.FirstName))
    {
        contact.FirstName = Label.LeadLastName;
    }

    // SEARCH Contacts
    contactsToSearch.add(contact.customerNum__c);
    if( String.isNotBlank(contact.email) ) {
      contactEmails.add(contact.email);
    }
    if( String.isNotBlank(contact.MobilePhone) ) {
      mobilePhones.add(contact.MobilePhone);
    }

    // SEARCH Partners (account)
    if (!String.isBlank(contact.masterPolicyNum__c)) {
      partnersToSearch.add(contact.masterPolicyNum__c);
    }

    recordsToProcess.put(actualRequest.id, contact);
  }

  /**
   * parseCustomer
   */
  private static void parseCustomer() {
    if (null != actualRequest.json__c)
      parseCustomer(actualRequest.json__c);
  }

  /**
   * parsePolicy
   */
  private static void parsePolicy() {
    if (null != actualRequest.json__c)
      parseOrder(actualRequest.json__c);
  }

  /**
   * parseClaim
   */
  private static void parseClaim() {
    

    Map<String, String> errorMessages = new Map<String, String>();
    Map<String, sObject> recordsMap = new Map<String, sObject>();

    Schema.SObjectType claimEntity = Schema.getGlobalDescribe().get('Case');
    WebServicesParser.WebParserResult parserResult = WebServicesParser.parseObject(
      claimEntity,
      actualRequest.Json__c,
      IBA_Source,
      WS_SERVICE_NAME_PROCESS_REQUEST
    );
    recordsMap = parserResult.recordsMap;
    errorMessages = parserResult.errorMessagesMap;
  
    if (Test.isRunningTest()) {
      Mock_Parser.isIBA_MultiPart = isIBAMultiPartner;
      Mock_Parser.isIBA_EMEA = isEMEA;
      recordsMap = Mock_Parser.MockParser(actualRequest.Entity__c);
      errorMessages.clear();
    }

    // Parsing errors?
    if (!errorMessages.isEmpty()) {
      throw new IntegrationException(Label.ParseError + ': ' + errorMessages);
    }

    if (recordsMap != null) {
      Case claim = (Case) recordsMap.values().get(0);
      

      // nts (agonzalezisasi) - 26/oct/2020 - Include Multi-Partner
      if( isIBAMultiPartner ) {IBA_Prefix = getMultiPartner(claim.Partner__c);}

      // FIELDS
      // Source Country
      claim.sourceCountry__c = actualRequest.country__c;
      // Claim Number      
      // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
      if( !String.isBlank(IBA_Prefix) ) { // if (claim.sourceCountry__c != 'Spain') {
        claim.claimNumber__c = IBA_Prefix + claim.claimNumber__c;
      }

      recordsToProcess.put(actualRequest.id, claim);

      // Search Claims
      claimsToSearch.add(claim.claimNumber__c);

      // Policy
      // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
      if (!String.isBlank(claim.PolicyNum__c)) {
        if( !String.isBlank(IBA_Prefix) ) { // if (claim.sourceCountry__c != 'Spain') {
          claim.PolicyNum__c = IBA_Prefix + claim.PolicyNum__c;
        }
        // Search Policies
        policiesToSearch.add(claim.PolicyNum__c);
      }

      // Customer
      if (!String.isBlank(claim.customerNum__c)) {
        // Search customer of both legal entity because claim doesn't specify Legal Entity
        // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
        String customerNumGI = ContactUtil.adaptCustomerNum( claim.customerNum__c, Label.GeneralInsurance );
        String customerNumLife = ContactUtil.adaptCustomerNum( claim.customerNum__c, Label.LifeInsurance );
        if( !String.isBlank(IBA_Prefix) ) { // if (claim.sourceCountry__c != 'Spain') {
          customerNumGI = IBA_Prefix + customerNumGI;
          customerNumLife = IBA_Prefix + customerNumLife;  
        }
        contactsToSearch.add( customerNumGI );
        contactsToSearch.add( customerNumLife );
      }

      // Insured object
      if (!String.isBlank(claim.insuredObjectId__c)) {
        // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
        if( !String.isBlank(IBA_Prefix) ) { // if (claim.sourceCountry__c != 'Spain') {
          claim.insuredObjectId__c = IBA_Prefix + claim.insuredObjectId__c;
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
  public static String reorderOrderJson(String receivedJson) {
    String itemsString = '';
    String discountsSerialized = '';

    List<Object> objectList = (List<Object>) JSON.deserializeUntyped(
      receivedJson
    );
    Map<String, Object> objectMap = (Map<String, Object>) objectList[0];

    // Discounts
    Object discountsItem = objectMap.remove('discounts');
    if( discountsItem != null )
        discountsSerialized = JSON.serialize(discountsItem);

    // Items
    Object items = objectMap.remove('items');
    if( items != null ) {
      String itemSerialized = JSON.serialize(items);
      List<Object> itemsList = (List<Object>) JSON.deserializeUntyped(
        itemSerialized
      );

      
      for (Object objectItem : itemsList) {
        Map<String, Object> mapItems = (Map<String, Object>) objectItem;
        String covers = JSON.serialize(mapItems.remove('covers'));

        // Item without covers
        String item = JSON.serialize(mapItems);
        item = item.removeEnd('}');

        // Add covers in the end
        item = item + ',"covers":' + covers;
        itemsString = itemsString + item + '},';
      }
      itemsString = itemsString.removeEnd(',');
      itemsString = '[' + itemsString + ']';
    }

    // Add discount and items to order
    String order = JSON.serialize(objectMap);
    order = order.removeEnd('}');
    order = order + ',"discounts":' + discountsSerialized;
    order = '[' + order + ',"items":' + itemsString + '}]';

    return order;
  }

  //---------------------------------------------------------------------------
  // Query data needed for processing
  private static void getDataForProcessing() {
    

    mapContacts = SystemUtil.contactsSelector( contactsToSearch );
    SystemUtil.contactsSelectorMatchCode(
      contactEmails, 
      mobilePhones,
      mapContactsEmailBirthDateLECountry, mapContactsEmailBirthDateLE, mapContactsEmailBirthDate,
      mapSubscribers
    );

    // nts (nbizkarra) - 17/11/2020 - Include search among subscribers

    // nts (nbizkarra) -  19/11/2020 - Include search quote with same product
    mapQuoteSameProd = SystemUtil.getQuoteSameProduct(contactSameProd, sameProd);

    mapPartners = SystemUtil.partnerSelector( partnersToSearch );
    mapPolicies = SystemUtil.policySelector( policiesToSearch );
    mapQuotes = SystemUtil.quoteSelector( quotesToSearch );
    mapClaims = SystemUtil.claimsSelector( claimsToSearch );
    mapOrderItem = SystemUtil.orderItemSelector( orderItemsToSearch );
    mapProducts = SystemUtil.productsSelector( productsToSearch );
    mapCovers = SystemUtil.coversSelector( coversToSearch );
  }

  //-------------------------------------------------------------:--------------
  // Process
  private static void processObjects( List<ExternalRequest__c> externalRequestList ) 
  {
    
    
    for (ExternalRequest__c externalRequestItem : externalRequestList) {
      // nts (agonzalezisasi) - 24/11/2020 - check if it didnt already fail in the parser
      if( externalRequestItem.processResult__c == null || externalRequestItem.processResult__c != 'KO' ) {
        try {
          actualRequest = externalRequestItem;
          if (externalRequestItem.entity__c != null) {
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
              when else 
              {
                  // else code
              }
            }
            externalRequestItem.processed__c = true;
            externalRequestItem.processedDate__c = Datetime.now();
            externalRequestItem.processResult__c = 'OK';
            externalRequestItem.error_Log__c = ' ';
          }
        } catch (Exception e) {
          externalRequestItem.processed__c = true;
          externalRequestItem.processedDate__c = Datetime.now();
          externalRequestItem.processResult__c = 'KO';
          externalRequestItem.error_Log__c = e.getMessage() + '\n' + e.getStackTraceString();
        }
      }
    }
  }

  private static void processCustomer() {
    
    // Get the customer
    if (recordsToProcess.containsKey(actualRequest.id)) {
      
      Contact incomingContact = (Contact) recordsToProcess.get( actualRequest.id );

      ContactUtil.upsertContact(incomingContact, null);
    }
  }

  private static void processQuoteEntry() {
    
    // Get the policy
    if ( recordsToProcess.containsKey(actualRequest.id) && quotesToProcess.containsKey(actualRequest.id) ) {
      listOrderItems = orderItemsToProcess.get(actualRequest.id);
      listDiscounts = discountsToProcess.get(actualRequest.id);
      listCovers = coversToProcess.get(actualRequest.id);

      Contact contact = (Contact) recordsToProcess.get(actualRequest.id);
      Order quote = (Order) quotesToProcess.get(actualRequest.id);

      OrderUtil.upsertQuote(contact, quote);
    }
  }

  private static void processPolicy() {
    
    // Get the policy
    if (recordsToProcess.containsKey(actualRequest.id)) {

      listOrderItems = orderItemsToProcess.get(actualRequest.id);
      listDiscounts = discountsToProcess.get(actualRequest.id);
      listCovers = coversToProcess.get(actualRequest.id);

      Order policy = (Order) recordsToProcess.get(actualRequest.id);

      OrderUtil.upsertPolicy(policy);
      //if quote has been processed first, remove it
      if (!String.isBlank(policy.QuoteEntry__c)) {
        quotesToUpdateList.remove(policy.QuoteEntry__c);
      }
    }
  }

  private static void processClaim() {
    
    // Get the claim
    if (recordsToProcess.containsKey(actualRequest.id)) {
      Case claim = (Case) recordsToProcess.get(actualRequest.id);
      CaseUtil.upsertClaim(claim);
    }
  }

  //---------------------------------------------------------------------------
  // Upsert objects
  private static void upsertData() {
    if (mastersToUpdate != null && !mastersToUpdate.isEmpty()) {
      upsert mastersToUpdate.values() Account.Fields.CustomerNum__c;
    }

    if (mastersToUpdateEMEA != null && !mastersToUpdateEMEA.isEmpty()) {
      upsert mastersToUpdateEMEA.values() Account.Fields.CustomerNum_EMEA__c;
    }

    if (mastersToUpdateMultiPartner != null && !mastersToUpdateMultiPartner.isEmpty()) {
      upsert mastersToUpdateMultiPartner.values() Account.Fields.CustomerNum_Partner__c;
    }

    if (mastersToUpdateById != null && !mastersToUpdateById.isEmpty()) {
      upsert mastersToUpdateById.values();
    }

    if (partnersToUpdateList != null && !partnersToUpdateList.isEmpty()) {
      upsert partnersToUpdateList.values();
    }

    if (contactsToUpdate != null && !contactsToUpdate.isEmpty()) {
      //upsert contactsToUpdate.values() Contact.Fields.CustomerNum__c;
      
      for(Contact c: contactsToUpdate.values() ) {
        
      }
      upsert contactsToUpdate.values();
    }

    if ( contactsToUpdateWithPartner != null && !contactsToUpdateWithPartner.isEmpty() ) {
      upsert contactsToUpdateWithPartner.values() Contact.Fields.CustomerNum__c;
    }

    if (contactPolicyDateUpdate != null && !contactPolicyDateUpdate.isEmpty()) {
      upsert contactPolicyDateUpdate.values();
    }

    if (quotesToUpdateList != null && !quotesToUpdateList.isEmpty()) {
      upsert quotesToUpdateList.values() Order.Fields.QuoteEntry__c;
    }

    if (ordersToUpdateList != null && !ordersToUpdateList.isEmpty()) {
      //Actualizar por id, para evitar error
      
      for( Order o : ordersToUpdateList.values() ) {
        
      }
      upsert ordersToUpdateList.values();
    }

    if (policiesToUpdateList != null && !policiesToUpdateList.isEmpty()) {
      upsert policiesToUpdateList.values() Order.Fields.PolicyNum__c;
    }

    if (
      ordersToUpdateWithPartner != null && !ordersToUpdateWithPartner.isEmpty()
    ) {
      upsert ordersToUpdateWithPartner.values() Order.Fields.QuoteEntry__c;
    }

    if ( policiesToUpdateWithPartner != null && !policiesToUpdateWithPartner.isEmpty() ) {
      upsert policiesToUpdateWithPartner.values() Order.Fields.PolicyNum__c;
    }

    if ( policyVersionsToUpdateList != null && !policyVersionsToUpdateList.isEmpty() ) {
      upsert policyVersionsToUpdateList.values();
    }

    if (productsToInsert != null && !productsToInsert.isEmpty()) {
      upsert productsToInsert.values() Product2.Fields.ProductID__c;
      upsert pricebookEntryToInsert.values() PricebookEntry.Fields.ProductID__c;
    }
    if (orderItemsToInsert != null && !orderItemsToInsert.isEmpty()) {
      
      for(OrderItem oi: orderItemsToInsert.values() ) {
        
        // if( oi.Order != null ) {
        //  
        // }
      }
      upsert orderItemsToInsert.values() OrderItem.Fields.ItemId__c;
    }
    if (discountsToInsert != null && !discountsToInsert.isEmpty()) {
      
      for(Discount__c d: discountsToInsert.values()) {
          
      }
      upsert discountsToInsert.values() Discount__c.Fields.DiscountId__c;
    }

    //Delete discounts from quotes that have converted because id changes
    if (discountsToDelete != null && !discountsToDelete.isEmpty()) {
      delete discountsToDelete.values();
    }

    //insert covers and then subcovers related to covers
    if (updateCover != null && !updateCover.isEmpty()) {
      upsert updateCover.values() Cover__c.Fields.CoverId__c;
      for (Cover__c cover : updateCover.values()) {
        mapInsertedCovers.put(cover.CoverId__c, cover);
      }
    }

    if (subCoversToInsertQuote != null && !subCoversToInsertQuote.isEmpty()) {
      List<Cover__c> relatedSubCover = new List<Cover__c>();
      for (Cover__c subcover : subCoversToInsertQuote.values()) {
        Cover__c insertedCover = mapInsertedCovers.get(
          subcover.ParentCoverId__c
        );
        if (insertedCover != null) {
          subcover.ParentCover__c = insertedCover.id;
          relatedSubCover.add(subcover);
        }
      }
      if (relatedSubCover != null && !relatedSubCover.isEmpty()) {
        upsert relatedSubCover;
      }
    }

    if (claimsToUpsert != null && !claimsToUpsert.isEmpty()) {
      upsert claimsToUpsert.values() Case.Fields.ClaimNumber__c;
    }
    // nts (nbizkarra) - 07/ene/2021 - Modelo de atribución
    if (tasksToUpdate != null && !tasksToUpdate.isEmpty()) {

      //relacionar tarea con id de SF de la póliza
      for( String key: tasksToUpdate.keySet() ){

        if(ordersToUpdateList.containsKey(key)){

          tasksToUpdate.get(key).WhatId = ordersToUpdateList.get(key).id;

        }
      }
      upsert tasksToUpdate.values();
    }
  }

  //---------------------------------------------------------------------------
  /**
   * Get the short term to use for the partner in the customer number. From the
   * partner string that comes from the json
   * 
   * @author nts (agonzalezisasi)
   * @date 27/10/2020
   */
  private static String getMultiPartner(String partner) {
      String result = null;
      if( !String.isBlank(partner) && mapMultiPartner.containsKey(partner) ) {
          result = mapMultiPartner.get(partner) + '-';
      } else {
          throw new IntegrationException( 'Partner not registered in the configuration: ' + partner );
      }
      return result;
  }
}