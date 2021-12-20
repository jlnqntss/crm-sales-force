/**
 * Clase helper que permite el borrado de planes comerciales de los RN/CV para sus mediadores que se han creado a 
 * raiz de los planes comerciales del DT/DZ.
 * 
 * Proyecto: SDM - Plan comercial anual
 *
 * @author nts (agonzalezisasi)
 * @date 17/12/2021
 *
 */
public without sharing class GenerateComercialPlanHelper {
    /**
     * Borra los planes comerciales indicados
     * 
     * @author nts (agonzalezisasi)
     * @date 17/12/2021
     * 
     * @param {List<PlanComercial__c> plansToDelete} planes a borrar
     */
    public static void deleteDescendantPlans(List<PlanComercial__c> plans)
    {
        if( plans != null && !plans.isEmpty() ) {
            delete plans;
        }
    }
}
