@isTest
public class ZRMOpportunityMatchBatchTest {
    @TestSetup
    static void makeData(){
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 2);
        insert accounts;

        List<Account> leadAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Lead', 1);
        insert leadAccounts;


        List<Opportunity> optys = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 2);
        List<Opportunity> optysFromLeads = TestDataFactory.generateOpportunitiesForEachAccount(leadAccounts, 'General', 'New', System.today().addDays(10), 2);

        insert optys;
        insert optysFromLeads; 

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 2);
        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, 2);
        
        
        insert contactPointEmails;
        insert contactPointPhones;

        List<Campaign> campaigns = TestDataFactory.generateCampaigns('000', 1);

        insert campaigns;
        /** Insertar usuarios ZRM ***************************************************************/
        // Crear cuentas de agrupacion
        List<Account> agrupaciones = TestDataFactory.generateAccounts(Label.GeneralInsurance,'AgrupacionMediador', 1);
        insert agrupaciones;
        // Crear cuentas de mediadores
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 2);
        intermediaryAccounts.get(0).IntermediaryGroup__c = agrupaciones.get(0).Id;
        intermediaryAccounts.get(0).Name = 'MediadorTest';
        intermediaryAccounts.get(1).Name = 'MediadorTest2';
        insert intermediaryAccounts;

        // Crear contactos de mediadores
        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(intermediaryAccounts, ContactsSelector.RT_NAME_CONTACT, 2);
        insert contacts;

        // Crear los usurios para recuperar
        List<User> userList = new List<User>();
        List<User> userAGRList = new List<User>();

        List<String> adminProfiles = new List<String> {'Administrador del sistema', 'System Administrator'};
        List<Boolean> activeStatus = new List<Boolean> {true};
        User adminUser = ( new UsersSelector() ).findByProfileName(adminProfiles, activeStatus, 1)[0];

        System.runAs (adminUser)
        {
            // Usuario Nominal
            String portalProfile = [SELECT Id FROM Profile WHERE Name = 'Agente Ventas' LIMIT 1].Id;

            userList = TestDataFactory.generateUsersByProfile(portalProfile, 1);
            userList[0].ContactId = contacts[0].Id;
            insert userList;

            // Usuario AGR
            String portalAGRProfile = [SELECT Id FROM Profile WHERE Name = 'Agente Ventas - AGR' LIMIT 1].Id;

            userAGRList = TestDataFactory.generateUsersByProfile(portalAGRProfile, 1);
            userAGRList[0].ContactId = contacts[1].Id;

            insert userAGRList;
        }
    }

    @isTest
    public static void mergeOffer_OK()
    {
        List<Account> accounts = [SELECT Name FROM Account];

        List<Opportunity> optys = [SELECT ID, AccountId, IntermediaryId__c, IntermediaryId__r.IntermediaryGroup__c,
                                        ProductBranch__c 
            FROM Opportunity
            WHERE Account.RecordType.DeveloperName = 'BusinessCustomer'];

        List<Campaign> campaigns = TestDataFactory.generateCampaigns('000', 1);

        insert campaigns;

        optys[0].Description = 'Test descripcion';
        optys[0].CampaignId = campaigns[0].Id;

        update optys;

        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();
        Test.startTest();
        zrmOppMatchBatch.mergeOffer(optys[1], optys[0]);
        Test.stopTest();

        Assert.areEqual(optys[0].Description, optys[1].Description);
        Assert.areEqual(optys[0].CampaignId, optys[1].CampaignId);
        Assert.areEqual(optys[1].StageName, 'Quoted');
        
    }

    @isTest
    public static void moveRelatedObjectToScopeOffers_WithTask_OK()
    {
        Map<String, String> matchIdByScopeId = new Map<String, String>();
        List<Opportunity> optys = [SELECT ID, AccountId, IntermediaryId__c, IntermediaryId__r.IntermediaryGroup__c,
                                        ProductBranch__c 
            FROM Opportunity
            WHERE Account.RecordType.DeveloperName = 'BusinessCustomer'];
        List<Task> tasks = new List<Task>();

        matchIdByScopeId.put(optys[0].Id, optys[1].Id);

        Task task0 = new Task();
            task0.Status = 'Nueva';
            task0.WhatId = optys[1].Id;
            task0.Subject = 'test status';
            task0.Type='Email';
            task0.Subtype__c='Note Info';

            tasks.add(task0);

        Task task2 = new Task();
            task2.Status = 'Nueva';
            task2.WhatId = optys[1].Id;
            task2.Subject = 'test status';
            task2.Type='Email';
            task2.Subtype__c='Note Info';

            tasks.add(task2);
        
        insert tasks;

        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();
        Test.startTest();
        update zrmOppMatchBatch.moveTasksToScopeOffers(matchIdByScopeId);
        Test.stopTest();

        List<Task> movedTask = [SELECT Id FROM Task WHERE WhatId = :optys[0].Id];

        Assert.areEqual(movedTask.size(), tasks.size());
    }

    @isTest
    public static void moveRelatedObjectToScopeOffers_WithEvents_OK()
    {
        List<Opportunity> optys = [SELECT ID, AccountId, IntermediaryId__c, IntermediaryId__r.IntermediaryGroup__c,
                                        ProductBranch__c 
            FROM Opportunity
            WHERE Account.RecordType.DeveloperName = 'BusinessCustomer'];
        Map<String, String> matchIdByScopeId = new Map<String, String>();
        List<Event> events = new List<Event>();

        matchIdByScopeId.put(optys[0].Id, optys[1].Id);

        Event e = new Event();
            e.subject = 'EventTest';
            e.EventType__c = 'Call';
            e.RelatedToIntermediary__c = 'No';
            e.DurationInMinutes = 60;
            e.ActivityDateTime = DateTime.now();
            e.WhatId = optys[1].Id;

        Event e1 = new Event();
            e1.subject = 'EventTest';
            e1.EventType__c = 'Call';
            e1.RelatedToIntermediary__c = 'No';
            e1.DurationInMinutes = 60;
            e1.ActivityDateTime = DateTime.now().addDays(1);
            e1.WhatId = optys[1].Id;

        events.add(e);
        events.add(e1);

        insert events;
        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();

        Test.startTest();
        update zrmOppMatchBatch.moveEventsToScopeOffers(matchIdByScopeId);
        Test.stopTest();

        List<Event> movedEvents = [SELECT Id FROM Event WHERE WhatId = :optys[0].Id];

        Assert.areEqual(movedEvents.size(), events.size());
    }

    @isTest
    public static void getDataFromOpportunities_OK()
    {
        List<Opportunity> optys = [SELECT ID, AccountId, IntermediaryId__c, IntermediaryId__r.IntermediaryGroup__c,
                                        ProductBranch__c 
            FROM Opportunity
            WHERE Account.RecordType.DeveloperName = 'BusinessCustomer'];

        Map<String, Object> result;
        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();

        Test.startTest();
        result = zrmOppMatchBatch.getDataFromOpportunities(optys);
        Test.stopTest();

    }

    @isTest
    public static void calculateClientOpportunitiesWithMatch_OK()
    {
        List<Opportunity> optys = [SELECT ID, AccountId, IntermediaryId__c, IntermediaryId__r.IntermediaryGroup__c,
                                        ProductBranch__c 
            FROM Opportunity
            WHERE Account.RecordType.DeveloperName = 'BusinessCustomer'];

        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();
        Map<String, Object> opportunityDataMap = zrmOppMatchBatch.getDataFromOpportunities(optys);
        Test.startTest();
        zrmOppMatchBatch.calculateClientOpportunitiesWithMatch(optys, opportunityDataMap);
        Test.stopTest();
    }

    @isTest
    public static void matchConditions_OK(){
        List<Opportunity> optys = [SELECT ID, AccountId, IntermediaryId__c, IntermediaryId__r.IntermediaryGroup__c 
            FROM Opportunity
            WHERE Account.RecordType.DeveloperName = 'BusinessCustomer' LIMIT 2];
        User zrmIntermediary = [SELECT Id, Contact.AccountId FROM User WHERE Profile.Name = 'Agente Ventas' AND Contact.Account.Name = 'MediadorTest' LIMIT 1];

        for(Opportunity opp : optys)
        {
            opp.ProductBranch__c = '0000000001';
            opp.IntermediaryId__c = zrmIntermediary.Contact.AccountId;
        }
        update optys;

        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();

        Boolean result;

        Test.startTest();
        result = zrmOppMatchBatch.matchConditions(optys[0], optys[1]);
        Test.stopTest();

        Assert.areEqual(true, result);
    }

    @isTest
    public static void matchConditions_KO(){
        List<Opportunity> optys = [SELECT ID, AccountId, IntermediaryId__c, IntermediaryId__r.IntermediaryGroup__c 
            FROM Opportunity
            WHERE Account.RecordType.DeveloperName = 'BusinessCustomer' LIMIT 2];

        for(Opportunity opp : optys)
        {
            opp.ProductBranch__c = '0000000001';
        }
        update optys;

        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();

        Boolean result;
        Test.startTest();
        result = zrmOppMatchBatch.matchConditions(optys[0], optys[1]);
        Test.stopTest();

        Assert.areEqual(false, result);
    }

    @isTest 
    public static void execute_ok()
    {
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'BusinessCustomer' LIMIT 2];
        List<Account> leadAccounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Lead'];
        User zrmIntermediary = [SELECT Id, Contact.AccountId FROM User WHERE Profile.Name = 'Agente Ventas' AND Contact.Account.Name = 'MediadorTest' LIMIT 1];
        
        List<Opportunity> optys = [SELECT ID FROM Opportunity WHERE Account.RecordType.DeveloperName = 'BusinessCustomer'];
        List<Opportunity> optysFromLeads = [SELECT ID FROM Opportunity WHERE Account.RecordType.DeveloperName = 'Lead'];
        
        List<ContactPointPhone> contactPointPhones = [SELECT Id, TelephoneNumber FROM contactPointPhone];
        Map<String, String> matchIdByScopeId = new Map<String, String>();
        List<Event> events = new List<Event>();
        List<Task> tasks = new List<Task>();

        for(Opportunity opp : optys)
        {
            opp.ProductBranch__c = '0000000001';
            opp.IntermediaryId__c = zrmIntermediary.Contact.AccountId;
            opp.StageName = 'Legit Lead';
            opp.InfoQuoteNumber__c = null;
            Test.setCreatedDate(opp.Id, System.today().addDays(-40));

        }
        
        optys[1].PotentialMatch__c = true;
        optys[3].PotentialMatch__c = true;
        
        update optys;

        Event e = new Event();
            e.subject = 'EventTest';
            e.EventType__c = 'Call';
            e.RelatedToIntermediary__c = 'No';
            e.DurationInMinutes = 60;
            e.ActivityDateTime = DateTime.now();
            e.WhatId = optys[0].Id;

        Event e1 = new Event();
            e1.subject = 'EventTest';
            e1.EventType__c = 'Call';
            e1.RelatedToIntermediary__c = 'No';
            e1.DurationInMinutes = 60;
            e1.ActivityDateTime = DateTime.now().addDays(1);
            e1.WhatId = optys[2].Id;

        events.add(e);
        events.add(e1);

        insert events;

        Task task0 = new Task();
            task0.Status = 'Nueva';
            task0.WhatId = optys[0].Id;
            task0.Subject = 'test status';
            task0.Type='Email';
            task0.Subtype__c='Note Info';
            tasks.add(task0);

            
            Task task2 = new Task();
            task2.Status = 'Nueva';
            task2.WhatId = optys[2].Id;
            task2.Subject = 'test status';
            task2.Type='Email';
            task2.Subtype__c='Note Info';
            
            tasks.add(task2);
        
        insert tasks;
        
     
        String query =  new OpportunitiesSelector().getQueryStringPotentialMatchOpportunities();
        Test.startTest();
        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch(query);
        Id jobId = Database.executeBatch(zrmOppMatchBatch, 200);
        Test.stopTest();

        //Si pasan a Quoted significa que se han mergeado correctamente
        Map<Id, Opportunity> quotedOffers = new Map<Id, Opportunity>([SELECT Id, Name FROM Opportunity WHERE StageName = 'Quoted']);

        //Comprobamos si las tareas y los eventos se han relacionado a las ofertas pasadas a Quoted
        List<Task> movedTasks = [SELECT Id FROM Task WHERE WhatId IN :quotedOffers.keySet()];
        List<Event> movedEvents = [SELECT Id FROM Event WHERE WhatId IN :quotedOffers.keySet()];

        Assert.areEqual(quotedOffers.values().size(), 2);
        Assert.areEqual(movedEvents.size(), events.size());
        Assert.areEqual(movedTasks.size(), tasks.size());

    }

    @isTest
    public static void execute_withLeads_ok()
    {
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'BusinessCustomer' LIMIT 2];
        List<Account> leadAccounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Lead'];
        User zrmIntermediary = [SELECT Id, Contact.AccountId FROM User WHERE Profile.Name = 'Agente Ventas' AND Contact.Account.Name = 'MediadorTest' LIMIT 1];
        
        List<Opportunity> optys = [SELECT ID FROM Opportunity WHERE Account.RecordType.DeveloperName = 'BusinessCustomer'];
        List<Opportunity> optysFromLeads = [SELECT ID FROM Opportunity WHERE Account.RecordType.DeveloperName = 'Lead'];
        
        List<ContactPointPhone> contactPointPhones = [SELECT Id, TelephoneNumber FROM contactPointPhone];
        
        

        for (ContactPointPhone cpp : contactPointPhones) 
        {
            leadAccounts[0].Phone = cpp.TelephoneNumber;
        }
        
        
        
        for(Opportunity opp : optys)
        {
            opp.ProductBranch__c = '0000000001';
            opp.IntermediaryId__c = zrmIntermediary.Contact.AccountId;
            opp.StageName = 'Legit Lead';
            opp.InfoQuoteNumber__c = null;
            opp.PotentialMatch__c = true;
            Test.setCreatedDate(opp.Id, System.today().addDays(-40));

        }

        for(Opportunity opp : optysFromLeads)
        {
            opp.ProductBranch__c = '0000000001';
            opp.IntermediaryId__c = zrmIntermediary.Contact.AccountId;
            opp.StageName = 'Legit Lead';
            opp.InfoQuoteNumber__c = null;
            Test.setCreatedDate(opp.Id, System.today().addDays(-40));

        }


        Test.setCreatedDate(leadAccounts[0].Id, System.today().addDays(-45));

        update leadAccounts;
        update optys;
        update optysFromLeads;

        String query =  new OpportunitiesSelector().getQueryStringPotentialMatchOpportunities();
        
        Test.startTest();
        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch(query);
        Id jobId = Database.executeBatch(zrmOppMatchBatch, 200);
        Test.stopTest();

        Map<Id, Opportunity> quotedOffers = new Map<Id, Opportunity>([SELECT Id, Name FROM Opportunity WHERE StageName = 'Quoted']);
        List<Account> resultLeads = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Lead'];
        Assert.areEqual(true, resultLeads.isEmpty());
    }

    @isTest
    public static void checkMatchMap_notInMatchMap()
    {
        Map<String, Opportunity> matchMap = new Map<String, Opportunity>();
        List<Opportunity> optys = [SELECT ID, campaignId FROM Opportunity WHERE Account.RecordType.DeveloperName = 'BusinessCustomer'];

        Boolean result;

        Test.startTest();
        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();
        result = zrmOppMatchBatch.checkMatchMap(matchMap, optys[0], optys[1]);
        Test.stopTest();

        Assert.areEqual(true, result);
    }

    @isTest
    public static void checkMatchMap_checkCampaign()
    {
        Map<String, Opportunity> matchMap = new Map<String, Opportunity>();
        List<Opportunity> optys = [SELECT ID, campaignId FROM Opportunity WHERE Account.RecordType.DeveloperName = 'BusinessCustomer'];
        List<Campaign> campaigns = [SELECT Id FROM Campaign LIMIT 1];

        system.debug(optys);
        system.debug(campaigns);
        optys[1].campaignId = campaigns[0].Id;

        update optys;

        matchMap.put(optys[0].Id, optys[1]);

        Boolean result;

        Test.startTest();
        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();
        result = zrmOppMatchBatch.checkMatchMap(matchMap, optys[0], optys[1]);
        Test.stopTest();

        Assert.areEqual(true, result);
    }

    @isTest
    public static void checkMatchMap_scopeInMatch()
    {
        Map<String, Opportunity> matchMap = new Map<String, Opportunity>();
        List<Opportunity> optys = [SELECT ID, campaignId, CreatedDate FROM Opportunity WHERE Account.RecordType.DeveloperName = 'BusinessCustomer'];
        List<Campaign> campaigns = [SELECT Id FROM Campaign LIMIT 1];

        system.debug(optys);
        system.debug(campaigns);
        
        matchMap.put(optys[0].Id, optys[1]);
        Boolean result;
        update optys;
        Test.setCreatedDate(optys[1].Id, System.today().addDays(-40));
        List<Opportunity> modifiedOpp = [SELECT Id, campaignId, CreatedDate FROM Opportunity WHERE CreatedDate = :System.today().addDays(-40)];

        Test.startTest();
        
        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();
        result = zrmOppMatchBatch.checkMatchMap(matchMap, optys[0], modifiedOpp[0]);
        Test.stopTest();

        Assert.areEqual(true, result);
    }

    @isTest
    public static void getOpportunitiesWithContactInfoDate_ok()
    {
        Map<String, Account> accountMap = new Map<String, Account>([SELECT Id FROM Account WHERE RecordType.DeveloperName = 'BusinessCustomer']);
        List<Opportunity> optys = [SELECT ID, AccountId FROM Opportunity WHERE AccountId IN :accountMap.keySet()];

        Map<Opportunity,Set<String>> opportunitiesWithContactInfoData = new Map<Opportunity,Set<String>>();
        for(Opportunity opp : optys)
        {
            opportunitiesWithContactInfoData.put(opp, null);
        }

        Test.startTest();
        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();
        Map<Opportunity,Set<String>> result = zrmOppMatchBatch.getOpportunitiesWithContactInfoData(optys, accountMap.keySet());
        Test.stopTest();

        //:TODO Este assert queda retocardo
        Assert.areEqual(opportunitiesWithContactInfoData.keySet(), result.keySet());
    }

    @isTest
    public static void checkIzZRM_isZRM()
    {
        List<Scope_Setting__mdt> scopeMDT = Scope_Setting__mdt.getAll().values();
        Map<String, String> scopeMdtMap = new Map<String, String>();

        for(Scope_Setting__mdt scope : scopeMDT)
        {
            scopeMdtMap.put(scope.BusinessCode__c, scope.Scope__c);
        }

        List<Opportunity> offer = [SELECT ID, BusinessCode__c, ZRM__c FROM Opportunity WHERE ZRM__c = TRUE];

        Boolean result;

        Test.startTest();
        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();
        result = zrmOppMatchBatch.checkIsZRM(offer[0], scopeMdtMap);
        Test.stopTest();

        Assert.areEqual(true, result);
    }

    @isTest
    public static void checkIzZRM_checkBusinessCode()
    {
        List<Scope_Setting__mdt> scopeMDT = Scope_Setting__mdt.getAll().values();
        Map<String, String> scopeMdtMap = new Map<String, String>();

        for(Scope_Setting__mdt scope : scopeMDT)
        {
            scopeMdtMap.put(scope.BusinessCode__c, scope.Scope__c);
        }

        List<Opportunity> offer = [SELECT ID, BusinessCode__c, ZRM__c FROM Opportunity WHERE ZRM__c = TRUE];

        offer[0].ZRM__c = false; //Forzamos que no sea ZRM

        Boolean result;

        Test.startTest();
        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();
        result = zrmOppMatchBatch.checkIsZRM(offer[0], scopeMdtMap);
        Test.stopTest();

        Assert.areEqual(true, result);
    }

    @isTest
    public static void checkIzZRM_notZRM()
    {
        List<Scope_Setting__mdt> scopeMDT = Scope_Setting__mdt.getAll().values();
        Map<String, String> scopeMdtMap = new Map<String, String>();

        for(Scope_Setting__mdt scope : scopeMDT)
        {
            scopeMdtMap.put(scope.BusinessCode__c, scope.Scope__c);
        }

        List<Opportunity> offer = [SELECT ID, BusinessCode__c, ZRM__c FROM Opportunity WHERE ZRM__c = TRUE];

        offer[0].ZRM__c = false; //Forzamos que no sea ZRM
        offer[0].BusinessCode__c = 'NotZRM';
         
        Boolean result;

        Test.startTest();
        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();
        result = zrmOppMatchBatch.checkIsZRM(offer[0], scopeMdtMap);
        Test.stopTest();

        Assert.areEqual(false, result);
    }

    @isTest
    public static void getScopeMDT_ok()
    {
        List<Scope_Setting__mdt> scopeMDT = Scope_Setting__mdt.getAll().values();
        Map<String, String> scopeMdtMap = new Map<String, String>();
        Map<String, String> resultScopeMdtMap = new Map<String, String>();
        for(Scope_Setting__mdt scope : scopeMDT)
        {
            scopeMdtMap.put(scope.BusinessCode__c, scope.Scope__c);
        }

        Test.startTest();
        ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();
        resultScopeMdtMap = zrmOppMatchBatch.getScopeMDT();
        Test.stopTest();

        Assert.areEqual(scopeMdtMap, resultScopeMdtMap);
    }

    @isTest
    public static void leadMatchesOpportunity_true()
    {
        List<Account> leadAccount = [SELECT Id, CreatedDate, Phone, PersonEmail FROM Account WHERE RecordType.DeveloperName = 'Lead' LIMIT 1];
        List<Opportunity> offer = [SELECT Id, AccountId, CreatedDate FROM Opportunity WHERE Account.RecordType.DeveloperName = 'BusinessCustomer' LIMIT 1];
        List<ContactPointPhone> contactPointPhones = [SELECT Id, TelephoneNumber FROM ContactPointPhone WHERE ParentId = :offer[0].AccountId]; 
        List<ContactPointEmail> contactPointEmails = [SELECT Id, EmailAddress FROM ContactPointEmail WHERE ParentId = :offer[0].AccountId];
        Set<String> contactDataInfo = new Set<String>();

        for(ContactPointPhone cpp : contactPointPhones)
        {
            contactDataInfo.add(cpp.TelephoneNumber);
        }

        for(ContactPointEmail cpe : contactPointEmails)
        {
            contactDataInfo.add(cpe.EmailAddress);
        }

        leadAccount[0].Phone = contactPointPhones[0].TelephoneNumber;
        leadAccount[0].PersonEmail = contactPointEmails[0].EmailAddress;

        Boolean result;

        Test.startTest();
            ZRMOpportunityMatchBatch zrmOppMatchBatch = new ZRMOpportunityMatchBatch();
            result = zrmOppMatchBatch.leadMatchesOpportunity(leadAccount[0], offer[0], contactDataInfo);
        Test.stopTest();

        Assert.areEqual(true, result);

        

    }
}