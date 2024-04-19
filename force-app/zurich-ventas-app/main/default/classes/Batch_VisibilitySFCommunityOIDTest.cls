@IsTest
public with sharing class Batch_VisibilitySFCommunityOIDTest {
    @TestSetup
    static void makeData()
    {
        // CUSTOM SETTINGS
        Cross_Selling__c ventaCruzada = new Cross_Selling__c();
        ventaCruzada.ContactCenterUser__c = 'generico';
        ventaCruzada.DefaultUser__c = 'adminkli';
        insert ventaCruzada;

        // ACCOUNTS (Mediadores)
        List<Account> intermediaries = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Intermediary', 2);
        List<Account> agrupaciones = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'AgrupacionMediador', 1);

        List<Account> accToInsert = new List<Account>();
        accToInsert.addAll(intermediaries);
        accToInsert.addAll(agrupaciones);
        insert accToInsert;
        
        // CONTACTOS (Mediadores)
        List<Contact> intermediaryContacts = TestDataFactory.generateContactsFromAccounts(intermediaries, ContactsSelector.RT_NAME_CONTACT, 1);
        insert intermediaryContacts;
        
        // USUARIOS
        List<String> adminProfiles = new List<String> {'Administrador del sistema', 'System Administrator'};
        List<Boolean> activeStatus = new List<Boolean> {true};
        
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        String portalProfile = [SELECT Id FROM Profile WHERE Name = 'Agente Ventas' LIMIT 1].Id;
        
        User adminUser = (new UsersSelector()).findByProfileName(adminProfiles, activeStatus, 1)[0];
        List<User> listUser = TestDataFactory.generateUsersByProfile(portalProfile, 2);
        
        listUser[0].FirstName='Agente';
        listUser[0].LastName='Mediador 1';
        listUser[0].Alias='test1Med';
        listUser[0].ContactId = intermediaryContacts[0].Id;
        listUser[1].FirstName='Agente';
        listUser[1].LastName='Mediador 2';
        listUser[1].Alias='test2Med';
        listUser[1].UserRole = portalRole;
        listUser[1].ContactId = intermediaryContacts[1].Id;
        
        System.runAs (adminUser)
        {
            insert listUser;
        }

        // CONFIGURACIÓN DE MEDIADORES
        List<User> communityUsers = new List<User>([SELECT Contact.AccountId FROM User WHERE Alias = 'test1Med' LIMIT 1]);
        Id intermediaryAccountUser1Id = communityUsers.get(0).Contact.AccountId;

        // asociar los mediadores con cuenta a cada una de las agrupaciones
        Account intermediaryUser1 = new Account();
        intermediaryUser1.Id = intermediaryAccountUser1Id;
        intermediaryUser1.IntermediaryGroup__c = agrupaciones.get(0).Id;

        // informar el mediador principal de las agrupaciones
        Account agrupacion1 = new Account();
        agrupacion1.Id = agrupaciones.get(0).Id;
        agrupacion1.IntermediaryWithUser__c = intermediaryAccountUser1Id;

        // asociar el mediador sin usuario a una agrupacion
        List<Account> accountWithUserToAssignGroup = new List<Account>();
        accountWithUserToAssignGroup.add(intermediaryUser1);

        Account intermediaryWithNoUser = [SELECT Id FROM Account WHERE Id NOT IN :accountWithUserToAssignGroup LIMIT 1];
        intermediaryWithNoUser.IntermediaryGroup__c = agrupacion1.Id;

        List<Account> accountToUpdate = new List<Account>();
        accountToUpdate.add(intermediaryUser1);
        accountToUpdate.add(agrupacion1);
        accountToUpdate.add(intermediaryWithNoUser);

        update accountToUpdate;

        // ACCOUNTS (Clientes)
        List<Account> customers = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 2);
        List<Account> mediadoresAgrupacion1 = new List<Account>([SELECT Id FROM Account WHERE IntermediaryGroup__c = :agrupacion1.Id]);
        customers[0].Intermediary_Name__c = mediadoresAgrupacion1[0].Id;
        insert customers;

        // PÓLIZAS
        // Creamos una póliza solo para uno de los Accounts del paso anterior
        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(customers, 1);
        for (Policy__c policy: policies)
        {
            policy.IntermediaryId__c = intermediaryUser1.Id;
            policy.PolicyStatus__c = 'V';
            policy.Anonymized__c = false;
            policy.Blocked__c = false;
        }
        policies[1].IntermediaryId__c = intermediaryUser1.Id;
        policies[1].Blocked__c = true;
        insert policies;
        
        // ACCOUNT TEAM MEMBERS
        // Vinculamos el ATM al cliente sin póliza del paso anterior para comprobar que el proceso lo borre
        List<AccountTeamMember> atmToInsert = new List<AccountTeamMember>();
        for (Account c : customers)
        {
            AccountTeamMember atm = new AccountTeamMember();
            atm.AccountId = c.Id;
            atm.UserId = communityUsers[0].Id;
            atm.TeamMemberRole = 'MediadorZRM';
            atm.AccountAccessLevel = 'Edit';
            atm.ContactAccessLevel = 'Read';
            atm.OpportunityAccessLevel = 'None';
            atm.CaseAccessLevel = 'None';
            atmToInsert.add(atm);
        }
        insert atmToInsert;
    }

    /**
     * @author fpalomo
     * @date 29/02/2024
     */
    @IsTest
    static void testCalcVisibilityOk()
    {
        List<User> communityUsers = new List<User>([SELECT Profile.Name FROM User WHERE Alias = 'test1Med' LIMIT 1]);
        
        Test.startTest();
        Database.executeBatch(new Batch_VisibilitySFCommunityOID(communityUsers[0].Profile.Name, communityUsers[0].Id));
        Test.stopTest();
        
        List<AccountTeamMember> atmAfter = [SELECT Id FROM AccountTeamMember];
        Assert.areNotEqual(0, atmAfter.size(), 'Debería haber al menos un ATM');
    } 
}