/**
 * Clase parser que transforma un origen de datos en objetos Salesforce dada una configuración
 **
 * @author xsobera
 * @date 13/10/2020
 */
public class Transformer {
  public static final String ORIGIN_NAME_INFO = 'INFO';
  private static Set<String> validOrigins = new Set<String>{ ORIGIN_NAME_INFO };

  public static final String OBJECT_NAME_ACCOUNT = 'Account';
  public static final String OBJECT_NAME_CONTACT = 'Contact';
  public static final String OBJECT_NAME_CONTACT_POINT_ADDRESS = 'ContactPointAddress';
  public static final String OBJECT_NAME_CONTACT_POINT_PHONE = 'ContactPointPhone';
  public static final String OBJECT_NAME_CONTACT_POINT_EMAIL = 'ContactPointEmail';

  private Map<String, Map<String, String>> mappingsByObject {
    get {
      if (mappingsByObject == null) {
        // Inicializar mapeo objeto Salesforce => campo origen -> campo destino
        mappingsByObject = new Map<String, Map<String, String>>();
      }
      return mappingsByObject;
    }
    set;
  }
  private static Map<String, Schema.DescribeSObjectResult> descResultMap;

  private List<Transformer__mdt> settings;
  public List<Transformer__mdt> getSettings() {
    return this.settings;
  }
  private String origin;
  public String getOrigin() {
    return this.origin;
  }
  private Map<String, Object> unmappedValues {
    get {
      if (unmappedValues == null) {
        // Inicializar mapa para devolver los campos no mapeados
        unmappedValues = new Map<String, Object>();
      }
      return unmappedValues;
    }
    set;
  }
  public Map<String, Object> getUnmappedValues() {
    return unmappedValues;
  }

  public Map<String, Map<sObject, ExternalRequest__c>> initRequestsMapBySettings() {
    Map<String, Map<sObject, ExternalRequest__c>> recordsToUpsertByObject = new Map<String, Map<sObject, ExternalRequest__c>>();

    // 2 - Creación de un mapa con una clave por cada entidad del CRM que se utilice en la integración con INFO
    for (Transformer__mdt setting : this.settings) {
      if (!recordsToUpsertByObject.containsKey(setting.SalesforceEntity__c)) {
        recordsToUpsertByObject.put(
          setting.SalesforceEntity__c,
          new Map<sObject, ExternalRequest__c>()
        );
      }
    }

    return recordsToUpsertByObject;
  }

  public Transformer(String originSystem) {
    if (String.isBlank(originSystem) || !validOrigins.contains(originSystem)) {
      throw new TransformerException(
        'There are not established a valid origin system for the Transformer'
      );
    }
    this.origin = originSystem;
    this.settings = new List<Transformer__mdt>(
      [
        SELECT
          OriginEntity__c,
          OriginField__c,
          SalesforceEntity__c,
          SalesforceField__c
        FROM Transformer__mdt
        WHERE Origin__c = :originSystem
      ]
    );

    if (settings == null || settings.isEmpty()) {
      throw new TransformerException(
        'There are not metadata configuration for selected origin: ' +
        this.origin
      );
    }

    // Inicializar mapeo campos según metadatos
    for (Transformer__mdt setting : this.settings) {
      if (!mappingsByObject.containsKey(setting.SalesforceEntity__c)) {
        mappingsByObject.put(
          setting.SalesforceEntity__c,
          new Map<String, String>()
        );
      }

      mappingsByObject.get(setting.SalesforceEntity__c)
        .put(setting.OriginField__c.toLowerCase(), setting.SalesforceField__c);
      mappingsByObject.get(setting.SalesforceEntity__c)
        .put(setting.OriginField__c.toUpperCase(), setting.SalesforceField__c);
    }
  }

