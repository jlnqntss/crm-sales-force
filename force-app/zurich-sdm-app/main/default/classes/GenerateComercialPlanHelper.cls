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
     * Busca los planes comerciales "hijos" de los planes comerciales anuales dados
     * 
     * @author nts (agonzalezisasi)
     * @date 17/12/2021
     * 
     * @param {List<PlanComercial__c> plansToDelete} planes "padres"
     */
    public static void deleteDescendantPlans(List<PlanComercial__c> plans)
    {
        if( plans != null && !plans.isEmpty() ) {
            // Se recupera la lista de planes descendientes (hijos) de los planes dados
            List<PlanComercial__c> childPlans = (new PlanComercialSelector()).findAnnualPlanDescendants(plans);

            if( childPlans != null && !childPlans.isEmpty() ) {
                delete childPlans;
            }
        }
    }
}
