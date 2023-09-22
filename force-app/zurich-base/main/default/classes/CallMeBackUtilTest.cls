/**
 * @description       : Clase de test que comprueba el correcto funcionamiento
 * de la clase 'CallMeBackUtil'.
 *
 * @author            : amiranda
 * @date              : 21-09-2023
 * @last modified on  : 21-09-2023
 * @last modified by  : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   21-09-2023   amiranda   Initial Version
 **/
@isTest
public with sharing class CallMeBackUtilTest
{

    @TestSetup
    static void makeData()
    {
        Lead_Offers__c leadOffer = TestDataFactory.generateLeadOfferCS();
        insert leadOffer;
    }

    // #region Test methods

    /**
     * @description Método que comprueba el correcto funcionamiento del método
     * 'insertCallMeBack' de la clase 'CallMeBackUtil'.
     *
     * @author amiranda
     * @date 21-09-2023
     **/
    @isTest
    static void test_insertCallMeBack_OK()
    {
        Lead_Offers__c leadOffersCS = Lead_Offers__c.getInstance();
        String queueName = leadOffersCS.VoiceQueue__c;
        String businessHoursName = leadOffersCS.BusinessHour__c;
        String businessCode = leadOffersCS.BusinessCode__c;

        CallMeBackUtil.CallMeBack requestedCallMeBack = generateCallMeBack();

        Test.startTest();
        String contactRequestId = CallMeBackUtil.insertCallMeBack(requestedCallMeBack, queueName, businessHoursName, businessCode);
        Test.stopTest();

        ContactRequest cr = [SELECT Id FROM ContactRequest LIMIT 1];

        Assert.isNotNull(cr, 'Se debería haber creado un registro del objeto ContactRequest');
        Assert.areEqual(contactRequestId,
                        cr.Id,
                        'El Id del ContactRequest debería coincidir por el devuelto por el método \'insertCallMeBack\'');
    }

    /**
     * @description Método de test que comprueba que se lanza una excepción al
     * invocar al método 'insertCallMeBack' de la clase 'CallMeBackUtil' cuando
     * se pasa el valor null como valor del parámetro 'queueName'.
     *
     * @author amiranda
     * @date 21-09-2023
     **/
    @isTest
    static void test_insertCallMeBack_nullQueueName_KO()
    {
        Lead_Offers__c leadOffersCS = Lead_Offers__c.getInstance();
        String queueName = null;
        String businessHoursName = leadOffersCS.BusinessHour__c;
        String businessCode = leadOffersCS.BusinessCode__c;

        CallMeBackUtil.CallMeBack requestedCallMeBack = generateCallMeBack();

        Test.startTest();
        try
        {
            CallMeBackUtil.insertCallMeBack(requestedCallMeBack, queueName, businessHoursName, businessCode);
        }
        catch (Exception ex)
        {
            Assert.areEqual(CallMeBackUtil.CallMeBackException.class.toString(),
                            ex.getTypeName(),
                            'El tipo de excepción no coincide');
            Assert.isTrue(ex.getMessage().contains('Genesys \'queueName\' can not be null'),
                          'El mensaje de error de la excepción no es el esperado.');
        }
        Test.stopTest();
    }

    /**
     * @description Método de test que comprueba que se lanza una excepción al
     * invocar al método 'insertCallMeBack' de la clase 'CallMeBackUtil' cuando
     * no existe la cola de Genesys pasada por parámetro.
     *
     * @author amiranda
     * @date 21-09-2023
     **/
    @isTest
    static void test_insertCallMeBack_nonExistentQueue_KO()
    {
        Lead_Offers__c leadOffersCS = Lead_Offers__c.getInstance();
        String queueName = 'Non Existent Queue';
        String businessHoursName = leadOffersCS.BusinessHour__c;
        String businessCode = leadOffersCS.BusinessCode__c;

        CallMeBackUtil.CallMeBack requestedCallMeBack = generateCallMeBack();

        Test.startTest();
        try
        {
            CallMeBackUtil.insertCallMeBack(requestedCallMeBack, queueName, businessHoursName, businessCode);
        }
        catch (Exception ex)
        {
            Assert.areEqual(CallMeBackUtil.CallMeBackException.class.toString(),
                            ex.getTypeName(),
                            'El tipo de excepción no coincide');
            Assert.isTrue(ex.getMessage().contains('Genesys ' + queueName + ' queue does not exist'),
                          'El mensaje de error de la excepción no es el esperado.');
        }
        Test.stopTest();
    }

    // #endregion

    // #region Private methods

    /**
     * @description Método que genera un objeto de la clase CallMeBackUtil.CallMeBack
     * con la información necesaria rellenada.
     *
     * @author amiranda
     * @date 21-09-2023
     * @return CallMeBackUtil.CallMeBack con la información necesaria rellenada
     **/
    private static CallMeBackUtil.CallMeBack generateCallMeBack()
    {
        Date today = Date.today();

        CallMeBackUtil.CallMeBack callMeBack = new CallMeBackUtil.CallMeBack();
        callMeBack.name = 'Test CallMeBack';
        callMeBack.phone = '+34688991212';
        callMeBack.bestTimeFrom = Datetime.newInstance(today.year(), today.month(), today.day(), 10, 0, 0);
        callMeBack.bestTimeUntil = Datetime.newInstance(today.year(), today.month(), today.day(), 11, 0, 0);
        callMeBack.webIdentifier = '123456789';
        callMeBack.businessCode = '123456789';

        return callMeBack;
    }

    // #endregion
}