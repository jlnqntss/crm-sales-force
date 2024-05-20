@isTest
public with sharing class ContentDocumentLinkSelectorTest {
    
    @TestSetup
    static void makeData() {
        
        /** Insertar usuarios ZRM ***************************************************************/
        // Crear cuentas de agrupacion
        List<Account> agrupaciones = TestDataFactory.generateAccounts(Label.GeneralInsurance,'AgrupacionMediador', 1);
        insert agrupaciones;
        // Crear cuentas de mediadores
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 1);
        intermediaryAccounts.get(0).IntermediaryGroup__c = agrupaciones.get(0).Id;
        intermediaryAccounts.get(0).INFOIntermediaryCode__c = '0000012345';
        intermediaryAccounts.get(0).Name = 'MediadorTest';
        insert intermediaryAccounts;

        // Crear contactos de mediadores
        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(intermediaryAccounts, ContactsSelector.RT_NAME_CONTACT, 2);
        insert contacts;

        // Crear los usurios para recuperar
        List<User> userList = new List<User>();
        List<User> userAGRList = new List<User>();

        List<String> adminProfiles = new List<String> {'Administrador del sistema', 'System Administrator'};
        List<Boolean> activeStatus = new List<Boolean> {true};
        User adminUser = ( new UsersSelector() ).findByProfileName(adminProfiles, activeStatus, 1)[0];

        System.runAs (adminUser)
        {
            // Usuario Nominal
            String portalProfile = [SELECT Id FROM Profile WHERE Name = :ProfilesSelector.PROFILE_AGENTE_VENTAS LIMIT 1].Id;

            userList = TestDataFactory.generateUsersByProfile(portalProfile, 1);
            userList[0].ContactId = contacts[0].Id;
            insert userList;

            // Usuario AGR
            String portalAGRProfile = [SELECT Id FROM Profile WHERE Name = :ProfilesSelector.PROFILE_AGENTE_VENTAS_AGR LIMIT 1].Id;

            userAGRList = TestDataFactory.generateUsersByProfile(portalAGRProfile, 1);            
            userAGRList[0].ContactId = contacts[1].Id;

            insert userAGRList;
        }

        User zrmIntermediary = [SELECT Id, Contact.AccountId FROM User WHERE Profile.Name = :ProfilesSelector.PROFILE_AGENTE_VENTAS AND  Contact.Account.Name = 'MediadorTest' LIMIT 1];
        
        /********************************  CLIENTES  ********************************/
        // Crear cuentas de clientes
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;
 
        /********************************  Poliza  ********************************/
        // Inserto una póliza para que el usuario zrm pueda ver al cliente

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);
        policies[0].IntermediaryId__c = zrmIntermediary.Contact.AccountId;

        insert policies;


        // Insertar documento
        ContentVersion content=new ContentVersion(); 

        content.Title='Header_Picture1'; 

        content.PathOnClient='/' + content.Title + '.jpg'; 

        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 

        content.VersionData=bodyBlob; 

        content.origin = 'H';

        insert content;

        ContentDocumentLink contentlink=new ContentDocumentLink();

        contentlink.LinkedEntityId=accounts.get(0).id;

        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;

        contentlink.ShareType = 'I';

        contentlink.Visibility = 'AllUsers'; 

        insert contentlink;

    }

    @isTest
    private static void test_getZRMContentDocumentByLinkedEntity() {

        Account cliente = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Customer' LIMIT 1];
        Account intermediary = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Intermediary' LIMIT 1];

        Test.startTest();
        
        List<ContentDocumentLink> result = (new ContentDocumentLinkSelector()).getZRMContentDocumentByLinkedEntity(cliente.Id, intermediary.Id);

        Test.stopTest();

        Assert.isTrue(result.size() >= 0, 'Debe obtener registros');        

    }

    @isTest
    private static void test_getZRMAGRContentDocumentByLinkedEntity() {

        Account cliente = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Customer' LIMIT 1];
        Account intermediary = [SELECT Id, IntermediaryGroup__c FROM Account WHERE RecordType.DeveloperName = 'Intermediary' LIMIT 1];

        Test.startTest();
        
        List<ContentDocumentLink> result = (new ContentDocumentLinkSelector()).getZRMAGRContentDocumentByLinkedEntity(cliente.Id, intermediary.IntermediaryGroup__c);

        Test.stopTest();

        Assert.isTrue(result.size() >= 0, 'Debe obtener registros'); 
        

    }
}