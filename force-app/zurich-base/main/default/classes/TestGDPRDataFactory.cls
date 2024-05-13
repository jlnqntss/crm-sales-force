/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 09-25-2023
 * @last modified by  : mfernandezcarrera
**/
public with sharing class TestGDPRDataFactory
{
    private static List<JerarquiaGDPR> gpdrRecords = new List<JerarquiaGDPR>();
    private static RecordType telemarketingCampaignRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Campaign' AND DeveloperName = 'Telemarketing'];
    public static RecordType ocsInquiryRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Case' AND DeveloperName = 'OCSInquiry'];

    private static Map<String, Campaign> testCampaigns = new Map<String, Campaign>();

    public static Map<String,Id> curtomersTypeRecordType
    {
        get
        {
            if(curtomersTypeRecordType != null)
            {
                return curtomersTypeRecordType;
            }

            List<RecordType> customerRecordTypes =
            [
                SELECT  DeveloperName
                FROM    RecordType
                WHERE   SobjectType = : Account.getSObjectType().getDescribe().getName()
                AND
                (
                    DeveloperName = : AccountType.BusinessCustomer.name()
                    OR
                    DeveloperName = : AccountType.Customer.name()
                )
            ];

            curtomersTypeRecordType = new Map<String,Id>();

            for(RecordType currentRecordType : customerRecordTypes)
            {
                curtomersTypeRecordType.put(currentRecordType.DeveloperName, currentRecordType.Id);
            }

            return curtomersTypeRecordType;
        }
        set;
    }


    public enum AccountType
    {
        BusinessCustomer,
        Customer // Person Account - Cliente fisico
    }

    public static JerarquiaGDPR createNewCustomer(AccountType customerType, String lastName)
    {
        JerarquiaGDPR nuevoCliente = new JerarquiaGDPR(customerType,lastName);
        gpdrRecords.add(nuevoCliente);
        return nuevoCliente;
    }

    // EntidadLegal: 000,001,002,003,004,005,006,007,008,999
    // Scope: ZE, ZEO, General
    public static Campaign createCampaign(String campaignName, String entidadLegal, String scope)
    {
        Campaign newCampaign = new Campaign(
            Name            = campaignName,
            LegalEntity__c  = entidadLegal,
            Scope__c        = scope,
            StartDate       = Date.today().addDays(30),
            EndDate         = Date.today().addDays(90),
            RecordTypeId    = telemarketingCampaignRecordType.Id
        );
        testCampaigns.put(campaignName, newCampaign);
        return newCampaign;
    }

    public static Set<Id> buildHierarchy()
    {
        List<Account> customers = new List<Account>();
        for(JerarquiaGDPR currentGDPRRecord : gpdrRecords)
        {
            customers.add(currentGDPRRecord.getCustomer());
        }
        Insert customers;

        // Los de tipo Customer son Person Account, no insertará contacto
        List<Contact> businessAccountContacts = new List<Contact>();
        for(JerarquiaGDPR currentGDPRRecord : gpdrRecords)
        {
            currentGDPRRecord.relateContactToCustomer();
            if(currentGDPRRecord.getBusinessContact() != null)
            {
                businessAccountContacts.add(currentGDPRRecord.getBusinessContact());
            }
        }
        Insert businessAccountContacts;

        Map<Id,JerarquiaGDPR> personAccountIdsByCustomer = new Map<Id,JerarquiaGDPR>();
        for(JerarquiaGDPR currentGDPRRecord : gpdrRecords)
        {
            if(String.isBlank(currentGDPRRecord.getPersonAccountId()))
            {
                continue;
            }

            personAccountIdsByCustomer.put(currentGDPRRecord.getPersonAccountId(),currentGDPRRecord);
        }

        for(Account currentPersonAccount : [SELECT PersonContactId FROM Account WHERE Id IN : personAccountIdsByCustomer.keyset()])
        {
            personAccountIdsByCustomer.get(currentPersonAccount.id).refreshPersonAccountCustomer(currentPersonAccount);
        }

        Insert testCampaigns.values();

        // Meter a campaña
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        for(JerarquiaGDPR currentGDPRRecord : gpdrRecords)
        {
            currentGDPRRecord.relateCustomerToCampaigns(testCampaigns);
            campaignMembers.addAll(currentGDPRRecord.getCampaignMembers());
        }

        Insert campaignMembers;

        List<Scope__c> scopesForCustomers = new List<Scope__c>();
        for(JerarquiaGDPR currentGDPRRecord : gpdrRecords)
        {
            currentGDPRRecord.ralateScopesToAccount();
            scopesForCustomers.addAll(currentGDPRRecord.getScopes());
        }
        Insert scopesForCustomers;

        List<ContactPointPhone> cppForScopes = new List<ContactPointPhone>();
        for(JerarquiaGDPR currentGDPRRecord : gpdrRecords)
        {
            currentGDPRRecord.relateContactPointPhonesToScopes();
            cppForScopes.addAll(currentGDPRRecord.getContactPointPhones());
        }
        Insert cppForScopes;

        List<ContactPointEmail> cpeForScopes = new List<ContactPointEmail>();
        for(JerarquiaGDPR currentGDPRRecord : gpdrRecords)
        {
            currentGDPRRecord.relateContactPointEmailsToScopes();
            cpeForScopes.addAll(currentGDPRRecord.getContactPointEmails());
        }
        Insert cpeForScopes;

        List<ContactPointAddress> cpaForScopes = new List<ContactPointAddress>();
        for(JerarquiaGDPR currentGDPRRecord : gpdrRecords)
        {
            currentGDPRRecord.relateContactPointAddressesToScopes();
            cpaForScopes.addAll(currentGDPRRecord.getContactPointAddresses());
        }
        Insert cpaForScopes;

        List<Policy__c> customerPolicies = new List<Policy__c>();
        for(JerarquiaGDPR currentGDPRRecord : gpdrRecords)
        {
            currentGDPRRecord.relatePolicyToCustomer();
            customerPolicies.addAll(currentGDPRRecord.getPolicies());
        }
        Insert customerPolicies;

        List<Opportunity> customerOffers = new List<Opportunity>();
        for(JerarquiaGDPR currentGDPRRecord : gpdrRecords)
        {
            currentGDPRRecord.relateOffersToAccount();
            customerOffers.addAll(currentGDPRRecord.getOffers());
        }
        Insert customerOffers;

        List<Claim__c> customerClaims = new List<Claim__c>();
        for(JerarquiaGDPR currentGDPRRecord : gpdrRecords)
        {
            currentGDPRRecord.relateClaimToCustomer();
            customerClaims.addAll(currentGDPRRecord.getClaims());
        }
        insert customerClaims;

        List<Case> customerCases = new List<Case>();
        customerCases.addAll(processCaseHierarchy(gpdrRecords));
        Insert customerCases;

        List<EmailMessage> emails = new List<EmailMessage>();
        for(JerarquiaGDPR currentGDPRRecord : gpdrRecords)
        {
            currentGDPRRecord.relateEmailsToCase();
            emails.addAll(currentGDPRRecord.getCaseEmails());
        }
        Insert emails;

        List<Task> tasks = new List<Task>();

        for(JerarquiaGDPR currentGDPRRecord : gpdrRecords)
        {
            currentGDPRRecord.relateTasksToEmail();
            tasks.addAll(currentGDPRRecord.getTasks());
        }
        Insert tasks;

        return new Map<Id,Account>(customers).keyset();
    }

    private static List<Case> processCaseHierarchy(List<JerarquiaGDPR> gpdrRecords)
    {
        List<Case> hierarchyRecords = new List<Case>();
        for(JerarquiaGDPR currentGDPRRecord : gpdrRecords)
        {
            currentGDPRRecord.relateCaseToCustomer();
            currentGDPRRecord.relateCasesToPolicies();
            currentGDPRRecord.relateCasesToOpportunities();
            currentGDPRRecord.relateCasesToClaims();
            hierarchyRecords.addAll(currentGDPRRecord.getCases());
        }
        return hierarchyRecords;
    }

    public class JerarquiaGDPR
    {
        Account customer;
        Boolean isCustomer;
        Contact businessContact;
        Map<String, Scope__c> scopes = new Map<String, Scope__c>();
        Map<ContactPointPhone, String> contactPointPhones = new Map<ContactPointPhone, String>();
        Map<ContactPointEmail, String> contactPointEmails = new Map<ContactPointEmail, String>();
        Map<ContactPointAddress, String> contactPointAddresses = new Map<ContactPointAddress, String>();
        Map<String,CampaignMember> campaignNames = new Map<String,CampaignMember>();
        List<CampaignMember> campaignMemberships = new List<CampaignMember>();
        Map<String,Policy__c> policiesByNumber = new Map<String,Policy__c>();
        Map<String, Opportunity> opportunitiesByName = new Map<String,Opportunity>();
        Map<String,Claim__c> claimsByNumber = new Map<String,Claim__c>();
        Map<String,Case> casesByName = new Map<String,Case>();
        Map<String,Emailmessage> caseEmails = new Map<String,EmailMessage>();
        Map<String, Task> emailTasks = new map<String,Task>();



        public JerarquiaGDPR(TestGDPRDataFactory.AccountType customerType, String lastName)
        {
            validateBlankValue(lastname, 'La cuenta necesita nombre');

            isCustomer = customerType.name() == 'Customer';
			String accountRecordTypeId    = TestGDPRDataFactory.curtomersTypeRecordType.get(customerType.name());

            if(isCustomer)
            {
                customer = new Account(
                    LastName = lastName
                );
            }
            else
            {
                customer = new Account(
                Name = lastName
                );
            }
            customer.RecordTypeId = accountRecordTypeId;
        }

        public Account getCustomer()
        {
            return customer;
        }

        /*********
         * CONTACT
         *********/
        public JerarquiaGDPR addBusinessContact()
        {
            if(!isCustomer)
            {
                businessContact = new Contact(LastName = customer.Name);
            }
            return this;
        }

        public void relateContactToCustomer()
        {
            if(!isCustomer)
            {
                businessContact.AccountId = customer.Id;
            }
        }

        public Contact getBusinessContact()
        {
            return businessContact;
        }

        public Id getPersonAccountId()
        {
            if(isCustomer)
            {
                return customer.Id;
            }

            return null;
        }

        public void refreshPersonAccountCustomer(Account personAccount)
        {
            if(isCustomer && personAccount.Id == customer.id && String.isNotBlank(personAccount.PersonContactId))
            {
                customer = personAccount;
            }
        }

        /*******
         * SCOPE
         *******/

        //Available Types: Z,ZE,ZEO,ZEB,Ventas
        public JerarquiaGDPR addScope(String scopeName, String scopeType)
        {
            validateBlankValue(scopeName,'Los scopes necesitan nombre');

            scopes.put(scopeName ,new Scope__c(
                Name            = scopeName,
                Scope__c        = scopeType
            ));

            return this;
        }

        public void ralateScopesToAccount()
        {
            if(String.isNotBlank(customer.Id))
            {
                for(Scope__c currentScope : scopes.values())
                {
                    currentScope.AccountId__c = customer.Id;
                }
            }
        }

        public List<Scope__c> getScopes()
        {
            return scopes.values();
        }

        /*********************
         * CONTACT POINT PHONE
         *********************/

        public JerarquiaGDPR addContactPointPhone(String phoneNumber, String relatedScopeName)
        {
            validateBlankValue(phoneNumber, 'Hace falta un telefono para un ContactPointPhone');

            contactPointPhones.put(new ContactPointPhone(
                TelephoneNumber = phoneNumber
            ), relatedScopeName);

            return this;
        }

        public void relateContactPointPhonesToScopes()
        {
            for(ContactPointPhone currentCPP : contactPointPhones.keySet())
            {
                String scopeName  = contactPointPhones.get(currentCPP);
                Scope__c scopeOfInterest = scopes.get(scopeName);
                currentCPP.ScopeId__c   = scopeOfInterest.Id;
                currentCPP.ParentId     = customer.Id;
            }
        }

        public Set<ContactPointPhone> getContactPointPhones()
        {
            return contactPointPhones.keySet();
        }

        /*********************
         * CONTACT POINT EMAIL
         *********************/

        public JerarquiaGDPR addContactPointEmail(String email, String relatedScopeName)
        {
            validateBlankValue(email, 'Hace falta un email para un ContactPointEmail');

            contactPointEmails.put(new ContactPointEmail(
            EmailAddress = email
            ), relatedScopeName);

            return this;
        }

        public void relateContactPointEmailsToScopes()
        {
            for(ContactPointEmail currentCPE : contactPointEmails.keySet())
            {
                String scopeName  = contactPointEmails.get(currentCPE);
                Scope__c scopeOfInterest = scopes.get(scopeName);
                currentCPE.ScopeId__c   = scopeOfInterest.Id;
                currentCPE.ParentId     = customer.Id;
            }
        }

        public Set<ContactPointEmail> getContactPointEmails()
        {
            return contactPointEmails.keySet();
        }

        /***********************
         * CONTACT POINT ADDRESS
         ***********************/

        public JerarquiaGDPR addContactPointAddress(String addressName, String relatedScopeName)
        {
            validateBlankValue(addressName, 'Hace falta un nombre para un ContactPointAddress');

            contactPointAddresses.put(new ContactPointAddress(
                Name = addressName,
                street = '111 John Street',
                city = 'San Francisco',
                state = 'CA',
                postalCode = '94111',
                country = 'United States'
            ), relatedScopeName);

            return this;
        }

        public void relateContactPointAddressesToScopes()
        {
            for(ContactPointAddress currentCPA : contactPointAddresses.keySet())
            {
                String scopeName  = contactPointAddresses.get(currentCPA);
                Scope__c scopeOfInterest = scopes.get(scopeName);
                currentCPA.ScopeId__c   = scopeOfInterest.Id;
                currentCPA.ParentId     = customer.Id;
            }
        }

        public Set<ContactPointAddress> getContactPointAddresses()
        {
            return contactPointAddresses.keySet();
        }

        /*****************
         * CAMPAIGN MEMBER
         *****************/

        public JerarquiaGDPR addToCampaign(String campaignName)
        {
            campaignNames.put(campaignName,null);
            return this;
        }

        public void relateCustomerToCampaigns(Map<String,Campaign> campaigns)
        {
            if(campaigns == null)
            {
                return;
            }

            for(String currentCampaign : campaignNames.keySet())
            {
                if(campaigns.containsKey(currentCampaign))
                {
                    campaignMemberships.add(new CampaignMember(
                        CampaignId = campaigns.get(currentCampaign).Id,
                        ContactId = isCustomer ? customer.PersonContactId : businessContact.Id
                    ));
                }
            }
        }

        public List<CampaignMember> getCampaignMembers()
        {
            return campaignMemberships;
        }

        private void validateBlankValue(Object parameter, String errorMessage)
        {
            if(parameter == null || (parameter instanceOf String && String.isBlank((String) parameter)))
            {
                throw new IllegalArgumentException(errorMessage);
            }
        }

        /*************
         * OPPORTUNITY (Offer)
         *************/

        public JerarquiaGDPR addOpportunity(String opportunityName)
        {
            opportunitiesByName.put(opportunityName, new Opportunity(
                Name = opportunityName,
                StageName = 'Quoted',
                CloseDate = Date.today().addDays(90)
            ));

            return this;
        }

        public void relateOffersToAccount()
        {
            for(Opportunity currentOpportunity : opportunitiesByName.values())
            {
                currentOpportunity.AccountId = customer.Id;
            }
        }

        public List<Opportunity> getOffers()
        {
            return opportunitiesByName.values();
        }

        /********
         * POLICY
         ********/

        public JerarquiaGDPR addPolicy(String policyNumber)
        {
            policiesByNumber.put(policyNumber,new Policy__c(
                Name = policyNumber
            ));

            return this;
        }

        public void relatePolicyToCustomer()
        {
            for(Policy__c currentPolicy : policiesByNumber.values())
            {
                currentPolicy.PolicyHolder__c = customer.Id;
            }
        }

        public List<Policy__c> getPolicies()
        {
            return policiesByNumber.values();
        }

        /*******
         * CLAIM
         ******/

        public JerarquiaGDPR addClaim(String claimNumber)
        {
            claimsByNumber.put(claimNumber,new Claim__c(
                Name = claimNumber
            ));

            return this;
        }

        public void relateClaimToCustomer()
        {
            for(Claim__c currentClaim : claimsByNumber.values())
            {
                currentClaim.PolicyHolder__c = customer.Id;
            }
        }

        public List<Claim__c> getClaims()
        {
            return claimsByNumber.values();
        }


        /*******
         * CASE
         ******/


        public JerarquiaGDPR addCase(String caseName, String policyNumber, String opportunityName, String claimNumber)
        {
            Case newCase = new Case
            (
                Subject = caseName,
                //Status = 'Pending',
                Origin = 'Phone',
                SourceArea__c = 'Mediator',
                RobotTypeN1__c = 'Venta',
                RecordTypeId = TestGDPRDataFactory.ocsInquiryRecordType.Id
            );

            if(String.isNotBlank(policyNumber))
            {
                newCase.PolicyNum__c = policyNumber;
            }

            if(String.isNotBlank(opportunityName))
            {
                newCase.CreatedOffer__c = opportunityName;
            }

            if(String.isNotBlank(claimNumber))
            {
                newCase.ClaimDetail__c = claimNumber;
            }

            casesByName.put(caseName, newCase);

            return this;
        }

        public void relateCaseToCustomer()
        {
            for(Case currentCase : casesByName.values())
            {
                currentCase.AccountId = customer.Id;
            }
        }

        public void relateCasesToPolicies()
        {
            for(Case currentCase : casesByName.values())
            {
                if(String.isNotBlank(currentCase.PolicyNum__c) && policiesbyNumber.containsKey(currentCase.PolicyNum__c))
                {
                    Policy__c chosenPolicy  = policiesbyNumber.get(currentCase.PolicyNum__c);
                    currentCase.PolicyId__c  = chosenPolicy.Id;
                }
            }
        }

        public void relateCasesToOpportunities()
        {
            for(Case currentCase : casesByName.values())
            {
                if(String.isNotBlank(currentCase.CreatedOffer__c) && opportunitiesByName.containsKey(currentCAse.CreatedOffer__c))
                {
                    Opportunity chosenOpportunity = opportunitiesByName.get(currentCase.CreatedOffer__c);
                    currentCase.OfferId__c = chosenOpportunity.Id;
                }
            }
        }

        public void relateCasesToClaims()
        {
            for(Case currentCase : casesByName.values())
            {
                if(String.isNotBlank(currentCase.ClaimDetail__c) && claimsByNumber.containsKey(currentCase.ClaimDetail__c))
                {
                    Claim__c chosenClaim = claimsByNumber.get(currentCase.ClaimDetail__c);
                    currentCase.ClaimId__c = chosenClaim.Id;
                }
            }
        }

        public List<Case> getCases()
        {
            return casesByName.values();
        }

        /***************
         * EMAIL MESSAGE
         **************/

        public JerarquiaGDPR addEmailmessage(String emailSubject, String caseName)
        {
            caseEmails.put(caseName, new EmailMessage(
                Subject = emailSubject,
                FromAddress = 'madeup@emaildoesntwork.com',
                ToAddress = 'particulares.dtsev@zurich.com.invalid'
            ));

            return this;
        }

        public void relateEmailsToCase()
        {
            for(String currentEM : caseEmails.keyset())
            {
                Case relatedCase = casesByName.get(currentEM);

                caseEmails.get(currentEM).HtmlBody = 'Correo relacionado con ' + relatedCase.Id;
                caseEmails.get(currentEM).Subject = 'ref: ' + relatedCase.Id;
                caseEmails.get(currentEM).parentId = relatedCase.Id;
            }
        }

        public List<EmailMessage> getCaseEmails()
        {
            return caseEmails.values();
        }

        /*******
         * TASK
         ******/

        public JerarquiaGDPR addTaskToEmail(String taskSubject, String emailSubject, Id userId)
        {
        emailTasks.put(emailSubject,new Task(
            OwnerId = String.isNotBlank(userId) ? userId : Userinfo.getUserId(),
            Subject = taskSubject
        ));

        return this;
        }

        public void relateTasksToEmail()
        {

            Map<String,EmailMessage> emailBySubject = new Map<String,Emailmessage>();
            for(EmailMessage currentEM : caseEmails.values())
            {
                emailBySubject.put(currentEM.Subject, currentEM);
            }

            for(String currentTaskEmail : emailTasks.keyset())
            {
                if(emailBySubject.containsKey(currentTaskEmail))
                {
                    EmailMessage chosenEmail = emailBySubject.get(currentTaskEmail);
                    Task currentTask = emailTasks.get(currentTaskEmail);
                    currentTask.WhatId = chosenEmail.Id;
                }
            }
        }

        public List<Task> getTasks()
        {
            return emailTasks.values();
        }

    }
}