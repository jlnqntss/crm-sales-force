@isTest
public class GenesysCloudSendSMSActionTest {
  @TestSetup
  static void createScenario() {
    List<Account> accounts = TestDataFactory.generateAccounts(
      '001',
      'Customer',
      10
    );
    insert accounts;

    List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(
      accounts,
      'ZE',
      1
    );
    insert scopes;

    List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
    insert cases;
  }

  @isTest
  static void test_GenesysCloudSendSMSAction_execute_ok() {
    // Datos petición
    Case relatedCase = [SELECT Id FROM Case LIMIT 1];
    System.assertEquals(true, relatedCase != null, 'Case exists');

    String body = '{"id":"1JB9ZmJnCCKXlerwxAOZXC"}';
    Integer code = 200; //Se va a probar un retorno bueno

    //Se necesita un MOCK porque en medio hay una llamada al SDK de genesys con POST
    GenesysCloud.RoutingService.mock = new GenesysCloudMocks(body, code);

    Test.startTest();
    List<GenesysCloudSendSMSAction.SendSMSRequest> requests = new List<GenesysCloudSendSMSAction.SendSMSRequest>();

    GenesysCloudSendSMSAction.SendSMSRequest sms = new GenesysCloudSendSMSAction.SendSMSRequest();
    List<AdminSetupParameter__mdt> settings = [
      SELECT Value__c
      FROM AdminSetupParameter__mdt
      WHERE KeyName__c = 'GenesysSmsNumber'
    ];
    System.assertEquals(false, settings.isEmpty(), 'List is not empty');
    String genesysSmsNumber = settings[0].Value__c;
    sms.senderNumber = genesysSmsNumber;
    sms.toNumber = '123456789';
    sms.smsText = 'sms text';
    sms.relatedCaseId = relatedCase.Id;
    requests.add(sms);

    GenesysCloudSendSMSAction.sendSMS(requests);
    Test.stopTest();
  }

  @isTest
  static void test_GenesysCloudSendSMSAction_execute_ko() {
    // Datos petición
    Case relatedCase = [SELECT Id FROM Case LIMIT 1];
    System.assertEquals(true, relatedCase != null, 'Case exists');

    String body = '{"id":"1JB9ZmJnCCKXlerwxAOZXC"}';
    Integer code = 200; //Se va a probar un retorno bueno

    //Se necesita un MOCK porque en medio hay una llamada al SDK de genesys con POST
    GenesysCloud.RoutingService.mock = new GenesysCloudMocks(body, code);

    Test.startTest();
    List<GenesysCloudSendSMSAction.SendSMSRequest> requests = new List<GenesysCloudSendSMSAction.SendSMSRequest>();

    GenesysCloudSendSMSAction.SendSMSRequest sms = new GenesysCloudSendSMSAction.SendSMSRequest();

    sms.toNumber = '';
    sms.smsText = 'sms text';
    sms.relatedCaseId = relatedCase.Id;
    requests.add(sms);

    try {
      GenesysCloudSendSMSAction.sendSMS(requests);
    } catch (Exception ex) {
      System.assertEquals(
        true,
        ex.getMessage().contains('Missing fields sending SMS'),
        'Missing fields exception'
      );
    }
    Test.stopTest();
  }
}
