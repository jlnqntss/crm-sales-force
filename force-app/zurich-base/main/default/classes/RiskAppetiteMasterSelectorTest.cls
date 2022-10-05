@IsTest
public with sharing class RiskAppetiteMasterSelectorTest {
    @TestSetup
    static void makeData()
    {
        String SicCode = '1100';
        MaestroApetito__c maestro1 = new MaestroApetito__c();
        maestro1.SIC__c = SicCode;
        maestro1.CodigoProducto__c = '0001';
        maestro1.CodigoActividad__c = '0010';
        maestro1.ApetitoRiesgo__c = 'Preferente';
        maestro1.UsoExplosivos__c = true;
        maestro1.ConExistenciaLiquidosInflamables__c = false;
        maestro1.ConFoamizado__c = false;
        maestro1.ConMateriasPlasticasEspumosas__c = false;
        maestro1.ConNitratos__c = false;
        maestro1.ConTapizados__c = false;
        maestro1.ConSecaderoMadera__c = false;
        maestro1.Espumosos__c = false;
        maestro1.ConAspiracionAutomatica__c = false;
        maestro1.ConRecubrimiento__c = false;
        maestro1.ConPlanchasCombustibles__c = false;
        maestro1.ConFabricacionDeEnvases__c = false;
        maestro1.ConDestilacion__c = false;
        insert maestro1;

        MaestroApetito__c maestro2 = new MaestroApetito__c();
        maestro2.SIC__c = SicCode;
        maestro2.CodigoProducto__c = '0002';
        maestro2.CodigoActividad__c = '0020';
        maestro2.ApetitoRiesgo__c = 'No preferente';
        maestro2.UsoExplosivos__c = true;
        maestro2.ConExistenciaLiquidosInflamables__c = false;
        maestro2.ConFoamizado__c = false;
        maestro2.ConMateriasPlasticasEspumosas__c = false;
        maestro2.ConNitratos__c = false;
        maestro2.ConTapizados__c = false;
        maestro2.ConSecaderoMadera__c = false;
        maestro2.Espumosos__c = false;
        maestro2.ConAspiracionAutomatica__c = false;
        maestro2.ConRecubrimiento__c = false;
        maestro2.ConPlanchasCombustibles__c = false;
        maestro2.ConFabricacionDeEnvases__c = false;
        maestro2.ConDestilacion__c = false;
        insert maestro2;

        MaestroApetito__c maestro3 = new MaestroApetito__c();
        maestro3.SIC__c = SicCode;
        maestro3.CodigoProducto__c = '0001';
        maestro3.CodigoActividad__c = '0020';
        maestro3.ApetitoRiesgo__c = 'Fuera de apetito';
        maestro3.UsoExplosivos__c = true;
        maestro3.ConExistenciaLiquidosInflamables__c = false;
        maestro3.ConFoamizado__c = false;
        maestro3.ConMateriasPlasticasEspumosas__c = false;
        maestro3.ConNitratos__c = false;
        maestro3.ConTapizados__c = false;
        maestro3.ConSecaderoMadera__c = false;
        maestro3.Espumosos__c = false;
        maestro3.ConAspiracionAutomatica__c = false;
        maestro3.ConRecubrimiento__c = false;
        maestro3.ConPlanchasCombustibles__c = false;
        maestro3.ConFabricacionDeEnvases__c = false;
        maestro3.ConDestilacion__c = false;
        insert maestro3;

        MaestroApetito__c maestro4 = new MaestroApetito__c();
        maestro4.SIC__c = SicCode;
        maestro4.CodigoProducto__c = '0001';
        maestro4.CodigoActividad__c = '0020';
        maestro4.ApetitoRiesgo__c = 'Fuera de apetito';
        maestro4.UsoExplosivos__c = false;
        maestro4.ConExistenciaLiquidosInflamables__c = false;
        maestro4.ConFoamizado__c = false;
        maestro4.ConMateriasPlasticasEspumosas__c = false;
        maestro4.ConNitratos__c = false;
        maestro4.ConTapizados__c = false;
        maestro4.ConSecaderoMadera__c = false;
        maestro4.Espumosos__c = false;
        maestro4.ConAspiracionAutomatica__c = false;
        maestro4.ConRecubrimiento__c = false;
        maestro4.ConPlanchasCombustibles__c = false;
        maestro4.ConFabricacionDeEnvases__c = false;
        maestro4.ConDestilacion__c = false;
        insert maestro4;
    }

    /**
     * Método que testea el método que recupera todos los registros de MaestroApetito__c
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     */
    @IsTest
    static void test_findAllMasters_OK()
    {
        
        test.startTest();
        List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findAllMasters();
        test.stopTest();

        system.assertEquals(4, records.size());
    }

    /**
     * Método que testea el método que recupera todos los registros de MaestroApetito__c en base al SIC
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     */
    @IsTest
    static void test_findProductsBySicCode_OK()
    {
        
        test.startTest();
        List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findProductsBySicCode('1100');
        test.stopTest();

        system.assertEquals(4, records.size());
    }

    /**
     * Método que testea el método que recupera todos los registros de MaestroApetito__c en base a SIC y ramo
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     */
    @IsTest
    static void test_findCommercialActivitiesByProductCode_OK()
    {
        
        test.startTest();
        List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findCommercialActivitiesByProductCode('1100', '0001');
        test.stopTest();

        system.assertEquals(3, records.size());
    }

    /**
     * Método que testea el método que recupera todos los registros de MaestroApetito__c en base a SIC, ramo y actividad comercial
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     */
    @IsTest
    static void test_findTechPolicyByCommercialActivity_OK()
    {
        
        test.startTest();
        List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findTechPolicyByCommercialActivity('1100', '0001', '0020');
        test.stopTest();

        system.assertEquals(2, records.size());
    }

    /**
     * Método que testea el método que recupera un registro en función a un json de entrada
     * @author jjuaristi@seidor.es
     * @date 05/10/2022
     */
    @IsTest
    static void test_getQueryFindTechnicalPolicy_OK()
    {
        List<String> fields = new List<String>{ 
            'UsoExplosivos__c',
            'ConExistenciaLiquidosInflamables__c',
            'ConFoamizado__c',
            'ConMateriasPlasticasEspumosas__c',
            'ConNitratos__c',
            'ConTapizados__c',
            'ConSecaderoMadera__c',
            'Espumosos__c',
            'ConAspiracionAutomatica__c',
            'ConRecubrimiento__c',
            'ConPlanchasCombustibles__c',
            'ConFabricacionDeEnvases__c',
            'ConDestilacion__c'
        };
        List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findTechPolicyByCommercialActivity('1100', '0001', '0020');
        MaestroApetito__c auxRecord = records[1];
        test.startTest();
        MaestroApetito__c foundRecord =  new RiskAppetiteMasterSelector().getQueryFindTechnicalPolicy(auxRecord, fields);
        test.stopTest();

        for(String field : fields)
        {
            system.assertEquals(auxRecord.get(field), foundRecord.get(field));
        }
    }
}
