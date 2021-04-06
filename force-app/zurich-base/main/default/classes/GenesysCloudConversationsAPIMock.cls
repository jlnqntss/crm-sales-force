@isTest
public class GenesysCloudConversationsAPIMock implements HttpCalloutMock
{
    Map<String, List<APIResponse> > scenario = new Map<String, List<APIResponse> >();

    public HTTPResponse respond(HTTPRequest request)
    {
        String path = request.getEndpoint().substringAfter('/');
        System.debug(path);

        if(this.scenario.containsKey(path) )
        {
            return scenario.get(path).remove(0).toHttpResponse();
        }

        return null;
    }

    public void addRawMockResponse(String path, APIResponse response)
    {
        if(!this.scenario.containsKey(path) )
        {
            this.scenario.put(path, new List<APIResponse>() );
        }

        this.scenario.get(path).add(response);
    }

    public void addActiveConversationsMockResponse(String conversationId)
    {
        addRawMockResponse(
            'api/v2/conversations/calls',
            new GenesysCloudConversationsAPIMock.APIResponse(
                200,
                new Map<String, Object>
        {
            'entities' => new List<Map<String, Object> >
            {
                new Map<String, Object>
                {
                    'id' => conversationId,
                    'participants' => new List<Map<String, Object> >
                    {
                        new Map<String, Object>
                        {
                            'id' => '22083121-445c-469f-8ba1-596e6a671c14',
                            'address' => 'sip:5fda310463dfb0197a3546c0+zurichspainlab.orgspan.com@localhost',
                            'startTime' => '2021-03-31T06:46:45.131Z',
                            'connectedTime' => '2021-03-31T06:46:52.151Z',
                            'purpose' => 'user',
                            'state' => 'connected',
                            'direction' => 'outbound',
                            'held' => false,
                            'wrapupRequired' => false,
                            'provider' => 'Edge',
                            'muted' => false,
                            'confined' => false,
                            'recording' => false,
                            'recordingState' => 'none',
                            'ani' => 'sip:5fda310463dfb0197a3546c0+zurichspainlab.orgspan.com@localhost',
                            'dnis' => 'tel:+34699504908'
                        },
                        new Map<String, Object>
                        {
                            'id' => '22083121-445c-469f-8ba1-596e6a671c14',
                            'name' => 'Mobile Number, Spain',
                            'address' => 'tel:+34699504908',
                            'startTime' => '2021-03-31T06:46:46.519Z',
                            'connectedTime' => '2021-03-31T06:46:52.149Z',
                            'purpose' => 'external',
                            'state' => 'connected',
                            'direction' => 'outbound',
                            'held' => false,
                            'wrapupRequired' => false,
                            'provider' => 'Edge',
                            'peer' => '30136822-029b-4582-a171-25297a793326',
                            'muted' => false,
                            'confined' => false,
                            'recording' => true,
                            'recordingState' => 'active',
                            'ani' => 'sip:soporte-ocs+genesys.qa%40nts-solutions.com@localhost',
                            'dnis' => 'tel:+34699504908',
                            'consultParticipantId' => '22083121-445c-469f-8ba1-596e6a671c14'
                        }
                    }
                }
            }
        }
                )
            );
    }




    public class APIResponse
    {
        Integer statusCode;
        Map<String, Object> mockResponse = new Map<String, Object>();

        public APIResponse(Integer statusCode, Map<String, Object> mockResponse)
        {
            this.statusCode = statusCode;

            if(mockResponse != null)
            {
                this.mockResponse = mockResponse;
            }
        }

        public HttpResponse toHttpResponse()
        {
            HttpResponse res = new HttpResponse();

            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(mockResponse) );
            res.setStatusCode(this.statusCode);

            return res;
        }
    }
}
