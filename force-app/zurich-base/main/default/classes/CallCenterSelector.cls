/**
 * @description       : Clase selectora del sobject CallCenter
 * @author            : dmunoz
 * @group             : 
 * @last modified on  : 12/06/2023
 * @last modified by  : dmunoz
**/
public with sharing class CallCenterSelector {

    public CallCenter findCallCenterFromInternalName(String internalName) {

        CallCenter result = null;

        if (internalName != null && String.isNotEmpty(internalName)) {
            List<CallCenter> callCenters = new List<CallCenter>([
                    SELECT Id FROM CallCenter WHERE InternalName = :internalName
            ]);
            if (!callCenters.isEmpty()) {
                result = callCenters.get(0);
            }
        }
        return result;
    }
    
}