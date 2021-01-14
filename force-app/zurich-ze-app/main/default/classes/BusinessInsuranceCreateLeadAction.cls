/**
 * Accióp invocable para ejecutar la lógica de creación de Lead
 * del formulario de Zurich Empresas desde un Flow
 * 
 * @author rlopez
 * @date 30/12/2020
 */
global with sharing class BusinessInsuranceCreateLeadAction {

    @InvocableMethod(
        label='Create Lead'
        description='Creates a Lead, Contact Points and Scope with the information provided'
        category='Other'
    )
    global static List<CreateLeadActionResponse> createLead(List<CreateLeadActionRequest> createLeadActionRequests)
    {
        List<CreateLeadActionResponse> results = new List<CreateLeadActionResponse>();

        if(createLeadActionRequests != null && !createLeadActionRequests.isEmpty())
        {
            CreateLeadActionRequest request = createLeadActionRequests[0];

            //Convertimos la información recibida al Request Wrapper de BusinessInsuranceRaterService
            BusinessInsuranceRaterService.Request formRequest = new BusinessInsuranceRaterService.Request();
            formRequest.doNotCreateCallback = true; //Desde el flow ZECreateLead no se quiere crear ContactRequest
            formRequest.lastStep = 'CRM-01';
            formRequest.webEmail = request.email;
            formRequest.webPhone = request.phone;
            formRequest.businessCode = request.scopeBusinessCode;

            BusinessInsuranceRaterService.AccountInformation accountInformation = new BusinessInsuranceRaterService.AccountInformation();
            accountInformation.lastName = request.lastName;
            accountInformation.firstName = request.firstName;
            accountInformation.commercialActivity = request.commercialActivity;
            accountInformation.nationalIdentifier = request.nationalIdentifier;
            formRequest.accountInformation = accountInformation;

            Account currentCustomer = BusinessInsuranceRaterService.processFormData(formRequest);
            if(currentCustomer != null && String.isNotBlank(currentCustomer.Id))
            {
                CreateLeadActionResponse response = new CreateLeadActionResponse();
                response.leadId = currentCustomer.Id;
                results.add(response);
            }
        }

        return results;
    }

    global class CreateLeadActionRequest
    {
        @InvocableVariable(
            label='Last Name'
            description='Last name'
            required=true
        )
        global String lastName;

        @InvocableVariable(
            label='First Name'
            description='First name'
            required=false
        )
        global String firstName;

        @InvocableVariable(
            label='Commercial Activity'
            description='Commercial Activity'
            required=false
        )
        global String commercialActivity;

        @InvocableVariable(
            label='National ID'
            description='National Identifier'
            required=false
        )
        global String nationalIdentifier;

        @InvocableVariable(
            label='Email'
            description='Email'
            required=true
        )
        global String email;

        @InvocableVariable(
            label='Phone'
            description='Phone'
            required=false
        )
        global String phone;

        @InvocableVariable(
            label='Scope'
            description='Scope'
            required=true
        )
        global String scopeBusinessCode;
    }

    global class CreateLeadActionResponse
    {
        @InvocableVariable(label='Lead Id' description='Id del Lead encontrado o creado')
        global String leadId;
    }
}