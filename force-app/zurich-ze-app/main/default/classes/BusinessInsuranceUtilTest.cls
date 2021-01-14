@isTest(SeeAllData=false)
public class BusinessInsuranceUtilTest
{
    /**
     * 
     */
    @isTest
    static void test_getPreferredContactDatetime_within_ok()
    {
        List<BusinessHours> businessHoursList = [SELECT Id FROM BusinessHours WHERE Name =: BusinessInsuranceUtil.ZE_BUSINESS_HOURS];
        System.assertEquals(false, businessHoursList.isEmpty(), 'List should NOT be empty');

        Datetime withinDatetime = BusinessHours.nextStartDate(businessHoursList.get(0).Id, System.now());

        Test.startTest();
        Datetime result = BusinessInsuranceUtil.getPreferredContactDatetime(withinDatetime);
        Test.stopTest();

        System.assertEquals(true, result != null, 'It is a valid Datetime');
        System.assertEquals(true, BusinessHours.isWithin(businessHoursList.get(0).Id, result), 'Datetime is within ZE Business Hours');
        System.assertEquals(true, withinDatetime == result, 'Datetimes are the same');
    }

    /**
     * 
     */
    @isTest
    static void test_getPreferredContactDatetime_not_within_ok()
    {
        List<BusinessHours> businessHoursList = [SELECT Id FROM BusinessHours WHERE Name =: BusinessInsuranceUtil.ZE_BUSINESS_HOURS];
        System.assertEquals(false, businessHoursList.isEmpty(), 'List should NOT be empty');

        Datetime notWithinDatetime = System.now();
        while(BusinessHours.isWithin(businessHoursList.get(0).Id, notWithinDatetime))
        {
            notWithinDatetime = notWithinDatetime.addDays(1);
        }

        Test.startTest();
        Datetime result = BusinessInsuranceUtil.getPreferredContactDatetime(notWithinDatetime);
        Test.stopTest();

        System.assertEquals(true, result != null, 'It is a valid Datetime');
        System.assertEquals(true, BusinessHours.isWithin(businessHoursList.get(0).Id, result), 'Datetime is within ZE Business Hours');
        System.assertEquals(true, notWithinDatetime != result, 'Datetimes are different');
    }

    /**
     * 
     */
    @isTest
    static void test_getPreferredContactDatetime_null_ok()
    {
        List<BusinessHours> businessHoursList = [SELECT Id FROM BusinessHours WHERE Name =: BusinessInsuranceUtil.ZE_BUSINESS_HOURS];
        System.assertEquals(false, businessHoursList.isEmpty(), 'List should NOT be empty');
        
        Test.startTest();
        Datetime result = BusinessInsuranceUtil.getPreferredContactDatetime(null);
        Test.stopTest();

        System.assertEquals(true, result != null, 'It is a valid Datetime');
        System.assertEquals(true, BusinessHours.isWithin(businessHoursList.get(0).Id, result), 'Datetime is within ZE Business Hours');
    }
}