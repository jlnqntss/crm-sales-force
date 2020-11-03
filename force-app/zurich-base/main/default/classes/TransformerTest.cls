/**
 * Clases de test para Transformer usado por las clases de procesamiento de los registros
 * ExternalRequest__c del tipo {ExternalSystemName}Handler.cls y que se encargan de mapear la estructura origen
 * con los objetos Salesforce
 **
 * @author xsobera
 * @date 09/10/2020
 */
@isTest(SeeAllData = false)
public with sharing class TransformerTest
{
    @testSetup
    static void makeData()
    {}

    /**
     * Método test que válida la obtención de los metadatos necesarios por origen
     **
     * @author xsobera
     * @date 14/10/2020
     */
    @IsTest
    static void test_getSettings()
    {
        Transformer myTransformer = new Transformer(Transformer.ORIGIN_NAME_INFO);
        List<Transformer__mdt> settings = myTransformer.getSettings();

        System.debug( 'Metadatos: ' + JSON.serialize(settings) );
        System.assertEquals(
            true,
            settings != null && !settings.isEmpty(),
            '[0] No se ha obtenido la configuración de metadatos esperada'
            );
        System.assertEquals(
            true,
            myTransformer.getOrigin().equalsIgnoreCase(Transformer.ORIGIN_NAME_INFO),
            '[1] No se ha establecido el origen adecuado'
            );
        Set<String> objectMapped = myTransformer.initRequestsMapBySettings()
                                   .keySet();
        System.assertEquals(
            true,
            objectMapped.contains('Account'),
            '[2] La configuración no contiene mapeo para el objeto Cuenta'
            );
        System.assertEquals(
            true,
            objectMapped.contains('Contact'),
            '[3] La configuración no contiene mapeo para el objeto Contacto'
            );

        try
        {
            Transformer myTransformer2 = new Transformer('BAD');
        }
        catch (Transformer.TransformerException ex)
        {
            System.assertEquals(
                'There are not established a valid origin system for the Transformer',
                ex.getMessage(),
                '[4] No se ha lanzado la excepción esperada'
                );
        }
    }

    /**
     * Método test que válida la transformación de los registros INFO de clientes en Cuentas y Contactos Salesforce
     **
     * @author xsobera
     * @date 14/10/2020
     */
    @isTest
    static void test_infoCustomerTransform()
    {
        List<Map<String, Object> > customersJsonItems = TestDataFactory.getINFOCustomerJson(
            10,
            'F'
            );
        List<Map<String, Object> > companiesJsonItems = TestDataFactory.getINFOCustomerJson(
            10,
            'J'
            );

        List<Account> customersAccounts = new List<Account>();
        List<Account> companiesAccounts = new List<Account>();
        List<Contact> companiesContacts = new List<Contact>();
        Account accountRecord;
        Contact contactRecord;

        // Instanciar el transformer con la configuración de INFO
        Transformer myTransformer = new Transformer(Transformer.ORIGIN_NAME_INFO);
        for (Integer i = 0; i < customersJsonItems.size(); i++)
        {
            accountRecord = (Account) myTransformer.transform(
                Transformer.OBJECT_NAME_ACCOUNT,
                customersJsonItems[i]
                );
            customersAccounts.add(accountRecord);
            System.assertEquals(
                customersJsonItems[i].get('cliente_cod_filiacion'),
                accountRecord.INFOCustomerNumber__c,
                '[PersonAccount-' +
                String.valueOf(i).leftPad(2, '0') +
                '] No se ha mapeado el External ID correctamente'
                );
        }

        for (Integer i = 0; i < companiesJsonItems.size(); i++)
        {
            accountRecord = (Account) myTransformer.transform(
                Transformer.OBJECT_NAME_ACCOUNT,
                companiesJsonItems[i]
                );
            companiesAccounts.add(accountRecord);
            System.assertEquals(
                companiesJsonItems[i].get('cliente_cod_filiacion'),
                accountRecord.INFOCustomerNumber__c,
                '[Account-' +
                String.valueOf(i).leftPad(2, '0') +
                '] No se ha mapeado el External ID correctamente'
                );

            contactRecord = (Contact) myTransformer.transform(
                Transformer.OBJECT_NAME_CONTACT,
                companiesJsonItems[i]
                );
            companiesContacts.add(contactRecord);
            System.assertEquals(
                companiesJsonItems[i].get('cliente_cod_filiacion'),
                contactRecord.InfoCustomerContactNumber__c,
                '[Contact-' +
                String.valueOf(i).leftPad(2, '0') +
                '] No se ha mapeado el External ID correctamente'
                );
        }

        System.assertEquals(
            customersJsonItems.size(),
            customersAccounts.size(),
            '[0] No se ha obtenido el número de Cuentas Personales esperado'
            );
        System.assertEquals(
            companiesJsonItems.size(),
            companiesAccounts.size(),
            '[1] No se ha obtenido el número de Cuentas esperado'
            );
        System.assertEquals(
            companiesJsonItems.size(),
            companiesContacts.size(),
            '[2] No se ha obtenido el número de Contactos esperado'
            );
    }

    /**
     * Método test que válida la transformación de los registros INFO de vias de contacto en
     * ContactPointAddress, ContactPointEmail y ContactPointPhone de Salesforce
     **
     * @author xsobera
     * @date 14/10/2020
     */
    @isTest
    static void test_infoContactPointTransform()
    {
        List<Map<String, Object> > emailsJsonItems = TestDataFactory.getINFOContactPointJson(
            10,
            'E'
            );
        List<Map<String, Object> > phonesJsonItems = TestDataFactory.getINFOContactPointJson(
            10,
            'T'
            );
        List<Map<String, Object> > addressesJsonItems = TestDataFactory.getINFOContactPointJson(
            10,
            'P'
            );

        List<ContactPointEmail> emails = new List<ContactPointEmail>();
        List<ContactPointPhone> phones = new List<ContactPointPhone>();
        List<ContactPointAddress> addresses = new List<ContactPointAddress>();

        ContactPointEmail emailRecord;
        ContactPointPhone phoneRecord;
        ContactPointAddress addressRecord;

        // Instanciar el transformer con la configuración de INFO
        Transformer myTransformer = new Transformer(Transformer.ORIGIN_NAME_INFO);
        for (Integer i = 0; i < emailsJsonItems.size(); i++)
        {
            emailRecord = (ContactPointEmail) myTransformer.transform(
                Transformer.OBJECT_NAME_CONTACT_POINT_EMAIL,
                emailsJsonItems[i]
                );
            emails.add(emailRecord);
            System.assertEquals(
                emailsJsonItems[i].get('email'),
                emailRecord.EmailAddress,
                '[ContactPointEmail-' +
                String.valueOf(i).leftPad(2, '0') +
                '] No se ha mapeado el email correctamente'
                );
        }

        for (Integer i = 0; i < phonesJsonItems.size(); i++)
        {
            phoneRecord = (ContactPointPhone) myTransformer.transform(
                Transformer.OBJECT_NAME_CONTACT_POINT_PHONE,
                phonesJsonItems[i]
                );
            phones.add(phoneRecord);
            System.assertEquals(
                phonesJsonItems[i].get('numero_tel'),
                phoneRecord.TelephoneNumber,
                '[ContactPointPhone-' +
                String.valueOf(i).leftPad(2, '0') +
                '] No se ha mapeado el teléfono correctamente'
                );
        }

        for (Integer i = 0; i < addressesJsonItems.size(); i++)
        {
            addressRecord = (ContactPointAddress) myTransformer.transform(
                Transformer.OBJECT_NAME_CONTACT_POINT_ADDRESS,
                addressesJsonItems[i]
                );
            addresses.add(addressRecord);
            System.assertEquals(
                addressesJsonItems[i].get('descripcion_dom'),
                addressRecord.Street,
                '[ContactPointAddress-' +
                String.valueOf(i).leftPad(2, '0') +
                '] No se ha mapeado la dirección correctamente'
                );
        }

        System.assertEquals(
            emailsJsonItems.size(),
            emails.size(),
            '[0] No se ha obtenido el número de emails esperado'
            );
        System.assertEquals(
            phonesJsonItems.size(),
            phones.size(),
            '[1] No se ha obtenido el número de teléfonos esperado'
            );
        System.assertEquals(
            addressesJsonItems.size(),
            addresses.size(),
            '[2] No se ha obtenido el número de direcciones postales esperado'
            );
    }

    @IsTest
    static void test_getUnmappedValues()
    {
        // Test para comprobar que obtenemos un mapa con los valores que no están configurados en la metadata
        List<Map<String, Object> > customersJsonItems = TestDataFactory.getINFOCustomerJson(
            1,
            'J'
            );
        customersJsonItems[0].put('unmapped', 'test');

        // Instanciar el transformer con la configuración de INFO
        Transformer myTransformer = new Transformer(Transformer.ORIGIN_NAME_INFO);
        myTransformer.transform(
            Transformer.OBJECT_NAME_ACCOUNT,
            customersJsonItems[0]
            );
        Map<String, Object> unmappedValues = myTransformer.getUnmappedValues();

        System.assertEquals(
            'test',
            (String) unmappedValues.get('unmapped'),
            '[0] No se ha obtenido el mapa con los campos no mapeados'
            );
    }

    @IsTest
    static void test_lookupRelationship()
    {
        String inputOK = 'Test0:Test1->Test2';
        String inputKO = 'Test0Test1Test2';

        System.assertEquals(
            true,
            Transformer.isLookupRelationship(inputOK),
            '[0] No se ha obtenido true'
            );
        System.assertEquals(
            false,
            Transformer.isLookupRelationship(inputKO),
            '[1] No se ha obtenido false'
            );

        SObject record = Schema.getGlobalDescribe().get('Contact').newSObject();
        record.put('Lastname', 'test');
        Transformer.buildParentRelationship(
            record,
            'AccountId:Account->INFOCustomerNumber__c',
            '000000001'
            );
        System.assertEquals(
            '000000001',
            ( (Contact) record ).Account.INFOCustomerNumber__c,
            '[2] No se ha obtenido el valor del externalId del padre esperado'
            );

        Boolean hasError = false;
        try
        {
            Transformer.buildParentRelationship(
                record,
                'CampoInventado:Account->INFOCustomerNumber__c',
                '000000001'
                );
        }
        catch (Transformer.TransformerException ex)
        {
            hasError = true;
        }
        System.assertEquals(
            true,
            hasError,
            '[3] No se ha obtenido el error esperado'
            );

        hasError = false;
        try
        {
            Transformer.buildParentRelationship(
                record,
                'AccountId:ObjetoInventado__c->INFOCustomerNumber__c',
                '000000001'
                );
        }
        catch (Transformer.TransformerException ex)
        {
            hasError = true;
        }
        System.assertEquals(
            true,
            hasError,
            '[4] No se ha obtenido el error esperado'
            );

        hasError = false;
        try
        {
            Transformer.buildParentRelationship(
                record,
                'AccountId:Account->CampoInventado__c',
                '000000001'
                );
        }
        catch (Transformer.TransformerException ex)
        {
            hasError = true;
        }
        System.assertEquals(
            true,
            hasError,
            '[5] No se ha obtenido el error esperado'
            );

        // Test lookup cuenta jurídica (Cuenta y Contacto)
        Transformer myTransformer = new Transformer(Transformer.ORIGIN_NAME_INFO);
        Map<String, Object> companyJson = TestDataFactory.getINFOCustomerJson(
            1,
            'J'
            )[0];
        Account accountRecord = (Account) myTransformer.transform(
            'Account',
            companyJson
            );
        accountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                                     .get('BusinessCustomer')
                                     .getRecordTypeId();
        Contact contactRecord = (Contact) myTransformer.transform(
            'Contact',
            companyJson
            );
        contactRecord.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
                                     .get('CustomerGI')
                                     .getRecordTypeId();

        System.assertEquals(
            true,
            accountRecord.INFOCustomerNumber__c ==
            contactRecord.Account.INFOCustomerNumber__c,
            '[6] No se ha relacionado cuenta y contacto correctamente'
            );
        System.assertEquals(
            true,
            accountRecord.INFOCustomerNumber__c ==
            contactRecord.InfoCustomerContactNumber__c,
            '[7] No se ha establecido correctamente el externalID de contacto fake'
            );
    }

    @IsTest
    static void test_getTargetFields()
    {
        String configValue = 'field1field2'; // esperado [0]field1field2
        List<String> returnedValues = Transformer.getTargetFields(configValue);
        System.assertEquals(
            true,
            returnedValues[0] == 'field1field2',
            '[0] No se ha obtenido el valor de configuración esperado'
            );

        configValue = 'field1,field2'; // esperado [0]field1 [1]field2
        returnedValues = Transformer.getTargetFields(configValue);
        System.assertEquals(
            true,
            returnedValues[0] == 'field1' &&
            returnedValues[1] == 'field2',
            '[1] No se ha obtenido el valor de configuración esperado'
            );

        configValue = 'field1,field2,field3:ParentObject->ParentExternalID'; // esperado [0]field1 [1]field2 [2]field3:ParentObject->ParentExternalID
        returnedValues = Transformer.getTargetFields(configValue);
        System.assertEquals(
            true,
            returnedValues[0] == 'field1' &&
            returnedValues[1] == 'field2' &&
            returnedValues[2] == 'field3:ParentObject->ParentExternalID',
            '[2] No se ha obtenido el valor de configuración esperado'
            );

        configValue = 'field1,,field2,,,'; // esperado [0]field1 [1]field2
        returnedValues = Transformer.getTargetFields(configValue);
        System.assertEquals(
            true,
            returnedValues[0] == 'field1' &&
            returnedValues[1] == 'field2',
            '[3] No se ha obtenido el valor de configuración esperado'
            );
    }
}
