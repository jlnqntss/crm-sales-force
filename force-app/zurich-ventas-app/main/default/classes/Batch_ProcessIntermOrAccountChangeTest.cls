@isTest
public with sharing class Batch_ProcessIntermOrAccountChangeTest
{

    /**
     * @author fpalomo
     * @date 11/04/2024
     */
    @TestSetup
    static void makeData()
    {
        // CUSTOM SETTINGS
        Cross_Selling__c ventaCruzada = new Cross_Selling__c();
        ventaCruzada.ContactCenterUser__c = 'generico';
        ventaCruzada.DefaultUser__c = 'adminkli';
        insert ventaCruzada;

        // ACCOUNTS (Agrupaciones)
        List<Account> agrupaciones = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'AgrupacionMediador', 1);

        // ACCOUNTS (Mediadores)
        List<Account> intermediaries = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Intermediary', 3);

        List<Account> accToInsert = new List<Account>();
        accToInsert.addAll(intermediaries);
        accToInsert.addAll(agrupaciones);
        insert accToInsert;
        
        // CONTACTOS (Mediadores)
        List<Contact> intermediaryContacts = TestDataFactory.generateContactsFromAccounts(intermediaries, ContactsSelector.RT_NAME_CONTACT, 1);
        insert intermediaryContacts;

        // USUARIOS
        List<String> adminProfiles = new List<String> {'Administrador del sistema', 'System Administrator'};
        List<Boolean> activeStatus = new List<Boolean> {true};
        
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        String portalProfile = [SELECT Id FROM Profile WHERE Name = 'Agente Ventas' LIMIT 1].Id;
        
        User adminUser = (new UsersSelector()).findByProfileName(adminProfiles, activeStatus, 1)[0];
        List<User> intermediaryUsers = TestDataFactory.generateUsersByProfile(portalProfile, 2);
        
        for (Integer i = 0; i < intermediaryUsers.size(); i++)
        {
            User usr = intermediaryUsers[i];
            usr.FirstName = 'Agente';
            usr.LastName = 'MN' + (i+1);
            usr.Alias = 'MN' + (i+1);
            usr.ContactId = intermediaryContacts[i].Id;
        }
        
        System.runAs (adminUser)
        {
            insert intermediaryUsers;
        }

        // CONFIGURACIÓN DE MEDIADORES
        intermediaryUsers = new List<User>([SELECT Contact.AccountId FROM User WHERE Alias LIKE 'MN%']);

        List<Account> agrIntermediaries = new List<Account>();
        List<Account> nomIntermediaries = new List<Account>();
        
        // asociar los mediadores con cuenta a cada una de las agrupaciones
        Account intermediaryUser1 = new Account();
        intermediaryUser1.Id = intermediaryUsers[0].Contact.AccountId;
        intermediaryUser1.IntermediaryGroup__c = agrupaciones[0].Id;
        nomIntermediaries.add(intermediaryUser1);
        
        Account intermediaryUser2 = new Account();
        intermediaryUser2.Id = intermediaryUsers[1].Contact.AccountId;
        intermediaryUser2.IntermediaryGroup__c = agrupaciones[0].Id;
        nomIntermediaries.add(intermediaryUser2);
        
        // informar el mediador principal de las agrupaciones
        Account intermediaryAGR1 = new Account();
        intermediaryAGR1.Id = agrupaciones[0].Id;
        intermediaryAGR1.IntermediaryWithUser__c = intermediaryUsers[1].Contact.AccountId;
        agrIntermediaries.add(intermediaryAGR1);
        
        update nomIntermediaries;
        update agrIntermediaries;
        
        // ACCOUNTS (Clientes)
        List<Account> mediadoresAgrupacion1 = new List<Account>([SELECT Id FROM Account WHERE IntermediaryGroup__c = :agrIntermediaries[0].Id]);
        List<Account> customers = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 2);
        
        for (Integer i = 0; i < customers.size(); i++)
        {
        	customers[i].Intermediary_Name__c = mediadoresAgrupacion1[0].Id;
        }
        
        insert customers;
        
        // PÓLIZAS
        // Creamos una póliza solo para uno de los Accounts del paso anterior
        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(customers, 1);
        for (Integer i = 0; i < policies.size(); i++)
        {
            Policy__c policy = policies[i];
            policy.IntermediaryId__c = nomIntermediaries[0].Id;
            policy.PolicyStatus__c = 'V';
            policy.Anonymized__c = false;
            policy.Blocked__c = false;
            
        	policy.LastDateIntermediaryOrAccountChange__c = System.today()-1;
        	policy.VisibilityRetry__c = 0;
        }
        
        policies[0].ZRMMovementType__c = Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_CLIENTE;
        policies[0].LastAccountId__c = (policies[0].PolicyHolder__c == customers[0].Id) ? customers[1].Id : customers[0].Id;
        policies[1].ZRMMovementType__c = Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_MEDIADOR;
        policies[1].LastAccountId__c = nomIntermediaries[1].Id;
        
        insert policies;
        
        // OFERTAS
        // Creamos una oferta solo para uno de los Accounts del paso anterior
        List<Opportunity> offers = TestDataFactory.generateOpportunitiesForEachAccount(customers, 'Ventas', 'New', System.today().addDays(10), 1);
        for (Opportunity offer: offers)
        {
            offer.IntermediaryId__c = nomIntermediaries[0].Id;
            offer.ZRM__c = true;
            
            offer.LastDateIntermediaryOrAccountChange__c = System.today()-1;
            offer.VisibilityRetry__c = 0;
        }
        
        offers[0].ZRMMovementType__c = Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_MEDIADOR;
        offers[0].LastAccountId__c = (offers[0].AccountId == customers[0].Id) ? customers[1].Id : customers[0].Id;
        offers[1].ZRMMovementType__c = Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_CLIENTE;
        offers[1].LastAccountId__c = nomIntermediaries[1].Id;
        
        insert offers;
    }

    /**
     * @author fpalomo
     * @date 11/04/2024
     */
    @IsTest
    static void testBatchWithOffersMovementTypeCustomer()
    {
        List<Opportunity> offers = [
            SELECT IntermediaryId__c, AccountId, VisibilityRetry__c, ZRMMovementType__c, LastDateIntermediaryOrAccountChange__c, LastAccountId__c
            FROM Opportunity
            WHERE ZRMMovementType__c = :Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_CLIENTE
        ];
        
        System.debug('fpalomo#Offers:');
        for (Opportunity o : offers)
        {
            System.debug(o);
        }
        
        Test.startTest();
        Database.executeBatch(new Batch_ProcessIntermediaryOrAccountChange(offers, 1000));
        Test.stopTest();
        
        List<Error_Log__c> errorlog = [SELECT Message__c, Stack_Trace__c, Source_Class__c FROM Error_Log__c];
        System.debug(errorLog);
        
        List<AccountTeamMember> atmAfter = [SELECT Id FROM AccountTeamMember];
        Assert.isTrue(atmAfter.size() > 0, 'No se han creado los ATMs');
    }

    /**
     * @author fpalomo
     * @date 11/04/2024
     */
    @IsTest
    static void testBatchWithPoliciesMovementTypeCustomer()
    {
        List<Policy__c> policies = [
            SELECT IntermediaryId__c, PolicyHolder__c, VisibilityRetry__c, ZRMMovementType__c, LastDateIntermediaryOrAccountChange__c, LastAccountId__c
            FROM Policy__c
            WHERE ZRMMovementType__c = :Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_CLIENTE
        ];
        
        System.debug('fpalomo#Policies:');
        for (Policy__c p : policies)
        {
            System.debug(p);
        }
        
        Test.startTest();
        Database.executeBatch(new Batch_ProcessIntermediaryOrAccountChange(policies, 1000));
        Test.stopTest();
        
        List<Error_Log__c> errorlog = [SELECT Message__c, Stack_Trace__c, Source_Class__c FROM Error_Log__c];
        System.debug(errorLog);
        
        List<AccountTeamMember> atmAfter = [SELECT Id FROM AccountTeamMember];
        Assert.isTrue(atmAfter.size() > 0, 'No se han creado los ATMs');
    }

    /**
     * @author fpalomo
     * @date 11/04/2024
     */
    @IsTest
    static void testBatchWithOffersMovementTypeIntermediary()
    {
        List<Opportunity> offers = [
            SELECT IntermediaryId__c, AccountId, VisibilityRetry__c, ZRMMovementType__c, LastDateIntermediaryOrAccountChange__c, LastAccountId__c
            FROM Opportunity
            WHERE ZRMMovementType__c = :Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_MEDIADOR
        ];
        
        System.debug('fpalomo#Offers:');
        for (Opportunity o : offers)
        {
            System.debug(o);
        }
        
        Test.startTest();
        Database.executeBatch(new Batch_ProcessIntermediaryOrAccountChange(offers, 1000));
        Test.stopTest();
        
        List<Error_Log__c> errorlog = [SELECT Message__c, Stack_Trace__c, Source_Class__c FROM Error_Log__c];
        System.debug(errorLog);
        
        List<AccountTeamMember> atmAfter = [SELECT Id FROM AccountTeamMember];
        Assert.isTrue(atmAfter.size() > 0, 'No se han creado los ATMs');
    }

    /**
     * @author fpalomo
     * @date 11/04/2024
     */
    @IsTest
    static void testBatchWithPoliciesMovementTypeIntermediary()
    {
        List<Policy__c> policies = [
            SELECT IntermediaryId__c, PolicyHolder__c, VisibilityRetry__c, ZRMMovementType__c, LastDateIntermediaryOrAccountChange__c, LastAccountId__c
            FROM Policy__c
            WHERE ZRMMovementType__c = :Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_MEDIADOR
        ];
        
        System.debug('fpalomo#Policies:');
        for (Policy__c p : policies)
        {
            System.debug(p);
        }
        
        Test.startTest();
        Database.executeBatch(new Batch_ProcessIntermediaryOrAccountChange(policies, 1000));
        Test.stopTest();
        
        List<Error_Log__c> errorlog = [SELECT Message__c, Stack_Trace__c, Source_Class__c FROM Error_Log__c];
        System.debug(errorLog);
        
        List<AccountTeamMember> atmAfter = [SELECT Id FROM AccountTeamMember];
        Assert.isTrue(atmAfter.size() > 0, 'No se han creado los ATMs');
    }

    /**
     * @author fpalomo
     * @date 11/04/2024
     */
    @IsTest
    static void testBatchKo()
    {
        List<Policy__c> policies = [SELECT Id FROM Policy__c];
        
        Test.startTest();
        Database.executeBatch(new Batch_ProcessIntermediaryOrAccountChange(policies, 1000));
        Test.stopTest();
        
        List<Error_Log__c> errorlog = [SELECT Message__c, Stack_Trace__c, Source_Class__c FROM Error_Log__c];
        Assert.isTrue(errorlog.size() > 0, 'Se debería haber generado al menos un error log');
    }
}