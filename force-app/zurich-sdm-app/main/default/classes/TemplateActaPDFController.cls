public with sharing class TemplateActaPDFController {

    private final Event eventFields;
    private final Acta__c datosActa;
    
    public TemplateActaPDFController(ApexPages.StandardController stdController) {
        Event event = (Event)stdController.getRecord();
        eventFields = EventSelector.getActaTemplateData(event.Id).get(0);
        system.System.debug(event);
        datosActa = getDatosActa(event);
        configurePage(eventFields, datosActa);        
    }

    /**Obtener los datos de acta necesarios para el controlador
     * @author nts (dmunoz)
     * @date 26/01/2023
     * 
     */
    private Acta__c getDatosActa(Event e) {

        List<Acta__c> actas = ActaSelector.getAccionesTratadasActa(e.Acta__c);
        Acta__c result;

        if (!actas.isEmpty()) {
            result = actas.get(0);
        }
        return result;
    }

    /**Añade la cabecera para descarga o previsualización segun el parametro
     * @author nts (dmunoz)
     * @date 26/01/2023
     * 
     */
    private void configurePage(Event e, Acta__c datosActa) {
        String modeValue = apexpages.currentpage().getparameters().get('mode');
        String visualforceModeInput = modeValue != null && String.isNotEmpty(modeValue) ? String.escapeSingleQuotes(modeValue) : '';

        if ('download'.equals(visualforceModeInput)) {
            Apexpages.currentPage().getHeaders().put('content-disposition',  'attachment; filename='+ datosActa.Name + ' Acta ' + e.Subject + '.pdf'); // attachment en lugar de inline lo descarga automaticamente             
        } else {
            Apexpages.currentPage().getHeaders().put('content-disposition',  'inline; filename=' + datosActa.Name + ' Acta ' + e.Subject + '.pdf');
        }     
    }
    
    public String getStartDate() {
        
        String result = '';

        if (eventFields.IsAllDayEvent) { // compruebo si es un evento de dia completo
            Date startDate = eventFields.ActivityDate;
            result = startDate.format();
        } else {
            Datetime startDate = eventFields.ActivityDateTime;
            result = startDate.format('dd/MM/yyyy HH:mm', 'Europe/Madrid');
        }
        
        return result;
    }

    public String getEndDate() {
        String result = '';

        if (eventFields.IsAllDayEvent) { // compruebo si es un evento de dia completo
            Date endDate = eventFields.EndDate;
            result = endDate.format();
        } else {
            Datetime endDate = eventFields.EndDateTime;
            result = endDate.format('dd/MM/yyyy HH:mm', 'Europe/Madrid');
        }
        
        return result;
    }

    public String getEventType() {
        return eventFields.EventType__c;
    }

    public List<AccionesTratadasActa__c> getAccionesTratadas() {
        return datosActa.AccionesTratadasActa__r;

    }
}