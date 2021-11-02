/**
 * Test para la clase KPIsSelector
 *
 * @author nts (agonzalezisasi)
 * @date 28/07/2021
 */
@isTest
private class KPIsSelectorTest 
{
    /**
     * Metodo comun para todas los metodos de test. Inicializa los datos de prueba
     *
     * @author nts (agonzalezisasi)
     * @date 29/06/2021
     */
    @TestSetup
    static void makeData() 
    {
        // Creacion de los Mediadores (3)
        List<Account> intermediaries = TestDataFactory.generateAccounts(
            TestDataFactorySDM.ACCOUNT_LEGAL_ENTITY, AccountsSelector.RT_NAME_INTERMEDIARY, 3
        );
        insert intermediaries;

        // Creacion de los KPIs (3x2)
        List<KPI__c> kpis = TestDataFactorySDM.generateKPIs(intermediaries, 2);
        insert kpis;
    }

    /**
     * Test del metodo que recupera los KPIs dados unos mediadores
     *
     * @author nts (agonzalezisasi)
     * @date 28/07/2021
     */
    @isTest
    static void findByIntermediaryIds()
    {
        List<Account> intermediaries = [SELECT Id FROM Account];
        System.assertEquals(3, intermediaries.size(), 'Deberia haber 3 mediadores');

        Map<ID, Account> mapIntermediaries = new Map<ID, Account>(intermediaries);

        Test.startTest();
        List<KPI__c> kpis = new KPIsSelector().findByIntermediaryIds(
            new List<ID>(mapIntermediaries.keySet()), 
            new List<string>{KPIsSelector.TEMPORALIDAD_Month},
            '2021', '9',
            new Set<String>{'Intermediary__c'}
        );
        Test.stopTest();

        System.assertEquals(6, kpis.size(), 'Deberia haber 6 KPIs');
    }

    /**
     * Test del mentodo que recupera el ultimo mes que tiene KPIs anuales para el año en curso
     * 
     * @author nts (agonzalezisasi)
     * @date 28/10/2021
     */
    @isTest
    static void findThisYearsLastMonth()
    {
        List<Account> intermediaries = [SELECT Id FROM Account];
        System.assertEquals(3, intermediaries.size(), 'Deberia haber 3 mediadores');
        
        // Creacion de los KPIs (3x1)
        List<KPI__c> kpis = TestDataFactorySDM.generateKPIs(intermediaries, 1);
        kpis[0].CalcMonth__c = '4';
        kpis[0].Temporalidad__c = KPIsSelector.TEMPORALIDAD_YTD;
        kpis[1].CalcMonth__c = '5';
        kpis[1].Temporalidad__c = KPIsSelector.TEMPORALIDAD_YTD;
        kpis[2].CalcMonth__c = '6';
        kpis[2].Temporalidad__c = KPIsSelector.TEMPORALIDAD_YTD;
        insert kpis;

        Test.startTest();
        String thisMonth = (new KPIsSelector()).findThisYearsLastMonth();
        Test.stopTest();

        System.assertEquals('6', thisMonth, 'Deberia ser 6');
    }
}