  /**
   * Método que mapea en un objeto Salesforce los datos dados en un Mapa según
   * la configuración establecida en los metadatos personalizados indicados en el constructor
   **
   * @param String objeto Salesforce
   * @param Map<String, Object> datos recibidos en la petición
   * @return sObject objeto SF inicializado con los datos dados en el Mapa
   * @throws TransformerException excepción especifica durante el proceso de transformación del registro
   * @author xsobera
   * @date 13/10/2020
   */
  public sObject transform(
    String objectName,
    Map<String, Object> originRecordMap
  ) {
    // Obtenemos la información de los campos del objeto Salesforce destino
    Map<String, Schema.SObjectField> objectFields = getObjectFields(objectName);
    Map<String, String> mappingByOriginField = mappingsByObject.get(objectName);
    SObject record = Schema.getGlobalDescribe().get(objectName).newSObject();
    String sfFieldNameConfig;
    String originFieldValue;
    Schema.SObjectField sfFieldObj;
    Schema.DisplayType fieldDisplayType;
    for (String originRecordField : originRecordMap.keySet()) {
      if (
        mappingByOriginField.containsKey(originRecordField.toUpperCase()) //origen1
      ) {
        sfFieldNameConfig = mappingByOriginField.get(
          originRecordField.toUpperCase()
        );
        // comprobar que hay un campo sf definido en el metadato
        if (String.isNotBlank(sfFieldNameConfig)) {
          for (String sfFieldName : getTargetFields(sfFieldNameConfig)) {
            sfFieldName = sfFieldName.trim();
            // comprobar que si es lookup
            if (!isLookupRelationship(sfFieldName)) {
              // Validar que el campo indicado en metadata existe en el objeto de salesforce
              if (objectFields.keySet().contains(sfFieldName.toLowerCase())) {
                originFieldValue = String.valueOf(
                  originRecordMap.get(originRecordField)
                );
                System.debug(
                  LoggingLevel.DEBUG,
                  '[Transformer] Obteniendo detalles del campo: ' + sfFieldName
                );
                sfFieldObj = objectFields.get(sfFieldName.toLowerCase());
                fieldDisplayType = sfFieldObj.getDescribe().getType();
                System.debug(
                  LoggingLevel.DEBUG,
                  '[Transformer] Tipo del campo: ' + fieldDisplayType.name()
                );
                switch on fieldDisplayType.name().toUpperCase() {
                  when 'BOOLEAN' {
                    record.put(
                      sfFieldName,
                      parseBooleanField(originFieldValue, this.origin)
                    );
                  }
                  when 'DATE' {
                    record.put(
                      sfFieldName,
                      parseDateField(originFieldValue, this.origin)
                    );
                  }
                  when 'DATETIME' {
                    record.put(
                      sfFieldName,
                      parseDatetimeField(originFieldValue, this.origin)
                    );
                  }
                  when 'CURRENCY', 'DOUBLE' {
                    record.put(
                      sfFieldName,
                      parseDoubleField(originFieldValue, this.origin)
                    );
                  }
                  when 'INTEGER' {
                    record.put(
                      sfFieldName,
                      parseIntegerField(originFieldValue, this.origin)
                    );
                  }
                  when else {
                    // se considera texto el resto de campos
                    record.put(
                      sfFieldName,
                      parseStringField(originFieldValue, this.origin)
                    );
                  }
                }
              } else {
                // Sí hay configuración para el campo origen y sí se ha definido un campo sf pero el objeto salefsorce destino no contiene un campo con el nombre indicado
                System.debug(
                  LoggingLevel.ERROR,
                  '[Transformer] No hay ningún campo en el objeto Salesforce con el nombre indicado. sObject: ' +
                  objectName +
                  ' Field: ' +
                  sfFieldName
                );
                throw new TransformerException(
                  'There are not any field with these name in the salesforce object. sObject: ' +
                  objectName +
                  ' Field: ' +
                  sfFieldName
                );
              }
            } else {
              // Insert lookup
              buildParentRelationship(
                record,
                sfFieldName,
                (String) originRecordMap.get(originRecordField)
              );
            }
          } // fin loop getTargetFields()
        } else {
          // Sí hay configuración para el campo origen pero no se ha definido un campo sf de destino en el metadato (vacío o nulo)
          System.debug(
            LoggingLevel.WARN,
            '[Transformer] No se ha indicado ningún campo Salesforce destino en la configuración.Origin: ' +
            origin +
            ' Field: ' +
            originRecordField
          );
          //throw new TransformerException('There are not salesforce field in metadata configuration to these values.Origin: ' + origin + ' Field: ' + originRecordField);

          // Guardar en unmappedValues
          unmappedValues.put(
            originRecordField,
            originRecordMap.get(originRecordField)
          );
        }
      } else {
        // No se ha especificado ninguna configuración para el campo origen xxx
        System.debug(
          LoggingLevel.WARN,
          '[Transformer] No hay configuración para los valores solicitados. Origen: ' +
          origin +
          ' sObject: ' +
          objectName +
          ' Field: ' +
          originRecordField
        );
        //throw new TransformerException('There are not metadata configuration to these values.  Origin: ' + origin + ' sObject: ' + objectName + ' Field: ' + originRecordField);

        // Guardar en unmappedValues
        unmappedValues.put(
          originRecordField,
          originRecordMap.get(originRecordField)
        );
      }
    }

    return record;
  }

