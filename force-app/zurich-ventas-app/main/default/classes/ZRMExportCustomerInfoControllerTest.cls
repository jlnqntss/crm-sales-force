/**
 * @description       : Controlador visualforce page ZRMExportCustomerInfoAndRelated
 * @author            : dmunoz
 * @group             :
 * @last modified on  : 05-11-2024
 **/
@isTest
public with sharing class ZRMExportCustomerInfoControllerTest {
    
    @TestSetup
    static void makeData(){
         //Insertar cuenta
         List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
         insert accounts;
    }

    @isTest
    private static void testLoadData() {
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];

        // Simulación del controlador estándar y del controlador personalizado
        ApexPages.StandardController stdController = new ApexPages.StandardController(testAccount); 
        ZRMExportCustomerInfoController controller = new ZRMExportCustomerInfoController(stdController);

        // Ejecutar el método para cargar los datos relacionados
        Test.startTest();
        controller.loadRelatedData();
        Test.stopTest();

        Assert.areEqual(testAccount.Name, controller.account.Name, 'Debe coincidir el nombre de la cuenta');
    }
}