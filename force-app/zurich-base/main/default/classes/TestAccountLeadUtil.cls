/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 11/08/2023
 * @last modified by  : jgallaga
**/
@IsTest
public with sharing class TestAccountLeadUtil
{
    @TestSetup
    static void makeData()
    {
        Map<String, User> testUsers = createCommnunityUsers();
    }

    private static Map<String, User> createCommnunityUsers()
    {
        User adminUser = [SELECT Id FRom User WHERE Profile.Name = 'System Administrator' AND Id != :UserInfo.getUserId() AND isActive = true LIMIT 1];

        Map<String, User> communityAgents = prepareNewUsers();

        Map<String, Account> communityAgentAccounts = insertAccounts(communityAgents.keySet());
        Map<String, Contact> communitAgentContacts = insertContacts(communityAgents.keySet(), communityAgentAccounts); //Contact

        System.runAs(adminUser)
        {
            relateRecordsToAgents(communityAgents, communitAgentContacts);
        }

        return communityAgents;
    }

    private static void relateRecordsToAgents(Map<String, User> communityAgents, Map<String, Contact> communityAgentContacts)
    {
        Profile zrmCommunityProfile = [Select Id from Profile where name = 'Agente Ventas'];

        for(String currentUserName : communityAgents.keySet())
        {
            User currentUser = communityAgents.get(currentUserName);
            currentUser.ContactId = communityAgentContacts.get(currentUserName).Id;
            currentUser.ProfileId = zrmCommunityProfile.Id;
        }

        insert communityAgents.values();
    }

    private static Map<String, Contact> insertContacts(Set<String> communityUserNames, Map<String, Account> agentAccounts)
    {
        Map<String, Contact> agentContactRecords = new Map<String, Contact>();

        for(String currentUserName : communityUserNames)
        {
            Account agentAccount = agentAccounts.get(currentUserName);
            agentContactRecords.put(currentUserName, new Contact(
                LastName = currentUserName,
                AccountId = agentAccount.Id
            ));
        }

        insert agentContactRecords.values();

        return agentContactRecords;
    }

    private static Map<String, Account> insertAccounts(Set<String> communityUserNames)
    {
        Map<String ,Account> agentAccounts = new Map<String, Account>();
        RecordType agentAccountRecordType = [SELECT Id FROM RecordType WHERE Name = 'Parent Account' AND SobjectType = 'Account'];


        for(String currentCommunityName : communityUserNames)
        {
            agentAccounts.put(currentCommunityName, new Account(
                Name = currentCommunityName,
                RecordTypeId = agentAccountRecordType.Id,
                INFOIntermediaryCode__c = currentCommunityName
            ));
        }

        insert agentAccounts.values();

        return agentAccounts;
    }

    private static Map<String, User> prepareNewUsers()
    {
        Map<String, User> communityAgents = new Map<String, User>();

        communityAgents.put('IDIOMA-ES', new User(
            Username = 'testAssignmetZurich@zurich.com' + '1',
            Alias = 'sfdc',
            Email='testAssignmetZurich@zurich.com',
            EmailEncodingKey='UTF-8',
            Firstname='Test',
            Lastname='IDIOMA-ES',
            LanguageLocaleKey='es',
            LocaleSidKey='es',
            TimeZoneSidKey='Europe/Madrid'
        ));

        communityAgents.put('IDIOMA-FR', new User(
            Username = 'testAssignmetZurich@zurich.com' + '2',
            Alias = 'sfdc',
            Email='testAssignmetZurich@zurich.com',
            EmailEncodingKey='UTF-8',
            Firstname='Test',
            Lastname='IDIOMA-FR',
            LanguageLocaleKey='es',
            LocaleSidKey='es',
            TimeZoneSidKey='Europe/Madrid'
        ));

        return communityAgents;
    }

    @isTest
    static void test_AssignmentFrenchLanguageAgent()
    {
        //Creación de metadatos
        List<LanguageAssignment__mdt> testLanguageAssignmentMetadata = new List<LanguageAssignment__mdt>();
        testLanguageAssignmentMetadata.add(new LanguageAssignment__mdt(DeveloperName = 'Español', AssignTo__c = 'IDIOMA-ES', Language__c = 'ES'));
        testLanguageAssignmentMetadata.add(new LanguageAssignment__mdt(DeveloperName = 'Frances', AssignTo__c = 'IDIOMA-FR', Language__c = 'FR'));

        AccountLeadAssignment.languageAssignmentMetadata = testLanguageAssignmentMetadata;

        String frenchAgenteId = [SELECT Id FROM User WHERE Lastname = 'IDIOMA-FR'].Id;

        Test.startTest();
        String resultAssignmentUserId = AccountLeadUtil.leadAssignment(null,null,null,'FR',null);
        Test.stopTest();

        Assert.areEqual(frenchAgenteId, resultAssignmentUserId, 'El usuario asignado para el lenguaje frances no es correcto.');
    }

}