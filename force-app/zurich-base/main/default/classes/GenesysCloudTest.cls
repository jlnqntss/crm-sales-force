@isTest
private class GenesysCloudTest {

    @isTest
     static void test_GenesysCloudRoutingService_route_email_ok() {

        String body = '{"id":"1JB9ZmJnCCKXlerwxAOZXC"}';
        Integer code = 200; //Se va a probar un retorno bueno

        GenesysCloud.RoutingService.mock = new GenesysCloudMocks(body, code);

        Test.startTest();
        GenesysCloud.Email email = new GenesysCloud.Email();
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
        GenesysCloud.Email updatedEmail = (GenesysCloud.Email) GenesysCloud.RoutingService.route(email);
        Test.stopTest();

        System.assertEquals('1JB9ZmJnCCKXlerwxAOZXC', updatedEmail.interactionId); //ID que devuelve el mock
    }

    @isTest
     static void test_GenesysCloudRoutingService_route_email_ko() {

        String body = '';
        Integer code = 400; //Se va a probar un retorno malo

        GenesysCloud.RoutingService.mock = new GenesysCloudMocks(body, code);

        Test.startTest();
        GenesysCloud.Email email = new GenesysCloud.Email();
        try{
            GenesysCloud.Email updatedEmail = (GenesysCloud.Email) GenesysCloud.RoutingService.route(email);
        }
        catch(GenesysCloud.RoutingServiceException e){
            Boolean expectedExceptionThrown =  e.getMessage().contains(GenesysCloud.RoutingService.STATUS_CODE_NO_200) ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        Test.stopTest();
    }

}