/**
 * Clase test AuthProviderSelect
 *
 * @author dmunoz
 * @date 29/05/2024
 */
@IsTest
private with sharing class AuthProviderSelectorTest {
    
    /**
     * Clase test Metodo test selector AuthProvider
     *
     * @author dmunoz
     * @date 29/05/2024
     */
    @IsTest
    private static void testGetAuthProvider() {

        Test.startTest();
        AuthProviderSelector selector = new AuthProviderSelector();
        List<AuthProvider> providers = selector.getAuthProvider('zurich_internal');
        Test.stopTest();

        Assert.isTrue(providers.size() > 0, 'Debe obtener un resultado');
    }
}