/**
 * Clase de test para la clase selectora del sobject Error_Log__c
 * 
 * @author nts (agonzalezisasi)
 * @date 09/11/2021
 */
@isTest
private with sharing class ErrorLogSelectorTest {
    public static final Integer NUM_ERROR_LOGS = 5;

    @TestSetup
    static void makeData()
    {
        Test.startTest();
        for(Integer i=0; i < NUM_ERROR_LOGS; i++) {
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, 'Generated error ' + i, 'ErrorLogSelectorTest');
        }
        Test.stopTest();
    }

    /**
     * Test del metodo que recupera todos los log de errores
     * 
     * @author nts (agonzalezisasi)
     * @date 09/11/2021
     */
    @isTest
    static void test_findAll()
    {
        Test.startTest();
        List<Error_Log__c> errors = (new ErrorLogSelector()).findAll();
        Test.stopTest();

        System.assertNotEquals(null, errors, 'Deberia haber log de errores registrados');
        System.assertEquals(NUM_ERROR_LOGS, errors.size(), 'Deberia haber 5 log de errores registrados');
    }
}