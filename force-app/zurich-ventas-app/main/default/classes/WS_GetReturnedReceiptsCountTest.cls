/**
 * Clase test WS_GetReturnedReceiptsList
 *
 * @author fpalomo
 * @date 19/06/2024
 */
@IsTest
private class WS_GetReturnedReceiptsCountTest {

    /**
     * Metodo test servicio web
     *
     * @author fpalomo
     * @date 19/06/2024
     */
    @IsTest
    private static void testGetReturnedReceiptsCount() {
        
        // Crear la respuesta simulada usando el método auxiliar
        GetReturnedReceiptsWSUtils.ZRMReciboCountResponse response = createZRMReciboResponse();
        
        // Simular el HTTP request y response
        Test.setMock(HttpCalloutMock.class, new WS_GetReturnedReceiptsCountMock(200, response));

        // Llamar a la clase que hace el callout
        WS_GetReturnedReceiptsCount wsClass = new WS_GetReturnedReceiptsCount();
        GetReturnedReceiptsWSUtils.ZRMReciboCountResponse actualResponse = wsClass.callWebService();

        // Realizar las aserciones necesarias para validar el comportamiento
        Assert.areEqual(30, actualResponse.numeroRecibosDevueltos, 'Debe de coincidir el numero de recibos devueltos con el dado');
    }

    /**
     * Metodo test errores servicio web
     *
     * @author fpalomo
     * @date 19/06/2024
     */
    @IsTest
    private static void testGetReturnedReceiptsCountError() {
        // Simular el HTTP request y response
        Test.setMock(HttpCalloutMock.class, new WS_GetReturnedReceiptsCountMock(500, null));

        // Llamar a la clase que hace el callout
        WS_GetReturnedReceiptsCount wsClass = new WS_GetReturnedReceiptsCount();
        GetReturnedReceiptsWSUtils.ZRMReciboCountResponse actualResponse = wsClass.callWebService();

        // Realizar las aserciones necesarias para validar el comportamiento
        Assert.areEqual(null, actualResponse, 'El WS debería haber devuelto una respuesta vacía.');
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
