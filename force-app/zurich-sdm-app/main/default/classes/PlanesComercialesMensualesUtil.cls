/**
 * Clase utilidad que contiene los métodos necesarios para generar y actualizar planes mensuales
 * 
 * @author nts (dmunoz)
 * @date 23/02/2023
 *
 */
public with sharing class PlanesComercialesMensualesUtil {

    /******************************************************* Métodos consulta BD *****************************************************************************************/

    /**
     * Query planes anuales o mensuales a partir de indicadores y año
     * @param objetivosInput: Objetivos recibidos
     * @param pcType: tipo de query a hacer planes anuales o mensuales
     * @return Map con los objetivos recuperados de la consulta siendo la clave ExternalId__c 
     * @author dmunoz
     * @date 21/07/2022
     */
    public static List<PlanComercial__c> getPlanesComercialesAnualesMensualesByObjetivos(Map<String, Objective__c> objetivosInput, String pcType) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();

        Set<String> indicatorSet = new Set<String>();
        Set<String> segmentSet = new Set<String>();
        Set<String> productSet = new Set<String>();
        Set<String> zoneSet = new Set<String>();
        Set<Integer> yearSet = new Set<Integer>();

        for (Objective__c obj: objetivosInput.values()) {
            indicatorSet.add(obj.Indicator__c);
            segmentSet.add(obj.Segment__c);
            productSet.add(obj.Product__c);
            zoneSet.add(obj.Zone__c);
            yearSet.add(Integer.valueOf(obj.Year__c));
        }

        if ('Anual'.equals(pcType)) {
            result = (new PlanComercialSelector()).findAnualPlanByObjectiveIndicators(indicatorSet, segmentSet, productSet, zoneSet, yearSet);
        } else if ('Mensual'.equals(pcType)) {
            result = (new PlanComercialSelector()).findMensualPlanByObjectiveIndicators(indicatorSet, segmentSet, productSet, zoneSet, yearSet);
        } else {
            throw new HandledException('Tipo no permitido en getPlanesComercialesAnualesMensualesByObjetivos');
        }        

        return result;
    }


    /**
     * Obtener los objetivos de los planes comerciales validos
     * @param planesComercialesAnualesList: Planes comerciales validados
     * @return Map con los objetivos recuperados de la consulta siendo la clave ExternalId__c 
     * @author dmunoz
     * @date 21/07/2022
     */
    public static Map<String, Objective__c> getObjetivosParametrica(List<PlanComercial__c> planesComercialesAnualesList) {
        Map<String, Objective__c> result = new Map<String, Objective__c>();

        Set<String> externalIdsSet = getExternalIdsPlanesAnuales(planesComercialesAnualesList);

        List<Objective__c> objetivosQuery = ObjectivesSelector.selectObjectivesByExternalId(externalIdsSet);

        for (Objective__c obj: objetivosQuery) {
            result.put(obj.ExternalId__c, obj);
        }

        return result;
    }


    /******************************************************* Métodos generar planes mensuales *****************************************************************************************/


    /**
     * Recorro los planes para generar los registros mensuales de cada plan anual
     * @param planesComercialesAnualesList: Planes comerciales validados
     * @param objetivosMap: Mapa de objetivos
     * @return Lista de planes mensuales listos para insertar
     * @author dmunoz
     * @date 21/07/2022
     */
    public static List<PlanComercial__c> generatePlanesMensualesToInsert(List<PlanComercial__c> planesComercialesAnualesList, Map<String, Objective__c> objetivosMap, Map<Id, PlanComercial__c> mapParentOwner) {

        List<PlanComercial__c> result = new List<PlanComercial__c>();
        String pcExternalId; // calculo el valor externalId para obtener el objetivo con el cual generaremos los planes mensuales con los pesos indicados
        Objective__c obj; // objetivo para el plan comercial i
        List<PlanComercial__c> planesMensuales = new List<PlanComercial__c>(); // lista de planes mensuales para el plan comercial i
        
        for (PlanComercial__c pc: planesComercialesAnualesList) {
            pcExternalId = generateExternalIdValue(pc);
            obj = objetivosMap.get(pcExternalId);

            if (obj != null) { // al hacer get si no lo encuentra devuelve null
                planesMensuales = generatePlanesMensualesFromPlanAnual(pc, obj, mapParentOwner); // lista auxiliar con los 12 planes mensuales generados
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
    private static List<PlanComercial__c> generatePlanesMensualesFromPlanAnual(PlanComercial__c pc, Objective__c obj, Map<Id, PlanComercial__c> mapParentOwner) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();

        for (Integer i = 1; i <= 12; i++) { // bucle por cada mes del año
            result.add(generatePlanMensual(pc, obj, i, mapParentOwner));
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
    private static PlanComercial__c generatePlanMensual(PlanComercial__c pc, Objective__c obj, Integer i, Map<Id, PlanComercial__c> mapParentOwner) {        
        PlanComercial__c result = pc.clone(false, false, false, false);

        if ('Ratio_Retention'.equals(pc.Indicator__c)) {
            result = calculateRetentionPlanData(pc, obj, i);
        } else if ('Ratio_Claim'.equals(pc.Indicator__c)) {
            result = calculateAccidentPlanData(pc, obj, i);
        } else {
            result = calculateOtherPlanData(pc, obj, i, mapParentOwner);
        }

        return result;
    }


    /**
     * Generar plan mensual Ratio Retencion para el mes i a partir de un plan anual
     * @param pc: Plan Anual
     * @param obj: Objetivo
     * @param i: nº del mes a generar
     * @return Plan Mensual i para el plan anual de entrada
     * @author dmunoz
     * @date 21/07/2022
     */
    private static PlanComercial__c calculateRetentionPlanData(PlanComercial__c pc, Objective__c obj, Integer i) {        
        Map<String, String> calculoPCMap = calculateAccidentRetentionPlanMensualFields(pc, obj, i);
        PlanComercial__c result = getMensualPlanFromAccidentRetention(pc, i, calculoPCMap);

        result.Name = ('Retención Mensual Zurich ' + obj.Segment__c + ' ' + obj.Zone__c + ' ' + calculoPCMap.get('MonthName')).left(75) + ' ' + pc.EndDate__c.year(); // recorto el tamaño a 75 y añado 5 caracteres al final con el año haciendo un total de 80
        
        return result;
    }


    /**
     * Generar plan mensual Ratio Retencion para el mes i a partir de un plan anual
     * @param pc: Plan Anual
     * @param obj: Objetivo
     * @param i: nº del mes a generar
     * @return Plan Mensual i para el plan anual de entrada
     * @author dmunoz
     * @date 21/07/2022
     */
    private static PlanComercial__c calculateAccidentPlanData(PlanComercial__c pc, Objective__c obj, Integer i) {        
        Map<String, String> calculoPCMap = calculateAccidentRetentionPlanMensualFields(pc, obj, i);
        PlanComercial__c result = getMensualPlanFromAccidentRetention(pc, i, calculoPCMap);
        
        result.Name = ('Siniestralidad Mensual Zurich ' + obj.Segment__c + ' ' + obj.Zone__c + ' ' + calculoPCMap.get('MonthName')).left(75) + ' ' + pc.EndDate__c.year(); // recorto el tamaño a 75 y añado 5 caracteres al final con el año haciendo un total de 80        

        return result;
    }

     /**
     * Generar plan mensual Ratio Retencion/Siniestralidad para el mes i a partir de un plan anual. Contiene los calculos comunes para estos registros
     * @param pc: Plan Anual
     * @param obj: Objetivo
     * @param i: nº del mes a generar
     * @return Plan Mensual i para el plan anual de entrada
     * @author dmunoz
     * @date 21/07/2022
     */
    private static PlanComercial__c getMensualPlanFromAccidentRetention(PlanComercial__c pc, Integer i, Map<String, String> calculoPCMap) {        
        PlanComercial__c result = pc.clone(false, false, false, false);       
        
        result.TargetKPIPercent__c = Decimal.valueOf(calculoPCMap.get('KPI'));
        result.RecordTypeId = Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId();
        result.StartDate__c = Date.newInstance(pc.EndDate__c.year(), i, 1); // no son acumulativos, por lo que start date es el 1 del mes a calcular
        result.EndDate__c = Date.newInstance(pc.EndDate__c.year(), i, Integer.valueOf(calculoPCMap.get('NumberOfDays')));
        result.SentNotifications__c = calculoPCMap.get('SentNotification');
        result.ParentPlan__c = pc.Id;

        return result;
    }

    /**
     * Generar plan mensual PN, Cartera, APES para el mes i a partir de un plan anual
     * @param pc: Plan Anual
     * @param obj: Objetivo
     * @param i: nº del mes a generar
     * @return Plan Mensual i para el plan anual de entrada
     * @author dmunoz
     * @date 21/07/2022
     */
    private static PlanComercial__c calculateOtherPlanData(PlanComercial__c pc, Objective__c obj, Integer i, Map<Id, PlanComercial__c> mapParentOwner) {        
        PlanComercial__c result = pc.clone(false, false, false, false);
        
        Map<String, String> calculoPCMap = calculatePlanMensualFields(pc, obj, i);

        result.Name = (pc.Name + ' ' + calculoPCMap.get('MonthName')).left(75) + ' ' + pc.EndDate__c.year(); // recorto el tamaño a 75 y añado 5 caracteres al final con el año haciendo un total de 80
        result.put(calculoPCMap.get('KPIField'), decimal.valueOf(calculoPCMap.get('KPI'))); // seteo uno de los 3 campos kpi segun el que esté informado en el plan mensual
        result.RecordTypeId = Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId();
        result.EndDate__c = Date.newInstance(pc.EndDate__c.year(), i, Integer.valueOf(calculoPCMap.get('NumberOfDays')));
        result.ParentPlan__c = pc.Id;
        result.OwnerId = calculatePlanOwner(pc, mapParentOwner);
        result.SentNotifications__c = calculoPCMap.get('NotificationSent');
        result.Actual_KPI__c = String.isEmpty(calculoPCMap.get('ActualKPI')) ? null : Decimal.valueOf(calculoPCMap.get('ActualKPI'));

        return result;
    }   


    /******************************************************* Métodos actualizar planes mensuales *****************************************************************************************/

    /**
     * Lista de ids permitidos para generar planes mensuales, PN, Cartera, APES, Retención y Siniestralidad
     * @return List<String>
     * @author dmunoz
     * @date 23/02/2023
     */
    private static List<String> getValidEmailsFromMetadata() {
        AdminSetupParameter__mdt adminSetupParameterMDT = AdminSetupParameter__mdt.getInstance('MensualPlanValidEmails');

        List<String> result = new List<String>();
        String metadataEmailsRaw = adminSetupParameterMDT.Value__c;

        if (String.isNotEmpty(metadataEmailsRaw)) {
            result = new List<String>(metadataEmailsRaw.split(','));
        }
        
        return result;
    }

    /**
     * Gestion logica actualización objetivos y su influencia sobre los PC
     * @param mapObjetivos: objetivos modificados
     * @return void
     * @author dmunoz
     * @date 21/07/2022
     */
    public static Map<String, List<PlanComercial__c>> updatePlanesMensualesFromObjective(Map<String, Map<String, Objective__c>> mapObjetivos) {

        Map<String, List<PlanComercial__c>> result = new Map<String, List<PlanComercial__c>>();
        Map<String, Objective__c> objetivosToUpdatePesos = mapObjetivos.get('ObjetivosToUpdatePesos'); // map externalId, Objetivo;  objetivos para recalcular los pesos
        Map<String, Objective__c> objetivosToUpdateActiveMensual = mapObjetivos.get('ObjetivosToUpdateActiveMensual'); // map externalId, Objetivo;  objetivos distintos de retencion y siniestralidad
        Map<String, Objective__c> objetivosToUpdateInactiveMensual = mapObjetivos.get('ObjetivosToUpdateInactiveMensual'); // map externalId, Objetivo; objetivos distintos de retencion y siniestralidad
        Map<String, Objective__c> objetivosToUpdateActiveAnual = mapObjetivos.get('ObjetivosToUpdateActiveAnual'); // map externalId, Objetivo;  calculamos solo los planes anuales
        Map<String, Objective__c> objetivosToUpdateInactiveAnual = mapObjetivos.get('ObjetivosToUpdateInactiveAnual'); // map externalId, Objetivo;  eliminaremos solo los planes anuales

        // lista pc para hacer las operaciones
        List<PlanComercial__c> pcMensualesToInsert = new List<PlanComercial__c>();
        List<PlanComercial__c> pcMensualToUpdate = new List<PlanComercial__c>();
        List<PlanComercial__c> pcMensualToDelete = new List<PlanComercial__c>();
        List<PlanComercial__c> pcAnualToInsert = new List<PlanComercial__c>();
        List<PlanComercial__c> pcAnualToDelete = new List<PlanComercial__c>();
        List<PlanComercial__c> pcAnualMensualToDelete = new List<PlanComercial__c>();

        if (!objetivosToUpdateActiveMensual.isEmpty()) { // objetivos PN, Cartera y APES activados
            // obtener planes anuales
            List<PlanComercial__c> pcAnualesBDList = getPlanesComercialesAnualesMensualesByObjetivos(objetivosToUpdateActiveMensual, 'Anual');
            Map<Id, PlanComercial__c> mapParentOwner = (new PlanComercialSelector()).getParentOwnerId(pcAnualesBDList);

            // calcular registros mensuales de los planes obtenidos de base de datos
            pcMensualesToInsert = generatePlanesMensualesToInsert(pcAnualesBDList, objetivosToUpdateActiveMensual, mapParentOwner);

        } if (!objetivosToUpdatePesos.isEmpty()) { // objetivos PN, Cartera, APES, Retencion, Siniestralidad modificados los pesos de los objetivos
            // obtener planes mensuales de BD
            List<PlanComercial__c> planesMensualesBDList = getPlanesComercialesAnualesMensualesByObjetivos(objetivosToUpdatePesos, 'Mensual');
            // actualizar los registros de planes mensuales obtenidos de BD
            pcMensualToUpdate = recalcularKPI(planesMensualesBDList, objetivosToUpdatePesos);

        } if (!objetivosToUpdateInactiveMensual.isEmpty()) { // objetivos PN, Cartera y APES desactivados
            // obtener planes mensuales a eliminar
            pcMensualToDelete = getPlanesComercialesAnualesMensualesByObjetivos(objetivosToUpdateInactiveMensual, 'Mensual');

        } if (!objetivosToUpdateActiveAnual.isEmpty()) { // objetivos Retencion y Siniestralidad activados
            // recupero los email de los usuarios piloto
            List<String> validEmailList = getValidEmailsFromMetadata();
            // calcular los planes anuales de retencion y siniestralidad
            pcAnualToInsert = PlanesComercialesAnualesUtil.generateAnualPlansFromUpdateObjectives(objetivosToUpdateActiveAnual, validEmailList);

        } if (!objetivosToUpdateInactiveAnual.isEmpty()) { // objetivos Retencion y Siniestralidad desactivados
            // obtener planes anuales
            pcAnualToDelete = getPlanesComercialesAnualesMensualesByObjetivos(objetivosToUpdateInactiveAnual, 'Anual');
            pcAnualMensualToDelete = getPlanesComercialesAnualesMensualesByObjetivos(objetivosToUpdateInactiveAnual, 'Mensual');
            pcMensualToDelete.addAll(pcAnualMensualToDelete); // añado los planes mensuales encontrados a la lista de planes mensuales a eliminar
        }

        result.put('PlanesMensualesToInsert', pcMensualesToInsert);
        result.put('PlanesMensualesToUpdate', pcMensualToUpdate);
        result.put('PlanesMensualesToDelete', pcMensualToDelete);
        result.put('PlanesAnualesToInsert', pcAnualToInsert);
        result.put('PlanesAnualesToDelete', pcAnualToDelete);

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
    public static List<PlanComercial__c> recalcularKPI(List<PlanComercial__c> planesMensualesList, Map<String, Objective__c> objetivosMap) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();
        String externalIdPCM;    
        Objective__c obj;  
        Map<String, String> calculoPCMap;        

        for (PlanComercial__c pcm: planesMensualesList) {
            externalIdPCM = generateExternalIdValue(pcm);
            obj = objetivosMap.get(externalIdPCM);

            if (obj != null) {
                if ('Ratio_Retention'.equals(pcm.Indicator__c) || 'Ratio_Claim'.equals(pcm.Indicator__c)) {
                    calculoPCMap = calculateAccidentRetentionPlanMensualFields(pcm, obj, pcm.EndDate__c.month());
                    pcm.TargetKPIPercent__c = Decimal.valueOf(calculoPCMap.get('KPI'));
                } else {
                    calculoPCMap = calculatePlanMensualFields(pcm.ParentPlan__r, obj, pcm.EndDate__c.month());
                    pcm.put(String.valueOf(calculoPCMap.get('KPIField')), Decimal.valueOf(calculoPCMap.get('KPI'))); // actualizo uno de los 3 campos kpi segun el que esté informado en el plan mensual
                }
                result.add(pcm);
            }
        }

        return result;
    }


    /****************************************************** Metodos auxiliares ******************************************************************************/

    /**
     * Calculo de valores de plan mensual siniestralidad/retencion según el mes
     * @param pc: plan comercial
     * @return Map con los calculos
     * @author dmunoz
     * @date 21/07/2022
     */
    private static Map<String, String> calculateAccidentRetentionPlanMensualFields(PlanComercial__c pc, Objective__c obj, Integer i) {
        Map<String, String> result = new Map<String, String>();

        String monthName;
        Decimal kpi;
        Integer numberOfDays;
        String sentNotification;
        Integer actualMonth = Date.today().month();
        
        switch on i {
            when 1 {
                monthName = 'Enero';
                kpi = obj.January__c;
                sentNotification = calculateNotificationsSent(i, actualMonth);
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 2 {
                monthName = 'Febrero';
                kpi = obj.February__c;
                sentNotification = calculateNotificationsSent(i, actualMonth);
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 3 {
                monthName = 'Marzo';
                kpi = obj.March__c;
                sentNotification = calculateNotificationsSent(i, actualMonth);
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 4 {
                monthName = 'Abril';
                kpi = obj.April__c;
                sentNotification = calculateNotificationsSent(i, actualMonth);
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 5 {
                monthName = 'Mayo';
                kpi = obj.May__c;
                sentNotification = calculateNotificationsSent(i, actualMonth);
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 6 {
                monthName = 'Junio';
                kpi = obj.June__c;
                sentNotification = calculateNotificationsSent(i, actualMonth);
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 7 {
                monthName = 'Julio';
                kpi = obj.July__c;
                sentNotification = calculateNotificationsSent(i, actualMonth);
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 8 {
                monthName = 'Agosto';
                kpi = obj.August__c;
                sentNotification = calculateNotificationsSent(i, actualMonth);
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 9 {
                monthName = 'Septiembre';
                kpi = obj.September__c;
                sentNotification = calculateNotificationsSent(i, actualMonth);
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 10 {
                monthName = 'Octubre';
                kpi = obj.October__c;
                sentNotification = calculateNotificationsSent(i, actualMonth);
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 11 {
                monthName = 'Noviembre';
                kpi = obj.November__c;
                sentNotification = calculateNotificationsSent(i, actualMonth);
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when 12 {
                monthName = 'Diciembre';
                kpi = obj.December__c;
                sentNotification = calculateNotificationsSent(i, actualMonth);
                numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
            } when else {
                throw new HandledException('No se permite un valor superior a 12, por ser mes, recibido ' + i);
            }
        }

        result.put('MonthName', monthName);
        result.put('KPI', String.valueOf(kpi));
        result.put('NumberOfDays', String.valueOf(numberOfDays));
        result.put('SentNotification', sentNotification);

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

        Integer actualMonth = Date.today().month();
        String monthName;
        Decimal kpi;
        Integer numberOfDays = Date.daysInMonth(pc.EndDate__c.year(), i);
        String kpiField = getKPIFieldName(pc);
        String actualKPI = calculateActualKPI(pc, i, actualMonth);
        String notificationSent = calculateNotificationsSent(i, actualMonth);

        
        switch on i {
            when 1 {
                monthName = 'Enero';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * obj.January__c) / 100;
            } when 2 {
                monthName = 'Febrero';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c)) / 100;
            } when 3 {
                monthName = 'Marzo';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c)) / 100;
            } when 4 {
                monthName = 'Abril';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c)) / 100;
            } when 5 {
                monthName = 'Mayo';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c)) / 100;
            } when 6 {
                monthName = 'Junio';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c)) / 100;
            } when 7 {
                monthName = 'Julio';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c)) / 100;
            } when 8 {
                monthName = 'Agosto';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c + obj.August__c)) / 100;
            } when 9 {
                monthName = 'Septiembre';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c + obj.August__c + obj.September__c)) / 100;
            } when 10 {
                monthName = 'Octubre';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c + obj.August__c + obj.September__c + obj.October__c)) / 100;
            } when 11 {
                monthName = 'Noviembre';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c + obj.August__c + obj.September__c + obj.October__c + obj.November__c)) / 100;
            } when 12 {
                monthName = 'Diciembre';
                kpi = (Decimal.valueOf(String.valueOf(pc.get(kpiField))) * (obj.January__c + obj.February__c + obj.March__c + obj.April__c + obj.May__c + obj.June__c + 
                        obj.July__c + obj.August__c + obj.September__c + obj.October__c + obj.November__c + obj.December__c)) / 100;
            } when else {
                throw new HandledException('No se permite un valor superior a 12, por ser mes, recibido ' + i);
            }
        }

        result.put('MonthName', monthName);
        result.put('KPI', String.valueOf(kpi));
        result.put('NumberOfDays', String.valueOf(numberOfDays));
        result.put('NotificationSent', notificationSent);
        result.put('KPIField', kpiField);
        result.put('ActualKPI', actualKPI);

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
    private static String calculateNotificationsSent(Integer monthToCalculate, Integer actualMonth) {
        String result = '';

        if (monthToCalculate < actualMonth) {
            result = '01;02;03';
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
        result = String.valueOf(year) + '-' + pc.Indicator__c  + '-' + pc.Segment__c + '-' + pc.Product__c + '-' + pc.Zone__c;

        return result;
    }


    /**
     * Obtener el nombre del campo  
     * @param pc: plan comercial anual
     * @return Api name del campo informado
     * @author dmunoz
     * @date 29/08/2022
     */
    public static String getKPIFieldName(PlanComercial__c planComercial) {
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
     * En caso de que al generar los planes mensuales el anual tenga informado el actual kpi, solo informaremos ese campo para los planes del mes actual en adelante
     * @param pc: plan comercial anual
     * @param monthToCalculate: mes a generar
     * @return Map con los calculos
     * @author dmunoz
     * @date 21/07/2022
     */
    private static String calculateActualKPI(PlanComercial__c pc, Integer monthToCalculate, Integer actualMonth) {
        String result = String.valueOf(pc.Actual_KPI__c);        

        if (monthToCalculate < actualMonth) {
            result = null;
        }
        
        return result;
    }

    private static String calculatePlanOwner(PlanComercial__c pc, Map<Id, PlanComercial__c> mapParentOwner) {
        String result = pc.OwnerId;

        // si el plan a calcular no tiene owner id es que el plan anual lo ha creado un director o un rn
        if (String.isEmpty(pc.ParentPlan__c)) {
            return result;
        } else {
            result = mapParentOwner.get(pc.Id).ParentPlan__r.OwnerId;
        }

        return result;
    }
}