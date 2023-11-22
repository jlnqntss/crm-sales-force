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
    public static void updateLinkedPolicy(List<Asset> newList, Map<Id, Asset> oldMap)
    {
        Id assetAddressRT = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Address').getRecordTypeId();
        Id assetMotorRT = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Motor').getRecordTypeId();

        Map<Id, Policy__c> toUpdate = new Map<Id, Policy__c>();

        Policy__c policy = null;
        for ( Asset asset : newList )
        {
            // Si no tiene póliza vinculada, no hacemos nada
            if ( asset.PolicyId__c != null && !toUpdate.containsKey(asset.PolicyId__c) )
            {
                policy = new Policy__c(Id = asset.PolicyId__c);

                // Si no es un asset de tipo dirección o motor, ponemos el identificador a "Varios"
                if ( asset.RecordTypeId != assetAddressRT && asset.RecordTypeId != assetMotorRT )
                {
                    policy.AssetIdentifier__c = Label.ventasAssetIdentifierVarios;
                }
                else
                {
                    policy.AssetIdentifier__c = asset.Identifier__c;
                }

                // Para insert -> actualizamos siempre la póliza
                // Para update -> actualizamos si el identificador ha cambiado
                if ( Trigger.isInsert )
                {
                    toUpdate.put(policy.Id, policy);
                }
                else if ( Trigger.isUpdate )
                {
                    Asset oldAsset = oldMap.get(asset.Id);
                    if ( oldAsset.Identifier__c != asset.Identifier__c )
                    {
                        toUpdate.put(policy.Id, policy);
                    }
                }
            }
        }

        if ( !toUpdate.isEmpty() )
        {
            update toUpdate.values();
        }
    }
}