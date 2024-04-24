/**
 * Clase de test para AvailableCasePicklistValuesByRtAction
 *
 * @author mario.navarro@seidor.com
 * @date 15/04/2024
 */
@isTest
public with sharing class Test_AvailableCasePicklistValuesByRtAct
{

    /**
     * Testea el metodo findValues
     *
     * @author mario.navarro@seidor.com
     * @date 15/04/2024
     */
    @isTest
    private static void test_findValues()
    {
        AvailableCasePicklistValuesByRtAction.AvailableCasePicklistValuesByRtActionRequest request = new AvailableCasePicklistValuesByRtAction.AvailableCasePicklistValuesByRtActionRequest();
        request.fieldName = 'CallCenter__c';
        request.recordTypeId = CaseUtil.RT_ID_ZDA;
        List<AvailableCasePicklistValuesByRtAction.AvailableCasePicklistValuesByRtActionRequest> reqList = new List<AvailableCasePicklistValuesByRtAction.AvailableCasePicklistValuesByRtActionRequest>();
        reqList.add(request);

        List<List<Case> > respList;
        Test.startTest();
        Test.setMock( HttpCalloutMock.class, new ToolingAPIMock() );
        respList = AvailableCasePicklistValuesByRtAction.findValues(reqList);
        Test.stopTest();

        Assert.isFalse( respList.isEmpty() );
        Assert.isFalse( respList[0].isEmpty() );
        //El mock esta preparado para que retorne 'Anulación', 'Cambio de intermediario' y 'Campaña'
        Assert.areEqual( 3, respList[0].size() );
        for (Case returnedCase : respList[0])
        {
            if (returnedCase.ActivityDescription__c != 'Anulación' &&
                returnedCase.ActivityDescription__c != 'Cambio de intermediario' &&
                returnedCase.ActivityDescription__c != 'Campaña')
            {
                Assert.fail('Ha llegado un valor inesperado');
            }
        }
    }
}