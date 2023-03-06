/**
 * Clase Utilidad PlanComercialTrigger
 * 
 * @author nts (dmunoz)
 * @date 21/07/2022
 *
 */
public with sharing class PlanComercialUtil {
    /**
     * Query de planes mensuales en el before delete para eliminarlos en el after delete del plan anual padre
     * @param oldMap: Elementos eliminados capturados en el trigger 
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    public static List<PlanComercial__c> getPlanesMensualesBeforeDelete(Map<Id, SObject> oldMap) {
        List<PlanComercial__c> planesMensuales = (new PlanComercialSelector()).findMensualPlans(oldMap.values());

        return planesMensuales;
    }    
}