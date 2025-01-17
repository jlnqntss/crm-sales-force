/**
 * @author nbizkarra
 * @date 08/04/2020
 **/
global with sharing class OrderUtil
{
    /**
     * Método que inserta o actualiza  una quote y sus objetos relacionados.
     * @author nbizkarra
     * @date 08/04/2020
     **/
    public static void upsertQuote(Contact contact, Order quote)
    {
        
        String legalEntityName = (quote.LegalEntity__c.equals(Label.GeneralInsurance) ? 'GI' : 'Life');

        quote.RecordTypeId = SystemUtil.getOrderRecordTypeIdByName( Label.Quote + legalEntityName );

        Order quoteSF = ExternalRequestUtil.mapQuotes.get(quote.QuoteEntry__c);
        if( quoteSF != null )
        {
            
            quote.Id = quoteSF.Id;
            
            
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
                
                
                // (
                if ( quote.QbLastPage__c.equalsIgnoreCase(Label.Q_StepLogin_v1) ||
                     quote.QbLastPage__c.equalsIgnoreCase(Label.Q_StepLogin_v2) &&
                     quoteSF.ContactId__r.CustomerNum__c != customerNum
                     )
                {
                    
                    quote = ContactUtil.upsertContact(contact, quote);
                    quote.Id = quoteSF.Id;
                }
            }
        }
        else
        {
            

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
        if ( quote.LegalEntity__c.equals(Label.LifeInsurance) && ExternalRequestUtil.listOrderItems != null)
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
        

        ExternalRequestUtil.quotesToUpdateList.put(quote.QuoteEntry__c, quote);
    }

    /**
     * Método que inserta o actualiza una póliza y sus objetos relacionados.
     * @author nbizkarra
     * @date 08/04/2020
     **/
    public static void upsertPolicy(Order policy)
    {
        
        Order policySF = ExternalRequestUtil.mapPolicies.get(policy.PolicyNum__c);
        String customerNumField = ExternalRequestUtil.AccountFieldCustomerNum;

        

        if (policySF != null) //--------------------------------------------------------------  POLICY EXIST
        {
            
            policy.Id = policySF.Id;

            //ver si ha cambiado la versión de póliza
            if ( !policy.PolicyContractSerial__c.equals(policySF.PolicyContractSerial__c) )
            {
                
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

                if (
                    policy?.adjustmentReason__c.trim().equalsIgnoreCase( Label.P_AdjustmentReason_1.trim() ) ||
                    policy?.adjustmentReason__c.trim().equalsIgnoreCase( Label.P_AdjustmentReason_2.trim() ) ||
                    policy?.adjustmentReason__c.trim().equalsIgnoreCase( Label.P_AdjustmentReason_3.trim() )
                    )
                {
                    
                    OrderItemUtil.deactivateOldProduct(
                        policySF, ExternalRequestUtil.listOrderItems, ExternalRequestUtil.orderItemsToInsert
                        );
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

            Contact contactoPolicy = ExternalRequestUtil.mapContacts.get( policy.CustomerNum__c );

            
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
                    
                    Order quoteSF = ExternalRequestUtil.mapQuotes.get( policy.QuoteEntry__c );

                    if (quoteSF != null)
                    {
                        //Quote existe en salesforce
                        policy.Id = quoteSF.id;
                        policy.QuoteStatus__c = Label.Converted;
                    }

                    if ( ExternalRequestUtil.quotesToUpdateList.containsKey( policy.QuoteEntry__c ) )
                    {
                        //Si quote existe en la lista de actualización, se saca de la lista
                        
                        policy.QuoteStatus__c = Label.Converted;
                        ExternalRequestUtil.quotesToUpdateList.remove(policy.QuoteEntry__c);

                        if ( ExternalRequestUtil.ordersToUpdateWithPartner.containsKey( policy.QuoteEntry__c ) )
                        {
                            
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
                policy.ContactId__r = contactRef;
                String[] adaptCustNum = policy.CustomerNum__c.split('-');
                String customerNumberOnly;
                Account masterRef;

                // nts (agonzalezisasi) - 26/oct/2020 - Include IBA Multi-Partner
                customerNumberOnly = adaptCustNum[adaptCustNum.size() - 1]; // get the last part. example: EMEA-GI-3291 => 3291

                masterRef = new Account();
                masterRef.put(customerNumField, customerNumberOnly);
                
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
     * change aberuete - 19/04/2023 - Refactorizar método
     **/
    public static void summaryTotalPolicies(List<Order> newList)
    {
        Set<Id> idSet = new Set<Id>();
        Set<Id> idSetQuotes = new Set<Id>();

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
            updateSummaryPolicies(idSet);
            
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
     * change aberuete - 19/04/2023 - Refactorizar método
     **/
    public static void updateLastQuoteOnContact(List<Order> newList)
    {
        Map<Id, Order> mapQuotes = new Map<Id, Order>();

        if (newList != null)
        {
            for (Order order : newList)
            {
                //Actualiza solo quotes y excluye las quotes actualizadas en el postprocesamiento
                if ( order.ContactId__c != null && order.PolicyNum__c == null && order.After_Processing_Check__c == true )
                {
                    mapQuotes.put(order.ContactId__c, order);
                }
            }

            if ( !mapQuotes.isEmpty() )
            {
                updateContacts (mapQuotes);
            }
        }
    }

     /**
     * Método que borra los casos asociados a las orders que hay que borrar
     * @author aberuete
     * @date 19/04/2023
     * @param List<Order> quotesToDelete: lista de orders a borrar
     **/
    public static void deleteCasesRelatedWithOrder (List<Order> quotesToDelete)
    {
        List<Case> casesToDelete = new List<Case>();

        for (Order quote : quotesToDelete)
        {
            if ( !quote.Casos__r.isEmpty() )
            {
                for (Case c : quote.Casos__r)
                {
                    casesToDelete.add(c);
                }
            }
            //Si la order está activada no se puede borrar, settear el valor a Sync
            quote.Status = Label.Order_Sync;
        }

        if ( !casesToDelete.isEmpty() )
        {
            delete casesToDelete;
        }
    }

    /**
     * Método que borra las covers y subcovers relacionadas con los order items de las orders a borrar
     * @author aberuete
     * @date 19/04/2023
     * @param List<Order> quotesToDelete: lista de orders a borrar
     **/
    public static void deleteConversAndSubcoversRelatedWithOrdersItem (List<Order> quotesToDelete)
    {
        List<Cover__c> coversToDelete = new List<Cover__c>();
        List<Cover__c> subCoversToDelete = new List<Cover__c>();

        SET<ID> keys = new Set<ID>();
        for (Order quoteToDelete : quotesToDelete)
        {
            //coger los ids de los orderItems
            for (OrderItem orderItemRelatedWithOrder : quoteToDelete.OrderItems)
            {
                keys.add(orderItemRelatedWithOrder.id);
            }
        }
        
        //Coger las covers y subcovers asociadas a los orderItems
        coversToDelete = [
            SELECT id, (SELECT id, CoverId__c FROM Coberturas__r), CoverId__c
            FROM Cover__c
            WHERE PolicyProduct__c IN (SELECT id FROM OrderItem WHERE id = :keys)
        ];
        
        for (Cover__c coverRelatedWithOrderItem : coversToDelete)
        {
            for (Cover__c subCoverRelatedWithOrderItem : coverRelatedWithOrderItem.Coberturas__r)
            {
                subCoversToDelete.add(subCoverRelatedWithOrderItem);
            }
        }
        
        if ( !subCoversToDelete.isEmpty() )
        {
            delete subCoversToDelete;
        }
        
        if ( !coversToDelete.isEmpty() )
        {
            delete coversToDelete;
        }
    }

    /**
     * Método que actualiza el número de pólizas del contacto
     * @author aberuete
     * @date 19/04/2023
     * @param Set<Id> idSet : conjunto de ids de contacto asociadas a la order
     **/
    @testvisible
    private static void updateSummaryPolicies(Set<Id> idSet)
    {
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
    }

    /**
     * Método que actualiza la última quote asociada al contacto
     * @author aberuete
     * @date 19/04/2023
     * @param Map<Id, Order> mapQuotes : Mapa de ids de contacto asociados a orders y la order
     **/
    @testvisible
    private static void updateContacts (Map<Id, Order> mapQuotes)
    {
        List<Contact> contacts = new List<Contact>();
        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();

        contacts = [ SELECT id, LastQuote__c FROM Contact WHERE id = :mapQuotes.keySet()];

        if (contacts != null)
        {
            for (Contact c : contacts)
            {
                Order quote = mapQuotes.get(c.id);

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