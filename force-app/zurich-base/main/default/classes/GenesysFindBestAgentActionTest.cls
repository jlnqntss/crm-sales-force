@isTest
public class GenesysFindBestAgentActionTest {

    /**
     * Generación de escenario usando TestDataFactory
     * @author nescudero
     * @date 13/11/2020
     */
    @TestSetup
    static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;

        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(accounts, 'CustomerGI', 1);
        insert contacts;

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 10);
        insert contactPointPhones;
        //Actualizar con los datos usados en los test
        contactPointPhones.get(0).TelephoneNumber = '123456789';
        update contactPointPhones.get(0);

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, 10);
        insert contactPointEmails;
        //Actualizar con los datos usados en los test
        contactPointEmails.get(0).EmailAddress = 'nescudero@nts-solutions.com';
        update contactPointEmails.get(0);

        //se crea 1 caso para cada cuenta
        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        insert cases;

        //Se crea 1 opp para cada cuenta
        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 1);
        insert opportunities;

        List<Task> tasks = TestDataFactory.generateInteractionTasks(10);
        insert tasks;
    }

    @isTest
     static void test_GenesysFindBestAgentAction_execute_ok() {

        List<GenesysFindBestAgentAction.FindBestAgentRequest> requests = new List<GenesysFindBestAgentAction.FindBestAgentRequest>();
        GenesysFindBestAgentAction.FindBestAgentRequest request = new GenesysFindBestAgentAction.FindBestAgentRequest();
        request.interactionType = 'Inbound'; //buscará por fromId
        request.lookFor = 'Opportunity';
        request.scope = GenesysInteractionsService.SCOPE_CODE_ALL; //Opp.Scope__c = 'General'
        request.fromId = 'nescudero@nts-solutions.com'; //coincide con contactPointEmail.EmailAddress
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