/**
 * Acción invocable para ejecutar la lógica de búsqueda de clientes
 * a partir del número de teléfono
 * 
 * @author rlopez
 * @date 27/01/2021
 */
global with sharing class FindCustomerByPhoneAction {

    @InvocableMethod(
        label='Find by phone'
        description='Searches customers using the phone number and scope provided'
        category='Other'
    )
    global static List<FindCustomerByPhoneActionResponse> findByPhone(List<FindCustomerByPhoneActionRequest> findCustomerActionRequests)
    {
        List<FindCustomerByPhoneActionResponse> results = new List<FindCustomerByPhoneActionResponse>();

        if(findCustomerActionRequests != null && !findCustomerActionRequests.isEmpty())
        {
            FindCustomerByPhoneActionRequest request = findCustomerActionRequests[0];

            if(String.isNotBlank(request.phone) && String.isNotBlank(request.scope))
            {
                AccountSearchService.Scope accSearchServiceScope = new AccountSearchService.Scope();
                accSearchServiceScope.scope = request.scope;

                List<Account> customers = AccountSearchService.findCustomersByPhoneNumber(new List<String>{request.phone}, accSearchServiceScope);

                if(customers != null && !customers.isEmpty())
                {
                    FindCustomerByPhoneActionResponse response = new FindCustomerByPhoneActionResponse();
                    response.customerId = customers.get(0).Id;
                    results.add(response);
                }
            }
        }

        return results;
    }

    global class FindCustomerByPhoneActionRequest
    {
        @InvocableVariable(
            label='Phone'
            description='Phone'
            required=true
        )
        global String phone;

        @InvocableVariable(
            label='Scope'
            description='Scope'
            required=true
        )
        global String scope;
    }

    global class FindCustomerByPhoneActionResponse
    {
        @InvocableVariable(label='Customer Id' description='Id del Customer encontrado')
        global String customerId;
    }
}