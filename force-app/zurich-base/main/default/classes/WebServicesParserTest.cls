@isTest
private class WebServicesParserTest
{
    private static void createGenericControlList(
        boolean ignoringErrors,
        String picklistValues,
        boolean nullables,
        boolean required
        )
    {
        List<WebServicesControl__mdt> wsControlList = new List<WebServicesControl__mdt>();
        /*public WebServiceControl(String attName, String src, String servName, String entName, String fldName, String relObjType,
                                    Boolean nlb, String pickValues, Boolean ignErrors, Boolean req, Boolean arr, Boolean obj,
                                    String pickObjId, String pickObjName, Boolean extId)*/
        //Checkbox
        wsControlList.add(
            new WebServicesControl__mdt(
                AttributeName__c = 'Private',
                Source__c = 'Web',
                ServiceName__c = 'GenericWS',
                EntityName__c = 'Opportunity',
                FieldName__c = 'IsPrivate',
                Nullable__c = nullables,
                IgnoreErrors__c = false,
                Required__c = required,
                Array__c = false,
                Object__c = false,
                External_Id__c = false,
                Duplicate__c = false,
                Nested__c = false
                )
            );
        //Double
        wsControlList.add(
            new WebServicesControl__mdt(
                AttributeName__c = 'Revenue',
                Source__c = 'Web',
                ServiceName__c = 'GenericWS',
                EntityName__c = 'Account',
                FieldName__c = 'AnnualRevenue',
                Nullable__c = nullables,
                IgnoreErrors__c = false,
                Required__c = required,
                Array__c = false,
                Object__c = false,
                External_Id__c = false,
                Duplicate__c = false,
                Nested__c = false
                )
            );
        //Text
        wsControlList.add(
            new WebServicesControl__mdt(
                AttributeName__c = 'AccountSite',
                Source__c = 'Web',
                ServiceName__c = 'GenericWS',
                EntityName__c = 'Account',
                FieldName__c = 'Site',
                Nullable__c = nullables,
                IgnoreErrors__c = false,
                Required__c = required,
                Array__c = false,
                Object__c = false,
                External_Id__c = false,
                Duplicate__c = false,
                Nested__c = false
                )
            );
        //Email
        wsControlList.add(
            new WebServicesControl__mdt(
                AttributeName__c = 'EmailAddress',
                Source__c = 'Web',
                ServiceName__c = 'GenericWS',
                EntityName__c = 'Contact',
                FieldName__c = 'Email',
                Nullable__c = nullables,
                IgnoreErrors__c = false,
                Required__c = required,
                Array__c = false,
                Object__c = false,
                External_Id__c = false,
                Duplicate__c = false,
                Nested__c = false
                )
            );
        //Integer
        wsControlList.add(
            new WebServicesControl__mdt(
                AttributeName__c = 'Employees',
                Source__c = 'Web',
                ServiceName__c = 'GenericWS',
                EntityName__c = 'Account',
                FieldName__c = 'NumberOfEmployees',
                Nullable__c = nullables,
                IgnoreErrors__c = false,
                Required__c = required,
                Array__c = false,
                Object__c = false,
                External_Id__c = false,
                Duplicate__c = false,
                Nested__c = false
                )
            );
        //Date
        wsControlList.add(
            new WebServicesControl__mdt(
                AttributeName__c = 'WhenIsClosed',
                Source__c = 'Web',
                ServiceName__c = 'GenericWS',
                EntityName__c = 'Opportunity',
                FieldName__c = 'CloseDate',
                Nullable__c = nullables,
                IgnoreErrors__c = false,
                Required__c = required,
                Array__c = false,
                Object__c = false,
                External_Id__c = false,
                Duplicate__c = false,
                Nested__c = false
                )
            );
        //Id
        wsControlList.add(
            new WebServicesControl__mdt(
                AttributeName__c = 'Account',
                Source__c = 'Web',
                ServiceName__c = 'GenericWS',
                EntityName__c = 'Opportunity',
                FieldName__c = 'AccountId',
                Nullable__c = nullables,
                IgnoreErrors__c = ignoringErrors,
                Required__c = required,
                Array__c = false,
                Object__c = false,
                External_Id__c = false,
                Duplicate__c = false,
                Nested__c = false
                )
            );
        //Picklist
        wsControlList.add(
            new WebServicesControl__mdt(
                AttributeName__c = 'Level',
                Source__c = 'Web',
                ServiceName__c = 'GenericWS',
                EntityName__c = 'Account',
                FieldName__c = 'Rating',
                Nullable__c = nullables,
                PicklistValues__c = picklistValues,
                IgnoreErrors__c = ignoringErrors,
                Required__c = required,
                Array__c = false,
                Object__c = false,
                External_Id__c = false,
                Duplicate__c = false,
                Nested__c = false
                )
            );

        //Multipicklist - Cannot be checked, no standard multipicklist field on standard object to be used
        //wsControlList.add(new WebServicesParser.WebServiceControl('multi', 'Web', 'GenericWS', 'Account', 'MultiField__c', '',
        //																		nullables, null, ignoringErrors, required));
        //Percent
        wsControlList.add(
            new WebServicesControl__mdt(
                AttributeName__c = 'Perc',
                Source__c = 'Web',
                ServiceName__c = 'GenericWS',
                EntityName__c = 'Opportunity',
                FieldName__c = 'Probability',
                Nullable__c = nullables,
                IgnoreErrors__c = ignoringErrors,
                Required__c = required,
                Array__c = false,
                Object__c = false,
                External_Id__c = false,
                Duplicate__c = false,
                Nested__c = false
                )
            );

        //Phone
        wsControlList.add(
            new WebServicesControl__mdt(
                AttributeName__c = 'MyPhone',
                Source__c = 'Web',
                ServiceName__c = 'GenericWS',
                EntityName__c = 'Account',
                FieldName__c = 'Phone',
                Nullable__c = nullables,
                IgnoreErrors__c = ignoringErrors,
                Required__c = required,
                Array__c = false,
                Object__c = false,
                External_Id__c = false,
                Duplicate__c = false,
                Nested__c = false
                )
            );

        //URL
        wsControlList.add(
            new WebServicesControl__mdt(
                AttributeName__c = 'MyURL',
                Source__c = 'Web',
                ServiceName__c = 'GenericWS',
                EntityName__c = 'Account',
                FieldName__c = 'Website',
                Nullable__c = nullables,
                IgnoreErrors__c = ignoringErrors,
                Required__c = required,
                Array__c = false,
                Object__c = false,
                External_Id__c = true,
                Duplicate__c = false,
                Nested__c = false
                )
            );

        //DateTime
        wsControlList.add(
            new WebServicesControl__mdt(
                AttributeName__c = 'Fecha',
                Source__c = 'Web',
                ServiceName__c = 'GenericWS',
                EntityName__c = 'EmailMessage',
                FieldName__c = 'MessageDate',
                Nullable__c = nullables,
                IgnoreErrors__c = ignoringErrors,
                Required__c = required,
                Array__c = false,
                Object__c = false,
                External_Id__c = false,
                Duplicate__c = false,
                Nested__c = false
                )
            );

        //Picklist with object format
        wsControlList.add(
            new WebServicesControl__mdt(
                AttributeName__c = 'Sector',
                Source__c = 'Web',
                ServiceName__c = 'GenericWS',
                EntityName__c = 'Account',
                FieldName__c = 'Industry',
                Nullable__c = nullables,
                IgnoreErrors__c = ignoringErrors,
                PicklistValues__c = picklistValues,
                Required__c = required,
                Array__c = false,
                Object__c = true,
                PicklistAttributesName__c = 'id;name',
                External_Id__c = false,
                Duplicate__c = false,
                Nested__c = false
                )
            );

        wsControlList.add(
            new WebServicesControl__mdt(
                AttributeName__c = 'Padre',
                Source__c = 'Web',
                ServiceName__c = 'GenericWS',
                EntityName__c = 'Account',
                FieldName__c = 'Parent.Name',
                Nullable__c = nullables,
                IgnoreErrors__c = ignoringErrors,
                PicklistValues__c = picklistValues,
                Required__c = false,
                Array__c = false,
                Object__c = false,
                External_Id__c = true,
                Attachable__c = true,
                Duplicate__c = false,
                Nested__c = false
                )
            );

        wsControlList.add(
            new WebServicesControl__mdt(
                AttributeName__c = 'Items',
                Source__c = 'Web',
                ServiceName__c = 'GenericWS',
                EntityName__c = 'Account',
                RelatedObjectType__c = 'Contact',
                FieldName__c = 'Account.Website',
                Array__c = true,
                Object__c = true,
                Nested__c = true,
                Required__c = false,
                Nullable__c = true,
                External_Id__c = false,
                Duplicate__c = false,
                Attachable__c = false,
                IgnoreErrors__c = ignoringErrors
                )
            );

        WebServicesParser.metadataList = wsControlList;
    }

