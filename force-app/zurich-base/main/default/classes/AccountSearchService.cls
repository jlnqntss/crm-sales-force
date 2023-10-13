/**
 * Clase de servicio que uniformiza la búsqueda y extracción de datos de clientes y mediadores en el sistema.
 */
public with sharing class AccountSearchService
{
    /**
     * Busca y encuentra clientes a través del número de teléfono, aplicando Scope de visibilidad dado.
     * @param phones : String[] - Listado de teléfonos. Los teléfonos se esperan en formato E164
     * @param scope : AccountSearchService.Scope - Scope a aplicar.
     * @param List<String> recordTypeNames: Listado de recordtypes de cuenta
     * @param List<String> typeOfAccount: Listado de tipo de cuenta
     * @return Devuelve el listado de clientes encontrado
     * change 06/06/2023 - aberuete- Añadir parámetro recordTypeNames para que pueda filtrarse por recordtype de la cuenta
     *                               y paramétro typeOfAccount para que pueda filtrarse por tipo de cuenta
     */
    public static Account[] findCustomersByPhoneNumber(String[] phones, RecordsSelector.Scope scope, RecordsSelector.LegalEntity legalEntity, List<String> recordTypeNames, List<String> typeOfAccount)
    {
        Set<Id> accountIds = new Set<Id>();

        ContactsSelector contactsSelector = new ContactsSelector();

        if (scope != null) 
        {
            contactsSelector.setScope(scope);
        }
        else if (recordTypeNames != null  && !recordTypeNames.isEmpty())
        {
            contactsSelector.setRecordType(recordTypeNames);
        }

        if (typeOfAccount != null  && !typeOfAccount.isEmpty())
        {
            contactsSelector.setTypeOfAccount(typeOfAccount);
        }

        List<Contact> contacts = contactsSelector.findByPhoneNumber(phones);
        for(Contact contact: contacts)
        {
            accountIds.add(contact.AccountId);
        }

        AccountsSelector accountsSelector = new AccountsSelector();

        if (scope != null)
        {
            accountsSelector.setScope(scope);
        }
        else if (recordTypeNames != null  && !recordTypeNames.isEmpty())
        {
            accountsSelector.setRecordType(recordTypeNames);
        }

        if (typeOfAccount != null  && !typeOfAccount.isEmpty())
        {
            accountsSelector.setTypeOfAccount(typeOfAccount);
        }
        
        List<Account> accounts = accountsSelector.findByPhoneNumber(phones);
        for(Account account: accounts)
        {
            accountIds.add(account.Id);
        }

        accountsSelector = new AccountsSelector();
        accountsSelector.setFields
        (
            new List<Schema.SObjectField>
            {
                Account.Id,
                Account.NumPolicies__pc,
                Account.NumQuotes__pc,
                Account.Name,
                Account.PersonContactId,
                Account.NationalId__c
            }
        );

        accountsSelector.setLegalEntity(legalEntity);
        
        return accountsSelector.selectById(accountIds);
    }

    /**
     * Busca y encuentra clientes a través del correo electrónico el Scope de visibilidad dado.
     * @param emails : String[] - Listado de emails.
     * @param scope : AccountSearchService.Scope - Scope a aplicar.
     * @param List<String> recordTypeNames: Listado de recordtypes de cuenta 
     * @param List<String> typeOfAccount: Listado de tipo de cuenta
     * @return Devuelve el listado de clientes encontrado
     * change 06/06/2023 - aberuete- Añadir parámetro recordTypeNames para que pueda filtrarse por recordtype de la cuenta
     *                                y paramétro typeOfAccount para que pueda filtrarse por tipo de cuenta
     */
    public static Account[] findCustomersByEmail(String[] emails, RecordsSelector.Scope scope, RecordsSelector.LegalEntity legalEntity,List<String> recordTypeNames, List<String> typeOfAccount)
    {
        Set<Id> accountIds = new Set<Id>();

        ContactsSelector contactsSelector = new ContactsSelector();

        if (scope != null) 
        {
            contactsSelector.setScope(scope);
        }
        else if (recordTypeNames != null  && !recordTypeNames.isEmpty())
        {
            contactsSelector.setRecordType(recordTypeNames);
        }

        if (typeOfAccount != null  && !typeOfAccount.isEmpty())
        {
            contactsSelector.setTypeOfAccount(typeOfAccount);
        }
        
        List<Contact> contacts = contactsSelector.findByEmail(emails);
        for(Contact contact: contacts)
        {
            accountIds.add(contact.AccountId);
        }

        AccountsSelector accountsSelector = new AccountsSelector();

        if (scope != null)
        {
            accountsSelector.setScope(scope);
        }
        else if (recordTypeNames != null  && !recordTypeNames.isEmpty())
        {
            accountsSelector.setRecordType(recordTypeNames);
        }

        if (typeOfAccount != null  && !typeOfAccount.isEmpty())
        {
            accountsSelector.setTypeOfAccount(typeOfAccount);
        }
        
        List<Account> accounts = accountsSelector.findByEmail(emails);
        for(Account account: accounts)
        {
            accountIds.add(account.Id);
        }

        accountsSelector = new AccountsSelector();
        accountsSelector.setFields
        (
            new List<Schema.SObjectField>
            {
                Account.Id,
                Account.NumPolicies__pc,
                Account.NumQuotes__pc,
                Account.Name,
                Account.PersonContactId,
                Account.NationalId__c
            }
        );

        accountsSelector.setLegalEntity(legalEntity);
        
        return accountsSelector.selectById(accountIds);
    }

    /**
     * Busca y encuentra clientes a través del correo electrónico el Scope de visibilidad dado.
     * @param documentIds : String[] - Nº de documento.
     * @param documentType : String[] - Tipo de documento a buscar. Si null, no se hace distinción del documento.
     * @param scope : AccountSearchService.Scope - Scope a aplicar. 
     * @param  legalEntity          Entidad legal en la que buscar
     * @param List<String> recordTypeNames: Listado de recordtypes de cuenta 
     * @param List<String> typeOfAccount: Listado de tipo de cuenta
     * @return Devuelve el listado de clientes encontrado
     * change 06/06/2023 - aberuete- Añadir parámetro recordTypeNames para que pueda filtrarse por recordtype de la cuenta
     *                                y paramétro typeOfAccount para que pueda filtrarse por tipo de cuenta
     */
    public static Account[] findCustomersByDocumentId(String[] documentIds, String documentType, RecordsSelector.Scope scope, RecordsSelector.LegalEntity legalEntity, List<String> recordTypeNames, List<String> typeOfAccount)
    {
        AccountsSelector accountsSelector = new AccountsSelector();

        if (scope != null) 
        {
            accountsSelector.setScope(scope);   
        }
        else if (recordTypeNames != null  && !recordTypeNames.isEmpty())
        {
            accountsSelector.setRecordType(recordTypeNames);
        }

        if (typeOfAccount != null  && !typeOfAccount.isEmpty())
        {
            accountsSelector.setTypeOfAccount(typeOfAccount);
        }
        
        accountsSelector.setLegalEntity(legalEntity);

        return accountsSelector.findByNationalId(documentIds, documentType);
    }

    /**
     * Busca y encuentra clientes a través del número de póliza y el Scope de visibilidad dado.
     * @param policyNumbers : String[] - Nº de póliza.
     * @param scope : AccountSearchService.Scope - Scope a aplicar. Si null, se busca sobre todo (Scope.all)
     * @return Devuelve el listado de clientes encontrado
     */
    public static Account[] findCustomersByPolicyNumber(String[] policyNumbers, RecordsSelector.Scope scope, RecordsSelector.LegalEntity legalEntity)
    {
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(scope);
        accountsSelector.setLegalEntity(legalEntity);

        return accountsSelector.findByPolicyNumber(policyNumbers);
    }

    /**
     * Busca y encuentra clientes a través del número de oferta y el Scope de visibilidad dado.
     * @param quoteNumbers : String[] - Nº de oferta.
     * @param scope : AccountSearchService.Scope - Scope a aplicar. Si null, se busca sobre todo (Scope.all)
     * @return Devuelve el listado de clientes encontrado
     */
    public static Account[] findCustomersByQuoteNumber(String[] quoteNumbers, RecordsSelector.Scope scope, RecordsSelector.LegalEntity legalEntity)
    {
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setScope(scope);
        accountsSelector.setLegalEntity(legalEntity);

        return accountsSelector.findByQuoteNumber(quoteNumbers);
    }

    /**
     * Busca y encuentra mediadores a través del número de teléfono, aplicando Scope de visibilidad dado.
     * @param phones : String[] - Listado de teléfonos. Los teléfonos se esperan en formato E16
     * @param scope : AccountSearchService.Scope - Scope a aplicar. Si null, se busca sobre todo (Scope.all)
     * @return Devuelve el listado de mediadores encontrado
     */
    public static Account[] findIntermediariesByPhoneNumber(String[] phones)
    {
        return new AccountsSelector().findByIntermediaryPhoneNumber(phones);
    }

    /**
     * Busca y encuentra mediadores a través del código de mediador, aplicando Scope de visibilidad dado.
     * @param phones : String[] - Listado de teléfonos. Los teléfonos se esperan en formato E16
     * @param scope : AccountSearchService.Scope - Scope a aplicar. Si null, se busca sobre todo (Scope.all)
     * @return Devuelve el listado de mediadores encontrado
     */
    public static Account[] findIntermediariesByCode(String[] codes)
    {
        return new AccountsSelector().findByIntermediaryCode(codes);
    }

    /**
     * Busca y encuentra mediadores a través del código del NIF, aplicando Scope de visibilidad dado.
     * @param phones : String[] - Listado de teléfonos. Los teléfonos se esperan en formato E16
     * @param scope : AccountSearchService.Scope - Scope a aplicar. Si null, se busca sobre todo (Scope.all)
     * @return Devuelve el listado de mediadores encontrado
     */
    public static Account[] findIntermediariesByNIF(String[] nifs)
    {
        return new AccountsSelector().findIntermediariesByNIF(nifs);
    }

    @TestVisible
    class AccountSearchServiceException extends Exception
    {}
}