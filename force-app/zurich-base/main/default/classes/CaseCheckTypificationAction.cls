/**
 * Acción invocable que llama a la lógica que comprueba si cierta tipificación está disponible para 
 * un Record Type concreto
 * 
 * @author arcortazar
 * @date 13/02/2023
 */
public with sharing class CaseCheckTypificationAction {
    @InvocableMethod(
        label='Check typification'
        description='Check if certain typification is available for the given record type ID'
        category='Other'
    )
    public static List<CheckTypificationResponse> checkTypification(List<CheckTypificationRequest> typificationRequests)
    {
        List<CheckTypificationResponse> results = new List<CheckTypificationResponse>();
        
        if(typificationRequests != null && !typificationRequests.isEmpty())
        {
            for(CheckTypificationRequest typifReq : typificationRequests)
            {
                CheckTypificationResponse reponse = new CheckTypificationResponse();
                if (typifReq.TypeN1 != null  && typifReq.TypeN1 != ''
                    && typifReq.TypeN2 != null  && typifReq.TypeN2 != ''
                    && typifReq.TypeN3 != null  && typifReq.TypeN3 != '')
                    {
                        reponse.isValid = CaseUtil.checkTypificationByRecordType(typifReq.TypeN1, typifReq.TypeN2, typifReq.TypeN3, typifReq.RecordTypeId);
                    }
                    else {
                        reponse.isValid = false;

                    }


                results.add(reponse);
            }
        }
        return results;
    }

    public class CheckTypificationRequest
    {
        @InvocableVariable(
            label='Type'
            description='Type N1'
        )
        public String TypeN1;

        @InvocableVariable(
            label='Subtype'
            description='Type N2'
        )
        public String TypeN2;

        @InvocableVariable(
            label='TypeN3'
            description='Type N3'
        )
        public String TypeN3;

        @InvocableVariable(
            label='Record type ID'
            description='Record type ID'
            required=true
        )
        public Id RecordTypeId;

    }

    public class CheckTypificationResponse
    {
        @InvocableVariable(label='IsAvailable' description='Booleando que indica si la tipificación está disponible o no')
        public Boolean isValid;
    }
}