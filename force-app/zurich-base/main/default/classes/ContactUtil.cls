/**
 * @author nbizkarra
 * @date 01/04/2020
 **/
global without sharing class ContactUtil
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
        System.debug('- - - - - ContactUtil.adaptCustomerNum - - - - -');
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


    // EMEA
    public static Order upsertContact(Contact incomingContact, Order quote)
    {
        System.debug('- - - - - ContactUtil.upsertContact - - - - -');
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
        // System.debug('*** Request customerNum: ' + customerNum);
        // System.debug('*** incomingContact: ' + incomingContact.CustomerNum__c);
        String customerNum = incomingContact.CustomerNum__c;

        Contact alreadyInSFContact = ExternalRequestUtil.mapContacts.get( customerNum );
        // The contact exist with the same customer number
        // BY CUSTOMER NUM -------------------------------------------------------------------------------------------------
        if ( alreadyInSFContact != null )
        {
            System.debug('>>> Contact found by Customer Number');

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
            String emailBirthDateLECountryCode = '';
            String emailBirthDateLECode = '';
            String emailBirthDateCode = '';

            if ( !String.isBlank(incomingContact.Email) && null != incomingContact.Birthdate )
            {
                emailBirthDateCode = incomingContact.Email + String.valueOfGmt(incomingContact.Birthdate);
                emailBirthDateLECode = emailBirthDateCode + legalEntity;

                if( !String.isBlank(incomingContact.sourceCountry__c) )
                {
                    emailBirthDateLECountryCode = emailBirthDateLECode + incomingContact.sourceCountry__c;
                }
            }

            System.debug( '>>> ExternalRequestUtil.mapContacts ' + ExternalRequestUtil.mapContacts );
            System.debug( '>>> ExternalRequestUtil.recordsToProcess ' + ExternalRequestUtil.recordsToProcess );
            System.debug( '>>> ExternalRequestUtil.actualRequest ' + ExternalRequestUtil.actualRequest );

            // EMAIL - BIRTHDATE - LEGALENTITY - COUNTRY
            if ( ExternalRequestUtil.mapContactsEmailBirthDateLECountry.containsKey( emailBirthDateLECountryCode ) )
            {
                // If contact exists with a different customer number
                System.debug('>>> Contact found by MC1');
                alreadyInSFContact = ExternalRequestUtil.mapContactsEmailBirthDateLECountry.get( emailBirthDateLECountryCode );

                if ( incomingContact.status__c == 'Lead' )
                {
                    // Update the contact only if it is also a lead in Salesforce
                    if( alreadyInSFContact.status__c == 'Lead' )
                    {
                        // Update the lead but keep the existing Customer Number
                        // todo: always will be the same country
                        // if ( incomingContact.sourceCountry__c == alreadyInSFContact.sourceCountry__c ) {
                        incomingContact.Id = alreadyInSFContact.Id;
                        // } else {
                        //     if (!String.isBlank(incomingContact.MasterPolicyNum__c)) {
                        //         //Asociar partner cuando el cliente es nuevo
                        //         AccountUtil.associatePartner(
                        //             incomingContact,
                        //             ExternalRequestUtil.mapPartners,
                        //             ExternalRequestUtil.contactsToUpdateWithPartner,
                        //             ExternalRequestUtil.partnersToUpdateList,
                        //             ExternalRequestUtil.recordOwner
                        //         );
                        //     }
                        // }
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
                }
                else if( incomingContact.status__c == 'Activo' )
                {
                    //&& (alreadyInSFContact.status__c == 'Lead' || alreadyInSFContact.status__c == 'Activo') ) {

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

                    // If there is a quote, and the contact is not a lead, the relationship between the
                    // quote and the contact is set but the contact is NOT updated
                    if (quote != null)
                    {
                        //Si se pasa la quote como parametro, solo se relaciona con el cliente, no se actualiza el cliente
                        quote.ContactId__c = alreadyInSFContact.Id;
                        quote.AccountId = alreadyInSFContact.AccountId;
                    }
                    else
                    {
                        // todo: always will be the same country
                        // if ( incomingContact.sourceCountry__c == alreadyInSFContact.sourceCountry__c ) {
                        incomingContact.Id = alreadyInSFContact.Id;
                        // } else {
                        //   if (!String.isBlank(incomingContact.MasterPolicyNum__c)) {
                        //       //Asociar partner when the client is new
                        //       AccountUtil.associatePartner(
                        //         incomingContact,
                        //         ExternalRequestUtil.mapPartners,
                        //         ExternalRequestUtil.contactsToUpdateWithPartner,
                        //         ExternalRequestUtil.partnersToUpdateList,
                        //         ExternalRequestUtil.recordOwner
                        //       );
                        //   }
                        // }
                        incomingContact.AccountId = alreadyInSFContact.AccountId;
                        incomingContact.OwnerId = ExternalRequestUtil.recordOwner.id;
                        ExternalRequestUtil.contactsToUpdate.put( incomingContact.CustomerNum__c, incomingContact );
                    }
                }
            } // EMAIL - BIRTHDATE - LEGALENTITY
            else if ( ExternalRequestUtil.mapContactsEmailBirthDateLE.containsKey( emailBirthDateLECode ) )
            {
                // If the contact exists in another country
                System.debug('>>> Contact found by MC2');

                alreadyInSFContact = ExternalRequestUtil.mapContactsEmailBirthDateLE.get( emailBirthDateLECode );

                incomingContact.AccountId = alreadyInSFContact.AccountId;

                Account accountItem = new Account();
                accountItem.Name = incomingContact.FirstName + ' ' + incomingContact.LastName;

                // The master account doesn't have the EMEA customer number
                // Account.CustomerNum__c / CustomerNum_EMEA__c / CustomerNum_Partner__c
                if( String.isBlank( (String) alreadyInSFContact.Account.get(customerNumField) ) )
                {
                    // The master account is updated
                    // Account.CustomerNum__c / CustomerNum_EMEA__c / CustomerNum_Partner__c
                    accountItem.put(customerNumField, customerNumberOnly);
                    accountItem.Id = alreadyInSFContact.AccountId;
                    ExternalRequestUtil.mastersToUpdateById.put( (String) accountItem.get(customerNumField), accountItem );
                }
                else // The master account has an EMEA customer number
                // The contact is a lead
                {
                    if (incomingContact.Status__c == 'Lead')
                    {
                        incomingContact.CustomerNum__c = alreadyInSFContact.CustomerNum__c;
                        // todo: forced to be the same id if is the same CustomerNum and already exist
                        incomingContact.Id = alreadyInSFContact.Id;
                        // Notice that the master account IS NOT UPDATED (by not putting it in any map)
                    }
                    else // The contact is an ACTIVE customer
                    // The master account is updated
                    // Account.CustomerNum__c / CustomerNum_EMEA__c / CustomerNum_Partner__c
                    {
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

                // todo: this cant happen because of the match condition
                // if ( incomingContact.sourceCountry__c == alreadyInSFContact.sourceCountry__c ) {
                //     incomingContact.Id = alreadyInSFContact.Id;
                // } else {
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
                // }
                incomingContact.OwnerId = ExternalRequestUtil.recordOwner.id;
                ExternalRequestUtil.contactsToUpdate.put( incomingContact.CustomerNum__c, incomingContact );

                if (quote != null)
                {
                    quote.AccountId = alreadyInSFContact.AccountId;
                    quote.CustomerNum__c = customerNumberOnly;
                    quote.ContactId__r = new Contact( CustomerNum__c = incomingContact.CustomerNum__c );
                }
            } // EMAIL - BIRTHDATE
            else if ( ExternalRequestUtil.mapContactsEmailBirthDate.containsKey( emailBirthDateCode ) )
            {
                // If the contact exists with a different legal entity
                System.debug('>>> Contact found by MC3');
                alreadyInSFContact = ExternalRequestUtil.mapContactsEmailBirthDate.get( emailBirthDateCode );

                incomingContact.AccountId = alreadyInSFContact.AccountId;

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

                incomingContact.OwnerId = ExternalRequestUtil.recordOwner.id;
                ExternalRequestUtil.contactsToUpdate.put( incomingContact.CustomerNum__c, incomingContact );

                if (quote != null)
                {
                    quote.CustomerNum__c = customerNumberOnly;
                    quote.AccountId = alreadyInSFContact.AccountId;
                    quote.ContactId__r = new Contact( CustomerNum__c = incomingContact.CustomerNum__c );
                }
            } // SEARCH AMONG SUBSCRIBERS // nts (nbizkarra) - 17/11/2020
            else if (ExternalRequestUtil.mapSubscribers.containsKey(incomingContact.Email) )
            {
                System.debug('>>> Contact found in Subscribers');
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

                        System.debug('>>> Subscriber found: ' + subscriber);
                        alreadyInSFContact = subscriber;
                        incomingContact.Id = alreadyInSFContact.Id;
                        ExternalRequestUtil.contactsToUpdate.put( incomingContact.CustomerNum__c, incomingContact );
                        subscriber_found = true;
                    }
                }

                //If no subscriber with same LE, Country and Partner, associate the incoming contact with the existing master
                if(subscriber_found == false)
                {

                    System.debug('>>> Subscribers master found');

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
                // The contact doesn't exist
                System.debug('>>> The contact does not exist');

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
        }
        return quote;
    }

    /**
     * Método que actualiza la información común de un cliente de la entidad contraria a través de un trigger (after insert, after update)
     * @author nbizkarra
     * @date 01/04/2020
     **/
    public static void updateCustomerInfo( List<Contact> newList, Map<Id, Contact> oldMap )
    {
        System.debug('- - - - - ContactUtil.updateCustomerInfo - - - - -');
        List<Contact> updateContacts = new List<Contact>();
        List<Account> updateMasters = new List<Account>();
        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();

        if (newList != null)
        {
            for (Contact cont : newList)
            {
                //Solo actualizar si es cliente
                if (cont.Status__c == Label.Customer)
                {
                    if ( !checkRecursive.SetOfIDs.contains(cont.AccountId) )
                    {
                        if (oldMap != null)
                        {
                            //cuando es after update, actualizar cuando cambia algún valor común
                            if (
                                (!String.isBlank(cont.DNI__c) && cont.DNI__c != oldMap.get(cont.Id).DNI__c) ||
                                (!String.isBlank(cont.Email) && cont.Email != oldMap.get(cont.Id).Email) ||
                                //  (!String.isBlank(cont.MobilePhone) && cont.MobilePhone != oldMap.get(cont.Id).MobilePhone)  ||
                                // (cont.Birthdate!= null && cont.Birthdate != oldMap.get(cont.Id).Birthdate)  ||
                                (!String.isBlank(cont.FirstName) && cont.FirstName != oldMap.get(cont.Id).FirstName) ||
                                (!String.isBlank(cont.LastName) && cont.LastName != oldMap.get(cont.Id).LastName) ||
                                //  (!String.isBlank(cont.Nationality__c) && cont.Nationality__c !=oldMap.get(cont.Id).Nationality__c) ||
                                //   (!String.isBlank(cont.Gender__c) && cont.Gender__c !=oldMap.get(cont.Id).Gender__c) ||
                                (cont.MasterPolicy__c != null && cont.MasterPolicy__c != oldMap.get(cont.Id).MasterPolicy__c)
                                )
                            {
                                //Solo los clientes
                                List<Account> masters = new List<Account>();
                                Account master;
                                masters = [
                                    SELECT Id, Name,
                                    (SELECT Id FROM Contacts WHERE Id != :cont.Id AND Status__c = :Label.Customer)
                                    FROM Account
                                    WHERE Id = :cont.AccountId
                                ];

                                if (masters != null)
                                {
                                    master = masters.get(0);
                                }

                                if (master != null && master.Contacts != null)
                                {
                                    //Actualizar nombre en el master
                                    if ( (!String.isBlank(cont.FirstName) && cont.FirstName != oldMap.get(cont.Id).FirstName) ||
                                         (!String.isBlank(cont.LastName) && cont.LastName != oldMap.get(cont.Id).LastName) )
                                    {
                                        master.Name = cont.FirstName + ' ' + cont.LastName;
                                        updateMasters.add(master);
                                    }

                                    for (Contact SFcontact : master.Contacts)
                                    {
                                        if ( !String.isBlank(cont.DNI__c) )
                                        {
                                            SFcontact.DNI__c = cont.DNI__c;
                                        }
                                        if ( !String.isBlank(cont.Email) )
                                        {
                                            SFcontact.Email = cont.Email;
                                        }
                                        //  if(!String.isBlank(cont.MobilePhone)){SFcontact.MobilePhone=cont.MobilePhone;}
                                        //  if(cont.Birthdate!= null){SFcontact.Birthdate=cont.Birthdate;}
                                        if ( !String.isBlank(cont.FirstName) )
                                        {
                                            SFcontact.FirstName = cont.FirstName;
                                        }
                                        if ( !String.isBlank(cont.LastName) )
                                        {
                                            SFcontact.LastName = cont.LastName;
                                        }
                                        //  if(!String.isBlank(cont.Nationality__c)){ SFcontact.Nationality__c=cont.Nationality__c;}
                                        //  if(!String.isBlank(cont.Gender__c)){ SFcontact.Gender__c=cont.Gender__c;}

                                        //update masterpolicy if it is set to true in custom metadatatype
                                        if (adminSetup.SameMasterPolicy__c == true)
                                        {
                                            if (cont.MasterPolicy__c != null)
                                            {
                                                SFcontact.MasterPolicy__c = cont.MasterPolicy__c;
                                            }
                                        }
                                        updateContacts.add(SFcontact);
                                    }
                                }
                            }
                        }
                        else //cuando es after insert
                        {
                            List<Account> masters = new List<Account>();
                            Account master;
                            masters = [
                                SELECT id, Name,
                                (SELECT Id, DNI__c, Email, MobilePhone, Birthdate, FirstName,LastName, Nationality__c, Gender__c, MasterPolicy__c
                                 FROM Contacts
                                 WHERE Id != :cont.Id AND Status__c = :Label.Customer)
                                FROM Account
                                WHERE Id = :cont.AccountId
                            ];

                            if (masters != null && masters.size() > 0)
                            {
                                master = masters.get(0);
                            }

                            if (master != null && master.Contacts != null)
                            {
                                for (Contact SFcontact : master.Contacts)
                                {
                                    if ( !String.isBlank(cont.DNI__c) && !cont.DNI__c.equalsIgnoreCase(SFcontact.DNI__c) )
                                    {
                                        SFcontact.DNI__c = cont.DNI__c;
                                    }
                                    if ( !String.isBlank(cont.Email) && !cont.Email.equalsIgnoreCase(SFcontact.Email) )
                                    {
                                        SFcontact.Email = cont.Email;
                                    }
                                    // if(!String.isBlank(cont.MobilePhone)  && !cont.MobilePhone.equalsIgnoreCase(SFcontact.MobilePhone) ){SFcontact.MobilePhone=cont.MobilePhone;}
                                    //  if(cont.Birthdate!= null && cont.Birthdate!=SFcontact.Birthdate){SFcontact.Birthdate=cont.Birthdate;}
                                    if ( !String.isBlank(cont.FirstName) && !cont.FirstName.equalsIgnoreCase(SFcontact.FirstName) )
                                    {
                                        SFcontact.FirstName = cont.FirstName;
                                    }
                                    if ( !String.isBlank(cont.LastName) && !cont.LastName.equalsIgnoreCase(SFcontact.LastName) )
                                    {
                                        SFcontact.LastName = cont.LastName;
                                    }
                                    //  if(!String.isBlank(cont.Nationality__c) && !cont.Nationality__c.equalsIgnoreCase(SFcontact.Nationality__c) ){ SFcontact.Nationality__c=cont.Nationality__c;}
                                    //  if(!String.isBlank(cont.Gender__c) && !cont.Gender__c.equalsIgnoreCase(SFcontact.Gender__c) ){ SFcontact.Gender__c=cont.Gender__c;}
                                    //update masterpolicy if it is set to true in custom metadatatype

                                    if (adminSetup.SameMasterPolicy__c == true)
                                    {
                                        if ( cont.MasterPolicy__c != null && cont.MasterPolicy__c != SFcontact.MasterPolicy__c )
                                        {
                                            SFcontact.MasterPolicy__c = cont.MasterPolicy__c;
                                        }
                                    }
                                    updateContacts.add(SFcontact);
                                }
                            }
                        }
                        checkRecursive.SetOfIDs.add(cont.AccountId);
                    }
                }
            }
        }

        if ( updateMasters != null && !updateMasters.isEmpty() )
        {
            upsert updateMasters;
        }

        if ( updateContacts != null && !updateContacts.isEmpty() )
        {
            upsert updateContacts;
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
        System.debug('- - - - - ContactUtil.SummaryTotalContacts - - - - -');
        Set<Id> idSet = new Set<Id>();
        List<Contact> contactOldList = new List<Contact>();
        System.debug(oldMap);
        System.debug(oldMap != null);

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
                System.debug(contactOldList);
                for (Contact cont : contactOldList)
                {
                    //list of IDs of the parent record
                    if (cont.AccountId != null)
                    {
                        idSet.add(cont.AccountId);
                    }
                }
            }

            System.debug(idSet);
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
        System.debug('- - - - - ContactUtil.generateHashContactId - - - - -');
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
        System.debug('- - - - - ContactUtil.updateQuoteStep4and5 - - - - -');
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