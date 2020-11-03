/**
 * Clase Apex que personaliza el guardado de interacciones de Genesys Cloud para adaptar los procesos de guardado del conector.
 * Para pruebas unitarias, ejecutar el método a través de un Execute Anoyimous serializando un Mapa de mapas a JSON.
 * '{ "interaction" : { "id": "test1"} } '
 */
global without sharing class ReassignInteractionCTIExtension implements purecloud.CTIExtension.SaveLog
{
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
    public static String onSaveLog(String data)
    {
        Savepoint sp = Database.setSavepoint();

        try
        {
            String dataInteractionId = null;
            Map<String, Object> deserializedData = (Map<String, Object>) JSON.deserializeUntyped(
                data
                );
            if ( deserializedData.containsKey('interaction') )
            {
                Map<String, Object> dataInteraction = (Map<String, Object>) deserializedData.get(
                    'interaction'
                    );
                if ( dataInteraction.containsKey('id') )
                {
                    dataInteractionId = (String) dataInteraction.get('id');
                }
            }

            //Si no se ha recibido el id universal de Genesys, no hacer nada
            if (dataInteractionId == null)
            {
                return null;
            }

            //Buscar la task que tenga el mismo ucid
            List<Task> taskToUpdate = ActivitySelector.selectTasksByCallObjectIdentifier(
                dataInteractionId
                );
            if ( !taskToUpdate.isEmpty() )
            {
                //Actualizar la task con el usuario logado y devolver el ID
                taskToUpdate[0].OwnerId = UserInfo.getUserId();
                taskToUpdate[0].Status = 'Asignada';
                update taskToUpdate;
                return String.valueOf(taskToUpdate[0].Id);
            }
            else
            {
                //Si no coincide ninguna tarea, entonces hay que crearla
                Task interaction = new Task();
                interaction.Status = 'Asignada';
                interaction.OwnerId = UserInfo.getUserId();
                interaction.CallObject = dataInteractionId;
                interaction.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
                                           .get('Interaction')
                                           .getRecordTypeId();
                insert interaction;
                return String.valueOf(interaction.Id);
            }
        }
        catch (Exception e)
        {
            Database.rollback(sp);
            ErrorLogUtil.commitError(e);
        }

        return null;
    }
}
