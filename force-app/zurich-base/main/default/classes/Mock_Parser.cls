/**
 * Global class to specify the response expected from the Parser
 * @Autor: nbizkarra (04/05/2020)
 *
 * @update nts (agonzalezisasi) - 26/oct/2020 - Include Mult-Partner logic
 **/
//@isTest
global class Mock_Parser
{
    public static Boolean isIBA_MultiPart = false;
    public static Boolean isIBA_EMEA = false;

    /**
     * MockParser
     */
    static global Map<String, SObject> MockParser(String Entity)
    {
        Map<String, SObject> recordsMap = new Map<String, SObject>();

        if ( Entity.equals('Claim') )
        {
            Case claim = new Case(
                ClaimNumber__c = '797',
                PolicyNum__c = '8989',
                CustomerNum__c = '3123',
                LegalEntity__c = Label.GeneralInsurance,
                DateReg__c = Date.valueOf('2020-01-02'),
                InsuredObjectId__c = '123456789',
                SourceCountry__c = 'Spain'
                );
            if( isIBA_EMEA )
                claim.SourceCountry__c = 'France';
            if( isIBA_MultiPart )
                claim.Partner__c = 'Orange Seguros';

            //Order policyRef=new Order(PolicyNum__c=claim.PolicyNum__c);
            //claim.Policy__r=policyRef;

            recordsMap.put(claim.ClaimNumber__c, (SObject) claim);
        }
        else if ( Entity.equals('Customer') )
        {
            
            if (ExternalRequestUtil.actualRequest.entity__c == 'QuoteEntry')
            {
                Contact lead = new Contact(
                    Email = 'nora@test.com',
                    MobilePhone = '11111111',
                    Status__c = Label.Lead,
                    Birthdate = Date.valueOf('1990-01-01'),
                    FirstName = 'Nora',
                    LastName = '', // Bizkarra // for coverage
                    CustomerNum__c = '9999',
                    LegalEntity__c = Label.GeneralInsurance,
                    SourceCountry__c = 'Spain'
                    );
                if( isIBA_EMEA )
                    lead.SourceCountry__c = 'France';
                if( isIBA_MultiPart )
                {
                    lead.Partner__c = 'Orange Seguros';
                    lead.Status__c = Label.Customer;
                    lead.MasterPolicyNum__c = '666';
                }
                recordsMap.put(lead.CustomerNum__c, (SObject) lead);
            }
            else
            {
                Contact customer = new Contact(
                    DNI__c = '443485723A',
                    Email = 'edu@test.com',
                    MobilePhone = '456456456',
                    Birthdate = Date.valueOf('1990-01-01'),
                    FirstName = 'Eduardo',
                    LastName = 'Sanchez',
                    CustomerNum__c = '3123',
                    LegalEntity__c = Label.GeneralInsurance,
                    MasterPolicyNum__c = '3344',
                    MasterPolicyDesc__c = 'Nestle',
                    SourceCountry__c = 'Spain'
                    );
                if( isIBA_EMEA )
                    customer.SourceCountry__c = 'France';
                if( isIBA_MultiPart )
                    customer.Partner__c = 'Orange Seguros';

                customer.Status__c = Label.Customer;
                recordsMap.put(customer.CustomerNum__c, (SObject) customer);
            }
        }
        else if ( Entity.equals('Policy') )
        {
            Order policy = new Order(
                EffectiveDate = Date.valueOf('1990-01-02'),
                CustomerNum__c = '3123',
                LegalEntity__c = Label.GeneralInsurance,
                PolicyNum__c = '1111',
                PolicyContractSerial__c = '1111-6',
                PolicyContractStartDate__c = Date.valueOf('2020-05-02'),
                UpdateReason__c = '',
                MasterPolicyNum__c = '789789',
                MasterPolicyDescr__c = 'Rastreator',
                Caseworker__c = 'Klinc_life',
                QuoteEntry__c = '10000',
                SourceCountry__c = 'Spain'
                );
            if( isIBA_EMEA )
                policy.SourceCountry__c = 'France';
            if( isIBA_MultiPart )
                policy.Partner__c = 'Orange Seguros';

            recordsMap.put(policy.PolicyNum__c, (SObject) policy);
        }
        else if ( Entity.equals('QuoteEntry') )
        {
            //Quote from the web
            Order quote = new Order(
                QbLastPage__c = Label.Q_LastStep_v1,
                EffectiveDate = Date.valueOf('1994-01-01'),
                CustomerNum__c = '9999',
                LegalEntity__c = Label.GeneralInsurance,
                QuoteEntry__c = '9090',
                SourceCountry__c = 'Spain'
                );
            if( isIBA_EMEA )
                quote.SourceCountry__c = 'France';
            if( isIBA_MultiPart )
                quote.Partner__c = 'Orange Seguros';

            recordsMap.put(quote.QuoteEntry__c, (SObject) quote);
        }
        return recordsMap;
    }

    /**
     * MockParserSecondLevel
     */
    static global Map<String, List<SObject> > MockParserSecondLevel(
        String Entity
        )
    {
        Map<String, List<SObject> > secLvlRecordsMap = new Map<String, List<SObject> >();
        List<SObject> listaDescuentos = new List<SObject>();
        List<SObject> listaItems = new List<SObject>();

        Discount__c disc = new Discount__c(
            Name = 'Primavera 2020',
            DiscountPct__c = 50,
            DiscountIdNumber__c = 1111
            );
        if( isIBA_MultiPart )
            disc.Partner__c = 'Orange Seguros';

        OrderItem item = new OrderItem(
            itemId__c = '7777',
            ItemAge__c = 2,
            Category__c = 'Smartphone',
            Brand__c = 'Samsung',
            itemModel__c = 'Samsung Galaxy'
            );
        if( isIBA_MultiPart )
            item.Partner__c = 'Orange Seguros';

        OrderItem item2 = new OrderItem(
            itemId__c = '6666',
            ItemAge__c = 2,
            Category__c = 'Smartphone',
            Brand__c = 'Apple',
            itemModel__c = 'IphoneX'
            );
        if( isIBA_MultiPart )
            item2.Partner__c = 'Orange Seguros';

        if ( Entity.equals('Quote') )
        {
            // Order quoteRef = new Order(QuoteEntry__c = '9090', SourceCountry__c = 'Spain');
            // if( isIBA_EMEA ) quoteRef.SourceCountry__c = 'France';
            // if( isIBA_MultiPart ) quoteRef.Partner__c = 'Orange Seguros';

            //Descuento
            disc.Policy__r = new Order(QuoteEntry__c = '9090');
            listaDescuentos.add( (SObject) disc );
            secLvlRecordsMap.put('Discount__c', listaDescuentos);

            //orderItem
            item.Order = new Order(QuoteEntry__c = '9090');
            item2.Order = new Order(QuoteEntry__c = '9090');
            listaItems.add( (SObject) item );
            listaItems.add( (SObject) item2 );
            secLvlRecordsMap.put('OrderItem', listaItems);
        }
        else if ( Entity.equals('Policy') )
        {
            // Order policyRef = new Order(PolicyNum__c = '1111');
            // if( isIBA_EMEA ) policyRef.SourceCountry__c = 'France';
            // if( isIBA_MultiPart ) policyRef.Partner__c = 'Orange Seguros';

            //Descuento
            disc.Policy__r = new Order(PolicyNum__c = '1111');
            listaDescuentos.add( (SObject) disc );
            secLvlRecordsMap.put('Discount__c', listaDescuentos);

            //OrderItem
            item.Order = new Order(PolicyNum__c = '1111');
            item2.Order = new Order(PolicyNum__c = '1111');
            listaItems.add( (SObject) item );
            listaItems.add( (SObject) item2 );
            secLvlRecordsMap.put('OrderItem', listaItems);
        }

        return secLvlRecordsMap;
    }

    /**
     * MockParserThirdLevel
     */
    static global Map<String, List<SObject> > MockParserThirdLevel(String Entity)
    {
        Map<String, List<SObject> > thrLvlRecordsMap = new Map<String, List<SObject> >();
        List<SObject> listaObjetos = new List<SObject>();
        List<SObject> listaObjetos2 = new List<SObject>();

        Cover__c cover = new Cover__c(
            CoverId__c = '1',
            ParentCoverId__c = null,
            Name = 'Robo',
            Description__c = 'Cobertura por robo',
            SumInsured__c = 1000,
            SourceCountry__c = 'Spain'
            );
        if( isIBA_MultiPart )
            cover.Partner__c = 'Orange Seguros';

        Cover__c subcover = new Cover__c(
            CoverId__c = '2',
            ParentCoverId__c = '1',
            Name = 'Sub-Robo',
            Description__c = 'SubCobertura por robo',
            SumInsured__c = 150,
            SourceCountry__c = 'Spain'
            );
        if( isIBA_MultiPart )
            subcover.Partner__c = 'Orange Seguros';

        Cover__c cover2 = new Cover__c(
            CoverId__c = '3',
            ParentCoverId__c = null,
            Name = 'Perdida',
            Description__c = 'Cobertura por perdida',
            SumInsured__c = 1000,
            SourceCountry__c = 'Spain'
            );
        if( isIBA_MultiPart )
            cover2.Partner__c = 'Orange Seguros';

        Cover__c subcover2 = new Cover__c(
            CoverId__c = '4',
            ParentCoverId__c = '3',
            Name = 'Sub-Perdida',
            Description__c = 'SubCobertura por perdida',
            SumInsured__c = 150,
            SourceCountry__c = 'Spain'
            );
        if( isIBA_MultiPart )
            subcover2.Partner__c = 'Orange Seguros';

        // OrderItem itemRef = new OrderItem(itemId__c = '7777');

        cover.PolicyProduct__r =  new OrderItem(itemId__c = '7777');
        subcover.PolicyProduct__r =  new OrderItem(itemId__c = '7777');
        cover2.PolicyProduct__r =  new OrderItem(itemId__c = '7777');
        subcover2.PolicyProduct__r =  new OrderItem(itemId__c = '7777');

        listaObjetos.add( (SObject) cover );
        listaObjetos.add( (SObject) subcover );
        listaObjetos.add( (SObject) cover2 );
        listaObjetos.add( (SObject) subcover2 );
        //el key deberia ser el external id de item
        thrLvlRecordsMap.put('7777', listaObjetos);

        // OrderItem itemRef2 = new OrderItem(itemId__c = '6666');

        Cover__c cover3 = new Cover__c(
            CoverId__c = '1',
            ParentCoverId__c = null,
            Name = 'Robo',
            Description__c = 'Cobertura por robo',
            SumInsured__c = 1000,
            SourceCountry__c = 'Spain'
            );
        if( isIBA_MultiPart )
            cover3.Partner__c = 'Orange Seguros';

        Cover__c subcover3 = new Cover__c(
            CoverId__c = '2',
            ParentCoverId__c = '1',
            Name = 'Sub-Robo',
            Description__c = 'SubCobertura por robo',
            SumInsured__c = 150,
            SourceCountry__c = 'Spain'
            );
        if( isIBA_MultiPart )
            subcover3.Partner__c = 'Orange Seguros';

        cover3.PolicyProduct__r = new OrderItem(itemId__c = '6666');
        subcover3.PolicyProduct__r = new OrderItem(itemId__c = '6666');


        listaObjetos2.add( (SObject) cover3 );
        listaObjetos2.add( (SObject) subcover3 );
        //el key deberia ser el external id de item
        thrLvlRecordsMap.put('6666', listaObjetos2);

        return thrLvlRecordsMap;
    }
}