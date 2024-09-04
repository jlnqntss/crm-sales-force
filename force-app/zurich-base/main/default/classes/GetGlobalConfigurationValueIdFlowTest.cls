/**
 * @description       : clase test para GetGlobalConfigurationValueIdFlow
 * @author            : Laura Rodríguez
 * @group             :
 * @last modified on  : 03-09-2024
 * @last modified by  : lrodriguez
 **/
@isTest
private with sharing class GetGlobalConfigurationValueIdFlowTest 
{
    @IsTest
    static void testGetGlobalConfigurationValueId() {

        Id USPRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('USPInquiry')?.getRecordTypeId();
        String instancesId='Instances_Id';

        List<GetGlobalConfigurationValueIdFlow.FlowInputs> flowInputs = new List<GetGlobalConfigurationValueIdFlow.FlowInputs> ();
        GetGlobalConfigurationValueIdFlow.FlowInputs flowInput= new GetGlobalConfigurationValueIdFlow.FlowInputs();

        flowInput.globalValueName='Case_RecordType_USP_Id';

        Organization org = [SELECT Id FROM Organization LIMIT 1];
        flowInput.idORg=org.Id;
        flowInputs.add(flowInput);
        
        String valueCheck;

        Test.startTest();
        List<List<String>> USPRecordTypeIdTest = GetGlobalConfigurationValueIdFlow.getIdValueGlobalConfiguration(flowInputs);
        Test.stopTest();

        //Check results
        for (String uspValue:USPRecordTypeIdTest[0])
        {
            valueCheck= uspValue;
        }
        System.assertEquals(USPRecordTypeId, valueCheck, 'No se ha obtenido correctamente el Id');
    }

   
}