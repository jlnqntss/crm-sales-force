abstract global without sharing class WS_BaseAPIService {
  private static final String REGEXP_VERSION_VALIDATION = 'v[0-9]+$';
  private static String[] urlTokens = RestContext.request.requestURI.split('/');
  private static Map<String, String> requestHeaders = RestContext.request.headers;
  public static Integer version {
    get {
      if(isValidVersion)
      {
        return Integer.valueOf(urlTokens[2].remove('v'));
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
        return Pattern.matches(REGEXP_VERSION_VALIDATION, urlTokens.get(2));
      }
      else
      {
        return false;
      }
    }
  }

  public static Boolean isJSONContentType {
    get {
      if(requestHeaders.containsKey('Content-Type') && requestHeaders.get('Content-Type').contains('application/json'))
      {
        return true;
      }
      else {
        return false;
      }
    }
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
    public String message;
    public String errorDetail;

    public ApiException(String statusCode, String message)
    {
      this.setMessage(message);
      this.message = this.getMessage();
      this.statusCode = statusCode;
      this.errorDetail = this.getStackTraceString();

      ErrorLogUtil.commitError(this);
    }
  }
}