  /**
   * Método para obtener la infomación del objeto salesforce
   **
   */
  @TestVisible
  private static Map<String, Schema.SObjectField> getObjectFields(
    String objectName
  ) {
    // Obtenemos la información de los campos del objeto Salesforce destino
    System.debug(LoggingLevel.DEBUG, '[Tramsformer] objectName: ' + objectName);

    if (descResultMap == null) {
      descResultMap = new Map<String, Schema.DescribeSObjectResult>();
    }

    Map<String, Schema.SObjectField> objectFields;
    Schema.DescribeSObjectResult descResult;
    if (!descResultMap.containsKey(objectName)) {
      if (
        Schema.getGlobalDescribe().keySet().contains(objectName.toLowerCase())
      ) {
        descResult = Schema.describeSObjects(new List<String>{ objectName })[0];
        descResultMap.put(objectName, descResult);
      } else {
        System.debug(
          LoggingLevel.ERROR,
          '[Transformer] No hay ningún objecto en Salesforce con el nombre indicado. sObject: ' +
          objectName
        );
        throw new TransformerException(
          'There are not any object in Salesforce with these name. sObject: ' +
          objectName
        );
      }
    } else {
      descResult = descResultMap.get(objectName);
    }
    objectFields = descResult.fields.getMap();
    System.debug(
      LoggingLevel.DEBUG,
      '[Transformer] objectFields: ' + JSON.serialize(objectFields.keySet())
    );
    return objectFields;
  }

  /**
   * Método que parsea un string en boolean de acuerdo con las indicaciones
   * de formato del sistema origen
   **
   * @param String valor a transformar en boolean, por ejemplo: S, Y, 1 ...
   * @param String origen configurado en el Transformer
   * @return Boolean
   *
   * @author xsobera
   * @date 13/10/2020
   */
  @TestVisible
  private static Boolean parseBooleanField(String strValue, string origin) {
    switch on origin {
      when 'INFO' {
        Boolean booleanValue = false;
        if (
          String.isNotBlank(strValue) && strValue.trim().equalsIgnoreCase('S')
        ) {
          booleanValue = true;
        }
        return booleanValue;
      }
      when else {
        // Agregar otros origenens o transformaciones por defecto
        System.debug(
          LoggingLevel.WARN,
          '[Transformer] parseBooleanField() transformación no específicada para origen: ' +
          origin
        );
      }
    }

    return null;
  }

  /**
   * Método que parsea un string en Date de acuerdo con las indicaciones
   * de formato del sistema origen
   **
   * @param String valor a transformar en Date, por ejemplo: 'YYYY-MM-DD' ...
   * @param String origen configurado en el Transformer
   * @return Date
   *
   * @author xsobera
   * @date 20/10/2020
   */
  @TestVisible
  private static Date parseDateField(String strValue, String origin) {
    switch on origin {
      when 'INFO' {
        if (String.isNotBlank(strValue)) {
          return Date.valueOf(strValue.trim());
        }
      }
      when else {
        // Agregar otros origenens o transformaciones por defecto
        System.debug(
          LoggingLevel.WARN,
          '[Transformer] parseDateField() transformación no específicada para origen: ' +
          origin
        );
      }
    }

    return null;
  }

