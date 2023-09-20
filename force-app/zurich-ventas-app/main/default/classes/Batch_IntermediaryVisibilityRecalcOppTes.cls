@isTest
public with sharing class Batch_IntermediaryVisibilityRecalcOppTes {
    
    @TestSetup
    static void makeData() {
        
        /********************************  INTERMEDIARIOS  ********************************/
        // Crear custom setting que indica el usuario genérico
        Cross_Selling__c ventaCruzada = new Cross_Selling__c();
        ventaCruzada.ContactCenterUser__c = 'generico';
        ventaCruzada.DefaultUser__c = 'adminkli';

        insert ventaCruzada;

        // Crear cuentas de intermediarios
        List<Account> intermediaries = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 3);
        // Crear grupo de intermediarios
        List<Account> agrupaciones = TestDataFactory.generateAccounts(Label.GeneralInsurance,'AgrupacionMediador', 2);

        insert intermediaries;
        insert agrupaciones;

        // Crear contactos de intermediarios
        List<Contact> intermediaryContacts = TestDataFactory.generateContactsFromAccounts(intermediaries, ContactsSelector.RT_NAME_CONTACT, 1);

        insert intermediaryContacts;

        // Crear los usuarios
        List<String> adminProfiles = new List<String> {'Administrador del sistema', 'System Administrator'};
        List<Boolean> activeStatus = new List<Boolean> {true};
        User adminUser = ( new UsersSelector() ).findByProfileName(adminProfiles, activeStatus, 1)[0];

        // Create portal account owner
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];

        // Partners
        String portalProfile = [SELECT Id FROM Profile WHERE Name = 'Agente Ventas' LIMIT 1].Id;
        List<User> listUser=TestDataFactory.generateUsersByProfile(portalProfile, 2);

        listUser[0].FirstName='Agente';
        listUser[0].LastName='Mediador 1';
        listUser[0].Alias='test1Med';
        listUser[0].ContactId = intermediaryContacts[0].Id;
        listUser[1].FirstName='Agente';
        listUser[1].LastName='Mediador 2';
        listUser[1].Alias='test2Med';
        listUser[1].UserRole = portalRole;
        listUser[1].ContactId = intermediaryContacts[1].Id;

        System.runAs (adminUser)
        {
            insert listUser;
        }

        // añado cada usuario a una agrupacion y seteo su usuario principal
        List<User> communityUsers = new List<User>([SELECT Contact.AccountId FROM User WHERE Alias In ('test1Med', 'test2Med') LIMIT 2]);
        Id intermediaryAccountUser1Id = communityUsers.get(0).Contact.AccountId;
        Id intermediaryAccountUser2Id = communityUsers.get(1).Contact.AccountId;

        // asociar los mediadores con cuenta a cada una de las agrupaciones
        Account intermediaryUser1 = new Account();
        intermediaryUser1.Id = intermediaryAccountUser1Id;
        intermediaryUser1.IntermediaryGroup__c = agrupaciones.get(0).Id;

        Account intermediaryUser2 = new Account();
        intermediaryUser2.Id = intermediaryAccountUser2Id;
        intermediaryUser2.IntermediaryGroup__c = agrupaciones.get(1).Id;

        // informar el mediador principal de las agrupaciones
        Account agrupacion1 = new Account();
        agrupacion1.Id = agrupaciones.get(0).Id;
        agrupacion1.IntermediaryWithUser__c = intermediaryAccountUser1Id;

        Account agrupacion2 = new Account();
        agrupacion2.Id = agrupaciones.get(1).Id;
        agrupacion2.IntermediaryWithUser__c = intermediaryAccountUser2Id;

        
        // asociar el mediador sin usuario a una agrupacion
        List<Account> accountWithUserToAssignGroup = new List<Account>();
        accountWithUserToAssignGroup.add(intermediaryUser1);
        accountWithUserToAssignGroup.add(intermediaryUser2);

        Account intermediaryWithNoUser = [SELECT Id FROM Account WHERE Id NOT IN :accountWithUserToAssignGroup LIMIT 1];
        intermediaryWithNoUser.IntermediaryGroup__c = agrupacion1.Id;

        List<Account> accountToUpdate = new List<Account>();
        accountToUpdate.add(intermediaryUser1);
        accountToUpdate.add(intermediaryUser2);
        accountToUpdate.add(agrupacion1);
        accountToUpdate.add(agrupacion2);
        accountToUpdate.add(intermediaryWithNoUser);

        update accountToUpdate;


        // Crear una oferta asociada al los mediadores de la agrupacion 1 (2 en total)
        List<Account> customers = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 2);
        insert customers;


        List<Account> mediadoresAgrupacion1 = new List<Account>([SELECT Id FROM Account WHERE IntermediaryGroup__c = :agrupacion1.Id]);
        List<Opportunity> offerList = TestDataFactory.generateOpportunitiesForEachAccount(customers, 'Ventas', 'Legit Lead', Date.today(), 1);

        offerList[0].IntermediaryId__c = mediadoresAgrupacion1[0].Id;
        offerList[1].IntermediaryId__c = mediadoresAgrupacion1[1].Id;        

        insert offerList;

    }


    /**
     * Test que comprueba que un mediador sin usuario nominal cambia de agrupación, sus registros de offer se deben de trasladar al nuevo usuario principal de la nueva agrupación
     * @author dmunoz
     * @date 19/09/2023
     */
    @isTest
    static void testCambioAgrupacionMedidadorNotPartnerOK() {
        Opportunity opBefore = [SELECT Id, IntermediaryVisibilityAcc__c, IntermediaryId__c, IntermediaryId__r.IntermediaryGroup__c FROM Opportunity WHERE IntermediaryId__r.IsPartner = false];
        System.debug('Valor antes ' + opBefore.IntermediaryVisibilityAcc__c);

        // cambio el mediador de agrupacion para que el batch recalcule la visibilidad, para ello obtengo el id de la otra agrupación primero
        List<Account> customerList = new List<Account>([SELECT Id FROM Account WHERE Recordtype.DeveloperName = 'AgrupacionMediador' AND Id != :opBefore.IntermediaryId__r.IntermediaryGroup__c]);

        if (!customerList.isEmpty()) {

            // actualizo el mediador
            Account mediatorNotPartner = new Account();
            mediatorNotPartner.Id = opBefore.IntermediaryId__c;
            mediatorNotPartner.IntermediaryGroup__c = customerList.get(0).Id;
            update mediatorNotPartner;


            Test.startTest();
            Batch_IntermediaryVisibilityRecalcOpp batch = new Batch_IntermediaryVisibilityRecalcOpp();
            Database.executeBatch(batch, 200);
            Test.stopTest();
    
            Opportunity opAfter = [SELECT Id, IntermediaryVisibilityAcc__c FROM Opportunity WHERE Id = :opBefore.Id];
            System.debug('Valor despues ' + opAfter.IntermediaryVisibilityAcc__c);
            System.assertNotEquals(opBefore.IntermediaryVisibilityAcc__c, opAfter.IntermediaryVisibilityAcc__c, 'Debe haberse modificado el valor del campo de visibilidad');
        }
    }


    /**
     * Test que blanquea la visibilidad para un cliente que se ha bloqueado por gdpr
     * @author dmunoz
     * @date 19/09/2023
     */
    @isTest
    static void testGDPRBlankVisibilityOK() {
        Opportunity opBefore = [SELECT Id, IntermediaryVisibilityAcc__c, AccountId FROM Opportunity WHERE IntermediaryId__r.IsPartner = false];
        System.debug('Valor antes ' + opBefore.IntermediaryVisibilityAcc__c);

        // consulto el cliente de la oportunidad
        List<Account> customerList = new List<Account>([SELECT Id FROM Account WHERE Id = :opBefore.AccountId]);

        if (!customerList.isEmpty()) {

            // actualizo el cliente
            Account customer = new Account();
            customer.Id = customerList.get(0).Id;
            customer.Blocked__c = true;
            update customer;


            Test.startTest();
            Batch_IntermediaryVisibilityRecalcOpp batch = new Batch_IntermediaryVisibilityRecalcOpp();
            Database.executeBatch(batch, 200);
            Test.stopTest();
    
            Opportunity opAfter = [SELECT Id, IntermediaryVisibilityAcc__c FROM Opportunity WHERE Id = :opBefore.Id];
            System.debug('Valor despues ' + opAfter.IntermediaryVisibilityAcc__c);
            System.assertEquals(null, opAfter.IntermediaryVisibilityAcc__c, 'Debe haberse modificado el valor del campo de visibilidad');
        }
    }


    /**
     * Test que recalcula la visibilidad a partir de una lista de ids
     * @author dmunoz
     * @date 19/09/2023
     */
    @isTest
    static void testRecalculateVisibilityGivenAccountListOK() {
        Opportunity opBefore = [SELECT Id, IntermediaryVisibilityAcc__c, AccountId FROM Opportunity WHERE IntermediaryId__r.IsPartner = true];
        System.debug('Valor antes ' + opBefore.IntermediaryVisibilityAcc__c);

        // cambio el mediador de agrupacion para que el batch recalcule la visibilidad, para ello obtengo el id de la otra agrupación primero
        List<Account> customerList = new List<Account>([SELECT Id,Blocked__c FROM Account LIMIT 50]);

        if (!customerList.isEmpty()) {
            List<Account> customerToUpdate = new List<Account>();
            Set<String> customerIds = new Set<String>();
            for (Account customer: customerList) {
                customer.Blocked__c = true;
                customerToUpdate.add(customer);
                customerIds.add(Customer.Id);
            }

            update customerToUpdate;
            

            Test.startTest();
            Batch_IntermediaryVisibilityRecalcOpp batch = new Batch_IntermediaryVisibilityRecalcOpp(customerIds);
            Database.executeBatch(batch, 200);
            Test.stopTest();
    
            Opportunity opAfter = [SELECT Id, IntermediaryVisibilityAcc__c FROM Opportunity WHERE Id = :opBefore.Id];
            System.debug('Valor despues ' + opAfter.IntermediaryVisibilityAcc__c);
            System.assertNotEquals(opBefore.IntermediaryVisibilityAcc__c, opAfter.IntermediaryVisibilityAcc__c, 'Debe haberse modificado el valor del campo de visibilidad');
        }
    }
}