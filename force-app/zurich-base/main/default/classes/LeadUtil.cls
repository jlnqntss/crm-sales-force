/**
**
* @author nbizkarra
* @date 16/11/2020
*/
public with sharing class LeadUtil
{
    private static final String RECORDTYPE_LEAD_GI = 'LeadGI';
    private static final String RECORDTYPE_LEAD_LIFE = 'LeadLife';
    private static final String LEAD_SOURCE_KLINC = 'Klinc';
    private static final String CONTACT_STATUS_LEAD = 'Lead';

    public static Map<String, List<Contact> > mapContacts;
    public static Map<String,Account> mastersToCreate;
    public static List<Contact> contactsToCreate;
    public static Map<String,Contact> contactsToUpdate;
    /**
     * Método que procesa leads (subscribers) creados desde web-to-lead
     * @author nbizkarra
     * @date 16/11/2020
     **/
    public static void newSubscribers(List<Lead> subscribers)
    {
        

        Set<String> emailsToSearch = new Set<String>();
        mapContacts = new Map<String, List<Contact> >();
        User recordOwner = SystemUtil.recordOwnerSelector();
        mastersToCreate = new Map<String,Account>();
        contactsToCreate = new List<Contact>();
        contactsToUpdate = new Map<String,Contact>();

        for(Lead subs : subscribers)
        {
            emailsToSearch.add(subs.email);
        }

        // get the list of contacts asociated to each lead by email
        mapContacts = SystemUtil.contactsSelectorEmail(emailsToSearch);

        // for each lead....
        for(Lead subscriber: subscribers)
        {
            // get the list of contacts
            List<Contact> contactlist = mapContacts.get(subscriber.Email);

            if ( contactlist == null )   // ---------------------------------------------------------------- NO CONTACTS
            {
                

                // Master (account) creation
                Account accountItem = new Account();
                accountItem.name = subscriber.FirstName + ' ' + subscriber.LastName;
                accountItem.recordTypeId = SystemUtil.getAccountRecordTypeIdByName( Label.Master );
                accountItem.ownerId = recordOwner.id;
                mastersToCreate.put(subscriber.Email, accountItem);

                // Contact creation
                if(subscriber.CheckGI__c == true)
                {
                    contactsToCreate.add( createSubscriberRecord(
                                              Label.GeneralInsurance, RECORDTYPE_LEAD_GI, subscriber, recordOwner
                                              ) );
                }

                if(subscriber.CheckLife__c == true)
                {
                    contactsToCreate.add(
                        createSubscriberRecord(
                            Label.LifeInsurance, RECORDTYPE_LEAD_LIFE, subscriber, recordOwner
                            ) );
                }
            }
            else     //-------------------------------------------------------------------------------------- CONTACTS EXISTS
            {   // There are contacts in Salesforce with subscriber's email
                

                // If LeadSource is Klinc the partner field of the contact must be empty
                String partner = (subscriber.LeadSource == LEAD_SOURCE_KLINC ? null : subscriber.LeadSource);

                Boolean gi_found = false;
                Boolean life_found = false;

                // Loop through all the contacts to find contact with same LE, Country and Partner
                for(Contact contact: contactlist)
                {
                    if( contact.SourceCountry__c == subscriber.Country && contact.Partner__c == partner )
                    {
                        //GI
                        if( subscriber.CheckGI__c == true && contact.LegalEntity__c == Label.GeneralInsurance )
                        {
                            

                            contact.HasOptedOutOfEmail = false;
                            contact.IsSubscriber__c = true;
                            // nts (nbizkarra) - 01/Feb/2021 - Actualizar el nombre y apellido del contacto si es nulo o "Unknown"
                            if( String.isNotBlank(subscriber.FirstName) && (String.isBlank(contact.FirstName) || contact.FirstName.equalsIgnoreCase('Unknown') ) ){

                                contact.FirstName = subscriber.FirstName;
                            }
                            if( String.isNotBlank(subscriber.LastName) && (String.isBlank(contact.LastName) || contact.LastName.equalsIgnoreCase('Unknown') )){
                                
                                contact.LastName = subscriber.LastName;
                            }
                            
                            contactsToUpdate.put(contact.CustomerNum__c, contact);
                            gi_found = true;
                        }


                        //Life
                        if( subscriber.CheckLife__c == true && contact.LegalEntity__c == Label.LifeInsurance )
                        {
                            

                            contact.HasOptedOutOfEmail = false;
                            contact.IsSubscriber__c = true;
                             // nts (nbizkarra) - 01/Feb/2021 - Actualizar el nombre y apellido del contacto si es nulo o "Unknown"
                             if( String.isNotBlank(subscriber.FirstName) && (String.isBlank(contact.FirstName) || contact.FirstName.equalsIgnoreCase('Unknown') ) ){

                                contact.FirstName = subscriber.FirstName;
                            }
                            if( String.isNotBlank(subscriber.LastName) && ( String.isBlank(contact.LastName) || contact.LastName.equalsIgnoreCase('Unknown') )){
                                
                                contact.LastName = subscriber.LastName;
                            }
                            contactsToUpdate.put(contact.CustomerNum__c, contact);
                            life_found = true;
                        }
                    }
                }

                
                

                if( (subscriber.CheckGI__c == true && gi_found == false) || (subscriber.CheckLife__c == true && life_found == false) )
                {

                    Map<String,Contact> mapExistingMasters = new Map<String,Contact>();
                    Map<String,Contact> mapCustomers = new Map<String,Contact>();
                    Map<String,Contact> mapLeads = new Map<String,Contact>();
                    Contact accountId;

                    //Master to associate new contacts
                    for( Contact contact : contactlist)
                    {
                        mapExistingMasters.put(contact.AccountId, contact);
                    }

                    

                    if(mapExistingMasters.size() == 1)   //------------------- ONLY 1 MASTER
                    {
                        accountId = mapExistingMasters.values().get(0);
                    }
                    else    //------------------------------------------------ MORE THAN 1 MASTER If there are more than 1 account to associate
                    {
                        for (Contact contact : contactlist)
                        {
                            if(contact.Status__c == CONTACT_STATUS_LEAD)
                            {
                                mapLeads.put(contact.AccountId, contact);
                            }
                            else
                            {
                                mapCustomers.put(contact.AccountId, contact);
                            }
                        }

                        //Associate to the master whose related contact is a customer
                        if ( mapCustomers != null && !mapCustomers.isEmpty() )
                        {

                            

                            accountId = mapCustomers.values().get(0);

                        }
                        else    //Is all of the masters are related to leads, associate to the first one

                        {   

                            accountId = mapLeads.values().get(0);
                        }

                    }

                    // GI: No contact with same LE, Country and Partner found
                    if( subscriber.CheckGI__c == true && gi_found == false)
                    {

                        //Contact creation
                        Contact contactGI = new Contact();
                        contactGI = createSubscriberRecord(
                            Label.GeneralInsurance, RECORDTYPE_LEAD_GI, subscriber, recordOwner
                            );

                        //Asociate to master
                        contactGI.AccountId = accountId.AccountId;
                        contactsToCreate.add(contactGI);

                    }

                    // LIFE: No contact with same LE, Country and Partner found
                    if( subscriber.CheckLife__c == true && life_found == false)
                    {

                        //Contact creation
                        Contact contactLife = new Contact();
                        contactLife = createSubscriberRecord(
                            Label.LifeInsurance, RECORDTYPE_LEAD_LIFE, subscriber, recordOwner
                            );

                        //Asociate to master
                        contactLife.AccountId = accountId.AccountId;
                        contactsToCreate.add(contactLife);
                    }
                }
            }

        }

        //---------------------------------------------------------------------------
        // Upsert objects
        if ( mastersToCreate != null && !mastersToCreate.isEmpty() )
        {
            insert mastersToCreate.values();
        }

        if ( contactsToCreate != null && !contactsToCreate.isEmpty() )
        {
            for(Contact cont: contactsToCreate)
            {

                if( mastersToCreate.containsKey(cont.Email) )
                {

                    Account master = mastersToCreate.get(cont.Email);
                    cont.AccountId = master.id;
                }
            }

            insert contactsToCreate;
        }

        if ( contactsToUpdate != null && !contactsToUpdate.isEmpty() )
        {
            upsert contactsToUpdate.values();
        }
    }

    /**
     * Método que crea el registro de contacto con los campos de subscribers
     * @author nbizkarra
     * @date 17/11/2020
     **/
    public static Contact createSubscriberRecord(String legalEntity, String recordTypeName, Lead subscriber, User recordOwner)
    {

        Contact contact = new Contact();
        contact.recordTypeId = SystemUtil.getContactRecordTypeIdByName(recordTypeName);
        contact.FirstName = subscriber.FirstName;
        contact.LastName = subscriber.LastName;
        contact.Status__c = CONTACT_STATUS_LEAD;
        contact.SourceCountry__c = subscriber.Country;
        contact.Email = subscriber.Email;
        contact.IsSubscriber__c = true;
        contact.OwnerId = recordOwner.id;
        contact.LegalEntity__c = legalEntity;

        if (subscriber.LeadSource != LEAD_SOURCE_KLINC)
        {
            contact.Partner__c = subscriber.LeadSource;
        }

        return contact;
    }

    /**
     * Método utilizado por el batch DeleteLeads que elimina o actualiza contactos en función de si está suscrito y no se ha desuscrito
     * @author nbizkarra
     * @date 17/11/2020
     * @change aberuete - Refactorización del método para llevarlo a la clase util 
     **/
    public static void deleteOrUpdateContacs (List<Contact> leads) 
    {
        List<Contact> deleteLeads = new List<Contact>();
        List<Contact> subscribersToUpdate = new List<Contact>();

        for ( Contact lead: leads )
        {
            // nts (nbizkarra) - 17/dic/2020 -  Include Subscribers
            // Si es lead de IBA, subscriber y no está desuscrito se borra toda la información de la tarificación
            // Se mantiene: Nombre, email, isSubscriber, SourceCountry, Legal Entity, Record Type, Partner y Status
            if ( lead.IsSubscriber__c == true && lead.HasOptedOutOfEmail == false)
            {
                lead.Balance__c = null;
                lead.Birthdate = null;
                lead.CNO__c = null;
                lead.CreditCard__c = null;
                lead.CustomerID__c = null;
                lead.CustomerNum__c = null;
                lead.DNI__c = null;
                lead.EmailHash__c = null;
                lead.Gender__c = null;
                lead.Job__c = null;
                lead.JobPosition__c = null;
                lead.MailingCity = null;
                lead.MailingCountry = null;
                lead.MailingPostalCode = null;
                lead.MailingState = null;
                lead.MailingStreet = null;
                lead.MasterPolicy__c = null;
                lead.MasterPolicyDesc__c = null;
                lead.MasterPolicyNum__c = null;
                lead.MobilePhone = null;
                lead.MonthExpiryDate__c = null;
                lead.Nationality__c = null;
                lead.YearExpiryDate__c = null;
                lead.Abandoned_Lead__c = false;

                subscribersToUpdate.add(lead);
            }
            else
            {
                deleteLeads.add(lead);
            }

        }

        if ( deleteLeads != null && !deleteLeads.isEmpty() )
        {
            delete deleteLeads;
        }

        if ( subscribersToUpdate != null && !subscribersToUpdate.isEmpty() )
        {
            update subscribersToUpdate;
        }
    }
}