/**
 * @description       : Clase de utilidad para la gestión de Excepciones
 * @author            : amiranda
 * @date              : 18-12-2023
 * @last modified on  : 18-12-2023
 * @last modified by  : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   18-12-2023   amiranda   Initial Version
 **/
public with sharing class ExceptionUtil
{

    /**
     * @description Método invocable para ser utilizado desde los Flows de Salesforce.
     * Permite lanzar una excepción y realizar rollback de la transacción en aquellos
     * flujos que no tienen la acción estándar de Salesforce 'Roll Back Records'.
     *
     * @author amiranda
     * @date 18-12-2023
     * @param exceptionMessage Mensaje de error que se ha producido en la excepción
     **/
    @InvocableMethod(label='Throw Custom Apex Exception'
                            description='Throws an exception in Apex to control flow errors and rollback the entire transaction.'
                                         category='Exception Handling')
    public static void throwFlowException(List<String> exceptionMessage)
    {
        throw new FlowUtil.FlowException( System.Label.FlowApexExceptionMessage + ' ' + exceptionMessage.get(0) );
    }
}