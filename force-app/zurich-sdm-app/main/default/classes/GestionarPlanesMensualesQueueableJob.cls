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

    private static final Integer numRecordsDML = 2000;

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
                } when 'InsertMensualesJob' { // en caso de insertar mas de 10k registros volvemos a llamar al job para los restantes
                    insertPlanesMensuales(planesComerciales);
                } when 'UpdateMensualesJob' { // en caso de actualizar mas de 10k registros volvemos a llamar al job para los restantes
                    updatePlanesMensuales(planesComerciales);
                } when 'DeleteMensualesJob' { // en caso de eliminar mas de 10k registros volvemos a llamar al job para los restantes
                    deletePlanesMensuales(planesComerciales);
                } when else {
                    throw new HandledException('Action no permitido, recibido ' + action);
                }
            }
        } catch (Exception e) {
            System.debug('exception dmm ' + e.getmessage() + ' - ' + e.getStackTraceString());
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

    /**
     * Según el número de registros a insertar, si son menores a 10k los insertamos directamente, si es mayor insertamos los primeros 10k e invocamos a un nuevo job para que los inserte directamente
     * @param planesComercialesAnualesList: Planes comerciales validados
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    private static void insertPlanesMensuales(List<PlanComercial__c> planesToInsertList) {

        if (planesToInsertList != null && !planesToInsertList.isEmpty()) {
            if (planesToInsertList.size() < numRecordsDML) {
                insert planesToInsertList;
            } else {
                dmlAndCallNewJob(planesToInsertList, 'InsertMensualesJob');
            }
        }
    }

    /**
     * Según el número de registros a insertar, si son menores a 10k los insertamos directamente, si es mayor insertamos los primeros 10k e invocamos a un nuevo job para que los inserte directamente
     * @param planesComercialesAnualesList: Planes comerciales validados
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    private static void updatePlanesMensuales(List<PlanComercial__c> planesToUpdateList) {

        if (planesToUpdateList != null && !planesToUpdateList.isEmpty()) {
            if (planesToUpdateList.size() < numRecordsDML) {
                update planesToUpdateList;
            } else {
                dmlAndCallNewJob(planesToUpdateList, 'UpdateMensualesJob');
            }
        }
    }

    /**
     * Según el número de registros a insertar, si son menores a 10k los insertamos directamente, si es mayor insertamos los primeros 10k e invocamos a un nuevo job para que los inserte directamente
     * @param planesComercialesAnualesList: Planes comerciales validados
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    private static void deletePlanesMensuales(List<PlanComercial__c> planesToDeleteList) {

        if (planesToDeleteList != null && !planesToDeleteList.isEmpty()) {
            if (planesToDeleteList.size() < numRecordsDML) {
                delete planesToDeleteList;
            } else {
                dmlAndCallNewJob(planesToDeleteList, 'DeleteMensualesJob');
            }
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
            List<PlanComercial__c> listaPlanesMensualesInsert = new List<PlanComercial__c>();

            Map<String, Objective__c> objetivosMap = getObjetivosParametrica(planesComercialesAnualesList); // key externalId
            if (!objetivosMap.isEmpty()) {
                listaPlanesMensualesInsert = generatePlanesHijosToInsert(planesComercialesAnualesList, objetivosMap);
            }  
            
            insertPlanesMensuales(listaPlanesMensualesInsert);
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

        insertPlanesMensuales(listaPlanesMensualesInsert);
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
        result.put(calculoPCMap.get('KPIField'), decimal.valueOf(calculoPCMap.get('KPI'))); // seteo uno de los 3 campos kpi segun el que esté informado en el plan mensual
        result.RecordTypeId = Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId();
        result.EndDate__c = Date.newInstance(pc.EndDate__c.year(), i, Integer.valueOf(calculoPCMap.get('NumberOfDays')));
        result.ParentPlan__c = pc.Id;
        result.SentNotifications__c = calculoPCMap.get('NotificationSent');
        result.OwnerId = pc.OwnerId;

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
                pcm.put(String.valueOf(calculoPCMap.get('KPIField')), decimal.valueOf(calculoPCMap.get('KPI'))); // actualizo uno de los 3 campos kpi segun el que esté informado en el plan mensual
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
        deletePlanesMensuales(planesComercialesMensualesList);      
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
        deletePlanesMensuales(pcToDelete);
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

            updatePlanesMensuales(planesMensualesList);            
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

        // query de planes cambia segun si es insert o update/delete de planes
        if (!objetivosToUpdateActive.isEmpty()) {
            pcToInsert = getPlanesComercialesAnualesMensualesByObjetivos(objetivosToUpdateActive, 'Anual');
        } if (!objetivosToUpdatePesos.isEmpty()) {            
            // obtener planes mensuales
            pcToUpdate = getPlanesComercialesAnualesMensualesByObjetivos(objetivosToUpdatePesos, 'Mensual');
        } if (!objetivosToUpdateInactive.isEmpty()) {
            pcToDelete = getPlanesComercialesAnualesMensualesByObjetivos(objetivosToUpdateInactive, 'Mensual');
        }             

        if (!pcToInsert.isEmpty()) {
            // insert planes
            List<PlanComercial__c> listaPlanesInsert = generatePlanesHijosToInsert(pcToInsert, objetivosToUpdateActive);
            insertPlanesMensuales(listaPlanesInsert);

        } if (!pcToUpdate.isEmpty()) {
            // recalcular planes
            List<PlanComercial__c>  planesMensualesList = recalcularKPI(pcToUpdate, objetivosToUpdatePesos);
            updatePlanesMensuales(planesMensualesList); 

        } if (!pcToDelete.isEmpty()) {
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
     * Hago la operación dml indicada, hago el insert/update/delete de los primeros 10k y los que queden los que queden los envío al siguiente encolable
     * @param planesComercialesAnualesList: Planes comerciales mensuales a insertar/ actualizar/eliminar
     * @return Map con los objetivos recuperados de la consulta siendo la clave ExternalId__c 
     * @author dmunoz
     * @date 21/07/2022
     */
    private static void dmlAndCallNewJob(List<PlanComercial__c> planesMensualesList, String action) {
        List<PlanComercial__c> planesMensualesToDMLList = new List<PlanComercial__c>();
        List<PlanComercial__c> planesMensualesSobrantesList = new List<PlanComercial__c>(); // en caso de haber mas de 10k informo esta lista
        if (planesMensualesList.size() > numRecordsDML) {            
            for (Integer i = 0; i < numRecordsDML; i++) {
                planesMensualesToDMLList.add(planesMensualesList.get(i));
            }
            for (Integer j = numRecordsDML; j < planesMensualesList.size(); j++) {
                planesMensualesSobrantesList.add(planesMensualesList.get(j));
            }
            
            System.enqueueJob(new GestionarPlanesMensualesQueueableJob(planesMensualesSobrantesList, action));
        } else {
            planesMensualesToDMLList = planesMensualesList;
        }

        switch on action {
            when 'InsertMensualesJob' {
                insert planesMensualesToDMLList;
            } when  'UpdateMensualesJob' {
                update planesMensualesToDMLList;
            } when  'DeleteMensualesJob' {
                delete planesMensualesToDMLList;
            }
            when else {
                throw new HandledException('Operación no permitida en dmlAndCallNewJob, recibido: ' + action);
            }
        }

    }
    
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
        String notificationSent;
        String kpiField = getKPIFieldName(pc);
        
        switch on i {
            when 1 {
                monthName = 'Enero';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * obj.January__c) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
                notificationSent = calculateNotificationsSent(pc, i);
            } when 2 {
                monthName = 'Febrero';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
                notificationSent = calculateNotificationsSent(pc, i);
            } when 3 {
                monthName = 'Marzo';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
                notificationSent = calculateNotificationsSent(pc, i);
            } when 4 {
                monthName = 'Abril';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
                notificationSent = calculateNotificationsSent(pc, i);
            } when 5 {
                monthName = 'Mayo';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
                notificationSent = calculateNotificationsSent(pc, i);
            } when 6 {
                monthName = 'Junio';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
                notificationSent = calculateNotificationsSent(pc, i);
            } when 7 {
                monthName = 'Julio';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
                notificationSent = calculateNotificationsSent(pc, i);
            } when 8 {
                monthName = 'Agosto';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c + obj.August__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
                notificationSent = calculateNotificationsSent(pc, i);
            } when 9 {
                monthName = 'Septiembre';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c + obj.August__c + obj.September__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
                notificationSent = calculateNotificationsSent(pc, i);
            } when 10 {
                monthName = 'Octubre';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c + obj.August__c + obj.September__c + obj.October__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
                notificationSent = calculateNotificationsSent(pc, i);
            } when 11 {
                monthName = 'Noviembre';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c + obj.August__c + obj.September__c + obj.October__c + obj.November__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
                notificationSent = calculateNotificationsSent(pc, i);
            } when 12 {
                monthName = 'Diciembre';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c + obj.August__c + obj.September__c + obj.October__c + obj.November__c + obj.December__c)) / 100;
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
                notificationSent = calculateNotificationsSent(pc, i);
            } when else {
                throw new HandledException('No se permite un valor superior a 12, por ser mes, recibido ' + i);
            }
        }

        result.put('MonthName', monthName);
        result.put('KPI', String.valueOf(kpi));
        result.put('NumberOfDays', String.valueOf(numberOfDays));
        result.put('NotificationSent', notificationSent);
        result.put('KPIField', kpiField);

        return result;
    }

    /**
     * Obtener el nombre del campo  
     * @param pc: plan comercial anual
     * @return Api name del campo informado
     * @author dmunoz
     * @date 29/08/2022
     */
    private static String getKPIFieldName(PlanComercial__c planComercial) {
        String result = '';

        if (planComercial.TargetKPIPercent__c != null) {
            result = 'TargetKPIPercent__c';
        } else if (planComercial.TargetKPINumber__c != null) {
            result = 'TargetKPINumber__c';
        } else if (planComercial.TargetKPICurrency__c != null) {
            result = 'TargetKPICurrency__c';
        }

        return result;
    }

    /**
     * Calculo el valor de sent notifications para los planes hijos, añado el valor 02,03 para no enviar notificaciones en planes de meses anteriores al actual
     * @param pc: plan comercial anual
     * @param monthToCalculate: mes a generar
     * @return Map con los calculos
     * @author dmunoz
     * @date 21/07/2022
     */
    private static String calculateNotificationsSent(PlanComercial__c pc, Integer monthToCalculate) {
        String result = '';
        Integer actualMonth = Date.today().month();

        if (monthToCalculate < actualMonth) {
            result = '01;02;03';
        }
        
        return result;
    }
}
