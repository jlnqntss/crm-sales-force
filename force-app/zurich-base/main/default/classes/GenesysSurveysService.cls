public without sharing class GenesysSurveysService {

    public static Integer version { get; set; }

    @TestVisible
    static final String MISSING_FIELDS_REQUIRED = 'Survey: some required fields are missing';
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

        //3º-Formar lista de respuestas
        SurveyResponse__c surveyResponse = new SurveyResponse__c();
        surveyResponse = createSurveyResponse(request);

        //4º-Formar encuesta
        Survey__c survey = new Survey__c();
        survey = createSurvey(request, interactionTask);

        //5º-Upsert
        upsertSurvey(survey, surveyResponse);
    }

    /**
     * Comprobar si algún campo viene a null y era obligatorio
     * @date 17/02/2021
     */
    public static void checkMissingFields(Survey request)
    {
        if(String.isBlank(request.interactionId) || String.isBlank(request.fromId) || String.isBlank(request.questionId) || String.isBlank(request.questionType) || String.isBlank(request.answer))
        {
            throw new GenesysSurveysServiceException(MISSING_FIELDS_REQUIRED);
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
        surveyResponse.Answer__c = request.answer.abbreviate(254);
        surveyResponse.LongAnswer__c = request.answer.abbreviate(130999);

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
        Schema.SObjectField responseExternalId = SurveyResponse__c.Fields.QuestionId__c;

        Database.UpsertResult surveyResult = Database.upsert(survey, surveyExternalId, false);
        if (!surveyResult.isSuccess())
        {
            throw new GenesysSurveysServiceException(surveyResult.getErrors()[0].getMessage());
        }

        Database.UpsertResult responseResult = Database.upsert(surveyResponse, responseExternalId, false);
        if (!responseResult.isSuccess())
        {
            throw new GenesysSurveysServiceException(responseResult.getErrors()[0].getMessage());
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
        public String questionId { get; set; }
        public String questionType { get; set; }
        public String answer { get; set; } //32k caracteres

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    @TestVisible
    class GenesysSurveysServiceException extends Exception {}
}
