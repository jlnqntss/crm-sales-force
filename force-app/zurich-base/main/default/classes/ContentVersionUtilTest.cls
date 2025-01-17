/**
 * Clases de test para ContentVersionUtil
 **
 * @author rlopez
 * @date 09/03/2021
 */
@isTest(SeeAllData=false)
private with sharing class ContentVersionUtilTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        insert cases;
    }

    /**
     * Test que comprueba la correcta ejecución del trigger en ContentVersion
     * al crear un ContentDocumentLink entre el Caso y el ContentVersion que
     * tengan el mismo valor en los campos DocumentationHashId__c y Guest_Record_fileupload__c,
     * respectivamente.
     *
     * @author rlopez
     * @date 09/03/2021
     */
    @isTest
    static void test_create_contentDocumentLink_from_contentVersion_ok()
    {
        Case relatedCase = [SELECT Id FROM Case LIMIT 1];
        System.assertEquals(true, relatedCase != null, 'Case exists');

        String docHashId = SystemUtil.generateHash(relatedCase.Id);
        relatedCase.DocumentationHashId__c = docHashId;
        relatedCase.Status = 'Asignado';
        update relatedCase;

        Test.startTest();
        String contentData = 'Test Content Data';
        Blob contentDataAsBlob = Blob.valueOf(contentData);
        String encodeContentData = EncodingUtil.base64Encode(contentDataAsBlob);
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'Test Path on Client';
        cv.VersionData = EncodingUtil.base64Decode(encodeContentData);
        cv.Guest_Record_fileupload__c = docHashId;
        insert cv;
        Test.stopTest();

        List<ContentDocumentLink> relatedContentDocumentLink = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: relatedCase.Id];
        System.assertEquals(false, relatedContentDocumentLink.isEmpty(), 'List is not empty');

        ContentVersion createdContentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id];
        System.assertEquals(true, createdContentVersion != null, 'CreatedContentVersion is not null');
        System.assertEquals(createdContentVersion.ContentDocumentId, relatedContentDocumentLink.get(0).ContentDocumentId, 'ContentDocumentIds are the same');

        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id =: relatedCase.Id];
        System.assertEquals(true, updatedCase != null, 'Case exists');
        System.assertEquals('Respondido', updatedCase.Status, 'Case status has changed');

        List<Task> createdTasks = [SELECT Id, Description FROM Task WHERE WhatId =: updatedCase.Id AND Subject =: Label.documentacionAnadida];
        System.assertEquals(false, createdTasks.isEmpty(), 'List is not empty');
        System.assertEquals(true, createdTasks.get(0).Description.contains(createdContentVersion.ContentDocumentId), 'Task contains ContentDocumentId');
    }

     /**
     * Test que comprueba que el mapa que contiene el caso y el campo DocumentationHashId__c se rellena correctamente
     *
     * @author aberuete
     * @date 19/04/2023
     */
    @isTest
    static void testIfHashToContentVersionNotEmptyFillHashToCaseMap() 
    {
        Map<String, ContentVersion> hashToContentVersion = new Map<String, ContentVersion>();
        String contentData = 'Test Content Data';
        Blob contentDataAsBlob = Blob.valueOf(contentData);
        String encodeContentData = EncodingUtil.base64Encode(contentDataAsBlob);

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'Test Path on Client';
        cv.VersionData = EncodingUtil.base64Decode(encodeContentData);
        cv.Guest_Record_fileupload__c = 'hash1';
        insert cv;

        hashToContentVersion.put('hash1', cv);

        Case caso = new Case();
        caso.DocumentationHashId__c = 'hash1';
        insert caso;
        
        Test.startTest();
        ContentVersionUtil.ifHashToContentVersionNotEmptyFillHashToCaseMap(hashToContentVersion);
        Test.stopTest();
        
        System.assertEquals(caso.Id, ContentVersionUtil.hashToCaseMap.get('hash1').Id, 'El mapa creado no es correcto');
    }

}