/**
 * Clases de test para WS_Requests
 **
 * @author nbizkarra
 * @date 07/05/2020
 */

@isTest(SeeAllData = false)
public with sharing class Test_WS_Requests
{
    /**
     * Method that tests the doPost
     **
     * @author nbizkarra
     * @date 03/04/2020
     */
    @isTest
    static void testdoPost()
    {
        List<ExternalRequest__c> externalReq = new List<ExternalRequest__c>();

        RestRequest request = new RestRequest();
        Integer existingReq = [SELECT COUNT() FROM ExternalRequest__c];

        request.requestUri = 'https://cs84.salesforce.com/services/apexrest/request';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(
            '{"Origin":"IBA","Country":"Spain","Entity":"Customer","Timestamp":"2020-04-06 13:55:04","Json":[{ "dni": "55658574P"}]}'
            );
        RestContext.request = request;

        WS_Requests.doPost();

        Integer newReq = [SELECT COUNT() FROM ExternalRequest__c];

        System.assertEquals(existingReq + 1, newReq);
    }
}