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

        Map<String, Objective__c> retentionObjectives = objectivesMap.get('RetentionObjectives'); // retencion
        Map<String, Objective__c> accidentObjectives = objectivesMap.get('AccidentObjectives'); // siniestralidad        

        List<PlanComercial__c> retentionPlansList = generateAnualPlans(retentionObjectives, validUserIdsList); // generar planes anuales retencion
        List<PlanComercial__c> accidentPlansList = generateAnualPlans(accidentObjectives, validUserIdsList); // generar planes anuales siniestralidad

        // añado todos los elementos a la lista resultado para que se inserten a la vez
        result.addAll(retentionPlansList);
        result.addAll(accidentPlansList);

        return result;
    }


    /**
     * Metodo principal de generar planes anuales a partir de objetivo usado desde SDMUpdatePlansAsyncBatch
     * @param mapObjetivos: objetivos modificados
     * @return void
     * @author dmunoz
     * @date 24/02/2023
     */
    public static List<PlanComercial__c> generateAnualPlansFromUpdateObjectives(Map<String, Objective__c> objetivosToUpdateActiveAnual, List<String> validEmailList) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();

        // recupero los ids de los usuarios piloto
        List<User> validUserIdsList = getIdsValidUser(validEmailList);  

        result = generateAnualPlans(objetivosToUpdateActiveAnual, validUserIdsList);

        return result;
    }


    /********************************************************* Metodos auxiliares generateAnualPlansFromObjectives **********************************************************************************/

    /**
     * Metodo para generar los planes anuales de retencion y/o de siniestralidad
     * @param objectivesMap: mapa de objetivos filtrados
     * @param validUserIdsList: lista de ids usuario
     * @author dmunoz
     * @date 23/02/2023
     */
    private static List<PlanComercial__c> generateAnualPlans(Map<String, Objective__c> objectivesMap, List<User> validUserIdsList) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();        

        for (Objective__c obj: objectivesMap.values()) {
            for (User user: validUserIdsList) {
                if ('Ratio_Retention'.equals(obj.Indicator__c)) {
                    result.add(calculateRetentionPlan(obj, user));
                } else if ('Ratio_Claim'.equals(obj.Indicator__c)) {
                    result.add(calculateAccidentPlan(obj, user));
                }
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

        PlanComercial__c plan = calculateAnualPlan(obj, user);
        plan.Name = 'Retención Anual Zurich ' + obj.Segment__c + ' ' + obj.Zone__c;

        return plan;
    }


    /**
     * Metodo para generar los planes anuales de retencion
     * @param obj: objetivo
     * @param user: usuario piloto
     * @author dmunoz
     * @date 23/02/2023
     */
    private static PlanComercial__c calculateAccidentPlan(Objective__c obj, User user) {

        PlanComercial__c plan = calculateAnualPlan(obj, user);
        plan.Name = 'Siniestralidad Anual Zurich ' + obj.Segment__c + ' ' + obj.Zone__c;

        return plan;
    }


    /**
     * Metodo para generar los datos comunes de los planes anuales de retencion y siniestralidad
     * @param obj: objetivo
     * @param user: usuario piloto
     * @author dmunoz
     * @date 23/02/2023
     */
    private static PlanComercial__c calculateAnualPlan(Objective__c obj, User user) {

        PlanComercial__c plan = new PlanComercial__c();        
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