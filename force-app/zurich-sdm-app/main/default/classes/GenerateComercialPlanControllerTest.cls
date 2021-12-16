/**
 * Clase controlador que es invocada en el LWC -> generateComercialPlan
 *
 * @author nts (agonzalezisasi)
 * @date 10/09/2021
 *
 */
@isTest
private with sharing class GenerateComercialPlanControllerTest 
{
    public static final Integer ACTUAL_YEAR = 2021;
    
    /**
     * Metodo comun para todas los metodos de test. Inicializa los datos de prueba
     *
     * @author nts (agonzalezisasi)
     * @date 29/06/2021
     */
    @TestSetup
    static void makeData() 
    {
        TestDataFactorySDM.AnualPlanSetupData(ACTUAL_YEAR);
    }

    @isTest
    static void testTerritoryDirector()
    {
        // Recuperamos el usuario DT
        String dtEmail = String.format(TestDataFactorySDM.TERRITORY_EMAIL, new List<String>{String.valueOf(0)});
        List<User> users = [SELECT Id FROM User WHERE Email = :dtEmail];
        System.assertEquals(1, users.size(), 'Deberia haber 1 usuario DT');
        User dtUser = users[0];

        // Recuperamos la tabla
        String tableString;
        System.runAs(dtUser) {
            tableString = GenerateComercialPlanController.getRecords(ACTUAL_YEAR);
        }

        // Convertirmos el resultado en objeto Tabletype para verificar mas campos
        GenerateComercialPlanController.Tabletype tabledata = 
            (GenerateComercialPlanController.Tabletype)JSON.deserialize(
                tableString, 
                GenerateComercialPlanController.Tabletype.class
            );
        System.assertNotEquals(null, tabledata.headers, 'Deberia haber una fila de cabecera');
        // 1 = Plan 1
        System.assertEquals(1, tabledata.headers.Cells.size(), 'Deberia haber 1 columna en la fila de cabecera');
        System.assertNotEquals(null, tabledata.rows, 'Deberia haber resto de filas');
        // 6 = segmento, producto, indicador, año, plan dt, rn1
        System.assertEquals(6, tabledata.rows.size(), 'Deberia haber 6 filas');
        // 1 = Plan 1
        System.assertEquals(1, tabledata.rows[0].Cells.size(), 'Deberia haber 1 columna en la primera fila');
        
        // Cambio Nombre del plan
        tabledata.headers.Cells[0].stringValue = 'Plan 1 modificado';
        tabledata.headers.Cells[0].isModified = true;
        // Cambio Segmento
        tabledata.rows[0].Cells[0].stringValue = 'Particulares'; // Picklist PlanComercial__c.Segment__c
        tabledata.rows[0].Cells[0].isModified = true;
        // Cambio Producto
        tabledata.rows[1].Cells[0].stringValue = 'Hogar'; // Picklist PlanComercial__c.Product__c
        tabledata.rows[1].Cells[0].isModified = true;
        // Cambio Indicador
        tabledata.rows[2].Cells[0].stringValue = 'Portfolio'; // Picklist PlanComercial__c.Indicator__c
        tabledata.rows[2].Cells[0].isModified = true;
        // Cambio Plan DT (saltamos año)
        tabledata.rows[4].Cells[0].decimalValue = 10;
        tabledata.rows[4].Cells[0].isModified = true;
        // Cambio RN 1
        tabledata.rows[5].Cells[0].decimalValue = 10;
        tabledata.rows[5].Cells[0].isModified = true;

        // Nuevo plan
        GenerateComercialPlanController.Celltype newPlanHeader = tabledata.headersNew.Cells[0];
        newPlanHeader.stringValue = 'New plan';
        newPlanHeader.Id = null;
        newPlanHeader.IsNew = true;
        tabledata.headers.Cells.add(newPlanHeader);
        for(Integer i=0; i<6; i++) {
            GenerateComercialPlanController.Celltype newPlanRow = tabledata.rowsNew[i].Cells[0];
            newPlanRow.Id = null;
            newPlanRow.IsNew = true;
            if( i == 4 || i == 5 ) { // filas de plan DT y RN
                newPlanRow.decimalValue = 8;
            }
            tabledata.rows[i].Cells.add(newPlanRow);
        }

        tableString = tabledata.toJSON();
        Test.startTest();        
        System.runAs(dtUser) {
            GenerateComercialPlanController.saveData(tableString);
        }
        Test.stopTest();

        // Comprobamos el resultado
        
        // Modificaciones en los planes
        List<PlanComercial__c> resultPlans = [
            SELECT Id, Name FROM PlanComercial__c WHERE Name = 'Plan 1 modificado'
        ];
        // 2 = plan DT global, plan de RN 1, no ve los 3 planes de mediadores
        System.assertEquals(2, resultPlans.size(), 'Deberia haber 2 planes modificados');

        // Creacion de nuevo plan
        resultPlans = [
            SELECT Id, Name FROM PlanComercial__c WHERE Name = :newPlanHeader.stringValue
        ];
        // 2 = plan DT global, plan de RN 1
        System.assertEquals(2, resultPlans.size(), 'Deberia haber 2 planes nuevos');

    }

    @isTest
    static void testBusinessManager()
    {
        // Recuperamos el usuario DT
        String rnEmail = String.format(TestDataFactorySDM.BUSINESS_EMAIL, new List<String>{String.valueOf(0)});
        List<User> users = [SELECT Id FROM User WHERE Email = :rnEmail];
        System.assertEquals(1, users.size(), 'Deberia haber 1 usuario RN');
        User rnUser = users[0];

        // Recuperamos la tabla
        String tableString;
        System.runAs(rnUser) {
            tableString = GenerateComercialPlanController.getRecords(ACTUAL_YEAR);
        }

        // Convertirmos el resultado en objeto Tabletype para verificar mas campos
        GenerateComercialPlanController.Tabletype tabledata = 
            (GenerateComercialPlanController.Tabletype)JSON.deserialize(
                tableString, 
                GenerateComercialPlanController.Tabletype.class
            );
        System.assertNotEquals(null, tabledata.headers, 'Deberia haber una fila de cabecera');
        // 1 = Plan 1
        System.assertEquals(1, tabledata.headers.Cells.size(), 'Deberia haber 1 columna en la fila de cabecera');
        System.assertNotEquals(null, tabledata.rows, 'Deberia haber resto de filas');
        // 8 = segmento, producto, indicador, año, plan dt, Mediador 1, Mediador 2, Mediador 3
        System.assertEquals(8, tabledata.rows.size(), 'Deberia haber 8 filas');
        // 1 = Plan 1
        System.assertEquals(1, tabledata.rows[0].Cells.size(), 'Deberia haber 1 columna en la primera fila');
        
        List<Id> intermediaryIds = new List<Id>();
        // Cambio Mediador 1
        intermediaryIds.add(tabledata.rows[5].Id);
        tabledata.rows[5].Cells[0].decimalValue = 2;
        tabledata.rows[5].Cells[0].isModified = true;
        // Cambio Mediador 2
        intermediaryIds.add(tabledata.rows[6].Id);
        tabledata.rows[6].Cells[0].decimalValue = 3;
        tabledata.rows[6].Cells[0].isModified = true;
        // Cambio Mediador 3
        intermediaryIds.add(tabledata.rows[7].Id);
        tabledata.rows[7].Cells[0].decimalValue = 4;
        tabledata.rows[7].Cells[0].isModified = true;

        tableString = tabledata.toJSON();

        Test.startTest();        
        System.runAs(rnUser) {
            GenerateComercialPlanController.saveData(tableString);
        }
        Test.stopTest();

        List<PlanComercial__c> resultPlans = [
            SELECT Id, TargetKPINumber__c FROM PlanComercial__c WHERE Intermediary__c IN :intermediaryIds
        ];
        System.assertEquals(3, resultPlans.size(), 'Deberia haber 3 planes del RN para los mediadores');
        Decimal sumValue = 0;
        for(PlanComercial__c plan: resultPlans) {
            sumValue += plan.TargetKPINumber__c;
        }
        System.assertEquals(9, sumValue, 'La suma de target KPI number deberia ser 9');
    }

    @isTest
    static void testDeletePlans()
    {
        // Recuperamos el usuario DT
        String rnEmail = String.format(TestDataFactorySDM.BUSINESS_EMAIL, new List<String>{String.valueOf(0)});
        List<User> users = [SELECT Id FROM User WHERE Email = :rnEmail];
        System.assertEquals(1, users.size(), 'Deberia haber 1 usuario RN');
        User rnUser = users[0];
        
        // Simulamos que se han calculado los KPIs y se han actualizado los planes con el valor
        List<PlanComercial__c> plans = [
            SELECT Id, Actual_KPI__c FROM PlanComercial__c WHERE AssignedTo__c = :rnUser.Id
        ];
        System.assertEquals(4, plans.size(), 'Deberia haber 4 planes, rn y 3 mediadores');
        for(PlanComercial__c plan: plans) {
            plan.Actual_KPI__c = 1;
        }
        update plans;

        String tableString;
        System.runAs(rnUser) {
            tableString = GenerateComercialPlanController.getRecords(ACTUAL_YEAR);
        }
        
        // Comprobamos el resultado
        System.assertEquals(true, String.isNotEmpty(tableString), 'El string de la tabla no deberia ser vacio');

        // Convertirmos el resultado en objeto Tabletype para verificar mas campos
        GenerateComercialPlanController.Tabletype tabledata = 
            (GenerateComercialPlanController.Tabletype)JSON.deserialize(
                tableString, 
                GenerateComercialPlanController.Tabletype.class
            );
        
        tabledata.headers.Cells[0].isDeleted = true;
        for(Integer i; i<tabledata.rows.size(); i++) {
            tabledata.rows[i].Cells[0].isDeleted = true;
        }

        Test.startTest();
        tableString = tabledata.toJSON();
        System.runAs(rnUser) {
            GenerateComercialPlanController.saveData(tableString);
        }
        Test.stopTest();

        // Comprobamos el resultado
        List<PlanComercial__c> resultPlans = [
            SELECT Id FROM PlanComercial__c WHERE Intermediary__c != null
        ];
        System.assertEquals(0, resultPlans.size(), 'No deberia haber planes de los mediadores');
    }

    @isTest
    static void testSaveData_ko()
    {
        Test.startTest();
        String exceptionMessage = null;
        try {
            GenerateComercialPlanController.testException = 'Error desconocido';
            GenerateComercialPlanController.saveData('vacio');
        } catch(Exception ex) {
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();

        // Comprobamos el resultado
        System.assertEquals(true, String.isNotBlank(exceptionMessage), 'El mensaje de excepcion no deberia estar vacio');

        List<Error_Log__c> errorList = (new ErrorLogSelector()).findAll();
        System.assertEquals(false, errorList.isEmpty(), 'Deberia haber un errorlog');
    }

    @isTest
    static void testGetRecords_ko()
    {
        Test.startTest();
        String exceptionMessage = null;
        try {
            GenerateComercialPlanController.testException = 'Error desconocido';
            GenerateComercialPlanController.getRecords(2021);
        } catch(Exception ex) {
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();

        // Comprobamos el resultado
        System.assertEquals(true, String.isNotBlank(exceptionMessage), 'El mensaje de excepcion no deberia estar vacio');
        
        List<Error_Log__c> errorList = (new ErrorLogSelector()).findAll();
        System.assertEquals(false, errorList.isEmpty(), 'Deberia haber un errorlog');
    }
}