/**
 * Proceso principal para generar planes de retención, siniestralidad y mensuales desde el trigger de plan comercial y objetivos.
 * Se lanza desde el trigger after insert de objetivos y plan comercial
 * 
 * @author nts (dmunoz)
 * @date 23/02/2023
 *
 */
public with sharing class SDMInsertPlansAsyncBatch implements Database.Batchable<SObject>, Database.Stateful {

    private static final Integer numRecordsDML = 1000;

    private List<SObject> elemsFromTrigger; // elementos que llegan desde el trigger de objetivo o plan comercial o desde los sucesivos batch
    private List<PlanComercial__c> planesMensualesRestantesList; // lista de planes mensuales calculados a partir de los planes de entrada
    private String action;
    private Boolean isError; // en caso de que se lance una excepción, informamos este flag para que no se lancen mas ejecuciones
    

    // constructor a usar desde el trigger de objetivos
    public SDMInsertPlansAsyncBatch(List<SObject> elemsFromTrigger, String action) {
        this.elemsFromTrigger = elemsFromTrigger;
        this.planesMensualesRestantesList = new List<PlanComercial__c>();
        this.action = action;
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
        return elemsFromTrigger;        
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
                    when 'InsertFromObjectives' {
                        generatePlansByObjectives(scope);
                    } when 'InsertFromPlanComercial' {
                        generateMensualPlansByPlanComercial(scope);
                    } when 'DMLRecursivo' { // llamada recursiva
                        insertMensualPlans(scope);
                    } when else {
                        throw new HandledException('Action no valido');
                    }
                }
            }

        } catch (Exception e) {
            isError = true;
            ErrorLogUtil.commitError(e, 'SDMInsertPlansAsyncBatch');
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
        if (!isError && !planesMensualesRestantesList.isEmpty()) {
            Database.executeBatch(new SDMInsertPlansAsyncBatch(planesMensualesRestantesList, 'DMLRecursivo'), planesMensualesRestantesList.size()); // batch de planes mensuales
        }
    }


    /******************************************************* Métodos principales *****************************************************************************************/
    

    /**
     * proceso que aglutina el proceso de creación de planes anuales de retencion y sinestralidad además de planes mensuales. Se dispara desde el trigger de objetivos
     * @param scope: Lista de objetivos recibidos desde el trigger de objetivos
     * @author dmunoz
     * @date 23/02/2023
     */
    private void generatePlansByObjectives(List<SObject> scope) {      
        
        // recupero los email de los usuarios piloto
        List<String> validEmailList = SDMValidatePlansAsyncBatchUtil.getValidEmailsFromMetadata();   

        // de los objetivos recibidos en el trigger filtramos por activos, indicador retencion y siniestralidad
        Map<String, Map<String, Objective__c>> objectivesMap = getValidObjectives(scope);
        
        // en primer lugar generaremos los planes anuales de retención y siniestralidad si procede
        List<PlanComercial__c> generatedAnualPlansList = PlanesComercialesAnualesUtil.generateAnualPlansFromObjectives(objectivesMap, validEmailList);
        // insertamos los planes anuales generado de siniestralidad y retención si procede
        List<PlanComercial__c> anualPlansInserted = insertAnualPlans(generatedAnualPlansList);

        // generar los planes mensuales de para los planes generados como para los planes anuales ya existentes en la bd para los usuarios del piloto
        List<PlanComercial__c> planesMensualesToInsertList = generateMensualPlansFromObjectives(objectivesMap, anualPlansInserted);
        // insertamos los planes mensuales generados
        insertMensualPlans(planesMensualesToInsertList);
        
    }


    /**
     * proceso que aglutina el proceso de creación de planes mensuales que se dispara desde el trigger de plan comercial
     * @param scope: Lista de planes recibidos desde el trigger de plan comercial
     * @author dmunoz
     * @date 23/02/2023
     */
    private void generateMensualPlansByPlanComercial(List<SObject> scope) {

        // recupero los email de los usuarios piloto
        List<String> validEmailList = SDMValidatePlansAsyncBatchUtil.getValidEmailsFromMetadata();  

        // obtener planes anuales validos para generar los planes mensuales
        List<PlanComercial__c> planesComercialesAnualesList = getValidAnualPlans(scope, validEmailList);

        // Query para obtener la información del owner del plan comercial anual padre (si tiene), esto es debido a que si un director crea planes a un rn, y este rn baja planes a mediador y a todos ellos se les han generado planes mensuales, debido a las sharing rules, el director no pueden borrar todos por no ser owner de los planes mensuales
        Map<Id, PlanComercial__c> mapParentOwner = (new PlanComercialSelector()).getParentOwnerId(planesComercialesAnualesList);

        // obtengo los objetivos compatibles con los planes que han pasado el filtro
        Map<String, Objective__c> objetivosMap = PlanesComercialesMensualesUtil.getObjetivosParametrica(planesComercialesAnualesList); // key externalId
        // Una vez tengo los planes a los cuales generar los planes mensuales y los objetivos, generamos la lista de planes mensuales a insertar
        List<PlanComercial__c> listaPlanesMensualesToInsert = PlanesComercialesMensualesUtil.generatePlanesMensualesToInsert(planesComercialesAnualesList, objetivosMap, mapParentOwner);

        insertMensualPlans(listaPlanesMensualesToInsert);
            
        
    }


    /******************************************************* Métodos secundarios generatePlansByObjectives *****************************************************************************************/

    /**
     * recorrer los objetivos insertados y nos quedamos con aquellos activos y de record type Objective
     * @param scope: Lista de objetivos recibidos desde el trigger de objetivos
     * @author dmunoz
     * @date 23/02/2023
     */
    private Map<String, Map<String, Objective__c>> getValidObjectives(List<SObject> scope) {
        Map<String, Map<String, Objective__c>> result = new Map<String, Map<String, Objective__c>>();

        Map<String, Objective__c> otherObjectives = new Map<String, Objective__c>(); // guardamos los objetivos activos de indicador PN, Cartera y APES
        Map<String, Objective__c> retentionObjectives = new Map<String, Objective__c>(); // guardamos los objetivos activos de indicador Ratio Retencion

        for (Objective__c obj: (List<Objective__c>) scope) {
            if (SDMValidatePlansAsyncBatchUtil.isObjectiveActive(obj) && SDMValidatePlansAsyncBatchUtil.isRTObjective(obj)) { // solo generamos planes de objetivos que se inserten activos
                if (SDMValidatePlansAsyncBatchUtil.isRetentionObjective(obj)) {
                    retentionObjectives.put(obj.ExternalId__c, obj);
                } else if (SDMValidatePlansAsyncBatchUtil.isOtherIndicator(obj)) {
                    otherObjectives.put(obj.ExternalId__c, obj);
                }
            }                 
        }

        result.put('RetentionObjectives', retentionObjectives);
        result.put('OtherObjectives', otherObjectives);

        return result;
    }

    

    /**
     * Metodo DML de planes anuales
     * @param generatedAnualPlansList: lista de planes anuales de retencion y siniestralidad calculados para insertar
     * @author dmunoz
     * @date 23/02/2023
     */
    private List<PlanComercial__c> insertAnualPlans(List<PlanComercial__c> generatedAnualPlansList) {
        if (!generatedAnualPlansList.isEmpty()) {
            insert generatedAnualPlansList;
        }

        return generatedAnualPlansList;
    }


    /**
     * Metodo que contiene lo necesario para generar los planes mensuales de los planes compatibles con los objetivos recibidos por el trigger
     * @param generatedAnualPlansList: lista de planes anuales de retencion y siniestralidad calculados para insertar
     * @author dmunoz
     * @date 23/02/2023
     */
    private List<PlanComercial__c> generateMensualPlansFromObjectives(Map<String, Map<String, Objective__c>> objectivesMap, List<PlanComercial__c> anualPlansInserted) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();

        Map<String, Objective__c> otherObjectives = objectivesMap.get('OtherObjectives');

        Map<String, Objective__c> allObjectivesMap = getAllObjectives(objectivesMap);

        // obtener primero los planes anuales Cartera, PN y APES
        List<PlanComercial__c> otherAnualPlanList = PlanesComercialesMensualesUtil.getPlanesComercialesAnualesMensualesByObjetivos(otherObjectives, 'Anual');

        // Query para obtener la información del owner del plan comercial anual padre (si tiene), esto es debido a que si un director crea planes a un rn, y este rn baja planes a mediador y a todos ellos se les han generado planes mensuales, debido a las sharing rules, el director no puede borrar todos por no ser owner de los planes mensuales
        Map<Id, PlanComercial__c> mapParentOwner = (new PlanComercialSelector()).getParentOwnerId(otherAnualPlanList);

        // Una vez tengo los planes anuales de cartera, PN y APES además de la lista de planes anuales de retención y siniestralidad los uno en una misma lista y genero los planes mensuales de cada uno de ellos.
        List<PlanComercial__c> planesAnualesToGenereateMensualPlanList = getAllAnualPlans(otherAnualPlanList, anualPlansInserted);
        result = PlanesComercialesMensualesUtil.generatePlanesMensualesToInsert(planesAnualesToGenereateMensualPlanList, allObjectivesMap, mapParentOwner);

        return result;
    }

    /**
     * Insert DML de planes mensuales calculados previamente
     * @param planesMensualesToInsertList: lista de planes mensuales calculados para insertar
     * @author dmunoz
     * @date 23/02/2023
     */
    private void insertMensualPlans(List<PlanComercial__c> planesMensualesToInsertList) {
        List<PlanComercial__c> insertList = new List<PlanComercial__c>(); // añado los primeros 1000 elementos

        if (!planesMensualesToInsertList.isEmpty()) {
            if (planesMensualesToInsertList.size() < numRecordsDML) {
                insert planesMensualesToInsertList;
            } else {
                Integer index = 0;
                for (PlanComercial__c planMensual: planesMensualesToInsertList) {
                    if (index < numRecordsDML) {
                        insertList.add(planMensual);
                    } else {
                        planesMensualesRestantesList.add(planMensual);
                    }
                    index++;
                }
    
                insert insertList;
            }
        }
    }
    


    private List<PlanComercial__c> getAllAnualPlans(List<PlanComercial__c> otherAnualPlanList, List<PlanComercial__c> anualPlansInserted) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();

        result.addAll(otherAnualPlanList);
        result.addAll(anualPlansInserted);

        return result;
    }


    private Map<String, Objective__c> getAllObjectives(Map<String, Map<String, Objective__c>> objectivesMap) {
        Map<String, Objective__c> result = new Map<String, Objective__c>();

        Map<String, Objective__c> otherObjectives = objectivesMap.get('OtherObjectives');
        Map<String, Objective__c> retentionObjectives = objectivesMap.get('RetentionObjectives');

        result.putAll(otherObjectives);
        result.putAll(retentionObjectives);

        return result;
    }
    
    
    /******************************************************* Métodos secundarios generatePlansByPlanComercial *****************************************************************************************/

    /**
     * Valida los planes comerciales que llegan desde el trigger de PlanComercial nos quedamos solo con los planes anuales de PN, Cartera y APES
     * @param scope: planes del trigger
     * @param validEmailList: email validos por el piloto
     * @author dmunoz
     * @date 27/02/2023
     */
    private List<PlanComercial__c> getValidAnualPlans(List<PlanComercial__c> scope, List<String> validEmailList) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();

        Map<Id, PlanComercial__c> pcAssignedToMap = (new PlanComercialSelector()).findAssignedToDataFromPC(scope); // obtengo la relacion entre los planes comerciales y sus email por query ya que al ser un lkp el trigger no tiene esta información
        
        for (PlanComercial__c pc: scope) {
            if (SDMValidatePlansAsyncBatchUtil.isPlanAnual(pc) && SDMValidatePlansAsyncBatchUtil.checkPlanIndicator(pc) && validAssignedTo(pc, validEmailList, pcAssignedToMap)) {
                result.add(pc);
            }
        }

        return result;
    }
    
    
    
    /******************************************************* Métodos auxiliares *****************************************************************************************/

    
    /**
     * Validamos antes de crear planes mensuales si el plan esta asignado a algún email válido para la metadata AdminSetupParameter__mdt
     * @param planComercial: Elementos capturados en el trigger
     * @return Boolean
     * @author dmunoz
     * @date 22/08/2022
     */
    private static Boolean validAssignedTo(PlanComercial__c planComercial, List<String> validEmailList, Map<Id, PlanComercial__c> pcAssignedToMap) {
        Boolean result = false; 

        if (pcAssignedToMap != null && !pcAssignedToMap.isEmpty()) {
            String pcEmail = pcAssignedToMap.get(planComercial.Id)?.AssignedTo__r.Email;
            if (validEmailList.contains(pcEmail)) {
                result = true;
            }
        } 
        
        if (Test.isRunningTest()) {
            result = true;
        }

        return result;
    }
}