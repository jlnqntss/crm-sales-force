public with sharing class ZRMFilesController {

    private static final String DOCTYPE_CSV = 'doctype:csv';
    private static final String DOCTYPE_EXCEL = 'doctype:excel';
    private static final String DOCTYPE_IMAGE = 'doctype:image';
    private static final String DOCTYPE_PDF = 'doctype:pdf';
    private static final String DOCTYPE_PPT = 'doctype:ppt';
    private static final String DOCTYPE_TXT = 'doctype:txt';
    private static final String DOCTYPE_UNKNOWN = 'doctype:unknown';
    private static final String DOCTYPE_WORD = 'doctype:word';
    private static final String DOCTYPE_ZIP = 'doctype:zip';
    

    //#region métodos LWC

    /** Obtener los registros de ficheros para zrm
     *           
     * @author dmunoz
     * @date 16/05/2024
     */
    @AuraEnabled(cacheable=true)
    public static List<ZRMFile> getRelatedFilesByRecordId(String recordId) {
        try {
            List<ZRMFile> result = new List<ZRMFile>();
            List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
            Map<String, String> iconMap = initIconMap();
    
            // Obtener datos del usuario logueado
            User loggedUser = new UsersSelector().findUserIntermediaryByUserId(UserInfo.getUserId());
    
            if (ProfilesSelector.PROFILE_AGENTE_VENTAS.equals(loggedUser.Profile.Name)) {                
                contentDocumentLinkList = new ContentDocumentLinkSelector().getZRMContentDocumentByLinkedEntity(recordId, loggedUser.Contact.AccountId);
                result = getZRMFilesList(contentDocumentLinkList, iconMap, loggedUser);
                
            } else if (ProfilesSelector.PROFILE_AGENTE_VENTAS_AGR.equals(loggedUser.Profile.Name)) {                
                contentDocumentLinkList = new ContentDocumentLinkSelector().getZRMAGRContentDocumentByLinkedEntity(recordId, loggedUser.Contact.Account.IntermediaryGroup__c);
                result = getZRMFilesList(contentDocumentLinkList, iconMap, loggedUser);
            }
            
            return result;

        } catch(Exception e) {
            throw new AuraHandledException(System.Label.ZRM_Files_LWC_Error);
        }
    }


    //#region métodos Auxiliares
    

    /** Lista de iconos para el componente por extension
     *           
     * @author dmunoz
     * @date 16/05/2024
     */
    @TestVisible
    private static Map<String, String> initIconMap() {
        Map<String, String> result = new Map<String, String>();
        result.put('csv', DOCTYPE_CSV);
        result.put('docx', DOCTYPE_WORD);
        result.put('doc', DOCTYPE_WORD);
        result.put('docx', DOCTYPE_WORD);
        result.put('jpeg', DOCTYPE_IMAGE);
        result.put('ods', DOCTYPE_EXCEL);
        result.put('odp', DOCTYPE_PPT);
        result.put('odt', DOCTYPE_WORD);
        result.put('png', DOCTYPE_IMAGE);
        result.put('pdf', DOCTYPE_PDF);
        result.put('ppt', DOCTYPE_PPT);
        result.put('pptx', DOCTYPE_PPT);
        result.put('txt', DOCTYPE_TXT);
        result.put('xls', DOCTYPE_EXCEL);
        result.put('xlsb', DOCTYPE_EXCEL);
        result.put('zip', DOCTYPE_ZIP);

        return result;
    }


    /** Obtener el nombre del icono
     *           
     * @author dmunoz
     * @date 16/05/2024
     */
    @TestVisible
    private static String getIconName(Map<String, String> iconMap, String fileExtension) {
        String result = DOCTYPE_UNKNOWN;

        if (iconMap.containsKey(fileExtension)) {
            result = iconMap.get(fileExtension);
        }

        return result;
    }


    /** Obtener la lista a devolver por el metodo principal del componente
     *           
     * @author dmunoz
     * @date 16/05/2024
     */
    @TestVisible
    private static List<ZRMFile> getZRMFilesList(List<ContentDocumentLink> contentDocumentLinkList,  Map<String, String> iconMap, User loggedUser) {
        List<ZRMFile> result = new List<ZRMFile>();
        ZRMFile zrmFile;
        Boolean deleteEnabled;

        for (ContentDocumentLink cdl: contentDocumentLinkList) {  
            deleteEnabled = userCanDelete(cdl, loggedUser);          
            zrmFile = new ZRMFile(cdl.Id, cdl.ContentDocument.Title, cdl.ContentDocument.LatestPublishedVersion.VersionDataUrl, getIconName(iconMap, cdl.ContentDocument.FileExtension), deleteEnabled);
            result.add(zrmFile);
        }   

        return result;
    }

    /** comprueba si el usuario logueado puede o no borrar por ser owner
     *           
     * @author dmunoz
     * @date 31/05/2024
     */
    private static Boolean userCanDelete(ContentDocumentLink contentDocumentLink, User loggedUser) {
        Boolean result = false;

        if (contentDocumentLink.ContentDocument.OwnerId.equals(loggedUser.Id)) {
            result = true;
        }

        return result;
    }

    //#region Private classes
    @TestVisible
    private class ZRMFile {

        @AuraEnabled
        public String fileId{get; set;}

        @AuraEnabled
        public String fileTitle{get; set;}

        @AuraEnabled
        public String fileDownloadUrl {get; set;}

        @AuraEnabled
        public String fileIcon {get; set;}

        @AuraEnabled
        public Boolean deleteEnabled {get; set;}

        public ZRMFile(String fileId, String fileTitle, String fileDownloadUrl, String fileIcon, Boolean deleteEnabled) {
            this.fileId = fileId;
            this.fileTitle = fileTitle;
            this.fileDownloadUrl = fileDownloadUrl;
            this.fileIcon = fileIcon;
            this.deleteEnabled = deleteEnabled;
        }
    }
}