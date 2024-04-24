/**
 * Clase encargada de hacer el envio a traves de SOAP API al ESB de Banc Sabadell para el envio
 * de informacion relacionada con los casos de ZDA para que en Canal unico tengan la informacion
 * actualizada sobre estos
 *
 * @author mario.navarro@seidor.com
 * @date 21/03/2024
 */
public with sharing class TicketingHegeoService
{

    //URL a la que apunta la named credential ESBCanalUnico = 'https://infoweb-uat.zurichspain.com/proxy/services/Hegeo/Ticketing/v1';

    /**
     * Realiza la peticion de envio al ESB de la request proporcionada
     *
     * @author mario.navarro@seidor.com
     * @date 21/03/2024
     * @param request objeto de tipo CanalUnicoUpdateVsegTicketRequest con los datos a enviar al ESB
     * @return la respuesta obtenida por el ESB a la peticion
     */
    public static String updateVsegTicket(CanalUnicoUpdateVsegTicketRequest request)
    {
        String requestBody;
        try
        {
            requestBody = constructSoapRequest(request);
        }
        catch (IllegalArgumentException iae)
        {
            //La peticion tiene algun parametro incorrecto
            throw iae;
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ESBCanalUnico');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/soap+xml;charset=UTF-8');
        //default timeout es 10 segundos, aumentamos a 20 (en pruebas daba timeout a pesar de que la peticion llegaba a destino correctamente)
        req.setTimeout(20000);
        req.setBody(requestBody);

        String responseResult;
        try
        {
            Http http = new Http();
            HttpResponse res = http.send(req);
            responseResult = TicketingHegeoService.parseResponse(res);
        }
        catch (Exception ex)
        {
            responseResult = 'KO';
            ErrorLogUtil.commitError(ex, TicketingHegeoService.class.getName(), 'updateVsegTicket');
        }

        return responseResult;
    }

    /**
     * Construye el cuerpo SOAP de la peticion al ESB en base al objeto proporcionado
     *
     * @author mario.navarro@seidor.com
     * @date 21/03/2024
     * @param request objeto de tipo CanalUnicoUpdateVsegTicketRequest con los datos a enviar al ESB
     * @return el string con el cuerpo de la peticion construido
     */
    private static String constructSoapRequest(CanalUnicoUpdateVsegTicketRequest request)
    {
        String soapRequest = '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:v1="http://webservices.zurich.com/proxy/Hegeo/Ticketing/v1_0">';
        soapRequest += '<soap:Header>';
        soapRequest += '<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">';
        soapRequest += '<wsse:UsernameToken xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">';
        soapRequest += '<wsse:Username>{!$Credential.Username}</wsse:Username>';
        soapRequest += '<wsse:Password>{!$Credential.Password}</wsse:Password>';
        soapRequest += '</wsse:UsernameToken>';
        soapRequest += '</wsse:Security>';
        soapRequest += '<eah:architectureHeader xmlns:eah="http://schemas.zurich.com/zia/corporate/ArchitectureHeader/v1_0">';
        soapRequest += '<eah:country>ES</eah:country>';
        soapRequest += '<eah:language>es</eah:language>';
        soapRequest += '<eah:applicationId>BSSG</eah:applicationId>';
        soapRequest += '</eah:architectureHeader>';
        soapRequest += '<wsu:Timestamp xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">';
        soapRequest += '<wsu:Created>' + DateTime.now().format(TicketingHegeoUtil.DATE_TIME_FORMATTER) + '</wsu:Created>';
        soapRequest += '</wsu:Timestamp>';
        soapRequest += '</soap:Header>';
        soapRequest += '<soap:Body>';
        soapRequest += request.buildRequest();
        soapRequest += '</soap:Body>';
        soapRequest += '</soap:Envelope>';
        return soapRequest;
    }

    /**
     * Parsea la respuesta retornada por el ESB. En caso de ser un codigo HTTP 200, se lee el XML en busca del resultado,
     * en caso contrario, se retorna el codigo de error junto con su descripcion
     *
     * @author mario.navarro@seidor.com
     * @date 22/04/2024
     * @param response el objeto response obtenido tras la peticion
     * @return la respuesta obtenida por el ESB a la peticion. Si ha ido bien, retornara un OK, mientras que si ha
     * ido mal podria devolver:
     * codigo Http - Descripcion para aquellas respuestas diferente de OK (200)
     * Fault code - Fault description en caso de producirse un error de SOAP (Fault)
     * Descripcion del error en caso de que la respuesta sea OK (200), pero la peticion no cumpla algun requisito
     */
    private static String parseResponse(HttpResponse response)
    {
        String parsedResponse;
        if ( response.getStatusCode() == 200 )
        {
            //Aunque nos haya retornado un codigo HTTP 200, hay que ver si el SOAP de respuesta contiene algun error
            if ( response.getBody().contains('<soap:Fault>') )
            {
                /*
                   SOAP FAULT => la peticion no esta bien construida (no deberia suceder, en CanalUnicoUpdateVsegTicketRequest
                   se comprueba que la peticion se crea correctamente)
                 */
                String elemFault = response.getBody().substringBetween('<soap:Fault>','</soap:Fault>');
                String elemCode = elemFault.substringBetween('<soap:Code>','</soap:Code>');
                String elemReason = elemFault.substringBetween('<soap:Reason>','</soap:Reason>');
                String faultCode = elemCode.substringBetween('>', '<');
                String faultDescription = elemReason.substringBetween('>', '<');

                parsedResponse = faultCode + ' - ' + faultDescription;
            }
            else if ( response.getBody().contains('<io:errorDescription>') )
            {
                //ERROR
                parsedResponse = response.getBody().substringBetween('<io:errorDescription>','</io:errorDescription>');
            }
            else
            {
                parsedResponse = 'OK';
            }
        }
        else
        {
            parsedResponse = response.getStatusCode() + ' - ' + response.getStatus();
        }

        return parsedResponse;
    }
}