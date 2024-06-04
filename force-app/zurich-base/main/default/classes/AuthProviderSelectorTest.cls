@IsTest
public with sharing class AuthProviderSelectorTest {
    
    @IsTest
    private static void testGetAuthProvider() {

        Test.startTest();
        AuthProviderSelector selector = new AuthProviderSelector();
        List<AuthProvider> providers = selector.getAuthProvider('zurich_internal');
        Test.stopTest();

        Assert.isTrue(providers.size() > 0, 'Debe obtener un resultado');
    }
}