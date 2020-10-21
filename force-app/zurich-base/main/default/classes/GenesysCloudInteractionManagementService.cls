public without sharing class GenesysCloudInteractionManagementService {
  /**
   * Sirve a WS_GenesysCloudInteractions
   * Deja un registro de la interacción entrante en
   * Salesforce por si el usuario abandona
   * @author nescudero
   * @date 21/10/2020
   */
  public static String createOnqueueInteraction() {
    String taskId;

    Id rtId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
      .get('Interaction')
      .getRecordTypeId();

    Task interaction = new Task();
    interaction.Status = 'Nueva';
    interaction.Priority = 'Normal';
    insert interaction;

    taskId = String.valueOf(interaction.Id);

    return taskId;
  }
}
