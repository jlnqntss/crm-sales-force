@isTest
public with sharing class PlanComercialUtilTest {
    public static final Integer ACTUAL_YEAR = Date.today().year() + 1;

    @TestSetup
    static void makeData() {        
        
        TestDataFactorySDM.anualPlanSetupData(ACTUAL_YEAR, AccountsSelector.SDM_DT_EMAIL_FIELD);       
    }


    /**
     * Test del metodo que recupera los planes mensuales a partir de unos planes anuales
     *
     * @author nts (dmunoz)
     * @date 29/07/2022
     */
    @isTest
    static void getPlanesMensualesBeforeDelete() {

        List<PlanComercial__c> planesAnuales = new List<PlanComercial__c>([SELECT ID, Name, SendNotifications__c, AccumulateType__c, Startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c FROM PlanComercial__c 
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                        AND ParentPlan__c != NULL 
                                                        AND Intermediary__c = NULL
                                                        LIMIT 1]);

        Test.startTest();
        PlanComercialSelector planSel = new PlanComercialSelector();
        List<Plancomercial__c> plans = planSel.findMensualPlans(planesAnuales);
        Test.stopTest();

        // Comprobamos el resultado del test
        System.assertEquals(0, plans.size(), 'Deberia haber 0 planes mensuales');
    }
}
