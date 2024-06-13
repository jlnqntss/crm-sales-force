@isTest
private with sharing class Batch_GDPRPropagateBlocked_Test {

    private static final String ACCOUNT_CUSTOMER = 'Customer';
    private static final String ACCOUNT_BCUSTOMER = 'BusinessCustomer';
    private static final String LEGAL_ENTITY = '001';
    private static final Id CustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().
                                                get(ACCOUNT_CUSTOMER).getRecordTypeId();
    private static final Id BCustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().
                                                get(ACCOUNT_BCUSTOMER).getRecordTypeId();



    @TestSetup
    private static void makeData(){
        List<Account> accs = TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_CUSTOMER, 1);

        for(Integer i = 0; accs.size() < i; i++){
            accs[i].FirstName = 'Test Account';
            accs[i].LastName = '-001';
            accs[i].RecordTypeId = CustomerRecordTypeId;
        }
        insert accs;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accs, 'ZE', 1);
        insert scopes;

        List<ContactPointAddress> cpa = TestDataFactory.generateContactPointAddressesFromAccounts(accs, 1);
        insert cpa;

        List<ContactPointEmail> cpe = TestDataFactory.generateContactPointEmailsFromAccounts(accs, 1);
        insert cpe;

        List<ContactPointPhone> cpp = TestDataFactory.generateContactPointPhonesFromAccounts(accs, 1);
        insert cpp;

        List<Opportunity> opp = TestDataFactory.generateOpportunitiesForEachAccount(accs, 'ZE', 'Closed', System.today().addDays(10), 1);
        insert opp;

        List<Policy__c> poliza1 = TestDataFactory.generatePoliciesForEachAccount(accs, 1);
        insert poliza1;

        List<Policy__c> poliza2 = TestDataFactory.generatePoliciesForEachOpportunity(opp, 1);
        insert poliza2;

        Claim__c cl = new Claim__c(Name='000049', PolicyHolder__c=accs[0].Id, Policy__c = poliza1[0].Id);
        insert cl;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accs, 3);
        cases[0].PolicyNum__c = poliza1[0].Name;
        cases[1].CreatedOffer__c = opp[0].Name;
        cases[2].ClaimId__c = cl.Id;
        insert cases;

        Task tk = new Task(WhatId=cases[0].Id, Status='3');
        insert tk;

    
        EmailMessage em = new EmailMessage(RelatedToId=cases[0].Id, ParentId=cases[0].Id, ActivityId=tk.Id);
        insert em;

        List<Account> accs2 = TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_BCUSTOMER, 1);
        for(Integer i = 0; accs2.size() < i; i++){
            accs2[i].FirstName = 'Test Account';
            accs2[i].LastName = '-001';
            accs2[i].RecordTypeId = BCustomerRecordTypeId;
        }
        insert accs2;
        System.debug('Business');

        Contact cont = new Contact(LastName='Contact Test', AccountId=accs2[0].Id);
        insert cont;
        System.debug('Contacto');

        Campaign camp = new Campaign(Name='Campaña test', LegalEntity__c='001');
        System.debug('Campaña');
        insert camp;

        CampaignMember cm = new CampaignMember(ContactId=cont.Id, CampaignId=camp.Id);
        insert cm;
        System.debug('CampaignMember');

        
    }
    @isTest 
    private static void comprobarPropagacionAccount()
    {
        //Actualizar los registros
        List<Account> acc = [SELECT Id, Blocked__c, Anonymized__c FROM Account WHERE Blocked__c=false AND Anonymized__c=false];
        for(Account a : acc){
            a.Anonymized__c = true;
            a.Blocked__c = true;
        }
        update acc;

        Test.startTest();
        //Lanzar Batch de Bloqueo
        Batch_GDPRPropagateBlocked batch1 = new Batch_GDPRPropagateBlocked('Account', '','','Bloquear');
        database.executeBatch(batch1, 200); 

        Batch_GDPRPropagateBlocked batch1Programado = new Batch_GDPRPropagateBlocked('Account', '', '', 'Bloquear');
        String jobID = System.schedule('Test Batch Bloqueo', '0 0 10 * * ?', batch1Programado);

        Batch_GDPRPropagateBlocked batch2 = new Batch_GDPRPropagateBlocked('Account', '','','Anonimizar');
        database.executeBatch(batch2, 200);
        
        Test.stopTest();
    }

    @isTest 
    private static void comprobarPropagacionOportunidad()
    {
        List<Opportunity> opp = [SELECT Id, Blocked__c, Anonymized__c FROM Opportunity WHERE Blocked__c=false AND Anonymized__c=false];
        for(Opportunity o: opp)
        {
            o.Anonymized__c = true;
            o.Blocked__c = true;
        }
        update opp;

        Test.startTest();

        Batch_GDPRPropagateBlocked batch1 = new Batch_GDPRPropagateBlocked('Opportunity', '','','Bloquear');
        database.executeBatch(batch1, 200);

        Batch_GDPRPropagateBlocked batch2 = new Batch_GDPRPropagateBlocked('Opportunity', '','','Anonimizar');
        database.executeBatch(batch2, 200);

        Test.stopTest();
    }

    @isTest
    private static void comprobarBorrado(){
        //Actualizar los registros a mano, cambiando el Anonymized a true
        //anonimizarDatosManual();        

        Test.startTest();
        Batch_GDPRAnonymized batchBorr = new Batch_GDPRAnonymized('','');
        database.executeBatch(batchBorr, 200);

        Batch_GDPRAnonymized batchBorrProgramado = new Batch_GDPRAnonymized('', '');
        String jobID = System.schedule('Test Batch Borrado', '0 0 10 * * ?', batchBorrProgramado);

        Test.stopTest();
        
    }

    @isTest 
    private static void comprobarExceptionBloqueo(){
        Test.startTest();

        try{
            GDPRComplianceUtil.getQuery('Account', 'Campaign', 'Bloquear');
        }catch(System.IllegalArgumentException ex)
        {
            System.assertEquals('No se puede obtener la query para el objeto: Campaign', ex.getMessage());
        }

        Test.stopTest();
    }

    @isTest
    private static void comprobarExceptionBorrado(){
        Test.startTest();

        try{
            GDPRComplianceUtil.queryFactoryBorrado('Campaign');
        }catch(System.IllegalArgumentException ex)
        {
            System.assertEquals('No se puede obtener la query para el objeto: Campaign', ex.getMessage());
        }

        Test.stopTest();
    }

    
    private static void anonimizarDatosManual(){
        //Account
        List<Account> acc = [SELECT Id, Blocked__c, Anonymized__c FROM Account WHERE Anonymized__c=false];
        for(Account a : acc){
            a.Anonymized__c = true;
        }
        update acc;

        //Opportunity
        List<Opportunity> opps = [SELECT Id, Anonymized__c FROM Opportunity WHERE Anonymized__c=false];
        for(Opportunity o : opps){
            o.Anonymized__c = true;
        }
        update opps;

        //Task
        List<Task> tsk= [SELECT Id, Anonymized__c FROM Task WHERE Anonymized__c=false];
        for(Task t: tsk){
            t.Anonymized__c = true;
        }
        update tsk;

        //EmailMessage
        List<EmailMessage> em= [SELECT Id, Anonymized__c FROM EmailMessage WHERE Anonymized__c=false];
        for(EmailMessage e: em){
            e.Anonymized__c = true;
        }
        update em;

        //Case
        List<Case> cs= [SELECT Id, Anonymized__c FROM Case WHERE Anonymized__c=false];
        for(Case c: cs){
            c.Anonymized__c = true;
        }
        update cs;

        //Claim
        List<Claim__c> cla= [SELECT Id, Anonymized__c FROM Claim__c WHERE Anonymized__c=false];
        for(Claim__c c: cla){
            c.Anonymized__c = true;
        }
        update cla;

        //Policy
        List<Policy__c> pol= [SELECT Id, Anonymized__c FROM Policy__c WHERE Anonymized__c=false];
        for(Policy__c p: pol){
            p.Anonymized__c = true;
        }
        update pol;

        //CampaignMember
        List<CampaignMember> cm= [SELECT Id, Anonymized__c FROM CampaignMember WHERE Anonymized__c=false];
        for(CampaignMember c : cm){
            c.Anonymized__c = true;
        }
        update cm;

        //Contact
        List<Contact> con = [SELECT Id, Anonymized__c FROM Contact WHERE Anonymized__c=false];
        for(Contact c: con){
            c.Anonymized__c = true;
        }
        update con;
    }
}