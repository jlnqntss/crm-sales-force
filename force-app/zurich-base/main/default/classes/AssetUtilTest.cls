@isTest
private class AssetUtilTest
{
    @TestSetup
    static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);
        for(Policy__c p: policies)
        {
            p.Scope__c = 'ZE';
        }
        insert policies;
    }

    /**
     * Test que comprueba la generación del ámbito correspondiente para cada siniestro (Asset)
     *
     * @author nts (agonzalezisasi)
     * @date 18/02/2021
     */
    @isTest
    static void test_generateScope()
    {
        // Recuperamos las polizas
        List<Policy__c> policies = [SELECT Id, Scope__c FROM Policy__c WHERE Scope__c != null];
        System.assertEquals(10, policies.size(), 'Deberia haber 10 polizas con scope');

        // Preparamos los siniestros (Asset) sin indicar el scope
        List<Asset> assets = new List<Asset>();
        for( Integer i=0,j=policies.size(); i < j; i++ )
        {
            assets.add( new Asset(
                            Name= String.valueOf(i + 1).leftPad(9, '0'),
                            PolicyId__c= policies[i].Id,
                            Scope__c= null
                            ) );
        }

        Test.startTest();
        insert assets;
        Test.stopTest();

        List<Asset> assetsUpdated = [SELECT Scope__c FROM Asset WHERE Scope__c != null];
        System.assertEquals(10, assetsUpdated.size(), 'No se han generado todas los Assets con el Ambito correctamente');

        //Para cobertura beforeDelete/afterDelete
        delete assets;
    }

    @isTest
    static void test_updateLinkedPolicy()
    {
        // 1. Recuperamos una póliza
        List<Policy__c> policies = [SELECT AssetIdentifier__c, InfoPolicyNumber__c FROM Policy__c LIMIT 1];
        Assert.areEqual(1, policies.size(), 'La query debería haber recuperado una póliza');

        // 2. Creamos un asset vinculado a la póliza
        Asset newAsset = new Asset(
            Name = 'Test update policy',
            BrandName__c = 'Test',
            Model__c = 'Test',
            RegistrationNumber__c = 'Test',
            INFOInsuredObjectCode__c = policies[0].InfoPolicyNumber__c,
            RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Motor').getRecordTypeId(),
            PolicyId__c = policies[0].Id
            );

        Test.startTest();
        insert newAsset;
        Test.stopTest();

        Asset insertedAsset = [SELECT Identifier__c FROM Asset WHERE Id = : newAsset.Id];
        Policy__c updatedPolicy = [SELECT AssetIdentifier__c FROM Policy__c WHERE Id = : policies[0].Id];

        // 3. Comprobamos que se haya actualizado el campo AssetIdentifier__c de la póliza
        Assert.areNotEqual(insertedAsset.Identifier__c, null, 'El campo Identifier__c del asset no se ha calculado.');
        Assert.areEqual(insertedAsset.Identifier__c, updatedPolicy.AssetIdentifier__c, 'El campo AssetIdentifier__c de la póliza no se ha actualizado correctamente');
    }
}
