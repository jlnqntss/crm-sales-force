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
    public static final String RT_NAME_PLAN_MENSUAL = 'MensualPlan'; // Recordtype PlanComercial__c=>PlanMensual

    public static final String SEGMENT_ALL = 'Todos'; // Valor picklist PlanComercial__c.Segment__c
    public static final String PRODUCT_ALL = 'Todos'; // Valor picklist PlanComercial__c.Product__c
    public static final String ACCUMULATE_TYPE_YRD = 'YTD'; // Valor picklist PlanComercial__c.AccumulateType__c
    public static final String ACCUMULATE_TYPE_MONTH = 'Mensual'; // Valor picklist PlanComercial__c.AccumulateType__c
    public static final String INDICATOR_PN = 'PN';  // Valor picklist PlanComercial__c.Indicator__c
    public static final String ZONE_11_BARCELONA = '11 BARCELONA';  // Valor picklist PlanComercial__c.Zone__c
    public static final String ZONE_ALL = 'Todos';  // Valor picklist PlanComercial__c.Zone__c
    public static final String SEND_NOTIFICATION_ABOVE_THRESHOLD = '01';  // Valor picklist PlanComercial__c.SendNotifications__c

    // Id del tipo de registro de PlanAnual
    public ID rtPlanAnualId {
        get {
            return Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get(RT_NAME_PLAN_ANUAL)?.getRecordTypeId();
        }
    }

    // Id del tipo de registro de PlanMensual
    public ID rtPlanMensualId {
        get {
            return Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get(RT_NAME_PLAN_MENSUAL)?.getRecordTypeId();
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
        'Totaldiscount' => eIndicator.type_percent,
        'APES' => eIndicator.type_currency
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
                   AssignedTo__c, OwnerId, Zone__c,
                   (SELECT Id, 
                           AssignedTo__c, AssignedTo__r.Name, Intermediary__c, Intermediary__r.Name,
                           TargetKPICurrency__c, TargetKPINumber__c, TargetKPIPercent__c, Actual_KPI__c, Zone__c
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
     * Recupera los planes comerciales anuales "hijos" de los planes comerciales anuales dados.
     * Ignorandose a si mismos si fueran "hijos" de algun otro plan de la lista.
     * 
     * @author nts (agonzalezisasi)
     * @date 04/10/2021
     * 
     * @param {List<PlanComercial__c} plnes
     * @return {List<PlanComercial__c>} lista de planes descendientes
     */
    public List<PlanComercial__c> findAnnualPlanDescendants(List<PlanComercial__c> plans)
    {
        List<PlanComercial__c> childPlans = null;

        if( plans != null && !plans.isEmpty() ) {
            childPlans = [
                SELECT Id, Name, Product__c, Segment__c, Indicator__c, 
                ParentPlan__r.Name, ParentPlan__r.Product__c, ParentPlan__r.Segment__c, ParentPlan__r.Indicator__c, 
                TargetKPICurrency__c, TargetKPINumber__c, TargetKPIPercent__c
                FROM PlanComercial__c
                WHERE RecordTypeId = :rtPlanAnualId
                AND ParentPlan__c IN :plans
                AND Id NOT IN :plans
            ];
        }

        return childPlans;
    }

    /**
     * Recupera los planes comerciales anuales que tienen los mediadores y usuarios dados
     * 
     * @author nts (agonzalezisasi)
     * @date 11/10/2021
     * 
     * @param {List<Id> intermediaries} lista de ids de mediadores
     * @return {List<Id> users} lista ids de usuarios
     */
    public List<PlanComercial__c> findAnnualPlansByIntermediariesAndUsers(Set<Id> intermediaries, Set<Id> users)
    {
        List<PlanComercial__c> result = null;

        if( intermediaries != null && !intermediaries.isEmpty() && users != null && !users.isEmpty() ) {
            this.baseQuery.selectFields (
                new List<Schema.SObjectField> {
                    PlanComercial__c.Id,
                    PlanComercial__c.Intermediary__c,
                    PlanComercial__c.AssignedTo__c
                }
            );
            
            this.baseQuery.addConditionEq(PlanComercial__c.RecordTypeId, rtPlanAnualId);
            this.baseQuery.addConditionIn(PlanComercial__c.Intermediary__c, intermediaries);
            this.baseQuery.addConditionIn(Plancomercial__c.AssignedTo__c, users);

            result = (List<PlanComercial__c>) this.baseQuery.run();
        }

        return result;
    }

    /**
     * Recupera los planes comerciales mensuales hijos
     * 
     * @author nts (dmunoz)
     * @date 25/07/2022
     * 
     * @param {List<PlanComercial__c} plnes
     * @return {List<PlanComercial__c>} lista de planes mensuales
     */
    public List<PlanComercial__c> findMensualPlans(List<PlanComercial__c> plans) {
        List<PlanComercial__c> childPlans = new List<PlanComercial__c>();

        if( plans != null && !plans.isEmpty() ) {
            childPlans = [
                SELECT Id, TargetKPIPercent__c, TargetKPINumber__c, TargetKPICurrency__c, Indicator__c, Segment__c, Product__c, EndDate__c, ParentPlan__r.TargetKPINumber__c, ParentPlan__r.EndDate__c, ParentPlan__r.SentNotifications__c,
                            ParentPlan__r.TargetKPIPercent__c, ParentPlan__r.TargetKPICurrency__c, ParentPlan__r.Actual_KPI__c, Zone__c
                FROM PlanComercial__c
                WHERE ParentPlan__c IN :plans
                AND RecordTypeId = :rtPlanMensualId
                
            ];
        }

        return childPlans;
    }

    /**Recuperar todos los campos de plan comercial anual (RN y Mediador) según indicadores y año de objetivo además de related email coincida con los de la metadata
     * @author nts (dmunoz)
     * @date 25/07/2022
     * 
     * @param {Set<String} indicadores
     * @param {Set<String} segmentos
     * @param {Set<String} productos
     * @param {Set<String} zonas
     * @param year año del plan
     * @return {List<PlanComercial__c>} lista de planes anuales
     */
    public List<PlanComercial__c> findAnualPlanByObjectiveIndicators(Set<String> indicatorSet, Set<String> segmentSet, Set<String> productSet, Set<String> zoneSet, Set<Integer> year) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();

        if( indicatorSet != null && !indicatorSet.isEmpty() && segmentSet != null && !segmentSet.isEmpty() && productSet != null && !productSet.isEmpty() && year != null) {
            result = [
                SELECT Id, AccumulateType__c, Actual_KPI__c, AssignedTo__c, Completed__c, Contact__c, Description__c, EndDate__c, FollowUp__c, Indicator__c, Intermediary__c,
                Month__c, Notified__c, ParentPlan__c, Priority__c, Product__c, RecordTypeId, Segment__c, SendNotifications__c, SentNotifications__c, StartDate__c, 
                Name, TargetKPIPercent__c, TargetKPINumber__c, TargetKPICurrency__c, OwnerId, Zone__c, ParentPlan__r.OwnerId
                FROM PlanComercial__c
                WHERE RecordTypeId = :rtPlanAnualId
                AND AssignedTo__r.UserRole.DeveloperName = 'SDM_RN'
                AND Indicator__c IN :indicatorSet
                AND Product__c IN :productSet
                AND Segment__c IN :segmentSet
                AND Zone__c IN :zoneSet
                AND CALENDAR_YEAR(StartDate__c) IN :year
                AND AssignedTo__r.Email IN :getMetadataEmails()        
            ];
        }

        return result;
    }

    /**Recuperar todos los campos de plan comercial mensual según indicadores y año de objetivo
     * @author nts (dmunoz)
     * @date 25/07/2022
     * 
     * @param {Set<String} indicadores
     * @param {Set<String} segmentos
     * @param {Set<String} productos
     * @param year año del plan
     * @return {List<PlanComercial__c>} lista de planes anuales
     */
    public List<PlanComercial__c> findMensualPlanByObjectiveIndicators(Set<String> indicatorSet, Set<String> segmentSet, Set<String> productSet, Set<String> zoneSet, Set<Integer> year) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();

        if( indicatorSet != null && !indicatorSet.isEmpty() && segmentSet != null && !segmentSet.isEmpty() && productSet != null && !productSet.isEmpty() && zoneSet != null &&
         !zoneSet.isEmpty() && year != null && !year.isEmpty()) {
            result = [
                SELECT Id, AccumulateType__c, Actual_KPI__c, AssignedTo__c, Completed__c, Contact__c, Description__c, EndDate__c, FollowUp__c, Indicator__c, Intermediary__c,
                Month__c, Notified__c, ParentPlan__c, Priority__c, Product__c, RecordTypeId, Segment__c, SendNotifications__c, SentNotifications__c, StartDate__c, 
                Name, TargetKPIPercent__c, TargetKPINumber__c, TargetKPICurrency__c, ParentPlan__r.TargetKPINumber__c, ParentPlan__r.TargetKPIPercent__c, ParentPlan__r.TargetKPICurrency__c, 
                ParentPlan__r.EndDate__c, ParentPlan__r.SentNotifications__c, ParentPlan__r.Actual_KPI__c, ParentPlan__r.Zone__c, Zone__c

                FROM PlanComercial__c
                WHERE RecordTypeId = :rtPlanMensualId
                AND Indicator__c IN :indicatorSet
                AND Product__c IN :productSet
                AND Segment__c IN :segmentSet
                AND Zone__c IN :zoneSet
                AND CALENDAR_YEAR(StartDate__c) IN :year                
            ];
        }

        return result;
    }

    /**Recuperar los email del usuario asignado de unos planes dados
     * @author nts (dmunoz)
     * @date 23/08/2022
     * 
     * @param {List<String} planComercialList
     * @return {Map<Id, PlanComercial__c>} mapa con el par id, email
     */
     public Map<Id, PlanComercial__c> findAssignedToDataFromPC(List<PlanComercial__c> planComercialList) {
        Map<Id, PlanComercial__c> result = new Map<Id, PlanComercial__c>();

        if (planComercialList != null && !planComercialList.isEmpty()) {
            result = new Map<Id, PlanComercial__c>([SELECT Id, AssignedTo__r.Email, AssignedTo__r.UserRole.DeveloperName FROM PlanComercial__c WHERE Id IN :planComercialList]);
        }

        return result;
     }

     /**
     * Lista de email contenido en la metadata
     * @return List<String>
     * @author dmunoz
     * @date 22/08/2022
     */
    private static List<String> getMetadataEmails() {
        String mensualPlanValidEmails = 'MensualPlanValidEmails';
        AdminSetupParameter__mdt adminSetupParameterMDT = AdminSetupParameter__mdt.getInstance(mensualPlanValidEmails);
        
        List<String> result = new List<String>();
        String metadataEmailsRaw = adminSetupParameterMDT.Value__c;

        if (String.isNotEmpty(metadataEmailsRaw)) {
            result = new List<String>(metadataEmailsRaw.split(','));
        }

        System.debug('selector planes getMetadataEmails ' + result);
        return result;
    }

    /**Recuperar los planes mensuales para borrar a partir de una fecha dada
     * @author nts (dmunoz)
     * @date 23/08/2022
     * 
     * @param {List<String} planComercialList
     * @return {Map<Id, PlanComercial__c>} mapa con el par id, email
     */
    public List<PlanComercial__c> findMensualPlanToDeleteByMaxDate(Date maxDate) {
        List<PlanComercial__c> result = new List<PlanComercial__c>();

        if (maxDate != null) {
            result = new List<PlanComercial__c>([SELECT Id FROM PlanComercial__c where RecordTypeId =: rtPlanMensualId AND EndDate__c < :maxDate]);
        }

        return result;
    }


    /**Recuperar el owner id del parent de los planes dados
     * @author nts (dmunoz)
     * @date 23/08/2022
     * 
     * @param {List<String} planComercialList
     * @return {Map<Id, PlanComercial__c>} mapa con el par id, email
     */
    public Map<Id, PlanComercial__c> getParentOwnerId(List<PlanComercial__c> planesComerciales) {
        Map<Id, PlanComercial__c> result = new Map<Id, PlanComercial__c>();

        if (planesComerciales != null && !planesComerciales.isEmpty()) {
            result = new  Map<Id, PlanComercial__c>([SELECT Id, ParentPlan__r.OwnerId FROM PlanComercial__c where Id in :planesComerciales]);
        }

        return result;
    }
}