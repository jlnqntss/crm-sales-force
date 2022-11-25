public with sharing class EmailToOpportunityService
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
    public static void searchRelatedEmailAndOpportunity(Messaging.InboundEmail inboundEmail, Messaging.InboundEnvelope envelope)
    {
        InboundEmailHeaders emailHeaders = new InboundEmailHeaders(inboundEmail);

        List<EmailMessage> relatedEmailMessages;
        Id relatedRecordId;

        // 1 - Se obtiene la referencia del Thread Id de nuestra cabecera
        String threadId = inboundEmail.messageId;

        try
        {
            if(!emailHeaders.inReplyTo.isEmpty() || !emailHeaders.references.isEmpty() )
            {
                Set<String> messageIdentifiers = new Set<String>();
                if(!emailHeaders.inReplyTo.isEmpty() )
                {
                    messageIdentifiers.addAll(emailHeaders.inReplyTo);
                }
                if(!emailHeaders.references.isEmpty() )
                {
                    messageIdentifiers.addAll(emailHeaders.references);
                }

                EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
                emailMessagesSelectorObj.fieldsToQuery = new Set<String> {'Id', 'RelatedToId', 'MessageIdentifier', 'ActivityId'};
                relatedEmailMessages = emailMessagesSelectorObj.selectByMessageIdentifier(messageIdentifiers);

                if(!relatedEmailMessages.isEmpty() )
                {
                    Map<Id, Task> tasksById = new Map<Id, Task>(ActivitySelector.selectTasksById(new Set<id> { relatedEmailMessages[0].ActivityId }) );

                    if(tasksById.containsKey(relatedEmailMessages[0].ActivityId) )
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

            emailMessage.Subject = inboundEmail.Subject;
            emailMessage.FromAddress = inboundEmail.fromAddress;
            emailMessage.Headers = processEmailHeaders(inboundEmail.headers);
            emailMessage.Status = '0';
            emailMessage.Incoming = true;
            emailMessage.ToAddress = String.join(inboundEmail.toAddresses, ';'); // fix-OCS-5034 (arcortazar - 3/11/22): sustituimos por ; para igualar con OCS y EON
            emailMessage.HtmlBody = inboundEmail.htmlBody;
            emailMessage.TextBody = inboundEmail.plainTextBody;
            emailMessage.MessageIdentifier = inboundEmail.messageId;
            emailMessage.ThreadIdentifier = threadId;


            if(relatedEmailMessages != null && !relatedEmailMessages.isEmpty() )
            {
                emailMessage.ReplyToEmailMessageId = relatedEmailMessages[0].Id;
            }

            // 3 - Se gestiona el RelatedToId - si el email existía de forma previa,
            //     Se relaciona con el mismo registro que el anterior
            ContactsSelector contactsSelector = new ContactsSelector();
            contactsSelector.setScope(RecordsSelector.Scope.ALL);
            List<Contact> matchedFromAddressContacts = contactsSelector.findByEmail(new List<String> { inboundEmail.fromAddress });

            if(String.isNotEmpty(relatedRecordId) )
            {
                emailMessage.RelatedToId = relatedRecordId;
            }
            else
            {
                // En caso contrario, se genera un Contact Request para dejar un registro mínimo asociado y que el Email Message deje reflejo
                /// TODO: ¿Gestionar colas aquí?
                ContactRequest request = new ContactRequest(
                    RequestDescription = (inboundEmail.Subject + '\n' + inboundEmail.plainTextBody).abbreviate(32000),
                    PreferredChannel = CHANNEL_EMAIL
                    );

                if(!matchedFromAddressContacts.isEmpty() )
                {
                    request.WhoId = matchedFromAddressContacts[0].Id;
                }

                insert request;

                emailMessage.RelatedToId = request.Id;
            }

            insert emailMessage;


            // 4 - Gestión de adjuntos
            processEmailAttachments(emailMessage, inboundEmail);

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
                                  RelationAddress = inboundEmail.fromAddress,
                                  RelationId = matchedFromAddressContacts[0].Id,
                                  RelationType = 'FromAddress'
                                  ) );
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


    /**
     * Genera un mapa de Attachments tomando los archivos adjuntos al InboundEmail, incluyendo las imágenes en línea
     * Las claves del mapa son la cabecera 'Content-ID'; en caso de que no exista, se utiliza el timestamp.
     *
     * Basado en http://simplyforce.blogspot.com/2014/08/handling-inline-images-in-salesforce.html
     *
     * @param  email    InboundEmail proveniente del Email Service
     * @param  parentId Id. del registro al que asociar el Attachment
     * @return        Mapa con Attachaments sin insertar en BBDD
     **/
    private static void processEmailAttachments(EmailMessage emailMessage, Messaging.InboundEmail inboundEmail)
    {
        Map<String, Attachment> attachmentsByContentId = buildEmailAttachmentsMap(inboundEmail, emailMessage.Id);

        insert attachmentsByContentId.values();

        // Parse email body and replace references to "cid" content ids
        // with attachment file urls so render when email message viewed in salesforce.
        //
        // Use of Content-ID header is inspired by http://simplyforce.blogspot.com/2014/08/handling-inline-images-in-salesforce.html
        // so that Email2CaseHandler can replace image sources in the html body with links to actual attachments
        // so that the images render when viewing the HTML version of this email message.


        for ( String contentId : attachmentsByContentId.keySet() )
        {
            String cid = contentId.replace( '<', '' ).replace( '>', '' );
            String url = URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.FileDownload?file=' + attachmentsByContentId.get( contentId ).id;

            if(String.isNotEmpty(emailMessage.textBody))
            {
                emailMessage.textBody = emailMessage.textBody.replaceAll( 'cid:' + cid, url );
            }

            if(String.isNotEmpty(emailMessage.htmlBody))
            {
                emailMessage.htmlBody = emailMessage.htmlBody.replaceAll( 'cid:' + cid, url );
            }
        }

        update emailMessage;
    }

    /**
     * Genera un mapa de Attachments tomando los archivos adjuntos al InboundEmail, incluyendo las imágenes en línea
     * Las claves del mapa son la cabecera 'Content-ID'; en caso de que no exista, se utiliza el timestamp.
     *
     * Basado en http://simplyforce.blogspot.com/2014/08/handling-inline-images-in-salesforce.html
     *
     * @param  email    InboundEmail proveniente del Email Service
     * @param  emailMessageId Id. del registro al que asociar el Attachment
     * @return        Mapa con Attachaments sin insertar en BBDD
     **/
    private static Map<String,Attachment> buildEmailAttachmentsMap(Messaging.InboundEmail email, Id emailMessageId)
    {
        Map<String, Attachment> attachmentsByContentId = new Map<String, Attachment>();

        if ( email.binaryAttachments != null )
        {

            for ( Messaging.InboundEmail.BinaryAttachment binaryAttachment : email.binaryAttachments )
            {
                String contentId = getHeaderValue( binaryAttachment.headers, 'Content-ID' );

                if ( String.isBlank( contentId ) )
                {
                    contentId = String.valueOf( Datetime.now().getTime() );
                }

                attachmentsByContentId.put( contentId, new Attachment(
                                                name = binaryAttachment.fileName,
                                                body = binaryAttachment.body,
                                                contentType = binaryAttachment.mimeTypeSubType,
                                                parentId = emailMessageId
                 ) );
            }
        }

        if ( email.textAttachments != null )
        {

            for ( Messaging.InboundEmail.TextAttachment textAttachment : email.textAttachments )
            {

                String contentId = getHeaderValue( textAttachment.headers, 'Content-ID' );

                if ( String.isBlank( contentId ) )
                {
                    contentId = String.valueOf(Datetime.now().getTime() );
                }

                attachmentsByContentId.put( contentId, new Attachment(
                                                name = textAttachment.fileName,
                                                body = Blob.valueOf( textAttachment.body ),
                                                contentType = textAttachment.mimeTypeSubType,
                                                parentId = emailMessageId
                     ) );
            }
        }

        return attachmentsByContentId;
    }

    private static String getHeaderValue( List<Messaging.InboundEmail.Header> headers, String name )
    {

        String value = null;

        if ( headers != null )
        {
            for ( Messaging.InboundEmail.Header header : headers )
            {
                if ( header.name == name )
                {
                    value = header.value;
                    break;
                }
            }
        }

        return value;
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
                        this.inReplyTo.addAll(header.value.split(',') );
                    }
                    when('References')
                    {
                        this.references.addAll(header.value.split(',') );
                    }
                }

                headers.add(header.name + ': ' + header.value);
            }

            this.headers = String.join(headers, '\n');
        }
    }

    @TestVisible
    class EmailToOpportunityServiceException extends Exception
    {}
}
