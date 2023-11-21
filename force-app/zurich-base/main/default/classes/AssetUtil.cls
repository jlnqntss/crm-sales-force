public class AssetUtil
{

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

        for(Asset asset : newList)
        {
            if( String.isNotBlank(asset.PolicyId__c) && asset.Scope__c == null )
            {
                polToGenerateScope.add(asset);
            }
        }

        if( !polToGenerateScope.isEmpty() )
        {
            GenerateScopeUtil.generateScopeEvents(
                Asset.Scope__c.getDescribe().getName(),
                Asset.PolicyId__c.getDescribe().getName(),
                Policy__c.getSObjectType().getDescribe().getName(),
                Policy__c.Scope__c.getDescribe().getName(),
                polToGenerateScope
                );
        }
    }

    /**
     * Actualiza los datos de la póliza vinculada a un asset
     *
     * @author fpalomo
     * @date 20/11/2023
     */
    public static void updateLinkedPolicy(List<Asset> newList)
    {
        Id assetAddressRT = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Address').getRecordTypeId();
        Id assetMotorRT = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Motor').getRecordTypeId();

        // 1. Obtenemos una lista con las pólizas de los assets
        Set<String> severalAssetsPoliciesIdSet = new Set<String>();
        Set<String> policyIdSet = new Set<String>();
        for (Asset asset : newList)
        {
            if ( asset.PolicyId__c != null)
            {
                policyIdSet.add(asset.PolicyId__c);
                if (asset.RecordTypeId != assetAddressRT && asset.RecordTypeId != assetMotorRT)
                {
                    severalAssetsPoliciesIdSet.add(asset.PolicyId__c);
                }
            }
        }

        // 2. Si no hay pólizas, salimos
        if ( policyIdSet.isEmpty() )
        {
            return;
        }

        // 3. Obtenemos las pólizas
        List<Policy__c> polizas = new PoliciesSelector().selectById(policyIdSet);

        // 4 Si el número de pólizas es distinto al número de assets, obtenemos el último asset creado para cada póliza
        List<Asset> assets = newList;
        if ( newList.size() != policyIdSet.size() )
        {
            AssetsSelector assetSelector = new AssetsSelector();
            assetSelector.baseQuery.orderBy('CreatedDate', 'DESC').setLimit(1);
            assets = assetSelector.selectByPolicyID( new List<String>(policyIdSet) );
        }

        // 5. Mapeamos cada asset con su póliza
        Map<Id, Asset> assetMap = new Map<Id, Asset>();
        for (Asset asset : assets)
        {
            assetMap.put(asset.PolicyId__c, asset);
        }

        // 6. Actualizamos las pólizas
        for(Policy__c policy : polizas)
        {
            if( severalAssetsPoliciesIdSet.contains(policy.Id) )
            {
                policy.AssetIdentifier__c = Label.ventasAssetIdentifierVarios;
            }
            else
            {
                policy.AssetIdentifier__c = assetMap.get(policy.Id).Identifier__c;
            }
        }

        update polizas;
    }
}