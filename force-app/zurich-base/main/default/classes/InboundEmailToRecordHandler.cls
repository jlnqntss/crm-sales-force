global class InboundEmailToRecordHandler implements Messaging.InboundEmailHandler 
{
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {
        Messaging.InboundEmailResult emailResult = new Messaging.InboundEmailResult();
        InboundEmailHeaders emailHeaders = new InboundEmailHeaders(email);
        List<EmailMessage> relatedEmailMessages;
		Opportunity relatedOpportunity = new Opportunity(
            Name = email.Subject,
            CloseDate = Date.today(),
            StageName = 'Clientes potenciales'
         );
        
        // 1 - Se obtiene la referencia del Thread Id de nuestra cabecera
        String threadId = '';

        System.debug(email.headers);
        System.debug(email.inReplyTo);
		System.debug(email.messageId);
        System.debug(email.references);
        
        
		if(emailHeaders.inReplyTo.isEmpty() || emailHeaders.references.isEmpty())
        {
              relatedOpportunity     = new Opportunity(
                Name = email.Subject,
                CloseDate = Date.today(),
                StageName = 'Clientes potenciales'
            );

        	insert relatedOpportunity;

        }
        else
        {
            relatedEmailMessages = [SELECT Id, RelatedToId FROM EmailMessage WHERE MessageIdentifier IN :emailHeaders.inReplyTo OR MessageIdentifier IN :emailHeaders.references ORDER BY SystemModstamp DESC];
            
            if(relatedEmailMessages.isEmpty() || String.isEmpty(relatedEmailMessages[0].RelatedToId))
            {
				insert relatedOpportunity;
            }
            else
            {
                relatedOpportunity = new Opportunity(
                	id = relatedEmailMessages[0].RelatedToId
                );
            }
                

        }
        
        // 3 - Se inserta un EmailMessage
        EmailMessage emailMessage = new EmailMessage();
        
        emailMessage.Subject = email.Subject;
        emailMessage.FromAddress = email.fromAddress;
        emailMessage.Headers = processEmailHeaders(email.headers);
        emailMessage.Status = '0';
        emailMessage.Incoming = true;
        emailMessage.ToAddress = String.join(email.toAddresses, ',');
        emailMessage.RelatedToId = relatedOpportunity.Id;
        emailMessage.HtmlBody = email.htmlBody;
        emailMessage.MessageIdentifier = email.messageId;
        emailMessage.ThreadIdentifier = 'test';
        
        
        if(relatedEmailMessages != null)
        {
            emailMessage.ReplyToEmailMessageId = relatedEmailMessages[0].Id;
        }
        
        insert emailMessage;

        insert new EmailMessageRelation(
            EmailMessageId = emailMessage.Id,
            RelationId = UserInfo.getUserId(),
            RelationType = 'ToAddress'
        );
        
            
        return emailResult;
    }
    
    
    String processEmailHeaders(Messaging.InboundEmail.Header[] inboundEmailHeaders)
    {
        List<String> headers = new List<String>();
        
        for(Messaging.InboundEmail.Header header : inboundEmailHeaders)
        {
            System.debug(header.name);
            System.debug(header.value);
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
                System.debug(header.name);
                System.debug(header.value);
                
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
}