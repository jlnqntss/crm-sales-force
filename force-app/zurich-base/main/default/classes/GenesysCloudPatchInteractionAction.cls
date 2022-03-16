public with sharing class GenesysCloudPatchInteractionAction
{

    @InvocableMethod(
        label='Update the wrapup of Interactions using Genesys Cloud API'
               description='Check the purpose and state of an interaction to check if its wrapup can be patched through Genesys Cloud'
                            category='Other'
        )
    public static List<String> execute (List<List<String> > listaRetorno)
    {
        List<String> responsePatch = new List<String>();

        String response;
        String getDataResponse;

        for (List<String> interaccionPatch : listaRetorno)
        {
            for(String interaccionToPatch : interaccionPatch)
            {
                try
                {
                    GenesysCloud.InteractionStatus interaccionCasos = new GenesysCloud.InteractionStatus();

                    interaccionCasos.conversationId = interaccionToPatch.split('#').get(0);
                    interaccionCasos.participants = interaccionToPatch.split('#').get(1);
                    interaccionCasos.purposeStatus = interaccionToPatch.split('#').get(2);

                    getDataResponse = GenesysCloud.PatchService.patchForService(interaccionCasos);
                    responsePatch.add(getDataResponse);

                }

                catch (Exception e)
                {
                    System.debug( e.getMessage() );
                }
            }
        }
        return responsePatch;
    }
}
