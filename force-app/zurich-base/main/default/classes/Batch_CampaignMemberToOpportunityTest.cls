/**
 * Clase de test para el batch Batch_CampaignMemberToOpportunity
 * @author nts (jfherrero)
 * @date 27/07/2023
 */

 @IsTest(SeeAllData=false)
 private with sharing class Batch_CampaignMemberToOpportunityTest
 {
 
     @TestSetup
     private static void makeData()
     {
 
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
         
         /********************************  CLIENTES  ********************************/
         // Crear cuentas de clientes
         List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;
 
         /********************************  Poliza  ********************************/
 
         User zrmIntermediary = [SELECT Id, Contact.AccountId FROM User WHERE Profile.Name = 'Agente Ventas' AND  Contact.Account.Name = 'MediadorTest' LIMIT 1];
 
         List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);        
         policies[0].IntermediaryId__c = zrmIntermediary.Contact.AccountId;
 
         insert policies;
 
         /*****************************  CUSTOM SETTINGS  ****************************/
         Cross_Selling__c ventaCruzada = new Cross_Selling__c();
         ventaCruzada.ContactCenterUser__c = 'generico';
         ventaCruzada.DefaultUser__c = 'adminkli';
 
         insert ventaCruzada;
 
         /********************************  CAMPAÑAS  ********************************/
         List<Campaign> campaigns = TestDataFactory.generateCampaigns('001', 1);
         
         for (Campaign c: campaigns) {
             c.Type = 'Cross Selling';
             c.IsActive = true;
             c.StartDate = Date.today() + 1;
             c.EndDate = Date.today() + 7;
             c.ExternalId__c = 'TestCampaign';
         }
 
         insert campaigns;
 
         // generate campaign member status
         List<Campaign> campaignTest = [SELECT Id FROM Campaign WHERE ExternalId__c = 'TestCampaign'];
         List<String> newStatusList = new List<String>();
         newStatusList.add('Pdte. Revisión Mediador');
         newStatusList.add('Gestión CC');
 
         List<CampaignMemberStatus> cmsList = TestDataFactory.generateCampaignStatus(newStatusList, campaignTest.get(0).Id);
         insert cmsList;       
         
     }
 
     @IsTest
     private static void test_CampaignMemberToOpportunityTest_OK()
     {
 
         
 
         // Insertamos campaign members
         // Obtener 
         Account mediador = [SELECT Id, INFOIntermediaryCode__c FROM Account where Name = 'MediadorTest'];
         List<Account> accounts = new List<Account>([SELECT Id, PersonContactId FROM Account WHERE RecordType.DeveloperName = 'Customer']);
         List<Campaign> campaignTest = [SELECT Id FROM Campaign WHERE ExternalId__c = 'TestCampaign'];
         
         // generate campaign member
         List<CampaignMember> campaignMembersToInsert = TestDataFactory.generateCampaignMembersForEachCampaign(accounts, campaignTest, 'Pdte. Revisión Mediador');
         for (CampaignMember cm: campaignMembersToInsert) {
             cm.LeadPhone__c = '600000000';
             cm.OfferAssignedCode__c = mediador.INFOIntermediaryCode__c;
             cm.OfferAssignedType__c = 'CC';
         }
         insert campaignMembersToInsert;         
         
         // Primero se van a borrar las oportunidades que se pudiesen haber generado automáticamente por el flow
         // si, éste está activo, al insertar los miembros de Campaña
         
         List<Opportunity> opportunitiesGenerated = [SELECT Id, CampaignId, OwnerId, IntermediaryId__c, IntermediaryCode__c, CreatedDate, CreatedBy.Name FROM Opportunity];
         
         delete opportunitiesGenerated;
         
         // Recuperamos los miembros de campaña para lanzar el batch
         
         List<CampaignMember> campaignMembers = [SELECT Id, ContactId, CampaignId, OfferAssignedCode__c
                                                 FROM CampaignMember WHERE Id IN : campaignMembersToInsert];
         
         Set<Id> campaignMembersIdSet = ( new Map<Id,CampaignMember>(campaignMembers) ).keySet();
         
         System.debug('DMM_1 ' + campaignMembers);
         
         Batch_CampaignMemberToOpportunity batch = new Batch_CampaignMemberToOpportunity(campaignMembersIdSet);
         
         // Ejecución del test
         
         Test.startTest();
         Database.executeBatch(batch);
         Test.stopTest();
         
         // Obtención de los datos para hacer la comprobación de las inserciones
         // Hay que tener en cuenta que sólo se crean ofertas para campañas de venta cruzada
         
         opportunitiesGenerated = [SELECT Id, CampaignId, OwnerId, IntermediaryId__c, IntermediaryCode__c, CreatedDate, CreatedBy.Name FROM Opportunity];
         
         campaignMembers = [SELECT Id, ContactId, CampaignId, OfferAssignedCode__c
                            FROM CampaignMember
                            WHERE Campaign.Type = 'Cross Selling'];
         
         System.assert(opportunitiesGenerated.size() > 0, 'Se han de crear ofertas asociadas a las campañas de cross selling' );
     }
 
 }