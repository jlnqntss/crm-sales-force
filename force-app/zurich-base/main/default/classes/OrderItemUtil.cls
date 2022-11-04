/**
 * @author nbizkarra
 * @date 08/04/2020
 **/
public class OrderItemUtil
{
    /**
     * Método que inserta o actualiza el producto asegurado y sus objetos relacionados.
     * @author nbizkarra
     * @date 08/04/2020
     **/
    public static void createOrderItem(
        Order order,
        List<Orderitem> listOrderItems,
        Map<String, OrderItem> mapOrderItem,
        Map<String, PricebookEntry> mapProducts,
        Map<String, Product2> productsToInsert,
        Map<String, PricebookEntry> pricebookEntryToInsert,
        Pricebook2 Pricebook,
        Map<String, OrderItem> orederItemsToInsert,
        List<Cover__c> listCovers,
        Map<String, Cover__c> subCoversToInsertQuote,
        Map<String, Cover__c> mapCovers,
        Map<String, Cover__c> updateCover,
        User recordOwner
        )
    {
        
        //crear mapa con covers de cada OrderItem
        Map<String, List<Cover__c> > receivedCovers = new Map<String, List<Cover__c> >();
        if (listCovers != null)
        {
            for (Cover__c cover : listCovers)
            {
                if ( receivedCovers.containsKey(cover.PolicyProduct__r.ItemId__c) )
                {
                    List<Cover__c> existingItemId = receivedCovers.get( cover.PolicyProduct__r.ItemId__c );
                    existingItemId.add(cover);
                    receivedCovers.put(cover.PolicyProduct__r.ItemId__c, existingItemId);
                }
                else
                {
                    receivedCovers.put( cover.PolicyProduct__r.ItemId__c, new List<Cover__c> { cover } );
                }
            }
        }
        
        
        if (listOrderItems != null)
        {
            for (OrderItem item : listOrderItems)
            {
                //get the list of covers for this order item
                List<Cover__c> covers = new List<Cover__c>();
                covers = receivedCovers.get(item.ItemId__c);

                OrderItem orderItemSF = mapOrderItem.get(item.ItemId__c);
                if (orderItemSF != null)
                {
                    
                    item.Id = orderItemSF.Id;

                    // mantener solo el external ID de la poliza
                    if (item.Order.PolicyNum__c != null)
                    {
                        item.Order.QuoteEntry__c = null;
                    }
                }
                else
                {
                    
                    //if order Item doesn't exist, relate product2
                    PricebookEntry productSF;
                    //Search product by product name
                    if (item.itemModel__c != null)
                    {
                        //GI insurance
                        productSF = mapProducts.get(item.itemModel__c);
                    }
                     // nts (nbizkarra) - 27/abr/2021 - Multiproduct
                    else if (item.TransportType__c != null){
                        
                        productSF = mapProducts.get(item.TransportType__c);
                    }
                    else
                    {
                        //life insurance: category: insured person
                        productSF = mapProducts.get(item.Category__c);
                    }

                    if (productSF != null)
                    {
                        
                        item.PricebookEntryId = productSF.Id;
                    }
                    else
                    {
                        
                        createProduct( item, productsToInsert, pricebookEntryToInsert, Pricebook );
                        PricebookEntry pricebookRef;

                        if (item.itemModel__c != null)
                        {
                            //GI insurance
                            pricebookRef = new PricebookEntry( ProductID__c = item.itemModel__c );
                        }
                        // nts (nbizkarra) - 27/abr/2021 - Multiproduct
                        else if (item.TransportType__c != null){
                            
                            pricebookRef = new PricebookEntry( ProductID__c = item.TransportType__c );

                        }
                        else if (item.Category__c != null)
                        {
                            //life
                            pricebookRef = new PricebookEntry( ProductID__c = item.Category__c );
                            item.itemModel__c = item.Category__c;
                        }
                        else
                        {
                            //if mandatory value empty in life
                            pricebookRef = new PricebookEntry( ProductID__c = 'Insured Person' );
                            item.itemModel__c = 'Insured Person';
                        }
                        item.PricebookEntry = pricebookRef;
                    }

                    item.Active__c = true;
                    item.UnitPrice = 0;
                    item.Quantity = 1;
                    item.ServiceDate = order.EffectiveDate + 1;
                }
                CoverUtil.addCovers(
                    item,
                    covers,
                    subCoversToInsertQuote,
                    mapCovers,
                    updateCover,
                    order.LegalEntity__c,
                    recordOwner
                    );
                
                orederItemsToInsert.put(item.ItemId__c, item);
            }
        }
    }

    /**
     * Método que crea un producto nuevo cuando no existe en Salesforce.
     * @author nbizkarra
     * @date 08/04/2020
     **/
    public static void createProduct(
        OrderItem item,
        Map<String, Product2> productsToInsert,
        Map<String, PricebookEntry> pricebookEntryToInsert,
        Pricebook2 Pricebook
        )
    {
        
        String productID;

        if (item.itemModel__c != null)
        {
            productID = item.itemModel__c;
        }
        // nts (nbizkarra) - 27/abr/2021 - Multiproduct
        else if (item.TransportType__c != null){
                        
            productID = item.TransportType__c;
        }
        else if (item.Category__c != null)
        {
            productID = item.Category__c;
        }
        else
        {
            productID = 'Insured Person';
        }

        PricebookEntry pricebookEntry = new PricebookEntry(
            UnitPrice = 0,
            ProductID__c = productID,
            Pricebook2Id = Pricebook.Id,
            IsActive = true
            );
        Product2 prodRef = new Product2(ProductID__c = productID);
        pricebookEntry.Product2 = prodRef;

        if ( !pricebookEntryToInsert.containsKey(pricebookEntry.ProductID__c) )
        {
            pricebookEntryToInsert.put(pricebookEntry.ProductID__c, pricebookEntry);
        }

        Product2 newProduct = new Product2(
            ProductID__c = productID,
            Name = productID,
            Family = item.Category__c,
            Brand__c = item.Brand__c,
            IsActive = true
            );

        if ( !productsToInsert.containsKey(newProduct.ProductID__c) )
        {
            productsToInsert.put(newProduct.ProductID__c, newProduct);
        }
    }

    /**
     * Método que desactiva un producto de la póliza
     * @author nbizkarra
     * @date 08/04/2020
     **/
    public static void deactivateOldProduct(
        Order policy,
        List<Orderitem> listOrderItems,
        Map<String, OrderItem> orederItemsToInsert
        )
    {
        
        Map<String, OrderItem> mapReceivedItems = new Map<String, OrderItem>();

        for (Orderitem ordItem : listOrderItems)
        {
            //mapa con los items recibidos
            // mapReceivedItems.put(renameItemId(policy, ordItem.ItemId__c), ordItem);
            mapReceivedItems.put(ordItem.ItemId__c, ordItem);
        }

        for (OrderItem itemSF : policy.OrderItems)
        {
            OrderItem receivedItem = mapReceivedItems.get(itemSF.ItemId__c);
            if (receivedItem == null)
            {
                //El producto no se ha recibido, marcar active=false
                
                itemSF.Active__c = false;
                orederItemsToInsert.put(itemSF.ItemId__c, itemSF);
            }
        }
    }
}