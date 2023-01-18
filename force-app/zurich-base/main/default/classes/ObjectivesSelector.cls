/**
 * Clase Apex que encapsula las consultas a BBDD a realizar sobre el objeto Objective__c
 */
public with sharing class ObjectivesSelector {

    //#region Record Types

    public static final String RT_NAME_OBJECTIVES = 'Objectives';
    public static final String RT_NAME_FREQUENCY_NOTIFICATIONS = 'FrequencyNotifications';

    public static Id rtObjectives
    {
        get
        {
            return Schema.SObjectType.Objective__c.getRecordTypeInfosByDeveloperName().get(RT_NAME_OBJECTIVES)?.getRecordTypeId();
        }
    }

    public static Id rtFrequencyNotifications
    {
        get
        {
            return Schema.SObjectType.Objective__c.getRecordTypeInfosByDeveloperName().get(RT_NAME_FREQUENCY_NOTIFICATIONS)?.getRecordTypeId();
        }
    }

    //#endregion

    private static String getFieldListString() {
        return ' Id, Year__c, Indicator__c, Segment__c, Product__c, Zone__c, January__c, February__c, March__c, April__c, May__c, June__c, July__c, August__c, September__c, October__c, November__c, December__c, Active__c, ExternalId__c ';
    }
    
    private static String getSObjectName() {
        return ' Objective__c ';
    }

    private static String getOrderBy(){
        return ' Indicator__c, Segment__c, Product__c, Zone__c ASC ';
    }

    public ObjectivesSelector() {}

    /**
     * Obtiene un listado de Objetivos dado un año ordenados de forma ascendente por Indicador y Segmento
     * @param year: String con el año a consultar
     * @return Listado de objetivos
     * @author dmunoz
     * @date 06/07/2022
     * @change amiranda 04/01/2023 Se añade el filtra de tipo de registro 'Objecitves' en la query
     */
    public static List<Objective__c> selectObjectivesByYear(String year) {
        //Devolver lista vacía
        if (year == null || String.isEmpty(year)) {
            return new List<Objective__c>();
        }

        String query = String.format(
            'SELECT {0} FROM {1} WHERE Year__c =: year AND RecordTypeId = :rtObjectives ORDER BY {2}',
            new List<String> {getFieldListString(), getSObjectName(), getOrderBy()}
            );
        System.debug('query ' + query + 'year ' + year);

        return (List<Objective__c>) Database.query(query);
    }

    /**
    * @description Método que recupera frecuencia de notificaciones. Es un registro 
    * único para el tipo de registro FrequencyNotifications del objeto Objective__c, 
    * por lo tanto la lista solo tendrá un elemento.
    * @author amiranda
    * @date 29-12-2022 
    * @return List<Objective__c> Lista con el único registro disponible para la frecuencia de notificaciones
    **/
    public static List<Objective__c> selectFrequencyNotification()
    {
        List<Objective__c> frequencyNotifications = [SELECT DaysLeft__c 
                                                    FROM Objective__c 
                                                    WHERE RecordTypeId = :rtFrequencyNotifications];

        return frequencyNotifications;
    }

    /**
     * Obtiene un listado de Objetivos activos según indicadores en externalId
     * @param year: String con el año a consultar
     * @return Listado de objetivos
     * @author dmunoz
     * @date 06/07/2022
     * @change amiranda 04/01/2023 Se añade el filtra de tipo de registro 'Objecitves' en la query
     * 
     */
    public static List<Objective__c> selectObjectivesByExternalId(Set<String> externalIdList) {
        //Devolver lista vacía
        if (externalIdList == null || externalIdList.isEmpty()) {
            return new List<Objective__c>();
        }

        String query = String.format(
            'SELECT {0} FROM {1} WHERE ExternalId__c in :externalIdList AND Active__c = true AND RecordTypeId = :rtObjectives',
            new List<String> {getFieldListString(), getSObjectName()}
            );
        System.debug('query ' + query);

        return (List<Objective__c>) Database.query(query);
    }
}
