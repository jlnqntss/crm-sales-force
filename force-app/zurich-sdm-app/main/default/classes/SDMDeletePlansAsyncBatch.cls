/**
 * Proceso principal para eliminar planes de retención, siniestralidad y mensuales desde el trigger de plan comercial.
 * Se lanza desde el trigger after delete de objetivos y plan comercial
 * 
 * @author nts (dmunoz)
 * @date 23/02/2023
 *
 */
public with sharing class SDMDeletePlansAsyncBatch implements Database.Batchable<SObject>, Database.Stateful  {

    private static final Integer numRecordsDML = 1000;
    private static Integer numDML = 0;
    private static Integer numElemsBatch = 0;
    
    private Map<Id, SObject> oldMap; // elementos eliminados que llegan desde el trigger de objetivo
    private List<PlanComercial__c> planesMensualesList;
    private Map<String, List<PlanComercial__c>> planesCalculadosMap; // planes a eliminar, se usa en el recursivo , <Mensual/Anual, List<PlanComercial__c>
    private String action;
    private Boolean isError; // en caso de que se lance una excepción, informamos este flag para que no se lancen mas ejecuciones

    // constructor trigger objetivos
    public SDMDeletePlansAsyncBatch(Map<Id, SObject> oldMap, String action) {
        this.oldMap = oldMap;
        this.action = action;
        this.isError = false;
    }

    // constructor trigger plan comercial
    public SDMDeletePlansAsyncBatch(List<SObject> planesMensualesList, String action) {
        this.planesMensualesList = planesMensualesList;
        this.planesCalculadosMap = new Map<String, List<PlanComercial__c>>();
        this.action = action;
        this.isError = false;
    }

    // constructor trigger plan comercial
    public SDMDeletePlansAsyncBatch(Map<String, List<PlanComercial__c>> planesCalculadosMap) {
        this.planesCalculadosMap = planesCalculadosMap;
        this.action = 'DMLRecursivo';
        this.isError = false;
    }

    /**
     * recibe los elementos que el batch va a tratar
     * @param bc: elementos recibidos en el constructor
     * @return List<PlanComercial__c__c> elementos recibidos en el constructor
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
                    when 'DeleteFromObjectives' {
                        deletePlansByObjective(scope);
                    } when 'DeleteFromPlanComercial' {
                        deletePlansByPlanComercial(scope);
                    } when 'DMLRecursivo' { // llamada recursiva
                        doDMLs(planesCalculadosMap);
                    } when else {
                        throw new HandledException('Action no valido');
                    }
                }
            }

        } catch (Exception e) {
            isError = true;
            ErrorLogUtil.commitError(e, 'SDMDeletePlansAsyncBatch');
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
            Database.executeBatch(new SDMDeletePlansAsyncBatch(planesCalculadosMap), numElemsBatch); // batch de planes mensuales
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
            when 'DeleteFromObjectives' {
                return oldMap.values();
            }
            when 'DeleteFromPlanComercial' {
                return planesMensualesList;
            }
            when 'DMLRecursivo' {
               return getRecursiveStartList();
            }
            when else {
                throw new HandledException('Action no permitido en Start ' + action);
            }
        }
    }


    /**
     * Devuelve una lista de planes en orden de dml que utilizaremos en los batch recursivos, no utilizaremos estas listas solo sirve para entrar en el metodo execute y ahí usamos el mapa calculado en la primera iteracion
     * @author dmunoz
     * @date 23/02/2023
     */
    private List<PlanComercial__c> getRecursiveStartList() {

        List<PlanComercial__c> result = new List<PlanComercial__c>(); // devuelvo lista vacia cuando haya terminado de procesar todos los elementos anteriores
        List<PlanComercial__c> planesMensualesToDelete = planesCalculadosMap.get('Mensual');
        List<PlanComercial__c> planesAnualesToDelete = planesCalculadosMap.get('Anual');

        if (planesMensualesToDelete != null && !planesMensualesToDelete.isEmpty()) {
            result = planesMensualesToDelete;
        } else if (planesAnualesToDelete != null && !planesAnualesToDelete.isEmpty()) {
            result = planesAnualesToDelete;
        } 

        return result;
    }


    /**
     * Metodo principal de borrado de planes desde el trigger de objetivos
     * @param scope lista de objetivos eliminados recibidos desde el trigger
     * @author dmunoz
     * @date 23/02/2023
     */
    private void deletePlansByObjective(List<SObject> scope) {

        // recorro los objetivos recibidos para descartar en caso que el record type no sea el de objetivo
        Map<String, Map<String, Objective__c>> objectivesToDeleteMap = getObjectivesToDelete(scope); // <Anual/Mensual <externalId, obj>>

        // query planes mensuales compatibles con los objetivos recibidos
        planesCalculadosMap = getAllPlansToDelete(objectivesToDeleteMap);

        // eliminar planes mensuales y para finalizar los planes anuales
        doDMLs(planesCalculadosMap);
    }

    /**
     * Comprueba que el flag active del objetivo está a true
     * @param obj: objetivo a consultar
     * @author dmunoz
     * @date 23/02/2023
     */
    private void deletePlansByPlanComercial(List<PlanComercial__c> scope) {

        // Añado los planes mensuales de la entrada en map para reutilizar el metodo doDML
        planesCalculadosMap.put('Mensual', scope);

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
        List<PlanComercial__c> planesAnualesToDelete = planesCalculadosMap.get('Anual');
        List<PlanComercial__c> planesMensualesToDelete = planesCalculadosMap.get('Mensual');
        
        if (isError) {
            return false;
        } else if (planesMensualesToDelete != null && !planesMensualesToDelete.isEmpty()) {
            result = true;
            numElemsBatch = planesMensualesToDelete.size();
        } else if (planesAnualesToDelete != null && !planesAnualesToDelete.isEmpty()) {
            result = true;
            numElemsBatch += planesAnualesToDelete.size();
        } 

        return result;
    }


    /******************************************************* Métodos deletePlansByObjective *****************************************************************************************/

    /**
     * Filtrar objetivos llegados desde el trigger para eliminar aquellos que no estan activos del proceso ni los que no tengan recordtype objetivos
     * @param scope lista de objetivos eliminados recibidos desde el trigger
     * @author dmunoz
     * @date 23/02/2023
     */
    private Map<String, Map<String, Objective__c>> getObjectivesToDelete(List<SObject> scope) {

        Map<String, Map<String, Objective__c>> result = new Map<String, Map<String, Objective__c>>();
        Map<String, Objective__c> anualObjectives = new Map<String, Objective__c>();
        Map<String, Objective__c> mensualObjectives = new Map<String, Objective__c>();

        for (Objective__c obj: (List<Objective__c>) scope) {
            if (SDMValidatePlansAsyncBatchUtil.isObjectiveActive(obj) && SDMValidatePlansAsyncBatchUtil.isRTObjective(obj)) {
                if (SDMValidatePlansAsyncBatchUtil.isAccidentOrRetentionObjective(obj)) { // si el objetivo es de tipo retención, siniestralidad
                    anualObjectives.put(obj.externalId__c, obj);
                } else { // si es de indicador PN, Cartera o APES
                    mensualObjectives.put(obj.externalId__c, obj);
                }
            }
        }

        result.put('Anual', anualObjectives);
        result.put('Mensual', mensualObjectives);

        return result;
    }


    /**
     * Obtener de la base de datos todos los planes mensuales compatibles con los objetivos que han pasado la validacion
     * @param objectivesToDeleteMap mapa de objetivos validos para buscar planes mensuales
     * @author dmunoz
     * @date 23/02/2023
     */
    private Map<String, List<PlanComercial__c>> getAllPlansToDelete(Map<String, Map<String, Objective__c>> objectivesToDeleteMap) {        
        Map<String, List<PlanComercial__c>> result = new Map<String, List<PlanComercial__c>>();

        // obtener planes mensuales compatibles
        List<PlanComercial__c> mensualPlansToDelete = getMensualPlansToDelte(objectivesToDeleteMap);
        
        // query planes anuales retencion y siniestralidad a borrar
        List<PlanComercial__c> anualPlansToDelete = PlanesComercialesMensualesUtil.getPlanesComercialesAnualesMensualesByObjetivos(objectivesToDeleteMap.get('Anual'), 'Anual');

        result.put('Anual', anualPlansToDelete);
        result.put('Mensual', mensualPlansToDelete);

        return result;
    }


    /**
     * Obtener de la base de datos todos los planes mensuales compatibles con los objetivos que han pasado la validacion
     * @param objectivesToDeleteMap mapa de objetivos validos para buscar planes mensuales
     * @author dmunoz
     * @date 23/02/2023
     */
    private List<PlanComercial__c> getMensualPlansToDelte(Map<String, Map<String, Objective__c>> objectivesToDeleteMap) {

        List<PlanComercial__c> result = new List<PlanComercial__c>();
        Map<String, Objective__c> objectivesToQueryMap = new Map<String, Objective__c>();
        
        // en primer lugar unimos todos los objetivos validados en un mismo mapa
        objectivesToQueryMap.putAll(objectivesToDeleteMap.get('Anual'));
        objectivesToQueryMap.putAll(objectivesToDeleteMap.get('Mensual'));

        result = PlanesComercialesMensualesUtil.getPlanesComercialesAnualesMensualesByObjetivos(objectivesToQueryMap, 'Mensual');

        return result;
    }

    /**
     * Realizaremos los DMLs de los registros que hemos calculado
     * @param planesCalculadosMap: Elementos calculados que contiene los planes mensuales y aquellos a eliminar
     * @author dmunoz
     * @date 24/02/2023
     */
    private void doDMLs(Map<String, List<PlanComercial__c>> planesCalculadosMap) {
        deleteMensualPlans(planesCalculadosMap); // key PlanesMensualesToDelete incluye planes mensuales de cualquier tipo de indicador
        deleteAnualPlans(planesCalculadosMap); // key PlanesAnualesToDelete        
    }


    /**
     * Eliminar planes mensuales
     * @param planesCalculadosMap: Elementos calculados que contiene los planes de retencion siniestralidad 
     * @author dmunoz
     * @date 24/02/2023
     */
    private void deleteMensualPlans(Map<String, List<PlanComercial__c>> planesCalculadosMap) {
        List<PlanComercial__c> planesMensualesToDelete = planesCalculadosMap.get('Mensual');
        planesMensualesToDelete = deletePlans(planesMensualesToDelete);

        // resetear map elimino los planes mensuales ya insertados
        planesCalculadosMap.put('Mensual', planesMensualesToDelete);        
    }


    /**
     * Eliminar planes anuales de retencion y siniestralidad
     * @param planesCalculadosMap: contiene los planes anuales de retencion y siniestralidad 
     * @author dmunoz
     * @date 24/02/2023
     */
    private void deleteAnualPlans(Map<String, List<PlanComercial__c>> planesCalculadosMap) {
        List<PlanComercial__c> planesAnualesToDelete = planesCalculadosMap.get('Anual');
        planesAnualesToDelete = deletePlans(planesAnualesToDelete);

        // resetear map elimino los planes mensuales ya insertados
        planesCalculadosMap.put('Anual', planesAnualesToDelete);   
    }


    /**
     * Insert de los elementos calculados
     * @param planesToDelete: planes a borrar
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


    /******************************************************* Métodos deletePlansByPlanComercial *****************************************************************************************/

    


    /******************************************************* Métodos auxiliares *****************************************************************************************/

    
}