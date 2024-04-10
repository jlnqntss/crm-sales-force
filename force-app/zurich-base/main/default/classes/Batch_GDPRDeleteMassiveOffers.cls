/**
 * @description       : Batch para realizar el borrado masivo de ofertas a partir de un criterio que comprueba los
 *                      días transcurridos desde la fecha de creación. La tabla desde la que se hace el criterio viene
 *                      compuesto por el tipo de cuenta a la que se asocia una oferta y la estrucura comercial y entidad
 *                      legal de la propia oferta.
 *                      Existen dos tablas por las que filtrar, una inicial de estructura interna y una mas general.
 *
 * @author            : mfernandezcarrera
 * @group             : Seidor
 * @last modified on  : 02-28-2024
 * @last modified by  : mfernandezcarrera
**/
public class Batch_GDPRDeleteMassiveOffers implements Database.Batchable<Sobject>
{
    /**
     * @description Constructor que acepte el parámetro query
     * @author      mfernandezcarrera | 27/02/2024
     */
    private String query;
    public Batch_GDPRDeleteMassiveOffers(String query)
    {
        // Query recibida por parámetro
        if(!String.isBlank(query))
        {
            this.query = query;
        }
    }

    // La clave se sompone de la entidad legal, el código de estructura y el tipo de cuenta.
    // El valor son los días a partir de los que se tienen que borrar.
    @TestVisible
    private static final Map<String,Integer> INTERNAL_ESTRUCTURE = new Map<String, Integer>
    {
        '0016100F' => 90,   '0016100J' => 1800, '0016200F' => 730,  '0016200J' => 730,  '0016250F' => 730,  '0016250J' => 730,  '0016300F' => 60,
        '0016300J' => 730,  '0016800F' => 90,   '0016800J' => 730,  '0056200F' => 730,  '0056200J' => 730,  '0056250F' => 730,  '0056250J' => 730,
        '0056300F' => 30,   '0056300J' => 730,  '0011950F' => 1800, '0011950J' => 730,  '0011951F' => 1800, '0011951J' => 730,  '0011952F' => 1800,
        '0011952J' => 730,  '0086700F' => 90,   '0086700J' => 730,  '0011006F' => 1800, '0011006J' => 730,  '0011008F' => 1800, '0011008J' => 730,
        '0011009F' => 1800, '0011009J' => 730
    };

    // La clave se sompone de la entidad legal y el tipo de cuenta.
    // El valor son los días a partir de los que se tienen que borrar.
    @TestVisible
    private static final Map<String,Integer> DEFAULT_ESTRUCTURE = new Map<String, Integer>
    {
        '001F' => 60,   '001J' => 730,  '005F' => 30,   '005J' => 30,   '008F' => 90,   '008J' => 730
    };

     /**
    * @description En el start si la variable viene vacía ejecutamos la Query por defecto.
    *              En la que se toman inicialmente todas las ofertas creadas hace 30 días o mas.
    * @author      mfernandezcarrera | 27/02/2024
    */
    public Database.QueryLocator start(Database.BatchableContext bc) 
    {  
        if (query == null || query == '')
        {
            Date firstDateFilter = Date.today().addDays(-30);
            query = 'SELECT CommercialStructureCode__c, Account.Type, CreatedDate, LegalEntity__c FROM Opportunity WHERE CreatedDate <= :firstDateFilter'; 
        }
        
        return Database.getQueryLocator(query);
    }

    /**
     * @desciption  Por cada lote que se ejecute, el procedimiento mirará si la oferta entra dentro
     *              de los criterios de las dos tablas definidas. Si la fecha de creación del registro
     *              es superior en días a los que indica la tabla, se borrará.
     * @author      jgallaga | 27/10/2023
     * @param       List<SObject>
     *              El scope de cada iteración serán ofertas creadas hace al menos 30 días
     ****
     * @modification    
     * @author      mfernandezcarrera | 07/11/2023
     * @description Por cada lote que se ejecute, por un lado mirará si la oferta que está analizando se            
     *              trata de una oferta que no se haya analizado en el método cuyas ofertas son de 
     *              estructura interna. Y por otro lado, mirará si la oferta está dentro de la tabla de 
     *              por defecto.
     *              En caso de que cumpla las dos condiciones, se borrará
     */
    public void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        List<Opportunity> offersToDelete = new List<Opportunity>();

        for(Opportunity opp: (List<Opportunity>) scope)
        {
            if(!addOfferAsInternalEstructureToDelete(opp,offersToDelete) && isOfferDefaultEstructure(opp))
            {
                offersToDelete.add(opp);
            }
        }

        delete offersToDelete;
    }

    public void finish(Database.BatchableContext bc){}

   /**
     * @description Función que busca, a partir de la estructura comercial, entidad legal
     *              y el tipo de cuenta a la que pertenece, si su fecha de creación es mayor o menos a la necesaria
     *              para que se considere para eliminar. Si se encuentra en el mapa, la función devolverá
     *              verdadero para que ningun otra lógica considere la oferta para su eliminación, cumpla o no las
     *              fechas indicadas en el mapa de estructra interna.
     * @author      jgallaga | 27/10/2023
     * @param       Opportunity
     *              El registro de oferta que se desea comprobar.
     * @param       List<Opportunity>
     *              La lista de ofertas que se borrarán.
     * @return      Boolean
     *              Si es true, la oferta se ha encontrado en el mapa de estructura interna
     ****
     * @modification    
     * @author      jgallaga | 07/11/2023
     * @description El método ahora recibe también al lista de ofertas donde se guardan las ofertas a borrar.
     *              Se comprueba si cumple o no la fecha indicada en el mapa para añadirlo a dicha lista.
     *              Después el booleano que se devuelve cambia para indicar unicamente si la clave generada por
     *              esa oferta se encuentra en el mapa o no. Ya que si existe, no debe volverse a considerar para
     *              el resto de casos.
     */
    private boolean addOfferAsInternalEstructureToDelete(Opportunity offer, List<Opportunity> offersToDelete)
    {
        String estructureKey = offer.LegalEntity__c + offer.CommercialStructureCode__c + offer.Account.Type;

        if(! INTERNAL_ESTRUCTURE.containsKey(estructureKey))
        {
            return false;
        }        

        Integer days = INTERNAL_ESTRUCTURE.get(estructureKey);
        Date estructureDate = Date.today().addDays(-days);

        if(offer.CreatedDate <= estructureDate)
        {
            offersToDelete.add(offer);
        }

        return true;
    }

        /**
     * @description Función para determinar si la oferta, a partir de la entidad legal
     *              y el tipo de cuenta a la que pertenece, su fecha de creación es mayor o menos a la necesaria
     *              para que se considere para eliminar.
     * @author      jgallaga | 27/10/2023
     * @param       Opportunity
     *              El registro de oferta que se desea comprobar.
     * @return      Boolean
     *              Si es true, la oferta deberá eliminar.
     */
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