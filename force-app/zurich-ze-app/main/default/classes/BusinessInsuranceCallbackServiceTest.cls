@isTest(SeeAllData=false)
public class BusinessInsuranceCallbackServiceTest
{
    static final String COMPLETE_CALLBACK = '{"name":"Carles Sans","phone":"600666000","bestTimeFrom":"2020-09-28T06:00:00.000Z","bestTimeUntil":"2020-09-28T09:00:00.000Z"}';
    static final String NO_COMPLETE_CALLBACK = '{"name":"Carles Sans","bestTimeFrom":"2020-09-28T06:00:00.000Z","bestTimeUntil":"2020-09-28T09:00:00.000Z"}';
    static final String CALLBACK_WITH_BADTIME = '{"name":"Carles Sans","phone":"600666000","bestTimeFrom":"2050-09-28T06:00:00.000Z","bestTimeUntil":"2020-09-28T09:00:00.000Z"}';

    /**
     * Prueba a validar un Call Me Back (que tenga los campos requeridos)
     */
    @isTest
    static void test_validateRequiredFields_ok()
    {
        BusinessInsuranceCallbackService.CallMeBack deserializedRequest = (BusinessInsuranceCallbackService.CallMeBack) JSON.deserializeStrict(
            COMPLETE_CALLBACK,
            BusinessInsuranceCallbackService.CallMeBack.class
            );

        BusinessInsuranceCallbackService.BusinessInsuranceCallbackServiceException expectedError;

        Test.startTest();
        try
        {
            BusinessInsuranceCallbackService.validateRequiredFields(deserializedRequest);
        }
        catch(BusinessInsuranceCallbackService.BusinessInsuranceCallbackServiceException error)
        {
            expectedError = error;
        }
        Test.stopTest();

        System.assertEquals(null, expectedError, 'No debe lanzar excepción porque están bien los campos rellenos');
    }

    /**
     * Prueba a validar un Call Me Back (que NO tenga los campos requeridos)
     */
    @isTest
    static void test_validateRequiredFields_ko()
    {
        BusinessInsuranceCallbackService.CallMeBack deserializedRequest = (BusinessInsuranceCallbackService.CallMeBack) JSON.deserializeStrict(
            NO_COMPLETE_CALLBACK,
            BusinessInsuranceCallbackService.CallMeBack.class
            );

        BusinessInsuranceCallbackService.BusinessInsuranceCallbackServiceException expectedError;

        Test.startTest();
        try
        {
            BusinessInsuranceCallbackService.validateRequiredFields(deserializedRequest);
        }
        catch(BusinessInsuranceCallbackService.BusinessInsuranceCallbackServiceException error)
        {
            expectedError = error;
        }
        Test.stopTest();

        System.assertNotEquals(null, expectedError, 'No se ha lanzado una excepción y se debería haberla lanzado');
    }

    /**
     * Prueba a insertar un ContactRequest, debe devolver el ID
     */
    @isTest
    static void test_insertCallMeBack_ok()
    {
        BusinessInsuranceCallbackService.CallMeBack deserializedRequest = (BusinessInsuranceCallbackService.CallMeBack) JSON.deserializeStrict(
            COMPLETE_CALLBACK,
            BusinessInsuranceCallbackService.CallMeBack.class
            );

        Test.startTest();
        String contactRequestId = BusinessInsuranceCallbackService.insertCallMeBack(deserializedRequest);
        Test.stopTest();

        ContactRequest cr = [SELECT Id FROM ContactRequest LIMIT 1];

        System.assertEquals(String.valueOf(cr.Id), contactRequestId, 'Se debería haber creado 1 contact request, el ID recibido debería coincidir');
    }

    /**
     * Prueba a insertar un ContactRequest, Pero
     * como saltará una Validation Rule de no más de 30 días
     * petará
     */
    @isTest
    static void test_insertCallMeBack_ko()
    {
        BusinessInsuranceCallbackService.CallMeBack deserializedRequest = (BusinessInsuranceCallbackService.CallMeBack) JSON.deserializeStrict(
            CALLBACK_WITH_BADTIME,
            BusinessInsuranceCallbackService.CallMeBack.class
            );

        BusinessInsuranceCallbackService.BusinessInsuranceCallbackServiceException expectedError;

        Test.startTest();
        try
        {
            String contactRequestId = BusinessInsuranceCallbackService.insertCallMeBack(deserializedRequest);
        }
        catch(BusinessInsuranceCallbackService.BusinessInsuranceCallbackServiceException error)
        {
            expectedError = error;
        }
        Test.stopTest();

        List<ContactRequest> crs = [SELECT Id FROM ContactRequest];
        System.assertEquals(0, crs.size(), 'No debería haberse creado el Contact Request');
        System.assertNotEquals(null, expectedError, 'Debería haber saltado la Validation Rule de que no se permite ContactRequest mayor a 30 días en el futuro');
    }

    /**
     * Comprueba que al insertar un CallMeBack con una fecha fuera del horario de atención,
     * se crea con la próxima hora hábil
     *
     * @author rlopez
     * @date 14/01/2020
     */
    @isTest
    static void test_insertCallMeBack_within_businessHours_ok()
    {
        BusinessInsuranceCallbackService.CallMeBack deserializedRequest = (BusinessInsuranceCallbackService.CallMeBack) JSON.deserializeStrict(
            COMPLETE_CALLBACK,
            BusinessInsuranceCallbackService.CallMeBack.class
            );

        //Modificamos la fecha de bestTimeFrom para que sea una fecha no válida
        List<BusinessHours> businessHoursList = [SELECT Id FROM BusinessHours WHERE Name =: BusinessInsuranceUtil.ZE_BUSINESS_HOURS];
        System.assertEquals(false, businessHoursList.isEmpty(), 'List should NOT be empty');

        Datetime notWithinDatetime = System.now();
        while(BusinessHours.isWithin(businessHoursList.get(0).Id, notWithinDatetime) )
        {
            notWithinDatetime = notWithinDatetime.addDays(1);
        }

        deserializedRequest.bestTimeFrom = notWithinDatetime;

        Test.startTest();
        String contactRequestId = BusinessInsuranceCallbackService.insertCallMeBack(deserializedRequest);
        Test.stopTest();

        ContactRequest cr = [SELECT Id, PreferredContactDatetime__c FROM ContactRequest LIMIT 1];

        System.assertEquals(String.valueOf(cr.Id), contactRequestId, 'Se debería haber creado 1 contact request, el ID recibido debería coincidir');
        System.assertEquals(true, cr.PreferredContactDatetime__c != notWithinDatetime, 'La fecha debería ser distinta a la que hemos especificado en la petición');
        System.assertEquals(true, BusinessHours.isWithin(businessHoursList.get(0).Id, cr.PreferredContactDatetime__c), 'La nueva fecha debería estar dentro del horario de atención');
    }
}