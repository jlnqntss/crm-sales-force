@isTest
public with sharing class CallCenterSelectorTest {


    /**
     * Test del método que recupera valor de callcenter
     * @author dmunoz
     * @date 26/06/2023
     */
    @isTest static void test_findCallCenterFromInternalName() {

        List<CallCenter> callCenterQueryList = new List<CallCenter>([SELECT Id, InternalName FROM CallCenter LIMIT 1]);

        if (!callCenterQueryList.isEmpty()) {
            CallCenter result = (new CallCenterSelector()).findCallCenterFromInternalName(callCenterQueryList.get(0).InternalName);

            System.assertEquals(true, result != null, 'Debe de existir resultado');
        }
    }
    
}