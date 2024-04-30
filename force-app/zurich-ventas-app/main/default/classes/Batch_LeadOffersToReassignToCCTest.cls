@isTest
public with sharing class Batch_LeadOffersToReassignToCCTest {
    @TestSetup
    static void makeData()
    {
        Lead_Offers__c leadOffer = TestDataFactory.generateLeadOfferCS();
        insert leadOffer;

        /*****************************  CUSTOM SETTINGS  ****************************/
        Cross_Selling__c ventaCruzada = new Cross_Selling__c();
        ventaCruzada.ContactCenterUser__c = 'generico';
        ventaCruzada.DefaultUser__c = 'adminkli';

        insert ventaCruzada;

        /********************************  INTERMEDIARIOS  ********************************/
        // Crear cuentas de intermediarios
        List<Account> intermediaries = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 4);
        intermediaries[0].EnableReassignmentLeadOffers__c = true;
        intermediaries[1].EnableReassignmentLeadOffers__c = true;
        intermediaries[2].EnableReassignmentLeadOffers__c = false;
        intermediaries[3].EnableReassignmentLeadOffers__c = true;
        insert intermediaries;

        // Crear contactos de intermediarios
        List<Contact> intermediaryContacts = TestDataFactory.generateContactsFromAccounts(intermediaries, ContactsSelector.RT_NAME_CONTACT, 3);
        insert intermediaryContacts;
    
        // Creamos los perfiles de los intermediarios
        String portalProfile = [SELECT Id FROM Profile WHERE Name = : ProfilesSelector.PROFILE_AGENTE_VENTAS LIMIT 1].Id;
        List<User> listUser=TestDataFactory.generateUsersByProfile(portalProfile, 3);

        // Partners - profile agente ventas
        String ccProfile = [SELECT Id FROM Profile WHERE Name = : ProfilesSelector.PROFILE_VENTAS_USER LIMIT 1].Id;
        listUser.addAll(TestDataFactory.generateUsersByProfile(ccProfile, 1));

        listUser[0].FirstName='Agente';
        listUser[0].LastName='Mediador 0';
        listUser[0].Alias='ag.med.0';
        listUser[0].ContactId = intermediaryContacts[0].Id;
        listUser[0].Username = 'agenteMediador0@nts-solutions.com.invalid';

        listUser[1].FirstName='Agente';
        listUser[1].LastName='Mediador 1';
        listUser[1].Alias='ag.med.1';
        listUser[1].ContactId = intermediaryContacts[1].Id;
        listUser[1].Username = 'agenteMediador1@nts-solutions.com.invalid';

        listUser[2].FirstName='Agente';
        listUser[2].LastName='Mediador 2';
        listUser[2].Alias='ag.med.2';
        listUser[2].ContactId = intermediaryContacts[2].Id;
        listUser[2].Username = 'agenteMediador2@nts-solutions.com.invalid';

        listUser[3].FirstName='Agente';
        listUser[3].LastName='Generico CC';
        listUser[3].Alias='generico';
        listUser[3].Username = 'agenteCC@nts-solutions.com.invalid';

        System.debug('++++ Users: ' + listUser);
        insert listUser;

        /********************************  CLIENTES  ********************************/
        // Crear cuentas de clientes
        List<Account> accounts = TestDataFactory.generateAccounts(null, 'Lead', 1);
        accounts[0].phone = '+34666999222';
        accounts[0].PreferedContactStart__c = DateTime.newInstance(2023, 11, 01, 15, 0, 0);
        accounts[0].PreferedContactEnd__c =  DateTime.newInstance(2023, 11, 20, 8, 30, 0);
        accounts[0].WebId__c = '123456A';
        insert accounts;

        /*****************************  OFERTAS  ****************************/

        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'Legit lead', System.today().addDays(3), 5);
        opportunities[0].IntermediaryId__c = intermediaries[0].Id;
        opportunities[0].ZRM__c = true;
        opportunities[1].IntermediaryId__c = intermediaries[1].Id;
        opportunities[1].ZRM__c = true;
        opportunities[2].OwnerId = listUser[1].Id;
        opportunities[2].IntermediaryId__c = intermediaries[1].Id;
        opportunities[3].OwnerId = listUser[1].Id;
        opportunities[3].IntermediaryId__c = intermediaries[1].Id;
        opportunities[3].StageName = 'Quoted';
        opportunities[4].OwnerId = listUser[2].Id;
        opportunities[4].IntermediaryId__c = intermediaries[2].Id;
        insert opportunities;

        Test.setCreatedDate(opportunities[0].Id, Date.today() - 15); //Oferta a cambiar, tiene todo lo indicado
        Test.setCreatedDate(opportunities[1].Id, Date.today() - 15); //Oferta a cambiar, tiene todo lo indicado
        Test.setCreatedDate(opportunities[2].Id, Date.today() - 5);  //Oferta se mantiene, no cumple con la restriccion de tiempo
        Test.setCreatedDate(opportunities[3].Id, Date.today() - 15); //Oferta se mantiene, no cumple con la restriccion de StageName
        Test.setCreatedDate(opportunities[4].Id, Date.today() - 15); //Oferta se mantiene, el Owner no tiene el flag activado
        upsert opportunities;

        /*****************************  ATM  ****************************/
        List<AccountTeamMember> lstATM = new List<AccountTeamMember>();
        AccountTeamMember atm1 = new AccountTeamMember();
        AccountTeamMember atm2 = new AccountTeamMember();
        AccountTeamMember atm3 = new AccountTeamMember();
        AccountTeamMember atm4 = new AccountTeamMember();

        atm1.AccountId = accounts[0].id;
        atm1.UserId = listUser[0].Id;

        atm2.AccountId = accounts[0].id;
        atm2.UserId = listUser[1].Id;

        atm3.AccountId = accounts[0].id;
        atm3.UserId = listUser[2].Id;

        atm4.AccountId = accounts[0].id;
        atm4.UserId = listUser[3].Id;

        lstATM.add(atm1);
        lstATM.add(atm2);
        lstATM.add(atm3);
        lstATM.add(atm4);

        insert lstATM;

    }

    @isTest
    private static void test_reassignOffers_ok()
    {
        List<Opportunity> offersPreBatch = [SELECT Id, ZRM__c, CreatedDate, IntermediaryId__r.EnableReassignmentLeadOffers__c, ReassignToContactCenter__c, Account.RecordType.DeveloperName, StageName, OwnerId, Owner.Name, Owner.Profile.Name, BusinessCode__c, CloseDate from Opportunity];
        List<AccountTeamMember> atmsPreBatch = [SELECT Id, AccountId, UserId FROM AccountTeamMember];

        Batch_LeadOffersToReassignToCC batch = new Batch_LeadOffersToReassignToCC();

        // Ejecución del test
        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        System.debug('+++ Despues del batch');

        Map<Id, Opportunity> offersPostBatch = new Map<Id, Opportunity>([SELECT Id, ZRM__c, CreatedDate, IntermediaryId__r.EnableReassignmentLeadOffers__c, ReassignToContactCenter__c, Account.RecordType.DeveloperName, StageName, OwnerId, Owner.Name, Owner.Profile.Name, BusinessCode__c, CloseDate from Opportunity]);
        Integer contCambios = 0;
        Integer contNoCambios = 0;
        for(Opportunity oPre : offersPreBatch)
        {
            Opportunity oPost = offersPostBatch.get(oPre.id);

            if(oPre.ZRM__c && oPre.ReassignToContactCenter__c)
            {
                // Ha de haber cambiado
                System.assertNotEquals(oPre.BusinessCode__c, oPost.BusinessCode__c, 'El BusinessCode de la oferta ha de haber cambiado');
                System.assertNotEquals(oPre.CloseDate, oPost.CloseDate, 'La fecha de cierre de la oferta ha de haber cambiado');
                contCambios++;
            }
            else
            {
                // los datos se mantienen igual
                System.assertEquals(oPre.OwnerId, oPost.OwnerId, 'El owner de la oferta no debe haber cambiado');
                System.assertEquals(oPre.BusinessCode__c, oPost.BusinessCode__c, 'El BusinessCode de la oferta no debe haber cambiado');
                System.assertEquals(oPre.CloseDate, oPost.CloseDate, 'La fecha de cierre de la oferta no debe haber cambiado');
                contNoCambios++;
            }
        }

        // Comprobamos que se han modificado las ofertas que han de hacerlo
        System.assertEquals(2, contCambios, 'No se han modificado las ofertas que tendrian que haberlo hecho');
        System.assertEquals(3, contNoCambios, 'No se han mantenido iguales las ofertas que tendrian que haberlo hecho');

        // Comprobamos que se han creado call me backs que deberían
        List<ContactRequest> cmbs = [SELECT Id, PreferredPhone FROM ContactRequest];
        System.assertEquals(false, cmbs.isEmpty(), 'Se han tenido que generar CallMeBacks');
        System.assertEquals(2, cmbs.size(), 'Se ha tenido que generar sólo una ContactRequest por la oferta que se cambia');

        
    }
}