  /**
   * Método que parsea un string en Datetime de acuerdo con las indicaciones
   * de formato del sistema origen
   **
   * @param String valor a transformar en Datetime, por ejemplo: YYYY-MM-DD HH:MM:SS
   * @param String origen configurado en el Transformer
   * @return Datetime
   *
   * @author xsobera
   * @date 20/10/2020
   */
  @TestVisible
  private static Datetime parseDatetimeField(String strValue, String origin) {
    switch on origin {
      when 'INFO' {
        if (String.isNotBlank(strValue)) {
          return Datetime.valueOf(strValue.trim());
        }
      }
      when else {
        // Agregar otros origenens o transformaciones por defecto
        System.debug(
          LoggingLevel.WARN,
          '[Transformer] parseDatetimeField() transformación no específicada para origen: ' +
          origin
        );
      }
    }

    return null;
  }

  /**
   * Método que parsea un string en texto de acuerdo con las indicaciones
   * de formato del sistema origen
   **
   * @param String valor a transformar en String , por ejemplo: 'hola'
   * @param String origen configurado en el Transformer
   * @return String
   *
   * @author xsobera
   * @date 21/10/2020
   */
  @TestVisible
  private static String parseStringField(String strValue, String origin) {
    switch on origin {
      when 'INFO' {
        if (String.isNotBlank(strValue)) {
          return strValue.trim();
        }
      }
      when else {
        // Agregar otros origenens o transformaciones por defecto
        System.debug(
          LoggingLevel.WARN,
          '[Transformer] parseStringField() transformación no específicada para origen: ' +
          origin
        );
      }
    }

    return null;
  }

  /**
   * Método que parsea un string en Double de acuerdo con las indicaciones
   * de formato del sistema origen
   **
   * @param String valor a transformar en Double, por ejemplo: '0000.00' ...
   * @param String origen configurado en el Transformer
   * @return Double
   *
   * @author xsobera
   * @date 26/10/2020
   */
  @TestVisible
  private static Double parseDoubleField(String strValue, String origin) {
    switch on origin {
      when 'INFO' {
        if (String.isNotBlank(strValue)) {
          return Double.valueOf(strValue.trim());
        }
      }
      when else {
        // Agregar otros origenens o transformaciones por defecto
        System.debug(
          LoggingLevel.WARN,
          '[Transformer] parseDoubleField() transformación no específicada para origen: ' +
          origin
        );
      }
    }

    return null;
  }

  /**
   * Método que parsea un string en Integer de acuerdo con las indicaciones
   * de formato del sistema origen
   **
   * @param String valor a transformar en Integer, por ejemplo: '0000' ...
   * @param String origen configurado en el Transformer
   * @return Integer
   *
   * @author xsobera
   * @date 26/10/2020
   */
  @TestVisible
  private static Integer parseIntegerField(String strValue, String origin) {
    switch on origin {
      when 'INFO' {
        if (String.isNotBlank(strValue) && strValue.isNumeric()) {
          return Integer.valueOf(strValue.trim());
        }
      }
      when else {
        // Agregar otros origenens o transformaciones por defecto
        System.debug(
          LoggingLevel.WARN,
          '[Transformer] parseIntegerField() transformación no específicada para origen: ' +
          origin
        );
      }
    }

    return null;
  }

  /**
   * Método que comprueba si la configuración de metadatos es lookup
   * Formato targetFieldOfChild:sObjectNameOfParent->externalFieldIdOfParent
   **
   * @param String valor configuración
   * @return Boolean
   *
   * @author xsobera
   * @date 21/10/2020
   */
  @TestVisible
  private static Boolean isLookupRelationship(String configValue) {
    return (String.isNotBlank(configValue) &&
    configValue.countMatches(':') == 1 &&
    configValue.countMatches('->') == 1);
  }

