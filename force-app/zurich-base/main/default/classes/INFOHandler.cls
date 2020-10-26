/**
 * Clase handler de INFO
 * Procesa las external request cuyo origen sea INFO con la ayuda de la clase Transformer
 **
 * @author adelgado
 * @date 13/10/2020
 */
public class INFOHandler implements ISystem 
{
  @testVisible
  private static Map<String, Map<sObject, ExternalRequest__c>> recordsToUpsertByObject = new Map<String, Map<sObject, ExternalRequest__c>>();
  @testVisible
  private static List<ExternalRequest__c> externalRequestResultList = new List<ExternalRequest__c>();

  // CUSTOM METATDATA
  @testVisible
  private static Transformer tf = new Transformer(Transformer.ORIGIN_NAME_INFO);
  @testVisible
  private static Map<String, String> externalIdByObject = new Map<String, String>();
  @testVisible
  private static Integer maxRetries;

  // Orden de DML sobre entidades
  private static List<String> entityOrder = new List<String>
  {
    'Account',              // 1
    'Contact',              // 2
    'ContactPointAddress',  // 3
    'ContactPointPhone',    // 4
    'ContactPointEmail',    // 5
    'Product2',             // 6
    'Policy__c',            // 7
    'PolicyVersion__c',     // 8
    'InsuredObject',        // 9
    'Opportunity',          // 10
    'Relationship__c'       // 11
  };

  /**
   * Obtiene la información necesaria para poder procesar las external request pendientes
   **
   * @author adelgado
   * @date 13/10/2020
   * @param externalRequestList Lista de external request que deben ser procesadas
   * @return void
   * @throws
   * @where ExternalJobQueueBatch
   */
  public static void prepare( List<ExternalRequest__c> externalRequestList ) 
  {
    // 1 - Creación de un mapa con una clave por cada entidad del CRM que se utilice en la integración con INFO
    recordsToUpsertByObject = tf.initRequestsMapBySettings();

    // 2 - Obtener identificadores externos por cada entidad
    for (ExternalIdField__mdt externalId : [SELECT SalesforceEntity__c, ExternalId__c FROM ExternalIdField__mdt WHERE Origin__c = 'INFO'])
    {
      externalIdByObject.put(externalId.SalesforceEntity__c, externalId.ExternalId__c);
    }

    // 3 - Obtener el número máximo de reintentos
    maxRetries = (Integer) [SELECT Retries__c FROM ExternalJobQueueBatch__mdt WHERE Origin__c = 'INFO'].Retries__c;
  }

