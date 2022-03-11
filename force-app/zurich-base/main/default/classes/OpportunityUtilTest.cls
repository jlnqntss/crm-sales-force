@isTest
private class OpportunityUtilTest
{
    @TestSetup
    static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;
    }

    /**
     * Test que comprueba la generación del ámbito correspondiente para cada oferta
     *
     * @author adelgado
     * @date 09/12/2020
     */
    @isTest
    static void test_generateScope()
    {
        List<Account> accounts = [SELECT Name FROM Account];

        List<Opportunity> optys = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 2);

        for(Integer i = 0; i < optys.size(); i++)
        {
            optys[i].InfoQuoteNumber__c = String.valueOf(i);
        }

        Test.startTest();
        insert optys;
        Test.stopTest();

        List<Scope__c> scopes = [SELECT Id, Name FROM Scope__c WHERE AccountId__c IN : accounts];
        List<Opportunity> optysUpdated = [SELECT Scope__c, ScopeId__c FROM Opportunity];

        System.assertEquals(10, scopes.size(), 'No se han generado todos los ámbitos necesarios');

        for(Opportunity opty : optysUpdated)
        {
            System.assert (String.isNotBlank(opty.Scope__c), 'No se ha informado la picklist de scope');
            System.assert (opty.ScopeId__c != null, 'No se ha asignado el scope correspondiente');
        }
    }

    /**
     * Método de test que comprueba que la oportunidad NO esta Cerrada Ganada
     * 
     * @author arcortazar - nts
     * @date 10/03/2022
     */
    @isTest
    static void test_isValidStageName_OK() 
    {
        List<Account> accounts = [SELECT Name FROM Account LIMIT 1];

        Opportunity opp = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 1).get(0);
        insert opp;

        Boolean salida;
        Test.startTest();
        salida = OpportunityUtil.isValidStageName(opp);
        Test.stopTest();

        System.assertEquals(true, salida, 'La oferta que hemos creado no debe ser Cerrada Ganada');
    }

    /**
     * Método de test que comprueba que la oportunidad SI está cerrada ganada
     * 
     * @author arcortazar - nts
     * @date 10/03/2022
     */
    @isTest
    static void test_isValidStageName_NOK() 
    {
        List<Account> accounts = [SELECT Name FROM Account LIMIT 1];

        Opportunity opp = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'Closed won', System.today().addDays(10), 1).get(0);
        insert opp;

        Boolean salida;
        Test.startTest();
        salida = OpportunityUtil.isValidStageName(opp);
        Test.stopTest();

        System.assertEquals(false, salida, 'La oferta que hemos creado si debe ser Cerrada Ganada');
    }

    /**
     * Método de test que comprueba que se hace correctamente el bypass debido al perfil. 
     * 
     * @author arcortazar - nts
     * @date 10/03/2022
     */
    @isTest
    static void test_skipStageNameValidation_byProfile_OK() 
    {

        User u = [Select Id FROM User WHERE Name like 'Integrator'];

        List<Account> accounts = [SELECT Name FROM Account LIMIT 1];

        Opportunity opp = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'Closed won', System.today().addDays(10), 1).get(0);
        insert opp;

        // Primera parte, ha de hacer el skip debido a que el perfil del usuario lo permite
        Boolean salida;
        System.runAs(u)
        {
            Test.startTest();
            salida = OpportunityUtil.skipStageNameValidation(opp);
            Test.stopTest();
        }
        System.assertEquals(true, salida, 'Se debe hacer el bypass debido al perfil (Integrator)');
    }

    /**
     * Método de test que comprueba que se hace correctamente el Bypass debido al Custom Permisson
     * 
     * @author arcortazar - nts
     * @date 10/03/2022
     */
    @isTest
    static void test_skipStageNameValidation_byCustomPermisson_OK() 
    {
        List<Account> accounts = [SELECT Name FROM Account LIMIT 1];

        Opportunity opp = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'Closed won', System.today().addDays(10), 1).get(0);
        insert opp;

        Boolean salida;
        User u = [Select Id FROM User WHERE Name like 'Agustin Angel Zapata Mendez'];
        System.runAs(u)
        {
            Test.startTest();
            salida = OpportunityUtil.skipStageNameValidation(opp);
            Test.stopTest();
        }
        System.assertEquals(true, salida, 'Este usuario tiene los Custom Permission adecuados para hacer el bypass');
    }

    /**
     * Método de test que comprueba que se hace correctamente el Bypass debido al flag de reasignación
     * 
     * @author arcortazar - nts
     * @date 10/03/2022
     */
    @isTest
    static void test_skipStageNameValidation_byHasBeenReassigned_OK() 
    {
        List<Account> accounts = [SELECT Name FROM Account LIMIT 1];

        Opportunity opp = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'Closed won', System.today().addDays(10), 1).get(0);
        opp.HasBeenReassigned__c = true;
        insert opp;
        User u = [Select Id FROM User WHERE Name like 'Nestor Neira Bellisco'];
        Boolean salida;
        System.runAs(u)
        {
            Test.startTest();
            salida = OpportunityUtil.skipStageNameValidation(opp);
            Test.stopTest();
        }

        System.assertEquals(true, salida, 'Debe pasar el bypass debido al flag de HasBeenReassigned__c');
    }

    /**
     * Método de test que comprueba que no se lleva a cabo el bypass debido a que no se da ninguna de las condiciones.
     * 
     * @author arcortazar - nts
     * @date 10/03/2022
     */
    @isTest
    static void test_skipStageNameValidation_NOK() 
    {
        List<Account> accounts = [SELECT Name FROM Account LIMIT 1];

        Opportunity opp = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'Closed won', System.today().addDays(10), 1).get(0);
        opp.HasBeenReassigned__c = false;
        insert opp;

        User u = [Select Id FROM User WHERE Name like 'Nestor Neira Bellisco'];
        Boolean salida;
        System.runAs(u)
        {
            Test.startTest();
            salida = OpportunityUtil.skipStageNameValidation(opp);
            Test.stopTest();
        }

        System.assertEquals(false, salida, 'No debe pasar el bypass debido al flag de HasBeenReassigned__c');
    }

    /**
     * Método de test que comprueba que se hace un update de la oportunidad utilizando uno de los perfiles bypaseados (En este caso, sysadmin).
     * @author arcortazar
     * @date 09/03/2022
     * 
     */
    @isTest
    static void test_runAsSysAdmin_OK() 
    {
        // Setup del test
        List<Account> accounts = [SELECT Name FROM Account LIMIT 1];

        Opportunity opp = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 1).get(0);
        insert opp;

        opp.OwnerId = UserInfo.getUserId();
        opp.HasBeenReassigned__c = true;
        
        // Lanzamos el test, modificamos la oferta 
        Test.startTest();
        upsert opp;
        Test.stopTest();

        // Comprobamos que se haya modificado la oferta
        List<Opportunity> oportunidades  = [SELECT Id, Name, OwnerId, HasBeenReassigned__c FROM Opportunity]; 
        System.assertEquals(1, oportunidades.size(), 'Ha de haber una oferta insertada');

        System.assertEquals(UserInfo.getUserId(), oportunidades.get(0).OwnerId, 'EL owner de la oferta ha de ser el usuario que corre el test');
        System.assertEquals(false, oportunidades.get(0).HasBeenReassigned__c, 'El flag debe haberse modificado');
    }

    /**
     * Método de test que comprueba que se hace un update de la oportunidad utilizando un perfil supervisor.
     * @author arcortazar
     * @date 09/03/2022
     * 
     */
    @isTest
    static void test_runAsSupervisor_OK() 
    {
        // Obtenemos los diferentes usuarios: supervisor y no supervisor
        User uSup = [SELECT Id FROM User WHERE Name='Agustin Angel Zapata Mendez'];

        // Creamos la oportunidad que vamos a manejar en el test
        List<Account> accounts = [SELECT Name FROM Account LIMIT 1];

       Product2 p = new Product2
            (
                Name = 'Product test 1',
                GroupDescription__c = 'Group 1',
                INFO_Product_Number__c = '00800-00001'
            );
        insert p;

        Opportunity opp = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 1).get(0);
        opp.BusinessCode__c = '123456';
        opp.InfoQuoteNumber__c = '123456';
        opp.OwnerId = uSup.Id;
        opp.ProductId__c = p.Id;
        insert opp;

        // Modificamos la oportunidad
        opp.HasBeenReassigned__c = true;

        System.runAs(uSup)
        {   
            // Lanzamos el test, modificamos la oferta 
            Test.startTest();
            upsert opp;
            Test.stopTest();
        }

        // Comprobamos que se haya modificado la oferta
        List<Opportunity> oportunidades  = [SELECT Id, Name, OwnerId, HasBeenReassigned__c FROM Opportunity]; 
        System.assertEquals(1, oportunidades.size(), 'Ha de haber una oferta insertada');

        System.assertEquals(uSup.Id, oportunidades.get(0).OwnerId, 'EL owner de la oferta ha de ser el usuario que corre el test');
        System.assertEquals(false, oportunidades.get(0).HasBeenReassigned__c, 'El flag debe haberse modificado');
    }

    /**
     * Método de test que comprueba que se hace un update de la oportunidad utilizando un perfil no supervisor, mediante el bypass de HassBeenReassigned
     * @author arcortazar
     * @date 09/03/2022
     * 
     */
    @isTest
    static void test_runNotAsSupervisor_OK() 
    {
       // Obtenemos los diferentes usuarios: supervisor y no supervisor
       User uNoSup = [SELECT Id FROM User WHERE Name='Nestor Neira Bellisco'];

       // Creamos la oportunidad que vamos a manejar en el test
       List<Account> accounts = [SELECT Name FROM Account LIMIT 1];

       Product2 p = new Product2
            (
                Name = 'Product test 1',
                GroupDescription__c = 'Group 1',
                INFO_Product_Number__c = '00800-00001'
            );
        insert p;

       Opportunity opp = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 1).get(0);
       opp.BusinessCode__c = '123456';
       opp.InfoQuoteNumber__c = '123456';
       opp.OwnerId = uNoSup.Id;
       opp.ProductId__c = p.Id;
       insert opp;

       // Modificamos la oportunidad
       opp.HasBeenReassigned__c = true;

       System.runAs(uNoSup)
       {   
           // Lanzamos el test, modificamos la oferta 
           Test.startTest();
           upsert opp;
           Test.stopTest();
       }

        // Comprobamos que se haya modificado la oferta
        List<Opportunity> oportunidades  = [SELECT Id, Name, OwnerId, HasBeenReassigned__c FROM Opportunity]; 
        System.assertEquals(1, oportunidades.size(), 'Ha de haber una oferta insertada');
        System.assertEquals(false, oportunidades.get(0).HasBeenReassigned__c, 'El flag debe haberse modificado');
    }

    /**
     * Método de test que comprueba que NO se hace un update de la oportunidad. No tenemos ninguna de las opciones de bypass
     * @author arcortazar
     * @date 09/03/2022
     * 
     */
    @isTest
    static void test_runNotAsSupervisor_ClosedWon_NOK() 
    {
        // Obtenemos los diferentes usuarios: supervisor y no supervisor
       User uNoSup = [SELECT Id FROM User WHERE Name='Nestor Neira Bellisco'];

       // Creamos la oportunidad que vamos a manejar en el test
       List<Account> accounts = [SELECT Name FROM Account LIMIT 1];

       Product2 p = new Product2
            (
                Name = 'Product test 1',
                GroupDescription__c = 'Group 1',
                INFO_Product_Number__c = '00800-00001'
            );
        insert p;

       Opportunity opp = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'Closed Won', System.today().addDays(10), 1).get(0);
       opp.BusinessCode__c = '123456';
       opp.InfoQuoteNumber__c = '123456';
       opp.OwnerId = uNoSup.Id;
       opp.ProductId__c = p.Id;
       insert opp;

       // Modificamos la oportunidad
       opp.HasBeenReassigned__c = false;

       Database.SaveResult resultados;
       System.runAs(uNoSup)
       {   
           // Lanzamos el test, modificamos la oferta 
           Test.startTest();
           resultados = Database.update(opp, false);
           Test.stopTest();
       }

        // Comprobamos que se haya modificado la oferta
        List<Opportunity> oportunidades  = [SELECT Id, Name, OwnerId, StageName, HasBeenReassigned__c FROM Opportunity]; 
        System.assertEquals(1, oportunidades.size(), 'Ha de haber una oferta insertada');

        System.assertEquals(false, resultados.isSuccess());
        System.assertEquals(Label.OfferStageValidationMessage, resultados.getErrors().get(0).getMessage());
    }

    /**
     * Método de test que comprueba que pese a tener elementos para bypasear, no se actualiza la oferta porque está cerrada ganada.
     * @author arcortazar
     * @date 09/03/2022
     */
    @isTest
    static void test_runAsSupervisor_ClosedWon_OK() 
    {
       // Obtenemos los diferentes usuarios: supervisor y no supervisor
       User uSup = [SELECT Id FROM User WHERE Name='Agustin Angel Zapata Mendez'];
       User uNoSup = [SELECT Id, IsZESupervisor__c FROM User WHERE Name='Nestor Neira Bellisco'];

       // Creamos la oportunidad que vamos a manejar en el test
       List<Account> accounts = [SELECT Name FROM Account LIMIT 1];

        Product2 p = new Product2
           (
               Name = 'Product test 1',
               GroupDescription__c = 'Group 1',
               INFO_Product_Number__c = '00800-00001'
           );
        insert p;

        Opportunity opp = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'Closed Won', System.today().addDays(10), 1).get(0);
        opp.BusinessCode__c = '123456';
        opp.InfoQuoteNumber__c = '123456';
        opp.OwnerId = uSup.Id;
        opp.ProductId__c = p.Id;
        insert opp;

        // Modificamos la oportunidad
        opp.HasBeenReassigned__c = true;

        Database.SaveResult resultados;
        System.runAs(uSup)
        {   
           // Lanzamos el test, modificamos la oferta 
           Test.startTest();
           resultados = Database.update(opp, false);
           Test.stopTest();
        }

        // Comprobamos que se haya modificado la oferta
        List<Opportunity> oportunidades  = [SELECT Id, Name, OwnerId, HasBeenReassigned__c FROM Opportunity]; 
        System.assertEquals(1, oportunidades.size(), 'Ha de haber una oferta insertada');
        System.assertEquals(true, resultados.isSuccess());
    }

    /**
     * Test detection of the change of the AccountId of the offer
     *
     * @author nts (agonzalezisasi)
     * @date 04/02/2021
     */
    @isTest
    static void test_detectOpportunityAccountChange_ok()
    {
        // Get 10 accounts
        List<Account> accounts = [SELECT Name FROM Account LIMIT 10];
        System.assertEquals(10, accounts.size(), 'There should be 10 accounts');
        // Get 10 offers
        List<Opportunity> optys = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 1);
        insert optys;
        // Create new 10 accounts
        List<Account> accountsOther = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 10);
        insert accountsOther;
        // Change the offers AccountId to the new accounts
        for(Integer i=0,j=optys.size();i<j;i++) {
            optys[i].AccountId = accountsOther[i].Id;
        }

        // do the update
        Test.startTest();
        update optys;
        Test.stopTest();

        // Check that the OldAccountId__c field is not null
        List<Opportunity> optysUpdated = [
            SELECT Id, OldAccountId__c FROM Opportunity WHERE Id IN :optys AND OldAccountId__c != null
        ];
        System.assertEquals(10, optysUpdated.size(), 'There should be 10 offers updated');
    }

    /**
     * Comprueba si una oferta se inserta con Stage a null, se cambia a Open
     * @date 25/02/2021
     */
    @isTest
    static void test_setStageNameOpen_ok()
    {
        List<Account> accounts = [SELECT Name FROM Account];
        List<Opportunity> optys = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', null, System.today().addDays(10), 2);
        for(Integer i = 0; i < optys.size(); i++)
        {
            optys[i].InfoQuoteNumber__c = String.valueOf(i);
        }

        Test.startTest();
        insert optys;
        Test.stopTest();

        List<Opportunity> optysInserted = [SELECT Id, StageName FROM Opportunity];

        for(Opportunity opty : optysInserted)
        {
            System.assertEquals('Open', opty.StageName, 'Se debería haber cambiado el Stage de null a Open');
        }
    }

    /**
     * Comprueba si una oferta se inserta con Stage a distinto de null, no se machaca con Open
     * @date 25/02/2021
     */
    @isTest
    static void test_setStageNameOpen_ko()
    {
        List<Account> accounts = [SELECT Name FROM Account];
        List<Opportunity> optys = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'Quoted', System.today().addDays(10), 2);
        for(Integer i = 0; i < optys.size(); i++)
        {
            optys[i].InfoQuoteNumber__c = String.valueOf(i);
        }

        Test.startTest();
        insert optys;
        Test.stopTest();

        List<Opportunity> optysInserted = [SELECT Id, StageName FROM Opportunity];

        for(Opportunity opty : optysInserted)
        {
            System.assertEquals('Quoted', opty.StageName, 'No se debería haber machacado el Stage');
        }
    }

    /**
     * Comprueba si una oferta se actualiza con Stage a null, se cambia a lo anterior
     * @date 25/02/2021
     */
    @isTest
    static void test_preventNullUpdates_ok()
    {
        List<Account> accounts = [SELECT Name FROM Account];
        List<Opportunity> optys = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'Quoted', System.today().addDays(10), 2);
        for(Integer i = 0; i < optys.size(); i++)
        {
            optys[i].InfoQuoteNumber__c = String.valueOf(i);
        }
        insert optys;

        Test.startTest();
        for(Integer j = 0; j < optys.size(); j++)
        {
            optys[j].StageName = null;
            optys[j].AccountId = null;
        }
        update optys;
        Test.stopTest();

        List<Opportunity> optysUpdated = [SELECT Id, StageName FROM Opportunity];

        for(Opportunity opty : optysUpdated)
        {
            System.assertEquals('Quoted', opty.StageName, 'Se debería haber cambiado el Stage de null a lo que tuviese anteriormente');
        }
    }

    /**
     * Comprueba si una oferta se actualiza con Stage válido a otro válido, no se revierte
     * @date 25/02/2021
     */
    @isTest
    static void test_preventNullUpdates_ko()
    {
        List<Account> accounts = [SELECT Name FROM Account];
        List<Opportunity> optys = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'Open', System.today().addDays(10), 2);
        for(Integer i = 0; i < optys.size(); i++)
        {
            optys[i].InfoQuoteNumber__c = String.valueOf(i);
        }
        insert optys;

        Test.startTest();
        for(Integer j = 0; j < optys.size(); j++)
        {
            optys[j].StageName = 'Quoted';
            optys[j].AccountId = accounts[0].Id;
        }
        update optys;
        Test.stopTest();

        List<Opportunity> optysUpdated = [SELECT Id, StageName FROM Opportunity];

        for(Opportunity opty : optysUpdated)
        {
            System.assertEquals('Quoted', opty.StageName, 'Se debería haber mantenido el cambio en el Stage, ya que no se está cambiando a null');
        }
    }
}
