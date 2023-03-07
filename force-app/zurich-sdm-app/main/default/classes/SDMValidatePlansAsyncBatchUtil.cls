/**
 * Metodos auxiliares para centralizar metodos de validación de planes comerciales y objetivos comunes para las clases SDMInsertPlansAsyncBatch, SDMUpdatePlansAsyncBatch y SDMDeletePlansAsyncBatch
 * 
 * @author nts (dmunoz)
 * @date 23/02/2023
 *
 */
public with sharing class SDMValidatePlansAsyncBatchUtil {


    /**
     * Lista de ids permitidos para generar planes mensuales, PN, Cartera, APES, Retención y Siniestralidad
     * @return List<String>
     * @author dmunoz
     * @date 23/02/2023
     */
    public static List<String> getValidEmailsFromMetadata() {
        AdminSetupParameter__mdt adminSetupParameterMDT = AdminSetupParameter__mdt.getInstance('MensualPlanValidEmails');

        List<String> result = new List<String>();
        String metadataEmailsRaw = adminSetupParameterMDT.Value__c;

        if (String.isNotEmpty(metadataEmailsRaw)) {
            result = new List<String>(metadataEmailsRaw.split(','));
        }
        
        return result;
    }


    /**
     * Comprueba que el flag active del objetivo está a true
     * @param obj: objetivo a consultar
     * @author dmunoz
     * @date 23/02/2023
     */
    public static Boolean isObjectiveActive(Objective__c obj) {
        Boolean result = false;

        if (obj.Active__c == true) {
            result = true;
        }   

        return result;
    }

    /**
     * Comprueba que el rt del objetivo es el adecuado para no tratar el registro específico para el numero de dias a notificar
     * @param obj: objetivo a consultar
     * @author dmunoz
     * @date 23/02/2023
     */
    public static Boolean isRTObjective(Objective__c obj) {
        Boolean result = false;

        if (obj.RecordTypeId.equals(ObjectivesSelector.rtObjectives)) {
            result = true;
        }   

        return result;
    }


    /**
     * Comprueba que el indicador del objetivo es Ratio Retencion
     * @param obj: objetivo a consultar
     * @author dmunoz
     * @date 23/02/2023
     */
    public static Boolean isRetentionObjective(Objective__c obj) {
        Boolean result = false;

        if ('Ratio_Retention'.equals(obj.Indicator__c)) {
            result = true;
        }   

        return result;
    }


    /**
     * Comprueba que el indicador del objetivo es Siniestralidad
     * @param obj: objetivo a consultar
     * @author dmunoz
     * @date 23/02/2023
     */
    public static Boolean isAccidentObjective(Objective__c obj) {
        Boolean result = false;

        if ('Ratio_Claim'.equals(obj.Indicator__c)) {
            result = true;
        }   

        return result;
    }


    /**
     * Comprueba que el rt del objetivo es el adecuado para no tratar el registro específico para el numero de dias a notificar
     * @param obj: objetivo a consultar
     * @author dmunoz
     * @date 23/02/2023
     */
    public static Boolean isOtherIndicator(Objective__c obj) {
        Boolean result = false;

        if ('PN'.equals(obj.Indicator__c) || 'Portfolio'.equals(obj.Indicator__c) || 'APES'.equals(obj.Indicator__c)) {
            result = true;
        }   

        return result;
    }

    /**
     * Comprobamos si un objetivo pasa de inactivo a activo
     * @param obj: Elementos actualizados capturados en el trigger 
     * @param oldMap: valores antiguos de los objetivos capturados en el trigger
     * @return boolean true si ha pasado de inactivo a activo
     * @author dmunoz
     * @date 21/07/2022
     */
    public static Boolean checkActive(Objective__c obj, Map<Id, SObject> oldMap) {
        Boolean result = false;

        Objective__c oldObj = (Objective__c) oldMap.get(obj.Id); 
        Boolean oldActiveFlag = oldObj.Active__c;

        if (!oldActiveFlag && obj.Active__c) { // si old es false y el nuevo es true
            result = true;
        }

        return result;
    }
    

    /**
     * Comprobamos si un objetivo pasa de activo a inactivo
     * @param obj: Elementos actualizados capturados en el trigger 
     * @param oldMap: valores antiguos de los objetivos capturados en el trigger
     * @return boolean true si ha pasado de activo a inactivo
     * @author dmunoz
     * @date 21/07/2022
     */
    public static Boolean checkInactive(Objective__c obj, Map<Id, SObject> oldMap) {
        Boolean result = false;

        Objective__c oldObj = (Objective__c) oldMap.get(obj.Id); 
        Boolean oldActiveFlag = oldObj.Active__c;

        if (oldActiveFlag && !obj.Active__c) { // si old es true y el nuevo es false
            result = true;
        }

        return result;
    }


    /**
     * Validamos si el plan es de tipo Plan Anual
     * @param planComercial: Elementos capturados en el trigger 
     * @return Boolean
     * @author dmunoz
     * @date 21/07/2022
     */
    public static Boolean isPlanAnual(PlanComercial__c planComercial) {
        Boolean result = false;

        Id rtPlanAnualId = Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId();

        if (planComercial.RecordTypeId.equals(rtPlanAnualId)) {
            result = true;
        }

        return result;
    }    
    

    /**
     * De los planes que llegan desde el trigger, para generar los planes mensuales solo nos quedamos con aquellos que son PN, APES y Cartera
     * @param planComercial: Elementos capturados en el trigger
     * @return Boolean
     * @author dmunoz
     * @date 27/02/2023
     */
    public static Boolean checkPlanIndicator(PlanComercial__c planComercial) {
        Boolean result = false;

        if ('PN'.equals(planComercial.Indicator__c) || 'Portfolio'.equals(planComercial.Indicator__c) || 'APES'.equals(planComercial.Indicator__c)) {
            result = true;
        }

        return result;
    }
}