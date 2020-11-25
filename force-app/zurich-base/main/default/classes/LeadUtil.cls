/**
**
* @author nbizkarra
* @date 16/11/2020
*/
public class LeadUtil
{
    private static final String RECORDTYPE_LEAD_GI = 'LeadGI';
    private static final String RECORDTYPE_LEAD_LIFE = 'LeadLife';
    private static final String LEAD_SOURCE_KLINC = 'Klinc';
    private static final String CONTACT_STATUS_LEAD = 'Lead';

    public static Map<String, List<Contact>> mapContacts;
    public static Map<String,Account> mastersToCreate;
    public static List<Contact> contactsToCreate;
    public static Map<String,Contact> contactsToUpdate;
   /**
     * Método que procesa leads (subscribers) creados desde web-to-lead
     * @author nbizkarra
     * @date 16/11/2020
     **/
    public static void NewSubscribers(List<Lead> subscribers)
    {
        System.debug('[NewSubscribers] INIT');

        Set<String> emailsToSearch = new Set<String>();
        mapContacts = new Map<String, List<Contact>>();
        User recordOwner = SystemUtil.recordOwnerSelector();
        mastersToCreate = new Map<String,Account>();
        contactsToCreate = new List<Contact>();
        contactsToUpdate = new Map<String,Contact>();

        for(Lead subs : subscribers) {
            emailsToSearch.add(subs.email);
        }
        
        // get the list of contacts asociated to each lead by email
        mapContacts = SystemUtil.contactsSelectorEmail(emailsToSearch);

        // for each lead....
        for(Lead subscriber: subscribers){
            // get the list of contacts
            List<Contact> contactlist = mapContacts.get(subscriber.Email);

            if ( contactlist == null ) { // ---------------------------------------------------------------- NO CONTACTS
                System.debug('>>> The contact does not exist: ' + contactlist);

                // Master (account) creation
                Account accountItem = new Account();
                accountItem.name = subscriber.FirstName + ' ' + subscriber.LastName;
                accountItem.recordTypeId = SystemUtil.getAccountRecordTypeIdByName( Label.Master );
                accountItem.ownerId = recordOwner.id;
                mastersToCreate.put(subscriber.Email, accountItem);
                
                // Contact creation
                if(subscriber.CheckGI__c == true) {
                    contactsToCreate.add(createSubscriberRecord(
                        Label.GeneralInsurance, RECORDTYPE_LEAD_GI, subscriber, recordOwner
                    ));
                }

                if(subscriber.CheckLife__c == true) {
                    contactsToCreate.add(
                        createSubscriberRecord(
                            Label.LifeInsurance, RECORDTYPE_LEAD_LIFE, subscriber, recordOwner
                    ));
                }
            } else { //-------------------------------------------------------------------------------------- CONTACTS EXISTS
                // There are contacts in Salesforce with subscriber's email
                System.debug('>>> The contact exists: ' + contactlist);

                // If LeadSource is Klinc the partner field of the contact must be empty
                String partner = (subscriber.LeadSource == LEAD_SOURCE_KLINC ? null: subscriber.LeadSource);

                Boolean GI_found = false;
                Boolean Life_found = false;

                // Loop through all the contacts to find contact with same LE, Country and Partner
                for(Contact contact: contactlist){
                    if( contact.SourceCountry__c == subscriber.Country && contact.Partner__c == partner ) {
                        //GI
                        if( subscriber.CheckGI__c == true && contact.LegalEntity__c == Label.GeneralInsurance ) {
                            // System.debug('>>> Subscriber GI Contact found: ' + contact);

                            contact.HasOptedOutOfEmail = false;
                            contact.IsSubscriber__c = true; 
                            contactsToUpdate.put(contact.CustomerNum__c, contact);
                            GI_found = true;
                        }


                        //Life
                        if( subscriber.CheckLife__c == true && contact.LegalEntity__c == Label.LifeInsurance ) {
                            // System.debug('>>> Subscriber Life Contact found: ' + contact);

                            contact.HasOptedOutOfEmail = false;
                            contact.IsSubscriber__c = true; 
                            contactsToUpdate.put(contact.CustomerNum__c, contact);
                            Life_found = true;
                        }
                    }
                }

                // System.debug('>>> CheckGI__c == true && GI_found == false: ' + (subscriber.CheckGI__c == true && GI_found == false));
                // System.debug('>>> CheckLife__c == true && Life_found == false : ' + (subscriber.CheckLife__c == true && Life_found == false));

                if( (subscriber.CheckGI__c == true && GI_found == false) || (subscriber.CheckLife__c == true && Life_found == false)) {

                    Map<String,Contact> mapExistingMasters = new Map<String,Contact>();
                    Map<String,Contact> mapCustomers = new Map<String,Contact>();
                    Map<String,Contact> mapLeads = new Map<String,Contact>();
                    Contact accountId;

                    //Master to associate new contacts                        
                    for( Contact contact : contactlist) {
                        mapExistingMasters.put(contact.AccountId, contact);
                    }

                    // System.debug('>>> mapExistingMasters size : ' + mapExistingMasters.size() + mapExistingMasters);

                    if(mapExistingMasters.size() == 1) { //------------------- ONLY 1 MASTER
                        accountId = mapExistingMasters.values().get(0);
                    }else { //------------------------------------------------ MORE THAN 1 MASTER If there are more than 1 account to associate
                        for (Contact contact : contactlist) {
                            if(contact.Status__c == CONTACT_STATUS_LEAD) {
                                mapLeads.put(contact.AccountId, contact);
                            } else {
                                mapCustomers.put(contact.AccountId, contact);
                            }
                        }

                        //Associate to the master whose related contact is a customer
                        if (mapCustomers != null && !mapCustomers.isEmpty()) {

                            // System.debug('>>> Relate to customer : ' + mapCustomers.values().get(0));
                            
                            accountId = mapCustomers.values().get(0);

                        }else { //Is all of the masters are related to leads, associate to the first one

                            // System.debug('>>> Relate to first lead : ' + mapLeads.values().get(0));
                            
                            accountId = mapLeads.values().get(0);
                        }

                    }

                    // GI: No contact with same LE, Country and Partner found
                    if( subscriber.CheckGI__c == true && GI_found == false){

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
                    if( subscriber.CheckLife__c == true && Life_found == false){

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
        if (mastersToCreate != null && !mastersToCreate.isEmpty()) {
            insert mastersToCreate.values();
        }

        if (contactsToCreate != null && !contactsToCreate.isEmpty()) {
            for(Contact cont: contactsToCreate){

                if(mastersToCreate.containsKey(cont.Email)){

                    Account master = mastersToCreate.get(cont.Email);
                    cont.AccountId = master.id;
                }
            }

            insert contactsToCreate;
        }

        if (contactsToUpdate != null && !contactsToUpdate.isEmpty()) {
            upsert contactsToUpdate.values();
        }
    }

    /**
     * Método que crea el registro de contacto con los campos de subscribers
     * @author nbizkarra
     * @date 17/11/2020
     **/
    public static Contact createSubscriberRecord(String legalEntity, String recordTypeName, Lead Subscriber, User RecordOwner){

        Contact contact = new Contact();
        contact.recordTypeId = SystemUtil.getContactRecordTypeIdByName(recordTypeName);       
        contact.FirstName = Subscriber.FirstName;
        contact.LastName = Subscriber.LastName;
        contact.Status__c = CONTACT_STATUS_LEAD;
        contact.SourceCountry__c = Subscriber.Country;
        contact.Email = Subscriber.Email;
        contact.IsSubscriber__c = true;
        contact.OwnerId = RecordOwner.id;
        contact.LegalEntity__c = legalEntity;

        if (Subscriber.LeadSource != LEAD_SOURCE_KLINC) {
            contact.Partner__c = Subscriber.LeadSource;
        }

        return contact;
    }
}