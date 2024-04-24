/**
 * Clase de test para TicketingHegeoAction
 *
 * @author mario.navarro@seidor.com
 * @date 24/04/2024
 */
@isTest
private with sharing class Test_TicketingHegeoAction
{

    @TestSetup
    private static void makeData()
    {
        //Creamos el caso que vamos a utilizar para relacionar con el envio
        Case c = new Case(
            TicketId__c = 15,
            Status = 'Asignado'
            );
        insert c;

        //Y un fichero adjunto
        ContentVersion newFile = new ContentVersion();
        newFile.Title = 'fichero1';
        newFile.PathOnClient = 'fichero1.pdf';
        newFile.VersionData = Blob.valueof('contenido fichero 1');
        insert newFile;
    }

    /**
     * Comprueba el correcto funcionamiento del metodo doCallout
     *
     * @author mario.navarro@seidor.com
     * @date 24/04/2024
     */
    @isTest
    private static void test_doCallout()
    {
        List<Case> createdCases = [SELECT TicketId__c, CaseNumber, Status, PendingBy__c, Owner.Name FROM Case];
        Assert.isFalse( createdCases.isEmpty() );

        List<ContentVersion> createdFiles = [SELECT ContentDocumentId FROM ContentVersion];
        Assert.isFalse( createdFiles.isEmpty() );

        TicketingHegeoAction.TicketingHegeoRequest req = new TicketingHegeoAction.TicketingHegeoRequest();
        req.relatedCase = createdCases[0];
        req.event = 4; //Petición información
        req.contentDocumentIdList = new List<String> {createdFiles[0].ContentDocumentId};
        req.comments = 'Comentarios de la peticion en test';

        TicketingHegeoAction.TicketingHegeoRequest req2 = new TicketingHegeoAction.TicketingHegeoRequest();
        req2.relatedCase = createdCases[0];
        req2.event = 4; //Petición información
        req2.comments = 'Comentarios de la peticion en test. SIN FICHEROS';

        Test.startTest();
        Test.setMock( HttpCalloutMock.class, new TicketingHegeoServiceMock.MockOk() );
        List<String> resList = TicketingHegeoAction.doCallout(new List<TicketingHegeoAction.TicketingHegeoRequest> {req, req2});
        Test.stopTest();

        Assert.isFalse( resList.isEmpty() );
        Assert.areEqual( 2, resList.size() );
        Assert.areEqual('OK', resList[0]);
        Assert.areEqual('OK', resList[1]);
    }
}