/**
 * @author nbizkarra
 * @date 08/04/2020
 **/
global without sharing class OrderUtil
{
    /**
     * Método que inserta o actualiza  una quote y sus objetos relacionados.
     * @author nbizkarra
     * @date 08/04/2020
     **/
    public static void upsertQuote(Contact contact, Order quote)
    {
        System.debug('- - - - - OrderUtil.upsertQuote - - - - -');
        String legalEntityName = (quote.LegalEntity__c.equals(Label.GeneralInsurance) ? 'GI' : 'Life');

        quote.RecordTypeId = SystemUtil.getOrderRecordTypeIdByName( Label.Quote + legalEntityName );
        //contact.CustomerNum__c=ContactUtil.adaptCustomerNum(contact.CustomerNum__c, contact.LegalEntity__c);

        Order quoteSF = ExternalRequestUtil.mapQuotes.get(quote.QuoteEntry__c);
        if( quoteSF != null )
        {
            System.debug('The Quote exists >>> ' + quoteSF.Id);
            quote.Id = quoteSF.Id;
            System.debug('quoteSF.ContactId__r.Status__c >>> ' + quoteSF.ContactId__r.Status__c);
            System.debug('contact.Status__c >>> ' + contact.Status__c);
            // nts (nbizkarra) - 13/ene/2021 - Copiar el consentimiento a nivel de quote
            //If the lead change to a customer, the quote must have the same consent of the original lead (consent is not updated)
            if( !(quoteSF.ContactId__r.Status__c == 'Lead' && contact.Status__c == 'Activo') )
            {

                quote.receiveMarketing__c = contact.receiveMarketing__c;

            }

            if (quote.QbLastPage__c != null)
            {
                if (
                    quote.QbLastPage__c.equalsIgnoreCase(Label.Q_LastStep_v1) ||
                    quote.QbLastPage__c.equalsIgnoreCase(Label.Q_LastStep_v2) ||
                    quote.QbLastPage__c.equalsIgnoreCase(Label.Q_LastStep_v3)
                    )
                {
                    quote.QuoteStatus__c = Label.Converted;
                }
                //en la web en el paso 3 comprobar si se ha logueado con otro Customer Num, en ese caso reasociar la quote al contacto correcto
                // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
                String customerNum = contact.CustomerNum__c; // ContactUtil.adaptCustomerNum( contact.CustomerNum__c, contact.LegalEntity__c );
                // System.Debug('*** customerNum: ' + customerNum);
                // System.Debug('*** existC.CustomerNum: ' + quoteSF.ContactId__r.CustomerNum__c);
                // (
                if ( quote.QbLastPage__c.equalsIgnoreCase(Label.Q_StepLogin_v1) ||
                     quote.QbLastPage__c.equalsIgnoreCase(Label.Q_StepLogin_v2) &&
                     quoteSF.ContactId__r.CustomerNum__c != customerNum
                     )
                {
                    //System.debug('Step3: Reasignar quote');
                    quote = ContactUtil.upsertContact(contact, quote);
                    quote.Id = quoteSF.Id;
                }
            }
        }
        else
        {
            System.debug('The quote does not exist');

            // nts (nbizkarra) - 13/ene/2021 - Copiar el consentimiento a nivel de quote
            quote.receiveMarketing__c = contact.receiveMarketing__c;

            quote = ContactUtil.upsertContact(contact, quote);

            quote.Status = Label.Order_Sync;
            quote.Pricebook2Id = ExternalRequestUtil.Pricebook.Id;
            quote.OwnerId = ExternalRequestUtil.recordOwner.id;

            if ( !String.isBlank(quote.MasterPolicyNum__c) ) //Asociar partner
            {
                AccountUtil.associatePartnerToOrder(
                    quote,
                    ExternalRequestUtil.mapPartners,
                    ExternalRequestUtil.ordersToUpdateWithPartner,
                    ExternalRequestUtil.partnersToUpdateList,
                    ExternalRequestUtil.recordOwner
                    );
            }
        }

        //Descuentos
        if (ExternalRequestUtil.listDiscounts != null)
        {
            for (Discount__c dis : ExternalRequestUtil.listDiscounts)
            {
                // If it is an EMEA record, add the prefix to its Orders ExternalId
                // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
                // if (quote.SourceCountry__c != 'Spain') {
                //   dis.Policy__r.QuoteEntry__c = 'EMEA-' + dis.Policy__r.QuoteEntry__c;
                // }
                ExternalRequestUtil.discountsToInsert.put(dis.DiscountId__c, dis);
            }
        }

        //Si el campo de itemId está vacio (workaround para life, en IBA no se puede crear el ID desde el step 1)
        //Se rellena el itemId con el quoteEntry, assumption: siempre va a haber 1 orderItem, si hay más se lanzará error
        if ( quote.LegalEntity__c.equals(Label.LifeInsurance) )
        {
            if (ExternalRequestUtil.listOrderItems != null)
            {
                if (ExternalRequestUtil.listOrderItems.size() > 1)
                {
                    throw new IntegrationException( Label.LifeObjectIdNull + ' ' + quote.QuoteEntry__c );
                }
                for (OrderItem item : ExternalRequestUtil.listOrderItems)
                {
                    if (item.ItemId__c == null)
                    {
                        item.ItemId__c = quote.QuoteEntry__c;
                    }

                    //Setear la relacion de las covers con orderItem
                    if (ExternalRequestUtil.listCovers != null)
                    {
                        for (Cover__c cover : ExternalRequestUtil.listCovers)
                        {
                            cover.PolicyProduct__r.ItemId__c = item.ItemId__c;
                        }
                    }
                }
            }
        }

        // for (OrderItem item : ExternalRequestUtil.listOrderItems) {
        //   // If it is an EMEA record, add the prefix to its Orders ExternalId
        //   // todo: agonzalezisasi - es necesario?
        //   // if (quote.SourceCountry__c != 'Spain') {
        //   //   item.Order.QuoteEntry__c = 'EMEA-' + item.Order.QuoteEntry__c;
        //   // }
        // }

        // for (Cover__c cover : ExternalRequestUtil.listCovers) {
        //   // If it is an EMEA record, add the prefix to its Items ExternalId
        //   // todo: agonzalezisasi - es necesario?
        //   // if (quote.SourceCountry__c != 'Spain') {
        //   //   cover.PolicyProduct__r.ItemId__c =
        //   //     'EMEA-' + cover.PolicyProduct__r.ItemId__c;
        //   // }
        // }

        if (quote.EffectiveDate == null)
        {
            quote.EffectiveDate = Date.today();
        }

        OrderItemUtil.createOrderItem(
            quote,
            ExternalRequestUtil.listOrderItems,
            ExternalRequestUtil.mapOrderItem,
            ExternalRequestUtil.mapProducts,
            ExternalRequestUtil.productsToInsert,
            ExternalRequestUtil.pricebookEntryToInsert,
            ExternalRequestUtil.Pricebook,
            ExternalRequestUtil.orderItemsToInsert,
            ExternalRequestUtil.listCovers,
            ExternalRequestUtil.subCoversToInsertQuote,
            ExternalRequestUtil.mapCovers,
            ExternalRequestUtil.updateCover,
            ExternalRequestUtil.recordOwner
            );
        System.debug( '***** Put quote with quote Entry: ' + quote.QuoteEntry__c + ' in the updating list.' );

        ExternalRequestUtil.quotesToUpdateList.put(quote.QuoteEntry__c, quote);
    }

    /**
     * Método que inserta o actualiza una póliza y sus objetos relacionados.
     * @author nbizkarra
     * @date 08/04/2020
     **/
    public static void upsertPolicy(Order policy)
    {
        System.debug('- - - - - OrderUtil.upsertPolicy - - - - -');
        Order policySF = ExternalRequestUtil.mapPolicies.get(policy.PolicyNum__c);
        String customerNumField = ExternalRequestUtil.AccountFieldCustomerNum;

        //System.debug('policy.PolicyNum__c >>> ' + policy.PolicyNum__c);

        if (policySF != null) //--------------------------------------------------------------  POLICY EXIST
        {
            System.debug('The policy exists');
            policy.Id = policySF.Id;

            //ver si ha cambiado la versión de póliza
            if ( !policy.PolicyContractSerial__c.equals(policySF.PolicyContractSerial__c) )
            {
                //System.debug('>>> PolicyContractSerial__c ha cambiado: ANTES ' + policySF.PolicyContractSerial__c + ' DESPUES ' + policy.PolicyContractSerial__c);
                PolicyVersion__c pversion = new PolicyVersion__c(
                    Name = policy.PolicyContractSerial__c,
                    StartDate__c = policy.PolicyContractStartDate__c,
                    BusinessEvent__c = policy.BusinessEvent__c,
                    UpdateReason__c = policy.UpdateReason__c,
                    adjustmentReason__c = policy.AdjustmentReason__c
                    );

                //insertar endDate de la anterior versión de póliza
                if ( !policySF.PolicyVersions__r.isEmpty() )
                {
                    PolicyVersion__c pversionUpdate = new PolicyVersion__c(
                        Id = policySF.PolicyVersions__r[0].Id,
                        EndDate__c = policy.PolicyContractStartDate__c
                        );
                    ExternalRequestUtil.policyVersionsToUpdateList.put( pversionUpdate.Name, pversionUpdate );
                }

                pversion.OrderId__c = policy.id;
                ExternalRequestUtil.policyVersionsToUpdateList.put( pversion.Name, pversion );

                if ( !String.isBlank(policy.adjustmentReason__c) )
                {
                    if (
                        policy.adjustmentReason__c.trim().equalsIgnoreCase( Label.P_AdjustmentReason_1.trim() ) ||
                        policy.adjustmentReason__c.trim().equalsIgnoreCase( Label.P_AdjustmentReason_2.trim() ) ||
                        policy.adjustmentReason__c.trim().equalsIgnoreCase( Label.P_AdjustmentReason_3.trim() )
                        )
                    {
                        //System.debug('>>> Cambio de producto');
                        OrderItemUtil.deactivateOldProduct(
                            policySF, ExternalRequestUtil.listOrderItems, ExternalRequestUtil.orderItemsToInsert
                            );
                    }
                }
            }

            //Descuentos
            if (ExternalRequestUtil.listDiscounts != null)
            {
                for (Discount__c dis : ExternalRequestUtil.listDiscounts)
                {
                    ExternalRequestUtil.discountsToInsert.put(dis.DiscountId__c, dis);
                }
            }

            OrderItemUtil.createOrderItem(
                policy,
                ExternalRequestUtil.listOrderItems,
                ExternalRequestUtil.mapOrderItem,
                ExternalRequestUtil.mapProducts,
                ExternalRequestUtil.productsToInsert,
                ExternalRequestUtil.pricebookEntryToInsert,
                ExternalRequestUtil.Pricebook,
                ExternalRequestUtil.orderItemsToInsert,
                ExternalRequestUtil.listCovers,
                ExternalRequestUtil.subCoversToInsertQuote,
                ExternalRequestUtil.mapCovers,
                ExternalRequestUtil.updateCover,
                ExternalRequestUtil.recordOwner
                );

            ExternalRequestUtil.policiesToUpdateList.put(policy.PolicyNum__c, policy);
        }
        else //--------------------------------------------------------------  POLICY DOESNT EXIST
        {
            System.debug('The Policy does not exist');
            String legalEntityName;
            if ( policy.LegalEntity__c.equals(Label.GeneralInsurance) )
            {
                legalEntityName = 'GI';
            }
            else
            {
                legalEntityName = 'Life';
            }
            // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
            // if (policy.SourceCountry__c == 'Spain') {
            //   policy.CustomerNum__c = ContactUtil.adaptCustomerNum(
            //     policy.CustomerNum__c,
            //     policy.LegalEntity__c
            //   );
            // }
            System.debug('policy.CustomerNum__c >>> ' + policy.CustomerNum__c);

            Contact contactoPolicy = ExternalRequestUtil.mapContacts.get( policy.CustomerNum__c );

            //System.debug('contactoPolicy: ' +contactoPolicy);
            if ( contactoPolicy != null || ExternalRequestUtil.contactsToUpdate.containsKey(policy.CustomerNum__c) )
            {
                //Contacto existe
                //if contact is lead, change to customer
                if ( ExternalRequestUtil.contactsToUpdate.containsKey( policy.CustomerNum__c ) )
                {
                    Contact con = ExternalRequestUtil.contactsToUpdate.get( policy.CustomerNum__c );

                    if (con != null)
                    {
                        if (con.Status__c == Label.Lead)
                        {
                            con.Status__c = Label.Customer;
                            con.RecordTypeId = SystemUtil.getContactRecordTypeIdByName( 'Customer' + legalEntityName );
                            ExternalRequestUtil.contactsToUpdate.put(con.CustomerNum__c, con);
                        }
                        //actualizar fecha última poliza contratada en el contacto
                        if (policy.EffectiveDate != null)
                        {
                            con.LastPolicyDate__c = policy.EffectiveDate;
                        }
                    }
                }
                else
                {
                    if (contactoPolicy.Status__c == Label.Lead)
                    {
                        contactoPolicy.Status__c = Label.Customer;
                        contactoPolicy.RecordTypeId = SystemUtil.getContactRecordTypeIdByName( 'Customer' + legalEntityName );
                        ExternalRequestUtil.contactsToUpdate.put( contactoPolicy.CustomerNum__c, contactoPolicy );
                    }
                    //actualizar fecha última poliza contratada en el contacto
                    if (policy.EffectiveDate != null)
                    {
                        contactoPolicy.LastPolicyDate__c = policy.EffectiveDate;
                    }
                    if ( !ExternalRequestUtil.contactPolicyDateUpdate.containsKey( contactoPolicy.CustomerNum__c ) )
                    {
                        ExternalRequestUtil.contactPolicyDateUpdate.put( contactoPolicy.CustomerNum__c, contactoPolicy );
                    }
                }

                //Buscar si existe quote
                if ( !String.isBlank(policy.QuoteEntry__c) )
                {
                    //System.debug('Quote existe');
                    Order quoteSF = ExternalRequestUtil.mapQuotes.get( policy.QuoteEntry__c );

                    if (quoteSF != null)
                    {
                        //Quote existe en salesforce
                        policy.Id = quoteSF.id;
                        policy.QuoteStatus__c = Label.Converted;

                        /*if(quoteSF.Descuentos__r!=null)
                                    {
                                        for(Discount__c dis: quoteSF.Descuentos__r)
                                        {
                                            ExternalRequestUtil.discountsToDelete.put(dis.DiscountId__c, dis);
                                        }
                                    } */
                    }

                    if ( ExternalRequestUtil.quotesToUpdateList.containsKey( policy.QuoteEntry__c ) )
                    {
                        //Si quote existe en la lista de actualización, se saca de la lista
                        //System.debug('Quote existe en la lista de actualización');
                        policy.QuoteStatus__c = Label.Converted;
                        ExternalRequestUtil.quotesToUpdateList.remove(policy.QuoteEntry__c);

                        if ( ExternalRequestUtil.ordersToUpdateWithPartner.containsKey( policy.QuoteEntry__c ) )
                        {
                            //System.debug('Quote borrado de la lista de insercion');
                            ExternalRequestUtil.ordersToUpdateWithPartner.remove( policy.QuoteEntry__c );
                        }

                        //Eliminar orderitems relacionados a quoteEntry
                        if (ExternalRequestUtil.listOrderItems != null)
                        {
                            for (OrderItem item : ExternalRequestUtil.listOrderItems)
                            {
                                if ( ExternalRequestUtil.orderItemsToInsert.containsKey( item.ItemId__c ) )
                                {
                                    ExternalRequestUtil.orderItemsToInsert.remove(item.ItemId__c);
                                }

                                //Eliminar covers relacionadas
                                for (Cover__c cover : ExternalRequestUtil.listCovers)
                                {
                                    if ( ExternalRequestUtil.updateCover.containsKey( item.ItemId__c + '-' + cover.Name ) )
                                    {
                                        ExternalRequestUtil.updateCover.remove( item.ItemId__c + '-' + cover.Name );
                                    }
                                }
                            }
                        }
                        //Si es de vida y el quote ha llegado sin itemID eliminar los items y covers con id del quoteEntry (workaround life)
                        if ( policy.LegalEntity__c.equals(Label.LifeInsurance) )
                        {
                            if ( ExternalRequestUtil.orderItemsToInsert.containsKey( policy.QuoteEntry__c ) )
                            {
                                ExternalRequestUtil.orderItemsToInsert.remove( policy.QuoteEntry__c );
                            }

                            //Eliminar covers relacionadas
                            for (Cover__c cover : ExternalRequestUtil.listCovers)
                            {
                                if ( ExternalRequestUtil.updateCover.containsKey( policy.QuoteEntry__c + '-' + cover.Name ) )
                                {
                                    ExternalRequestUtil.updateCover.remove( policy.QuoteEntry__c + '-' + cover.Name );
                                }
                            }
                        }

                        //Eliminar discounts relacionados al quoteEntry (su discount id es diferente a la poliza)
                        for ( Discount__c dis : ExternalRequestUtil.discountsToInsert.values() )
                        {
                            if ( dis.Policy__r.QuoteEntry__c != null && dis.Policy__r.QuoteEntry__c.equals(policy.QuoteEntry__c) )
                            {
                                ExternalRequestUtil.discountsToInsert.remove( dis.DiscountId__c  );
                            }
                        }
                    }

                    // policy.QuoteEntry__c='';
                }

                // nts (nbizkarra) - 19/11/2020 - Include search quote with same product
                if ( ExternalRequestUtil.mapQuoteSameProd.containsKey( policy.CustomerNum__c ) )
                {
                    List<Order> quotesSameProd = ExternalRequestUtil.mapQuoteSameProd.get(  policy.CustomerNum__c );

                    if (quotesSameProd != null)
                    {

                        for( Order quote: quotesSameProd)
                        {
                            //Mark other quotes with same product as "Converted"
                            if( quote.QuoteEntry__c != policy.QuoteEntry__c)
                            {

                                quote.QuoteStatus__c = Label.Converted;
                                ExternalRequestUtil.quotesToUpdateList.put(quote.QuoteEntry__c, quote);

                            }

                        }

                    }

                }

                policy.OwnerId = ExternalRequestUtil.recordOwner.id;
                policy.QuoteStatus__c = Label.Converted;
                Contact contactRef = new Contact( CustomerNum__c = policy.CustomerNum__c );
                //policy.ContactId__c=contactoPolicy.Id;
                policy.ContactId__r = contactRef;
                String[] adaptCustNum = policy.CustomerNum__c.split('-');
                String customerNumberOnly;
                Account masterRef;

                // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
                // if( policy.SourceCountry__c != 'Spain') {
                //   customerNumberOnly = adaptCustNum[2];
                //   masterRef = new Account(CustomerNum_EMEA__c = customerNumberOnly);
                // } else {
                //   customerNumberOnly = adaptCustNum[1];
                //   masterRef = new Account(CustomerNum__c = customerNumberOnly);
                // }
                customerNumberOnly = adaptCustNum[adaptCustNum.size() - 1]; // get the last part. example: EMEA-GI-3291 => 3291

                masterRef = new Account();
                masterRef.put(customerNumField, customerNumberOnly);

                //policy.AccountId=contactoPolicy.AccountId;
                policy.Account = masterRef;
                policy.Status = Label.Order_Sync;
                policy.Pricebook2Id = ExternalRequestUtil.Pricebook.Id;

                policy.RecordTypeId = SystemUtil.getOrderRecordTypeIdByName( 'Policy' + legalEntityName );

                //Crear versión de póliza
                if ( !String.isBlank(policy.PolicyContractSerial__c) )
                {
                    PolicyVersion__c pversion = new PolicyVersion__c(
                        Name = policy.PolicyContractSerial__c,
                        StartDate__c = policy.PolicyContractStartDate__c,
                        BusinessEvent__c = policy.BusinessEvent__c,
                        UpdateReason__c = policy.UpdateReason__c
                        );

                    Order policyRef = new Order(PolicyNum__c = policy.PolicyNum__c);
                    pversion.OrderId__r = policyRef;

                    if ( !ExternalRequestUtil.policyVersionsToUpdateList.containsKey( pversion.Name ) )
                    {
                        ExternalRequestUtil.policyVersionsToUpdateList.put( pversion.Name, pversion );
                    }
                }

                if ( !String.isBlank(policy.MasterPolicyNum__c) )
                {
                    //Asociar partner
                    AccountUtil.associatePartnerToOrder(
                        policy,
                        ExternalRequestUtil.mapPartners,
                        ExternalRequestUtil.policiesToUpdateWithPartner,
                        ExternalRequestUtil.partnersToUpdateList,
                        ExternalRequestUtil.recordOwner
                        );
                }

                //detectar póliza offline
                List<String> caseWorkers = ExternalRequestUtil.adminSetup.IBACaseworker__c.split( ',' );

                if ( !String.isBlank(policy.Caseworker__c) )
                {
                    for (String worker : caseWorkers)
                    {
                        if ( !policy.Caseworker__c.equalsIgnoreCase(worker) )
                        {
                            policy.Offline__c = true;
                        }
                    }
                }

                // nts (nbizkarra) - 07/ene/2021 - Modelo de atribución
                // Se relaciona la póliza con el agente si el cliente tiene tareas de llamada registradas
                if ( !contactoPolicy.Tasks.isEmpty() )
                {
                    policy.RelatedAgent__c = contactoPolicy.Tasks.get(0).OwnerId;
                    //Relacionar la tarea a la póliza:
                    //task.WhatId= policy.PolicyNum__c; No es posible relacionarlo con el id externo, se hará después de instertar la poliza
                    //upsert with relationships on polymorphic keys (whatId is polymorhpic) is not yet supported.
                    ExternalRequestUtil.tasksToUpdate.put( policy.PolicyNum__c, contactoPolicy.Tasks.get(0) );

                }

                //Descuentos
                if (ExternalRequestUtil.listDiscounts != null)
                {
                    for (Discount__c dis : ExternalRequestUtil.listDiscounts)
                    {
                        ExternalRequestUtil.discountsToInsert.put(dis.DiscountId__c, dis);
                    }
                }

                OrderItemUtil.createOrderItem(
                    policy,
                    ExternalRequestUtil.listOrderItems,
                    ExternalRequestUtil.mapOrderItem,
                    ExternalRequestUtil.mapProducts,
                    ExternalRequestUtil.productsToInsert,
                    ExternalRequestUtil.pricebookEntryToInsert,
                    ExternalRequestUtil.Pricebook,
                    ExternalRequestUtil.orderItemsToInsert,
                    ExternalRequestUtil.listCovers,
                    ExternalRequestUtil.subCoversToInsertQuote,
                    ExternalRequestUtil.mapCovers,
                    ExternalRequestUtil.updateCover,
                    ExternalRequestUtil.recordOwner
                    );

                ExternalRequestUtil.ordersToUpdateList.put(policy.PolicyNum__c, policy);
            }
            else
            {
                //System.debug('Contacto no existe');
                throw new IntegrationException(
                          Label.PolicyError + '' + policy.PolicyNum__c + ', ' + Label.CustomerError + ' ' + policy.CustomerNum__c
                          );
            }
        }
    }

    /**
     * Método que setea en el contacto el número total de pólizas activas y el número total the quotes
     * @author nbizkarra
     * @date 08/04/2020
     **/
    public static void SummaryTotalPolicies(List<Order> newList)
    {
        System.debug('- - - - - OrderUtil.SummaryTotalPolicies - - - - -');
        Set<Id> idSet = new Set<Id>();
        Set<Id> idSetQuotes = new Set<Id>();
        Map<String, Contact> contactsToUpdate = new Map<String, Contact>();

        if (newList != null)
        {
            for (Order order : newList)
            {
                if (order.ContactId__c != null)
                {
                    idSet.add(order.ContactId__c);
                    idSetQuotes.add(order.ContactId__c);
                }
            }

            //Summary Polizas
            if ( !idSet.isEmpty() )
            {
                String whereClause = 'PolicyNum__c!=NULL AND PolicyStatus__c=\'' + Label.PolicyStatusActive + '\'';
                // Define the context for the RollupSummariesUtil.summarize() method
                RollupSummariesUtil.Context cont = new RollupSummariesUtil.Context(
                    Contact.SobjectType,
                    Order.SobjectType,
                    Schema.SObjectType.Order.fields.ContactId__c,
                    whereClause
                    );

                // RollupSummaryField for the NumPolicies__c field
                cont.add(
                    new RollupSummariesUtil.RollupSummaryField(
                        Schema.SObjectType.Contact.fields.NumPolicies__c,
                        Schema.SObjectType.Order.fields.Id,
                        RollupSummariesUtil.summaryOperation.Count
                        )
                    );

                // Call summarize method with context and parent records
                Sobject[] responseObject = RollupSummariesUtil.summarize(cont, idSet);

                responseObject = (Contact[]) responseObject;

                if ( responseObject != null && !responseObject.isEmpty() )
                {
                    update responseObject;
                }
            }

            //Summary Quotes
            if ( !idSetQuotes.isEmpty() )
            {
                String whereClause = 'PolicyNum__c=NULL';
                // Define the context for the RollupSummariesUtil.summarize() method
                RollupSummariesUtil.Context cont = new RollupSummariesUtil.Context(
                    Contact.SobjectType,
                    Order.SobjectType,
                    Schema.SObjectType.Order.fields.ContactId__c,
                    whereClause
                    );

                // RollupSummaryField for the NumQuotes__c field
                cont.add(
                    new RollupSummariesUtil.RollupSummaryField(
                        Schema.SObjectType.Contact.fields.NumQuotes__c,
                        Schema.SObjectType.Order.fields.Id,
                        RollupSummariesUtil.summaryOperation.Count
                        )
                    );

                // Call summarize method with context and parent records
                Sobject[] responseObject = RollupSummariesUtil.summarize(
                    cont,
                    idSetQuotes
                    );

                responseObject = (Contact[]) responseObject;

                if ( responseObject != null && !responseObject.isEmpty() )
                {
                    update responseObject;
                }
            }
        }
    }

    /**
     * Método que actualiza en el contacto la última quote actualizada
     * @author nbizkarra
     * @date 30/06/2020
     **/
    public static void updateLastQuoteOnContact(List<Order> newList)
    {
        System.debug('- - - - - OrderUtil.updateLastQuoteOnContact - - - - -');
        Map<Id, Order> MapQuotes = new Map<Id, Order>();
        List<Contact> contacts = new List<Contact>();
        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();

        if (newList != null)
        {
            for (Order order : newList)
            {
                //Actualiza solo quotes y excluye las quotes actualizadas en el postprocesamiento
                if ( order.ContactId__c != null && order.PolicyNum__c == null && order.After_Processing_Check__c == true )
                {
                    MapQuotes.put(order.ContactId__c, order);
                }
            }

            if ( !MapQuotes.isEmpty() )
            {
                contacts = [ SELECT id, LastQuote__c FROM Contact WHERE id = :MapQuotes.keySet() ];

                if (contacts != null)
                {
                    for (Contact c : contacts)
                    {
                        Order quote = MapQuotes.get(c.id);

                        if (quote != null)
                        {
                            c.LastQuote__c = quote.id;
                            contactsToUpdate.put(c.Id, c);
                        }
                    }
                }

                //Update contacts
                if ( contactsToUpdate != null && !contactsToUpdate.isEmpty() )
                {
                    update contactsToUpdate.values();
                }
            }
        }
    }
}