    @isTest
    static void test_parseObject_Nested_Lvl2()
    {
        createGenericControlList(false, null, true, true);
        String jsonAccounts = '[{"Revenue":"1500000","Employees":"5000","Level":"Warm","MyPhone":"+34999999999","MyURL":"www.google.es","AccountSite":"OneSite", "Sector":{"id":"Agriculture", "name":"Agriculture"}, "Items":[{"EmailAddress":"emailTest@miTest.com"}]}]';

        WebServicesParser.WebParserResult accountResult = WebServicesParser.parseObject(
            Account.sObjectType,
            jsonAccounts,
            'Web',
            'GenericWS'
            );
        System.debug('Error map: ' + accountResult.errorMessagesMap);
        System.assert (accountResult.errorMessagesMap.values().isEmpty() );
        System.debug('Result Record Map: ' + accountResult.recordsMap);
        System.debug('Result LvL 2 Record Map: ' + accountResult.secLvlRecordsMap);
    }

    @isTest
    static void test_parseObject_everyFieldType_Account()
    {
        System.debug('@@test_parseObject_everyFieldType');
        createGenericControlList(false, null, true, true);

        //Se simula la generación de registros
        //FIXME: Level : High porque se han modificado los valores de este campos en cuenta
        String jsonAccounts = '[{"Revenue":"1500000","Employees":"5000","Level":"Warm","MyPhone":"+34999999999","MyURL":"www.google.es","AccountSite":"OneSite", "Sector":{"id":"Agriculture", "name":"Agriculture"}}]';

        WebServicesParser.WebParserResult accountResult = WebServicesParser.parseObject(
            Account.sObjectType,
            jsonAccounts,
            'Web',
            'GenericWS'
            );
        System.debug('Error map: ' + accountResult.errorMessagesMap);
        System.assert (accountResult.errorMessagesMap.values().isEmpty() );
        for (Account acc : (List<Account>) accountResult.recordsMap.values() )
        {
            System.AssertEquals(acc.AnnualRevenue, 1500000);
            System.AssertEquals(acc.NumberOfEmployees, 5000);
            System.AssertEquals(acc.Rating, 'Warm');
            System.AssertEquals(acc.Phone, '+34999999999');
            System.AssertEquals(acc.Website, 'www.google.es');
        }

        System.debug('@@FIN_test_parseObject_everyFieldType');
    }

