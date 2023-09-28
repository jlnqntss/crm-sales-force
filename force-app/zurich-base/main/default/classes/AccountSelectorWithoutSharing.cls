/**
 *
 * @description       : Clase Apex con el without sharing en la cual creamos 3 métodos, que serán referenciados en la clase AccountLeadUtil
 * @author            : overes
 **/
public without sharing class AccountSelectorWithoutSharing
{
    public AccountSelectorWithoutSharing()
    {}

    //#region RECORD TYPES
    public static final String RT_NAME_CUSTOMER = 'Customer';
    public static final String RT_NAME_BUSINESSCUSTOMER = 'BusinessCustomer';
    public static final String RT_NAME_LEAD= 'Lead';

    // Recupera el Id del RecordType de clientes personales
    public ID rtCustomerId
    {
        get
        {
            return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RT_NAME_CUSTOMER)?.getRecordTypeId();
        }
    }
    // Recupera el Id del RecordType de clientes Lead
    public ID rtLeadId
    {
        get
        {
            return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RT_NAME_LEAD)?.getRecordTypeId();
        }
    }
    // Recupera el Id del RecordType de clientes
    public ID rtBusinessCustomerId
    {
        get
        {
            return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RT_NAME_BUSINESSCUSTOMER)?.getRecordTypeId();
        }
    }

    /**
     * Busca cuentas a partir de un listado de DNIs y record type Customer o Business Customer
     * @author overes
     * @date 16/08/2023
     * @param  documents Listado de DNIs
     * @return           Listado de cuentas
     * **
     * @modification    Se añade que se ordene por fecha de creación
     * @author          jgallaga
     * @date            21/09/2023
     */
    public List<Account> findByNationalIdAndRcTypeCustAndBC(List<String> documents)
    {
        List<Account> result = new List<Account>();

        if ( documents != null && !documents.isEmpty() )
        {
            result = new List<Account>(
                [
                    SELECT Id, FirstName, LastName, Intermediary_Name__c, Intermediary_Name__r.INFOIntermediaryCode__c,
                    NationalIdType__c, RecordType.DeveloperName, NationalId__c
                    FROM Account
                    WHERE NationalId__c IN: documents
                    AND     (
                        RecordTypeId = : rtCustomerId
                                       OR
                                       RecordTypeId = : rtBusinessCustomerId
                        )
                    ORDER BY LastModifiedDate DESC
                ]);
        }
        return result;
    }

    /**
     * Busca cuentas a partir de un listado de DNIs y lecord type Lead
     * @author overes
     * @date 16/08/2023
     * @param  documents   Listado de DNIs
     * @return             Listado de cuentas sobre los que se ha realizado match
     *
     * @change amiranda 31/08/2023 Se elimina el campo 'Name' de la query. Es un
     * campo de solo lectura que se conforma por la concatenación de los campos
     * 'FirstName' y 'LastName' (entre otros) que son los que se consultarán
     * en la query. Por lo tanto, al intentar actualizar la lista de cuentas que
     *  nos devuelve este método, Salesforce lanza una excepción.
     * *
     * @modification    Se añade que el resultado este ordenado por fecha de creación, mas reciente primero
     * @author          jgallaga
     * @date            21/09/2023
     */
    public List<Account> findByNationalIdAndRcTypeLead(List<String> documents)
    {
        List<Account> result = new List<Account>();

        if ( documents != null && !documents.isEmpty() )
        {
            result = new List<Account>(
                [
                    SELECT Id, FirstName, LastName, NationalIdType__c, Intermediary_Name__c, Intermediary_Name__r.INFOIntermediaryCode__c, RecordType.DeveloperName, NationalId__c
                    FROM account
                    WHERE NationalId__c IN: documents
                    AND RecordTypeId = : rtLeadId
                                       ORDER BY LastModifiedDate DESC
                ]);
        }
        return result;
    }

    /**
     * Busca un registro account a partir de un id, si no encuentra resultado devuelve null
     *
     * @author dmunoz
     * @date 28/09/2023
     * @return Account cuenta a la que comprobar si es duplicado, en caso que no encuentre resultado devuelve null (no hay duplicado)
     */
    public Account findAccountById(String accountId)
    {
        Account result = null;
        if ( String.isNotEmpty(accountId) )
        {
            List<Account> accountQueryList = new List<Account>([SELECT Id, FirstName, LastName, Intermediary_Name__c, Intermediary_Name__r.INFOIntermediaryCode__c,
                                                                NationalIdType__c, RecordType.DeveloperName, NationalId__c
                                                                FROM Account
                                                                WHERE Id = : accountId]);

            if ( !accountQueryList.isEmpty() )
            {
                result = accountQueryList.get(0);
            }

        }
        return result;
    }

    /**
     * Se ha intentado evitar crear una Query más sólo para el nombre y se construía el mensaje de los registros devueltos
     * con el firstName + lastName pero en caso de las cuentas con RecordType Business Customer no tiene esos campos
     * @author overes
     * @date 28-09-2023
     * @param  accountId id a buscar
     * @return           Listado de cuentas
     */
    public List<Account> findAccountNameById(ID accountId)
    {
        List<Account> result = new List<Account>();
        if ( accountId != null)
        {
            result = new List<Account>([SELECT Id, Name FROM account WHERE Id = : accountId]);
        }
        return result;
    }

    public List<ContactpointPhone> selectByAccountScopeLead(string phone)
    {
        return [SELECT Scope__c,ScopeId__c, ScopeId__r.AccountId__c, ScopeId__r.AccountId__r.Createddate FROM ContactPointPhone WHERE TelephoneNumber = :phone AND ScopeId__r.AccountId__r.RecordType.DeveloperName = 'Lead'];
    }
}