  /**
   * Realiza las transformaciones necesarias para procesar las external request recibidas y convertirlas en objetos de Salesforce
   **
   * @author adelgado
   * @date 13/10/2020
   * @param externalRequestList Lista de external request que deben ser procesadas
   * @return void
   * @throws
   * @where ExternalJobQueueBatch
   */
  public static void process( List<ExternalRequest__c> externalRequestList ) 
  {
    // 1 - Recorrer todas las external request recibidas
    for (ExternalRequest__c externalRequest : externalRequestList) 
    {
      try 
      {
        // 1.1 - Comprobar si el contenido de la solicitud está en formato JSON
        if (externalRequest.ContentFormat__c == 'JSON' && String.isNotBlank(externalRequest.Payload__c)) 
        {
          // 1.1.1 - Transformar el contenido del JSON a una estructura Map
          Map<String, Object> recordValuesMap = (Map<String, Object>) JSON.deserializeUntyped(externalRequest.Payload__c);

          // 1.1.2 - Convertir a mayúsculas todas las claves del mapa de campos de INFO
          for (string field : recordValuesMap.keySet()) 
          {
            recordValuesMap.put(field.toUpperCase(), recordValuesMap.get(field));
          }

          // 1.1.3 - Realizar las transformaciones necesarias en base a la entidad de INFO
          switch on externalRequest.Entity__c.toUpperCase() 
          {
            // Persona
            when 'ACCOUNT'
            {
              if (recordValuesMap.containsKey('CLIENTE_TIPO_PERSONA')) 
              {
                // Persona física
                if (((String) recordValuesMap.get('CLIENTE_TIPO_PERSONA')).equalsIgnoreCase('F')) 
                {
                  Account accountRecord = (Account) tf.transform('Account', recordValuesMap);
                  accountRecord.FirstName = recordValuesMap.containsKey('CLIENTE_NOMBRE') ? (String) recordValuesMap.get('CLIENTE_NOMBRE') : null;
                  accountRecord.LastName = (recordValuesMap.containsKey('CLIENTE_APELLIDO1') ? (String) recordValuesMap.get('CLIENTE_APELLIDO1') : null) + ' ' 
                                          + (recordValuesMap.containsKey('CLIENTE_APELLIDO2') ? (String) recordValuesMap.get('CLIENTE_APELLIDO2') : null);
                  accountRecord.LegalEntity__pc = recordValuesMap.containsKey('CLIENTE_ENTIDAD_LEGAL') ? (String) recordValuesMap.get('CLIENTE_ENTIDAD_LEGAL') : null;                        
                  accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
                  recordsToUpsertByObject.get('Account').put(accountRecord, externalRequest);
                } 
                else if (((String) recordValuesMap.get('CLIENTE_TIPO_PERSONA')).equalsIgnoreCase('J')) 
                {
                  // Persona jurídica
                  Account accountRecord = (Account) tf.transform('Account', recordValuesMap);
                  accountRecord.Name = (recordValuesMap.containsKey('CLIENTE_NOMBRE') ? (String) recordValuesMap.get('CLIENTE_NOMBRE') : null) + ' ' 
                                      + (recordValuesMap.containsKey('CLIENTE_APELLIDO1') ? (String) recordValuesMap.get('CLIENTE_APELLIDO1'): null) + ' ' 
                                      + (recordValuesMap.containsKey('CLIENTE_APELLIDO2') ? (String) recordValuesMap.get('CLIENTE_APELLIDO2') : null);
                  accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('BusinessCustomer').getRecordTypeId();
                  recordsToUpsertByObject.get('Account').put(accountRecord, externalRequest);

                  Contact contactRecord = (Contact) tf.transform('Contact', recordValuesMap);
                  contactRecord.FirstName = recordValuesMap.containsKey('CLIENTE_NOMBRE') ? (String) recordValuesMap.get('CLIENTE_NOMBRE') : null;
                  contactRecord.LastName = (recordValuesMap.containsKey('CLIENTE_APELLIDO1') ? (String) recordValuesMap.get('CLIENTE_APELLIDO1') : null) + ' ' 
                                          + (recordValuesMap.containsKey('CLIENTE_APELLIDO2') ? (String) recordValuesMap.get('CLIENTE_APELLIDO2') : null);
                  contactRecord.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('CustomerGI').getRecordTypeId();
                  recordsToUpsertByObject.get('Contact').put(contactRecord, null);
                }
                else 
                {
                  externalRequest.ProcessResult__c = 'KO';
                  externalRequest.Error_Log__c = 'No se ha podido identificar el tipo de cliente';
                  externalRequest.Processed__c = true;
                  externalRequestResultList.add(externalRequest);
                }
              }
            }
            // Vía de contacto
            when 'CONTACT_POINT'
            {
              if(recordValuesMap.containsKey('TIPO_DOMICILIO'))
              {
                // Vía de contacto postal (A, B, P)
                if(((String) recordValuesMap.get('TIPO_DOMICILIO')).equalsIgnoreCase('A') 
                  || ((String) recordValuesMap.get('TIPO_DOMICILIO')).equalsIgnoreCase('B') 
                    || ((String) recordValuesMap.get('TIPO_DOMICILIO')).equalsIgnoreCase('P'))
                {
                  ContactPointAddress cpaRecord = (ContactPointAddress) tf.transform('ContactPointAddress', recordValuesMap);
                  recordsToUpsertByObject.get('ContactPointAddress').put(cpaRecord, externalRequest);
                }
                //  Vía de contacto telefónico (T)
                else if(((String) recordValuesMap.get('TIPO_DOMICILIO')).equalsIgnoreCase('T'))
                {
                  ContactPointPhone cppRecord = (ContactPointPhone) tf.transform('ContactPointPhone', recordValuesMap);
                  recordsToUpsertByObject.get('ContactPointPhone').put(cppRecord, externalRequest);
                }
                // Vía de contacto email (E)
                else if(((String) recordValuesMap.get('TIPO_DOMICILIO')).equalsIgnoreCase('E'))
                {
                  ContactPointEmail cpeRecord = (ContactPointEmail) tf.transform('ContactPointEmail', recordValuesMap);
                  recordsToUpsertByObject.get('ContactPointEmail').put(cpeRecord, externalRequest);
                }
                else 
                {
                  externalRequest.ProcessResult__c = 'KO';
                  externalRequest.Error_Log__c = 'No se ha podido identificar el tipo de vía de contacto';
                  externalRequest.Processed__c = true;
                  externalRequestResultList.add(externalRequest);
                }
              }
            }
            when else 
            {	
              externalRequest.ProcessResult__c = 'KO';
              externalRequest.Error_Log__c = 'No se ha encontrado la entidad indicada';
              externalRequest.NumRetry__c = externalRequest.NumRetry__c == null ? 1 : externalRequest.NumRetry__c + 1;
              externalRequest.Processed__c = true;
              externalRequestResultList.add(externalRequest);
            }
          }  
        } 
        else 
        {
          externalRequest.ProcessResult__c = 'KO';
          externalRequest.Error_Log__c = 'No se ha recibido información del registro en INFO';
          externalRequest.NumRetry__c = externalRequest.NumRetry__c == null ? 1 : externalRequest.NumRetry__c + 1;
          externalRequest.Processed__c = true;
          externalRequestResultList.add(externalRequest);
        }
      } catch (Exception e) 
      {
        // Informar la external request con el error que ha provocado
        externalRequest.ProcessResult__c = 'KO';
        externalRequest.Error_Log__c = e.getMessage();
        externalRequest.NumRetry__c = externalRequest.NumRetry__c == null ? 1 : externalRequest.NumRetry__c + 1;
        externalRequest.Processed__c = true;
        externalRequestResultList.add(externalRequest);

        ErrorLogUtil.commitError(e, 'INFOHandler', 'process');
      }
    }
  }

