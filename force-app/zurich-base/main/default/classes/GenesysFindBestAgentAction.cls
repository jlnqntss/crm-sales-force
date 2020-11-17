public class GenesysFindBestAgentAction
{
    /**
     *Delega la ejecución a GenesysInteractionsService.findBestAgentFor(request)
     @param requests Petición de búsqueda. Formato lista para permitir el bulkificado del flow
     @return Devuelve los ownerId encontrados (User.email de salesforce)
     */
    @InvocableMethod(
        label='Find Best Agent (Owner for the Email)'
        description='Use GenesysInteractionsService.findBestAgent()'
        category= 'Other'
    )
    public static List<FindBestAgentResult> execute(List<FindBestAgentRequest> requests)
    {
        GenesysInteractionsService.Interaction interaction;
        List<FindBestAgentResult> results = new List<FindBestAgentResult>();
        FindBestAgentResult result;

        if(requests.size() == 1)
        {
            for(FindBestAgentRequest request : requests)
            {
                interaction = new GenesysInteractionsService.Interaction();
                interaction = GenesysInteractionsService.findBestAgentFor(request.toInteraction());
                //Añadir a la lista de resultados, el owner Id (email) encontrado
                result = new FindBestAgentResult();
                result.ownerId = interaction.bestAgentId;
                result.screenPopRecordId = interaction.screenPopRecordId;
                results.add(result);
            }
        }
        return results;
    }

    /**
     * Devuelve los identificadores de interacción dados por Genesys Cloud
     */
    public class FindBestAgentResult
    {
        @InvocableVariable(label='Owner Id' description='Email del Usuario de Salesforce (Agente)')
        public String ownerId;
        @InvocableVariable(label='Screen Pop Record Id' description='Screen Pop')
        public String screenPopRecordId;
    }

    /**
     * Recibe los valores que necesita Interaction
     */
    public class FindBestAgentRequest
    {
        @InvocableVariable(label = 'Interaction Type' description='Outbound / Inbound')
        public String interactionType;
        @InvocableVariable(label = 'Look For' description='Opportunity / Case')
        public String lookFor;
        @InvocableVariable(label = 'Scope' description='ámbitos, ej: ze')
        public String scope;
        @InvocableVariable(label = 'From Id' description='FromAddres del EmailMessage')
        public String fromId;

        /**
         * @return Devuelve una interacción en el formato GenesysInteractionsService.Interaction utilizando los datos dados por el flow
         */
        public GenesysInteractionsService.Interaction toInteraction()
        {
            GenesysInteractionsService.Interaction interaction = new GenesysInteractionsService.Interaction();

            interaction.interactionType = this.interactionType;
            interaction.lookFor = this.lookFor;
            interaction.scope = this.scope;
            interaction.fromId = this.fromId;

            return interaction;
        }
    }
}