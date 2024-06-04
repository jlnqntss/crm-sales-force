
/**
 * Clase controladora del LWC ZRMRecibos
 *
 * @author dmunoz
 * @date 29/05/2024
 */
public with sharing class ZRMRecibosController {

    //#region metodo principal

    /**
     * Clase principal que llama al servicio web GetReturnedReceiptsList
     *
     * @author dmunoz
     * @date 29/05/2024
     * @return PaginatedResult
     */
    @AuraEnabled
    public static PaginatedResult getData(Integer pageNumber, Integer pageSize, String invocationType) {

        String errorMessage;

        try {
            PaginatedResult result = new PaginatedResult();

            // Invocar servicio web
            WS_GetReturnedReceiptsList ws = new WS_GetReturnedReceiptsList();
            WS_GetReturnedReceiptsList.ZRMReciboResponse response = ws.callWebService(pageNumber, pageSize, invocationType);

            // Obtener los datos de la respuesta y devolver resultado         
            if (response != null) { // si ha habido respuesta
                result = getResposeData(response, pageNumber);

            } else {
                errorMessage = System.Label.ZRM_Recibos_WS_Error;
                throw new HandledException(errorMessage);
            }

            return result;

        } catch (Exception e) {
            errorMessage = String.isNotEmpty(errorMessage) ? errorMessage : System.Label.ZRM_Recibos_LWC_Error;
            throw new AuraHandledException(errorMessage);
        }
    }


    //#region metodos auxiliares

    /**
     * Metodo que lee la respuesta obtenida del servicio web para cada página
     *
     * @author dmunoz
     * @date 29/05/2024
     * @return PaginatedResult
     */
    private static PaginatedResult getResposeData(WS_GetReturnedReceiptsList.ZRMReciboResponse response, Integer pageNumber) {

        PaginatedResult result = new PaginatedResult();

        // recorro los resultados
        List<ZRMRecibo> recibos = new List<ZRMRecibo>();
        Boolean esUltimaPagina = response.esUltimaPagina;

        for (WS_GetReturnedReceiptsList.ReciboDevuelto reciboResponse: response.listaRecibosDevueltos) {
            recibos.add(createObjectZRMRecibo(reciboResponse));
        }

        result.records = recibos;
        result.disablePreviousButton = pageNumber <= 1;
        result.disableNextButton = esUltimaPagina; 

        return result;        
    }

    /**
     * Metodo que convierte cada recibo del WS en un objeto legible por el LWC
     *
     * @author dmunoz
     * @date 29/05/2024
     * @return ZRMRecibo
     */
    private static ZRMRecibo createObjectZRMRecibo(WS_GetReturnedReceiptsList.ReciboDevuelto reciboResponse) {

        ZRMRecibo result = new ZRMRecibo();
        result.codigoRecibo = reciboResponse.codigoRecibo;
        result.fechaEfectoMovimiento = reciboResponse.fechaEfectoMovimiento;
        result.codigoPoliza = reciboResponse.codigoPoliza;
        result.descripcionAgrupacionCompania = reciboResponse.descripcionAgrupacionCompania;
        result.nombreTomador = reciboResponse.nombreTomador;
        result.telefonoTomador = reciboResponse.telefonoTomador;
        result.importeTotalRecibo = reciboResponse.importeTotalRecibo;
        result.descripcionFormaPago = reciboResponse.descripcionFormaPago;
        result.numeroDevolucionesRecibo = reciboResponse.numeroDevolucionesRecibo;
        result.descripcionDocumentoReclamacion = reciboResponse.descripcionDocumentoReclamacion;
        result.fechaUltimaDevolucionRecibo = reciboResponse.fechaUltimaDevolucionRecibo;
        result.fechaEnvioBancoRecibo = reciboResponse.fechaEnvioBancoRecibo;
        result.codigoIntermediario = reciboResponse.codigoIntermediario;
        return result; 
    }


    //#region objeto respuesta

    /**
     * Objetos para enviar al LWC
     *
     * @author dmunoz
     * @date 29/05/2024
     *
     */
    public class PaginatedResult {
        @AuraEnabled public List<ZRMRecibo> records { get; set; }
        @AuraEnabled public Boolean disablePreviousButton { get; set; }
        @AuraEnabled public Boolean disableNextButton { get; set; }
    }


    @TestVisible
    private class ZRMRecibo {
        @AuraEnabled public String codigoRecibo {get; set;}
        @AuraEnabled public Date fechaEfectoMovimiento {get; set;}
        @AuraEnabled public String codigoPoliza {get; set;}
        @AuraEnabled public String descripcionAgrupacionCompania {get; set;}
        @AuraEnabled public String nombreTomador {get; set;}
        @AuraEnabled public String telefonoTomador {get; set;}
        @AuraEnabled public Integer importeTotalRecibo {get; set;}
        @AuraEnabled public String descripcionFormaPago {get; set;}
        @AuraEnabled public Integer numeroDevolucionesRecibo {get; set;}
        @AuraEnabled public String descripcionDocumentoReclamacion {get; set;}
        @AuraEnabled public Date fechaUltimaDevolucionRecibo {get; set;}
        @AuraEnabled public Date fechaEnvioBancoRecibo {get; set;}
        @AuraEnabled public String codigoIntermediario {get; set;}
    }
}