@isTest(SeeAllData = false)
public without sharing class GenesysInteractionsServiceTest
{
    public static Account acc;
    public static Task interaction;
    /**
     * creación de reistros necesarios
     **
     * @author nescudero
     * @date 23/10/2020
     */
    public static void setUp()
    {
        acc = new Account();
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

        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.Name = 'opp';
        opp.StageName = 'New';
        opp.CloseDate = System.today().addDays(10);
        opp.Scope__c = 'General';
        insert opp;

        interaction = new Task();
        interaction.Status = 'Nueva';
        interaction.Priority = 'Normal';
        interaction.CallObject = 'ucid';
        interaction.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
                                   .get('Interaction')
                                   .getRecordTypeId();
        insert interaction;
    }

    /**
     * válida la devolución de un BestAgent y creación de una task
     **
     * @author nescudero
     * @date 26/10/2020
     */
    @IsTest
    static void test_initInteraction()
    {
        setUp(); //Se insertan Opp y Case así que ya tendrán Owner
        String callLogId = String.valueOf(interaction.Id);
        String screenPopRecordId = acc.Id;
        Case caso = [
            SELECT
            TYPEOF Owner
            WHEN User THEN Email
            END
            FROM Case
        ][0];
        String bestAgentCase = caso.Owner.Email;
        Opportunity opp = [SELECT Owner.Email FROM Opportunity][0];
        String bestAgentOpp = opp.Owner.Email;

        GenesysInteractionsService.BestAgent expectedBaCaseOut = new GenesysInteractionsService.BestAgent(
            screenPopRecordId,
            callLogId,
            bestAgentCase
            );
        GenesysInteractionsService.BestAgent expectedBaOppIn = new GenesysInteractionsService.BestAgent(
            screenPopRecordId,
            callLogId,
            bestAgentOpp
            );

        GenesysInteractionsService.InteractionRequest requestBaCaseOut = new GenesysInteractionsService.InteractionRequest();
        requestBaCaseOut.interaction = 'aaa';
        requestBaCaseOut.interactionType = 'Outbound';
        requestBaCaseOut.fromId = '123456789';
        requestBaCaseOut.toId = '123456789';
        requestBaCaseOut.queueId = '0001';
        requestBaCaseOut.lookFor = 'Case';
        GenesysInteractionsService.InteractionRequest requestBaOppIn = new GenesysInteractionsService.InteractionRequest();
        requestBaOppIn.interaction = 'bbb';
        requestBaOppIn.interactionType = 'Inbound';
        requestBaOppIn.fromId = 'nescudero@nts-solutions.com';
        requestBaOppIn.toId = 'nescudero@nts-solutions.com';
        requestBaOppIn.queueId = '0002';
        requestBaOppIn.lookFor = 'Opportunity';
        requestBaOppIn.scope = 'all';

        Test.startTest();
        GenesysInteractionsService.version = 1; //Importante
        GenesysInteractionsService.BestAgent baCaseOut = GenesysInteractionsService.initInteraction(
            requestBaCaseOut
            );
        GenesysInteractionsService.version = 1; //Importante
        GenesysInteractionsService.BestAgent baOppIn = GenesysInteractionsService.initInteraction(
            requestBaOppIn
            );
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task];
        System.assertEquals(
            3,
            tasks.size(),
            'Se debió crear 2 tasks, una por cada initInteraction + 1 existente en el setUp()'
            );
        System.assertEquals(
            expectedBaCaseOut.bestAgentId,
            baCaseOut.bestAgentId,
            'El mejor agente debería haber coincidido'
            );
        System.assertEquals(
            expectedBaOppIn.bestAgentId,
            baOppIn.bestAgentId,
            'El mejor agente debería haber coincidido'
            );
    }

    /**
     * válida la creación de una Task
     **
     * @author nescudero
     * @date 23/10/2020
     */
    @IsTest
    static void test_createOnqueueInteraction()
    {
        String ucid = '1234';

        Test.startTest();
        GenesysInteractionsService.createOnqueueInteraction(ucid);
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task];

        System.assertEquals(1, tasks.size(), 'Se debió crear 1 task');
    }

    /**
     * válida la devolución de un BestAgent
     **
     * @author nescudero
     * @date 23/10/2020
     */
    @IsTest
    static void test_findBestAgentFor()
    {
        setUp(); //Se insertan Opp y Case así que ya tendrán Owner
        String callLogId = String.valueOf(interaction.Id);
        String screenPopRecordId = acc.Id;
        Case caso = [
            SELECT
            TYPEOF Owner
            WHEN User THEN Email
            END
            FROM Case
        ][0];
        String bestAgentCase = caso.Owner.Email;
        Opportunity opp = [SELECT Owner.Email FROM Opportunity][0];
        String bestAgentOpp = opp.Owner.Email;

        GenesysInteractionsService.BestAgent expectedBaCaseOut = new GenesysInteractionsService.BestAgent(
            screenPopRecordId,
            callLogId,
            bestAgentCase
            );
        GenesysInteractionsService.BestAgent expectedBaOppIn = new GenesysInteractionsService.BestAgent(
            screenPopRecordId,
            callLogId,
            bestAgentOpp
            );

        Test.startTest();
        GenesysInteractionsService.BestAgent baCaseOut = GenesysInteractionsService.findBestAgentFor(
            callLogId,
            'Outbound',
            '123456789',
            '123456789',
            'Case',
            'General'
            );
        GenesysInteractionsService.BestAgent baOppIn = GenesysInteractionsService.findBestAgentFor(
            callLogId,
            'Inbound',
            'nescudero@nts-solutions.com',
            'nescudero@nts-solutions.com',
            'Opportunity',
            'General'
            );
        Test.stopTest();

        System.assertEquals(
            expectedBaCaseOut.bestAgentId,
            baCaseOut.bestAgentId,
            'El mejor agente debería haber coincidido'
            );
        System.assertEquals(
            expectedBaOppIn.bestAgentId,
            baOppIn.bestAgentId,
            'El mejor agente debería haber coincidido'
            );
    }
}
