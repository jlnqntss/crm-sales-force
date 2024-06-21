/**
 * Clase utils para los servicios de recibos
 * Actualmente en uso por:
 * - WS_GetReturnedReceiptsCount.cls
 * - WS_GetReturnedReceiptsList.cls
 *
 * @author fpalomo
 * @date 13/06/2024
 */
public with sharing class GetReturnedReceiptsWSUtils
{
    
     /**
     * Método que genera un nuevo token de autenticación
     *
     * @author dmunoz
     * @date 29/05/2024
     *
     * @return HttpRequest devuelve la request del servicio web 
     */
    public static HttpRequest setAuthenticationHeader(HttpRequest httpRequest)
    {

        String accessToken = '';

        String authProviderName = GlobalConfigUtil.getGlobalConfigurationValue('Provider_Zurich_Internal'); // zurich_internal
        String providerName = GlobalConfigUtil.getGlobalConfigurationValue('Provider_Name_OpenIdConnect'); // Open ID Connect

        if (!Test.isRunningTest()) {
            // Obtener token
            List<AuthProvider> providers = new AuthProviderSelector().getAuthProvider(authProviderName);
            String authProviderId = providers[0].Id;
            String oldAccessToken = Auth.AuthToken.getAccessToken(authProviderId, providerName);

            // compruebo si ha expirado el token para refrescarlo
            if (hasExpired(oldAccessToken)) {
                Map<String, String> newAccessToken = Auth.AuthToken.refreshAccessToken(authProviderId, providerName, oldAccessToken);

                accessToken = String.valueof(newAccessToken.get('AccessToken'));
            } else {
                accessToken = oldAccessToken;
            }
        }

        // Añadir cabeceras y autenticación
        httpRequest.setHeader('Content-Type', 'application/json');        
        httpRequest.setHeader('Authorization', 'Bearer ' + accessToken);        
        httpRequest.setHeader('Session-Id', 'test-session');
        httpRequest.setHeader('flow-id', 'test-flowid');

        return httpRequest;
    }

     /**
     * Método que comprueba si hay que refrescar el token para seguir llamando al servicio
     *
     * @author dmunoz
     * @date 29/05/2024
     *
     * @return Boolean, devuelve true si ha expirado o falso si aún está vigente el token
     */
    @TestVisible
    private static Boolean hasExpired(String oldAccessToken)
    {

        Boolean result = true;
        Blob decodedToken = EncodingUtil.base64Decode(oldAccessToken.substringBetween('.')); // me quedo con la posicion intermedia que es la que nos interesa para obtener la fecha
        Map<String, Object> decodedTokenMap = (Map<String, Object>) JSON.deserializeUntyped(decodedToken.toString());
        String expiredDateFormat = String.valueof(decodedTokenMap.get('exp')) + '000';
        TimeZone userTimeZone = UserInfo.getTimeZone();
        Datetime expiredDateOld = datetime.newinstance(long.valueof(expiredDateFormat));
        Integer offSet = userTimeZone.getOffset(expiredDateOld);
        Datetime expiredDate = expiredDateOld.addSeconds(offSet/1000);
 
        if (System.now() > expiredDate) {
            result = true;
        }

        return result;        
    }

    /**
     * Método que crea la request del servicio web
     *
     * @author dmunoz
     * @date 29/05/2024
     *
     * @return ZRMReciboRequest devuelve la request del servicio web 
     */
    public static ZRMReciboRequest createRequest(Integer pageNumber, Integer pageSize, String invocationType)
    {
        ZRMReciboRequest result = new ZRMReciboRequest();
        result.antiguedadRecibo = invocationType;
        result.numeroElementosPagina = pageSize;
        result.numeroPagina = pageNumber;

        return result;
    }

    /**
     * Clases request y response
     *
     * @author dmunoz
     * @date 29/05/2024
     *
     */
    public class ZRMReciboRequest
    {
        public String antiguedadRecibo { get; set; }
        public Integer numeroElementosPagina { get; set; }
        public Integer numeroPagina { get; set; }
    }

    public class ZRMReciboCountResponse
    {
        public Integer numeroRecibosDevueltos  { get; set; }
        public Integer numeroRecibosImpagados  { get; set; }
        public Integer numeroDiasValidez  { get; set; }
        public String codigoAgrupacion  { get; set; }
        public String codigoIntermediario  { get; set; }
        public String codigoIntermediarioOfertaDirigidaUsuario { get; set; }
        public String codigoNegocioOfertaDirigidaUsuario { get; set; }
        public List<Error> errors { get; set; }

    }

    public class ZRMReciboListResponse
    {
        public Integer numeroDiasValidez  { get; set; }
        public String codigoAgrupacion  { get; set; }
        public String codigoIntermediario  { get; set; }
        public String codigoIntermediarioOfertaDirigidaUsuario { get; set; }
        public String codigoNegocioOfertaDirigidaUsuario { get; set; }
        public List<ReciboDevuelto> listaRecibosDevueltos { get; set; }
        public Boolean esUltimaPagina { get; set; }
        public List<Error> errors { get; set; }
    }
    
    public class ReciboDevuelto
    {
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
        public Double importeTotalRecibo { get; set; }
        public String descripcionFormaPago { get; set; }
        public Integer numeroDevolucionesRecibo { get; set; }
        public String descripcionDocumentoReclamacion { get; set; }
        public Date fechaUltimaDevolucionRecibo { get; set; }
        public Date fechaEnvioBancoRecibo { get; set; }
        public String codigoIntermediario { get; set; }
    }
    
    public class Error
    {
        public String code { get; set; }
        public String message { get; set; }
        public Integer severity { get; set; }
        public List<ChildError> childErrors { get; set; }
    }
    
    public class ChildError
    {
        // Definir los atributos de ChildError si es necesario
    }
}