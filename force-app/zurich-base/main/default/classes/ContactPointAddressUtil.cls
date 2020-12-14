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

        for(ContactPointAddress ContactPointAddress : newList)
        {
            if( String.isNotBlank(ContactPointAddress.INFOContactPointNumber__c) )
            {
                cpaToGenerateScope.add(ContactPointAddress);
            }
        }

        if( !cpaToGenerateScope.isEmpty() )
        {
            GenerateScopeUtil.generateScopeEvents('ParentId', null, cpaToGenerateScope);
        }
    }
}