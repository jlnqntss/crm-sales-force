/**
 * Utilitiy methods for the Scope__c object
 *
 * @author nts (agonzalezisasi)
 * @date 30/11/2020
 */
global without sharing class ScopeUtil {
  // Fields to check if there is any change
  private static final List<String> FieldsToCheckChange = new List<String>{
    'PrimaryEmail__c',
    'PrimaryPhone__c',
    'HasOptedOutOfEmail__c'
  };
  //! To be removed in the future
  // Scope__c field (picklist) of Scope__c object
  private static final List<String> ScopesToConsider = new List<String>{
    'ZE',
    'ZEO'
  };

  // List of Scopes to change the Contactable field.
  @testvisible
  private List<Scope__c> scopesToSetContatable;
  // Map of Scopes that will be updated. Used in AFTER trigger
  @testvisible
  private Map<ID, Scope__c> scopesToUpdateAfter;
  // List of accounts of the changed Scopes
  private List<Account> accountsToCheck;
  // List of accounts to update because of the scopes
  @testvisible
  private List<Account> accountsToUpdate;

  /**
   * Select the scopes that has a change in the following fields:
   *  - PrimaryEmail__c
   *  - HasOptedOutOfEmail__c
   *  - PrimaryPhone__c
   *
   * @author nts (agonzalezisasi)
   * @date 30/11/2020
   * change aberuete -27/04/2023 - Refactorizar método
   */
  public void bulkContactableBefore(List<Scope__c> newList, Map<Id, Scope__c> oldMap) 
  {
    if (newList != null) 
    {

      this.scopesToSetContatable = new List<Scope__c>();

      // for each scope...
      for (Integer i = 0, j = newList.Size(); i < j; i++) 
      {
        Scope__c s_new = newList[i];
         
        // Check if is valid scope
        //! To be removed in the future
        ifAddScopeTrueAddToScopesToSetContatable (s_new, oldMap);
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
  public void bulkContactableAfter(
    List<Scope__c> newList,
    Map<Id, Scope__c> oldMap
  ) {
    

    if (newList != null) {
      Set<ID> accounts = new Set<ID>();

      // for each scope...
      for (Integer i = 0, j = newList.Size(); i < j; i++) {
        Boolean addAccount = false;
        Scope__c s_new = newList[i];

        if (oldMap == null) {
          //--------------------------------------------- INSERT
          // if is insert check with the other scopes and contacts
          addAccount = true;
        } else {
          //----------------------------------------------------------- UPDATE
          Scope__c s_old = oldMap.get(s_new.Id);

          // If the field have changed...
          addAccount = (s_new.Contactable__c != s_old.Contactable__c);
        }

        if (addAccount) {
          accounts.add(s_new.AccountId__c);
        }
      }

      // if there are changes, get the info of the contact and all the scopes of the accounts
      if (!accounts.isEmpty()) {
        AccountsSelector accountsSel = new AccountsSelector();
        //! ScopesToConsider: to be removed in the future
        this.accountsToCheck = accountsSel.findByIdsAndScope(
          accounts,
          ScopesToConsider
        );
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
  public void checkContactable() {
    

    if (scopesToSetContatable != null && !scopesToSetContatable.isEmpty()) {
      for (Integer i = 0, j = scopesToSetContatable.size(); i < j; i++) {
        Scope__c s = scopesToSetContatable[i];
        if (ScopesToConsider.contains(s.Scope__c)) {
          // Contactable is true if Has PrimaryPhone Or has PrimaryEmail and not HasOptedOutOfEmail
          s.Contactable__c = (String.isNotBlank(s.PrimaryPhone__c) ||
          (String.isNotBlank(s.PrimaryEmail__c) && !s.HasOPtedOutOfEmail__c));
          s.LastContactableModifiedDate__c = DateTime.now();
        }
      }
    }
  }

  /**
   * Synchronize any "Contactable__c" Scope with all "SincronizarMC" Contacts to the related Accounts
   *
   * @author nts (agonzalezisasi)
   * @date 30/11/2020
   * change aberuete -27/04/2023 - Refactorizar método
   **/
  public void checkAccounts() 
  {
    if (accountsToCheck != null && !accountsToCheck.isEmpty()) 
    {
      this.accountsToUpdate = new List<Account>();

      // For each account...
      for (Account accountToCheck : accountsToCheck) 
      {
        checkIfAccountHasToBeUpdated(accountToCheck);
      }
    }
  }

  /**
   * Final actions in for the scope triggers
   * - afterInsert: update the personal accounts
   *
   * @author nts (agonzalezisasi)
   * @date 14/12/2020
   *
   * @change 15/12/2020 - nts (agonzalezisasi) - Add the test for the HashedId__c field
   * @change 15/12/2020 - nts (agonzalezisasi) - Make the process of update indepedent
   */
  public void finish(System.TriggerOperation triggerOperation) 
  {
    switch on triggerOperation 
    {
      when AFTER_INSERT, AFTER_UPDATE 
      {
        // Update personal accounts
        doUpdate(this.accountsToUpdate);

        // Only for After Insert Events
        if (triggerOperation == System.TriggerOperation.AFTER_INSERT) 
        {
          doUpdate(this.scopesToUpdateAfter.values());
        }
      }
      when else 
      {
        // else code
      }
    }
  }

  /**
   * This method does the update for the given list of sobjects with allornone to false.
   * It also registers the errors in the log if there are any.
   *
   * @author nts (agonzalezisasi)
   * @date 15/12/2020
   *
   * @change 15/12/2020 - nts (agonzalezisasi) - Make the process of update indepedent
   * @change 27/04/2023 - aberuete- Refactorizar método
   */
  public void doUpdate(List<SObject> listToUpdate) 
  {
    if (listToUpdate != null && !listToUpdate.isEmpty()) 
    {
      try 
      {
        
        // Do the Update
        List<Database.SaveResult> listaSaveResult = Database.update(listToUpdate, false);

        // Check if there are any errors...
        Map<ID, List<Database.Error>> mapOfErrors = checkIfThereAnyErrorInUpdate (listaSaveResult);

        // If there are errors, register them in the Error Log
        if (!mapOfErrors.isEmpty()) 
        {
          // for each register (sobject) ...
          for (String key : mapOfErrors.keySet()) 
          {
            // fill a message with all the errors of that sobject...
            List<Database.Error> listOfErrors = mapOfErrors.get(key);
            string errorMessage = 'ID [' + key + ']';
            for (Integer i = 0, j = listOfErrors.size(); i < j; i++) 
            {
              errorMessage =
                '\n[' +
                listOfErrors[i].getStatusCode() +
                ']: ' +
                listOfErrors[i].getMessage();
            }

            // send the message to the Error Log
            ErrorLogUtil.commitError(
              ErrorLogUtil.ERROR_LEVEL_ERROR,
              errorMessage,
              'ScopeUtil.doUpdate'
            );
          }
        }
      } catch (Exception ex) {
        ErrorLogUtil.commitError(ex, 'ScopeUtil.doUpdate');
      }
    }
  }

  /**
   * Generates for security a hash id from the scope SF Id.
   * This is to be used in the Preference Center ZE, to unsuscribe from the given scope
   *
   * @author nts (agonzalezisasi)
   * @date 15/12/2020
   * change aberuete -27/04/2023 - Refactorizar método
   */
  public void generateHashId(List<Scope__c> newList) 
  {
    if (newList != null && !newList.isEmpty()) 
    {
      if (this.scopesToUpdateAfter == null) 
      {
        this.scopesToUpdateAfter = new Map<ID, Scope__c>();
      }

      for (Scope__c scopeFromNewList : newList) 
      {
        generateHashForScope (scopeFromNewList);
      }
    }
  }

  /**
  * Método que en el caso que el nuevo scope sea por inserción o que se haya actualizado alguno de los siguientes valores 
  * PrimaryEmail__c o PrimaryPhone__c o HasOptedOutOfEmail__c añade el scope a la lista para cambiar el valor Contactable.
  * @author aberuete 
  * @date 27-04-2023 
  * @param Scope__c s_new : nuevo scope o scope actualizado
  * @param Scope__c> oldMap : antiguo scope
  **/
  @testvisible
  private void ifAddScopeTrueAddToScopesToSetContatable (Scope__c s_new, Map<Id, Scope__c> oldMap )
  {
    if (ScopesToConsider.contains(s_new.Scope__c)) 
    {
      Boolean addScope = false;
      if (oldMap == null) 
      {
        //INSERT
        addScope = true;
      } 

      else 
      {
        //UPDATE
        Scope__c s_old = oldMap.get(s_new.Id);

        // If any of the following fields has changed
        Integer x = 0;
        while (!addScope && x < FieldsToCheckChange.size()) 
        {
          if (s_new.get(FieldsToCheckChange[x]) != s_old.get(FieldsToCheckChange[x])) 
          {
            addScope = true;
          }
          x++;
        }
      }

      if (addScope) 
      {
        scopesToSetContatable.add(s_new);
      }
    }
  }

  /**
  * Método que verifica si el valor SincronizarMC__pc de la cuenta debe ser actualizado. 
  * En caso de que deba ser actualizado lo añade a la lista de cuentas a actualizar. 
  * @author aberuete 
  * @date 27-04-2023 
  * @param Account accountToCheck : cuenta a verificar
  **/
  @testvisible
  private void checkIfAccountHasToBeUpdated(Account accountToCheck)
  {
    // Check if there are scopes. There should be but check anyway to avoid weirds cases
    if (accountToCheck.Scope__r != null && !accountToCheck.Scope__r.isEmpty()) 
    {
      // check if any scope has Contactable__c to true
      Boolean isContactable = false;
      Integer i = 0;
      Integer j = accountToCheck.Scope__r.size();
      while (!isContactable && i < j) 
      {
        Scope__c scopeFromAccount = accountToCheck.Scope__r[i];
        isContactable = scopeFromAccount.Contactable__c; // the first true will stop the search
        i++;
      }

      // now check the contacts 
      if ((isContactable && !accountToCheck.SincronizarMC__pc) || (!isContactable && accountToCheck.SincronizarMC__pc))
      {
        accountToCheck.SincronizarMC__pc = isContactable;
        accountsToUpdate.add(accountToCheck);
      }
    }  
  }

  /**
  * Método que genera un hast id para el scope.  
  * @author aberuete 
  * @date 27-04-2023 
  * @param Scope__c scopeFromNewList : nuevo scope o actualizado
  **/
  @testvisible
  private void generateHashForScope (Scope__c scopeFromNewList)
  {
    if (scopeFromNewList.Id != null && scopeFromNewList.HashedId__c == null) 
    {
      // not needed but just to be sure....
      try 
      {
        Scope__c aux = null;

        if (this.scopesToUpdateAfter.containsKey(scopeFromNewList.Id)) 
        {
          aux = this.scopesToUpdateAfter.get(scopeFromNewList.Id);
        }
        else 
        {
          // Creates another object for the update, only to change the HasedId__c field
          aux = new Scope__c(Id = scopeFromNewList.Id);
          this.scopesToUpdateAfter.put(scopeFromNewList.Id, aux);
        }
        // Generate the hash
        aux.HashedId__c = SystemUtil.generateHash(scopeFromNewList.Id);
      } 
      catch (Exception ex) 
      {
        ErrorLogUtil.commitError(ex, 'ScopeUtil.generateHashId');
      }
    }
  }

  /**
  * Método que obtiene un mapa de los errores que ha habido al actualizar un objeto.  
  * @author aberuete 
  * @date 27-04-2023 
  * @param List<Database.SaveResult> listaSaveResult : Lista que guarda el resultado de la actualización
  **/
  @testvisible
  private Map<ID, List<Database.Error>> checkIfThereAnyErrorInUpdate (List<Database.SaveResult> listaSaveResult)
  {
    Map<ID, List<Database.Error>> mapOfErrors = new Map<ID, List<Database.Error>>();

    for (Database.SaveResult saveResult : listaSaveResult) 
    {
      if (!saveResult.isSuccess()) 
      {
        mapOfErrors.put(saveResult.getId(), saveResult.getErrors());
      }
    }
    return mapOfErrors;
  }
}
