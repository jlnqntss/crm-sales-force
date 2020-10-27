/**
 * Clase Apex que personaliza el guardado de interacciones de Genesys Cloud para adaptar los procesos de guardado del conector.
 */
global without sharing class ReassignInteractionCTIExtension implements purecloud.CTIExtension.SaveLog {
  /**
   * Identifica una tarea a través del parámetro data.interaction.id y devuelve dicha tarea modificando el usuario Asignado
   * @param data: JSON string con la información de Genesys Cloud
   * data.eventName: Representa ele vento que lanza la creación/actualización del Call Log
   * data.interaction: Representa la interacción de Genesys
   * data.interaction.id: Interaction Id. Debe usarse para buscar la tarea a partir del campo CallObjectIdentifier
   * @return Identificado de la tarea creada/actualizada
   * @author nescudero
   * @date 27/10/2020
   * @consideraciones El parámetro data llega como un JSON que debe ser deserializado mediante JSON.deserialize
   * Enlace a documentación de la interfaz: https://help.mypurecloud.com/articles/use-the-extension-points-to-customize-saving-interaction-logs/
   */
  public String onSaveLog(String data) {
    // Example: Save interaction log as Task record after interaction is disconnected.
    Map<String, Object> saveLogData = (Map<String, Object>) JSON.deserializeUntyped(
      data
    );
    Map<String, Object> interaction = (Map<String, Object>) saveLogData.get(
      'interaction'
    );
    Map<String, Object> callLog = (Map<String, Object>) saveLogData.get(
      'callLog'
    );
    Boolean isDisconnected = (Boolean) interaction.get('isDisconnected');
    String callLogId = '';
    if (isDisconnected) {
      Task t = (Task) JSON.deserialize(JSON.serialize(callLog), Task.class);
      upsert t;
      callLogId = t.Id;
    }
    return callLogId;
  }
}
