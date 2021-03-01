public class AssetUtil {
    
    /**
     * Método que controla la generación del scope correspondiente
     * Actualmente solo se generá scope para pólizas que provengan de INFO
     *
     * @author nts (agonzalezisasi)
     * @date 24/02/2021
     */
    public static void generateScope(List<Asset> newList)
    {
        List<Asset> polToGenerateScope = new List<Asset>();

        for(Asset asset : newList) {
            if( String.isNotBlank(asset.PolicyId__c) && asset.Scope__c == null ) {
                polToGenerateScope.add(asset);
            }
        }

        if( !polToGenerateScope.isEmpty() ) {
            GenerateScopeUtil.generateScopeEvents(
                Asset.Scope__c.getDescribe().getName(), 
                Asset.PolicyId__c.getDescribe().getName(),
                Policy__c.getSObjectType().getDescribe().getName(), 
                Policy__c.Scope__c.getDescribe().getName(),
                polToGenerateScope
            );
        }
    }
}