  /**
   * Realiza las operaciones DML sobre la BBDD y actualiza la información de las external request procesadas
   **
   * @author adelgado
   * @date 13/10/2020
   * @param Lista de external request que deben ser procesadas
   * @return void
   * @throws
   * @where ExternalJobQueueBatch
   */
  public static void persists( List<ExternalRequest__c> externalRequestList ) 
  {
    Map<String, List<ExternalRequest__c>> externalRequestByObject = new Map<String, List<ExternalRequest__c>>();
    Map<String, List<sObject>> recordsByObject = new Map<String, List<ExternalRequest__c>>();

    try 
    {
      if (recordsToUpsertByObject != null && !recordsToUpsertByObject.isEmpty()) 
      {
        // 1 - Recorrer todos los registros generados y generar estructuras 
        for (String objectName : recordsToUpsertByObject.keySet()) 
        {
          if (!recordsToUpsertByObject.get(objectName).isEmpty()) 
          {
            if (!externalRequestByObject.containsKey(objectName)) 
            {
              externalRequestByObject.put(objectName, new List<ExternalRequest__c>());
              recordsByObject.put(objectName, new List<sObject>());
            }

            for (sObject record : recordsToUpsertByObject.get(objectName).keySet()) 
            {
              if (recordsToUpsertByObject.get(objectName).get(record) != null) 
              {
                externalRequestByObject.get(objectName).add(recordsToUpsertByObject.get(objectName).get(record));
              }

              recordsByObject.get(objectName).add(record);
            }
          }
        }

        // 2 - Realizar las operaciones DML sobre los registros generados y actualizar external request con resultado
        for (String objectName : entityOrder) 
        {
          if(recordsByObject.containsKey(objectName) && !recordsByObject.get(objectName).isEmpty())
          {
            Schema.SObjectField externalId = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(externalIdByObject.get(objectName));
            Database.UpsertResult[] resultList = Database.upsert(recordsByObject.get(objectName), externalId, false);

            for (Integer i = 0;i < externalRequestByObject.get(objectName).size();i++) 
            {
              ExternalRequest__c extReq = externalRequestByObject.get(objectName).get(i);

              //Procesamiento correcto
              if (resultList.get(i).isSuccess()) 
              {
                extReq.ProcessResult__c = 'OK';
                extReq.Processed__c = true;
                extReq.Error_Log__c = null;
              } 
              //Procesamiento incorrecto
              else 
              {
                extReq.ProcessResult__c = 'KO';
                extReq.Error_Log__c = string.join(resultList.get(i).getErrors(), '\n');
                extReq.NumRetry__c = extReq.NumRetry__c == null ? 1 : extReq.NumRetry__c + 1;

                if (extReq.NumRetry__c >= maxRetries) 
                {
                  extReq.Processed__c = true;
                }
              }

              externalRequestResultList.add(extReq);
            }
          }
        }
      }
    } catch (Exception e) {
      ErrorLogUtil.commitError(e, 'INFOHandler', 'persists');
    }
  }

