public with sharing class Rest_GetReturnedReceiptsList {

    private static final String CLASS_NAME = 'Rest_GetReturnedReceiptsList';

    public ZRMReciboResponse callWebService(Integer pageSize, String invocationType) {

        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            
            // Crear request
            ZRMReciboRequest zrmReciboRequest = createRequest(pageSize, invocationType);
            request.setBody(JSON.serialize(zrmReciboRequest));
        
            HttpResponse response = http.send(request);
            
            // Verificar el estado de la respuesta
            if (response.getStatusCode() == 200) {
                // Deserializar la respuesta JSON en un objeto ZRMReciboResponse
                ZRMReciboResponse result = (ZRMReciboResponse) JSON.deserialize(response.getBody(), ZRMReciboResponse.class);
                return result;
            } else {
                // Manejar respuestas que no sean exitosas
                return null;
            }
        } catch (Exception e) {            
            ErrorLogUtil.commitError(e, CLASS_NAME);
            return null;
        }
    }

    //#region crear request
    private ZRMReciboRequest createRequest(Integer pageSize, String invocationType) {
        ZRMReciboRequest result = new ZRMReciboRequest();
        result.antiguedadRecibo = invocationType;
        result.numeroElementosPagina = pageSize;
        result.numeroPagina = 99999;

        return result;
    }

    //#region clases 

    public class ZRMReciboRequest {
        private String antiguedadRecibo { get; set; }
        private Integer numeroElementosPagina { get; set; }
        private Integer numeroPagina { get; set; }
    }

    public class ZRMReciboResponse {
        public Integer numeroDiasValidez  { get; set; }
        public String codigoAgrupacion  { get; set; }
        public String codigoIntermediario  { get; set; }
        public String codigoIntermediarioOfertaDirigidaUsuario { get; set; }
        public String codigoNegocioOfertaDirigidaUsuario { get; set; }
        public List<ReciboDevuelto> listaRecibosDevueltos { get; set; }
        public Boolean esUltimaPagina { get; set; }
        public List<Error> errors { get; set; }
    }
    
    public class ReciboDevuelto {
        public String codigoRecibo { get; set; }
        public Date fechaEfectoMovimiento { get; set; }
        public String codigoPoliza { get; set; }
        public Integer versionPoliza { get; set; }
        public String descripcionAgrupacionCompania { get; set; }
        public String claveFiliacionTomador { get; set; }
        public String tipoPersona { get; set; }
        public String tipoDocumento { get; set; }
        public String documentoIdentificacion { get; set; }
        public String nombreTomador { get; set; }
        public String telefonoTomador { get; set; }
        public String nombreAgrupacion { get; set; }
        public Integer importeTotalRecibo { get; set; }
        public String descripcionFormaPago { get; set; }
        public Integer numeroDevolucionesRecibo { get; set; }
        public String descripcionDocumentoReclamacion { get; set; }
        public Date fechaUltimaDevolucionRecibo { get; set; }
        public Date fechaEnvioBancoRecibo { get; set; }
        public String codigoIntermediario { get; set; }
    }
    
    public class Error {
        public String code { get; set; }
        public String message { get; set; }
        public Integer severity { get; set; }
        public List<ChildError> childErrors { get; set; }
    }
    
    public class ChildError {
        // Definir los atributos de ChildError si es necesario
    }
    
    
}