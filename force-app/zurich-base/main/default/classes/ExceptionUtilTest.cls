/**
 * @description       : Clase de test que recoge los test unitarios para la clase
 *                      'ExceptionUtil'
 * @author            : amiranda
 * @date              : 18-12-2023
 * @last modified on  : 18-12-2023
 * @last modified by  : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   18-12-2023   amiranda   Initial Version
 **/
@IsTest
 private with sharing class ExceptionUtilTest
{

    /**
     * @description Método de test que comprueba que se lanza la excepción 
     * correctamente cuando se invoca el método de lanzar excepciones utilizado
     * en los flujos.
     * 
     * @author amiranda 
     * @date 18-12-2023
     **/
    @IsTest
    private static void test_throwFlowException()
    {
        Test.startTest();
        try
        {
            ExceptionUtil.throwFlowException(new List<String>{'Test error'});
            Assert.fail('Debería haberse lanzado una excepción.');
        }
        catch (Exception ex)
        {
            Assert.areEqual(FlowUtil.FlowException.class.toString(),
                            ex.getTypeName(),
                            'El tipo de excepción no coincide');
        }
        Test.stopTest();
    }
}