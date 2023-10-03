@isTest
public with sharing class Batch_IntermediaryVisbtyAccActivitesTest {
    
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


        // Crear clientes y asociarlos a una agrupacion
        List<Account> customers = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 2);
        
        List<Account> mediadoresAgrupacion1 = new List<Account>([SELECT Id FROM Account WHERE IntermediaryGroup__c = :agrupacion1.Id]);
        customers[0].Intermediary_Name__c = mediadoresAgrupacion1[0].Id;
        customers[1].Intermediary_Name__c = mediadoresAgrupacion1[1].Id;         
        
        insert customers;


        // Crear Tareas y asociarlas a cada cliente
        List<Contact> contactList = new List<Contact>([SELECT Id FROM Contact WHERE AccountId IN :customers]);
        List<Task> taskList = TestDataFactory.generateInteractionTasks(2);
        taskList[0].WhoId = contactList[0].Id;
        taskList[1].WhoId = contactList[1].Id;

        taskList[0].WhatId = customers[0].Id;
        taskList[1].WhatId = customers[1].Id;
        
        // owner debe ser un usuario zrm
        User u = [SELECT Id FROM User WHERE Profile.Name = 'Agente Ventas' AND IsActive = TRUE LIMIT 1];

        taskList[0].OwnerId = u.Id;
        taskList[1].OwnerId = u.Id;

        insert taskList;

    }


    /**
     * Test que al bloquear un cliente se debe comprobar que la tarea ha cambiado de owner
     * @author dmunoz
     * @date 29/09/2023
     */
    @isTest
    static void testGDPRBlankVisibilityOK() {
        Account customer = [SELECT Id FROM Account WHERE Recordtype.DeveloperName = 'Customer' LIMIT 1];
        Task taskBefore = [SELECT Id, PriorIntermediaryOwner__c, OwnerId, AccountId FROM Task WHERE AccountId = :customer.Id];

        // update customers a bloqueado
        customer.Blocked__c = true;
        update customer;

        // Añado el cliente a un set
        Set<String> accountIds = new Set<String>();
        accountIds.add(customer.Id);
        
        Test.startTest();
        Batch_IntermediaryVisibilityAccActivites batch = new Batch_IntermediaryVisibilityAccActivites(accountIds);
        Database.executeBatch(batch, 200);
        Test.stopTest();

        Task taskAfter = [SELECT Id, PriorIntermediaryOwner__c, OwnerId FROM Task WHERE Id = :taskBefore.Id]; 
        System.assertNotEquals(taskBefore.OwnerId, taskAfter.OwnerId, 'Debe haberse modificado el valor del campo Owner');
    }
}