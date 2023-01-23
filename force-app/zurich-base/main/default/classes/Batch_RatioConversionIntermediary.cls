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

private String daysToQuery='1';

//private static final string      statusClosed     =  'Closed';
//private static final string      statusCombinado  =  'Combinado';

private List<Case> allCases= new List<Case>();
private List<Account> allIntermediary= new List<Account>();

Map <Id, Decimal> mapAllIntermediaryCases= new Map <Id,Decimal>();
Map <Id, Decimal> mapWonIntermediaryCases= new Map <Id,Decimal>();

Integer ratio;




/**
* Constructor por defecto
* @author lrodriguez6@seidor.es
* @date 19/01/2023
*/
public Batch_RatioConversionIntermediary()
{

}

///////////////////////////////////////////////////////

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
//////////////////////////////////
    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        if ( scope != null && !scope.isEmpty() )
        {
            // Se convierte el Scope en casos
            List<Case> allCases = (List<Case>) scope;
            System.debug('NUMERO DE CASOS: '+allCases.size());
           /* try
            {*/
                for(Case currentCase:allCases)
                {   System.debug('VALOR DEL MAPA ALL: '+mapAllIntermediaryCases.get(currentCase.AccountId));

                    if(mapAllIntermediaryCases.get(currentCase.AccountId)==null)
                    {
                        mapAllIntermediaryCases.put(currentCase.AccountId,0);
                        System.debug('ES NULO');
                    }
                    mapAllIntermediaryCases.put(currentCase.AccountId,(mapAllIntermediaryCases.get(currentCase.AccountId)+1));
                    
                    System.debug('ACABO DE SUMARLE UNO:---->:'+mapAllIntermediaryCases.get(currentCase.AccountId));


                    if(currentCase.QuotationStage__c=='Won')
                    {
                        if(mapWonIntermediaryCases.get(currentCase.AccountId)==null)
                        {                               
                            mapWonIntermediaryCases.put(currentCase.AccountId,0);
                            System.debug('HE PUESTO A CERO MAP WON');
                        }
                        
                        mapWonIntermediaryCases.put(currentCase.AccountId,(mapWonIntermediaryCases.get(currentCase.AccountId)+1));
                        System.debug('MAS UNO EN GANADAS: '+(mapWonIntermediaryCases.get(currentCase.AccountId)));

                    }
                }

                allIntermediary= [SELECT USPConversionRatio__c FROM Account WHERE Id=:mapAllIntermediaryCases.keySet()];

                for(Account acc: allIntermediary)
                {
                    //if(mapWonIntermediaryCases.get(acc.Id)!=null)
                    //{  
                        Decimal num= mapWonIntermediaryCases.get(acc.Id);
                        Decimal den= mapAllIntermediaryCases.get(acc.Id);
                        Decimal res;
                        res= num/den;
                        System.debug('RES: '+res);
                        System.debug('Valores de la división: '+mapWonIntermediaryCases.get(acc.Id)/mapAllIntermediaryCases.get(acc.Id));
                        acc.USPConversionRatio__c=(mapWonIntermediaryCases.get(acc.Id)/mapAllIntermediaryCases.get(acc.Id));
                        System.debug('conversion : '+acc.USPConversionRatio__c);
                  //  }
                    
                }


                update allIntermediary;
                
          /*  }
            catch (Exception ex)
            {
                ErrorLogUtil.commitError(ex, 'Batch_RatioConversionIntermediary');
            }*/
        }
    }

    global void finish(Database.BatchableContext bc)
    {}

}
/*
    //Inicializar 

    allCases                = new List<Case>();
    allIntermediary         = new List<Account>();
    mapAllIntermediaryCases = new Map <Id,Integer>();
    mapWonIntermediaryCases = new Map <Id,Integer>();

    //allCases= [SELECT Status,AccountId FROM Case WHERE Status!=: statusClosed AND Status!=: statusCombinado AND CreatedDate=LAST_N_DAYS:365];

   for(Case currentCase:allCases)
   {
    mapAllIntermediaryCases.put(currentCase.AccountId,+1);

    if(currentCase.Status=='Won')
    {
        mapWonIntermediaryCases.put(currentCase.AccountId,+1);
    }
   }

   allIntermediary= [SELECT USPConversionRatio__c FROM Account WHERE Id=:mapAllIntermediaryCases.keySet()];

   for allIntermediary

}*/