    @isTest
    static void test_parseObject_everyFieldType_Opportunity()
    {
        createGenericControlList(false, null, true, true);
        String jsonOpportunities = '[{"Private":"true","WhenIsClosed":"2017-08-20","Account":"001D00000xxxxxx","Perc":"11"}]';

        WebServicesParser.WebParserResult opportunityResult = WebServicesParser.parseObject(
            Opportunity.sObjectType,
            jsonOpportunities,
            'Web',
            'GenericWS'
            );
        System.assert (opportunityResult.errorMessagesMap.values().isEmpty() );
        for (
            Opportunity opp : (List<Opportunity>) opportunityResult.recordsMap.values()
            )
        {
            System.AssertEquals(true, opp.IsPrivate);
            System.AssertEquals(opp.CloseDate, Date.valueOf('2017-08-20') );
            System.AssertEquals(opp.AccountId, '001D00000xxxxxx');
            System.AssertEquals(opp.Probability, 11);
        }
    }

    @isTest
    static void test_parseObject_everyFieldType_Contact()
    {
        createGenericControlList(false, null, true, true);
        String jsonContacts = '[{"EmailAddress":"emailTest@miTest.com"}]';

        WebServicesParser.WebParserResult contactResult = WebServicesParser.parseObject(
            Contact.sObjectType,
            jsonContacts,
            'Web',
            'GenericWS'
            );
        System.assert (contactResult.errorMessagesMap.values().isEmpty() );
        for (Contact cont : (List<Contact>) contactResult.recordsMap.values() )
        {
            System.AssertEquals(cont.Email, 'emailTest@miTest.com');
        }
    }

