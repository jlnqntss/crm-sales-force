/**
 * Clase que implementa el rest Web Service a consumir por sistemas externos
 *
 **
 * @author nbizkarra
 * @date 07/05/2020
 */
@RestResource(urlMapping = '/request/*')
global without sharing class WS_Requests
{
    /**
     * Metodo Post que recibe la información del sistema externo e inserta un objeto ExternalRequest__c
     * Devuelve el ID del objeto creado, utilizado como ID de transacción
     * @author nbizkarra
     * @date 07/05/2020
     */
    @HttpPost
    global static ID doPost()
    {
        Map<String, String> headers = RestContext.request.headers;

        // 1 - Se comprueba si el cuerpo de la petición es un JSON
        if (
            !headers.containsKey('Content-Type') ||
            !headers.get('Content-Type').equals('application/json')
            )
        {
            throw new RESTExampleException('Content-Type must be application/json');
        }

        // 2 - Parseamos la petición

        Map<String, Object> request = (Map<String, Object>) JSON.deserializeUntyped(
            RestContext.request.requestBody.toString()
            );

        // 3 - Creamos objeto ExternalRequest
        System.debug(request.get('Timestamp') );
        ExternalRequest__c req = new ExternalRequest__c(
            Origin__c = (String) request.get('Origin'),
            Country__c = (String) request.get('Country'),
            Entity__c = (String) request.get('Entity'),
            Timestamp__c = Datetime.valueOf( (String) request.get('Timestamp') ),
            Json__c = JSON.serialize(request.get('Json') )
            );

        insert req;
        return req.Id;
    }

    class RESTExampleException extends Exception
    {}
}