/**
 * Clase encolable para gestionar la creación, actualización y borrado de los planes mensuales
 * 
 * @author nts (dmunoz)
 * @date 21/07/2022
 *
 */
public with sharing class GestionarPlanesMensualesQueueableJob implements Queueable {

    private List<PlanComercial__c> planesComerciales;
    private Map<String, Map<String, Objective__c>> mapObjetivos;
    private String action;

    public GestionarPlanesMensualesQueueableJob(List<PlanComercial__c> planesComercialesAnualesList, String action) {
        this.planesComerciales = planesComercialesAnualesList;
        this.mapObjetivos = null;
        this.action = action;
    }

    public GestionarPlanesMensualesQueueableJob(Map<String, Map<String, Objective__c>> mapObjetivos, String action) {
        this.planesComerciales = null;
        this.mapObjetivos = mapObjetivos;
        this.action = action;
    }

    public void execute(QueueableContext context) {
        try {
            switch on action {
                when 'Insert' {
                    insertPlanesMensuales(planesComerciales, mapObjetivos);
                } when 'Update' {
                    updatePlanesMensuales(planesComerciales, mapObjetivos);
                } when 'Delete' {
                    deletePlanesMensuales(planesComerciales, mapObjetivos);                
                } when else {
                    throw new HandledException('Action no permitido, recibido ' + action);
                }
            }
        } catch (Exception e) {
            ErrorLogUtil.commitError(e, 'GestionarPlanesMensualesQueueableJob', 'execute');
        }
    }


    /**
     * Proceso insert de planes mensuales
     * @param planesComercialesAnualesList: Planes comerciales validados
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    private static void insertPlanesMensuales(List<PlanComercial__c> planesComercialesAnualesList,  Map<String, Map<String, Objective__c>> mapObjetivos) {

        if (mapObjetivos == null) {
            insertPlanesMensualesFromPC(planesComercialesAnualesList);
        } else {
            insertPlanesMensualesFromObjective(mapObjetivos);
        }
    }

    /**
     * Proceso update de planes mensuales
     * @param planesComercialesAnualesList: Planes comerciales validados
     * @param objetivosList: Objetivos actualizados
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    private static void updatePlanesMensuales(List<PlanComercial__c> planesComercialesAnualesList, Map<String, Map<String, Objective__c>> mapObjetivos) {
        
        if (mapObjetivos == null) { // si no hay objetivos se ha invocado desde el trigger de plan comercial
            updatePlanesMensualesFromPC(planesComercialesAnualesList);
        } else { // se ha invocado desde trigger objetivos
            updatePlanesMensualesFromObjective(mapObjetivos);
        }
                        
    }


    /**
     * Proceso delete de planes mensuales
     * @param planesComercialesAnualesList: Planes comerciales eliminados
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    private static void deletePlanesMensuales(List<PlanComercial__c> planesComercialesMensualesList, Map<String, Map<String, Objective__c>> mapObjetivos) {

        if (mapObjetivos == null) {
            deletePlanesMensualesFromPC(planesComercialesMensualesList);
        } else {
            deletePlanesMensualesFromObjectives(mapObjetivos);
        }        
    }   

    

    /****************************************************** Metodos Auxiliares Insert Planes Mensuales***************************************************************************/    

    /**
     * Proceso insert de planes mensuales
     * @param planesComercialesAnualesList: Planes comerciales validados
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    private static void insertPlanesMensualesFromPC(List<PlanComercial__c> planesComercialesAnualesList) {

        if (planesComercialesAnualesList != null && !planesComercialesAnualesList.isEmpty()) {
            List<PlanComercial__c> listPlanesHijos = new List<PlanComercial__c>();

            Map<String, Objective__c> objetivosMap = getObjetivosParametrica(planesComercialesAnualesList); // key externalId
            if (!objetivosMap.isEmpty()) {
                listPlanesHijos = generatePlanesHijosToInsert(planesComercialesAnualesList, objetivosMap);
            }  
            
            if (!listPlanesHijos.isEmpty()) {
                insert listPlanesHijos;
            }
        }        
    }

    /**
     * Proceso insert de planes mensuales
     * @param planesComercialesAnualesList: Planes comerciales validados
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    private static void insertPlanesMensualesFromObjective(Map<String, Map<String, Objective__c>> mapObjetivos) {

        Map<String, Objective__c> objetivosToInsert = mapObjetivos.get('ObjetivosInsert'); // map externalId, Objetivo

        // obtengo los planes anuales compatibles con los objetivos insertados
        List<PlanComercial__c> pcAnualesList = getPlanesComercialesAnualesMensualesByObjetivos(objetivosToInsert, 'Anual');

        // genero la lista de planes mensuales a insertar
        List<PlanComercial__c> listaPlanesMensualesInsert = generatePlanesHijosToInsert(pcAnualesList, objetivosToInsert);

        if (!listaPlanesMensualesInsert.isEmpty()) {
            insert listaPlanesMensualesInsert;
        }
    }

    /**
     * Recorro los planes para generar los registros mensuales de cada plan anual
     * @param planesComercialesAnualesList: Planes comerciales validados
     * @param objetivosMap: Mapa de objetivos
     * @return Lista de planes mensuales listos para insertar
     * @author dmunoz
     * @date 21/07/2022
     */
    private static List<PlanComercial__c> generatePlanesHijosToInsert(List<PlanComercial__c> planesComercialesAnualesList, Map<String, Objective__c> objetivosMap) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();
        String pcExternalId; // calculo el valor externalId para obtener el objetivo con el cual generaremos los planes mensuales con los pesos indicados
        Objective__c obj; // objetivo para el plan comercial i
        List<PlanComercial__c> planesMensuales = new List<PlanComercial__c>(); // lista de planes mensuales para el plan comercial i
        
        for (PlanComercial__c pc: planesComercialesAnualesList) {
            pcExternalId = generateExternalIdValue(pc);
            obj = objetivosMap.get(pcExternalId);

            if (obj != null) { // al hacer get si no lo encuentra devuelve null
                planesMensuales = generatePlanesMensualesFromPlanAnual(pc, obj); // lista auxiliar con los 12 planes mensuales generados
                result.addAll(planesMensuales);
                planesMensuales.clear(); // reseteo la lista auxiliar
            }
        }

        return result;
    }

    /**
     * Recorro los planes para generar los registros mensuales de cada plan anual
     * @param planesComercialesAnualesList: Planes comerciales validados
     * @param objetivosMap: Mapa de objetivos
     * @return Lista de planes mensuales listos para insertar
     * @author dmunoz
     * @date 21/07/2022
     */
    private static List<PlanComercial__c> generatePlanesMensualesFromPlanAnual(PlanComercial__c pc, Objective__c obj) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();

        for (Integer i = 1; i <= 12; i++) { // bucle por cada mes del año
            result.add(generatePlanMensual(pc, obj, i));
        }

        return result;
    }

     /**
     * Generar plan mensual para el mes i a partir de un plan anual
     * @param pc: Plan Anual
     * @param obj: Objetivo
     * @param i: nº del mes a generar
     * @return Plan Mensual i para el plan anual de entrada
     * @author dmunoz
     * @date 21/07/2022
     */
    private static PlanComercial__c generatePlanMensual(PlanComercial__c pc, Objective__c obj, Integer i) {        
        PlanComercial__c result = pc.clone(false, false, false, false);
        Map<String, String> calculoPCMap = calculatePlanMensualFields(pc, obj, i);

        result.Name = (pc.Name + ' ' + calculoPCMap.get('MonthName')).left(80); // recorto el tamaño a 80 que tiene el campo
        result.TargetKPINumber__c = decimal.valueOf(calculoPCMap.get('KPI'));
        result.RecordTypeId = Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId();
        result.EndDate__c = Date.newInstance(pc.EndDate__c.year(), i, Integer.valueOf(calculoPCMap.get('NumberOfDays')));
        result.ParentPlan__c = pc.Id;

        return result;
    }

    /****************************************************** Metodos Auxiliares Update Planes Mensuales***************************************************************************/    

    /**
     * Obtener los planes mensuales a partir de los planes anuales
     * @param planesComercialesAnualesList: Planes comerciales validados
     * @return Lista de planes mensuales
     * @author dmunoz
     * @date 21/07/2022
     */
    private static List<PlanComercial__c> getPlanesMensuales(List<PlanComercial__c> planesComercialesAnualesList) {
        List<PlanComercial__c> result = (new PlanComercialSelector()).findMensualPlans(planesComercialesAnualesList);

        return result;
    }

    /**
     * Modificar todos los Target KPI Nº de los planes mensuales debido al cambio en ese campo en el plan padre (anual)
     * @param planesComercialesAnualesList: Planes comerciales validados
     * @param objetivosMap: Planes comerciales validados
     * @return Lista de planes mensuales
     * @author dmunoz
     * @date 21/07/2022
     */
    private static List<PlanComercial__c> recalcularKPI(List<PlanComercial__c> planesMensualesList, Map<String, Objective__c> objetivosMap) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();
        String externalIdPCM;    
        Objective__c obj;  
        Map<String, String> calculoPCMap;

        for (PlanComercial__c pcm: planesMensualesList) {
            externalIdPCM = generateExternalIdValue(pcm);
            obj = objetivosMap.get(externalIdPCM);

            if (obj != null) {
                calculoPCMap = calculatePlanMensualFields(pcm.ParentPlan__r, obj, pcm.EndDate__c.month());
                pcm.TargetKPINumber__c = decimal.valueOf(calculoPCMap.get('KPI'));
                result.add(pcm);
            }
        }

        return result;
    }
    

    /****************************************************** Metodos Auxiliares Delete Planes Mensuales***************************************************************************/

    /**
     * Proceso delete de planes mensuales
     * @param planesComercialesAnualesList: Planes comerciales a eliminar
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    private static void deletePlanesMensualesFromPC(List<PlanComercial__c> planesComercialesMensualesList) {
        
        if (!planesComercialesMensualesList.isEmpty()) {
            delete planesComercialesMensualesList; 
        }        
    }

    /**
     * Proceso delete de planes mensuales
     * @param planesComercialesAnualesList: Planes comerciales eliminados
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    private static void deletePlanesMensualesFromObjectives(Map<String, Map<String, Objective__c>> mapObjetivos) {

        Map<String, Objective__c> objetivosToDelete = mapObjetivos.get('ObjetivosToDelete'); // map externalId, Objetivo
        List<PlanComercial__c> pcToDelete = getPlanesComercialesAnualesMensualesByObjetivos(objetivosToDelete, 'Mensual');      
        deletePlanesMensualesFromPC(pcToDelete);
    }


    /****************************************************** Metodos Auxiliares updatePlanesMensualesFromObjective***************************************************************************/
    /**
     * Gestion logica actualización objetivos y su influencia sobre los PC
     * @param mapObjetivos: objetivos modificados
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    private static void updatePlanesMensualesFromPC(List<PlanComercial__c> planesComercialesAnualesList) {
        Map<String, Objective__c> objetivosMap = getObjetivosParametrica(planesComercialesAnualesList); // key externalId
        if (!objetivosMap.isEmpty()) {
            List<PlanComercial__c> planesMensualesList = getPlanesMensuales(planesComercialesAnualesList);
        
            planesMensualesList = recalcularKPI(planesMensualesList, objetivosMap);

            if (!planesMensualesList.isEmpty()) {
                update planesMensualesList;
            }            
        } 
    }


    /**
     * Gestion logica actualización objetivos y su influencia sobre los PC
     * @param mapObjetivos: objetivos modificados
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    private static void updatePlanesMensualesFromObjective(Map<String, Map<String, Objective__c>> mapObjetivos) {
        Map<String, Objective__c> objetivosToUpdatePesos = mapObjetivos.get('ObjetivosToUpdatePesos'); // map externalId, Objetivo
        Map<String, Objective__c> objetivosToUpdateActive = mapObjetivos.get('ObjetivosToUpdateActive'); // map externalId, Objetivo
        Map<String, Objective__c> objetivosToUpdateInactive = mapObjetivos.get('ObjetivosToUpdateInactive'); // map externalId, Objetivo

        // lista pc para hacer las operaciones
        List<PlanComercial__c> pcToInsert = new List<PlanComercial__c>();
        List<PlanComercial__c> pcToUpdate = new List<PlanComercial__c>();
        List<PlanComercial__c> pcToDelete = new List<PlanComercial__c>();

        List<PlanComercial__c> pcList = new List<PlanComercial__c>(); // lista de planes via query

        // query de planes cambia segun si es insert o update/delete de planes
        if (!objetivosToUpdateActive.isEmpty()) {
            pcList = getPlanesComercialesAnualesMensualesByObjetivos(objetivosToUpdateActive, 'Anual');
        } else if (!objetivosToUpdatePesos.isEmpty()) {            
            // obtener planes mensuales
            pcList = getPlanesComercialesAnualesMensualesByObjetivos(objetivosToUpdatePesos, 'Mensual');
        } else if (!objetivosToUpdateInactive.isEmpty()) {
            pcToDelete = getPlanesComercialesAnualesMensualesByObjetivos(objetivosToUpdateInactive, 'Mensual');
        }

        String externalIdPCGenerated;
        for (PlanComercial__c pc: pcList) {
            externalIdPCGenerated = generateExternalIdValue(pc);

            if (objetivosToUpdateActive.get(externalIdPCGenerated) != null) {
                pcToInsert.add(pc); // inserto planes anuales
            } else if (objetivosToUpdatePesos.get(externalIdPCGenerated) != null) {
                pcToUpdate.add(pc); // inserto planes mensuales
            }
        }

        if (!pcToInsert.isEmpty()) {
            // insert planes
            List<PlanComercial__c> listaPlanesInsert = generatePlanesHijosToInsert(pcToInsert, objetivosToUpdateActive);

            if (!listaPlanesInsert.isEmpty()) {
                insert listaPlanesInsert;
            }
        } else if (!pcToUpdate.isEmpty()) {
            // recalcular planes
            List<PlanComercial__c>  planesMensualesList = recalcularKPI(pcToUpdate, objetivosToUpdatePesos);

            if (!planesMensualesList.isEmpty()) {
                update planesMensualesList;
            } 

        } else if (!pcToDelete.isEmpty()) {
            // eliminar planes
            deletePlanesMensuales(pcToDelete, null);
        }

    }

    /**
     * Query planes anuales o mensuales a partir de indicadores y año
     * @param objetivosInput: Objetivos recibidos
     * @param pcType: tipo de query a hacer planes anuales o mensuales
     * @return Map con los objetivos recuperados de la consulta siendo la clave ExternalId__c 
     * @author dmunoz
     * @date 21/07/2022
     */
    private static List<PlanComercial__c> getPlanesComercialesAnualesMensualesByObjetivos(Map<String, Objective__c> objetivosInput, String pcType) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();

        Set<String> indicatorSet = new Set<String>();
        Set<String> segmentSet = new Set<String>();
        Set<String> productSet = new Set<String>();
        Set<Integer> yearSet = new Set<Integer>();

        for (Objective__c obj: objetivosInput.values()) {
            indicatorSet.add(obj.Indicator__c);
            segmentSet.add(obj.Segment__c);
            productSet.add(obj.Product__c);
            yearSet.add(Integer.valueOf(obj.Year__c));
        }

        if ('Anual'.equals(pcType)) {
            result = (new PlanComercialSelector()).findAnualPlanByObjectiveIndicators(indicatorSet, segmentSet, productSet, yearSet);
        } else if ('Mensual'.equals(pcType)) {
            result = (new PlanComercialSelector()).findMensualPlanByObjectiveIndicators(indicatorSet, segmentSet, productSet, yearSet);
        } else {
            throw new HandledException('Tipo no permitido en getPlanesComercialesAnualesMensualesByObjetivos');
        }        

        return result;
    }

    /****************************************************** Metodos Auxiliares Comunes ******************************************************************************************/
    
    /**
     * Obtener los objetivos de los planes comerciales validos
     * @param planesComercialesAnualesList: Planes comerciales validados
     * @return Map con los objetivos recuperados de la consulta siendo la clave ExternalId__c 
     * @author dmunoz
     * @date 21/07/2022
     */
    private static Map<String, Objective__c> getObjetivosParametrica(List<PlanComercial__c> planesComercialesAnualesList) {
        Map<String, Objective__c> result = new Map<String, Objective__c>();
        Set<String> externalIdsSet = getExternalIdsPlanesAnuales(planesComercialesAnualesList);

        List<Objective__c> objetivosQuery = ObjectivesSelector.selectObjectivesByExternalId(externalIdsSet);

        for (Objective__c obj: objetivosQuery) {
            result.put(obj.ExternalId__c, obj);
        }

        return result;
    }


    /**
     * Recorro los planes para obtener el conjunto de valores ExternalId para buscar en la query
     * @param planesComercialesAnualesList: Planes comerciales validados
     * @return Conjunto con los valores generados con formato ExternalId__c 
     * @author dmunoz
     * @date 21/07/2022
     */
    private static Set<String> getExternalIdsPlanesAnuales(List<PlanComercial__c> planesComercialesAnualesList) {
        Set<String> result = new Set<String>();

        for (PlanComercial__c pc: planesComercialesAnualesList) {
            result.add(generateExternalIdValue(pc));            
        }

        return result;
    }

    /**
     * Calculo del valor externalId del plan comercial
     * @param pc: plan comercial
     * @return String valor externalId
     * @author dmunoz
     * @date 21/07/2022
     */
    private static String generateExternalIdValue(PlanComercial__c pc) {
        String result;
        Integer year = pc.EndDate__c.year();
        result = String.valueOf(year) + '-' + pc.Indicator__c  + '-' + pc.Segment__c + '-' + pc.Product__c;

        return result;
    }

    /**
     * Calculo de valores de plan mensual según el mes
     * @param pc: plan comercial
     * @return Map con los calculos
     * @author dmunoz
     * @date 21/07/2022
     */
    private static Map<String, String> calculatePlanMensualFields(PlanComercial__c pc, Objective__c obj, Integer i) {
        Map<String, String> result = new Map<String, String>();

        String monthName;
        Decimal kpi;
        Integer numberOfDays;
        
        switch on i {
            when 1 {
                monthName = 'Enero';
                kpi = (pc.TargetKPINumber__c * obj.January__c) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 2 {
                monthName = 'Febrero';
                kpi = (pc.TargetKPINumber__c * (obj.January__c + obj.February__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 3 {
                monthName = 'Marzo';
                kpi = (pc.TargetKPINumber__c * (obj.January__c + obj.February__c + obj.March__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 4 {
                monthName = 'Abril';
                kpi = (pc.TargetKPINumber__c * (obj.January__c + obj.February__c + obj.March__c + obj.April__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 5 {
                monthName = 'Mayo';
                kpi = (pc.TargetKPINumber__c * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 6 {
                monthName = 'Junio';
                kpi = (pc.TargetKPINumber__c * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 7 {
                monthName = 'Julio';
                kpi = (pc.TargetKPINumber__c * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 8 {
                monthName = 'Agosto';
                kpi = (pc.TargetKPINumber__c * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c + obj.August__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 9 {
                monthName = 'Septiembre';
                kpi = (pc.TargetKPINumber__c * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c + obj.August__c + obj.September__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 10 {
                monthName = 'Octubre';
                kpi = (pc.TargetKPINumber__c * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c + obj.August__c + obj.September__c + obj.October__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 11 {
                monthName = 'Noviembre';
                kpi = (pc.TargetKPINumber__c * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c + obj.August__c + obj.September__c + obj.October__c + obj.November__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 12 {
                monthName = 'Diciembre';
                kpi = (pc.TargetKPINumber__c * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c + obj.August__c + obj.September__c + obj.October__c + obj.November__c + obj.December__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when else {
                throw new HandledException('No se permite un valor superior a 12, por ser mes, recibido ' + i);
            }
        }

        result.put('MonthName', monthName);
        result.put('KPI', String.valueOf(kpi));
        result.put('NumberOfDays', String.valueOf(numberOfDays));

        return result;
    }
}
