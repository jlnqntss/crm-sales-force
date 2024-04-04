@isTest
public with sharing class CaseCheckTypificationActionTest {
    
    @isTest
    static void test_CaseCheckTypificationAction_OK()
    {
        String recordTypeOCS = CaseUtil.RT_ID_OCSINQUIRY;

        // Preparamos la Request
        List<CaseCheckTypificationAction.CheckTypificationRequest> typificationRequests = new List<CaseCheckTypificationAction.CheckTypificationRequest>();

        CaseCheckTypificationAction.CheckTypificationRequest request = new CaseCheckTypificationAction.CheckTypificationRequest();
        request.RecordTypeId = recordTypeOCS;
        request.TypeN1 = 'A';
        request.TypeN2 = 'A1';
        request.TypeN3 = 'A11';

        typificationRequests.add(request);

        // Preparamos la respuesta
        List<CaseCheckTypificationAction.CheckTypificationResponse> listResponses = new List<CaseCheckTypificationAction.CheckTypificationResponse>();

        test.startTest();
        listResponses = CaseCheckTypificationAction.checkTypification(typificationRequests);
        test.stopTest();

        // Probamos los resultados
        System.assertEquals(false, listResponses.isEmpty(), 'List should NOT be empty');
        System.assertEquals(1, listResponses.size(), 'List should have 1 response');
        System.assertEquals(true, listResponses[0].isValid, 'Typification should be available for the recordtype');

    }

    @isTest
    static void test_CaseCheckTypificationAction_KO()
    {
        String recordTypeOCS = CaseUtil.RT_ID_OCSINQUIRY;

        // Preparamos la Request
        List<CaseCheckTypificationAction.CheckTypificationRequest> typificationRequests = new List<CaseCheckTypificationAction.CheckTypificationRequest>();

        CaseCheckTypificationAction.CheckTypificationRequest request = new CaseCheckTypificationAction.CheckTypificationRequest();
        request.RecordTypeId = recordTypeOCS;
        request.TypeN1 = 'A';
        request.TypeN2 = 'A1';
        request.TypeN3 = 'No existe';

        typificationRequests.add(request);

        // Preparamos la respuesta
        List<CaseCheckTypificationAction.CheckTypificationResponse> listResponses = new List<CaseCheckTypificationAction.CheckTypificationResponse>();

        test.startTest();
        listResponses = CaseCheckTypificationAction.checkTypification(typificationRequests);
        test.stopTest();

        // Probamos los resultados
        System.assertEquals(false, listResponses.isEmpty(), 'List should NOT be empty');
        System.assertEquals(1, listResponses.size(), 'List should have 1 response');
        System.assertEquals(false, listResponses[0].isValid, 'Typification should NOT be available for the recordtype');
    }
}