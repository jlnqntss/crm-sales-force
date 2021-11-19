import { createElement } from "lwc";
import CallMeBackList from "c/callMeBackList";

describe("c-call-me-back-list", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  // Test donde no hay elementos Contact Request
  it("Se comprueba el título de la aplicación.", () => {
    const element = createElement("c-call-me-back-list", {
      is: CallMeBackList
    });
    document.body.appendChild(element);
    expect(element.shadowRoot.querySelector("lightning-card").title).toBe(
      "Call Me Backs"
    );
  });
});
