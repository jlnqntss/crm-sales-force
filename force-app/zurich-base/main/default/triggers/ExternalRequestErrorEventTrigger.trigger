/**
 * Trigger que captura los eventos de ExternalRequestError
 **
 * @author xsobera
 * @date 06/10/2020
 */
trigger ExternalRequestErrorEventTrigger on ExternalRequestErrorEvent__e(
  after insert
) {
  if (Trigger.New != null) {
    ErrorLogUtil.handleExternalRequestErrors(
      (List<ExternalRequestErrorEvent__e>) Trigger.New
    );
  }
}
