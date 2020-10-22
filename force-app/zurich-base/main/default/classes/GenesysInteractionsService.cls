public without sharing class GenesysInteractionsService {
  public class GenesysInteractionsServiceException extends Exception {
  }

  public static Integer version { get; set; }

  /**
   * Sirve a WS_GenesysAPIService
   * Implemental la lógica de iniciar una interacción:
   * 1º crea una tarea
   * 2º busca al cliente y su registro más antiguo
   * 3º consigue el Owner del registro y lo devuelve como el BestAgent
   * @author nescudero
   * @date 22/10/2020
   */
  public static BestAgent initInteraction(InteractionRequest request) {
    String screenPopRecordId;
    String callLogId;
    String bestAgentId;

    //Ahora mismo solo hay una versión del servicio
    if (version != 1) {
      version = 1;
    }

    if (version == 1) {
      //Si el servicio no recibe el from, to o interactionType, devolverá un KO
      if (
        request.interactionType == null ||
        request.fromId == null ||
        request.toId == null
      ) {
        throw new GenesysInteractionsServiceException(
          'BAD_REQUEST: some required fields are missing'
        );
      }

      //Si el servicio no recibe ucid, no generará tarea y por tanto no devolverá callLogId
      if (request.queueId != null) {
        //1º Dejar un registro de la interacción entrante en Salesforce por si el usuario abandona
        callLogId = createOnqueueInteraction();
      }

      //2º Identificar al cliente y el último registro de interés abierto (Oportunidad/Caso). Admite como parámetro de entrada si
      screenPopRecordId = findCustomerInterest();

      //Si el servicio no recibe lookFor, no buscará el bestAgentId
      if (request.lookFor != null) {
        //3º Identificar al gestor preferente (usuario) de la interacción
        bestAgentId = findBestAgentFor();
      }
    }

    //Devolver BestAgent
    BestAgent ba = new BestAgent(screenPopRecordId, callLogId, bestAgentId);
    return ba;
  }

  /**
   * WIP: Falta definir qué campos rellenar en la task
   * @author nescudero
   * @date 22/10/2020
   */
  private static String createOnqueueInteraction() {
    Id rtId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
      .get('Interaction')
      .getRecordTypeId();

    //WIP
    Task interaction = new Task();
    interaction.Status = 'Nueva';
    interaction.Priority = 'Normal';
    insert interaction;

    String taskId = String.valueOf(interaction.Id);

    return taskId;
  }

  /**
   * WIP: Falta definir
   * @author nescudero
   * @date 22/10/2020
   */
  private static String findCustomerInterest() {
    //Ver si hay que buscar en ContactPointPhone o ContactPointEmail

    //Buscar el contacto

    //si no existe contacto --> Error

    //Buscar el registro Case u Opportunity más reciente creado para dicho cliente

    return 'caseOppId';
  }

  /**
   * WIP: Falta definir
   * @author nescudero
   * @date 22/10/2020
   */
  private static String findBestAgentFor() {
    //¿Recibe como parámetro screenPopRecordId o solo lookFor?
    //Devuelve el OwnerId del registro Case u Opportunity más reciente creado para dicho cliente (Depende de LookFor)
    return 'ownerId';
  }

  //Entrada
  public class InteractionRequest {
    public String interaction { get; set; }
    public String interactionType { get; set; }
    public String fromId { get; set; }
    public String toId { get; set; }
    public String queueId { get; set; }
    public String lookFor { get; set; }
  }

  //Salida
  public class BestAgent {
    public String screenPopRecordId { get; set; }
    public String callLogId { get; set; }
    public String bestAgentId { get; set; }

    public BestAgent(
      String screenPopRecordId,
      String callLogId,
      String bestAgentId
    ) {
      this.screenPopRecordId = screenPopRecordId;
      this.callLogId = callLogId;
      this.bestAgentId = bestAgentId;
    }
  }
}
