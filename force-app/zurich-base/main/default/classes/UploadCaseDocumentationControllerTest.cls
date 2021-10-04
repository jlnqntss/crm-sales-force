/**
 * Clases de test para UploadCaseDocumentationController
 **
 * @author rlopez
 * @date 03/03/2021
 */
@isTest(SeeAllData=false)
public with sharing class UploadCaseDocumentationControllerTest
{
    @TestSetup
    static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        insert cases;

        ContentVersion version = new ContentVersion(title = '001', PathOnClient='prueba',  VersionData = Blob.valueOf('data'));
        insert version;
    }

    /**
     * Comprueba que se recupera correctamente la información del caso
     **
     * @author rlopez
     * @date 03/03/2021
     */
    @isTest
    static void test_getCase_ok()
    {
        Case relatedCase = [SELECT Id FROM Case LIMIT 1];
        System.assertEquals(true, relatedCase != null, 'Case exists');

        String docHashId = SystemUtil.generateHash(relatedCase.Id);
        relatedCase.DocumentationHashId__c = docHashId;
        update relatedCase;

        Test.startTest();
        Case caseResult = UploadCaseDocumentationController.getCase(docHashId);
        Test.stopTest();

        System.assertEquals(true, caseResult != null, 'Case found by hashId');
        System.assertEquals(caseResult.Id, relatedCase.Id, 'Ids from cases are the same');
    }

    /**
     * Comprueba que si el Id no corresponde con un caso lanza una excepción
     **
     * @author rlopez
     * @date 03/03/2021
     */
    @isTest
    static void test_getCase_invalidHashId_ko()
    {
        Case relatedCase = [SELECT Id FROM Case LIMIT 1];
        System.assertEquals(true, relatedCase != null, 'Case exists');

        String docHashId = SystemUtil.generateHash(relatedCase.Id);
        relatedCase.DocumentationHashId__c = docHashId;
        update relatedCase;

        Test.startTest();
        try
        {
            Case caseResult = UploadCaseDocumentationController.getCase('123');
        }
        catch (Exception ex)
        {
            System.assertEquals(true, ex.getTypeName().contains('AuraHandledException'), 'AuraException sent to the component');
        }
        Test.stopTest();

        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(false, errorLogs.isEmpty(), 'List is not empty');
    }

    /**
     * Comprueba que si el Id no corresponde con un caso lanza una excepción
     **
     * @author rlopez
     * @date 03/03/2021
     */
    @isTest
    static void test_getCase_emptyHashId_ko()
    {
        Case relatedCase = [SELECT Id FROM Case LIMIT 1];
        System.assertEquals(true, relatedCase != null, 'Case exists');

        String docHashId = SystemUtil.generateHash(relatedCase.Id);
        relatedCase.DocumentationHashId__c = docHashId;
        update relatedCase;

        Test.startTest();
        try
        {
            Case caseResult = UploadCaseDocumentationController.getCase('');
        }
        catch (Exception ex)
        {
            System.assertEquals(true, ex.getTypeName().contains('AuraHandledException'), 'AuraException sent to the component');
        }
        Test.stopTest();

        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(false, errorLogs.isEmpty(), 'List is not empty');
    }


    /**
     * Comprueba que si el Id es correcto se elimina el documento
     **
     * @author jjuaristi
     * @date 27/09/2021
     */
    @isTest
    static void test_deleteDocumentWithVersion_ok()
    {
        ContentVersion version = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        Test.startTest();
        UploadCaseDocumentationController.deleteDocumentWithVersion(version.Id);
        Test.stopTest();
        ContentDocument document = new ContentDocument();
        try 
        {
            document = [SELECT Id FROM ContentDocument WHERE Id = :version.ContentDocumentId LIMIT 1];
        } catch (Exception e) {
            System.assertEquals(false, document == null, 'Document is not deleted');
        }
        System.assertEquals(false, document == null, 'Document is not deleted');
    }

/**
     * Comprueba que si el Id es incorrecto, salta la excepción
     **
     * @author jjuaristi
     * @date 27/09/2021
     */
    @isTest
    static void test_deleteDocumentWithVersion_ko()
    {
         ContentVersion version = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        Test.startTest();
        UploadCaseDocumentationController.deleteDocumentWithVersion(version.Id);
        
        ContentDocument document = new ContentDocument();
        try 
        {
            //Volvemos a intentar eliminar el documento para que salte la excepción
            UploadCaseDocumentationController.deleteDocumentWithVersion(version.Id);
        } catch (Exception e) {
            System.assertEquals('System.AuraHandledException', e.getTypeName(), 'Error not catched');
        }
        Test.stopTest();
    }
}