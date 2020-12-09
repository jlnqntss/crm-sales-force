public with sharing class CampaignMembersSelector
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
    public CampaignMembersSelector()
    {}

    public CampaignMembersSelector(Set<String> fieldsToQuery)
    {
        this();
        this.fieldsToQuery = fieldsToQuery;
    }
    //#endregion

    /**
     * Busca campañas a partir del Name
     *
     * @author rlopez
     * @date 01/12/2020
     * @param  campaignId   Id de campaña a buscar
     * @param  contactIds   Conjunto de ids de Contacto
     * @return          Listado de CampaignMembers sobre los que se ha realizado match
     */
    public List<CampaignMember> selectByCampaignAndContact(Id campaignId, Set<Id> contactIds)
    {
        if(campaignId != null && contactIds != null)
        {
            this.sObjectToQuery = 'CampaignMember';
            String query = String.format(
                'SELECT {0} FROM CampaignMember ' +
                'WHERE campaignId = : campaignId AND ContactId IN : contactIds ',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<CampaignMember>) Database.query(query);
        }
        else
        {
            return new List<CampaignMember>();
        }
    }
}