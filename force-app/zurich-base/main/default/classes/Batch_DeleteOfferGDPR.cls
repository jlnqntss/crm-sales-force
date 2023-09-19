/**
 * @author mfernandezcarrera
 * Batch para borrar todas las ofertas cuya fecha de creación supere ciertos días
 * @date 26/06/2023
 */

 global class Batch_DeleteOfferGDPR implements Database.Batchable<sObject>, Database.Stateful, Schedulable
 {
    private static final List<GDPR_OfferDeletion__mdt>  borradoOfertas = SystemUtil.getOfferDeletionMetadata();
    private static List<String> ramos=new List<String>();
    private static Date fechaFisicaMinimaGDPR;
    private static Date fechaJuridicaMinimaGDPR;
    private static Map<String,GDPR_OfferDeletion__mdt> ramosMap= new Map<String,GDPR_OfferDeletion__mdt>();
    
    /**
    *Preparamos la información inicial
    *Ramos del metadato, ramo con el resto de su información, y el menor de los valores de fisica y juridica. 
    *Llamando al metodo numberDays, para rellener esos valores
    */
    private static void loadInitialData()
    {
      if(borradoOfertas !=null)
      {
        for(GDPR_OfferDeletion__mdt offerDeletion: borradoOfertas)
        {
            ramos.add(offerDeletion.Ramo__c.toPlainString());
            ramosMap.put(offerDeletion.Ramo__c.toPlainString(),offerDeletion);

            if(fechaFisicaMinimaGDPR == null || numberDays(offerDeletion.Fisica__c)>fechaFisicaMinimaGDPR )
            {
                fechaFisicaMinimaGDPR = numberDays(offerDeletion.Fisica__c);
            }

            if(fechaJuridicaMinimaGDPR == null || numberDays(offerDeletion.Juridica__c)>fechaJuridicaMinimaGDPR )
            {
                fechaJuridicaMinimaGDPR = numberDays(offerDeletion.Juridica__c);
            }
        }
       }
    }

    /**
    *Método al que le pasamos los valores fisica o juridica del metadato, para quedarnos con el valor númerico.
    *Saber si se trata de un año o día, para ello fijandonos en la letra.
    */
    private static Date numberDays(String fecha)
    {
        Date fechaLimite;
        if(fecha.contains('A'))
        {
            Integer year = Integer.valueOf(fecha.split('A').get(0));
            fechaLimite = Date.today().addYears(-year);  
        }
        else if (fecha.contains('D')) 
        {
            Integer days = Integer.valueOf(fecha.split('D').get(0));
            fechaLimite = Date.today().addDays(-days);
        }
        return fechaLimite;
    }

    /**
    *Nos traemos las ofertas de ZE, que su CommercialStructureCode__c esté en la lista de Ramos 
    *y con la fecha de creación minima en base al metadato, tanto para física como para jurídica.
    *Para despúes devolver un listado de Ids de las ofertas que nos interesan borrar.
    */
    private static List<Id> checkMetadata ()
    {
        List<Id> idsToQuery= new List<Id>();
        List<Opportunity> ofertas = [
            SELECT Id, Name, Scope__c, CommercialStructureCode__c,Account.Type, CreatedDate
            FROM Opportunity
            WHERE Scope__c = 'ZE' AND CommercialStructureCode__c IN: ramos AND 
            ((Account.Type='F' AND CreatedDate<:fechaFisicaMinimaGDPR) OR(Account.Type='J'AND CreatedDate<:fechaJuridicaMinimaGDPR))
        ];
        
        for(Opportunity opp:ofertas)
        {
            GDPR_OfferDeletion__mdt metadatoRecord= ramosMap.get(opp.CommercialStructureCode__c);

            if(opp.CreatedDate<numberDays(metadatoRecord.Fisica__c) && opp.Account.Type == 'F')
            {
               idsToQuery.add(opp.Id);
            }
            
            else if(opp.CreatedDate<numberDays(metadatoRecord.Juridica__c) && opp.Account.Type == 'J')
            {
               idsToQuery.add(opp.Id);
            }   
        }
        return idsToQuery;
    }
    /**
    *Hacemos la query a la BD para traernos todas las ofertas que hay en SF cuyo Id estén en la lista que devolvemos en el checkMetadata() 
    */
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        loadInitialData();
        List<Id> idsToQueryOffer= checkMetadata();

        if(idsToQueryOffer.isEmpty()== False)
        {
            return Database.getQueryLocator('SELECT Id From Opportunity WHERE Id IN: idsToQueryOffer');
        }
            return Database.getQueryLocator('SELECT Id FROM Opportunity WHERE Id = null');
    }

    global void execute(SchedulableContext sc)
    {
        Database.executeBatch(new Batch_DeleteOfferGDPR(), 400);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        List<Opportunity> offers = (List<Opportunity>) scope;

            Database.DeleteResult[] resultadoBorrado = Database.delete(offers, false);

            for(Database.DeleteResult dr : resultadoBorrado) {
                if (!dr.isSuccess()) {
                    // Borrado exitoso, se obtiene el ID del registro que se ha procesado
                    ErrorLogUtil.commitError(dr, 'Batch_DeleteOfferGDPR','execute','Opportunity');
                }
            }
    }
 
    global void finish(Database.BatchableContext bc)
    {
        Batch_DeleteAccounts instanciaCuenta= new Batch_DeleteAccounts();
        database.executeBatch(instanciaCuenta);
    }
 }