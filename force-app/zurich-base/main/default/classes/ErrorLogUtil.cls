/**
 * Clase con la gestión de errores
 **
 * @author nts
 * @date 01/04/2020
 * @testClass Test_ErrorLogUtil
 */
public without sharing class ErrorLogUtil {
  public static final String ERROR_LEVEL_CRITICAL = 'Critical';
  public static final String ERROR_LEVEL_ERROR = 'Error';
  public static final String ERROR_LEVEL_WARNING = 'Warning';

  static final String SETTING_MIN_LOG_LEVEL;
  static final String SETTING_NOTIFY_TO;
  static final String SETTING_NOTIFY_FROM;
  static final Boolean SETTING_SEND_EMAIL;

  static {
    // Cargar los valores de configuración
    ErrorManagementSetting__mdt setup = SystemUtil.getErrorLogSettingsMetadata();

    /* SETTINGS */
    SETTING_MIN_LOG_LEVEL = setup.Min_Log_Level__c;
    SETTING_NOTIFY_TO = setup.Notify_To__c;
    SETTING_NOTIFY_FROM = setup.Notify_From__c;
    SETTING_SEND_EMAIL = setup.Send_Email__c;
  }

  public static void commitError(
    String level,
    String message,
    String throwingClass
  ) {
    /* Evitar mensajes mayores de la longitud de campo */
    if (String.isNotBlank(message) && message.length() > 131072) {
      Schema.DescribeFieldResult fieldInfo = Error_Log__c.Message__c.getDescribe();
      message = message.substring(0, fieldInfo.getLength() - 1);
    }

    publish(
      message,
      throwingClass,
      null, // throwingMethod
      null, // lineNumber
      level,
      null, // stackTrace
      null, //jobId
      null, //recordId
      null, //objectName
      null //type
    );
  }

  public static void commitError(
    Exception ex,
    String throwingClass,
    ID recordID
  ) {
    publish(
      ex.getMessage(),
      throwingClass,
      null,
      ex.getLineNumber(),
      ERROR_LEVEL_ERROR,
      ex.getStackTraceString(),
      null, //jobId
      recordID, //recordId
      null, //objectName
      ex.getTypeName() //type
    );
  }

  public static void commitError(Exception ex, String throwingClass) {
    publish(
      ex.getMessage(),
      throwingClass,
      null,
      ex.getLineNumber(),
      ERROR_LEVEL_ERROR,
      ex.getStackTraceString(),
      null, //jobId
      null, //recordId
      null, //objectName
      ex.getTypeName() //type
    );
  }
  public static void commitError(
    Exception ex,
    String throwingClass,
    String throwingMethod
  ) {
    publish(
      ex.getMessage(),
      throwingClass,
      throwingMethod,
      ex.getLineNumber(),
      ERROR_LEVEL_ERROR,
      ex.getStackTraceString(),
      null, //jobId
      null, //recordId
      null, //objectName
      ex.getTypeName() //type
    );
  }

  public static void commitError(Exception ex) {
    publish(
      ex.getMessage(),
      null,
      null,
      ex.getLineNumber(),
      ERROR_LEVEL_ERROR,
      ex.getStackTraceString(),
      null, //jobId
      null, //recordId
      null, //objectName
      ex.getTypeName() //type
    );
  }

  /**
   * Método que publica el evento de tipo Error
   **
   * @param String mensaje
   * @param String clase/trigger apex origen
   * @param String método origen
   * @param Integer linea
   * @param String nivel de error
   * @param String traza
   * @param String id del proceso (batch/job)
   * @param String id/external_id del registro
   * @param String nombre del objeto
   * @param String tipo de error
   *
   * @return Boolean isSuccess
   *
   * @author nts
   * @date 24/02/2020
   */
  private static Boolean publish(
    String message,
    String sourceClass,
    String sourceMethod,
    Integer lineNumber,
    String level,
    String stackTrace,
    String jobId,
    String recordId,
    String objectName,
    String type
  ) {
    // Lanzar el evento
    Database.SaveResult sr = Eventbus.publish(
      new Error_Event__e(
        Message__c = message,
        Source_Class__c = sourceClass,
        Source_Method__c = sourceMethod,
        Line_Number__c = lineNumber,
        Level__c = level,
        Stack_Trace__c = stackTrace,
        Job_ID__c = jobId,
        Record_External_ID__c = recordId,
        Record_Object__c = objectName,
        Type_Name__c = type,
        Throwing_time__c = System.now()
      )
    );

    return sr.isSuccess();
  }

  /**
   * Método registra en Salesforce el log de los errores
   **
   * @param List<Error_Event__e> eventos de tipo error
   *
   * @author nts
   * @date 24/02/2020
   */
  public static void handleErrors(List<Error_Event__e> evs) {
    List<Error_Log__c> errors = new List<Error_Log__c>();
    for (Error_Event__e e : evs) {
      errors.add(
        new Error_Log__c(
          Message__c = e.Message__c,
          Source_Class__c = e.Source_Class__c,
          Source_Method__c = e.Source_Method__c,
          Line_Number__c = e.Line_Number__c,
          Level__c = e.Level__c,
          Stack_Trace__c = e.Stack_Trace__c,
          Job_ID__c = e.Job_ID__c,
          Record_External_ID__c = e.Record_External_ID__c,
          Record_Object__c = e.Record_Object__c,
          Type_Name__c = e.Type_Name__c,
          Throwing_time__c = e.Throwing_time__c
        )
      );
    }

    if (!errors.isEmpty()) {
      Database.SaveResult[] srResults = Database.insert(errors, false);

      /* DEBUG */
      for (Database.SaveResult sr : srResults) {
        if (!sr.isSuccess()) {
          System.debug(
            LoggingLevel.ERROR,
            '[ERROR LOG] Excepción insertando registros de log:'
          );
          for (Database.Error err : sr.getErrors()) {
            System.debug(
              LoggingLevel.ERROR,
              err.getStatusCode() +
              ': ' +
              err.getMessage()
            );
            System.debug(
              LoggingLevel.ERROR,
              'ErrorLog fields that affected this error: ' + err.getFields()
            );
          }
        }
      }
      /* END DEBUG */
    }
  }

  /**
   * Método registra en Salesforce el log de los errores de integración
   **
   * @param List<ExternalRequestErrorEvent__e> eventos de tipo error específicos de integración
   *
   * @author xsobera
   * @date 06/10/2020
   */
  public static void handleExternalRequestErrors(
    List<ExternalRequestErrorEvent__e> evs
  ) {
    List<ExternalRequestError__c> errors = new List<ExternalRequestError__c>();
    for (ExternalRequestErrorEvent__e e : evs) {
      errors.add(
        new ExternalRequestError__c(
          Action__c = e.Action__c,
          ContentFormat__c = e.ContentFormat__c,
          Entity__c = e.Entity__c,
          ExternalRequestCreatedDate__c = e.ExternalRequestCreatedDate__c,
          JobId__c = e.JobId__c,
          Message__c = e.Message__c,
          Origin__c = e.Origin__c,
          Payload__c = e.Payload__c,
          RecordId__c = e.RecordId__c,
          StackTrace__c = e.StackTrace__c,
          ThrowingTime__c = e.ThrowingTime__c
        )
      );
    }

    if (!errors.isEmpty()) {
      Database.DMLOptions dmo = new Database.DMLOptions();
      dmo.AllowFieldTruncation = true;
      dmo.OptAllOrNone = false;

      Database.SaveResult[] srResults = Database.insert(errors, dmo);

      /* DEBUG */
      for (Database.SaveResult sr : srResults) {
        if (!sr.isSuccess()) {
          System.debug(
            LoggingLevel.ERROR,
            '[ERROR LOG] Excepción insertando registros de log:'
          );
          for (Database.Error err : sr.getErrors()) {
            System.debug(
              LoggingLevel.ERROR,
              err.getStatusCode() +
              ': ' +
              err.getMessage()
            );
            System.debug(
              LoggingLevel.ERROR,
              'ErrorLog fields that affected this error: ' + err.getFields()
            );
          }
        }
      }
      /* END DEBUG */
    }
  }

  /**
   * Método envía el log de los errores
   **
   * @param List<Error_Log__c> registros de error
   *
   * @author nts
   * @date 24/02/2020
   */
  public static void notifyErrors(List<Error_Log__c> errors) {
    System.debug('[ERROR LOG] Preparando para notificar errores');
    if (errors != null && SETTING_SEND_EMAIL == true) {
      List<String> recipients = new List<String>();
      if (String.isNotBlank(SETTING_NOTIFY_TO)) {
        List<String> aux = SETTING_NOTIFY_TO.split(',');
        if (aux != null && !aux.isEmpty()) {
          recipients.addAll(aux);
        }
      }
      if (!recipients.isEmpty()) {
        List<String> errHtmlTableLines = new List<String>();
        for (Error_Log__c err : errors) {
          if (isErrorSendable(err)) {
            errHtmlTableLines.add(
              '<tr><td>' +
              err.Id +
              '</td><td>' +
              err.Message__c +
              '</td><td>' +
              err.Level__c +
              '</td><td>' +
              String.valueOfGmt(err.CreatedDate) +
              '</td><td><a href="' +
              System.URL.getSalesforceBaseUrl().toExternalForm() +
              '/' +
              err.Id +
              '">Enlace a error</a></td></tr>'
            );
          }
        }

        if (!errHtmlTableLines.isEmpty()) {
          String subject = '[ERROR LOG] Se ha producido un error que debe ser revisado';
          String errHtmlTemplate =
            '<p>Se han detectado los siguentes errores en la instancia de <a href="' +
            System.URL.getSalesforceBaseUrl().toExternalForm() +
            '">Salesforce</a></p>' +
            '<table style="width:100%">' +
            '<tr>' +
            '<th>ID</th>' +
            '<th>Mensaje</th> ' +
            '<th>Nivel</th>' +
            '<th>Fecha</th>' +
            '<th>Enlace</th>' +
            '</tr>' +
            '{{lines}}' +
            '</table>';

          errHtmlTemplate = errHtmlTemplate.replace(
            '{{lines}}',
            String.join(errHtmlTableLines, '')
          );

          /* Obtener from */
          String auxAddress = SETTING_NOTIFY_FROM;
          OrgWideEmailAddress fromEmail;
          if (Test.isRunningTest()) {
            fromEmail = new OrgWideEmailAddress(Address = SETTING_NOTIFY_FROM);
          } else {
            fromEmail = [
              SELECT Id
              FROM OrgWideEmailAddress
              WHERE Address = :auxAddress
              LIMIT 1
            ];
          }

          try {
            System.debug('[ERROR LOG] Preparando envío ...');
            /* Construir el email */
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSubject(subject);
            email.setToAddresses(recipients);
            email.setHtmlBody(errHtmlTemplate);
            email.setOrgWideEmailAddressId(fromEmail.Id);
            Messaging.sendEmail(
              new List<Messaging.SingleEmailMessage>{ email }
            );
            System.debug('[ERROR LOG] OK!');
          } catch (EmailException ex) {
            System.debug(
              LoggingLevel.ERROR,
              '[ERROR LOG] No se ha podido enviar el email de notifiación de errores'
            );
            System.debug(LoggingLevel.ERROR, 'Mensaje: ' + ex.getMessage());
            System.debug(
              LoggingLevel.ERROR,
              'Trace: ' + ex.getStackTraceString()
            );
          }
        } else {
          System.debug(
            LoggingLevel.WARN,
            '[ERROR LOG] No hay ningún error que cumple la configuración mínima para ser notificado'
          );
        }
      } else {
        System.debug(
          LoggingLevel.WARN,
          '[ERROR LOG] No se ha especificado ninguna dirección de email para notificar los errores registrados'
        );
      }
    }
    System.debug('[ERROR LOG] Fin de notificar errores');
  }

  /**
   * Método que comprueba si un error se debe enviar
   * según la configuración especificada en el sistema
   **
   * @param Error_Log__c registro de error
   *
   * @author nts
   * @date 24/02/2020
   */
  private static Boolean isErrorSendable(Error_Log__c err) {
    Boolean isSendable = false;

    if (
      SETTING_MIN_LOG_LEVEL == ERROR_LEVEL_WARNING &&
      (err.Level__c == ERROR_LEVEL_WARNING ||
      err.Level__c == ERROR_LEVEL_ERROR ||
      err.Level__c == ERROR_LEVEL_CRITICAL)
    ) {
      isSendable = true;
    }

    if (
      SETTING_MIN_LOG_LEVEL == ERROR_LEVEL_ERROR &&
      (err.Level__c == ERROR_LEVEL_ERROR ||
      err.Level__c == ERROR_LEVEL_CRITICAL)
    ) {
      isSendable = true;
    }

    if (
      SETTING_MIN_LOG_LEVEL == ERROR_LEVEL_CRITICAL &&
      err.Level__c == ERROR_LEVEL_CRITICAL
    ) {
      isSendable = true;
    }

    return isSendable;
  }
}
