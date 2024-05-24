/**
 * Clase de test para ContentVersionSelector
 *
 * @author mario.navarro@seidor.com
 * @date 23/04/2024
 */
@isTest
private with sharing class Test_ContentVersionSelector
{

    @TestSetup
    private static void makeData()
    {
        ContentVersion newVersion = new ContentVersion();
        newVersion.Title = 'fichero1';
        newVersion.PathOnClient = 'fichero1.txt';
        newVersion.VersionData = Blob.valueof('contenido fichero 1');
        insert newVersion;

        ContentVersion newVersion2 = new ContentVersion();
        newVersion2.Title = 'fichero2';
        newVersion2.PathOnClient = 'fichero2.txt';
        newVersion2.VersionData = Blob.valueof('contenido fichero 2');
        insert newVersion2;
    }

    /**
     * Metodo que comprueba el correcto funcionamiento de findByContentDocumentId
     *
     * @author mario.navarro@seidor.com
     * @date 23/04/2024
     */
    @isTest
    private static void test_findByContentDocumentId()
    {
        List<ContentVersion> files = [SELECT ContentDocumentId FROM ContentVersion];
        Assert.isFalse( files.isEmpty() );

        Map<Id, List<ContentVersion> > cvByContendDocId = (Map<Id, List<ContentVersion> >) CollectionUtil.groupListBy( files, ContentVersion.fields.ContentDocumentId.getDescribe().getName() );

        Test.startTest();
        List<ContentVersion> emptyList = new ContentVersionSelector().findByContentDocumentId(null);
        List<ContentVersion> emptyList2 = new ContentVersionSelector().findByContentDocumentId( new Set<Id>() );
        List<ContentVersion> foundList = new ContentVersionSelector().findByContentDocumentId( cvByContendDocId.keySet() );
        Test.stopTest();

        Assert.isTrue( emptyList.isEmpty() );
        Assert.isTrue( emptyList2.isEmpty() );
        Assert.isFalse( foundList.isEmpty() );
        Assert.areEqual( files.size(), foundList.size() );
    }


}