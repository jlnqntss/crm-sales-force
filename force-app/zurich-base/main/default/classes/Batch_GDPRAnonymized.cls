/**
 * @description     : Batch para eliminar los objetos de la jerarquía según mande INFO
 * @author          : amunoz
 * @group:
 * @last modified on:
 * @last modified by:
 */
global class Batch_GDPRAnonymized implements Database.Batchable<sObject>, Schedulable{

    global String currentSobject, nextSobject;
    private static Map<Integer,Map<Integer,String>> mapOrderAnonymized;

    global Batch_GDPRAnonymized(String currentSobject, String nextSobject) {
        if (mapOrderAnonymized == null)
        {
            mapOrderAnonymized = GDPRComplianceUtil.loadSetting('Account');        
        }

        if (!String.isBlank(currentSobject))
        {
            this.currentSobject = currentSobject;
        }else
        {
            this.currentSobject = GDPRComplianceUtil.getLastObject(mapOrderAnonymized);
        }

        if (!String.isBlank(nextSobject) || currentSobject=='Account')
        {
            this.nextSobject = nextSobject;
        }else
        {
            String siguiente = GDPRComplianceUtil.getNextObject(mapOrderAnonymized, this.currentSobject);
            this.nextSobject = siguiente;
        }
    }

    /**
     * @description Método execute del scheduler
     */
    global void execute(SchedulableContext sc)
    {
        System.debug('Current object:' + currentSobject);
        System.debug('Next Object:' + nextSobject);
        database.executeBatch( new Batch_GDPRAnonymized(currentSobject, nextSobject), 200 );
        
    }

    /**
     * @description Método start del Batch, obtiene todas las cuentas con el campo Anonymiced a True
     */
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        //Query para obtener los objetos dependientes de la cuenta para borrar
        //SELECT Id,Name FROM currentSObject WHERE Anonymiced=TRUE and RelationID = AccountId
        System.debug('Query Opp: ' + [SELECT Id, Anonymized__c, Account.Anonymized__c FROM Opportunity]);

        String query;
        query = GDPRComplianceUtil.queryFactoryBorrado(currentSobject);
        System.debug('String query: '+query);
        System.debug('Start: ' + Database.query(query).isEmpty());
        return Database.getQueryLocator(query);
    }

    /**
     * @description Método execute del Batch
     */
    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        //El metodo process se encargará de recorrer el scope teniendo en cuenta el currentSobject actual del batch
        //Procesar el objeto que hay que borrar
        //GDPRComplianceUtil.processBorrado(scope, currentSobject);
        system.debug('execute: currentobject: ' + currentSobject);
        System.debug('Execute Scope: ' + scope);
        GDPRComplianceUtil.processAnonimizar(scope, currentSobject);
        system.debug(scope);
    }

    /**
     * @description Método finish del Batch
     */
    global void finish(Database.BatchableContext bc)
    {
        //Según lo que comenta Joseba, los batch tienen un límite de 50000 registros cuando se trata de borrado
        //En principio el batch no deberia de tener problema con el limite del borrado
        system.debug('finish');

        String futureNextObject = null;
        String futureCurrentObject = nextSobject;

        if(nextSobject != 'Account' && !String.isBlank(nextSobject))
        {
            System.debug('Finish pre Account');
            System.debug(nextSobject);
            futureNextObject = GDPRComplianceUtil.getNextObject(GDPRComplianceUtil.loadSetting('Account'), futureCurrentObject);
            GDPRComplianceUtil.postProcessAnonymized(futureCurrentObject, futureNextObject);
        }else if(nextSobject == 'Account')
        {
            System.debug('Finish cuando es igual a Account');
            GDPRComplianceUtil.postProcessAnonymized(futureCurrentObject, '');
        }

    }
}