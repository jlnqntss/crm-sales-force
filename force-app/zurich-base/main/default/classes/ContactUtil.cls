/**
 * @author nbizkarra
 * @date 01/04/2020
 **/
global without sharing class ContactUtil {
  /**
   * Método que adapta el número de cliente para cada entidad legal
   * @param String número de cliente y entidad legal
   * @author nbizkarra
   * @return Número de cliente con el formato adaptado
   * @date 01/04/2020
   **/
  public static String adaptCustomerNum(
    String CustomerNum,
    String LegalEntity
  ) {
    System.debug('- - - - - ContactUtil.adaptCustomerNum - - - - -');
    if (
      LegalEntity.equals('GI') || LegalEntity.equals(Label.GeneralInsurance)
    ) {
      CustomerNum = 'GI-' + CustomerNum;
    } else if (LegalEntity.equals(Label.LifeInsurance)) {
      CustomerNum = 'LIFE-' + CustomerNum;
    } else {
      throw new IntegrationException(Label.LegalEntityError);
    }

    return CustomerNum;
  }

  /**
   * Método que inserta o actualiza un cliente, si recibe una quote como parámetro, lo asocia al cliente y devuelve
   * la quote con el cliente asociado
   * @author nbizkarra
   * @date 01/04/2020
   */
  /*public static Order upsertCustomer(Contact customer, Order quote, Map<String, Contact> mapContacts, Map<String,Contact> contactsToUpdateList,
                                Map<String, Contact> mapContactsMatchCode, Map<String, Contact> mapContactsMatchCodePartial,
                                Map<String,Account> mastersToUpdateList, Map<String, Account> mastersEmeaToUpdateList, Map<String, Account> mapPartners,
                                Map<String, Contact> contactsToUpdateWithPartner,Map<String,Account> partnersToUpdateList,User recordOwner)
    {
        System.debug('- - - - - ContactUtil.upsertCustomer - - - - -');
        customer.CustomerNum__c = ContactUtil.adaptCustomerNum(customer.CustomerNum__c, customer.LegalEntity__c);
        //Si el campo receive marketig de IBA está a false, settear hasOptedOut de Salesforce
        if(customer.receiveMarketing__c == false)
        {
            customer.HasOptedOutOfEmail = true;
        }

        String legalEntityName;
        if(customer.LegalEntity__c.equals(Label.GeneralInsurance))
        {
            legalEntityName = 'GI';
        }
        else
        {
            legalEntityName = 'Life';
        }

        customer.RecordTypeId = SystemUtil.getContactRecordTypeIdByName('Customer' + legalEntityName);

        Contact contactoSF = mapContacts.get(customer.CustomerNum__c);
        if(contactoSF != null)
        {//El contacto existe en SF (lead o customer)           
            System.debug('The Contact exists >>> ' + contactoSF.Id);

            if(quote != null)
            {//Si se pasa la quote como parametro, solo se relaciona con el cliente, no se actualiza el cliente
                quote.ContactId__c = contactoSF.Id;
                quote.AccountId = contactoSF.AccountId;
            }
            else
            {
                //actualizar cliente
                customer.Id = contactoSF.Id;

                if(String.isBlank(customer.LastName))
                {
                    customer.LastName = Label.LeadLastName;
                }
                contactsToUpdateList.put(customer.CustomerNum__c, customer);
            }
        }
        else
        {   
            // EMEA
            // Buscamos por Email + Birthday + LegalEntity + SourceCountry
            Contact contactoMatchCode = mapContactsMatchCode.get(customer.Email + customer.Birthdate + legalEntityName + customer.SourceCountry__c);
            String[] adaptCustNum = customer.CustomerNum__c.split('-');
            if(contactoMatchCode != null)
            {
                // El contacto existe con otro CustomerNum
                // Actualizamos el customerNum de la master Account
                Account masterAccount = [SELECT Id FROM Account 
                                         WHERE Id = : contactoMatchCode.AccountId LIMIT 1];// CustomerNum__c, CustomerNum_EMEA__c
                if(masterAccount != null)
                {
                    if(customer.SourceCountry__c != 'Spain')
                    {
                        masterAccount.CustomerNum_EMEA__c = adaptCustNum[1];
                        mastersEmeaToUpdateList.put(masterAccount.CustomerNum_EMEA__c, masterAccount);
                    }
                    else
                    {
                        masterAccount.CustomerNum__c = adaptCustNum[1];
                        mastersToUpdateList.put(masterAccount.CustomerNum__c, masterAccount);
                    }
                }
                // END EMEA

                if(quote != null)
                {
                    //Si se pasa la quote como parametro, solo se relaciona con el cliente, no se actualiza el cliente
                    quote.ContactId__c = contactoMatchCode.Id;
                    quote.AccountId = contactoMatchCode.AccountId;
                }
                else
                {
                    //actualizar cliente
                    customer.Id = contactoMatchCode.Id;
    
                    if(String.isBlank(customer.LastName)){
                        customer.LastName = Label.LeadLastName;
                    }
                    contactsToUpdateList.put(customer.CustomerNum__c, customer);
                }
            }
            else
            {
                // Búsqueda sin tener en cuenta la legal entity ni el country
                Contact contactoMatchCodePartial = mapContactsMatchCodePartial.get(customer.Email+customer.Birthdate);
                if(contactoMatchCodePartial != null)
                {              
                    // Encuentra contacto por email + birthdate                  
                    System.debug('Contacto con el mismo email y fecha de nacimiento existe');
             
                    Account masterAccount = [SELECT Id FROM Account 
                                             WHERE Id = :contactoMatchCodePartial.AccountId];// CustomerNum__c, CustomerNum_EMEA__c
                
                    if(customer.SourceCountry__c != 'Spain')
                    {
                        // Tanto si el Customer Num EMEA es blanco como si hay uno, se va a sustituir y se asociará el contacto a ese master.
                        customer.AccountId = contactoMatchCodePartial.AccountId;
                        masterAccount.CustomerNum_EMEA__c = adaptCustNum[1];
                    }
                    else
                    {
                        // Tanto si el Customer Num es blanco como si hay uno, se va a sustituir y se asociará el contacto a ese master.
                        customer.AccountId = contactoMatchCodePartial.AccountId;
                        masterAccount.CustomerNum__c = adaptCustNum[1];
                    }

                    if(quote != null)
                    {
                        Contact contactRef = new Contact(CustomerNum__c = customer.CustomerNum__c);
                        quote.AccountId = contactoMatchCodePartial.AccountId;
                        quote.CustomerNum__c = customer.CustomerNum__c;
                        quote.ContactId__r = contactRef;
                    }

                    if(String.isBlank(customer.LastName))
                    {
                        customer.LastName = Label.LeadLastName;
                    }

                    //Poner el owner el usuario integrador
                    customer.OwnerId = recordOwner.id;
                    //Actualizar contacto
                    contactsToUpdateList.put(customer.CustomerNum__c, customer);
                }
                else
                {
                        // No encuentra el contacto por email + birthdate
                        // EMEA
                        String customerNumberSpain = '';
                        String customerNumberEmea = '';
                        if(customer.SourceCountry__c != 'Spain')
                        {
                            customerNumberEmea = customer.CustomerNum__c;
                        }
                        else 
                        {
                            customerNumberSpain = customer.CustomerNum__c;
                        }
                     
                        // Creamos nuevo master Account
                        Account newMaster = new Account(
                                                Name = customer.FirstName + ' ' + customer.LastName,
                                                RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master));
                        // gpacho 2020-09-09
                        if(customer.SourceCountry__c != 'Spain')
                        {
                            newMaster.CustomerNum_EMEA__c = adaptCustNum[1];
                        }
                        else 
                        {
                            newMaster.CustomerNum__c = adaptCustNum[1];
                        }
                        // END EMEA

                        //Poner el owner el usuario integrador
                        newMaster.OwnerId = recordOwner.id;
                        customer.OwnerId = recordOwner.id;
                        Account masterRef = new Account();
                        // EMEA gpacho 2020-09-09
                        if(customer.SourceCountry__c != 'Spain')
                        {
                            mastersEmeaToUpdateList.put(newMaster.CustomerNum_EMEA__c, newMaster);
                            masterRef.CustomerNum_EMEA__c = adaptCustNum[1];
                        }
                        else
                        {
                            mastersToUpdateList.put(newMaster.CustomerNum__c, newMaster);
                            masterRef.CustomerNum__c = adaptCustNum[1];
                        }
                        // END EMEA
                        customer.Account = masterRef;

                        if(String.isBlank(customer.LastName))
                        {
                            customer.LastName = Label.LeadLastName;
                        }
                                            
                        contactsToUpdateList.put(customer.CustomerNum__c, customer);

                        if(quote != null)
                        {
                            Contact contactRef= new Contact(CustomerNum__c = customer.CustomerNum__c);
                            quote.CustomerNum__c = customer.CustomerNum__c;
                            quote.ContactId__r = contactRef;
                            quote.Account = masterRef;
                        }
                }
            
                if(!String.isBlank(customer.MasterPolicyNum__c))
                { 
                    //Asociar partner cuando el cliente es nuevo
                    AccountUtil.associatePartner(customer,mapPartners, contactsToUpdateWithPartner, partnersToUpdateList,recordOwner);
                }
            }
        }
        return quote;
    }*/

  /**
   * @Description: Método que inserta o actualiza un lead, si recibe una quote como parámetro, lo asocia al lead o customer y devuelve
   *               la quote con el lead asociado.
   * @Author: nbizkarra
   * @Date: 01/04/2020
   **/
  /*public static Order upsertLead(Contact lead, Order quote, Map<String, Contact> mapContacts, Map<String,Contact> contactsToUpdateList,
                                   Map<String, Contact> mapContactsMatchCode, Map<String, Contact> mapContactsMatchCodePartial, 
                                   Map<String,Account> mastersToUpdateList, Map<String, Account> mastersEmeaToUpdateList,
                                   Map<String, Account> mapPartners, Map<String, Contact> contactsToUpdateWithPartner,
                                   Map<String,Account> partnersToUpdateList, User recordOwner)
    {
        System.debug('- - - - - ContactUtil.upsertLead - - - - -');
        lead.CustomerNum__c = ContactUtil.adaptCustomerNum(lead.CustomerNum__c, lead.LegalEntity__c);
        String legalEntityName;

        if(lead.LegalEntity__c.equals(Label.GeneralInsurance))
        {
            legalEntityName = 'GI';
        }
        else
        {
            legalEntityName ='Life';
        }

        lead.RecordTypeId = SystemUtil.getContactRecordTypeIdByName('Lead' + legalEntityName);

        //Si el campo receive marketig de IBA está a false, settear hasOptedOut de Salesforce
        if(lead.receiveMarketing__c == false)
        {
            lead.HasOptedOutOfEmail = true;
        }

        Contact contactoSF = mapContacts.get(lead.CustomerNum__c);
        if(contactoSF != null)
        {//El lead existe en SF

            System.debug('Lead existe');
            lead.Id = contactoSF.Id;

            if(String.isBlank(lead.LastName))
            {
                lead.LastName = Label.LeadLastName;
            }
            
            contactsToUpdateList.put(lead.CustomerNum__c, lead);
            
            //Si se pasa quote como parametro, asociar lead y master
            if(quote != null)
            {
                quote.ContactId__c = contactoSF.Id;
                quote.AccountId = contactoSF.AccountId;
            }
        }
        else
        {
            //Buscar por matchcode: email + birthdate + legal entity + Source Country
            
            Contact contactoMatchCode = mapContactsMatchCode.get(lead.Email + lead.Birthdate + legalEntityName + lead.SourceCountry__c);
            if(contactoMatchCode != null)
            {
                System.debug('Lead matchcode existe');
                //actualizar información solo si el contacto de Salesforce es un lead
                if(contactoMatchCode.Status__c.equals(Label.Lead))
                {
                    lead.Id = contactoMatchCode.Id;
                    lead.CustomerNum__c = contactoMatchCode.CustomerNum__c;

                    if(String.isBlank(lead.LastName))
                    {
                        lead.LastName = Label.LeadLastName;
                    }

                    contactsToUpdateList.put(lead.CustomerNum__c, lead);
                }

                if(quote != null)
                {
                    quote.AccountId = contactoMatchCode.AccountId;
                    quote.ContactId__c = contactoMatchCode.Id;
                    quote.CustomerNum__c = contactoMatchCode.Account.CustomerNum__c;
                }

            }
            else 
            {*/
  /** OLD Buscar matchcode en la entidad legal contraria
                String opposite_LE;

                if(lead.LegalEntity__c.equals(Label.LifeInsurance))
                {
                    opposite_LE='GI';
                }
                else
                {
                    opposite_LE='Life';
                }
                */

  // EMEA
  /*Contact contactMatchCodePartial = mapContactsMatchCodePartial.get(lead.Email + lead.Birthdate);
                // END EMEA

                //Account masterMatchCode = mapAccountsMatchCode.get(lead.Email+lead.Birthdate);
                if(contactMatchCodePartial != null)
                {
                    System.debug('Matchcode existe con Email + Birthday');
                    lead.AccountId = contactMatchCodePartial.AccountId;

                    //Quitar prefijo de la entidad legal al customer number
                    String[] adaptCustNum = contactMatchCodePartial.CustomerNum__c.split('-');
                    lead.CustomerNum__c = ContactUtil.adaptCustomerNum(adaptCustNum[1], lead.LegalEntity__c);
                    
                    // EMEA
                    Account masterAccount = [SELECT CustomerNum_EMEA__c, CustomerNum__c 
                                             FROM Account WHERE Id = : contactMatchCodePartial.AccountId LIMIT 1];
                    if(masterAccount != null)
                    {
                        if(lead.SourceCountry__c != 'Spain')
                        {
                            if(masterAccount.CustomerNum_EMEA__c != null)
                            {
                                lead.CustomerNum__c = masterAccount.CustomerNum_EMEA__c;
                            }
                            else
                            {
                                masterAccount.CustomerNum_EMEA__c = adaptCustNum[1];
                                mastersEmeaToUpdateList.put(masterAccount.CustomerNum_EMEA__c, masterAccount);
                            }
                        }
                        else
                        {
                            if(masterAccount.CustomerNum__c != null)
                            {
                                lead.CustomerNum__c = masterAccount.CustomerNum__c;
                            }
                            else
                            {
                                masterAccount.CustomerNum__c = adaptCustNum[1];
                                mastersToUpdateList.put(masterAccount.CustomerNum__c, masterAccount);
                            }
                        }
                    }
                    // END EMEA

                    //Lastname campo obligatorio, si está vacío se inserta valor
                    if(String.isBlank(lead.LastName))
                    {
                        lead.LastName = Label.LeadLastName;
                        lead.FirstName = Label.LeadLastName;
                    }
                    //Poner el owner el usuario integrador
                    lead.OwnerId = recordOwner.id;
                    
                    contactsToUpdateList.put(lead.CustomerNum__c, lead);
                
                    if(quote != null)
                    {
                        Contact contactRef = new Contact(CustomerNum__c = lead.CustomerNum__c);
                        quote.AccountId = contactMatchCodePartial.AccountId;
                        quote.CustomerNum__c = adaptCustNum[0];
                        quote.ContactId__r = contactRef;
                    }
                }
                else //si no existe, crear master
                {
                    String[] adaptCustNum = lead.CustomerNum__c.split('-');

                    //Lastname campo obligatorio, si está vacío se inserta valor
                    if(String.isBlank(lead.lastName))
                    {
                        lead.LastName = Label.LeadLastName;
                    }

                    // EMEA
                    String customerNumberSpain = '';
                    String customerNumberEmea = '';
                    if(lead.SourceCountry__c != 'Spain')
                    {
                        customerNumberEmea = adaptCustNum[1];
                    }
                    else 
                    {
                        customerNumberSpain = adaptCustNum[1];
                    }
                    // END EMEA

                    Account newMaster = new Account(
                                            Name = lead.FirstName + ' ' + lead.LastName,                        
                                            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master));
                    // EMEA gpacho 2020-09-09
                    if(lead.SourceCountry__c != 'Spain')
                    {
                        newMaster.CustomerNum_EMEA__c = customerNumberEmea;
                    }
                    else 
                    {
                        newMaster.CustomerNum__c = customerNumberSpain;
                    }
                    // END EMEA
                    
                    //Poner el owner el usuario integrador
                    newMaster.OwnerId = recordOwner.id;
                    lead.OwnerId = recordOwner.id;

                    // EMEA
                    if(lead.SourceCountry__c != 'Spain')
                    { 
                        mastersEmeaToUpdateList.put(newMaster.CustomerNum_EMEA__c, newMaster);
                    }
                    else
                    {
                        mastersToUpdateList.put(newMaster.CustomerNum__c, newMaster);
                    }

                    // gpacho 2020-09-09
                    Account masterRef = new Account();
                    if(lead.SourceCountry__c != 'Spain')
                    {
                        masterRef.CustomerNum_EMEA__c = customerNumberEmea;
                    }
                    else 
                    {
                        masterRef.CustomerNum__c = customerNumberSpain;
                    }
                    
                    // END EMEA
                    lead.Account = masterRef;
                    contactsToUpdateList.put(lead.CustomerNum__c, lead);
                    
                    if(quote != null)
                    {
                        Contact contactRef = new Contact(CustomerNum__c = lead.CustomerNum__c);
                        quote.CustomerNum__c = adaptCustNum[1];
                        quote.ContactId__r = contactRef;
                        quote.Account = masterRef;
                    }
                    
                }

                if(!String.isBlank(lead.MasterPolicyNum__c))
                { 
                    //Asociar partner cuando el lead es nuevo
                    AccountUtil.associatePartner(lead,mapPartners, contactsToUpdateWithPartner, partnersToUpdateList,recordOwner);
                }
            }
        }
        return quote;
    }*/

  public static Order upsertContact(Contact incomingContact, Order quote) {
    System.debug('- - - - - ContactUtil.upsertContact - - - - -');
    String[] customerNumberParts = incomingContact.CustomerNum__c.split('-');
    String legalEntity = '';
    String customerNumberOnly = '';

    // Get legal entity from the customer number.

    // If the customer number has 3 parts, this means that contains the prefix EMEA
    if (customerNumberParts.size() == 3) {
      // If it comes from EMEA the legal entity will be in the second place
      customerNumberOnly = customerNumberParts[2];
    } else if (customerNumberParts.size() == 2) {
      // If it comes from Spain the legal entity will be in the first place
      customerNumberOnly = customerNumberParts[1];
    } else {
      throw new IntegrationException(
        Label.ParseError + ': invalid customer number.'
      );
    }

    if (incomingContact.LegalEntity__c.equals(Label.GeneralInsurance)) {
      legalEntity = 'GI';
    } else {
      legalEntity = 'Life';
    }

    // Assign record type
    incomingContact.RecordTypeId = incomingContact.Status__c != 'Lead'
      ? SystemUtil.getContactRecordTypeIdByName('Customer' + legalEntity)
      : SystemUtil.getContactRecordTypeIdByName('Lead' + legalEntity);

    // Generate codes to match
    String emailBirthDateLECountryCode = '';
    String emailBirthDateLECode = '';
    String emailBirthDateCode = '';

    if (
      !String.isBlank(incomingContact.Email) &&
      null != incomingContact.Birthdate &&
      !String.isBlank(legalEntity) &&
      !String.isBlank(incomingContact.sourceCountry__c)
    ) {
      emailBirthDateLECountryCode =
        incomingContact.Email +
        String.valueOfGmt(incomingContact.Birthdate) +
        legalEntity +
        incomingContact.sourceCountry__c;
    }
    if (
      !String.isBlank(incomingContact.Email) &&
      null != incomingContact.Birthdate
    ) {
      emailBirthDateLECode =
        incomingContact.Email +
        String.valueOfGmt(incomingContact.Birthdate) +
        legalEntity;
    }

    if (
      !String.isBlank(incomingContact.Email) &&
      null != incomingContact.Birthdate
    ) {
      emailBirthDateCode =
        incomingContact.Email + String.valueOfGmt(incomingContact.Birthdate);
    }

    System.debug(
      '>>> ExternalRequestUtil.mapContacts ' + ExternalRequestUtil.mapContacts
    );
    System.debug(
      '>>> ExternalRequestUtil.recordsToProcess ' +
      ExternalRequestUtil.recordsToProcess
    );
    System.debug(
      '>>> ExternalRequestUtil.actualRequest ' +
      ExternalRequestUtil.actualRequest
    );

    // The contact exist with the same customer number
    if (
      ExternalRequestUtil.mapContacts.containsKey(
        ((Contact) ExternalRequestUtil.recordsToProcess.get(
            ExternalRequestUtil.actualRequest.id
          ))
          .CustomerNum__c
      )
    ) {
      System.debug('>>> Contact found by Customer Number');
      Contact alreadyInSFContact = ExternalRequestUtil.mapContacts.get(
        ((Contact) ExternalRequestUtil.recordsToProcess.get(
            ExternalRequestUtil.actualRequest.id
          ))
          .CustomerNum__c
      );
      // If there is a quote, and the contact is a lead, the relationship between the
      // quote and the contact is set and the contact is updated
      if (quote != null && incomingContact.status__c == 'Lead') {
        // Update the contact
        incomingContact.Id = alreadyInSFContact.Id;
        ExternalRequestUtil.contactsToUpdate.put(
          incomingContact.CustomerNum__c,
          incomingContact
        );

        quote.ContactId__c = alreadyInSFContact.Id;
        quote.AccountId = alreadyInSFContact.AccountId;
      } else if (quote != null && incomingContact.status__c == 'Activo') {
        // If there is a quote, and the contact is not a lead, the relationship between the
        // quote and the contact is set but the contact is NOT updated
        quote.ContactId__c = alreadyInSFContact.Id;
        quote.AccountId = alreadyInSFContact.AccountId;
      } else {
        // If there is no quote, the contact is updated
        // Update the contact
        incomingContact.Id = alreadyInSFContact.Id;
        ExternalRequestUtil.contactsToUpdate.put(
          incomingContact.CustomerNum__c,
          incomingContact
        );
      }

      // The incoming contact comes from EMEA
      if (incomingContact.sourceCountry__c != 'Spain') {
        Account accountItem = new Account();
        accountItem.Name =
          incomingContact.FirstName +
          ' ' +
          incomingContact.LastName;
        accountItem.customerNum_EMEA__c = customerNumberOnly;
        if (
          alreadyInSFContact.Account.customerNum_EMEA__c == customerNumberOnly
        ) {
          ExternalRequestUtil.mastersToUpdateEMEA.put(
            accountItem.CustomerNum_EMEA__c,
            accountItem
          );
        } else {
          accountItem.Id = alreadyInSFContact.AccountId;
          ExternalRequestUtil.mastersToUpdateById.put(
            accountItem.CustomerNum_EMEA__c,
            accountItem
          );
        }
      } else {
        // The incoming contact comes from Spain
        Account accountItem = new Account();
        accountItem.Name =
          incomingContact.FirstName +
          ' ' +
          incomingContact.LastName;
        accountItem.CustomerNum__c = customerNumberOnly;
        if (alreadyInSFContact.Account.CustomerNum__c == customerNumberOnly) {
          ExternalRequestUtil.mastersToUpdate.put(
            accountItem.CustomerNum__c,
            accountItem
          );
        } else {
          accountItem.Id = alreadyInSFContact.AccountId;
          ExternalRequestUtil.mastersToUpdateById.put(
            accountItem.CustomerNum__c,
            accountItem
          );
        }
      }
    } else if (
      ExternalRequestUtil.mapContactsEmailBirthDateLECountry.containsKey(
        emailBirthDateLECountryCode
      )
    ) {
      // If contact exists with a different customer number
      System.debug('>>> Contact found by MC1');
      Contact alreadyInSFContact = ExternalRequestUtil.mapContactsEmailBirthDateLECountry.get(
        emailBirthDateLECountryCode
      );
      if (
        incomingContact.status__c == 'Lead' &&
        alreadyInSFContact.status__c == 'Lead'
      ) {
        // Update the lead but keep the existing Customer Number
        if (
          incomingContact.sourceCountry__c ==
          alreadyInSFContact.sourceCountry__c
        ) {
          incomingContact.Id = alreadyInSFContact.Id;
        } else {
          if (!String.isBlank(incomingContact.MasterPolicyNum__c)) {
            //Asociar partner cuando el cliente es nuevo
            AccountUtil.associatePartner(
              incomingContact,
              ExternalRequestUtil.mapPartners,
              ExternalRequestUtil.contactsToUpdateWithPartner,
              ExternalRequestUtil.partnersToUpdateList,
              ExternalRequestUtil.recordOwner
            );
          }
        }
        incomingContact.CustomerNum__c = alreadyInSFContact.CustomerNum__c;
        ExternalRequestUtil.contactsToUpdate.put(
          incomingContact.CustomerNum__c,
          incomingContact
        );

        if (quote != null) {
          quote.AccountId = alreadyInSFContact.AccountId;
          quote.ContactId__c = alreadyInSFContact.Id;
          if (incomingContact.sourceCountry__c != 'Spain') {
            quote.CustomerNum__c = alreadyInSFContact.Account.CustomerNum_EMEA__c;
          } else {
            quote.CustomerNum__c = alreadyInSFContact.Account.CustomerNum__c;
          }
        }
      } else if (
        incomingContact.status__c == 'Activo' &&
        (alreadyInSFContact.status__c == 'Lead' ||
        alreadyInSFContact.status__c == 'Activo')
      ) {
        incomingContact.AccountId = alreadyInSFContact.AccountId;
        Account accountItem = new Account();
        accountItem.Name =
          incomingContact.FirstName +
          ' ' +
          incomingContact.LastName;
        // The incoming contact comes from EMEA
        if (incomingContact.sourceCountry__c != 'Spain') {
          accountItem.customerNum_EMEA__c = customerNumberOnly;
          // The master account should have the EMEA customer number, since the contact has been found
          // with the same source country
          // Populate the Id field only if the account has the same customer number
          if (
            alreadyInSFContact.Account.customerNum_EMEA__c == customerNumberOnly
          ) {
            ExternalRequestUtil.mastersToUpdateEMEA.put(
              accountItem.CustomerNum_EMEA__c,
              accountItem
            );
          } else {
            accountItem.Id = alreadyInSFContact.AccountId;
            ExternalRequestUtil.mastersToUpdateById.put(
              accountItem.CustomerNum_EMEA__c,
              accountItem
            );
          }
        } else {
          // The incoming contact comes from Spain
          accountItem.CustomerNum__c = customerNumberOnly;
          // The master account should have the EMEA customer number, since the contact has been found
          // with the same source country
          // Populate the Id field only if the account has the same customer number
          if (alreadyInSFContact.Account.CustomerNum__c == customerNumberOnly) {
            ExternalRequestUtil.mastersToUpdate.put(
              accountItem.CustomerNum__c,
              accountItem
            );
          } else {
            accountItem.Id = alreadyInSFContact.AccountId;
            ExternalRequestUtil.mastersToUpdateById.put(
              accountItem.CustomerNum__c,
              accountItem
            );
          }
        }

        // If there is a quote, and the contact is not a lead, the relationship between the
        // quote and the contact is set but the contact is NOT updated
        if (quote != null) {
          //Si se pasa la quote como parametro, solo se relaciona con el cliente, no se actualiza el cliente
          quote.ContactId__c = alreadyInSFContact.Id;
          quote.AccountId = alreadyInSFContact.AccountId;
        } else {
          if (
            incomingContact.sourceCountry__c ==
            alreadyInSFContact.sourceCountry__c
          ) {
            incomingContact.Id = alreadyInSFContact.Id;
          } else {
            if (!String.isBlank(incomingContact.MasterPolicyNum__c)) {
              //Asociar partner cuando el cliente es nuevo
              AccountUtil.associatePartner(
                incomingContact,
                ExternalRequestUtil.mapPartners,
                ExternalRequestUtil.contactsToUpdateWithPartner,
                ExternalRequestUtil.partnersToUpdateList,
                ExternalRequestUtil.recordOwner
              );
            }
          }
          incomingContact.AccountId = alreadyInSFContact.AccountId;
          incomingContact.OwnerId = ExternalRequestUtil.recordOwner.id;
          ExternalRequestUtil.contactsToUpdate.put(
            incomingContact.CustomerNum__c,
            incomingContact
          );
        }
      } else {
        if (quote != null) {
          quote.AccountId = alreadyInSFContact.AccountId;
          quote.ContactId__c = alreadyInSFContact.Id;
          if (incomingContact.sourceCountry__c != 'Spain') {
            quote.CustomerNum__c = alreadyInSFContact.Account.CustomerNum_EMEA__c;
          } else {
            quote.CustomerNum__c = alreadyInSFContact.Account.CustomerNum__c;
          }
        }
      }
    } else if (
      ExternalRequestUtil.mapContactsEmailBirthDateLE.containsKey(
        emailBirthDateLECode
      )
    ) {
      // If the contact exists in another country
      System.debug('>>> Contact found by MC2');
      Contact alreadyInSFContact = ExternalRequestUtil.mapContactsEmailBirthDateLE.get(
        emailBirthDateLECode
      );
      incomingContact.AccountId = alreadyInSFContact.AccountId;
      Account accountItem = new Account();
      accountItem.Name =
        incomingContact.FirstName +
        ' ' +
        incomingContact.LastName;
      // The contact comes from IBA EMEA
      if (incomingContact.sourceCountry__c != 'Spain') {
        // The master account doesn't have the EMEA customer number
        if (String.isBlank(alreadyInSFContact.Account.CustomerNum_EMEA__c)) {
          // The master account is updated
          accountItem.customerNum_EMEA__c = customerNumberOnly;
          accountItem.Id = alreadyInSFContact.AccountId;
          ExternalRequestUtil.mastersToUpdateById.put(
            accountItem.CustomerNum_EMEA__c,
            accountItem
          );
        } else {
          // The master account has an EMEA customer number
          // The contact is a lead
          if (incomingContact.Status__c == 'Lead') {
            incomingContact.CustomerNum__c = alreadyInSFContact.CustomerNum__c;
            // Notice that the master account IS NOT UPDATED (by not putting it in any map)
          } else {
            // The contact is an active customer
            // The master account is updated
            accountItem.customerNum_EMEA__c = customerNumberOnly;
            // Populate the Id field only if the account has the same customer number
            if (
              alreadyInSFContact.Account.customerNum_EMEA__c ==
              customerNumberOnly
            ) {
              ExternalRequestUtil.mastersToUpdateEMEA.put(
                accountItem.CustomerNum_EMEA__c,
                accountItem
              );
            } else {
              accountItem.Id = alreadyInSFContact.AccountId;
              ExternalRequestUtil.mastersToUpdateById.put(
                accountItem.CustomerNum_EMEA__c,
                accountItem
              );
            }
          }
        }
        if (
          incomingContact.sourceCountry__c ==
          alreadyInSFContact.sourceCountry__c
        ) {
          incomingContact.Id = alreadyInSFContact.Id;
        } else {
          if (!String.isBlank(incomingContact.MasterPolicyNum__c)) {
            //Asociar partner cuando el cliente es nuevo
            AccountUtil.associatePartner(
              incomingContact,
              ExternalRequestUtil.mapPartners,
              ExternalRequestUtil.contactsToUpdateWithPartner,
              ExternalRequestUtil.partnersToUpdateList,
              ExternalRequestUtil.recordOwner
            );
          }
        }
        incomingContact.OwnerId = ExternalRequestUtil.recordOwner.id;
        ExternalRequestUtil.contactsToUpdate.put(
          incomingContact.CustomerNum__c,
          incomingContact
        );
      } else {
        // The contact comes from Spain
        // The master account doesn't have the (Spanish) customer number
        if (String.isBlank(alreadyInSFContact.Account.CustomerNum__c)) {
          // The master account is updated
          accountItem.CustomerNum__c = customerNumberOnly;
          accountItem.Id = alreadyInSFContact.AccountId;
          ExternalRequestUtil.mastersToUpdateById.put(
            accountItem.CustomerNum__c,
            accountItem
          );
        } else // The master account has a (Spanish) customer number
        {
          // The incoming contact is a lead
          if (incomingContact.Status__c == 'Lead') {
            incomingContact.CustomerNum__c = alreadyInSFContact.CustomerNum__c;
            // Notice that the master account IS NOT UPDATED (by not putting it in any map)
          } else {
            // The incoming contact is an active customer
            // The master account is updated
            accountItem.CustomerNum__c = customerNumberOnly;
            // Populate the Id field only if the account has the same customer number
            if (
              alreadyInSFContact.Account.CustomerNum__c == customerNumberOnly
            ) {
              ExternalRequestUtil.mastersToUpdate.put(
                accountItem.CustomerNum__c,
                accountItem
              );
            } else {
              accountItem.Id = alreadyInSFContact.AccountId;
              ExternalRequestUtil.mastersToUpdateById.put(
                accountItem.CustomerNum__c,
                accountItem
              );
            }
          }
        }
        if (
          incomingContact.sourceCountry__c ==
          alreadyInSFContact.sourceCountry__c
        ) {
          incomingContact.Id = alreadyInSFContact.Id;
        } else {
          if (!String.isBlank(incomingContact.MasterPolicyNum__c)) {
            //Asociar partner cuando el cliente es nuevo
            AccountUtil.associatePartner(
              incomingContact,
              ExternalRequestUtil.mapPartners,
              ExternalRequestUtil.contactsToUpdateWithPartner,
              ExternalRequestUtil.partnersToUpdateList,
              ExternalRequestUtil.recordOwner
            );
          }
        }
        incomingContact.OwnerId = ExternalRequestUtil.recordOwner.id;
        ExternalRequestUtil.contactsToUpdate.put(
          incomingContact.CustomerNum__c,
          incomingContact
        );
      }

      if (quote != null) {
        Contact contactRef = new Contact(
          CustomerNum__c = incomingContact.CustomerNum__c
        );
        quote.AccountId = alreadyInSFContact.AccountId;
        quote.CustomerNum__c = customerNumberOnly;
        quote.ContactId__r = contactRef;
      }
    } else if (
      ExternalRequestUtil.mapContactsEmailBirthDate.containsKey(
        emailBirthDateCode
      )
    ) {
      // If the contact exists with a different legal entity
      System.debug('>>> Contact found by MC3');
      Contact alreadyInSFContact = ExternalRequestUtil.mapContactsEmailBirthDate.get(
        emailBirthDateCode
      );
      incomingContact.AccountId = alreadyInSFContact.AccountId;
      Account accountItem = new Account();
      accountItem.Name =
        incomingContact.FirstName +
        ' ' +
        incomingContact.LastName;
      // The contact comes from IBA EMEA
      if (incomingContact.sourceCountry__c != 'Spain') {
        // The master account doesn't have the EMEA customer number
        if (String.isBlank(alreadyInSFContact.Account.CustomerNum_EMEA__c)) {
          // The master account is updated
          accountItem.customerNum_EMEA__c = customerNumberOnly;
          accountItem.Id = alreadyInSFContact.AccountId;
          ExternalRequestUtil.mastersToUpdateById.put(
            accountItem.customerNum_EMEA__c,
            accountItem
          );
        } else {
          // The master account has an EMEA customer number
          // The contact is an active customer
          if (incomingContact.Status__c == 'Activo') {
            // The master account is updated
            accountItem.customerNum_EMEA__c = customerNumberOnly;
            // Populate the Id field only if the account has the same customer number
            if (
              alreadyInSFContact.Account.CustomerNum_EMEA__c ==
              customerNumberOnly
            ) {
              ExternalRequestUtil.mastersToUpdateEMEA.put(
                accountItem.CustomerNum_EMEA__c,
                accountItem
              );
            } else {
              accountItem.Id = alreadyInSFContact.AccountId;
              ExternalRequestUtil.mastersToUpdateById.put(
                accountItem.CustomerNum_EMEA__c,
                accountItem
              );
            }
          }
        }

        if (!String.isBlank(incomingContact.MasterPolicyNum__c)) {
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
        ExternalRequestUtil.contactsToUpdate.put(
          incomingContact.CustomerNum__c,
          incomingContact
        );
      } else {
        // The contact comes from Spain
        // The master account doesn't have the (Spanish) customer number
        if (String.isBlank(alreadyInSFContact.Account.CustomerNum__c)) {
          // The master account is updated
          accountItem.CustomerNum__c = customerNumberOnly;
          accountItem.Id = alreadyInSFContact.AccountId;
          ExternalRequestUtil.mastersToUpdateById.put(
            accountItem.CustomerNum__c,
            accountItem
          );
        } else // The master account has a (Spanish) customer number
        {
          // The incoming contact is an active customer
          if (incomingContact.Status__c == 'Activo') {
            // The master account is updated
            accountItem.CustomerNum__c = customerNumberOnly;
            // Populate the Id field only if the account has the same customer number
            if (
              alreadyInSFContact.Account.CustomerNum__c == customerNumberOnly
            ) {
              ExternalRequestUtil.mastersToUpdate.put(
                accountItem.CustomerNum__c,
                accountItem
              );
            } else {
              accountItem.Id = alreadyInSFContact.AccountId;
              ExternalRequestUtil.mastersToUpdateById.put(
                accountItem.CustomerNum__c,
                accountItem
              );
            }
          }
        }

        if (!String.isBlank(incomingContact.MasterPolicyNum__c)) {
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
        ExternalRequestUtil.contactsToUpdate.put(
          incomingContact.CustomerNum__c,
          incomingContact
        );
      }

      if (quote != null) {
        Contact contactRef = new Contact(
          CustomerNum__c = incomingContact.CustomerNum__c
        );
        quote.AccountId = alreadyInSFContact.AccountId;
        quote.CustomerNum__c = customerNumberOnly;
        quote.ContactId__r = contactRef;
      }
    } else {
      // The contact doesn't exist
      System.debug('>>> The contact does not exist');
      Account accountItem = new Account();
      accountItem.name =
        incomingContact.FirstName +
        ' ' +
        incomingContact.LastName;
      accountItem.recordTypeId = SystemUtil.getAccountRecordTypeIdByName(
        Label.Master
      );
      accountItem.ownerId = ExternalRequestUtil.recordOwner.id;
      // The incoming contact comes from EMEA
      if (incomingContact.SourceCountry__c != 'Spain') {
        incomingContact.Account = new Account(
          CustomerNum_EMEA__c = customerNumberOnly
        );
        accountItem.customerNum_EMEA__c = customerNumberOnly;
        ExternalRequestUtil.mastersToUpdateEMEA.put(
          accountItem.CustomerNum_EMEA__c,
          accountItem
        );
        if (quote != null) {
          quote.CustomerNum__c = customerNumberOnly;
          quote.ContactId__r = new Contact(
            CustomerNum__c = incomingContact.CustomerNum__c
          );
          quote.Account = new Account(customerNum_EMEA__c = customerNumberOnly);
        }
      } else {
        // The incoming contact comes from Spain
        incomingContact.Account = new Account(
          CustomerNum__c = customerNumberOnly
        );
        accountItem.CustomerNum__c = customerNumberOnly;
        ExternalRequestUtil.mastersToUpdate.put(
          accountItem.CustomerNum__c,
          accountItem
        );
        if (quote != null) {
          quote.CustomerNum__c = customerNumberOnly;
          quote.ContactId__r = new Contact(
            CustomerNum__c = incomingContact.CustomerNum__c
          );
          quote.Account = new Account(CustomerNum__c = customerNumberOnly);
        }
      }
      incomingContact.OwnerId = ExternalRequestUtil.recordOwner.id;
      ExternalRequestUtil.contactsToUpdate.put(
        incomingContact.CustomerNum__c,
        incomingContact
      );

      if (!String.isBlank(incomingContact.MasterPolicyNum__c)) {
        //Asociar partner cuando el cliente es nuevo
        AccountUtil.associatePartner(
          incomingContact,
          ExternalRequestUtil.mapPartners,
          ExternalRequestUtil.contactsToUpdateWithPartner,
          ExternalRequestUtil.partnersToUpdateList,
          ExternalRequestUtil.recordOwner
        );
      }
    }
    return quote;
  }

  /**
   * Método que actualiza la información común de un cliente de la entidad contraria a través de un trigger (after insert, after update)
   * @author nbizkarra
   * @date 01/04/2020
   **/
  public static void updateCustomerInfo(
    List<Contact> newList,
    Map<Id, Contact> oldMap
  ) {
    System.debug('- - - - - ContactUtil.updateCustomerInfo - - - - -');
    List<Contact> updateContacts = new List<Contact>();
    List<Account> updateMasters = new List<Account>();
    AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();

    if (newList != null) {
      for (Contact cont : newList) {
        //Solo actualizar si es cliente
        if (cont.Status__c == Label.Customer) {
          if (!checkRecursive.SetOfIDs.contains(cont.AccountId)) {
            if (oldMap != null) {
              //cuando es after update, actualizar cuando cambia algún valor común
              if (
                (!String.isBlank(cont.DNI__c) &&
                cont.DNI__c != oldMap.get(cont.Id).DNI__c) ||
                (!String.isBlank(cont.Email) &&
                cont.Email != oldMap.get(cont.Id).Email) ||
                //  (!String.isBlank(cont.MobilePhone) && cont.MobilePhone != oldMap.get(cont.Id).MobilePhone)  ||
                // (cont.Birthdate!= null && cont.Birthdate != oldMap.get(cont.Id).Birthdate)  ||
                (!String.isBlank(cont.FirstName) &&
                cont.FirstName != oldMap.get(cont.Id).FirstName) ||
                (!String.isBlank(cont.LastName) &&
                cont.LastName != oldMap.get(cont.Id).LastName) ||
                //  (!String.isBlank(cont.Nationality__c) && cont.Nationality__c !=oldMap.get(cont.Id).Nationality__c) ||
                //   (!String.isBlank(cont.Gender__c) && cont.Gender__c !=oldMap.get(cont.Id).Gender__c) ||
                (cont.MasterPolicy__c != null &&
                cont.MasterPolicy__c != oldMap.get(cont.Id).MasterPolicy__c)
              ) {
                //Solo los clientes
                List<Account> masters = new List<Account>();
                Account master;
                masters = [
                  SELECT
                    Id,
                    Name,
                    (
                      SELECT Id
                      FROM Contacts
                      WHERE Id != :cont.Id AND Status__c = :Label.Customer
                    )
                  FROM Account
                  WHERE Id = :cont.AccountId
                ];

                if (masters != null) {
                  master = masters.get(0);
                }

                if (master != null && master.Contacts != null) {
                  //Actualizar nombre en el master
                  if (
                    (!String.isBlank(cont.FirstName) &&
                    cont.FirstName != oldMap.get(cont.Id).FirstName) ||
                    (!String.isBlank(cont.LastName) &&
                    cont.LastName != oldMap.get(cont.Id).LastName)
                  ) {
                    master.Name = cont.FirstName + ' ' + cont.LastName;
                    updateMasters.add(master);
                  }

                  for (Contact SFcontact : master.Contacts) {
                    if (!String.isBlank(cont.DNI__c)) {
                      SFcontact.DNI__c = cont.DNI__c;
                    }
                    if (!String.isBlank(cont.Email)) {
                      SFcontact.Email = cont.Email;
                    }
                    //  if(!String.isBlank(cont.MobilePhone)){SFcontact.MobilePhone=cont.MobilePhone;}
                    //  if(cont.Birthdate!= null){SFcontact.Birthdate=cont.Birthdate;}
                    if (!String.isBlank(cont.FirstName)) {
                      SFcontact.FirstName = cont.FirstName;
                    }
                    if (!String.isBlank(cont.LastName)) {
                      SFcontact.LastName = cont.LastName;
                    }
                    //  if(!String.isBlank(cont.Nationality__c)){ SFcontact.Nationality__c=cont.Nationality__c;}
                    //  if(!String.isBlank(cont.Gender__c)){ SFcontact.Gender__c=cont.Gender__c;}

                    //update masterpolicy if it is set to true in custom metadatatype
                    if (adminSetup.SameMasterPolicy__c == true) {
                      if (cont.MasterPolicy__c != null) {
                        SFcontact.MasterPolicy__c = cont.MasterPolicy__c;
                      }
                    }
                    updateContacts.add(SFcontact);
                  }
                }
              }
            } else //cuando es after insert
            {
              List<Account> masters = new List<Account>();
              Account master;
              masters = [
                SELECT
                  id,
                  Name,
                  (
                    SELECT
                      Id,
                      DNI__c,
                      Email,
                      MobilePhone,
                      Birthdate,
                      FirstName,
                      LastName,
                      Nationality__c,
                      Gender__c,
                      MasterPolicy__c
                    FROM Contacts
                    WHERE Id != :cont.Id AND Status__c = :Label.Customer
                  )
                FROM Account
                WHERE Id = :cont.AccountId
              ];

              if (masters != null && masters.size() > 0) {
                master = masters.get(0);
              }

              if (master != null && master.Contacts != null) {
                for (Contact SFcontact : master.Contacts) {
                  if (
                    !String.isBlank(cont.DNI__c) &&
                    !cont.DNI__c.equalsIgnoreCase(SFcontact.DNI__c)
                  ) {
                    SFcontact.DNI__c = cont.DNI__c;
                  }
                  if (
                    !String.isBlank(cont.Email) &&
                    !cont.Email.equalsIgnoreCase(SFcontact.Email)
                  ) {
                    SFcontact.Email = cont.Email;
                  }
                  // if(!String.isBlank(cont.MobilePhone)  && !cont.MobilePhone.equalsIgnoreCase(SFcontact.MobilePhone) ){SFcontact.MobilePhone=cont.MobilePhone;}
                  //  if(cont.Birthdate!= null && cont.Birthdate!=SFcontact.Birthdate){SFcontact.Birthdate=cont.Birthdate;}
                  if (
                    !String.isBlank(cont.FirstName) &&
                    !cont.FirstName.equalsIgnoreCase(SFcontact.FirstName)
                  ) {
                    SFcontact.FirstName = cont.FirstName;
                  }
                  if (
                    !String.isBlank(cont.LastName) &&
                    !cont.LastName.equalsIgnoreCase(SFcontact.LastName)
                  ) {
                    SFcontact.LastName = cont.LastName;
                  }
                  //  if(!String.isBlank(cont.Nationality__c) && !cont.Nationality__c.equalsIgnoreCase(SFcontact.Nationality__c) ){ SFcontact.Nationality__c=cont.Nationality__c;}
                  //  if(!String.isBlank(cont.Gender__c) && !cont.Gender__c.equalsIgnoreCase(SFcontact.Gender__c) ){ SFcontact.Gender__c=cont.Gender__c;}
                  //update masterpolicy if it is set to true in custom metadatatype

                  if (adminSetup.SameMasterPolicy__c == true) {
                    if (
                      cont.MasterPolicy__c != null &&
                      cont.MasterPolicy__c != SFcontact.MasterPolicy__c
                    ) {
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

    if (updateMasters != null && !updateMasters.isEmpty()) {
      upsert updateMasters;
    }

    if (updateContacts != null && !updateContacts.isEmpty()) {
      upsert updateContacts;
    }
  }

  /**
   * Método que setea en la cuenta el número total de contactos. Este campo se usa en un campo fórmula del contacto
   * para determinar si existe el contacto en la entidad legal contraria
   * @author nbizkarra
   * @date 01/04/2020
   */
  public static void SummaryTotalContacts(
    List<Contact> newList,
    Map<Id, Contact> oldMap
  ) {
    System.debug('- - - - - ContactUtil.SummaryTotalContacts - - - - -');
    Set<Id> idSet = new Set<Id>();
    List<Contact> contactOldList = new List<Contact>();
    System.debug(oldMap);
    System.debug(oldMap != null);

    if (newList != null || oldMap != null) {
      if (newList != null) {
        for (Contact cont : newList) {
          //list of IDs of the parent record
          if (cont.AccountId != null) {
            idSet.add(cont.AccountId);
          }
        }
      }
      if (oldMap != null) {
        contactOldList = oldMap.values();
        System.debug(contactOldList);
        for (Contact cont : contactOldList) {
          //list of IDs of the parent record
          if (cont.AccountId != null) {
            idSet.add(cont.AccountId);
          }
        }
      }

      System.debug(idSet);
      if (!idSet.isEmpty()) {
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

        if (responseObject != null && !responseObject.isEmpty()) {
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
  public static void generateHashContactId(
    List<Contact> newList,
    Map<Id, Contact> oldMap
  ) {
    System.debug('- - - - - ContactUtil.generateHashContactId - - - - -');
    List<Contact> updateContacts = new List<Contact>();

    if (newList != null || oldMap != null) {
      for (Contact contacto : newList) {
        if (contacto.Id != null) {
          Contact aux = new Contact(Id = contacto.Id);

          //Se obtiene el hash del id del contacto
          aux.HashedId__c = SystemUtil.generateHash(contacto.Id);
          updateContacts.add(aux);
        }
      }

      //Se actualiza la lista de contactos
      if (updateContacts.size() > 0) {
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
  public static void updateQuoteStep4and5(
    List<Contact> newList,
    Map<Id, Contact> oldMap
  ) {
    System.debug('- - - - - ContactUtil.updateQuoteStep4and5 - - - - -');
    List<Contact> quotes = new List<Contact>();
    Map<ID, Order> quotesToUpdate = new Map<ID, Order>();
    Map<ID, Contact> mapContactos = new Map<ID, Contact>();

    Set<Id> idSet = new Set<Id>();

    if (newList != null && oldMap != null) {
      for (Contact cont : newList) {
        //guardar los ids de las quotes para hacer la query del campo QbLastPage__C
        if (
          cont.LastQuote__c != null &&
          (cont.MailingStreet != oldMap.get(cont.Id).MailingStreet ||
          cont.CreditCard__c != oldMap.get(cont.Id).CreditCard__c)
        ) {
          idSet.add(cont.LastQuote__c);
          mapContactos.put(cont.id, cont);
        }
      }

      Map<ID, Order> MapQuotes = new Map<ID, Order>(
        [SELECT id, QbLastPage__c, Step__c FROM Order WHERE id = :idSet]
      );

      if (MapQuotes != null && mapContactos != null) {
        for (Contact cont : mapContactos.values()) {
          Order quote = MapQuotes.get(cont.LastQuote__c);
          if (quote.QbLastPage__c != null) {
            //Si está en el step 4
            if (
              quote.QbLastPage__c.equalsIgnoreCase('elige tu protección') ||
              quote.QbLastPage__c.equalsIgnoreCase('quote configuration')
            ) {
              //Si solo cambia dirección, ha pasado al step 5
              if (
                cont.MailingStreet != oldMap.get(cont.Id).MailingStreet &&
                cont.CreditCard__c == oldMap.get(cont.Id).CreditCard__c
              ) {
                quote.Step__c = 'Step5';
                quotesToUpdate.put(quote.id, quote);
              } else if (
                cont.CreditCard__c != oldMap.get(cont.Id).CreditCard__c
              ) {
                quote.Step__c = 'Step6';
                quotesToUpdate.put(quote.id, quote);
              }
            }
          }
        }

        //Update step in the quotes
        if (quotesToUpdate != null && !quotesToUpdate.isEmpty()) {
          update quotesToUpdate.values();
        }
      }
    }
  }
}
