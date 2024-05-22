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
}