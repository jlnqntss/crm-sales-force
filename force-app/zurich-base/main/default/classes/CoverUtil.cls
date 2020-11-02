/**
 * @author nbizkarra
 * @date 21/04/2020
 **/
public class CoverUtil
{
    /**
     * Método que inserta o actualiza las coberturas relacionadas a un orderItem
     * @author nbizkarra
     * @date 08/04/2020
     **/
    public static void addCovers(
        OrderItem item,
        List<Cover__c> listCovers,
        Map<String, Cover__c> subCoversToInsertQuote,
        Map<String, Cover__c> mapCovers,
        Map<String, Cover__c> updateCover,
        String LegalEntity,
        User recordOwner
        )
    {
        Map<String, Cover__c> mapNewCovers = new Map<String, Cover__c>();

        System.debug('listCovers >>> ' + listCovers);

        if (listCovers != null)
        {
            for (Cover__c cover : listCovers)
            {
                //mapa con los ids de las coberturas recibidas
                mapNewCovers.put(cover.CoverId__c, cover);
            }

            for (Cover__c cover : listCovers)
            {
                //covers identified in Salesforce as ItemId-CoverName
                Cover__c coverSF = mapCovers.get(item.ItemId__c + '-' + cover.Name);
                if (coverSF != null)
                {
                    //Cover or subcover exists in salesforce
                    cover.id = coverSF.id;
                    cover.CoverId__c = coverSF.CoverId__c;
                    cover.ParentCoverId__c = coverSF.ParentCoverId__c;
                    //the relation is already set, remove the relationship set by parser
                    cover.PolicyProduct__r = null;

                    updateCover.put(cover.CoverId__c, cover);
                }
                else
                {
                    //cover id doesn't exist
                    if (cover.ParentCoverId__c != null)
                    {
                        //subcover
                        Cover__c parent = mapNewCovers.get(cover.ParentCoverId__c);

                        if (parent != null)
                        {
                            //set parent cover to the subcover
                            cover.ParentCoverId__c = item.ItemId__c + '-' + parent.Name;
                        }

                        cover.CoverId__c = item.ItemId__c + '-' + cover.Name;
                        //delete relation set in parser
                        if (cover.PolicyProduct__r.ItemId__c != null)
                        {
                            cover.PolicyProduct__r.ItemId__c = null;
                        }
                        cover.LegalEntity__c = LegalEntity;
                        cover.ownerId = recordOwner.id;

                        if (!subCoversToInsertQuote.containsKey(cover.CoverId__c) )
                        {
                            subCoversToInsertQuote.put(cover.CoverId__c, cover);
                        }
                    }
                    else
                    {
                        //cover
                        // identificador:  itemid-CoverName
                        cover.CoverId__c = item.ItemId__c + '-' + cover.Name;
                        cover.LegalEntity__c = LegalEntity;
                        cover.ownerId = recordOwner.id;

                        updateCover.put(cover.CoverId__c, cover);
                    }
                }
            }
        }
    }
}