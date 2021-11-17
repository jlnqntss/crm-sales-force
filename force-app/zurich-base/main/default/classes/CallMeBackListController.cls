/**
 * @description       : 
 * @author            : Kevin Rueda
 * @group             : 
 * @last modified on  : 16-11-2021
 * @last modified by  : jjuaristi
**/
public with sharing class CallMeBackListController {


    @AuraEnabled(cacheable = true)
    public static String getContactRequestsById(String customerId)
    {
        // TODO cambiarlo para que funcione con la query del selector y este método no haga básicamente nada
        Map<String, String> returnMap = new Map<String,String>();

        //Coger fields del fieldset
        String nullFieldset;
        List<Schema.FieldSetMember> lstFSMember;
       
        List<ContactRequest> contactRequests = new ContactRequestSelector().findByCustomerId(customerId);

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
    * Pasa el estado de un CMB a cancelado
    * @author jjuaristi
    * @date 04/11/2021
    * @param string que contiene el contactRequestId a cancelar
    * @return void
    */
    @AuraEnabled(cacheable=false)
    public static void statusToCancelled(String contactRequestId){
        try {

            ContactRequest contactRequest = new ContactRequest(
                Id = contactRequestId,
                Status = ContactRequestSelector.STATUS_CANCELLED
            );
            //Actualizar registro en la base de datos
            update contactRequest;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}