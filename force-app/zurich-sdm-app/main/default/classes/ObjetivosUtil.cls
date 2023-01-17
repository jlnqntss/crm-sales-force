/**
 * Clase Utilidad ObjetivosTrigger
 * 
 * @author nts (dmunoz)
 * @date 29/07/2022
 *
 */
public with sharing class ObjetivosUtil {

    /**
     * Invocar a la clase encolable para los objetivos insertador
     * @param planesComercialesList: Elementos insertados/actualizados capturados en el trigger 
     * @param action: identifica si es insert/update
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    public static void altaJobInsertObjetivos(List<Objective__c> newList) {

        Map<String, Map<String, Objective__c>> objectivesToJob = new Map<String, Map<String, Objective__c>>();        
        Map<String, Objective__c> objetivosToInsert = new Map<String, Objective__c>(); // map externalId, Objetivo

        for (Objective__c obj: newList) {
            if (obj.Active__c == true && obj.RecordTypeId.equals(ObjectivesSelector.rtObjectives)) { // solo generamos planes de objetivos que se inserten activos
                objetivosToInsert.put(obj.ExternalId__c, obj);      
            }                 
        }

        // envio todos los objetivos juntos 
        if (!objetivosToInsert.isEmpty()) {        
            objectivesToJob.put('ObjetivosInsert', objetivosToInsert);
            
            System.enqueueJob(new GestionarPlanesMensualesQueueableJob(objectivesToJob, 'Insert'));
        }
    }
    

    /**
     * Invocar a la clase encolable para los objetivos modificados
     * @param planesComercialesList: Elementos actualizados capturados en el trigger 
     * @param action: identifica si es insert/update
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    public static void altaJobUpdateObjetivos(List<Objective__c> newList, Map<Id, SObject> oldMap) {

        Map<String, Map<String, Objective__c>> objectivesToJob = new Map<String, Map<String, Objective__c>>();

        // compruebo si se ha modificado pesos y/o active
        Map<String, Objective__c> objetivosToUpdatePesos = new Map<String, Objective__c>(); // map externalId, Objetivo
        Map<String, Objective__c> objetivosToUpdateActive = new Map<String, Objective__c>(); // map externalId, Objetivo
        Map<String, Objective__c> objetivosToUpdateInactive = new Map<String, Objective__c>(); // map externalId, Objetivo

        for (Objective__c obj: newList) {
            if (checkActive(obj, oldMap) && obj.RecordTypeId.equals(ObjectivesSelector.rtObjectives)) { // valido primero el flag de activo, si se activa generaremos nuevos planes
                objetivosToUpdateActive.put(obj.ExternalId__c, obj);
            } else if (checkInactive(obj, oldMap)) { // si uno de los cambios del objetivo es inactivar, borraremos los planes mensuales
                objetivosToUpdateInactive.put(obj.ExternalId__c, obj);
            } else if (checkPesos(obj, oldMap) && obj.Active__c == true) { // actualizaremos los planes mensuales de los que se cambien pesos y el flag active sigue siendo true
                objetivosToUpdatePesos.put(obj.ExternalId__c, obj);
            }
        }

        // envio todos los objetivos juntos 
        if (!objetivosToUpdatePesos.isEmpty() || !objetivosToUpdateActive.isEmpty() || !objetivosToUpdateInactive.isEmpty()) {        
            objectivesToJob.put('ObjetivosToUpdatePesos', objetivosToUpdatePesos);
            objectivesToJob.put('ObjetivosToUpdateActive', objetivosToUpdateActive);
            objectivesToJob.put('ObjetivosToUpdateInactive', objetivosToUpdateInactive);
            
            System.enqueueJob(new GestionarPlanesMensualesQueueableJob(objectivesToJob, 'Update'));
        }
    }


    /**
     * Invocar a la clase encolable para eliminar los planes mensuales afectados por los objetivo eliminado
     * @param planesComercialesList: Elementos eliminados capturados en el trigger 
     * @param action: identifica si es insert/update
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    public static void altaJobEliminarObjetivos(Map<Id, SObject> oldMap) {
        Map<String, Map<String, Objective__c>> objectivesToJob = new Map<String, Map<String, Objective__c>>();
        Map<String, Objective__c> objectivesToDelete = new Map<String, Objective__c>();

        for (Objective__c obj: (List<Objective__c>) oldMap.values()) {
            if (obj.RecordTypeId.equals(ObjectivesSelector.rtObjectives)) objectivesToDelete.put(obj.ExternalId__c, obj);
        }

        if (!objectivesToDelete.isEmpty()) {
            objectivesToJob.put('ObjetivosToDelete', objectivesToDelete);
            System.enqueueJob(new GestionarPlanesMensualesQueueableJob(objectivesToJob, 'Delete'));    
        }            
    }


    /******************* Metodos auxiliares *******************************************/
    /**
     * Comprobamos si un objetivo pasa de inactivo a activo
     * @param obj: Elementos actualizados capturados en el trigger 
     * @param oldMap: valores antiguos de los objetivos capturados en el trigger
     * @return boolean true si ha pasado de inactivo a activo
     * @author dmunoz
     * @date 21/07/2022
     */
    private static Boolean checkActive(Objective__c obj, Map<Id, SObject> oldMap) {
        Boolean result = false;

        Objective__c oldObj = (Objective__c) oldMap.get(obj.Id); 
        Boolean oldActiveFlag = oldObj.Active__c;

        if (!oldActiveFlag && obj.Active__c) { // si old es false y el nuevo es true
            result = true;
        }

        return result;
    }

    /******************* Metodos auxiliares *******************************************/
    /**
     * Comprobamos si un objetivo pasa de activo a inactivo
     * @param obj: Elementos actualizados capturados en el trigger 
     * @param oldMap: valores antiguos de los objetivos capturados en el trigger
     * @return boolean true si ha pasado de activo a inactivo
     * @author dmunoz
     * @date 21/07/2022
     */
    private static Boolean checkInactive(Objective__c obj, Map<Id, SObject> oldMap) {
        Boolean result = false;

        Objective__c oldObj = (Objective__c) oldMap.get(obj.Id); 
        Boolean oldActiveFlag = oldObj.Active__c;

        if (oldActiveFlag && !obj.Active__c) { // si old es true y el nuevo es false
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
    private static Boolean checkPesos(Objective__c obj, Map<Id, SObject> oldMap) {
        Boolean result = false;

        Objective__c oldObj = (Objective__c) oldMap.get(obj.Id); 
        Decimal oldJanuary = oldObj.January__c;
        Decimal oldFebruary = oldObj.February__c;
        Decimal oldMarch = oldObj.March__c;
        Decimal oldApril = oldObj.April__c;
        Decimal oldMay = oldObj.May__c;
        Decimal oldJune = oldObj.June__c;
        Decimal oldJuly = oldObj.July__c;
        Decimal oldAugust = oldObj.August__c;
        Decimal oldSeptember = oldObj.September__c;
        Decimal oldOctober = oldObj.October__c;
        Decimal oldNovember = oldObj.November__c;
        Decimal oldDecember = oldObj.December__c;

        Decimal newJanuary = obj.January__c;
        Decimal newFebruary = obj.February__c;
        Decimal newMarch = obj.March__c;
        Decimal newApril = obj.April__c;
        Decimal newMay = obj.May__c;
        Decimal newJune = obj.June__c;
        Decimal newJuly = obj.July__c;
        Decimal newAugust = obj.August__c;
        Decimal newSeptember = obj.September__c;
        Decimal newOctober = obj.October__c;
        Decimal newNovember = obj.November__c;
        Decimal newDecember = obj.December__c;

        // si ha cambiado el peso de algún mes devuelvo true
        if (oldJanuary != newJanuary || oldFebruary != newFebruary || oldMarch != newMarch  || oldApril != newApril || oldMay != newMay || oldJune != newJune || 
            oldJuly != newJuly || oldAugust != newAugust || oldSeptember != newSeptember || oldOctober != newOctober || oldNovember != newNovember || oldDecember != newDecember) { 
            result = true;
        }

        return result;
    }
}
