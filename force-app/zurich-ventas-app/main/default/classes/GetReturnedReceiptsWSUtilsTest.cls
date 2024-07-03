/**
 * Clase test GetReturnedReceiptsWSUtilsTest
 *
 * @author fpalomo
 * @date 19/06/2024
 */
@IsTest
public class GetReturnedReceiptsWSUtilsTest
{
    @IsTest
    private static void setAuthenticationHeader()
    {
        HttpRequest httpRequest = new HttpRequest();

        Test.startTest();
        httpRequest = GetReturnedReceiptsWSUtils.setAuthenticationHeader(httpRequest);
        Test.stopTest();

        Assert.areEqual(httpRequest.getHeader('Content-Type'), 'application/json', 'Falta el header "Content-Type"');
        Assert.areEqual(httpRequest.getHeader('Authorization'), 'Bearer ', 'Falta el header "Authorization"');
        Assert.areEqual(httpRequest.getHeader('Session-Id'), 'test-session', 'Falta el header "Session-Id"');
        Assert.areEqual(httpRequest.getHeader('flow-id'), 'test-flowid', 'Falta el header "flow-id"');
    }

    @IsTest
    private static void testTokenExpired()
    {
        String token = 'eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJWTnVET2RhZXBYOGNFb2s2bS1IbXhTbFI0NHpXd0lIdUpfRmZGVG1zSnNFIn0.eyJleHAiOjE3MTc1ODI0MDIsImlhdCI6MTcxNzU4MDYwMiwiYXV0aF90aW1lIjoxNzE3NTc3ODI0LCJqdGkiOiI3MzA3OThmYS1lZmE5LTQwNDctYWYwMC0zZGRjN2E2OWRhMGQiLCJpc3MiOiJodHRwczovL2xvZ2luLXVhdC56dXJpY2guZXMvYXV0aC9yZWFsbXMvZW1wLWludGVyIiwiYXVkIjpbIlpvbmFadXJpY2hUaHVuZGVyIiwiQXhlc29yIiwiYWNjb3VudCIsIkVDTSIsIlpvbmFadXJpY2hFbXByZXNhcyJdLCJzdWIiOiI4ZDg5ODAzNi03MjMxLTRkYjktOTUwZS0wMGMwZmQxMWVjYTQiLCJ0eXAiOiJCZWFyZXIiLCJhenAiOiJjcm0iLCJzZXNzaW9uX3N0YXRlIjoiOWFjZjI0ZjMtODExNS00ODA5LTg1ODQtMDBkZGUxMWE2NTljIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbIkVTQl9XU0VNUFRPVEVTQiIsIkVTQl9MSUZFX1JJU0tfU0NPUklORyIsIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6YXRpb24iLCJFU0JfTm9BdXRob3JpemF0aW9uIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsiWm9uYVp1cmljaFRodW5kZXIiOnsicm9sZXMiOlsiQ09NVU5JREFERVNfRU1JU0lPTiIsIlNJTklFU1RSTyIsIkRFU0NBUkdBIiwiQU5VTEFDSU9OIiwiVEVTVCIsIkNPTlRSQVRBQ0lPTiIsIktQSSIsIlJFQ0lCTyJdfSwiQXhlc29yIjp7InJvbGVzIjpbIkFQSV9RVUVSWSJdfSwiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19LCJFQ00iOnsicm9sZXMiOlsiaW5mb3NwYWluIl19LCJjcm0iOnsicm9sZXMiOlsiVmVudGFzX0FnZW50ZV9NZWRpYWRvciJdfSwiWm9uYVp1cmljaEVtcHJlc2FzIjp7InJvbGVzIjpbIlpaRV9NZWRpYWRvciJdfX0sInNjb3BlIjoib3BlbmlkIEJhc2ljX2Zsb3dfZm9yX2luZm9fcmVxdWVzdCIsInNpZCI6IjlhY2YyNGYzLTgxMTUtNDgwOS04NTg0LTAwZGRlMTFhNjU5YyIsIm5hbWUiOiJWaWN0b3IgVGFuZGF6byIsInByZWZlcnJlZF91c2VybmFtZSI6Inp6bWVkMiIsImdpdmVuX25hbWUiOiJWaWN0b3IiLCJhY2NvdW50Y29kZSI6IjAwMDAwMTExMTIiLCJmYW1pbHlfbmFtZSI6IlRhbmRhem8iLCJlbWFpbCI6InZpY3Rvci50YW5kYXpvQHp1cmljaC5jb20udWF0IiwidXNlcm5hbWUiOnsiaW5mbyI6Ilp6bWVkMiJ9fQ.aJPVQbVp-FhhqhtF0I30P6n5xjq9y6HBC7OnYYFEJwcz-aOpUILu67qVIUnNgG3bLC83MHyYTo7jmWXowoupLWLabaD_4Lwo2MeiquWyBsggatTXLq_4s8ZCWJuko3JmIjBlL8uyVJj5sXK8_vsmpmRP6OwlA3fZQ15Pgh5UhbUKTeiThl-B8944Rf8E7WAgdko-TMEAUnim-7_rx2yEosHDdKKdJ2f5L-SQe2_pBw6HJ58hSLcobh5L_nGGAwQUGrjpdUs7V2oL2Kl0iHdrfjAT_bE-QDM1Zq7yrfYegs6Pae7yexMal1EqdBpn4xGxY2uE0ysoJw2s9in1pc8k8w';

        Test.startTest();
        Boolean result = GetReturnedReceiptsWSUtils.hasExpired(token);
        Test.stopTest();

        Assert.isTrue(result == true, 'Debe haber expirado');
    } 
}