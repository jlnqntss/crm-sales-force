trigger ContentDocumentLinkTrigger on ContentDocumentLink(after insert, before insert, after update, before update, after delete, before delete)
{
    TriggerFactory.createHandler(ContentDocumentLink.sObjectType);
}