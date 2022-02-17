public class GenesysCloudDisconnectionAction {
    /**
     * La acción se diseña como un Invocable Action que recoge los datos de los Email Messages cuyas interacciones 
     * hay que desconectar. Con la información de dichos EmailMessages se crean una serie de eventos en los que se va a 
     * delegar las llamadas a la API de GenesysCloud para su desconexión.
       @param listaInputMessages Lista de Lista de EmailMessages que se reciben desde el Flow
       @return Devuelve el status de las publicaciones de los eventos que se han generado (List<List<String>>).
     */
    @InvocableMethod(
        label='Disconnect Interactions using Genesys Cloud APi'
               description='Allows to close an interaction through Genesys Cloud'
                            category= 'Other'
        )
    public static List<List<String>> execute(List<List<EmailMessage>> listaCasos)
    {
        List<List<String>> retorno = new List<List<String>>();
        
        for(List<EmailMessage> listaEmailMessages : listaCasos)
        {
            List<String> listaInteraccionesSalida = new List<String>();
            for(EmailMessage email: listaEmailMessages)
            {
                try
                {
                    // Creamos un objeto del tipo que necesita GenesysCloud para mandarlo por su api
                    GenesysCloud.InteractionCancel intCancel = new GenesysCloud.InteractionCancel();
                    intCancel.conversationId = email.GenesysInteractionId__c;

                    // Llamamos al servicio que hemos creado en GenesysCloud para ejecutar la Desconexión
                    String idSalida = GenesysCloud.DisconnectionService.close(intCancel);
                    listaInteraccionesSalida.add(idSalida);
                }
                catch(Exception e)
                {
                    System.debug(e.getMessage());
                }
            }
            retorno.add(listaInteraccionesSalida);
        }
        return retorno;
    }

}