    @isTest
    static void test_parseObject_everyFieldType_EmailResult()
    {
        createGenericControlList(false, null, true, true);
        String jsonEmailMessages = '[{"Fecha":"2017-08-20 15:24:17"}]';
        WebServicesParser.WebParserResult emailsResult = WebServicesParser.parseObject(
            EmailMessage.sObjectType,
            jsonEmailMessages,
            'Web',
            'GenericWS'
            );
        System.assert (emailsResult.errorMessagesMap.values().isEmpty() );
        for (
            EmailMessage ema : (List<EmailMessage>) emailsResult.recordsMap.values()
            )
        {
            System.Assert(ema.MessageDate != null);
            //System.AssertEquals(email.MessageDate, '2017-08-20 15:24:17');
        }
    }

    @isTest
    static void test_parseObject_specificPicklistValue_Valid()
    {
        System.debug('@@test_parseObject_specificPicklistValue_Valid');
        createGenericControlList(false, 'Warm;Agriculture', true, true);

        //Se simula la generación de registros
        String jsonAccounts = '[{"Revenue":"1500000","Employees":"5000","Level":"Warm","MyPhone":"+34999999999","MyURL":"www.google.es","AccountSite":"OneSite", "Sector":{"id":"Agriculture", "name":"Agriculture"}}]';

        WebServicesParser.WebParserResult accountResult = WebServicesParser.parseObject(
            Account.sObjectType,
            jsonAccounts,
            'Web',
            'GenericWS'
            );
        System.debug('Error map: ' + accountResult.errorMessagesMap.values() );
        System.assert (accountResult.errorMessagesMap.values().isEmpty() );
        for (Account acc : (List<Account>) accountResult.recordsMap.values() )
        {
            System.AssertEquals(acc.AnnualRevenue, 1500000);
            System.AssertEquals(acc.NumberOfEmployees, 5000);
            System.AssertEquals(acc.Rating, 'Warm');
            System.AssertEquals(acc.Phone, '+34999999999');
            System.AssertEquals(acc.Website, 'www.google.es');
        }

        System.debug('@@FIN_test_parseObject_specificPicklistValue_Valid');
    }

    @isTest
    static void test_parseObject_specificPicklistValue_Invalid()
    {
        System.debug('@@test_parseObject_specificPicklistValue_Invalid');
        createGenericControlList(false, null, true, true);

        //Se simula la generación de registros
        String jsonAccounts = '[{"Revenue":"1500000","Employees":"5000","Level":"Platinum","MyPhone":"+34999999999","MyURL":"www.google.es", "Sector":{"id":"Financiero", "name":"Financiero"}}]';

        WebServicesParser.WebParserResult accountResult = WebServicesParser.parseObject(
            Account.sObjectType,
            jsonAccounts,
            'Web',
            'GenericWS'
            );
        System.assert (!accountResult.errorMessagesMap.values().isEmpty() );
        List<String> errors = accountResult.errorMessagesMap.values();
        for (String errorMsg : errors)
        {
            System.assert (
                errorMsg.contains('Level: ' + Label.ValorListaNoValido + ': Platinum')
                );
        }
        System.assert (
            accountResult.recordsMap.values() == null ||
            accountResult.recordsMap.values().isEmpty()
            );

        System.debug('@@FIN_test_parseObject_specificPicklistValue_Invalid');
    }

