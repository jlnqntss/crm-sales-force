public with sharing class GenesysCloudPatchInteractionAction
{

    @InvocableMethod(
        label='Update the wrapup of Interactions using Genesys Cloud API'
               description='Check the purpose and state of an interaction to check if its wrapup can be patched through Genesys Cloud'
                            category='Other'
        )
    public static List<List<String> > execute (List<List<String> > listaRetorno)
    {
        System.debug('*listaRetorno*:'+listaRetorno);
        List<List<String> > responsePatch = new List<List<String> >();
        String getDataResponse;

        for (List<String> interaccionPatch : listaRetorno)
        {
            List<String> listaResponsePatch = new List<String>();

            for(String interaccionToPatch : interaccionPatch)
            {
                try
                {
                    GenesysCloud.InteractionStatus interaccionCasos = new GenesysCloud.InteractionStatus();

                    interaccionCasos.conversationId = interaccionToPatch.split('#').get(0);
                    interaccionCasos.participants = interaccionToPatch.split('#').get(1);
                    interaccionCasos.purposeStatus = interaccionToPatch.split('#').get(2);

                    System.debug('*interaccionCasos*: '+interaccionCasos);

                    getDataResponse = GenesysCloud.PatchService.patchForService(interaccionCasos);

                    System.debug('*getDataResponse*: '+getDataResponse);
                    listaResponsePatch.add(getDataResponse);

                }

                catch (Exception e)
                {
                   //Catch code 
                }
            }
            responsePatch.add(listaResponsePatch);
        }
        System.debug('*responsePatch*: '+responsePatch);
        return responsePatch;
    }
}