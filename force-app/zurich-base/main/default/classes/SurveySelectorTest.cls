/**
 * Clases de test para SurveySelector
 **
 * @author aberuete
 * @date 04/05/2022
 */

@isTest
private class SurveySelectorTest 
{

    /**
     * Create test data
     **
     * @author aberuete
     * @date 04/05/2022
     */
    @TestSetup
    static void makeData()
    {
        List<Survey__c> surveys = Test.loadData(Survey__c.sObjectType, 'TestSurvey');
        System.assert(surveys.size() == 194);
        //Survey__c s = (Survey__c)surveys[193];
        //

        List<Survey__c> s = new List<Survey__c>();

        for(Integer i = 1; i <= 5; i++)
        {
            s.add(
                new Survey__c(
                    CanBeRemoved__c = false
                )
            );

        }
        insert s;
    }

    /**
     * Test que comprueba si funciona correctamente la query  
     * *
     * @author aberuete
     * @date 04/05/2022
     */
    @istest
    static void test_getQueryLastModifiedDateAfterThan()
    {      
        Test.startTest();
        System.assert (
             String.isNotBlank( new SurveySelector().getQueryLastModifiedDateAfterThan(20)),
             'No se ha podido recuperar la query de obtener encuentas'
             );
        Test.stopTest();
    }

    /**
     * Test que comprueba si funciona correctamente la query de tipo count
     * *
     * @author aberuete
     * @date 04/05/2022
     */
    @istest
    static void test_count()
    {      
        Test.startTest();
        System.assertEquals(199, new SurveySelector().count(0,false), 'No se ha contado correctamente todos');
        System.assertEquals(194, new SurveySelector().count(20,null), 'No se ha contado correctamente los de antes');
        Test.stopTest();
    }
}