    @isTest
    static void test_parseObject_emptyParameters()
    {
        System.debug('@@test_parseObject_emptyParameters');
        createGenericControlList(false, 'Warm', true, true);

        WebServicesParser.WebParserResult accountResult = WebServicesParser.parseObject(
            null,
            null,
            null,
            null
            );
        System.assert (!accountResult.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : accountResult.errorMessagesMap.values() )
        {
            //System.assert(errorMsg.contains(Label.ParametrosVacios));
        }
        System.debug('@@FIN_test_parseObject_emptyParameters');
    }

    @isTest
    static void test_parseObject_invalidJSON()
    {
        System.debug('@@test_parseObject_invalidJSON');
        createGenericControlList(false, 'Warm', true, true);

        String anyJSON = '';
        WebServicesParser.WebParserResult accountResult = WebServicesParser.parseObject(
            Account.sObjectType,
            anyJSON,
            'Web',
            'GenericWS'
            );
        System.assert (!accountResult.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : accountResult.errorMessagesMap.values() )
        {
            //System.assert(errorMsg.contains(Label.ObjetoJsonVacio));
        }

        String invalidJSON = '[{"asdsa""dasd"';
        WebServicesParser.WebParserResult accountResult2 = WebServicesParser.parseObject(
            Account.sObjectType,
            invalidJSON,
            'Web',
            'GenericWS'
            );
        System.assert (!accountResult2.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : accountResult2.errorMessagesMap.values() )
        {
            System.assert (errorMsg.contains(Label.JsonIncorrecto) );
        }

        String emptyAttributeNameJSON = '[{"":"anyValue"}]';
        WebServicesParser.WebParserResult accountResult3 = WebServicesParser.parseObject(
            Account.sObjectType,
            emptyAttributeNameJSON,
            'Web',
            'GenericWS'
            );
        System.assert (!accountResult3.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : accountResult3.errorMessagesMap.values() )
        {
            System.assert (errorMsg.contains(Label.NombreAtributoVacio) );
        }

        /*String duplicateAttributeNameJSON = '[{"Level":"Cold","Level":"Warm"}]';
           WebServicesParser.WebParserResult accountResult4 = WebServicesParser.parseObject(Account.sObjectType, duplicateAttributeNameJSON, 'Web', 'GenericWS');
           System.assert(!accountResult4.errorMessagesMap.values().isEmpty());
           for(String errorMsg : accountResult4.errorMessagesMap.values())
           {
           System.debug('Error Message: ' + errorMsg);
           System.assert(errorMsg.contains(Label.AtributoDuplicado + ': Level'), 'Error Message: ' + errorMsg);
           }*/

        System.debug('@@FIN_test_parseObject_invalidJSON');
    }

