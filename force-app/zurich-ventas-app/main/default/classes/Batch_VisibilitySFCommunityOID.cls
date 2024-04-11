/**
 * Batch encargado de calcular los Account Team Members (ATMs) que se van a insertar para un usuario nuevo de la comunidad, este batch se ejecuta de forma recursiva
 * en lotes de un tamaño determinado el cual puede configurarse con la variable "numDMLs" para evitar realizar una inserción única que pueda superar el máximo de
 * registros que permite salesforce insertar en el mismo DML. La recursividad parará en caso de error o si no quedasen mas registros que insertar.
 * 
 * @author fpalomo <fpalomo@seidor.es>
 * @date 20/03/2024
 */
global with sharing class Batch_VisibilitySFCommunityOID implements Database.Batchable<sObject>, Database.Stateful
{
    private static final String CLASS_NAME = 'Batch_VisibilitySFCommunityOID';

    
    private Integer numDMLs = 5000;
    Set<AccountTeamMember> pendingATMs;
    Set<AccountTeamMember> pendingATMsToDelete;
    private String intermediaryUserId;
    private String profile;
    private Boolean stopRecusrive = false;

    public Batch_VisibilitySFCommunityOID(Set<AccountTeamMember> pendingATMs, Set<AccountTeamMember> pendingATMsToDelete, String intermediaryUserId)
    {
        this.pendingATMs = pendingATMs;
        this.pendingATMsToDelete = pendingATMsToDelete;
        this.intermediaryUserId = intermediaryUserId;
    }
    
    public Batch_VisibilitySFCommunityOID(String profile, String intermediaryUserId)
    {
        this.pendingATMs = new Set<AccountTeamMember>();
        this.pendingATMsToDelete = new Set<AccountTeamMember>();
        this.intermediaryUserId = intermediaryUserId;
        this.profile = profile;
    }
    /**
     * Clase Wrapper que inicializa las variables invocables necesarias para el método invocable
     * @author nikola.cobian@seidor.com
     * @date 10/04/2024 
     */
    public with sharing class Requests
    {
        @InvocableVariable public String profile;
        @InvocableVariable public String intermediaryUserId;
    }

    /**
     * Método invocable para llamar al Batch desde un flujo Apex
     * @author nikola.cobian@seidor.com
     * @date 10/04/2024
     * @param 
     * @return 
     */
    @InvocableMethod
    public static void batchGenerateATMsInvocableMethod(List<Requests> requests)
    {
        if(requests == null || requests.isEmpty())
        {
            return;
        }
        if((requests[0].profile != null || requests[0].intermediaryUserId != null) && (String.isNotEmpty(requests[0].profile) || String.isNotEmpty(requests[0].intermediaryUserId)))
        {
            Database.executeBatch(new Batch_VisibilitySFCommunityOID(requests[0].profile, requests[0].intermediaryUserId));
        }
    }

    /**
     * Metodo start del batch. Devuelve una lista con el usuario del mediador que recibe el batch.
     * 
     * @author fpalomo <fpalomo@seidor.es>
     * @date 20/03/2024
     */
    global List<User> start(Database.BatchableContext bc)
    {
        return new List<User>{ (new UsersSelector()).findUserIntermediaryByUserId(intermediaryUserId) };
    }

    /**
     * Metodo execute del batch. Decide si debe calcular los ATMs para el mediador o insertarlos de manera recursiva, la primera
     * ejecución del batch siempre debería lanzar el recalculo de ATMs.
     * 
     * @author fpalomo <fpalomo@seidor.es>
     * @date 20/03/2024
     */
    global void execute(Database.BatchableContext bc, List<User> scope)
    {
        try
        {
            if(pendingATMsToDelete != null && !pendingATMsToDelete.isEmpty())
            {
                //Eliminamos los ATMs
                processDelete(pendingATMsToDelete);
            }
            else if (pendingATMs != null && !pendingATMs.isEmpty())
            {
                // Insertamos los ATMs
                processInsert(pendingATMs);
            }
            else
            {
                // Calculamos los ATMs
                calculateIntermediaryATMs(scope[0]);
            }
        }

        catch (Exception e)
        {
            // Si se produce algun error debemos parar la ejecución del batch para que no entre en bucle
            stopRecusrive = true;
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }

    /**
     * Metodo finish del batch. Vuelve a ejecutar el batch (solo insert, no se recalcula nada) si quedan ATMs por insertar.
     * 
     * @author fpalomo <fpalomo@seidor.es>
     * @date 20/03/2024
     */
    global void finish(Database.BatchableContext bc) {
        if ((!pendingATMs.isEmpty() || !pendingATMsToDelete.isEmpty()) && !stopRecusrive)
        {
            Database.executeBatch(new Batch_VisibilitySFCommunityOID(pendingATMs, pendingATMsToDelete, intermediaryUserId));
        }
    }

    /**
     * Metodo que procesa la inserción y prepara los paquetes futuros
     * 
     * @author fpalomo
     * @date 20/03/2024
     */
    private void processInsert(Set<AccountTeamMember> scope) {
        List<AccountTeamMember> toInsert = new List<AccountTeamMember>();
        Set<AccountTeamMember> toFuture = new Set<AccountTeamMember>();

        // Dividimos los ATMs que recibe el metodo en 2:
        // 1. Lote de ATMs "toInsert" son los que mandaremos al DML
        // 2. Lote de ATMs "toFuture" son los que mandaremos al Batch de nuevo para que los vuelva a procesar
        Integer contador = 0;
        for (AccountTeamMember atm: scope) {
            if (contador < numDMLs) {
                toInsert.add(atm);
                contador++;
            } else {
                toFuture.add(atm);
            }
        }

        // Insertamos los ATMs que entran en el lote que acaba de procesarse
        insert toInsert;
        
        // Nos aseguramos que no haya nada en la lista de ATMs pendientes y añadimos los que se insertarán en la siguiente tanda
        pendingATMs.clear();
        pendingATMs = toFuture;
    }

    /**
     * Método que procesa el borrado de ATMs y prepara los paquetes futuros
     * @author nikola.cobian@seidor.com
     * @date 08/04/2024
     * @param Set<AccountTeamMember>
     */
    private void processDelete(Set<AccountTeamMember> scope)
    {
        List<AccountTeamMember> toDelete = new List<AccountTeamMember>();
        Set<AccountTeamMember> toFuture = new Set<AccountTeamMember>();

        // Dividimos los ATMs que recibe el metodo en 2:
        // 1. Lote de ATMs "toDelete" son los que mandaremos al DML
        // 2. Lote de ATMs "toFuture" son los que mandaremos al Batch de nuevo para que los vuelva a procesar
        Integer contador = 0;
        for (AccountTeamMember atm: scope) 
        {
            if (contador < numDMLs) 
            {
                toDelete.add(atm);
                contador++;
            } 
            else 
            {
                toFuture.add(atm);
            }
        }

        // Eliminamos los ATMs que entran en el lote que acaba de procesarse
        delete toDelete;
        
        // Nos aseguramos que no haya nada en la lista de ATMs pendientes y añadimos los que se eliminarán en la siguiente tanda
        pendingATMsToDelete.clear();
        pendingATMsToDelete = toFuture;
    }

    /**
     * Metodo encargado de calcular los ATMs para un mediador en base a los clientes de ofertas y pólizas
     * 
     * @author fpalomo
     * @date 20/03/2024
     */
    private void calculateIntermediaryATMs(User intermediaryUser)
    {
        // Selectores
        PoliciesSelector policiesSelector = new PoliciesSelector();
        OpportunitiesSelector opportunitiesSelector = new OpportunitiesSelector();
        AccountTeamMemberSelector atmsSelector = new AccountTeamMemberSelector();

        List<Opportunity> offers = new List<Opportunity>();
        List<Policy__c> policies = new List<Policy__c>();
        List<AccountTeamMember> atms = new List<AccountTeamMember>();

        //DELETE ATMs: seleccionamos los ATMs a borrar
        atms = atmsSelector.findATMsForIntermediariesByUserId(new Set<String>{intermediaryUser.Id});

        //DELETE ATMs: recorremos el resultado de la búsqueda para añadirlos a los ATMs a eliminar
        pendingATMsToDelete.addAll(atms);


        // Obtenemos las ofertas y pólzas para el mediador según su perfil
        if (profile.equals('Agente Ventas'))
        {
            policies = policiesSelector.selectByIntermediaryId(new Set<String> { intermediaryUser.contact.AccountId });
            offers = opportunitiesSelector.getIntermediaryOtherOffers(new Set<String>(), intermediaryUser.Contact.Account);
        }
        else if (profile.equals('Agente Ventas - AGR'))
        {
            policies = policiesSelector.selectByIntermediaryGroupId(new Set<String> { intermediaryUser.contact.Account.IntermediaryGroup__c });
            offers = opportunitiesSelector.getIntermediaryOtherOffers(new Set<String>(), intermediaryUser.Contact.Account);
        }

        // Recorremos las pólizas y generamos los ATMs para los account de las mismas
        for (Policy__c policy : policies)
        {
            pendingATMs.add(AccountTeamMemberUtil.createATMZRMRecord(policy.PolicyHolder__c, intermediaryUser.Id));
        }
        
        // Recorremos las Ofertas y generamos los ATMs para los account de las mismas
        for (Opportunity offer : offers)
        {
            pendingATMs.add(AccountTeamMemberUtil.createATMZRMRecord(offer.AccountId, intermediaryUser.Id));
        }
    }
}