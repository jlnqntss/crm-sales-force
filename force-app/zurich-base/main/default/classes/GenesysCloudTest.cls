@isTest
private class GenesysCloudTest {

     @isTest
     static void test_GenesysCloudRoutingService_routeEmail() {
    }

    @isTest
     static void test_GenesysCloudRoutingService_routeRoutingWork() {

        Test.setMock(HttpCalloutMock.class, new GenesysCloudMocks());

        Test.startTest();
        GenesysCloud.RoutingWork routingWork = new GenesysCloud.RoutingWork();
        routingWork.endpoint = 'emails';
        GenesysCloud.RoutingWork updatedRoutingWork = GenesysCloud.RoutingService.route(routingWork);
        Test.stopTest();

        //WIP
        System.assertEquals('1JB9ZmJnCCKXlerwxAOZXC', updatedRoutingWork.interactionId); //ID que devuelve el mock
    }

    @isTest
     static void test_GenesysCloudRoutingService_removeEmail() {
    }

    @isTest
     static void test_GenesysCloudRoutingService_transferEmail() {

    }
}