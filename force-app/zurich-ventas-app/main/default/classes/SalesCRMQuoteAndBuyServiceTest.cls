/**
 * @description       : Clase test para comprobar el correcto funcionamiento de lo métodos
 *                      de la clase 'SalesCRMQuoteAndBuyService'
 * @author            : overes
 * @group             :
 * @last modified on  : 27-09-2023
 * @last modified by  : overes
 **/
@isTest
private with sharing class SalesCRMQuoteAndBuyServiceTest
{
    
    @TestSetup
    static void setup()
    {
        // Crear Custom Setting para default user
        TestDataFactory.insertCrossSellingCustomSetting();

        // Crear Custom Setting para las colas y Business Hours
        Lead_Offers__c leadOffer = TestDataFactory.generateLeadOfferCS();
        insert leadOffer;
    }

    /**
     * @description Método que comprueba que la creación de leads se hace correctamente
     *
     * @author overes | 26-09-2023
     **/
    @isTest
    static void test_manageLead_createLead_OK()
    {
        SalesCRMQuoteAndBuyService.Lead lead = generateLead();
        String leadDocumentId = lead.cliente.idFiscal;
        String leadPhone = lead.cliente.contacto.telefono;

        List<Account> leadAccounts = [SELECT Id,NationalId__c,Phone FROM Account
                                      WHERE NationalId__c = : leadDocumentId
                                                            OR Phone =: leadPhone];
        Assert.isTrue(leadAccounts.isEmpty(),
                      'No debería existir una cuenta en el sistema con el valor ' + leadDocumentId + ' en el campo \'NationalId__c\'.');

        Test.startTest();
        Account leadAccount = SalesCRMQuoteAndBuyService.manageLead(lead);
        Test.stopTest();

        Assert.isNotNull(leadAccount,
                         'El método \'manageLead\' debería haber devuelto una cuenta.');

        List<Account> leadAccountsCreated = [SELECT Id, RecordType.Name,NationalId__c,Phone
                                             FROM Account
                                             WHERE NationalId__c = : leadDocumentId
                                                                   OR Phone =: leadPhone];

        Assert.isFalse(leadAccountsCreated.isEmpty(),
                       'Debería haberse creado una cuenta con el valor ' + leadDocumentId + ' en el campo \'NationalId__c\'.');
        Assert.areEqual('Lead',
                        leadAccountsCreated.get(0).RecordType.Name,
                        'Se debería haber creado una cuenta de tipo Lead.');
    }

    /**
     * @description Método de test que se encarga de comprobar que si no existe
     * una oferta asociada a la cuenta de tipo 'Lead' que se pasa por parámetro,
     * se genera una nueva oferta.
     *
     * @author overes | 26-09-2023
     **/
    @isTest
    static void test_manageOpportunity_createOpportunity_OK()
    {
        List<Opportunity> offers = [SELECT Id FROM Opportunity];
        Assert.isTrue(offers.isEmpty(), 'No debería haber ninguna oferta en el sistema.');

        List<Account> leadAccounts = TestDataFactory.generateAccounts(null, 'Lead', 1);
        insert leadAccounts;

        SalesCRMQuoteAndBuyService.Lead lead = generateLead();

        Test.startTest();
        Opportunity offer = SalesCRMQuoteAndBuyService.manageOpportunity(leadAccounts.get(0),lead);
        Test.stopTest();

        Assert.isNotNull(offer,'El método \'managerOffer\' debería haber devuelto una oferta.');
    }

    /**
     * @description Método de test que se encarga de comprobar el desarrollo de cambio de estados
     * de la oferta, funciona correctamente
     *
     * @author overes | 26-09-2023
     **/
    @isTest
    static void test_manageOfferStage_OK()
    {
        SalesCRMQuoteAndBuyService.Lead lead = generateLead();
        lead.poliza.numeroOferta = null;
        lead.poliza.numeroPoliza = null;
        List<Account> leadAccounts = TestDataFactory.generateAccounts(null, 'Lead', 1);
        for (Account l: leadAccounts) {
            l.Phone = '666666666'; 
        }
        insert leadAccounts;
        Opportunity offer = SalesCRMQuoteAndBuyService.manageOpportunity(leadAccounts.get(0),lead);


        Test.startTest();
        try
        {
            SalesCRMQuoteAndBuyService.processData(leadAccounts.get(0),offer,lead);
        }
        catch (Exception ex)
        {
            Assert.fail('No debería haberse lanzado ninguna excepción en el manejo de estados de la Oferta \n ' + ex);
        }
        Test.stopTest();
    }

    /**
     * @description Método de test que se encarga de comprobar que no se lanza
     * ninguna excepción cuando todos los campos requeridos se encuentran informados.
     *
     * @author overes | 26-09-2023
     **/
    @isTest
    static void test_checkRequiredFields_informed_OK()
    {
        SalesCRMQuoteAndBuyService.Lead lead = generateLead();

        Test.startTest();
        try
        {
            SalesCRMQuoteAndBuyService.checkRequiredFields(lead);
        }
        catch (Exception ex)
        {
            Assert.fail('No debería haberse lanzado ninguna excepción');
        }
        Test.stopTest();
    }

    /**
     * @description Método que comprueba que se rellenan los campos de una cuenta
     * con los datos deserializados en el objeto wrapper 'Lead' de la clase
     * 'SalesCRMQuoteAndBuyService'.
     *
     * @author overes | 26-09-2023
     **/
    @isTest
    static void test_fillAccountFields_OK()
    {
        Map<String, Schema.SObjectField> fieldsToBeFilled = new Map<String, Schema.SObjectField> {};

        Account accountToBeFilled = new Account();
        SalesCRMQuoteAndBuyService.Lead lead = generateLead();

        Test.startTest();
        SalesCRMQuoteAndBuyService.fillAccountFields(accountToBeFilled, lead);
        Test.stopTest();

        for ( String fieldToBeFilled : fieldsToBeFilled.keySet() )
        {
            Assert.areEqual(lead.get(fieldToBeFilled),
                            accountToBeFilled.get( fieldsToBeFilled.get(fieldToBeFilled) ),
                            'No se ha informado el campo ' + fieldsToBeFilled.get(fieldToBeFilled).getDescribe().getName() + ' con el valor esperado.');
        }
    }

    /**
     * @description Método de test que comprueba que no se establece el valor 'N'
     * en el campo 'NationalIdType__c' cuando no se pasa un documentId.
     *
     * @author overes | 26-09-2023
     **/
    @isTest
    static void test_setNationalIdType_notModifyNationalIdType_OK()
    {
        Account account = new Account(
            Name = 'Test National Id',
            NationalIdType__c = 'US'
            );

        Test.startTest();
        SalesCRMQuoteAndBuyService.setNationalIdType(account, null);
        Test.stopTest();

        Assert.areNotEqual(SalesCRMQuoteAndBuyService.NATIONAL_ID_TYPE_NIF,
                           account.NationalIdType__c,
                           'El valor del campo \'NationalIdType__c\' no debería ser ' + SalesCRMQuoteAndBuyService.NATIONAL_ID_TYPE_NIF);
    }

    /**
     * @description Método que comprueba que no se lanza ninguna excepción cuando
     * los valores de los campos de tipo picklist son valores válidos por el campo
     * correspondiente en Salesforce.
     *
     * @author overes | 26-09-2023
     **/
    @isTest
    static void test_checkPicklistValues_validValues_KO()
    {
        SalesCRMQuoteAndBuyService.Lead lead = generateLead();
        List<Account> leadAccounts = TestDataFactory.generateAccounts(null, 'Lead', 1);
        insert leadAccounts;

        Test.startTest();
        try
        {
            SalesCRMQuoteAndBuyService.checkPicklistValues(lead);
        }
        catch (Exception ex)
        {
            Assert.fail('No debería haberse lanzado ninguna excepción.');
        }
        Test.stopTest();
    }

    /**
     * @description Método que comprueba que no se lanza ninguna excepción cuando
     * los valores de los campos de tipo picklist son valores válidos por el campo
     * correspondiente en Salesforce.
     *
     * @author overes | 26-09-2023
     **/
    @isTest
    static void test_managePolicy_OK()
    {
        SalesCRMQuoteAndBuyService.Lead lead = generateLead();
        List<Account> leadAccounts = TestDataFactory.generateAccounts(null, 'Lead', 1);
        insert leadAccounts;

        Test.startTest();
        Policy__c policy = SalesCRMQuoteAndBuyService.managePolicy(leadAccounts.get(0),lead);
        Test.stopTest();

        Assert.isNotNull(policy,'El método \'managePolicy\' debería haber devuelto una oferta.');
    }

    /**
     * @description Método de test que comprueba que la conversión de string a DateTime
     * se hace correctamente
     *
     * @author overes | 26-09-2023
     **/
    @isTest
    static void test_convertStringToDateTime_OK()
    {
        String stringToConvert = '10:45';
        DateTime today = DateTime.now();
        DateTime expectedDateTime = DateTime.newInstance(today.year(), today.month(), today.day(), 10, 45, 0);

        Test.startTest();
        DateTime returnDateTime = SalesCRMQuoteAndBuyService.convertStringToDateTime(stringToConvert);
        Test.stopTest();
        Assert.areEqual(expectedDateTime, returnDateTime, 'La cadena \'10:45\' debería haberse convertido a tipo DateTime');
    }

    /**
     * @description Método de test que comprueba que la conversión de entero a tipo Date
     * es la esperada
     *
     * @author overes | 26-09-2023
     **/
    @isTest
    static void test_convertIntegerToDate_OK()
    {
        Integer integerToConvert = 19900121;
        Date expectedDate = Date.newInstance(1990, 1, 21);

        Test.startTest();
        Date returnDate = SalesCRMQuoteAndBuyService.convertIntegerToDate(integerToConvert);
        Test.stopTest();
        Assert.areEqual(expectedDate, returnDate, 'El entero 19900121 debería haberse convertido a tipo Date');
    }

    /**
     * @description Método que se encarga de generar un objeto de tipo 'Lead' con
     * todas sus propiedades informadas.
     *
     * @author overes | 26-09-2023
     * @return SalesCRMQuoteAndBuyService.Lead
     **/
    private static SalesCRMQuoteAndBuyService.Lead generateLead()
    {
        SalesCRMQuoteAndBuyService.Lead lead = new SalesCRMQuoteAndBuyService.Lead();
        lead.origen = 'formulario';
        lead.sesion = '9e451536-7b52-448b-af4f-8a50494d0db4';
        lead.cliente.idFiscal = '6786236H';
        lead.cliente.nombre = 'Anabel';
        lead.cliente.primerApellido = 'PrimerApellidoTest';
        lead.cliente.segundoApellido = 'Segundo';
        lead.cliente.fechaNacimiento = 19900121;
        lead.cliente.fechaCarnet = 20140121;
        lead.cliente.paisCarnet = 'ESP';
        lead.cliente.sexo = 'V';
        lead.cliente.contacto.telefono = '34666778899';
        lead.cliente.contacto.email = 'esto@esto.es';
        lead.cliente.contacto.codigoPostal = '08921';
        lead.cliente.contacto.poblacion = 'BARCELONA';
        lead.cliente.contacto.llamada = 20210916;
        lead.cliente.contacto.horaDesde = '10:15';
        lead.cliente.contacto.horaHasta = '12:00';
        lead.cliente.contacto.quiereLlamada = 'S';
        lead.poliza.ramo = '0000000001';
        lead.poliza.numeroPoliza = '7897979454444444';
        lead.poliza.numeroOferta = '4723000444444';
        lead.poliza.fechaInicio = 20230922;
        lead.poliza.precioAnual = 145.94;
        lead.poliza.codigoIntermediario = '0000013200';
        lead.poliza.paquete = 'TERCEROS';
        lead.poliza.coche.marca = 'SEAT';
        lead.poliza.coche.modelo = 'ATECA';
        lead.poliza.coche.version = '2.0 TDI';
        lead.poliza.coche.matricula = '1111LKM';
        lead.poliza.coche.paisMatriculacion = 'ESP';
        lead.poliza.errores.oferta = 'N';
        lead.poliza.errores.poliza = 'N';

        return lead;
    }
}