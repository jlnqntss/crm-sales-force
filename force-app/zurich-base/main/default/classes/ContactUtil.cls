/**
 * @author nbizkarra
 * @date 01/04/2020
 **/
global with sharing class ContactUtil
{
    /**
     * Método que adapta el número de cliente para cada entidad legal
     * @param String número de cliente y entidad legal
     * @author nbizkarra
     * @return Número de cliente con el formato adaptado
     * @date 01/04/2020
     **/
    public static String adaptCustomerNum( String CustomerNum, String LegalEntity )
    {
        
        if ( LegalEntity.equals('GI') || LegalEntity.equals(Label.GeneralInsurance) )
        {
            CustomerNum = 'GI-' + CustomerNum;
        }
        else if ( LegalEntity.equals(Label.LifeInsurance) )
        {
            CustomerNum = 'LIFE-' + CustomerNum;
        }
        else
        {
            throw new IntegrationException(Label.LegalEntityError);
        }

        return CustomerNum;
    }

    /**
     * Método que crea el matchcode en base a la información recibida del contacto
     * @param Contacto recibido
     * @author nbizkarra
     * @return Matchcode generado
     * @date 10/03/2021
     **/
    public static String createMatchcode( Contact incomingContact )
    {
        String matchcode = '';

         //Si tiene email y fecha de nacimiento: MATCHCODE = email +  birthdate
         if ( !String.isBlank(incomingContact.Email) && null != incomingContact.Birthdate && !String.isBlank(incomingContact.sourceCountry__c)  )
         {
             matchcode = incomingContact.Email.toLowerCase() + String.valueOfGmt(incomingContact.Birthdate);            

         } // Si no tiene email y tiene fecha de nacimiento y teléfono : MATCHCODE = sourcecountry + mobilephone +  birthdate
         else if ( String.isBlank(incomingContact.Email) && !String.isBlank(incomingContact.MobilePhone)
                   && !String.isBlank(incomingContact.sourceCountry__c) && null != incomingContact.Birthdate )
         {
             matchcode = incomingContact.SourceCountry__c + incomingContact.MobilePhone + String.valueOfGmt(incomingContact.Birthdate);

         } // Sin fecha de nacimiento, con email y telefono: MATCHCODE = email + sourcecountry + mobilephone
         else if (  incomingContact.Birthdate == null && !String.isBlank(incomingContact.Email) 
                     && !String.isBlank(incomingContact.MobilePhone) && !String.isBlank(incomingContact.sourceCountry__c) )
         {
             matchcode = incomingContact.Email.toLowerCase() + incomingContact.SourceCountry__c + incomingContact.MobilePhone ;

         } // Sin fecha de nacimiento, sin telefono, con email:  MATCHCODE = email 
         else if (  incomingContact.Birthdate == null && !String.isBlank(incomingContact.Email) 
                     && String.isBlank(incomingContact.MobilePhone) && !String.isBlank(incomingContact.sourceCountry__c) )
         {
             matchcode = incomingContact.Email.toLowerCase() ;

         } // Sin fecha de nacimiento, con telefono, sin email:  MATCHCODE =  sourcecountry + mobilephone
         else if (  incomingContact.Birthdate == null && String.isBlank(incomingContact.Email) 
                     && !String.isBlank(incomingContact.MobilePhone) && !String.isBlank(incomingContact.sourceCountry__c) )
         {
             matchcode = incomingContact.SourceCountry__c + incomingContact.MobilePhone;

         }

        return matchcode;
    }


    // EMEA
    public static Order upsertContact(Contact incomingContact, Order quote)
    {
        
        String[] customerNumberParts = incomingContact.CustomerNum__c.split('-');
        String legalEntity = '';
        String customerNumberOnly = '';
        String customerNumField = ExternalRequestUtil.AccountFieldCustomerNum;

        // Get legal entity from the customer number.

        // If the customer number has 3 parts, this means that contains the prefix EMEA
        if (customerNumberParts.size() == 3)
        {
            // If it comes from EMEA the legal entity will be in the second place
            customerNumberOnly = customerNumberParts[2];
        }
        else if (customerNumberParts.size() == 2)
        {
            // If it comes from Spain the legal entity will be in the first place
            customerNumberOnly = customerNumberParts[1];
        }
        else
        {
            throw new IntegrationException( Label.ParseError + ': invalid customer number.' );
        }

        if ( incomingContact.LegalEntity__c.equals(Label.GeneralInsurance) )
        {
            legalEntity = 'GI';
        }
        else
        {
            legalEntity = 'Life';
        }

        // Assign record type
        incomingContact.RecordTypeId = incomingContact.Status__c != 'Lead'
                                       ? SystemUtil.getContactRecordTypeIdByName('Customer' + legalEntity)
                                       : SystemUtil.getContactRecordTypeIdByName('Lead' + legalEntity);

        // String customerNum = ((Contact) ExternalRequestUtil.recordsToProcess.get(
        //   ExternalRequestUtil.actualRequest.id )).CustomerNum__c;
        
        
        String customerNum = incomingContact.CustomerNum__c;

        Contact alreadyInSFContact = ExternalRequestUtil.mapContacts.get( customerNum );
        // The contact exist with the same customer number
        // BY CUSTOMER NUM -------------------------------------------------------------------------------------------------
        if ( alreadyInSFContact != null )
        {
            

            // If there is a quote, and the contact is a lead, the relationship between the
            // quote and the contact is set and the contact is updated
            if (quote != null && incomingContact.status__c == 'Lead')
            {
                // Update the contact
                incomingContact.Id = alreadyInSFContact.Id;
                ExternalRequestUtil.contactsToUpdate.put( incomingContact.CustomerNum__c, incomingContact );

                quote.ContactId__c = alreadyInSFContact.Id;
                quote.AccountId = alreadyInSFContact.AccountId;
            }
            else if (quote != null && incomingContact.status__c == 'Activo')
            {
                // If there is a quote, and the contact is not a lead, the relationship between the
                // quote and the contact is set but the contact is NOT updated
                quote.ContactId__c = alreadyInSFContact.Id;
                quote.AccountId = alreadyInSFContact.AccountId;
            }
            else
            {
                // If there is no quote, the contact is updated
                // Update the contact
                incomingContact.Id = alreadyInSFContact.Id;
                ExternalRequestUtil.contactsToUpdate.put( incomingContact.CustomerNum__c, incomingContact );
            }

            // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
            Account accountItem = new Account();
            accountItem.Name = incomingContact.FirstName + ' ' + incomingContact.LastName;
            accountItem.put(customerNumField,  customerNumberOnly);
            // Account.CustomerNum__c / CustomerNum_EMEA__c / CustomerNum_Partner__c
            if( alreadyInSFContact.Account.get(customerNumField) == customerNumberOnly )
            {
                ExternalRequestUtil.AccountMastersToUpdate.put( customerNumberOnly, accountItem );
            }
            else
            {
                accountItem.Id = alreadyInSFContact.AccountId;
                ExternalRequestUtil.mastersToUpdateById.put( customerNumberOnly, accountItem );
            }
        }
        else // BY MATCH CODE ------------------------------------------------------------------------------------------
        // Generate codes to match
        {
            String matchcode_LECountyPartner = '';
            String matchcode = '';

            matchcode = createMatchcode(  incomingContact );
            matchcode_LECountyPartner = matchcode + legalEntity + incomingContact.sourceCountry__c + incomingContact.Partner__c;
           
            
            
            
            

            // MATCHCODE - LEGALENTITY - COUNTRY + PARTNER : Contact found
            if ( ExternalRequestUtil.mapContactsEmailBirthDateLECountry.containsKey( matchcode_LECountyPartner ) )
            {
                // If contact exists with a different customer number
                
                alreadyInSFContact = ExternalRequestUtil.mapContactsEmailBirthDateLECountry.get( matchcode_LECountyPartner );

                if ( incomingContact.status__c == 'Lead' )
                {
                    // Update the contact only if it is also a lead in Salesforce
                    if( alreadyInSFContact.status__c == 'Lead' )
                    {
                        // Update the lead but keep the existing Customer Number
                        incomingContact.Id = alreadyInSFContact.Id;
                        // nts (nbizkarra) - 11/ene/2021 - avoid overwritting existing email in salesforce's contact when incoming is empty
                        if( String.isBlank(incomingContact.Email) && !String.isBlank(alreadyInSFContact.Email) )
                        {
                            incomingContact.Email = alreadyInSFContact.Email;
                        }
                        if( String.isBlank(incomingContact.MobilePhone) && !String.isBlank(alreadyInSFContact.MobilePhone) )
                        {
                            incomingContact.MobilePhone = alreadyInSFContact.MobilePhone;
                        }
                        if( incomingContact.Birthdate == null && alreadyInSFContact.Birthdate != null )
                        {
                            incomingContact.Birthdate = alreadyInSFContact.Birthdate;
                        }

                        incomingContact.CustomerNum__c = alreadyInSFContact.CustomerNum__c;
                        ExternalRequestUtil.contactsToUpdate.put( incomingContact.CustomerNum__c, incomingContact );
                    }

                    if( quote != null )
                    {
                    quote.AccountId = alreadyInSFContact.AccountId;
                    quote.ContactId__c = alreadyInSFContact.Id;
                    // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
                    // Account.CustomerNum__c / CustomerNum_EMEA__c / CustomerNum_Partner__c
                    quote.CustomerNum__c = (String) alreadyInSFContact.Account.get(customerNumField);
                    }
                   
                } // Sobreescribir información si es un cliente activo y en Salesforce es un lead
                else if( incomingContact.status__c == 'Activo' && alreadyInSFContact.status__c == 'Lead')
                {
                    incomingContact.AccountId = alreadyInSFContact.AccountId;

                    Account accountItem = new Account();
                    accountItem.Name = incomingContact.FirstName + ' ' + incomingContact.LastName;
                    // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
                    // Account.CustomerNum__c / CustomerNum_EMEA__c / CustomerNum_Partner__c
                    accountItem.put(customerNumField, customerNumberOnly);
                    // Populate the Id field only if the account has the same customer number
                    if ( alreadyInSFContact.Account.get(customerNumField) == customerNumberOnly )
                    {
                        ExternalRequestUtil.AccountMastersToUpdate.put( customerNumberOnly, accountItem );
                    }
                    else
                    {
                        accountItem.Id = alreadyInSFContact.AccountId;
                        ExternalRequestUtil.mastersToUpdateById.put( customerNumberOnly, accountItem );
                    }

                    // nts (nbizkarra) - 27/01/2021 - Fix: si el contacto que llega es "Activo" actualizar cuenta y contacto de SF
                    incomingContact.Id = alreadyInSFContact.Id;
                    ExternalRequestUtil.contactsToUpdate.put( incomingContact.CustomerNum__c, incomingContact );

                    if( quote != null )
                    {
                    quote.AccountId = alreadyInSFContact.AccountId;
                    quote.ContactId__c = alreadyInSFContact.Id;
                    // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
                    // Account.CustomerNum__c / CustomerNum_EMEA__c / CustomerNum_Partner__c
                    quote.CustomerNum__c = (String) alreadyInSFContact.Account.get(customerNumField);
                    }

                } // Crear nuevo contacto y cuenta si es un cliente activo y el registro encontrado en Salesforce también
                else if( incomingContact.status__c == 'Activo' && alreadyInSFContact.status__c == 'Activo' ){

                    createContactAndMaster(  incomingContact,  customerNumField,  customerNumberOnly,  quote );
                }


            }// ONLY MATCHCODE (DIFFERENT LEGAL ENTITY - COUNTRY OR PARTNER) : Associate contact to existing master
            else if ( ExternalRequestUtil.mapContactsEmailBirthDate.containsKey( matchcode ) )
            {
                
                
                alreadyInSFContact = ExternalRequestUtil.mapContactsEmailBirthDate.get( matchcode );

                incomingContact.AccountId = alreadyInSFContact.AccountId;

                Account accountItem = new Account();

                // The master account doesn't have the customer number
                // Account.Customer_Num__c / Customer_Num_EMEA__c / Customer_Num_Partner__c
                if( String.isBlank( (String) alreadyInSFContact.Account.get(customerNumField) ) )
                {
                    // The master account is updated
                    if (incomingContact.Status__c == 'Activo')
                    {
                        accountItem.Name = incomingContact.FirstName + ' ' + incomingContact.LastName;
                    }
                    // Account.Customer_Num__c / Customer_Num_EMEA__c / Customer_Num_Partner__c
                    accountItem.put(customerNumField, customerNumberOnly);
                    accountItem.Id = alreadyInSFContact.AccountId;
                    ExternalRequestUtil.mastersToUpdateById.put( (String) accountItem.get(customerNumField), accountItem );
                }
                else // The master account has an customer number
                // The contact is an active customer
                {
                    if (incomingContact.Status__c == 'Activo')
                    {
                        // The master account is updated
                        accountItem.Name = incomingContact.FirstName + ' ' + incomingContact.LastName;
                        // Account.Customer_Num__c / Customer_Num_EMEA__c / Customer_Num_Partner__c
                        accountItem.put(customerNumField, customerNumberOnly);
                        // Populate the Id field only if the account has the same customer number
                        if ( alreadyInSFContact.Account.get(customerNumField) == customerNumberOnly )
                        {
                            ExternalRequestUtil.AccountMastersToUpdate.put( (String) accountItem.get(customerNumField), accountItem );
                        }
                        else
                        {
                            accountItem.Id = alreadyInSFContact.AccountId;
                            ExternalRequestUtil.mastersToUpdateById.put( (String) accountItem.get(customerNumField), accountItem );
                        }
                    }
                }

                if ( !String.isBlank(incomingContact.MasterPolicyNum__c) )
                {
                    //Asociar partner cuando el cliente es nuevo
                    AccountUtil.associatePartner(
                        incomingContact,
                        ExternalRequestUtil.mapPartners,
                        ExternalRequestUtil.contactsToUpdateWithPartner,
                        ExternalRequestUtil.partnersToUpdateList,
                        ExternalRequestUtil.recordOwner
                        );
                }

                incomingContact.OwnerId = ExternalRequestUtil.recordOwner.id;
                ExternalRequestUtil.contactsToUpdate.put( incomingContact.CustomerNum__c, incomingContact );

                if (quote != null)
                {
                    quote.CustomerNum__c = customerNumberOnly;
                    quote.AccountId = alreadyInSFContact.AccountId;
                    quote.ContactId__r = new Contact( CustomerNum__c = incomingContact.CustomerNum__c );
                }
            } // SEARCH AMONG SUBSCRIBERS // nts (nbizkarra) - 17/11/2020
            else if ( ExternalRequestUtil.mapSubscribers.containsKey(incomingContact.Email) )
            {
                
                List <Contact> listSubscribers = ExternalRequestUtil.mapSubscribers.get(incomingContact.Email);
                Boolean subscriber_found = false;

                // Loop through all the subscribers with same email to find contact with same LE, Country and Partner
                for(Contact subscriber: listSubscribers)
                {

                    if( incomingContact.LegalEntity__c == subscriber.LegalEntity__c &&
                        incomingContact.SourceCountry__c == subscriber.SourceCountry__c &&
                        incomingContact.Partner__c == subscriber.Partner__c
                        )
                    {

                        
                        alreadyInSFContact = subscriber;
                        incomingContact.Id = alreadyInSFContact.Id;
                        ExternalRequestUtil.contactsToUpdate.put( incomingContact.CustomerNum__c, incomingContact );
                        subscriber_found = true;
                    }
                }

                //If no subscriber with same LE, Country and Partner, associate the incoming contact with the existing master
                if(subscriber_found == false)
                {

                    

                    alreadyInSFContact = listSubscribers.get(0);
                    incomingContact.AccountId = alreadyInSFContact.AccountId;
                    incomingContact.OwnerId = ExternalRequestUtil.recordOwner.id;
                    ExternalRequestUtil.contactsToUpdate.put( incomingContact.CustomerNum__c, incomingContact );

                }

                Account accountItem = new Account();
                accountItem.Name = incomingContact.FirstName + ' ' + incomingContact.LastName;
                // The master account doesn't have the customer number
                // Account.Customer_Num__c / Customer_Num_EMEA__c / Customer_Num_Partner__c
                if( String.isBlank( (String) alreadyInSFContact.Account.get(customerNumField) ) )
                {
                    // The master account is updated
                    // Account.Customer_Num__c / Customer_Num_EMEA__c / Customer_Num_Partner__c
                    accountItem.put(customerNumField, customerNumberOnly);
                    accountItem.Id = alreadyInSFContact.AccountId;
                    ExternalRequestUtil.mastersToUpdateById.put( (String) accountItem.get(customerNumField), accountItem );
                }
                else // The master account has an customer number
                // The contact is an active customer
                {
                    if (incomingContact.Status__c == 'Activo')
                    {
                        // The master account is updated
                        // Account.Customer_Num__c / Customer_Num_EMEA__c / Customer_Num_Partner__c
                        accountItem.put(customerNumField, customerNumberOnly);
                        // Populate the Id field only if the account has the same customer number
                        if ( alreadyInSFContact.Account.get(customerNumField) == customerNumberOnly )
                        {
                            ExternalRequestUtil.AccountMastersToUpdate.put( (String) accountItem.get(customerNumField), accountItem );
                        }
                        else
                        {
                            accountItem.Id = alreadyInSFContact.AccountId;
                            ExternalRequestUtil.mastersToUpdateById.put( (String) accountItem.get(customerNumField), accountItem );
                        }
                    }
                }

                if ( !String.isBlank(incomingContact.MasterPolicyNum__c) )
                {
                    //Asociar partner cuando el cliente es nuevo
                    AccountUtil.associatePartner(
                        incomingContact,
                        ExternalRequestUtil.mapPartners,
                        ExternalRequestUtil.contactsToUpdateWithPartner,
                        ExternalRequestUtil.partnersToUpdateList,
                        ExternalRequestUtil.recordOwner
                        );
                }

                if (quote != null)
                {
                    quote.CustomerNum__c = customerNumberOnly;
                    quote.AccountId = alreadyInSFContact.AccountId;
                    quote.ContactId__r = new Contact( CustomerNum__c = incomingContact.CustomerNum__c );
                }
            } // NOT FOUND
            else
            {
                createContactAndMaster(  incomingContact,  customerNumField,  customerNumberOnly,  quote );
            }
        }
        return quote;
    }

    /**
     * Método que crea un contacto nuevo y un master nuevo
     * @author nbizkarra
     * @date 10/03/2021
     **/
    public static void createContactAndMaster( Contact incomingContact, String customerNumField, String customerNumberOnly, Order quote )
    {
        // The contact doesn't exist
        

        // Master (account) creation
        Account accountItem = new Account();
        accountItem.name = incomingContact.FirstName + ' ' + incomingContact.LastName;
        accountItem.recordTypeId = SystemUtil.getAccountRecordTypeIdByName( Label.Master );
        accountItem.ownerId = ExternalRequestUtil.recordOwner.id;
        // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
        // Account.CustomerNum__c / CustomerNum_EMEA__c / CustomerNum_Partner__c
        accountItem.put( customerNumField, customerNumberOnly );
        if( ExternalRequestUtil.isIBAMultiPartner && incomingContact.Partner__c != null )
        {
            accountItem.Partner__c = incomingContact.Partner__c;
        }
        ExternalRequestUtil.AccountMastersToUpdate.put( customerNumberOnly, accountItem );

        // Relation: Master - Contact
        incomingContact.Account = new Account();
        // Account.CustomerNum__c / CustomerNum_EMEA__c / CustomerNum_Partner__c
        incomingContact.Account.put( customerNumField, customerNumberOnly );

        incomingContact.OwnerId = ExternalRequestUtil.recordOwner.id;
        ExternalRequestUtil.contactsToUpdate.put( incomingContact.CustomerNum__c, incomingContact );

        if( !String.isBlank(incomingContact.MasterPolicyNum__c) )
        {
            //Asociar partner cuando el cliente es nuevo
            AccountUtil.associatePartner(
                incomingContact,
                ExternalRequestUtil.mapPartners,
                ExternalRequestUtil.contactsToUpdateWithPartner,
                ExternalRequestUtil.partnersToUpdateList,
                ExternalRequestUtil.recordOwner
                );
        }

        // Relation: Quote - Contact - Master
        if (quote != null)
        {
            quote.CustomerNum__c = customerNumberOnly;
            quote.Account = new Account();
            // Account.CustomerNum__c / CustomerNum_EMEA__c / CustomerNum_Partner__c
            quote.Account.put(customerNumField, customerNumberOnly);
            quote.ContactId__r = new Contact( CustomerNum__c = incomingContact.CustomerNum__c );
        }

    }

    /**
     * Método que setea en la cuenta el número total de contactos. Este campo se usa en un campo fórmula del contacto
     * para determinar si existe el contacto en la entidad legal contraria
     * @author nbizkarra
     * @date 01/04/2020
     */
    public static void SummaryTotalContacts( List<Contact> newList, Map<Id, Contact> oldMap )
    {
        
        Set<Id> idSet = new Set<Id>();
        List<Contact> contactOldList = new List<Contact>();
        
        

        if (newList != null || oldMap != null)
        {
            if (newList != null)
            {
                for (Contact cont : newList)
                {
                    //list of IDs of the parent record
                    if (cont.AccountId != null)
                    {
                        idSet.add(cont.AccountId);
                    }
                }
            }
            if (oldMap != null)
            {
                contactOldList = oldMap.values();
                
                for (Contact cont : contactOldList)
                {
                    //list of IDs of the parent record
                    if (cont.AccountId != null)
                    {
                        idSet.add(cont.AccountId);
                    }
                }
            }

            
            if ( !idSet.isEmpty() )
            {
                // Define the context for the RollupSummariesUtil.summarize() method
                RollupSummariesUtil.Context cont = new RollupSummariesUtil.Context(
                    Account.SobjectType,
                    Contact.SobjectType,
                    Schema.SObjectType.Contact.fields.AccountId
                    );

                // RollupSummaryField for the NumClaims__c field
                cont.add(
                    new RollupSummariesUtil.RollupSummaryField(
                        Schema.SObjectType.Account.fields.NumberOfContacts__c,
                        Schema.SObjectType.Contact.fields.Id,
                        RollupSummariesUtil.summaryOperation.Count
                        )
                    );

                // Call summarize method with context and parent records
                Sobject[] responseObject = RollupSummariesUtil.summarize(cont, idSet);

                responseObject = (Contact[]) responseObject;

                if ( responseObject != null && !responseObject.isEmpty() )
                {
                    update responseObject;
                }
            }
        }
    }

    /**
     * Método que genera el hash de seguridad del contact Id para usarlo como token de seguridad en el centro de preferencias
     **
     * @param String id
     * @return String
     *
     * @author iortega
     * @date 25/05/2020
     */
    public static void generateHashContactId( List<Contact> newList, Map<Id, Contact> oldMap )
    {
        
        List<Contact> updateContacts = new List<Contact>();

        if (newList != null || oldMap != null)
        {
            for (Contact contacto : newList)
            {
                if (contacto.Id != null)
                {
                    Contact aux = new Contact(Id = contacto.Id);

                    //Se obtiene el hash del id del contacto
                    aux.HashedId__c = SystemUtil.generateHash(contacto.Id);
                    updateContacts.add(aux);
                }
            }

            //Se actualiza la lista de contactos
            if (updateContacts.size() > 0)
            {
                update updateContacts;
            }
        }
    }

    /**
     * Método que actualiza la información del step de la última quote de un contacto cuando cambia la dirección o la tarjeta
     * de crédito y el contacto tiene una quote en el step 4 o 5
     * @author nbizkarra
     * @date 30/06/2020
     */
    public static void updateQuoteStep4and5( List<Contact> newList, Map<Id, Contact> oldMap )
    {
        
        List<Contact> quotes = new List<Contact>();
        Map<ID, Order> quotesToUpdate = new Map<ID, Order>();
        Map<ID, Contact> mapContactos = new Map<ID, Contact>();

        Set<Id> idSet = new Set<Id>();

        if (newList != null && oldMap != null)
        {
            for (Contact cont : newList)
            {
                //guardar los ids de las quotes para hacer la query del campo QbLastPage__C
                if (
                    cont.LastQuote__c != null &&
                    (cont.MailingStreet != oldMap.get(cont.Id).MailingStreet ||
                     cont.CreditCard__c != oldMap.get(cont.Id).CreditCard__c)
                    )
                {
                    idSet.add(cont.LastQuote__c);
                    mapContactos.put(cont.id, cont);
                }
            }

            Map<ID, Order> MapQuotes = new Map<ID, Order>(
                [SELECT id, QbLastPage__c, Step__c FROM Order WHERE id = : idSet]
                );

            if (MapQuotes != null && mapContactos != null)
            {
                for ( Contact cont : mapContactos.values() )
                {
                    Order quote = MapQuotes.get(cont.LastQuote__c);
                    if (quote.QbLastPage__c != null)
                    {
                        //Si está en el step 4
                        if ( quote.QbLastPage__c.equalsIgnoreCase('elige tu protección') ||
                             quote.QbLastPage__c.equalsIgnoreCase('quote configuration') )
                        {
                            //Si solo cambia dirección, ha pasado al step 5
                            if (
                                cont.MailingStreet != oldMap.get(cont.Id).MailingStreet &&
                                cont.CreditCard__c == oldMap.get(cont.Id).CreditCard__c
                                )
                            {
                                quote.Step__c = 'Step5';
                                quotesToUpdate.put(quote.id, quote);
                            }
                            else if (
                                cont.CreditCard__c != oldMap.get(cont.Id).CreditCard__c
                                )
                            {
                                quote.Step__c = 'Step6';
                                quotesToUpdate.put(quote.id, quote);
                            }
                        }
                    }
                }

                //Update step in the quotes
                if ( quotesToUpdate != null && !quotesToUpdate.isEmpty() )
                {
                    update quotesToUpdate.values();
                }
            }
        }
    }
}