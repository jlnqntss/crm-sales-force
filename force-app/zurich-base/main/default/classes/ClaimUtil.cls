public class ClaimUtil {
    
    /**
     * Método que controla la generación del scope correspondiente
     * Actualmente solo se generá scope para pólizas que provengan de INFO
     *
     * @author nts (agonzalezisasi)
     * @date 18/02/2021
     */
    public static void generateScope(List<Claim__c> newList)
    {
        List<Claim__c> polToGenerateScope = new List<Claim__c>();

        for(Claim__c claim : newList) {
            if( String.isNotBlank(claim.Policy__c) && claim.Scope__c == null ) {
                polToGenerateScope.add(claim);
            }
        }

        if( !polToGenerateScope.isEmpty() ) {
            GenerateScopeUtil.generateScopeEvents(
                Claim__c.Scope__c.getDescribe().getName(), 
                Claim__c.Policy__c.getDescribe().getName(),
                Policy__c.getSObjectType().getDescribe().getName(), 
                Policy__c.Scope__c.getDescribe().getName(),
                polToGenerateScope
            );
        }
    }
}