  /**
   * Actualiza las external request procesadas con el resultado obtenido en las operaciones DML
   **
   * @author adelgado
   * @date 13/10/2020
   * @param Id del job que se está ejecutando
   * @param Lista de external request que deben ser procesadas
   * @return void
   * @throws
   * @where ExternalJobQueueBatch
   */
  public static void manageResult( Id jobId, List<ExternalRequest__c> externalRequestList ) 
  {
    List<ExternalRequestErrorEvent__e> erErrorEventList = new List<ExternalRequestErrorEvent__e>();

    try 
    {
      if (externalRequestResultList != null && !externalRequestResultList.isEmpty()) 
      {
        // 1 - Actualizar las external request con el resultado
        Database.SaveResult[] resultList = Database.update(externalRequestResultList, false);

        // 2 - Publicar las external request que no se hayan procesado correctamente
        for (ExternalRequest__c externalRequest : externalRequestResultList) 
        {
          try
          {
            // 2.1 - Solo publicar evento de error si el resultado es 'KO' y se ha superado el número máximo de reintentos
            if (externalRequest.Processed__c && externalRequest.ProcessResult__c == 'KO') 
            {
              erErrorEventList.add
              (
                new ExternalRequestErrorEvent__e
                (
                  JobId__c = jobId,
                  RecordId__c = externalRequest.Id,
                  Origin__c = externalRequest.Origin__c,
                  Entity__c = externalRequest.Entity__c,
                  Action__c = externalRequest.Action__c,
                  ContentFormat__c = externalRequest.ContentFormat__c,
                  Payload__c = externalRequest.Payload__c,
                  Message__c = externalRequest.Error_Log__c,
                  StackTrace__c = externalRequest.Error_Log__c,
                  ThrowingTime__c = Datetime.now(),
                  ExternalRequestCreatedDate__c = externalRequest.CreatedDate
                )
              );
            }

          } catch (Exception e) 
          {
            ErrorLogUtil.commitError(e, 'INFOHandler', 'manageResult');
          }
        }

        // 3 - Publicar external request erróneas
        if (!erErrorEventList.isEmpty()) 
        {
          List<Database.SaveResult> results = EventBus.publish(erErrorEventList);
        }

      }
    } catch (Exception e) 
    {
      ErrorLogUtil.commitError(e, 'INFOHandler', 'manageResult');
    }
  }
}