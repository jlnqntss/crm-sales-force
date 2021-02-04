public class LWCCaseSelectCustomerController {

    /**
     * Llamado desde el lwc FlowCaseSelectCustomer para recuperar
     * información de las cuentas
     */
    @AuraEnabled
    public static List<Account> getAccountsInfo(List<Id> idsToFind) {
        Set<Id> accountIds = new Set<Id>(idsToFind);
        List<Account> result = new List<Account>();
        
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.setFields
        (
            new List<Schema.SObjectField>
            {
                Account.Id,
                Account.Name,
                Account.RecordTypeId
            },
            new List<String>
            {
                'RecordType.Name'
            }
        );

        result = AccountsSelector.selectById(accountIds);
        return result;
    }
}
