@isTest
public with sharing class Batch_IntermediaryVisibilityRecalcPolTes {
    
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


        // Crear una oferta póliza a los mediadores de la agrupacion 1 (2 en total)
        List<Account> customers = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 2);
        insert customers;

        List<Account> mediadoresAgrupacion1 = new List<Account>([SELECT Id FROM Account WHERE IntermediaryGroup__c = :agrupacion1.Id]);
        List<Policy__c> policyList = TestDataFactory.generatePoliciesForEachAccount(customers, 1);
        policyList[0].IntermediaryId__c = mediadoresAgrupacion1[0].Id;
        policyList[1].IntermediaryId__c = mediadoresAgrupacion1[1].Id; 

        insert policyList;

    }


    /**
     * Test que comprueba que un mediador sin usuario nominal cambia de agrupación, sus registros de policy se deben de trasladar al nuevo usuario principal de la nueva agrupación
     * @author dmunoz
     * @date 19/09/2023
     */
    @isTest
    static void testCambioAgrupacionMedidadorNotPartnerOK() {
        Policy__c polBefore = [SELECT Id, IntermediaryVisibilityAcc__c, IntermediaryId__c, IntermediaryId__r.IntermediaryGroup__c FROM Policy__c WHERE IntermediaryId__r.IsPartner = false];

        // cambio el mediador de agrupacion para que el batch recalcule la visibilidad, para ello obtengo el id de la otra agrupación primero
        List<Account> agrupacionMediadorList = new List<Account>([SELECT Id FROM Account WHERE Recordtype.DeveloperName = 'AgrupacionMediador' AND Id != :polBefore.IntermediaryId__r.IntermediaryGroup__c]);

        if (!agrupacionMediadorList.isEmpty()) {

            // actualizo el mediador
            Account mediatorNotPartner = new Account();
            mediatorNotPartner.Id = polBefore.IntermediaryId__c;
            mediatorNotPartner.IntermediaryGroup__c = agrupacionMediadorList.get(0).Id;
            update mediatorNotPartner;


            Test.startTest();
            Batch_IntermediaryVisibilityRecalcPol batch = new Batch_IntermediaryVisibilityRecalcPol();
            Database.executeBatch(batch, 200);
            Test.stopTest();
    
            Policy__c polAfter = [SELECT Id, IntermediaryVisibilityAcc__c FROM Policy__c WHERE Id = :polBefore.Id];
            System.assertNotEquals(polBefore.IntermediaryVisibilityAcc__c, polAfter.IntermediaryVisibilityAcc__c, 'Debe haberse modificado el valor del campo de visibilidad a la nueva cuenta');
        }
    }


    /**
     * Test que blanquea la visibilidad para un cliente que se ha bloqueado por gdpr
     * @author dmunoz
     * @date 19/09/2023
     */
    @isTest
    static void testGDPRBlankVisibilityOK() {
        Policy__c polBefore = [SELECT Id, IntermediaryVisibilityAcc__c, PolicyHolder__c FROM Policy__c WHERE IntermediaryId__r.IsPartner = false];

        // consulto el cliente de la póliza
        List<Account> agrupacionMediadorList = new List<Account>([SELECT Id FROM Account WHERE Id = :polBefore.PolicyHolder__c]);

        if (!agrupacionMediadorList.isEmpty()) {

            // actualizo el cliente
            Account customer = new Account();
            customer.Id = agrupacionMediadorList.get(0).Id;
            customer.Blocked__c = true;
            update customer;


            Test.startTest();
            Batch_IntermediaryVisibilityRecalcPol batch = new Batch_IntermediaryVisibilityRecalcPol();
            Database.executeBatch(batch, 200);
            Test.stopTest();
    
            Policy__c polAfter = [SELECT Id, IntermediaryVisibilityAcc__c FROM Policy__c WHERE Id = :polBefore.Id];
            System.assertEquals(null, polAfter.IntermediaryVisibilityAcc__c, 'Debe haberse modificado el valor del campo de visibilidad');
        }
    }


    /**
     * Test que recalcula la visibilidad a partir de una lista de ids
     * @author dmunoz
     * @date 19/09/2023
     */
    @isTest
    static void testRecalculateVisibilityGivenAccountListOK() {
        Policy__c polBefore = [SELECT Id, IntermediaryVisibilityAcc__c, PolicyHolder__c FROM Policy__c WHERE IntermediaryId__r.IsPartner = true];
        System.debug('Valor antes ' + polBefore.IntermediaryVisibilityAcc__c);

        // cambio el mediador de agrupacion para que el batch recalcule la visibilidad, para ello obtengo el id de la otra agrupación primero
        List<Account> agrupacionMediadorList = new List<Account>([SELECT Id,Blocked__c FROM Account LIMIT 50]);

        if (!agrupacionMediadorList.isEmpty()) {
            List<Account> customerToUpdate = new List<Account>();
            Set<String> customerIds = new Set<String>();
            for (Account customer: agrupacionMediadorList) {
                customer.Blocked__c = true;
                customerToUpdate.add(customer);
                customerIds.add(Customer.Id);
            }

            update customerToUpdate;
            

            Test.startTest();
            Batch_IntermediaryVisibilityRecalcPol batch = new Batch_IntermediaryVisibilityRecalcPol(customerIds);
            Database.executeBatch(batch, 200);
            Test.stopTest();
    
            Policy__c polAfter = [SELECT Id, IntermediaryVisibilityAcc__c FROM Policy__c WHERE Id = :polBefore.Id];
            System.debug('Valor despues ' + polAfter.IntermediaryVisibilityAcc__c);
            System.assertNotEquals(polBefore.IntermediaryVisibilityAcc__c, polAfter.IntermediaryVisibilityAcc__c, 'Debe haberse modificado el valor del campo de visibilidad');
        }
    }
}