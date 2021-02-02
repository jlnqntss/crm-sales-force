public class LWCCaseSelectCustomerController {

    /**
     * Llamado desde el lwc FlowCaseSelectCustomer para recuperar
     * información de las cuentas
     */
    @AuraEnabled
    public static List<Account> getAccountsInfo(List<Id> idsToFind) {
        Set<Id> accountIds = new Set<Id>(idsToFind);
        List<Account> result = new List<Account>();
        result = AccountsSelector.selectById(accountIds, new Set<String> {'Id', 'Name', 'RecordTypeId', 'RecordType.Name'});
        return result;
    }
}
