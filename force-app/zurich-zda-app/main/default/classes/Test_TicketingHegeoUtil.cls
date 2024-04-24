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
        TicketingHegeoUtil.setStatusSubstatusByCase( reqNew, new Case(status='Nuevo') );
        TicketingHegeoUtil.setStatusSubstatusByCase( reqAssigned, new Case(status='Asignado') );
        TicketingHegeoUtil.setStatusSubstatusByCase( reqAnswered, new Case(status='Respondido') );
        TicketingHegeoUtil.setStatusSubstatusByCase( reqClosed, new Case(status='Cerrado') );
        TicketingHegeoUtil.setStatusSubstatusByCase( reqPendSupport, new Case(status='Pendiente', PendingBy__c='Support') );
        TicketingHegeoUtil.setStatusSubstatusByCase( reqPendSupervisor, new Case(status='Pendiente', PendingBy__c='Supervisor') );
        TicketingHegeoUtil.setStatusSubstatusByCase( reqPendPartner, new Case(status='Pendiente', PendingBy__c='Partner') );
        Test.stopTest();

        Assert.areEqual(1, reqNew.ticket.ticketStatus);
        Assert.areEqual(0, reqNew.ticket.ticketSubStatus);
        Assert.areEqual(2, reqAssigned.ticket.ticketStatus);
        Assert.areEqual(0, reqAssigned.ticket.ticketSubStatus);
        Assert.areEqual(2, reqAnswered.ticket.ticketStatus);
        Assert.areEqual(0, reqAnswered.ticket.ticketSubStatus);
        Assert.areEqual(3, reqClosed.ticket.ticketStatus);
        Assert.areEqual(0, reqClosed.ticket.ticketSubStatus);

        Assert.areEqual(5, reqPendSupport.ticket.ticketStatus);
        Assert.areEqual(1, reqPendSupport.ticket.ticketSubStatus);
        Assert.areEqual('Pendiente de Support', reqPendSupport.ticket.subStatusDesc);
        Assert.areEqual(5, reqPendSupervisor.ticket.ticketStatus);
        Assert.areEqual(1, reqPendSupervisor.ticket.ticketSubStatus);
        Assert.areEqual('Pendiente de Supervisor', reqPendSupervisor.ticket.subStatusDesc);
        Assert.areEqual(5, reqPendPartner.ticket.ticketStatus);
        Assert.areEqual(0, reqPendPartner.ticket.ticketSubStatus);
        Assert.areEqual('Pendiente de Partner', reqPendPartner.ticket.subStatusDesc);
    }

}