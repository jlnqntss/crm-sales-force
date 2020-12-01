/**
 * Clase de servicio que uniformiza la búsqueda y extracción de datos de clientes y mediadores en el sistema.
 */
public with sharing class AccountSearchService
{

    public static final String SCOPE_CODE_ALL = 'all';
    public static final String SCOPE_CODE_ZE = 'ze';
    public static final String SCOPE_CODE_KLINC = 'klinc';
    public static final String SCOPE_CODE_CSM = 'csm';
    private static final Map<String, String> SCOPE_NAMES_BY_CODE = new Map<String, String>
    {
        SCOPE_CODE_ALL  => 'General',
        SCOPE_CODE_ZE => 'Zurich Empresas',
        SCOPE_CODE_KLINC => 'Klinc',
        SCOPE_CODE_CSM => 'csm'
    };
    static final String INVALID_SCOPE = 'Invalid scope. Please, try with all, ze or klinc.';
    public class Scope
    {
        public String all
        {
            get {
                return SCOPE_NAMES_BY_CODE.get('all');
            }
        }
        public String scope
        {
            get {
                if(scope == null)
                {
                    return all;
                }
                else
                {
                    return scope;
                }
            }
            set
            {
                if(value == null)
                {
                    scope = all;
                }
                else if(SCOPE_NAMES_BY_CODE.containsKey(value) )
                {
                    scope = SCOPE_NAMES_BY_CODE.get(value);
                }
                else
                {
                    throw new AccountSearchServiceException(INVALID_SCOPE);
                }
            }
        }
    }

    /**
     * Busca y encuentra clientes a través del número de teléfono, aplicando Scope de visibilidad dado.
     * @param phones : String[] - Listado de teléfonos. Los teléfonos se esperan en formato E164
     * @param scope : AccountSearchService.Scope - Scope a aplicar. Si null, se busca sobre todo (Scope.all)
     * @return Devuelve el listado de clientes encontrado
     */
    public static Account[] findCustomersByPhoneNumber(String[] phones, AccountSearchService.Scope scope)
    {
        String scopeToApply = scope.scope;
        Set<Id> accountIds = new Set<Id>();
        List<Contact> contacts = new ContactsSelector().applyScope(scopeToApply).findByPhoneNumber(phones);
        for(Contact contact: contacts)
        {
            accountIds.add(contact.AccountId);
        }
        List<Account> accounts = new AccountsSelector().applyScope(scopeToApply).findByPhoneNumber(phones);
        for(Account account: accounts)
        {
            accountIds.add(account.Id);
        }

        return [SELECT Id, NumPolicies__pc, NumQuotes__pc FROM Account WHERE Id IN : accountIds];
    }

    /**
     * Busca y encuentra clientes a través del correo electrónico el Scope de visibilidad dado.
     * @param emails : String[] - Listado de emails.
     * @param scope : AccountSearchService.Scope - Scope a aplicar. Si null, se busca sobre todo (Scope.all)
     * @return Devuelve el listado de clientes encontrado
     */
    public static Account[] findCustomersByEmail(String[] emails, AccountSearchService.Scope scope)
    {
        String scopeToApply = scope.scope;
        Set<Id> accountIds = new Set<Id>();
        List<Contact> contacts = new ContactsSelector().applyScope(scopeToApply).findByEmail(emails);
        for(Contact contact: contacts)
        {
            accountIds.add(contact.AccountId);
        }
        List<Account> accounts = new AccountsSelector().applyScope(scopeToApply).findByEmail(emails);
        for(Account account: accounts)
        {
            accountIds.add(account.Id);
        }

        return [SELECT Id, NumPolicies__pc, NumQuotes__pc FROM Account WHERE Id IN : accountIds];
    }

    /**
     * Busca y encuentra clientes a través del correo electrónico el Scope de visibilidad dado.
     * @param documentIds : String[] - Nº de documento.
     * @param documentType : String[] - Tipo de documento a buscar. Si null, no se hace distinción del documento.
     * @param scope : AccountSearchService.Scope - Scope a aplicar. Si null, se busca sobre todo (Scope.all)
     * @param  legalEntity          Entidad legal en la que buscar
     * @return Devuelve el listado de clientes encontrado
     */
    public static Account[] findCustomersByDocumentId(String[] documentIds, String documentType, AccountSearchService.Scope scope, String legalEntity)
    {
        String scopeToApply = scope.scope;
        return new AccountsSelector().applyScope(scopeToApply).findByNationalId(documentIds, documentType, legalEntity);
    }

    /**
     * Busca y encuentra clientes a través del número de póliza y el Scope de visibilidad dado.
     * @param policyNumbers : String[] - Nº de póliza.
     * @param scope : AccountSearchService.Scope - Scope a aplicar. Si null, se busca sobre todo (Scope.all)
     * @return Devuelve el listado de clientes encontrado
     */
    public static Account[] findCustomersByPolicyNumber(String[] policyNumbers, AccountSearchService.Scope scope)
    {
        String scopeToApply = scope.scope;
        return new AccountsSelector().applyScope(scopeToApply).findByPolicyNumber(policyNumbers);
    }

    /**
     * Busca y encuentra clientes a través del número de oferta y el Scope de visibilidad dado.
     * @param quoteNumbers : String[] - Nº de oferta.
     * @param scope : AccountSearchService.Scope - Scope a aplicar. Si null, se busca sobre todo (Scope.all)
     * @return Devuelve el listado de clientes encontrado
     */
    public static Account[] findCustomersByQuoteNumber(String[] quoteNumbers, AccountSearchService.Scope scope)
    {
        String scopeToApply = scope.scope;
        return new AccountsSelector().applyScope(scopeToApply).findByQuoteNumber(quoteNumbers);
    }

    /**
     * Busca y encuentra mediadores a través del número de teléfono, aplicando Scope de visibilidad dado.
     * @param phones : String[] - Listado de teléfonos. Los teléfonos se esperan en formato E16
     * @param scope : AccountSearchService.Scope - Scope a aplicar. Si null, se busca sobre todo (Scope.all)
     * @return Devuelve el listado de mediadores encontrado
     */
    public static Account[] findIntermediariesByPhoneNumber(String[] phones, AccountSearchService.Scope scope)
    {
        String scopeToApply = scope.scope;
        return new AccountsSelector().applyScope(scopeToApply).findByIntermediaryPhoneNumber(phones);
    }

    /**
     * Busca y encuentra mediadores a través del código de mediador, aplicando Scope de visibilidad dado.
     * @param phones : String[] - Listado de teléfonos. Los teléfonos se esperan en formato E16
     * @param scope : AccountSearchService.Scope - Scope a aplicar. Si null, se busca sobre todo (Scope.all)
     * @return Devuelve el listado de mediadores encontrado
     */
    public static Account[] findIntermediariesByCode(String[] codes, AccountSearchService.Scope scope)
    {
        String scopeToApply = scope.scope;
        return new AccountsSelector().applyScope(scopeToApply).findByIntermediaryCode(codes);
    }

    @TestVisible
    class AccountSearchServiceException extends Exception
    {}
}