/**
 * Proceso principal para actualizar planes de retención, siniestralidad y mensuales desde el trigger de plan comercial y objetivos.
 * Se lanza desde el trigger after update de objetivos y plan comercial
 * 
 * @author nts (dmunoz)
 * @date 23/02/2023
 *
 */
public with sharing class SDMUpdatePlansAsyncBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private static Integer numRecordsDML = 1000;
    private static Integer numDML = 0;
    private static Integer numElemsBatch = 0;

    private List<SObject> elemsFromTrigger; // elementos actualizados que llegan desde el trigger de objetivo o plan comercial o desde los sucesivos batch
    private Map<Id, SObject> oldMap; // // elementos antes de actualizar que llegan desde el trigger de objetivo o plan comercial
    private Map<String, List<PlanComercial__c>> planesCalculadosMap; // elementos a realizar los distintos dmls
    private String action;
    private Boolean isError; // en caso de que se lance una excepción, informamos este flag para que no se lancen mas ejecuciones

    public SDMUpdatePlansAsyncBatch(List<SObject> newList, Map<Id, SObject> oldMap, String action) {
        this.elemsFromTrigger = newList;
        this.oldMap = oldMap;
        this.planesCalculadosMap = new Map<String, List<PlanComercial__c>>();
        this.action = action;
        this.isError = false;
    }


    public SDMUpdatePlansAsyncBatch(Map<String, List<PlanComercial__c>> planesCalculadosMap) {
        this.planesCalculadosMap = planesCalculadosMap;
        this.action = 'DMLRecursivo';
        this.isError = false;
    }


    /**
     * recibe los elementos que el batch va a tratar
     * @param bc: elementos recibidos en el constructor
     * @return List<PlanComercial__c> elementos recibidos en el constructor
     * @author dmunoz
     * @date 23/02/2023
     */
    public List<SObject> start(Database.BatchableContext bc) {
        System.debug('Entro en start ' + action);
        List<SObject> batchElemsToProcess = getStartElements();
        return batchElemsToProcess;
    }

    /**
     * metodo principal del batch, ejecuta estas acciones para los registros recibidos en start
     * @param bc: contexto batch
     * @param scope elementos recibidos en el constructor
     * @author dmunoz
     * @date 23/02/2023
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            System.debug('Entro en execute ' + action);

            if (scope != null && !scope.isEmpty()) {

                switch on action {
                    when 'UpdateFromObjectives' {
                        updatePlansByObjectives(scope);
                    } when 'UpdateFromPlanComercial' {
                        updateMensualPlansByPlanComercial(scope);
                    } when 'DMLRecursivo' { // llamada recursiva
                        doDMLs(planesCalculadosMap);
                    } when else {
                        throw new HandledException('Action no valido');
                    }
                }
            }

        } catch (Exception e) {
            isError = true;
            ErrorLogUtil.commitError(e, 'SDMUpdatePlansAsyncBatch');
        }
    }

    /**
     * metodo final del batch, se encarga de hacer llamadas recursivas en caso de haber generado mas datos de los que puede insertar de una vez
     * @param bc: contexto batch
     * @author dmunoz
     * @date 23/02/2023
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('entro en finish ' + action);
        if (continueRecursive()) {            
            Database.executeBatch(new SDMUpdatePlansAsyncBatch(planesCalculadosMap), numElemsBatch); // batch de planes mensuales
        }
    }


    /******************************************************* Métodos principales *****************************************************************************************/

    /**
     * Devuelve los elementos a procesar según el action recibido
     * @author dmunoz
     * @date 23/02/2023
     */
    private List<SObject> getStartElements() {

        switch on action {
            when 'UpdateFromObjectives' {
                return elemsFromTrigger;
            }
            when 'UpdateFromPlanComercial' {
                return elemsFromTrigger;
            }
            when 'DMLRecursivo' {
               return getRecursiveStartList(); // devuelvo la lista de planes que tocaría hacer dml, pero utilizaré en el metodo execute el mapa calculado en los action principales y que se pasa desde el finally
            }
            when else {
                throw new HandledException('Action no permitido en Start');
            }
        }
    }

    /**
     * Devuelve una lista de planes en orden de dml que utilizaremos en los batch recursivos, no utilizaremos estas listas solo sirve para entrar en el metodo execute y ahí usamos el mapa calculado en la primera iteracion
     * @param scope: Lista de objetivos recibidos desde el trigger de objetivos
     * @author dmunoz
     * @date 23/02/2023
     */
    private List<PlanComercial__c> getRecursiveStartList() {

        List<PlanComercial__c> result = new List<PlanComercial__c>(); // devuelvo lista vacia cuando haya terminado de procesar todos los elementos anteriores
        List<PlanComercial__c> planesMensualesToInsert = planesCalculadosMap.get('PlanesMensualesToInsert');
        List<PlanComercial__c> planesMensualesToUpdate = planesCalculadosMap.get('PlanesMensualesToUpdate');
        List<PlanComercial__c> planesMensualesToDelete = planesCalculadosMap.get('PlanesMensualesToDelete');
        List<PlanComercial__c> planesAnualesToDelete = planesCalculadosMap.get('PlanesAnualesToDelete');

        if (planesMensualesToInsert != null && !planesMensualesToInsert.isEmpty()) {
            result = planesMensualesToInsert;
        } else if (planesMensualesToUpdate != null && !planesMensualesToUpdate.isEmpty()) {
            result = planesMensualesToUpdate;
        } else if (planesMensualesToDelete != null && !planesMensualesToDelete.isEmpty()) {
            result = planesMensualesToDelete;
        } else if (planesAnualesToDelete != null && !planesAnualesToDelete.isEmpty()) {
            result = planesAnualesToDelete;
        } 

        return result;
    }

    /**
     * proceso que aglutina el proceso de actualizacion de planes mensuales de retencion, sinestralidad y demas planes mensuales. Se dispara desde el trigger de objetivos
     * @param scope: Lista de objetivos recibidos desde el trigger de objetivos
     * @author dmunoz
     * @date 23/02/2023
     */
    private void updatePlansByObjectives(List<SObject> scope) {

        // Identifico los cambios que han habido en los objetivos recibidos desde el trigger
        Map<String, Map<String, Objective__c>> objetivosMap = handlerObjetivos(scope, oldMap);
        // en funcion de que cambios se han realizado en los objetivos generamos una serie de modificaciones u otras
        planesCalculadosMap = PlanesComercialesMensualesUtil.updatePlanesMensualesFromObjective(objetivosMap);
        // insertar si hay los planes de retencion, siniestralidad
        planesCalculadosMap = insertAnualPlans(planesCalculadosMap);
        // obtener los planes mensuales de los planes recien insertados
        planesCalculadosMap = obtenerPlanesMensualesAdicionales(planesCalculadosMap, objetivosMap); // generar los planes mensuales de los planes anuales de siniestralidad y retencion, se añaden a la key PlanesMensualesToInsert del map

        doDMLs(planesCalculadosMap);
    }


    /**
     * proceso que aglutina el proceso de creación de planes mensuales que se dispara desde el trigger de plan comercial
     * @param scope: Lista de planes recibidos desde el trigger de plan comercial
     * @author dmunoz
     * @date 23/02/2023
     */
    private void updateMensualPlansByPlanComercial(List<SObject> scope) {

        // validar los registros que llegan para solo realizar las actualizaciones necesarias
        List<PlanComercial__c> validAnualPlansToUpdateList = getValidAnualPlansToUpdate(scope);

        // Obtener objetivos compatibles con los planes validados
        Map<String, Objective__c> objetivosMap = PlanesComercialesMensualesUtil.getObjetivosParametrica(validAnualPlansToUpdateList); // key externalId

        // obtener los planes mensuales de aquellos planes anuales validos
        List<PlanComercial__c> planesMensualesList =  (new PlanComercialSelector()).findMensualPlans(validAnualPlansToUpdateList);
        // recalcular kpis objetivos 
        planesCalculadosMap = recalcularKPI(planesMensualesList, objetivosMap);        

        doDMLs(planesCalculadosMap);
        
    }


    /**
     * Comprobamos si quedan elementos por procesar de forma que se hagan mas llamadas recursivas
     * @author dmunoz
     * @date 23/02/2023
     */
    @TestVisible
    private Boolean continueRecursive() {

        Boolean result = false; // devuelvo lista vacia cuando haya terminado de procesar todos los elementos anteriores
        List<PlanComercial__c> planesMensualesToInsert = planesCalculadosMap.get('PlanesMensualesToInsert');
        List<PlanComercial__c> planesMensualesToUpdate = planesCalculadosMap.get('PlanesMensualesToUpdate');
        List<PlanComercial__c> planesMensualesToDelete = planesCalculadosMap.get('PlanesMensualesToDelete');
        List<PlanComercial__c> planesAnualesToDelete = planesCalculadosMap.get('PlanesAnualesToDelete');

        if (isError) {
            return false;
        } else if (planesMensualesToInsert != null && !planesMensualesToInsert.isEmpty()) {
            result = true;
            numElemsBatch = planesMensualesToInsert.size();
        } else if (planesMensualesToUpdate != null && !planesMensualesToUpdate.isEmpty()) {
            result = true;
            numElemsBatch += planesMensualesToUpdate.size();
        } else if (planesMensualesToDelete != null && !planesMensualesToDelete.isEmpty()) {
            result = true;
            numElemsBatch += planesMensualesToDelete.size();
        } else if (planesAnualesToDelete != null && !planesAnualesToDelete.isEmpty()) {
            result = true;
            numElemsBatch += planesAnualesToDelete.size();
        } 

        return result;
    }


    /******************************************************* Métodos secundarios updatePlansByObjectives *****************************************************************************************/
    /**
     * Detectamos que modificacion se ha realizado para los objetivos y segun sea el escenario realizamos una acción u otra
     * @param scope: Elementos actualizados capturados en el trigger 
     * @author dmunoz
     * @date 21/07/2022
     */
    public Map<String, Map<String, Objective__c>> handlerObjetivos(List<Objective__c> scope, Map<Id, SObject> oldMap) {

        Map<String, Map<String, Objective__c>> result = new Map<String, Map<String, Objective__c>>();

        // compruebo si se ha modificado pesos y/o active
        Map<String, Objective__c> objetivosToUpdatePesos = new Map<String, Objective__c>(); // map externalId, Objetivo
        Map<String, Objective__c> objetivosToUpdateActiveMensual = new Map<String, Objective__c>(); // map externalId, Objetivo
        Map<String, Objective__c> objetivosToUpdateInactiveMensual = new Map<String, Objective__c>(); // map externalId, Objetivo
        Map<String, Objective__c> objetivosToUpdateActiveAnual = new Map<String, Objective__c>(); // map externalId, Objetivo
        Map<String, Objective__c> objetivosToUpdateInactiveAnual = new Map<String, Objective__c>(); // map externalId, Objetivo

        for (Objective__c obj: (List<Objective__c>) scope) {
            if (SDMValidatePlansAsyncBatchUtil.checkActive(obj, oldMap) && SDMValidatePlansAsyncBatchUtil.isRTObjective(obj)) { // valido primero el flag de activo, si se activa generaremos nuevos planes
                if (SDMValidatePlansAsyncBatchUtil.isAccidentOrRetentionObjective(obj)) {
                    objetivosToUpdateActiveAnual.put(obj.ExternalId__c, obj);
                } else {
                    objetivosToUpdateActiveMensual.put(obj.ExternalId__c, obj);
                }
            } else if (SDMValidatePlansAsyncBatchUtil.checkInactive(obj, oldMap)) { // si uno de los cambios del objetivo es inactivar, borraremos los planes mensuales
                if (SDMValidatePlansAsyncBatchUtil.isAccidentOrRetentionObjective(obj)) {
                    objetivosToUpdateInactiveAnual.put(obj.ExternalId__c, obj);
                } else {
                    objetivosToUpdateInactiveMensual.put(obj.ExternalId__c, obj);
                }
            } else if (checkPesos(obj, oldMap) && SDMValidatePlansAsyncBatchUtil.isObjectiveActive(obj)) { // actualizaremos los planes mensuales de los que se cambien pesos y el flag active sigue siendo true
                objetivosToUpdatePesos.put(obj.ExternalId__c, obj);
            }
        }
      
        result.put('ObjetivosToUpdatePesos', objetivosToUpdatePesos);
        result.put('ObjetivosToUpdateActiveMensual', objetivosToUpdateActiveMensual);
        result.put('ObjetivosToUpdateInactiveMensual', objetivosToUpdateInactiveMensual);
        result.put('ObjetivosToUpdateActiveAnual', objetivosToUpdateActiveAnual);
        result.put('ObjetivosToUpdateInactiveAnual', objetivosToUpdateInactiveAnual);

        return result;      
    }


    /**
     * Insertar los elementos anuales generados
     * @param planesCalculadosMap: Elementos calculados que contiene los planes de retencion siniestralidad 
     * @author dmunoz
     * @date 24/02/2023
     */
    private Map<String, List<PlanComercial__c>> insertAnualPlans(Map<String, List<PlanComercial__c>> planesCalculadosMap) {
        List<PlanComercial__c> anualPlansToInsert = planesCalculadosMap.get('PlanesAnualesToInsert');

        if (!anualPlansToInsert.isEmpty()) {
            insert anualPlansToInsert;

            planesCalculadosMap.put('PlanesAnualesToInsert', anualPlansToInsert); // reseteo los planes anuales del map con los ids
        }

        return planesCalculadosMap;
    }

    /**
     * Calculo de los planes mensuales de los planes de retencion y siniestralidad y se añade al map
     * @param planesCalculadosMap: Elementos calculados que contiene los planes de retencion siniestralidad 
     * @author dmunoz
     * @date 24/02/2023
     */
    private Map<String, List<PlanComercial__c>> obtenerPlanesMensualesAdicionales(Map<String, List<PlanComercial__c>> planesCalculadosMap, Map<String, Map<String, Objective__c>> mapObjetivos) {

        List<PlanComercial__c> anualPlans = planesCalculadosMap.get('PlanesAnualesToInsert');
        if (!anualPlans.isEmpty()) {
            Map<String, Objective__c> objetivosAnualesToActive = mapObjetivos.get('ObjetivosToUpdateActiveAnual');
            List<PlanComercial__c> mensualPlansGeneratedList = PlanesComercialesMensualesUtil.generatePlanesMensualesToInsert(anualPlans, objetivosAnualesToActive, null);

            // obtengo los planes mensuales ya calculados y le añado los nuevos planes calculados reseteando la key PlanesMensualesToInsert
            List<PlanComercial__c> calculatedMensualPlansList = planesCalculadosMap.get('PlanesMensualesToInsert');
            calculatedMensualPlansList.addAll(mensualPlansGeneratedList);
            planesCalculadosMap.put('PlanesMensualesToInsert', calculatedMensualPlansList);
        }

        return planesCalculadosMap;
    }

    /**
     * Realizaremos los DMLs de los registros que hemos calculado
     * @param planesCalculadosMap: Elementos calculados que contiene los planes mensuales y aquellos a eliminar
     * @author dmunoz
     * @date 24/02/2023
     */
    private void doDMLs(Map<String, List<PlanComercial__c>> planesCalculadosMap) {
        // primero hacemos las inserciones
        insertMensualPlans(planesCalculadosMap); // key PlanesMensualesToInsert

        // segundo hacemos los updates
        updateMensualPlans(planesCalculadosMap); // key PlanesMensualesToUpdate

        // para terminar se eliminan los registros identificados
        deleteMensualPlans(planesCalculadosMap); // key PlanesMensualesToDelete incluye planes mensuales de cualquier tipo de indicador
        deleteAnualPlans(planesCalculadosMap); // key PlanesAnualesToDelete
        
    }


    /******************************************************* Métodos secundarios updateMensualPlansByPlanComercial *****************************************************************************************/
    /**
     * Metodo para considerar solo los planes anuales que se han modificado
     * @param scope: Elementos que han llegado desde el trigger
     * @author dmunoz
     * @date 24/02/2023
     */
    private List<PlanComercial__c> getValidAnualPlansToUpdate(List<PlanComercial__c> scope) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();

        for (PlanComercial__c pc: scope) {
            if (SDMValidatePlansAsyncBatchUtil.isPlanAnual(pc) && SDMValidatePlansAsyncBatchUtil.checkPlanIndicator(pc) && targetKPIUpdated(pc, oldMap)) {
                result.add(pc);
            }
        }

        return result;
    }

    /**
     * Insert de los elementos calculados
     * @param planesCalculadosMap: Elementos calculados que contiene los planes de retencion siniestralidad 
     * @author dmunoz
     * @date 24/02/2023
     */
    private Map<String, List<PlanComercial__c>> recalcularKPI(List<PlanComercial__c> planesMensualesList, Map<String, Objective__c> objetivosMap) {
        Map<String, List<PlanComercial__c>> result = new Map<String, List<PlanComercial__c>>();

        List<PlanComercial__c> planesMensualesToUpdate = PlanesComercialesMensualesUtil.recalcularKPI(planesMensualesList, objetivosMap);
        // lo añado al map para reutilizar el método doDML
        result.put('PlanesMensualesToUpdate', planesMensualesToUpdate);

        return result;
    }



    /******************************************************* Métodos auxiliares *****************************************************************************************/

    /**
     * Insert de los elementos calculados
     * @param planesCalculadosMap: Elementos calculados que contiene los planes de retencion siniestralidad 
     * @author dmunoz
     * @date 24/02/2023
     */
    private void insertMensualPlans(Map<String, List<PlanComercial__c>> planesCalculadosMap) {
        List<PlanComercial__c> planesMensualesToInsert = planesCalculadosMap.get('PlanesMensualesToInsert');
        planesMensualesToInsert = insertMensualPlans(planesMensualesToInsert);

        // resetear map elimino los planes mensuales ya insertados
        planesCalculadosMap.put('PlanesMensualesToInsert', planesMensualesToInsert);
    }


    /**
     * Insert de los elementos calculados
     * @param planesCalculadosMap: Elementos calculados que contiene los planes de retencion siniestralidad 
     * @author dmunoz
     * @date 24/02/2023
     */
    private List<PlanComercial__c> insertMensualPlans(List<PlanComercial__c> planesMensualesToInsertList) {
        
        List<PlanComercial__c> planesRestantes = new List<PlanComercial__c>();
        if (planesMensualesToInsertList != null && !planesMensualesToInsertList.isEmpty()) { // si sigue habiendo elementos a insertar calculo
            
            if (planesMensualesToInsertList.size() < numRecordsDML) {
                numDML += planesMensualesToInsertList.size(); // actualizo el numero de elementos insertados, si es menor a 1000 lanzaremos los siguientes dmls (update y delete)
                insert planesMensualesToInsertList;

            } else {
                Integer index = 0;
                List<PlanComercial__c> insertList = new List<PlanComercial__c>();

                for (PlanComercial__c planMensual: planesMensualesToInsertList) {
                    if (index < numRecordsDML) {
                        insertList.add(planMensual);
                    } else {
                        planesRestantes.add(planMensual);
                    }
                    index++;
                }
                insert insertList;
            }
        }
        return planesRestantes;
    }


    /**
     * Insert de los elementos calculados
     * @param planesCalculadosMap: Elementos calculados que contiene los planes de retencion siniestralidad 
     * @author dmunoz
     * @date 24/02/2023
     */
    private void updateMensualPlans(Map<String, List<PlanComercial__c>> planesCalculadosMap) {
        List<PlanComercial__c> planesMensualesToUpdate = planesCalculadosMap.get('PlanesMensualesToUpdate');
        planesMensualesToUpdate = updateMensualPlans(planesMensualesToUpdate);

        // resetear map elimino los planes mensuales ya insertados
        planesCalculadosMap.put('PlanesMensualesToUpdate', planesMensualesToUpdate);
        
    }


    /**
     * Insert de los elementos calculados
     * @param planesCalculadosMap: Elementos calculados que contiene los planes de retencion siniestralidad 
     * @author dmunoz
     * @date 24/02/2023
     */
    private List<PlanComercial__c> updateMensualPlans(List<PlanComercial__c> planesMensualesToUpdateList) {
        
        List<PlanComercial__c> planesRestantes = new List<PlanComercial__c>();
        if (planesMensualesToUpdateList != null && !planesMensualesToUpdateList.isEmpty()) { // si sigue habiendo elementos a insertar calculo
            Integer dmlsRestantes = numRecordsDML - numDML;
            
            if (planesMensualesToUpdateList.size() < dmlsRestantes) {
                numDML += planesMensualesToUpdateList.size(); // actualizo el numero de elementos actualizados, si es menor a 1000 lanzaremos los siguientes dmls (delete)
                update planesMensualesToUpdateList;

            } else {
                Integer index = 0;
                List<PlanComercial__c> updateList = new List<PlanComercial__c>();

                for (PlanComercial__c planMensual: planesMensualesToUpdateList) {
                    if (index < dmlsRestantes) {
                        updateList.add(planMensual);
                    } else {
                        planesRestantes.add(planMensual);
                    }
                    index++;
                }                
                update updateList;
            }
        }
        return planesRestantes;
    }


    /**
     * Eliminar planes mensuales
     * @param planesCalculadosMap: Elementos calculados que contiene los planes de retencion siniestralidad 
     * @author dmunoz
     * @date 24/02/2023
     */
    private void deleteMensualPlans(Map<String, List<PlanComercial__c>> planesCalculadosMap) {
        List<PlanComercial__c> planesMensualesToDelete = planesCalculadosMap.get('PlanesMensualesToDelete');
        planesMensualesToDelete = deletePlans(planesMensualesToDelete);

        // resetear map elimino los planes mensuales ya insertados
        planesCalculadosMap.put('PlanesMensualesToDelete', planesMensualesToDelete);        
    }


    /**
     * Eliminar planes anuales de retencion y siniestralidad
     * @param planesCalculadosMap: Elementos calculados que contiene los planes de retencion siniestralidad 
     * @author dmunoz
     * @date 24/02/2023
     */
    private void deleteAnualPlans(Map<String, List<PlanComercial__c>> planesCalculadosMap) {
        List<PlanComercial__c> planesAnualesToDelete = planesCalculadosMap.get('PlanesAnualesToDelete');
        planesAnualesToDelete = deletePlans(planesAnualesToDelete);

        // resetear map elimino los planes mensuales ya insertados
        planesCalculadosMap.put('PlanesAnualesToDelete', planesAnualesToDelete);   
    }


    /**
     * Insert de los elementos calculados
     * @param planesCalculadosMap: Elementos calculados que contiene los planes de retencion siniestralidad 
     * @author dmunoz
     * @date 24/02/2023
     */
    private List<PlanComercial__c> deletePlans(List<PlanComercial__c> planesToDelete) {
        
        List<PlanComercial__c> planesRestantes = new List<PlanComercial__c>();
        if (planesToDelete != null && !planesToDelete.isEmpty()) { // si sigue habiendo elementos a insertar calculo
            Integer dmlsRestantes = numRecordsDML - numDML;
            
            if (planesToDelete.size() < dmlsRestantes) {
                numDML += planesToDelete.size(); // actualizo el numero de elementos actualizados, si es menor a 1000 lanzaremos los siguientes dmls (delete)
                delete planesToDelete;

            } else {
                Integer index = 0;
                List<PlanComercial__c> updateList = new List<PlanComercial__c>();

                for (PlanComercial__c planMensual: planesToDelete) {
                    if (index < dmlsRestantes) {
                        updateList.add(planMensual);
                    } else {
                        planesRestantes.add(planMensual);
                    }
                    index++;
                }                
                delete updateList;
            }
        }
        return planesRestantes;
    }


    /**
     * Comprobamos si un objetivo pasa de activo a inactivo
     * @param obj: Elementos actualizados capturados en el trigger 
     * @param oldMap: valores antiguos de los objetivos capturados en el trigger
     * @return boolean true si ha pasado de activo a inactivo
     * @author dmunoz
     * @date 21/07/2022
     */
    private Boolean checkPesos(Objective__c obj, Map<Id, SObject> oldMap) {
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
    
   
    /**
     * Validamos los planes para enviar al encolable solo los que se han modificado su target kpi
     * @param planComercial: Elementos capturados en el trigger 
     * @param oldMap: Planes comerciales anterior a actualizar capturados en el trigger 
     * @return Boolean
     * @author dmunoz
     * @date 21/07/2022
     */
    private static Boolean targetKPIUpdated(PlanComercial__c planComercial, Map<Id, SObject> oldMap) {
        Boolean result = false; 
        String kpiFieldNew = PlanesComercialesMensualesUtil.getKPIFieldName(planComercial);
        
        PlanComercial__c oldPC = (PlanComercial__c) oldMap.get(planComercial.Id); 
        String kpiFieldOld = PlanesComercialesMensualesUtil.getKPIFieldName(planComercial);
        String oldKPINumberString = String.valueOf(oldPC.get(kpiFieldOld));
        if (oldKPINumberString != null && String.isNotEmpty(oldKPINumberString)) {
            Decimal oldKPINumber = Decimal.valueOf(oldKPINumberString);

            if (planComercial.get(kpiFieldNew) != oldKPINumber) {
                result = true; 
            }
        }        

        return result;
    }
}