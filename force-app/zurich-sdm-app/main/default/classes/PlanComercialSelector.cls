/**
 * Clase selector del objeto PlanComercial__c
 *
 * Proyecto: SDM (Sales Digital Management)
 *
 * @author nts (agonzalezisasi)
 * @date 01/10/2021
 */
public with sharing class PlanComercialSelector extends RecordsSelector {

    public static final String RT_NAME_PLAN_ANUAL = 'AnualPlan'; // Recordtype PlanComercial__c=>PlanAnual

    public static final String SEGMENT_ALL = 'Todos'; // Valor picklist PlanComercial__c.Segment__c
    public static final String PRODUCT_ALL = 'Todos'; // Valor picklist PlanComercial__c.Product__c
    public static final String ACCUMULATE_TYPE_YRD = 'YTD'; // Valor picklist PlanComercial__c.AccumulateType__c
    public static final String INDICATOR_PN = 'PN';  // Valor picklist PlanComercial__c.Indicator__c
    public static final String SEND_NOTIFICATION_ABOVE_THRESHOLD = '01';  // Valor picklist PlanComercial__c.SendNotifications__c

    // Id del tipo de registro de PlanAnual
    public ID rtPlanAnualId {
        get {
            return Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get(RT_NAME_PLAN_ANUAL)?.getRecordTypeId();
        }
    }

    // Tipos de indicadores
    public enum eIndicator {
        type_number,
        type_currency,
        type_percent
    }

    // Mapa de equivalencias entre los tipos de Indicador y el campo target del objeto KPI__c
    public static Map<eIndicator, String> mapIndicatorTypeField = new Map<eIndicator, String> {
        eIndicator.type_number => 'TargetKPINumber__c',
        eIndicator.type_currency => 'TargetKPICurrency__c',
        eIndicator.type_percent => 'TargetKPIPercent__c'
    };
    
    // Equivalencias entre la picklist PlanComercial__c.Indicator__c y el tipo de valor para el plan.
    // num = numerico / currency = moneda / percent = porcentaje
    public static Map<String, eIndicator> mapIndicatorType = new Map<String, eIndicator> {
        'PN' => eIndicator.type_number,
        'PoliciesPN' => eIndicator.type_number,
        'PoliciesInForce' => eIndicator.type_number,
        'Portfolio' => eIndicator.type_currency,
        'Ratio_PNIncrease' => eIndicator.type_percent,
        'Ratio_PoliciesPNIncreas' => eIndicator.type_percent,
        'Ratio_PoliciesInForceIncrease' => eIndicator.type_percent,
        'Ratio_PortIncrease' => eIndicator.type_percent,
        'Ratio_Claim' => eIndicator.type_percent,
        'Ratio_Retention' => eIndicator.type_percent,
        'Totaldiscount' => eIndicator.type_percent
    };

    /**
     * Constructor
     */
    public PlanComercialSelector() 
    {
        super(PlanComercial__c.getSObjectType());
    }

    /**
     * Calcula el tipo de indicador segun el indicador de plan indicado
     * 
     * @author nts (agonzalezisasi)
     * @date 20/09/2021
     * 
     * @param {String indicator} indicador del plan
     * @return {eIndicator} tipo de indicador
     */
    public static eIndicator getIndicatorType(String indicator) 
    {
        eIndicator result = eIndicator.type_number;
        if( mapIndicatorType.containsKey(indicator) ) result = mapIndicatorType.get(indicator);

        return result;
    }

    /**
     * Devuelve el nombre del campo TargetKPI... del objeto PlanComercial__c segun
     * el tipo de indicador
     * 
     * @author nts (agonzalezisasi)
     * @date 04/10/2021
     * 
     * @param {eIndicator indicator} tipo de indicador
     * @return {String} nombre del campo
     */
    public static String getTargetKPIFieldByType(eIndicator indicator)
    {
        return mapIndicatorTypeField.get(indicator);
    }

    /**
     * Convierte el mapa de tipos de indicador en un mapa de strings
     * 
     * @author nts (agonzalezisasi)
     * 
     * @return {Map<String, String>} mapa convertido
     */
    public static Map<String, String> getMapIndicatorType()
    {
        Map<String, String> result = new Map<String, String>();
        for(String key: mapIndicatorType.keySet()) {
            result.put(key, String.valueOf(mapIndicatorType.get(key)));
        }
        return result;
    }

    /**
     * Recupera los planes comerciales anuales asignados a un usuario para un año.
     * Incluye tambien los datos de los planes comerciales anuales "hijos"
     * 
     * @author nts (agonzalezisasi)
     * @date 01/10/2021
     * 
     * @param {Id assignedUserId} id de usuario
     * @param {Integer actualYear} año
     * @return {List<PlanComercial__c>} lista de planes
     */
    public List<PlanComercial__c> findAnualPlansByAssignedUserAndYear(Id assignedUserId, Integer actualYear)
    {
        List<PlanComercial__c> parentPlans = [
            SELECT id, Name, Product__c, Segment__c, Indicator__c,
                   TargetKPICurrency__c, TargetKPINumber__c, TargetKPIPercent__c, Actual_KPI__c,
                   (SELECT Id, 
                           AssignedTo__c, AssignedTo__r.Name, Intermediary__c, Intermediary__r.Name,
                           TargetKPICurrency__c, TargetKPINumber__c, TargetKPIPercent__c, Actual_KPI__c 
                   FROM ParentPlans__r)
            FROM PlanComercial__c
            WHERE RecordTypeId = :rtPlanAnualId
            AND Intermediary__c = null
            AND AssignedTo__c = :assignedUserId
            AND CALENDAR_YEAR(StartDate__c) = :actualYear
            Order By CreatedDate
        ];

        return parentPlans;
    }

    /**
     * Recupera los planes comerciales anuales "hijos" de los planes comerciales anuales dados
     * 
     * @author nts (agonzalezisasi)
     * @date 04/10/2021
     * 
     * @param {List<PlanComercial__c} plnes
     * @return {List<PlanComercial__c>} lista de planes descendientes
     */
    public List<PlanComercial__c> findAnualPlanDescendants(List<PlanComercial__c> plans)
    {
        List<PlanComercial__c> childPlans = null;

        if( plans != null && !plans.isEmpty() ) {
            childPlans = [
                SELECT Id, Name, Product__c, Segment__c, Indicator__c, 
                ParentPlan__r.Name, ParentPlan__r.Product__c, ParentPlan__r.Segment__c, ParentPlan__r.Indicator__c, 
                TargetKPICurrency__c, TargetKPINumber__c, TargetKPIPercent__c
                FROM PlanComercial__c
                WHERE RecordTypeId = :rtPlanAnualId
                AND ParentPlan__r.ParentPlan__c IN :plans
            ];
        }

        return childPlans;
    }
}
