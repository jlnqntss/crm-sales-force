/**
 * @description       : Acción invocable para ejecutar la lógica de búsqueda de clientes a partir del CIF, si no encuentra ninguno a partir del email
 *                      y en el caso que no encuentre ninguno por teléfono.
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 06-06-2023
 * @last modified by  : aberuete
**/
public class FindCustomersByCIFEmailPhoneAction 
{
    @InvocableMethod
    (
        label='Find Account by National Id or Email or Phone'
        description='Busca las cuentas que tengan el national id coincidente con los recibido en Case.RobotNif__c ,en caso de que no encuentre ninguna buscar por Case.SuppliedEmail, y en el caso que no encuentre ninguna por Case.SuppliedPhone'
        category='Other'
    )
    public static List<FindCustomerByCIFOrEmailorPhoneActionResponse> findByCIFOrEmailOrPhone(List<FindCustomerByCIFOrEmailOrPhoneActionRequest> accountRequests)
    {
        List<FindCustomerByCIFOrEmailorPhoneActionResponse> results = new List<FindCustomerByCIFOrEmailorPhoneActionResponse>();

        if(accountRequests != null && !accountRequests.isEmpty())
        {//Solo va a llegar un registro porque esto se muestra en el Layout de caso, es un flow INDIVIDUAL
            FindCustomerByCIFOrEmailOrPhoneActionRequest request = accountRequests[0];

            List<Account> matchedAccounts = new List<Account>();

            if (request.caseCIF != null && !String.isBlank(request.caseCIF))
            {
                matchedAccounts = AccountSearchService.findCustomersByDocumentId(new List<String>{request.caseCIF},'', null, null, new List<String>{'Customer'},new List<String>{'F','J'});
            }
            
            if (matchedAccounts.isEmpty() && request.caseEmail != null && !String.isBlank(request.caseEmail))
            {
                matchedAccounts = AccountSearchService.findCustomersByEmail(new List<String>{request.caseEmail}, null, null, new List<String>{'Customer'},new List<String>{'F','J'});
            }

            if (matchedAccounts.isEmpty() && request.casePhone != null && !String.isBlank(request.casePhone))
            {
                matchedAccounts = AccountSearchService.findCustomersByPhoneNumber(new List<String>{request.casePhone}, null, null, new List<String>{'Customer'}, new List<String>{'F','J'});
            }

            //La salida para el flow se necesita en una lista de Strings:
            List<String> listIds = new List<String>();
            for(Account acc : matchedAccounts)
            {
                listIds.add(acc.Id);
            }

            //Creamos la respuesta para el flow:
            FindCustomerByCIFOrEmailorPhoneActionResponse response = new FindCustomerByCIFOrEmailorPhoneActionResponse();
            response.AccountIds = new List<String>();
            response.AccountIds.addAll(listIds);
            results.add(response);
        }

        return results;
    }
    
    public class FindCustomerByCIFOrEmailOrPhoneActionRequest
    {
        @InvocableVariable(label='Robot NIF'  description='Nif asociado al caso')
        public String caseCIF;

        @InvocableVariable(label='Supplied Email'  description='Email del caso')
        public String caseEmail;

        @InvocableVariable(label='Supplied Phone'  description='Teléfono del caso')
        public String casePhone;
    }

    public class FindCustomerByCIFOrEmailorPhoneActionResponse
    {
        @InvocableVariable(label='Account Id List' description='Ids de cuentas encontradas a través del national id')
        public List<String> AccountIds;
    }
}