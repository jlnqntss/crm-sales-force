import { createElement } from "lwc";
import ZrmRecibos from "c/zrmRecibos";

// Define los valores de las etiquetas aquí
const labels = {
  ZRM_Recibos_Previous: "Previous",
  ZRM_Recibos_Next: "Next",
  ZRM_Recibos_Column_Receipt: "Receipt",
  ZRM_Recibos_Column_EffectiveDate: "Effective Date",
  ZRM_Recibos_Column_Policy: "Policy",
  ZRM_Recibos_Column_Company: "Company",
  ZRM_Recibos_Column_Holder: "Holder",
  ZRM_Recibos_Column_Phone: "Phone",
  ZRM_Recibos_Column_Amount: "Amount",
  ZRM_Recibos_Column_PaymentMethod: "Payment Method",
  ZRM_Recibos_Column_NumberOfReturns: "Number of Returns",
  ZRM_Recibos_Column_DocumentDescriptionReceipt: "Document Description",
  ZRM_Recibos_Column_LastReturnDate: "Last Return Date",
  ZRM_Recibos_Column_BankShipmentDate: "Bank Shipment Date",
  ZRM_Recibos_Column_Intermediary: "Intermediary"
};

describe("c-zrm-recibos", () => {
  let element;

  beforeEach(() => {
    // Crear un nuevo elemento antes de cada prueba
    element = createElement("c-zrm-recibos", {
      is: ZrmRecibos
    });

    // Configurar datos de prueba
    element.isLoading = false;

    document.body.appendChild(element);
  });

  describe("c-zrm-recibos", () => {
    afterEach(() => {
      while (document.body.firstChild) {
        document.body.removeChild(document.body.firstChild);
      }
    });

    it("Debería renderizar lightning-spinner cuando isLoading sea verdadero", async () => {
      // Arrange
      const element = createElement("c-zrm-recibos", {
        is: ZrmRecibos
      });
      document.body.appendChild(element);

      // Act
      element.isLoading = true;
      await Promise.resolve(); // Espera a que el DOM se actualice

      // Assert
      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).not.toBeNull();
    });
  });

  it("Debería renderizar lightning-datatable cuando isLoading sea falso", () => {
    element.isLoading = false;
    return Promise.resolve().then(() => {
      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
    });
  });
});
