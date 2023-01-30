/**
 *
 * Batch that calculates the conversion rate on the last year's opportunities of the mediators
 * It is executed once a month 
 * 
 * @author lrodriguez
 * @date 19/01/2023
 * 
 **/



global class Batch_RatioConversionIntermediary implements Database.Batchable<sObject>, Schedulable
{

    //Variables

    public String query;

    private String daysToQuery='365';

    private List<Case> allCases= new List<Case>();
   

    /**
    * Constructor por defecto
    * @author lrodriguez6@seidor.es
    * @date 19/01/2023
    */
        public Batch_RatioConversionIntermediary()
        {

        }


        public Batch_RatioConversionIntermediary(String query) 
        {
            // Query recibida por parámetro
            if(!String.isBlank(query))
            {
                this.query = query;
            }
        }

    /**
    * En caso de que no se haya introducido una query en el constructor, se carga la query por defecto
    * @author lrodriguez6@seidor.es
    * @date 11/11/2022
    */
        global Database.QueryLocator start(Database.BatchableContext bc)
        {
            if (query == null || query == '')
            {
                query = new CasesSelector().getQueryStringCasesIntermediaryRatio(daysToQuery);
            }
            
            return Database.getQueryLocator(query);
        }


    /**
    * Método necesario en todas las clases batchable
    * @author lrodriguez6@seidor.es
    * @date 19/01/2023
    */

    global void execute(SchedulableContext sc)
    {
        Database.executeBatch(new Batch_RatioConversionIntermediary(), 200);
    }


    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        if ( scope != null)
        {
            // Se convierte el Scope en casos
            List<Case> allCases = (List<Case>) scope;

                List<Account> accountUpdate= CaseUtil.generateAccountRatio(allCases);
                if(accountUpdate != null && !accountUpdate.isEmpty())
                {
                    // Se actualizan los registros 
                    update accountUpdate;
                }

                    
        }
    }

        global void finish(Database.BatchableContext bc)
        {}

}