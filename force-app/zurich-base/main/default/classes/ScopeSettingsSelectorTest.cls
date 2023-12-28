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
        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');

        Test.startTest();
        List<Scope_Setting__mdt> scopeSettings = new ScopeSettingsSelector().selectByBusinessCode(new Set<String> {scopeSettingsList.get(0).BusinessCode__c});
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
