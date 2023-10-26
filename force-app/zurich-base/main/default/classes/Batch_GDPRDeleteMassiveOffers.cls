/**
 * @description       :
 * @author            : mfernandezcarrera
 * @group             :
 * @last modified on  : 25/10/2023
 * @last modified by  : jgallaga
**/
public class Batch_GDPRDeleteMassiveOffers implements Database.Batchable<Sobject>
{
    /*
    Creamos un primer mapa de String e Integer,que contiene todos los casos de Estructura.
    String --> EntidadLegal + Código Estructural + Tipo de Cuenta
    Integer --> Número de días
     */
    private static final Map<String,Integer> INTERNAL_ESTRUCTURE = new Map<String, Integer>
    {
        '0016100F' => 90,   '0016100J' => 1800, '0016200F' => 730,  '0016200J' => 730,  '0016250F' => 730,  '0016250J' => 730,  '0016300F' => 60,
        '0016300J' => 730,  '0016800F' => 90,   '0016800J' => 730,  '0056200F' => 730,  '0056200J' => 730,  '0056250F' => 730,  '0056250J' => 730,
        '0056300F' => 30,   '0056300J' => 730,  '0011950F' => 1800, '0011950J' => 730,  '0011951F' => 1800, '0011951J' => 730,  '0011952F' => 1800,
        '0011952J' => 730,  '0086700F' => 90,   '0086700J' => 730,  '0011006F' => 1800, '0011006J' => 730,  '0011008F' => 1800, '0011008J' => 730,
        '0011009F' => 1800, '0011009J' => 730
    };

    /*
    Creamos un segundo mapa de String e Integer,que contiene todos los casos de por defecto.
    String --> EntidadLegal + Código Estructural + Tipo de Cuenta
    Integer --> Número de días
     */
    private static final Map<String,Integer> DEFAULT_ESTRUCTURE = new Map<String, Integer>
    {
        '001F' => 60,   '001J' => 730,  '005F' => 30,   '005J' => 30,   '008F' => 90,   '008J' => 730
    };

    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        /*
        * Coger todas las ofertas con los campos que nos interesas de SF cuya fecha de creación sea minimo de hace a 30 días
        */
        Date firstDateFilter = Date.today().addDays(-30);
        String query = 'SELECT CommercialStructureCode__c, Account.Type, CreatedDate, LegalEntity__c FROM Opportunity WHERE CreatedDate <= :firstDateFilter';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        List<Opportunity> offersToDelete = new List<Opportunity>();

        for(Opportunity opp: (List<Opportunity>) scope)
        {
            if(isOfferAnInternalEstructure(opp))
            {
                offersToDelete.add(opp);
            }
            else if(isOfferDefaultEstructure(opp))
            {
                offersToDelete.add(opp);
            }
        }

        delete offersToDelete;
    }

    public void finish(Database.BatchableContext bc){}

    private boolean isOfferAnInternalEstructure(Opportunity offer)
    {
        String estructureKey = offer.LegalEntity__c + offer.CommercialStructureCode__c + offer.Account.Type;

        if(! INTERNAL_ESTRUCTURE.containsKey(estructureKey))
        {
            return false;
        }

        Integer days = INTERNAL_ESTRUCTURE.get(estructureKey);
        Date estructureDate = Date.today().addDays(-days);

        return offer.CreatedDate <= estructureDate;
    }

    private boolean isOfferDefaultEstructure(Opportunity offer)
    {
        String estructureKey = offer.LegalEntity__c + offer.Account.Type;

        if(! DEFAULT_ESTRUCTURE.containsKey(estructureKey))
        {
            return false;
        }

        Integer days = DEFAULT_ESTRUCTURE.get(estructureKey);
        Date estructureDate = Date.today().addDays(-days);

        return offer.CreatedDate <= estructureDate;
    }
}