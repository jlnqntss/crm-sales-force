/**
 * @description       : 
 * @author            : Kevin Rueda
 * @group             : 
 * @last modified on  : 12-11-2021
 * @last modified by  : jjuaristi
**/
public with sharing class CallMeBackListController {
    /**
    * Recoge una lista de contactRequests para plasmarlos luego en la tabla del componente callMeBackList
    **
    * @author Kevin Rueda
    * @date 02/09/2021
    * @param strfieldSetName,criteriaFieldValue String que indica el nombre del fieldSet seleccionado, String que dice por qué campo se va a buscar
    * @return String String de formato JSON que contiene un mapa con los fields y los registros en cuetión a plasmar después en tabla
    */
    @AuraEnabled(cacheable = true)
    public static String getContactRequestsById(String strfieldSetName, String criteriaFieldValue)
    {
        Map<String, String> returnMap = new Map<String,String>();

        //Coger fields del fieldset
        String nullFieldset;
        List<Schema.FieldSetMember> lstFSMember;
        SObject sObj = (SObject)(Type.forName('Schema.ContactRequest').newInstance());
        Schema.FieldSet fieldset = sObj.getSObjectType().getDescribe().fieldSets.getMap().get(strfieldSetName);
        if(fieldset == null)
        {
            nullFieldset = '[{}]';
        }else
        {
            lstFSMember = fieldset.getFields();            
        }

	    //Ejecutar query
        List<Account> accList = [SELECT PersonContactId from Account WHERE Id = :criteriaFieldValue];
        Id perConId = accList.get(0).PersonContactId;
        String query = 'SELECT Id, Name, CreatedById, CreatedDate, GenesysCloudQueueId__c, LastModifiedById, LastModifiedDate, ' + 
                        'OwnerId, PreferredChannel, PreferredPhone, Preferred_Status__c, WhatId, RequestDescription, RequestReason, ' + 
                        'WhoId, WebName__c, GenesysInteractionId__c, PreferredContactDatetime__c, Status, Priority__c FROM ContactRequest ' + 
                        'WHERE WhoId = :perConId AND (NOT (Preferred_Status__c = \'Cancelled\')) ORDER BY Preferred_Status__c, PreferredContactDatetime__c';
        List<SObject> lstRecordsQuery = Database.query(query);

        List<Map<String, String>> records = new List<Map<String, String>>();
        
        Map<String, Schema.SObjectField> conReqFields = Schema.SObjectType.ContactRequest.fields.getMap();
        for (SObject obj : lstRecordsQuery)
        {
            Map<String, Object> objMap = obj.getPopulatedFieldsAsMap();
            Map<String, String> stringMap = new Map<String, String>();
            for (String fieldName : objMap.keySet()) {
                if(conReqFields.get(fieldName).getDescribe().getType() == Schema.DisplayType.DateTime)
                {
                    DateTime dateTimeField = (DateTime)objMap.get(fieldName);
                    stringMap.put(fieldName, dateTimeField.format('dd/MM/yyyy - HH:mm'));
                }else
                {
                    stringMap.put(fieldName, String.valueOf(objMap.get(fieldName)));
                }
            }
            records.add(stringMap);
        }

        //Preparar mapa con la lista de fields y los registros, y devolverlo
	    if(fieldset == null)
        {
            returnMap.put('FIELD_LIST', nullFieldset);
        }else
        {
            returnMap.put('FIELD_LIST', JSON.serialize(lstFSMember));
        }
	    returnMap.put('RECORD_LIST', JSON.serialize(records));
	    return JSON.serialize(returnMap);
    }

    /**
    * Pasa el estado de un CMB a cancelado, y devuelve su id para poder cancelarlo en genesys posteriormente
    * Por alguna razón row.Id no devuelve el id del registro, por lo que se aprovecha esta query que hay que hacer igualmente para recuperarlo
    * @author jjuaristi
    * @date 04/11/2021
    * @param string que contiene el GenesysInteractionId
    * @return void
    */
    @AuraEnabled(cacheable=false)
    public static String statusToCancelled(String genesysInteractionId){
        try {

            ContactRequest contactRequest = [SELECT Id, Status, Preferred_Status__c FROM ContactRequest WHERE GenesysInteractionId__c =:genesysInteractionId LIMIT 1];

            //Cambiar el status a Cancelled
            contactRequest.Status = 'Cancelled';
            //Actualizar registro en la base de datos
            update contactRequest;

            return String.valueOf(contactRequest.Id);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}