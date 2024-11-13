/**
 * Clase utils para la gestión de la custom metadata  RoutingTeamQueueConfig__mdt, cuyo objetivo es mapear las colas de casos
 * con el equipo de enrutamiento correspondiente
 * @author fjbelmonte
 * @date 24/10/2024
 */
public with sharing class RoutingTeamQueueConfigUtil {
 
    /**
     * Devuelve en forma de mapa todas las colas con su correspondiente equipo de enrutamiento
     * @author fjbelmonte
     * @date 24/10/2024
     * @return  Mapa con los valores de la mdt
     */
    public static Map<String, String> getRoutingTeamQueueConfigValues()
    {
        Map<String, String> mConfigValues = new Map<String, String>();
        
        //Get de todos los registros del CMT
        Map<String, RoutingTeamQueueConfig__mdt> mConfigs = RoutingTeamQueueConfig__mdt.getAll();
        // Agregar los valores al mapa
        for (RoutingTeamQueueConfig__mdt config : mConfigs.values()) {
            mConfigValues.put(config.Queue__c, config.RoutingTeam__c);
        }
        return mConfigValues;
    }
}