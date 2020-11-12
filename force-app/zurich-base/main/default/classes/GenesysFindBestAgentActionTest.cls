@isTest
public class GenesysFindBestAgentActionTest {

    @testSetup
    public static void createScenario()
    {
        Account acc = new Account();
        acc.LastName = 'nescudero';
        acc.LegalEntity__pc = Label.GeneralInsurance;
        insert acc;

        ContactPointPhone cpp = new ContactPointPhone();
        cpp.ParentId = acc.Id;
        cpp.TelephoneNumber = '123456789';
        insert cpp;

        ContactPointEmail cpe = new ContactPointEmail();
        cpe.ParentId = acc.Id;
        cpe.EmailAddress = 'nescudero@nts-solutions.com';
        insert cpe;

        Case caso = new Case();
        caso.AccountId = acc.Id;

        insert caso;

        caso.OwnerId = USerInfo.getUserid();

        update caso;

        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.Name = 'opp';
        opp.StageName = 'New';
        opp.CloseDate = System.today().addDays(10);
        opp.Scope__c = 'General';
        insert opp;

        Task interaction = new Task();
        interaction.Status = 'Nueva';
        interaction.Priority = 'Normal';
        interaction.CallObject = 'ucid';
        interaction.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
                                   .get('Interaction')
                                   .getRecordTypeId();
        insert interaction;
    }

    @isTest
     static void test_GenesysFindBestAgentAction_execute_ok() {

        List<GenesysFindBestAgentAction.FindBestAgentRequest> requests = new List<GenesysFindBestAgentAction.FindBestAgentRequest>();
        GenesysFindBestAgentAction.FindBestAgentRequest request = new GenesysFindBestAgentAction.FindBestAgentRequest();
        request.interactionType = 'Inbound';
        request.lookFor = 'Opportunity';
        request.scope = GenesysInteractionsService.SCOPE_CODE_ALL;
        request.fromId = 'nescudero@nts-solutions.com';
        requests.add(request);

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointEmail> ([SELECT Id FROM ContactPointEmail WHERE EmailAddress = : request.fromId]).keySet();
        Test.setFixedSearchResults(new List<Id>(recordIds));

        Test.startTest();
        List<GenesysFindBestAgentAction.FindBestAgentResult> updatedInteraction = GenesysFindBestAgentAction.execute(requests);
        Test.stopTest();

        Opportunity expectedOpportunity = [SELECT AccountId, Owner.Email FROM Opportunity LIMIT 1];

        System.assertEquals(expectedOpportunity.Owner.Email, updatedInteraction[0].ownerId, 'No coincide el Id. del mejor agente');
        System.assertEquals(expectedOpportunity.AccountId, updatedInteraction[0].screenPopRecordId, 'No se está realizando screen pop del Id. de oportunidad');
    }

    @isTest
     static void test_GenesysFindBestAgentAction_execute_ko() {

        List<GenesysFindBestAgentAction.FindBestAgentRequest> requests = new List<GenesysFindBestAgentAction.FindBestAgentRequest>();
        GenesysFindBestAgentAction.FindBestAgentRequest request = new GenesysFindBestAgentAction.FindBestAgentRequest();
        request.interactionType = 'Inbound';
        request.lookFor = 'Opportunity';
        request.scope = GenesysInteractionsService.SCOPE_CODE_ALL;
        request.fromId = 'noexisto@nnoexisto.com';
        requests.add(request);

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointEmail> ([SELECT Id FROM ContactPointEmail WHERE EmailAddress = : request.fromId]).keySet();
        Test.setFixedSearchResults(new List<Id>(recordIds));

        Test.startTest();
            List<GenesysFindBestAgentAction.FindBestAgentResult> updatedInteraction = GenesysFindBestAgentAction.execute(requests);
        Test.stopTest();

        System.assertEquals(null, updatedInteraction[0].ownerId, 'No se puede encontrar el mejor agente porque no existe el Contacto con email noexisto@noexisto.com');
        System.assertEquals(null, updatedInteraction[0].screenPopRecordId, 'No hay screenPop porque no existe el Contacto con email noexisto@noexisto.com');
    }

}