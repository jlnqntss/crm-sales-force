abstract global without sharing class WS_BaseAPIService {
  /** Ejemplo: split /genesys-cloud/v1/interactions/init por '/'
   * [0] = ''
   * [1] = genesys-cloud
   * [2] = v1
   * [3] = interactions
   */
  private static final String REGEXP_VERSION_VALIDATION = 'v[0-9]+$';
  private static String[] urlTokens = RestContext.request.requestURI.split('/');
  private static Map<String, String> requestHeaders = RestContext.request.headers;
  public static Integer version {
    get {
      if (isValidVersion) {
        return Integer.valueOf(urlTokens[2].remove('v'));
      } else {
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
      if (!urlTokens.isEmpty() && urlTokens.get(2) != null) {
        return Pattern.matches(REGEXP_VERSION_VALIDATION, urlTokens.get(2));
      } else {
        return false;
      }
    }
  }

  public static Boolean isJSONContentType {
    get {
      if (
        requestHeaders.containsKey('Content-Type') &&
        requestHeaders.get('Content-Type') == 'application/json'
      ) {
        return true;
      } else {
        return false;
      }
    }
  }

  /**
   * Clase para construir Errores en el WebService
   * Siempre hará uso del ErrorLogUtil
   * @author nescudero
   * @date 22/10/2020
   */
  global class WS_BaseAPIServiceError {
    public String errorCode { get; set; }
    public String message { get; set; }
    public String errorDetail { get; set; }

    public WS_BaseAPIServiceError(
      Exception ex,
      String errorCode,
      String message,
      String errorDetail
    ) {
      ErrorLogUtil.commitError(ex);

      this.errorCode = errorCode;
      this.message = message;
      this.errorDetail = errorDetail;
    }
  }

  /**
   * Clase para construir Errores en el WebService
   * Siempre hará uso del ErrorLogUtil
   * @author rlopez
   * @date 29/10/2020
   */
  public class ApiException extends Exception {
    public String statusCode;
    public String message;
    public String errorDetail;

    public ApiException(String statusCode, String message) {
      this.setMessage(message);
      this.message = this.getMessage();
      this.statusCode = statusCode;
      this.errorDetail = this.getStackTraceString();

      System.debug('errorDetail: ' + errorDetail);

      ErrorLogUtil.commitError(this);
    }
  }
}
