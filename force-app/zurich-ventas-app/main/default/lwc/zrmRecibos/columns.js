import labels from "./labels";

export default [
    { label: labels.ZRM_Recibos_Column_Receipt, fieldName: 'codigoRecibo', wrapText: true },
        {   label: labels.ZRM_Recibos_Column_EffectiveDate, 
            fieldName: 'fechaEfectoMovimiento', 
            type: 'date',
            typeAttributes: {
                day: "2-digit",
                month: "2-digit",
                year: "numeric"
            },
            wrapText: true
        },
        { label: labels.ZRM_Recibos_Column_Policy, fieldName: 'codigoPoliza', wrapText: true },
        { label: labels.ZRM_Recibos_Column_Company, fieldName: 'descripcionAgrupacionCompania', wrapText: true },
        { label: labels.ZRM_Recibos_Column_Holder, fieldName: 'nombreTomador', wrapText: true },
        { label: labels.ZRM_Recibos_Column_Phone, fieldName: 'telefonoTomador', wrapText: true },
        { label: labels.ZRM_Recibos_Column_Amount, 
            fieldName: 'importeTotalRecibo', 
            type: 'currency',
            typeAttributes: { 
                currencyCode: 'EUR', 
                step: '0.001' 
            },
            wrapText: true
        },
        { label: labels.ZRM_Recibos_Column_PaymentMethod, fieldName: 'descripcionFormaPago', wrapText: true },
        { label: labels.ZRM_Recibos_Column_NumberOfReturns, fieldName: 'numeroDevolucionesRecibo', wrapText: true },
        { label: labels.ZRM_Recibos_Column_DocumentDescriptionReceipt, fieldName: 'descripcionDocumentoReclamacion', wrapText: true },
        { 
            label: labels.ZRM_Recibos_Column_LastReturnDate, 
            fieldName: 'fechaUltimaDevolucionRecibo', 
            type: 'date',
            typeAttributes: {
                day: "2-digit",
                month: "2-digit",
                year: "numeric"
            },
            wrapText: true
        },
        {   label: labels.ZRM_Recibos_Column_BankShipmentDate, 
            fieldName: 'fechaEnvioBancoRecibo', 
            type: 'date',
            typeAttributes:{
                day: "2-digit",
                month: "2-digit",
                year: "numeric"
            },
            wrapText: true
        },
        { label: labels.ZRM_Recibos_Column_Intermediary, fieldName: 'codigoIntermediario', wrapText: true }
];
