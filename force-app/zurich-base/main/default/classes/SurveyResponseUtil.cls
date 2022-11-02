public with sharing class SurveyResponseUtil
{

    public static Map<Id, Map<Integer,SurveyResponse__c> > allResponsesMap = new Map<Id, Map<Integer,SurveyResponse__c> >();
    public static Map<Id, Survey__c> surveysToUpdate = new Map<Id, Survey__c>();

    /**
     * BULKAFTER
     * Inicializa un mapa de respuestas
     * La clave es el Id de la Survey Padre
     * A su vez contendrá un mapa (mejor que una lista para evitar duplicados) con las respuestas
     * cuya clave será la position (questionId: surveyId-position)
     * para que luego sea más fácil su ordenación
     * Como hay que fusionar las respuestas anteriores + las que acaban de entrar en el trigger,
     * las que prevalecen son las que se actualizan en el trigger
     *
     * @date 24/02/2021
     */
    public static void initMapOfResponses(List<SurveyResponse__c> newList, Map<Id, SurveyResponse__c> oldMap)
    {
        //1º conseguir el listado de Survey Padres que van a ser actualizados
        Set<Id> surveyIds = new Set<Id>();
        for(SurveyResponse__c sr: newList)
        {
            surveyIds.add(sr.SurveyId__c);
        }

        //2º Conseguir el listado de respuestas que ya tienen esas encuestas (como es After: la soql recupera también las que se acaban de insert/updatear)
        List<SurveyResponse__c> surveyresponses = new List<SurveyResponse__c>();
        surveyresponses = [SELECT Id, SurveyId__c, QuestionId__c, QuestionType__c, Answer__c, LongAnswer__c FROM SurveyResponse__c WHERE SurveyId__c IN :surveyIds];

        //3º crear un mapa que agrupe las respuestas de cada encuesta padre
        Map<Integer, SurveyResponse__c> responsesMap = new Map<Integer,SurveyResponse__c>();
        List<String> parts = new List<String>();
        for(Id surveyId: surveyIds)
        {
            //Inicializar mapa en cada iteración
            responsesMap = new Map<Integer,SurveyResponse__c>();
            for(SurveyResponse__c response: surveyresponses)
            {
                //Si coincide con la Survey padre de la iteración, se mete al map
                if(response.SurveyId__c == surveyId && response.QuestionId__c != null)
                {
                    //obtener position si QuestionId está estructurado correctamente
                    parts = new List<String>();
                    parts = response.QuestionId__c.split('-');
                    if(parts.size() > 1)
                    {
                        Integer i = parts.size() == 1 ? 1 : parts.size() - 1;
                        Integer position = Integer.valueOf( parts.get(i) );
                        responsesMap.put(position,response);
                    }
                }
            }
            //rellenar el mapa global de respuestas
            allResponsesMap.put(surveyId,responsesMap);
        }
    }

    /**
     * AFTERINSERT AFTERUPDATE
     * actualiza los campos shortanswersprocessed__c, longAnswerProcessed__c de las Surveys padre
     * las respuestas ivr van concatenadas ej: 1;NULL;3;NULL;NULL
     * la respuesta asr va en el Long text área
     *
     * @date 24/02/2021
     */
    public static void processAnswers()
    {
        Survey__c surveyToUpdate = new Survey__c();

        //1º Por cada survey padre
        for( Id surveyId: allResponsesMap.keySet() )
        {
            Map<Integer,SurveyResponse__c> responsesOfSurvey = allResponsesMap.get(surveyId);

            //2º inicializar la survey padre
            surveyToUpdate = new Survey__c();
            String shortAnswer = '';
            String longAnswer = '';

            //Ordenar las respuestas
            Set<Integer> setPositions = responsesOfSurvey.keySet();
            List<Integer> positions = new List<Integer>(setPositions);
            positions.sort();

            //Por cada respuesta, procesarla según su tipo
            for(Integer position: positions)
            {
                SurveyResponse__c response = responsesOfSurvey.get(position);
                if(response.QuestionType__c == 'asr')
                {
                    longAnswer = response.LongAnswer__c;
                }
                else if(response.QuestionType__c == 'ivr')
                {
                    if( String.isBlank(response.Answer__c) )
                    {
                        shortAnswer = shortAnswer + 'NULL;';
                    }
                    else
                    {
                        shortAnswer = shortAnswer + response.Answer__c + ';';
                    }
                }
            }

            //Rellenar cabecera Survey
            surveyToUpdate.Id = surveyId;
            surveyToUpdate.ShortAnswersProcessed__c = shortAnswer.abbreviate(255);
            surveyToUpdate.LongAnswerProcessed__c = longAnswer;
            surveysToUpdate.put(surveyToUpdate.Id, surveyToUpdate);
        }
    }

    /**
     * ANDFINALLY
     * actualiza los registros de encuestas padre relacionados
     *
     * @date 24/02/2021
     */
    public static void updateParentSurveys()
    {
        System.debug(surveysToUpdate);
        List<Survey__c> surveys = new List<Survey__c>();
        surveys = surveysToUpdate.values();

        if( !surveys.isEmpty() )
        {
            try
            {
                update surveys;
            }
            catch(Exception ex)
            {
                ErrorLogUtil.commitError(ex,'SurveyResponseUtil', 'updateParentSurveys');
            }
        }
    }

}
