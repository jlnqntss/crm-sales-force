/**
 * Class TriggerFactory
 *
 * Used to instantiate and execute Trigger Handlers associated with sObjects.
 */
public with sharing class TriggerFactory
{
    private static Map<String, Trigger_Setting__mdt> triggerSettingsMap {
        get {
            return getTriggerSettings;
        }
        private set;
    }
    private static List<String> salesforceClasses {
        get {
            return getSalesforceClasses;
        }
        private set;
    }

    /**
     * Public static method to create and execute a trigger handler
     *
     * Arguments:   Schema.sObjectType soType - Object type to process (SObject.sObjectType)
     *
     * Saves Log_de_Error__c if handler is null.
     */
    public static void createHandler(Schema.sObjectType soType)
    {
        // Get a handler appropriate to the object being processed
        ITrigger handler = getHandler(soType);

        // Make sure we have a handler registered, new handlers must be registered in the getHandler method.
        // Execute the handler to fulfil the trigger
        if (handler != null)
        {
            execute(handler);
        }
    }

    /**
     *  @author         eetxaniz
     *                  Checks if the trigger is active in the metadata
     */
    private static Boolean isTriggerActive(String pObjectName)
    {
        return triggerSettingsMap.get(pObjectName).Active__c;
    }

    /**
     *  @author         eetxaniz
     *                  Gets the trigger settings metadata
     */
    private static Map<String, Trigger_Setting__mdt> getTriggerSettings {
        get {
            if (getTriggerSettings == null)
            {
                getTriggerSettings = new Map<String, Trigger_Setting__mdt>();

                for (Trigger_Setting__mdt triggerMetadata : [
                         SELECT MasterLabel, DeveloperName, Active__c
                         FROM Trigger_Setting__mdt
                     ])
                {
                    getTriggerSettings.put(triggerMetadata.MasterLabel, triggerMetadata);
                }
            }
            return getTriggerSettings;
        }
        private set;
    }

    /**
     * private static method to control the execution of the handler
     *
     * Arguments:   ITrigger handler - A Trigger Handler to execute
     */
    public static void execute(ITrigger handler)
    {
        // Before Trigger
        if (Trigger.isBefore)
        {
            // Call the bulk before to handle any caching of data and enable bulkification
            handler.bulkBefore(Trigger.new, Trigger.oldMap);
            // Iterate through the records to be inserted passing them to the handler.
            if (Trigger.isInsert)
            {
                handler.beforeInsert(Trigger.new);
            }
            else if (Trigger.isUpdate)
            {
                // Iterate through the records to be updated passing them to the handler.
                handler.beforeUpdate(Trigger.new, Trigger.oldMap);
            }
            else if (Trigger.isDelete)
            {
                // Iterate through the records to be deleted passing them to the handler.
                handler.beforeDelete(Trigger.oldMap);
            }
        }
        else
        {
            // Call the bulk after to handle any caching of data and enable bulkification
            handler.bulkAfter(Trigger.new, Trigger.oldMap);
            // Iterate through the records inserted passing them to the handler.
            if (Trigger.isInsert)
            {
                handler.afterInsert(Trigger.new);
            }
            else if (Trigger.isUpdate)
            {
                // Iterate through the records updated passing them to the handler.
                handler.afterUpdate(Trigger.new, Trigger.oldMap);
            }
            else if (Trigger.isDelete)
            {
                // Iterate through the records deleted passing them to the handler.
                handler.afterDelete(Trigger.oldMap);
            }

            // Perform any post processing
            handler.andFinally(Trigger.oldMap, Trigger.newMap);
        }
    }

    /**
     * private static method to get the appropriate handler for the object type.
     * Modify this method to add any additional handlers.
     *
     * Arguments:   Schema.sObjectType soType - Object type tolocate (SObject.sObjectType)
     *
     * Returns:     ITrigger - A trigger handler if one exists or null.
     */
    private static ITrigger getHandler(Schema.sObjectType soType)
    {
        Itrigger handler = null;

        // Get sObject Name
        String objectName = soType.getDescribe().getName();
        // Get the Handler class name

        String className = triggerSettingsMap.containsKey(objectName)
                           ? triggerSettingsMap.get(objectName).DeveloperName
                           : null;

        if (
            isTriggerActive(objectName) &&
            String.isNotBlank(className) &&
            salesforceClasses.contains(className)
            )
        {
            //  Return a new instance of the Handler
            handler = (ITrigger) Type.forName(className).newInstance();
        }
        return handler;
    }

    private static List<String> getSalesforceClasses {
        get {
            if (getSalesforceClasses == null)
            {
                getSalesforceClasses = new List<String>();

                for (ApexClass nextAC : [SELECT Name FROM ApexClass])
                {
                    getSalesforceClasses.add(nextAC.Name);
                }
                for (ApexTrigger nextT : [SELECT Name FROM ApexTrigger])
                {
                    getSalesforceClasses.add(nextT.Name);
                }
            }
            return getSalesforceClasses;
        }
        private set;
    }
}