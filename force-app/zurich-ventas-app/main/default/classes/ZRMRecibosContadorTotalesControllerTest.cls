/**
 * Clase test ZRMRecibosController
 *
 * @author dmunoz
 * @date 29/05/2024
 */
@isTest
private with sharing class ZRMRecibosContadorTotalesControllerTest {
    
    @isTest
    private static void testGetData() {

        // Crear la respuesta simulada usando el método auxiliar
        GetReturnedReceiptsWSUtils.ZRMReciboCountResponse response = createZRMReciboResponse();
        
        // Simular el HTTP request y response
        Test.setMock(HttpCalloutMock.class, new WS_GetReturnedReceiptsCountMock(200, response));

        Integer result = ZRMRecibosContadorTotalesController.getData();
        Assert.areEqual(30, result, 'Debe de coincidir el numero de recibos devueltos con el dado');
    }

    @isTest
    private static void testErrorGetData() {
        // Simular el HTTP request y response
        Test.setMock(HttpCalloutMock.class, new WS_GetReturnedReceiptsCountMock(500, null));

        String errorMessage = '';
        try {
            ZRMRecibosContadorTotalesController.getData();
        }

        catch (HandledException e) {
            errorMessage = e.getMessage();
        }

        Assert.areEqual(System.Label.ZRM_Recibos_WS_Error, errorMessage, 'El error devuelto no coincide con el esperado');
    }

    /**
     * Método auxiliar para crear la respuesta simulada
     *
     * @author fpalomo
     * @date 19/06/2024
     */
    private static GetReturnedReceiptsWSUtils.ZRMReciboCountResponse createZRMReciboResponse() {
        GetReturnedReceiptsWSUtils.ZRMReciboCountResponse response = new GetReturnedReceiptsWSUtils.ZRMReciboCountResponse();
        response.numeroRecibosDevueltos = 30;
        response.numeroRecibosImpagados = 0;
        response.numeroDiasValidez = 99999;
        response.codigoAgrupacion = 'string';
        response.codigoIntermediario = 'string';
        response.codigoIntermediarioOfertaDirigidaUsuario = 'string';
        response.codigoNegocioOfertaDirigidaUsuario = 'string';

        
        GetReturnedReceiptsWSUtils.Error error = new GetReturnedReceiptsWSUtils.Error();
        error.code = '';
        error.message = '';
        error.severity = 0;
        error.childErrors = new List<GetReturnedReceiptsWSUtils.ChildError> { new GetReturnedReceiptsWSUtils.ChildError() };
        response.errors = new List<GetReturnedReceiptsWSUtils.Error> { error };
        
        return response;
    }  

    /**
     * Clase Mock para simular la respuesta HTTP
     *
     * @author fpalomo
     * @date 19/06/2024
     */
    private class WS_GetReturnedReceiptsCountMock implements HttpCalloutMock {
        private GetReturnedReceiptsWSUtils.ZRMReciboCountResponse response;
        private Integer code;
        
        public WS_GetReturnedReceiptsCountMock(Integer code, GetReturnedReceiptsWSUtils.ZRMReciboCountResponse response) {
            this.response = response;
            this.code = code;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (response != null)
            {
                res.setBody(JSON.serialize(response));
            }
            res.setStatusCode(code);
            return res;
        }
    }
}