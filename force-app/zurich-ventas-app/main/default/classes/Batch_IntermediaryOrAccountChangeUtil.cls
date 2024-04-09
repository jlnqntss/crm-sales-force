/**
 Clase Utilidad para los métodos a utilizar en el proceso batch Batch_ProcessIntermediaryOrAccountChangeUtil y Batch_IntermediaryOrAccountChangeDML
 * 
 * @author dmunoz
 * @date 04/04/2024
 **/
public with sharing class Batch_IntermediaryOrAccountChangeUtil {
    public static final String MOVEMENT_TYPE_CAMBIO_MEDIADOR = 'IntermediaryChange';
    public static final String MOVEMENT_TYPE_CAMBIO_CLIENTE = 'AccountChange';
}