@isTest(SeeAllData=false)
public class BusinessInsuranceUtilTest
{
    /**
     * Test que comprueba que si la fecha enviada está dentro
     * del horario de atención, la fecha de getPreferredContactDatetime es la misma
     *
     * @author rlopez
     * @date 13/01/2020
     */
    @isTest
    static void test_getPreferredContactDatetime_within_ok()
    {
        List<BusinessHours> businessHoursList = [SELECT Id FROM BusinessHours WHERE Name =: BusinessInsuranceUtil.ZE_BUSINESS_HOURS];
        System.assertEquals(false, businessHoursList.isEmpty(), 'List should NOT be empty');

        Datetime withinDatetime = BusinessHours.nextStartDate(businessHoursList.get(0).Id, System.now() );

        Test.startTest();
        Datetime result = BusinessInsuranceUtil.getPreferredContactDatetime(withinDatetime);
        Test.stopTest();

        System.assertEquals(true, result != null, 'It is a valid Datetime');
        System.assertEquals(true, BusinessHours.isWithin(businessHoursList.get(0).Id, result), 'Datetime is within ZE Business Hours');
        System.assertEquals(true, withinDatetime == result, 'Datetimes are the same');
    }

    /**
     * Test que comprueba que si la fecha enviada NO está dentro
     * del horario de atención, la fecha de getPreferredContactDatetime es la próxima hora hábil
     *
     * @author rlopez
     * @date 13/01/2020
     */
    @isTest
    static void test_getPreferredContactDatetime_not_within_ok()
    {
        List<BusinessHours> businessHoursList = [SELECT Id FROM BusinessHours WHERE Name =: BusinessInsuranceUtil.ZE_BUSINESS_HOURS];
        System.assertEquals(false, businessHoursList.isEmpty(), 'List should NOT be empty');

        Datetime notWithinDatetime = System.now();
        while(BusinessHours.isWithin(businessHoursList.get(0).Id, notWithinDatetime) )
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
     * Test que comprueba que si la fecha es null,
     * getPreferredContactDatetime devuelve la próxima hora hábil
     *
     * @author rlopez
     * @date 13/01/2020
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