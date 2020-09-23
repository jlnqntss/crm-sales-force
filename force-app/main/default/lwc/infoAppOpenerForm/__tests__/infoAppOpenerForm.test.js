import { createElement } from "lwc";
import InfoAppOpenerForm from "c/infoAppOpenerForm";

describe("c-info-app-opener-form", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("On empty URL, open button is disabled", () => {
    const element = createElement("c-info-app-opener-form", {
      is: InfoAppOpenerForm
    });
    document.body.appendChild(element);

    return Promise.resolve().then(() => {
      expect(
        element.shadowRoot.querySelector(".open-url-action").disabled
      ).toBe(true);
    });
  });

  it("On incorrect URL, open button is disabled", () => {
    const element = createElement("c-info-app-opener-form", {
      is: InfoAppOpenerForm
    });
    document.body.appendChild(element);

    const baseUrlInput = Array.prototype.find.call(
      element.shadowRoot.querySelectorAll("lightning-input"),
      (input) => {
        return input.name === "base-url";
      }
    );

    baseUrlInput.value = "incorrect-url";
    baseUrlInput.dispatchEvent(new CustomEvent("change", { bubbles: true }));

    return Promise.resolve().then(() => {
      expect(
        element.shadowRoot.querySelector(".open-url-action").disabled
      ).toBe(true);
    });
  });

  it("On correct URL, open button is enabled", () => {
    const element = createElement("c-info-app-opener-form", {
      is: InfoAppOpenerForm
    });
    document.body.appendChild(element);

    const baseUrlInput = Array.prototype.find.call(
      element.shadowRoot.querySelectorAll("lightning-input"),
      (input) => {
        return input.name === "base-url";
      }
    );

    baseUrlInput.value = "https://mydomain.com";
    baseUrlInput.dispatchEvent(new CustomEvent("change", { bubbles: true }));

    return Promise.resolve().then(() => {
      expect(
        element.shadowRoot.querySelector(".open-url-action").disabled
      ).toBe(false);
    });
  });
});
