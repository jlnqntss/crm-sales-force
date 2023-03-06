/**
 * Clase utilidad que contiene los métodos necesarios para generar y actualizar planes mensuales
 * 
 * @author nts (dmunoz)
 * @date 23/02/2023
 *
 */
public with sharing class PlanesComercialesAnualesUtil {    
    
    /**
     * Metodo principal de generar planes anuales a partir de objetivos usado desde SDMInsertPlansAsyncBatch
     * @param mapObjetivos: objetivos modificados
     * @return void
     * @author dmunoz
     * @date 24/02/2023
     */
    public static List<PlanComercial__c> generateAnualPlansFromObjectives(Map<String, Map<String, Objective__c>> objectivesMap, List<String> validEmailList) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();

        // recupero los ids de los usuarios piloto     
        List<User> validUserIdsList = getIdsValidUser(validEmailList);

        Map<String, Objective__c> retentionObjectives = objectivesMap.get('RetentionObjectives');

        List<PlanComercial__c> retentionPlansList = generateAnualRetentionPlans(retentionObjectives, validUserIdsList);

        // añado todos los elementos a la lista resultado, dejo preparado para siniestralidad
        result.addAll(retentionPlansList);


        return result;
    }


    /**
     * Metodo principal de generar planes anuales a partir de objetivo usado desde SDMUpdatePlansAsyncBatch
     * @param mapObjetivos: objetivos modificados
     * @return void
     * @author dmunoz
     * @date 24/02/2023
     */
    public static List<PlanComercial__c> generateAnualPlansFromObjectives(Map<String, Objective__c> objetivosToUpdateActiveAnual, List<String> validEmailList) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();

        // recupero los ids de los usuarios piloto
        List<User> validUserIdsList = getIdsValidUser(validEmailList);  

        List<PlanComercial__c> retentionPlansList = generateAnualRetentionPlans(objetivosToUpdateActiveAnual, validUserIdsList);

        // añado todos los elementos a la lista resultado, dejo preparado para siniestralidad
        result.addAll(retentionPlansList);


        return result;
    }


    /********************************************************* Metodos auxiliares generateAnualPlansFromObjectives **********************************************************************************/

    /**
     * Metodo para generar los planes anuales de retencion
     * @param retentionObjectives: mapa de objetivos filtrados
     * @param validUserIdsList: lista de ids usuario
     * @author dmunoz
     * @date 23/02/2023
     */
    private static List<PlanComercial__c> generateAnualRetentionPlans(Map<String, Objective__c> retentionObjectives, List<User> validUserIdsList) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();        

        for (Objective__c obj: retentionObjectives.values()) {
            for (User user: validUserIdsList) {
                result.add(calculateRetentionPlan(obj, user));
            }
        }

        return result;
    }


    /**
     * Metodo para generar los planes anuales de retencion
     * @param obj: objetivo
     * @param user: usuario piloto
     * @author dmunoz
     * @date 23/02/2023
     */
    private static PlanComercial__c calculateRetentionPlan(Objective__c obj, User user) {

        PlanComercial__c plan = new PlanComercial__c();
        plan.Name = 'Retención Anual Zurich ' + obj.Segment__c + ' ' + obj.Zone__c;
        plan.OwnerId = UserInfo.getUserId(); // será un home office
        plan.AssignedTo__c = user.Id;
        plan.RecordTypeId = Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId();
        plan.Indicator__c = obj.Indicator__c;
        plan.Segment__c = obj.Segment__c;
        plan.Product__c = obj.Product__c;
        plan.Zone__c = obj.Zone__c;
        plan.StartDate__c = Date.newinstance(Integer.valueOf(obj.Year__c), 1, 1);
        plan.EndDate__c = Date.newinstance(Integer.valueOf(obj.Year__c), 12, 31);
        plan.SendNotifications__c = '01';
        plan.SentNotifications__c = '01;02;03'; // seteo las notificaciones de estos planes para no lanzar ninguna notificación para este tipo de plan anual
        plan.AccumulateType__c = 'YTD';
        plan.Completed__c = false;
        plan.Description__c = plan.Name;

        return plan;
    }

    /******************************************************* Métodos auxiliares *****************************************************************************************/

    /**
     * Obtener los ids de los usuarios del piloto
     * @param validEmailList: lista de emails del piloto
     * @author dmunoz
     * @date 23/02/2023
     */
    private static List<User> getIdsValidUser(List<String> validEmailList) {
        List<User> result = (new UserSelector()).getIdsValidUser(validEmailList);

        if (Test.isRunningTest()) {
            result = (new UserSelector()).getSDMUserId();
        }
        return result;
    }
}