  /**
   * Método que devuelve establece la relación con el padre según el externalId configurado
   * Formato targetFieldOfChild:sObjectNameOfParent->externalFieldIdOfParent
   **
   * @param sObject parentObjectName
   * @param String configValue
   * @param String fieldValue
   *
   * @author xsobera
   * @date 21/10/2020
   */
  @TestVisible
  private static void buildParentRelationship(
    sObject record,
    String configValue,
    String fieldValue
  ) {
    String childFieldName;
    String parentObjectName;
    String parentExternalFieldName;

    List<String> aux;
    if (isLookupRelationship(configValue)) {
      aux = new List<String>(configValue.split(':'));
      childFieldName = aux[0];
      aux = new List<String>(aux[1].split('->'));
      parentObjectName = aux[0];
      parentExternalFieldName = aux[1];

      // Comprobar que existen los campos en hijo y el objeto padre y su campo
      Map<String, Schema.SObjectField> parentObjectFields = getObjectFields(
        parentObjectName
      );
      if (
        parentObjectFields.keySet()
          .contains(parentExternalFieldName.toLowerCase())
      ) {
        Map<String, Schema.SObjectField> childObjectFields = getObjectFields(
          String.valueOf(record.getSObjectType())
        );
        if (childObjectFields.keySet().contains(childFieldName.toLowerCase())) {
          if (string.isNotBlank(fieldValue)) {
            SObject parentObject = Schema.getGlobalDescribe()
              .get(parentObjectName)
              .newSObject();
            parentObject.put(parentExternalFieldName, fieldValue);

            String relationName = childObjectFields.get(
                childFieldName.toLowerCase()
              )
              .getDescribe()
              .getRelationshipName();
            System.debug(
              LoggingLevel.DEBUG,
              '[Transformer] Nombre de la relación: ' + relationName
            );
            record.putSObject(relationName, parentObject);
          } else {
            System.debug(
              LoggingLevel.WARN,
              '[Transformer] El valor indicado para el lookup es nulo o vacío. sObject: ' +
              String.valueOf(record.getSObjectType()) +
              ' Field: ' +
              childFieldName
            );
            record.put(childFieldName, null);
          }
        } else {
          // El hijo no contienen un campo con ese nombre
          System.debug(
            LoggingLevel.ERROR,
            '[Transformer] No hay ningún campo en el objeto hijo de Salesforce con el nombre indicado. sObject: ' +
            String.valueOf(record.getSObjectType()) +
            ' Field: ' +
            childFieldName
          );
          throw new TransformerException(
            'There are not any field with these name in the salesforce child object. sObject: ' +
            String.valueOf(record.getSObjectType()) +
            ' Field: ' +
            childFieldName
          );
        }
      } else {
        // El padre no contiene un campo con ese nombre
        System.debug(
          LoggingLevel.ERROR,
          '[Transformer] No hay ningún campo en el objeto padre de Salesforce con el nombre indicado. sObject: ' +
          parentObjectName +
          ' Field: ' +
          parentExternalFieldName
        );
        throw new TransformerException(
          'There are not any field with these name in the salesforce parent object. sObject: ' +
          parentObjectName +
          ' Field: ' +
          parentExternalFieldName
        );
      }
    }
  }

  /**
   * Método que las configuraciones para cada uno de los campos destino
   * Formato entrada targetField1,targetField2
   **
   * @param String configValue
   * @return List<String> configuraciones para cada campo destino
   *
   * @author xsobera
   * @date 23/10/2020
   */
  @TestVisible
  private static List<String> getTargetFields(String configValue) {
    List<String> configValues = new List<String>(); // siempre tiene que devolver una lista instanciada
    if (String.isNotBlank(configValue)) {
      Set<String> aux = new Set<String>(configValue.split(','));
      aux.removeAll(new Set<String>{ null, '', ' ' });
      configValues.addAll(aux);
    }

    return configValues;
  }

  public class TransformerException extends Exception {
  }
}