    @isTest
    static void test_parseObject_checkFormatErrors()
    {
        System.debug('@@test_parseObject_checkFormatErrors');
        createGenericControlList(false, 'Warm', true, true);

        //Se simula la generación de registros
        String jsonAccounts = '[{"Revenue":"15000.50","Employees":"5000.5","Level":"Hot","MyPhone":"+349a9999999","MyURL":"www.google"}]';
        String jsonAccounts2 = '[{"Revenue":"15ab0.50","Employees":"11123456789874511245","Level":"Hot","MyPhone":"+349a9999999","MyURL":"www.google"}]';
        String jsonOpportunities = '[{"Private":"otro","WhenIsClosed":"2017-08-55","Account":"001D","Perc":"11.1"}]';
        String jsonContacts = '[{"EmailAddress":"emailTest@miTest"}]';

        WebServicesParser.WebParserResult accountResult = WebServicesParser.parseObject(
            Account.sObjectType,
            jsonAccounts,
            'Web',
            'GenericWS'
            );
        System.debug('### ErroreMessagesMap: ' + accountResult.errorMessagesMap);
        System.assert (!accountResult.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : accountResult.errorMessagesMap.values() )
        {
            System.assert (
                errorMsg.contains('Revenue: ' + Label.EscalaNumeroNoValida) ||
                errorMsg.contains('Employees: ' + Label.EnteroNoValido) ||
                errorMsg.contains('Level: ' + Label.ValorListaNoValido + ': Hot') ||
                errorMsg.contains('MyPhone: ' + Label.TelefonoNoValido) ||
                errorMsg.contains('MyURL: ' + Label.URLNoValida)
                );
        }
        System.assert (
            accountResult.recordsMap.values() == null ||
            accountResult.recordsMap.values().isEmpty()
            );

        WebServicesParser.WebParserResult accountResult2 = WebServicesParser.parseObject(
            Account.sObjectType,
            jsonAccounts2,
            'Web',
            'GenericWS'
            );
        System.assert (!accountResult2.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : accountResult2.errorMessagesMap.values() )
        {
            System.assert (
                errorMsg.contains('Revenue: ' + Label.NumeroNoValido) ||
                errorMsg.contains('Employees: ' + Label.PrecisionNumeroNoValida) ||
                errorMsg.contains('Level: ' + Label.ValorListaNoValido + ': Hot') ||
                errorMsg.contains('MyPhone: ' + Label.TelefonoNoValido) ||
                errorMsg.contains('MyURL: ' + Label.URLNoValida) ||
                errorMsg.contains('Site: ' + Label.LongitudTextoNoValida)
                );
        }
        System.assert (
            accountResult.recordsMap.values() == null ||
            accountResult.recordsMap.values().isEmpty()
            );

        WebServicesParser.WebParserResult opportunityResult = WebServicesParser.parseObject(
            Opportunity.sObjectType,
            jsonOpportunities,
            'Web',
            'GenericWS'
            );
        System.assert (!opportunityResult.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : opportunityResult.errorMessagesMap.values() )
        {
            System.Debug('errorMsg: ' + errorMsg);
            System.assert (
                errorMsg.contains('Private: ' + Label.BooleanoNoValido) ||
                errorMsg.contains('WhenIsClosed: ' + Label.FechaNovalida) ||
                errorMsg.contains('Account: ' + Label.IdNoValido) ||
                errorMsg.contains('Account: ' + Label.EscalaNumeroNoValida) ||
                errorMsg.contains('Perc: ' + Label.EscalaNumeroNoValida) ||
                errorMsg.contains('Perc: ' + Label.PrecisionDobleNoValida)
                );
        }
        System.assert (
            opportunityResult.recordsMap.values() == null ||
            opportunityResult.recordsMap.values().isEmpty()
            );

        WebServicesParser.WebParserResult contactResult = WebServicesParser.parseObject(
            Contact.sObjectType,
            jsonContacts,
            'Web',
            'GenericWS'
            );
        System.assert (!contactResult.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : contactResult.errorMessagesMap.values() )
        {
            System.assert (errorMsg.contains('EmailAddress: ' + Label.EmailNoValido) );
        }
        System.assert (
            contactResult.recordsMap.values() == null ||
            contactResult.recordsMap.values().isEmpty()
            );
        System.debug('@@FIN_test_parseObject_checkFormatErrors');
    }

