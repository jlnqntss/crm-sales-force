@isTest
private class ScopeSettingsSelectorTest
{
    @isTest
    static void test_selectAll()
    {
        Test.startTest();
        List<Scope_Setting__mdt> scopeSettings = new ScopeSettingsSelector().selectAll();
        Test.stopTest();

        System.assert (!scopeSettings.isEmpty(), 'No se han recuperado los metadatos de scope');
    }

    @isTest
    static void test_selectByBusinessCode_OK()
    {
        Test.startTest();
        List<Scope_Setting__mdt> scopeSettings = new ScopeSettingsSelector().selectByBusinessCode(new Set<String> {'3200012477'});
        Test.stopTest();

        System.assert (!scopeSettings.isEmpty(), 'No se han recuperado los metadatos de scope');
    }

    @isTest
    static void test_selectByBusinessCode_Empty()
    {
        Test.startTest();
        List<Scope_Setting__mdt> scopeSettings = new ScopeSettingsSelector().selectByBusinessCode(null);
        Test.stopTest();

        System.assert (scopeSettings.isEmpty(), 'Se han recuperado los metadatos de scope y no deberia');
    }


}
