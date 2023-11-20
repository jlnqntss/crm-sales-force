import labels from "./labels";

export default [
  {
    label: labels.thAffiliationCode,
    fieldName: "cmAffiliationCode",
    type: "text",
    hideDefaultActions: true
  },
  {
    label: labels.thName,
    fieldName: "cmName",
    type: "hyperlinkedString",
    hideDefaultActions: true,
    typeAttributes: {
      recordId: { fieldName: "cmRelatedAccountId" },
      sObject: "Account"
    }
  },
  {
    label: labels.thType,
    fieldName: "cmRelatedAccountRTName",
    hideDefaultActions: true
  },
  {
    label: labels.thStatus,
    fieldName: "cmStatus",
    hideDefaultActions: true,
    actions: [
      { label: "Todos", checked: false, disabled: true, name: "all" },
      {
        label: "Gestión CC",
        checked: false,
        disabled: true,
        name: "Gestión CC"
      },
      {
        label: "Gestión Mediador",
        checked: false,
        disabled: true,
        name: "Gestión Mediador"
      },
      {
        label: "Pdtes. Revisión Mediador",
        checked: false,
        disabled: true,
        name: "Pdtes. Revisión Mediador"
      }
    ]
  },
  {
    label: labels.thOffer,
    fieldName: "offerName",
    type: "hyperlinkedString",
    hideDefaultActions: true,
    typeAttributes: {
      recordId: { fieldName: "offerId" },
      sObject: "Opportunity"
    }
  },
  {
    label: labels.thOfferStage,
    fieldName: "offerStage",
    hideDefaultActions: true,
    actions: [
      { label: "Todos", checked: false, disabled: true, name: "all" },
      {
        label: "Cerrada Perdida",
        checked: false,
        disabled: true,
        name: "Cerrada Perdida"
      },
      {
        label: "Cerrada Ganada",
        checked: false,
        disabled: true,
        name: "Cerrada Ganada"
      },
      {
        label: "En gestión pendiente información",
        checked: false,
        disabled: true,
        name: "En gestión pendiente información"
      },
      {
        label: "No iniciado",
        checked: false,
        disabled: true,
        name: "No iniciado"
      },
      {
        label: "Oferta realizada",
        checked: false,
        disabled: true,
        name: "Oferta realizada"
      }
    ]
  },
  {
    label: labels.thLostReason,
    fieldName: "offerSalesLossReasonLabel",
    hideDefaultActions: true
  },
  {
    label: labels.thIntermediary,
    fieldName: "cmIntermediaryCode",
    hideDefaultActions: true
  }
];
