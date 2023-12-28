@isTest
private class AccountTeamMemberUtilTest
{
    @TestSetup
    public static void createScenario()
    {
        //Accounts Intermediary donde se actualizará el campo indicado
        Id accountIntermediaryRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
        Account cuenta1= new Account(RecordTypeId=accountIntermediaryRecordType,Name='Intermediario 1');
        insert cuenta1;
        Account cuenta2= new Account(RecordTypeId=accountIntermediaryRecordType,Name='Intermediario 2');
        insert cuenta2;
        
        //Account Customer para posteriormente crear AccountTeamMember
        Profile profile = [SELECT Id FROM Profile WHERE Name='USP Supervisor' LIMIT 1];
        String profileId= profile.Id;

        List<User> listUser=TestDataFactory.generateUsersByProfile(profileId, 1);
        listUser[0].FirstName='NOMBRE';
        listUser[0].LastName='APELLIDOS';
        insert listUser;
    }

    @isTest
    public static void updateAccount_OK()
    {
        User usuario= [SELECT Id, Name, LastName FROM User LIMIT 1];
        List<Account> cuenta= [SELECT Id,BusinessManagerName__c FROM Account LIMIT 2];

        
        String fieldToUpdate='BusinessManagerName__c';
        
        Test.startTest();
        //AÑADIR
        AccountTeamMemberUtil.updateIntermediaryWithAccountTeamMembersName(cuenta[0],fieldToUpdate,usuario);
        update cuenta[0];
        //VACIAR 
        AccountTeamMemberUtil.emptyIntermediaryWithAccountTeamMembersName(cuenta[1],fieldToUpdate);
        update cuenta[1];
        Test.stopTest();

        String idCuenta=cuenta[0].Id;
        Account actualizada= [SELECT BusinessManagerName__c FROM Account WHERE Id=:idCuenta];
        System.assertNotEquals(null, actualizada.BusinessManagerName__c);

        String idCuentaEmpty=cuenta[1].Id;
        Account actualizadaEmpty= [SELECT BusinessManagerName__c FROM Account WHERE Id=:idCuentaEmpty];
        System.assertEquals(null, actualizadaEmpty.BusinessManagerName__c);
    }
}