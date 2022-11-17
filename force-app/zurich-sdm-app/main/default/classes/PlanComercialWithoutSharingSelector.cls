/**
 * Clase selector del objeto PlanComercial__c without sharing. 
 * Se ha creado por la problematica que hay al eliminar planes desde un director, 
 * cuando el rn ha bajado planes a algun mediador donde su director no está en el equipo de cuentas
 *  no se encuentran dichos planes al intentar borrar su plan y todos los que dependen de él por lo que pueden quedar planes sin eliminar
 *
 * Proyecto: SDM (Sales Digital Management)
 *
 * @author nts (dmunoz)
 * @date 16/11/2022
 */
public without sharing class PlanComercialWithoutSharingSelector {

    public static final String RT_NAME_PLAN_ANUAL = 'AnualPlan'; // Recordtype PlanComercial__c=>PlanAnual

    public PlanComercialWithoutSharingSelector() {}

    // Id del tipo de registro de PlanAnual
    public ID rtPlanAnualId {
        get {
            return Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get(RT_NAME_PLAN_ANUAL)?.getRecordTypeId();
        }
    }


    /**
     * Recupera los planes comerciales anuales "hijos" de los planes comerciales anuales dados.
     * Ignorandose a si mismos si fueran "hijos" de algun otro plan de la lista.
     * 
     * @author nts (dmunoz)
     * @date 16/11/2022
     * 
     * @param {List<PlanComercial__c} plnes
     * @return {List<PlanComercial__c>} lista de planes descendientes
     */
    public List<PlanComercial__c> findAnnualPlanDescendants(List<PlanComercial__c> plans)
    {
        List<PlanComercial__c> childPlans = null;

        if( plans != null && !plans.isEmpty() ) {
            childPlans = [
                SELECT Id, Name, Product__c, Segment__c, Indicator__c, 
                ParentPlan__r.Name, ParentPlan__r.Product__c, ParentPlan__r.Segment__c, ParentPlan__r.Indicator__c, 
                TargetKPICurrency__c, TargetKPINumber__c, TargetKPIPercent__c
                FROM PlanComercial__c
                WHERE RecordTypeId = :rtPlanAnualId
                AND ParentPlan__c IN :plans
                AND Id NOT IN :plans
            ];
        }        

        return childPlans;
    }
}
