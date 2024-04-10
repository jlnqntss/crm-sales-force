/**
 * Generic auxiliar methods for working with ApexLists, Sets ans Maps
 *
 * @group Utils
 * @author Javier Martínez de Pissón
 * @date 17/10/2016
 **/
global with sharing class CollectionUtil
{
    //#region Global Methods

    /**
     * Generates a Map of lists from a SOQL query or a list of sObjects, where the key is a String field passed as argument.
     *
     * @author Javier Martínez de Pissón
     * @date 17/10/2016
     * @param objectList (List<sObject>, sobject list source)
     * @param field (String, key Field)
     * @return Map, must be casted to the corresponding Map type
     */
    global static Object groupListBy(List<sObject> sObjectList, String field)
    {
        // 0 - Si se recibe null, se deuelve null
        if( sObjectList == null)
            return null;

        // 1 - Se obtiene el tipo de SObject y se verifica su existencia
        Schema.sObjectType sObjType = sObjectList.getSObjectType();

        if(sObjType == null)
            throw new CollectionException('CollectionUtil.groupListBy: Cannot infered the sObject Type of a generic sObjectList - The sObjectList must be a typed List.');

        Schema.SObjectField fieldToken = sObjType.getDescribe().fields.getMap().get(field);

        if(fieldToken == null)
            throw new CollectionException('CollectionUtil.groupListBy: Field ' + field + ' does not exist in the definition of ' + sObjType);

        // 2 - A partir del describe del campo, se llama al método que genera el mapa correspondiente
        return buildGroupMap( sObjectList, field, fieldToken.getDescribe().getSoapType() );
    }

    /**
     * Generates a Map of lists from a Aggregate SOQL query or an Aggregate list, where the key is the field passed as argument.
     **
     * @author Javier Martínez de Pissón
     * @date 09/03/2017
     * @param aggList (List<AggregateResult>) The aggregate list source
     * @param field (String) Field to be used as key of the map
     * @throws CollectionException Apex cannot handle empty List<AggregateResult>
     * @return  Map, must be casted to the corresponding Map type
     */
    global static Object groupListBy(List<AggregateResult> aggregateResultList, String field)
    {
        // 0 - Si se recibe null o una lista vacía, se devuelve null
        if( aggregateResultList == null)
            return null;

        if( aggregateResultList.isEmpty() )
        {
            throw new CollectionException('CollectionUtil.groupListBy: The AggregateResult list is empty.');
        }

        // 1 - Se obtiene el tipo de campo a partir de la primera línea de registros del AggregateResult
        Schema.SOAPType fieldType = inferSOAPType( aggregateResultList[0].get(field) );

        // 2 - A partir del tipo del campo, se llama al método que genera el mapa correspondiente
        return buildGroupMap(aggregateResultList, field, fieldType );
    }

    /**
     * Generates a Map from a SOQL query or a list of sObjects, where the key is the field passed as argument.
     *
     * @author Javier Martínez de Pissón
     * @date 09/08/2016
     * @param objectList (List<sObject>) The sobject list source
     * @param field (String) Field to be used as key of the map
     * @return HashList, must be casted to the corresponding Map type
     */
    global static Object hashList(List<sObject> sObjectList, String field)
    {
        if( sObjectList == null)
            return null;

        // 1 - Se obtiene el tipo de SObject y se verifica su existencia
        Schema.sObjectType sObjType = sObjectList.getSObjectType();

        if(sObjType == null)
            throw new CollectionException('CollectionUtil.hashList: Cannot infered the sObject Type of a generic sObjectList - The sObjectList must be a typed List.');

        // 2 - Se verifica la existencia del campo
        Schema.SObjectField fieldToken = sObjType.getDescribe().fields.getMap().get(field);

        if(fieldToken == null)
            throw new CollectionException('CollectionUtil.hashList: Field ' + field + ' does not exist in the definition of ' + sObjType);

        // 3 - A partir de los tipos de campo y objeto, se genera de forma dinámica un mapa
        Schema.SOAPType fieldType = fieldToken.getDescribe().getSoapType();

        Type sObjMapClass = Type.forName( 'Map<' + fieldType + ', ' + String.valueOf( sObjType ) + '>');
        Object sObjMap = sObjMapClass.newInstance();

        buildMap(sObjMap, sObjectList, field, fieldType );

        return sObjMap;
    }

    /**
     * Generates a Map from a Aggregate SOQL query or an Aggregate list, where the key is the field passed as argument.
     *
     * @author Javier Martínez de Pissón
     * @date 09/03/2017
     * @param aggList (List<AggregateResult>) The aggregate list source
     * @param field (String) Field to be used as key of the map
     * @throws CollectionException Apex cannot handle empty List<AggregateResult>
     * @return HashList, must be casted to the corresponding Map type
     */
    global static Object hashList(List<AggregateResult> aggregateResultList, String field)
    {
        if( aggregateResultList == null )
            return null;

        if( aggregateResultList.isEmpty() )
        {
            throw new CollectionException('CollectionUtil.groupListBy: The AggregateResult list is empty.');
        }

        // 1 - Se obtiene el tipo de campo a partir de la primera línea de registros del AggregateResult
        Schema.SOAPType fieldType = inferSOAPType( aggregateResultList[0].get(field) );

        // 2 - A partir de los describe, se genera de forma dinámica un mapa
        Type sObjMapClass = Type.forName( 'Map<' + String.valueOf(fieldType) + ', AggregateResult>');
        Object sObjMap = sObjMapClass.newInstance();

        buildMap(sObjMap, aggregateResultList, field, fieldType);

        return sObjMap;
    }
    //#endregion

    //#region Private methods

    /**
     * Auxiliar method - Create a dynamic map ordered by a sObject field from a list of sObjects, inferring field type using polymorphism.
     *
     * @author Javier Martínez de Pissón
     * @date 17/10/2016
     * @param sObjectMap (Object) The map entry, of type Map<T1,sObject>
     * @param sObjectList (List<sObject>) The datasource for Map -list of sObjects-
     * @param fieldName (String) Name of field to be used as map key
     * @param type (enum Schema.SOAPType) Type of the field referenced by fieldName
     * @return The infered map, returned as a generic Object
     */
    public static Object buildMap(Object sObjMap, List<sObject> sObjectList, String fieldName, Schema.SOAPType type)
    {
        if(type == Schema.SOAPType.String)
        {
            buildStringMap( (Map<String, sObject>) sObjMap, sObjectList, fieldName );
        }
        else if(type == Schema.SOAPType.Id)
        {
            buildIdMap( (Map<Id, sObject>) sObjMap, sObjectList, fieldName );
        }
        else if(type == Schema.SOAPType.Date)
        {
            buildDateMap( (Map<Date, sObject>) sObjMap, sObjectList, fieldName );
        }
        else if(type == Schema.SOAPType.Datetime)
        {
            buildDateTimeMap( (Map<Datetime, sObject>) sObjMap, sObjectList, fieldName );
        }
        else if(type == Schema.SOAPType.Double)
        {
            buildDoubleMap( (Map<Double, sObject>) sObjMap, sObjectList, fieldName );
        }
        else if(type == Schema.SOAPType.Integer)
        {
            buildIntegerMap( (Map<Integer, sObject>) sObjMap, sObjectList, fieldName );
        }
        else if(type == Schema.SOAPType.Boolean)
        {
            buildBooleanMap( (Map<Boolean, sObject>) sObjMap, sObjectList, fieldName );
        }
        else if(type == Schema.SOAPType.Time)
        {
            buildTimeMap( (Map<Time, sObject>) sObjMap, sObjectList, fieldName );
        }
        else
        {
            throw new CollectionException('CollectionUtil.hashList: FieldType ' + type + ' not supported as key');
        }

        return sObjMap;
    }

    //#region buildTypeMap methods
    /**
     * Auxiliar method - Create a dynamic map from a list of sObjects, ordering them by a reference field.
     *
     * @author Javier Martínez de Pissón
     * @date 17/10/2016
     * @change 02/06/2017 Changed the implementation to improve eficiency
     * @param sObjMap (Map<Id,sObject>) The map to fill, passed as referenced
     * @param sObjectList (List<sObject>) The datasource for sObjMap -list of sObjects-
     * @param fieldName (String) Name of field to be used as map key
     */
    private static void buildIdMap(Map<Id,sObject> sObjMap, List<sObject> sObjectList, String fieldName)
    {
        Id fieldValue;
        sObject o;

        for(Integer i = 0, l = sObjectList.size(); i < l; i++)
        {
            o = sObjectList[i];
            fieldValue = (Id) o.get(fieldName);

            if( String.isNotBlank(fieldValue) )
            {
                sObjMap.put(fieldValue, o);
            }
        }
    }

    /**
     * Auxiliar method - Create a dynamic map from a list of sObjects, ordering them by a string field.
     *
     * @author Javier Martínez de Pissón
     * @date 17/10/2016
     * @change 02/06/2017 Changed the implementation to improve eficiency
     * @param sObjMap (Map<String,sObject>) The map to fill, passed as referenced
     * @param sObjectList (List<sObject>) The datasource for sObjMap -list of sObjects-
     * @param fieldName (String) Name of field to be used as map key
     */
    private static void buildStringMap(Map<String,sObject> sObjMap, List<sObject> sObjectList, String fieldName)
    {
        String fieldValue;
        sObject o;

        for(Integer i = 0, l = sObjectList.size(); i < l; i++)
        {
            o = sObjectList[i];

            fieldValue = String.valueOf( o.get(fieldName) );

            if( String.isNotBlank(fieldValue) )
            {
                sObjMap.put(fieldValue, o);
            }
        }
    }

    /**
     * Auxiliar method -  Create a dynamic map from a list of sObjects, ordering them by a Integer field.
     *
     * @author Javier Martínez de Pissón
     * @date 17/10/2016
     * @change 02/06/2017 Changed the implementation to improve eficiency
     * @param sObjMap (Map<String,sObject>) The map to fill, passed as referenced
     * @param sObjectList (List<sObject>) The datasource for sObjMap -list of sObjects-
     * @param fieldName (String) Name of field to be used as map key
     */
    private static void buildIntegerMap(Map<Integer,sObject> sObjMap, List<sObject> sObjectList, String fieldName)
    {
        Integer fieldValue;
        sObject o;

        for(Integer i = 0, l = sObjectList.size(); i < l; i++)
        {
            o = sObjectList[i];

            fieldValue = (Integer) o.get(fieldName);

            if( fieldValue != null )
            {
                sObjMap.put(fieldValue, o);
            }
        }
    }

    /**
     * Auxiliar method -  Create a dynamic map from a list of sObjects, ordering them by a Double field.
     *
     * @author Javier Martínez de Pissón
     * @date 17/10/2016
     * @change 02/06/2017 Changed the implementation to improve eficiency
     * @param sObjMap (Map<String,sObject>) The map to fill, passed as referenced
     * @param sObjectList (List<sObject>) The datasource for sObjMap -list of sObjects-
     * @param fieldName (String) Name of field to be used as map key
     */
    private static void buildDoubleMap(Map<Double,sObject> sObjMap, List<sObject> sObjectList, String fieldName)
    {
        Double fieldValue;
        sObject o;

        for(Integer i = 0, l = sObjectList.size(); i < l; i++)
        {
            o = sObjectList[i];
            fieldValue = (Double)  o.get(fieldName);

            if( fieldValue != null )
            {
                sObjMap.put(fieldValue, o);
            }
        }
    }

    /**
     * Auxiliar method -  Create a dynamic map from a list of sObjects, ordering them by a Date field.
     *
     * @author Javier Martínez de Pissón
     * @date 17/10/2016
     * @change 02/06/2017 Changed the implementation to improve eficiency
     * @param sObjMap (Map<String,sObject>) The map to fill, passed as referenced
     * @param sObjectList (List<sObject>) The datasource for sObjMap -list of sObjects-
     * @param fieldName (String) Name of field to be used as map key
     */
    private static void buildDateMap(Map<Date,sObject> sObjMap, List<sObject> sObjectList, String fieldName)
    {
        Date fieldValue;
        sObject o;

        for(Integer i = 0, l = sObjectList.size(); i < l; i++)
        {
            o = sObjectList[i];
            fieldValue = (Date) o.get(fieldName);

            if( fieldValue != null )
            {
                sObjMap.put(fieldValue, o);
            }
        }
    }

    /**
     * Auxiliar method -  Create a dynamic map from a list of sObjects, ordering them by a Datetime field.
     *
     * @author Javier Martínez de Pissón
     * @date 17/10/2016
     * @change 02/06/2017 Changed the implementation to improve eficiency
     * @param sObjMap (Map<String,sObject>) The map to fill, passed as referenced
     * @param sObjectList (List<sObject>) The datasource for sObjMap -list of sObjects-
     * @param fieldName (String) Name of field to be used as map key
     */
    private static void buildDatetimeMap(Map<Datetime,sObject> sObjMap, List<sObject> sObjectList, String fieldName)
    {
        Datetime fieldValue;
        sObject o;

        for(Integer i = 0, l = sObjectList.size(); i < l; i++)
        {
            o = sObjectList[i];
            fieldValue = (Datetime) o.get(fieldName);

            if( fieldValue != null )
            {
                sObjMap.put(fieldValue, o);
            }
        }
    }

    /**
     * Auxiliar method -  Create a dynamic map from a list of sObjects, ordering them by a Time field.
     *
     * @author Javier Martínez de Pissón
     * @date 17/10/2016
     * @change 02/06/2017 Changed the implementation to improve eficiency
     * @param sObjMap (Map<String,sObject>) The map to fill, passed as referenced
     * @param sObjectList (List<sObject>) The datasource for sObjMap -list of sObjects-
     * @param fieldName (String) Name of field to be used as map key
     */
    private static void buildTimeMap(Map<Time,sObject> sObjMap, List<sObject> sObjectList, String fieldName)
    {
        Time fieldValue;
        sObject o;

        for(Integer i = 0, l = sObjectList.size(); i < l; i++)
        {
            o = sObjectList[i];
            fieldValue = (Time) o.get(fieldName);

            if( fieldValue != null )
            {
                sObjMap.put(fieldValue, o);
            }
        }
    }

    /**
     * Auxiliar method -  Create a dynamic map from a list of sObjects, ordering them by a Boolean field.
     *
     * @author Javier Martínez de Pissón
     * @date 17/10/2016
     * @change 02/06/2017 Changed the implementation to improve eficiency
     * @param sObjMap (Map<String,sObject>) The map to fill, passed as referenced
     * @param sObjectList (List<sObject>) The datasource for sObjMap -list of sObjects-
     * @param fieldName (String) Name of field to be used as map key
     */
    private static void buildBooleanMap(Map<Boolean,sObject> sObjMap, List<sObject> sObjectList, String fieldName)
    {
        Boolean fieldValue;
        sObject o;

        for(Integer i = 0, l = sObjectList.size(); i < l; i++)
        {
            o = sObjectList[i];
            fieldValue = (Boolean) o.get(fieldName);

            if( fieldValue != null )
            {
                sObjMap.put(fieldValue, o);
            }
        }
    }
    //  #endregion


    /**
     * Create a map of lists from a list of sObjects, using polymorphism for infering the Map type
     **
     * @author Javier Martínez de Pissón (17/10/2016)
     * @param sObjectList (< List<sObject >, )
     * @param fieldName (String, name of field to uses as map key)
     * @param type (enum Schema.SOAPType,type of the field referenced by fieldName)
     **/
    private static Object buildGroupMap(List<sObject> sObjectList, String fieldName, Schema.SOAPType type)
    {
        if(type == Schema.SOAPType.Id)
        {
            return buildGroupIdMap(sObjectList, fieldName);
        }
        else if(type == Schema.SOAPType.String)
        {
            return buildGroupStringMap(sObjectList, fieldName);
        }
        else if(type == Schema.SOAPType.Integer)
        {
            return buildGroupIntegerMap(sObjectList, fieldName);
        }
        else if(type == Schema.SOAPType.Double)
        {
            return buildGroupDoubleMap(sObjectList, fieldName);
        }
        else if(type == Schema.SOAPType.Date)
        {
            return buildGroupDateMap(sObjectList, fieldName);
        }
        else if(type == Schema.SOAPType.Datetime)
        {
            return buildGroupDateTimeMap(sObjectList, fieldName);
        }
        else if(type == Schema.SOAPType.Boolean)
        {
            return buildGroupBooleanMap(sObjectList, fieldName);
        }
        else if(type == Schema.SOAPType.Time)
        {
            return buildGroupTimeMap(sObjectList, fieldName);
        }

        throw new CollectionException('CollectionUtil.groupListBy: FieldType ' + type + ' not supported as key');
    }

    //  #region buildGroupTypeMap methods
    private static Map<Id, List<sObject> > buildGroupIdMap(List<sObject> sObjectList, String fieldName)
    {
        Map<Id, List<sObject> > sObjListMap = new Map<Id, List<sObject> >();
        Id fieldValue;
        sObject o;

        for(Integer i = 0, l = sObjectList.size(); i < l; i++)
        {
            o = sObjectList[i];
            fieldValue = (Id) o.get(fieldName);

            if( String.isNotBlank(fieldValue) )
            {
                if( !sObjListMap.containsKey(fieldValue) )
                {
                    sObjListMap.put( fieldValue, new List<sObject> () );
                }

                sObjListMap.get(fieldValue).add(o);
            }
        }

        return sObjListMap;
    }

    private static Map<String, List<sObject> > buildGroupStringMap(List<sObject> sObjectList, String fieldName)
    {
        Map<String, List<sObject> > sObjListMap = new Map<String, List<sObject> >();
        String fieldValue;

        for(sObject o : sObjectList)
        {
            fieldValue = String.valueOf( o.get(fieldName) );

            if( String.isNotBlank(fieldValue) )
            {
                if( !sObjListMap.containsKey(fieldValue) )
                {
                    sObjListMap.put( fieldValue, new List<sObject> () );
                }

                sObjListMap.get(fieldValue).add(o);
            }
        }

        return sObjListMap;
    }

    private static Map<Integer, List<sObject> >  buildGroupIntegerMap(List<sObject> sObjectList, String fieldName)
    {
        Map<Integer, List<sObject> > sObjListMap = new Map<Integer, List<sObject> >();
        Integer fieldValue;
        sObject o;

        for(Integer i = 0, l = sObjectList.size(); i < l; i++)
        {
            o = sObjectList[i]; fieldValue = (Integer) o.get(fieldName);

            if( fieldValue != null )
            {
                if( !sObjListMap.containsKey(fieldValue) )
                {
                    sObjListMap.put( fieldValue, new List<sObject> () );
                }

                sObjListMap.get(fieldValue).add(o);
            }
        }

        return sObjListMap;
    }

    private static Map<Double, List<sObject> > buildGroupDoubleMap(List<sObject> sObjectList, String fieldName)
    {
        Map<Double, List<sObject> > sObjListMap = new Map<Double, List<sObject> >();
        Double fieldValue;
        sObject o;

        for(Integer i = 0, l = sObjectList.size(); i < l; i++)
        {
            o = sObjectList[i];
            fieldValue = (Double)  o.get(fieldName);

            if( fieldValue != null )
            {
                if( !sObjListMap.containsKey(fieldValue) )
                {
                    sObjListMap.put( fieldValue, new List<sObject> () );
                }

                sObjListMap.get(fieldValue).add(o);
            }
        }

        return sObjListMap;
    }

    private static Map<Date, List<sObject> > buildGroupDateMap(List<sObject> sObjectList, String fieldName)
    {
        Map<Date, List<sObject> > sObjListMap = new Map<Date, List<sObject> >();
        Date fieldValue;
        sObject o;

        for(Integer i = 0, l = sObjectList.size(); i < l; i++)
        {
            o = sObjectList[i];
            fieldValue = (Date) o.get(fieldName);

            if( fieldValue != null )
            {
                if( !sObjListMap.containsKey(fieldValue) )
                {
                    sObjListMap.put( fieldValue, new List<sObject> () );
                }

                sObjListMap.get(fieldValue).add(o);
            }
        }

        return sObjListMap;
    }

    private static Map<Datetime, List<sObject> > buildGroupDatetimeMap(List<sObject> sObjectList, String fieldName)
    {
        Map<Datetime, List<sObject> > sObjListMap = new Map<Datetime, List<sObject> >();
        Datetime fieldValue;
        sObject o;

        for(Integer i = 0, l = sObjectList.size(); i < l; i++)
        {
            o = sObjectList[i];
            fieldValue = (Datetime) o.get(fieldName);

            if( fieldValue != null )
            {
                if( !sObjListMap.containsKey(fieldValue) )
                {
                    sObjListMap.put( fieldValue, new List<sObject> () );
                }

                sObjListMap.get(fieldValue).add(o);
            }
        }

        return sObjListMap;
    }

    private static Map<Time, List<sObject> > buildGroupTimeMap(List<sObject> sObjectList, String fieldName)
    {
        Map<Time, List<sObject> > sObjListMap = new Map<Time, List<sObject> >();
        Time fieldValue;
        sObject o;

        for(Integer i = 0, l = sObjectList.size(); i < l; i++)
        {
            o = sObjectList[i];
            fieldValue = (Time) o.get(fieldName);

            if( fieldValue != null )
            {
                if( !sObjListMap.containsKey(fieldValue) )
                {
                    sObjListMap.put( fieldValue, new List<sObject> () );
                }

                sObjListMap.get(fieldValue).add(o);
            }
        }

        return sObjListMap;
    }

    private static Map<Boolean, List<sObject> > buildGroupBooleanMap(List<sObject> sObjectList, String fieldName)
    {
        Map<Boolean, List<sObject> > sObjListMap = new Map<Boolean, List<sObject> >();
        Boolean fieldValue;
        sObject o;

        for(Integer i = 0, l = sObjectList.size(); i < l; i++)
        {
            o = sObjectList[i];
            fieldValue = (Boolean) o.get(fieldName);

            if( fieldValue != null )
            {
                if( !sObjListMap.containsKey(fieldValue) )
                {
                    sObjListMap.put( fieldValue, new List<sObject> () );
                }

                sObjListMap.get(fieldValue).add(o);
            }
        }

        return sObjListMap;
    }

    /**
     * Auxiliar method -  Get SOAPType from value
     *
     * @author Javier Martínez de Pissón
     * @date 03/03/2017
     * @param sObjMap (Map<String,sObject>) The map to fill, passed as referenced
     * @return Schema.SOAPType
     */
    private static Schema.SOAPType inferSOAPType(Object value)
    {
        if(value instanceof Id)
        {
            return Schema.SOAPType.Id;
        }
        else if(value instanceof String)
        {
            return Schema.SOAPType.String;
        }
        else if(value instanceof Integer)
        {
            return Schema.SOAPType.Integer;
        }
        else if(value instanceof Double)
        {
            return Schema.SOAPType.Double;
        }
        else if(value instanceof Date)
        {
            return Schema.SOAPType.Date;
        }
        else if(value instanceof Datetime)
        {
            return Schema.SOAPType.Datetime;
        }
        else if(value instanceof Boolean)
        {
            return Schema.SOAPType.Boolean;
        }
        else if(value instanceof Time)
        {
            return Schema.SOAPType.Time;
        }

        throw new CollectionException('CollectionUtil: Value ' + value + ' is not a supported primitive type');
    }
    //  #endregion

    //#endregion

    //#region Inner Classes
    //  #region Exceptions
    @testVisible private class CollectionException extends Exception
    {}

    //  #endregion
    //#endregion
}