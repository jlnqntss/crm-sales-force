public with sharing class ClientIdentificationService
{

    public static Set<String> currentReceivedFields = new Set<String>(); // Campos que nos envían desde el JSON
    public static Set<String> requiredFieldsMetadataSet = new Set<String>(); // Campos obligatorios

    public static final String INVALID_FIELD_STATUSCODE = 'INVALID_FIELD';
    public static final String EMPTY_FIELD_STATUSCODE = 'EMPTY_FIELD';

    public ClientIdentificationService()
    {}

    public static String processData(Client receivedData, String finding)
    {
        switch on finding {
            // 1 - POST /people: Procesa la búsqueda de clientes
            when 'findByPolicyNumber' {
                return getByPolicyNumber(receivedData);
            }
            when 'findByPhone' {
                return getByPhone(receivedData);
            }
            when else {
                return 'error';
            }
        }
    }

    public static String getByPolicyNumber(Client receivedData)
    {
        if ( String.isBlank(receivedData.nationalID) || String.isBlank(receivedData.policyNumber) )
        {
            throw new ClientIdentificationException(
                      EMPTY_FIELD_STATUSCODE,
                      'A required field is empty'
                      );
        }

        AccountsSelector accountsSelector = new AccountsSelector();
        PoliciesSelector policiesSelector = new PoliciesSelector();
        AssetsSelector assetsSelector = new AssetsSelector();

        SearchResult resultado = new SearchResult();
        resultado.isValidPolicy = false;

        // jgarciamartinez - 18/08/2022 - campos nuevos añadidos a petición de cliente
        resultado.existsNationalID = false;
        resultado.existsPolicy = false;

        // Comprobamos si existe una poliza asignada al DNI que nos envían:
        // 1.- Obtenemos el ID del Account
        List<Account> cuentasEncontradas = accountsSelector.findByNationalId(new List<String> { receivedData.nationalID }, '');
        List<Policy__c> polizaEncontrada = new List<Policy__c>();

        if( !cuentasEncontradas.isEmpty() )
        {
            resultado.existsNationalID = true;
            polizaEncontrada = policiesSelector.selectByInfoPolicyNumberAndNationalId(new List<String> { receivedData.nationalID },new List<String> { receivedData.policyNumber });
        }
        else
        {
            resultado.existsNationalID = false;
            polizaEncontrada = policiesSelector.selectByNumber(receivedData.policyNumber);
        }

        if( !polizaEncontrada.isEmpty() )
        {
            resultado.existsPolicy = true;
            if(polizaEncontrada[0].PolicyStatus__c == 'V')
            {
                resultado.isValidPolicy = true;
            }
        }

        // Tan solo si los tres flags son true les vamos a pasar los valores
        if (resultado.existsNationalID && resultado.existsPolicy && resultado.isValidPolicy)
        {
            resultado.policyEndDate = polizaEncontrada[0].EndDate__c;
            resultado.policyStartDate = polizaEncontrada[0].MovementStartDate__c;
            resultado.policyVersion = polizaEncontrada[0].policyVersion__c;
            
            List<String> listaPolizas = new List<String>();
            for (Policy__c p : polizaEncontrada)
            {
                listaPolizas.add(p.id);
            }
            
            List<Asset> obtainedAssets = assetsSelector.selectByPolicyID(listaPolizas);
            if(!obtainedAssets.isEmpty())
            {
                resultado.policyInfoInsuredObject = obtainedAssets[0].INFOInsuredObjectCode__c;
            }

            List<Product2> obtainedProduct = new ProductsSelector(
                    new Set<String> {'Id', 'Name', 'CommercialCode__c', 'TechnicalCode__c'}
                    ).selectByID(polizaEncontrada[0].ProductId__c);
            if(!obtainedProduct.isEmpty())
            {
                resultado.technicalCode = obtainedProduct[0].TechnicalCode__c;
            }

        } 

        return resultado.toString();

    }


    public static String getByPhone(Client receivedData)
    {
        SearchResultLong resultado = new SearchResultLong();
        List<InsuredObject> listaObjetos = new List<InsuredObject>();
        resultado.objects = listaObjetos;

        // Comprobamos si los datos nos vienen rellenos
        if ( String.isBlank(receivedData.nationalID) || String.isBlank(receivedData.phoneNumber) || String.isBlank(receivedData.groupDescription) )
        {
            System.debug('++++ :' + receivedData.nationalID);
            System.debug('++++ :' + receivedData.phoneNumber);
            System.debug('++++ :' + receivedData.groupDescription);

            throw new ClientIdentificationException(
                      EMPTY_FIELD_STATUSCODE,
                      'A required field is empty'
                      );
        }

        // Si todo bien, buscamos account por DNI + Telefono

        AccountsSelector accountsSelector = new AccountsSelector();
        PoliciesSelector policiesSelector = new PoliciesSelector();
        AssetsSelector assetsSelector = new AssetsSelector();

        // Con el ID del account conseguido, sacamos las pólizas
        List<Account> cuentasEncontradas = accountsSelector.findByNationalIdAndPhoneNumber(new List<String> { receivedData.nationalID }, '', new List<String> { receivedData.phoneNumber });

        if(!cuentasEncontradas.isEmpty())
        {
            resultado.nationalID = receivedData.nationalID;
            resultado.phoneNumber = receivedData.phoneNumber;

            List<Policy__c> polizasEncontradas = policiesSelector.selectByHolderAndGroupDescription(cuentasEncontradas[0].id, receivedData.groupDescription);
            if(!polizasEncontradas.isEmpty())
            {
                System.debug('++++ Entra en if');
                Map<Id, Policy__c> mapaPolizas = new Map<Id, Policy__c>();
                List<Id> listaPolIds = new List<Id>();
                for(Policy__c pol : polizasEncontradas)
                {
                    listaPolIds.add(pol.id);
                    mapaPolizas.put(pol.id, pol);
                }

                List<Asset> listaAssets = assetsSelector.selectByPolicyID(listaPolIds);
                for(Asset a : listaAssets)
                {
                    InsuredObject obj = new InsuredObject();

                    // Datos correspondientes al Asset
                    obj.name = a.Name;
                    obj.registrationNumber = a.RegistrationNumber__c;
                    obj.model = a.Model__c;
                    obj.addressType = a.AddressType__c;
                    obj.addressName = a.AddressName__c; 
                    obj.addressNumber = a.AddressNumber__c;
                    obj.addressAdditionalInfo = a.AddressAdditionalInfo__c;
                    obj.city = a.City__c;

                    // Datos correspondientes a la poliza como tal
                    obj.policyInfoInsuredObject = a.INFOInsuredObjectCode__c;
                    obj.policyEndDate = mapaPolizas.get(a.PolicyId__c).EndDate__c;
                    obj.policyStartDate = mapaPolizas.get(a.PolicyId__c).StartDate__c;
                    obj.policyVersion= mapaPolizas.get(a.PolicyId__c).PolicyVersion__c;

                    listaObjetos.add(obj);
                }

                resultado.objects = listaObjetos;
            }
        }
        return resultado.toString();
    }

    //#region Métodos auxiliares
    /**
     * Método que carga el set de campos que hemos recibido desde el JSON
     *
     * @author arcortazar
     * @date 09/06/2022
     */
    public static void setCurrentFields(String field)
    {
        currentReceivedFields.add(field.toLowerCase());
    }

    /**
     * Método que valida que no falte ninguno de los campos requeridos
     *
     * @return List<String> fieldsNotFound listado de campos no encontrado en el JSON
     * @author rlopez
     * @date 21/10/2020
     */

     public static void validateReceivedInformation(Client receivedData, String identificationType)
     {
        // Obtenemos los campos que son mandatorios
        List<Client_Identification__mdt> allFieldsMetadataSet = Client_Identification__mdt.getAll().values();
        List<Client_Identification__mdt> requiredFieldsMetadataSet = new List<Client_Identification__mdt>();
        for (Client_Identification__mdt m : allFieldsMetadataSet)
        {
            if(m.Identification__c.equals('All') || m.Identification__c.contains(identificationType))
            {
                requiredFieldsMetadataSet.add(m);
            }
        }

        // Comprobamos que entre los recibidos están los mandatorios
        List<String> fieldsNotFound = new List<String>();
        for (Client_Identification__mdt field : requiredFieldsMetadataSet)
        {
            if ( !currentReceivedFields.contains( field.Label.toLowercase() ) )
            {
                fieldsNotFound.add( field.Label.toLowercase() );
            }
        }

        // Si no están, lanzamos excepción
        if( !fieldsNotFound.isEmpty() )
        {
            throw new ClientIdentificationException(
                      INVALID_FIELD_STATUSCODE,
                      'The following fields are missing: ' +
                      fieldsNotFound.toString()
                      );
        }
    }

    //#endregion


    //#region Inner Classes
    /**
     * Representa la información del cliente que llega desde Thunder
     *
     * @author arcortazar
     * @created date: 09/06/2022
     */
    public class Client
    {
        public Client()
        {}

        public String fullName {
            get;
            set {
                setCurrentFields('fullName');
                fullName = value;
            }
        }

        public String nationalID {
            get;
            set {
                setCurrentFields('nationalID');
                nationalID = value;
            }
        }
        public String policyNumber {
            get;
            set {
                setCurrentFields('policyNumber');
                policyNumber = value;
            }
        }
        
        public String phoneNumber {
            get;
            set {
                setCurrentFields('phoneNumber');
                phoneNumber = value;
            }
        }

        public String groupDescription {
            get;
            set {
                setCurrentFields('groupDescription');
                groupDescription = value;
            }
        }

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Representa los resultados de búsqueda del CRM
     *
     * @author arcortazar
     * @created date: 09/06/2022
     */
    public class SearchResult
    {
        public Boolean isValidPolicy;
        // jgarciamartinez - 18/08/2022 - campos nuevos añadidos a petición de cliente
        public Boolean existsNationalID;
        public Boolean existsPolicy;
        public Date policyEndDate;
        public Date policyStartDate;
        public String policyVersion;
        public String policyInfoInsuredObject;

        // arcortazar - 31/01/2023 - [OCS-5874]
        public String technicalCode;

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }
   
    public class SearchResultLong
    {
        public String nationalID;
        public String phoneNumber;
        public List<InsuredObject> objects;

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    public class InsuredObject 
    {
        public Date policyEndDate;
        public Date policyStartDate;
        public String policyVersion;
        public String policyInfoInsuredObject;
        public String technicalCode;

        public String name;
        public String registrationNumber;
        public String model;
        public String addressType;
        public String addressName;
        public String addressNumber;
        public String addressAdditionalInfo;
        public String city;

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }


    //#endregion

    //#region Excepciones

    @TestVisible
    public class ClientIdentificationException extends Exception
    {
        public String statusCode;
        public String message
        {
            get
            {
                return this.getMessage();
            }
        }

        /**
         * Constructor por defecto
         * @author arcortazar
         * @created date: 09/06/2022
         */
        public ClientIdentificationException(String statusCode, String message)
        {
            this.setMessage(message);
            this.statusCode = statusCode;
        }
    }

    //#endregion
}
