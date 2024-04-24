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

        TicketingHegeoServiceMock mock = new TicketingHegeoServiceMock(
            200,
            'OK',
            'application/soap+xml;charset=utf-8',
            '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Header><NS1:Security xmlns:NS1="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"><Timestamp xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><Created>2024-04-12T09:14:24.786Z</Created></Timestamp></NS1:Security></soap:Header><soap:Body><io:updateVsegTicketResponse xmlns:io="http://webservices.zurich.com/proxy/Hegeo/Ticketing/v1_0"><io:ticket><io:ticketId>102845</io:ticketId></io:ticket></io:updateVsegTicketResponse></soap:Body></soap:Envelope>',
            false
            );

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        List<String> resList = TicketingHegeoAction.doCallout(new List<TicketingHegeoAction.TicketingHegeoRequest> {req, req2});
        Test.stopTest();

        Assert.isFalse( resList.isEmpty() );
        Assert.areEqual( 2, resList.size() );
        Assert.areEqual('OK', resList[0]);
        Assert.areEqual('OK', resList[1]);
    }
}