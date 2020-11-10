public without sharing class EmailToOpportunityService
{
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
        Id relatedOpportunityId;
        
        // 1 - Se obtiene la referencia del Thread Id de nuestra cabecera
        String threadId = email.messageId;
        
        if(!emailHeaders.inReplyTo.isEmpty() || !emailHeaders.references.isEmpty())
        {
            Set<String> messageIdentifiers = new Set<String>();
            messageIdentifiers.addAll(emailHeaders.inReplyTo);
            messageIdentifiers.addAll(emailHeaders.references);

            EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
            emailMessagesSelectorObj.fieldsToQuery = new Set<String>{'Id', 'RelatedToId', 'MessageIdentifier'};
            relatedEmailMessages = emailMessagesSelectorObj.selectByMessageIdentifier(messageIdentifiers);
            
            if(!relatedEmailMessages.isEmpty() && String.isNotBlank(relatedEmailMessages[0].RelatedToId))
            {
				relatedOpportunityId = relatedEmailMessages[0].RelatedToId;
            }

            if(!relatedEmailMessages.isEmpty() && String.isNotBlank(relatedEmailMessages[0].MessageIdentifier))
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
        emailMessage.RelatedToId = relatedOpportunityId;
        emailMessage.HtmlBody = email.htmlBody;
        emailMessage.MessageIdentifier = email.messageId;
        emailMessage.ThreadIdentifier = threadId;
        
        
        if(relatedEmailMessages != null && !relatedEmailMessages.isEmpty())
        {
            emailMessage.ReplyToEmailMessageId = relatedEmailMessages[0].Id;
        }
        
        try {
            insert emailMessage;

            insert new EmailMessageRelation(
                EmailMessageId = emailMessage.Id,
                RelationId = UserInfo.getUserId(),
                RelationType = 'ToAddress'
            );
        } catch (EmailToOpportunityServiceException ex) {
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