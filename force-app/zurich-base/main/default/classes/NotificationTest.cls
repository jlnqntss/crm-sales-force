/**
 * Test para la clase Notification
 *
 * @author nts (agonzalezisasi)
 * @date 19/08/2021
 */
@isTest
private class NotificationTest
{
    /**
     * Test del metodo que comprueba el envio correcto de una notificacion
     * 
     * @author nts (agonzalezisasi)
     * @date 19/08/2021
     */
    @isTest
    static void send_ok()
    {
        //String targetID = '000000000000000AAA'; //dummy
        // El usuario actual recibe la notificacion
        String currentUserid = UserInfo.getUserId();
        Set<String> recipientsIds = new Set<String>{currentUserid};

        Test.startTest();
        // Creamos el objeto notificacion
        Notification notification = new Notification(Notification.NotificationType.SDMAlert);
        // Lo preparamos para que vaya al apartado de Cuentas
        notification.addPageReference('standard__objectPage', 'Account', 'list', 'Recent');
        // Enviamos la notificacion
        notification.send(recipientsIds, 'Welcome!', 'Notification body');
        Test.stopTest();

        // Hasta la fecha (19/08/2021) no se puede comprobar si la notificacion se ha enviado por lo que no se
        // incluye assert
    }

    @isTest
    static void send_ko()
    {
        Notification notification = new Notification(Notification.NotificationType.SDMAlert);
        notification.testUknownError = true;

        Test.startTest();
        notification.send('no title', 'no content');
        Test.stopTest();

        // Resultado
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(false, errorLogs.isEmpty(), 'Deberia haber Error Logs');
    }
}
