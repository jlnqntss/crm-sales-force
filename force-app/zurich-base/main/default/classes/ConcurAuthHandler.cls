global class ConcurAuthHandler extends Auth.AuthProviderPluginClass
{

    public String redirectUrl = 'https://zurich-es--deva.my.salesforce.com/services/authcallback/GenesysCloud_Test';            // use this URL for the endpoint that the authentication provider calls back to for configuration
    private String key = 'a4b7cfe1-ccf8-4a64-8304-b83aa10dfdd7';
    private String secret = 'OsHyq2WTO-qZJv_9Jy7STRPbB7v3PV-d5EB4Gqs0wD4';
    private String authUrl = 'https://login.mypurecloud.ie/oauth/authorize';               // application redirection to the Concur website for authentication and authorization
    private String accessTokenUrl = 'https://login.mypurecloud.ie/oauth/token';
    private String userAPIURL = 'https://api.mypurecloud.ie/api/v2/users/me';


    global String getCustomMetadataType()
    {
        return 'TestAuth__mdt';
    }

    global PageReference initiate(Map<string,string> authProviderConfiguration, String stateToPropagate)
    {

        String url = String.format('{0}?client_id={1}&response_type=code&redirect_uri={2}&state={3}', new String[]
        {
            authUrl,
            EncodingUtil.urlEncode(key, 'UTF-8'),
            EncodingUtil.urlEncode(redirectUrl, 'UTF-8'),
            stateToPropagate
        });

        return new PageReference(url);
    }

    global Auth.AuthProviderTokenResponse handleCallback(Map<string,string> authProviderConfiguration, Auth.AuthProviderCallbackState state )
    {
        Map<String,String> queryParams = state.queryParameters;
        String code = queryParams.get('code');
        String sfdcState = queryParams.get('state');

        System.debug(state);

        HttpRequest req = new HttpRequest();
        String url = accessTokenUrl;
        req.setEndpoint(url);
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(key + ':' + secret) ) );
        req.setMethod('POST');


        req.setBody(String.join(new List<String>
        {
            'grant_type=authorization_code',
            'code=' + EncodingUtil.urlEncode(code, 'UTF-8'),
            'redirect_uri=' + EncodingUtil.urlEncode(redirectUrl, 'UTF-8')
        }, '&') );

        Http http = new Http();
        HTTPResponse res = http.send(req);
        String responseBody = res.getBody();

        System.debug(responseBody);
        Map<String, String> accessToken = (Map<String, String>) JSON.deserialize(responseBody, Map<String, string>.class);

        //Parse access token value
        String refreshToken = accessToken.get('refresh_token');
        //Parse refresh token value
        String token = accessToken.get('access_token');

        return new Auth.AuthProviderTokenResponse('ConcurAuthHandler', token, refreshToken, sfdcState);
        //don’t hard-code the refresh token value!
    }


    global Auth.UserData  getUserInfo(Map<string,string> authProviderConfiguration, Auth.AuthProviderTokenResponse response)
    {
        //Here the developer is responsible for constructing an Auth.UserData object
        String token = response.oauthToken;
        HttpRequest req = new HttpRequest();

        req.setHeader('Authorization', 'Bearer ' + token);
        req.setEndpoint(userAPIURL);
        req.setHeader('Content-Type','application/json');
        req.setMethod('GET');


        Http http = new Http();
        HTTPResponse res = http.send(req);
        String responseBody = res.getBody();

        System.debug(responseBody);
        Map<String, Object> userInfo = ( Map<String, Object> ) JSON.deserializeUntyped(responseBody);


        return new Auth.UserData( (string) userInfo.get('id'), null, null, null, null,
                                  'what', null, null, 'ConcurAuthHandler', null, null );
    }

}