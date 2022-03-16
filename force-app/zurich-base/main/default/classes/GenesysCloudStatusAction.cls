public with sharing class GenesysCloudStatusAction
{

    @InvocableMethod(
        label='Check the status of Interactions using Genesys Cloud API'
               description='Check the status of an interaction to see if it can be closed through Genesys Cloud'
                            category='Other'
        )

    public static List<List<String> > execute (List<List<EmailMessage> > estadoInteracciones)
    {
        List<List<String> > listaRetorno = new List<List<String> >();

        for (List<EmailMessage> listaParaEstadoEmailMessages : estadoInteracciones)
        {

            List<String> listaValores = new List<String>();

            for(EmailMessage email : listaParaEstadoEmailMessages)
            {
                try
                {
                    //Creo nueva instancia de InteractionStatus
                    GenesysCloud.InteractionStatus statusInteract = new GenesysCloud.InteractionStatus();
                    //hago que tenga el valor de la Id que tiene el email que traigo como parámetor
                    statusInteract.conversationId = email.GenesysInteractionId__c;
                    //lo utilizo para hacer una nueva llamada httpresponse para traerme todo el objeto
                    HttpResponse idEstado = GenesysCloud.StatusService.status(statusInteract);
                    // 1. Recuperar body
                    String body = idEstado.getBody();
                    // 2. Deserializar el JSON
                    Map<String,Object> mapaObjetos = (Map<String,Object>) JSON.deserializeUntyped(body);
                    // 3. Coger el parámetro que necesito
                    Object participantListObj = mapaObjetos.get('participants');
                    // 4. Creamos una lista de objetos para poder pasar a una lista el objeto participants
                    List<Object> participantsInteraction = (List<Object>) participantListObj;
                    // 5. Recorremos la lista de objetos que hemos creado
                    for(Object participantObj : participantsInteraction)
                    {
                        //asignamos el participantObj a un mapa de participant para poder comprar los valores y añadirlo
                        Map<String,Object> participant = (Map<String,Object>) participantObj;
                        if( listaValores.isEmpty() )
                        {
                            if ( participant.get('purpose') == 'agent' && (participant.get('state') == 'connected' || participant.get('state') == 'alerting') )
                            {
                                listaValores.add(email.GenesysInteractionId__c + '#' + participant.get('id') + '#' + 'pending');
                            }
                            else if (participant.get('purpose') == 'acd' && participant.get('state') == 'connected')
                            {
                                listaValores.add(email.GenesysInteractionId__c + '#' + participant.get('id') + '#' + 'working');
                            }
                        }
                    }
                    listaRetorno.add(listaValores);
                }
                catch (Exception e)
                {
                    System.debug( e.getMessage() );
                }
            }
        }
        return listaRetorno;
    }
}