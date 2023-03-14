@isTest
public with sharing class PlanesComercialesAnualesUtilTest {


    /**
     * generar registros retencion anuales desde mapa de mapas de objetivo
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void testGenerateAnualPlansFromObjectivesMap_OK() {
        Map<String, Map<String, Objective__c>> objectivesMap = new Map<String, Map<String, Objective__c>>();
        Map<String, Objective__c> objectivesRetentionMap = new Map<String, Objective__c>();
        Map<String, Objective__c> objectivesAccidentMap = new Map<String, Objective__c>();

        Objective__c obj = TestDataFactory.generateObjective(2022, 'Ratio_Retention', 'Particulares', 'Autos', '11 BARCELONA', 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
        Objective__c obj2 = TestDataFactory.generateObjective(2022, 'Ratio_Claim', 'Particulares', 'Autos', '11 BARCELONA', 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
        
        objectivesRetentionMap.put(getExternalId(obj), obj);
        objectivesAccidentMap.put(getExternalId(obj2), obj2);

        objectivesMap.put('RetentionObjectives', objectivesRetentionMap);
        objectivesMap.put('AccidentObjectives', objectivesAccidentMap);

        List<PlanComercial__c> resultAnualPlan = PlanesComercialesAnualesUtil.generateAnualPlansFromObjectives(objectivesMap, new List<String>());

        System.assertEquals(true, resultAnualPlan.size() != 0, 'Debe haber registros generados');
    }

    /**
     * generar registros retencion anuales desde mapa de objetivo
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void testGenerateAnualPlansFromObjectives_OK() {
        Map<String, Objective__c> objectivesRetentionMap = new Map<String, Objective__c>();

        Objective__c obj = TestDataFactory.generateObjective(2022, 'Ratio_Retention', 'Particulares', 'Autos', '11 BARCELONA', 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
        
        objectivesRetentionMap.put(getExternalId(obj), obj);

        List<PlanComercial__c> resultAnualPlan = PlanesComercialesAnualesUtil.generateAnualPlansFromUpdateObjectives(objectivesRetentionMap, new List<String>());

        System.assertEquals(true, resultAnualPlan.size() != 0, 'Debe haber registros generados');
    }


    private static String getExternalId(Objective__c obj) {
        String result = obj.Year__c + '-' + obj.Indicator__c + '-' + obj.Segment__c + '-' + obj.Product__c + '-' + obj.Zone__c;
        return result;
    }

}