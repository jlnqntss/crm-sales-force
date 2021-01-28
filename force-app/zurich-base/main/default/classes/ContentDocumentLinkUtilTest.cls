/**
 * Clases de test para ContentDocumentLinkUtil
 **
 * @author rlopez
 * @date 26/01/2021
 */
@isTest(SeeAllData=false)
private with sharing class ContentDocumentLinkUtilTest
{
    @TestSetup
    public static void createScenario()
    {
        
    }

    /**
     * Test que comprueba que al insertar un nuevo ContactPointEmail marcado como IsPrimary,
     * se actualiza correctamente el campo PrimaryEmail__c del ámbito
     *
     * @author rlopez
     * @date 26/01/2021
     */
    @isTest
    static void test_email2case_hegeo_ok()
    {
        Case relatedCase = new Case();
        insert relatedCase;

        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Status = '3'; // email was sent
        emailMessage.ParentId = relatedCase.Id; 
        emailMessage.FromAddress = 'rlopez@nts-solutions.com'; // from address
        emailMessage.FromName = 'Ruben Lopez'; // from name
        emailMessage.ToAddress = 'email2case@fakeemail.com.invalid';
        emailMessage.Subject = 'HEGEO-CLASIFICACION Email';

        emailMessage.HtmlBody = 'The CSV is attached.';
        insert emailMessage;

        String csvContent = 'Incidence,App,\n';
        csvContent += 'Fake Name <from@fakeemail.com.invalid>\n';
        csvContent += 'Fake Name <to@fakeemail.com.invalid>';

        ContentVersion newVersion = new ContentVersion();
        newVersion.Title = 'HEGEO-CLASIFICACION';
        newVersion.PathOnClient = 'HEGEO-CLASIFICACION.csv';
        newVersion.VersionData = Blob.valueof(csvContent);
        insert newVersion;

        newVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: newVersion.Id];

        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.ContentDocumentId = newVersion.ContentDocumentId;
        newLink.LinkedEntityId = emailMessage.Id;
        Test.startTest();
        insert newLink;
        Test.stopTest();

        EmailMessage updatedEmailMessage = [SELECT Id, FromAddress, ToAddress FROM EmailMessage WHERE Id =: emailMessage.Id];
        System.debug('updatedEmailMessage: ' + updatedEmailMessage);
        System.assertEquals(true, updatedEmailMessage != null, 'EmailMessage found');
        System.assertEquals(true, updatedEmailMessage.FromAddress == 'from@fakeemail.com.invalid', 'FromAddress is the same');
        System.assertEquals(true, updatedEmailMessage.ToAddress == 'to@fakeemail.com.invalid', 'ToAddress is the same');

        Case updatedCase = [SELECT Id, Type, Subtype__c, TypeN3__c FROM Case WHERE Id =: relatedCase.Id];
        System.assertEquals(true, updatedCase != null, 'Case found');
        System.assertEquals(true, updatedCase.Type == 'Incidence', 'Type is incidence');
        System.assertEquals(true, updatedCase.Subtype__c == 'App', 'Subtype is app');
    }
}