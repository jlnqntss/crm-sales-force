/**
 * Utilitiy methods for the Scope__c object 
 *
 * @author nts (agonzalezisasi)
 * @date 30/11/2020
 */
global without sharing class ScopeUtil
{
    private static final Boolean showDebug = false;

    // Fields to check if there is any change
    private static final List<String> FieldsToCheckChange = new List<String> {
        'PrimaryEmail__c',
        'PrimaryPhone__c',
        'HasOptedOutOfEmail__c'
    };
    //! To be removed in the future
    // Scope__c field (picklist) of Scope__c object
    private static final List<String> ScopesToConsider = new List<String> {'ZE','ZEO'};

    // List of Scopes to change the Contactable field
    private List<Scope__c> scopesToSetContatable;
    // List of accounts of the changed Scopes
    private List<Account> accountsToCheck;
    // List of accounts to update because of the scopes
    public List<Account> accountsToUpdate;
    //public List<Contact> contactsToUpdate;

    /**
     * Select the scopes that has a change in the following fields:
     *  - PrimaryEmail__c
     *  - HasOptedOutOfEmail__c
     *  - PrimaryPhone__c
     *
     * @author nts (agonzalezisasi)
     * @date 30/11/2020
     */
    public void bulkContactableBefore( List<Scope__c> newList, Map<Id, Scope__c> oldMap )
    {
        System.debug('- - - - - ScopeUtil.bulkContactableBefore - - - - -');
        if( newList != null ) {
            this.scopesToSetContatable = new List<Scope__c>();            
            
            // for each scope...
            for(Integer i=0, j=newList.Size(); i < j; i++) {
                Scope__c s_new = newList[i];

                // Check if is valid scope 
                //! To be removed in the future
                if( ScopesToConsider.contains(s_new.Scope__c) ) {
                    Boolean addScope = false;
                    if( oldMap == null ) { //--------------------------------------------- INSERT
                        addScope = true;
                    } else { //----------------------------------------------------------- UPDATE
                        Scope__c s_old = oldMap.get(s_new.Id);

                        // If any of the following fields has changed
                        Integer x = 0;
                        while( !addScope && x<FieldsToCheckChange.size() ) {
                            if( s_new.get(FieldsToCheckChange[x]) != s_old.get(FieldsToCheckChange[x]) ) {
                                addScope = true;
                            }
                            x++;
                        }
                        
                        // if( s_new.PrimaryEmail__c != s_old.PrimaryEmail__c || 
                        //     s_new.PrimaryPhone__c != s_old.PrimaryPhone__c ||
                        //     s_new.HasOptedOutOfEmail__c != s_old.HasOptedOutOfEmail__c ) {
                        //     addScope = true;    
                        // }
                    }

                    if( addScope ) {
                        scopesToSetContatable.add(s_new);
                    }
                }
            }
        }
    }

    /**
     * Get accounts associated with the scopes whose field Contactable__c has changed.
     * Include all the associated Scopes and Contacts of those accounts
     *
     * @author nts (agonzalezisasi)
     * @date 30/11/2020
     */
    public void bulkContactableAfter( List<Scope__c> newList, Map<Id, Scope__c> oldMap ) 
    {
        System.debug('- - - - - ScopeUtil.bulkContactableAfter - - - - -');
        
        if( newList != null ) {
            Set<ID> accounts = new Set<ID>();

            // for each scope...
            for(Integer i=0, j=newList.Size(); i < j; i++) {
                Boolean addAccount = false;
                Scope__c s_new = newList[i];
                
                if( oldMap == null ) { //--------------------------------------------- INSERT
                    // if is insert check with the other scopes and contacts
                    addAccount = true;
                } else { //----------------------------------------------------------- UPDATE
                    Scope__c s_old = oldMap.get(s_new.Id);

                    // If the field have changed... 
                    addAccount = (s_new.Contactable__c != s_old.Contactable__c );
                }

                if( addAccount ) {
                    accounts.add(s_new.AccountId__c);
                }
            }

            // if there are changes, get the info of the contact and all the scopes of the accounts
            if( !accounts.isEmpty() ) {
                AccountsSelector accountsSel = new AccountsSelector();
                //! ScopesToConsider: to be removed in the future
                this.accountsToCheck = accountsSel.findByIdsAndScope(accounts, ScopesToConsider);
            }
        }
    }

    /**
     * Check if to activate the field Contactable__c based on:
     * - Has PrimaryEmail__c and HasOptedOutOfEmail__c is false
     * - Or has PrimaryPhone__c
     *
     * @author nts (agonzalezisasi)
     * @date 30/11/2020
     */
    public void checkContactable()
    {
        System.debug('- - - - - ScopeUtil.checkContactable - - - - -');

        if( scopesToSetContatable != null && !scopesToSetContatable.isEmpty() ) {
            for(Integer i=0,j=scopesToSetContatable.size(); i<j; i++) {
                Scope__c s = scopesToSetContatable[i];

                // Contactable is true if Has PrimaryPhone Or has PrimaryEmail and not HasOptedOutOfEmail
                s.Contactable__c =(String.isNotBlank(s.PrimaryPhone__c) 
                    || (String.isNotBlank(s.PrimaryEmail__c) && !s.HasOPtedOutOfEmail__c)
                );
                s.LastContactableModifiedDate__c = DateTime.now();
            }
        }
    }

    /**
     * Synchronize any "Contactable__c" Scope with all "SincronizarMC" Contacts to the related Accounts
     *
     * @author nts (agonzalezisasi)
     * @date 30/11/2020
     **/
    public void checkAccounts()
    {
        System.debug('- - - - - ScopeUtil.checkAccounts - - - - -');

        if( accountsToCheck != null && !accountsToCheck.isEmpty() ) {
            this.accountsToUpdate = new List<Account>();

            // For each account...
            for( Account a: accountsToCheck ) {                
                // Check if there are scopes. There should be but check anyway to avoid weirds cases
                if( a.Scope__r != null && !a.Scope__r.isEmpty() ) {
                    // check if any scope has Contactable__c to true
                    Boolean isContactable = false;
                    Integer i=0;
                    Integer j=a.Scope__r.size();
                    while( !isContactable && i<j ){
                        Scope__c s = a.Scope__r[i];
                        isContactable = s.Contactable__c; // the first true will stop the search
                        i++;
                    }
                    // now check the contacts
                    if( showDebug ) System.Debug('--------- isContactable: ' + isContactable);
                    if( showDebug ) System.Debug('--------- SincronizarMC__pc: ' + a.SincronizarMC__pc);
                    if( (isContactable && !a.SincronizarMC__pc) || (!isContactable && a.SincronizarMC__pc) ) {
                        a.SincronizarMC__pc = isContactable;
                        accountsToUpdate.add(a);
                    }
                }
            }
        }
    }

    /**
     * Final actions in for the scope triggers
     * - afterInsert: update the personal accounts
     * 
     * @author nts (agonzalezisasi)
     * @date 14/12/2020
     */
    public void finish(System.TriggerOperation triggerOperation) { 
        System.debug('- - - - - ScopeUtil.finish - - - - -');
        
        switch on triggerOperation { 
            when AFTER_INSERT, AFTER_UPDATE { 
                // Update personal accounts
                if( this.accountsToUpdate != null && !this.accountsToUpdate.isEmpty() ) {
                    try {
                        Map<ID, List<Database.Error>> mapOfErrors = new Map<ID, List<Database.Error>>();
                        for(Account a: this.accountsToUpdate) {
                            if( showDebug ) System.debug(a);
                        }
                        // Update
                        List<Database.SaveResult> listaSaveResult = Database.update(this.accountsToUpdate, false);
                        // Check if there are any errors
                        for(Database.SaveResult saveResult:listaSaveResult) { 
                            if( !saveResult.isSuccess() ) {
                                mapOfErrors.put(saveResult.getId(), saveResult.getErrors());
                            }
                        }

                        // If there are error, register them in the error log
                        if( !mapOfErrors.isEmpty() ) {
                            for( String key: mapOfErrors.keySet() ) {
                                List<Database.Error> listOfErrors = mapOfErrors.get(key);
                                string errorMessage = 'ID [' + key+ ']';
                                for(Integer i=0, j=listOfErrors.size(); i<j; i++) {
                                    errorMessage = '\n[' + listOfErrors[i].getStatusCode() + ']: ' + listOfErrors[i].getMessage();
                                }
                                ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, errorMessage, 'ScopeUtil.finish');
                            }
                        }
                    } catch( Exception ex ) {
                        ErrorLogUtil.commitError(ex, 'ScopeUtil.finish');
                    }
                }
            }
        }
    }
}