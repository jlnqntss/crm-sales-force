public with sharing class GenesysCloudBatchPatchInteractionAction
{

    @InvocableMethod(
        label='Update the wrapup of Interactions using Genesys Cloud API'
               description='Check the purpose and state of an interaction to check if its wrapup can be patched through Genesys Cloud'
                            category='Other'
        )
    public static List<List<String> > execute (List<List<String> > listaRetorno)
    {
        System.debug('*GenesysCloudBatchPatchInteractionAction lista entrada*:'+listaRetorno);

        List<List<String> > responsePatch = new List<List<String> >();
        String getDataResponse;

        for (List<String> interaccionPatch : listaRetorno)
        {
            List<String> listaResponsePatch = new List<String>();

            for(String interaccionToPatch : interaccionPatch)
            {
                try
                {
                    GenesysCloud.InteractionStatusId interaccionCasos = new GenesysCloud.InteractionStatusId();

                    interaccionCasos.conversationId = interaccionToPatch.split('#').get(0);
                    interaccionCasos.participants = interaccionToPatch.split('#').get(1);

                    System.debug('*GenesysCloudBatchPatchInteractionAction interaccionCasos*: '+interaccionCasos);
                    if(Test.isRunningTest())
                    {
                        String bodyAcd = '{"state": "disconnected", "wrapup: [{"code": "123", "name": "válida"}]}';
                        Integer codeAcd = 200;
                        GenesysCloud.PatchServiceId.mock = new GenesysCloudMocks(bodyAcd, codeAcd);
                    }
                    getDataResponse = GenesysCloud.PatchServiceId.patchForServiceId(interaccionCasos);
                    
                    System.debug('*GenesysCloudBatchPatchInteractionAction getDataResponse*: '+getDataResponse +'conversationId'+interaccionCasos.conversationId);
                    listaResponsePatch.add(getDataResponse);

                }

                catch (Exception e)
                {
                    ErrorLogUtil.commitError(e, 'GenesysCloudBatchPatchInteractionAction->'+e.getMessage());
                }
            }
            responsePatch.add(listaResponsePatch);
        }
        
        System.debug('*GenesysCloudBatchPatchInteractionAction responsePatch*: '+responsePatch);
        return responsePatch;
    }
}