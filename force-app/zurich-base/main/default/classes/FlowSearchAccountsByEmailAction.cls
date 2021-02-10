public class FlowSearchAccountsByEmailAction {

    @InvocableMethod(
        label='Search Account in Contact Point Email'
        description='Busca en ContactPointEmail las cuentas que tengan un email coincidente con los recibido en Case.SuppliedEmail al haberse creado por un Email-to-case'
        category='Other'
    )
    public static List<AccountEmailResult> execute(List<AccountEmailRequest> accountEmailRequests)
    {
        List<AccountEmailResult> results = new List<AccountEmailResult>();

        if(accountEmailRequests != null && !accountEmailRequests.isEmpty())
        {//Solo va a llegar un registro porque esto se muestra en el Layout de caso, es un flow INDIVIDUAL
            AccountEmailRequest request = accountEmailRequests[0];

            //Preparamos la información recibida para pasársela al AccountSearchService
            //AccountSearchService.Scope scope = new AccountSearchService.Scope();
            //scope.scope = null; //FIXME: Cambiar esto por request.caseScope cuando se haya refactorizado AccountSearchService y la picklist de caso coincidan en valores
            List<String> emailsToSearch = new List<String>();
            emailsToSearch.add(request.caseEmail);

            //Utilizamos el AccountSearchService que usa SOSL para querys no selectivas
            List<Account> matchedAccounts = new List<Account>();
            matchedAccounts = AccountSearchService.findCustomersByEmail(emailsToSearch, RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.ALL);

            //La salida para el flow se necesita en una lista de Strings:
            List<String> listIds = new List<String>();
            for(Account acc : matchedAccounts)
            {
                listIds.add(acc.Id);
            }

            //Creamos la respuesta para el flow:
            AccountEmailResult response = new AccountEmailResult();
            response.AccountIds = new List<String>();
            response.AccountIds.addAll(listIds);
            results.add(response);
        }

        return results;
    }

    public class AccountEmailRequest
    {
        @InvocableVariable(label='Supplied Email'  description='Email del caso' required=true)
        public String caseEmail;

        //202102 ya no es relevante usar el Scope del caso, se va a buscar en Scope.All
        //@InvocableVariable(label='Scope' description='Scope del caso' required=true)
        //public String caseScope;
    }

    public class AccountEmailResult
    {
        @InvocableVariable(label='Account Id List' description='Ids de cuentas encontradas a través de ContactPointEmail')
        public List<String> AccountIds;
    }
}