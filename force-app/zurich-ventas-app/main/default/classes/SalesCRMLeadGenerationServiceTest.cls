/**
 * @description       : Clase de test para comprobr el correcto funcionamiento de
 * los métodos de la clase 'SalesCRMLeadGenerationService'
 * @author            : amiranda
 * @date              : 22-09-2023
 * @last modified on  : 22-09-2023
 * @last modified by  : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   21-09-2023   amiranda   Initial Version
 **/
@isTest
public with sharing class SalesCRMLeadGenerationServiceTest
{

    // #region Test Methods

    /**
     * @description Método de test que comprueba que se genera una cuenta de tipo
     * Lead cuando no existe una cuenta en el sistema que coincida con el DNI o
     * el teléfono.
     *
     * @author amiranda
     * @date 22-09-2023
     **/
    @isTest
    static void test_manageLead_createLead_OK()
    {
        SalesCRMLeadGenerationService.Lead lead = generateLead();
        String leadDocumentId = lead.documentID;
        String leadPhone = lead.phone;

        List<Account> leadAccounts = [SELECT Id FROM Account
                                      WHERE NationalId__c = : leadDocumentId
                                                            OR Phone =: leadPhone];
        Assert.isTrue(leadAccounts.isEmpty(),
                      'No debería existir una cuenta en el sistema con el valor ' + leadDocumentId + ' en el campo \'NationalId__c\'.');

        Test.startTest();
        Account leadAccount = SalesCRMLeadGenerationService.manageLead(lead);
        Test.stopTest();

        Assert.isNotNull(leadAccount,
                         'El método \'manageLead\' debería haber devuelto una cuenta.');

        List<Account> leadAccountsCreated = [SELECT Id, RecordType.Name
                                             FROM Account
                                             WHERE NationalId__c = : leadDocumentId
                                                                   AND Phone =: leadPhone];
        Assert.isFalse(leadAccountsCreated.isEmpty(),
                       'Debería haberse creado una cuenta con el valor ' + leadDocumentId + ' en el campo \'NationalId__c\'.');
        Assert.areEqual('Lead',
                        leadAccountsCreated.get(0).RecordType.Name,
                        'Se debería haber creado una cuenta de tipo Lead.');
    }

    /**
     * @description Método de test que comprueba que se genera un registro de tipo
     * 'ContactRequest'.
     *
     * @author amiranda
     * @date 22-09-2023
     **/
    @isTest
    static void test_manageCallMeBack_insertCallMeBackk_OK()
    {
        // Crear Custom Setting para las colas y Business Hours
        Lead_Offers__c leadOffer = TestDataFactory.generateLeadOfferCS();
        insert leadOffer;

        SalesCRMLeadGenerationService.Lead lead = generateLead();

        Test.startTest();
        SalesCRMLeadGenerationService.manageCallMeBack(lead);
        Test.stopTest();

        List<ContactRequest> cr = [SELECT Id FROM ContactRequest];
        Assert.isFalse(cr.isEmpty(),
                       'Se debería haber creado al menos 1 registro del objeto Contact Request.');
    }

    /**
     * @description Método de test que se encarga de comprobar que si no existe
     * una oferta asociada a la cuenta de tipo 'Lead' que se pasa por parámetro,
     * se genera una nueva oferta.
     *
     * @author amiranda
     * @date 22-09-2023
     **/
    @isTest
    static void test_manageOffer_createOffer_OK()
    {
        List<Opportunity> offers = [SELECT Id FROM Opportunity];
        Assert.isTrue(offers.isEmpty(), 'No debería haber ninguna oferta en el sistema.');

        List<Account> leadAccounts = TestDataFactory.generateAccounts(null, 'Lead', 1);
        insert leadAccounts;

        SalesCRMLeadGenerationService.Lead lead = generateLead();

        Test.startTest();
        Opportunity offer = SalesCRMLeadGenerationService.manageOffer(new Map<String, Account> {UserInfo.getUserId() => null},
                                                                      leadAccounts.get(0).Id,
                                                                      lead);
        Test.stopTest();

        Assert.isNotNull(offer,
                         'El método \'managerOffer\' debería haber devuelto una oferta.');

        List<Opportunity> offersCreated = [SELECT Id FROM Opportunity];
        Assert.isFalse(offersCreated.isEmpty(), 'Debería haberse creado una oferta.');
    }

    /**
     * @description Método que se encarga de comprobar que se lanza una excepción
     * cuando algún campo requerido no se encuentra informado.
     *
     * @author amiranda
     * @date 21-09-2023
     **/
    @isTest
    static void test_checkRequiredFields_notInformed_KO()
    {
        SalesCRMLeadGenerationService.Lead lead = generateLead();
        // Se elimina un campo requerido
        lead.valuesByProperty.remove('origin');

        Test.startTest();
        try
        {
            SalesCRMLeadGenerationService.checkRequiredFields(lead);
            Assert.fail('Debería haberse lanzado una excepción.');
        }
        catch (Exception ex)
        {
            Assert.areEqual(SalesCRMLeadGenerationService.LeadGenerationException.class.toString(),
                            ex.getTypeName(),
                            'El tipo de excepción no coincide');
            Assert.isTrue(ex.getMessage().contains('The following required fields are missing: origin'),
                          'El mensaje de error de la excepción no es el esperado.');
        }
        Test.stopTest();
    }

    /**
     * @description Método de test que se encarga de comprobar que no se lanza
     * ninguna excepción cuando todos los campos requeridos se encuentran informados.
     *
     * @author amiranda
       @date 21-09-2023
     **/
    @isTest
    static void test_checkRequiredFields_informed_OK()
    {
        SalesCRMLeadGenerationService.Lead lead = generateLead();

        Test.startTest();
        try
        {
            SalesCRMLeadGenerationService.checkRequiredFields(lead);
        }
        catch (Exception ex)
        {
            Assert.fail('No debería haberse lanzado ninguna excepción');
        }
        Test.stopTest();
    }

    /**
     * @description Método que comprueba que cuando un campo de tipo picklist
     * contiene un valor no admitido por el campo correspondiente en Salesforce,
     * se lanza una excepción.
     *
     * @author amiranda
     * @date 21-09-2023
     **/
    @isTest
    static void test_checkPicklistValues_invalidValues_KO()
    {
        SalesCRMLeadGenerationService.Lead lead = generateLead();
        // Modificar un campo de tipo picklist con un valor no válido
        lead.language = 'Valor invalido';

        Test.startTest();
        try
        {
            SalesCRMLeadGenerationService.checkPicklistValues(lead);
            Assert.fail('Debería haberse lanzado una excepción.');
        }
        catch (Exception ex)
        {
            Assert.areEqual(SalesCRMLeadGenerationService.LeadGenerationException.class.toString(),
                            ex.getTypeName(),
                            'El tipo de excepción no coincide');
            Assert.isTrue(ex.getMessage().contains('The following fields send invalid values for the picklist entries: language'),
                          'El mensaje de error de la excepción no es el esperado.');
        }
        Test.stopTest();
    }

    /**
     * @description Método que comprueba que no se lanza ninguna excepción cuando
     * los valores de los campos de tipo picklist son valores válidos por el campo
     * correspondiente en Salesforce.
     *
     * @author amiranda
     * @date 21-09-2023
     **/
    @isTest
    static void test_checkPicklistValues_validValues_KO()
    {
        SalesCRMLeadGenerationService.Lead lead = generateLead();

        Test.startTest();
        try
        {
            SalesCRMLeadGenerationService.checkPicklistValues(lead);
        }
        catch (Exception ex)
        {
            Assert.fail('No debería haberse lanzado ninguna excepción.');
        }
        Test.stopTest();
    }

    /**
     * @description Método que comprueba que se rellenan los campos de una cuenta
     * con los datos deserializados en el objeto wrapper 'Lead' de la clase
     * 'SalesCRMLeadGenerationService'.
     *
     * @author amiranda
     * @date 21-09-2023
     **/
    @isTest
    static void test_fillAccountFields_OK()
    {
        Map<String, Schema.SObjectField> fieldsToBeFilled = new Map<String, Schema.SObjectField>
        {
            'name' => Account.LastName,
            'phone' => Account.Phone,
            'webIdentifier' => Account.WebId__c,
            'documentId' => Account.NationalId__c,
            'language' => Account.Language__c,
            'email' => Account.PersonEmail,
            'bestTimeFrom' => Account.PreferedContactStart__c,
            'bestTimeUntil' => Account.PreferedContactEnd__c,
            'comments' => Account.Description
        };

        Account accountToBeFilled = new Account();
        SalesCRMLeadGenerationService.Lead lead = generateLead();

        Test.startTest();
        SalesCRMLeadGenerationService.fillAccountFields(accountToBeFilled, lead);
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
     * @author amiranda
     * @date 21-09-2023
     **/
    @isTest
    static void test_setNationalIdType_notModifyNationalIdType_OK()
    {
        Account account = new Account(
            Name = 'Test National Id',
            NationalIdType__c = 'US'
            );

        Test.startTest();
        SalesCRMLeadGenerationService.setNationalIdType(account, null);
        Test.stopTest();

        Assert.areNotEqual(SalesCRMLeadGenerationService.NATIONAL_ID_TYPE_NIF,
                           account.NationalIdType__c,
                           'El valor del campo \'NationalIdType__c\' no debería ser ' + SalesCRMLeadGenerationService.NATIONAL_ID_TYPE_NIF);
    }

    /**
     * @description Método de test que comprueba que no se establece el valor 'N'
     * en el campo 'NationalIdType__c' cuando la cuenta que se pasa por parámetro
     * tiene el campo 'NationalId__c' y 'NationalIdType__c' informados.
     *
     * @author amiranda
     * @date  21-09-2023
     **/
    @isTest
    static void test_setNationalIdType_notModifyNationalIdType_fieldsInformed_OK()
    {
        String documentId = '11111112L';
        Account account = new Account(
            Name = 'Test National Id',
            NationalIdType__c = 'US',
            NationalId__c = '111-22-3333'
            );

        Test.startTest();
        SalesCRMLeadGenerationService.setNationalIdType(account, documentId);
        Test.stopTest();

        Assert.areNotEqual(SalesCRMLeadGenerationService.NATIONAL_ID_TYPE_NIF,
                           account.NationalIdType__c,
                           'El valor del campo \'NationalIdType__c\' no debería ser ' + SalesCRMLeadGenerationService.NATIONAL_ID_TYPE_NIF);
    }

    /**
     * @description Método de test que comprueba que se establece el valor 'N'
     * en el campo 'NationalIdType__c' cuando la cuenta que se pasa por parámetro
     * no tiene informado el campo 'NationalId__c'.
     *
     * @author amiranda
     * @date 21-09-2023
     **/
    @isTest
    static void test_setNationalIdType_modifyNationalIdType_OK()
    {
        String documentId = '11111112L';
        Account account = new Account(
            Name = 'Test National Id',
            NationalIdType__c = 'US'
            );

        Test.startTest();
        SalesCRMLeadGenerationService.setNationalIdType(account, documentId);
        Test.stopTest();

        Assert.areEqual(SalesCRMLeadGenerationService.NATIONAL_ID_TYPE_NIF,
                        account.NationalIdType__c,
                        'El valor del campo \'NationalIdType__c\' debería ser ' + SalesCRMLeadGenerationService.NATIONAL_ID_TYPE_NIF);

    }

    // #endregion

    // #region Private methods

    /**
     * @description Método que se encarga de generar un objeto de tipo 'Lead' con
     * todas sus propiedades informadas.
     *
     * @author amiranda
     * @date 21-09-2023
     * @return SalesCRMLeadGenerationService.Lead
     **/
    private static SalesCRMLeadGenerationService.Lead generateLead()
    {
        Date today = Date.today();

        SalesCRMLeadGenerationService.Lead lead = new SalesCRMLeadGenerationService.Lead();
        lead.origin = 'formulario embarcaciones';
        lead.name = 'Test FillAccountFields';
        lead.intermediaryCode = '0000000000';
        lead.phone = '+34666778899';
        lead.webIdentifier = '123456789';
        lead.documentID = '11111111L';
        lead.language = 'Spanish';
        lead.email = 'example@test.com';
        lead.postalCode = '33444';
        lead.bestTimeFrom = Datetime.newInstance(today.year(), today.month(), today.day(), 10, 0, 0);
        lead.bestTimeUntil = Datetime.newInstance(today.year(), today.month(), today.day(), 12, 0, 0);
        lead.comments = 'Comment';

        return lead;
    }

    // #endregion

}