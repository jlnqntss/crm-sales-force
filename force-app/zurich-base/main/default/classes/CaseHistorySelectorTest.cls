/**
 * @description       : Clase de test para la clase selectora CaseHistorySelector
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 06-26-2023
 * @last modified by  : aberuete
**/
@isTest
private class CaseHistorySelectorTest 
{
    /*
    * Test que comprueba que se obtiene correctamente los valores del case history filtrado por caso, tipo de campo que se ha actualizado y tipo de dato
    * @author aberuete
    * @date 26/06/2023
    */
    @isTest
    static void test_findByCaseIdAndField()
    {
        // Crear caso
        Case caso = new Case();
        caso.Subject = 'Test Case';
        insert caso;

        // Case history
        CaseHistory ch1 = new CaseHistory();
        ch1.CaseId = caso.Id;
        ch1.Field = 'Owner';
        ch1.DataType = 'EntityId';
        insert ch1;

        Test.startTest();
        List<CaseHistory> result = new CaseHistorySelector().findByCaseIdAndFieldAndDatType(caso.Id, 'Owner', 'EntityId');
        Test.stopTest();

        // Verificar los resultados
        System.assertEquals(1, result.size(), 'Debería haber un solo registro coincidente');
        System.assertEquals(caso.Id, result[0].CaseId, 'El ID del caso no coincide');
    }
}

