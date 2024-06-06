/**
 * Clase de test para Batch_DeleteSendDocCUInfo
 * 
 * @author mario.navarro@seidor.com
 * @date 28/05/2024
 */
@isTest
private with sharing class Test_Batch_DeleteSendDocCUInfo
{

    /**
     * Creacion de los datos para los tests
     * 
     * @author mario.navarro@seidor.com
     * @date 28/05/2024
     */
    @TestSetup
    private static void makeData()
    {
        //Generamos los casos que se asociaran a los objetos a purgar
        List<Case> cases = TestDataFactory.generateZDACases(6);
        insert cases;
        //Ahora un envio por cada caso
        List<SendDocCUInfo__c> sendDocs = new List<SendDocCUInfo__c>();
        for (Case c : cases)
        {
            sendDocs.add(new SendDocCUInfo__c(
                CaseId__c = c.Id
            ));
        }
        insert sendDocs;
    }

    /**
     * Realiza el test de la ejecucion batch en la que los objetos son borrados segun
     * la query por defecto
     * 
     * @author mario.navarro@seidor.com
     * @date 28/05/2024
     */
    @isTest
    private static void test_defaultExecution()
    {
        Integer oldestRetention = GlobalConfigUtil.getDefaultObjectRetention(SendDocCUInfo__c.getSObjectType().toString())+5;

        List<SendDocCUInfo__c> objectList = [SELECT Id FROM SendDocCUInfo__c];
        //A los 5 primeros les establecemos una fecha de creacion mayor a la retencion definida, para que sean borrados
        Datetime dateOld = Datetime.now().addDays(-oldestRetention);
        Integer objectsToDelete = 5;
        for (Integer cnt = 0; cnt < objectsToDelete; cnt++)
        {
            Test.setCreatedDate(objectList[cnt].Id, dateOld);
        }
        //Al resto, la fecha de ayer, para que no se borren
        Datetime yesterday = Datetime.now().addDays(-1);
        for (Integer cnt = objectsToDelete; cnt < objectList.size(); cnt++)
        {
            Test.setCreatedDate(objectList[cnt].Id, yesterday);
        }

        Test.startTest();
        Batch_DeleteSendDocCUInfo batch = new Batch_DeleteSendDocCUInfo();
        Database.executeBatch(batch);
        Test.stopTest();

        List<SendDocCUInfo__c> postObjectList = [SELECT Id FROM SendDocCUInfo__c];
        Assert.isFalse(postObjectList.isEmpty());
        Assert.areEqual(objectList.size()-objectsToDelete, postObjectList.size());
    }

    /**
     * Realiza el test de la ejecucion batch en la que los objetos son borrados segun
     * la query que se le proporciona al constructor
     * 
     * @author mario.navarro@seidor.com
     * @date 28/05/2024
     */
    @isTest
    private static void test_CustomExecution()
    {
        Integer customRetention = 10;
        Integer oldestRetention = customRetention+5;

        List<SendDocCUInfo__c> objectList = [SELECT Id FROM SendDocCUInfo__c];
        //A los 5 primeros les establecemos una fecha de creacion mayor a la retencion definida, para que sean borrados
        Datetime dateOld = Datetime.now().addDays(-oldestRetention);
        Integer objectsToDelete = 5;
        for (Integer cnt = 0; cnt < objectsToDelete; cnt++)
        {
            Test.setCreatedDate(objectList[cnt].Id, dateOld);
        }
        //Al resto, la fecha de ayer, para que no se borren
        Datetime yesterday = Datetime.now().addDays(-1);
        for (Integer cnt = objectsToDelete; cnt < objectList.size(); cnt++)
        {
            Test.setCreatedDate(objectList[cnt].Id, yesterday);
        }

        String query = new SendDocCUInfosSelector().getQueryToDeleteObjectsByRetention(customRetention);

        Test.startTest();
        Batch_DeleteSendDocCUInfo batch = new Batch_DeleteSendDocCUInfo(query);
        Database.executeBatch(batch);
        Test.stopTest();

        List<SendDocCUInfo__c> postObjectList = [SELECT Id FROM SendDocCUInfo__c];
        Assert.isFalse(postObjectList.isEmpty());
        Assert.areEqual(objectList.size()-objectsToDelete, postObjectList.size());
    }

}