abstract global without sharing class WS_BaseAPIService
{
    private static final String REGEXP_VERSION_VALIDATION = 'v[0-9]+$';
    private static String[] urlTokens = RestContext.request.requestURI.split('/');
    private static Map<String, String> requestHeaders = RestContext.request.headers;
    public static Integer version {
        get {
            if(isValidVersion)
            {
                return Integer.valueOf(urlTokens[2].remove('v') );
            }
            else
            {
                return 1;
            }
        }
    }
    public static String vendor {
        get {
            return String.valueOf(urlTokens[1]);
        }
    }
    public static String resource {
        get {
            return String.valueOf(urlTokens[3]);
        }
    }

    public static Boolean isValidVersion {
        get {
            if(!urlTokens.isEmpty() && urlTokens.get(2) != null)
            {
                return Pattern.matches(REGEXP_VERSION_VALIDATION, urlTokens.get(2) );
            }
            else
            {
                return false;
            }
        }
    }

    public static Boolean isJSONContentType {
        get {
            if(requestHeaders.containsKey('Content-Type') && requestHeaders.get('Content-Type').contains('application/json') )
            {
                return true;
            }
            else
            {
                return false;
            }
        }
    }


    public final static String API_BAD_REQUEST_KO = 'BAD_REQUEST';
    public final static String API_GENERIC_KO = 'GENERIC_ERROR';
    public final static String API_DML_KO = 'DML_ERROR';
    public final static String API_DML_RECORD_ERROR_MESSAGE  = Label.RESTApiErrorOnDMLRecordTransaction;

    private static String builDMLMessage(DmlException dmlError)
    {
        List<String> messages = new List<String>();
        Integer i = dmlError.getNumDml();

        while(i > 0)
        {
            messages.add(String.format(API_DML_RECORD_ERROR_MESSAGE, new List<String>
            {
                dmlError.getDmlType(i).name(),
                dmlError.getDmlMessage(i),
                dmlError.getDmlId(i),
                String.join(dmlError.getDmlFieldNames(i), ', ')
            }) );
        }

        return String.join(messages, '\n');
    }

    /**
     * Clase para construir Errores en el WebService
     * Siempre hará uso del ErrorLogUtil
     * @author rlopez
     * @date 29/10/2020
     */
    public class ApiException extends Exception
    {
        public String statusCode;
        public String errorDetail
        {
            get
            {
                return this.getStackTraceString();
            }
        }

        public String message
        {
            get
            {
                return this.getMessage();
            }
        }

        /**
         * Constructor por defecto
         * @author rlopez
         * @date 29/10/2020
         */
        public ApiException(String statusCode, String message)
        {
            this.setMessage(message);
            this.statusCode = statusCode;

            ErrorLogUtil.commitError(this);
        }


        /**
         * Genera un mensaje de error con el detalle de la excepción DML
         *
         * @author jmartinezpisson
         * @date 02/11/2020
         * @param  dmlError Excepción DML
         */
        public ApiException(DmlException dmlError)
        {
            this(API_DML_KO, builDMLMessage(dmLError) );
        }

        /**
         * Sobreescribe el toString para devolve un JSON
         *
         * @author jmartinezpisson
         * @date 02/11/2020
         * @return   JSON formateado con el error y el Stack tarce
         */
        public String toErrorString()
        {
            System.debug(this);
            return JSON.serialize(new Map<String, String>
            {
                'message' => this.getMessage(),
                'trace' => this.getStackTraceString()
            });
        }
    }
}
