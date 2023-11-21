@isTest(SeeAllData=false)
public with sharing class ClientInteracionServiceTest
{
    private static String GRUPO_MOTOR = 'Motor';

    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 2);
        insert accounts;

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 1);
        insert contactPointPhones;

        List<Account> partners = TestDataFactory.generateAccounts('001', 'Partner', 1);
        insert partners;

        List<Account> tempList = new List<Account>();
        tempList.add( accounts.get(0) );

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(tempList, 10);
        insert policies;

        List<Asset> assets = TestDataFactory.generateInsuredObjectsForEachPolicy('Motor', policies, 1);
        insert assets;

        List<Product2> productos = TestDataFactory.generateProducts(1);
        productos[0].GroupDescription__c = GRUPO_MOTOR;
        insert productos;
    }

    /**
     * Método de test que confirma que existe tanto el DNI que nos mandan, como el número de póliza, son correctas
     */
    @isTest
    static void processData_foundClient()
    {
        List<Policy__c> policies = [SELECT Id, InfoPolicyNumber__c, PolicyHolder__c, PolicyHolder__r.NationalId__c FROM Policy__c LIMIT 1];
        List<Account> accounts = [SELECT Id, NationalId__c FROM Account WHERE NationalId__c = : policies[0].PolicyHolder__r.NationalId__c LIMIT 1];

        policies[0].MovementStartDate__c = date.today();
        policies[0].EndDate__c = date.today().addDays(10);
        policies[0].PolicyVersion__c = '2';

        upsert policies[0];

        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();
        testClient.fullName = 'Nombre Apellido';
        testClient.nationalID = accounts[0].NationalId__c;
        testClient.policyNumber = policies[0].InfoPolicyNumber__c;

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;
        ClientIdentificationService.SearchResult resultado;

        Test.startTest();
        try
        {
            String salida = ClientIdentificationService.processData(testClient, 'findByPolicyNumber');
            resultado= (ClientIdentificationService.SearchResult) JSON.deserializeStrict(
                salida,
                ClientIdentificationService.SearchResult.class
                );
        }
        catch(ClientIdentificationService.ClientIdentificationException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        System.assertEquals(null, expectedError, 'Ha de encontrarse el cliente y no saltar ninguna excepción');
        System.assertEquals(true, resultado.existsNationalID, 'Es un cliente del sistema');
        System.assertEquals(true, resultado.existsPolicy, 'La póliza existe y está asociada al cliente');

        System.assertEquals(true, resultado.isValidPolicy, 'La póliza existe y es válida');
        System.assertNotEquals(null, resultado.policyStartDate, 'La póliza tiene una fecha de inicio');
        System.assertNotEquals(null, resultado.policyEndDate, 'La póliza tiene una fecha de fin');
        System.assertNotEquals(null, resultado.policyVersion, 'La póliza tiene una versión');
    }

    /**
     * Método de test que comprueba que el DNI que se le pasa se corresponde con un cliente existente en el sistema, pero la póliza no.
     */
    @isTest
    static void processData_foundClient_noPolicy()
    {
        List<Policy__c> policies = [SELECT Id, PolicyHolder__c, PolicyHolder__r.NationalId__c FROM Policy__c LIMIT 1];
        List<Account> accounts = [SELECT Id, NationalId__c FROM Account WHERE NationalId__c != : policies[0].PolicyHolder__r.NationalId__c LIMIT 1];

        String policyNoExiste = '00000000000000';

        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();
        testClient.fullName = 'Nombre Apellido';
        testClient.nationalID = accounts[0].NationalId__c;
        testClient.policyNumber = policyNoExiste;

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;
        ClientIdentificationService.SearchResult resultado;

        Test.startTest();
        try
        {
            String salida = ClientIdentificationService.processData(testClient, 'findByPolicyNumber');
            resultado= (ClientIdentificationService.SearchResult) JSON.deserializeStrict(
                salida,
                ClientIdentificationService.SearchResult.class
                );
        }
        catch(ClientIdentificationService.ClientIdentificationException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        System.assertEquals(null, expectedError, 'Ha de encontrarse el cliente y no saltar ninguna excepción');
        System.assertEquals(true, resultado.existsNationalID, 'Es un cliente del sistema');
        System.assertEquals(false, resultado.existsPolicy, 'La póliza indicada no existe en el sistema');
    }

    /**
     * Método de test que confirma que existe tanto el DNI que nos mandan, como el número de póliza, son correctas
     */
    @isTest
    static void processData_foundPolicyNotClient()
    {
        List<Policy__c> policies = [SELECT Id, InfoPolicyNumber__c, PolicyHolder__c, PolicyHolder__r.NationalId__c FROM Policy__c LIMIT 1];
        String dniNoExiste = '00000000A';

        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();
        testClient.fullName = 'Nombre Apellido';
        testClient.nationalID = dniNoExiste;
        testClient.policyNumber = policies[0].InfoPolicyNumber__c;

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;
        ClientIdentificationService.SearchResult resultado;

        Test.startTest();
        try
        {
            String salida = ClientIdentificationService.processData(testClient, 'findByPolicyNumber');
            resultado= (ClientIdentificationService.SearchResult) JSON.deserializeStrict(
                salida,
                ClientIdentificationService.SearchResult.class
                );
        }
        catch(ClientIdentificationService.ClientIdentificationException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        System.assertEquals(null, expectedError, 'Ha de encontrarse el cliente y no saltar ninguna excepción');
        System.assertEquals(false, resultado.existsNationalID, 'El cliente no está en el sistema');
        System.assertEquals(true, resultado.existsPolicy, 'La póliza existe y está asociada al cliente');

    }

    /**
     * Método de test que comprueba el caso en el que ni el DNI ni la Póliza estan en el sistema
     */
    @isTest
    static void processData_clientNotFound()
    {

        String dniNoExiste = '00000000A';
        String policyNoExiste = '00000000000000';

        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();
        testClient.fullName = 'Nombre Apellido';
        testClient.nationalID = dniNoExiste;
        testClient.policyNumber = policyNoExiste;

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;
        ClientIdentificationService.SearchResult resultado;

        Test.startTest();
        try
        {
            String salida = ClientIdentificationService.processData(testClient, 'findByPolicyNumber');
            resultado= (ClientIdentificationService.SearchResult) JSON.deserializeStrict(
                salida,
                ClientIdentificationService.SearchResult.class
                );
        }
        catch(ClientIdentificationService.ClientIdentificationException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        System.assertEquals(null, expectedError, 'Ha de encontrarse el cliente y no saltar ninguna excepción');
        System.assertEquals(false, resultado.existsNationalID, 'El cliente no está en el sistema');
        System.assertEquals(false, resultado.existsPolicy, 'No tiene policies asociadas');

    }

    /**
     * Método de test que confirma que no se ha enviado el campo DNI. Ha de devolver una excepción del tipo INVALID_FIELD
     */
    @isTest
    static void processData_noDNIexception()
    {

        // When
        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();
        testClient.fullName = 'Nombre Apellido';
        testClient.policyNumber = '123456';

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;

        Test.startTest();
        try
        {
            ClientIdentificationService.validateReceivedInformation(testClient, 'findByPolicyNumber');
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
    static void processData_blankDNIexception()
    {
        // When
        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();

        testClient.fullName = 'Nombre Apellido';
        testClient.nationalID = '';
        testClient.policyNumber = '123456';

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;

        Test.startTest();
        try
        {
            ClientIdentificationService.processData(testClient, 'findByPolicyNumber');
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
    static void processData_blankPolicyException()
    {
        // When
        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();
        testClient.fullName = 'Nombre Apellido';
        testClient.nationalID = '12345678A';
        testClient.policyNumber = '';

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;

        Test.startTest();
        try
        {
            ClientIdentificationService.processData(testClient, 'findByPolicyNumber');
        }
        catch(ClientIdentificationService.ClientIdentificationException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        System.assertEquals(ClientIdentificationService.EMPTY_FIELD_STATUSCODE, expectedError.statusCode, 'No se ha lanzado la excepción correcta');
    }

    /**
     * Método de test que confirma que existe tanto el teléfono que nos mandan, como el DNI, y el grupo del producto de la póliza
     */
    @isTest
    static void processData_foundByPhone()
    {

        //String.isBlank(receivedData.nationalID) || String.isBlank(receivedData.phoneNumber) || String.isBlank(receivedData.groupDescription)

        List<Asset> assets = [SELECT Id, Model__c, BrandName__c, PolicyId__c FROM Asset LIMIT 1];

        List<Policy__c> policies = [SELECT Id, Name, InfoPolicyNumber__c, PolicyHolder__c, ProductId__c
                                    FROM Policy__c WHERE Id = : assets[0].PolicyId__c LIMIT 1];

        List<Account> accounts = [SELECT Id, NationalId__c, Phone FROM Account WHERE Id = : policies[0].PolicyHolder__c LIMIT 1];

        List<ContactPointPhone> contactPhones = [SELECT Id, ParentId, TelephoneNumber, ScopeId__c, Scope__c
                                                 FROM ContactPointPhone WHERE ParentId = : accounts[0].Id LIMIT 1];

        List<Product2> products = [SELECT Id, GroupDescription__c FROM Product2 LIMIT 1];

        accounts[0].NationalId__c = '11111111E';
        accounts[0].Phone = contactPhones[0].TelephoneNumber;
        upsert accounts[0];

        policies[0].ProductId__c = products[0].Id;
        upsert policies[0];


        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();
        testClient.nationalID = '11111111E';
        testClient.phonePrefix = '';
        testClient.phoneNumber = contactPhones[0].TelephoneNumber;
        testClient.groupDescription = GRUPO_MOTOR;

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;
        ClientIdentificationService.SearchResultLong resultado;

        Test.startTest();
        try
        {
            String salida = ClientIdentificationService.processData(testClient, 'findByPhone');
            resultado = (ClientIdentificationService.SearchResultLong) JSON.deserializeStrict(
                salida,
                ClientIdentificationService.SearchResultLong.class
                );
        }
        catch(ClientIdentificationService.ClientIdentificationException error)
        {
            expectedError = error;
        }

        ClientIdentificationService.SearchResultLong resultado2 = ClientIdentificationService.setInsuredObjectsByPhone(testClient,
                                                                                                                       contactPhones[0].TelephoneNumber, new ClientIdentificationService.SearchResultLong(),
                                                                                                                       new List<ClientIdentificationService.InsuredObject>(), accounts);

        Test.stopTest();

        System.assertEquals(null, expectedError, 'Ha de encontrarse el cliente y no saltar ninguna excepción');
        System.assertEquals(testClient.nationalID, resultado2.nationalID, 'Debe existir un cliente con ese Identificador');

        System.assert ( (testClient.phonePrefix + testClient.phoneNumber == resultado2.phoneNumber || testClient.phoneNumber == resultado2.phoneNumber),
                        'Existe un cliente con ese teléfono' );
    }

    /**
     * Método de test que confirma que existe la matrícula introducida
     */
    @isTest
    static void processData_foundByRegistrationNumber()
    {

        //String.isBlank(receivedData.nationalID) || String.isBlank(receivedData.phoneNumber) || String.isBlank(receivedData.groupDescription)

        List<Asset> assets = [SELECT Id, Model__c, BrandName__c, PolicyId__c FROM Asset LIMIT 1];

        List<Policy__c> policies = [SELECT Id, Name, InfoPolicyNumber__c, PolicyHolder__c, Partner__c FROM Policy__c WHERE Id = : assets[0].PolicyId__c LIMIT 1];

        List<Account> accounts = [SELECT Id, FirstName, LastName FROM Account WHERE Id = : policies[0].PolicyHolder__c LIMIT 1];

        assets[0].RegistrationNumber__c = '1111AAA';

        upsert assets[0];

        ClientIdentificationService.Client testClient = new ClientIdentificationService.Client();
        testClient.registrationNumber = '1111AAA';

        // Test
        ClientIdentificationService.ClientIdentificationException expectedError;
        ClientIdentificationService.SearchResultLong resultado;

        Test.startTest();
        try
        {
            String salida = ClientIdentificationService.processData(testClient, 'findByRegistrationNumber');
            resultado = (ClientIdentificationService.SearchResultLong) JSON.deserializeStrict(
                salida,
                ClientIdentificationService.SearchResultLong.class
                );
        }
        catch(ClientIdentificationService.ClientIdentificationException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        System.assertEquals(null, expectedError, 'Ha de encontrarse el cliente y no saltar ninguna excepción');
        System.assertEquals(true, resultado.existsRegistrationNumber, 'Existe un Objeto Asegurado con esa Matrícula');
    }

    /**
     * Método de test que recorre el camino de error si no llega un selector correcto
     */
    @isTest
    static void processData_foundError()
    {
        // Test

        String salida;

        Test.startTest();

        salida = ClientIdentificationService.processData(null, 'find_error');

        Test.stopTest();

        System.assertEquals(salida, 'error', 'Ha de devolver *error*');
    }

}