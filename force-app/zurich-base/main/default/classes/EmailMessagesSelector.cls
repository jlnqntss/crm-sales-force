public with sharing class EmailMessagesSelector
{
    //Esta propiedad indica el objeto Salesforce del que vamos a extraer los campos necesarios en la query
    //Si no se indica el objeto, solo se recupera el Id del objeto Salesforce
    public String sObjectToQuery {get; set;}
    public Set<String> fieldsToQuery
    {
        get
        {
            if( String.isNotBlank(this.sObjectToQuery) )
            {
                SObjectType currentObjectType = Schema.getGlobalDescribe().get(this.sObjectToQuery);
                Map<String,Schema.SObjectField> currentTypeFields = currentObjectType.getDescribe().fields.getMap();

                if( fieldsToQuery == null || fieldsToQuery.isEmpty() )
                {
                    fieldsToQuery = new Set<String>();

                    //Recuperamos los required y externalIds
                    for( Schema.SObjectField sObjectField: currentTypeFields.values() )
                    {
                        //Si el campo es requerido o externalId, lo incluimos en el Set de campos a recuperar en la query
                        if(sObjectField.getDescribe().isNillable() != true || sObjectField.getDescribe().isExternalId() == true)
                        {
                            fieldsToQuery.add( sObjectField.getDescribe().getName() );
                        }
                    }
                }
                else
                {
                    //Comprobamos que los campos existen en los campos del objeto, si alguno no existe lo eliminamos del Set
                    for(String field: fieldsToQuery)
                    {
                        if( !currentTypeFields.containsKey(field) )
                        {
                            fieldsToQuery.remove(field);
                        }
                    }

                    if( fieldsToQuery.isEmpty() )
                    {
                        fieldsToQuery.add('Id');
                    }
                }

                return fieldsToQuery;
            }
            else
            {
                return new Set<String> {'Id'};
            }
        }
        set;
    }


    //#region Contructores
    public EmailMessagesSelector()
    {}

    public EmailMessagesSelector(Set<String> fieldsToQuery)
    {
        this();
        this.fieldsToQuery = fieldsToQuery;
    }
    //#endregion

    // #######
    // #Region EmailMessage: Queries relacionadas con el objeto EmailMessage
    // #######

    /**
     * Busca emails a partir del MessageIdentifier
     *
     * @author rlopez
     * @date 09/11/2020
     * @param  messageIdentifiers   Listado de identificadores. Válido cualquier formato
     * @return                      Listado de emails sobre los que se ha realizado match
     */
    public List<EmailMessage> selectByMessageIdentifier(Set<String> messageIdentifiers)
    {
        if(messageIdentifiers != null)
        {
            this.sObjectToQuery = 'EmailMessage';
            String query = String.format(
                'SELECT {0} FROM EmailMessage ' +
                'WHERE MessageIdentifier IN : messageIdentifiers ' +
                'ORDER BY SystemModstamp DESC',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<EmailMessage>) Database.query(query);
        }
        else
        {
            return new List<EmailMessage>();
        }
        //return [SELECT Id, RelatedToId FROM EmailMessage WHERE MessageIdentifier IN : messageIdentifiers ORDER BY SystemModstamp DESC];
    }

    /**
     * Busca emails a partir del asunto
     *
     * @author rlopez
     * @date 10/11/2020
     * @param  subjects   Listado de asuntos de email
     * @return            Listado de emails sobre los que se ha realizado match
     */
    public List<EmailMessage> selectBySubject(List<String> subjects)
    {
        if(subjects != null)
        {
            this.sObjectToQuery = 'EmailMessage';
            String query = String.format(
                'SELECT {0} FROM EmailMessage ' +
                'WHERE Subject IN : subjects ',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<EmailMessage>) Database.query(query);
        }
        else
        {
            return new List<EmailMessage>();
        }
    }

    /**
     * Busca emails a partir del Id del objeto relacionado
     *
     * @author rlopez
     * @date 10/11/2020
     * @param  relatedToIds     Listado de Ids de objetos de Salesforce relacionados con emails
     * @return                  Listado de emails sobre los que se ha realizado match
     */
    public List<EmailMessage> selectByRelatedObjectId(Set<String> relatedToIds)
    {
        if(relatedToIds != null)
        {
            this.sObjectToQuery = 'EmailMessage';
            String query = String.format(
                'SELECT {0} FROM EmailMessage ' +
                'WHERE RelatedToId IN : relatedToIds',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            });

            return (List<EmailMessage>) Database.query(query);
        }
        else
        {
            return new List<EmailMessage>();
        }
    }

    // #######
    // #Region EmailMessageRelation: Queries relacionadas con el objeto EmailMessageRelation
    // #######

    /**
     * Busca relaciones entre emails a partir del Id del Email y el Id de la relación
     *
     * @author rlopez
     * @date 10/11/2020
     * @param  emailIds      Listado de asuntos de email
     * @param  relationIds   Listado de asuntos de email
     * @return               Listado de relaciones entre emails sobre los que se ha realizado match
     */
    public List<EmailMessageRelation> selectRelationByEmailAndRelation(Set<String> emailIds, Set<String> relationIds)
    {
        if(emailIds != null && relationIds != null)
        {
            this.sObjectToQuery = 'EmailMessageRelation';
            String query = String.format(
                'SELECT {0} FROM EmailMessageRelation ' +
                'WHERE EmailMessageId IN : emailIds AND RelationId IN : relationIds',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<EmailMessageRelation>) Database.query(query);
        }
        else
        {
            return new List<EmailMessageRelation>();
        }
    }


    /**
     * Busca un Email message a través de un Id de area
     *
     * @author jmartinezpisson
     * @date 16/11/2020
     * @param  activityIds      Listado de Ids. de tarea
     * @return               Listado de relaciones entre emails sobre los que se ha realizado match
     */
    public List<EmailMessage> selectByActivityId(Set<Id> activityIds)
    {
        if(activityIds == null || activityIds.isEmpty() )
        {
            return new List<EmailMessage>();
        }

        return (List<EmailMessage>) Database.query(String.format(
                                                       'SELECT {0} FROM EmailMessage ' +
                                                       'WHERE ActivityId IN : activityIds',
                                                       new List<String>
        {
            String.join(new List<String> (this.fieldsToQuery), ',')
        }
                                                       ) );
    }

    /**
     * Busca un Email message a través de un Id de interacción de Genesys Cloud
     *
     * @author jmartinezpisson
     * @date 16/11/2020
     * @param  interactionIds      Listado de Ids. de Genesys
     * @return               Listado de emails sobre los que se ha realizado match
     */
    public List<EmailMessage> selectByInteractionId(Set<String> interactionIds)
    {
        if(interactionIds == null || interactionIds.isEmpty() )
        {
            return new List<EmailMessage>();
        }

        return [SELECT Id, ToIds, ActivityId, Status FROM EmailMessage WHERE GenesysInteractionId__c IN : interactionIds];
    }
}