abstract global without sharing class WS_BaseAPIService {
  /** Ejemplo: split /genesys-cloud/v1/interactions/init por '/'
   * [0] = ''
   * [1] = genesys-cloud
   * [2] = v1
   * [3] = interactions
   */
  private static String[] urlTokens = RestContext.request.requestURI.split('/');
  public static Integer version {
    get {
      return Integer.valueOf(urlTokens[2].remove('v'));
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
}
