/**
 * @description       : Clase de test para comprobar el correcto funcionamiento
 * de la clase 'Batc_IntermediaryOrAccountChangeZRM'
 * @author            : amiranda
 * @date              : 11-04-2024
 * @last modified on  : 11-04-2024
 * @last modified by  : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   11-04-2024   amiranda   Initial Version
**/
@IsTest
private with sharing class Batch_IntermediaryOrAccountChangeZRMTest
{
    /**
    * @description Método de test que comprueba simultáneamente la programación
    * de un job y la ejecución el batch. Este batch no tiene ninguna lógica por
    * lo que es suficiente comprobar que se encola.
    * @author amiranda
    * @date 11-04-2024 
    **/
    @IsTest
    private static void test_createStandardSchedule()
    {
        String jobName = Batch_IntermediaryOrAccountChangeZRM.CLASS_NAME + System.Today();
        Test.startTest();
        Batch_IntermediaryOrAccountChangeZRM.createStandardSchedule(jobName, null, 50);
        Test.stopTest();

        List<AsyncApexJob> asyncApexJobs = [SELECT ApexClass.Name, JobType
                                            FROM AsyncApexJob
                                            WHERE JobType IN ('ScheduledApex', 'BatchApex')];

        List<AsyncApexJob> scheduledJobs = new List<AsyncApexJob>();
        List<AsyncApexJob> batchJobs = new List<AsyncApexJob>();                                            

        for (AsyncApexJob asyncApexJob : asyncApexJobs)
        {
            if (asyncApexJob.JobType == 'ScheduledApex')
            {
                scheduledJobs.add(asyncApexJob);
            }

            if (asyncApexJob.JobType == 'BatchApex')
            {
                batchJobs.add(asyncApexJob);
            }
        }

        // Se comprueba que se ha programado un job
        Assert.isTrue(scheduledJobs.size() == 1,
                      'Debería haberse programado un job.');
        Assert.areEqual(Batch_IntermediaryOrAccountChangeZRM.CLASS_NAME,
                        scheduledJobs.get(0).ApexClass.Name,
                        'El job programado no es el esperado.');

        // Se comprueba que el batch se ha encolado
        Assert.isTrue(batchJobs.size() == 1,
                      'Debería haberse lanzado un batch');
        Assert.areEqual(Batch_IntermediaryOrAccountChangeZRM.CLASS_NAME,
                        batchJobs.get(0).ApexClass.Name,
                        'El batch a ejecutar no es el esperado.');
    }

    /**
    * @description Método de test que comprueba que el método 'setJobName' devuelve
    * la cadena de texto pasasda por parámetro como 'jobName'.
    * @author amiranda
    * @date 11-04-2024 
    **/
    @IsTest
    private static void test_setJobName_customName()
    {
        String jobName = 'TestJobName';

        Test.startTest();
        String returnedJobName = Batch_IntermediaryOrAccountChangeZRM.setJobName(jobName);
        Test.stopTest();

        Assert.areEqual(jobName, returnedJobName, 'El nombre del job debería ser el mismo.');
    }

    /**
    * @description Método de test que comprueba que el método 'setJobName' devuelve
    * la cadena de texto con el nombre por defecto del 'job' que coincide con el nombre
    * de la clase de batch.
    * @author amiranda
    * @date 11-04-2024 
    **/
    @IsTest
    private static void test_setJobName_defaultName()
    {
        Test.startTest();
        String returnedJobName = Batch_IntermediaryOrAccountChangeZRM.setJobName('');
        Test.stopTest();

        Assert.areEqual(Batch_IntermediaryOrAccountChangeZRM.CLASS_NAME,
                        returnedJobName,
                        'El nombre del job debería ser el nombre de la clase de Batch');
    }

    /**
    * @description Método de test que comprueba que el método 'setTimeExpression' devuelve
    * la cadena de texto con la expresión de tiempo pasada por parámetro.
    * @author amiranda
    * @date 11-04-2024 
    **/
    @IsTest
    private static void test_setTimeExpression_customExpression() 
    {
        String timeExpression = '0 30 12 * * ?';

        Test.startTest();
        String returnedTimeExpression = Batch_IntermediaryOrAccountChangeZRM.setTimeExpression(timeExpression);
        Test.stopTest();

        Assert.areEqual(timeExpression, returnedTimeExpression, 'La expresión temporal debería ser la misma.');
    }

    /**
    * @description Método de test que comprueba que el método 'setTimeExpression' devuelve
    * la cadena de texto con la expresión de tiempo por defecto.
    * @author amiranda
    * @date 11-04-2024 
    **/
    @IsTest
    private static void test_setTimeExpression_defaultExpression()
    {
        String defaultTimeExpression = '0 0 3 * * ?';
        Test.startTest();
        String returnedTimeExpression = Batch_IntermediaryOrAccountChangeZRM.setTimeExpression('');
        Test.stopTest();

        Assert.areEqual(defaultTimeExpression,
                        returnedTimeExpression,
                        'La expresión temporal debería ser la establecida por defecto.');
    }
}