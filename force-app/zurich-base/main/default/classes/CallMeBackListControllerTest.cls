@isTest
private class CallMeBackListControllerTest {

    @TestSetup
    public static void createScenario()
    {
        //Creamos la cuenta            
        List<Account> accounts = TestDataFactory.generateAccounts('Life insurance', 'Customer', 1);
        insert accounts;

        //Creamos los contactRequests asociados a esa cuenta 
        List<Account> createdAccounts = [SELECT PersonContactId FROM Account];
        Id perConId = createdAccounts.get(0).PersonContactId;
        List<ContactRequest> contactReqs = new List<ContactRequest>();

        for (Integer i = 0; i < 10; i++) {
            contactReqs.add(
                new ContactRequest(
                    GenesysInteractionId__c= 'b5d554e7-94b7-4fe1-8041-bfd9992a569' + i,
                    Status= 'New',
                    WhoId= perConId,
                    PreferredContactDatetime__c= DateTime.now()
                )
            );
        }
        insert contactReqs;
    }

    
    @isTest
    static void test_getContactRequestsById_ok()
    {
        // Creamos el objeto esperado
        Map<String, String> returnMap = new Map<String,String>();

        //Obtenemos los campos del fieldset para una parte del mapa
        SObject sObj = (SObject)(Type.forName('Schema.ContactRequest').newInstance());
        List<Schema.FieldSetMember> lstFSMember = sObj.getSObjectType().getDescribe().fieldSets.getMap().get('ContactRequestFieldSet').getFields();

        //Obtenemos el contenido de los registros para la otra parte del mapa
        List<Account> accounts = [SELECT Id FROM Account];
        Id accountId = accounts.get(0).Id;
        List<Account> accList = [SELECT PersonContactId FROM Account WHERE Id = :accountId];
        Id perConId = accList.get(0).PersonContactId;
        String query = 'SELECT Id, Name, CreatedById, CreatedDate, GenesysCloudQueueId__c, LastModifiedById, LastModifiedDate, ' + 
                        'OwnerId, PreferredChannel, PreferredPhone, Preferred_Status__c, WhatId, RequestDescription, RequestReason, ' + 
                        'WhoId, WebName__c, GenesysInteractionId__c, PreferredContactDatetime__c, Status, Priority__c FROM ContactRequest ' + 
                        'WHERE WhoId = :perConId ORDER BY Preferred_Status__c, PreferredContactDatetime__c';
        List<SObject> lstRecordsQuery = Database.query(query);
        List<Map<String, String>> records = new List<Map<String, String>>();
        
        Map<String, Schema.SObjectField> conReqFields = Schema.SObjectType.ContactRequest.fields.getMap();
        
        //Parseamos los posibles campos de tipo fecha para que estén el el formato deseado posteriormente
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
        //Serializamos el mapa compuesto por registros y campos para que nos quede un string
        returnMap.put('FIELD_LIST', JSON.serialize(lstFSMember));
	    returnMap.put('RECORD_LIST', JSON.serialize(records));
        String expectedContactRequests = JSON.serialize(returnMap);
        
        // Test
        Test.startTest();

        String foundContactRequests = CallMeBackListController.getContactRequestsById('ContactRequestFieldSet', accountId);

        Test.stopTest();

        // Asserts
        System.assertEquals(expectedContactRequests, foundContactRequests, 'No contiene los mismos contactRequests');
    }
}