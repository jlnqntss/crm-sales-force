/**
* Clase de test para la lógica de la clase RoutingTeamQueueConfigUtil
* @author fjbelmonte
* @date: 24/10/2024
*/
@isTest
private with sharing class RoutingTeamQueueConfigUtilTest {
    /**
     * Devuelve en forma de mapa todas las colas con su correspondiente equipo de enrutamiento
     * @author fjbelmonte
     * @date: 24/10/2024
     */
    @isTest
    private static void test_getRoutingTeamQueueConfigValues()
    {
        Map<String, String> mRoutingTeamQueueConfigValues = null;
        Test.startTest();
            mRoutingTeamQueueConfigValues = RoutingTeamQueueConfigUtil.getRoutingTeamQueueConfigValues();
        Test.stopTest();
        Assert.isNotNull(mRoutingTeamQueueConfigValues , 'mRoutingTeamQueueConfigValues debería contener la tabla de configuración de colas y equipos');
    }
}