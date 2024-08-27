import { createElement } from "lwc";
import ZrmRecibos from "c/zrmRecibos";

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
