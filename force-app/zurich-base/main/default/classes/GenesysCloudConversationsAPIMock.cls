@isTest
public class GenesysCloudConversationsAPIMock implements HttpCalloutMock
{
    public static final String ENTITY_ID = '22083121-445c-469f-8ba1-596e6a671c14';
    public static final String ENTITY_DNIS = 'tel:+34699504908';
    public static final String ENTITY_ADDRESS = 'sip:5fda310463dfb0197a3546c0+zurichspainlab.orgspan.com@localhost';

    Map<String, List<APIResponse> > scenario = new Map<String, List<APIResponse> >();

    public HTTPResponse respond(HTTPRequest request)
    {
        String path = request.getEndpoint().substringAfter('/');

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
                            'id' => ENTITY_ID,
                            'address' => ENTITY_ADDRESS,
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
                            'ani' => ENTITY_ADDRESS,
                            'dnis' => ENTITY_DNIS
                        },
                        new Map<String, Object>
                        {
                            'id' => ENTITY_ID,
                            'name' => 'Mobile Number, Spain',
                            'address' => ENTITY_DNIS,
                            'startTime' => '2021-03-31T06:46:46.519Z',
                            'connectedTime' => '2021-03-31T06:46:52.149Z',
                            'purpose' => 'external',
                            'state' => 'connected',
                            'direction' => 'outbound',
                            'held' => false,
                            'wrapupRequired' => false,
                            'provider' => 'Edge',
                            'attributes' => new Map<String, String> {
                                'CalledAddress' => '662114885'
                            },
                            'peer' => '30136822-029b-4582-a171-25297a793326',
                            'muted' => false,
                            'confined' => false,
                            'recording' => true,
                            'recordingState' => 'active',
                            'ani' => 'sip:soporte-ocs+genesys.qa%40nts-solutions.com@localhost',
                            'dnis' => ENTITY_DNIS,
                            'consultParticipantId' => ENTITY_ID
                        }
                    }
                }
            }
        }
                )
            );
    }

    public void addParticipantMockResponse(String conversationId)
    {
        addRawMockResponse(
            'api/v2/conversations/calls/9d720887-910f-402d-b102-946c2c273992/participants/22083121-445c-469f-8ba1-596e6a671c14/attributes',
            new GenesysCloudConversationsAPIMock.APIResponse(
                200,
                new Map<String, Object> {
                    'attributes' => new Map<String, String>{
                        'parentConversationId' => conversationId
                    }
                }
            )
        );
    }

    public void addUUIDMockResponse()
    {
        addRawMockResponse(
            'api/v2/conversations/calls/9d720887-910f-402d-b102-946c2c273992/participants/22083121-445c-469f-8ba1-596e6a671c14/communications/30136822-029b-4582-a171-25297a793326/uuidata',
            new GenesysCloudConversationsAPIMock.APIResponse(
                200,
                null
            )
        );
    }

    public void addConsultMockResponse()
    {
        addRawMockResponse(
            'api/v2/conversations/calls/9d720887-910f-402d-b102-946c2c273992/participants/22083121-445c-469f-8ba1-596e6a671c14/consult',
            new GenesysCloudConversationsAPIMock.APIResponse(
                200,
                null
            )
        );
    }

    public void addCallMockResponse(String interactionId, String conversationId)
    {
        addRawMockResponse(
            'api/v2/conversations/calls/' + interactionId,
            new GenesysCloudConversationsAPIMock.APIResponse(
                200,
                new Map<String, Object> {
                    'id' => conversationId,
                    'participants' => new List<Map<String, Object>> {
                        new Map<String, Object> {
                            'id' => ENTITY_ID,
                            'address' => ENTITY_ADDRESS,
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
                            'ani' => ENTITY_ADDRESS,
                            'dnis' => ENTITY_DNIS
                        },
                        new Map<String, Object> {
                            'id' => ENTITY_ID,
                            'name' => 'Mobile Number, Spain',
                            'address' => ENTITY_DNIS,
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
                            'dnis' => ENTITY_DNIS,
                            'consultParticipantId' => ENTITY_ID
                        }
                    }
                }
            )
        );
    }

    public void addCallbackCancelMockResponse(String interactionId)
    {
        // {"participants":[],"state":"disconnected"}
        addRawMockResponse(
            'api/v2/conversations/callbacks/' + interactionId, 
            new GenesysCloudConversationsAPIMock.APIResponse(
                200,
                new Map<String, Object> {
                    'state' => 'disconnected'
                }
            )
        );
    }

    public void addCallbackCancelMockResponseError(String interactionId)
    {
        // {"participants":[],"state":"disconnected"}
        addRawMockResponse(
            'api/v2/conversations/callbacks/' + interactionId, 
            new GenesysCloudConversationsAPIMock.APIResponse(
                404,
                new Map<String, Object> {
                    'message' => 'not found'
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