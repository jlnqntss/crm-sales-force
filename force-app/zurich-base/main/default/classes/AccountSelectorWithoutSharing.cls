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
     */
    public List<Account> findByNationalIdAndRcTypeCustAndBC(List<String> documents)
    {
        List<Account> result = new List<Account>();

        if ( documents != null && !documents.isEmpty() )
        {
            result = new List<Account>([SELECT Id, FirstName, LastName, Intermediary_Name__c,Intermediary_Name__r.INFOIntermediaryCode__c, NationalIdType__c, RecordType.DeveloperName, NationalId__c FROM account WHERE NationalId__c IN: documents AND (RecordTypeId = : rtCustomerId OR RecordTypeId = : rtBusinessCustomerId)]);
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
     */
    public List<Account> findByNationalIdAndRcTypeLead(List<String> documents)
    {
        List<Account> result = new List<Account>();

        if ( documents != null && !documents.isEmpty() )
        {
            result = new List<Account>([SELECT Id, FirstName, LastName, NationalIdType__c, Intermediary_Name__c, Intermediary_Name__r.INFOIntermediaryCode__c, RecordType.DeveloperName, NationalId__c FROM account WHERE NationalId__c IN: documents AND RecordTypeId = : rtLeadId]);
        }
        return result;
    }

    /**
     * Busca cuentas a partir de un listado de números de teléfono y record types Lead
     * @author overes
     * @date 16/08/2023
     * @param  phones  Listado de números de teléfono
     * @return         Listado de cuentas sobre los que se ha realizado match
     */
    public List<Account> findByPhoneAndRcTypeLead(List<String> phones)
    {
        List<Account> result = new List<Account>();

        if ( phones != null && !phones.isEmpty() )
        {
            result = new List<Account>([SELECT Id, FirstName, LastName, NationalIdType__c, Intermediary_Name__c, Intermediary_Name__r.INFOIntermediaryCode__c, NationalId__c, RecordType.DeveloperName, Phone FROM account WHERE Phone IN: phones AND RecordTypeId = : rtLeadId ORDER BY CreatedDate DESC]);
        }
        return result;
    }
}