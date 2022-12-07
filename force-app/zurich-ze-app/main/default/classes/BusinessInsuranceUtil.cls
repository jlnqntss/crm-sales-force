/**
 * Clase Util para los servicios de Business Insurance (Zurich Empresas)
 * @author rlopez
 * @date 13/01/2021
 */
public with sharing class BusinessInsuranceUtil
{
    public static final String ZE_BUSINESS_HOURS = 'ZE Business Hours';
    /**
     * Método que comprueba si la fecha solicitada se encuentra dentro
     * del horario de atención.
     *
     * Devuelve la misma fecha si se encuentra dentro del horario o
     * la siguiente hora hábil si se encuentra fuera
     *
     * @author rlopez
     * @date 13/01/2021
     */
    public static Datetime getPreferredContactDatetime(Datetime requestedDatetime)
    {
        Datetime result;

        if(requestedDatetime == null)
        {
            requestedDatetime = System.now();
        }

        //Recuperamos la configuración del horario de atención de Zurich Empresas
        List<BusinessHours> businessHoursList = [SELECT Id FROM BusinessHours WHERE Name=:ZE_BUSINESS_HOURS];
        if(businessHoursList != null && !businessHoursList.isEmpty() )
        {
            Id zeBusinessHoursId = businessHoursList.get(0).Id;
            result = ( BusinessHours.isWithin(zeBusinessHoursId, requestedDatetime) ? requestedDatetime : BusinessHours.nextStartDate(zeBusinessHoursId, requestedDatetime) );
        }
        else
        {
            result = requestedDatetime;
        }

        return result;
    }
}