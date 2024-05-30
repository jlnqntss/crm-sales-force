
/**
 * Clase test WS_GetReturnedReceiptsList
 *
 * @author dmunoz
 * @date 29/05/2024
 */
@IsTest
public class WS_GetReturnedReceiptsListTest {

    /**
     * Metodo test servicio web
     *
     * @author dmunoz
     * @date 29/05/2024
     */
    @IsTest
    private static void testGetReturnedReceiptsList() {
        
        // Crear la respuesta simulada usando el método auxiliar
        WS_GetReturnedReceiptsList.ZRMReciboResponse response = createZRMReciboResponse();
        
        // Simular el HTTP request y response
        Test.setMock(HttpCalloutMock.class, new WS_GetReturnedReceiptsListMock(response));

        // Llamar a la clase que hace el callout
        WS_GetReturnedReceiptsList wsClass = new WS_GetReturnedReceiptsList();
        WS_GetReturnedReceiptsList.ZRMReciboResponse actualResponse = wsClass.callWebService(1, 'DiaAnterior');

        // Realizar las aserciones necesarias para validar el comportamiento
        Assert.areEqual(99999, actualResponse.numeroDiasValidez, 'Debe de coincidir el numero de dias de validez con el dado');
    }

    
    /**
     * Método auxiliar para crear la respuesta simulada
     *
     * @author dmunoz
     * @date 29/05/2024
     */
    private static WS_GetReturnedReceiptsList.ZRMReciboResponse createZRMReciboResponse() {
        WS_GetReturnedReceiptsList.ZRMReciboResponse response = new WS_GetReturnedReceiptsList.ZRMReciboResponse();
        response.numeroDiasValidez = 99999;
        response.codigoAgrupacion = 'string';
        response.codigoIntermediario = 'string';
        response.codigoIntermediarioOfertaDirigidaUsuario = 'string';
        response.codigoNegocioOfertaDirigidaUsuario = 'string';

        // Crear lista de recibos devueltos
        WS_GetReturnedReceiptsList.ReciboDevuelto recibo = new WS_GetReturnedReceiptsList.ReciboDevuelto();
        recibo.codigoRecibo = 'string';
        recibo.fechaEfectoMovimiento = Date.newInstance(2024, 5, 30);
        recibo.codigoPoliza = 'string';
        recibo.versionPoliza = 99999;
        recibo.descripcionAgrupacionCompania = 'string';
        recibo.claveFiliacionTomador = 'string';
        recibo.tipoPersona = 'F';
        recibo.tipoDocumento = 'C';
        recibo.documentoIdentificacion = 'string';
        recibo.nombreTomador = 'string';
        recibo.telefonoTomador = 'string';
        recibo.nombreAgrupacion = 'string';
        recibo.importeTotalRecibo = 300;
        recibo.descripcionFormaPago = 'string';
        recibo.numeroDevolucionesRecibo = 999;
        recibo.descripcionDocumentoReclamacion = 'string';
        recibo.fechaUltimaDevolucionRecibo = Date.newInstance(2024, 5, 30);
        recibo.fechaEnvioBancoRecibo = Date.newInstance(2024, 5, 30);
        recibo.codigoIntermediario = 'string';
        response.listaRecibosDevueltos = new List<WS_GetReturnedReceiptsList.ReciboDevuelto> { recibo };
        
        response.esUltimaPagina = true;
        
        WS_GetReturnedReceiptsList.Error error = new WS_GetReturnedReceiptsList.Error();
        error.code = '';
        error.message = '';
        error.severity = 0;
        error.childErrors = new List<WS_GetReturnedReceiptsList.ChildError> { new WS_GetReturnedReceiptsList.ChildError() };
        response.errors = new List<WS_GetReturnedReceiptsList.Error> { error };
        
        return response;
    }

    
    /**
     * Clase Mock para simular la respuesta HTTP
     *
     * @author dmunoz
     * @date 29/05/2024
     */
    private class WS_GetReturnedReceiptsListMock implements HttpCalloutMock {
        private WS_GetReturnedReceiptsList.ZRMReciboResponse response;
        
        public WS_GetReturnedReceiptsListMock(WS_GetReturnedReceiptsList.ZRMReciboResponse response) {
            this.response = response;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(response));
            res.setStatusCode(200);
            return res;
        }
    }
}
