/**
 * Acción invocable para ejecutar la lógica de generación de Hash Id
 *
 * @author rlopez
 * @date 24/02/2021
 */
global with sharing class GenerateHashIdAction
{

    @InvocableMethod(
        label='Generate Hash Id'
               description='Generates a Hash Id from a record id using standard Crypto Class'
                            category='Other'
        )
    global static List<GenerateHashIdActionResponse> generateHash(List<GenerateHashIdActionRequest> generateHashRequests)
    {
        List<GenerateHashIdActionResponse> results = new List<GenerateHashIdActionResponse>();

        if( generateHashRequests != null && !generateHashRequests.isEmpty() )
        {
            GenerateHashIdActionRequest request = generateHashRequests[0];

            if( String.isNotBlank(request.recordId) )
            {
                String generatedHashFromRecordId = SystemUtil.generateHash(request.recordId);
                if( String.isNotBlank(generatedHashFromRecordId) )
                {
                    GenerateHashIdActionResponse response = new GenerateHashIdActionResponse();
                    response.hashId = generatedHashFromRecordId;
                    results.add(response);
                }
            }
        }

        return results;
    }

    global class GenerateHashIdActionRequest
    {
        @InvocableVariable(
            label='Record Id'
                   description='Record Id to convert'
                                required=true
            )
        global String recordId;
    }

    global class GenerateHashIdActionResponse
    {
        @InvocableVariable(label='Hash Id' description='Generated Hash Id')
        global String hashId;
    }
}