/* Clase de test que comprueba la creación de una nueva task asociada a una oferta y la 
asignación del owner a la oferta
@author: arcortazar
@date: 04/03/2022
*/

@isTest
public with sharing class Test_ClosedWinOfferByUser {

    // Corremos el test como SysAdmin, tiene que funcionar bien.

    @isTest
    static void test_runAsSysAdmin() {
        Account acc = new Account(Name = 'New Account 1');
        insert acc;

        Product2 p = new Product2
        (
            Name = 'Product test 1',
            GroupDescription__c = 'Group 1'
        );
        insert p;

        Contact customer = new Contact(
            Email = 'edu@test.com',
            MobilePhone = '675887723',
            DNI__c = '05289654W',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = 'GI-3123',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerGI),
            AccountId = acc.Id
            );
        insert customer;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Name = 'New Opportunity',
            CloseDate = Date.today().addDays(3),
            TotalOpportunityQuantity = 10,
            BusinessCode__c = '1234',
            ProductId__c = p.Id, 
            StageName = 'Closed Won');
        insert opp;

        // Creamos la task asociada a la oferta cerrada -> Tiene que funcionar
        
        Task interactionTask = new Task(
            Subject = 'Llamada ' + Datetime.now().format(),
            Status = 'Nueva',
            Priority = 'Normal',
            CallObject = 'ABCD12345',
            WhoId = customer.Id,
            TaskSubtype = 'Call',
            Type = 'Call', 
            OwnerId = UserInfo.getUserId(),
            WhatId = opp.Id
        );
    
        Test.startTest();
        insert interactionTask;
        Test.stopTest();

        // Comprobamos que se haya modificado la oferta
        List<Opportunity> oportunidades  = [SELECT Id, Name, OwnerId FROM Opportunity WHERE StageName like 'Closed Won']; 
        System.assertEquals(1, oportunidades.size(), 'Ha de haber una oferta insertada');
        System.assertEquals(UserInfo.getUserId(), oportunidades.get(0).OwnerId, 'EL owner de la oferta ha de ser el usuario que corre el test');

        // Comprobamos que se haya insertado la task
        List<Task> tareas = [SELECT Id, OwnerId FROM Task WHERE WhatId = :oportunidades.get(0).id];
        System.assertEquals(1, tareas.size(), 'Ha de haber una tarea insertada para la oferta de la que disponemos');
    }

    // Corremos el test como User que es ZE Supervisor, tiene que funcionar bien.
    @isTest
    static void test_runAsZEUser_SupervisorTrue() {

        // Agustín Zapata tiene a True el flag "isZESupervisor__c"
        User u = [SELECT Id, IsZESupervisor__c FROM User WHERE Name='Agustin Angel Zapata Mendez'];
        System.runAs(u) {
            // The following code runs as user 'u'
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Is ZE Supervisor: ' + u.IsZESupervisor__c);

            Account acc = new Account(Name = 'New Account 1');
            insert acc;

            Contact customer = new Contact(
            Email = 'edu@test.com',
            MobilePhone = '675887723',
            DNI__c = '05289654W',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = 'GI-3123',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerGI),
            AccountId = acc.Id
            );
        
            insert customer;

            Product2 p = new Product2
            (
                Name = 'Product test 1',
                GroupDescription__c = 'Group 1',
                INFO_Product_Number__c = '00800-00001'
            );
            insert p;

            Opportunity opp = new Opportunity(
                AccountId = acc.Id,
                Name = 'New Opportunity',
                CloseDate = Date.today().addDays(3),
                TotalOpportunityQuantity = 10,
                BusinessCode__c = '1234',
                ProductId__c = p.Id, 
                StageName = 'Closed Won');
            insert opp;

            // Creamos la task asociada a la oferta cerrada -> Tiene que funcionar
            
            Task interactionTask = new Task(
                Subject = 'Llamada ' + Datetime.now().format(),
                Status = 'Nueva',
                Priority = 'Normal',
                CallObject = 'ABCD12345',
                WhoId = customer.Id,
                TaskSubtype = 'Call',
                Type = 'Call', 
                OwnerId = u.Id,
                WhatId = opp.Id
            );
        
            Test.startTest();
            insert interactionTask;
            Test.stopTest();
        }

        // Comprobamos que se haya modificado la oferta
        List<Opportunity> oportunidades  = [SELECT Id, Name, OwnerId FROM Opportunity WHERE StageName like 'Closed Won']; 
        System.assertEquals(1, oportunidades.size(), 'Ha de haber una oferta insertada');
        System.assertEquals(u.id, oportunidades.get(0).OwnerId, 'EL owner de la oferta ha de ser el usuario que corre el test');

        // Comprobamos que se haya insertado la task
        List<Task> tareas = [SELECT Id, OwnerId FROM Task WHERE WhatId = :oportunidades.get(0).id];
        System.assertEquals(1, tareas.size(), 'Ha de haber una tarea insertada para la oferta de la que disponemos');

    }

    // Corremos el test como User que no es ZE Supervisor, pero como no cambiamos de OwnerId a la oferta, tiene que funcionar bien.
    @isTest
    static void test_runAsZEUser_SupervisorFalse_OK() {

        // Julio Fabeiro Garcia tiene a True el flag "isZESupervisor__c"
        User u = [SELECT Id, IsZESupervisor__c FROM User WHERE Name='Julio Fabeiro Garcia'];

        System.runAs(u) {

            // The following code runs as user 'u'
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Is ZE Supervisor: ' + u.IsZESupervisor__c);

            Account acc = new Account(Name = 'New Account 1');
            insert acc;

            Contact customer = new Contact(
            Email = 'edu@test.com',
            MobilePhone = '675887723',
            DNI__c = '05289654W',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = 'GI-3123',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerGI),
            AccountId = acc.Id
            );
        
            insert customer;

            Product2 p = new Product2
            (
                Name = 'Product test 1',
                GroupDescription__c = 'Group 1',
                INFO_Product_Number__c = '00800-00001'
            );
            insert p;

            User u2 = [SELECT Id FROM User WHERE Name='Agustin Angel Zapata Mendez'];

            Opportunity opp = new Opportunity(
                AccountId = acc.Id,
                Name = 'New Opportunity',
                CloseDate = Date.today().addDays(3),
                TotalOpportunityQuantity = 10,
                BusinessCode__c = '1234',
                ProductId__c = p.Id, 
                StageName = 'Closed Won',
                OwnerId = u.Id);
            insert opp;

            // Creamos la task asociada a la oferta cerrada -> Tiene que funcionar
            
            Task interactionTask = new Task(
                Subject = 'Llamada ' + Datetime.now().format(),
                Status = 'Nueva',
                Priority = 'Normal',
                CallObject = 'ABCD12345',
                WhoId = customer.Id,
                TaskSubtype = 'Call',
                Type = 'Call', 
                OwnerId = u.Id,
                WhatId = opp.Id
            );
        
            Test.startTest();
            insert interactionTask;
            Test.stopTest();
        }

        // Comprobamos que se haya modificado la oferta
        List<Opportunity> oportunidades  = [SELECT Id, Name, OwnerId FROM Opportunity WHERE StageName like 'Closed Won']; 
        System.assertEquals(1, oportunidades.size(), 'Ha de haber una oferta insertada');
        System.assertEquals(u.id, oportunidades.get(0).OwnerId, 'El owner de la oferta ha de ser el usuario que corre el test');

        // Comprobamos que se haya insertado la task
        List<Task> tareas = [SELECT Id, OwnerId FROM Task WHERE WhatId = :oportunidades.get(0).id];
        System.assertEquals(1, tareas.size(), 'La oferta se ha debido de insertar bien');
    }


    // Corremos el test como User que no es ZE Supervisor, pero como cambiamos de OwnerId a la oferta, tiene que fallar.

    @isTest
    static void test_runAsZEUser_SupervisorFalse_NOK() {

        // Julio Fabeiro Garcia tiene a True el flag "isZESupervisor__c"
        User u = [SELECT Id, IsZESupervisor__c FROM User WHERE Name='Julio Fabeiro Garcia'];

        System.runAs(u) {

            // The following code runs as user 'u'
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Is ZE Supervisor: ' + u.IsZESupervisor__c);

            Account acc = new Account(Name = 'New Account 1');
            insert acc;

            Contact customer = new Contact(
            Email = 'edu@test.com',
            MobilePhone = '675887723',
            DNI__c = '05289654W',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = 'GI-3123',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerGI),
            AccountId = acc.Id
            );
        
            insert customer;

            Product2 p = new Product2
            (
                Name = 'Product test 1',
                GroupDescription__c = 'Group 1',
                INFO_Product_Number__c = '00800-00001'
            );
            insert p;

            User u2 = [SELECT Id FROM User WHERE Name='Agustin Angel Zapata Mendez'];

            Opportunity opp = new Opportunity(
                AccountId = acc.Id,
                Name = 'New Opportunity',
                CloseDate = Date.today().addDays(3),
                TotalOpportunityQuantity = 10,
                BusinessCode__c = '1234',
                ProductId__c = p.Id, 
                StageName = 'Closed Won',
                OwnerId = u2.Id);
            insert opp;

            // Creamos la task asociada a la oferta cerrada -> Tiene que funcionar
            
            Task interactionTask = new Task(
                Subject = 'Llamada ' + Datetime.now().format(),
                Status = 'Nueva',
                Priority = 'Normal',
                CallObject = 'ABCD12345',
                WhoId = customer.Id,
                TaskSubtype = 'Call',
                Type = 'Call', 
                OwnerId = u.Id,
                WhatId = opp.Id
            );
        
            Test.startTest();
            try
            {
                insert interactionTask;
            }
            catch(DmlException e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
                System.assert( e.getMessage().contains('INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY'), e.getMessage());
            }

            Test.stopTest();
        }

        // Comprobamos que se haya modificado la oferta
        List<Opportunity> oportunidades  = [SELECT Id, Name, OwnerId FROM Opportunity WHERE StageName like 'Closed Won']; 
        System.assertEquals(1, oportunidades.size(), 'Ha de haber una oferta insertada');
        System.assertNotEquals(u.id, oportunidades.get(0).OwnerId, 'El owner de la oferta ha de ser el usuario que corre el test');

        // Comprobamos que se haya insertado la task
        List<Task> tareas = [SELECT Id, OwnerId FROM Task WHERE WhatId = :oportunidades.get(0).id];
        System.assertEquals(0, tareas.size(), 'No se ha debido de insertar la oferta');
    }
}
