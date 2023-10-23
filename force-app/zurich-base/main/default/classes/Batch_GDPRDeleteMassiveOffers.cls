/**
 * @description       : 
 * @author            : mfernandezcarrera
 * @group             : 
 * @last modified on  : 10-23-2023
 * @last modified by  : mfernandezcarrera
**/
public class Batch_GDPRDeleteMassiveOffers 
{
    /*
    Creamos un primer mapa de String e Integer,que contiene todos los casos de Estructura.
    String --> EntidadLegal + Código Estructural + Tipo de Cuenta
    Integer --> Número de días
     */ 
    private static Map<String,Integer> internalEstructureMap= new Map<String, Integer>
    {
        '0016100F'=>90,'0016100J'=>1800,'0016200F'=>730,'0016200J'=>730,'0016250F'=>730,'0016250J'=>730,'0016300F'=>60,
        '0016300J'=>730,'0016800F'=>90,'0016800J'=>730,'0056200F'=>730,'0056200J'=>730,'0056250F'=>730,'0056250J'=>730,
        '0056300F'=>30,'0056300J'=>730,'0011950F'=>1800,'0011950J'=>730,'0011951F'=>1800,'0011951J'=>730,'0011952F'=>1800,
        '0011952J'=>730,'0086700F'=>90,'0086700J'=>730,'0011006F'=>1800,'0011006J'=>730,'0011008F'=>1800,'0011008J'=>730,
        '0011009F'=>1800,'0011009J'=>730
    };
     /*
    Creamos un segundo mapa de String e Integer,que contiene todos los casos de por defecto.
    String --> EntidadLegal + Código Estructural + Tipo de Cuenta
    Integer --> Número de días
     */ 
    private static Map<String,Integer> defaultMap= new Map<String, Integer>
    {
        '001F'=>60,'001J'=>730,'005F'=>30,'005J'=>30,'008F'=>90,'008J'=>730
    };
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
    /*
    * Coger todas las ofertas con los campos que nos interesas de SF cuya fecha de creación sea minimo de hace a 30 días
    */
        return Database.getQueryLocator('SELECT Id, CommercialStructureCode__c,Account.Type, CreatedDate, LegalEntity__c FROM Opportunity WHERE CreatedDate <= Date.today().addDays(-30)');
    }
    global void execute(SchedulableContext sc)
    {
        Database.executeBatch(new Batch_GDPRDeleteMassiveOffers(), 400);
    }
    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        List<Opportunity> offers = (List<Opportunity>) scope;
        List<Opportunity> offersToDelete = new List<Opportunity>();
        // Miramos que no viene vacio ni nulo el execute
        if ( scope != null && !scope.isEmpty() )
        {
            // 1- Para cada oportunidad que viene, miramos primero si su concatenación de los campos está en el mapa de estructura
            for(Opportunity opp:offers)
            {
                if(internalEstructureMap.contains(opp.LegalEntity__c+opp.CommercialStructureCode__c+opp.Account.Type))
                {
                    Integer daysMapEstructure = internalEstructureMap.get(Integer);
                    Date createdDateStructure = opp.CreatedDate;
                    Date todayDate = System.Today();
                    Integer numberDaysDue = createdDateStructure.daysBetween(todayDate);
                    /*En el caso en el que esté, miramos si la diferencia de días es mayor o menor a la del mapa.
                    * Si es mayor o igual añadimos a la lista de ofertas a borrar
                    */
                    if(numberDaysDue>=daysMapEstructure)
                    {
                        offersToDelete.add(opp.Id);
                    }
                }
                //2- Si esa oferta no es de estructura, venimos al de por defecto y la buscamos si se encuentra en el mapa correspondiente
                else if (defaultMap.contains(opp.LegalEntity__c+opp.Account.Type))
                {
                    Integer daysMapDefault = defaultMap.get(Integer);
                    Date createdDateDefault = opp.CreatedDate;
                    Date todayDate = System.Today();
                    Integer numberDays = createdDateDefault.daysBetween(todayDate);
                    /*En el caso en el que esté, miramos si la diferencia de días es mayor o menor a la del mapa.
                    * Si es mayor o igual añadimos a la lista de ofertas a borrar
                    */
                    if(numberDays>=daysMapDefault)
                    {
                        offersToDelete.add(opp.Id);
                    }
                }
            }//Falta por hacer la llamada a BD para el delete
        }
    }
    public Batch_GDPRDeleteMassiveOffers(){} 
}