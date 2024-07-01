/**
 * @description       : Desmarca el campo Active Agent en el caso que se dé de baja el usuario
 * @author            : lgonzalez
 * @group             : Seidor
 * @last modified on  : 05-24-2023
 * @last modified by  : lgonzalez
**/
trigger UserTrigger on User (after insert, before insert, after update, before update, after delete, before delete)
{
    TriggerFactory.createHandler(User.sObjectType);
}