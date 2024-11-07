import { createElement } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import IntermAddCampaignMember from "c/intermAddCampaignMember";
import getContacts from "@salesforce/apex/IntermAddCampaignMemberController.getContacts";

// Importa el adaptador de wire de prueba desde `@salesforce/sfdx-lwc-jest`
import { registerLdsTestWireAdapter } from "@salesforce/sfdx-lwc-jest";

// Registra un adaptador de wire simulado para `getRecord`
const getRecordWireAdapter = registerLdsTestWireAdapter(getRecord);

// Definir el mock de datos directamente en el código
const mockContactsData = require("./data/getAccounts.json");
const mockCampaingsData = require("./data/getCampaigns.json");

// Mockear el adaptador de Apex
jest.mock(
  "@salesforce/apex/IntermAddCampaignMemberController.getContacts",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

describe("c-interm-add-campaign-member", () => {
  afterEach(() => {
    // Restablecer el DOM después de cada prueba
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("Validación de representación de cuentas", async () => {
    // Crear el elemento
    const element = createElement("c-interm-add-campaign-member", {
      is: IntermAddCampaignMember
    });
    element.campaignId = mockCampaingsData.Id;

    // Añadir el componente al DOM
    document.body.appendChild(element);

    getRecordWireAdapter.emit(mockCampaingsData);

    // Emitir datos del mock en el adaptador de wire
    getContacts.emit(mockContactsData);

    // Esperar a que se resuelvan las promesas y actualicen el DOM
    await Promise.resolve();

    // Seleccionar la tabla y verificar que contiene los datos
    const showModalButton =
      element.shadowRoot.querySelector("lightning-button");
    showModalButton.dispatchEvent(new CustomEvent("click", { detail: {} }));

    await Promise.resolve();

    const modal = element.shadowRoot.querySelector("section.slds-modal");
    expect(modal).not.toBeNull();
    const datatable = modal.querySelector("lightning-datatable");
    expect(datatable).not.toBeNull();

    // Verificar que se muestra el número correcto de filas
    expect(datatable.data.length).toBe(mockContactsData.length);
  });

  it("Validación de filtrado", async () => {
    // Crear el elemento
    const element = createElement("c-interm-add-campaign-member", {
      is: IntermAddCampaignMember
    });
    element.campaignId = mockCampaingsData.Id;

    // Añadir el componente al DOM
    document.body.appendChild(element);

    getRecordWireAdapter.emit(mockCampaingsData);

    // Emitir datos del mock en el adaptador de wire
    getContacts.emit(mockContactsData);

    // Esperar a que se resuelvan las promesas y actualicen el DOM
    await Promise.resolve();

    // Seleccionar la tabla y verificar que contiene los datos
    const showModalButton =
      element.shadowRoot.querySelector("lightning-button");
    showModalButton.dispatchEvent(new CustomEvent("click", { detail: {} }));

    await Promise.resolve();

    // Obtener el elemento del input de búsqueda
    const modal = element.shadowRoot.querySelector("section.slds-modal");
    const lightningInput = modal.querySelector("lightning-input");

    // Configurar el valor del input y disparar el evento "input"
    lightningInput.value = "NID002";
    lightningInput.dispatchEvent(
      new CustomEvent("input", {
        bubbles: true,
        composed: true,
        detail: { value: "NID002" }
      })
    );

    // Esperar a que el componente se actualice
    await Promise.resolve();

    // Verificar si la tabla muestra los resultados filtrados
    const filteredResults = element.filteredAccounts; // o como se llame en tu LWC
    expect(filteredResults.length).toBe(1);
    expect(filteredResults).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ NationalId: "NID002" }),
        expect.objectContaining({ AccountName: "Account 2" })
      ])
    );
  });
});
