public with sharing class GenesysCloudPatchInteractionAction
{

    @InvocableMethod(
        label='Update the wrapup of Interactions using Genesys Cloud API'
               description='Check the purpose and state of an interaction to check if its wrapup can be patched through Genesys Cloud'
                            category='Other'
        )
    public static List<List<String> > execute (List<List<String> > listaRetorno)
    {
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

                    getDataResponse = GenesysCloud.PatchService.patchForService(interaccionCasos);
                    listaResponsePatch.add(getDataResponse);

                }

                catch (Exception e)
                {
                    
                }
            }
            responsePatch.add(listaResponsePatch);
        }
        return responsePatch;
    }
}