    @isTest
    static void test_parseObject_checkFormatIgnoringErrors()
    {
        System.debug('@@test_parseObject_checkFormatIgnoringErrors');
        createGenericControlList(true, null, true, true);

        //Se simula la generación de registros
        String jsonAccounts = '[{"Revenue":"15000.50","Employees":"5000.5","Level":"Hot","MyPhone":"+349a9999999","MyURL":"www.google"}]';
        String jsonOpportunities = '[{"Private":"otro","WhenIsClosed":"2017-08-55","Account":"001D","Perc":"11.1"}]';
        String jsonContacts = '[{"EmailAddress":"emailTest@miTest"}]';

        WebServicesParser.WebParserResult accountResult = WebServicesParser.parseObject(
            Account.sObjectType,
            jsonAccounts,
            'Web',
            'GenericWS'
            );
        System.assert (!accountResult.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : accountResult.errorMessagesMap.values() )
        {
            System.assert (
                errorMsg.contains('Revenue: ' + Label.EscalaNumeroNoValida)
                );
        }
        System.assert (
            accountResult.recordsMap.values() == null ||
            accountResult.recordsMap.values().isEmpty()
            );

        WebServicesParser.WebParserResult opportunityResult = WebServicesParser.parseObject(
            Opportunity.sObjectType,
            jsonOpportunities,
            'Web',
            'GenericWS'
            );
        System.assert (!opportunityResult.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : opportunityResult.errorMessagesMap.values() )
        {
            System.assert (errorMsg.contains('Private: ' + Label.BooleanoNoValido) );
        }
        System.assert (
            opportunityResult.recordsMap.values() == null ||
            opportunityResult.recordsMap.values().isEmpty()
            );

        WebServicesParser.WebParserResult contactResult = WebServicesParser.parseObject(
            Contact.sObjectType,
            jsonContacts,
            'Web',
            'GenericWS'
            );
        System.assert (!contactResult.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : contactResult.errorMessagesMap.values() )
        {
            System.assert (errorMsg.contains('EmailAddress: ' + Label.EmailNoValido) );
        }
        System.assert (
            contactResult.recordsMap.values() == null ||
            contactResult.recordsMap.values().isEmpty()
            );
        System.debug('@@FIN_test_parseObject_checkFormatIgnoringErrors');
    }

    @isTest
    static void test_parseObject_checkNullables()
    {
        System.debug('@@test_parseObject_checkNullables');
        createGenericControlList(false, null, true, false);

        //Se simula la generación de registros
        String jsonAccounts = '[{"Revenue":"","Employees":"","Level":"","MyPhone":"","MyURL":""}]';
        String jsonOpportunities = '[{"Private":"","WhenIsClosed":"","Account":"","Perc":""}]';
        String jsonContacts = '[{"EmailAddress":""}]';

        WebServicesParser.WebParserResult accountResult = WebServicesParser.parseObject(
            Account.sObjectType,
            jsonAccounts,
            'Web',
            'GenericWS'
            );
        System.assert (accountResult.errorMessagesMap.values().isEmpty() );
        System.assert (accountResult.recordsMap.values().size() == 1);

        WebServicesParser.WebParserResult opportunityResult = WebServicesParser.parseObject(
            Opportunity.sObjectType,
            jsonOpportunities,
            'Web',
            'GenericWS'
            );
        System.assert (opportunityResult.errorMessagesMap.values().isEmpty() );
        System.assert (opportunityResult.recordsMap.values().size() == 1);

        WebServicesParser.WebParserResult contactResult = WebServicesParser.parseObject(
            Contact.sObjectType,
            jsonContacts,
            'Web',
            'GenericWS'
            );
        System.assert (contactResult.errorMessagesMap.values().isEmpty() );
        System.assert (contactResult.recordsMap.values().size() == 1);
        System.debug('@@FIN_test_parseObject_checkNullables');
    }

