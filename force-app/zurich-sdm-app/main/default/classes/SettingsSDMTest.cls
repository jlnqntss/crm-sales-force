/**
 * Test para la clase SettingsSDM
 *
 * @author nts (agonzalezisasi)
 * @date 16/11/2021
 */
@isTest
private class SettingsSDMTest 
{
    public static final String SETUP_PARAM_APINAME = 'testParam';
    public static final String SETUP_PARAM_VALUE = 'testValue';

    /**
     * Test del metodo que recupera los parametros globales de configuracion
     *
     * @author nts (agonzalezisasi)
     * @date 16/11/2021
     */
    @isTest
    static void getSetupParameter()
    {
        Test.startTest();
        SettingsSDM settings = new SettingsSDM();
        settings.testSetupParamValue = SETUP_PARAM_VALUE;
        String result = settings.getSetupParameter(SETUP_PARAM_APINAME, 'noValue');
        Test.stopTest();

        System.assertEquals(SETUP_PARAM_VALUE, result, 'El valor deberia ser ' + SETUP_PARAM_VALUE);
    }
    
    /**
     * Test del metodo que recupera los indicadores configurados
     *
     * @author nts (agonzalezisasi)
     * @date 16/11/2021
     */
    @isTest
    static void getSettingsIndicator()
    {
        Test.startTest();
        SettingsSDM settings = new SettingsSDM();
        List<SDMCommercialPlan__mdt> testSettingsIndicator = new List<SDMCommercialPlan__mdt>();
        testSettingsIndicator.add(TestDataFactorySDM.generateSDMSettingsPlan(
            'PN', PlanComercialSDM.SETTINGS_CALCULATION_TYPE_SUM, 'PN__c', null));
        Map<String, SDMCommercialPlan__mdt> result = settings.getSettingsIndicator(testSettingsIndicator);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Deberia recuperar indicadores');
        System.assertEquals(false, result.isEmpty(), 'Deberia haber algun indicador');
    }
   
    /**
     * Test del metodo que recupera las relaciones de ATM y la cuenta
     *
     * @author nts (agonzalezisasi)
     * @date 16/11/2021
     */
    @isTest
    static void getAccountRolesWithIntermediaryFields()
    {
        Test.startTest();
        SettingsSDM settings = new SettingsSDM();
        List<SDMAccountTeamRole__mdt> testSettingsATM = TestDataFactorySDM.getSDMSettingsATM(
            SettingsSDM.ATM_ROL_TERRITORY, AccountsSelector.SDM_DT_EMAIL_FIELD
        );
        List<SDMAccountTeamRole__mdt> result = settings.getAccountRolesWithIntermediaryFields(
            testSettingsATM
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Deberia recuperar account rols');
        System.assertEquals(false, result.isEmpty(), 'Deberia haber algun account rol');
    }

    /**
     * Test del metodo que recupera las etiquetas de los roles configurados de los Account Team Members
     *
     * @author nts (agonzalezisasi)
     * @date 16/11/2021
     */
    @isTest
    static void getATMRoleLabel()
    {
        Test.startTest();
        SettingsSDM settings = new SettingsSDM();
        String result = settings.getATMRoleLabel(SettingsSDM.ATM_ROL_TERRITORY);
        Test.stopTest();
        
        System.assertEquals(true, String.isNotBlank(result), 'Deberia recuperar etiqueta para el rol ' + SettingsSDM.ATM_ROL_TERRITORY);
    }
   
    /**
     * Test del metodo que recupera las relaciones de ATM y la cuenta
     *
     * @author nts (agonzalezisasi)
     * @date 16/11/2021
     */
    @isTest
    static void getContactRolesWithIntermediaryFields()
    {
        Test.startTest();
        SettingsSDM settings = new SettingsSDM();
        String roleLabelMain = settings.getACRRoleLabel(SettingsSDM.ACR_ROL_MAINEMAIL);
        // Preparamos la configuracion para el campo que nos interesa
        List<SDMAccountContactRelation__mdt> testSettingsACR = TestDataFactorySDM.getSDMSettingsACR(
            roleLabelMain, AccountsSelector.SDM_MAINEMAIL_FIELD, TestDataFactorySDM.MAINEMAIL_TEXT
        );
        List<SDMAccountContactRelation__mdt> result = settings.getContactRolesWithIntermediaryFields(
            testSettingsACR
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Deberia recuperar relaciones account contact');
        System.assertEquals(false, result.isEmpty(), 'Deberia haber alguna relacion account contact');
    }

    /**
     * Test del metodo que recupera las etiquetas de los roles configurados de los AccountContactRelations
     *
     * @author nts (agonzalezisasi)
     * @date 16/11/2021
     */
    @isTest
    static void getACRRoleLabel()
    {
        Test.startTest();
        SettingsSDM settings = new SettingsSDM();
        String result = settings.getACRRoleLabel(SettingsSDM.ACR_ROL_MAINEMAIL);
        Test.stopTest();
        
        System.assertEquals(true, String.isNotBlank(result), 'Deberia recuperar etiqueta para el rol ' + SettingsSDM.ACR_ROL_MAINEMAIL);
    }
}
