/**
 * Clase de test para TicketingHegeoUtil
 *
 * @author mario.navarro@seidor.com
 * @date 22/04/2024
 */
@isTest
private with sharing class Test_TicketingHegeoUtil
{

    /**
     * Testea el metodo setStatusSubstatusByCase
     *
     * @author mario.navarro@seidor.com
     * @date 22/04/2024
     */
    @isTest
    private static void test_setStatusSubstatusByCase()
    {
        CanalUnicoUpdateVsegTicketRequest reqNew = new CanalUnicoUpdateVsegTicketRequest();
        reqNew.ticket = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoTicket();
        CanalUnicoUpdateVsegTicketRequest reqAssigned = new CanalUnicoUpdateVsegTicketRequest();
        reqAssigned.ticket = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoTicket();
        CanalUnicoUpdateVsegTicketRequest reqAnswered = new CanalUnicoUpdateVsegTicketRequest();
        reqAnswered.ticket = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoTicket();
        CanalUnicoUpdateVsegTicketRequest reqClosed = new CanalUnicoUpdateVsegTicketRequest();
        reqClosed.ticket = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoTicket();
        CanalUnicoUpdateVsegTicketRequest reqPendSupport = new CanalUnicoUpdateVsegTicketRequest();
        reqPendSupport.ticket = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoTicket();
        CanalUnicoUpdateVsegTicketRequest reqPendSupervisor = new CanalUnicoUpdateVsegTicketRequest();
        reqPendSupervisor.ticket = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoTicket();
        CanalUnicoUpdateVsegTicketRequest reqPendPartner = new CanalUnicoUpdateVsegTicketRequest();
        reqPendPartner.ticket = new CanalUnicoUpdateVsegTicketRequest.CanalUnicoTicket();

        Test.startTest();
        TicketingHegeoUtil.setStatusSubstatusByCase( reqNew, new Case(status=CaseUtil.CASE_NUEVO) );
        TicketingHegeoUtil.setStatusSubstatusByCase( reqAssigned, new Case(status=CaseUtil.CASE_ASIGNADO) );
        TicketingHegeoUtil.setStatusSubstatusByCase( reqAnswered, new Case(status=CaseUtil.CASE_RESPONDIDO) );
        TicketingHegeoUtil.setStatusSubstatusByCase( reqClosed, new Case(status=CaseUtil.estadoCerrado) );
        TicketingHegeoUtil.setStatusSubstatusByCase( reqPendSupport, new Case(status=CaseUtil.CASE_PENDIENTE, PendingBy__c=CaseUtil.CASE_PENDIENTE_SOPORTE) ); 
        TicketingHegeoUtil.setStatusSubstatusByCase( reqPendSupervisor, new Case(status=CaseUtil.CASE_PENDIENTE, PendingBy__c=CaseUtil.CASE_PENDIENTE_SUPERVISOR) );
        TicketingHegeoUtil.setStatusSubstatusByCase( reqPendPartner, new Case(status=CaseUtil.CASE_PENDIENTE, PendingBy__c=CaseUtil.CASE_PENDIENTE_PARTNER) );
        Test.stopTest();

        Assert.areEqual('1', reqNew.ticket.ticketStatus);
        Assert.areEqual('0', reqNew.ticket.ticketSubStatus);
        Assert.areEqual('2', reqAssigned.ticket.ticketStatus);
        Assert.areEqual('0', reqAssigned.ticket.ticketSubStatus);
        Assert.areEqual('2', reqAnswered.ticket.ticketStatus);
        Assert.areEqual('0', reqAnswered.ticket.ticketSubStatus);
        Assert.areEqual('3', reqClosed.ticket.ticketStatus);
        Assert.areEqual('0', reqClosed.ticket.ticketSubStatus);

        Assert.areEqual('5', reqPendSupport.ticket.ticketStatus);
        Assert.areEqual('1', reqPendSupport.ticket.ticketSubStatus);
        Assert.areEqual('Pendiente de Support', reqPendSupport.ticket.subStatusDesc);
        Assert.areEqual('5', reqPendSupervisor.ticket.ticketStatus);
        Assert.areEqual('1', reqPendSupervisor.ticket.ticketSubStatus);
        Assert.areEqual('Pendiente de Supervisor', reqPendSupervisor.ticket.subStatusDesc);
        Assert.areEqual('5', reqPendPartner.ticket.ticketStatus);
        Assert.areEqual('0', reqPendPartner.ticket.ticketSubStatus);
        Assert.areEqual('Pendiente de Partner', reqPendPartner.ticket.subStatusDesc);
    }

    /**
     * Testea el metodo createBaseRequestByCase
     *
     * @author mario.navarro@seidor.com
     * @date 25/06/2024
     */
    @isTest
    private static void test_createBaseRequestByCase()
    {
        //Caso 0: Cotizacion
        //Caso 1: Recotizacion
        //Caso 2: Otra peticion
        //Caso 3: Contactar sobre 'Otra peticion'
        List<Case> zdaCaseList = TestDataFactory.generateZDACases(4);
        zdaCaseList[0].Status = CaseUtil.estadoCerrado; //un caso de recotizacion siempre estara asociado a otro ya cerrado
        zdaCaseList[1].RelatedCuTicketId__c = zdaCaseList[0].CuTicketId__c;
        zdaCaseList[1].Description = 'Cuerpo de la recotizacion';
        zdaCaseList[3].RelatedCuTicketId__c = zdaCaseList[2].CuTicketId__c;
        zdaCaseList[3].Description = TicketingHegeoUtil.LABEL_BODY_CONTACTAR+': texto del contactar';

        insert zdaCaseList;

        Test.startTest();
        CanalUnicoUpdateVsegTicketRequest recotizarReq = TicketingHegeoUtil.createBaseRequestByCase(zdaCaseList[1]);
        CanalUnicoUpdateVsegTicketRequest contactarReq = TicketingHegeoUtil.createBaseRequestByCase(zdaCaseList[3]);
        Test.stopTest();

        Case recotizarCase = [SELECT RelatedCuTicketId__c FROM Case WHERE Id = :zdaCaseList[1].Id];
        Case contactarCase = [SELECT CuTicketId__c FROM Case WHERE Id = :zdaCaseList[3].Id];

        Assert.areEqual(recotizarCase.RelatedCuTicketId__c, recotizarReq.ticket.ticketId);
        Assert.areEqual(contactarCase.CuTicketId__c, contactarReq.ticket.ticketId);
    }

}