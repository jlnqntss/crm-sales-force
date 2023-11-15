global with sharing class Batch_LeadOffersToReassignToCC implements Database.Batchable<sObject>,Schedulable
{
    Id defaultUserCC;
    Set<String> userAndAccountIds;
    Set<Id> userIds;
    Set<Id> accountIds;

    public Batch_LeadOffersToReassignToCC() 
    {
        userAndAccountIds = new Set<String>();
        userIds = new Set<Id>();
        accountIds = new Set<Id>();
    }

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        //Ejecuta la query de registros a procesar del batch: 
        return Database.getQueryLocator((new OpportunitiesSelector()).findZRMtoReassign());
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> scope)
    {
        // 1.- Obtenemos el usuario generico
        String aliasCCUser = Lead_Offers__c.getinstance().ContactCenterUser__c;
        if(String.isNotBlank(aliasCCUser))
        {
            UsersSelector userQuery = new UsersSelector();
            List<User> defaultUser = userQuery.findUsersByAlias(new List<String>{aliasCCUser});

            if(! defaultUser.isEmpty())
            {
                defaultUserCC = defaultUser.get(0).id;
            }
        }

        // 2.- Recorremos las oportunidades y actualizamos información

        List<CallMeBackUtil.CallMeBackFull> cmbToInsert = new List<CallMeBackUtil.CallMeBackFull>();
        for(Opportunity opp : scope)
        {
            // Guardamos datos de la opp
            userAndAccountIds.add(opp.OwnerId+'#'+opp.AccountId);
            userIds.add(opp.OwnerId);
            accountIds.add(opp.AccountId);

            // Actualizamos la opp
            opp.OwnerId = defaultUserCC;
            opp.BusinessCode__c = Lead_Offers__c.getinstance().BusinessCode__c;
            opp.CloseDate = Date.today() + (Integer)Lead_Offers__c.getinstance().DaysToReassignOffer__c;


            // Creamos CMB
            CallMeBackUtil.CallMeBack cmb = new CallMeBackUtil.CallMeBack();
            cmb.name = opp.Account.Name;
            cmb.phone = opp.Account.Phone;
            cmb.bestTimeFrom = DateTime.newInstance(Date.Today(), opp.Account.PreferedContactStart__c.time());
            cmb.bestTimeUntil = DateTime.newInstance(Date.Today(), opp.Account.PreferedContactEnd__c.time());
            cmb.webIdentifier = opp.Account.WebId__c;
            cmb.businessCode = Lead_Offers__c.getinstance().BusinessCode__c;

            // Completamos el objeto con el resto de la información
            CallMeBackUtil.CallMeBackFull cmbFull = new CallMeBackUtil.CallMeBackFull();
            cmbFull.request = cmb;
            cmbFull.queueName = Lead_Offers__c.getinstance().VoiceQueue__c;
            cmbFull.businessHoursName = Lead_Offers__c.getinstance().BusinessHour__c;

            cmbToInsert.add(cmbFull);
        }

        // 3.- Update de Optys
        update scope;

        // 4.- Insertamos las CMB
        CallMeBackUtil.insertCallMeBack(cmbToInsert);

        // 5.- Obtiene si los Mediadores desasignados tienen otras Ofertas con los mismos Leads
        List<Opportunity> lstOpportunities = (new OpportunitiesSelector()).findByAccountAndOwner(this.accountIds, this.userIds);
        if(!lstOpportunities.isEmpty() && lstOpportunities != null)
        {
            for(Opportunity opp : lstOpportunities)
            {
                String toCheck = opp.OwnerId+'#'+opp.AccountId;
                if(userAndAccountIds.contains(toCheck))
                {
                    userAndAccountIds.remove(toCheck);
                }
            }
        }

        // 6.- Elimina los registros de AccountTeamMember correspondientes a los agentes desasignados y sus antiguos Leads
        List<AccountTeamMember> lstATMtoDelete = new List<AccountTeamMember>();
        List<AccountTeamMember> lstAccountTeamMembers = (new AccountTeamMemberSelector()).findByAccountAndUser(this.accountIds, this.userIds);
        if(!lstAccountTeamMembers.isEmpty() && lstAccountTeamMembers != null)
        {
            for(AccountTeamMember atm : lstAccountTeamMembers)
            {
                String toCheck = atm.UserId+'#'+atm.AccountId;
                if(userAndAccountIds.contains(toCheck))
                {
                    lstATMtoDelete.add(atm);
                }
            }
        }
        delete lstATMtoDelete;
    }

    global void execute(SchedulableContext sc)
    {
        database.executeBatch(new Batch_LeadOffersToReassignToCC(), 10);
    }

    global void finish(Database.BatchableContext bc) 
    {}
}