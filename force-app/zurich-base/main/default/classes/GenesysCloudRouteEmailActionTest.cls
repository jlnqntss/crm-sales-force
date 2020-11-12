@isTest
public class GenesysCloudRouteEmailActionTest {

    @isTest
     static void test_GenesysCloudRouteEmailAction_execute_ok() {

        String body = '{"id":"1JB9ZmJnCCKXlerwxAOZXC"}';
        Integer code = 200; //Se va a probar un retorno bueno

        //Se necesita un MOCK porque en medio hay una llamada al SDK de genesys con POST
        GenesysCloud.RoutingService.mock = new GenesysCloudMocks(body, code);

        Test.startTest();
        List<GenesysCloudRouteEmailAction.RouteEmailRequest> requests = new List<GenesysCloudRouteEmailAction.RouteEmailRequest>();
        GenesysCloudRouteEmailAction.RouteEmailRequest email = new GenesysCloudRouteEmailAction.RouteEmailRequest();
        email.queueId = 'debe ser null si hay flowID';
        email.flowId = 'debe ser null si hay queueId';
        email.skillIds = new List<String>{'skill1','skill2'};
        email.priority = 1;
        email.screenPopRecordId = 'recordID';
        email.subject = 'subjet';
        email.toName = 'toname';
        email.toAddress = 'toaddres';
        email.fromName = 'fromname';
        email.fromAddress = 'fromaddress';
        requests.add(email);
        List<GenesysCloudRouteEmailAction.RouteEmailResult> updatedEmail = GenesysCloudRouteEmailAction.execute(requests);
        Test.stopTest();

        System.assertEquals('1JB9ZmJnCCKXlerwxAOZXC', updatedEmail[0].interactionId); //ID que devuelve el mock
    }

    @isTest
     static void test_GenesysCloudRouteEmailAction_execute_ko() {

        String body = '';
        Integer code = 400; //Se va a probar un retorno malo

        //Se necesita un MOCK porque en medio hay una llamada al SDK de genesys con POST
        GenesysCloud.RoutingService.mock = new GenesysCloudMocks(body, code);

        Test.startTest();
        List<GenesysCloudRouteEmailAction.RouteEmailRequest> requests = new List<GenesysCloudRouteEmailAction.RouteEmailRequest>();
        GenesysCloudRouteEmailAction.RouteEmailRequest email = new GenesysCloudRouteEmailAction.RouteEmailRequest();
        try{
            requests.add(email);
            List<GenesysCloudRouteEmailAction.RouteEmailResult> updatedEmail = GenesysCloudRouteEmailAction.execute(requests);
        }
        catch(GenesysCloud.RoutingServiceException e){
            Boolean expectedExceptionThrown =  e.getMessage().contains(GenesysCloud.ERROR_RESPONSE_SDK) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        Test.stopTest();
    }

}