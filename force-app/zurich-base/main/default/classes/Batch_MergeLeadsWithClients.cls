/**
 * Process all the offers whose AccountId has changed from a Lead account to another Lead and merge the accounts.
 * Because Marketing Cloud has the Lead Account Id, in the merge, the master will be the Lead Account so that that ID
 * will prevail.
 * 
 * @author nts (agonzalezisasi)
 * @date 02/02/2021
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
    private static final string ACCOUNT_FIELD_NAME = 'name'; // lowercase

    private static final string SETTINGS_LEAD_FIELDS_TO_KEEP = 'BatchMergeLeadsLeadFields';

    
    private String query;
    private Boolean isErrorScopeToBig;
    
    private List<string> PersonalAccounts;
    private Id LeadRecordTypeid;
    @testvisible
    private List<string> fieldsToMergePerson;
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
        // System.Debug('----------------- Batch_MergeLeadsWithClients INIT');
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
        // System.Debug('----------------- Lead fields keep');
        // System.Debug(LeadFieldsToKeep);

        // 1. Get the list of account fields to merge for each type (person/normal)
        SObjectType accountType = Schema.getGlobalDescribe().get(ACCOUNT_NAME);
        Map<String, Schema.SObjectField> mfields = accountType.getDescribe().fields.getMap();
        for(String key: mfields.keySet() ) {
            if( mfields.get(key).getDescribe().isUpdateable() || mfields.get(key).getDescribe().isCreateable() ) {
                // Person Account
                if( !key.equalsIgnoreCase(ACCOUNT_FIELD_NAME)) {
                    fieldsToMergePerson.add(key);
                }

                // Normal Account
                if( !key.endsWithIgnoreCase(PERSON_ACCOUNT_FIELD_EXTENSION) && !key.equalsIgnoreCase(PERSON_ACCOUNT_LASTNAME) && 
                    !key.equalsIgnoreCase(PERSON_ACCOUNT_FIRSTNAME) ) {
                    fieldsToMergeNotPerson.add(key);
                }
            }
        }

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

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        if ( String.isBlank(query) ) {
            query = 'SELECT Id, AccountId, OldAccountId__c, Account.RecordType.DeveloperName FROM Opportunity WHERE AccountId != null AND OldAccountId__c != null';
        }

        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext SC)
    {
        Database.executeBatch(new Batch_MergeLeadsWithClients(query), 1);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        if ( scope != null && scope.size() == 1 ) {
            List<Opportunity> offers = (List<Opportunity>) scope;

            if( offers[0].AccountId != offers[0].OldAccountId__c ) {
                // Get the lead account and other accounts ids from the offer
                ID offerAccountId = offers[0].AccountId;
                ID offerOldAccountId = offers[0].OldAccountId__c;

                // Get the fields to merge por person acccount
                List<String> fieldsToMerge = fieldsToMergePerson;
                Boolean isPersonAccount = true;
                // Check if is not a person account to change the fields to merge
                if( !PersonalAccounts.contains( offers[0].Account.RecordType.DeveloperName ) ) { // Normal Account
                    isPersonAccount = false;
                    fieldsToMerge = fieldsToMergeNotPerson;
                }

                // Get the Lead Account query
                String leadQuery = 'SELECT ' + String.join(fieldsToMerge, ',') + ' FROM Account';
                leadQuery += ' WHERE Id = \'' + offerOldAccountId + '\' AND RecordTypeId = \'' + LeadRecordTypeid + '\'';

                // Get the Lead account
                List<Account> leadAccounts = (List<Account>) Database.query(leadQuery);

                // System.debug('---------------------------- DML limit before: ' + Limits.getDmlStatements());
                Savepoint sp = Database.setSavepoint();
                try {
                    // check if
                    if( !leadAccounts.isEmpty() ) { // Is a Lead => merge
                        // Get the lead account
                        Account leadAccount = leadAccounts[0];

                        // Get the query for the other account
                        String accountQuery = 'SELECT ' + String.join(fieldsToMerge, ',');
                        // fix: Get the ContactPoints of the account to reparent them before merging
                        for( String s: mapRelatedObjects.keySet() ) {
                            accountQuery += ',(SELECT Id, ' + mapRelatedObjects.get(s) + ' FROM ' + s + ')';
                        }
                        accountQuery += ' FROM Account';
                        accountQuery += ' WHERE Id = \'' + offerAccountId + '\'';

                        // Get the other account
                        List<Account> accounts = (List<Account>) Database.query(accountQuery);
                        if( !accounts.isEmpty() ) { // should exist
                            Account account = accounts[0];

                            Account leadClone = leadAccount.clone(true,false,false,false);

                            // merge all the fields from the other account to the lead
                            for(String fieldName: fieldsToMerge) {
                                if( account.get(fieldName) != null ) {
                                    leadAccount.put(fieldName, account.get(fieldName));
                                }
                            }

                            // System.Debug('------------------ Fields to keep');
                            // keep the original fields of the lead
                            if( LeadFieldsToKeep != null && !LeadFieldsToKeep.isEmpty() ) {
                                for(String fieldName: LeadFieldsToKeep) {
                                    if( leadClone.get(fieldName) != null ) {
                                        leadAccount.put(fieldName, leadClone.get(fieldName));
                                    }
                                }
                            }

                            // check if 
                            if( !isPersonAccount ) {
                                // On testing, is found...
                                // List<Contact> cs = [SELECT Id FROM Contact WHERE AccountId = :leadAccount.Id];
                                // System.assertEquals(1, cs.size(),'deberia haber un contacto para el lead');
                                
                                // System.debug('Recordtype NOT PersonAccount');
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
                                String rtId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(CONTACT_RECORDTYPE_DEVELOPERNAME).getRecordTypeId();
                                if( !leadContacts.isEmpty() ) {                                    
                                    leadContacts[0].RecordTypeId = rtId;
                                    leadContacts[0].LegalEntity__c = account.LegalEntity__c;

                                    update leadContacts[0]; //! 1 DML
                                }
                            }

                            // Fix: re-parent the contact points. For some reason the merge does not do it
                            for(String s: mapRelatedObjects.keySet()) {
                                List<SObject> contactPoints = account.getSObjects(s);
                                if( contactPoints != null && !contactPoints.isEmpty() ) {
                                    for( SObject o: contactPoints ) {
                                        o.put(mapRelatedObjects.get(s), leadAccount.Id);
                                        //System.debug(o);
                                    }
                                    update contactPoints; //! 3 DML. One per ContactPoint (email, phone, address)
                                }
                            }
            
                            // Do the merge
                            // System.debug('Merging........');
                            merge leadAccount account; //! 1 DML 
                        }
                    }

                    // Finally update the offer to clear the field OldAccountId__c
                    // System.debug('Updating offer........');
                    update new Opportunity(
                        Id= offers[0].Id,
                        OldAccountId__c= null
                    ); //! 1 DML 

                    // System.debug('---------------------------- dml limit after merge: ' + Limits.getDmlStatements());
                } catch( Exception ex ) {
                    Database.rollback(sp); 
                    // System.Debug('----------------------- Exception');
                    // System.Debug(ex);
                    ErrorLogUtil.commitError(ex, CLASS_NAME, offers[0].Id);
                }

                // System.debug('----------------------------  DML limit after: ' + Limits.getDmlStatements());
            }
        } else {
            isErrorScopeToBig = true;
        }
    }

    global void finish(Database.BatchableContext BC)
    {
        if( isErrorScopeToBig )
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, ERROR_SCOPE_TOO_BIG, CLASS_NAME);
    }

    private class MergeLeadsException extends Exception {}
}