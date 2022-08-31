@isTest
public with sharing class ClientInteracionServiceTest {
    
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 2);
        insert accounts;

        List<Account> tempList = new List<Account>();
        tempList.add(accounts.get(0));

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(tempList, 10);
        insert policies;
    }

    /**
     * Método de test que confirma que existe tanto el DNI que nos mandan, como el número de póliza, son correctas
     */
    @isTest
    static void processData_foundClient(){
        List<Policy__c> policies = [SELECT Id, InfoPolicyNumber__c, PolicyHolder__c, PolicyHolder__r.NationalId__c FROM Policy__c LIMIT 1];
        List<Account> accounts = [SELECT Id, NationalId__c FROM Account WHERE NationalId__c = :policies[0].PolicyHolder__r.NationalId__c LIMIT 1];

        policies[0].MovementStartDate__c = date.today();
        policies[0].EndDate__c = date.today().addDays(10);
        policies[0].PolicyVersion__c = '2';

        upsert policies[0];

        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();
        testClient.nombreCompleto = 'Nombre Apellido';
        testClient.dniNiePasaporte = accounts[0].NationalId__c;
        testClient.codigoPoliza = policies[0].InfoPolicyNumber__c;

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;
        ClientIdentificationService.SearchResult resultado;

        Test.startTest();
        try
        {
            resultado = ClientIdentificationService.processData(testClient);
        }
        catch(ClientIdentificationService.ClientIdentificationException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        System.debug('++++ resultado: ' + resultado);

        System.assertEquals(null, expectedError, 'Ha de encontrarse el cliente y no saltar ninguna excepción');
        System.assertEquals(true, resultado.existeDni, 'Es un cliente del sistema');
        System.assertEquals(true, resultado.existePoliza, 'La póliza existe y está asociada al cliente');
        
        System.assertEquals(true, resultado.polizaValida, 'La póliza existe y es válida');
        System.assertNotEquals(null, resultado.fechaInicioPoliza, 'La póliza tiene una fecha de inicio');
        System.assertNotEquals(null, resultado.fechaFinPoliza, 'La póliza tiene una fecha de fin');
        System.assertNotEquals(null, resultado.versionPoliza, 'La póliza tiene una versión');
    }

    /**
     * Método de test que comprueba que el DNI que se le pasa se corresponde con un cliente existente en el sistema, pero la póliza no.
     */
    @isTest
    static void processData_foundClient_noPolicy(){
        List<Policy__c> policies = [SELECT Id, PolicyHolder__c, PolicyHolder__r.NationalId__c FROM Policy__c LIMIT 1];
        List<Account> accounts = [SELECT Id, NationalId__c FROM Account WHERE NationalId__c != :policies[0].PolicyHolder__r.NationalId__c LIMIT 1];

        String policyNoExiste = '00000000000000';

        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();
        testClient.nombreCompleto = 'Nombre Apellido';
        testClient.dniNiePasaporte = accounts[0].NationalId__c;
        testClient.codigoPoliza = policyNoExiste;

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;
        ClientIdentificationService.SearchResult resultado;

        Test.startTest();
        try
        {
            resultado = ClientIdentificationService.processData(testClient);
        }
        catch(ClientIdentificationService.ClientIdentificationException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        System.assertEquals(null, expectedError, 'Ha de encontrarse el cliente y no saltar ninguna excepción');
        System.assertEquals(true, resultado.existeDni, 'Es un cliente del sistema');
        System.assertEquals(false, resultado.existePoliza, 'La póliza indicada no existe en el sistema');
    }

    /**
     * Método de test que confirma que existe tanto el DNI que nos mandan, como el número de póliza, son correctas
     */
    @isTest
    static void processData_foundPolicyNotClient(){
        List<Policy__c> policies = [SELECT Id, InfoPolicyNumber__c, PolicyHolder__c, PolicyHolder__r.NationalId__c FROM Policy__c LIMIT 1];
        String dniNoExiste = '00000000A';

        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();
        testClient.nombreCompleto = 'Nombre Apellido';
        testClient.dniNiePasaporte = dniNoExiste;
        testClient.codigoPoliza = policies[0].InfoPolicyNumber__c;

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;
        ClientIdentificationService.SearchResult resultado;

        Test.startTest();
        try
        {
            resultado = ClientIdentificationService.processData(testClient);
        }
        catch(ClientIdentificationService.ClientIdentificationException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        System.assertEquals(null, expectedError, 'Ha de encontrarse el cliente y no saltar ninguna excepción');
        System.assertEquals(false, resultado.existeDni, 'El cliente no está en el sistema');
        System.assertEquals(true, resultado.existePoliza, 'La póliza existe y está asociada al cliente');

    }



    /**
     * Método de test que comprueba el caso en el que ni el DNI ni la Póliza estan en el sistema
     */
    @isTest
    static void processData_clientNotFound(){

        String dniNoExiste = '00000000A'; 
        String policyNoExiste = '00000000000000';
        
        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();
        testClient.nombreCompleto = 'Nombre Apellido';
        testClient.dniNiePasaporte = dniNoExiste;
        testClient.codigoPoliza = policyNoExiste;

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;
        ClientIdentificationService.SearchResult resultado;

        Test.startTest();
        try
        {
            resultado = ClientIdentificationService.processData(testClient);
        }
        catch(ClientIdentificationService.ClientIdentificationException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        System.assertEquals(null, expectedError, 'Ha de encontrarse el cliente y no saltar ninguna excepción');
        System.assertEquals(false, resultado.existeDni, 'El cliente no está en el sistema');
        System.assertEquals(false, resultado.existePoliza, 'No tiene policies asociadas');
        
    }

    /**
     * Método de test que confirma que no se ha enviado el campo DNI. Ha de devolver una excepción del tipo INVALID_FIELD
     */
    @isTest
    static void processData_noDNIexception(){

        // When
        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();
        testClient.nombreCompleto = 'Nombre Apellido';
        testClient.codigoPoliza = '123456';

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;

        Test.startTest();
        try
        {
            ClientIdentificationService.validateReceivedInformation(testClient);
        }
        catch(ClientIdentificationService.ClientIdentificationException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        System.assertEquals(ClientIdentificationService.INVALID_FIELD_STATUSCODE, expectedError.statusCode, 'No se ha lanzado la excepción correcta');
        
    }

    /**
     * Método de test que confirma que el DNI se ha enviado vacío. Ha de devolver una excepción del tipo EMPTY_FIELD
     */
    @isTest
    static void processData_blankDNIexception(){
        // When
        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();

        testClient.nombreCompleto = 'Nombre Apellido';
        testClient.dniNiePasaporte = '';
        testClient.codigoPoliza = '123456';

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;

        Test.startTest();
        try
        {
            ClientIdentificationService.processData(testClient);
        }
        catch(ClientIdentificationService.ClientIdentificationException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        System.assertEquals(ClientIdentificationService.EMPTY_FIELD_STATUSCODE, expectedError.statusCode, 'No se ha lanzado la excepción correcta');
    }

    /**
     * Método de test que confirma que la policy se ha enviado vacío. Ha de devolver una excepción del tipo EMPTY_FIELD
     */
    @isTest
    static void processData_blankPolicyException(){
        // When
        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();
        testClient.nombreCompleto = 'Nombre Apellido';
        testClient.dniNiePasaporte = '12345678A';
        testClient.codigoPoliza = '';

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;

        Test.startTest();
        try
        {
            ClientIdentificationService.processData(testClient);
        }
        catch(ClientIdentificationService.ClientIdentificationException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        System.assertEquals(ClientIdentificationService.EMPTY_FIELD_STATUSCODE, expectedError.statusCode, 'No se ha lanzado la excepción correcta');
    }
}
