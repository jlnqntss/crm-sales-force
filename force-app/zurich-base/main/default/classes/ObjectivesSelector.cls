/**
 * Clase Apex que encapsula las consultas a BBDD a realizar sobre el objeto Objective__c
 */
public with sharing class ObjectivesSelector {

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
     */
    public static List<Objective__c> selectObjectivesByYear(String year) {
        //Devolver lista vacía
        if (year == null || String.isEmpty(year)) {
            return new List<Objective__c>();
        }

        String query = String.format(
            'SELECT {0} FROM {1} WHERE Year__c =: year ORDER BY {2}',
            new List<String> {getFieldListString(), getSObjectName(), getOrderBy()}
            );
        System.debug('query ' + query + 'year ' + year);

        return (List<Objective__c>) Database.query(query);
    }

    /**
     * Obtiene un listado de Objetivos activos según indicadores en externalId
     * @param year: String con el año a consultar
     * @return Listado de objetivos
     * @author dmunoz
     * @date 06/07/2022
     */
    public static List<Objective__c> selectObjectivesByExternalId(Set<String> externalIdList) {
        //Devolver lista vacía
        if (externalIdList == null || externalIdList.isEmpty()) {
            return new List<Objective__c>();
        }

        String query = String.format(
            'SELECT {0} FROM {1} WHERE ExternalId__c in :externalIdList AND Active__c = true',
            new List<String> {getFieldListString(), getSObjectName()}
            );
        System.debug('query ' + query);

        return (List<Objective__c>) Database.query(query);
    }
}
