/**
 * Process all the offers whose AccountId has changed from a Lead account to another Lead and merge the accounts.
 * Because Marketing Cloud has the Lead Account Id, in the merge, the master will be the Lead Account so that that ID
 * will prevail.
 * 
 * @author nts (agonzalezisasi)
 * @date 02/02/2021
 * change aberuete- 21/04/2023 - Refactorizar clase
 **/

global class Batch_MergeLeadsWithClients implements Database.Batchable<sObject>, Database.Stateful, Schedulable
{
    private static final string CLASS_NAME = 'Batch_MergeLeadsWithClients';
    private static final string ERROR_NO_LEAD_RT_FOUND = 'The ID of the PersonAccount.Lead RecordType could not be found.';
    @testvisible
    private static final string ERROR_SCOPE_TOO_BIG = 'The batch can only process 1 Offer at a time!';
    @testvisible
    private static final string LEAD_RECORDTYPE_DEVELOPERNAME = 'Lead';
    private static final string CONTACT_RECORDTYPE_DEVELOPERNAME = 'Contact';
    private static final string ACCOUNT_NAME = 'Account';
    private static final string PERSON_ACCOUNT_FIELD_EXTENSION = '__pc'; // lowercase
    private static final string PERSON_ACCOUNT_LASTNAME = 'lastname'; // lowercase
    private static final string PERSON_ACCOUNT_FIRSTNAME = 'firstname'; // lowercase
    private static final string PERSON_ACCOUNT_SALUTATION = 'salutation'; // lowercase
    private static final string ACCOUNT_FIELD_NAME = 'name'; // lowercase

    private static final string SETTINGS_LEAD_FIELDS_TO_KEEP = 'BatchMergeLeadsLeadFields';

    
    private String query;
    private Boolean isErrorScopeToBig;
    
    private List<string> PersonalAccounts;
    private Id LeadRecordTypeid;
    @testvisible
    private List<string> fieldsToMergePerson;
    @testvisible
    private List<string> fieldsToMergeNotPerson;
    private List<string> LeadFieldsToKeep;

    // Account related childs to be update to the master account before the merge. Inlcuding the parent field
    private static final Map<String, String> mapRelatedObjects = new Map<String, String> {
        'ContactPointEmails' => 'ParentId',
        'ContactPointPhones' => 'ParentId',
        'ContactPointAddresses' => 'ParentId'
    };
    

    global Batch_MergeLeadsWithClients()
    {
        
        // 0. Initialize
        // NormalAccounts = new List<string>();
        PersonalAccounts = new List<string>();
        fieldsToMergePerson = new List<string>();
        fieldsToMergeNotPerson = new List<String>();
        isErrorScopeToBig = false;

        LeadFieldsToKeep = new List<string>();
        List<AdminSetupParameter__mdt> settings = [
            SELECT KeyName__c, Value__c FROM AdminSetupParameter__mdt WHERE KeyName__c = :SETTINGS_LEAD_FIELDS_TO_KEEP
        ];
        if( !settings.isEmpty() ) {
            LeadFieldsToKeep = settings[0].Value__c.split(',');
        }

        // 1. Get the list of account fields to merge for each type (person/normal)
        getAccountFieldsToMergeForEachType(); 

        // 2. Get the list of record types of the Account
        List<RecordType> recordTypes = [
            SELECT Id, Name, DeveloperName, IsPersonType
                FROM recordtype
                WHERE SobjectType = :ACCOUNT_NAME
        ];

        // for each recordtype
        for(Integer i=0,j=recordTypes.size();i<j;i++) {
            // if is
            if( recordTypes[i].IsPersonType ) { // Personal Account
                PersonalAccounts.add(recordTypes[i].DeveloperName);
            }

            // Get the Lead Id
            if( recordTypes[i].DeveloperName == LEAD_RECORDTYPE_DEVELOPERNAME ) {
                LeadRecordTypeid = recordTypes[i].Id;
            }
        }

        if( LeadRecordTypeid == null ) 
            throw new MergeLeadsException(ERROR_NO_LEAD_RT_FOUND);
        
    }

    global Batch_MergeLeadsWithClients(String p_query)
    {
        this();

        if ( String.isNotBlank(p_query) ) {
            query = p_query;
        }
        
    }

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        if ( String.isBlank(query) ) {
            query = 'SELECT Id, AccountId, OldAccountId__c, Account.RecordType.DeveloperName FROM Opportunity WHERE AccountId != null AND OldAccountId__c != null';
        }

        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext sc)
    {
        Database.executeBatch(new Batch_MergeLeadsWithClients(query), 1);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        if ( scope != null && scope.size() == 1 ) 
        {
            List<Opportunity> offers = (List<Opportunity>) scope;

            if( offers[0].AccountId != offers[0].OldAccountId__c ) 
            {
                // Get the lead account and other accounts ids from the offer
                ID offerOldAccountId = offers[0].OldAccountId__c;

                // Get the fields to merge por person acccount
                List<String> fieldsToMerge = fieldsToMergePerson;
                Boolean isPersonAccount = true;
                // Check if is not a person account to change the fields to merge
                if( !PersonalAccounts.contains( offers[0].Account.RecordType.DeveloperName ) ) 
                { // Normal Account
                    isPersonAccount = false;
                    fieldsToMerge = fieldsToMergeNotPerson;
                }

                // Get the Lead Account query
                String leadQuery = 'SELECT ' + String.join(fieldsToMerge, ',') + ' FROM Account';
                leadQuery += ' WHERE Id = \'' + offerOldAccountId + '\' AND RecordTypeId = \'' + LeadRecordTypeid + '\'';

                // Get the Lead account
                List<Account> leadAccounts = (List<Account>) Database.query(leadQuery);

                Savepoint sp = Database.setSavepoint();
                try 
                {
                    //Merge Account if leadAccounts not empty
                    iflistLeadAccountsNotEmptyMergeAccount (leadAccounts,offers, fieldsToMerge, isPersonAccount);
                   
                    // Finally update the offer to clear the field OldAccountId__c 
                    update new Opportunity(
                        Id= offers[0].Id,
                        OldAccountId__c= null
                    ); //! 1 DML 
                } 
                catch( Exception ex ) 
                {
                    Database.rollback(sp); 
                    ErrorLogUtil.commitError(ex, CLASS_NAME, offers[0].Id);
                } 
            }
        } 
        else 
        {
            isErrorScopeToBig = true;
        }
    }

    global void finish(Database.BatchableContext bc)
    {
        if( isErrorScopeToBig )
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, ERROR_SCOPE_TOO_BIG, CLASS_NAME);
    }

    /**
    * Método que obtiene los campos que deben mergearse del objeto account dependiendo del tipo de cuenta
    * @author aberuete
    * @date 21/04/2023
    **/
    @testvisible
    private void getAccountFieldsToMergeForEachType()
    {
        SObjectType accountType = Schema.getGlobalDescribe().get(ACCOUNT_NAME);
        Map<String, Schema.SObjectField> mfields = accountType.getDescribe().fields.getMap();

        for(String key: mfields.keySet() ) 
        {
            if( mfields.get(key).getDescribe().isUpdateable() || mfields.get(key).getDescribe().isCreateable() ) 
            {
                // Person Account
                if( !key.equalsIgnoreCase(ACCOUNT_FIELD_NAME)) 
                {
                    fieldsToMergePerson.add(key);
                }

                // Normal Account
                if( !key.endsWithIgnoreCase(PERSON_ACCOUNT_FIELD_EXTENSION) && !key.equalsIgnoreCase(PERSON_ACCOUNT_LASTNAME) && 
                    !key.equalsIgnoreCase(PERSON_ACCOUNT_FIRSTNAME) && !key.equalsIgnoreCase(PERSON_ACCOUNT_SALUTATION)) 
                {
                    fieldsToMergeNotPerson.add(key);
                }
            }
        }
    }

     /**
    * Método que convierte la cuenta lead en una cuenta normal y actualiza los contactos asociados a la cuenta
    * @author aberuete
    * @date 21/04/2023
    * @param Boolean isPersonAccount: booleano que indica si la cuenta es de tipo person account
    * @param Account leadAccount : cuenta a mergear
    * @param Account account
    **/
    @testvisible
    private void ifNotPersonAccountConvertLeadAccountAndUpdateContacts(Boolean isPersonAccount,Account leadAccount, Account account)
    {
        if( !isPersonAccount ) 
        {
            // Convert the lead account into a normal account
            Account leadConversion = new Account(
                Id= leadAccount.Id,
                RecordTypeId= account.RecordTypeId
            );
            update leadConversion;  //! 1 DML 

            // On testing, after the update, for some reason the contact is not found...
            // After changing to normal account, update the contact of the lead with the RecordType and LegalEntity                                
            List<Contact> leadContacts = [
                SELECT Id, RecordTypeId, LegalEntity__c FROM Contact
                WHERE AccountId = :leadAccount.Id AND RecordTypeId = null
            ];

            String rtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(CONTACT_RECORDTYPE_DEVELOPERNAME).getRecordTypeId();
            if( !leadContacts.isEmpty() ) 
            {                                    
                leadContacts[0].RecordTypeId = rtId;
                leadContacts[0].LegalEntity__c = account.LegalEntity__c;

                update leadContacts[0]; //! 1 DML
            }
        }
    }

     /**
    * Método que actualiza los contactPoints asociados a la cuenta y los asocia a la lead account
    * @author aberuete
    * @date 21/04/2023
    * @param Account leadAccount : cuenta a mergear
    * @param Account account
    **/
    @testvisible
    private void updateContactPoints (Account account, Account leadAccount)
    {
        List<SObject> contactPoints = new List<SObject>();
        for(String s: mapRelatedObjects.keySet()) 
        {
            if (account.getSObjects(s) != null && !account.getSObjects(s).isEmpty())
            {
                contactPoints.addAll(account.getSObjects(s));
            }
            if( contactPoints != null && !contactPoints.isEmpty() ) 
            {
                for( SObject o: contactPoints ) 
                {
                    o.put(mapRelatedObjects.get(s), leadAccount.Id);                                        
                }
            }
        }
        update contactPoints; //! 3 DML. One per ContactPoint (email, phone, address)  
    }

     /**
    * Método que actualiza los campos a mergear
    * @author aberuete
    * @date 21/04/2023
    * @param List<String> fieldsToMerge : lista campos a mergear
    * @param Account leadAccount : cuenta a mergear
    * @param Account account
    **/
    @testvisible
    private Account mergeAllFieldsFromAccountToLeadAccount (List<String> fieldsToMerge, Account account, Account leadAccount )
    {
        Account leadClone = leadAccount.clone(true,false,false,false);

        // merge all the fields from the other account to the lead
        for(String fieldName: fieldsToMerge) 
        {
            if( account.get(fieldName) != null ) 
            {
                leadAccount.put(fieldName, account.get(fieldName));
            }
        }

        // keep the original fields of the lead
        if( LeadFieldsToKeep != null && !LeadFieldsToKeep.isEmpty() ) 
        {
            for(String fieldName: LeadFieldsToKeep) 
            {
                if( leadClone.get(fieldName) != null ) 
                {
                    leadAccount.put(fieldName, leadClone.get(fieldName));
                }
            }
        }
        return leadAccount;
    }

    /**
    * Método que obtiene una query
    * @author aberuete
    * @date 21/04/2023
    * @param List<Opportunity> offers : Lista de oportunidades
    * @param List<String> fieldsToMerge : Lista de campos a mergear
    **/
    @testvisible
    private String getQueryAccountFromOfferAccount (List<Opportunity> offers, List<String> fieldsToMerge )
    {
        ID offerAccountId = offers[0].AccountId;

        String accountQuery = 'SELECT ' + String.join(fieldsToMerge, ',');
        // fix: Get the ContactPoints of the account to reparent them before merging
        for( String s: mapRelatedObjects.keySet() ) 
        {
            accountQuery += ',(SELECT Id, ' + mapRelatedObjects.get(s) + ' FROM ' + s + ')';
        }
        accountQuery += ' FROM Account';
        accountQuery += ' WHERE Id = \'' + offerAccountId + '\'';
        return accountQuery;
    }

    /**
    * Método que mergea la cuenta lead account 
    * @author aberuete
    * @date 21/04/2023
    * @param List<Account> leadAccounts: lista de cuentas a mergear
    * @param List<Opportunity> offers : Lista de oportunidades
    * @param List<String> fieldsToMerge : Lista de campos a mergear
    * @param Boolean isPersonAccount : booleano que indica si es una cuenta de tipo person account
    **/
    @testvisible
    private void iflistLeadAccountsNotEmptyMergeAccount (List<Account> leadAccounts,List<Opportunity> offers, List<String> fieldsToMerge, Boolean isPersonAccount)
    {
        if( !leadAccounts.isEmpty() ) 
        { // Is a Lead => merge
            // Get the lead account
            Account leadAccount = leadAccounts[0];
            // Get the query for the other account
            String accountQuery = getQueryAccountFromOfferAccount (offers, fieldsToMerge );

            // Get the other account
            List<Account> accounts = (List<Account>) Database.query(accountQuery);
            if( !accounts.isEmpty() ) 
            { // should exist
                Account account = accounts[0];

                //Merge all the fields from the other account to the lead
                leadAccount = mergeAllFieldsFromAccountToLeadAccount (fieldsToMerge, account, leadAccount);

                ifNotPersonAccountConvertLeadAccountAndUpdateContacts(isPersonAccount, leadAccount, account);

                // Fix: re-parent the contact points. For some reason the merge does not do it
                updateContactPoints (account, leadAccount);

                // Do the merge
                merge leadAccount account; //! 1 DML 
            }
        }  
    }

    private class MergeLeadsException extends Exception {}

}