/**
 * @description       : clase test para globalConfigUtil
 * @author            : Olalla Iglesias
 * @group             :
 * @last modified on  : 21-05-2024
 * @last modified by  : oiglesias
 **/
@isTest
private with sharing class GlobalConfigUtilTest
{
    @isTest
    private static void testGetGlobalConfigurationValues()
    {
        
        Test.startTest();
        Map<String, String> configValues = GlobalConfigUtil.getGlobalConfigurationValues();
        Test.stopTest();

        //Check results
        System.assertEquals('USPInquiry', configValues.get('Case_RecordType_USP'));
        System.assertEquals('365', configValues.get('Query_Filter_Days_365'));
    }
    
    @isTest
    static void testGetGlobalConfigurationValue() {
        
        Test.startTest();
        String configValue = GlobalConfigUtil.getGlobalConfigurationValue('Case_RecordType_USP');
        Test.stopTest();

        //Check results
        System.assertEquals('USPInquiry', configValue);
    }
    
    @IsTest
    static void testGetGlobalConfigurationValueId() {

        Organization org = [SELECT Id FROM Organization];
        String orgId = org.Id;
        
        Test.startTest();
        String configValueId = GlobalConfigUtil.getGlobalConfigurationValueId('Instances_Id');
        Test.stopTest();

        //Check results
        System.assertEquals(orgId, configValueId);
    }

    /**
     * Testea los metodos getDefaultObjectRetention y getObjectRetention
     *
     * @author mario.navarro@seidor.com
     * @date 27/05/2024
     */
    @IsTest
    static void test_getDefaultObjectRetention()
    {
        Integer retention = null;
        Test.startTest();
        retention = GlobalConfigUtil.getDefaultObjectRetention(SendDocCUInfo__c.getSObjectType().toString());
        try
        {
            GlobalConfigUtil.getDefaultObjectRetention(null);
            Assert.fail('Exception should be thrown');
        }
        catch (IllegalArgumentException iae)
        {}
        Test.stopTest();

        Global_Configuration__mdt sendDocCUInfoConfig = [SELECT Value__c 
            FROM Global_Configuration__mdt
            WHERE DeveloperName = 'SendDocCUInfoDefault'
        ];
        Assert.areEqual(Integer.valueOf(sendDocCUInfoConfig.Value__c), retention);
    }

}