@isTest
private class GenesysCloudTest {

     @isTest
     static void test_GenesysCloudRoutingService_routeEmail() {

        Test.startTest();
        purecloud.Email routingEmail = purecloud.SDK.Email.create();
        //Rellenar email con los atributos https://help.mypurecloud.com/articles/use-the-sdk-to-route-salesforce-emails
        GenesysCloud.RoutingService.route(routingEmail);
        Test.stopTest();

        //Asserts...
        //TODO: falta definir qué cambios se generan en Salesforce a partir de la respuesta de genesys
    }

    @isTest
     static void test_GenesysCloudRoutingService_routeWork() {

        //Asserts...
        //TODO: falta definir qué cambios se generan en Salesforce a partir de la respuesta de genesys
    }

    @isTest
     static void test_GenesysCloudRoutingService_removeEmail() {

        //Asserts...
        //TODO: falta definir qué cambios se generan en Salesforce a partir de la respuesta de genesys
    }

    @isTest
     static void test_GenesysCloudRoutingService_transferEmail() {

        //Asserts...
        //TODO: falta definir qué cambios se generan en Salesforce a partir de la respuesta de genesys
    }
}