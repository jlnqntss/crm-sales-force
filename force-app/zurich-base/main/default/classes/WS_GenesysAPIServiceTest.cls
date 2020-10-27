@isTest(SeeAllData=false)
public without sharing class WS_GenesysAPIServiceTest {
  public static Contact c;
  /**
   * creación de reistros necesarios
   **
   * @author nescudero
   * @date 26/10/2020
   */
  public static void setUp() {
    c = new Contact();
    c.LastName = 'nescudero';
    c.LegalEntity__c = Label.GeneralInsurance;
    insert c;

    ContactPointPhone cpp = new ContactPointPhone();
    cpp.ContactId__c = c.Id;
    cpp.TelephoneNumber = '123456789';
    insert cpp;

    ContactPointEmail cpe = new ContactPointEmail();
    cpe.ContactId__c = c.Id;
    cpe.EmailAddress = 'nescudero@nts-solutions.com';
    insert cpe;

    Case caso = new Case();
    caso.ContactId = c.Id;
    insert caso;

    Opportunity opp = new Opportunity();
    opp.ContactId__c = c.Id;
    opp.Name = 'opp';
    opp.StageName = 'New';
    opp.CloseDate = System.today().addDays(10);
    insert opp;
  }

  /**POST
   * Prueba que se reciba una petición
   * y se responda correctamente lo esperado
   * @author nescudero
   * @date 26/10/2020
   */
  @isTest
  static void test_doPost() {
    setUp(); //Se insertan Opp y Case así que ya tendrán Owner
    String screenPopRecordId = c.Id;
    Opportunity opp = [SELECT Owner.Email FROM Opportunity][0];
    String bestAgentOpp = opp.Owner.Email;

    RestResponse response = new RestResponse();
    RestRequest request = new RestRequest();
    //request.requestURI = System.URL.getSalesforceBaseURL().toExternalForm()+'/genesys-cloud/v1/interactions/init';
    request.requestURI = '/genesys-cloud/v1/interactions/init';
    request.httpMethod = 'POST';
    request.addHeader('Content-Type', 'application/json');
    request.requestBody = Blob.valueOf(
      '{"interaction":"123456789","interactionType":"Inbound","fromId": "nescudero@nts-solutions.com","toId": "123456789","queueId": "0001","lookFor": "Opportunity"}'
    );

    RestContext.request = request;
    RestContext.response = response;

    Test.startTest();
    WS_GenesysAPIService.doPost();
    Test.stopTest();

    Task createdTask = [SELECT id FROM Task][0];
    System.assertEquals(
      '{"screenPopRecordId":"' +
      screenPopRecordId +
      '","callLogId":"' +
      createdTask.Id +
      '","bestAgentId":"' +
      bestAgentOpp +
      '"}',
      response.responseBody.toString()
    );
  }
}