    @isTest
    static void test_parseObject_checkNotNullables()
    {
        System.debug('@@test_parseObject_checkNotNullables');
        createGenericControlList(false, null, false, true);

        //Se simula la generación de registros
        String jsonAccounts = '[{"Revenue":"","Employees":"","Level":"","MyPhone":"","MyURL":""}]';
        String jsonOpportunities = '[{"Private":"","WhenIsClosed":"","Account":"","Perc":""}]';
        String jsonContacts = '[{"EmailAddress":""}]';

        WebServicesParser.WebParserResult accountResult = WebServicesParser.parseObject(
            Account.sObjectType,
            jsonAccounts,
            'Web',
            'GenericWS'
            );
        System.assert (!accountResult.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : accountResult.errorMessagesMap.values() )
        {
            System.assert (
                errorMsg.contains('Revenue: ' + Label.AtributoNoAnulable) ||
                errorMsg.contains('Employees: ' + Label.AtributoNoAnulable) ||
                errorMsg.contains('Level: ' + Label.AtributoNoAnulable) ||
                errorMsg.contains('MyPhone: ' + Label.AtributoNoAnulable) ||
                errorMsg.contains('MyURL: ' + Label.AtributoNoAnulable)
                );
        }
        System.assert (
            accountResult.recordsMap.values() == null ||
            accountResult.recordsMap.values().isEmpty()
            );

        WebServicesParser.WebParserResult opportunityResult = WebServicesParser.parseObject(
            Opportunity.sObjectType,
            jsonOpportunities,
            'Web',
            'GenericWS'
            );
        System.assert (!opportunityResult.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : opportunityResult.errorMessagesMap.values() )
        {
            System.assert (
                errorMsg.contains('Revenue: ' + Label.AtributoNoAnulable) ||
                errorMsg.contains('WhenIsClosed: ' + Label.AtributoNoAnulable) ||
                errorMsg.contains('Account: ' + Label.AtributoNoAnulable) ||
                errorMsg.contains('Perc: ' + Label.AtributoNoAnulable)
                );
        }
        System.assert (
            opportunityResult.recordsMap.values() == null ||
            opportunityResult.recordsMap.values().isEmpty()
            );

        WebServicesParser.WebParserResult contactResult = WebServicesParser.parseObject(
            Contact.sObjectType,
            jsonContacts,
            'Web',
            'GenericWS'
            );
        System.assert (!contactResult.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : contactResult.errorMessagesMap.values() )
        {
            System.assert (
                errorMsg.contains('EmailAddress: ' + Label.AtributoNoAnulable)
                );
        }
        System.assert (
            contactResult.recordsMap.values() == null ||
            contactResult.recordsMap.values().isEmpty()
            );
        System.debug('@@FIN_test_parseObject_checkNotNullables');
    }

    @isTest
    static void test_parseObject_checkRequired()
    {
        System.debug('@@test_parseObject_checkRequired');
        createGenericControlList(false, null, true, true);

        //Se simula la generación de registros
        String jsonAccounts = '[{"Revenue":"15000.50"}]';
        String jsonOpportunities = '[{"Private":"false"}]';
        String jsonContacts = '[{}]';

        WebServicesParser.WebParserResult accountResult = WebServicesParser.parseObject(
            Account.sObjectType,
            jsonAccounts,
            'Web',
            'GenericWS'
            );
        System.assert (!accountResult.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : accountResult.errorMessagesMap.values() )
        {
            System.assert (
                errorMsg.contains('Revenue: ' + Label.EscalaNumeroNoValida) ||
                errorMsg.contains(Label.AtributoRequerido + ': Employees') ||
                errorMsg.contains(Label.AtributoRequerido + ': Level') ||
                errorMsg.contains(Label.AtributoRequerido + ': MyPhone') ||
                errorMsg.contains(Label.AtributoRequerido + ': MyURL')
                );
        }
        System.assert (
            accountResult.recordsMap.values() == null ||
            accountResult.recordsMap.values().isEmpty()
            );

        WebServicesParser.WebParserResult opportunityResult = WebServicesParser.parseObject(
            Opportunity.sObjectType,
            jsonOpportunities,
            'Web',
            'GenericWS'
            );
        System.assert (!opportunityResult.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : opportunityResult.errorMessagesMap.values() )
        {
            System.assert (
                errorMsg.contains('Private: ' + Label.BooleanoNoValido) ||
                errorMsg.contains(Label.AtributoRequerido + ': WhenIsClosed') ||
                errorMsg.contains(Label.AtributoRequerido + ': Account') ||
                errorMsg.contains(Label.AtributoRequerido + ': Perc')
                );
        }
        System.assert (
            opportunityResult.recordsMap.values() == null ||
            opportunityResult.recordsMap.values().isEmpty()
            );

        WebServicesParser.WebParserResult contactResult = WebServicesParser.parseObject(
            Contact.sObjectType,
            jsonContacts,
            'Web',
            'GenericWS'
            );
        System.assert (!contactResult.errorMessagesMap.values().isEmpty() );
        for (String errorMsg : contactResult.errorMessagesMap.values() )
        {
            System.assert (
                errorMsg.contains(Label.AtributoRequerido + ': EmailAddress')
                );
        }
        System.assert (
            contactResult.recordsMap.values() == null ||
            contactResult.recordsMap.values().isEmpty()
            );
        System.debug('@@FIN_test_parseObject_checkRequired');
    }
}