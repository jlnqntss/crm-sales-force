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
        String csvContent = [SELECT Body FROM StaticResource WHERE Name = 'testcsvemail' ].Body.toString();
        System.debug('csvContent: ' + csvContent);

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
        System.assertEquals(true, updatedEmailMessage != null, 'EmailMessage found');
        System.assertEquals(true, updatedEmailMessage.FromAddress == 'from@fakeemail.com.invalid', 'FromAddress is the same');
        System.assertEquals(true, updatedEmailMessage.ToAddress == 'to@fakeemail.com.invalid', 'ToAddress is the same'); 
    }
}