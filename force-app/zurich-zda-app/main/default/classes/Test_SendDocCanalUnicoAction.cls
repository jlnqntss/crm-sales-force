/**
 * Clase encargada del testing de la clase SendDocCanalUnicoAction
 *
 * @author mario.navarro@seidor.com
 * @date 25/03/2024
 */
@isTest
private with sharing class Test_SendDocCanalUnicoAction
{

    @TestSetup
    private static void makeData()
    {
        //Creamos el caso que vamos a utilizar para relacionar con el envio
        Case c = new Case(
            CuTicketId__c = '15',
            Status = 'Asignado',
            RecordTypeId = CaseUtil.RT_ID_ZDA
            );
        insert c;

        //Y dos fichero adjuntos
        ContentVersion newFile = new ContentVersion();
        newFile.Title = 'fichero1';
        newFile.PathOnClient = 'fichero1.pdf';
        newFile.VersionData = Blob.valueof('contenido fichero 1');

        ContentVersion newFile2 = new ContentVersion();
        newFile2.Title = 'fichero2';
        newFile2.PathOnClient = 'fichero2.pdf';
        newFile2.VersionData = Blob.valueof('contenido fichero 2');

        insert new List<ContentVersion> {newFile, newFile2};

        SendDocCUInfo__c sdc = new SendDocCUInfo__c(
            CaseId__c = c.Id,
            Comments__c = 'Comentario del envio en test'
            );
        insert sdc;
    }

    /**
     * Testea que el metodo sendDocumentation funciona correctamente
     *
     * @author mario.navarro@seidor.com
     * @date 25/03/2024
     */
    @isTest
    private static void test_sendDocumentation()
    {
        List<SendDocCUInfo__c> sdcList = [SELECT CaseId__c, Comments__c FROM SendDocCUInfo__c];
        Assert.isFalse( sdcList.isEmpty() );

        List<ContentVersion> fileList = [SELECT ContentDocumentId FROM ContentVersion];
        Assert.isFalse( fileList.isEmpty() );
        Assert.areEqual( 2, fileList.size() );

        SendDocCUInfo__c sendObj = sdcList[0];
        sendObj.ContentDocIds__c='[' + fileList[0].ContentDocumentId + ',' + fileList[1].ContentDocumentId + ']';

        TicketingHegeoServiceMock mock = new TicketingHegeoServiceMock(
            200,
            'OK',
            'application/soap+xml;charset=utf-8',
            '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope"><soap:Header><NS1:Security xmlns:NS1="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"><Timestamp xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><Created>2024-04-12T09:14:24.786Z</Created></Timestamp></NS1:Security></soap:Header><soap:Body><io:updateVsegTicketResponse xmlns:io="http://webservices.zurich.com/proxy/Hegeo/Ticketing/v1_0"><io:ticket><io:ticketId>102845</io:ticketId></io:ticket></io:updateVsegTicketResponse></soap:Body></soap:Envelope>',
            false
            );
        SendDocCanalUnicoAction.SendDocCanalUnicoRequest req = new SendDocCanalUnicoAction.SendDocCanalUnicoRequest();
        req.sendDocObject = sendObj;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        SendDocCanalUnicoAction.sendDocumentation(new List<SendDocCanalUnicoAction.SendDocCanalUnicoRequest> {req});
        Test.stopTest();

        //Se valida que se haya actualizado el objeto de envio correctamente
        List<SendDocCUInfo__c> updatedSdcList = [SELECT Result__c, SendDate__c FROM SendDocCUInfo__c];
        Assert.isFalse( updatedSdcList.isEmpty() );
        Assert.isNotNull(updatedSdcList[0].Result__c);
        Assert.areEqual('OK', updatedSdcList[0].Result__c);
        Assert.isNotNull(updatedSdcList[0].SendDate__c);

        //Se comprueba tambien que se hayan lincado los documentos adjuntos
        List<ContentDocumentLink> foundLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = : sendObj.Id];
        Assert.isFalse( foundLinks.isEmpty() );
        Assert.areEqual( 2, foundLinks.size() );
    }

    /**
     * Testea un KO en el metodo sendDocumentation al ejecutar el callout
     *
     * @author mario.navarro@seidor.com
     * @date 25/03/2024
     */
    @isTest
    private static void test_sendDocumentationKo()
    {
        List<SendDocCUInfo__c> sdcList = [SELECT CaseId__c, Comments__c, ContentDocIds__c FROM SendDocCUInfo__c];
        Assert.isFalse( sdcList.isEmpty() );
        SendDocCUInfo__c sendObj = sdcList[0];

        TicketingHegeoServiceMock mock = new TicketingHegeoServiceMock(
            null,
            null,
            null,
            null,
            true
            );
        SendDocCanalUnicoAction.SendDocCanalUnicoRequest req = new SendDocCanalUnicoAction.SendDocCanalUnicoRequest();
        req.sendDocObject = sendObj;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        SendDocCanalUnicoAction.sendDocumentation(new List<SendDocCanalUnicoAction.SendDocCanalUnicoRequest> {req});
        Test.stopTest();

        //Se valida que se haya actualizado el objeto de envio correctamente
        List<SendDocCUInfo__c> updatedSdcList = [SELECT Result__c, SendDate__c FROM SendDocCUInfo__c];
        Assert.isFalse( updatedSdcList.isEmpty() );
        Assert.isNotNull(updatedSdcList[0].Result__c);
        Assert.areEqual(Label.ZDAVsegTicketRequestError, updatedSdcList[0].Result__c);
        Assert.isNotNull(updatedSdcList[0].SendDate__c);
    }

}