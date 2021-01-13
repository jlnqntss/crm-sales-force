public class ContactPointAddressUtil
{
    /**
     * Método que controla la generación del scope correspondiente
     * Actualmente solo se generá scope para ContactPointAddress que provengan de INFO
     *
     * @author adelgado
     * @date 07/12/2020
     */
    public static void generateScope(List<ContactPointAddress> newList)
    {
        List<ContactPointAddress> cpaToGenerateScope = new List<ContactPointAddress>();

        for(ContactPointAddress contactPointAddress : newList)
        {
            if( String.isNotBlank(contactPointAddress.INFOContactPointNumber__c) && contactPointAddress.ScopeId__c == null && contactPointAddress.ParentId != null)
            {
                cpaToGenerateScope.add(contactPointAddress);
            }
        }

        if( !cpaToGenerateScope.isEmpty() )
        {
            GenerateScopeUtil.generateScopeEvents('ParentId', null, cpaToGenerateScope);
        }
    }
}