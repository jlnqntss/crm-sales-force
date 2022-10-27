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
    
    SettingsSDM settings;    

    // Mapa de configuraciones del calculo de indicadores por indicador
    private Map<String, SDMCommercialPlan__mdt> mapSettingsIndicator;
    @TestVisible
    private List<SDMCommercialPlan__mdt> testSettingsIndicator;


    // Mapa de todos los mediadores de cada usuario implicado en los planes en cuestion
    private Map<Id, Set<Id>> mapIntermediariesByUserId;
    // Mapa de todos los mediadores de cada agrupacion de cada usuario implicado en los planes en cuestion
    private Map<Id, Map<Id, Set<Id>>> mapIntermediariesByUserIdAndAgrupationId;
    // Lista de todos los mediadores implicados en los planes en cuestion
    private Set<Id> allIntermediaries;

    // Mapa de lista de KPIs de cada Mediador implicado en los planes en cuestion
    private Map<Id, List<KPI__c>> mapKPIsByIntermediary;

    private String thisYear;
    private String thisMonth;
    private String lastMonthOfYear;

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
     * 
     * @param {List<Id> intermediaries} lista de ids de mediadores
     * @param {Set<String> fields} lista de campos del objeto KPI__c
     */ 
    private void findKPIsByIntermediaries(Set<Id> intermediaries, Set<String> fields, Boolean containsMonths, Boolean containsYTD)
    {
        if( intermediaries != null && !intermediaries.isEmpty() && fields != null && !fields.isEmpty() ) {
            // SDM-729 - Recuperamos los KPIs, primero los mensuales y luego los anuales
            // lo hemos separado en 2 consultas debido al gran volumen de registros de KPI, para evitar que salten 
            // los limites de registros por soql
            List<KPI__c> kpis = new List<KPI__c>();

            if( containsMonths ) {
                // Recuperamos los KPIs MENSUALES de los mediadores 
                List<KPI__c> kpisMonth = new KPIsSelector().findByIntermediaryIds(
                    new List<Id>(intermediaries), 
                    new List<String>{KPIsSelector.TEMPORALIDAD_Month},
                    this.thisYear, this.thisMonth,
                    fields
                );
                if( kpisMonth != null && !kpisMonth.isEmpty() ) kpis.addAll(kpisMonth);
            }

            if( containsYTD ) {
                // Recuperamos los KPIs ANUALES de los mediadores. Hay una foto por cada mes pero es acumulada, por tanto
                // debemos obtener los KPIs anuales de la ultima foto=mes disponible
                if( this.lastMonthOfYear != null ) {
                    List<KPI__c> kpisAnnual = new KPIsSelector().findByIntermediaryIds(
                        new List<Id>(intermediaries), 
                        new List<String>{KPIsSelector.TEMPORALIDAD_YTD},
                        this.thisYear, this.lastMonthOfYear,
                        fields
                    );
                    if( kpisAnnual != null && !kpisAnnual.isEmpty() ) kpis.addAll(kpisAnnual);
                }
            }
            
            // Si se ha encontrado algo...
            if( !kpis.isEmpty() ) {
                // A partir de los datos recuperamos generamos un mapa de KPIs por mediador como clave
                mapKPIsByIntermediary = new Map<Id, List<KPI__c>>();
                // Por cada KPI recuperado ...
                for(KPI__c kpi: kpis) {
                    // Lo añadimos al mapa
                    List<KPI__c> tmp = mapKPIsByIntermediary.get(kpi.Intermediary__c);
                    if( tmp == null ) {
                        tmp = new List<KPI__c>();
                        mapKPIsByIntermediary.put(kpi.Intermediary__c, tmp);
                    }
                    tmp.add(kpi);
                }
            }
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
    private Decimal doCalculation(List<KPI__c> kpis, String indicator)
    {
        Decimal result = 0;

        // Recuperamos de la configuracion el tipo de calculo y los nombres de los campos de KPI
        SDMCommercialPlan__mdt settingsIndicator = mapSettingsIndicator?.get(indicator);
        // Si existe la configuracion para ese indicador (que deberia)...
        if( settingsIndicator != null ) {
            
            Decimal firstField = 0;
            Decimal secondField = 0;

            // Por cada KPI sumamos los valores del primer campo siempre y del segundo campo si existe
            for( KPI__c kpi: kpis ) {
                // Primer campo siempre
                Decimal firstFieldValue = (Decimal)kpi.get(settingsIndicator.FirstField__c);
                firstField += (firstFieldValue == null ? 0:firstFieldValue );

                // Segundo campo si existe
                if( settingsIndicator.SecondField__c != null ) {
                    Decimal secondFieldValue = (Decimal)kpi.get(settingsIndicator.SecondField__c);
                    secondField += (secondFieldValue == null ? 0:secondFieldValue );
                }
            }

            // Ahora dependiendo del tipo de calculo, hacemos una cosa u otra con los sumatorios
            if( settingsIndicator.CalculationType__c.equals(SETTINGS_CALCULATION_TYPE_SUM) ) {
                result = firstField;
            } else if( settingsIndicator.CalculationType__c.equals(SETTINGS_CALCULATION_TYPE_RATIO) ) {
                if( secondField != 0 ) result = (firstField / secondField);
            } else if( settingsIndicator.CalculationType__c.equals(SETTINGS_CALCULATION_TYPE_GROWTH) ) {
                if( secondField != 0 ) result = (firstField / secondField) - 1;
            }
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
     * 
     * @param {Set<Id> userIds} listado de ids de usuario
     */
    public void findIntermediariesByUserIds(Set<Id> userIds)
    {
        // Si hay usuarios
        if( userIds != null && !userIds.isEmpty() ) {
            // Se recuperan los ATMs que hay para dichos usuarios. Se incluyen los campos del mediador y de la agrupacion
            // a la que pertenece
            List<AccountTeamMember> atms = (new AccountTeamMemberSelector()).findIntermediariesByUsers(userIds);

            // Si se han encontrado ATMs
            if( atms != null && !atms.isEmpty() ) {
                allIntermediaries = new Set<Id>();
                // Crear un mapa de todos los mediadores de cada usuario
                mapIntermediariesByUserId = new Map<Id, Set<Id>>();
                // Crear un mapa de todos los mediadores de cada agrupacion para cada usuario
                mapIntermediariesByUserIdAndAgrupationId = new Map<Id, Map<Id, Set<Id>>>();

                // Por cada ATM ... rellenaremos los mapas y la lista
                for(AccountTeamMember atm: atms) {
                    // Creacion del mapa de lista de mediadores por id de usuario
                    Set<Id> listIntermediaries = mapIntermediariesByUserId.get(atm.UserId);
                    if( listIntermediaries == null ) {
                        listIntermediaries = new Set<Id>();
                        mapIntermediariesByUserId.put(atm.UserId, listIntermediaries);
                    }
                    listIntermediaries.add(atm.AccountId);

                    // Creacion del mapa de lista de mediadores por id de agrupacion y estos a su vez por id de usuario
                    if( atm.Account.ParentId != null ) {    
                        Map<Id, Set<Id>> mapIntermediariesByAgrupationId = mapIntermediariesByUserIdAndAgrupationId.get(atm.UserId);
                        if( mapIntermediariesByAgrupationId == null ) {
                            mapIntermediariesByAgrupationId = new Map<Id, Set<Id>>();
                            mapIntermediariesByUserIdAndAgrupationId.put(atm.UserId, mapIntermediariesByAgrupationId);
                        }
                        Set<Id> listIntermediaries2 = mapIntermediariesByAgrupationId.get(atm.Account.ParentId);
                        if( listIntermediaries2 == null ) {
                            listIntermediaries2 = new Set<Id>();
                            mapIntermediariesByAgrupationId.put(atm.Account.ParentId, listIntermediaries2);
                        }
                        listIntermediaries2.add(atm.AccountId);
                    }

                    // Añadimos el mediador a la lista de todos los mediadores
                    allIntermediaries.add(atm.AccountId);
                }
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
     * 
     * @param {List<PlanComercial__c> plans} lista de planes comerciales
     */
    public void calculateRealKPI(List<PlanComercial__c> plans) 
    {
        if( plans != null && !plans.isEmpty() ) {
            // Inicializamos las variables globales para cada calculo
            allIntermediaries = null;
            mapIntermediariesByUserId = null;
            mapIntermediariesByUserIdAndAgrupationId = null;
            mapKPIsByIntermediary = null;

            // Guardara la lista de ids de usuarios de los planes
            Set<Id> userIds = new Set<Id>();       
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
            Boolean containsMonths = false;
            Boolean containsYTD = false;
            
            // Por cada Plan comercial... averiguamos el usuario, los campos y los mediadores a los que hace referencia
            for(PlanComercial__c plan: plans) {
                // Recuperamos la configuracion del calculo del indicador que deberia existir
                SDMCommercialPlan__mdt indicatorSetting = mapSettingsIndicator?.get(plan.Indicator__c);
                if( indicatorSetting == null ) { // Si no existe la configuracion => reportar error
                    String errorMessage = String.format(ERROR_SETTINGS_NO_INDICATOR, new List<String>{plan.Indicator__c});
                    ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, errorMessage, CLASS_NAME);
                } else {
                    // Incluimos los campos del indicador para recuperarlos con la consulta de kpis
                    kpiFields.add(indicatorSetting.FirstField__c);
                    if( indicatorSetting.SecondField__c != null ) kpiFields.add(indicatorSetting.SecondField__c);

                    if( !containsMonths ) containsMonths = (plan.AccumulateType__c == PlanComercialSelector.ACCUMULATE_TYPE_MONTH);
                    if( !containsYTD ) containsYTD = (plan.AccumulateType__c == PlanComercialSelector.ACCUMULATE_TYPE_YRD);

                    // Recuperamos el usuario del plan y lo incluimos en la lista de usuarios implicados
                    Id userId = getUserIdFromPlan(plan);
                    if( userId != null ) userIds.add(userId);
                }
            }

            // Recuperamos todos los mediadores y agrupaciones relacionados con los usuarios de los planes en cuestion
            findIntermediariesByUserIds(userIds);

            // Recuperamos todos los KPIs a partir de los mediadores
            findKPIsByIntermediaries(allIntermediaries, kpiFields, containsMonths, containsYTD);

            // Si se han encontrado KPIs...
            if( mapKPIsByIntermediary != null && !mapKPIsByIntermediary.isEmpty() ) {
                // Ahora si, por cada plan comercial, se realiza el calculo...
                for(PlanComercial__c plan: plans) {

                    // Obtenemos de nuevo el usuario relacionado con el plan
                    Id userId = getUserIdFromPlan(plan);

                    // Obtenemos la lista de mediadores implicados en el plan segun el campo mediador tenga
                    // uno de los siguientes valores:
                    // - nulo: todos los mediadores que ve el usuario del plan
                    // - agrupacion: todos los mediadores de esa agrupacion que ve el usuario del plan
                    // - mediador: el mediador directamente
                    Set<Id> intermediaries = null;
                    if( plan.Intermediary__c == null ) {
                        intermediaries = mapIntermediariesByUserId?.get(userId);
                    } else {
                        // Miramos si el mediador del plan es de Agrupacion (puede no ser y por tanto devolver nulo)
                        Map<Id, Set<Id>> mapIntermediaries = mapIntermediariesByUserIdAndAgrupationId?.get(userId);
                        intermediaries = mapIntermediaries?.get(plan.Intermediary__c);

                        // Si la lista es nula significa que no es una agrupacion sino un mediador directamente
                        if( intermediaries == null 
                            && mapIntermediariesByUserId?.get(userId) != null && mapIntermediariesByUserId.get(userId).contains(plan.Intermediary__c) ) {
                            intermediaries = new Set<Id>{plan.Intermediary__c};
                        }
                    }

                    // Si hay mediadores..
                    if( intermediaries != null && !intermediaries.isEmpty() ) {
                        // formaremos una lista de KPIs a utilizar en el calculo
                        List<KPI__c> kpis = new List<KPI__c>();

                        // Por cada mediador...
                        for(Id i: intermediaries) {
                            // Recuperamos la lista de KPIs que hay para ese mediador
                            List<KPI__c> kpisByIntermediary = mapKPIsByIntermediary?.get(i);
                            // Si existe algun KPI...
                            if( kpisByIntermediary != null && !kpisByIntermediary.isEmpty() ) {
                                // Por cada KPI, comprobamos que el KPI cumple con los filtros del plan
                                for(KPI__c kpi: kpisByIntermediary) {
                                    // Si cumple los filtros lo añadimos a la lista de kpis a tener en cuenta en el
                                    // calculo
                                    if( inPlan(kpi, plan) ) kpis.add(kpi);
                                }
                            }
                        }
                        
                        // Si hay KPIs (que deberia)...
                        if( !kpis.isEmpty() ) {
                            // Se realiza el calculo
                            Decimal result = doCalculation(kpis, plan.Indicator__c);

                            // Guardamos el resultado en el Plan comercial
                            plansToUpdate.add(new PlanComercial__c(
                                Id= plan.Id,
                                Actual_KPI__c= result
                            ));
                        }
                    }
                }

                // Si hay planes a modificar se actualizan
                if( !plansToUpdate.isEmpty() ) {
                    update plansToUpdate;
                }
            }
        }
    }
    
    /**
     * Metodo que comprueba si hay que eliminar planes comerciales anuales a partir de los ATMs proporcionados
     *  
     * @author nts (agonzalezisasi)
     * @date 11/10/2021
     * 
     * @param {List<AccountTeamMember> deletedAtms} lista de ATMs eliminados
     */
    public void removeAnnualPlans(List<AccountTeamMember> deletedAtms)
    {
        if( deletedAtms != null && !deletedAtms.isEmpty() ) {
            // 1. Recuperamos la lista de mediadores y usuarios de los ATMs eliminados
            Set<Id> intermediaries = new Set<Id>();
            Set<Id> users = new Set<Id>();
            // formando tambien una lista de la pareja mediador-usuario
            Set<String> deletedRelations = new Set<String>();
            for(AccountTeamMember atm: deletedAtms) {
                intermediaries.add(atm.AccountId);
                users.add(atm.UserId);
                deletedRelations.add(atm.AccountId + '#' + atm.UserId);
            }

            // 2. Recuperamos la lista de planes que pertenecen a esos mediadores y usuarios
            List<PlanComercial__c> annualPlans = (new PlanComercialSelector()).findAnnualPlansByIntermediariesAndUsers(
                intermediaries, users
            );
            if( annualPlans != null && !annualPlans.isEmpty() ) {
                List<PlanComercial__c> plansToDelete = new List<PlanComercial__c>();
                Set<Id> userIdsToNotify = new Set<Id>();

                // Comprobamos para cada plan...
                for(PlanComercial__c plan: annualPlans) {
                    // si cumple que tenga la pareja de mediadores y usuarios eliminados
                    String planRelation = plan.Intermediary__c + '#' + plan.AssignedTo__c;
                    if( deletedRelations.contains(planRelation) ) {
                        plansToDelete.add(plan);
                        userIdsToNotify.add(plan.AssignedTo__c);
                    }
                }

                if( !plansToDelete.isEmpty() ) {
                    delete plansToDelete;

                    if( !userIdsToNotify.isEmpty() ) {
                        sendNotificationRemovedPlans(userIdsToNotify);
                    }
                }
            }
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
}
