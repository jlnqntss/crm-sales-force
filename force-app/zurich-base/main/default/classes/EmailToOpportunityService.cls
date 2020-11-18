public without sharing class EmailToOpportunityService
{
    private final static String CHANNEL_EMAIL = 'Email';
    /**
     * Método que recibe un InboundEmail, busca si existe en Salesforce un EmailMessage relacionado
     * a partir de las cabeceras del InboundEmail y deja registrada la información en un nuevo EmailMessage.
     *
     * Si se encuentra un EmailMessage relacionado con el nuevo Email, éste quedará relacionado con la misma Oportunidad
     *
     * @author rlopez
     * @date 09/11/2020
     */
    public static void searchRelatedEmailAndOpportunity(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope)
    {
        InboundEmailHeaders emailHeaders = new InboundEmailHeaders(email);

        List<EmailMessage> relatedEmailMessages;
        Id relatedRecordId;

        // 1 - Se obtiene la referencia del Thread Id de nuestra cabecera
        String threadId = email.messageId;

        try
        {
            if(!emailHeaders.inReplyTo.isEmpty() || !emailHeaders.references.isEmpty() )
            {
                Set<String> messageIdentifiers = new Set<String>();
                messageIdentifiers.addAll(emailHeaders.inReplyTo);
                messageIdentifiers.addAll(emailHeaders.references);

                EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
                emailMessagesSelectorObj.fieldsToQuery = new Set<String> {'Id', 'RelatedToId', 'MessageIdentifier', 'ActivityId'};
                relatedEmailMessages = emailMessagesSelectorObj.selectByMessageIdentifier(messageIdentifiers);

                if(!relatedEmailMessages.isEmpty() )
                {
                    Map<Id, Task> tasksById = new Map<Id, Task>(ActivitySelector.selectTasksById(new Set<id> { relatedEmailMessages[0].ActivityId }));

                    if(tasksById.containsKey(relatedEmailMessages[0].ActivityId))
                    {
                        relatedRecordId = tasksById.get(relatedEmailMessages[0].ActivityId).WhatId;
                    }
                }

                if(!relatedEmailMessages.isEmpty() && String.isNotBlank(relatedEmailMessages[0].MessageIdentifier) )
                {
                    threadId = relatedEmailMessages[0].MessageIdentifier;
                }
            }

            // 2 - Se inserta un EmailMessage
            EmailMessage emailMessage = new EmailMessage();

            emailMessage.Subject = email.Subject;
            emailMessage.FromAddress = email.fromAddress;
            emailMessage.Headers = processEmailHeaders(email.headers);
            emailMessage.Status = '0';
            emailMessage.Incoming = true;
            emailMessage.ToAddress = String.join(email.toAddresses, ',');
            emailMessage.HtmlBody = email.htmlBody;
            emailMessage.MessageIdentifier = email.messageId;
            emailMessage.ThreadIdentifier = threadId;


            if(relatedEmailMessages != null && !relatedEmailMessages.isEmpty() )
            {
                emailMessage.ReplyToEmailMessageId = relatedEmailMessages[0].Id;
            }

            // 3 - Se gestiona el RelatedToId - si el email existía de forma previa,
            //     Se relaciona con el mismo registro que el anterior
            List<Contact> matchedFromAddressContacts = ContactsSelector.findByEmail(new List<String> { email.fromAddress });

            if(String.isNotEmpty(relatedRecordId))
            {
                emailMessage.RelatedToId = relatedRecordId;
            }
            else
            {
                // En caso contrario, se genera un Contact Request para dejar un registro mínimo asociado y que el Email Message deje reflejo
                /// TODO: ¿Gestionar colas aquí?
                ContactRequest request = new ContactRequest(
                    RequestDescription = (email.Subject + '\n' + email.plainTextBody).abbreviate(32000),
                    PreferredChannel = CHANNEL_EMAIL
                );

                if(!matchedFromAddressContacts.isEmpty())
                {
                    request.WhoId = matchedFromAddressContacts[0].Id;
                }

                insert request;

                emailMessage.RelatedToId = request.Id;
            }

            insert emailMessage;
            
            List<EmailMessageRelation> relations = new List<EmailMessageRelation>
            {
                new EmailMessageRelation(
                    EmailMessageId = emailMessage.Id,
                    RelationId = UserInfo.getUserId(),
                    RelationType = 'ToAddress'
                )
            };

            if(!matchedFromAddressContacts.isEmpty() )
            {
                relations.add(new EmailMessageRelation(
                    EmailMessageId = emailMessage.Id,
                    RelationAddress = email.fromAddress,
                    RelationId = matchedFromAddressContacts[0].Id,
                    RelationType = 'FromAddress'
                ));
            }

            insert relations;
        }
        catch (Exception ex)
        {
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_CRITICAL, ex.getMessage(), 'EmailToOpportunityService');
        }
    }

    private static String processEmailHeaders(Messaging.InboundEmail.Header[] inboundEmailHeaders)
    {
        List<String> headers = new List<String>();

        for(Messaging.InboundEmail.Header header : inboundEmailHeaders)
        {
            headers.add(header.name + ': ' + header.value);
        }

        return String.join(headers, '\n');
    }

    class InboundEmailHeaders
    {
        public String headers = '';
        public Set<String> references = new Set<String>();
        public Set<String> inReplyTo = new Set<String>();


        public InboundEmailHeaders(Messaging.InboundEmail inboundEmail)
        {
            List<String> headers = new List<String>();

            for(Messaging.InboundEmail.Header header : inboundEmail.headers)
            {
                switch on header.name
                {
                    when('In-Reply-To')
                    {
                        this.inReplyTo.addAll(header.value.split(','));
                    }
                    when('References')
                    {
                        this.references.addAll(header.value.split(','));
                    }
                }

                headers.add(header.name + ': ' + header.value);
            }

            this.headers = String.join(headers, '\n');
        }
    }

    @TestVisible
    class EmailToOpportunityServiceException extends Exception {}
}