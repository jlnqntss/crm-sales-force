public with sharing class GenesysCloudEmailStatusAction
{

    @InvocableMethod(
        label='Check the status of Interactions using Genesys Cloud API'
               description='Check the status of an interaction to see if it can be closed through Genesys Cloud'
                            category='Other'
        )

    public static List<List<String> > execute (List<List<EmailMessage> > estadoInteracciones)
    {
        List<List<String> > listaRetorno = new List<List<String> >();

        System.debug('*Lista Entrada GenesysCloudEmailStatusAction*: '+estadoInteracciones);

        for (List<EmailMessage> listaParaEstadoEmailMessages : estadoInteracciones)
        {
            List<String> listaValores = new List<String>();

            for(EmailMessage email : listaParaEstadoEmailMessages)
            {
                String valores = '';

                try
                {
                    //generamos una nueva interacción de Genesys Cloud
                    GenesysCloud.InteractionStatusId statusInteract = new GenesysCloud.InteractionStatusId();
                    System.debug('GenesysCloudEmailStatusAction statusInteract: '+statusInteract);

                    statusInteract.conversationId = email.GenesysInteractionId__c;
                    System.DEBUG('GenesysCloudEmailStatusAction: '+statusInteract.conversationId);

                    HttpResponse idEstado = new GenesysCloud.StatusServiceId().status(statusInteract);
                    System.debug('*GenesysCloudEmailStatusAction idEstado*: '+idEstado);

                    String body = idEstado.getBody();
                    System.debug('*GenesysCloudEmailStatusAction body*:'+body);
                    Map<String,Object> mapaObjetos = (Map<String,Object>) JSON.deserializeUntyped(body);
                    System.debug('*GenesysCloudEmailStatusAction mapaObjetos*:'+mapaObjetos);
                    Object participantListObj = mapaObjetos.get('participants');
                    System.debug('*GenesysCloudEmailStatusAction participantListObj*:'+participantListObj);
                    List<Object> participantsInteraction = (List<Object>) participantListObj;

                    for(Object participantObj : participantsInteraction)
                    {
                        Map<String,Object> participant = (Map<String,Object>) participantObj;

                        if( valores == '' )
                        {   
                            valores = email.GenesysInteractionId__c + '#' + participant.get('id'); 
                        }
                    }
                    if (valores != '')
                    {
                        listaValores.add(valores);
                        System.debug('Tamaño salida lita valores:'+listaValores.size());
                    }

                }
                catch (Exception e)
                {
                    ErrorLogUtil.commitError(e, 'GenesysCloudEmailStatusAction->'+e.getMessage());

                }
            }
            listaRetorno.add(listaValores);
        }
        return listaRetorno;
    }
}