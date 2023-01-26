public with sharing class GenesysSurveysService {

    public static Integer version { get; set; }

    @TestVisible
    static final String SURVEY_MISSING_FIELDS_REQUIRED = 'Survey: some required fields are missing';
    @TestVisible
    static final String RESPONSE_MISSING_FIELDS_REQUIRED = 'SurveyResponse: some required fields are missing';
    @TestVisible
    static final String INTERACTION_NO_EXIST = 'The survey cannot be created because the interaction task does not exist';

    /**
     * Sirve a WS_GenesysAPIService
     * Hace un upsert de la encuesta y sus respuestas
     * Si no existe una Task cuyo CallObject = interactionId da ERROR
     * @date 17/02/2021
     */
    public static void initSurvey(Survey request)
    {
        //1º-Comprobar si han llegado todos los campos obligatorios
        checkMissingFields(request);

        //2º-Buscar Task.CallObject que sea igual que interactionId, sino ERROR
        Task interactionTask = new Task();
        interactionTask = searchInteractionTask(request);

        //3º-Formar respuesta (si ha venido)
        SurveyResponse__c surveyResponse = new SurveyResponse__c();
        if(String.isNotBlank(request.questionId))
        {
            surveyResponse = createSurveyResponse(request);
        }

        //4º-Formar encuesta
        Survey__c survey = new Survey__c();
        survey = createSurvey(request, interactionTask);

        //5º-Upsert
        upsertSurvey(survey, surveyResponse);

        //6º Si la Survey aún no tiene respuestas creadas, se crean unas vacías
        //Esto sirve para que entren en el TriggerAfter y se procese la cabecera
        firstInsertOfSurvey(survey);
    }

    /**
     * Comprobar si algún campo viene a null y era obligatorio
     * @date 17/02/2021
     */
    public static void checkMissingFields(Survey request)
    {
        //Obligatorios son interactionId y fromId
        if(String.isBlank(request.interactionId) || String.isBlank(request.fromId) || String.isBlank(request.callOriginQueueId) || String.isBlank(request.surveyFlowId) || request.numberOfQuestions == null)
        {
            throw new GenesysSurveysServiceException(SURVEY_MISSING_FIELDS_REQUIRED);
        }

        //Devolver error si se pasó un Id de respuesta pero venían vacios los otros parámetros. La asnwer puede ser null si se queda en silencio/no responde
        if(String.isNotBlank(request.questionId) && (String.isBlank(request.questionType)))
        {
            throw new GenesysSurveysServiceException(RESPONSE_MISSING_FIELDS_REQUIRED);
        }
    }

    /**
     * Buscar Task cuyo CallObject = interactionId y devolverlo
     * @date 17/02/2021
     */
    public static Task searchInteractionTask(Survey request)
    {
        Task interactionTask = new Task();

        List<Task> existingInteractionTasks = new List<Task>();
        existingInteractionTasks = ActivitySelector.selectTasksByCallObjectIdentifier(request.interactionId);

        //si no existe ninguna Task con ese CallObject=interactionId -> ERROR
        if(existingInteractionTasks.isEmpty())
        {
            throw new GenesysSurveysServiceException(INTERACTION_NO_EXIST);
        }else{
            interactionTask = existingInteractionTasks[0];
        }

        return interactionTask;
    }

    /**
     * Formar una SurveyResponse__c a partir de las SurveyResponse
     * @date 17/02/2021
     */
    public static SurveyResponse__c createSurveyResponse(Survey request)
    {
        SurveyResponse__c surveyResponse = new SurveyResponse__c();

        //Crear una Survey con el ExternalId relleno como referencia del Master-Detail
        Survey__c surveyReference = new Survey__c(InteractionId__c = request.interactionId);

        surveyResponse.SurveyId__r = surveyReference; //Master-Detail
        surveyResponse.QuestionId__c = request.questionId; //ExternalId
        surveyResponse.QuestionType__c = request.questionType;
        if(request.answer != null)
        {
            surveyResponse.Answer__c = request.answer.abbreviate(254);
            surveyResponse.LongAnswer__c = request.answer.abbreviate(130999);
        }

        return surveyResponse;
    }

     /**
     * Formar un registro Survey__c a partir del Survey
     * @date 17/02/2021
     */
    public static Survey__c createSurvey(Survey request, Task interactionTask)
    {
        Survey__c survey = new Survey__c();
        survey.InteractionId__c = request.interactionId; //ExternalId
        survey.ANI__c = request.fromId;
        survey.CallOriginQueueId__c = request.callOriginQueueId;
        survey.SurveyFlowId__c = request.surveyFlowId;
        survey.NumberOfQuestions__c = request.numberOfQuestions;

        //jgarciamartinez - 06/04/2022 // nuevos campos para survey
        survey.CDUSUARI__c = request.agentEmail;
        survey.ClaimNumber__c = request.claimNumber;
        survey.VehicleLicensePlate__c = request.licensePlate;
        survey.CustomerNif__c = request.customerNif;

        // arcortazar - 13/09/2022: OCS-3782, incluimos un campo nuevo para cargar desde genesys el TIPENT
        survey.TIPENT__c = request.interactionType;

        //Solo si la task estaba relacionada con un caso
        if(interactionTask.WhatId != null && interactionTask.WhatId.getsObjectType() == Case.sObjectType)
        {
            survey.CaseId__c = interactionTask.WhatId;
        }

        return survey;
    }

    /**
     * Configurar y ejecutar la DML de upsert
     * @date 17/02/2021
     */
    public static void upsertSurvey(Survey__c survey, SurveyResponse__c surveyResponse)
    {
        Schema.SObjectField surveyExternalId = Survey__c.Fields.InteractionId__c;
        Database.UpsertResult surveyResult = Database.upsert(survey, surveyExternalId, false);
        if (!surveyResult.isSuccess())
        {
            throw new GenesysSurveysServiceException(surveyResult.getErrors()[0].getMessage());
        }

        //Si no viene respuesta, se crea solamente la encuesta y nada más
        if(surveyResponse.QuestionId__c != null)
        {
            Schema.SObjectField responseExternalId = SurveyResponse__c.Fields.QuestionId__c;
            Database.UpsertResult responseResult = Database.upsert(surveyResponse, responseExternalId, false);
            if (!responseResult.isSuccess())
            {
                throw new GenesysSurveysServiceException(responseResult.getErrors()[0].getMessage());
            }
        }
    }

     /**
     * Si la Survey aún no tiene respuestas creadas, se crean unas vacías
     * Esto sirve para que entren en el TriggerAfter y se procese la cabecera
     * @date 24/02/2021
     */
    public static void firstInsertOfSurvey(Survey__c survey)
    {
        List<SurveyResponse__c> responsesToInsert = new List<SurveyResponse__c>();

        //1º comprobar si la survey tiene respuestas ya creadas
        List<SurveyResponse__c> surveyresponses = new List<SurveyResponse__c>();
        surveyresponses = [SELECT Id FROM SurveyResponse__c WHERE SurveyId__c = :survey.Id];

        //2º Si la encuesta aún no tiene respuestas, hay que crear unas artificiales
        if(surveyresponses.size() == 0)
        {
            Survey__c surveyReference = new Survey__c(InteractionId__c = survey.InteractionId__c);

            //3º se van creando con Id: SurveyId-1, SurveyId-2, SurveyId-3...
            for(Integer i = 1; i <= survey.NumberOfQuestions__c; i++)
            {
                SurveyResponse__c surveyResponse = new SurveyResponse__c();
                surveyResponse.SurveyId__r = surveyReference; //Master-Detail
                surveyResponse.QuestionId__c = survey.InteractionId__c + '-' + i; //ExternalId
                surveyResponse.QuestionType__c = 'ivr';
                surveyResponse.Answer__c = '';
                surveyResponse.LongAnswer__c = '';
                responsesToInsert.add(surveyResponse);
            }
        }

        //4º insertar las respuestas temporales
        if(responsesToInsert.size()>0)
        {
            Schema.SObjectField responseExternalId = SurveyResponse__c.Fields.QuestionId__c;
            Database.UpsertResult[] responseResults = Database.upsert(responsesToInsert, responseExternalId, false);
            for(Integer index = 0; index < responseResults.size(); index++)
            {
                if (!responseResults[index].isSuccess())
                {
                    throw new GenesysSurveysServiceException('[firstInsertOfSurvey] '+responseResults[index].getErrors()[0].getMessage());
                }
            }
        }
    }

    /**
     * Representa una Survey de Genesys Cloud
     * @date 17/02/2021
     */
    public class Survey
    {
        public String interactionId { get; set; }
        public String fromId { get; set; }
        public String callOriginQueueId { get; set; }
        public String surveyFlowId { get; set; }
        public Integer numberOfQuestions { get; set; }
        public String questionId { get; set; }
        public String questionType { get; set; }
        public String answer { get; set; } //32k caracteres

        //jgarciamartinez - 06/04/2022 // nuevos campos para survey
        public String agentEmail { get; set; }
        public String claimNumber { get; set; }
        public String licensePlate { get; set; }
        public String customerNif { get; set; }

        // arcortazar - 13/09/2022: OCS-3782, incluimos un campo nuevo para cargar desde genesys el TIPENT
        public String interactionType { get; set; }

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    @TestVisible
    class GenesysSurveysServiceException extends Exception {}
}
