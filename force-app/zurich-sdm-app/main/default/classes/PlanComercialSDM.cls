/**
 * Clase que da solucion a los automatismos del PlanComercial
 * - Calculo del KPI real del Plan comercial
 *
 * Proyecto: SDM (Sales Digital Management)
 *
 * @author nts (agonzalezisasi)
 * @date 21/07/2021
 */
public with sharing class PlanComercialSDM {
    // Constantes
    @TestVisible
    private static final String CLASS_NAME = 'PlanComercialSDM';
    // Mensaje de error de indicador del plan no encontrado
    private static final String ERROR_SETTINGS_NO_INDICATOR = 'SDM-Plan Comercial-The following indicator cant be found in the metadata configuration: {0}';
    // Textos para el mensaje de notificacion cuando se elimina un plan anual a un usuario porque le ha cambiado su panel de mediadores
    private static final String SETUP_NOTIF_REMOVE_PLAN_TITLE = '1SDMAnnualPlanNotifRemovePlanTitle';
    private static final String SETUP_NOTIF_REMOVE_PLAN_TITLE_DEFAULT = 'Eliminados planes comerciales anuales';
    private static final String SETUP_NOTIF_REMOVE_PLAN_BODY = 'SDMAnnualPlanNotifRemovePlanBody';
    private static final String SETUP_NOTIF_REMOVE_PLAN_BODY_DEFAULT = 'Atención: Se han eliminado los planes comerciales anuales asociados a los mediadores que ya no están en tu panel';
    private static final String NOTIF_LIST_VIEW_API_NAME = 'Planes_anuales';

    // Lista de nombres de los campos de filtrado de los KPI__c
    @testvisible
    private static final List<String> KPI_FILTER_FIELDS = new List<String> {
        'CalcYear__c', 'CalcMonth__c', 'Intermediary__c', 'EstructuraUnificada__c', 'EstructuraDetalle__c', 'Temporalidad__c', 'Intermediary__r.Zone__c'
    };
    // Mapa de equivalencias entre campos del objeto PlanComercial__c y campos del objeto KPI__c
    private static final Map<String, String> mapPlanComercialToKpiFields = new Map<String, String> {
        'Segment__c' => 'EstructuraUnificada__c',
        'Product__c' => 'EstructuraDetalle__c',
        'AccumulateType__c' => 'Temporalidad__c'
    };
    // Se corresponde con el API NAME del valor todos en los picklist Segment__c y Product__c del objeto PlanComercial__c
    @TestVisible
    private static final String ALL_VALUE = 'Todos';
    private static final String ZONE_ALL_VALUE = 'Todos';
    private static final String PLAN_COMERCIAL_ACCUMULATE_TYPE_MONTH = 'Mensual';
    // Se corresponden el campo picklist CalculationType__c del metadato SDMCommercialPlan__mdt 
    @TestVisible
    private static final String SETTINGS_CALCULATION_TYPE_SUM = 'Sum';
    @TestVisible
    private static final String SETTINGS_CALCULATION_TYPE_RATIO = 'Ratio';
    @TestVisible
    private static final String SETTINGS_CALCULATION_TYPE_GROWTH = 'Growth';
    private static final String SETTINGS_CALCULATION_TYPE_COMPLEX_RATIO = 'ComplexRatio';
    
    SettingsSDM settings;    

    // Mapa de configuraciones del calculo de indicadores por indicador
    private Map<String, SDMCommercialPlan__mdt> mapSettingsIndicator;
    @TestVisible
    private List<SDMCommercialPlan__mdt> testSettingsIndicator;


    // Mapa de todos los mediadores de cada usuario implicado en los planes en cuestion
    @testvisible
    private Map<Id, Set<Id>> mapIntermediariesByUserId;
    // Mapa de todos los mediadores de cada agrupacion de cada usuario implicado en los planes en cuestion
    @testvisible
    private Map<Id, Map<Id, Set<Id>>> mapIntermediariesByUserIdAndAgrupationId;
    // Lista de todos los mediadores implicados en los planes en cuestion
    @testvisible
    private Set<Id> allIntermediaries;

    // Mapa de lista de KPIs de cada Mediador implicado en los planes en cuestion
    @testvisible
    private Map<Id, List<KPI__c>> mapKPIsByIntermediary;

    private String thisYear;
    private String thisMonth;
    @testvisible
    private String lastMonthOfYear;

    //Para calcular kpi real 
    @testvisible
    private Boolean containsMonths;
    @testvisible
    private Boolean containsYTD;
    @testvisible
    private Set<Id> userIdsFromPlans;

    // Constructor
    public PlanComercialSDM()
    {
        settings = new SettingsSDM();

        // Se obtiene el año actual para la recuperacion de los KPIs (mensuales y anuales)
        this.thisYear = String.valueOf(Date.today().year());
        if( Test.isRunningTest() ) this.thisYear = '2021';
        
        // Se obtiene el mes actual para la recuperacion de los KPIs (mensuales)
        this.thisMonth = String.valueOf(Date.today().month());
        if( Test.isRunningTest() ) this.thisMonth = '9';
        
        // Se obtiene el ultimo mes disponible para la recuperacion de los KPIs (anuales)
        this.lastMonthOfYear = (new KPIsSelector()).findThisYearsLastMonth();
    }

    /**
     * Recupera los KPIs para los mediadores dados. El resultado incluira los campos necesarios para luego realizar
     * los calculos.
     * Rellena el mapa global de lista de KPIs por id de mediador
     * 
     * @author nts (agonzalezisasi)
     * @date 26/07/2021
     * change aberuete 17/04/2023 - Refactorizar método
     * 
     * @param {List<Id> intermediaries} lista de ids de mediadores
     * @param {Set<String> fields} lista de campos del objeto KPI__c
     */ 
    private void findKPIsByIntermediaries(Set<Id> intermediaries, Set<String> fields, Boolean containsMonths, Boolean containsYTD)
    {
        if( intermediaries != null && !intermediaries.isEmpty() && fields != null && !fields.isEmpty() ) 
        {
            // SDM-729 - Recuperamos los KPIs, primero los mensuales y luego los anuales
            // lo hemos separado en 2 consultas debido al gran volumen de registros de KPI, para evitar que salten 
            // los limites de registros por soql
            List<KPI__c> kpis = new List<KPI__c>();

            if( containsMonths ) 
            {
                // Recuperamos los KPIs MENSUALES de los mediadores 
                List<KPI__c> kpisMonth = new KPIsSelector().findByIntermediaryIds(
                    new List<Id>(intermediaries), 
                    new List<String>{KPIsSelector.TEMPORALIDAD_Month},
                    this.thisYear, this.thisMonth,
                    fields
                );
                if( kpisMonth != null && !kpisMonth.isEmpty() ) kpis.addAll(kpisMonth);
            }

            // Recuperamos los KPIs ANUALES de los mediadores. Hay una foto por cada mes pero es acumulada, por tanto
            // debemos obtener los KPIs anuales de la ultima foto=mes disponible
            kpis = getKpisAnualOfTheLastMonth (intermediaries, fields, containsYTD, kpis);
            // Si hay kpis, generar mapa de intermediario por kpis
            ifKpisNotEmptyGenerateMapKpiIntermediary (kpis);
        }
    }

    /**
     * A través de estas variables, se va a realizar un cálculo diferente según el valor del campo “Tipo de cálculo“:
     * Suma: se usará para los KPIs de conteo y cifras económicas. Se sumará los valores de las cifras almacenadas en el campo 1.
     * Ratio: para los porcentajes que no sean de incremento. Se aplicará la siguiente fórmula:
     *      (Suma Campo 1)/(Suma Campo 2)
     * Crecimiento: para los porcentajes que calculen el incremento. Se aplicará la siguiente fórmula:
     *      [(Suma Campo 1)/(Suma Campo 2) ] -1
     * 
     * @author nts (agonzalezisasi)
     * @date 26/07/2021
     * 
     * @param {List<KPI__c> kpis} lista de kpis a tener en cuenta en el calculo
     * @param {String indicator} Nombre del indicador en la configuracion
     * @return {Decimal} el valor resultado del calculo. Si hay algun problema devolvera 0
     */
    private Decimal doCalculation(List<KPI__c> kpis, PlanComercial__c plan)
    {   
        Decimal result = 0;

        // Recuperamos de la configuracion el tipo de calculo y los nombres de los campos de KPI
        SDMCommercialPlan__mdt settingsIndicator = getMetadataRecord(plan);
        // Si existe la configuracion para ese indicador (que deberia)...
        if( settingsIndicator != null ) {
            
            Decimal firstField = 0;
            Decimal secondField = 0;
            Decimal thirdField = 0;

            // Por cada KPI sumamos los valores del primer campo siempre y del segundo campo si existe
            for( KPI__c kpi: kpis ) {
                // Primer campo siempre                
                firstField += getFirstFieldValue(settingsIndicator, kpi);
                secondField += getSecondFieldValue(settingsIndicator, kpi);
                thirdField += getThridFieldValue(settingsIndicator, kpi);                
            }

            result = getOperationResult(settingsIndicator, firstField, secondField, thirdField);
            
        }

        return result;
    }

    /**
    * @description Método que calcula el valor del campo PAActualKPI para el plan que se pasa por parámetro.
    * Este campo solo se informe en los planes cuyo indicador es PN, Cartera o APES.
    * @author amiranda
    * @date 16-03-2023 
    * @param List<KPI__c> kpis lista de KPIs a tener en cuenta en el cálculo
    * @param PLanComercial__c plan comercial sobre el que se realiza el cálculo
    * @return Decimal resultado del cálculo. Devuelve null si la suma del campo 
    * PAActualKPI de los diferentes KPIs es 0.
    **/
    private Decimal doCalculationPA(List<KPI__c> kpis, PLanComercial__c plan)
    {
        Decimal result;

        // Recuperamos de la configuracion el tipo de cálculo y los nombres de los campos de KPI
        SDMCommercialPlan__mdt settingsIndicator = getMetadataRecord(plan);

        // Si existe la configuracion para ese indicador y está marcado que debe calcularse el valor del KPI para el periodo anterior
        if( settingsIndicator != null && settingsIndicator.CalculatedPreviousPeriod__c) 
        {
            Decimal previousPeriodField = 0;
            
            // Por cada KPI se suma el valor del campo PreviousPeriodField
            for (KPI__c kpi: kpis) 
            {
                Decimal previousPeriodFieldValue = (Decimal) kpi.get(settingsIndicator.PreviousPeriodField__c);
                previousPeriodField += previousPeriodFieldValue == null ? 0 : previousPeriodFieldValue;
            }

            // Si la suma es superior a 0, se devuelve el resultado de la suma
            if (previousPeriodField > 0)
            {
                result = previousPeriodField;
            } 
        }

        return result;
    }


     /**
     * Para reducir la complejidad ciclomatica del metodo doCalculation saco fuera la logica para obtener el valor del primer campo
     * 
     * @author nts (dmunoz)
     * @date 10/03/2023
     * 
     * @param settingsIndicator registro metadata
     * @param kpi kpi
     * @return valor obtenido del kpi para el primer campo seleccionado
     */
    private Decimal getFirstFieldValue(SDMCommercialPlan__mdt settingsIndicator, KPI__c kpi) {
        Decimal result = 0;
        // Primer campo siempre
        Decimal firstFieldValue = (Decimal) kpi.get(settingsIndicator.FirstField__c);
        result = firstFieldValue == null ? 0 : firstFieldValue;

        return result;
    }

     /**
     * Para reducir la complejidad ciclomatica del metodo doCalculation saco fuera la logica para obtener el valor del segundo campo
     * 
     * @author nts (dmunoz)
     * @date 10/03/2023
     * 
     * @param settingsIndicator registro metadata
     * @param kpi kpi
     * @return valor obtenido del kpi para el segundo campo seleccionado
     */
    private Decimal getSecondFieldValue(SDMCommercialPlan__mdt settingsIndicator, KPI__c kpi) {
        Decimal result = 0;
        // Segundo campo si existe
        if( settingsIndicator.SecondField__c != null ) {
            Decimal secondFieldValue = (Decimal) kpi.get(settingsIndicator.SecondField__c);
            result = secondFieldValue == null ? 0:secondFieldValue;
        }

        return result;
    }

    /**
     * Para reducir la complejidad ciclomatica del metodo doCalculation saco fuera la logica para obtener el valor del tercer campo
     * 
     * @author nts (dmunoz)
     * @date 10/03/2023
     * 
     * @param settingsIndicator registro metadata
     * @param kpi kpi
     * @return valor obtenido del kpi para el tercer campo seleccionado
     */
    private Decimal getThridFieldValue(SDMCommercialPlan__mdt settingsIndicator, KPI__c kpi) {
        Decimal result = 0;
        // Tercer campo si existe
        if( settingsIndicator.ThirdField__c != null ) {
            Decimal thirdFieldValue = (Decimal) kpi.get(settingsIndicator.ThirdField__c);
            result = thirdFieldValue == null ? 0 : thirdFieldValue;
        }

        return result;
    }


    /**
     * Para reducir la complejidad ciclomatica del metodo doCalculation saco fuera la logica de las operaciones
     * 
     * @author nts (dmunoz)
     * @date 10/03/2023
     * 
     * @param {KPI__c kpi} datos del KPI
     * @param {PlanComercial__c plan} datos del Plan
     * @return Resultado operacion
     */
    private Decimal getOperationResult(SDMCommercialPlan__mdt settingsIndicator, Decimal firstField, Decimal secondField, Decimal thirdField) {
        Decimal result = 0;

        // Ahora dependiendo del tipo de calculo, hacemos una cosa u otra con los sumatorios
        if( settingsIndicator.CalculationType__c.equals(SETTINGS_CALCULATION_TYPE_SUM) ) {
            result = firstField;
        } else if( settingsIndicator.CalculationType__c.equals(SETTINGS_CALCULATION_TYPE_RATIO) && secondField != 0 ) {
           result = (firstField / secondField);
        } else if( settingsIndicator.CalculationType__c.equals(SETTINGS_CALCULATION_TYPE_GROWTH) && secondField != 0) {
            result = (firstField / secondField) - 1;
        } else if( settingsIndicator.CalculationType__c.equals(SETTINGS_CALCULATION_TYPE_COMPLEX_RATIO) && thirdField != 0) {
            Decimal operationResult = (((firstField - secondField) / thirdField) * 100).setScale(2);
            result = operationResult;
        }

        return result;
    }

    /**
     * Comprueba si un KPI cumple con los parametros de filtrado del plan
     * - Mediador
     * - Segmento (todos)
     * - Producto (todos)
     * - Temporalidad
     * 
     * @author nts (agonzalezisasi)
     * @date 26/07/2021
     * 
     * @param {KPI__c kpi} datos del KPI
     * @param {PlanComercial__c plan} datos del Plan
     * @return {Boolean} si el KPI cumple el plan (true) o no (false)
     */
    private Boolean inPlan(KPI__c kpi, PlanComercial__c plan) 
    {
        Boolean result = true;
        
        // Comparamos los campos de filtrado del Plan con los campos del KPI para ver si alguno hace que no cumplan
        for(String key: mapPlanComercialToKpiFields.keySet()) {
            String planFieldValue = String.valueOf(plan.get(key));
            String kpiFieldValue = String.valueOf(kpi.get(mapPlanComercialToKpiFields.get(key)));

            if( planFieldValue != ALL_VALUE && planFieldValue != kpiFieldValue ) {
                result = false; 
            }
        }

        // Si ha cumplido los parametros de filtrado, revisamos las fechas
        if( result ) {
            // Primero revisamos el año
            Integer startYear = plan.StartDate__c.year();       // Ej: 2021
            Integer endYear = plan.EndDate__c.year();           // Ej: 2022
            Integer kpiYear = Integer.valueOf(kpi.CalcYear__c); // Ej: 2021

            result = (kpiYear >= startYear && kpiYear <= endYear); // Ej: true

            // comprobamos que la zona del plan coincida con la zona del kpi que estamos consultando en caso que la zona del plan no sea TODAS
            if (result && !ZONE_ALL_VALUE.equals(plan.Zone__c)) {
                result = plan.Zone__c.equals(kpi.Intermediary__r.Zone__c);
            }

            // Y si es mensual
            if( result && plan.AccumulateType__c == PLAN_COMERCIAL_ACCUMULATE_TYPE_MONTH ) {
                // Revisamos el mes
                Integer startMonth = plan.StartDate__c.month();         // Ej: 9 (2021)
                Integer endMonth = plan.EndDate__c.month();             // Ej: 1 (2022)
                Integer kpiMonth = Integer.valueOf(kpi.CalcMonth__c);   // Ej: 11 (2021)

                Integer startValue = (startYear * 100) + startMonth;     // Ej: 202100 + 9 =     202109
                Integer endValue = (endYear * 100) + endMonth;           // Ej: 202200 + 1 =     202201
                Integer kpiValue = (kpiYear * 100) + kpiMonth;      // Ej: 202100 + 11 =    202111

                result = (kpiValue >= startValue && kpiValue <= endValue); // Ej: true 
            }
        }

        return result;
    }

    /**
     * Recupera los mediadores relacionados con los usuarios indicados. El resultado generará un mapa de mediadores 
     * por cada usuario, otro de mediadores por cada agrupacion de cada usuario y un listado de todos los mediadores 
     * recuperados.
     * 
     * @author nts (agonzalezisasi)
     * @date 26/08/2021
     * @change aberuete - 11/04/2023 Refactorizar método
     * 
     * @param {Set<Id> userIds} listado de ids de usuario
     */
    public void findIntermediariesByUserIds(Set<Id> userIds)
    {
        // Si hay usuarios
        if( userIds != null && !userIds.isEmpty() ) 
        {
            // Se recuperan los ATMs que hay para dichos usuarios. Se incluyen los campos del mediador y de la agrupacion
            // a la que pertenece
            List<AccountTeamMember> atms = (new AccountTeamMemberSelector()).findIntermediariesByUsers(userIds);

            // Si se han encontrado ATMs
            if( atms != null && !atms.isEmpty() ) 
            {
                allIntermediaries = new Set<Id>();
                // Crear un mapa de todos los mediadores de cada usuario
                mapIntermediariesByUserId = new Map<Id, Set<Id>>();
                // Crear un mapa de todos los mediadores de cada agrupacion para cada usuario
                mapIntermediariesByUserIdAndAgrupationId = new Map<Id, Map<Id, Set<Id>>>();
                // Rellenar ambos mapas
                generateMapIntermediariesToCalculateKpi (atms);
            }
        }
    }

    /**
     * Obtiene el Id de usuario del Plan comercial.
     * Primero a partir del campo AssignedTo__c y si esta vacio lo recupera del usuario
     * que ha creado el plan
     * 
     * @author nts (agonzalezisasi)
     * @date 28/07/2021
     * 
     * @param {PlanComercial__c plan} el plan comercial
     * @return {Id} id del usuario
     */
    private Id getUserIdFromPlan(PlanComercial__c plan) 
    {
        Id userId = plan.AssignedTo__c;
        if( userId == null ) userId = plan.CreatedById;

        return userId;
    }

    /**
     * Calcula el valor de los KPIs que engloban el plan comercial
     * 
     * @author nts (agonzalezisasi)
     * @date 27/07/2021
     * @change aberuete 17/04/2023 - Refactorizar método
     * 
     * @param {List<PlanComercial__c> plans} lista de planes comerciales
     */
    public void calculateRealKPI(List<PlanComercial__c> plans) 
    {
        if( plans != null && !plans.isEmpty() ) 
        {
            // Inicializamos las variables globales para cada calculo
            allIntermediaries = null;
            mapIntermediariesByUserId = null;
            mapIntermediariesByUserIdAndAgrupationId = null;
            mapKPIsByIntermediary = null;

            // Guardara la lista de ids de usuarios de los planes
            userIdsFromPlans = new Set<Id>();       
            // Guardara la lista de indicadores a recuperar de los KPIs para el calculo
            Set<String> kpiFields = new Set<String>();
            // Guardara la lista de Planes a modificar
            List<PlanComercial__c> plansToUpdate = new List<PlanComercial__c>();

            // Añadimos a los campos de KPI a recuperar los campos de filtrado.
            // Para luego poder usarlos para saber si el kpi cumple con los filtros del plan
            kpiFields.addAll(KPI_FILTER_FIELDS);

            // Recuperamos la configuracion del calculo para cada indicador del plan comercial
            mapSettingsIndicator = settings.getSettingsIndicator(this.testSettingsIndicator);

            // Se genera un mapa de agrupaciones de mediadores para los planes actuales
            // findAgrupationsByPlan(plans);                        
            containsMonths = false;
            containsYTD = false;
            
            // Por cada Plan comercial... averiguamos el usuario, los campos y los mediadores a los que hace referencia
            
            for(PlanComercial__c plan: plans) 
            {
                // Recuperamos la configuracion del calculo del indicador que deberia existir
                SDMCommercialPlan__mdt indicatorSetting = getMetadataRecord(plan);
                // Si no existe la configuracion => reportar error
                if( indicatorSetting == null ) 
                { 
                    String errorMessage = String.format(ERROR_SETTINGS_NO_INDICATOR, new List<String>{plan.Indicator__c});
                    ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, errorMessage, CLASS_NAME);
                } 

                kpiFields = ifIndicatorSettingNotNUll (indicatorSetting, kpiFields, plan);
            }
            
            // Recuperamos todos los mediadores y agrupaciones relacionados con los usuarios de los planes en cuestion
            findIntermediariesByUserIds(userIdsFromPlans);

            // Recuperamos todos los KPIs a partir de los mediadores
            findKPIsByIntermediaries(allIntermediaries, kpiFields, containsMonths, containsYTD);

            // Si se han encontrado KPIs...
            calculateRealKpiAndUpdatePlans (plans, plansToUpdate);
        }
    }
    
    /**
     * Metodo que comprueba si hay que eliminar planes comerciales anuales a partir de los ATMs proporcionados
     *  
     * @author nts (agonzalezisasi)
     * @date 11/10/2021
     * @change aberuete 11/04/2023 - Refactorizar método
     * 
     * @param {List<AccountTeamMember> deletedAtms} lista de ATMs eliminados
     */
    public void removeAnnualPlans(List<AccountTeamMember> deletedAtms)
    {
        if( deletedAtms != null && !deletedAtms.isEmpty() ) 
        {
            // 1. Recuperamos la lista de mediadores y usuarios de los ATMs eliminados
            Set<Id> intermediaries = new Set<Id>();
            Set<Id> users = new Set<Id>();
            // formando tambien una lista de la pareja mediador-usuario
            Set<String> deletedRelations = new Set<String>();
            for(AccountTeamMember atm: deletedAtms) 
            {
                intermediaries.add(atm.AccountId);
                users.add(atm.UserId);
                deletedRelations.add(atm.AccountId + '#' + atm.UserId);
            }

            // 2. Recuperamos la lista de planes que pertenecen a esos mediadores y usuarios
            List<PlanComercial__c> annualPlans = (new PlanComercialSelector()).findAnnualPlansByIntermediariesAndUsers(
                intermediaries, users
            );
            // Eliminar los planes y mandar notificación a los usuarios
            ifIntermediaryAndUserDeletedEliminatePlans (annualPlans, deletedRelations);
        }
    }

    /**
     * Metodo que envia la siguiente notificacion a todos los usuarios (RN) que se les ha eliminado planes comerciales
     * anuales porque algun mediador les ha desparecido del panel
     * 
     * @param {Set<Id> userIds} Lista de usuario receptores de la notificacion
     * @param {Set<String> planSubjects} lista de asuntos de planes a incluir en el mensaje de la notificacion
     */
    public void sendNotificationRemovedPlans(Set<Id> userIds)
    {
        if( userIds != null && !userIds.isEmpty() ) {
            String title = this.settings.getSetupParameter(SETUP_NOTIF_REMOVE_PLAN_TITLE, SETUP_NOTIF_REMOVE_PLAN_TITLE_DEFAULT);
            String bodyContent = this.settings.getSetupParameter(SETUP_NOTIF_REMOVE_PLAN_BODY, SETUP_NOTIF_REMOVE_PLAN_BODY_DEFAULT);

            Notification notif = new Notification(Notification.notificationType.SDMAlert);
            // Permite abrir la seccion de Cuentas, listview Mis Mediadores
            notif.addPageReference('standard__objectPage', 'PlanComercial__c', 'list', NOTIF_LIST_VIEW_API_NAME);
            // Convertimos la lista de ids de usuario a string
            Set<String> stringSet = new Set<String>( (List<String>)new List<Id>( userIds ) );
            notif.send(stringSet, title, bodyContent);
        }
    }

    /**
     * Debido a que existe ya un registro en la metadata para retencion y siniestralidad, para no solapar creamos un nuevo registro para esos indicadores añadiendo HO (Home Office) al final para identificar los planes que ha creado el home office
     * 
     * @param PlanComercial__c plan comercial a conseguir el registro metadata adecuado
     */
    private SDMCommercialPlan__mdt getMetadataRecord (PlanComercial__c plan) {

        SDMCommercialPlan__mdt result;
        String indicator;
        if (plan.IsOwnedByHomeOffice__c) {
            indicator = plan.Indicator__c + 'HO';
        } else {
            indicator = plan.Indicator__c;
        }

        result =  mapSettingsIndicator?.get(indicator);
        return result;
    }

    /**
    * @description Método que se encarga de eliminar los planes anuales y notificar al usuario del plan si no existe relación entre el mediador y el usuario
    * @author aberuete 
    * @date 11-04-2023 
    **/
    @testvisible
    private void ifIntermediaryAndUserDeletedEliminatePlans (List<PlanComercial__c> annualPlans, Set<String> deletedRelations)
    {
        if( annualPlans != null && !annualPlans.isEmpty() ) 
        {
            List<PlanComercial__c> plansToDelete = new List<PlanComercial__c>();
            Set<Id> userIdsToNotify = new Set<Id>();

            // Comprobamos para cada plan...
            for(PlanComercial__c plan: annualPlans) 
            {
                // si cumple que tenga la pareja de mediadores y usuarios eliminados
                String planRelation = plan.Intermediary__c + '#' + plan.AssignedTo__c;
                if( deletedRelations.contains(planRelation) ) 
                {
                    plansToDelete.add(plan);
                    userIdsToNotify.add(plan.AssignedTo__c);
                }
            }

            if( !plansToDelete.isEmpty() ) 
            {
                delete plansToDelete;

                if( !userIdsToNotify.isEmpty() ) 
                {
                    sendNotificationRemovedPlans(userIdsToNotify);
                }
            }
        }
    }
    /**
    * @description Método que rellena los mapas de intermediarios por usuario e intermediario por usuario y cuenta de agrupación 
    * @author aberuete 
    * @date 11-04-2023 
    * @param List<AccountTeamMember> atms : lista de miembros de equipos de cuentas
    **/
    @testvisible
    private void generateMapIntermediariesToCalculateKpi (List<AccountTeamMember> atms)
    {
        for(AccountTeamMember atm: atms) 
        {
            // Creacion del mapa de lista de mediadores por id de usuario
            Set<Id> listIntermediaries = mapIntermediariesByUserId.get(atm.UserId);
            if( listIntermediaries == null ) 
            {
                listIntermediaries = new Set<Id>();
                mapIntermediariesByUserId.put(atm.UserId, listIntermediaries);
            }
            listIntermediaries.add(atm.AccountId);

            // Creacion del mapa de lista de mediadores por id de agrupacion y estos a su vez por id de usuario
            if( atm.Account.ParentId != null ) 
            {    
                Map<Id, Set<Id>> mapIntermediariesByAgrupationId = mapIntermediariesByUserIdAndAgrupationId.get(atm.UserId);
                if( mapIntermediariesByAgrupationId == null ) 
                {
                    mapIntermediariesByAgrupationId = new Map<Id, Set<Id>>();
                    mapIntermediariesByUserIdAndAgrupationId.put(atm.UserId, mapIntermediariesByAgrupationId);
                }
                Set<Id> listIntermediaries2 = mapIntermediariesByAgrupationId.get(atm.Account.ParentId);
                if( listIntermediaries2 == null ) 
                {
                    listIntermediaries2 = new Set<Id>();
                    mapIntermediariesByAgrupationId.put(atm.Account.ParentId, listIntermediaries2);
                }
                listIntermediaries2.add(atm.AccountId);
            }
            // Añadimos el mediador a la lista de todos los mediadores
            allIntermediaries.add(atm.AccountId);
        }   
    }

    /**
    * @description Método que se encarga de rellenar el mapa de kpis por intermediario
    * @author aberuete 
    * @date 11-04-2023 
    * @param List<KPI__c> kpis : lista de kpis
    **/
    @testvisible
    private void ifKpisNotEmptyGenerateMapKpiIntermediary (List<KPI__c> kpis)
    {
        if( !kpis.isEmpty() ) 
        {
            // A partir de los datos recuperamos generamos un mapa de KPIs por mediador como clave
            mapKPIsByIntermediary = new Map<Id, List<KPI__c>>();
            // Por cada KPI recuperado ...
            for(KPI__c kpi: kpis) 
            {
                // Lo añadimos al mapa
                List<KPI__c> kpisOfIntermediary = mapKPIsByIntermediary.get(kpi.Intermediary__c);
                if( kpisOfIntermediary == null ) 
                {
                    kpisOfIntermediary = new List<KPI__c>();
                    mapKPIsByIntermediary.put(kpi.Intermediary__c, kpisOfIntermediary);
                }
                kpisOfIntermediary.add(kpi);
            }
        }
    }

    /**
    * @description Método que se encarga de obtener una lista de los kpis anuales del último mes
    * @author aberuete 
    * @date 11-04-2023 
    * @param Set<Id> intermediaries : conjunto de ids de mediadores
    * @param Set<String> fields : conjunto de nombre de los campos de kpi a recuperar por la query
    * @param Boolean containsYTD : booleano que indica si la temporalidad es ytd 
    * @param List<KPI__c> kpis : lista de kpis
    **/
    @testvisible
    private List<KPI__c> getKpisAnualOfTheLastMonth (Set<Id> intermediaries, Set<String> fields, Boolean containsYTD, List<KPI__c> kpis)
    {
        // Recuperamos los KPIs ANUALES de los mediadores. Hay una foto por cada mes pero es acumulada, por tanto
        // debemos obtener los KPIs anuales de la ultima foto=mes disponible
        if( containsYTD && this.lastMonthOfYear != null ) 
        {
            List<KPI__c> kpisAnnual = new KPIsSelector().findByIntermediaryIds(
                new List<Id>(intermediaries), 
                new List<String>{KPIsSelector.TEMPORALIDAD_YTD},
                this.thisYear, this.lastMonthOfYear,
                fields
            );
            if( kpisAnnual != null && !kpisAnnual.isEmpty() ) kpis.addAll(kpisAnnual);
        }

        return kpis;
    }

     /**
    * @description Método que se encarga de obtener los campos del metadato SDMCommercialPlan__mdt que correspondan dependiendo del plan comercial
    * @author aberuete 
    * @date 17-04-2023 
    * @param SDMCommercialPlan__mdt indicatorSetting : metadato SDMCommercialPlan__mdt
    * @param Set<String> kpiFields : conjunto de campos de kpi 
    * @param PlanComercial__c plan : plan comercial
    **/
    @testvisible
    private Set<String> ifIndicatorSettingNotNUll (SDMCommercialPlan__mdt indicatorSetting, Set<String> kpiFields, PlanComercial__c plan)
    {
        if ( indicatorSetting != null)
        {
            // Incluimos los campos del indicador para recuperarlos con la consulta de kpis
            kpiFields.add(indicatorSetting.FirstField__c);
            if( indicatorSetting.SecondField__c != null ) kpiFields.add(indicatorSetting.SecondField__c);
            if( indicatorSetting.ThirdField__c != null ) kpiFields.add(indicatorSetting.ThirdField__c);

            if( !containsMonths ) containsMonths = (plan.AccumulateType__c == PlanComercialSelector.ACCUMULATE_TYPE_MONTH);
            if( !containsYTD ) containsYTD = (plan.AccumulateType__c == PlanComercialSelector.ACCUMULATE_TYPE_YRD);

            if (indicatorSetting.CalculatedPreviousPeriod__c) kpiFields.add(indicatorSetting.PreviousPeriodField__c);

            // Recuperamos el usuario del plan y lo incluimos en la lista de usuarios implicados
            Id userId = getUserIdFromPlan(plan);
            if( userId != null ) userIdsFromPlans.add(userId);
        }   
        
        return kpiFields;
    }

    /**
    * @description Método que se encarga de obtener el conjunto de ids de las cuentas de intermediario asociadas al plan comercial y al usuario
    * @author aberuete 
    * @date 17-04-2023 
    * @param PlanComercial__c plan : plan comercial
    * @param Id userId : id de usuario
    **/
    @testvisible
    private Set<Id> getIdsIntermediariesOfPlan (PlanComercial__c plan, Id userId)
    {
        Set<Id> intermediaries = null;

        if( plan.Intermediary__c == null ) 
        {
            intermediaries = mapIntermediariesByUserId?.get(userId);
        } 
        else 
        {
            // Miramos si el mediador del plan es de Agrupacion (puede no ser y por tanto devolver nulo)
            Map<Id, Set<Id>> mapIntermediaries = mapIntermediariesByUserIdAndAgrupationId?.get(userId);
            intermediaries = mapIntermediaries?.get(plan.Intermediary__c);

            // Si la lista es nula significa que no es una agrupacion sino un mediador directamente
            if( intermediaries == null && mapIntermediariesByUserId?.get(userId) != null 
            && mapIntermediariesByUserId.get(userId).contains(plan.Intermediary__c) ) 
            {
                intermediaries = new Set<Id>{plan.Intermediary__c};
            }
        }
        return intermediaries;
    }

     /**
    * @description Método que se encarga de obtener una lista de kpis a recalcular que están asociados con el 
    * plan comercial y el conjunto de intermediarios
    * @author aberuete 
    * @date 17-04-2023 
    * @param Set<Id> intermediaries : conjunto de ids de cuentas de intermediario
    * @param PlanComercial__c plan : plan comercial
    **/
    @testvisible
    private List<KPI__c> getKpisToCalculate (Set<Id> intermediaries, PlanComercial__c plan)
    {
        List<KPI__c> kpis = new List<KPI__c>();
        // Por cada mediador...
        for(Id idIntermediaries: intermediaries) 
        {
            // Recuperamos la lista de KPIs que hay para ese mediador
            List<KPI__c> kpisByIntermediary = mapKPIsByIntermediary?.get(idIntermediaries);
            // Si existe algun KPI...
            if( kpisByIntermediary != null && !kpisByIntermediary.isEmpty() ) 
            {
                // Por cada KPI, comprobamos que el KPI cumple con los filtros del plan
                for(KPI__c kpi: kpisByIntermediary) 
                {
                    // Si cumple los filtros lo añadimos a la lista de kpis a tener en cuenta en el
                    // calculo
                    if( inPlan(kpi, plan) ) kpis.add(kpi);
                }
            }
        }
        return kpis;     
    }

     /**
    * @description Método que se encarga de recalcular el kpi actual para los kpis dados asociados al plan comercial
    *  y lo añade a la lista de planes comerciales a actualizar
    * @author aberuete 
    * @date 17-04-2023 
    * @param List<PlanComercial__c> plansToUpdate :  lista que contiene los planes comerciales a actualizar
    * @param List<KPI__c> kpis : lista de kpis
    * @param PlanComercial__c plan : plan comercial
    **/
    @testvisible
    private List<PlanComercial__c> updatePlanWithRealKpi (List<PlanComercial__c> plansToUpdate,List<KPI__c> kpis, PlanComercial__c plan)
    {
        if( !kpis.isEmpty() ) 
        {
            // Se realiza el calculo para el KPI Actual
            Decimal result = doCalculation(kpis, plan);

            // Guardamos el resultado en el Plan comercial
            PlanComercial__c planToUpdate = new PlanComercial__c(
                Id = plan.Id,
                Actual_KPI__c = result
            );
            
            // Se realiza el cálculo para el KPI Actual del perioodo anterior
            Decimal resultPA = doCalculationPA(kpis, plan);
            
            if (resultPA != null)
            {
                planToUpdate.PAActualKPI__c = resultPA;
            }
            
            plansToUpdate.add(planToUpdate);
        }
        return plansToUpdate;
    }

    /**
    * @description Método que se encarga de recalcular el kpi actual para los kpis dados asociados al plan comercial
    *  y actualiza los planes comerciales
    * @author aberuete 
    * @date 17-04-2023 
    * @param List<PlanComercial__c> plans : Lista de planes para recalcular su kpi
    * @param List<PlanComercial__c> plansToUpdate :  lista que contiene los planes comerciales a actualizar
    **/
    @testvisible
    private void calculateRealKpiAndUpdatePlans (List<PlanComercial__c> plans,  List<PlanComercial__c> plansToUpdate)
    {
        if( mapKPIsByIntermediary != null && !mapKPIsByIntermediary.isEmpty() ) 
        {
            // Ahora si, por cada plan comercial, se realiza el calculo...
            for(PlanComercial__c plan: plans) 
            {
                // Obtenemos de nuevo el usuario relacionado con el plan
                Id userId = getUserIdFromPlan(plan);

                // Obtenemos la lista de mediadores implicados en el plan segun el campo mediador tenga
                // uno de los siguientes valores:
                // - nulo: todos los mediadores que ve el usuario del plan
                // - agrupacion: todos los mediadores de esa agrupacion que ve el usuario del plan
                // - mediador: el mediador directamente
                Set<Id> intermediaries = getIdsIntermediariesOfPlan (plan, userId);

                // Si hay mediadores..
                if( intermediaries != null && !intermediaries.isEmpty() ) 
                {
                    // formaremos una lista de KPIs a utilizar en el calculo
                    List<KPI__c> kpis = getKpisToCalculate (intermediaries, plan);
                    // Si hay KPIs (que deberia)...
                    plansToUpdate = updatePlanWithRealKpi (plansToUpdate, kpis, plan);
                }
            }

            // Si hay planes a modificar se actualizan
            if( !plansToUpdate.isEmpty() ) 
            {
                update plansToUpdate;
            }
        } 
    }
}