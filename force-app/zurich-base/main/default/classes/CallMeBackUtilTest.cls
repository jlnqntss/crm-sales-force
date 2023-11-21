/**
 * @description       : Clase de test que comprueba el correcto funcionamiento
 * de la clase 'CallMeBackUtil'.
 *
 * @author            : amiranda
 * @date              : 22-09-2023
 * @last modified on  : 22-09-2023
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

        CallMeBackUtil.CallMeBackFull fullObject = new CallMeBackUtil.CallMeBackFull();
        fullObject.request = requestedCallMeBack;
        fullObject.queueName = queueName;
        fullObject.businessHoursName = businessHoursName;

        List<CallMeBackUtil.CallMeBackFull> lstRequests = new List<CallMeBackUtil.CallMeBackFull>();
        lstRequests.add(fullObject);

        Test.startTest();
        List<String> contactRequestIds = CallMeBackUtil.insertCallMeBack(lstRequests);
        Test.stopTest();

        ContactRequest cr = [SELECT Id FROM ContactRequest LIMIT 1];

        Assert.isNotNull(cr, 'Se debería haber creado un registro del objeto ContactRequest');
        Assert.areEqual(contactRequestIds.get(0),
                        cr.Id,
                        'El Id del ContactRequest debería coincidir por el devuelto por el método \'insertCallMeBack\'');
    }

     /**
     * @description Método que comprueba el correcto funcionamiento del método
     * 'insertCallMeBack' de la clase 'CallMeBackUtil' cuando pasamos múltiples requests.
     *
     * @author arcortazar
     * @date 20-11-2023
     **/
    @isTest
    static void test_insertCallMeBack_bulk_OK()
    {
        Lead_Offers__c leadOffersCS = Lead_Offers__c.getInstance();
        String queueName = leadOffersCS.VoiceQueue__c;
        String businessHoursName = leadOffersCS.BusinessHour__c;
        String businessCode = leadOffersCS.BusinessCode__c;

        CallMeBackUtil.CallMeBack requestedCallMeBack1 = generateCallMeBack();
        CallMeBackUtil.CallMeBack requestedCallMeBack2 = generateCallMeBack();

        CallMeBackUtil.CallMeBackFull fullObject1 = new CallMeBackUtil.CallMeBackFull();
        fullObject1.request = requestedCallMeBack1;
        fullObject1.queueName = queueName;
        fullObject1.businessHoursName = businessHoursName;

        CallMeBackUtil.CallMeBackFull fullObject2 = new CallMeBackUtil.CallMeBackFull();
        fullObject2.request = requestedCallMeBack2;
        fullObject2.queueName = queueName;
        fullObject2.businessHoursName = businessHoursName;

        List<CallMeBackUtil.CallMeBackFull> lstRequests = new List<CallMeBackUtil.CallMeBackFull>();
        lstRequests.add(fullObject1);
        lstRequests.add(fullObject2);

        Test.startTest();
        List<String> contactRequestIds = CallMeBackUtil.insertCallMeBack(lstRequests);
        Test.stopTest();

        List<ContactRequest> lstCR = [SELECT Id FROM ContactRequest];

        Assert.areEqual(false, lstCR.isEmpty(), 'Se deberían haber creado registros del objeto ContactRequest');
        for(ContactRequest cr : lstCR)
        {
            System.assertEquals(true, contactRequestIds.contains(cr.id), 'El Id del ContactRequest debería encontrarse entre los obtenidos mediante el método \'insertCallMeBack\'' );
        }
    }

    /**
     * @description Método de test que comprueba que se lanza una excepción al
     * invocar al método 'insertCallMeBack' de la clase 'CallMeBackUtil' cuando
     * se pasa el valor null como valor del parámetro 'queueName'.
     *
     * @author amiranda
     * @date 21-09-2023
     * 
     * @last modified by arcortazar
     * @date 20-11-2023
     **/
    @isTest
    static void test_insertCallMeBack_nullQueueName_KO()
    {
        Lead_Offers__c leadOffersCS = Lead_Offers__c.getInstance();
        String queueName = null;
        String businessHoursName = leadOffersCS.BusinessHour__c;
        String businessCode = leadOffersCS.BusinessCode__c;

        CallMeBackUtil.CallMeBack requestedCallMeBack = generateCallMeBack();

        CallMeBackUtil.CallMeBackFull fullObject = new CallMeBackUtil.CallMeBackFull();
        fullObject.request = requestedCallMeBack;
        fullObject.queueName = queueName;
        fullObject.businessHoursName = businessHoursName;

        List<CallMeBackUtil.CallMeBackFull> lstRequests = new List<CallMeBackUtil.CallMeBackFull>();
        lstRequests.add(fullObject);

        Test.startTest();
        try
        {
            CallMeBackUtil.insertCallMeBack(lstRequests);
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
     * 
     * @modified by arcortazar
     * @date 20-11-2023
     **/
    @isTest
    static void test_insertCallMeBack_nonExistentQueue_KO()
    {
        Lead_Offers__c leadOffersCS = Lead_Offers__c.getInstance();
        String queueName = 'Non Existent Queue';
        String businessHoursName = leadOffersCS.BusinessHour__c;
        String businessCode = leadOffersCS.BusinessCode__c;

        CallMeBackUtil.CallMeBack requestedCallMeBack = generateCallMeBack();
        CallMeBackUtil.CallMeBack requestedCallMeBack2 = generateCallMeBack();

        CallMeBackUtil.CallMeBackFull fullObject = new CallMeBackUtil.CallMeBackFull();
        fullObject.request = requestedCallMeBack;
        fullObject.queueName = queueName;
        fullObject.businessHoursName = businessHoursName;

        CallMeBackUtil.CallMeBackFull fullObject2 = new CallMeBackUtil.CallMeBackFull();
        fullObject2.request = requestedCallMeBack2;
        fullObject2.queueName = Lead_Offers__c.getInstance().VoiceQueue__c;
        fullObject2.businessHoursName = businessHoursName;

        List<CallMeBackUtil.CallMeBackFull> lstRequests = new List<CallMeBackUtil.CallMeBackFull>();
        lstRequests.add(fullObject);
        lstRequests.add(fullObject2);

        Test.startTest();
        try
        {
            CallMeBackUtil.insertCallMeBack(lstRequests);
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