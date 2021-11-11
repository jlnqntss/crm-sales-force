/**
 * Clase de test del enrutador de mensalejes a Genesys Cloud.
 * @see GenesysCloudRouteMessageAction
 * @author rpolvera@nts-solutions.com
 * @date 10/11/2021
 */
@IsTest
public with sharing class GenesysCloudRouteMessageActionTest
{
    /**
     * Prueba de enrutamiento de mensaje a Genesys Cloud.
     * Se envíala petición y se comprueba que el resultado es el esperado.
     * Resultado List<MessageResult> con identificador de la interacción de Genesys.
     * @author rpolvera@nts-solutions.com
     * @date 10/11/2021
     */
    @Istest
    public static void test_sendMessage_ok()
    {
        Map<String, String> body = new Map<String, String>
        {
            'id' => 'f441db46-256e-4781-bb20-7c094ea14119',
            'otherMediaUris' => '[]',
            'selfUri' => '/api/v2/conversations/emails/f441db46-256e-4781-bb20-7c094ea14119'
        };
        Integer code = 200; //Se crea la interacción en Genesys Cloud.
        //Se necesita un MOCK para la llamada al SDK de genesys con m.etodo POST
        GenesysCloud.RoutingService.mock = new GenesysCloudMocks(JSON.serialize(body), code);
        Test.startTest();
        List<GenesysCloudRouteMessageAction.MessageRequest> requests = new List<GenesysCloudRouteMessageAction.MessageRequest>();
        GenesysCloudRouteMessageAction.MessageRequest request = new GenesysCloudRouteMessageAction.MessageRequest();
        request.subject = 'Test Message';
        request.toName = 'Detination';
        request.toAddress = 'Detination@destination.com';
        request.fromName = 'Sender';
        request.fromAddress = 'Sender@Sender.com';
        request.queueId = '233dc463-b254-4936-b840-dd04a5e979dd';
        request.screenPopRecordId = '5005t000000ol02AAA';
        request.ownerId = '5005t000000ol02AAA';
        requests.add(request);
        List<GenesysCloudRouteMessageAction.MessageResult> responses = GenesysCloudRouteMessageAction.execute(requests);
        Test.stopTest();
        // Se comrpueba que el identificador devuelto es correcto.
        System.assertEquals(body.get('id'), responses[0].interactionId, 'El identificador de interacción de Genesys Cloud no coincide.');
    }

    /**
     * Prueba de enrutamiento de mensaje a Genesys Cloud.
     * Se envíala petición y se comprueba que el resultado es el esperado.
     * Resultado GenesysCloudRouteMessageActionException error durante la petición.
     * @author rpolvera@nts-solutions.com
     * @date 10/11/2021
     */
    @IsTest
    public static void test_sendMessage_ko()
    {
        try
        {
            Map<String, String> body = new Map<String, String>
            {
                'id' => null
            };
            Integer code = 500; //Se crea la interacción en Genesys Cloud.
            //Se necesita un MOCK para la llamada al SDK de genesys con m.etodo POST
            GenesysCloud.RoutingService.mock = new GenesysCloudMocks(JSON.serialize(body), code);
            Test.startTest();
            List<GenesysCloudRouteMessageAction.MessageRequest> requests = new List<GenesysCloudRouteMessageAction.MessageRequest>();
            GenesysCloudRouteMessageAction.MessageRequest request = new GenesysCloudRouteMessageAction.MessageRequest();
            requests.add(request);
            List<GenesysCloudRouteMessageAction.MessageResult> responses = GenesysCloudRouteMessageAction.execute(requests);
            Test.stopTest();
        }
        catch (Exception e)
        {
            // Se comrpueba la gestión de la excepción.
            System.assertEquals(GenesysCloudRouteMessageAction.GenesysCloudRouteMessageActionException.class.toString(), e.getTypeName(), 'Esta petición a Genesys Cloud debería retornar una excepción.');
        }
    }
}
