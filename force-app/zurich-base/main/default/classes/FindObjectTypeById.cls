/**
 * Acción invocable para buscar el sObject Type a partir de una Id.
 * 
 * @author palegria
 * @date 14/07/2022
 */
global with sharing class FindObjectTypeById {

    @InvocableMethod(
        label='Find sObject Type by Id'
        description='Returns sObject Type by Id'
        category='Other'
    )
    global static List<FindObjectTypeByIdResponse> findObjectType(List<FindObjectTypeByIdRequest> findObjectTypeRequests)
    {
        List<FindObjectTypeByIdResponse> results = new List<FindObjectTypeByIdResponse>();

        if(findObjectTypeRequests != null && !findObjectTypeRequests.isEmpty())
        {
            FindObjectTypeByIdRequest request = findObjectTypeRequests[0];

            if(String.isNotBlank(request.Id))
            {
                String sObjName = request.Id.getSObjectType().getDescribe().getName();

                if(String.isNotBlank(sObjName))
                {
                    FindObjectTypeByIdResponse response = new FindObjectTypeByIdResponse();
                    response.objectType = sObjName;
                    results.add(response);
                }
            }
        }

        return results;
    }

    global class FindObjectTypeByIdRequest
    {
        @InvocableVariable(
            label='Object Id'
            description='Id del objeto'
            required=true
        )
        global Id id;
    }

    global class FindObjectTypeByIdResponse
    {
        @InvocableVariable(label='sObject Type' description='String con el nombre del objeto')
        global String objectType;
    }
}