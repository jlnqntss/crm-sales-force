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
    private static final String ERROR_SETTINGS_NO_INDICATOR = 'SDM-Plan Comercial-The following indicator cant be found in the metadata configuration: {0}';
    private static final List<String> KPI_FILTER_FIELDS = new List<String> {
        'Intermediary__c', 'EstructuraUnificada__c', 'EstructuraDetalle__c', 'Temporalidad__c'
    };
    private static final Map<String, String> mapPlanComercialToKpiFields = new Map<String, String> {
        'Segment__c' => 'EstructuraUnificada__c',
        'Product__c' => 'EstructuraDetalle__c',
        'AccumulateType__c' => 'Temporalidad__c'
    };
    // Se corresponde con el API NAME del valor todos en los picklist Segment__c y Product__c del objeto PlanComercial__c
    @TestVisible
    private static final String ALL_VALUE = 'Todos';
    // Se corresponden el campo picklist CalculationType__c del metadato SDMCommercialPlan__mdt 
    @TestVisible
    private static final String SETTINGS_CALCULATION_TYPE_SUM = 'Sum';
    @TestVisible
    private static final String SETTINGS_CALCULATION_TYPE_RATIO = 'Ratio';
    @TestVisible
    private static final String SETTINGS_CALCULATION_TYPE_GROWTH = 'Growth';

    // Mapa de configuraciones del calculo de indicadores por indicador
    private Map<String, SDMCommercialPlan__mdt> mapSettingsIndicator;
    @TestVisible
    private List<SDMCommercialPlan__mdt> testSettingsIndicator;
    // Mapa de intermediarios por id de usuario e id de agrupacion
    Map<Id, Map<Id, Set<Id>>> mapIntermediariesByUserAndAgrupationId;
    // Lista de todos los mediadores
    Set<Id> allIntermediaries;
    // Mapa de Agrupaciones de mediadores por Id de agrupacion
    private Map<Id, Account> mapAgruptaionsById;
    // Mapa de lista de KPIs por id de intermediario
    private Map<Id, List<KPI__c>> mapKPIsByIntermediary;
    // Id del RecordType AgrupacionMediador del objeto Account
    Id rtAgrupationId;
    // Id del RecordType Intermediary del objeto Account
    Id rtIntermediaryId;

    /**
     * Recuperamos de los metadatos de configuracion los tipos de calculos que seran necesarios para cada indicador
     * de los planes comerciales
     * 
     * @author nts (agonzalezisasi)
     * @date 26/07/2021
     */
    private void getSettingsIndicator()
    {
        // Si no existen los datos de configuracion...
        if( mapSettingsIndicator == null ) {
            // creamos el mapa
            mapSettingsIndicator = new Map<String, SDMCommercialPlan__mdt>();
            // Recuperamos los datos de configuracion de los indicadores
            List<SDMCommercialPlan__mdt> settings = [
                SELECT Indicator__c, CalculationType__c, FirstField__c, SecondField__c FROM SDMCommercialPlan__mdt
            ];

            // Solo para los test cambiamos la configuracion
            if( Test.isRunningTest() && testSettingsIndicator != null ) {
                settings = testSettingsIndicator;
            }

            // Por cada indicador...
            for(SDMCommercialPlan__mdt s: settings) {
                mapSettingsIndicator.put( s.Indicator__c, s );
            }
        }
    }

    /**
     * Recuperamos los mediadores relacionados con las agrupaciones de mediadores para unos usuarios determinados
     * El resultado se añade al mapa global de lista de intermediarios por id de usuario
     * 
     * @author nts (agonzalezisasi)
     * @date 26/07/2021
     * 
     * @param {Set<Id> agrupatedIds} lista de ids de agrupacion de mediadores (account)
     * @param {Set<Id> userIds} lista de ids de usuarios de salesforce
     */
    private void findIntermediaryByAgrupatedId(Set<Id> agrupatedIds, Set<Id> userIds)
    {
        // is hay ids de agrupacion y de usuario
        if( agrupatedIds != null && !agrupatedIds.isEmpty() && userIds != null && !userIds.isEmpty() ) {
            // Recuperamos los Equipos de cuenta
            List<AccountTeamMember> atms = [
                SELECT Id, UserId, AccountId, Account.ParentId
                FROM AccountTeamMember
                WHERE Account.ParentId IN :agrupatedIds
                AND UserId IN :userIds
            ];

            // Inicializamos el mapa de lista de intermediarios por agrupacion
            mapIntermediariesByUserAndAgrupationId = new Map<Id, Map<Id, Set<Id>>>();
            // Por cada atm encontrado...
            for(AccountTeamMember atm: atms) {
                // rellenamos el mapa de lista de mediadores por usuario y agrupacion
                Map<Id, Set<Id>> mapIntermediaryByAgrupationId = mapIntermediariesByUserAndAgrupationId.get(atm.UserId);
                if( mapIntermediaryByAgrupationId == null ) {
                    mapIntermediaryByAgrupationId = new Map<Id, Set<Id>>();
                    mapIntermediariesByUserAndAgrupationId.put(atm.UserId, mapIntermediaryByAgrupationId);
                }
                Set<Id> listIntermediaries = mapIntermediaryByAgrupationId.get(atm.Account.ParentId);
                if( listIntermediaries == null ) {
                    listIntermediaries = new Set<Id>();
                    mapIntermediaryByAgrupationId.put(atm.Account.ParentId, listIntermediaries);
                }
                listIntermediaries.add(atm.AccountId);

                // rellenamos la lista de todos los mediadores
                allIntermediaries.add(atm.AccountId);
            }
        }
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
    private void findKPIsByIntermediaries(Set<Id> intermediaries, Set<String> fields)
    {
        // Recuperamos los KPIs de los mediadores
        List<KPI__c> kpis = new KPIsSelector().findByIntermediaryIds(new LIst<Id>(intermediaries), fields);
        
        // Si se ha encontrado algo...
        if( kpis != null && !kpis.isEmpty() ) {
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

        return result;
    }

    /**
     * Recupera los mediadores de agrupacion relacionados con los planes de accion datos y crea un mapa
     * de mediadores de agrupacion por Id (puede quedar vacio);
     * 
     * @author nts (agonzalezisasi)
     * @date 26/07/2021
     * 
     * @param {List<PlanComercial> plans} lista de planes comerciales
     */
    private void findAgrupationsByPlan(List<PlanComercial__c> plans)
    {
        // Se crea la subquery de planes comerciales que nos dara los mediadores de cada plan
        Query planQuery = new Query(PlanComercial__c.getSObjectType());
        planQuery.selectField(PlanComercial__c.Intermediary__c);
        planQuery.addConditionIn(PlanComercial__c.Id, plans);

        // Se recuperan las agrupaciones a partir de los mediadores de los planes
        List<Account> agrupations = new AccountsSelector().findAgrupationsBySubquery(planQuery);
        
        // Si hay agrupaciones...
        if( agrupations != null ) {
            // Se genera un mapa de agrupaciones por id
            mapAgruptaionsById = new Map<Id, Account>(agrupations);
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
            // Inicializamos los mapas globales para cada calculo
            mapIntermediariesByUserAndAgrupationId = null;
            mapAgruptaionsById = null;
            mapKPIsByIntermediary = null;
            allIntermediaries = new Set<Id>();

            // Guardara la lista de ids de agrupaciones de mediadores
            Set<Id> agrupatedIds = new Set<Id>();     
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
            getSettingsIndicator();

            // Se genera un mapa de agrupaciones de mediadores para los planes actuales
            findAgrupationsByPlan(plans);                        
            
            // Por cada Plan comercial... averiguamos el usuario, los campos y los mediadores a los que hace referencia
            for(PlanComercial__c plan: plans) {
                // Recuperamos el usuario que ha creado el plan
                Id userId = getUserIdFromPlan(plan);

                // Recuperamos la configuracion del calculo del indicador que deberia existir
                SDMCommercialPlan__mdt indicatorSetting = mapSettingsIndicator?.get(plan.Indicator__c);
                if( indicatorSetting == null ) { // Si no existe la configuracion => reportar error
                    String errorMessage = String.format(ERROR_SETTINGS_NO_INDICATOR, new List<String>{plan.Indicator__c});
                    ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, errorMessage, CLASS_NAME);
                } else {
                    // Incluimos los campos del indicador para recuperarlos con la consulta de kpis
                    kpiFields.add(indicatorSetting.FirstField__c);
                    if( indicatorSetting.SecondField__c != null ) kpiFields.add(indicatorSetting.SecondField__c);
                    // Intentamos recuperar el Id de agrupacion del mediador a partir de id de mediador informado
                    // en el plan
                    Id agrupatedId = mapAgruptaionsById?.get(plan.Intermediary__c)?.Id;
                    // Si NO es agrupacion...
                    if( agrupatedId == null ) {
                        // Lo añadimos a la lista de intermediarios para el usuario
                        allIntermediaries.add(plan.Intermediary__c);
                    } else {
                        // Si SI es una agrupacion, se añade a la lista de agrupaciones y usuarios
                        agrupatedIds.add(agrupatedId);
                        userIds.add(userId);
                    }
                }
            }

            // Recuperamos los mediadores de las Agrupaciones si los hay
            findIntermediaryByAgrupatedId(agrupatedIds, userIds);

            // Recuperamos los KPIs a partir de los mediadores
            findKPIsByIntermediaries(allIntermediaries, kpiFields);

            if( mapKPIsByIntermediary != null && !mapKPIsByIntermediary.isEmpty() ) {
                // Ahora si, por cada plan comercial, se realiza el calculo...
                for(PlanComercial__c plan: plans) {
                    Id userId = getUserIdFromPlan(plan);

                    // Intentamos recuperar la lista de mediadores por agrupacion para el usuario si los hay...
                    Map<Id, Set<Id>> mapIntermediaries = mapIntermediariesByUserAndAgrupationId?.get(userId);
                    // Intentamos recuperar la lista de mediadores para la agrupacion si la hay...
                    Set<Id> intermediaries = mapIntermediaries?.get(plan.Intermediary__c);
                    // Si no se ha encontrado nada es directamente un mediador...
                    if( intermediaries == null ) intermediaries = new Set<Id>{plan.Intermediary__c};

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
}
