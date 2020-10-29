public without sharing class GenesysInteractionsService {

  static final String MISSING_FIELDS_REQUIRED = 'some required fields are missing';
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
    BestAgent ba = new BestAgent(screenPopRecordId, callLogId, bestAgentId); //Se devolverá todo a null si no entra en el flujo

    if (version == 1) {
      //Si el servicio no recibe el from, to o interactionType, devolverá un KO
      if (
        request.interactionType == null ||
        request.fromId == null ||
        request.toId == null
      ) {
        throw new WS_BaseAPIService.ApiException('BAD_REQUEST', MISSING_FIELDS_REQUIRED);
      }

      //Si el servicio no recibe ucid, no generará tarea y por tanto no devolverá callLogId
      if (request.interaction != null) {
        //1º Dejar un registro de la interacción entrante en Salesforce por si el usuario abandona
        callLogId = createOnqueueInteraction(request.interaction);
      }

      //Si el servicio no recibe lookFor, no buscará el bestAgentId ni screenPopRecordId
      if (request.lookFor != null) {
        //2º Identificar al cliente y el último registro de interés abierto (Oportunidad/Caso).
        //3º Identificar al gestor preferente (usuario) de la interacción
        ba = findBestAgentFor(
          callLogId,
          request.interactionType,
          request.fromId,
          request.toId,
          request.lookFor,
          request.scope
        );
      }
    }

    //Devolver BestAgent
    return ba;
  }

  /**
   * WIP: Falta definir qué campos rellenar en la task
   * @author nescudero
   * @date 22/10/2020
   */
  @TestVisible
  private static String createOnqueueInteraction(String ucid) {
    Id rtId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
      .get('Interaction')
      .getRecordTypeId();

    //WIP
    Task interaction = new Task();
    interaction.Status = 'Nueva';
    interaction.Priority = 'Normal';
    interaction.CallObject = ucid;
    interaction.RecordTypeId = rtId;
    insert interaction;

    String taskId = String.valueOf(interaction.Id);

    return taskId;
  }

  /**
   * 1. Si hay múltiples clientes => Tenemos que decidirlo. De momento, recordId=null y bestAgentId=null
    2. Si hay múltiples casos de un mismo cliente =>  RecordId=ID_CLIENTE y *bestAgentId="Case/opportutiny.Owner.Email" del último caso abierto => Si OWner es una cola null
    3. Si hay solo hay una coincidencia => RecordId=ID_CLIENTE y *bestAgentId="Case/opportutiny.Owner.Email"   => Si Owner es una cola null
   * @author nescudero
   * @date 23/10/2020
   */
  @TestVisible
  private static BestAgent findBestAgentFor(
    String callLogId,
    String interactionType,
    String fromId,
    String toId,
    String lookFor,
    String scope
  ) {
    Id ownerId;
    String contactPoint;
    Boolean isContactPointPhone;
    String screenPopRecordId;
    String bestAgentId;
    Set<Id> userIds = new Set<Id>();

    //buscar en fromId o toId depende de interactionType
    switch on interactionType {
      when 'Inbound' {
        contactPoint = fromId;
      }
      when 'Outbound' {
        contactPoint = toId;
      }
    }

    //Ver si hay que buscar en ContactPointPhone o ContactPointEmail
    if (contactPoint.isNumeric()) {
      isContactPointPhone = true;
    } else {
      isContactPointPhone = false;
    }

    //Buscar el contacto
    if (isContactPointPhone) {
      List<ContactPointPhone> contactPointPhones = new List<ContactPointPhone>();
      contactPointPhones = [
        SELECT Id, TelephoneNumber, ContactId__c
        FROM ContactPointPhone
        WHERE TelephoneNumber = :contactPoint
      ];

      //1. Si hay múltiples clientes => Se aglutinan y se devuelve el registro más reciente
      for (ContactPointPhone contactPointPhone : contactPointPhones) {
        userIds.add(contactPointPhone.ContactId__c);
      }
    } else {
      List<ContactPointEmail> contactPointEmails = new List<ContactPointEmail>();
      contactPointEmails = [
        SELECT Id, EmailAddress, ContactId__c
        FROM ContactPointEmail
        WHERE EmailAddress = :contactPoint
      ];

      //1. Si hay múltiples clientes => Se aglutinan y se devuelve el registro más reciente
      for (ContactPointEmail contactPointEmail : contactPointEmails) {
        userIds.add(contactPointEmail.ContactId__c);
      }
    }

    //una vez se tiene el contacto elegido se busca su Case/Opp
    if (!userIds.isEmpty()) {
      //Dependiendo de scope
      String scopeFilter = '';
      switch on scope {
        when 'all' {
          scopeFilter = 'AND Scope__c = \'General\''; //TODO: cuando esté definido esto pasar a label?
        }
        when 'ze' {
          scopeFilter = 'AND Scope__c = \'Zurich Empresas\''; //TODO: cuando esté definido esto pasar a label?
        }
        when 'klinc' {
          scopeFilter = 'AND Scope__c = \'Klinc\''; //TODO: cuando esté definido esto pasar a label?
        }
      }

      //Dependiendo de lookFor
      switch on lookFor {
        when 'Opportunity' {
          List<Opportunity> opps = new List<Opportunity>();
          String query =
            'SELECT OwnerId, ContactId__c, isClosed, CreatedDate, Owner.Email FROM Opportunity WHERE isClosed = FALSE AND ContactId__c IN :userIds ' +
            scopeFilter +
            ' ORDER BY CreatedDate DESC';
          opps = Database.query(query);
          if (!opps.isEmpty()) {
            bestAgentId = opps[0].Owner.Email;
            screenPopRecordId = opps[0].ContactId__c;
            ownerId = opps[0].OwnerId;
          }
        }
        when 'Case' {
          List<Case> cases = new List<Case>();
          cases = [
            SELECT
              OwnerId,
              ContactId,
              isClosed,
              CreatedDate,
              TYPEOF Owner
                WHEN User THEN Email
              END
            FROM Case
            WHERE isClosed = FALSE AND ContactId IN :userIds
            ORDER BY CreatedDate DESC
          ];
          if (!cases.isEmpty()) {
            bestAgentId = cases[0].Owner.Email;
            screenPopRecordId = cases[0].ContactId;
            ownerId = cases[0].OwnerId;
          }
        }
      }
    }

    //Actualizar la tarea si se ha conseguido el bestagent
    if (bestAgentId != null && callLogId != null) {
      Task interaction = new Task();
      interaction.Id = Id.valueOf(callLogId);
      interaction.BestAgent__c = ownerId;
      update interaction;
    }

    //Si todo ha ido bien, screenPopRecordId y bestAgentId estarán rellenos, sino se envían a null
    BestAgent ba = new BestAgent(screenPopRecordId, callLogId, bestAgentId);
    return ba;
  }

  //Entrada
  public class InteractionRequest {
    public String interaction { get; set; }
    public String interactionType { get; set; }
    public String fromId { get; set; }
    public String toId { get; set; }
    public String queueId { get; set; }
    public String lookFor { get; set; }
    public String scope { get; set; }
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
