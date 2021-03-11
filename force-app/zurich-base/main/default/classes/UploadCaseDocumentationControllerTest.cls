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
}